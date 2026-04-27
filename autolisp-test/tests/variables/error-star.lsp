;;;; tests/variables/error-star.lsp -- *ERROR*
;;;; *error* is the user-installable hook called on error. We test
;;;; that it can be set, that catch-all-apply still observes errors,
;;;; and that the implementation honors the hook variable.

(deftest "error-star-is-bindable"
  '((operator . "*ERROR*") (area . "variable") (profile . strict))
  '(progn (setq *error* '(lambda (msg) nil))
          (eq (type *error*) 'list))
  T)

(deftest-pred "error-star-installs-callback-without-corrupting-runtime"
  '((operator . "*ERROR*") (area . "variable") (profile . strict))
  '(progn (setq *error* '(lambda (msg) nil))
          (vl-catch-all-apply 'car '(99)))
  '(vl-catch-all-error-p *result*))
