;;;; cadgui action layer -- SLICE 1: a central action registry, one uniform
;;;; dispatch entry point, and an introspection API. cadgui-action-layer.issue.
;;;;
;;;; The point of the epic: the layer a TEST harness drives and the layer an AI
;;;; agent drives are the SAME layer. Every user-facing operation is registered
;;;; ONCE (stable id, typed params, docstring, category) and invoked through the
;;;; single entry point CADGUI-INVOKE-ACTION -- the GUI, the CLI, scripts and an
;;;; AI driver are all just callers; nothing mutates app state by another route.
;;;;
;;;; Slice 1 delivers the registry + dispatch + introspection and registers the
;;;; existing drawing / query / selection operations. OUT of slice 1 (later
;;;; slices): typed-arg coercion/validation, the structured interaction protocol
;;;; (typed input requests + event stream), menu/ribbon/dialog surfaces, and the
;;;; CI driveability guard that FAILS the build unless every action is
;;;; registered + reachable + headlessly tested.

(in-package #:clautolisp.cadgui)

(defstruct (cadgui-action (:conc-name action-))
  (id       nil :type symbol)     ; stable keyword id, e.g. :add-line
  (params   nil)                  ; ((NAME TYPE DOC) ...), for introspection
  (doc      ""  :type string)
  (category nil :type symbol)     ; :draw :edit :view :select :query :script ...
  (fn       nil))                 ; the implementation: (apply fn args)

(defvar *cadgui-actions* (make-hash-table :test 'eq)
  "The action registry: ID -> CADGUI-ACTION. The single surface the GUI, the
-command CLI, scripts and an AI driver all invoke (CADGUI-INVOKE-ACTION) and
introspect (CADGUI-LIST-ACTIONS / CADGUI-DESCRIBE-ACTION).")

(define-condition cadgui-unknown-action (error)
  ((id :initarg :id :reader cadgui-unknown-action-id))
  (:report (lambda (c s) (format s "No cadgui action ~S." (cadgui-unknown-action-id c)))))

(defun cadgui-register-action (id &key params (doc "") category fn)
  "Register (or replace) the action ID (a keyword). PARAMS is a list of
(NAME TYPE DOC) for introspection; FN is the implementation. Returns ID."
  (check-type id keyword)
  (check-type fn (or function symbol))
  (setf (gethash id *cadgui-actions*)
        (make-cadgui-action :id id :params params :doc (or doc "")
                            :category category :fn fn))
  id)

(defun cadgui-invoke-action (id &rest args)
  "Invoke the registered action ID with ARGS. THE single dispatch entry point --
the GUI, CLI, scripts and AI driver all call this; nothing mutates app state by
another route (the invariant a later driveability guard enforces). Signals
CADGUI-UNKNOWN-ACTION when ID is not registered."
  (let ((a (gethash id *cadgui-actions*)))
    (unless a (error 'cadgui-unknown-action :id id))
    (apply (action-fn a) args)))

(defun cadgui-list-actions (&optional category)
  "Ids of all registered actions (or those in CATEGORY), sorted by name."
  (sort (loop for a being the hash-values of *cadgui-actions*
              when (or (null category) (eq category (action-category a)))
                collect (action-id a))
        #'string< :key #'symbol-name))

(defun cadgui-describe-action (id)
  "A plist (:id :category :doc :params) describing action ID, or NIL -- the
structured self-description an AI driver reads to discover what is possible."
  (let ((a (gethash id *cadgui-actions*)))
    (when a
      (list :id (action-id a) :category (action-category a)
            :doc (action-doc a) :params (action-params a)))))

;;; --- the built-in actions: the existing cadgui operations, registered once ---

(defun cadgui-register-builtin-actions ()
  "Register cadgui's built-in actions. Idempotent (re-registration replaces)."
  (cadgui-register-action
   :add-line :category :draw
   :doc "Add a LINE from (X1 Y1) to (X2 Y2) on LAYER in COLOR. Returns its ename."
   :params '((x1 real "start X") (y1 real "start Y")
             (x2 real "end X") (y2 real "end Y")
             (layer string "layer name (default \"0\")")
             (color integer "ACI colour (optional)"))
   :fn (lambda (x1 y1 x2 y2 &key (layer "0") color)
         (cadgui-add-line x1 y1 x2 y2 :layer layer :color color)))
  (cadgui-register-action
   :add-circle :category :draw
   :doc "Add a CIRCLE centred (CX CY) with radius R. Returns its ename."
   :params '((cx real "centre X") (cy real "centre Y") (r real "radius")
             (layer string "layer name (default \"0\")")
             (color integer "ACI colour (optional)"))
   :fn (lambda (cx cy r &key (layer "0") color)
         (cadgui-add-circle cx cy r :layer layer :color color)))
  (cadgui-register-action
   :eval-command :category :script
   :doc "Evaluate STRING as AutoLISP against the active drawing; returns the new scene entity count."
   :params '((string string "an AutoLISP form to evaluate"))
   :fn (lambda (string) (cadgui-eval-command string)))
  (cadgui-register-action
   :entity-count :category :query
   :doc "Number of drawable primitives currently in the scene."
   :params '()
   :fn (lambda () (cadgui-entity-count)))
  (cadgui-register-action
   :selection :category :select
   :doc "Handle string(s) of the current entsel selection, or NIL."
   :params '()
   :fn (lambda () (cadgui-selection))))

(cadgui-register-builtin-actions)         ; populate the registry at load time
