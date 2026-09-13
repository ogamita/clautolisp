(in-package #:clautolisp.cadtui.tests)

(in-suite cadtui-suite)

;;;; Phase 2 slice 4: verb dispatch + the non-modal line entry.

(defun %dispatch-tree ()
  "A tree with one drawing (its own console + a cad-view of 5 entities), for the
dispatch tests."
  (let ((app (make-application-tree))          ; app + menu-bar + console
        (dwg (make-instance 'ui-drawing :key "plan.dwg")))
    (add-child app dwg)
    (add-child dwg (make-instance 'ui-console :key "console"))
    (let ((view (make-instance 'ui-cad-view :key "cad-view")))
      (add-child dwg view)
      (dotimes (i 5)
        (add-child view (make-instance 'ui-entity :key (format nil "e~D" (1+ i))))))
    app))

(test interpret-dump-returns-node-and-registers
  (reset-dump-registry)
  (let* ((app (make-application-tree))
         (r (interpret-line "=dump(/application/menu-bar, depth: 0)" app)))
    (is (eq :ok (command-result-status r)))
    (is (eq :dump (command-result-verb r)))
    (is (search "menu-bar:menu-bar" (command-result-text r)))
    (is (search "D1 " (command-result-text r)))
    (is (= 1 (dump-descriptor-number *last-dump*)))))

(test interpret-dump-paginates-and-next-pages
  (reset-dump-registry)
  (let* ((app (%dispatch-tree))
         (r1 (interpret-line "=dump(/application/drawings[1]/cad-view, page: 1, size: 2)" app)))
    (is (eq :ok (command-result-status r1)))
    (is (search "(2/5, 2 per page)" (command-result-text r1)))
    (is (search "entity:e1" (command-result-text r1)))
    (let ((r2 (interpret-line "=next" app)))
      (is (eq :ok (command-result-status r2)))
      (is (search "entity:e3" (command-result-text r2)))
      (is (not (search "entity:e1" (command-result-text r2)))))
    (let ((r3 (interpret-line "=previous" app)))
      (is (search "entity:e1" (command-result-text r3))))))

(test interpret-help-returns-repertoire
  (let ((r (interpret-line "=help()" (make-application-tree))))
    (is (eq :ok (command-result-status r)))
    (is (search "dump(" (command-result-text r)))))

(test interpret-pass-through-routes-to-app-console
  ;; No active drawing => the application console.
  (let* ((app (make-application-tree))
         (r (interpret-line "(setq a 1)" app)))
    (is (eq :pass-through (command-result-status r)))
    (is (string= "(setq a 1)" (command-result-text r)))
    (is (eq (ui-find-child app "console") (command-result-data r)))))

(test interpret-pass-through-routes-to-drawing-console
  ;; With an active drawing => that drawing's own console.
  (let* ((app (%dispatch-tree))
         (dwg (ui-find-child app "plan.dwg"))
         (r (interpret-line "CIRCLE" app)))
    (is (eq :pass-through (command-result-status r)))
    (is (eq (ui-find-child dwg "console") (command-result-data r)))))

(test interpret-verbe-shaped-pass-through-is-not-parsed
  ;; A line with no leading escape shaped like verbe(args) is pass-through.
  (let* ((app (make-application-tree))
         (r (interpret-line "touche(f2)" app)))
    (is (eq :pass-through (command-result-status r)))
    (is (string= "touche(f2)" (command-result-text r)))))

(test interpret-errors-become-error-results
  (let ((app (make-application-tree)))
    ;; parse error
    (is (eq :error (command-result-status (interpret-line "=dump(" app))))
    ;; address error
    (is (eq :error (command-result-status (interpret-line "=dump(/application/nope)" app))))
    ;; unknown verb
    (is (eq :error (command-result-status (interpret-line "=frobnicate()" app))))))
