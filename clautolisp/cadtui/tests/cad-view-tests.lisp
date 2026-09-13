(in-package #:clautolisp.cadtui.tests)

(in-suite cadtui-suite)

;;;; Phase 5 slice 1: entity/grip mirror, bounding boxes, the viewport.

(defun %line-entity (drawing handle x1 y1 x2 y2)
  "Add a LINE entity to DRAWING with the two given end points; return it."
  (add-entity drawing
              (list (cons 0 "LINE") (cons 8 "0")
                    (list 10 x1 y1 0) (list 11 x2 y2 0))
              :handle handle)
  (find-entity drawing handle))

(test entity->ui-entity-maps-handle-type-layer-and-grips
  (let* ((d (make-drawing))
         (e (%line-entity d "10" 0 0 10 5))
         (ui (entity->ui-entity e)))
    (is (eq :entity (ui-role ui)))
    (is (string= "10" (ui-key ui)))
    (is (string= "LINE" (clautolisp.cadtui::ui-entity-type ui)))
    (is (string= "0" (clautolisp.cadtui::ui-layer ui)))
    ;; one grip per point group, 1-based keys, in order.
    (is (equal '("1" "2") (mapcar #'ui-key (ui-children ui))))
    (let ((pt (clautolisp.cadtui::ui-grip-point (second (ui-children ui)))))
      (is (= 10 (first pt)))
      (is (= 5 (second pt))))))

(test entity-bounding-box-over-point-groups
  (let* ((d (make-drawing))
         (e (%line-entity d "10" 0 0 10 5))
         (box (entity-bounding-box e)))
    (is (= 0 (first box)))
    (is (= 0 (second box)))
    (is (= 10 (third box)))
    (is (= 5 (fourth box))))
  ;; an entity with no point groups has no box.
  (let* ((d (make-drawing))
         (e (progn (add-entity d (list (cons 0 "LAYER") (cons 8 "0")) :handle "5")
                   (find-entity d "5"))))
    (is (null (entity-bounding-box e)))))

(test bbox-intersects-predicate
  (is (clautolisp.cadtui::%bbox-intersects-p '(0 0 10 5) '(5 0 20 20)))     ; overlap
  (is (not (clautolisp.cadtui::%bbox-intersects-p '(0 0 10 5) '(20 20 30 30)))) ; disjoint
  (is (null (clautolisp.cadtui::%bbox-intersects-p nil '(0 0 100 100)))))  ; no box

(test viewport-bounds-accessor
  (is (null (viewport-bounds nil)))
  (let ((v (make-viewport :x1 0 :y1 0 :x2 100 :y2 50)))
    (is (equal '(0 0 100 50) (viewport-bounds v)))))

(test grip-dump-renders-index-and-point
  (let ((g (make-instance 'ui-grip :key "1" :index 1 :point '(1.0 2.0 0.0))))
    (let ((line (dump-node-to-string g)))
      (is (search "grip:1" line))
      (is (search "index=1" line))
      (is (search "point=(1.0 2.0 0.0)" line)))))

;;;; Phase 5 slice 2: the viewport wired to the zoom/pan verbs.

(defun %view-tree ()
  "An app with one drawing whose cad-view is reachable at
/application/drawings[1]/cad-view."
  (let ((app (make-application-tree))
        (dwg (make-instance 'ui-drawing :key "plan.dwg")))
    (add-child app dwg)
    (add-child dwg (make-instance 'ui-cad-view :key "cad-view"))
    app))

(test zoom-window-sets-viewport-bounds
  (let* ((app (%view-tree))
         (view (resolve-target app "/application/drawings[1]/cad-view"))
         (r (interpret-line "=zoom(/application/drawings[1]/cad-view, window: (0 0 100 50))" app)))
    (is (eq :ok (command-result-status r)))
    (is (equal '(0 0 100 50) (viewport-bounds (ui-viewport view))))))

(test zoom-factor-and-pan-return-ok-and-move-bounds
  (let* ((app (%view-tree))
         (view (resolve-target app "/application/drawings[1]/cad-view")))
    ;; establish a known window first.
    (interpret-line "=zoom(/application/drawings[1]/cad-view, window: (0 0 100 50))" app)
    ;; factor: 2 halves the window about its centre (50,25).
    (let ((r (interpret-line "=zoom(/application/drawings[1]/cad-view, factor: 2)" app)))
      (is (eq :ok (command-result-status r))))
    (let ((b (viewport-bounds (ui-viewport view))))
      (is (= 25 (first b)))  (is (= (/ 25 2) (second b)))
      (is (= 75 (third b)))  (is (= (/ 75 2) (fourth b))))
    ;; pan shifts the window by (dx dy).
    (let ((r (interpret-line "=pan(/application/drawings[1]/cad-view, 5, 5)" app)))
      (is (eq :ok (command-result-status r))))
    (let ((b (viewport-bounds (ui-viewport view))))
      (is (= 30 (first b)))
      (is (= 80 (third b))))))

(test dump-does-not-mutate-the-viewport
  (reset-dump-registry)
  (let* ((app (%view-tree))
         (view (resolve-target app "/application/drawings[1]/cad-view")))
    (interpret-line "=zoom(/application/drawings[1]/cad-view, window: (0 0 100 50))" app)
    (let ((before (viewport-bounds (ui-viewport view)))
          (r (interpret-line "=dump(/application/drawings[1]/cad-view)" app)))
      (is (eq :ok (command-result-status r)))
      (is (equal before (viewport-bounds (ui-viewport view)))))))
