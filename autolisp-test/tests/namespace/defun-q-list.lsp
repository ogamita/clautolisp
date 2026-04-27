;;;; tests/namespace/defun-q-list.lsp -- DEFUN-Q-LIST-REF / DEFUN-Q-LIST-SET

(deftest "defun-q-list-ref-after-defun-q"
  '((operator . "DEFUN-Q-LIST-REF") (area . "namespace") (profile . strict))
  '(progn (defun-q dql-fn (x) (* 2 x))
          (eq (type (defun-q-list-ref 'dql-fn)) 'list))
  T)

(deftest "defun-q-list-set-installs-callable"
  '((operator . "DEFUN-Q-LIST-SET") (area . "namespace") (profile . strict))
  '(progn (defun-q-list-set 'dql-set-fn '((x) (+ x 1)))
          (dql-set-fn 41))
  42)
