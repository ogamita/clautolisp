(in-package #:clautolisp.debug)

;;;; Session entry points (spec §8, §21). CALL-WITH-DEBUGGING is the
;;;; in-thread entry: it arms a thread-debug-info and turns on *DEBUGGING*
;;;; so instrumented bodies run, then evaluates the body; breakpoints
;;;; dispatch through *DEBUG-HIT-HANDLER*. RUN-DEBUGGED-THREAD adds the
;;;; spec's two-thread pause: the application runs in its own thread and,
;;;; on a hit, enqueues the hit and blocks on its inbound queue until the
;;;; debugger thread replies with CONTINUE-THREAD.

(defun call-with-debugging (thunk &key thread-info)
  "Evaluate THUNK with debugging active on the current thread. Returns
THUNK's value. THREAD-INFO defaults to a fresh thread-debug-info with its
debug flag set; pass one to share breakpoints set beforehand."
  (let* ((ti (or thread-info (make-thread-debug-info :debug-flag t)))
         (*thread-debug-info* ti)
         (*debugging* t))
    (setf (thread-debug-info-debug-flag ti) t)
    (funcall thunk)))

(defmacro with-debugging ((&key thread-info) &body body)
  `(call-with-debugging (lambda () ,@body)
                        ,@(when thread-info `(:thread-info ,thread-info))))

;;;; --- two-thread pause ----------------------------------------------

(defun queue-hit-handler (hit)
  "Hit handler installed in a debugged thread: report the hit on the
outbound queue, then block on the inbound queue for a resume command."
  (let ((ti (hit-thread-info hit)))
    (setf (thread-debug-info-status ti) :stopped)
    (bq-push (thread-debug-info-outbound ti) (list :hit hit))
    (let ((command (bq-pop (thread-debug-info-inbound ti))))
      (setf (thread-debug-info-status ti) :running)
      command)))

(defun run-debugged-thread (thunk &key thread-info)
  "Run THUNK in a fresh application thread under debugger control and
return its thread-debug-info. The TI carries inbound/outbound blocking
queues: the caller reads (:hit hit) / (:thread-exit value-or-error) from
the outbound queue and resumes with CONTINUE-THREAD. THUNK is responsible
for evaluating against an explicit context (the new thread does not share
dynamic bindings)."
  (let ((ti (or thread-info
                (make-thread-debug-info :debug-flag t
                                        :inbound (make-blocking-queue)
                                        :outbound (make-blocking-queue)))))
    (setf (thread-debug-info-debug-flag ti) t)
    (unless (thread-debug-info-inbound ti)
      (setf (thread-debug-info-inbound ti) (make-blocking-queue)))
    (unless (thread-debug-info-outbound ti)
      (setf (thread-debug-info-outbound ti) (make-blocking-queue)))
    (bordeaux-threads:make-thread
     (lambda ()
       (let ((*thread-debug-info* ti)
             (*debugging* t)
             (*debug-hit-handler* #'queue-hit-handler))
         (setf (gethash (bordeaux-threads:current-thread) *thread-debug-info-table*) ti)
         (let ((outcome (handler-case (cons :value (funcall thunk))
                          (error (condition) (cons :error condition)))))
           (setf (thread-debug-info-status ti) :exited)
           (bq-push (thread-debug-info-outbound ti) (list :thread-exit outcome)))))
     :name "aldb-application")
    ti))

(defun continue-thread (ti)
  "Resume a TI paused at a hit (spec §8.3 :continue)."
  (bq-push (thread-debug-info-inbound ti) :continue))

(defun step-thread (ti kind)
  "Resume a paused TI with a single step of KIND (:into|:over|:out|:finish,
spec §6); the application stops again at the stepped-to poll point."
  (bq-push (thread-debug-info-inbound ti) (list :step kind)))
