;;;; lispsys-forward-probe.lsp -- encoding-situations-cli-options: alfe's
;;;; -Efile-write UTF-8 forwarded to AutoCAD's OPEN as the third argument
;;;; "utf8" (alfe-open* in the bootstrap), checked end to end.
;;;;
;;;; scripts/run-lispsys-bom-probe.ps1 runs this once per LISPSYS level, with
;;;; `alfe --autocad -Efile-write utf-8 -l ENTRY', where ENTRY is a one-line
;;;; file (alfe-load "<this file>"). This file MUST be loaded with alfe-load:
;;;; only alfe-load rewrites the literal OPEN calls below into alfe-open*. The
;;;; -l file itself goes through the plain request path, which rewrites
;;;; nothing -- the first run (2026-10-08, job 16998925786) loaded this file
;;;; with -l directly and so measured the unforwarded OPEN: "w SIZE 3" and
;;;; "a SIZE 1" at every level, no WARN (alfe-efile-write-not-applied-to-l-file).
;;;;
;;;; Prints one "ENC E1F ..." line per case with the file size:
;;;;   w: "A" e-acute "B" -- 3 = cp1252 (not forwarded), 4 = UTF-8 (forwarded);
;;;;   a: one e-acute appended to a fresh file -- 1 = cp1252, 2 = UTF-8.
;;;; Expected: LISPSYS 0 -> w 3, a 1, one WARN naming LISPSYS (alfe's error
;;;; channel); LISPSYS 1 / 2 -> w 4, a 2, no WARN.

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
                                           (eval '*ALFE-OPEN-WRITE-ARG*)))))
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

(e1f-run)
