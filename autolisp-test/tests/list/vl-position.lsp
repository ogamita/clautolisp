;;;; tests/list/vl-position.lsp -- VL-POSITION

(deftest "vl-position-found-at-0"
  '((operator . "VL-POSITION") (area . "list") (profile . strict))
  '(vl-position 'a '(a b c))
  0)

(deftest "vl-position-found-at-2"
  '((operator . "VL-POSITION") (area . "list") (profile . strict))
  '(vl-position 'c '(a b c d))
  2)

(deftest "vl-position-not-found-returns-nil"
  '((operator . "VL-POSITION") (area . "list") (profile . strict))
  '(vl-position 'z '(a b c))
  nil)

(deftest "vl-position-empty-list"
  '((operator . "VL-POSITION") (area . "list") (profile . strict))
  '(vl-position 'a nil)
  nil)

(deftest "vl-position-uses-equal"
  '((operator . "VL-POSITION") (area . "list") (profile . strict))
  '(vl-position "x" '("a" "x" "c"))
  1)
