(defpackage #:clautolisp.autolisp-mock-host
  (:use #:cl)
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
                #:host-getvar
                #:host-setvar
                #:host-command
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
                #:host-vlax-method-applicable-p)
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
   #:mock-host-set-sysvar
   ;; Entity-allocation helpers (Phase 10)
   #:mock-host-creation-order
   #:mock-host-next-handle-counter
   #:mock-host-allocate-handle
   #:mock-host-find-entity-by-handle
   ;; Prompt / interaction helpers (Phase 12)
   #:mock-host-pending-initget
   #:mock-host-tblnext-iterators
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
   #:mock-host-com-objects
   #:mock-host-next-com-counter
   #:mock-host-allocate-com-id
   #:mock-host-find-com-object
   #:*com-progids*
   #:register-com-progid
   #:populate-default-com-progids))
