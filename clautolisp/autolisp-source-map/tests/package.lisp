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

(defun run-all-tests ()
  (let ((results (run 'source-map-suite)))
    (explain! results)
    (unless (results-status results)
      (error "clautolisp.source tests failed."))))
