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

;; With no argument the vendors return the VOID (null) symbol -- the
;; spec's "void symbol value", the reason a command function ends in
;; (princ): its name is empty, so the console echoes nothing.
(deftest "prin1-no-arg-returns-the-void-symbol"
  '((operator . "PRIN1") (area . "printer") (profile . strict))
  '(vl-symbol-name (prin1)) "")
