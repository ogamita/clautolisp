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
