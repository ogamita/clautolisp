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

;;; --- Continuations as parked threads (slice 3d) -------------------

(defun %park-teardown (scheduler)
  "Unwind any still-parked context threads (push :exit, then join) so no thread
leaks across the FiveAM double run."
  (dolist (sc (scheduler-context-list scheduler))
    (let ((th (scheduled-context-thread sc)))
      (when (and th (bordeaux-threads:thread-alive-p th))
        (ignore-errors (park-mailbox-push (scheduled-context-mailbox sc) :exit))
        (ignore-errors (bordeaux-threads:join-thread th))))))

(test scheduler-spawns-parked-thread-and-starts-it
  ;; A spawned context is born parked (thread alive, nothing run); scheduler-start
  ;; wakes it and it runs as the current context.
  (%with-fresh-active-context
    (let* ((session (make-runtime-session))
           (sched (make-document-scheduler))
           (x (%make-doc-context session "X" "X"))
           (results (make-park-mailbox)))
      (scheduler-register-context sched x)
      (scheduler-spawn-context sched x
        (lambda ()
          (park-mailbox-push results
                             (list :ran (eq x (scheduler-current-context sched))))))
      (unwind-protect
           (progn
             (is (bordeaux-threads:thread-alive-p (scheduled-context-thread x)))
             (scheduler-start sched x)
             (is (equal '(:ran t) (park-mailbox-pop results 5))))
        (%park-teardown sched)))))

(test scheduler-switch-hands-off-exactly-one-running
  ;; Two context threads hand control back and forth via the condvar rendezvous;
  ;; the strict interleaving proves exactly one runs at a time.
  (%with-fresh-active-context
    (let* ((session (make-runtime-session))
           (sched (make-document-scheduler))
           (a (%make-doc-context session "A" "A"))
           (b (%make-doc-context session "B" "B"))
           (results (make-park-mailbox)))
      (scheduler-register-context sched a)
      (scheduler-register-context sched b)
      (flet ((thunk (self other first second done)
               (lambda ()
                 (park-mailbox-push results first)
                 (let ((tok (scheduler-switch sched self other)))
                   (unless (eq tok :exit) (park-mailbox-push results second)))
                 (park-mailbox-push results done))))
        (scheduler-spawn-context sched a (thunk a b :a-first :a-second :a-done))
        (scheduler-spawn-context sched b (thunk b a :b-first :b-second :b-done))
        (unwind-protect
             (progn
               (scheduler-start sched a)
               ;; A runs, parks at switch; B runs, parks at switch; A resumes+finishes.
               (is (eq :a-first  (park-mailbox-pop results 5)))
               (is (eq :b-first  (park-mailbox-pop results 5)))
               (is (eq :a-second (park-mailbox-pop results 5)))
               (is (eq :a-done   (park-mailbox-pop results 5)))
               ;; B is still parked in its switch; resume it to let it finish.
               (scheduler-resume sched b)
               (is (eq :b-second (park-mailbox-pop results 5)))
               (is (eq :b-done   (park-mailbox-pop results 5))))
          (%park-teardown sched))))))

(test scheduler-activate-spawns-no-thread
  ;; No-regression: the synchronous activation path creates no threads (only
  ;; scheduler-spawn-context does), so single-document behaviour stays thread-free.
  (%with-fresh-active-context
    (let* ((session (make-runtime-session))
           (sched (make-document-scheduler))
           (a (%make-doc-context session "A" "A"))
           (b (%make-doc-context session "B" "B")))
      (scheduler-register-context sched a)
      (scheduler-register-context sched b)
      (scheduler-activate sched a)
      (scheduler-activate sched b)
      (is (null (scheduled-context-thread a)))
      (is (null (scheduled-context-thread b))))))

;;; --- Rendezvous folded into SCHEDULER-ACTIVATE (slice 3e) ----------
;;;
;;; A thread-backed context carries a THUNK; SCHEDULER-ACTIVATE dispatches on it.
;;; From the driver it bootstraps (spawn + start); from a running context's own
;;; thread it hands off through SCHEDULER-SWITCH. Env install runs on the woken
;;; thread. All pops are timeout-guarded and all threads torn down.

(test activate-bootstraps-and-runs-thread-backed-context
  ;; A context with a THUNK, activated from the driver, is spawned and started:
  ;; the thunk runs on its own thread as the :RUNNING current context.
  (%with-fresh-active-context
    (let* ((session (make-runtime-session))
           (sched (make-document-scheduler))
           (x (%make-doc-context session "X" "X"))
           (results (make-park-mailbox)))
      (setf (scheduled-context-thunk x)
            (lambda ()
              (park-mailbox-push
               results
               (list :ran
                     (eq x (scheduler-current-context sched))
                     (scheduled-context-status x)))))
      (scheduler-register-context sched x)
      (unwind-protect
           (progn
             (scheduler-activate sched x)             ; driver: spawn + start
             (is (equal '(:ran t :running) (park-mailbox-pop results 5))))
        (%park-teardown sched)))))

(test activate-from-context-thread-hands-off-via-switch
  ;; When a RUNNING thread-backed context activates another, the call routes
  ;; through SCHEDULER-SWITCH (hand-off), not a driver start. The strict
  ;; interleaving proves exactly one context runs at a time — the activate-driven
  ;; analogue of scheduler-switch-hands-off-exactly-one-running.
  (%with-fresh-active-context
    (let* ((session (make-runtime-session))
           (sched (make-document-scheduler))
           (a (%make-doc-context session "A" "A"))
           (b (%make-doc-context session "B" "B"))
           (results (make-park-mailbox)))
      (setf (scheduled-context-thunk a)
            (lambda ()
              (park-mailbox-push results :a-first)
              (scheduler-activate sched b)            ; A's thread => hand off to B
              (park-mailbox-push results :a-second)
              (park-mailbox-push results :a-done)))
      (setf (scheduled-context-thunk b)
            (lambda ()
              (park-mailbox-push results :b-first)
              (scheduler-activate sched a)            ; B's thread => hand back to A
              (park-mailbox-push results :b-done)))
      (scheduler-register-context sched a)
      (scheduler-register-context sched b)
      (unwind-protect
           (progn
             (scheduler-activate sched a)             ; driver: bootstrap A
             (is (eq :a-first  (park-mailbox-pop results 5)))
             (is (eq :b-first  (park-mailbox-pop results 5)))
             (is (eq :a-second (park-mailbox-pop results 5)))
             (is (eq :a-done   (park-mailbox-pop results 5)))
             ;; B is still parked inside its hand-off; resume it to finish.
             (scheduler-resume sched b)
             (is (eq :b-done   (park-mailbox-pop results 5))))
        (%park-teardown sched)))))

(test activate-installs-env-on-woken-thread
  ;; Each woken context thread installs ITS OWN evaluation context (thread-local
  ;; *active-evaluation-context*) before running — the §13.5 handoff install and
  ;; the per-thread binding: each thread sees only its own context.
  (%with-fresh-active-context
    (let* ((session (make-runtime-session))
           (sched (make-document-scheduler))
           (a (%make-doc-context session "A" "A"))
           (b (%make-doc-context session "B" "B"))
           (results (make-park-mailbox)))
      (setf (scheduled-context-thunk a)
            (lambda ()
              (park-mailbox-push results
                                 (list :a (eq (scheduled-context-context a)
                                              (current-evaluation-context))))
              (scheduler-activate sched b)))
      (setf (scheduled-context-thunk b)
            (lambda ()
              (park-mailbox-push results
                                 (list :b (eq (scheduled-context-context b)
                                              (current-evaluation-context))))))
      (scheduler-register-context sched a)
      (scheduler-register-context sched b)
      (unwind-protect
           (progn
             (scheduler-activate sched a)
             (is (equal '(:a t) (park-mailbox-pop results 5)))
             (is (equal '(:b t) (park-mailbox-pop results 5))))
        (%park-teardown sched)))))

(test activate-mixes-bare-and-thread-backed
  ;; A bare context (THUNK nil) activated after a thread-backed one still takes
  ;; the synchronous path and spawns no thread; the mixed :runnable/:parked
  ;; scheduler passes %assert-single-runner (one runner across the mix).
  (%with-fresh-active-context
    (let* ((session (make-runtime-session))
           (sched (make-document-scheduler))
           (t1 (%make-doc-context session "T1" "T1"))
           (bare (%make-doc-context session "BARE" "BARE"))
           (results (make-park-mailbox)))
      (setf (scheduled-context-thunk t1)
            (lambda () (park-mailbox-push results :t1-ran)))
      (scheduler-register-context sched t1)
      (scheduler-register-context sched bare)
      (unwind-protect
           (progn
             (scheduler-activate sched t1)            ; thread-backed: spawn + start
             (is (eq :t1-ran (park-mailbox-pop results 5)))
             (scheduler-activate sched bare)          ; bare: synchronous path
             (is (eq bare (scheduler-current-context sched)))
             (is (eq :running (scheduled-context-status bare)))
             (is (null (scheduled-context-thread bare)))  ; bare spawned no thread
             (let ((running (remove :running (scheduler-context-list sched)
                                    :key #'scheduled-context-status
                                    :test-not #'eq)))
               (is (= 1 (length running)))))           ; single runner across the mix
        (%park-teardown sched)))))

;;; --- Park-to-runner: interactive-input parking (slice 3f) ---------
;;;
;;; A running context that parks waiting for input yields to the DRIVER via the
;;; scheduler's driver-mailbox; the driver obtains the response (running the
;;; request on its OWN thread) and resumes the context. All pops timeout-guarded,
;;; all threads torn down.

(test scheduler-park-notifies-driver-and-resumes-with-response
  ;; A context parks with a request; the driver is notified (:park sc request),
  ;; serves it, and the parked context resumes with the response value.
  (%with-fresh-active-context
    (let* ((session (make-runtime-session))
           (sched (make-document-scheduler))
           (x (%make-doc-context session "X" "X"))
           (results (make-park-mailbox)))
      (scheduler-register-context sched x)
      (scheduler-spawn-context sched x
        (lambda ()
          (park-mailbox-push results :about-to-park)
          (let ((resp (scheduler-park sched x (lambda () :resp))))
            (park-mailbox-push results (list :resumed resp)))))
      (unwind-protect
           (progn
             (scheduler-start sched x)
             (is (eq :about-to-park (park-mailbox-pop results 5)))
             (let ((note (scheduler-await-park sched 5)))
               (is (eq :park (first note)))
               (is (eq x (second note)))
               (scheduler-serve-park sched note))
             (is (equal '(:resumed :resp) (park-mailbox-pop results 5))))
        (%park-teardown sched)))))

(test scheduler-park-clears-runner-then-restores-on-resume
  ;; While parked, RUNNING is nil and the context is :parked (single-runner holds
  ;; with zero runners); after serve+resume the context is :running again.
  (%with-fresh-active-context
    (let* ((session (make-runtime-session))
           (sched (make-document-scheduler))
           (x (%make-doc-context session "X" "X"))
           (results (make-park-mailbox)))
      (scheduler-register-context sched x)
      (scheduler-spawn-context sched x
        (lambda ()
          (scheduler-park sched x (lambda () :ok))
          (park-mailbox-push results :done)))
      (unwind-protect
           (let ((note (progn (scheduler-start sched x)
                              (scheduler-await-park sched 5))))
             (is (null (scheduler-current-context sched)))   ; no runner while parked
             (is (eq :parked (scheduled-context-status x)))
             (scheduler-serve-park sched note)
             (is (eq :done (park-mailbox-pop results 5)))
             (is (eq x (scheduler-current-context sched)))   ; re-promoted on resume
             (is (eq :running (scheduled-context-status x))))
        (%park-teardown sched)))))

(test scheduler-serve-park-runs-request-on-driver-thread
  ;; The blocking request runs on the DRIVER thread (via serve-park), never on
  ;; the context/runner thread (D1 §13.1 -- a host request does not block the
  ;; runner).
  (%with-fresh-active-context
    (let* ((session (make-runtime-session))
           (sched (make-document-scheduler))
           (x (%make-doc-context session "X" "X"))
           (results (make-park-mailbox))
           (driver (bordeaux-threads:current-thread)))
      (scheduler-register-context sched x)
      (scheduler-spawn-context sched x
        (lambda ()
          (scheduler-park sched x
            (lambda ()
              (park-mailbox-push
               results
               (list :req
                     (eq (bordeaux-threads:current-thread) driver)
                     (eq (bordeaux-threads:current-thread)
                         (scheduled-context-thread x))))
              :resp))))
      (unwind-protect
           (progn
             (scheduler-start sched x)
             (scheduler-serve-park sched (scheduler-await-park sched 5))
             (is (equal '(:req t nil) (park-mailbox-pop results 5))))
        (%park-teardown sched)))))

(test scheduler-park-exit-token-unwinds-without-reinstall
  ;; A parked context resumed with :exit returns :exit (no re-promote/reinstall)
  ;; and unwinds -- the teardown contract.
  (%with-fresh-active-context
    (let* ((session (make-runtime-session))
           (sched (make-document-scheduler))
           (x (%make-doc-context session "X" "X"))
           (results (make-park-mailbox)))
      (scheduler-register-context sched x)
      (scheduler-spawn-context sched x
        (lambda ()
          (let ((tok (scheduler-park sched x (lambda () :never))))
            (park-mailbox-push results (list :exited tok)))))
      (unwind-protect
           (progn
             (scheduler-start sched x)
             (scheduler-await-park sched 5)                  ; ensure it parked
             (park-mailbox-push (scheduled-context-mailbox x) :exit)
             (is (equal '(:exited :exit) (park-mailbox-pop results 5))))
        (%park-teardown sched)))))

(test scheduler-on-context-thread-p-predicate
  ;; NIL from the driver thread (or with nothing running); T from inside a
  ;; running context's own thread.
  (%with-fresh-active-context
    (let* ((session (make-runtime-session))
           (sched (make-document-scheduler))
           (x (%make-doc-context session "X" "X"))
           (results (make-park-mailbox)))
      (scheduler-register-context sched x)
      (is (null (scheduler-on-context-thread-p sched)))      ; driver, nothing running
      (scheduler-spawn-context sched x
        (lambda ()
          (park-mailbox-push results
                             (list :on (scheduler-on-context-thread-p sched)))))
      (unwind-protect
           (progn
             (scheduler-start sched x)
             (is (equal '(:on t) (park-mailbox-pop results 5))))
        (%park-teardown sched)))))
