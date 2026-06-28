(in-package #:clautolisp.debug.ui)

;;;; The debugger session ties a UI to a debugged thread's state, the
;;;; current snapshot, the selected frame, an optional inspector session,
;;;; and the shared workspace. Commands (cmd-*) read/drive it; the
;;;; lifecycle entries (start-session / with-session) install the engine
;;;; hit handler that calls the UI command loop.

(defstruct debugger-session
  ui
  thread-info
  context
  workspace
  ;; mutable per-stop state
  snapshot
  current-hit
  (selected-frame 0 :type fixnum)
  inspector
  (last-step :over))

;;; --- accessors the spec names session-* (kept distinct from the
;;;     defstruct's debugger-session-* to match §17 vocabulary) --------

(defun session-ui (session) (debugger-session-ui session))
(defun session-thread-info (session) (debugger-session-thread-info session))
(defun session-context (session) (debugger-session-context session))
(defun session-workspace (session) (debugger-session-workspace session))
(defun session-snapshot (session) (debugger-session-snapshot session))
(defun session-selected-frame (session) (debugger-session-selected-frame session))
(defun session-inspector (session) (debugger-session-inspector session))
(defun session-last-step (session) (debugger-session-last-step session))

(defun current-snapshot (session)
  "The snapshot at the current stopping point, or NIL when running."
  (debugger-session-snapshot session))

(defun current-metadata (session)
  "function-debug-metadata of the stopped function, or NIL."
  (let ((hit (debugger-session-current-hit session)))
    (and hit (metadata-for-function-id (hit-fid hit)))))

;;; --- resume commands (return a directive to ui-await-command) -------
;;
;; The command functions return the resume directive the engine expects;
;; the UI's command loop returns whatever the chosen command yields. A
;; command that does not resume (inspect a binding, set a breakpoint,
;; eval) returns NIL, and the loop keeps reading.

(defun cmd-continue (session)
  (declare (ignore session))
  :continue)

(defun cmd-step (session kind)
  "Single-step (:into|:over|:out|:finish, spec §6)."
  (setf (debugger-session-last-step session) kind)
  (list :step kind))

(defun cmd-advance (session fid form-id &optional (when :before))
  (declare (ignore session))
  (list :advance fid form-id when))

(defun cmd-abort (session)
  (declare (ignore session))
  :abort)

(defun cmd-return (session value)
  (declare (ignore session))
  (list :continue-with-return value))

;;; --- breakpoint commands (no resume; return the breakpoint) --------

(defun cmd-set-breakpoint (session fid form-id &key (when :before) (steady t) condition action)
  (let ((bp (add-breakpoint (debugger-session-thread-info session)
                            fid form-id :when when :steady steady
                            :condition condition :action action)))
    (ui-breakpoint-added (debugger-session-ui session) bp)
    bp))

(defun cmd-set-breakpoint-at-line (session line &key (when :before) (steady t))
  "Set a breakpoint at the poll point on LINE in the currently-stopped
function (spec §17.3 click/line → poll point). Returns the breakpoint or
NIL if LINE has none."
  (let ((metadata (current-metadata session)))
    (when metadata
      (let ((form-id (find-form-id-at-line metadata line)))
        (when form-id
          (cmd-set-breakpoint session (function-debug-metadata-function-id metadata)
                              form-id :when when :steady steady))))))

(defun cmd-advance-at-line (session line &optional (when :before))
  "Advance to the poll point on LINE in the currently-stopped function — a
volatile breakpoint removed on first stop (spec §6.2, command reference §1).
Returns the :advance resume directive, or NIL if LINE has no poll point."
  (let ((metadata (current-metadata session)))
    (when metadata
      (let ((form-id (find-form-id-at-line metadata line)))
        (when form-id
          (cmd-advance session (function-debug-metadata-function-id metadata)
                       form-id when))))))

(defun cmd-remove-breakpoint (session breakpoint)
  (remove-breakpoint (debugger-session-thread-info session) breakpoint)
  (ui-breakpoint-removed (debugger-session-ui session) breakpoint)
  breakpoint)

(defun cmd-list-breakpoints (session)
  (list-breakpoints (debugger-session-thread-info session)))

;;; --- frame / eval / variable commands ------------------------------

(defun cmd-select-frame (session frame-index)
  (setf (debugger-session-selected-frame session) frame-index)
  (let* ((snapshot (debugger-session-snapshot session))
         (frames (and snapshot (snapshot-call-stack snapshot)))
         (frame (and frames (nth frame-index frames))))
    (when (and frame (session-ui session))
      (ui-show-source (session-ui session) (stack-frame-source-position frame)))
    frame))

(defun cmd-eval (session form)
  "Evaluate FORM in the stopping context (innermost frame; spec §17.2).
FORM may be a string (read first) or a runtime form."
  (let ((snapshot (debugger-session-snapshot session))
        (parsed (if (stringp form)
                    (first (read-runtime-from-string form))
                    form)))
    (eval-in-frame snapshot parsed :frame-index 0)))

(defun cmd-set-variable (session symbol value)
  "Set SYMBOL at the stopping point — the innermost binding, or global if
unshadowed (spec §9.5)."
  (declare (ignore session))
  (set-visible-variable symbol value))

;;; --- inspector commands (spec §14) ---------------------------------

(defun cmd-inspect (session value &key origin)
  "Open an inspector session on VALUE, sharing the debugger workspace and
installing the frame-binding writer so :frame binds work (§16.1)."
  (let ((inspector
          (inspect value
                   :origin origin
                   :context (debugger-session-context session)
                   :workspace (debugger-session-workspace session)
                   :bind-frame-fn (make-frame-binding-writer session))))
    (setf (debugger-session-inspector session) inspector)
    inspector))

(defun make-frame-binding-writer (session)
  "Return a writer (frame symbol value) that rewrites SYMBOL's binding in
the snapshot's FRAME via set-binding-entry (spec §16.1 :frame)."
  (lambda (frame symbol value)
    (let* ((snapshot (debugger-session-snapshot session))
           (entries (and snapshot (bindings-of-name snapshot symbol)))
           ;; find the entry owned by the requested frame
           (entry (find frame entries :key #'binding-entry-frame)))
      (unless entry
        (error "Frame has no binding for ~A to rewrite (§16.1)." symbol))
      (set-binding-entry entry value)
      value)))

(defun cmd-inspector-descend (session index)
  (session-down (require-inspector session) index))

(defun cmd-inspector-up (session)
  (session-up (require-inspector session)))

(defun cmd-inspector-bind (session target)
  (session-bind (require-inspector session) target))

(defun cmd-inspector-path-expression (session)
  (session-path-expression (require-inspector session)))

(defun require-inspector (session)
  (or (debugger-session-inspector session)
      (error "No inspector session is open.")))

(defun cmd-workspace-list (session)
  (workspace-list (debugger-session-workspace session)))

(defun cmd-workspace-clear (session &optional slot)
  (workspace-clear (debugger-session-workspace session) slot))

;;; --- lifecycle (spec §21–§24) --------------------------------------

(defun call-with-session (ui-designator thunk
                          &key thread-info context (auto-quit t)
                            ui-initargs break-on-caught)
  "Open a debugger session with UI (a keyword or UI object), run THUNK
with debugging active, and tear down on exit (spec §21/§24). THUNK is the
AutoLISP work to debug; it should evaluate against CONTEXT. Returns THUNK's
value (or :ABORTED).

The session installs *debug-hit-handler* so each stop runs the UI command
loop synchronously and applies its resume directive."
  (let* ((ui (apply #'make-ui ui-designator ui-initargs))
         (ti (or thread-info (make-thread-debug-info :debug-flag t)))
         (ctx (or context (make-default-runtime-context)))
         (session (make-debugger-session
                   :ui ui :thread-info ti :context ctx
                   :workspace (make-workspace))))
    (check-protocol-version ui)
    (ui-attached ui session)
    (unwind-protect
         (let ((*debug-hit-handler*
                 (lambda (hit) (session-stop session hit))))
           (call-with-debugging thunk :thread-info ti
                                      :break-on-caught break-on-caught))
      (when auto-quit
        (clear-breakpoints ti))
      (ui-detached ui))))

(defmacro with-session ((ui &rest options) &body body)
  `(call-with-session ,ui (lambda () ,@body) ,@options))

(defun start-session (&key (ui :terminal) thread-info context ui-initargs)
  "Create a session object attached to UI without running anything (spec
§21). Returns the session; the caller drives evaluation under it via
call-with-session, or uses the session for breakpoint setup first."
  (let* ((uio (apply #'make-ui ui ui-initargs))
         (ti (or thread-info (make-thread-debug-info :debug-flag t)))
         (ctx (or context (make-default-runtime-context)))
         (session (make-debugger-session
                   :ui uio :thread-info ti :context ctx
                   :workspace (make-workspace))))
    (check-protocol-version uio)
    (ui-attached uio session)
    session))

(defun check-protocol-version (ui)
  "Spec §27: a UI may refuse to attach on a major-version mismatch. A UI
opts in by defining a method on UI-PROTOCOL-VERSION returning its expected
(major . minor); the default accepts."
  (let ((expected (ui-protocol-version ui)))
    (when (and expected (/= (car expected) (car *protocol-version*)))
      (error "UI expects debug protocol major ~D but engine is ~D."
             (car expected) (car *protocol-version*)))))

(defgeneric ui-protocol-version (ui)
  (:method (ui) (declare (ignore ui)) nil))

;;; --- the stop handler: build per-stop state, run the UI loop -------

(defun session-stop (session hit)
  "Called by the engine at each stop. Records the snapshot, notifies the
UI of the appropriate event, runs the command loop, and returns the
resume directive."
  (setf (debugger-session-snapshot session) (hit-snapshot hit)
        (debugger-session-current-hit session) hit
        (debugger-session-selected-frame session) 0
        (debugger-session-inspector session) nil)
  (let ((ui (debugger-session-ui session))
        (reason (hit-stop-reason hit)))
    (case reason
      (:unhandled-error (ui-thread-unhandled-error ui session hit))
      (:caught-error (ui-thread-caught-error ui session hit))
      (t (ui-thread-hit ui session hit)))
    (when (hit-source-position hit)
      (ui-show-source ui (hit-source-position hit)))
    (prog1 (ui-await-command ui session hit)
      (ui-thread-resumed ui session))))
