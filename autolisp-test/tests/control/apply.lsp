;;;; tests/control/apply.lsp -- APPLY

(deftest "apply-of-plus-empty"
  '((operator . "APPLY") (area . "control") (profile . strict))
  '(apply '+ nil) 0)

(deftest "apply-of-plus-list"
  '((operator . "APPLY") (area . "control") (profile . strict))
  '(apply '+ '(1 2 3 4)) 10)

(deftest "apply-of-times-list"
  '((operator . "APPLY") (area . "control") (profile . strict))
  '(apply '* '(2 3 4)) 24)

(deftest "apply-of-list-builtin"
  '((operator . "APPLY") (area . "control") (profile . strict))
  '(apply 'list '(a b c)) '(a b c))

(deftest "apply-of-lambda"
  '((operator . "APPLY") (area . "control") (profile . strict))
  '(apply '(lambda (x y) (* x y)) '(6 7)) 42)
