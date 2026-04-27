;;;; tests/list/vl-remove-if.lsp -- VL-REMOVE-IF / VL-REMOVE-IF-NOT

(deftest "vl-remove-if-removes-numbers"
  '((operator . "VL-REMOVE-IF") (area . "list") (profile . strict))
  '(vl-remove-if 'numberp '(1 a 2 b 3))
  '(a b))

(deftest "vl-remove-if-keeps-all-when-none-match"
  '((operator . "VL-REMOVE-IF") (area . "list") (profile . strict))
  '(vl-remove-if 'numberp '(a b c))
  '(a b c))

(deftest "vl-remove-if-empty"
  '((operator . "VL-REMOVE-IF") (area . "list") (profile . strict))
  '(vl-remove-if 'numberp nil)
  nil)

(deftest "vl-remove-if-not-keeps-numbers"
  '((operator . "VL-REMOVE-IF-NOT") (area . "list") (profile . strict))
  '(vl-remove-if-not 'numberp '(1 a 2 b 3))
  '(1 2 3))

(deftest "vl-remove-if-not-empty"
  '((operator . "VL-REMOVE-IF-NOT") (area . "list") (profile . strict))
  '(vl-remove-if-not 'numberp nil)
  nil)
