;;;; tests/list/reverse.lsp -- REVERSE

(deftest "reverse-empty-list"
  '((operator . "REVERSE") (area . "list") (profile . strict))
  '(reverse nil)
  nil)

(deftest "reverse-singleton"
  '((operator . "REVERSE") (area . "list") (profile . strict))
  '(reverse '(x))
  '(x))

(deftest "reverse-three-elements"
  '((operator . "REVERSE") (area . "list") (profile . strict))
  '(reverse '(1 2 3))
  '(3 2 1))

(deftest "reverse-shallow-only"
  '((operator . "REVERSE") (area . "list") (profile . strict))
  '(reverse '((a b) (c d)))
  '((c d) (a b)))

(deftest "reverse-of-reverse-identity"
  '((operator . "REVERSE") (area . "list") (profile . strict))
  '(reverse (reverse '(1 2 3 4 5)))
  '(1 2 3 4 5))
