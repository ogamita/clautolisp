;;;; tests/string/itoa.lsp -- ITOA

(deftest "itoa-positive"
  '((operator . "ITOA") (area . "string") (profile . strict))
  '(itoa 17) "17")

(deftest "itoa-negative"
  '((operator . "ITOA") (area . "string") (profile . strict))
  '(itoa -42) "-42")

(deftest "itoa-zero"
  '((operator . "ITOA") (area . "string") (profile . strict))
  '(itoa 0) "0")

(deftest "itoa-large"
  '((operator . "ITOA") (area . "string") (profile . strict))
  '(itoa 1000000) "1000000")
