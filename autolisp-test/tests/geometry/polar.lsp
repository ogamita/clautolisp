;;;; tests/geometry/polar.lsp -- POLAR

(deftest-pred "polar-along-x"
  '((operator . "POLAR") (area . "geometry") (profile . strict))
  '(polar '(0 0) 0.0 5.0)
  '(and (< (abs (- (car *result*) 5.0)) 0.0001)
        (< (abs (cadr *result*)) 0.0001)))

(deftest-pred "polar-along-y"
  '((operator . "POLAR") (area . "geometry") (profile . strict))
  '(polar '(0 0) (/ pi 2) 3.0)
  '(and (< (abs (car *result*)) 0.0001)
        (< (abs (- (cadr *result*) 3.0)) 0.0001)))

(deftest-pred "polar-base-offset"
  '((operator . "POLAR") (area . "geometry") (profile . strict))
  '(polar '(10 20) 0.0 5.0)
  '(and (< (abs (- (car *result*) 15.0)) 0.0001)
        (< (abs (- (cadr *result*) 20.0)) 0.0001)))
