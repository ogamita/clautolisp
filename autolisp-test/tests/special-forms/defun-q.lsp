;;;; tests/special-forms/defun-q.lsp -- DEFUN-Q special form
;;;;
;;;; defun-q preserves the body as a list and binds the function with
;;;; the same calling semantics as defun. The list-form is observable
;;;; through defun-q-list-ref.

(deftest "defun-q-callable-like-defun"
  '((operator . "DEFUN-Q") (area . "special-forms") (profile . strict))
  '(progn (defun-q dq-square (x) (* x x))
          (dq-square 5))
  25)

(deftest "defun-q-recursive"
  '((operator . "DEFUN-Q") (area . "special-forms") (profile . strict))
  '(progn (defun-q dq-fact (n)
            (if (<= n 1) 1 (* n (dq-fact (- n 1)))))
          (dq-fact 4))
  24)

(deftest "defun-q-list-ref-returns-list-form"
  '((operator . "DEFUN-Q") (area . "special-forms") (profile . strict))
  '(progn (defun-q dq-double (x) (* 2 x))
          (eq (type (defun-q-list-ref 'dq-double)) 'list))
  T)

(deftest "defun-q-list-ref-includes-arglist"
  '((operator . "DEFUN-Q") (area . "special-forms") (profile . strict))
  '(progn (defun-q dq-shape (a b) (list a b))
          (car (defun-q-list-ref 'dq-shape)))
  '(a b))
