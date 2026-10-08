;;;; lispsys-forward-probe.lsp -- encoding-situations-cli-options: alfe's
;;;; -Efile-write UTF-8 forwarded to the CAD's OPEN -- AutoCAD's third argument
;;;; "utf8", BricsCAD/Windows' ",ccs=UTF-8" (alfe-open* in the bootstrap) --
;;;; checked end to end.
;;;;
;;;; scripts/run-lispsys-bom-probe.ps1 (AutoCAD, once per LISPSYS level) and
;;;; scripts/run-encoding-experiment.ps1 (the FORWARD step) run it THREE ways
;;;; under -Efile-write utf-8, one alfe run each:
;;;;   alfe-load  -l ENTRY, ENTRY being the one line (alfe-load "<this file>");
;;;;   -l         -l <this file>, read by the deported loader;
;;;;   -x         -l <this file> with E1F_MODE=x (nothing runs at load) and
;;;;              -x "(e1f-x (open (e1f-xp 'w) (e1f-xm 'w)) (open (e1f-xp 'a) (e1f-xm 'a)))",
;;;;              so the OPEN calls are in the -x form's own text.
;;;; Since alfe 2.3.14 (alfe-efile-write-not-applied-to-l-file) all three are
;;;; forwarded; before, only the alfe-load one was -- the first run
;;;; (2026-10-08, job 16998925786) loaded this file with -l and measured the
;;;; unforwarded OPEN: "w SIZE 3" and "a SIZE 1" at every level, no WARN.
;;;;
;;;; Prints one "ENC E1F ..." line per case with the file size:
;;;;   w: "A" e-acute "B" -- 3 = cp1252 (not forwarded), 4 = UTF-8 (forwarded,
;;;;      AutoCAD), 7 = UTF-8 with a BOM (forwarded ,ccs=UTF-8, BricsCAD/Windows);
;;;;   a: one e-acute appended to a fresh file -- 1 = cp1252, 2 = UTF-8 (5 with
;;;;      a BOM).
;;;; Expected on AutoCAD, for each of the three ways: LISPSYS 0 -> w 3, a 1, one
;;;; WARN naming LISPSYS (alfe's error channel); LISPSYS 1 / 2 -> w 4, a 2, no
;;;; WARN.

(defun e1f--line (text)
  (princ (strcat "\nENC E1F " text "\n")))

(defun e1f-size (path)
  (if (findfile path) (strcat "SIZE " (vl-prin1-to-string (vl-file-size path))) "NO-FILE"))

;; The OPEN calls are at the top level of the defun body, NOT inside a
;; (function (lambda ...)) or a quoted form: alfe's rewriter stops at QUOTE /
;; FUNCTION, so an OPEN there would never reach alfe-open*. alfe-open* falls
;; back to the plain mode by itself if the CAD refuses the argument.
(defun e1f-run ( / dir p q f)
  (setq dir (getenv "E1_DIR"))
  (e1f--line (strcat "LISPSYS " (vl-prin1-to-string (getvar "LISPSYS"))
                     " FORWARDED-ARG "
                     (vl-prin1-to-string (if (boundp '*ALFE-OPEN-WRITE-ARG*)
                                           (eval '*ALFE-OPEN-WRITE-ARG*)))
                     " FORWARDED-CCS "
                     (vl-prin1-to-string (if (boundp '*ALFE-OPEN-WRITE-CCS*)
                                           (eval '*ALFE-OPEN-WRITE-CCS*)))))
  (setq p (strcat dir "/e1f-w.txt"))
  (setq f (open p "w"))
  (if f (progn (write-char 65 f) (write-char 233 f) (write-char 66 f) (close f)))
  (e1f--line (strcat "w " (e1f-size p)))
  (setq q (strcat dir "/e1f-a.txt"))
  (if (findfile q) (vl-file-delete q))
  (setq f (open q "a"))
  (if f (progn (write-char 233 f) (close f)))
  (e1f--line (strcat "a " (e1f-size q)))
  (princ "\nENC-PROBE DONE\n")
  (princ))

;; The -x way: the OPEN calls are written in the -x form, which calls these.
;; No string in that form (Windows PowerShell 5.1 mangles the double quotes
;; of a native argument), hence the symbols W and A.
(defun e1f-xpath (which)
  (strcat (getenv "E1_DIR") (if (eq which 'w) "/e1f-xw.txt" "/e1f-xa.txt")))

;; The path to open for WHICH; the append file is removed first.
(defun e1f-xp (which / p)
  (setq p (e1f-xpath which))
  (if (and (not (eq which 'w)) (findfile p)) (vl-file-delete p))
  p)

(defun e1f-xm (which) (if (eq which 'w) "w" "a"))

(defun e1f-x (fw fa)
  (e1f--line (strcat "-x LISPSYS " (vl-prin1-to-string (getvar "LISPSYS"))))
  (if fw (progn (write-char 65 fw) (write-char 233 fw) (write-char 66 fw) (close fw)))
  (e1f--line (strcat "w " (e1f-size (e1f-xpath 'w))))
  (if fa (progn (write-char 233 fa) (close fa)))
  (e1f--line (strcat "a " (e1f-size (e1f-xpath 'a))))
  (princ "\nENC-PROBE DONE\n")
  (princ))

(if (not (equal (getenv "E1F_MODE") "x")) (e1f-run))
