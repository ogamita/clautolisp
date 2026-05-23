(in-package #:autolisp-front-end.tests)

(defun run-all-tests ()
  "Run the entire alfe FiveAM suite. Signals an error if any test
failed, so the Makefile's `make test` target exits non-zero on
regression."
  (let ((result (fiveam:run 'autolisp-front-end-suite)))
    (explain! result)
    (unless (results-status result)
      (error "autolisp-front-end tests failed."))
    t))
