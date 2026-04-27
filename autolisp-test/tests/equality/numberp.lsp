;;;; tests/equality/numberp.lsp -- NUMBERP

(deftest "numberp-of-integer"
  '((operator . "NUMBERP") (area . "equality") (profile . strict))
  '(numberp 7)
  T)

(deftest "numberp-of-real"
  '((operator . "NUMBERP") (area . "equality") (profile . strict))
  '(numberp 3.14)
  T)

(deftest "numberp-of-zero"
  '((operator . "NUMBERP") (area . "equality") (profile . strict))
  '(numberp 0)
  T)

(deftest "numberp-of-string-nil"
  '((operator . "NUMBERP") (area . "equality") (profile . strict))
  '(numberp "1")
  nil)

(deftest "numberp-of-symbol-nil"
  '((operator . "NUMBERP") (area . "equality") (profile . strict))
  '(numberp 'a)
  nil)

(deftest "numberp-of-nil"
  '((operator . "NUMBERP") (area . "equality") (profile . strict))
  '(numberp nil)
  nil)
