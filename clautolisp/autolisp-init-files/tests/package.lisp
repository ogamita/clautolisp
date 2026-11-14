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

;;; The temporary file and directory names these tests make with (RANDOM N)
;;; must differ between processes: SBCL starts every image with the same
;;; default *RANDOM-STATE*, so each run -- of every user -- drew the same
;;; "random" names, and a tree one user's run had left in the sticky /tmp
;;; was then unwritable to the next user's (Permission denied). Each suite run
;;; gets a state seeded from the system instead.
(defun run-all-tests ()
  (let ((results (let ((*random-state* (make-random-state t))) (run 'autolisp-init-files-suite))))
    (explain! results)
    (unless (results-status results)
      (error "clautolisp.autolisp-init-files tests failed."))))
