(in-package #:clautolisp.drawing)

;;;; The drawing value object and its data carriers (Phase 17a).
;;;;
;;;; These structures were extracted verbatim from
;;;; clautolisp.autolisp-mock-host (model.lisp) so the in-memory
;;;; drawing database becomes a first-class CL value that can be held
;;;; outside any host, loaded from / written to a file (Phase 17b/c),
;;;; and enumerated by pure-CL tools (Phase 17d). MockHost now holds
;;;; one of these and delegates its entity / table / sysvar surface to
;;;; the active drawing; it re-exports the carriers so older code and
;;;; tests that imported them from the mock-host package keep working.

;;; --- Entity handle ----------------------------------------------

(defstruct entity-handle
  "Opaque handle for one CAD object. The :data slot holds the
DXF group-code list as exchanged with AutoLISP via entget /
entmod (a list of dotted pairs of integer group-codes and values,
plus the canonical group-0 marker giving the entity kind)."
  (id        (gensym "ENT-") :type t)
  (kind      nil :type symbol)
  (block     nil)
  (layer     nil)
  (data      nil :type list)
  (deleted-p nil :type boolean))

;;; --- Symbol-table record ---------------------------------------

(defstruct symbol-table-record
  "Row in one of the named symbol tables: BLOCK, LAYER, LTYPE,
STYLE, VIEW, UCS, VPORT, DIMSTYLE, APPID."
  (id   (gensym "TBL-") :type t)
  (kind nil :type symbol)
  (name "" :type string)
  (data nil :type list))

;;; --- Dictionary -------------------------------------------------

(defstruct dictionary
  "Generic key->object container anchored at the named-object
dictionary or at any sub-dictionary. The :entries slot maps a
case-folded string key to an opaque value (an entity handle, an
xrecord representation, or another dictionary)."
  (id      (gensym "DICT-") :type t)
  (entries (make-hash-table :test #'equal)))

;;; --- Sysvar / header-variable cell ------------------------------

(defstruct sysvar-cell
  "Single AutoLISP system variable / drawing header variable. KIND
is one of :integer, :short, :real, :string, :point, :symbol — used
by getvar / setvar to validate type coercions.

HOST-DERIVED-P is T when the cell's initial value was sourced from
a non-literal default marker in the inventory ((:host-specific) /
(:drawing) / (:session) / (:registry) / (:preference) / (:unknown)).
A host-derived cell still holds a kind-appropriate stand-in value
so GETVAR returns the right AutoLISP type, but conformance tests
must not assert a specific value against it: the vendor docs state
the value is computed from host / drawing / session / user context
rather than fixed."
  (name           "" :type string)
  (kind           :integer :type keyword)
  (value          nil)
  (read-only-p    nil :type boolean)
  (host-derived-p nil :type boolean))

;;; --- The drawing value object -----------------------------------

(defclass drawing ()
  ((name :initarg :name
         :initform "Drawing.dwg"
         :accessor drawing-name
         :documentation "Drawing name (the DWGNAME the host reports).")
   (path :initarg :path
         :initform nil
         :accessor drawing-path
         :documentation "Source / target pathname this drawing was
read from or last written to, or NIL for an in-memory drawing.")
   (format :initarg :format
           :initform nil
           :accessor drawing-format
           :documentation "Persisted format: one of :dxf-ascii,
:dxf-binary, :dwg, :native, or NIL when never serialised.")
   (version :initarg :version
            :initform nil
            :accessor drawing-version
            :documentation "Drawing format version keyword
(e.g. :ac1027 for R2013), or NIL.")
   (codepage :initarg :codepage
             :initform nil
             :accessor drawing-codepage
             :documentation "Drawing codepage string (DWGCODEPAGE),
or NIL. Drives non-ASCII text decoding in the codec.")
   (entities :initform (make-hash-table :test #'equal)
             :accessor drawing-entities
             :documentation "Hash-table mapping the entity's hex
handle string (e.g. \"10\") to its ENTITY-HANDLE. The handle string
is what AutoLISP user code sees through the group-code 5 entry and
through HANDENT.")
   (creation-order :initform '()
                   :accessor drawing-creation-order
                   :documentation "Reverse-order list of handle
strings, in allocation order. Walked by entlast / entnext.")
   (handle-seed :initarg :handle-seed
                :initform 16
                :accessor drawing-handle-seed
                :documentation "Allocator state for hex-string
handles (the DXF HEADER $HANDSEED). The first allocated handle is
\"10\" (= 16), matching AutoCAD's customary minimum visible handle.
A loader MUST set this from the file's HANDSEED so freshly created
entities never collide with loaded handles.")
   (tables :initform (make-hash-table :test #'eq)
           :accessor drawing-tables
           :documentation "Hash-table mapping a table-kind keyword
(e.g. :layer) to a hash-table mapping the table-record name
(case-folded string) to a SYMBOL-TABLE-RECORD.")
   (named-object-dictionary :initform (make-dictionary)
                            :accessor drawing-named-object-dictionary
                            :documentation "Root named-object
dictionary; sub-dictionaries hang off its entries.")
   (header-variables :initform (make-hash-table :test #'equalp)
                     :accessor drawing-header-variables
                     :documentation "Hash-table mapping a
case-insensitive variable name string to a SYSVAR-CELL. This is the
DXF HEADER section: the drawing-resident system variables. (The
session/registry/preference-scoped sysvars are a host concern; a
later phase may overlay them rather than store them here.)")
   (classes :initform '()
            :accessor drawing-classes
            :documentation "DXF/DWG CLASSES-section metadata, carried
opaquely for round-trip fidelity. A list of class descriptors, or
NIL."))
  (:documentation "A first-class CAD drawing database as a pure
Common-Lisp value. Holds entities, symbol tables, the named-object
dictionary, header variables, the handle allocator, the class table,
and file provenance. Independent of any host backend: a host holds
zero or more drawings and delegates its AutoLISP entity / table /
sysvar surface to the active one."))

(defun make-drawing (&key (name "Drawing.dwg") path format version codepage
                          (handle-seed 16))
  "Construct a fresh, empty DRAWING. The symbol tables, entity table,
and header are empty; the named-object dictionary is a fresh empty
dictionary; the handle allocator starts at HANDLE-SEED (default 16)."
  (make-instance 'drawing
                 :name name :path path :format format
                 :version version :codepage codepage
                 :handle-seed handle-seed))

(defun drawing-p (object)
  "True iff OBJECT is a DRAWING."
  (typep object 'drawing))
