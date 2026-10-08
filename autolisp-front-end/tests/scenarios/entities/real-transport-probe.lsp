;;;; real-transport-probe.lsp -- MEASURE how real literals reach the CAD when
;;;; alfe loads a file (issues/open/alfe-cad-transport-rounds-reals.issue).
;;;;
;;;; alfe does not load an -l file with the CAD's own LOAD: its CAD-side loader
;;;; reads each top-level form and hands it to the CAD's native LOAD through a
;;;; temporary file. Up to alfe 2.3.7 that file held the form PRINTED BACK with
;;;; princ, which keeps 6 significant digits of a real on AutoCAD and 14 on
;;;; BricsCAD. Since 2.3.12 it holds the form's own TEXT, and a form alfe must
;;;; rewrite (AutoCAD: a 1-arg princ/print/prin1/load) is printed back with
;;;; every real at full precision. This probe reports, per literal and per
;;;; path, whether the value the CAD ended up with is the one its own reader
;;;; makes of the same digits -- it measures, it does not judge.
;;;;
;;;; Paths:
;;;;   literal     a top-level (setq ...) of the file: travels as its text;
;;;;   normalised  the same literal inside a form holding (princ ""), which
;;;;               alfe rewrites on AutoCAD and so prints back;
;;;;   read        (read "<digits>") at run time: the CAD reader alone, the
;;;;               reference the other two are compared with;
;;;;   x-request   (alfe only) the literal as an -x request, see the run
;;;;               scripts (scripts/run-real-transport-probe.*).
;;;;
;;;; Output, one line per observation, space-separated:
;;;;   REALTX <case> <path> <exact|differs> <type> <(rtos x 2 16)> <(rtos x 1 16)>
;;;;   REALTX-PRINC <case> <(vl-princ-to-string x)>    ; the CAD's princ digits
;;;;   REALTX-PRINTER <case> <text> <reads-back yes|no> ; alfe's lossless printer
;;;;   REALTX-INFO <name> <value>
;;;;   REALTX-DONE
;;;; "exact" means: a REAL, = to (read "<digits>"), with the same sign of zero
;;;; (told apart with atan, which = cannot do). Keep this file ASCII.

(defun rtx-negzero-p (x / r)
  (and (= (type x) 'REAL)
       (= x 0.0)
       (progn
         (setq r (vl-catch-all-apply 'atan (list x -1.0)))
         (and (not (vl-catch-all-error-p r)) (minusp r)))))

(defun rtx-rtos (x mode / s)
  (if (numberp x)
    (progn
      (setq s (vl-catch-all-apply 'rtos (list x mode 16)))
      (if (vl-catch-all-error-p s) "ERROR" s))
    "NOT-A-NUMBER"))

(defun rtx-exact-p (x digits / ref)
  (setq ref (read digits))
  (and (= (type x) 'REAL)
       (= (type ref) 'REAL)
       (= x ref)
       (eq (rtx-negzero-p x) (rtx-negzero-p ref))))

(defun rtx-report (name path x digits)
  (princ (strcat "REALTX " name " " path " "
                 (if (rtx-exact-p x digits) "exact" "differs") " "
                 (vl-princ-to-string (type x)) " "
                 (rtx-rtos x 2) " " (rtx-rtos x 1) "\n")))

;; The run scripts call this with -x: the literal travels in the request.
(defun rtx-x-case (x)
  (rtx-report "b" "x-request" x "1.5707963267948966"))

(defun rtx-info (name value)
  (princ (strcat "REALTX-INFO " name " "
                 (vl-princ-to-string
                   (if (vl-catch-all-error-p value) "ERROR" value))
                 "\n")))

(rtx-info "PRODUCT" (vl-catch-all-apply 'getvar (list "PRODUCT")))
(rtx-info "ACADVER" (vl-catch-all-apply 'getvar (list "ACADVER")))
(rtx-info "DIMZIN" (vl-catch-all-apply 'getvar (list "DIMZIN")))
(rtx-info "LUPREC" (vl-catch-all-apply 'getvar (list "LUPREC")))

;; The cases: name and digits. Kept as STRINGS here so this table itself
;; cannot be rounded on the way in.
(setq *rtx-cases*
  (list
    (list "a" "1.2345678901234")
    (list "b" "1.5707963267948966")
    (list "c" "0.1")
    (list "d" "1.0e-300")
    (list "e" "1.0e300")
    (list "f" "-2.5e-7")
    (list "g" "3.0")
    (list "h" "-0.0")
    (list "i" "1.7976931348623157e308")
    (list "j" "123456789012345678.0")
    (list "k" "0.7853981633974483")))

;; --- path "literal": top-level setq forms, one literal each --------------
(setq rtl-a 1.2345678901234)
(setq rtl-b 1.5707963267948966)
(setq rtl-c 0.1)
(setq rtl-d 1.0e-300)
(setq rtl-e 1.0e300)
(setq rtl-f -2.5e-7)
(setq rtl-g 3.0)
(setq rtl-h -0.0)
(setq rtl-i 1.7976931348623157e308)
(setq rtl-j 123456789012345678.0)
(setq rtl-k 0.7853981633974483)

;; --- path "normalised": the same literals in a form holding (princ "") ----
(progn
  (setq rtn-a 1.2345678901234 rtn-b 1.5707963267948966 rtn-c 0.1
        rtn-d 1.0e-300 rtn-e 1.0e300 rtn-f -2.5e-7 rtn-g 3.0 rtn-h -0.0
        rtn-i 1.7976931348623157e308 rtn-j 123456789012345678.0
        rtn-k 0.7853981633974483)
  (princ ""))

(foreach c *rtx-cases*
  (rtx-report (car c) "literal"
              (eval (read (strcat "rtl-" (car c)))) (cadr c))
  (rtx-report (car c) "normalised"
              (eval (read (strcat "rtn-" (car c)))) (cadr c))
  (rtx-report (car c) "read" (read (cadr c)) (cadr c))
  (princ (strcat "REALTX-PRINC " (car c) " "
                 (vl-princ-to-string (read (cadr c))) "\n"))
  ;; alfe's lossless printer, when this runs under alfe on a CAD.
  (if (and (boundp 'autolisp-real-source-text) autolisp-real-source-text
           (= (type (read (cadr c))) 'REAL))
    (progn
      (setq rtx-text (autolisp-real-source-text (read (cadr c))))
      (princ (strcat "REALTX-PRINTER " (car c) " " rtx-text " "
                     (if (and (not (vl-catch-all-error-p
                                     (setq rtx-back (vl-catch-all-apply
                                                      'read (list rtx-text)))))
                              (rtx-exact-p rtx-back (cadr c)))
                       "yes" "no")
                     "\n")))))

(princ "REALTX-DONE\n")
(princ)
