;;;; tests/reader/symbol.lsp

(deftest "symbol-canonical-uppercase"
  '((operator . "Symbol") (area . "reader") (profile . strict))
  '(vl-symbol-name 'abc) "ABC")

(deftest "symbol-with-dash"
  '((operator . "Symbol") (area . "reader") (profile . strict))
  '(vl-symbol-name 'foo-bar) "FOO-BAR")

(deftest "symbol-with-digits"
  '((operator . "Symbol") (area . "reader") (profile . strict))
  '(vl-symbol-name 'a1b2) "A1B2")

(deftest "symbol-eq-with-itself"
  '((operator . "Symbol") (area . "reader") (profile . strict))
  '(eq 'foo 'foo) T)

(deftest-pred "symbol-type"
  '((operator . "Symbol") (area . "reader") (profile . strict))
  ''abc
  '(eq (type *result*) 'sym))
