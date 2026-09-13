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
