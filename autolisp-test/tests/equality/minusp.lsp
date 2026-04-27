;;;; tests/equality/minusp.lsp -- MINUSP

(deftest "minusp-of-negative-int"
  '((operator . "MINUSP") (area . "equality") (profile . strict))
  '(minusp -3)
  T)

(deftest "minusp-of-zero"
  '((operator . "MINUSP") (area . "equality") (profile . strict))
  '(minusp 0)
  nil)

(deftest "minusp-of-positive-int"
  '((operator . "MINUSP") (area . "equality") (profile . strict))
  '(minusp 5)
  nil)

(deftest "minusp-of-negative-float"
  '((operator . "MINUSP") (area . "equality") (profile . strict))
  '(minusp -0.5)
  T)

(deftest "minusp-of-zero-float"
  '((operator . "MINUSP") (area . "equality") (profile . strict))
  '(minusp 0.0)
  nil)
