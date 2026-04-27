;;;; tests/geometry/inters.lsp -- INTERS

(deftest-pred "inters-perpendicular-segments-cross"
  '((operator . "INTERS") (area . "geometry") (profile . strict))
  '(inters '(0 0) '(2 2) '(0 2) '(2 0))
  '(and (listp *result*)
        (< (abs (- (car *result*) 1.0)) 0.0001)
        (< (abs (- (cadr *result*) 1.0)) 0.0001)))

(deftest "inters-parallel-no-intersection"
  '((operator . "INTERS") (area . "geometry") (profile . strict))
  '(inters '(0 0) '(2 0) '(0 1) '(2 1))
  nil)

(deftest "inters-with-onseg-flag-nil-uses-extended-lines"
  '((operator . "INTERS") (area . "geometry") (profile . strict))
  '(listp (inters '(0 0) '(1 1) '(2 0) '(3 -1) nil))
  T)
