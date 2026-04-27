;;;; tests/list/last.lsp -- LAST

(deftest "last-of-three-list"
  '((operator . "LAST") (area . "list") (profile . strict))
  '(last '(1 2 3))
  3)

(deftest "last-of-singleton"
  '((operator . "LAST") (area . "list") (profile . strict))
  '(last '(only))
  'only)

(deftest "last-of-nested"
  '((operator . "LAST") (area . "list") (profile . strict))
  '(last '((a b) (c d)))
  '(c d))

(deftest "last-of-empty-is-nil"
  '((operator . "LAST") (area . "list") (profile . strict))
  '(last nil)
  nil)

(deftest "last-of-dotted-pair-tail"
  '((operator . "LAST") (area . "list") (profile . strict))
  '(last '(a b . c))
  'c)
