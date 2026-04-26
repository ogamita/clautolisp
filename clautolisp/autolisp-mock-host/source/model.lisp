(in-package #:clautolisp.autolisp-mock-host)

;;;; MockHost data carriers.
;;;;
;;;; Phase 9 of the implementation roadmap. The structures defined
;;;; here mirror the AutoLISP host-visible data model documented in
;;;; the implementation roadmap ("Data Model — Inferred From the
;;;; CAD Specifications"): handles to entities, selection sets,
;;;; symbol-table records, dictionaries, sysvar cells. Every
;;;; structure is purely data; the host *operations* on these data
;;;; (entget / ssget / getvar / ...) land in Phase 10.
;;;;
;;;; The MockHost class itself is also defined in this file so the
;;;; sysvar-table and tables-table slots have visible struct types
;;;; at compile time.

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

;;; --- Selection set ---------------------------------------------

(defstruct pickset
  "Bag of entity-handles preserving insertion order."
  (id      (gensym "SS-") :type t)
  (members nil :type list))

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

;;; --- Sysvar cell -----------------------------------------------

(defstruct mock-com-object
  "In-memory COM-object record for MockHost. PROGID is the
ProgID string the object was created from. PROPERTIES is a
case-insensitive hash-table from name string to current value
(populated initially from the *com-progids* template, mutated by
vlax-put-property). METHODS is a case-insensitive hash-table from
name string to a (lambda (mock object args) -> value) closure
that implements the method. RELEASED-P is set by
vlax-release-object."
  (id          (gensym "COM-") :type t)
  (progid      "" :type string)
  (properties  (make-hash-table :test #'equalp))
  (methods     (make-hash-table :test #'equalp))
  (released-p  nil :type boolean))

(defstruct sysvar-cell
  "Single AutoLISP system variable. KIND is one of :integer,
:short, :real, :string, :point, :symbol — used by the mock
implementation of getvar / setvar to validate type coercions."
  (name        "" :type string)
  (kind        :integer :type keyword)
  (value       nil)
  (read-only-p nil :type boolean))

;;; --- MockHost ---------------------------------------------------

(defclass mock-host (host)
  ((entities                 :initform (make-hash-table :test #'equal)
                             :reader   mock-host-entities
                             :documentation "Hash-table mapping the
entity's hex handle string (e.g. \"10\") to its ENTITY-HANDLE.
The handle string is what AutoLISP user code sees through the
group-code 5 entry and through HANDENT.")
   (creation-order           :initform '()
                             :accessor mock-host-creation-order
                             :documentation "Reverse-order list of
handle strings, in the order they were allocated by entmake /
entmakex. Walked by entlast / entnext.")
   (next-handle-counter      :initform 16
                             :accessor mock-host-next-handle-counter
                             :documentation "Allocator state for
hex-string handles. The first allocated handle is \"10\" (= 16),
matching AutoCAD's customary minimum visible handle.")
   (picksets                 :initform (make-hash-table :test #'eq)
                             :reader   mock-host-picksets)
   (vla-objects              :initform (make-hash-table :test #'eq)
                             :reader   mock-host-vla-objects)
   (tables                   :initform (make-hash-table :test #'eq)
                             :reader   mock-host-tables
                             :documentation "Hash-table mapping a
table-kind keyword (e.g. :layer) to a hash-table mapping the
table-record name (case-folded string) to a SYMBOL-TABLE-RECORD.")
   (named-object-dictionary  :initform (make-dictionary)
                             :accessor mock-host-named-object-dictionary)
   (sysvars                  :initform (make-hash-table :test #'equalp)
                             :reader   mock-host-sysvars
                             :documentation "Hash-table mapping a
case-insensitive sysvar name string to a SYSVAR-CELL.")
   (prompt-stream            :initform nil
                             :accessor mock-host-prompt-stream
                             :documentation "Optional input stream
that getstring / getreal / getpoint / etc. consume in headless
mode. Set by tests and the CLI's --mock-input flag.")
   (prompt-output            :initform (make-string-output-stream)
                             :accessor mock-host-prompt-output
                             :documentation "Sink that the prompt
builtin and the get* prompts write to. Tests inspect it.")
   (display-log              :initform '()
                             :accessor mock-host-display-log
                             :documentation "Reverse-order list of
recorded transient-graphics calls (grdraw / grtext / grvecs /
grclear / redraw). Tests inspect this; production code does not.")
   (pickfirst                :initform nil
                             :accessor mock-host-pickfirst
                             :documentation "The session's
pickfirst selection set, as set by ssgetfirst / sssetfirst.")
   (tblnext-iterators        :initform (make-hash-table :test #'eq)
                             :accessor mock-host-tblnext-iterators
                             :documentation "Per-kind iterator
state for tblnext. Maps a table-kind keyword to the remaining
list of records that subsequent (tblnext KIND) calls will
return. Cleared / reset when (tblnext KIND :rewind t).")
   (pending-initget          :initform nil
                             :accessor mock-host-pending-initget
                             :documentation "Per-host scratch slot
for the most recent INITGET call. Bound to an `initget-state`
object; consumed and cleared by the next get* invocation, matching
AutoLISP's documented one-shot semantics.")
   (com-objects              :initform (make-hash-table :test #'equal)
                             :reader   mock-host-com-objects
                             :documentation "Hash-table mapping a
unique COM-object id (string) to a MOCK-COM-OBJECT struct. The
AutoLISP-visible VLA-object wraps that id.")
   (next-com-counter         :initform 0
                             :accessor mock-host-next-com-counter
                             :documentation "Allocator state for
COM-object ids."))
  (:default-initargs :name "mock-host")
  (:documentation "In-memory deterministic CAD-database substitute
backend for clautolisp. Phase 9 — data structures only; Phase 10
fills in the entget / ssget / getvar / command surfaces."))
