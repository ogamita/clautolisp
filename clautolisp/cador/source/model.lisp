(in-package #:clautolisp.cador)

;;;; MockHost data carriers and the MockHost class.
;;;;
;;;; Phase 9 introduced these structures; Phase 17a extracted the
;;;; *drawing-resident* carriers — ENTITY-HANDLE, SYMBOL-TABLE-RECORD,
;;;; DICTIONARY, SYSVAR-CELL — and the drawing database itself into
;;;; clautolisp.drawing. They are imported back here (and re-exported
;;;; from this package) so older callers and tests are unaffected.
;;;;
;;;; What remains in this file are the *session / host* carriers that
;;;; are not part of a drawing — PICKSET and MOCK-COM-OBJECT — and the
;;;; MOCK-HOST class. MockHost now holds an ACTIVE-DRAWING and delegates
;;;; its entity / table / sysvar surface to it; the historical
;;;; accessors (cador-entities, cador-tables, cador-sysvars,
;;;; cador-creation-order, cador-next-handle-counter,
;;;; cador-named-object-dictionary) are preserved below as thin
;;;; functions that forward to the active drawing.

;;; --- Selection set (session state) ------------------------------

(defstruct pickset
  "Bag of entity-handles preserving insertion order."
  (id      (gensym "SS-") :type t)
  (members nil :type list))

;;; --- COM object (session state) ---------------------------------

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
  (released-p  nil :type boolean)
  ;; When this COM object is the ActiveX wrapper of a drawing entity
  ;; (vlax-ename->vla-object), BACKING-ENAME is that entity's hex-handle
  ;; string; NIL for ordinary application/document/collection objects.
  (backing-ename nil)
  ;; When this COM object is an ActiveX collection (Documents, ModelSpace,
  ;; …), COLLECTION-P is T and COLLECTION-MEMBERS is the ordered list of
  ;; its member VLA-objects, iterated by vlax-for / vlax-map-collection.
  (collection-p nil)
  (collection-members '())
  ;; Live collections are backed by the drawing database instead of a
  ;; static member list: COLLECTION-KIND is NIL (static), :BLOCKS
  ;; (the document's block-definition collection), :LAYERS (the layer
  ;; table), or (:BLOCK-ENTITIES . NAME) (the entities owned by block
  ;; NAME — *Model_Space / *Paper_Space / a user block). Their members
  ;; and Count are recomputed from the drawing on each access, so
  ;; entmake / DXF loads / Add / Delete are always reflected.
  (collection-kind nil))

;;; --- MockHost ---------------------------------------------------

(defclass cador (host)
  ((active-drawing           :initform (make-drawing :name "Drawing.dwg")
                             :accessor cador-active-drawing
                             :documentation "The drawing the host's
AutoLISP entity / table / sysvar surface currently operates on. A
CLAUTOLISP.DRAWING:DRAWING. Phase 17a holds exactly one; Phase 17f
will grow a set of open drawings with this as the active pointer.")
   (picksets                 :initform (make-hash-table :test #'eq)
                             :reader   cador-picksets)
   (vla-objects              :initform (make-hash-table :test #'eq)
                             :reader   cador-vla-objects)
   (prompt-stream            :initform nil
                             :accessor cador-prompt-stream
                             :documentation "Optional input stream
that getstring / getreal / getpoint / etc. consume in headless
mode. Set by tests and the CLI's --mock-input flag.")
   (prompt-output            :initform (make-string-output-stream)
                             :accessor cador-prompt-output
                             :documentation "Sink that the prompt
builtin and the get* prompts write to. Tests inspect it.")
   (command-log              :initform '()
                             :accessor cador-command-log
                             :documentation "Reverse-order list of
recorded (command ...) token sequences — each element is the
normalized token-string list one HOST-COMMAND call received.
MockHost has no command engine; recording the tokens (and echoing
them to PROMPT-OUTPUT) is the whole mock semantics. Read oldest-
first through HOST-COMMAND-LOG / the CLAL-COMMAND-LOG extension.")
   (display-log              :initform '()
                             :accessor cador-display-log
                             :documentation "Reverse-order list of
recorded transient-graphics calls (grdraw / grtext / grvecs /
grclear / redraw). Tests inspect this; production code does not.")
   (pickfirst                :initform nil
                             :accessor cador-pickfirst
                             :documentation "The session's
pickfirst selection set, as set by ssgetfirst / sssetfirst.")
   (tblnext-iterators        :initform (make-hash-table :test #'eq)
                             :accessor cador-tblnext-iterators
                             :documentation "Per-kind iterator
state for tblnext. Maps a table-kind keyword to the remaining
list of records that subsequent (tblnext KIND) calls will
return. Cleared / reset when (tblnext KIND :rewind t).")
   (dictnext-iterators       :initform (make-hash-table :test #'equal)
                             :accessor cador-dictnext-iterators
                             :documentation "Per-dictionary iterator
state for dictnext. Maps a dictionary hex-handle string to the
remaining list of (KEY . MEMBER-HANDLE) entries that subsequent
 (dictnext DICT) calls will return. Rebuilt on first reference or on
 (dictnext DICT :rewind t), matching the tblnext contract.")
   (pending-initget          :initform nil
                             :accessor cador-pending-initget
                             :documentation "Per-host scratch slot
for the most recent INITGET call. Bound to an `initget-state`
object; consumed and cleared by the next get* invocation, matching
AutoLISP's documented one-shot semantics.")
   (com-objects              :initform (make-hash-table :test #'equal)
                             :reader   cador-com-objects
                             :documentation "Hash-table mapping a
unique COM-object id (string) to a MOCK-COM-OBJECT struct. The
AutoLISP-visible VLA-object wraps that id.")
   (next-com-counter         :initform 0
                             :accessor cador-next-com-counter
                             :documentation "Allocator state for
COM-object ids.")
   (acad-application-id      :initform nil
                             :accessor cador-acad-application-id
                             :documentation "COM-object id of the
singleton AutoCAD.Application returned by (vlax-get-acad-object),
or NIL before the first call. Lazily created together with its
ActiveDocument so the vla-get-activedocument chain resolves.")
   (live-collection-ids      :initform (make-hash-table :test #'equalp)
                             :reader   cador-live-collection-ids
                             :documentation "Identity map for the
drawing-backed (live) COM objects: a stable key string (\"BLOCKS\",
\"LAYERS\", \"BLOCK:<name>\", \"LAYER:<name>\") -> COM-object id, so
repeated vla-get-blocks / Item calls return the same VLA object, as
vendor ActiveX does.")
   (entity-vla-map           :initform (make-hash-table :test #'equal)
                             :accessor cador-entity-vla-map
                             :documentation "Entity hex-handle string ->
COM-object id of its vlax-ename->vla-object wrapper, so repeated
conversions of the same entity yield the same (identity-stable) VLA
object and vlax-vla-object->ename round-trips.")
   (ldata-store              :initform (make-hash-table :test #'equal)
                             :accessor cador-ldata-store
                             :documentation "Persistent vlax-ldata store:
maps a (DICT-KEY . PRIVATE-P) namespace string to an alist of
(entry-key . value). DICT-KEY is the dictionary's identity (COM id or
global-dictionary name). Survives for the host's lifetime — the headless
CAD analogue of ldata stored in the drawing.")
   (registered-commands      :initform '()
                             :accessor cador-registered-commands
                             :documentation "Reverse-order list of
(global-name local-name . function) registered by vlax-add-cmd, and the
queue fed by vlax-queueexpr. Headless has no interactive command line, so
this records registrations/queued expressions for introspection.")
   (open-complex-handle      :initform nil
                             :accessor cador-open-complex-handle
                             :documentation "The hex handle of the
complex entity (a POLYLINE or an INSERT) whose subentity run is
currently open, or NIL. When an entmake/entmakex creates a POLYLINE
or an INSERT, its handle is recorded here; each following VERTEX /
ATTRIB subentity gets its owner (group 330) set to this handle
unless the caller supplied one, matching the AutoCAD/BricsCAD
create-sequence contract. A SEQEND closes the run (clears the
slot). This is session state, not drawing state.")
   (ename-cache              :initform (make-hash-table :test #'equal)
                             :accessor cador-ename-cache
                             :documentation "Interns AutoLISP ENAMEs by
hex-handle string so that every producer (entget, entlast, entnext,
handent, ssname, entmakex ...) yields the SAME (EQ) ename object for a
given handle within a drawing. Vendor AutoLISP has this identity —
 (eq (entlast) (entlast)) is T and the EQ-based idioms (member ename
list), (eq ename (car sel)) work. Keyed and drained per drawing via
ENAME-CACHE-DRAWING. See HANDLE->ENAME. (ename-eq-identity.issue)")
   (ename-cache-drawing      :initform nil
                             :accessor cador-ename-cache-drawing
                             :documentation "The DRAWING object the
ENAME-CACHE is currently valid for. When the active drawing is replaced
 (a future multi-drawing session), HANDLE->ENAME notices the identity
change and clears the cache so handles from a closed drawing can never
alias a fresh drawing's entities."))
  (:default-initargs :name "cador")
  (:documentation "In-memory deterministic CAD-database substitute
backend for clautolisp. Holds an active CLAUTOLISP.DRAWING:DRAWING
(the drawing database) plus the session-level state — picksets,
COM objects, prompt streams, transient-graphics log, iterators —
that is not part of a drawing."))

;;; --- Active-drawing delegation ----------------------------------
;;;
;;; Before Phase 17a these were slots on MOCK-HOST. They now forward
;;; to the active drawing so every existing caller (entity-api,
;;; table-api, sysvar-api, api, and the test suite) keeps working
;;; unchanged. The names are deliberately preserved.

(defun cador-entities (host)
  "The active drawing's entity table (hex-handle string -> ENTITY-HANDLE)."
  (drawing-entities (cador-active-drawing host)))

(defun cador-tables (host)
  "The active drawing's symbol tables (kind keyword -> name -> record)."
  (drawing-tables (cador-active-drawing host)))

(defun cador-sysvars (host)
  "The active drawing's header variables (name string -> SYSVAR-CELL)."
  (drawing-header-variables (cador-active-drawing host)))

(defun cador-creation-order (host)
  "The active drawing's reverse-order handle list."
  (drawing-creation-order (cador-active-drawing host)))

(defun (setf cador-creation-order) (new host)
  (setf (drawing-creation-order (cador-active-drawing host)) new))

(defun cador-next-handle-counter (host)
  "The active drawing's handle allocator state (HANDSEED)."
  (drawing-handle-seed (cador-active-drawing host)))

(defun (setf cador-next-handle-counter) (new host)
  (setf (drawing-handle-seed (cador-active-drawing host)) new))

(defun cador-named-object-dictionary (host)
  "The active drawing's root named-object dictionary."
  (drawing-named-object-dictionary (cador-active-drawing host)))

(defun (setf cador-named-object-dictionary) (new host)
  (setf (drawing-named-object-dictionary (cador-active-drawing host)) new))
