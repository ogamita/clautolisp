(in-package #:clautolisp.cadtui.tests)

(def-suite cadtui-suite
  :description "Tests for the cadtui host (Phase 1: the UI-node tree model).")

(in-suite cadtui-suite)

(defun run-all-tests ()
  (let ((result (run 'cadtui-suite)))
    (fiveam:explain! result)
    (unless (fiveam:results-status result)
      (error "cadtui tests failed."))
    result))
