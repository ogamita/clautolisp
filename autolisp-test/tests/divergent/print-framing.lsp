;;;; tests/divergent/print-framing.lsp -- printer framing twin tests
;;;;
;;;; BricsCAD V26 / macOS Phase-5 probe recorded the file output of:
;;;;
;;;;   (prin1 "hello" file-desc) ->  "hello"\n
;;;;   (princ "hello" file-desc) ->  hello\n
;;;;   (print "hello" file-desc) ->  \n"hello" \n
;;;;
;;;; AutoCAD's documented framing for `print' historically uses
;;;; "\n<form> " (leading newline, form, trailing space, no trailing
;;;; newline). The exact bytes vary across releases, so the AutoCAD
;;;; twin is INFERRED until probe data lands.
;;;;
;;;; Each test writes to a fresh temp file and reads the resulting
;;;; bytes back.

(setq *aut-pf-file*
      (strcat *autolisp-test-root* "results/.tmp-print-framing.txt"))

(defun aut-pf-read-bytes ( / fp acc ch)
  (setq fp (open *aut-pf-file* "r"))
  (setq acc "")
  (setq ch (read-char fp))
  (while ch
    (setq acc (strcat acc (chr ch)))
    (setq ch (read-char fp)))
  (close fp)
  acc)

(defun aut-pf-write-and-read (action / fp result)
  (setq fp (open *aut-pf-file* "w"))
  (eval (list action fp))
  (close fp)
  (aut-pf-read-bytes))

;; --- BricsCAD twin (TESTED-BRICSCAD) -------------------------------
(deftest "bricscad-prin1-string-framing"
  '((operator . "PRIN1") (area . "printer") (profile . bricscad)
    (authority . tested-bricscad))
  '(aut-pf-write-and-read '(lambda (fp) (prin1 "hello" fp)))
  "\"hello\"\n")

(deftest "bricscad-princ-string-framing"
  '((operator . "PRINC") (area . "printer") (profile . bricscad)
    (authority . tested-bricscad))
  '(aut-pf-write-and-read '(lambda (fp) (princ "hello" fp)))
  "hello\n")

(deftest "bricscad-print-string-framing"
  '((operator . "PRINT") (area . "printer") (profile . bricscad)
    (authority . tested-bricscad))
  '(aut-pf-write-and-read '(lambda (fp) (print "hello" fp)))
  "\n\"hello\" \n")

;; --- AutoCAD twin (INFERRED, no probe yet) -------------------------
(deftest "autocad-print-string-framing-no-trailing-newline"
  '((operator . "PRINT") (area . "printer") (profile . autocad)
    (authority . inferred))
  '(aut-pf-write-and-read '(lambda (fp) (print "hello" fp)))
  "\n\"hello\" ")
