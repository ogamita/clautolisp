;;;; tests/list/vl-consp.lsp -- VL-CONSP

(deftest "vl-consp-of-non-empty-list"
  '((operator . "VL-CONSP") (area . "list") (profile . strict))
  '(vl-consp '(a))
  T)

(deftest "vl-consp-of-empty-list-is-nil"
  '((operator . "VL-CONSP") (area . "list") (profile . strict))
  '(vl-consp nil)
  nil)

(deftest "vl-consp-of-symbol-is-nil"
  '((operator . "VL-CONSP") (area . "list") (profile . strict))
  '(vl-consp 'foo)
  nil)

(deftest "vl-consp-of-integer-is-nil"
  '((operator . "VL-CONSP") (area . "list") (profile . strict))
  '(vl-consp 42)
  nil)

(deftest "vl-consp-of-dotted-pair"
  '((operator . "VL-CONSP") (area . "list") (profile . strict))
  '(vl-consp (cons 1 2))
  T)
