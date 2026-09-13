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
      (setf (scheduled-context-status prev) :runnable)))
  (setf (scheduled-context-status scheduled-context) :running
        (document-scheduler-running scheduler) scheduled-context)
  (%assert-single-runner scheduler)
  (let ((context (scheduled-context-context scheduled-context)))
    (when context
      (setf clautolisp.autolisp-runtime.internal::*active-evaluation-context*
            context)
      (let ((session (evaluation-context-session context))
            (document (evaluation-context-current-document context)))
        (when (and session document)
          ;; Flips the runtime current document AND fires the host
          ;; activation hook, so runtime and host stay in lock-step.
          (set-runtime-session-current-document session document)))))
  scheduled-context)
