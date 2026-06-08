(in-package #:clautolisp.drawing.dwg.tests)

(def-suite drawing-dwg-suite
  :description "Tests for the clautolisp DWG codec (libredwg, Phase 17e).")

(in-suite drawing-dwg-suite)

(defun run-all-tests ()
  (let ((result (run 'drawing-dwg-suite)))
    (fiveam:explain! result)
    (unless (fiveam:results-status result)
      (error "clautolisp.drawing.dwg tests failed."))
    result))
