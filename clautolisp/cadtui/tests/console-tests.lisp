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
