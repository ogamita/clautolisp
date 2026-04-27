;;;; tests/list/vl-every.lsp -- VL-EVERY

(deftest "vl-every-all-true"
  '((operator . "VL-EVERY") (area . "list") (profile . strict))
  '(vl-every 'numberp '(1 2 3))
  T)

(deftest "vl-every-one-false"
  '((operator . "VL-EVERY") (area . "list") (profile . strict))
  '(vl-every 'numberp '(1 a 3))
  nil)

(deftest "vl-every-empty-list-is-T"
  '((operator . "VL-EVERY") (area . "list") (profile . strict))
  '(vl-every 'numberp nil)
  T)

(deftest "vl-every-with-lambda-and-two-lists"
  '((operator . "VL-EVERY") (area . "list") (profile . strict))
  '(vl-every '(lambda (a b) (< a b)) '(1 2 3) '(2 3 4))
  T)

(deftest "vl-every-with-lambda-fails-on-pair"
  '((operator . "VL-EVERY") (area . "list") (profile . strict))
  '(vl-every '(lambda (a b) (< a b)) '(1 9 3) '(2 3 4))
  nil)
