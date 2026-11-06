(in-package #:clautolisp.cadtui)

;;;; Menu bar and bands from a data description (Phase 6).
;;;;
;;;; A cadtui host loads its menu bar and its bands (toolbars / ribbons) from a
;;;; DATA description -- the simplified CUIX/MNU of the spec (§Roadmap 6): every
;;;; interactive node associates a label with a Lisp function or CAD command
;;;; name, exactly the PopMenuCollection / RibbonRoot / LspFileCollection idea of
;;;; a CUIX MenuGroup (spec §"Étude AutoCAD"). The description is data, never
;;;; code: it is a nested list of keyword-headed forms, so a dictionary/locale
;;;; layer (Phase 7) can translate the labels without touching a grammar.
;;;;
;;;; Grammar (canonical, label strings, English keywords):
;;;;   menu-bar ::= (:menu-bar menu*)
;;;;   menu     ::= (:menu   LABEL (item | menu | separator)*)
;;;;   item     ::= (:item   LABEL [:action A] [:state S])
;;;;   separator::= (:separator)
;;;;   band     ::= (:band   LABEL [:style :toolbar|:ribbon] element*)
;;;;                  toolbar element ::= button
;;;;                  ribbon  element ::= tab
;;;;   tab      ::= (:tab    LABEL panel*)
;;;;   panel    ::= (:panel  LABEL button*)
;;;;   button   ::= (:button LABEL [:action A] [:state S])
;;;; A node's KEY is its LABEL (spec addresses menus/items/buttons by label);
;;;; ACTION is a CAD command name string or a Lisp function/closure.

;;; --- Condition ----------------------------------------------------

(define-condition ui-description-error (cadtui-error)
  ((form   :initarg :form   :reader ui-description-error-form)
   (reason :initarg :reason :reader ui-description-error-reason))
  (:report (lambda (condition stream)
             (format stream "Bad UI description ~S: ~A"
                     (ui-description-error-form condition)
                     (ui-description-error-reason condition))))
  (:documentation "Signalled when a menu-bar/band description is malformed."))

(defun %desc-error (form reason &rest args)
  (error 'ui-description-error :form form :reason (apply #'format nil reason args)))

(defun %desc-label (form what)
  "The label string that must be FORM's second element."
  (let ((label (second form)))
    (unless (stringp label)
      (%desc-error form "~A needs a string label" what))
    label))

(defun %desc-plist (form)
  "The option plist trailing FORM (its cddr): :action / :state pairs."
  (cddr form))

;;; --- Menu bar -----------------------------------------------------

(defun %build-item (form)
  (let ((label (%desc-label form "an :item"))
        (plist (%desc-plist form)))
    (make-instance 'ui-menu-item
                   :key label :label label
                   :action (getf plist :action)
                   :state (getf plist :state :normal))))

(defun %build-separator (index)
  (make-instance 'ui-node :key (format nil "separator-~D" index)
                          :role :separator :label "---"))

(defun %build-menu-child (form index)
  (unless (consp form)
    (%desc-error form "a menu child must be a (:item ...) / (:menu ...) / (:separator)"))
  (case (first form)
    (:item      (%build-item form))
    (:menu      (%build-menu form))          ; a nested submenu
    (:separator (%build-separator index))
    (t (%desc-error form "unknown menu child head ~S" (first form)))))

