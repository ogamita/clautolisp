;;;; tests/geometry/angle.lsp -- ANGLE

(deftest "angle-positive-x"
  '((operator . "ANGLE") (area . "geometry") (profile . strict))
  '(angle '(0 0) '(1 0))
  0.0)

(deftest-pred "angle-positive-y-is-pi-half"
  '((operator . "ANGLE") (area . "geometry") (profile . strict))
  '(angle '(0 0) '(0 1))
  '(< (abs (- *result* (/ pi 2))) 0.00001))

(deftest-pred "angle-negative-x-is-pi"
  '((operator . "ANGLE") (area . "geometry") (profile . strict))
  '(angle '(0 0) '(-1 0))
  '(< (abs (- *result* pi)) 0.00001))

(deftest-pred "angle-45-degrees"
  '((operator . "ANGLE") (area . "geometry") (profile . strict))
  '(angle '(0 0) '(1 1))
  '(< (abs (- *result* (/ pi 4))) 0.00001))
