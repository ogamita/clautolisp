(in-package #:clautolisp.autolisp-mock-host.tests)

(def-suite autolisp-mock-host-suite
  :description "Tests for the clautolisp MockHost data carriers (Phase 9).")

(in-suite autolisp-mock-host-suite)

(defun run-all-tests ()
  (let ((result (run 'autolisp-mock-host-suite)))
    (fiveam:explain! result)
    (unless (fiveam:results-status result)
      (error "autolisp-mock-host tests failed."))
    result))
