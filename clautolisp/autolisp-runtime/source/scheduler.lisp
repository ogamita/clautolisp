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
EVALUATION-CONTEXT; STATUS is :RUNNABLE, :RUNNING, or :PARKED. CONTINUATION,
PENDING-BREAK and SAVED-ENV are reserved for real parking (slice 2/3): the
captured continuation, the deferred-break flag for the outstanding-host-call
hazard, and the saved per-context dynamic environment."
  (context nil)
  (document-key nil)
  (status :runnable :type keyword)
  (continuation nil)
  (pending-break nil)
  (saved-env nil))

(defstruct document-scheduler
  "The single-runner cooperative scheduler: CONTEXTS is the ordered list of
SCHEDULED-CONTEXTs; RUNNING is the one :RUNNING context, or NIL."
  (contexts '())
  (running nil))

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

(defun scheduler-activate (scheduler scheduled-context)
  "Make SCHEDULED-CONTEXT the single running context: demote the previously
running one to :RUNNABLE, mark this one :RUNNING, install its
EVALUATION-CONTEXT as the active one, and switch the runtime current document
(and, via *DOCUMENT-ACTIVATION-HOOK*, the host document) in lock-step. Asserts
the at-most-one-running invariant. Returns SCHEDULED-CONTEXT."
  (unless (member scheduled-context (document-scheduler-contexts scheduler))
    (signal-autolisp-runtime-error
     :no-such-context
     "Context ~S is not registered with this scheduler."
     scheduled-context))
  (let ((prev (document-scheduler-running scheduler)))
    (when (and prev (not (eq prev scheduled-context)))
      ;; Save the demoted runner's per-context globals before it stops running.
      (%scheduler-save-env prev)
      (setf (scheduled-context-status prev) :runnable)))
  (setf (scheduled-context-status scheduled-context) :running
        (document-scheduler-running scheduler) scheduled-context)
  (%assert-single-runner scheduler)
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
