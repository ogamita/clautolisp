;;;; tests/list/length.lsp -- LENGTH

(deftest "length-empty-list-is-zero"
  '((operator . "LENGTH") (area . "list") (profile . strict))
  '(length nil)
  0)

(deftest "length-single-element"
  '((operator . "LENGTH") (area . "list") (profile . strict))
  '(length '(x))
  1)

(deftest "length-three-elements"
  '((operator . "LENGTH") (area . "list") (profile . strict))
  '(length '(a b c))
  3)

(deftest "length-of-nested-counts-top"
  '((operator . "LENGTH") (area . "list") (profile . strict))
  '(length '((a b) (c d) (e f)))
  3)

(deftest "length-after-cons"
  '((operator . "LENGTH") (area . "list") (profile . strict))
  '(length (cons 'x '(1 2 3)))
  4)
