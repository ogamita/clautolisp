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

(defun run-all-tests ()
  (let ((result (call-with-cador-suite-environment
                 (lambda () (run 'cador-suite)))))
    (fiveam:explain! result)
    (unless (fiveam:results-status result)
      (error "cador tests failed."))
    result))
