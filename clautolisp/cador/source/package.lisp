(defpackage #:clautolisp.cador
  (:use #:cl)
  (:import-from #:clautolisp.drawing
                ;; Phase 17a: the drawing value object and its data
                ;; carriers now live in clautolisp.drawing. MockHost
                ;; holds a drawing and re-exports these so code/tests
                ;; that imported the carriers from this package before
                ;; the extraction keep resolving to the same symbols.
                #:drawing
                #:make-drawing
                #:drawing-p
                #:drawing-name
                #:drawing-path
                #:drawing-format
                #:drawing-version
                #:drawing-codepage
                #:drawing-entities
                #:drawing-creation-order
                #:drawing-handle-seed
                #:drawing-tables
                #:drawing-named-object-dictionary
                #:drawing-header-variables
                #:drawing-classes
                #:drawing-blocks
                #:entity-handle
                #:make-entity-handle
                #:entity-handle-id
                #:entity-handle-kind
                #:entity-handle-block
                #:entity-handle-layer
                #:entity-handle-data
                #:entity-handle-deleted-p
                #:symbol-table-record
                #:make-symbol-table-record
                #:symbol-table-record-id
                #:symbol-table-record-kind
                #:symbol-table-record-name
                #:symbol-table-record-data
                #:dictionary
                #:make-dictionary
                #:dictionary-id
                #:dictionary-entries
                #:sysvar-cell
                #:make-sysvar-cell
                #:copy-sysvar-cell
                #:sysvar-cell-name
                #:sysvar-cell-kind
                #:sysvar-cell-value
                #:sysvar-cell-read-only-p
                #:sysvar-cell-host-derived-p)
  (:import-from #:clautolisp.autolisp-host
                #:host
                #:host-name
                #:signal-host-not-supported
                ;; HAL generic-function names — needed by entity-api.lisp
                ;; (and the upcoming Phase-11 selection / sysvar files)
                ;; so that defmethod attaches a method to the *host*
                ;; package's generic, not a new same-named symbol.
                #:host-entget
                #:host-entmod
                #:host-entmake
                #:host-entmakex
                #:host-entdel
                #:host-entupd
                #:host-entlast
                #:host-entnext
                #:host-handent
                #:host-ssget
                #:host-ssadd
                #:host-ssdel
                #:host-ssname
                #:host-sslength
                #:host-ssmemb
                #:host-ssgetfirst
                #:host-sssetfirst
                #:host-tblsearch
                #:host-tblnext
                #:host-tblobjname
                #:host-namedobjdict
                #:host-dictsearch
                #:host-dictnext
                #:host-dictadd
                #:host-dictremove
                #:host-dictrename
                #:host-dictobjname
                #:host-regapp
                #:host-getvar
                #:host-setvar
                #:host-set-derived-sysvar
                #:host-define-sysvar
                #:host-undefine-sysvar
                #:host-snapshot-sysvars
                #:host-restore-sysvars
                #:host-sysvar-names
                #:host-registry-read #:host-registry-write
                #:host-registry-delete #:host-registry-descendents
                #:host-command
                #:host-command-log
                #:host-prompt
                #:host-initget
                #:host-getstring
                #:host-getint
                #:host-getreal
                #:host-getpoint
                #:host-getcorner
                #:host-getdist
                #:host-getangle
                #:host-getorient
                #:host-getkword
                #:host-grdraw
                #:host-grtext
                #:host-grvecs
                #:host-grclear
                #:host-grread
                #:host-redraw
                #:host-vlax-create-object
                #:host-vlax-get-object
                #:host-vlax-release-object
                #:host-vlax-get-property
                #:host-vlax-put-property
                #:host-vlax-invoke-method
                #:host-vlax-property-available-p
                #:host-vlax-method-applicable-p
                #:host-vlax-get-acad-object
                #:host-vlax-ename->vla-object
                #:host-vlax-vla-object->ename
                #:host-vlax-erased-p
                #:host-vlax-describe-object
                #:host-vlax-ldata-put
                #:host-vlax-ldata-get
                #:host-vlax-ldata-delete
                #:host-vlax-ldata-list
                #:host-vlax-add-cmd
                #:host-vlax-remove-cmd
                #:host-vlax-queueexpr
                #:host-vlax-collection-items)
  (:export
   ;; Class hierarchy
   #:cador
   #:make-cador
   #:*mock-registry-path*
   ;; Drawing value object (re-exported from clautolisp.drawing) +
   ;; the host's active-drawing accessor.
   #:drawing
   #:make-drawing
   #:drawing-p
   #:drawing-name
   #:drawing-path
   #:drawing-format
   #:drawing-version
   #:drawing-codepage
   #:drawing-entities
   #:drawing-creation-order
   #:drawing-handle-seed
   #:drawing-tables
   #:drawing-named-object-dictionary
   #:drawing-header-variables
   #:drawing-classes
   #:cador-active-drawing
   ;; Data structures
   #:entity-handle
   #:make-entity-handle
   #:entity-handle-id
   #:entity-handle-kind
   #:entity-handle-block
   #:entity-handle-layer
   #:entity-handle-data
   #:entity-handle-deleted-p
   #:pickset
   #:make-pickset
   #:pickset-id
   #:pickset-members
   #:symbol-table-record
   #:make-symbol-table-record
   #:symbol-table-record-id
   #:symbol-table-record-kind
   #:symbol-table-record-name
   #:symbol-table-record-data
   #:dictionary
   #:make-dictionary
   #:dictionary-id
   #:dictionary-entries
   #:sysvar-cell
   #:make-sysvar-cell
   #:sysvar-cell-name
   #:sysvar-cell-kind
   #:sysvar-cell-value
   #:sysvar-cell-read-only-p
   #:sysvar-cell-host-derived-p
   ;; Generated full catalogue (1836 entries from
   ;; autolisp-spec/documentation/system-variables-inventory.sexp).
   #:*full-sysvar-catalogue*
   ;; MockHost accessors
   #:cador-entities
   #:cador-picksets
   #:cador-vla-objects
   #:cador-tables
   #:cador-named-object-dictionary
   #:cador-sysvars
   #:cador-prompt-stream
   #:cador-prompt-output
   #:cador-command-log
   #:cador-display-log
   #:cador-pickfirst
   ;; Pre-population helpers
   #:populate-default-tables
   #:populate-default-sysvars
   ;; Snapshot / restore
   #:cador-snapshot
   #:cador-restore
   ;; Per-table accessors
   #:cador-table
   #:cador-find-table-record
   #:cador-add-table-record
   ;; Sysvar API
   #:cador-sysvar
   #:cador-set-sysvar
   #:cador-remove-sysvar
   ;; BricsCAD-dialect sysvar overlay
   #:*bricscad-absent-sysvars*
   #:*bricscad-factory-defaults*
   #:apply-bricscad-dialect-sysvars
   ;; Entity-allocation helpers (Phase 10)
   #:cador-creation-order
   #:cador-next-handle-counter
   #:cador-allocate-handle
   #:cador-find-entity-by-handle
   ;; Prompt / interaction helpers (Phase 12)
   #:cador-pending-initget
   #:cador-tblnext-iterators
   #:initget-state
   #:initget-bits
   #:initget-keywords
   ;; COM bridge (Phase 13)
   #:mock-com-object
   #:make-mock-com-object
   #:mock-com-object-id
   #:mock-com-object-progid
   #:mock-com-object-properties
   #:mock-com-object-methods
   #:mock-com-object-released-p
   #:mock-com-object-collection-p
   #:mock-com-object-collection-members
   #:mock-com-object-collection-kind
   #:cador-com-objects
   #:cador-next-com-counter
   #:cador-allocate-com-id
   #:cador-find-com-object
   #:*com-progids*
   #:register-com-progid
   #:populate-default-com-progids))
