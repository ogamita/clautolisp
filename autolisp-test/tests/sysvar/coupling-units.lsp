;;;; tests/sysvar/coupling-units.lsp
;;;;
;;;; LUNITS / LUPREC / DIMZIN / UNITMODE drive rtos and distance
;;;; formatting. Distance / getdist read LUPREC for input parsing.

(deftest "sysvar-luprec-controls-decimal-places"
  '((operator . "LUPREC") (area . "sysvar") (profile . strict))
  '(progn (setvar "LUNITS" 2)         ;; decimal
          (setvar "LUPREC" 3)
          (rtos 1.234567 2 3))
  "1.235")

(deftest "sysvar-luprec-zero-rounds-to-int"
  '((operator . "LUPREC") (area . "sysvar") (profile . strict))
  '(progn (setvar "LUNITS" 2)
          (setvar "LUPREC" 0)
          (rtos 1.6 2 0))
  "2")

(deftest "sysvar-lunits-2-is-decimal"
  '((operator . "LUNITS") (area . "sysvar") (profile . strict))
  '(progn (setvar "LUNITS" 2)
          (setvar "LUPREC" 2)
          (rtos 1.25 2 2))
  "1.25")

(deftest "sysvar-lunits-1-is-scientific"
  '((operator . "LUNITS") (area . "sysvar") (profile . strict))
  '(progn (setvar "LUNITS" 1)
          (setvar "LUPREC" 2)
          (rtos 100.0 1 2))
  "1.00E+02")

;;; --- defaults: rtos with MODE / PRECISION omitted reads the sysvars

(deftest "sysvar-luprec-is-rtos-default-precision"
  '((operator . "LUPREC") (area . "sysvar") (profile . strict))
  '(progn (setvar "LUNITS" 2)
          (setvar "LUPREC" 2)
          (setvar "DIMZIN" 0)
          (rtos 3.14159))                 ;; no mode / precision args
  "3.14")

(deftest "sysvar-lunits-is-rtos-default-mode"
  '((operator . "LUNITS") (area . "sysvar") (profile . strict))
  '(progn (setvar "LUNITS" 1)             ;; scientific
          (setvar "LUPREC" 2)
          (setvar "DIMZIN" 0)
          (rtos 100.0))                   ;; no mode / precision args
  "1.00E+02")

;;; --- DIMZIN zero suppression (decimal output)

(deftest "sysvar-dimzin-8-suppresses-trailing-zeros"
  '((operator . "DIMZIN") (area . "sysvar") (profile . strict))
  '(progn (setvar "LUNITS" 2)
          (setvar "DIMZIN" 8)
          (rtos 12.5 2 4))
  "12.5")

(deftest "sysvar-dimzin-4-suppresses-leading-zero"
  '((operator . "DIMZIN") (area . "sysvar") (profile . strict))
  '(progn (setvar "LUNITS" 2)
          (setvar "DIMZIN" 4)
          (rtos 0.5 2 4))
  ".5000")

;;; --- rtos modes 3-5 (engineering / architectural / fractional) -----
;;; LUPREC is decimal places for engineering, and the power-of-two
;;; fraction denominator (2^LUPREC) for architectural / fractional.
;;; Canonical AutoCAD examples for 17.5 drawing-units (inches).

(deftest "sysvar-rtos-mode-3-engineering"
  '((operator . "LUNITS") (area . "sysvar") (profile . strict))
  '(rtos 17.5 3 2)
  "1'-5.50\"")

(deftest "sysvar-rtos-mode-4-architectural"
  '((operator . "LUNITS") (area . "sysvar") (profile . strict))
  '(rtos 17.5 4 2)
  "1'-5 1/2\"")

(deftest "sysvar-rtos-mode-5-fractional"
  '((operator . "LUNITS") (area . "sysvar") (profile . strict))
  '(rtos 17.5 5 2)
  "17 1/2")

;;; --- UNITMODE: 0 = display form (space), 1 = input form (hyphen) ----

(deftest "sysvar-unitmode-0-uses-space"
  '((operator . "UNITMODE") (area . "sysvar") (profile . strict))
  '(progn (setvar "UNITMODE" 0)
          (rtos 17.5 4 2))
  "1'-5 1/2\"")

(deftest "sysvar-unitmode-1-uses-hyphen"
  '((operator . "UNITMODE") (area . "sysvar") (profile . strict))
  '(progn (setvar "UNITMODE" 1)
          (let ((result (rtos 17.5 5 2)))
            (setvar "UNITMODE" 0)        ;; restore
            result))
  "17-1/2")

;; Reset UNITMODE so it does not leak into later tests.
(deftest "sysvar-unitmode-reset"
  '((operator . "UNITMODE") (area . "sysvar") (profile . strict))
  '(progn (setvar "UNITMODE" 0) (getvar "UNITMODE"))
  0)

;; Reset DIMZIN so it does not leak into later tests in the shared image.
(deftest "sysvar-dimzin-reset"
  '((operator . "DIMZIN") (area . "sysvar") (profile . strict))
  '(progn (setvar "DIMZIN" 0) (getvar "DIMZIN"))
  0)
