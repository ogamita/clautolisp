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
                #:ambiguous-target-candidates)
  (:export #:cadtui-suite
           #:run-all-tests))
