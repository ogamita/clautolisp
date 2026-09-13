(in-package #:clautolisp.autolisp-runtime.tests)

(in-suite autolisp-runtime-suite)

;;;; Cooperative single-runner document scheduler (cador-2 slice 2a).
;;;; No threads, no real parking: these exercise the state machine and the
;;;; runtime<->host current-document lock-step, deterministically.

(defun %make-doc-context (session name key)
  "A SCHEDULED-CONTEXT for a fresh document NAME/KEY in SESSION."
  (let* ((ns (make-document-namespace :name name))
         (ctx (make-evaluation-context :session session
                                       :current-document ns
                                       :current-namespace ns)))
    (setf (document-namespace-host-document-key ns) key)
    (make-scheduled-context :context ctx :document-key key)))

(defmacro %with-fresh-active-context (&body body)
  "Rebind *ACTIVE-EVALUATION-CONTEXT* and *DOCUMENT-ACTIVATION-HOOK* around
BODY so a test that calls SCHEDULER-ACTIVATE (which SETFs the active context
and SET-RUNTIME-SESSION-CURRENT-DOCUMENT, which fires the hook) or that
installs its own hook cannot leak into later tests — the FiveAM shared-global
hazard. Rebinding (not SETF) matters especially for the hook: in the full
image the host layer installs a real *DOCUMENT-ACTIVATION-HOOK* at load, and a
SETF-then-restore-to-nil would clobber it for every later suite."
  `(let ((clautolisp.autolisp-runtime.internal::*active-evaluation-context*
           clautolisp.autolisp-runtime.internal::*active-evaluation-context*)
         (*document-activation-hook* *document-activation-hook*)
         ;; slice 2c: the per-context global the scheduler saves/restores.
         (clautolisp.autolisp-runtime::*current-form*
           clautolisp.autolisp-runtime::*current-form*))
     ,@body))

(test scheduler-registers-and-lists-contexts
  (let* ((session (make-runtime-session))
         (sched (make-document-scheduler))
         (a (%make-doc-context session "A" "A"))
         (b (%make-doc-context session "B" "B")))
    (scheduler-register-context sched a)
    (scheduler-register-context sched b)
    (is (equal (list a b) (scheduler-context-list sched)))   ; registration order
    (is (null (scheduler-current-context sched)))))          ; nothing running yet

(test scheduler-activate-enforces-single-runner
  ;; Activate among three contexts; at every step exactly one is :RUNNING and
  ;; the others are :RUNNABLE. %assert-single-runner (inside activate) never
  ;; trips.
  (%with-fresh-active-context
    (let* ((session (make-runtime-session))
           (sched (make-document-scheduler))
           (a (%make-doc-context session "A" "A"))
           (b (%make-doc-context session "B" "B"))
           (c (%make-doc-context session "C" "C")))
      (dolist (x (list a b c)) (scheduler-register-context sched x))
      (dolist (target (list a b c a c))
        (scheduler-activate sched target)
        (is (eq target (scheduler-current-context sched)))
        (is (eq :running (scheduled-context-status target)))
        (let ((running (remove :running (scheduler-context-list sched)
                               :key #'scheduled-context-status :test-not #'eq)))
          (is (= 1 (length running))
              "exactly one context RUNNING after activating ~A"
              (scheduled-context-document-key target)))))))

(test scheduler-activate-follows-current-document
  ;; Activation installs the context as the active one and flips the runtime
  ;; current document in lock-step.
  (%with-fresh-active-context
    (let* ((session (make-runtime-session))
           (sched (make-document-scheduler))
           (a (%make-doc-context session "A" "A"))
           (b (%make-doc-context session "B" "B")))
      (scheduler-register-context sched a)
      (scheduler-register-context sched b)
      (scheduler-activate sched b)
      (is (eq (scheduled-context-context b) (current-evaluation-context)))
      (is (eq (evaluation-context-current-document (scheduled-context-context b))
              (runtime-session-current-document session)))
      (scheduler-activate sched a)
      (is (eq (evaluation-context-current-document (scheduled-context-context a))
              (runtime-session-current-document session))))))

(test scheduler-activation-hook-fires-in-lockstep
  ;; *document-activation-hook* (the runtime->host seam) is called with the
  ;; session and the activated document on each switch. Restored via
  ;; unwind-protect so a suite re-run does not see a stale hook.
  (%with-fresh-active-context
    (let* ((session (make-runtime-session))
           (sched (make-document-scheduler))
           (a (%make-doc-context session "A" "A"))
           (b (%make-doc-context session "B" "B"))
           (calls '()))
      (scheduler-register-context sched a)
      (scheduler-register-context sched b)
      ;; Rebound by %with-fresh-active-context, so this SETF is local to the
      ;; test — it does not clobber the host layer's installed hook.
      (setf *document-activation-hook* (lambda (s d) (push (cons s d) calls)))
      (scheduler-activate sched a)
      (scheduler-activate sched b)
      (is (= 2 (length calls)))
      (is (eq session (car (first calls))))
      (is (eq (evaluation-context-current-document (scheduled-context-context b))
              (cdr (first calls)))))))            ; newest call = document B

(test single-document-session-has-no-scheduler
  ;; The no-regression guard: a fresh session has no scheduler, so
  ;; single-document behaviour is unchanged. (The activation hook may be nil,
  ;; or, in the full image, the host layer's installed lock-step hook — either
  ;; way it is a no-op for a document with no host-document-key, so it is not
  ;; asserted here.)
  (let ((session (make-runtime-session)))
    (is (null (session-scheduler session)))))

;;; --- Per-context save/restore (slice 2c) --------------------------

(test scheduler-activate-saves-and-restores-per-context-form
  ;; *current-form* is a per-context runtime global carried through saved-env:
  ;; demoting a context saves it, promoting a context restores it.
  (%with-fresh-active-context
    (let* ((session (make-runtime-session))
           (sched (make-document-scheduler))
           (x (%make-doc-context session "X" "X"))
           (y (%make-doc-context session "Y" "Y")))
      (scheduler-register-context sched x)
      (scheduler-register-context sched y)
      (scheduler-activate sched x)                             ; X runs
      (setf clautolisp.autolisp-runtime::*current-form* :form-a)
      (scheduler-activate sched y)                             ; demote X (saves A)
      (is (eq :form-a (getf (scheduled-context-saved-env x) :current-form)))
      (setf clautolisp.autolisp-runtime::*current-form* :form-b) ; Y's form
      (scheduler-activate sched x)                             ; promote X -> restore A
      (is (eq :form-a clautolisp.autolisp-runtime::*current-form*))
      ;; and Y's B was saved when Y was demoted
      (is (eq :form-b (getf (scheduled-context-saved-env y) :current-form))))))

(test scheduler-activate-restore-is-noop-for-never-run-context
  ;; First activation of a context (saved-env nil) must not clobber the global.
  (%with-fresh-active-context
    (let* ((session (make-runtime-session))
           (sched (make-document-scheduler))
           (x (%make-doc-context session "X" "X")))
      (scheduler-register-context sched x)
      (setf clautolisp.autolisp-runtime::*current-form* :sentinel)
      (scheduler-activate sched x)
      (is (eq :sentinel clautolisp.autolisp-runtime::*current-form*))
      (is (null (scheduled-context-saved-env x))))))

;;; --- Deferred-break discipline (slice 2c) -------------------------

(test scheduler-request-break-sets-flag-on-target-and-running
  (%with-fresh-active-context
    (let* ((session (make-runtime-session))
           (sched (make-document-scheduler))
           (x (%make-doc-context session "X" "X"))
           (y (%make-doc-context session "Y" "Y")))
      (scheduler-register-context sched x)
      (scheduler-register-context sched y)
      (scheduler-request-break sched y)              ; explicit target
      (is (scheduler-pending-break-p y))
      (is (not (scheduler-pending-break-p x)))
      (scheduler-activate sched x)
      (scheduler-request-break sched)                ; default = running (X)
      (is (scheduler-pending-break-p x)))))

(test scheduler-observe-break-clears-and-defers
  (%with-fresh-active-context
    (let* ((session (make-runtime-session))
           (sched (make-document-scheduler))
           (x (%make-doc-context session "X" "X"))
           (y (%make-doc-context session "Y" "Y")))
      (scheduler-register-context sched x)
      (scheduler-register-context sched y)
      (scheduler-activate sched x)
      (scheduler-request-break sched x)
      (is (eq t (scheduler-observe-break sched)))    ; running context's break due
      (is (null (scheduler-observe-break sched)))    ; cleared (observe-once)
      ;; a break on a NON-running context is deferred until it is activated
      (scheduler-request-break sched y)
      (is (null (scheduler-observe-break sched)))    ; X runs, Y's break not due
      (scheduler-activate sched y)
      (is (eq t (scheduler-observe-break sched))))))  ; now Y runs -> due
