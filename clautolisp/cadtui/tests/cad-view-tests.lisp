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

;;;; Phase 5 slice 3: dump-entities — spatial cull, pagination, provider reuse.

(defun %entity-drawing ()
  "A drawing of five LINE entities (handles 1..5) at x = 0,10,20,30,40, each a
1x1 segment, so a window can pick a known prefix."
  (let ((d (make-drawing)))
    (dotimes (i 5)
      (let ((x (* i 10)))
        (add-entity d (list (cons 0 "LINE") (cons 8 "0")
                            (list 10 x 0 0) (list 11 (+ x 1) 1 0))
                    :handle (princ-to-string (1+ i)))))
    d))

(defun %sink () (make-broadcast-stream))

(test dump-entities-paginates-and-provider-repages-lazily
  (reset-dump-registry)
  (let* ((d (%entity-drawing))
         (view (make-instance 'ui-cad-view :key "cad-view" :drawing d))
         (desc (dump-entities view :page 1 :page-size 2 :stream (%sink))))
    (is (= 5 (dump-descriptor-total desc)))
    ;; only the shown page is mirrored into nodes (lazy, one page at a time).
    (is (equal '("1" "2") (mapcar #'ui-key (ui-children view))))
    ;; page 2 re-reads through the provider; children become the new page only.
    (is (dump-page desc 2 :stream (%sink)))
    (is (equal '("3" "4") (mapcar #'ui-key (ui-children view))))
    (is (dump-page desc 3 :stream (%sink)))
    (is (equal '("5") (mapcar #'ui-key (ui-children view))))
    ;; page 4 is out of range.
    (is (null (dump-page desc 4 :stream (%sink))))))

(test dump-entities-culls-to-an-explicit-window
  (reset-dump-registry)
  (let* ((d (%entity-drawing))
         (view (make-instance 'ui-cad-view :key "cad-view" :drawing d))
         (desc (dump-entities view :window '(0 0 5 100) :page-size 50 :stream (%sink))))
    ;; only entity 1 (bbox 0..1) meets the x<=5 window.
    (is (= 1 (dump-descriptor-total desc)))
    (is (equal '("1") (mapcar #'ui-key (ui-children view))))))

(test dump-entities-culls-to-the-viewport-when-no-window-given
  (reset-dump-registry)
  (let* ((d (%entity-drawing))
         (view (make-instance 'ui-cad-view :key "cad-view" :drawing d
                              :viewport (make-viewport :x1 0 :y1 0 :x2 25 :y2 100))))
    (let ((desc (dump-entities view :page-size 50 :stream (%sink))))
      ;; entities 1,2,3 (x 0,10,20) fall inside x<=25; 4,5 do not.
      (is (= 3 (dump-descriptor-total desc)))
      (is (equal '("1" "2" "3") (mapcar #'ui-key (ui-children view)))))))

(test dump-entities-with-no-window-and-no-viewport-shows-all
  (reset-dump-registry)
  (let* ((d (%entity-drawing))
         (view (make-instance 'ui-cad-view :key "cad-view" :drawing d))
         (desc (dump-entities view :page-size 50 :stream (%sink))))
    (is (= 5 (dump-descriptor-total desc)))
    (is (equal '("1" "2" "3" "4" "5") (mapcar #'ui-key (ui-children view))))))

;;;; Phase 5 slice 4: the :dump verb routes entities requests to dump-entities.

(defun %entities-view-tree ()
  "An app whose drawings[1]/cad-view carries a five-entity drawing."
  (let ((app (make-application-tree))
        (dwg (make-instance 'ui-drawing :key "plan.dwg"))
        (view (make-instance 'ui-cad-view :key "cad-view" :drawing (%entity-drawing))))
    (add-child app dwg)
    (add-child dwg view)
    (values app view)))

(test dump-verb-routes-an-entities-path-with-a-window
  (reset-dump-registry)
  (multiple-value-bind (app view) (%entities-view-tree)
    (let ((r (interpret-line
              "=dump(/application/drawings[1]/cad-view/entities, window: (0 0 5 100))"
              app)))
      (is (eq :ok (command-result-status r)))
      (is (= 1 (dump-descriptor-total (command-result-data r))))
      (is (equal '("1") (mapcar #'ui-key (ui-children view)))))))

(test dump-verb-routes-the-entities-keyword-with-pagination
  (reset-dump-registry)
  (multiple-value-bind (app view) (%entities-view-tree)
    (let ((r (interpret-line
              "=dump(/application/drawings[1]/cad-view, :entities, size: 2)" app)))
      (is (eq :ok (command-result-status r)))
      (is (= 5 (dump-descriptor-total (command-result-data r))))
      (is (equal '("1" "2") (mapcar #'ui-key (ui-children view)))))))

(test entities-dump-grips-addressable-by-dotted-reference
  (reset-dump-registry)
  (let* ((d (%entity-drawing))
         (view (make-instance 'ui-cad-view :key "cad-view" :drawing d)))
    (dump-entities view :page-size 50 :stream (%sink))  ; registers D1
    ;; D1.<handle>.<grip-key>: entity 3, then its 2nd grip.
    (let ((g (resolve-target view "D1.3.2")))
      (is (eq :grip (ui-role g)))
      (is (string= "2" (ui-key g))))
    ;; the same via the last-dump dotted form (no D prefix).
    (let ((g2 (resolve-target view "3.2")))
      (is (eq :grip (ui-role g2)))
      (is (string= "2" (ui-key g2))))))
