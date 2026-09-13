(in-package #:clautolisp.cadtui)

;;;; The cadtui UI-node tree model (Phase 1).
;;;;
;;;; A cadtui host presents the CAD application as a tree of UI-NODEs. This
;;;; file lands the CLOS model exactly as sketched in the spec (§"Modèle de
;;;; données"): the generic UI-NODE base carrying the five node attributes the
;;;; whole dump/navigation/interaction machinery keys on
;;;; (KEY/ROLE/LABEL/STATE/ACTION) plus the tree links (PARENT/CHILDREN), and a
;;;; subclass per node role. Subclasses add only the slots a particular role
;;;; needs for detailed rendering; those slots stay NIL stubs until the later
;;;; phase that exercises them (the entity view, the consoles, DCL, ...). The
;;;; tree walker never touches subclass slots — only the generic attributes and
;;;; CHILDREN — so every later mechanic stays role-agnostic.
;;;;
;;;; Phase 1 is headless: no rendering, no interaction language, no threads.

;;; --- The generic node ---------------------------------------------

(defclass ui-node ()
  ((key      :initarg :key      :reader ui-key
             :documentation "A stable, sibling-unique identity for this node
(a string or symbol). Stable means it survives redisplay and window switches,
so a later dump can address the node by a path that does not depend on focus.")
   (role     :initarg :role     :reader ui-role
             :documentation "The node's kind, a keyword (:application :menu
:button :entity ...). These canonical role tokens are English; a locale layer
(Phase 7, gated on LANG) maps localised surface tokens to them. Set per subclass
via :default-initargs; the dump renders it as the leading ROLE:KEY token.")
   (label    :initarg :label    :initform nil :reader ui-label
             :documentation "A human-readable label for display, or NIL.")
   (state    :initarg :state    :initform :normal :accessor ui-state
             :documentation "Display state (canonical English keyword):
:normal :grayed :checked :focus :selected ...")
   (action   :initarg :action   :initform nil :reader ui-action
             :documentation "For executable nodes: the associated AutoLISP
command name or a Lisp closure; NIL for inert nodes.")
   (parent   :initarg :parent   :initform nil :accessor ui-parent
             :documentation "The containing node, or NIL for a root.")
   (children :initarg :children :initform nil :accessor ui-children
             :documentation "Child nodes in order; the canonical tree
structure the walker traverses."))
  (:documentation "Base class for every cadtui UI tree node. All generic tree
mechanics act only on KEY/ROLE/LABEL/STATE/ACTION/CHILDREN."))

;;; --- Role subclasses ----------------------------------------------
;;;
;;; Each carries :default-initargs :role so MAKE-INSTANCE without an explicit
;;; :role gets the canonical role keyword. Stub slots are :initform nil until a
;;; later phase gives them behaviour (kept per the spec's CLOS sketch).

(defclass ui-application (ui-node)
  ((menubar  :initarg :menubar  :initform nil :accessor ui-menubar-slot)
   (drawings :initarg :drawings :initform nil :accessor ui-drawings-slot)
   (console  :initarg :console  :initform nil :accessor ui-console-slot))
  (:default-initargs :role :application)
  (:documentation "The tree root, /application (spec §Architecture)."))

(defclass ui-menubar (ui-node) ()
  (:default-initargs :role :menu-bar))

(defclass ui-menu (ui-node) ()
  (:default-initargs :role :menu))

(defclass ui-menu-item (ui-node) ()
  (:default-initargs :role :item))

(defclass ui-drawing (ui-node)
  ((filename      :initarg :filename      :initform nil :accessor ui-filename)
   (bands         :initarg :bands         :initform nil :accessor ui-bands-slot)
   (local-menus   :initarg :local-menus   :initform nil :accessor ui-local-menus-slot)
   (view          :initarg :view          :initform nil :accessor ui-view-slot)
   (alerts        :initarg :alerts        :initform nil :accessor ui-alerts-slot)
   (dialogs       :initarg :dialogs       :initform nil :accessor ui-dialogs-slot)
   (console       :initarg :console       :initform nil :accessor ui-drawing-console-slot)
   (lisp-namespace :initarg :lisp-namespace :initform nil :accessor ui-lisp-namespace))
  (:default-initargs :role :drawing)
  (:documentation "One drawing (MDI document); its per-document Lisp namespace
is strictly isolated from other drawings (spec §Communication inter-dessins)."))

(defclass ui-band (ui-node)
  ((style :initarg :style :initform :toolbar :accessor ui-band-style))
  (:default-initargs :role :band)
  (:documentation "A toolbar or ribbon band; STYLE is :toolbar or :ribbon."))

(defclass ui-button (ui-node) ()
  (:default-initargs :role :button))

(defclass ui-ribbon-tab (ui-node) ()
  (:default-initargs :role :ribbon-tab))

(defclass ui-ribbon-panel (ui-node) ()
  (:default-initargs :role :ribbon-panel))

(defclass ui-cad-view (ui-node)
  ((viewport  :initarg :viewport  :initform nil :accessor ui-viewport)
   (selection :initarg :selection :initform nil :accessor ui-selection))
  (:default-initargs :role :cad-view))

(defclass ui-entity (ui-node)
  ((entity-type :initarg :entity-type :initform nil :accessor ui-entity-type)
   (layer       :initarg :layer       :initform nil :accessor ui-layer)
   (properties  :initarg :properties  :initform nil :accessor ui-properties)
   (handles     :initarg :handles     :initform nil :accessor ui-handles))
  (:default-initargs :role :entity))

(defclass ui-grip (ui-node)
  ((index :initarg :index :initform nil :accessor ui-grip-index)
   (point :initarg :point :initform nil :accessor ui-grip-point))
  (:default-initargs :role :grip))

(defclass ui-alert (ui-node)
  ((severity :initarg :severity :initform nil :accessor ui-severity)
   (message  :initarg :message  :initform nil :accessor ui-message))
  (:default-initargs :role :alert))

(defclass ui-dialog (ui-node)
  ((dcl-source :initarg :dcl-source :initform nil :accessor ui-dcl-source)
   (tiles      :initarg :tiles      :initform nil :accessor ui-tiles-slot))
  (:default-initargs :role :dialog))

(defclass ui-tile (ui-node)
  ((tile-type :initarg :tile-type :initform nil :accessor ui-tile-type)
   (value     :initarg :value     :initform nil :accessor ui-tile-value))
  (:default-initargs :role :tile))

(defclass ui-console (ui-node)
  ((stream-buffer     :initarg :stream-buffer     :initform nil :accessor ui-stream-buffer)
   (input-zone        :initarg :input-zone        :initform nil :accessor ui-input-zone)
   ;; queue of pass-through lines awaiting a not-yet-reading thread (Phase 4):
   ;; a runtime park-mailbox (blocking FIFO of whole lines) — the type-ahead
   ;; buffer of spec §"Classification des lignes et tamponnage".
   (lignes-en-attente :initarg :lignes-en-attente :initform nil :accessor ui-lignes-en-attente)
   ;; The runtime scheduled-context backing this console (Phase 4): its thread is
   ;; the console's AutoLISP thread, its evaluation-context carries the isolated
   ;; per-drawing document namespace. NIL until the console is given a context.
   (context           :initarg :context           :initform nil :accessor ui-context)
   ;; suspended/woken, never killed (Phase 4, on the runtime scheduler).
   (lisp-thread       :initarg :lisp-thread       :initform nil :accessor ui-lisp-thread)
   (debug-thread      :initarg :debug-thread      :initform nil :accessor ui-debug-thread))
  (:default-initargs :role :console)
  (:documentation "A console: a history stream + an input zone + an isolated
Lisp namespace. One per drawing, plus one at /application (spec §Consoles)."))

;;; --- Conditions ---------------------------------------------------

(define-condition cadtui-error (error) ()
  (:documentation "Base class for cadtui errors."))

(define-condition duplicate-sibling-key (cadtui-error)
  ((parent :initarg :parent :reader duplicate-sibling-key-parent)
   (key    :initarg :key    :reader duplicate-sibling-key-key))
  (:report (lambda (condition stream)
             (format stream "A child with key ~S already exists under ~S."
                     (duplicate-sibling-key-key condition)
                     (duplicate-sibling-key-parent condition))))
  (:documentation "Signalled by ADD-CHILD when a sibling already carries the
key — sibling keys must be unique so addressing stays stable."))

;;; --- Tree construction / navigation -------------------------------

(defun ui-root-p (node)
  "True when NODE has no parent (it is a tree root)."
  (null (ui-parent node)))

(defun ui-find-child (parent key &key (test #'equal))
  "The child of PARENT whose UI-KEY is KEY (compared with TEST, default
EQUAL), or NIL when none."
  (find key (ui-children parent) :key #'ui-key :test test))

(defun add-child (parent child)
  "Append CHILD to PARENT's children, set CHILD's parent, and return CHILD.
Sibling keys must be unique: signal DUPLICATE-SIBLING-KEY when PARENT already
has a child with CHILD's key."
  (let ((key (ui-key child)))
    (when (ui-find-child parent key)
      (error 'duplicate-sibling-key :parent parent :key key))
    (setf (ui-parent child) parent
          (ui-children parent) (append (ui-children parent) (list child))))
  child)
