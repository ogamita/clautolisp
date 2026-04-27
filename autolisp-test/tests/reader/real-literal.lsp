;;;; tests/reader/real-literal.lsp

(deftest "real-literal-positive"
  '((operator . "Real Literal") (area . "reader") (profile . strict))
  '3.14 3.14)

(deftest "real-literal-negative"
  '((operator . "Real Literal") (area . "reader") (profile . strict))
  '-2.5 -2.5)

(deftest "real-literal-zero"
  '((operator . "Real Literal") (area . "reader") (profile . strict))
  '0.0 0.0)

(deftest "real-literal-scientific"
  '((operator . "Real Literal") (area . "reader") (profile . strict))
  '1.0e3 1000.0)

(deftest-pred "real-literal-type-real"
  '((operator . "Real Literal") (area . "reader") (profile . strict))
  '3.14
  '(eq (type *result*) 'real))
