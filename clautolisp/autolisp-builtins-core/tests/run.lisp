(in-package #:clautolisp.autolisp-builtins-core.tests)

;;; The temporary file and directory names these tests make with (RANDOM N)
;;; must differ between processes: SBCL starts every image with the same
;;; default *RANDOM-STATE*, so each run -- of every user -- drew the same
;;; "random" names, and a tree one user's run had left in the sticky /tmp
;;; was then unwritable to the next user's (Permission denied). Each suite run
;;; gets a state seeded from the system instead.
(defun run-all-tests ()
  ;; The SECURELOAD warn path fires whenever a test loads an untrusted
  ;; file (most temp-file load tests). Silence it suite-wide so the
  ;; output stays clean; the secureload tests that assert on the warn
  ;; rebind it locally.
  (let ((clautolisp.autolisp-runtime:*secureload-diagnostic-suppress-p* t))
    (let ((result (let ((*random-state* (make-random-state t))) (run 'autolisp-builtins-core-suite))))
      (explain! result)
      (unless (results-status result)
        (error "autolisp-builtins-core tests failed."))
      t)))
