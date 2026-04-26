(in-package #:clautolisp.autolisp-dcl)

;;;; DCL runtime: loaded sources, dialog instances, action dispatch.
;;;;
;;;; The renderer (terminal, GUI subprocess, McCLIM, etc.) is
;;;; pluggable via `*dcl-renderer*` — a generic-function-style
;;;; dispatch object that responds to a small message protocol.
;;;; A no-op renderer ships by default; the terminal renderer
;;;; lives in terminal.lisp; future GUI backends drop in via
;;;; (install-default-renderer ...).

;;; --- Predefined tile registry ------------------------------------

(defparameter *predefined-tiles*
  (make-hash-table :test #'equalp)
  "Registry of predefined DCL tile classes (the ones AutoCAD
ships in `base.dcl`). Each entry maps a class-name string to a
function (lambda () -> dcl-tile) that constructs a fresh
instance. Examples: ok_only, ok_cancel, ok_cancel_help,
errtile, retirement_button, …")

(defun register-predefined-tile (name builder)
  (setf (gethash name *predefined-tiles*) builder)
  name)

(defun expand-predefined-tile (tile)
  "If TILE is a reference to a predefined class (no children, no
local attributes), expand it into the registered template."
  (let ((builder (gethash (string (dcl-tile-type tile))
                          *predefined-tiles*)))
    (cond
      ((and builder
            (null (dcl-tile-children tile))
            (null (dcl-tile-attributes tile)))
       (funcall builder))
      (t tile))))

;;; --- Renderer protocol ------------------------------------------

(defparameter *dcl-renderer* nil
  "Process-wide DCL renderer object. The runtime sends it the
following messages via funcall on the appropriate slot:

  :open-dialog DIALOG
  :close-dialog DIALOG
  :set-tile DIALOG KEY VALUE
  :focus-tile DIALOG KEY
  :update-mode DIALOG KEY MODE
  :run DIALOG -> integer status

Renderers are responsible for delivering action events back into
the dialog via dcl-runtime-fire-action; the runtime is a passive
state machine.")

(defstruct dcl-renderer
  (open-fn       (lambda (d) (declare (ignore d)) nil))
  (close-fn      (lambda (d) (declare (ignore d)) nil))
  (set-tile-fn   (lambda (d k v) (declare (ignore d k v)) nil))
  (focus-fn      (lambda (d k) (declare (ignore d k)) nil))
  (mode-fn       (lambda (d k m) (declare (ignore d k m)) nil))
  ;; Run-fn returns the dialog's terminal status integer (1 = OK,
  ;; 0 = Cancel, anything else = user-supplied done_dialog status).
  ;; The runtime calls run-fn from inside dcl-runtime-start-dialog
  ;; and uses the return value as the dialog's exit status.
  (run-fn        (lambda (d) (declare (ignore d)) 0)))

(defun current-dcl-renderer ()
  (or *dcl-renderer* (make-noop-renderer)))

(defun install-default-renderer (renderer)
  (setf *dcl-renderer* renderer))

(defun make-noop-renderer ()
  (make-dcl-renderer))

;;; --- Source / dialog tables ------------------------------------

(defparameter *next-dcl-id* 0)
(defparameter *loaded-sources* (make-hash-table :test #'eql))
(defparameter *active-dialogs* (make-hash-table :test #'eql))

(defun fresh-dcl-id ()
  (let ((n *next-dcl-id*))
    (incf *next-dcl-id*)
    n))

;;; --- Public API ------------------------------------------------

(defun dcl-runtime-load-dialog (path)
  "Parse PATH and return the integer handle assigned to the
loaded source. Returns nil on parse error."
  (handler-case
      (let* ((tiles (parse-dcl-from-file path))
             (id (fresh-dcl-id))
             (source (make-dcl-source :id id :path path :tiles tiles)))
        (setf (gethash id *loaded-sources*) source)
        id)
    (dcl-parse-error () nil)
    (file-error () nil)))

(defun dcl-runtime-unload-dialog (id)
  (remhash id *loaded-sources*)
  nil)

(defun find-loaded-source (id)
  (or (gethash id *loaded-sources*)
      (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
       :unknown-dcl-handle
       "No DCL source is loaded under handle ~A." id)))

(defun lookup-tile-class (source name)
  (cdr (assoc name (dcl-source-tiles source) :test #'string-equal)))

(defun dcl-runtime-new-dialog (source-id name &key (key nil))
  "Construct a dialog instance from SOURCE-ID's tile class NAME.
Returns the dialog's id. KEY is currently ignored (Phase 15a
does not implement nested dialogs)."
  (declare (ignore key))
  (let* ((source (find-loaded-source source-id))
         (tile (lookup-tile-class source name))
         (id (fresh-dcl-id)))
    (unless tile
      (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
       :unknown-dcl-tile
       "DCL source ~A has no tile class named ~A." source-id name))
    (let ((dialog (make-dcl-dialog :id id :source source
                                   :tile (deep-copy-tile tile)
                                   :focus nil)))
      (initialise-dialog-state dialog)
      (setf (gethash id *active-dialogs*) dialog)
      (funcall (dcl-renderer-open-fn (current-dcl-renderer)) dialog)
      id)))

(defun deep-copy-tile (tile)
  (make-dcl-tile :type (dcl-tile-type tile)
                 :key (dcl-tile-key tile)
                 :attributes (mapcar (lambda (entry) (cons (car entry) (cdr entry)))
                                     (dcl-tile-attributes tile))
                 :children (mapcar #'deep-copy-tile
                                    (mapcar #'expand-predefined-tile
                                            (dcl-tile-children tile)))
                 :source (dcl-tile-source tile)))

(defun initialise-dialog-state (dialog)
  (let ((state (dcl-dialog-state dialog)))
    (labels ((walk (tile)
               (let ((key (or (dcl-tile-key tile)
                              (tile-attribute tile "key"))))
                 (when key
                   (setf (gethash key state)
                         (or (tile-attribute tile "value") "")))
                 (dolist (child (dcl-tile-children tile)) (walk child)))))
      (walk (dcl-dialog-tile dialog)))))

(defun find-active-dialog (id)
  (or (gethash id *active-dialogs*)
      (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
       :unknown-dialog-handle
       "No active DCL dialog under handle ~A." id)))

(defun dcl-runtime-start-dialog (dialog-id)
  "Ask the active renderer to drive DIALOG-ID's interaction loop.
Blocks until the renderer signals done_dialog (or its equivalent
exit). Returns the dialog's terminal status integer."
  (let* ((dialog (find-active-dialog dialog-id))
         (renderer (current-dcl-renderer))
         (status (funcall (dcl-renderer-run-fn renderer) dialog)))
    ;; Done — close out and return the recorded status.
    (unless (dcl-dialog-finished-p dialog)
      (setf (dcl-dialog-status dialog) status))
    (funcall (dcl-renderer-close-fn renderer) dialog)
    (remhash dialog-id *active-dialogs*)
    (dcl-dialog-status dialog)))

(defun dcl-runtime-done-dialog (dialog-id &optional (status 1))
  (let ((dialog (find-active-dialog dialog-id)))
    (setf (dcl-dialog-status dialog) status
          (dcl-dialog-finished-p dialog) t)
    status))

(defun dcl-runtime-action-tile (dialog-id key callback)
  (let ((dialog (find-active-dialog dialog-id)))
    (setf (gethash key (dcl-dialog-actions dialog)) callback)
    callback))

(defun dcl-runtime-find-tile (dialog key)
  "Locate the tile with KEY in DIALOG's tile tree, or nil."
  (labels ((walk (tile)
             (cond
               ((or (and (dcl-tile-key tile) (string= (dcl-tile-key tile) key))
                    (let ((k (tile-attribute tile "key")))
                      (and k (string= k key))))
                tile)
               (t (some #'walk (dcl-tile-children tile))))))
    (walk (dcl-dialog-tile dialog))))

(defun dcl-runtime-set-tile (dialog-id key value)
  (let ((dialog (find-active-dialog dialog-id)))
    (setf (gethash key (dcl-dialog-state dialog)) value)
    (funcall (dcl-renderer-set-tile-fn (current-dcl-renderer))
             dialog key value)
    value))

(defun dcl-runtime-get-tile (dialog-id key)
  (gethash key (dcl-dialog-state (find-active-dialog dialog-id)) ""))

(defun dcl-runtime-mode-tile (dialog-id key mode)
  (let ((dialog (find-active-dialog dialog-id)))
    (setf (gethash key (dcl-dialog-modes dialog)) mode)
    (funcall (dcl-renderer-mode-fn (current-dcl-renderer)) dialog key mode)
    nil))

(defun dcl-runtime-client-data (dialog-id key)
  (gethash key (dcl-dialog-client (find-active-dialog dialog-id))))

(defun dcl-runtime-set-client-data (dialog-id key value)
  (setf (gethash key
                 (dcl-dialog-client (find-active-dialog dialog-id)))
        value))

(defun dcl-runtime-fire-action (dialog key value reason)
  "Invoked by the renderer when a tile fires its action. Looks up
the registered AutoLISP callback (a list of forms or a callable)
and invokes it. Sets *$key$*, *$value$*, *$reason$* per the
AutoLISP DCL contract. The callback may call done_dialog;
afterwards `dcl-dialog-finished-p` is t."
  (let* ((callback (gethash key (dcl-dialog-actions dialog)))
         (key-symbol (clautolisp.autolisp-runtime:intern-autolisp-symbol "$KEY$"))
         (value-symbol (clautolisp.autolisp-runtime:intern-autolisp-symbol "$VALUE$"))
         (reason-symbol (clautolisp.autolisp-runtime:intern-autolisp-symbol "$REASON$"))
         (data-symbol (clautolisp.autolisp-runtime:intern-autolisp-symbol "$DATA$")))
    (when callback
      (clautolisp.autolisp-runtime:set-variable
       key-symbol (clautolisp.autolisp-runtime:make-autolisp-string key))
      (clautolisp.autolisp-runtime:set-variable
       value-symbol (clautolisp.autolisp-runtime:make-autolisp-string (or value "")))
      (clautolisp.autolisp-runtime:set-variable
       reason-symbol reason)
      (clautolisp.autolisp-runtime:set-variable
       data-symbol (or (gethash key (dcl-dialog-client dialog)) nil))
      (cond
        ;; A string callback: parse and evaluate as a sequence of
        ;; AutoLISP forms (this is how AutoCAD's action_tile is
        ;; documented — the second argument is a *string* of code).
        ((typep callback 'clautolisp.autolisp-runtime:autolisp-string)
         (let* ((source (clautolisp.autolisp-runtime:autolisp-string-value callback))
                (forms (clautolisp.autolisp-runtime:read-runtime-from-string
                        source :source-name "<dcl-action>")))
           (clautolisp.autolisp-runtime:autolisp-eval-progn forms)))
        ;; Already a callable subr / usubr / lambda form.
        (t
         (clautolisp.autolisp-runtime:call-autolisp-function callback))))))

;;; --- Predefined tiles registry seed ----------------------------

(defun register-predefined-button (name &key label is-cancel is-default
                                              is-help mnemonic key)
  (register-predefined-tile name
   (lambda ()
     (make-dcl-tile :type :button
                    :key (or key name)
                    :attributes (list (cons "label" (or label name))
                                      (cons "is_cancel" is-cancel)
                                      (cons "is_default" is-default)
                                      (cons "is_help" is-help)
                                      (cons "mnemonic" mnemonic))))))

(defun register-predefined-row (name children)
  (register-predefined-tile name
   (lambda ()
     (make-dcl-tile :type :row
                    :children (mapcar (lambda (c) (funcall c)) children)))))

;; Real DCL ships these in BASE.DCL; we hard-code the canonical few.
(eval-when (:load-toplevel :execute)
  (register-predefined-button "ok_button"
                               :label "OK" :is-default t :key "accept")
  (register-predefined-button "cancel_button"
                               :label "Cancel" :is-cancel t :key "cancel")
  (register-predefined-button "help_button"
                               :label "Help" :is-help t :key "help")
  (register-predefined-row "ok_only"
                            (list (lambda ()
                                    (funcall (gethash "ok_button"
                                                       *predefined-tiles*)))))
  (register-predefined-row "ok_cancel"
                            (list (lambda () (funcall (gethash "ok_button" *predefined-tiles*)))
                                  (lambda () (funcall (gethash "cancel_button" *predefined-tiles*)))))
  (register-predefined-row "ok_cancel_help"
                            (list (lambda () (funcall (gethash "ok_button" *predefined-tiles*)))
                                  (lambda () (funcall (gethash "cancel_button" *predefined-tiles*)))
                                  (lambda () (funcall (gethash "help_button" *predefined-tiles*))))))
