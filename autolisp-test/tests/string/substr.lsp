;;;; tests/string/substr.lsp -- SUBSTR
;;;; AutoLISP indices are 1-based.

(deftest "substr-from-start"
  '((operator . "SUBSTR") (area . "string") (profile . strict))
  '(substr "abcdef" 1 3) "abc")

(deftest "substr-middle"
  '((operator . "SUBSTR") (area . "string") (profile . strict))
  '(substr "abcdef" 3 2) "cd")

(deftest "substr-from-position-to-end"
  '((operator . "SUBSTR") (area . "string") (profile . strict))
  '(substr "abcdef" 4) "def")

(deftest "substr-position-equals-length-plus-one"
  '((operator . "SUBSTR") (area . "string") (profile . strict))
  '(substr "abc" 4) "")

(deftest "substr-length-zero"
  '((operator . "SUBSTR") (area . "string") (profile . strict))
  '(substr "abcdef" 2 0) "")

(deftest "substr-length-larger-than-rest"
  '((operator . "SUBSTR") (area . "string") (profile . strict))
  '(substr "abc" 2 100) "bc")
