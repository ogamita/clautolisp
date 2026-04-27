;;;; tests/reader/dotted-pair.lsp
;;;;
;;;; A literal dotted pair as a form would be read as a function
;;;; call by (eval), so the construction-style tests have to quote
;;;; them. The accessor tests already use proper function calls.

(deftest "dotted-pair-construction"
  '((operator . "Dotted Pair") (area . "reader") (profile . strict))
  ''(1 . 2) '(1 . 2))

(deftest "dotted-pair-car"
  '((operator . "Dotted Pair") (area . "reader") (profile . strict))
  '(car '(1 . 2)) 1)

(deftest "dotted-pair-cdr"
  '((operator . "Dotted Pair") (area . "reader") (profile . strict))
  '(cdr '(1 . 2)) 2)

(deftest "dotted-pair-improper-list"
  '((operator . "Dotted Pair") (area . "reader") (profile . strict))
  ''(1 2 . 3) '(1 2 . 3))
