(in-package #:clautolisp.debug)

;;;; Poll points (spec §11) + stop dispatch (§6, §8). A poll point is a
;;;; call into POLL-POINT from the woven %CLAL-POLL nodes of an
;;;; instrumented body. The hot path is allocation-free: read the
;;;; thread-local debug-flag, then either a pending step fires or the
;;;; Bloom summary + exact lookup find a breakpoint.

(defstruct hit
  thread-info
  breakpoint
  (fid 0 :type fixnum)
  (form-id 0 :type fixnum)
  (when :before :type keyword)
  (stop-reason :breakpoint :type keyword)   ; :breakpoint | :step | :watch | :unhandled-error | :caught-error
  metadata
  source-position
  snapshot
  watch                                      ; the WATCH that fired, for a :watch stop
  ;; populated for error stops (spec §10)
  condition
  error-message
  errno)

(defparameter *debug-hit-handler*
  (lambda (hit) (declare (ignore hit)) :continue)
  "Called (in the application thread) when execution stops, with the HIT
describing the stopping point. Returns a resume directive:

  :continue                       resume until the next stop
  (:step :into|:over|:out|:finish) single-step (spec §6)
  (:advance fid form-id [when])   set a volatile breakpoint and resume

The default continues. A session installs a handler that reports the hit
and blocks for the debugger's command (spec §8). This function IS the
debugger/UI boundary in Phase 1–2.")

(declaim (inline poll-point))
(defun poll-point (fid form-id when)
  "Poll point called before/after every instrumented form. No-op unless a
debugged thread has armed a step or set a breakpoint covering this point
(spec §11.1)."
  (let ((ti *thread-debug-info*))
    (when (and ti (thread-debug-info-debug-flag ti)            ; (a) fast path
               (not (thread-debug-info-jump-target ti)))       ; jumping ⇒ no stops
      (setf (thread-debug-info-current-pp ti) (cons fid form-id))
      (let* ((step (step-request-fires-p ti when))
             (bp (and (not step)
                      (summary-test ti fid form-id)            ; (b) Bloom
                      (find-active-breakpoint ti fid form-id when)))
             ;; software watchpoints (§2): re-checked at every poll point, but
             ;; only when at least one is set. CHECK-WATCHES refreshes the
             ;; remembered values whether or not it fires, so a change is
             ;; reported exactly once even if a breakpoint/step also stops here.
             (watched (and (thread-debug-info-watches ti) (check-watches ti)))
             (reason (cond (step :step) (bp :breakpoint) (watched :watch))))
        (when reason
          (handle-stop ti fid form-id when reason))))))

(defun handle-stop (ti fid form-id when reason)
  ;; A breakpoint condition (if any) gates a breakpoint stop; a trace
  ;; action runs and transparently continues (spec §6.4). On any stop, all
  ;; volatile breakpoints and the pending step are cleared (spec §6); the
  ;; resume directive returned by the handler arms the next stop.
  (let* ((breakpoint (and (eq reason :breakpoint)
                          (find-active-breakpoint ti fid form-id when)))
         (metadata (metadata-for-function-id fid)))
    (when (and breakpoint (breakpoint-condition breakpoint)
               (not (funcall (breakpoint-condition breakpoint)
                             (make-hit :thread-info ti :breakpoint breakpoint
                                       :fid fid :form-id form-id :when when))))
      (return-from handle-stop nil))
    (clear-volatile-breakpoints ti)
    (clear-step-request ti)
    (when (and breakpoint (breakpoint-action breakpoint))
      ;; run the attached action; a tracepoint (TRACE-P) continues
      ;; transparently, a bpcmd breakpoint (TRACE-P NIL) runs the action
      ;; then falls through to the normal stop (spec §2, §6.4).
      (funcall (breakpoint-action breakpoint)
               (make-hit :thread-info ti :breakpoint breakpoint :fid fid
                         :form-id form-id :when when :stop-reason reason :metadata metadata))
      (when (breakpoint-trace-p breakpoint)
        (return-from handle-stop :continue)))
    (let ((hit (make-hit :thread-info ti :breakpoint breakpoint :fid fid
                         :form-id form-id :when when :stop-reason reason
                         :metadata metadata
                         :watch (and (eq reason :watch) (thread-debug-info-fired-watch ti))
                         :source-position (and metadata (form-id-position metadata form-id))
                         :snapshot (build-snapshot ti fid form-id when metadata))))
      (apply-resume-directive ti (funcall *debug-hit-handler* hit)))))

(defun invoke-debugger-break (&optional message)
  "Programmatic debugger entry (CLAL-BREAK / CLAL-INVOKE-DEBUGGER, command
reference §1): when a debug session is active on this thread, stop at the
current poll point and run the UI command loop, applying its resume directive
(so `abort'/`return' work). A no-op otherwise. MESSAGE, if any, is shown at the
stop. Returns NIL."
  (let ((ti *thread-debug-info*))
    (when (and ti (thread-debug-info-debug-flag ti))
      (let* ((pp (thread-debug-info-current-pp ti))
             (fid (if pp (car pp) 0))
             (form-id (if pp (cdr pp) 0))
             (metadata (metadata-for-function-id fid)))
        (apply-resume-directive
         ti (funcall *debug-hit-handler*
                     (make-hit :thread-info ti :fid fid :form-id form-id :when :before
                               :stop-reason :break :metadata metadata
                               :error-message message
                               :source-position (and metadata (form-id-position metadata form-id))
                               :snapshot (build-snapshot ti fid form-id :before metadata))))))
    nil))

;; Install the programmatic-break hook so the CLAL-BREAK / CLAL-INVOKE-DEBUGGER
;; builtins (autolisp-builtins-core) reach the debugger without builtins-core
;; depending on the debug system.
(setf clautolisp.autolisp-runtime:*debug-break-hook* #'invoke-debugger-break)

(defvar *pending-nav-function* nil
  "Set by REQUEST-NAV-FUNCTION to the name of a function the UI should navigate
on its next stop (pre-debug navigation, aldo-pre-debug.issue). The UI command
loop reads and clears it. NIL when there is no pending navigation request.")

(defun request-nav-function (name)
  "CLAL-NAV-FUNCTION entry: record NAME as the pending navigation target and
break into the debugger, so the UI opens the navigator on NAME's source. A no-op
(and the pending target is cleared) when no debug session is active."
  (setf *pending-nav-function* name)
  (unwind-protect (invoke-debugger-break nil)
    (setf *pending-nav-function* nil)))

(setf clautolisp.autolisp-runtime:*debug-nav-function-hook* #'request-nav-function)

(defun apply-resume-directive (ti directive)
  "Interpret the handler's return value, arming the next stop. :ABORT
unwinds the whole evaluation to the session's CLAL-ABORT catch (the same
mechanism the error path uses, §10.1) — so the user can abort from ANY
stop, not just an error stop."
  (cond
    ((null directive) nil)
    ((eq directive :continue) nil)
    ((eq directive :abort)
     (clear-step-request ti)
     (throw 'clal-abort :aborted))
    ((and (consp directive) (eq (first directive) :step))
     (request-step ti (or (second directive) :into)))
    ((and (consp directive) (eq (first directive) :advance))
     (destructuring-bind (fid form-id &optional (when :before)) (rest directive)
       (advance-to-point ti fid form-id when)))
    ((and (consp directive) (eq (first directive) :jump))
     (destructuring-bind (fid form-id) (rest directive)
       (request-jump ti fid form-id)))
    ((and (consp directive) (eq (first directive) :continue-with-return))
     ;; `return FORM' at a normal (non-error) stop: make the innermost
     ;; instrumented form return VALUE via its CLAL-POLL-RETURN restart
     ;; (spec §1 return / §10.1). Mirrors APPLY-ERROR-DIRECTIVE; declines
     ;; (resumes normally) when no instrumented form encloses the stop.
     (let ((restart (find-restart 'clal-poll-return)))
       (when restart
         (invoke-restart restart (coerce-from-cl (second directive))))))
    (t nil))
  directive)

;;;; The %CLAL-POLL special operator. An instrumented form
;;;;     (%CLAL-POLL fid k inner)
;;;; fires the :before poll point, evaluates INNER, fires the :after poll
;;;; point, and returns INNER's value. While a session is active it also
;;;; maintains the form-depth and shadow call-stack used by stepping and
;;;; the snapshot (stepping.lisp). FID and K are literal integers.

(defparameter +poll-operator-name+ "%CLAL-POLL")

(defun eval-poll-form (arguments context)
  (destructuring-bind (fid form-id inner) arguments
    (let ((ti *thread-debug-info*))
      (if (and ti (thread-debug-info-debug-flag ti))
          ;; debugged thread: maintain depths + shadow stack, kept balanced
          ;; on non-local exit by unwind-protect. The CLAL-POLL-RETURN
          ;; restart lets the debugger's *error* handler supply a value for
          ;; the innermost instrumented form (continue-with-return, §10.1).
          (progn
            (debug-poll-enter ti fid form-id context)
            (unwind-protect
                 (restart-case
                     (progn
                       (poll-point fid form-id :before)
                       ;; Form-level jump (§1): skip this form's body entirely
                       ;; when it is neither the target nor on the path to it.
                       ;; A skipped form contributes NIL. JUMP-DISPOSITION
                       ;; clears the jump when this poll point IS the target.
                       (if (eq (jump-disposition ti fid form-id) :skip)
                           nil
                           (prog1 (autolisp-eval inner context)
                             (jump-exit-check ti fid form-id)
                             (poll-point fid form-id :after))))
                   (clal-poll-return (value) value))
              (debug-poll-exit ti form-id)))
          ;; not a debugged thread (e.g. eval-in-frame with *debugging*
          ;; rebound, or a stray woven form): just evaluate.
          (autolisp-eval inner context)))))

(defvar *poll-operator-registered* nil)

(defun ensure-poll-operator ()
  "Install the %CLAL-POLL special operator (idempotent)."
  (unless *poll-operator-registered*
    (register-special-operator +poll-operator-name+ #'eval-poll-form)
    (setf *poll-operator-registered* t)))

(ensure-poll-operator)
