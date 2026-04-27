;;;; tests/printer/prin1.lsp -- PRIN1
;;;; Returns its argument; printed representation is read-back-able.

(deftest "prin1-returns-its-argument-int"
  '((operator . "PRIN1") (area . "printer") (profile . strict))
  '(prin1 17) 17)

(deftest "prin1-returns-its-argument-string"
  '((operator . "PRIN1") (area . "printer") (profile . strict))
  '(prin1 "hello") "hello")

(deftest "prin1-returns-list"
  '((operator . "PRIN1") (area . "printer") (profile . strict))
  '(prin1 '(1 2 3)) '(1 2 3))

(deftest "prin1-returns-symbol"
  '((operator . "PRIN1") (area . "printer") (profile . strict))
  '(prin1 'foo) 'foo)

(deftest "prin1-no-arg-returns-nil"
  '((operator . "PRIN1") (area . "printer") (profile . strict))
  '(prin1) nil)
