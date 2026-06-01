(in-package #:clautolisp.ui.emacs)

;;;; The Emacs UI (spec §20). A line-oriented S-expression RPC: the debugger
;;;; writes notification forms to OUTPUT (the Emacs side reads them with
;;;; `read`); at a stopping point it reads command forms back from INPUT and
;;;; returns a resume directive. No length prefixes / encoding negotiation
;;;; (§20.1). Both streams are injectable, so the shim is testable over
;;;; string streams with no Emacs present.

(defclass emacs-ui ()
  ((input  :initarg :input  :initform *standard-input*  :accessor emacs-ui-input)
   (output :initarg :output :initform *standard-output* :accessor emacs-ui-output)))

(defun make-emacs-ui (&rest initargs)
  (apply #'make-instance 'emacs-ui initargs))

(register-ui :emacs (lambda (&rest initargs) (apply #'make-emacs-ui initargs)))
(register-ui :aldb  (lambda (&rest initargs) (apply #'make-emacs-ui initargs)))

;;; --- wire writing --------------------------------------------------

(defun write-message (ui tag &rest args)
  "Write one RPC message — the form (TAG . ARGS) — to the channel, one per
line, readable by Emacs `read`. Strings, integers, and keywords print
readably; nested wire forms are plain lists."
  (let ((stream (emacs-ui-output ui))
        (*print-readably* nil)
        (*print-pretty* nil)
        (*package* (find-package :keyword)))
    (prin1 (cons tag args) stream)
    (terpri stream)
    (force-output stream)))

(defun preview (value &optional (limit 80))
  "A human-readable one-line string for a value (the Emacs side shows it;
it is never read back as code)."
  (let ((string (handler-case (prin1-to-string value) (error () "#<?>"))))
    (if (> (length string) limit)
        (concatenate 'string (subseq string 0 limit) "…")
        string)))

(defun source-position->wire (position)
  "Serialize a source position to (:pos FILE START-LINE START-COL) or NIL."
  (when (source-position-p position)
    (list :pos
          (source-position-file position)
          (source-position-start-line position)
          (source-position-start-column position))))

(defun frame->wire (frame index)
  (list :frame index
        (or (stack-frame-function-name frame) "?")
        (source-position->wire (stack-frame-source-position frame))))

(defun bindings->wire (snapshot)
  "Visible bindings as (NAME PREVIEW) pairs — names and printed previews
are strings, so the Emacs side never evaluates them."
  (loop for (symbol . value) in (snapshot-visible-names snapshot)
        collect (list (autolisp-symbol-name symbol) (preview value))))

(defun snapshot->wire (snapshot)
  "Serialize a snapshot to a plist of wire-safe values for the :stopped /
error messages (§20.2 buffers are populated from this)."
  (when snapshot
    (list :function (or (snapshot-function-name snapshot) "?")
          :position (source-position->wire (snapshot-source-position snapshot))
          :frames (loop for frame in (snapshot-call-stack snapshot)
                        for i from 0 collect (frame->wire frame i))
          :bindings (bindings->wire snapshot)
          :catch-depth (length (snapshot-catch-stack snapshot)))))

;;; --- notifications (debugger → Emacs) ------------------------------

(defmethod ui-attached ((ui emacs-ui) session)
  (declare (ignore session))
  (write-message ui :attached :protocol-version
                 (list (car *protocol-version*) (cdr *protocol-version*))))

(defmethod ui-detached ((ui emacs-ui))
  (write-message ui :detached))

(defmethod ui-show-message ((ui emacs-ui) level control &rest args)
  (write-message ui :message level (apply #'format nil control args)))

(defmethod ui-show-source ((ui emacs-ui) position)
  (write-message ui :show-source (source-position->wire position)))

(defmethod ui-breakpoint-added ((ui emacs-ui) bp)
  (write-message ui :breakpoint-added (breakpoint-id bp)
                 (breakpoint-fid bp) (breakpoint-form-id bp) (breakpoint-when bp)))

(defmethod ui-breakpoint-removed ((ui emacs-ui) bp)
  (write-message ui :breakpoint-removed (breakpoint-id bp)))

(defmethod ui-thread-resumed ((ui emacs-ui) session)
  (declare (ignore session))
  (write-message ui :resumed))

(defmethod ui-thread-hit ((ui emacs-ui) session hit)
  (write-message ui (if (eq (hit-stop-reason hit) :step) :step-hit :breakpoint-hit)
                 (snapshot->wire (session-snapshot session))))

(defmethod ui-thread-unhandled-error ((ui emacs-ui) session hit)
  (write-message ui :unhandled-error
                 (hit-error-message hit) (hit-errno hit)
                 (snapshot->wire (session-snapshot session))))

(defmethod ui-thread-caught-error ((ui emacs-ui) session hit)
  (write-message ui :caught-error
                 (hit-error-message hit) (hit-errno hit)
                 (snapshot->wire (session-snapshot session))))

;;; --- the command loop (Emacs → debugger) ---------------------------

(defun read-command (ui)
  "Read one command form from the channel, or :EOF at end of input."
  (let ((*package* (find-package :keyword)))
    (handler-case (read (emacs-ui-input ui) nil :eof)
      (end-of-file () :eof))))

(defmethod ui-await-command ((ui emacs-ui) session hit)
  "Read command forms until one resumes; answer the rest with :reply
messages (§20.1). Returns the resume directive. EOF ⇒ continue."
  (write-message ui :await-command)
  (loop
    (let ((command (read-command ui)))
      (when (eq command :eof) (return :continue))
      (multiple-value-bind (directive resumep) (dispatch ui session hit command)
        (when resumep (return directive))))))

(defun dispatch (ui session hit command)
  "Interpret one command form. Returns (values directive resumep): when
RESUMEP, DIRECTIVE is the resume directive returned to the engine;
otherwise the command was answered inline and the loop keeps reading."
  (unless (consp command)
    (write-message ui :error "malformed command" (preview command))
    (return-from dispatch (values nil nil)))
  (let ((tag (first command))
        (args (rest command)))
    (case tag
      (:continue (values (cmd-continue session) t))
      (:step (values (cmd-step session (or (first args) :over)) t))
      (:abort (values (cmd-abort session) t))
      ((:quit) (values (cmd-abort session) t))
      (:return (values (return-directive ui session (first args)) t))
      (:advance (values (apply #'cmd-advance session args) t))
      (:select-frame (cmd-select-frame session (first args)) (values nil nil))
      (:eval (reply-eval ui session (first args)) (values nil nil))
      (:set-breakpoint-line (reply-set-breakpoint ui session (first args)) (values nil nil))
      (:list-breakpoints (reply-breakpoints ui session) (values nil nil))
      (:inspect (reply-inspect ui session (first args)) (values nil nil))
      (:inspector-descend (reply-descend ui session (first args)) (values nil nil))
      (:inspector-up (cmd-inspector-up session) (reply-page ui session) (values nil nil))
      (:inspector-bind (reply-bind ui session (rest command)) (values nil nil))
      (:inspector-path (reply-path ui session) (values nil nil))
      (t (write-message ui :error "unknown command" (string tag)) (values nil nil)))))

(defun parse-form (string)
  "Read the first AutoLISP form from STRING (commands carry user text)."
  (first (clautolisp.autolisp-runtime:read-runtime-from-string string)))

(defun reply-eval (ui session string)
  (handler-case
      (write-message ui :eval-result (preview (cmd-eval session (parse-form string)) 200))
    (error (e) (write-message ui :eval-error (princ-to-string e)))))

(defun return-directive (ui session string)
  (handler-case (cmd-return session (cmd-eval session (parse-form (or string "nil"))))
    (error (e) (write-message ui :error "return" (princ-to-string e)) nil)))

(defun reply-set-breakpoint (ui session line)
  (let ((bp (cmd-set-breakpoint-at-line session line)))
    (if bp
        (write-message ui :breakpoint-set (breakpoint-id bp) line)
        (write-message ui :message :warning (format nil "no poll point at line ~A" line)))))

(defun reply-breakpoints (ui session)
  (write-message ui :breakpoints
                 (loop for bp in (cmd-list-breakpoints session)
                       collect (list (breakpoint-id bp) (breakpoint-fid bp)
                                     (breakpoint-form-id bp) (breakpoint-when bp)))))

(defun reply-inspect (ui session string)
  (handler-case
      (progn
        (cmd-inspect session (cmd-eval session (parse-form string)) :origin (parse-form string))
        (reply-page ui session))
    (error (e) (write-message ui :inspect-error (princ-to-string e)))))

(defun reply-descend (ui session index)
  (handler-case (progn (cmd-inspector-descend session index) (reply-page ui session))
    (error (e) (write-message ui :inspect-error (princ-to-string e)))))

(defun page->wire (session)
  (let ((page (session-page (session-inspector session))))
    (list :type (inspect-page-type-name page)
          :header (inspect-page-header page)
          :origin (preview (session-origin (session-inspector session)))
          :path (multiple-value-bind (expr kind) (cmd-inspector-path-expression session)
                  (if (eq kind :partial)
                      (format nil "~A …(opaque)" (preview expr))
                      (preview expr)))
          :components (loop for c in (inspect-page-components page)
                            for i from 0
                            collect (list i (inspect-component-label c)
                                          (preview (inspect-component-preview c))
                                          (and (inspect-component-descendable-p c) t))))))

(defun reply-page (ui session)
  (write-message ui :inspect-page (page->wire session)))

(defun reply-bind (ui session target-args)
  (let ((target (normalize-bind-target target-args)))
    (handler-case
        (write-message ui :bound (princ-to-string (cmd-inspector-bind session target)))
      (error (e) (write-message ui :inspect-error (princ-to-string e))))))

(defun normalize-bind-target (args)
  "Map a wire bind target to a session-bind target. (:workspace) / NIL →
:workspace; (:workspace NAME) / (:setq NAME-STRING) / (:global NAME-STRING)
map through, interning name strings as AutoLISP symbols."
  (cond
    ((null args) :workspace)
    ((eq (first args) :workspace)
     (if (rest args) (list :workspace (second args)) :workspace))
    ((member (first args) '(:setq :global))
     (list (first args) (intern-autolisp-symbol (string-upcase (string (second args))))))
    (t :workspace)))

(defun reply-path (ui session)
  (multiple-value-bind (expr kind) (cmd-inspector-path-expression session)
    (write-message ui :path (preview expr) (and (eq kind :partial) t))))
