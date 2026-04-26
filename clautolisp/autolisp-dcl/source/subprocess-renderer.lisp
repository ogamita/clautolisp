(in-package #:clautolisp.autolisp-dcl)

;;;; Phase 15b — subprocess renderer.
;;;;
;;;; Spawns an external GUI driver (e.g. clautolisp-gui-qt) and
;;;; speaks the sexp wire protocol to it. The driver is selected
;;;; by setting the CLAUTOLISP_GUI environment variable (or by
;;;; passing :command at construction time). The renderer is
;;;; agnostic about which GUI toolkit the driver wraps; everything
;;;; is funnelled through the sexp protocol defined in
;;;; sexp-wire.lisp.
;;;;
;;;; Lifecycle:
;;;;   1. open-fn       -> spawn the subprocess (lazy, on first use)
;;;;                       and send (:open-dialog DID NAME TILE).
;;;;   2. set-tile-fn   -> (:set-tile DID KEY VALUE)
;;;;   3. mode-fn       -> (:mode-tile DID KEY MODE)
;;;;   4. focus-fn      -> (:focus DID KEY)
;;;;   5. run-fn        -> drain incoming events, invoke fire-action
;;;;                       on (:action ...) and exit when (:done DID
;;;;                       STATUS) arrives or the subprocess exits.
;;;;   6. close-fn      -> (:close-dialog DID STATUS) and, if no
;;;;                       dialogs remain, (:bye) + reap.

(defvar *subprocess-renderer-process* nil
  "uiop:launch-program info for the active subprocess driver, or
nil if none is running.")

(defvar *subprocess-renderer-command* nil
  "Command line used to spawn the subprocess driver. Set by
make-subprocess-renderer.")

(defvar *subprocess-renderer-active-dialogs* (make-hash-table :test #'eql)
  "Tracks which dialog ids have been announced to the subprocess
so that we know when to shut it down.")

(defun subprocess-input-stream ()
  (uiop:process-info-input *subprocess-renderer-process*))

(defun subprocess-output-stream ()
  (uiop:process-info-output *subprocess-renderer-process*))

(defun ensure-subprocess-running ()
  (unless (and *subprocess-renderer-process*
               (uiop:process-alive-p *subprocess-renderer-process*))
    (unless *subprocess-renderer-command*
      (signal-sexp-wire-error
       "no GUI driver command configured; set CLAUTOLISP_GUI."))
    (setf *subprocess-renderer-process*
          (uiop:launch-program *subprocess-renderer-command*
                               :input :stream
                               :output :stream
                               :error-output :inherit))
    (write-sexp-message
     (list :hello *sexp-protocol-version*)
     (subprocess-input-stream))))

(defun subprocess-shutdown ()
  (when (and *subprocess-renderer-process*
             (uiop:process-alive-p *subprocess-renderer-process*))
    (handler-case
        (write-sexp-message '(:bye) (subprocess-input-stream))
      (error () nil))
    (handler-case
        (uiop:wait-process *subprocess-renderer-process*)
      (error () nil)))
  (setf *subprocess-renderer-process* nil)
  (clrhash *subprocess-renderer-active-dialogs*))

(defun subprocess-open-dialog (dialog)
  (ensure-subprocess-running)
  (setf (gethash (dcl-dialog-id dialog)
                 *subprocess-renderer-active-dialogs*)
        t)
  (write-sexp-message
   (list :open-dialog
         (dcl-dialog-id dialog)
         (or (tile-attribute (dcl-dialog-tile dialog) "label") "(dialog)")
         (tile->sexp (dcl-dialog-tile dialog)))
   (subprocess-input-stream)))

(defun subprocess-close-dialog (dialog)
  (when (and *subprocess-renderer-process*
             (uiop:process-alive-p *subprocess-renderer-process*))
    (handler-case
        (write-sexp-message
         (list :close-dialog
               (dcl-dialog-id dialog)
               (dcl-dialog-status dialog))
         (subprocess-input-stream))
      (error () nil)))
  (remhash (dcl-dialog-id dialog) *subprocess-renderer-active-dialogs*)
  (when (zerop (hash-table-count *subprocess-renderer-active-dialogs*))
    (subprocess-shutdown)))

(defun subprocess-set-tile (dialog key value)
  (when (and *subprocess-renderer-process*
             (uiop:process-alive-p *subprocess-renderer-process*))
    (write-sexp-message
     (list :set-tile (dcl-dialog-id dialog) key value)
     (subprocess-input-stream))))

(defun subprocess-focus-tile (dialog key)
  (when (and *subprocess-renderer-process*
             (uiop:process-alive-p *subprocess-renderer-process*))
    (write-sexp-message
     (list :focus (dcl-dialog-id dialog) key)
     (subprocess-input-stream))))

(defun subprocess-mode-tile (dialog key mode)
  (when (and *subprocess-renderer-process*
             (uiop:process-alive-p *subprocess-renderer-process*))
    (write-sexp-message
     (list :mode-tile (dcl-dialog-id dialog) key mode)
     (subprocess-input-stream))))

(defun subprocess-run-dialog (dialog)
  "Drain upstream messages from the subprocess until done or EOF.
Returns the dialog's terminal status."
  (loop
    (when (dcl-dialog-finished-p dialog)
      (return (dcl-dialog-status dialog)))
    (unless (and *subprocess-renderer-process*
                 (uiop:process-alive-p *subprocess-renderer-process*))
      (return 0))
    (let ((message (handler-case (read-sexp-message
                                  (subprocess-output-stream))
                     (error () :eof))))
      (cond
        ((eq message :eof) (return 0))
        ((not (consp message)) nil)
        (t
         (case (first message)
           (:action
            (destructuring-bind (&optional did key value reason)
                (rest message)
              (declare (ignore did))
              (when (and key reason)
                (dcl-runtime-fire-action dialog key (or value "")
                                          (or reason :reason-selected)))))
           (:done
            (destructuring-bind (&optional did status) (rest message)
              (declare (ignore did))
              (setf (dcl-dialog-status dialog) (or status 0)
                    (dcl-dialog-finished-p dialog) t)))
           (:error
            ;; Driver reported an error: just bail out.
            (return 0))
           (:hello nil)
           (otherwise nil)))))))

(defun resolve-gui-command (command)
  (cond
    (command command)
    (t (let ((env (uiop:getenv "CLAUTOLISP_GUI")))
         (when (and env (plusp (length env)))
           (uiop:split-string env :separator '(#\Space)))))))

(defun make-subprocess-renderer (&key command)
  "Build a dcl-renderer that funnels every event through the sexp
wire protocol to a subprocess. COMMAND is a list (PROGRAM ARGS...);
when omitted, CLAUTOLISP_GUI is consulted."
  (setf *subprocess-renderer-command* (resolve-gui-command command))
  (make-dcl-renderer
   :open-fn      #'subprocess-open-dialog
   :close-fn     #'subprocess-close-dialog
   :set-tile-fn  #'subprocess-set-tile
   :focus-fn     #'subprocess-focus-tile
   :mode-fn      #'subprocess-mode-tile
   :run-fn       #'subprocess-run-dialog))
