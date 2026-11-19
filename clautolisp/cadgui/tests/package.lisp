(defpackage #:clautolisp.cadgui.tests
  (:use #:cl)
  (:import-from #:fiveam
                #:def-suite #:in-suite #:test #:is #:signals #:run #:explain! #:results-status)
  (:import-from #:clautolisp.cadgui
                #:cadgui-start #:cadgui-session-host #:*cadgui-session*
                #:cadgui-display-list #:cadgui-extents #:cadgui-entity-count
                #:cadgui-regen-serial #:cadgui-selection #:cadgui-selection-geometry
                #:cadgui-invoke-action #:cadgui-list-actions #:cadgui-describe-action
                #:cadgui-unknown-action #:cadgui-register-action #:*cadgui-actions*
                #:cadgui-register-builtin-actions
                #:cadgui-register-gui-binding #:*cadgui-gui-bindings*
                #:cadgui-gui-bindings #:cadgui-register-action-sample-args
                #:cadgui-drive-all-actions #:cadgui-driveability-violations
                #:cadgui-run-driveability-check #:cadgui-driveability-report
                #:cadgui-recording-transcript #:cadgui-replay-transcript
                #:cadgui-transcript-actions
                #:cadgui-make-workspace #:cadgui-workspace-docs #:cadgui-open-document
                #:cadgui-doc-supply-point #:cadgui-doc-host #:cadgui-workspace-start
                #:cadgui-workspace-serve #:cadgui-workspace-run #:cadgui-workspace-shutdown
                #:cadgui-doc-feed #:cadgui-doc-feed-point #:cadgui-workspace-launch
                #:cadgui-workspace-drive-step #:cadgui-document-command-loop
                #:cadgui-doc-display-list #:cadgui-workspace-all-finished-p
                #:cadgui-close-document #:cadgui-workspace-document-keys
                #:cadgui-workspace-active-document #:cadgui-workspace-state
                #:cadgui-workspace-events #:cadgui-workspace-pending-requests
                #:cadgui-add-line #:cadgui-add-circle
                #:cadgui-input-stream #:*cadgui-input-hook* #:*cadgui-pending-input*
                #:cadgui-point-line #:cadgui-install-input
                #:cadgui-eval-command)
  (:import-from #:clautolisp.autolisp-host
                #:host-getpoint #:host-entsel)
  (:export #:run-all-tests #:cadgui-suite))

(in-package #:clautolisp.cadgui.tests)

(def-suite cadgui-suite :description "The cadgui host CL protocol.")

(defun run-all-tests ()
  (let ((results (let ((*random-state* (make-random-state t))) (run 'cadgui-suite))))
    (explain! results)
    (unless (results-status results)
      (error "clautolisp.cadgui tests failed."))))
