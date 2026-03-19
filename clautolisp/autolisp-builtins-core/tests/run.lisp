(in-package #:clautolisp.autolisp-builtins-core.tests)

(defun run-all-tests ()
  (let ((result (run 'autolisp-builtins-core-suite)))
    (explain! result)
    (unless (results-status result)
      (error "autolisp-builtins-core tests failed."))
    t))
