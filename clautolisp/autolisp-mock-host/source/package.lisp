(defpackage #:clautolisp.autolisp-mock-host
  (:use #:cl)
  (:import-from #:clautolisp.autolisp-host
                #:host
                #:host-name
                #:signal-host-not-supported)
  (:export
   ;; Class hierarchy
   #:mock-host
   #:make-mock-host
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
   ;; MockHost accessors
   #:mock-host-entities
   #:mock-host-picksets
   #:mock-host-vla-objects
   #:mock-host-tables
   #:mock-host-named-object-dictionary
   #:mock-host-sysvars
   #:mock-host-prompt-stream
   #:mock-host-prompt-output
   #:mock-host-display-log
   #:mock-host-pickfirst
   ;; Pre-population helpers
   #:populate-default-tables
   #:populate-default-sysvars
   ;; Snapshot / restore
   #:mock-host-snapshot
   #:mock-host-restore
   ;; Per-table accessors
   #:mock-host-table
   #:mock-host-find-table-record
   #:mock-host-add-table-record
   ;; Sysvar API
   #:mock-host-sysvar
   #:mock-host-set-sysvar))
