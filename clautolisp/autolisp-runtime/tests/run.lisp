(in-package #:clautolisp.autolisp-runtime.tests)

(defun run-all-tests ()
  (let ((result (run 'autolisp-runtime-suite)))
    (explain! result)
    (unless (results-status result)
      (error "autolisp-runtime tests failed."))
    t))
