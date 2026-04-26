(in-package #:clautolisp.autolisp-host.tests)

(def-suite autolisp-host-suite
  :description "Tests for the clautolisp Host Abstraction Layer.")

(in-suite autolisp-host-suite)

(defun run-all-tests ()
  (let ((result (run 'autolisp-host-suite)))
    (fiveam:explain! result)
    (unless (fiveam:results-status result)
      (error "autolisp-host tests failed."))
    result))
