;;;; tests/equality/null.lsp -- NULL

(deftest "null-of-nil"
  '((operator . "NULL") (area . "equality") (profile . strict))
  '(null nil)
  T)

(deftest "null-of-empty-list"
  '((operator . "NULL") (area . "equality") (profile . strict))
  '(null (list))
  T)

(deftest "null-of-non-nil-symbol"
  '((operator . "NULL") (area . "equality") (profile . strict))
  '(null 'a)
  nil)

(deftest "null-of-zero-is-nil"
  '((operator . "NULL") (area . "equality") (profile . strict))
  '(null 0)
  nil)

(deftest "null-of-empty-string-is-nil"
  '((operator . "NULL") (area . "equality") (profile . strict))
  '(null "")
  nil)

(deftest "null-of-list-is-nil"
  '((operator . "NULL") (area . "equality") (profile . strict))
  '(null '(a))
  nil)
