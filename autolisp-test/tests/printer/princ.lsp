;;;; tests/printer/princ.lsp -- PRINC
;;;; Returns its argument; printed representation is human-readable.

(deftest "princ-returns-its-argument-int"
  '((operator . "PRINC") (area . "printer") (profile . strict))
  '(princ 17) 17)

(deftest "princ-returns-its-argument-string"
  '((operator . "PRINC") (area . "printer") (profile . strict))
  '(princ "hello") "hello")

(deftest "princ-returns-list"
  '((operator . "PRINC") (area . "printer") (profile . strict))
  '(princ '(a b c)) '(a b c))

(deftest "princ-no-arg-returns-nil"
  '((operator . "PRINC") (area . "printer") (profile . strict))
  '(princ) nil)
