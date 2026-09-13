(defpackage #:clautolisp.cadtui.tests
  (:use #:cl)
  (:import-from #:fiveam
                #:def-suite
                #:in-suite
                #:is
                #:run
                #:explain!
                #:results-status
                #:test)
  (:import-from #:clautolisp.cadtui
                #:ui-node
                #:ui-application
                #:ui-menubar
                #:ui-menu
                #:ui-menu-item
                #:ui-drawing
                #:ui-band
                #:ui-button
                #:ui-ribbon-tab
                #:ui-ribbon-panel
                #:ui-cad-view
                #:ui-entity
                #:ui-grip
                #:ui-alert
                #:ui-dialog
                #:ui-tile
                #:ui-console
                #:ui-key
                #:ui-role
                #:ui-label
                #:ui-state
                #:ui-action
                #:ui-parent
                #:ui-children
                #:add-child
                #:ui-find-child
                #:ui-root-p
                #:duplicate-sibling-key
                ;; slice 2: dump + builders
                #:dump-node
                #:dump-node-to-string
                #:node-dump-attributes
                #:dump-header
                #:next-dump-number
                #:*dump-counter*
                #:make-application-tree
                #:make-cador-tree
                ;; slice 3: addressing
                #:find-node
                #:resolve-target
                #:target-not-found
                #:ambiguous-target
                #:ambiguous-target-candidates
                ;; Phase 2 slice 1: classifier
                #:*command-escape*
                #:classify-line
                ;; Phase 2 slice 2: parser
                #:parse-meta-command
                #:meta-command-verb
                #:meta-command-positionals
                #:meta-command-options
                #:meta-command-parse-error
                ;; Phase 2 slice 3: dump registry + D<n> addressing
                #:*dump-counter*
                #:*last-dump*
                #:reset-dump-registry
                #:find-dump
                #:register-dump
                #:dump-list
                #:dump-page
                #:dump-descriptor-number
                #:dump-descriptor-page
                ;; Phase 2 slice 4: dispatch + interpret-line
                #:interpret-line
                #:dispatch-meta-command
                #:implicit-input-target
                #:command-result-status
                #:command-result-verb
                #:command-result-text
                #:command-result-data
                ;; Phase 3: DCL integration
                #:*cadtui-dcl-root*
                #:install-cadtui-dcl-renderer
                #:cadtui-dcl-enqueue
                #:reset-cadtui-dcl-events
                ;; Phase 4: per-console runtime
                #:ui-context
                #:ensure-session-scheduler
                #:make-console-context
                #:console-namespace
                #:console-queue
                #:deliver-line-to-console
                #:console-read-line
                #:start-console
                #:activate-drawing-document
                #:*cadtui-console*
                #:push-console-interactor
                #:tui-command-escape
                ;; Phase 5: CAD view + entities
                #:ui-cad-view-drawing
                #:entity-bounding-box
                #:entity->ui-entity
                #:viewport
                #:make-viewport
                #:viewport-bounds)
  (:import-from #:clautolisp.drawing
                #:make-drawing
                #:add-entity
                #:find-entity
                #:map-entities)
  (:import-from #:clautolisp.interactor
                #:make-input-context
                #:make-activation
                #:activation-state
                #:*command-activation*
                #:interactor-p
                #:find-registered-interactor)
  (:import-from #:clautolisp.autolisp-dcl
                #:dcl-runtime-load-dialog
                #:dcl-runtime-new-dialog
                #:dcl-runtime-action-tile
                #:dcl-runtime-set-tile
                #:dcl-runtime-get-tile
                #:dcl-runtime-mode-tile
                #:dcl-runtime-start-dialog
                #:dcl-runtime-done-dialog
                #:dcl-runtime-fire-action
                #:dcl-dialog-status
                #:dcl-dialog-finished-p
                #:dcl-tile-type
                #:current-dcl-renderer
                #:install-default-renderer
                #:make-noop-renderer)
  (:import-from #:clautolisp.autolisp-runtime
                #:reset-default-evaluation-context
                #:intern-autolisp-symbol
                #:autolisp-symbol-value
                #:autolisp-string-value
                #:make-autolisp-string
                #:run-autolisp-string
                ;; Phase 4
                #:make-runtime-session
                #:session-scheduler
                #:document-namespace-set
                #:document-namespace-ref
                #:scheduled-context-thread
                #:scheduled-context-mailbox
                #:park-mailbox-pop
                #:park-mailbox-push
                #:make-park-mailbox
                #:scheduler-context-list
                #:scheduler-current-context
                #:scheduler-await-park
                #:scheduler-serve-park
                #:runtime-session-current-document)
  (:export #:cadtui-suite
           #:run-all-tests))
