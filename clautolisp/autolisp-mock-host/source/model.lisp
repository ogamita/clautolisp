(in-package #:clautolisp.autolisp-mock-host)

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
;;;; accessors (mock-host-entities, mock-host-tables, mock-host-sysvars,
;;;; mock-host-creation-order, mock-host-next-handle-counter,
;;;; mock-host-named-object-dictionary) are preserved below as thin
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
  (released-p  nil :type boolean))

;;; --- MockHost ---------------------------------------------------

(defclass mock-host (host)
  ((active-drawing           :initform (make-drawing :name "Drawing.dwg")
                             :accessor mock-host-active-drawing
                             :documentation "The drawing the host's
AutoLISP entity / table / sysvar surface currently operates on. A
CLAUTOLISP.DRAWING:DRAWING. Phase 17a holds exactly one; Phase 17f
will grow a set of open drawings with this as the active pointer.")
   (picksets                 :initform (make-hash-table :test #'eq)
                             :reader   mock-host-picksets)
   (vla-objects              :initform (make-hash-table :test #'eq)
                             :reader   mock-host-vla-objects)
   (prompt-stream            :initform nil
                             :accessor mock-host-prompt-stream
                             :documentation "Optional input stream
that getstring / getreal / getpoint / etc. consume in headless
mode. Set by tests and the CLI's --mock-input flag.")
   (prompt-output            :initform (make-string-output-stream)
                             :accessor mock-host-prompt-output
                             :documentation "Sink that the prompt
builtin and the get* prompts write to. Tests inspect it.")
   (command-log              :initform '()
                             :accessor mock-host-command-log
                             :documentation "Reverse-order list of
recorded (command ...) token sequences — each element is the
normalized token-string list one HOST-COMMAND call received.
MockHost has no command engine; recording the tokens (and echoing
them to PROMPT-OUTPUT) is the whole mock semantics. Read oldest-
first through HOST-COMMAND-LOG / the CLAL-COMMAND-LOG extension.")
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

(defun mock-host-entities (host)
  "The active drawing's entity table (hex-handle string -> ENTITY-HANDLE)."
  (drawing-entities (mock-host-active-drawing host)))

(defun mock-host-tables (host)
  "The active drawing's symbol tables (kind keyword -> name -> record)."
  (drawing-tables (mock-host-active-drawing host)))

(defun mock-host-sysvars (host)
  "The active drawing's header variables (name string -> SYSVAR-CELL)."
  (drawing-header-variables (mock-host-active-drawing host)))

(defun mock-host-creation-order (host)
  "The active drawing's reverse-order handle list."
  (drawing-creation-order (mock-host-active-drawing host)))

(defun (setf mock-host-creation-order) (new host)
  (setf (drawing-creation-order (mock-host-active-drawing host)) new))

(defun mock-host-next-handle-counter (host)
  "The active drawing's handle allocator state (HANDSEED)."
  (drawing-handle-seed (mock-host-active-drawing host)))

(defun (setf mock-host-next-handle-counter) (new host)
  (setf (drawing-handle-seed (mock-host-active-drawing host)) new))

(defun mock-host-named-object-dictionary (host)
  "The active drawing's root named-object dictionary."
  (drawing-named-object-dictionary (mock-host-active-drawing host)))

(defun (setf mock-host-named-object-dictionary) (new host)
  (setf (drawing-named-object-dictionary (mock-host-active-drawing host)) new))
