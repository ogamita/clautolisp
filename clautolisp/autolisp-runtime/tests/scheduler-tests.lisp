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
  "Rebind *ACTIVE-EVALUATION-CONTEXT* around BODY so a test that calls
SCHEDULER-ACTIVATE (which SETFs the global active context, and calls
SET-RUNTIME-SESSION-CURRENT-DOCUMENT) cannot leak a throwaway test context
into later tests — the FiveAM shared-global hazard."
  `(let ((clautolisp.autolisp-runtime.internal::*active-evaluation-context*
           clautolisp.autolisp-runtime.internal::*active-evaluation-context*))
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
      (unwind-protect
           (progn
             (setf *document-activation-hook*
                   (lambda (s d) (push (cons s d) calls)))
             (scheduler-activate sched a)
             (scheduler-activate sched b)
             (is (= 2 (length calls)))
             (is (eq session (car (first calls))))
             (is (eq (evaluation-context-current-document
                      (scheduled-context-context b))
                     (cdr (first calls)))))       ; newest call = document B
        (setf *document-activation-hook* nil)))))

(test single-document-session-has-no-scheduler
  ;; The no-regression guard: a fresh session has no scheduler and the hook is
  ;; nil by default, so single-document behaviour is unchanged.
  (let ((session (make-runtime-session)))
    (is (null (session-scheduler session)))
    (is (null *document-activation-hook*))))
