;;;; clautolisp/autolisp-interactor/source/template.lisp
;;;;
;;;; Interactor templates (windows-and-interactor-templates.issue).
;;;;
;;;; An INTERACTOR (interactor.lisp) is the singleton "program" — a reader, an
;;;; evaluator, a prompt, two dictionaries. An INTERACTOR-TEMPLATE pairs one
;;;; with the metadata needed to INSTANTIATE it in a window: a display name and
;;;; a one-line description (for `M-x make-*-window' and the list-selector), a
;;;; CONSTRUCTOR that builds an ACTIVATION over a given TARGET within a
;;;; context, and the name of the CONFIG the activation runs under (the config
;;;; cascade, tui-core — carried here as a plain string so this dependency-free
;;;; system need not see tui-core).
;;;;
;;;; Every template is *multi-instance*: creating a window instantiates a fresh
;;;; activation. Some templates use an internal singleton (the one lisp
;;;; evaluator per image, the one aldo debugger) — that coupling is the
;;;; constructor's concern, hidden from the registry (issue, "Core design
;;;; tension"): the registry only knows how to make an activation.
;;;;
;;;; This layer is dependency-free like the rest of the framework: the window
;;;; and frame a template renders into are opaque values here (the UI layer,
;;;; which depends on both this system and tui-core, fills and uses them).

(in-package #:clautolisp.interactor)

;;; --- the context handed to a template constructor ------------------------

(defstruct (template-context (:constructor make-template-context))
  "What an INTERACTOR-TEMPLATE constructor receives. Kept generic — this
system does not depend on the window/frame layer, so WINDOW and FRAME hold
opaque values:
 - WINDOW / FRAME: the UI objects the new activation renders into (opaque);
 - STACK: the interactor stack (a list of activations) the new activation
   will sit on. Its tail is *shared* — the debugger's four windows share one
   =(aldo lisp)= bottom, so commands route through the same evaluator/debugger
   (issue §Core design tension, C);
 - TARGET: the object / form / file / stack to edit, inspect or navigate;
 - SAVE-CONTINUATION: (function (result)) invoked on an intermediate save —
   e.g. =(clal-sedit 'my-function)= redefining the function — or NIL;
 - QUIT-CONTINUATION: (function (result)) invoked with the final result when
   the activation is left — e.g. =clal-sedit= returning the edited sexp — or
   NIL."
  (window nil)
  (frame  nil)
  (stack  '())
  (target nil)
  (save-continuation nil :type (or null function-designator))
  (quit-continuation nil :type (or null function-designator)))

;;; --- the template -------------------------------------------------------

(defstruct (interactor-template (:constructor %make-interactor-template)
                                (:copier nil))
  "A window-instantiable interactor kind (issue §Interactor templates):
 - NAME: the registry key, downcased (e.g. \"sedit\");
 - DISPLAY-NAME: the human name shown in the picker / command help;
 - DESCRIPTION: a one-line description shown alongside it;
 - INTERACTOR: the singleton program (an INTERACTOR) this template activates;
 - CONSTRUCTOR: (function (template-context)) building and returning an
   ACTIVATION of INTERACTOR over the context's target/continuations;
 - CONFIG-NAME: the name of the config the activation runs under (its
   =<name>.conf= cascade), or NIL to inherit the enclosing stack's config."
  (name         ""  :type string)
  (display-name ""  :type string)
  (description  ""  :type string)
  (interactor   nil :type (or null interactor))
  (constructor  nil :type (or null function-designator))
  (config-name  nil :type (or null string)))

(defun make-interactor-template (&key name display-name description
                                      interactor constructor config-name)
  "Build an INTERACTOR-TEMPLATE named NAME (required). DISPLAY-NAME defaults to
NAME, DESCRIPTION to the empty string, CONFIG-NAME to NAME when an INTERACTOR
is given (a template runs under a config of its own name by default)."
  (check-type name (or string symbol))
  (let ((name (string-downcase (string name))))
    (%make-interactor-template
     :name name
     :display-name (or display-name name)
     :description  (or description "")
     :interactor   interactor
     :constructor  constructor
     :config-name  (or config-name (and interactor name)))))

;;; --- the registry -------------------------------------------------------

(defvar *interactor-templates* '()
  "The registered interactor templates, registration order (oldest first).
DEFINE-INTERACTOR-TEMPLATE / REGISTER-INTERACTOR-TEMPLATE populate this.")

(defun register-interactor-template (template)
  "Register TEMPLATE, replacing any same-name entry (a reload). Returns it."
  (check-type template interactor-template)
  (setf *interactor-templates*
        (append (remove (interactor-template-name template) *interactor-templates*
                        :key #'interactor-template-name :test #'equalp)
                (list template)))
  template)

(defun find-interactor-template (name)
  "The registered template named NAME (a name or an INTERACTOR-TEMPLATE),
case-insensitively; NIL when none."
  (cond ((interactor-template-p name) name)
        (name (find (string-downcase (string name)) *interactor-templates*
                    :key #'interactor-template-name :test #'equalp))))

(defun list-interactor-templates ()
  "Every registered template, registration order — the list the picker /
`M-x make-*-window' offer."
  (copy-list *interactor-templates*))

(defun interactor-template-names ()
  "The names of every registered template, registration order."
  (mapcar #'interactor-template-name *interactor-templates*))

(defun instantiate-interactor-template (name context &key existing-names)
  "Instantiate the template named NAME (a name or an INTERACTOR-TEMPLATE) over
CONTEXT (a TEMPLATE-CONTEXT): call its constructor and return the fresh
ACTIVATION. When the constructor left the activation unnamed, give it the
template's display-name as its instance name, uniquified against EXISTING-NAMES
(the live instance names the caller — a UI — already has), so several instances
of one template get distinct names (\"sedit\", \"sedit<2>\"). Signals when NAME
is unknown or the template has no constructor."
  (let ((template (or (find-interactor-template name)
                      (error "No interactor template named ~S." name))))
    (let ((constructor (interactor-template-constructor template)))
      (unless constructor
        (error "The interactor template ~S has no constructor."
               (interactor-template-name template)))
      (let ((activation (funcall constructor context)))
        (unless (activation-p activation)
          (error "The constructor of template ~S returned ~S, not an activation."
                 (interactor-template-name template) activation))
        (unless (activation-name activation)
          (setf (activation-name activation)
                (uniquify-instance-name (interactor-template-display-name template)
                                        existing-names)))
        activation))))

;;; --- definition sugar ---------------------------------------------------

(defmacro define-interactor-template (name &key display-name description
                                                interactor constructor config-name)
  "Register an interactor template named NAME (a string). INTERACTOR is the
singleton program form; CONSTRUCTOR a (function (template-context)) form
returning an activation; the rest is metadata (see MAKE-INTERACTOR-TEMPLATE).
Evaluated for effect at load time; returns the template."
  `(register-interactor-template
    (make-interactor-template
     :name ,name
     ,@(when display-name `(:display-name ,display-name))
     ,@(when description  `(:description ,description))
     ,@(when interactor   `(:interactor ,interactor))
     ,@(when constructor  `(:constructor ,constructor))
     ,@(when config-name  `(:config-name ,config-name)))))
