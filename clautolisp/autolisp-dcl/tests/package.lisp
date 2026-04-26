(defpackage #:clautolisp.autolisp-dcl.tests
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
  (:import-from #:clautolisp.autolisp-runtime
                #:make-autolisp-string
                #:autolisp-string-value
                #:default-evaluation-context
                #:reset-default-evaluation-context
                #:autolisp-symbol-value
                #:intern-autolisp-symbol)
  (:import-from #:clautolisp.autolisp-dcl
                #:dcl-tile
                #:dcl-tile-type
                #:dcl-tile-key
                #:dcl-tile-attributes
                #:dcl-tile-children
                #:tile-attribute
                #:parse-dcl
                #:dcl-parse-error
                #:*predefined-tiles*
                #:dcl-runtime-load-dialog
                #:dcl-runtime-unload-dialog
                #:dcl-runtime-new-dialog
                #:dcl-runtime-start-dialog
                #:dcl-runtime-done-dialog
                #:dcl-runtime-action-tile
                #:dcl-runtime-set-tile
                #:dcl-runtime-get-tile
                #:dcl-runtime-mode-tile
                #:dcl-runtime-find-tile
                #:dcl-runtime-fire-action
                #:dcl-dialog-tile
                #:dcl-dialog-status
                #:install-default-renderer
                #:current-dcl-renderer
                #:make-noop-renderer
                #:make-terminal-renderer)
  (:export #:autolisp-dcl-suite
           #:run-all-tests))
