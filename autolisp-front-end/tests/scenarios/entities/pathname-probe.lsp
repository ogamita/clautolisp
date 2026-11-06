;;;; pathname-probe.lsp — probe how open / findfile / load treat "." and
;;;; ".." path segments on each target (clautolisp vs BricsCAD vs AutoCAD).
;;;;
;;;; Background: cad-path-dotdot-resolution.issue. clautolisp collapses
;;;; ".."/"." (POSIX-UP semantics) so a path like BASE/sub/../target.txt
;;;; reaches the file; BricsCAD is reported NOT to resolve it (file treated
;;;; as not found). This probe confirms the divergence with a controlled,
;;;; self-contained repro: it CREATES the directory structure it needs
;;;; (BASE/ + BASE/sub/) so the ".." step traverses a directory that really
;;;; exists — the POSIX-UP precondition — leaving only the resolution
;;;; question to the host.
;;;;
;;;; Every result line is machine-readable: "PATHPROBE <KEY>=<VALUE>", so a
;;;; diff of the report across backends shows the divergence. Ends with
;;;; "PATHPROBE DONE".

(defun pp (key val) (princ (strcat "PATHPROBE " key "=" val "\n")) (princ))

(defun open-result (path mode / h)
  ;; "HANDLE" if (open PATH MODE) yields a file, "NIL" otherwise. Always
  ;; closes what it opened.
  (setq h (vl-catch-all-apply 'open (list path mode)))
  (cond ((vl-catch-all-error-p h) "ERROR")
        ((null h) "NIL")
        (t (vl-catch-all-apply 'close (list h)) "HANDLE")))

(defun probe-pathnames ( / base sub target ddpath dotpath nxpath sep tmp)
  ;; --- pick a writable base directory --------------------------------
  (setq tmp (getvar "TEMPPREFIX"))
  (if (or (null tmp) (= tmp "")) (setq tmp (getenv "TMPDIR")))
  (if (or (null tmp) (= tmp "")) (setq tmp (getenv "TEMP")))
  (if (or (null tmp) (= tmp "")) (setq tmp (getenv "TMP")))
  (if (or (null tmp) (= tmp "")) (setq tmp "./"))
  ;; normalise to a forward-slash directory with a trailing slash
  (while (wcmatch tmp "*\\*")
    (setq tmp (vl-string-subst "/" "\\" tmp)))
  (if (/= "/" (substr tmp (strlen tmp))) (setq tmp (strcat tmp "/")))
  (pp "TEMPPREFIX" (vl-princ-to-string (getvar "TEMPPREFIX")))
  (pp "BASE-DIR" tmp)

  ;; --- build BASE/ and BASE/sub/ -------------------------------------
  (setq base   (strcat tmp "ddprobe"))
  (setq sub    (strcat base "/sub"))
  (setq target (strcat base "/target.txt"))
  (vl-catch-all-apply 'vl-mkdir (list base))
  (vl-catch-all-apply 'vl-mkdir (list sub))
  (pp "MKDIR-BASE-OK" (if (vl-file-directory-p base) "Y" "N"))
  (pp "MKDIR-SUB-OK"  (if (vl-file-directory-p sub)  "Y" "N"))

  ;; --- write the target file -----------------------------------------
  (setq f (vl-catch-all-apply 'open (list target "w")))
  (if (and f (not (vl-catch-all-error-p f)))
      (progn (write-line "dotdot-probe payload" f) (close f)))
  (pp "TARGET-EXISTS" (if (findfile target) "Y" "N"))

  ;; --- the actual probes ---------------------------------------------
  (setq ddpath  (strcat base "/sub/../target.txt"))     ; ".." through sub/ (exists)
  (setq dotpath (strcat base "/./target.txt"))          ; "." no-op segment
  (setq nxpath  (strcat base "/noexist/../target.txt")) ; ".." through a MISSING dir
  (pp "DIRECT-OPEN"     (open-result target "r"))
  (pp "DOT-OPEN"        (open-result dotpath "r"))
  (pp "DOTDOT-OPEN"     (open-result ddpath "r"))
  (pp "DOTDOT-FINDFILE" (vl-princ-to-string (findfile ddpath)))
  (pp "DOT-FINDFILE"    (vl-princ-to-string (findfile dotpath)))
  ;; ".." through a directory that does NOT exist distinguishes POSIX-UP
  ;; (physical walk -> must fail: the missing dir can't be traversed) from
  ;; syntactic BACK (textual rewrite to BASE/target.txt -> would succeed).
  ;; clautolisp is UP; this line says what each CAD does.
  (pp "NOEXIST-DOTDOT-OPEN"     (open-result nxpath "r"))
  (pp "NOEXIST-DOTDOT-FINDFILE" (vl-princ-to-string (findfile nxpath)))

  ;; --- clean up ------------------------------------------------------
  (vl-catch-all-apply 'vl-file-delete (list target))
  (vl-catch-all-apply 'vl-rmdir (list sub))
  (vl-catch-all-apply 'vl-rmdir (list base))
  (pp "DONE" "1"))

(vl-catch-all-apply 'probe-pathnames nil)
(princ "PATHPROBE DONE\n")
(princ)
