(in-package #:clautolisp.cadtui.tests)

(in-suite cadtui-suite)

;;;; Phase 4 slice 1: per-console runtime plumbing (namespace + context + queue).
;;;; No live threads here — the read-eval loop and blocked-read park are slice 2.

(test console-namespaces-are-isolated-per-drawing
  ;; The anti-BricsCAD guarantee: a setq in one drawing's console namespace is
  ;; invisible in another's.
  (let* ((session (make-runtime-session))
         (app (make-application-tree))
         (dA (make-instance 'ui-drawing :key "A"))
         (cA (make-instance 'ui-console :key "console"))
         (dB (make-instance 'ui-drawing :key "B"))
         (cB (make-instance 'ui-console :key "console")))
    (add-child app dA) (add-child dA cA)
    (add-child app dB) (add-child dB cB)
    (make-console-context session cA :document-key "A")
    (make-console-context session cB :document-key "B")
    (let ((sym (intern-autolisp-symbol "X")))
      (document-namespace-set (console-namespace cA) sym 1)
      (multiple-value-bind (val boundp) (document-namespace-ref (console-namespace cA) sym)
        (is (eql 1 val))
        (is (eq t boundp)))
      (multiple-value-bind (val boundp) (document-namespace-ref (console-namespace cB) sym)
        (declare (ignore val))
        (is (null boundp))))                 ; X is not visible in drawing B
    ;; the session now has a scheduler, but slice 1 spawned no thread.
    (is (not (null (session-scheduler session))))
    (is (null (scheduled-context-thread (ui-context cA))))))

(test console-queue-is-type-ahead-fifo
  ;; Pass-through lines delivered before the thread reads queue in arrival order.
  (let* ((session (make-runtime-session))
         (app (make-application-tree))
         (d (make-instance 'ui-drawing :key "A"))
         (c (make-instance 'ui-console :key "console")))
    (add-child app d) (add-child d c)
    (make-console-context session c :document-key "A")
    (deliver-line-to-console c "one")
    (deliver-line-to-console c "two")
    (is (string= "one" (park-mailbox-pop (console-queue c) 5)))
    (is (string= "two" (park-mailbox-pop (console-queue c) 5)))))

(test single-document-session-stays-scheduler-free
  ;; No-regression: a session that never opens a per-drawing console keeps
  ;; SESSION-SCHEDULER nil (nothing in the Phase-4 plumbing runs for it).
  (let ((session (make-runtime-session)))
    (make-cador-tree)                        ; the degenerate config: no drawings
    (is (null (session-scheduler session)))))

;;;; Phase 4 slice 2: the park-aware blocked read (live thread).

(defun %console-teardown (session)
  "Unwind any still-parked console threads (push :exit, join) so no thread leaks
across the FiveAM double run."
  (let ((sched (session-scheduler session)))
    (when sched
      (dolist (sc (scheduler-context-list sched))
        (let ((th (scheduled-context-thread sc)))
          (when (and th (bordeaux-threads:thread-alive-p th))
            (ignore-errors (park-mailbox-push (scheduled-context-mailbox sc) :exit))
            (ignore-errors (bordeaux-threads:join-thread th))))))))

(defun %single-read-console (session key results)
  "A console under a fresh drawing whose thread reads ONE line and ships it to
RESULTS. Returns the ui-console."
  (let* ((app (make-application-tree))
         (d (make-instance 'ui-drawing :key key))
         (c (make-instance 'ui-console :key "console")))
    (add-child app d) (add-child d c)
    (make-console-context session c :document-key key
                          :thunk (lambda () (park-mailbox-push results (console-read-line c))))
    c))

(test console-read-consumes-a-queued-line
  ;; Type-ahead: a line queued before the thread reads is returned by its read.
  (let* ((session (make-runtime-session))
         (results (make-park-mailbox))
         (c (%single-read-console session "A" results)))
    (unwind-protect
         (progn
           (deliver-line-to-console c "hello")   ; queued before start
           (start-console c)
           (is (string= "hello" (park-mailbox-pop results 5))))
      (%console-teardown session))))

(test console-read-parks-until-a-line-arrives
  ;; An empty read parks (control returns to the driver, no runner); when the
  ;; driver delivers a line and serves the park, the read resumes with it.
  (let* ((session (make-runtime-session))
         (results (make-park-mailbox))
         (c (%single-read-console session "A" results))
         (sched (session-scheduler session)))
    (unwind-protect
         (progn
           (start-console c)                     ; queue empty -> the thread parks
           (let ((note (scheduler-await-park sched 5)))
             (is (eq :park (first note)))
             (is (null (scheduler-current-context sched)))   ; single-runner: none running while parked
             (deliver-line-to-console c "world")
             (scheduler-serve-park sched note))
           (is (string= "world" (park-mailbox-pop results 5))))
      (%console-teardown session))))
