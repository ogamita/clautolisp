(in-package #:clautolisp.autolisp-runtime)

;;;; Cooperative single-runner document scheduler (cador-2 slice 2a).
;;;;
;;;; The multidocument runtime runs N document contexts on ONE runner: at
;;;; most one context's evaluation runs at any instant, any number may hold a
;;;; suspended evaluation (constraints C2 "no concurrent per-document
;;;; execution" and C8 "single-runner, no mandatory worker thread"). There is
;;;; NO thread per document, and this file deliberately introduces no thread:
;;;; the debugger's two-thread rendezvous (autolisp-debug/source/session.lisp,
;;;; run-debugged-thread) is the *hosted same-image* case; cador's model is
;;;; continuation capture, not a worker thread (R21).
;;;;
;;;; Slice 2a lands the STATE MACHINE and the runtime<->host current-document
;;;; lock-step — the parts every later slice builds on — and models them
;;;; WITHOUT real parking. That is legitimate because a batch cador run parks
;;;; nowhere (a scripted console makes interactive input complete
;;;; immediately, D2 s I.2), so continuation capture and the
;;;; park-with-outstanding-host-call hazard are deferred, with the slots that
;;;; will carry them (CONTINUATION, PENDING-BREAK, SAVED-ENV) reserved here.
;;;;
;;;; Single-document sessions leave RUNTIME-SESSION-SCHEDULER nil and behave
;;;; exactly as before; everything here is opt-in.

;;; --- Public wrappers for the new (internal) struct slots -----------

(defun session-scheduler (session)
  "The session's DOCUMENT-SCHEDULER, or NIL for a single-document session."
  (clautolisp.autolisp-runtime.internal::runtime-session-scheduler session))

(defun (setf session-scheduler) (new session)
  (setf (clautolisp.autolisp-runtime.internal::runtime-session-scheduler session)
        new))

(defun document-namespace-host-document-key (namespace)
  "The opaque host document KEY this namespace maps to (e.g. a cador document
key), or NIL when no host document is linked."
  (clautolisp.autolisp-runtime.internal::document-namespace-host-document-key
   namespace))

(defun (setf document-namespace-host-document-key) (new namespace)
  (setf (clautolisp.autolisp-runtime.internal::document-namespace-host-document-key
         namespace)
        new))

;;; --- The scheduler data model -------------------------------------

(defstruct scheduled-context
  "One document's slot in the cooperative scheduler. CONTEXT is its
EVALUATION-CONTEXT; STATUS is :RUNNABLE, :RUNNING, or :PARKED.

THREAD is this context's continuation, made concrete as a thread (pjb: \"our
continuations are our threads, parked on a condition variable\"): a parked
context is its THREAD blocked on MAILBOX; resuming it pushes a token to MAILBOX
and the previously-running thread then blocks on its own. The condition-variable
rendezvous itself enforces at-most-one-running (C2/C8) — the thread is the
cooperative coroutine carrier, never a concurrent worker. Both are NIL until the
context is first spawned; a single-document session never spawns one.

PENDING-BREAK is the deferred-break flag; SAVED-ENV the saved per-context
dynamic environment.

THUNK is this context's evaluation entry, supplied at registration for a
thread-backed context and NIL for a bare (synchronous) one. It is the switch
SCHEDULER-ACTIVATE dispatches on: THUNK nil takes the pure synchronous state
machine (single-document and every batch cador run), THUNK non-nil takes the
thread rendezvous (real parking). A bare context spawns no thread, so
single-document behaviour stays thread-free (slice 3e)."
  (context nil)
  (document-key nil)
  (status :runnable :type keyword)
  (thread nil)
  (mailbox nil)
  (pending-break nil)
  (saved-env nil)
  (thunk nil))

