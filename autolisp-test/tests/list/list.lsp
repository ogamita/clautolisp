;;;; tests/list/list.lsp -- LIST

(deftest "list-empty-returns-nil"
  '((operator . "LIST") (area . "list") (profile . strict))
  '(list)
  nil)

(deftest "list-single"
  '((operator . "LIST") (area . "list") (profile . strict))
  '(list 1)
  '(1))

(deftest "list-three"
  '((operator . "LIST") (area . "list") (profile . strict))
  '(list 1 2 3)
  '(1 2 3))

(deftest "list-mixed-types"
  '((operator . "LIST") (area . "list") (profile . strict))
  '(list 1 "two" 'three nil)
  '(1 "two" three nil))

(deftest "list-evaluates-arguments"
  '((operator . "LIST") (area . "list") (profile . strict))
  '(list (+ 1 1) (* 2 3))
  '(2 6))

(deftest "list-of-lists"
  '((operator . "LIST") (area . "list") (profile . strict))
  '(list '(a b) '(c d))
  '((a b) (c d)))
