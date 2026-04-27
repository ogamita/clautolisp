;;;; tests/reader/dotted-pair.lsp

(deftest "dotted-pair-construction"
  '((operator . "Dotted Pair") (area . "reader") (profile . strict))
  '(1 . 2) '(1 . 2))

(deftest "dotted-pair-car"
  '((operator . "Dotted Pair") (area . "reader") (profile . strict))
  '(car '(1 . 2)) 1)

(deftest "dotted-pair-cdr"
  '((operator . "Dotted Pair") (area . "reader") (profile . strict))
  '(cdr '(1 . 2)) 2)

(deftest "dotted-pair-improper-list"
  '((operator . "Dotted Pair") (area . "reader") (profile . strict))
  '(1 2 . 3) '(1 2 . 3))
