(in-package #:clautolisp.autolisp-cli.tests)

(defun run-all-tests ()
  (let ((result (run 'autolisp-cli-suite)))
    (explain! result)
    (unless (results-status result)
      (error "autolisp-cli tests failed."))
    t))
