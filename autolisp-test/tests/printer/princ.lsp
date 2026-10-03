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

;; With no argument the vendors return the VOID (null) symbol -- the
;; spec's "void symbol value", the reason a command function ends in
;; (princ): its name is empty, so the console echoes nothing.
(deftest "princ-no-arg-returns-the-void-symbol"
  '((operator . "PRINC") (area . "printer") (profile . strict))
  '(vl-symbol-name (princ)) "")
