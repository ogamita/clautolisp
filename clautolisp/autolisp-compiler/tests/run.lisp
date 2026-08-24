(in-package #:clautolisp.autolisp-compiler.tests)

(defun run-all-tests ()
  (let ((result (run 'autolisp-compiler-suite)))
    (explain! result)
    (unless (results-status result)
      (error "autolisp-compiler tests failed."))
    t))
