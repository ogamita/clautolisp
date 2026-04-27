;;;; tests/equality/equal.lsp -- EQUAL

(deftest "equal-same-integer"
  '((operator . "EQUAL") (area . "equality") (profile . strict))
  '(equal 7 7)
  T)

(deftest "equal-same-string"
  '((operator . "EQUAL") (area . "equality") (profile . strict))
  '(equal "abc" "abc")
  T)

(deftest "equal-different-strings"
  '((operator . "EQUAL") (area . "equality") (profile . strict))
  '(equal "abc" "def")
  nil)

(deftest "equal-list-structural-match"
  '((operator . "EQUAL") (area . "equality") (profile . strict))
  '(equal '(1 (2 3)) '(1 (2 3)))
  T)

(deftest "equal-list-different"
  '((operator . "EQUAL") (area . "equality") (profile . strict))
  '(equal '(1 2) '(1 2 3))
  nil)

(deftest "equal-real-with-fuzz-tolerates-difference"
  '((operator . "EQUAL") (area . "equality") (profile . strict))
  '(equal 1.0 1.001 0.01)
  T)

(deftest "equal-real-without-fuzz-rejects-difference"
  '((operator . "EQUAL") (area . "equality") (profile . strict))
  '(equal 1.0 1.001)
  nil)

(deftest "equal-nil-equal-nil"
  '((operator . "EQUAL") (area . "equality") (profile . strict))
  '(equal nil nil)
  T)
