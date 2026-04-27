;;;; tests/string/rtos.lsp -- RTOS
;;;; Mode 2 = decimal; mode 1 = scientific. Precision = decimal places.

(deftest "rtos-decimal-mode-2-prec-3"
  '((operator . "RTOS") (area . "string") (profile . strict))
  '(rtos 3.14159 2 3) "3.142")

(deftest "rtos-decimal-mode-2-prec-0"
  '((operator . "RTOS") (area . "string") (profile . strict))
  '(rtos 3.5 2 0) "4")

(deftest "rtos-zero"
  '((operator . "RTOS") (area . "string") (profile . strict))
  '(rtos 0.0 2 2) "0.00")

(deftest "rtos-negative"
  '((operator . "RTOS") (area . "string") (profile . strict))
  '(rtos -1.234 2 2) "-1.23")
