(defpackage #:clautolisp.drawing
  (:use #:cl)
  (:documentation "Phase 17a — the drawing value object.

A DRAWING is a first-class, backend-independent Common-Lisp value
holding the persistent contents of a CAD drawing database: its
entities (keyed by hex handle), block / symbol tables, named-object
dictionary, header (drawing-resident system) variables, the handle
allocator, the DXF/DWG class table, and file provenance.

This package speaks *pure* Common-Lisp values only. The AutoLISP
wrapper types (autolisp-ename, autolisp-string, …) are not visible
here; wrapping/unwrapping is the host adapter's job
(clautolisp.autolisp-mock-host and, later, the LiveHost). MockHost
holds one or more of these drawings and delegates its entity /
table / sysvar surface to the active one.

The data-carrier structs (ENTITY-HANDLE, SYMBOL-TABLE-RECORD,
DICTIONARY, SYSVAR-CELL) live here and are re-exported by MockHost
for backward compatibility with code and tests that imported them
from the mock-host package before the Phase-17a extraction.")
  (:export
   ;; The drawing value object.
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
   ;; Data carrier: entity.
   #:entity-handle
   #:make-entity-handle
   #:entity-handle-id
   #:entity-handle-kind
   #:entity-handle-block
   #:entity-handle-layer
   #:entity-handle-data
   #:entity-handle-deleted-p
   ;; Data carrier: symbol-table record.
   #:symbol-table-record
   #:make-symbol-table-record
   #:symbol-table-record-id
   #:symbol-table-record-kind
   #:symbol-table-record-name
   #:symbol-table-record-data
   ;; Data carrier: dictionary.
   #:dictionary
   #:make-dictionary
   #:dictionary-id
   #:dictionary-entries
   ;; Data carrier: sysvar / header-variable cell.
   #:sysvar-cell
   #:make-sysvar-cell
   #:sysvar-cell-name
   #:sysvar-cell-kind
   #:sysvar-cell-value
   #:sysvar-cell-read-only-p
   #:sysvar-cell-host-derived-p))
