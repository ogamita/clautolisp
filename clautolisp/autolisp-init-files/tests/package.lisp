;;;; clautolisp/autolisp-init-files/tests/package.lisp

(defpackage #:clautolisp.autolisp-init-files.tests
  (:use #:cl)
  (:import-from #:fiveam
                #:def-suite
                #:in-suite
                #:test
                #:is
                #:signals
                #:run
                #:explain!
                #:results-status)
  (:import-from #:clautolisp.autolisp-init-files
                #:*default-clautolisp-stems*
                #:*default-alfe-stems*
                #:find-init-file
                #:find-init-files
                #:no-init-requested-p
                #:env-true-p)
  (:export #:run-all-tests))

(in-package #:clautolisp.autolisp-init-files.tests)

(def-suite autolisp-init-files-suite
  :description "Init-file discovery + gating helpers.")

(defun run-all-tests ()
  (let ((results (run 'autolisp-init-files-suite)))
    (explain! results)
    (unless (results-status results)
      (error "clautolisp.autolisp-init-files tests failed."))))
