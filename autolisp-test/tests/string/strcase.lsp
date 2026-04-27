;;;; tests/string/strcase.lsp -- STRCASE

(deftest "strcase-upper"
  '((operator . "STRCASE") (area . "string") (profile . strict))
  '(strcase "hello") "HELLO")

(deftest "strcase-lower-flag"
  '((operator . "STRCASE") (area . "string") (profile . strict))
  '(strcase "HELLO" T) "hello")

(deftest "strcase-mixed-to-upper"
  '((operator . "STRCASE") (area . "string") (profile . strict))
  '(strcase "Hello World") "HELLO WORLD")

(deftest "strcase-empty"
  '((operator . "STRCASE") (area . "string") (profile . strict))
  '(strcase "") "")

(deftest "strcase-already-upper"
  '((operator . "STRCASE") (area . "string") (profile . strict))
  '(strcase "ABC") "ABC")

(deftest "strcase-digits-untouched"
  '((operator . "STRCASE") (area . "string") (profile . strict))
  '(strcase "abc123") "ABC123")
