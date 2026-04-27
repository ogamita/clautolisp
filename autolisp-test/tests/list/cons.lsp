;;;; tests/list/cons.lsp -- CONS

(deftest "cons-builds-pair"
  '((operator . "CONS") (area . "list") (profile . strict))
  '(cons 1 nil)
  '(1))

(deftest "cons-prepends-to-list"
  '((operator . "CONS") (area . "list") (profile . strict))
  '(cons 1 '(2 3))
  '(1 2 3))

(deftest "cons-creates-dotted-pair"
  '((operator . "CONS") (area . "list") (profile . strict))
  '(cons 1 2)
  '(1 . 2))

(deftest "cons-of-list-as-car"
  '((operator . "CONS") (area . "list") (profile . strict))
  '(cons '(a) '(b))
  '((a) b))

(deftest "cons-of-symbol-and-list"
  '((operator . "CONS") (area . "list") (profile . strict))
  '(cons 'a '(b c))
  '(a b c))

(deftest "cons-nil-into-list"
  '((operator . "CONS") (area . "list") (profile . strict))
  '(cons nil '(a))
  '(nil a))
