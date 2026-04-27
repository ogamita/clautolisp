;;;; tests/list/car.lsp -- CAR

(deftest "car-of-list"
  '((operator . "CAR") (area . "list") (profile . strict))
  '(car '(1 2 3))
  1)

(deftest "car-of-singleton"
  '((operator . "CAR") (area . "list") (profile . strict))
  '(car '(only))
  'only)

(deftest "car-of-nested"
  '((operator . "CAR") (area . "list") (profile . strict))
  '(car '((a b) c))
  '(a b))

(deftest "car-of-nil-is-nil"
  '((operator . "CAR") (area . "list") (profile . strict))
  '(car nil)
  nil)

(deftest "car-of-dotted-pair"
  '((operator . "CAR") (area . "list") (profile . strict))
  '(car '(1 . 2))
  1)

(deftest-error "car-of-non-list-signals-error"
  '((operator . "CAR") (area . "list") (profile . strict))
  '(car 42)
  'argument)
