;;;; tests/special-forms/defun.lsp -- DEFUN special form

(deftest "defun-zero-arg"
  '((operator . "DEFUN") (area . "special-forms") (profile . strict))
  '(progn (defun defun-test-zero () 7)
          (defun-test-zero))
  7)

(deftest "defun-single-arg"
  '((operator . "DEFUN") (area . "special-forms") (profile . strict))
  '(progn (defun defun-test-square (x) (* x x))
          (defun-test-square 6))
  36)

(deftest "defun-multi-arg"
  '((operator . "DEFUN") (area . "special-forms") (profile . strict))
  '(progn (defun defun-test-mul (a b c) (* a b c))
          (defun-test-mul 2 3 4))
  24)

(deftest "defun-local-variables-via-slash"
  '((operator . "DEFUN") (area . "special-forms") (profile . strict))
  '(progn (defun defun-test-local (x / sq) (setq sq (* x x)) (+ sq 1))
          (defun-test-local 3))
  10)

(deftest "defun-multi-form-body-returns-last"
  '((operator . "DEFUN") (area . "special-forms") (profile . strict))
  '(progn (defun defun-test-multi (n) 1 2 (+ n 99))
          (defun-test-multi 1))
  100)

(deftest "defun-recursive"
  '((operator . "DEFUN") (area . "special-forms") (profile . strict))
  '(progn (defun defun-test-fact (n)
            (if (<= n 1) 1 (* n (defun-test-fact (- n 1)))))
          (defun-test-fact 5))
  120)

(deftest "defun-redefinition-replaces-previous"
  '((operator . "DEFUN") (area . "special-forms") (profile . strict))
  '(progn (defun defun-test-redef () 1)
          (defun defun-test-redef () 2)
          (defun-test-redef))
  2)

(deftest "defun-returns-symbol-of-function-name"
  '((operator . "DEFUN") (area . "special-forms") (profile . strict))
  '(defun defun-test-returns-name () nil)
  'defun-test-returns-name)

(deftest "defun-c:command-prefix-callable"
  '((operator . "DEFUN") (area . "special-forms") (profile . strict))
  '(progn (defun c:defun-test-cmd () 'cmd-was-run)
          (c:defun-test-cmd))
  'cmd-was-run)
