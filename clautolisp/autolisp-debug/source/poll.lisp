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
  (stop-reason :breakpoint :type keyword)   ; :breakpoint | :step
  metadata
  source-position
  snapshot)

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
    (when (and ti (thread-debug-info-debug-flag ti))           ; (a) fast path
      (setf (thread-debug-info-current-pp ti) (cons fid form-id))
      (let ((reason
              (cond
                ((step-request-fires-p ti when) :step)
                ((and (summary-test ti fid form-id)            ; (b) Bloom
                      (find-active-breakpoint ti fid form-id when))
                 :breakpoint))))
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
      ;; trace point: run the action, do not stop
      (funcall (breakpoint-action breakpoint)
               (make-hit :thread-info ti :breakpoint breakpoint :fid fid
                         :form-id form-id :when when :stop-reason reason :metadata metadata))
      (return-from handle-stop :continue))
    (let ((hit (make-hit :thread-info ti :breakpoint breakpoint :fid fid
                         :form-id form-id :when when :stop-reason reason
                         :metadata metadata
                         :source-position (and metadata (form-id-position metadata form-id))
                         :snapshot (build-snapshot ti fid form-id when metadata))))
      (apply-resume-directive ti (funcall *debug-hit-handler* hit)))))

(defun apply-resume-directive (ti directive)
  "Interpret the handler's return value, arming the next stop."
  (cond
    ((null directive) nil)
    ((eq directive :continue) nil)
    ((and (consp directive) (eq (first directive) :step))
     (request-step ti (or (second directive) :into)))
    ((and (consp directive) (eq (first directive) :advance))
     (destructuring-bind (fid form-id &optional (when :before)) (rest directive)
       (advance-to-point ti fid form-id when)))
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
          ;; on non-local exit by unwind-protect.
          (progn
            (debug-poll-enter ti fid form-id context)
            (unwind-protect
                 (progn
                   (poll-point fid form-id :before)
                   (prog1 (autolisp-eval inner context)
                     (poll-point fid form-id :after)))
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
