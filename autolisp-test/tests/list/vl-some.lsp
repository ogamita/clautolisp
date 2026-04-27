;;;; tests/list/vl-some.lsp -- VL-SOME

(deftest "vl-some-true-on-first"
  '((operator . "VL-SOME") (area . "list") (profile . strict))
  '(vl-some 'numberp '(1 a b))
  T)

(deftest "vl-some-true-in-middle"
  '((operator . "VL-SOME") (area . "list") (profile . strict))
  '(vl-some 'numberp '(a 2 b))
  T)

(deftest "vl-some-all-false"
  '((operator . "VL-SOME") (area . "list") (profile . strict))
  '(vl-some 'numberp '(a b c))
  nil)

(deftest "vl-some-empty-is-nil"
  '((operator . "VL-SOME") (area . "list") (profile . strict))
  '(vl-some 'numberp nil)
  nil)

(deftest "vl-some-with-two-lists"
  '((operator . "VL-SOME") (area . "list") (profile . strict))
  '(vl-some '(lambda (a b) (> a b)) '(1 2 9) '(3 4 5))
  T)
