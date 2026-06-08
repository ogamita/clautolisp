(in-package #:clautolisp.drawing.tests)

(def-suite drawing-suite
  :description "Tests for the clautolisp drawing CL API (Phase 17b).")

(in-suite drawing-suite)

(defun run-all-tests ()
  (let ((result (run 'drawing-suite)))
    (fiveam:explain! result)
    (unless (fiveam:results-status result)
      (error "clautolisp.drawing tests failed."))
    result))
