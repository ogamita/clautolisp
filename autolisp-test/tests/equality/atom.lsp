;;;; tests/equality/atom.lsp -- ATOM

(deftest "atom-of-symbol"
  '((operator . "ATOM") (area . "equality") (profile . strict))
  '(atom 'a)
  T)

(deftest "atom-of-integer"
  '((operator . "ATOM") (area . "equality") (profile . strict))
  '(atom 42)
  T)

(deftest "atom-of-string"
  '((operator . "ATOM") (area . "equality") (profile . strict))
  '(atom "x")
  T)

(deftest "atom-of-nil"
  '((operator . "ATOM") (area . "equality") (profile . strict))
  '(atom nil)
  T)

(deftest "atom-of-list-is-nil"
  '((operator . "ATOM") (area . "equality") (profile . strict))
  '(atom '(a))
  nil)

(deftest "atom-of-cons-pair-is-nil"
  '((operator . "ATOM") (area . "equality") (profile . strict))
  '(atom (cons 1 2))
  nil)
