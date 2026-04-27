;;;; tests/list/vl-list-star.lsp -- VL-LIST*

(deftest "vl-list-star-builds-dotted-pair"
  '((operator . "VL-LIST*") (area . "list") (profile . strict))
  '(vl-list* 1 2)
  '(1 . 2))

(deftest "vl-list-star-with-list-tail-flattens"
  '((operator . "VL-LIST*") (area . "list") (profile . strict))
  '(vl-list* 1 2 '(3 4))
  '(1 2 3 4))

(deftest "vl-list-star-single-arg"
  '((operator . "VL-LIST*") (area . "list") (profile . strict))
  '(vl-list* 42)
  42)

(deftest "vl-list-star-two-with-nil-tail"
  '((operator . "VL-LIST*") (area . "list") (profile . strict))
  '(vl-list* 'a nil)
  '(a))

(deftest "vl-list-star-three-then-list"
  '((operator . "VL-LIST*") (area . "list") (profile . strict))
  '(vl-list* 'a 'b '(c d))
  '(a b c d))
