(defpackage #:clautolisp.cadtui
  ;; :use CL only, deliberately: clautolisp shadows PRINC/PRIN1/PRINT for
  ;; AutoLISP semantics, and the cadtui dump layer must get the standard CL
  ;; printers, not the runtime's shadowed ones (see cadtui/CLAUDE.md).
  (:use #:cl)
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
   ;; Conditions.
   #:cadtui-error
   #:duplicate-sibling-key
   #:duplicate-sibling-key-parent
   #:duplicate-sibling-key-key))
