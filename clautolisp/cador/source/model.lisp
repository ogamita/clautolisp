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
  (collection-kind nil)
  ;; The document this object belongs to (a document KEY), :APPLICATION for
  ;; the application-level objects (Application, Documents, Preferences), or
  ;; NIL before registration. Every access to the object runs with that
  ;; document's drawing current (multi-document slice 5).
  (document-key nil))

;;; --- MockHost ---------------------------------------------------

;;; --- the template a new drawing is created from --------------------
;;;
;;; The names live HERE, in the earliest file that needs them, because the
;;; startup document below is built in an :initform -- before any sysvar table
;;; exists, so before user code could setvar anything. sysvars.lisp (which loads
;;; later) reuses these constants; one definition, not the same string twice.
;;;
;;; Two knobs, one meaning (pjb, 2026-09-26 -- "il doit y avoir une sysvar pour
;;; specifier un template non?"):
;;;   * the SYSVAR governs documents opened during the session;
;;;   * the ENVIRONMENT VARIABLE of the same name governs the STARTUP document,
;;;     which is created before a session can run at all.
;;; Both empty means what clautolisp has always done: an empty drawing.

(defparameter +new-drawing-template-sysvar+ "CLAUTOLISPNEWDRAWINGTEMPLATE"
  "Name of the clautolisp new-drawing-template system / environment variable:
the drawing a NEW document is created from. Empty (the default) keeps a new
document empty.")

(defparameter +templatepath-sysvar+ "TEMPLATEPATH"
  "Name of BricsCAD's Templates-FOLDER system variable, used to resolve a
relative CLAUTOLISPNEWDRAWINGTEMPLATE.")

(defun %environment-template-pathname ()
  "The template named by $CLAUTOLISPNEWDRAWINGTEMPLATE, resolved against
$TEMPLATEPATH when relative, or NIL when unset or unreadable. Used for the
STARTUP document only; a warning here would precede any output the user asked
for, so an unreadable value is silently an empty drawing and the session's first
document creation reports it."
  (let ((name (uiop:getenv +new-drawing-template-sysvar+)))
    (when (and name (plusp (length (string-trim '(#\Space #\Tab) name))))
      (let* ((name (string-trim '(#\Space #\Tab) name))
             (folder (uiop:getenv +templatepath-sysvar+))
             (candidates
               (remove nil
                       (list (when (and folder (plusp (length folder)))
                               (ignore-errors
                                (merge-pathnames
                                 name (uiop:ensure-directory-pathname folder))))
                             (ignore-errors (pathname name))))))
        (find-if (lambda (candidate) (ignore-errors (probe-file candidate)))
                 candidates)))))

(defun %startup-drawing (&optional (template (ignore-errors
                                              (%environment-template-pathname))))
  "The drawing a fresh cador starts with: from TEMPLATE -- by default whatever
$CLAUTOLISPNEWDRAWINGTEMPLATE names, when that is readable -- else the empty
shell clautolisp has always started with. TEMPLATE is an argument so the choice
can be tested without setting an environment variable."
  (if template
      (clautolisp.drawing:make-drawing-from-template :name "Drawing1.dwg"
                                                     :template template)
      (make-drawing :name "Drawing1.dwg")))

(defclass cador (host)
  ((active-drawing           :initform (%startup-drawing)
                             :accessor cador-active-drawing
                             :documentation "The drawing the host's
AutoLISP entity / table / sysvar surface currently operates on. A
CLAUTOLISP.DRAWING:DRAWING. Phase 17a holds exactly one; Phase 17f
will grow a set of open drawings with this as the active pointer.")
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
normalized token-string list one HOST-COMMAND call received. Every
call is recorded (and echoed to PROMPT-OUTPUT per CMDECHO); the
model-only drawing commands the engine knows (LINE, CIRCLE, TEXT,
DONUT, SOLID — see command-api.lisp) are additionally EXECUTED
against the drawing. Read oldest-first through HOST-COMMAND-LOG /
the CLAL-COMMAND-LOG extension.")
   (display-log              :initform '()
                             :accessor cador-display-log
                             :documentation "Reverse-order list of
recorded transient-graphics calls (grdraw / grtext / grvecs /
grclear / redraw). Tests inspect this; production code does not.")
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
   (pending-input            :initform '()
                             :accessor cador-pending-input
                             :documentation "The COMMAND tokens a LISP
command (registered with vlax-add-cmd) has not consumed yet: its get*,
entsel and ssget calls take their input from here first, as the vendors
feed a LISP command the rest of the (command ...) arguments.")
   (registered-commands      :initform '()
                             :accessor cador-registered-commands
                             :documentation "Reverse-order list of
(global-name local-name . function) registered by vlax-add-cmd, and the
queue fed by vlax-queueexpr. Headless has no interactive command line, so
this records registrations/queued expressions for introspection.")
   (document-sessions        :initform (make-hash-table :test #'equal)
                             :reader   cador-document-sessions
                             :documentation "Document KEY -> DOC-SESSION: the
per-document session state (picksets, pickfirst, iterators, initget, ldata,
open entmake runs, the ename cache, the COM identity maps). Multi-document
slice 2: they were host-global, shared by every drawing.")
   (document-com-ids         :initform (make-hash-table :test #'equal)
                             :reader   cador-document-com-ids
                             :documentation "Document KEY -> COM id of its
AutoCAD.Document object (identity-stable, one per open document).")
   (untitled-counter         :initform 1
                             :accessor cador-untitled-counter
                             :documentation "The number of the last untitled
drawing name handed out (Drawing1.dwg is the startup drawing's): AutoCAD numbers
them for the whole session, so the next NEW after Drawing1 is Drawing2 even once
Drawing1 has been saved under another name.")
   (documents                :initform '()
                             :accessor cador-documents
                             :documentation "Open documents as an ORDERED
alist (KEY . DRAWING), KEY a string. cador-2 slice 1: the host holds a SET of
open drawings; ACTIVE-DRAWING stays the pointer to the current one and every
delegation shim reads it, so single-document behaviour is unchanged. Seeded by
INITIALIZE-INSTANCE :after with the initial ACTIVE-DRAWING as the first (and
current) document. Managed through HOST-OPEN/CLOSE/ACTIVATE-DOCUMENT.")
   (active-document-key      :initform nil
                             :accessor cador-active-document-key
                             :documentation "The KEY (in DOCUMENTS) of the
current document — the one ACTIVE-DRAWING points at. HOST-ACTIVATE-DOCUMENT
swaps both together."))
  (:default-initargs :name "cador")
  (:documentation "In-memory deterministic CAD-database substitute
backend for clautolisp. Holds an active CLAUTOLISP.DRAWING:DRAWING
(the drawing database) plus the session-level state — picksets,
COM objects, prompt streams, transient-graphics log, iterators —
that is not part of a drawing."))

;;; --- Per-document session state (multi-document slice 2) ---------
;;;
;;; What AutoCAD keeps per document besides the drawing database: the
;;; selection sets and the pickfirst set, the tblnext / dictnext iterators,
;;; the pending INITGET, the vlax-ldata, the open entmake runs (complex entity,
;;; block definition), the ename identity cache and the COM identity maps.
;;; The accessors keep their names and read the ACTIVE document's record, so
;;; every caller follows the current document unchanged.

(defstruct doc-session
  (read-only nil)
  (picksets (make-hash-table :test #'eq))
  (pickfirst nil)
  (tblnext-iterators (make-hash-table :test #'eq))
  (dictnext-iterators (make-hash-table :test #'equal))
  (pending-initget nil)
  (live-collection-ids (make-hash-table :test #'equalp))
  (entity-vla-map (make-hash-table :test #'equal))
  (ldata-store (make-hash-table :test #'equal))
  (open-complex-handle nil)
  (open-block-definition nil)
  (ename-cache (make-hash-table :test #'equal))
  (ename-cache-drawing nil)
  ;; The tiled (model space) viewports, the current one first: a list of
  ;; (ID LLX LLY URX URY). NIL until first asked: viewports.lisp.
  (model-viewports nil)
  ;; -VPORTS Toggle: the layout the first Toggle maximised, or NIL.
  (viewport-toggle nil)
  ;; -VPORTS Save / Restore: name -> the saved layout, (vports) order.
  (viewport-configurations (make-hash-table :test #'equalp)))

(defun cador-document-session (host &optional (key (cador-active-document-key host)))
  "The DOC-SESSION of document KEY (default: the current one), made on first use."
  (let ((table (cador-document-sessions host))
        (key (or key "")))
    (or (gethash key table)
        (setf (gethash key table) (make-doc-session)))))

(defmacro %define-document-session-accessor (name slot)
  `(progn
     (defun ,name (host) (,slot (cador-document-session host)))
     (defun (setf ,name) (new host) (setf (,slot (cador-document-session host)) new))))

(%define-document-session-accessor cador-picksets doc-session-picksets)
(%define-document-session-accessor cador-pickfirst doc-session-pickfirst)
(%define-document-session-accessor cador-tblnext-iterators doc-session-tblnext-iterators)
(%define-document-session-accessor cador-dictnext-iterators doc-session-dictnext-iterators)
(%define-document-session-accessor cador-pending-initget doc-session-pending-initget)
(%define-document-session-accessor cador-live-collection-ids doc-session-live-collection-ids)
(%define-document-session-accessor cador-entity-vla-map doc-session-entity-vla-map)
(%define-document-session-accessor cador-ldata-store doc-session-ldata-store)
(%define-document-session-accessor cador-open-complex-handle doc-session-open-complex-handle)
(%define-document-session-accessor cador-open-block-definition doc-session-open-block-definition)
(%define-document-session-accessor cador-ename-cache doc-session-ename-cache)
(%define-document-session-accessor cador-ename-cache-drawing doc-session-ename-cache-drawing)
(%define-document-session-accessor %cador-model-viewports doc-session-model-viewports)
(%define-document-session-accessor %cador-viewport-toggle doc-session-viewport-toggle)
(%define-document-session-accessor %cador-viewport-configurations doc-session-viewport-configurations)

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

(defvar *cador-in-lisp-command* nil
  "True while COMMAND runs a LISP command registered with vlax-add-cmd:
CMDACTIVE reads 1 then (bricscad-dialect-sysvar-parity, Phase 3).")
