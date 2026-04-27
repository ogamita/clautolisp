;;;; tests/list/vl-list-length.lsp -- VL-LIST-LENGTH

(deftest "vl-list-length-of-empty-is-zero"
  '((operator . "VL-LIST-LENGTH") (area . "list") (profile . strict))
  '(vl-list-length nil)
  0)

(deftest "vl-list-length-of-three"
  '((operator . "VL-LIST-LENGTH") (area . "list") (profile . strict))
  '(vl-list-length '(a b c))
  3)

(deftest "vl-list-length-of-singleton"
  '((operator . "VL-LIST-LENGTH") (area . "list") (profile . strict))
  '(vl-list-length '(only))
  1)

(deftest "vl-list-length-improper-list-returns-nil"
  '((operator . "VL-LIST-LENGTH") (area . "list") (profile . strict))
  '(vl-list-length (cons 1 2))
  nil)
