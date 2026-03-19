(in-package #:clautolisp.autolisp-reader.tests)

(def-suite autolisp-reader-suite
  :description "Tests for the clautolisp AutoLISP reader.")

(in-suite autolisp-reader-suite)

(defun run-all-tests ()
  (let ((result (run 'autolisp-reader-suite)))
    (fiveam:explain! result)
    (unless (fiveam:results-status result)
      (error "autolisp-reader tests failed."))
    result))
