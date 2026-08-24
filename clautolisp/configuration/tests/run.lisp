(in-package #:clautolisp.configuration.tests)

(defun run-all-tests ()
  (let ((result (run 'configuration-suite)))
    (explain! result)
    (unless (results-status result)
      (error "configuration tests failed."))
    t))
