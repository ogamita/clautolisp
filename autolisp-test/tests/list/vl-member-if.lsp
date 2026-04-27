;;;; tests/list/vl-member-if.lsp -- VL-MEMBER-IF / VL-MEMBER-IF-NOT

(deftest "vl-member-if-finds-from-pivot"
  '((operator . "VL-MEMBER-IF") (area . "list") (profile . strict))
  '(vl-member-if 'numberp '(a b 7 c 8))
  '(7 c 8))

(deftest "vl-member-if-no-match"
  '((operator . "VL-MEMBER-IF") (area . "list") (profile . strict))
  '(vl-member-if 'numberp '(a b c))
  nil)

(deftest "vl-member-if-empty"
  '((operator . "VL-MEMBER-IF") (area . "list") (profile . strict))
  '(vl-member-if 'numberp nil)
  nil)

(deftest "vl-member-if-not-finds-non-match"
  '((operator . "VL-MEMBER-IF-NOT") (area . "list") (profile . strict))
  '(vl-member-if-not 'numberp '(1 2 a 3))
  '(a 3))

(deftest "vl-member-if-not-all-match"
  '((operator . "VL-MEMBER-IF-NOT") (area . "list") (profile . strict))
  '(vl-member-if-not 'numberp '(1 2 3))
  nil)