(defun %build-menu (form)
  (let* ((label (%desc-label form "a :menu"))
         (menu (make-instance 'ui-menu :key label :label label)))
    (loop for child in (cddr form)
          for i from 1
          do (add-child menu (%build-menu-child child i)))
    menu))

(defun build-menu-bar (form &key (key "menu-bar"))
  "Build a ui-menubar from FORM = (:menu-bar menu*). Every executable node
carries its :action (a CAD command name or a Lisp function)."
  (unless (and (consp form) (eq :menu-bar (first form)))
    (%desc-error form "a menu bar must be a (:menu-bar ...)"))
  (let ((bar (make-instance 'ui-menubar :key key)))
    (dolist (m (rest form) bar)
      (unless (and (consp m) (eq :menu (first m)))
        (%desc-error m "a menu-bar element must be a (:menu ...)"))
      (add-child bar (%build-menu m)))))

;;; --- Bands (toolbars / ribbons) -----------------------------------

(defun %build-button (form)
  (unless (and (consp form) (eq :button (first form)))
    (%desc-error form "a button must be a (:button ...)"))
  (let ((label (%desc-label form "a :button"))
        (plist (%desc-plist form)))
    (make-instance 'ui-button
                   :key label :label label
                   :action (getf plist :action)
                   :state (getf plist :state :normal))))

(defun %build-panel (form)
  (unless (and (consp form) (eq :panel (first form)))
    (%desc-error form "a ribbon panel must be a (:panel ...)"))
  (let* ((label (%desc-label form "a :panel"))
         (panel (make-instance 'ui-ribbon-panel :key label :label label)))
    (dolist (b (cddr form) panel)
      (add-child panel (%build-button b)))))

(defun %build-tab (form)
  (unless (and (consp form) (eq :tab (first form)))
    (%desc-error form "a ribbon band element must be a (:tab ...)"))
  (let* ((label (%desc-label form "a :tab"))
         (tab (make-instance 'ui-ribbon-tab :key label :label label)))
    (dolist (p (cddr form) tab)
      (add-child tab (%build-panel p)))))

(defun build-band (form)
  "Build a ui-band from FORM = (:band LABEL [:style :toolbar|:ribbon] element*).
A :toolbar band holds flat buttons; a :ribbon band holds tabs > panels >
buttons. STYLE defaults to :toolbar."
  (unless (and (consp form) (eq :band (first form)))
    (%desc-error form "a band must be a (:band ...)"))
  (let ((label (%desc-label form "a :band")))
    (multiple-value-bind (style elements)
        (if (eq :style (third form))
            (values (fourth form) (cddddr form))
            (values :toolbar (cddr form)))
      (unless (member style '(:toolbar :ribbon))
        (%desc-error form "band :style must be :toolbar or :ribbon, not ~S" style))
      (let ((band (make-instance 'ui-band :key label :label label :style style)))
        (dolist (element elements band)
          (add-child band (if (eq style :ribbon)
                              (%build-tab element)
                              (%build-button element))))))))

;;; --- Installation into an existing tree ---------------------------

(defun install-menu-bar (application form)
  "Replace APPLICATION's menu-bar with one built from FORM (a :menu-bar
description), keeping it first among the children (spec tree order). Returns the
new ui-menubar."
  (let ((old (ui-find-child application "menu-bar"))
        (bar (build-menu-bar form)))
    (when old
      (setf (ui-children application) (remove old (ui-children application))
            (ui-parent old) nil))
    (setf (ui-parent bar) application
          (ui-children application) (cons bar (ui-children application))
          (ui-menubar-slot application) bar)
    bar))

(defun add-band (drawing form)
  "Build a band from FORM and append it to DRAWING; returns the ui-band."
  (let ((band (build-band form)))
    (add-child drawing band)
    band))

;;; --- File-command events from the command engine (alref Phase 4 S3) ---
;;;
;;; The CAD core opens documents and reads customisation files; this side
;;; mirrors that into the tree. The core never depends on cadtui: the CLI
;;; connects APPLY-FILE-COMMAND-EVENT to its hook when --host cadtui runs.

(defun %root-active-drawing (root)
  (find :drawing (ui-children root) :key #'ui-role))

(defvar *cadtui-activate-document-function* nil
  "NIL, or a function (KEY) the CLI installs: make host document KEY current
(=activate on a drawing node). The switch takes effect at the next read, as a
NEW does; the tree follows on :DOCUMENT-ACTIVATED.")

(defvar *cadtui-close-document-function* nil
  "NIL, or a function (KEY) the CLI installs: close host document KEY (=close on
a drawing node); the tree follows on :DOCUMENT-CLOSED.")

(defun %drawing-node (root key)
  (find-if (lambda (node) (and (eq :drawing (ui-role node)) (equal key (ui-key node))))
           (ui-children root)))

(defun ensure-drawing-node (root key)
  "ROOT's ui-drawing for host document KEY, made (with its console) if missing."
  (or (%drawing-node root key)
      (let ((drawing (make-instance 'ui-drawing :key key :filename key))
            (console (make-instance 'ui-console :key "console")))
        (add-child root drawing)
        (add-child drawing console)
        drawing)))

(defun apply-file-command-event (root event &rest args)
  "Mirror a file command into ROOT. :DOCUMENT-OPENED KEY -- NEW / OPEN made
document KEY current: a ui-drawing (with its console) is added and made the
active drawing. :MENU-LOADED FORMS PATH -- MENULOAD / CUILOAD read FORMS: a
(:menu-bar ...) replaces the application's menu bar, each (:band ...) is
added to the active drawing (bands belong to a drawing; without one they
are not installed). Returns the node(s) created."
  (ecase event
    ;; A document opened (it becomes current at the switch time of the
    ;; dialect: :DOCUMENT-ACTIVATED then puts it first).
    (:document-opened
     (ensure-drawing-node root (first args)))
    (:document-activated
     (%activate-drawing (ensure-drawing-node root (first args))))
    (:document-closed
     (let ((node (%drawing-node root (first args))))
       (when node
         (setf (ui-children root) (remove node (ui-children root))
               (ui-parent node) nil))
       node))
    (:menu-loaded
     (let ((target (%root-active-drawing root)))
       (loop for form in (first args)
             when (eq (first form) :menu-bar)
               collect (install-menu-bar root form)
             when (and (eq (first form) :band) target)
               collect (add-band target form))))))
