;;;; tests/geometry/distance.lsp -- DISTANCE

(deftest "distance-2d-zero"
  '((operator . "DISTANCE") (area . "geometry") (profile . strict))
  '(distance '(0 0) '(0 0))
  0.0)

(deftest "distance-2d-3-4-5"
  '((operator . "DISTANCE") (area . "geometry") (profile . strict))
  '(distance '(0 0) '(3 4))
  5.0)

(deftest "distance-3d"
  '((operator . "DISTANCE") (area . "geometry") (profile . strict))
  '(distance '(0 0 0) '(2 2 1))
  3.0)

(deftest-pred "distance-real-precision"
  '((operator . "DISTANCE") (area . "geometry") (profile . strict))
  '(distance '(0 0) '(1 1))
  '(< (abs (- *result* 1.41421356)) 0.00001))
