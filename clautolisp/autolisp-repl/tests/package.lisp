;;;; clautolisp/autolisp-repl/tests/package.lisp

(defpackage #:clautolisp.repl.tests
  (:use #:cl)
  (:import-from #:fiveam
                #:def-suite #:in-suite #:test #:is #:run #:explain! #:results-status)
  (:export #:run-all-tests))

(in-package #:clautolisp.repl.tests)

(def-suite repl-suite
  :description "The AutoLISP REPL interactor library: the relocated *AUTOLISP*
interactor, its default hooks, and the lisp window template.")

(defun run-all-tests ()
  (let ((results (run 'repl-suite)))
    (explain! results)
    (unless (results-status results)
      (error "clautolisp.repl tests failed."))))
