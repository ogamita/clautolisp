;;;; tests/reader/string-literal.lsp

(deftest "string-literal-empty"
  '((operator . "String Literal") (area . "reader") (profile . strict))
  '"" "")

(deftest "string-literal-simple"
  '((operator . "String Literal") (area . "reader") (profile . strict))
  '"hello" "hello")

(deftest "string-literal-with-space"
  '((operator . "String Literal") (area . "reader") (profile . strict))
  '"a b c" "a b c")

(deftest-pred "string-literal-type-str"
  '((operator . "String Literal") (area . "reader") (profile . strict))
  '"abc"
  '(eq (type *result*) 'str))
