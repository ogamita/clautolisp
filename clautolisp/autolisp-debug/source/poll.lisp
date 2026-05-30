(in-package #:clautolisp.debug)

;;;; Poll points (spec §11). A poll point is a call into POLL-POINT from
;;;; the woven %CLAL-POLL nodes of an instrumented body. The hot path is
;;;; allocation-free: read the thread-local debug-flag, test the Bloom
;;;; summary, and only on a Bloom hit do an exact table lookup.

(defstruct hit
  thread-info
  breakpoint
  (fid 0 :type fixnum)
  (form-id 0 :type fixnum)
  (when :before :type keyword)
  metadata
  source-position)

(defparameter *debug-hit-handler*
  (lambda (hit) (declare (ignore hit)) :continue)
  "Called (in the application thread) when a breakpoint fires, with the
HIT describing it. Returns a resume directive (e.g. :CONTINUE). The
default continues immediately. A session installs a handler that
enqueues the hit and blocks until the debugger thread replies (spec §8).
This function IS the debugger/UI boundary in Phase 1.")

(declaim (inline poll-point))
(defun poll-point (fid form-id when)
  "Poll point called before/after every instrumented form. FID and
FORM-ID identify the poll point; WHEN is :before or :after. No-op unless
a debugged thread has a breakpoint covering this point (spec §11.1)."
  (let ((ti *thread-debug-info*))
    (when (and ti (thread-debug-info-debug-flag ti))           ; (a) fast path
      (setf (thread-debug-info-current-pp ti) (cons fid form-id))
      (when (summary-test ti fid form-id)                       ; (b) Bloom
        (let ((bp (find-active-breakpoint ti fid form-id when))); (c) exact
          (when bp
            (handle-breakpoint ti bp fid form-id when)))))))

(defun handle-breakpoint (ti bp fid form-id when)
  ;; A breakpoint condition (if any) gates the stop; a trace action runs
  ;; and transparently continues (spec §6.4). Once any breakpoint fires,
  ;; all volatile breakpoints are cleared (spec §6).
  (let* ((metadata (metadata-for-function-id fid))
         (hit (make-hit :thread-info ti :breakpoint bp :fid fid :form-id form-id
                        :when when :metadata metadata
                        :source-position (and metadata
                                              (form-id-position metadata form-id)))))
    (when (and (breakpoint-condition bp)
               (not (funcall (breakpoint-condition bp) hit)))
      (return-from handle-breakpoint nil))
    (clear-volatile-breakpoints ti)
    (cond
      ((breakpoint-action bp)
       (funcall (breakpoint-action bp) hit)
       :continue)
      (t
       (funcall *debug-hit-handler* hit)))))

;;;; The %CLAL-POLL special operator. An instrumented form
;;;;     (%CLAL-POLL fid k inner)
;;;; fires the :before poll point, evaluates INNER, fires the :after poll
;;;; point, and returns INNER's value. FID and K are literal integers (the
;;;; operator's operands are not evaluated). Registered into the runtime's
;;;; special-operator dispatch so the existing evaluator drives it.

(defparameter +poll-operator-name+ "%CLAL-POLL")

(defun eval-poll-form (arguments context)
  (destructuring-bind (fid form-id inner) arguments
    (poll-point fid form-id :before)
    (let ((value (autolisp-eval inner context)))
      (poll-point fid form-id :after)
      value)))

(defvar *poll-operator-registered* nil)

(defun ensure-poll-operator ()
  "Install the %CLAL-POLL special operator (idempotent)."
  (unless *poll-operator-registered*
    (register-special-operator +poll-operator-name+ #'eval-poll-form)
    (setf *poll-operator-registered* t)))

(ensure-poll-operator)
