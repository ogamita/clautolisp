;;;; tests/reader/integer-literal.lsp

(deftest "integer-literal-positive"
  '((operator . "Integer Literal") (area . "reader") (profile . strict))
  '17 17)

(deftest "integer-literal-negative"
  '((operator . "Integer Literal") (area . "reader") (profile . strict))
  '-42 -42)

(deftest "integer-literal-zero"
  '((operator . "Integer Literal") (area . "reader") (profile . strict))
  '0 0)

(deftest-pred "integer-literal-type-int"
  '((operator . "Integer Literal") (area . "reader") (profile . strict))
  '17
  '(eq (type *result*) 'int))
