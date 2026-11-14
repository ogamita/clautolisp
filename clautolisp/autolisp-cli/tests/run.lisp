(in-package #:clautolisp.autolisp-cli.tests)

;;; The temporary file and directory names these tests make with (RANDOM N)
;;; must differ between processes: SBCL starts every image with the same
;;; default *RANDOM-STATE*, so each run -- of every user -- drew the same
;;; "random" names, and a tree one user's run had left in the sticky /tmp
;;; was then unwritable to the next user's (Permission denied). Each suite run
;;; gets a state seeded from the system instead.
(defun run-all-tests ()
  (let ((result (let ((*random-state* (make-random-state t))) (run 'autolisp-cli-suite))))
    (explain! result)
    (unless (results-status result)
      (error "autolisp-cli tests failed."))
    t))
