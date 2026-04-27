(in-package #:clautolisp.autolisp-dcl.tests)

(def-suite autolisp-dcl-suite
  :description "Tests for the clautolisp DCL subsystem (parser + runtime).")

(in-suite autolisp-dcl-suite)

(defun run-all-tests ()
  (let ((result (run 'autolisp-dcl-suite)))
    (fiveam:explain! result)
    (unless (fiveam:results-status result)
      (error "autolisp-dcl tests failed."))
    result))
