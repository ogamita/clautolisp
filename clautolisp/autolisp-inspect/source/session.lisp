(in-package #:clautolisp.inspect)

;;;; The inspector session (spec §14): the currently-displayed value, its
;;;; page, the origin S-expression, and the navigation history. Descending
;;;; records the step's accessor so SESSION-PATH-EXPRESSION can compose the
;;;; S-expression naming the current value (§15.2).

(defstruct descent-step
  value           ; the parent value (to restore on session-up)
  page            ; the parent page
  accessor)       ; how we descended from parent to child (template, or :opaque)

(defstruct inspector-session
  current
  page
  origin
  context
  workspace
  (%history '() :type list)        ; innermost first
  (path nil)                       ; last yielded path expression ($path, §16.3)
  (bind-frame-fn nil))             ; (frame symbol value) -> result; debug installs it

(defun inspect (value &key into origin context workspace bind-frame-fn)
  "Open an inspector session on VALUE (spec §14). ORIGIN is the
S-expression naming where VALUE came from; if omitted, VALUE is bound to a
fresh workspace slot and that slot name is the origin (a transient value).
INTO selects a UI sink and is recorded for the caller; CONTEXT is the eval
context for accessors and session-eval."
  (declare (ignore into))
  (let* ((ctx (or context (current-evaluation-context)))
         (ws (or workspace (make-workspace)))
         (session (make-inspector-session
                   :current value
                   :context ctx
                   :workspace ws
                   :bind-frame-fn bind-frame-fn
                   :origin (or origin (%allocate-origin ws value)))))
    (setf (inspector-session-page session) (inspect-page-for value ctx))
    session))

(defun %allocate-origin (workspace value)
  "Bind VALUE to a fresh workspace slot and return that slot name as the
origin symbol (spec §14: transient value → fresh workspace name)."
  (let ((name (next-slot-name workspace)))
    (workspace-bind workspace name value)
    (%sym name)))

;;; --- accessors mirroring the spec's session-* protocol -------------

(defun session-current (session) (inspector-session-current session))
(defun session-page (session) (inspector-session-page session))
(defun session-origin (session) (inspector-session-origin session))

(defun session-history (session)
  "The navigation history as (value page accessor) steps, outermost first."
  (reverse (inspector-session-%history session)))

;;; --- navigation ----------------------------------------------------

(defun session-down (session index)
  "Descend into component INDEX of the current page; return the new
current value. The component's accessor is appended to the path (§14)."
  (let* ((page (inspector-session-page session))
         (component (nth index (inspect-page-components page))))
    (unless component
      (error "No component at index ~D." index))
    (unless (inspect-component-descendable-p component)
      (error "Component ~D (~A) is not descendable."
             index (inspect-component-label component)))
    (push (make-descent-step :value (inspector-session-current session)
                             :page page
                             :accessor (inspect-component-accessor component))
          (inspector-session-%history session))
    (let ((value (inspect-component-value component)))
      (setf (inspector-session-current session) value
            (inspector-session-page session)
            (inspect-page-for value (inspector-session-context session)))
      value)))

(defun session-up (session)
  "Pop one navigation step, returning to the parent value (spec §14).
Returns the restored current value, or NIL if already at the origin."
  (let ((step (pop (inspector-session-%history session))))
    (when step
      (setf (inspector-session-current session) (descent-step-value step)
            (inspector-session-page session) (descent-step-page step))
      (inspector-session-current session))))

;;; --- path expression (spec §15.2) ----------------------------------

(defun session-path-expression (session)
  "Return the S-expression that names the currently-displayed value from
the session's origin, by folding the accessor chain (substituting `_` at
each step). If a step's accessor is :opaque, return (values partial
:partial) — the expression up to the last fully-expressible point."
  (let ((expr (inspector-session-origin session)))
    (dolist (step (session-history session))    ; outermost first
      (let ((accessor (descent-step-accessor step)))
        (when (eq accessor :opaque)
          (setf (inspector-session-path session) expr)
          (return-from session-path-expression (values expr :partial)))
        ;; Fold EXPR into this step's accessor with SUBSTITUTE-PLACEHOLDER
        ;; (fresh consing), never CL:SUBST: page accessors share the one
        ;; interned `_` symbol, and SUBST's structure sharing would splice
        ;; EXPR into shared structure and build a CIRCULAR path (DN-8).
        (setf expr (substitute-placeholder expr accessor))))
    (setf (inspector-session-path session) expr)
    expr))

;;; --- eval in the session (spec §14, §16.2) -------------------------

(defun session-eval (session form)
  "Evaluate FORM in the session's context with the currently-displayed
value bound to `*` and `$0`, and every workspace slot $N bound to its
value (spec §16.2). Resolution of these names is inspector-side, in a
temporary dynamic frame; *debugging* is off so the evaluation cannot
re-enter the debugger."
  (let ((context (inspector-session-context session)))
    (push-dynamic-frame context)
    (unwind-protect
         (let ((current (inspector-session-current session)))
           (bind-dynamic-variable (%sym "*") current context)
           (bind-dynamic-variable (%sym "$0") current context)
           (loop for (name . value) in (workspace-list (inspector-session-workspace session))
                 do (bind-dynamic-variable (%sym name) value context))
           (let ((*debugging* nil))
             (autolisp-eval form context)))
      (pop-dynamic-frame context))))

;;; --- binding the displayed value to a name (spec §16.1) ------------

(defun session-bind (session target)
  "Store the currently-displayed value under a name and return the name.
TARGET is one of:
  :workspace            next free slot $N (default; AutoLISP untouched)
  (:workspace NAME)     a chosen workspace slot
  (:global SYMBOL)      (setq SYMBOL value) in the global namespace
  (:setq SYMBOL)        frame-aware setq at the stopping point
  (:frame FRAME SYMBOL) rewrite SYMBOL's binding in FRAME (debugger-only)"
  (let ((value (inspector-session-current session))
        (workspace (inspector-session-workspace session))
        (context (inspector-session-context session)))
    (cond
      ((eq target :workspace)
       (let ((name (next-slot-name workspace)))
         (workspace-bind workspace name value)
         name))
      ((and (consp target) (eq (first target) :workspace))
       (workspace-bind workspace (second target) value))
      ((and (consp target) (eq (first target) :global))
       (current-document-namespace-set (second target) value context)
       (second target))
      ((and (consp target) (eq (first target) :setq))
       (set-variable (second target) value context)
       (second target))
      ((and (consp target) (eq (first target) :frame))
       (let ((writer (inspector-session-bind-frame-fn session)))
         (unless writer
           (error "Frame binding requires a debugger-provided writer (no debug session)."))
         (funcall writer (second target) (third target) value)))
      (t (error "Unknown bind target ~S." target)))))
