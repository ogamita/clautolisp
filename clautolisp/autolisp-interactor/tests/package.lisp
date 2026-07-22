;;;; clautolisp/autolisp-interactor/tests/package.lisp

(defpackage #:clautolisp.interactor.tests
  (:use #:cl #:clautolisp.interactor)
  (:import-from #:fiveam
                #:def-suite #:in-suite #:test #:is #:signals #:run #:explain! #:results-status)
  (:export #:run-all-tests))

(in-package #:clautolisp.interactor.tests)

(def-suite interactor-suite
  :description "The interactor framework: command parser, dictionaries, stack lookup, and the loop.")

(defun run-all-tests ()
  (let ((results (run 'interactor-suite)))
    (explain! results)
    (unless (results-status results)
      (error "clautolisp.interactor tests failed."))))

;;; --- fixtures -------------------------------------------------------------

(defun run-loop-on-script (script &key interactors floor)
  "Push INTERACTORS (outermost first; an entry may be a ready-made ACTIVATION
to carry state), run INTERACTOR-LOOP over SCRIPT (a string of input lines),
and return (values OUTPUT LOOP-VALUE ERRORS)."
  (let ((*interactor-stack* (mapcar (lambda (entry)
                                      (if (activation-p entry)
                                          entry
                                          (make-activation entry)))
                                    (reverse interactors)))
        (*package* (find-package '#:clautolisp.interactor.tests))
        (output (make-string-output-stream))
        (errors (make-string-output-stream)))
    (let ((value (with-input-from-string (input script)
                   (interactor-loop :input input :output output
                                    :error-output errors
                                    :floor (or floor (length interactors))))))
      (values (get-output-stream-string output)
              value
              (get-output-stream-string errors)))))
