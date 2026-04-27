;;;; tests/special-forms/function.lsp -- FUNCTION special form

(deftest "function-named-symbol-resolves-to-function"
  '((operator . "FUNCTION") (area . "special-forms") (profile . strict))
  '(progn (defun fn-target (x) (+ x 1))
          (apply (function fn-target) '(10)))
  11)

(deftest "function-of-builtin"
  '((operator . "FUNCTION") (area . "special-forms") (profile . strict))
  '(apply (function +) '(1 2 3))
  6)

(deftest "function-of-lambda"
  '((operator . "FUNCTION") (area . "special-forms") (profile . strict))
  '(apply (function (lambda (x) (* x 10))) '(7))
  70)

(deftest "function-mapcar-with-builtin"
  '((operator . "FUNCTION") (area . "special-forms") (profile . strict))
  '(mapcar (function 1+) '(1 2 3))
  '(2 3 4))
