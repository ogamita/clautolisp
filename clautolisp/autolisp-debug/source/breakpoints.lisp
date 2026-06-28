(in-package #:clautolisp.debug)

;;;; Per-thread debug state (spec §8.1) and the breakpoint table with a
;;;; 1024-bit Bloom-filter summary (spec §11.2). The breakpoint table is
;;;; keyed by a fixnum combining (function-id, form-id) so the poll-point
;;;; hot path never conses (spec §11.1).

(defstruct (blocking-queue (:constructor make-blocking-queue ()))
  (items '() :type list)
  (lock (bordeaux-threads:make-lock "aldb-queue"))
  (cv (bordeaux-threads:make-condition-variable)))

(defun bq-push (queue item)
  "Enqueue ITEM (non-blocking) and wake one waiter."
  (bordeaux-threads:with-lock-held ((blocking-queue-lock queue))
    (setf (blocking-queue-items queue)
          (nconc (blocking-queue-items queue) (list item)))
    (bordeaux-threads:condition-notify (blocking-queue-cv queue)))
  item)

(defun bq-pop (queue &optional timeout)
  "Dequeue the next item, blocking while the queue is empty. With a
TIMEOUT (seconds), return :TIMEOUT if nothing arrives in time — a guard
so a stuck debugged thread can't hang a caller (tests) forever."
  (let ((deadline (and timeout
                       (+ (get-internal-real-time)
                          (* timeout internal-time-units-per-second)))))
    (bordeaux-threads:with-lock-held ((blocking-queue-lock queue))
      (loop until (blocking-queue-items queue)
            do (when (and deadline (>= (get-internal-real-time) deadline))
                 (return-from bq-pop :timeout))
               (bordeaux-threads:condition-wait (blocking-queue-cv queue)
                                                 (blocking-queue-lock queue)
                                                 :timeout (when timeout 0.25)))
      (pop (blocking-queue-items queue)))))

(defstruct thread-debug-info
  (debug-flag nil)
  ;; combined-key (fixnum) → list of breakpoint records on that poll point
  (breakpoints (make-hash-table :test 'eql))
  ;; 1024-bit Bloom filter over set poll points (spec §11.2)
  (summary (make-array 1024 :element-type 'bit :initial-element 0))
  ;; volatile breakpoints, cleared the first time ANY breakpoint fires (§6)
  (volatile '() :type list)
  (current-pp nil)
  (status :running)
  ;; Stepping + backtrace state (spec §6, §9), maintained by eval-poll-form
  ;; while a session is active on this thread:
  ;;  - poll-depth: form-nesting depth (incf at each :before, decf at :after)
  ;;  - call-stack: shadow stack of debug-frame, innermost first, pushed at
  ;;    each function-entry poll point (form-id 0)
  ;;  - step-request: a pending step (or NIL); see stepping.lisp
  (poll-depth 0 :type fixnum)
  (call-stack '() :type list)
  (step-request nil)
  ;; software watchpoints (spec §2 watch): a list of WATCH records re-checked
  ;; at every poll point, plus the one that most recently fired (for the hit).
  (watches '() :type list)
  (fired-watch nil)
  ;; two-thread pause channels (spec §8): debugger→app and app→debugger
  (inbound nil)
  (outbound nil)
  (lock (bordeaux-threads:make-lock "aldb-ti")))

(defstruct breakpoint
  (id 0 :type fixnum)
  (fid 0 :type fixnum)
  (form-id 0 :type fixnum)
  (when :before :type keyword)            ; :before | :after | :both
  (steady-p t :type boolean)
  (condition nil)                          ; NIL or a function of (hit) → boolean
  (action nil)                             ; NIL or a function of (hit) run on hit
  (trace-p t :type boolean)                ; T ⇒ action auto-continues (trace);
                                           ; NIL ⇒ run action, then STOP (bpcmd, §2)
  (enabled-p t :type boolean))             ; NIL ⇒ temporarily inactive (disable/enable)

(defvar *breakpoint-id-counter* 0)

(defparameter *thread-debug-info* nil
  "The thread-debug-info governing the current (application) thread, or
NIL. Bound per debugged thread; the poll-point fast path reads it and is
a no-op when it is NIL (spec §11.1).")

(defvar *thread-debug-info-table* (make-hash-table :test 'eq)
  "bt:thread → thread-debug-info, for all currently debugged threads
(spec §8.1).")

;;;; --- combining hash + Bloom filter ---------------------------------

(declaim (inline combined-key bloom-index))

(defun combined-key (fid form-id)
  "Allocation-free fixnum key combining a function-id and form-id.
Assumes form-id < 2^24, which the dense per-function numbering respects."
  (logior (ash fid 24) (logand form-id #xFFFFFF)))

(defun bloom-index (fid form-id)
  (mod (logxor (* fid 1009) form-id) 1024))

(defun summary-set (ti fid form-id)
  (setf (sbit (thread-debug-info-summary ti) (bloom-index fid form-id)) 1))

(declaim (inline summary-test))
(defun summary-test (ti fid form-id)
  (= 1 (sbit (thread-debug-info-summary ti) (bloom-index fid form-id))))

(defun rebuild-summary (ti)
  "Recompute the Bloom bits from the live breakpoint table (spec §11.2:
bits are not cleared on individual removal, only rebuilt in bulk)."
  (let ((summary (thread-debug-info-summary ti)))
    (fill summary 0)
    (maphash (lambda (key breakpoints)
               (declare (ignore key))
               (dolist (bp breakpoints)
                 (summary-set ti (breakpoint-fid bp) (breakpoint-form-id bp))))
             (thread-debug-info-breakpoints ti))))

;;;; --- breakpoint management (spec §12) ------------------------------

(defun add-breakpoint (ti fid form-id &key (when :before) (steady t) condition action (trace t))
  "Set a breakpoint at poll point (FID, FORM-ID) on TI and return it.
WHEN is :before, :after, or :both. A non-steady breakpoint is volatile
and is removed the first time any breakpoint fires (§6). When ACTION is
supplied, TRACE governs its disposition: T (default) auto-continues after
the action (a tracepoint, §6.4); NIL runs the action then stops (bpcmd, §2)."
  (bordeaux-threads:with-lock-held ((thread-debug-info-lock ti))
    (let ((bp (make-breakpoint :id (incf *breakpoint-id-counter*)
                               :fid fid :form-id form-id :when when
                               :steady-p steady :condition condition :action action
                               :trace-p trace))
          (key (combined-key fid form-id)))
      (push bp (gethash key (thread-debug-info-breakpoints ti)))
      (unless steady (push bp (thread-debug-info-volatile ti)))
      (summary-set ti fid form-id)
      bp)))

(defun add-breakpoint-in (ti usubr form-id &rest keys)
  "Like ADD-BREAKPOINT but resolves the function-id from an instrumented
USUBR. Signals if USUBR has not been instrumented."
  (let ((metadata (metadata-for-usubr usubr)))
    (unless metadata
      (error "Cannot set a breakpoint: ~A has no debug metadata (not instrumented)."
             (autolisp-usubr-name usubr)))
    (apply #'add-breakpoint ti (function-debug-metadata-function-id metadata) form-id keys)))

(defun remove-breakpoint (ti bp)
  "Remove BP from TI. The Bloom bit is left set (it may cover another
poll point); call REBUILD-SUMMARY to reclaim bits in bulk (spec §11.2)."
  (bordeaux-threads:with-lock-held ((thread-debug-info-lock ti))
    (let ((key (combined-key (breakpoint-fid bp) (breakpoint-form-id bp))))
      (setf (gethash key (thread-debug-info-breakpoints ti))
            (remove bp (gethash key (thread-debug-info-breakpoints ti))))
      (setf (thread-debug-info-volatile ti)
            (remove bp (thread-debug-info-volatile ti))))
    bp))

(defun list-breakpoints (ti)
  "Return every breakpoint set on TI."
  (let ((result '()))
    (maphash (lambda (key breakpoints)
               (declare (ignore key))
               (dolist (bp breakpoints) (push bp result)))
             (thread-debug-info-breakpoints ti))
    result))

(defun clear-breakpoints (ti)
  "Remove all breakpoints from TI and clear the Bloom summary."
  (bordeaux-threads:with-lock-held ((thread-debug-info-lock ti))
    (clrhash (thread-debug-info-breakpoints ti))
    (setf (thread-debug-info-volatile ti) '())
    (fill (thread-debug-info-summary ti) 0)))

(defun clear-volatile-breakpoints (ti)
  "Remove every volatile breakpoint on TI (called on the first hit, §6)."
  (dolist (bp (thread-debug-info-volatile ti))
    (let ((key (combined-key (breakpoint-fid bp) (breakpoint-form-id bp))))
      (setf (gethash key (thread-debug-info-breakpoints ti))
            (remove bp (gethash key (thread-debug-info-breakpoints ti))))))
  (setf (thread-debug-info-volatile ti) '()))

(defun find-active-breakpoint (ti fid form-id when)
  "Return a breakpoint at (FID, FORM-ID) whose WHEN matches the poll
event, or NIL. A :both breakpoint matches either event."
  (find-if (lambda (bp)
             (and (breakpoint-enabled-p bp)
                  (let ((bw (breakpoint-when bp)))
                    (or (eq bw :both) (eq bw when)))))
           (gethash (combined-key fid form-id)
                    (thread-debug-info-breakpoints ti))))

(defun set-breakpoint-enabled (bp enabled)
  "Enable (ENABLED non-NIL) or disable a breakpoint without removing it
(command reference §2). A disabled breakpoint stays in the table but does not
fire. Returns BP."
  (setf (breakpoint-enabled-p bp) (and enabled t))
  bp)

(defun set-breakpoint-action (bp action &key (trace nil))
  "Attach ACTION (a function of one HIT argument, or NIL to clear) to BP.
TRACE governs the disposition (see ADD-BREAKPOINT): NIL (default here) makes
this a bpcmd breakpoint that runs ACTION then stops (§2); T makes it a
tracepoint that runs ACTION and continues (§6.4). Returns BP."
  (setf (breakpoint-action bp) action
        (breakpoint-trace-p bp) (and trace t))
  bp)
