(in-package #:clautolisp.autolisp-file-compat.tests)

(defun run-all-tests ()
  (let ((result (run 'autolisp-file-compat-suite)))
    (explain! result)
    (unless (results-status result)
      (error "autolisp-file-compat tests failed."))
    t))
