;;;; clautolisp/autolisp-debug/tests/package.lisp

(defpackage #:clautolisp.debug.tests
  (:use #:cl)
  (:import-from #:fiveam
                #:def-suite #:in-suite #:test #:is #:signals #:run #:explain! #:results-status)
  (:export #:run-all-tests))

(in-package #:clautolisp.debug.tests)

(def-suite debug-suite
  :description "clautolisp debugger engine: instrumentation, poll points, breakpoints, two-body dispatch.")

(defun run-all-tests ()
  (let ((results (run 'debug-suite)))
    (explain! results)
    (unless (results-status results)
      (error "clautolisp.debug tests failed."))))
