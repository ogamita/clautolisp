(defpackage #:clautolisp.cadtui
  ;; :use CL only, deliberately: clautolisp shadows PRINC/PRIN1/PRINT for
  ;; AutoLISP semantics, and the cadtui dump layer must get the standard CL
  ;; printers, not the runtime's shadowed ones (see cadtui/CLAUDE.md).
  (:use #:cl)
  ;; Phase 3: the DCL runtime API cadtui mirrors into ui-nodes. Imported by
  ;; name (not :use) so cadtui keeps CL's printers, not the runtime's shadowed
  ;; ones. cadtui depends on autolisp-dcl (exported API only) — no cycle.
  (:import-from #:clautolisp.autolisp-dcl
                #:dcl-tile-key
                #:dcl-tile-type
                #:dcl-tile-children
                #:tile-attribute
                #:dcl-dialog-id
                #:dcl-dialog-tile
                #:dcl-dialog-status
                #:dcl-dialog-finished-p
                #:dcl-runtime-fire-action
                #:dcl-runtime-done-dialog
                #:make-dcl-renderer
                #:install-default-renderer
                #:current-dcl-renderer
                #:make-noop-renderer)
  (:documentation
   "The cadtui host: a textual, keyboard-driven UI tree for CAD objects and
the CAD application, for headless interactive/scriptable testing of DCL
dialogs and CAD commands. Phase 1 lands the CLOS UI-node tree model only —
no rendering, no interaction language, no threads. See
documentation/cadtui-specifications.org (normative).")
  (:export
   ;; Phase 1: the UI-node model (spec §\"Modèle de données\").
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
   ;; Generic node accessors — the ONLY slots the tree mechanics touch.
   #:ui-key
   #:ui-role
   #:ui-label
   #:ui-state
   #:ui-action
   #:ui-parent
   #:ui-children
   ;; Tree construction / navigation primitives.
   #:add-child
   #:ui-find-child
   #:ui-root-p
   ;; Phase 1 slice 2: structured text dump + tree builders.
   #:dump-node
   #:dump-node-to-string
   #:node-dump-attributes
   #:dump-header
   #:next-dump-number
   #:*dump-counter*
   #:*last-dump*
   ;; Phase 2 slice 3: dump registry + pagination + D<n> addressing.
   #:dump-descriptor
   #:dump-descriptor-p
   #:dump-descriptor-number
   #:dump-descriptor-path
   #:dump-descriptor-root
   #:dump-descriptor-entries
   #:dump-descriptor-items
   #:dump-descriptor-total
   #:dump-descriptor-page
   #:dump-descriptor-page-size
   #:*dump-registry*
   #:reset-dump-registry
   #:find-dump
   #:register-dump
   #:collect-dump-entries
   #:dump-list
   #:dump-page
   #:make-application-tree
   #:make-cador-tree
   ;; Phase 1 slice 3: addressing.
   #:find-node
   #:resolve-target
   #:resolve-segment
   #:target-not-found
   #:target-not-found-path
   #:target-not-found-segment
   #:ambiguous-target
   #:ambiguous-target-path
   #:ambiguous-target-segment
   #:ambiguous-target-candidates
   #:*container-role-map*
   ;; Phase 2 slice 1: line classifier / escape mechanism.
   #:*command-escape*
   #:classify-line
   ;; Phase 2 slice 2: meta-command parser.
   #:parse-meta-command
   #:meta-command
   #:meta-command-p
   #:make-meta-command
   #:meta-command-verb
   #:meta-command-positionals
   #:meta-command-options
   #:meta-command-parse-error
   #:meta-command-parse-error-text
   #:meta-command-parse-error-reason
   #:*meta-option-names*
   ;; Phase 2 slice 4: dispatch + the non-modal line entry.
   #:command-result
   #:command-result-p
   #:make-command-result
   #:command-result-status
   #:command-result-verb
   #:command-result-text
   #:command-result-data
   #:*verb-table*
   #:define-verb
   #:dispatch-meta-command
   #:interpret-line
   #:implicit-input-target
   #:*help-text*
   #:*key-bindings*
   ;; Phase 3: DCL integration (mirror the DCL runtime into ui-nodes).
   #:*cadtui-dcl-root*
   #:make-cadtui-dcl-renderer
   #:install-cadtui-dcl-renderer
   #:*cadtui-dcl-events*
   #:cadtui-dcl-enqueue
   #:reset-cadtui-dcl-events
   ;; Conditions.
   #:cadtui-error
   #:duplicate-sibling-key
   #:duplicate-sibling-key-parent
   #:duplicate-sibling-key-key))
