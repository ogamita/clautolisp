;;;; tests/list/mapcar.lsp -- MAPCAR

(deftest "mapcar-empty-list"
  '((operator . "MAPCAR") (area . "list") (profile . strict))
  '(mapcar '1+ nil)
  nil)

(deftest "mapcar-single-list-with-1+"
  '((operator . "MAPCAR") (area . "list") (profile . strict))
  '(mapcar '1+ '(1 2 3))
  '(2 3 4))

(deftest "mapcar-single-list-with-lambda"
  '((operator . "MAPCAR") (area . "list") (profile . strict))
  '(mapcar '(lambda (x) (* x x)) '(1 2 3))
  '(1 4 9))

(deftest "mapcar-two-lists-with-plus"
  '((operator . "MAPCAR") (area . "list") (profile . strict))
  '(mapcar '+ '(1 2 3) '(10 20 30))
  '(11 22 33))

(deftest "mapcar-three-lists"
  '((operator . "MAPCAR") (area . "list") (profile . strict))
  '(mapcar '(lambda (a b c) (list a b c))
           '(1 2)
           '(10 20)
           '(100 200))
  '((1 10 100) (2 20 200)))

(deftest "mapcar-shortest-list-stops"
  '((operator . "MAPCAR") (area . "list") (profile . strict))
  '(mapcar 'list '(1 2 3) '(a b))
  '((1 a) (2 b)))
