(in-package #:clautolisp.cador.tests)

(def-suite cador-suite
  :description "Tests for the clautolisp cador data carriers (Phase 9).")

(in-suite cador-suite)

(defun call-with-cador-suite-environment (thunk)
  "Call THUNK in the state the cador suite tests: the host BELOW the
builtins layer, so COM points cross as plain lists and no vla-* facade
resolves. A suite that installed the builtins earlier in the same process
leaves their hooks set globally; the suite must not depend on that
(install-core-builtins-leaks-com-hooks-across-suites)."
  (clautolisp.autolisp-runtime:without-builtin-layer-hooks
    (funcall thunk)))

;;; The temporary file and directory names these tests make with (RANDOM N)
;;; must differ between processes: SBCL starts every image with the same
;;; default *RANDOM-STATE*, so each run -- of every user -- drew the same
;;; "random" names, and a directory one user's run had left in the sticky
;;; /tmp was then unwritable to the next user's (Permission denied). Each
;;; suite run gets a state seeded from the system instead.
(defun run-all-tests ()
  (let ((result (call-with-cador-suite-environment
                 (lambda () (let ((*random-state* (make-random-state t))) (run 'cador-suite))))))
    (fiveam:explain! result)
    (unless (fiveam:results-status result)
      (error "cador tests failed."))
    result))
