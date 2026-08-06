(in-package #:clautolisp.cador.tests)

(def-suite cador-suite
  :description "Tests for the clautolisp MockHost data carriers (Phase 9).")

(in-suite cador-suite)

(defun run-all-tests ()
  (let ((result (run 'cador-suite)))
    (fiveam:explain! result)
    (unless (fiveam:results-status result)
      (error "cador tests failed."))
    result))
