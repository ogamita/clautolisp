(defpackage #:clautolisp.autolisp-dcl
  (:use #:cl)
  (:import-from #:clautolisp.autolisp-runtime
                #:autolisp-runtime-error
                #:signal-autolisp-runtime-error
                #:make-autolisp-string
                #:autolisp-string
                #:autolisp-string-value
                #:intern-autolisp-symbol
                #:autolisp-symbol-name)
  (:export
   ;; AST / model
   #:dcl-tile
   #:make-dcl-tile
   #:dcl-tile-key
   #:dcl-tile-type
   #:dcl-tile-attributes
   #:dcl-tile-children
   #:dcl-tile-source
   #:tile-attribute
   #:set-tile-attribute
   ;; Parsing
   #:parse-dcl
   #:parse-dcl-from-file
   #:dcl-parse-error
   ;; Predefined tile registry
   #:*predefined-tiles*
   #:register-predefined-tile
   ;; Runtime
   #:dcl-source
   #:make-dcl-source
   #:dcl-source-id
   #:dcl-source-path
   #:dcl-source-tiles
   #:dcl-dialog
   #:make-dcl-dialog
   #:dcl-dialog-id
   #:dcl-dialog-source
   #:dcl-dialog-tile
   #:dcl-dialog-actions
   #:dcl-dialog-status
   #:dcl-dialog-result-bindings
   #:dcl-dialog-finished-p
   #:dcl-runtime-load-dialog
   #:dcl-runtime-unload-dialog
   #:dcl-runtime-new-dialog
   #:dcl-runtime-start-dialog
   #:dcl-runtime-done-dialog
   #:dcl-runtime-action-tile
   #:dcl-runtime-set-tile
   #:dcl-runtime-get-tile
   #:dcl-runtime-mode-tile
   #:dcl-runtime-client-data
   #:dcl-runtime-set-client-data
   #:dcl-runtime-find-tile
   #:dcl-runtime-fire-action
   #:current-dialog-id
   #:require-current-dialog-id
   #:install-default-renderer
   #:current-dcl-renderer
   #:make-noop-renderer
   ;; Terminal renderer
   #:make-terminal-renderer
   ;; Phase 15b — sexp wire protocol + subprocess renderer
   #:*sexp-protocol-version*
   #:sexp-wire-error
   #:sexp-wire-error-message
   #:read-sexp-message
   #:write-sexp-message
   #:tile->sexp
   #:make-subprocess-renderer))
