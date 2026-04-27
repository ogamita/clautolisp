;;;; tests/list/vl-sort.lsp -- VL-SORT and VL-SORT-I

(deftest "vl-sort-numeric-ascending"
  '((operator . "VL-SORT") (area . "list") (profile . strict))
  '(vl-sort '(3 1 4 1 5 9 2 6) '<)
  '(1 1 2 3 4 5 6 9))

(deftest "vl-sort-numeric-descending"
  '((operator . "VL-SORT") (area . "list") (profile . strict))
  '(vl-sort '(1 2 3) '>)
  '(3 2 1))

(deftest "vl-sort-empty"
  '((operator . "VL-SORT") (area . "list") (profile . strict))
  '(vl-sort nil '<)
  nil)

(deftest "vl-sort-singleton"
  '((operator . "VL-SORT") (area . "list") (profile . strict))
  '(vl-sort '(42) '<)
  '(42))

(deftest "vl-sort-i-returns-index-list"
  '((operator . "VL-SORT-I") (area . "list") (profile . strict))
  '(vl-sort-i '(30 10 20) '<)
  '(1 2 0))

(deftest "vl-sort-i-empty"
  '((operator . "VL-SORT-I") (area . "list") (profile . strict))
  '(vl-sort-i nil '<)
  nil)
