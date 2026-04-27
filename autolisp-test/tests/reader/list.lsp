;;;; tests/reader/list.lsp

(deftest "list-empty"
  '((operator . "List") (area . "reader") (profile . strict))
  '() nil)

(deftest "list-single"
  '((operator . "List") (area . "reader") (profile . strict))
  '(1) '(1))

(deftest "list-three-elements"
  '((operator . "List") (area . "reader") (profile . strict))
  '(1 2 3) '(1 2 3))

(deftest "list-mixed-types"
  '((operator . "List") (area . "reader") (profile . strict))
  '(1 "two" three nil) '(1 "two" three nil))

(deftest "list-nested"
  '((operator . "List") (area . "reader") (profile . strict))
  '((a) (b c) (d (e f))) '((a) (b c) (d (e f))))
