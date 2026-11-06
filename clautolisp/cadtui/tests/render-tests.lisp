(in-package #:clautolisp.cadtui.tests)

(in-suite cadtui-suite)

;;;; Phase 8: the visual screen render backend seam (reuses interpret-line).

(defun %render-tree ()
  "An app with a menu bar and two drawings; the active one has a cad-view with
two entities and its own console."
  (let ((app (make-application-tree))
        (d1 (make-instance 'ui-drawing :key "a.dwg"))
        (d2 (make-instance 'ui-drawing :key "b.dwg")))
    (add-child app d1)
    (add-child app d2)
    (let ((view (make-instance 'ui-cad-view :key "cad-view")))
      (add-child d1 view)
      (add-child view (make-instance 'ui-entity :key "1"))
      (add-child view (make-instance 'ui-entity :key "2")))
    (add-child d1 (make-instance 'ui-console :key "console"))
    app))

(test text-screen-renders-menu-drawings-and-active-detail
  (let ((screen (render-screen-to-string (%render-tree))))
    (is (search "menu:" screen))
    ;; the active drawing is marked with a star, the other is not.
    (is (search "a.dwg*" screen))
    (is (search "b.dwg" screen))
    (is (search "--- a.dwg (active) ---" screen))
    (is (search "cad-view: 2 entit" screen))
    (is (search "console>" screen))))

(test text-screen-with-no-drawing-shows-the-application-console
  (let ((screen (render-screen-to-string (make-application-tree))))
    (is (search "no drawing" screen))
    (is (search "application console>" screen))))

(test ui-step-reuses-interpret-line-and-re-renders
  (let ((app (%render-tree)))
    ;; activating drawing 2 goes through the UNCHANGED interpret-line...
    (multiple-value-bind (result screen) (ui-step "=activate(drawings[2])" app)
      (is (eq :ok (command-result-status result)))
      ;; ...and the re-rendered screen shows b.dwg as the active drawing now.
      (is (search "b.dwg*" screen)))))

(test screen-renderer-seam-is-replaceable
  (let ((*screen-renderer*
          (lambda (root &key (stream *standard-output*))
            (declare (ignore root))
            (format stream "CUSTOM BACKEND"))))
    (is (string= "CUSTOM BACKEND"
                 (render-screen-to-string (make-application-tree))))))
