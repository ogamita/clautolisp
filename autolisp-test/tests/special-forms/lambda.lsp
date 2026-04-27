;;;; tests/special-forms/lambda.lsp -- LAMBDA special form

(deftest "lambda-zero-args"
  '((operator . "LAMBDA") (area . "special-forms") (profile . strict))
  '((lambda () 42))
  42)

(deftest "lambda-single-arg"
  '((operator . "LAMBDA") (area . "special-forms") (profile . strict))
  '((lambda (x) (* x x)) 5)
  25)

(deftest "lambda-two-args"
  '((operator . "LAMBDA") (area . "special-forms") (profile . strict))
  '((lambda (a b) (+ a b)) 3 4)
  7)

(deftest "lambda-multi-form-body-returns-last"
  '((operator . "LAMBDA") (area . "special-forms") (profile . strict))
  '((lambda (x) 1 2 (+ x 10)) 5)
  15)

(deftest "lambda-with-local-variables"
  '((operator . "LAMBDA") (area . "special-forms") (profile . strict))
  '((lambda (x / tmp)
      (setq tmp (* x x))
      (+ tmp 1)) 4)
  17)

(deftest "lambda-applied-to-list-via-mapcar"
  '((operator . "LAMBDA") (area . "special-forms") (profile . strict))
  '(mapcar '(lambda (n) (* 2 n)) '(1 2 3))
  '(2 4 6))

(deftest "lambda-as-function-value"
  '((operator . "LAMBDA") (area . "special-forms") (profile . strict))
  '(progn (setq lam-fn (lambda (x) (+ x 100)))
          (apply lam-fn '(7)))
  107)
