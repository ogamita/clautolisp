(defpackage #:clautolisp.cadgui.tests
  (:use #:cl)
  (:import-from #:fiveam
                #:def-suite #:in-suite #:test #:is #:run #:explain! #:results-status)
  (:import-from #:clautolisp.cadgui
                #:cadgui-start #:cadgui-session-host #:*cadgui-session*
                #:cadgui-display-list #:cadgui-extents #:cadgui-entity-count
                #:cadgui-add-line #:cadgui-add-circle
                #:cadgui-supply-point #:cadgui-supply-entity
                #:*cadgui-pending-input* #:cadgui-pending-input
                #:cadgui-eval-command)
  (:export #:run-all-tests #:cadgui-suite))

(in-package #:clautolisp.cadgui.tests)

(def-suite cadgui-suite :description "The cadgui host CL protocol.")

(defun run-all-tests ()
  (let ((results (let ((*random-state* (make-random-state t))) (run 'cadgui-suite))))
    (explain! results)
    (unless (results-status results)
      (error "clautolisp.cadgui tests failed."))))
