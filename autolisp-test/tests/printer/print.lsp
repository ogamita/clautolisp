;;;; tests/printer/print.lsp -- PRINT
;;;; Returns its argument. Printed framing is vendor-divergent;
;;;; framing assertions live in tests/divergent/print-framing.lsp.

(deftest "print-returns-its-argument-int"
  '((operator . "PRINT") (area . "printer") (profile . strict))
  '(print 17) 17)

(deftest "print-returns-its-argument-string"
  '((operator . "PRINT") (area . "printer") (profile . strict))
  '(print "hello") "hello")

(deftest "print-returns-list"
  '((operator . "PRINT") (area . "printer") (profile . strict))
  '(print '(1 2 3)) '(1 2 3))

;; With no argument the vendors return the VOID (null) symbol -- the
;; spec's "void symbol value", the reason a command function ends in
;; (princ): its name is empty, so the console echoes nothing.
(deftest "print-no-arg-returns-the-void-symbol"
  '((operator . "PRINT") (area . "printer") (profile . strict))
  '(vl-symbol-name (print)) "")