(defstruct document-scheduler
  "The single-runner cooperative scheduler: CONTEXTS is the ordered list of
SCHEDULED-CONTEXTs; RUNNING is the one :RUNNING context, or NIL. LOCK guards the
status/running transition across the thread handoff."
  (contexts '())
  (running nil)
  (lock (bordeaux-threads:make-lock "document-scheduler")))

;;; --- Registry -----------------------------------------------------

(defun scheduler-register-context (scheduler scheduled-context)
  "Add SCHEDULED-CONTEXT to SCHEDULER, appended so registration order is
preserved. Returns the context."
  (setf (document-scheduler-contexts scheduler)
        (append (document-scheduler-contexts scheduler)
                (list scheduled-context)))
  scheduled-context)

(defun scheduler-context-list (scheduler)
  "The scheduled contexts, in registration order."
  (document-scheduler-contexts scheduler))

(defun scheduler-current-context (scheduler)
  "The :RUNNING scheduled context, or NIL when none is running."
  (document-scheduler-running scheduler))

;;; --- The single-runner invariant (executable C2) ------------------

(defun %assert-single-runner (scheduler)
  "Signal :SCHEDULER-INVARIANT unless at most one context is :RUNNING. This is
the executable form of C2 — the guarantee that no two document contexts ever
run at once. Returns the list of :RUNNING contexts (0 or 1)."
  (let ((running (remove :running (document-scheduler-contexts scheduler)
                         :key #'scheduled-context-status :test-not #'eq)))
    (when (> (length running) 1)
      (signal-autolisp-runtime-error
       :scheduler-invariant
       "Cooperative scheduler invariant violated: ~D contexts RUNNING at once."
       (length running)))
    running))

;;; --- Per-context dynamic-environment save/restore (slice 2c) -------
;;;
;;; Most per-context dynamic state — current document/namespace, *ERROR*, the
;;; dynamic frame — already rides inside the EVALUATION-CONTEXT, which
;;; SCHEDULER-ACTIVATE swaps wholesale via *ACTIVE-EVALUATION-CONTEXT*. What
;;; SAVED-ENV carries is the small set of per-evaluation runtime *globals* that
;;; live OUTSIDE the context and would otherwise bleed across a switch. Slice
;;; 2c carries exactly one such global, *CURRENT-FORM*, to prove the seam;
;;; later slices extend the captured set. Session/registry-scoped state is
;;; deliberately NOT saved (R13: a resumed context re-reads it).

(defun %scheduler-save-env (scheduled-context)
  "Snapshot the per-context runtime globals into SCHEDULED-CONTEXT's SAVED-ENV,
called when the context is demoted from :RUNNING."
  (setf (scheduled-context-saved-env scheduled-context)
        (list :current-form *current-form*))
  scheduled-context)

(defun %scheduler-restore-env (scheduled-context)
  "Restore the per-context runtime globals from SCHEDULED-CONTEXT's SAVED-ENV,
called when the context is promoted to :RUNNING. A NIL SAVED-ENV (a context
that has never run) leaves the globals untouched, so first activation and the
single-document path are unaffected."
  (let ((env (scheduled-context-saved-env scheduled-context)))
    (when env
      (setf *current-form* (getf env :current-form))))
  scheduled-context)

;;; --- Activation (the core transition) -----------------------------
;;;
;;; SCHEDULER-ACTIVATE is the single entry every caller uses; slice 3e folds the
;;; thread rendezvous in behind it so the caller never chooses between "activate"
;;; and "switch". The fold dispatches on the target's THUNK:
;;;
;;;   THUNK nil  -> %SCHEDULER-ACTIVATE-SYNCHRONOUS: the pure state machine that
;;;                 shipped in slices 2a-2c, byte-for-byte. This is what a
;;;                 single-document session and every scripted/batch cador run
;;;                 take (they park nowhere, D2 s I.2), so no thread is ever
;;;                 spawned on that path.
;;;   THUNK set  -> the rendezvous: from the driver thread, lazily spawn the
;;;                 context's thread and START it; from a running context's OWN
;;;                 thread, hand off via SCHEDULER-SWITCH (park self, wake target).
;;;
;;; The env install (active context + restore-env + current-document lock-step)
;;; is factored into %SCHEDULER-INSTALL-CONTEXT so that on the thread path it
;;; runs ON the woken thread (each context thread owns thread-local bindings of
;;; the two process-globals — see SCHEDULER-SPAWN-CONTEXT), never on the driver.

(defun %scheduler-install-context (scheduled-context)
  "Install SCHEDULED-CONTEXT's EVALUATION-CONTEXT as the active one, restore its
per-context globals, and switch the runtime current document (firing
*DOCUMENT-ACTIVATION-HOOK* in lock-step). Run by whichever thread becomes the
runner. Returns SCHEDULED-CONTEXT."
  (let ((context (scheduled-context-context scheduled-context)))
    (when context
      (setf clautolisp.autolisp-runtime.internal::*active-evaluation-context*
            context)
      ;; Restore the promoted context's per-context globals (no-op the first
      ;; time it runs, when its SAVED-ENV is still nil).
      (%scheduler-restore-env scheduled-context)
      (let ((session (evaluation-context-session context))
            (document (evaluation-context-current-document context)))
        (when (and session document)
          ;; Flips the runtime current document AND fires the host
          ;; activation hook, so runtime and host stay in lock-step.
          (set-runtime-session-current-document session document)))))
  scheduled-context)

(defun %scheduler-activate-synchronous (scheduler scheduled-context)
  "The pure, thread-free activation state machine (slices 2a-2c): demote the
previous runner to :RUNNABLE, mark this one :RUNNING, assert the invariant, and
install its environment on the calling thread. Returns SCHEDULED-CONTEXT."
  (let ((prev (document-scheduler-running scheduler)))
    (when (and prev (not (eq prev scheduled-context)))
      ;; Save the demoted runner's per-context globals before it stops running.
      (%scheduler-save-env prev)
      (setf (scheduled-context-status prev) :runnable)))
  (setf (scheduled-context-status scheduled-context) :running
        (document-scheduler-running scheduler) scheduled-context)
  (%assert-single-runner scheduler)
  (%scheduler-install-context scheduled-context)
  scheduled-context)

(defun %on-context-thread-p (scheduler)
  "True when the calling thread IS the scheduler's currently running context's
thread — i.e. a running context is activating from inside its own evaluation, so
the transition must be a hand-off (SCHEDULER-SWITCH), not a driver-side start."
  (let ((running (document-scheduler-running scheduler)))
    (and running
         (scheduled-context-thread running)
         (eq (bordeaux-threads:current-thread)
             (scheduled-context-thread running)))))

(defun scheduler-activate (scheduler scheduled-context)
  "Make SCHEDULED-CONTEXT the single running context. The unified entry (slice
3e): a bare context (THUNK nil) takes the synchronous state machine and installs
its EVALUATION-CONTEXT as active, switching the runtime current document (and,
via *DOCUMENT-ACTIVATION-HOOK*, the host document) in lock-step; a thread-backed
context (THUNK set) is bootstrapped (lazy spawn + start) from the driver thread,
or handed off via SCHEDULER-SWITCH when a running context activates from its own
thread. Asserts the at-most-one-running invariant. Returns SCHEDULED-CONTEXT."
  (unless (member scheduled-context (document-scheduler-contexts scheduler))
    (signal-autolisp-runtime-error
     :no-such-context
     "Context ~S is not registered with this scheduler."
     scheduled-context))
  (cond
    ;; No thunk => the pure synchronous path (single-document, batch cador):
    ;; unchanged from slices 2a-2c, spawns no thread.
    ((null (scheduled-context-thunk scheduled-context))
     (%scheduler-activate-synchronous scheduler scheduled-context))
    ;; Thread-backed, and we ARE the running context's thread => hand off.
    ((%on-context-thread-p scheduler)
     (let ((from (document-scheduler-running scheduler)))
       (unless (eq from scheduled-context)
         (scheduler-spawn-context scheduler scheduled-context
                                  (scheduled-context-thunk scheduled-context))
         (scheduler-switch scheduler from scheduled-context)))
     scheduled-context)
    ;; Thread-backed, driver thread => bootstrap or re-enter: spawn (if needed)
    ;; and start.
    (t
     (scheduler-spawn-context scheduler scheduled-context
                              (scheduled-context-thunk scheduled-context))
     (scheduler-start scheduler scheduled-context)
     scheduled-context)))

;;; --- Deferred-break discipline (slice 2c) -------------------------
;;;
;;; A break requested against a context is not an asynchronous interrupt: it
;;; sets that context's PENDING-BREAK flag, and the flag is observed (and
;;; cleared) only at a poll/park point while that context is the runner (D1
;;; §13.5). This is the cooperative half of the outstanding-host-call hazard —
;;; a break asked for while a host request is in flight waits until control
;;; returns to the running context. Real parking (the CONTINUATION slot) is
;;; Slice 3; here the flag and its observe-at-poll semantics are complete and
;;; testable synchronously.

(defun scheduler-request-break (scheduler &optional scheduled-context)
  "Request a cooperative break on SCHEDULED-CONTEXT, or on SCHEDULER's running
context when none is given. Sets the context's PENDING-BREAK flag; the break is
observed later, at a poll point, by SCHEDULER-OBSERVE-BREAK. Returns the
context, or NIL when there is no context to mark."
  (let ((target (or scheduled-context (document-scheduler-running scheduler))))
    (when target
      (setf (scheduled-context-pending-break target) t))
    target))

(defun scheduler-pending-break-p (scheduled-context)
  "True when a break has been requested against SCHEDULED-CONTEXT and not yet
observed."
  (and (scheduled-context-pending-break scheduled-context) t))

(defun scheduler-observe-break (scheduler)
  "The poll point: if the RUNNING context has a pending break, clear it and
return T (a break is now due); otherwise NIL. A break requested on a context
that is not the runner is not observed until that context is activated — the
deferral. No asynchronous interrupt is ever raised here."
  (let ((running (document-scheduler-running scheduler)))
    (when (and running (scheduled-context-pending-break running))
      (setf (scheduled-context-pending-break running) nil)
      t)))

;;; --- Thread rendezvous: continuations as parked threads (slice 3d) ---
;;;
;;; A context's continuation is its THREAD, parked on a condition variable
;;; (pjb). PARK-MAILBOX is a one-slot blocking token queue over a lock + condvar
;;; (the shape of the debugger's blocking-queue, reimplemented here because
;;; autolisp-debug depends on autolisp-runtime, not the reverse — reuse would
;;; invert the dependency). Handing off = push a token to the target's mailbox
;;; (waking its thread) then pop your own (blocking). The rendezvous guarantees
;;; exactly one thread is ever off its mailbox, so it *is* the single-runner
;;; mutual exclusion — no concurrent execution (C2/C8).
;;;
;;; Slice 3d adds this rendezvous ALONGSIDE the synchronous state machine and
;;; does NOT touch SCHEDULER-ACTIVATE: a single-document session (no scheduler)
;;; still spawns no thread. Wiring park points to real evaluation is a later
;;; increment; here the thunks are caller-supplied.

(defstruct park-mailbox
  "A blocking one-token-at-a-time mailbox: a lock + condition variable over a
FIFO of tokens. The parked thread POPs (blocks); a resumer PUSHes."
  (tokens '())
  (lock (bordeaux-threads:make-lock "park-mailbox"))
  (cv (bordeaux-threads:make-condition-variable)))

(defun park-mailbox-push (mailbox token)
  "Enqueue TOKEN and wake one waiter. Non-blocking."
  (bordeaux-threads:with-lock-held ((park-mailbox-lock mailbox))
    (setf (park-mailbox-tokens mailbox)
          (nconc (park-mailbox-tokens mailbox) (list token)))
    (bordeaux-threads:condition-notify (park-mailbox-cv mailbox)))
  token)

(defun park-mailbox-pop (mailbox &optional timeout)
  "Block until a token is available and return it; with TIMEOUT (seconds),
return :TIMEOUT if none arrives in time. A token already present is returned at
once (no lost-wakeup)."
  (let ((deadline (and timeout (+ (get-internal-real-time)
                                  (* timeout internal-time-units-per-second)))))
    (bordeaux-threads:with-lock-held ((park-mailbox-lock mailbox))
      (loop
        (when (park-mailbox-tokens mailbox)
          (return (pop (park-mailbox-tokens mailbox))))
        (when (and deadline (>= (get-internal-real-time) deadline))
          (return :timeout))
        (bordeaux-threads:condition-wait
         (park-mailbox-cv mailbox) (park-mailbox-lock mailbox)
         :timeout 0.25)))))

(defun %scheduler-set-running (scheduler sc)
  "Under the scheduler lock: demote the current runner to :PARKED, make SC the
:RUNNING one, and assert the single-runner invariant."
  (bordeaux-threads:with-lock-held ((document-scheduler-lock scheduler))
    (let ((prev (document-scheduler-running scheduler)))
      (when (and prev (not (eq prev sc)))
        (setf (scheduled-context-status prev) :parked)))
    (setf (scheduled-context-status sc) :running
          (document-scheduler-running scheduler) sc)
    (%assert-single-runner scheduler)))

(defun scheduler-spawn-context (scheduler sc thunk)
  "Spawn SC's thread (its continuation), born PARKED: the thread first blocks on
SC's mailbox, then runs THUNK when resumed. Returns SC. Idempotent-guarded: a
context already carrying a thread is not respawned."
  (unless (scheduled-context-thread sc)
    (unless (scheduled-context-mailbox sc)
      (setf (scheduled-context-mailbox sc) (make-park-mailbox)))
    (setf (scheduled-context-thread sc)
          (bordeaux-threads:make-thread
           (lambda ()
             ;; Each context thread owns thread-local bindings of the two
             ;; per-evaluation process-globals, so its install-on-wake SETFs are
             ;; private (no cross-thread leak into the top-level value, and the
             ;; FiveAM double-run stays isolated — %with-fresh-active-context
             ;; only rebinds them in the driver thread).
             (let ((clautolisp.autolisp-runtime.internal::*active-evaluation-context*
                     clautolisp.autolisp-runtime.internal::*active-evaluation-context*)
                   (*current-form* *current-form*))
               ;; born idle: wait for the first :run before doing anything.
               (let ((token (park-mailbox-pop (scheduled-context-mailbox sc))))
                 (unless (eq token :exit)
                   ;; This thread is now the runner: install its environment
                   ;; here, on itself, before evaluating.
                   (%scheduler-install-context sc)
                   (funcall thunk)))))
           :name (format nil "cador-doc-~A"
                         (or (scheduled-context-document-key sc) "?")))))
  sc)

(defun scheduler-start (scheduler sc)
  "Driver-side: make SC the running context and wake its thread. Used to kick a
freshly spawned (parked) context, or to re-enter a parked one."
  (%scheduler-set-running scheduler sc)
  (park-mailbox-push (scheduled-context-mailbox sc) :run)
  sc)

;; scheduler-resume is scheduler-start under a name that reads right at a
;; driver re-entering a parked context to let it finish.
(setf (fdefinition 'scheduler-resume) (fdefinition 'scheduler-start))

(defun scheduler-switch (scheduler from to)
  "Called by FROM's OWN thread to hand control to TO: save FROM's per-context
globals, mark the transition under the lock, wake TO's thread, then park FROM's
thread on its mailbox until it is resumed. On resume with :run, reinstall FROM's
environment (on FROM's own thread) before returning; on :exit, return without
reinstalling so the thread can unwind for teardown. Returns the resume token."
  (%scheduler-save-env from)
  (%scheduler-set-running scheduler to)
  (park-mailbox-push (scheduled-context-mailbox to) :run)         ; wake TO
  (let ((token (park-mailbox-pop (scheduled-context-mailbox from)))) ; park FROM
    (unless (eq token :exit)
      ;; Resumed as the runner again: reinstall our environment on this thread.
      (%scheduler-install-context from))
    token))
