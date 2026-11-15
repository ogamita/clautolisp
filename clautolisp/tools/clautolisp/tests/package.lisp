;;;; clautolisp/tools/clautolisp/tests/package.lisp

(defpackage #:clautolisp.tools.clautolisp.tests
  (:use #:cl)
  (:import-from #:fiveam
                #:def-suite #:in-suite #:test #:is #:signals
                #:run #:explain! #:results-status)
  (:export #:run-all-tests))

(in-package #:clautolisp.tools.clautolisp.tests)

(def-suite clautolisp-tool-suite
  :description "The clautolisp tool: the dribble tee/echo streams and
start/stop/toggle logic, and the debugger (aldo) CLI options.")

;;; The temporary file and directory names these tests make with (RANDOM N)
;;; must differ between processes: SBCL starts every image with the same
;;; default *RANDOM-STATE*, so each run -- of every user -- drew the same
;;; "random" names, and a directory one user's run had left in the sticky
;;; /tmp was then unwritable to the next user's (Permission denied). Each
;;; suite run gets a state seeded from the system instead.
(defun run-all-tests ()
  ;; The suite also parses command lines in-process: the developer's own
  ;; AUTOLISP_* / CLAUTOLISP_* option variables must not change the results.
  ;; A test that is about them binds *ENVIRONMENT-GETENV* to a table.
  (let ((results (let ((*random-state* (make-random-state t))
                       (clautolisp.autolisp-cli:*environment-getenv* (constantly nil)))
                   (run 'clautolisp-tool-suite))))
    (explain! results)
    (unless (results-status results)
      (error "clautolisp.tools.clautolisp tests failed."))))
