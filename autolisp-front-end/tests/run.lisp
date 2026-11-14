(in-package #:autolisp-front-end.tests)

;;; The temporary file and directory names these tests make with (RANDOM N)
;;; must differ between processes: SBCL starts every image with the same
;;; default *RANDOM-STATE*, so each run -- of every user -- drew the same
;;; "random" names, and a directory one user's run had left in the sticky
;;; /tmp was then unwritable to the next user's (Permission denied). Each
;;; suite run gets a state seeded from the system instead.
(defun run-all-tests ()
  "Run the entire alfe FiveAM suite. Signals an error if any test
failed, so the Makefile's `make test` target exits non-zero on
regression."
  ;; The suite also parses command lines in-process: the developer's own
  ;; AUTOLISP_* / ALFE_* option variables must not change the results. A
  ;; test about them binds *ENVIRONMENT-GETENV* to a table.
  (let ((result (let ((*random-state* (make-random-state t))
                      (clautolisp.autolisp-cli:*environment-getenv* (constantly nil)))
                  (fiveam:run 'autolisp-front-end-suite))))
    (explain! result)
    (unless (results-status result)
      (error "autolisp-front-end tests failed."))
    t))
