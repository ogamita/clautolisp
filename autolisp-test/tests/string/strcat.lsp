;;;; tests/string/strcat.lsp -- STRCAT

(deftest "strcat-zero-args"
  '((operator . "STRCAT") (area . "string") (profile . strict))
  '(strcat) "")

(deftest "strcat-one-arg"
  '((operator . "STRCAT") (area . "string") (profile . strict))
  '(strcat "hello") "hello")

(deftest "strcat-two-args"
  '((operator . "STRCAT") (area . "string") (profile . strict))
  '(strcat "foo" "bar") "foobar")

(deftest "strcat-many-args"
  '((operator . "STRCAT") (area . "string") (profile . strict))
  '(strcat "a" "b" "c" "d" "e") "abcde")

(deftest "strcat-with-empty"
  '((operator . "STRCAT") (area . "string") (profile . strict))
  '(strcat "x" "" "y") "xy")

(deftest "strcat-only-empties"
  '((operator . "STRCAT") (area . "string") (profile . strict))
  '(strcat "" "" "") "")
