;;;; clautolisp/autolisp-source-map/tests/package.lisp

(defpackage #:clautolisp.source.tests
  (:use #:cl)
  (:import-from #:fiveam
                #:def-suite #:in-suite #:test #:is #:run #:explain! #:results-status)
  (:import-from #:clautolisp.source
                #:source-position #:make-source-position #:source-position-p
                #:source-position-file #:source-position-start-line
                #:source-position-start-column #:source-position-equal
                #:*track-source-positions* #:note-position #:position-of
                #:clear-source-positions #:with-source-tracking #:lines-of)
  (:export #:run-all-tests))

(in-package #:clautolisp.source.tests)

(def-suite source-map-suite
  :description "clautolisp.source: positions, tracking, lines-of.")

;;; The temporary file and directory names these tests make with (RANDOM N)
;;; must differ between processes: SBCL starts every image with the same
;;; default *RANDOM-STATE*, so each run -- of every user -- drew the same
;;; "random" names, and a directory one user's run had left in the sticky
;;; /tmp was then unwritable to the next user's (Permission denied). Each
;;; suite run gets a state seeded from the system instead.
(defun run-all-tests ()
  (let ((results (let ((*random-state* (make-random-state t))) (run 'source-map-suite))))
    (explain! results)
    (unless (results-status results)
      (error "clautolisp.source tests failed."))))
