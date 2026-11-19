;;;; The cadgui host: the GRAPHICAL UI-tree host, the Qt6 peer of cadtui on the
;;;; cador core (cadgui-2-qt6-gui-host.issue). This package is the CL side of the
;;;; cadgui host -- the protocol the embedded-ECL Qt6 shell calls: the display
;;;; list to paint, the view extents, interactive input, and command evaluation.
;;;; The C++ shell owns the window + per-frame paint; CL owns the model, and the
;;;; boundary is crossed only on regen and on input (never per frame).

(defpackage #:clautolisp.cadgui
  (:use #:common-lisp)
  (:export
   ;; Session
   #:cadgui-session
   #:cadgui-session-host
   #:*cadgui-session*
   #:cadgui-start
   #:cadgui-session-or-start
   ;; Scene (slices B/C/F) -- what the shell pulls to paint
   #:cadgui-display-list
   #:cadgui-extents
   ;; Model builders (so a demo / the shell can populate the model via the real
   ;; cador engine; the full AutoLISP command eval is slice E)
   #:cadgui-add-line
   #:cadgui-add-circle
   #:cadgui-entity-count
   #:cadgui-regen-serial
   #:cadgui-selection
   #:cadgui-selection-geometry
   ;; Interactive input bridge (slice D) -- a GUI-backed cador prompt stream so
   ;; getpoint/entsel/ssget drive from the canvas. The shell sets the hook to its
   ;; nested-event-loop await; it returns the next input line (e.g. a point "x,y").
   #:cadgui-input-stream
   #:*cadgui-input-hook*
   #:*cadgui-pending-input*
   #:cadgui-point-line
   #:cadgui-install-input
   ;; Command evaluation (slice E)
   #:cadgui-eval-command
   ;; Action layer (cadgui-action-layer slice 1) -- one registry + dispatch +
   ;; introspection; the surface the GUI, CLI, scripts and an AI driver share.
   #:*cadgui-actions*
   #:cadgui-register-action
   #:cadgui-register-builtin-actions
   #:cadgui-invoke-action
   #:cadgui-list-actions
   #:cadgui-describe-action
   #:cadgui-unknown-action
   #:cadgui-unknown-action-id
   ;; Multi-document workspace (cooperative-scheduler integration slice 1) --
   ;; N documents interleaving through the single-runner scheduler, each with
   ;; its own cador host + input channel.
   #:cadgui-make-workspace
   #:cadgui-workspace-docs
   #:cadgui-open-document
   #:cadgui-doc-key
   #:cadgui-doc-host
   #:cadgui-doc-supply
   #:cadgui-doc-supply-point
   #:cadgui-workspace-start
   #:cadgui-workspace-serve
   #:cadgui-workspace-run
   #:cadgui-doc-feed
   #:cadgui-doc-feed-point
   #:cadgui-workspace-launch
   #:cadgui-workspace-drive-step
   #:cadgui-document-run-command
   #:cadgui-document-command-loop
   #:cadgui-doc-display-list
   #:cadgui-doc-extents
   #:cadgui-workspace-all-finished-p
   #:cadgui-close-document
   #:cadgui-workspace-document-keys
   #:cadgui-workspace-active-document
   #:cadgui-document-state
   #:cadgui-workspace-state
   #:cadgui-workspace-shutdown))
