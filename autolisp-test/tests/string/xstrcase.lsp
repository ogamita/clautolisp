;;;; tests/string/xstrcase.lsp -- XSTRCASE

(deftest "xstrcase-upper"
  '((operator . "XSTRCASE") (area . "string") (profile . strict))
  '(xstrcase "abc") "ABC")

(deftest "xstrcase-lower-flag"
  '((operator . "XSTRCASE") (area . "string") (profile . strict))
  '(xstrcase "ABC" T) "abc")

(deftest "xstrcase-empty"
  '((operator . "XSTRCASE") (area . "string") (profile . strict))
  '(xstrcase "") "")
