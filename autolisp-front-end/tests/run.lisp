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
  (let ((result (let ((*random-state* (make-random-state t))) (fiveam:run 'autolisp-front-end-suite))))
    (explain! result)
    (unless (results-status result)
      (error "autolisp-front-end tests failed."))
    t))
