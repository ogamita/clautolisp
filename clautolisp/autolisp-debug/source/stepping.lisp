(in-package #:clautolisp.debug)

;;;; Stepping (spec §6), implemented as the degenerate volatile-breakpoint:
;;;; a pending "step request" that the poll-point routine tests against the
;;;; current nesting depth. eval-poll-form maintains two depths while a
;;;; session is active on the thread:
;;;;
;;;;  - poll-depth (form nesting): +1 at each :before, -1 at each :after.
;;;;  - call-stack (function nesting): a shadow frame pushed at each
;;;;    function-entry poll point (form-id 0) and popped at its exit.
;;;;
;;;; Step semantics (depth captured when the step is armed: D0F form-depth,
;;;; D0C call-depth):
;;;;
;;;;  - :into  — stop at the next form beginning (:before), any depth:
;;;;             descends into the first sub-form or a called function.
;;;;  - :over  — stop at the next :before at form-depth <= D0F (skipping the
;;;;             current form's sub-forms and any functions it calls), or as
;;;;             soon as the current function returns (call-depth < D0C).
;;;;  - :out   — run until the current function returns (call-depth < D0C);
;;;;             "finish" is :out with the function body as the frame.

(defstruct step-request
  (kind :into :type keyword)
  (form-depth 0 :type fixnum)
  (call-depth 0 :type fixnum))

(defun call-depth-of (ti)
  (length (thread-debug-info-call-stack ti)))

(defun step-request-fires-p (ti when)
  "True iff TI's pending step request should stop at this poll event."
  (let ((request (thread-debug-info-step-request ti)))
    (when request
      (let ((call-depth (call-depth-of ti))
            (poll-depth (thread-debug-info-poll-depth ti)))
        (ecase (step-request-kind request)
          (:into (eq when :before))
          (:over (or (and (eq when :before)
                          (<= poll-depth (step-request-form-depth request)))
                     (< call-depth (step-request-call-depth request))))
          (:out (< call-depth (step-request-call-depth request))))))))

(defun request-step (ti kind)
  "Arm a step of KIND (:into | :over | :out | :finish) from the current
stopping point. :finish is an alias for :out."
  (let ((kind (if (eq kind :finish) :out kind)))
    (setf (thread-debug-info-step-request ti)
          (make-step-request :kind kind
                             :form-depth (thread-debug-info-poll-depth ti)
                             :call-depth (call-depth-of ti)))))

(defun clear-step-request (ti)
  (setf (thread-debug-info-step-request ti) nil))

(defun advance-to-point (ti fid form-id &optional (when :before))
  "Place a volatile breakpoint at (FID, FORM-ID) and let the caller
continue — the spec's 'advance to point' (§6.2)."
  (add-breakpoint ti fid form-id :when when :steady nil))

;;; --- shadow-stack / poll-depth maintenance (called by eval-poll-form)

(defun debug-poll-enter (ti fid form-id context)
  "On a :before poll event: bump form-depth, push a shadow frame at a
function entry (form-id 0), and record the current form-id on the top
frame."
  (incf (thread-debug-info-poll-depth ti))
  (when (zerop form-id)
    (push (make-debug-frame
           :fid fid :current-form-id 0
           :dynamic-frame (evaluation-context-dynamic-frame context))
          (thread-debug-info-call-stack ti)))
  (let ((top (car (thread-debug-info-call-stack ti))))
    (when (and top (= (debug-frame-fid top) fid))
      (setf (debug-frame-current-form-id top) form-id))))

(defun debug-poll-exit (ti form-id)
  "On poll-event cleanup: pop the shadow frame at a function exit
(form-id 0) and drop the form-depth. Always runs (unwind-protect), so a
non-local exit through the form keeps the depths balanced."
  (when (zerop form-id)
    (pop (thread-debug-info-call-stack ti)))
  (decf (thread-debug-info-poll-depth ti)))

;;; --- map a source position to a poll point (spec §17.3) ------------

(defun poll-point-at (source-position)
  "Return (values fid form-id) of a poll point whose recorded position
equals SOURCE-POSITION, scanning every instrumented function, or
(values NIL NIL). Implements 'which poll point is at this source
position' for click-to-break."
  (block search
    (maphash
     (lambda (fid metadata)
       (let ((positions (function-debug-metadata-form-id->position metadata)))
         (dotimes (form-id (length positions))
           (let ((position (aref positions form-id)))
             (when (and (source-position-p position)
                        (source-position-equal position source-position))
               (return-from search (values fid form-id)))))))
     *function-id-registry*)
    (values nil nil)))
