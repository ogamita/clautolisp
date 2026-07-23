;;;; clautolisp/tools/clautolisp/tests/package.lisp

(defpackage #:clautolisp.tools.clautolisp.tests
  (:use #:cl)
  (:import-from #:fiveam
                #:def-suite #:in-suite #:test #:is #:signals
                #:run #:explain! #:results-status)
  (:export #:run-all-tests))

(in-package #:clautolisp.tools.clautolisp.tests)

(def-suite clautolisp-tool-suite
  :description "The clautolisp tool: the dribble tee/echo streams and start/stop/toggle logic.")

(defun run-all-tests ()
  (let ((results (run 'clautolisp-tool-suite)))
    (explain! results)
    (unless (results-status results)
      (error "clautolisp.tools.clautolisp tests failed."))))
