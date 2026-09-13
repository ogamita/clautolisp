(in-package #:clautolisp.cadtui.tests)

(in-suite cadtui-suite)

;;;; Phase 1 slice 2: structured text dump + tree builders.
;;;; Canonical tokens are English (a Phase-7 locale layer renders localised
;;;; surface forms); the golden dumps below are the canonical rendering.

(test cador-tree-is-application-plus-console
  ;; The degenerate --host cador config: /application with only the console.
  (let ((app (make-cador-tree)))
    (is (eq :application (ui-role app)))
    (is (equal '("console") (mapcar #'ui-key (ui-children app))))
    (is (string= (format nil "application:application~%  console:console~%")
                 (dump-node-to-string app)))))

(test application-tree-has-menubar-and-console
  ;; The full --host cadtui skeleton: menu-bar then console, drawings[] empty.
  (let ((app (make-application-tree)))
    (is (equal '("menu-bar" "console") (mapcar #'ui-key (ui-children app))))
    (is (string= (format nil "application:application~%  menu-bar:menu-bar~%  console:console~%")
                 (dump-node-to-string app)))))

(test dump-depth-0-shows-only-the-node
  ;; depth 0 dumps the node alone, to inspect just its state.
  (let ((app (make-application-tree)))
    (is (string= (format nil "application:application~%")
                 (dump-node-to-string app :depth 0)))))

(test dump-depth-1-shows-direct-children-only
  (let* ((app (make-instance 'ui-application :key "application"))
         (dwg (make-instance 'ui-drawing :key "plan.dwg"))
         (view (make-instance 'ui-cad-view :key "cad-view")))
    (add-child app dwg)
    (add-child dwg view)                       ; grandchild, must not appear
    (is (string= (format nil "application:application~%  drawing:plan.dwg~%")
                 (dump-node-to-string app :depth 1)))))

(test dump-line-renders-label-and-attributes
  ;; ROLE:KEY  LABEL, then downcased keyword attributes.
  (let ((menu (make-instance 'ui-menu :key "m1" :label "Draw")))
    (is (string= (format nil "menu:m1  Draw~%")
                 (dump-node-to-string menu))))
  (let ((band (make-instance 'ui-band :key "b1" :style :ribbon)))
    (is (string= (format nil "band:b1  style=ribbon~%")
                 (dump-node-to-string band))))
  (let ((ent (make-instance 'ui-entity :key "2A" :entity-type "LINE" :layer "0")))
    (is (string= (format nil "entity:2A  type=LINE  layer=0~%")
                 (dump-node-to-string ent)))))

(test dump-line-shows-non-normal-state
  ;; The base attribute every node may carry: a non-:normal display state.
  (let ((item (make-instance 'ui-menu-item :key "i1" :label "Line" :state :grayed)))
    (is (string= (format nil "item:i1  Line  state=grayed~%")
                 (dump-node-to-string item))))
  ;; :normal state is the default and is not rendered.
  (let ((item (make-instance 'ui-menu-item :key "i2" :label "Circle")))
    (is (string= (format nil "item:i2  Circle~%")
                 (dump-node-to-string item)))))

(test dump-indents-by-nesting-depth
  (let* ((app (make-instance 'ui-application :key "application"))
         (dwg (make-instance 'ui-drawing :key "plan.dwg"))
         (view (make-instance 'ui-cad-view :key "cad-view"))
         (ent (make-instance 'ui-entity :key "2A")))
    (add-child app dwg)
    (add-child dwg view)
    (add-child view ent)
    (is (string= (format nil "application:application~%  drawing:plan.dwg~%    cad-view:cad-view~%      entity:2A~%")
                 (dump-node-to-string app)))))

(test dump-header-format-and-counter
  ;; The paginated-dump header seam: D<n> <path> (shown/total, size per page),
  ;; with a monotonic dump number.
  (let ((*dump-counter* 0))
    (is (string= (format nil "D1 /application/drawings[1]/cad-view/entities (50/5000, 50 per page)~%")
                 (with-output-to-string (s)
                   (dump-header "/application/drawings[1]/cad-view/entities" 5000
                                :shown 50 :page-size 50 :stream s))))
    ;; the number advances for the next distinct dump
    (is (= 2 (next-dump-number)))))

;;;; Phase 2 slice 3: dump registry + pagination.

(test register-dump-records-entries-and-allocates-number
  (reset-dump-registry)
  (let* ((app (make-instance 'ui-application :key "application"))
         (dwg (make-instance 'ui-drawing :key "plan.dwg")))
    (add-child app dwg)
    (add-child dwg (make-instance 'ui-cad-view :key "cad-view"))
    (let ((desc (register-dump app :path "/application")))
      (is (= 1 (dump-descriptor-number desc)))
      (is (eq desc (find-dump 1)))
      (is (eq desc *last-dump*))
      ;; every rendered node's key is recorded
      (is (not (null (assoc "cad-view" (clautolisp.cadtui::dump-descriptor-entries desc)
                            :test #'string=)))))))

(test dump-list-paginates-and-pages-under-same-number
  (reset-dump-registry)
  (let ((view (make-instance 'ui-cad-view :key "cad-view")))
    (dotimes (i 5)
      (add-child view (make-instance 'ui-entity :key (format nil "e~D" (1+ i)))))
    ;; page 1 of size 2: header (D1) + entities e1,e2
    (let ((out (with-output-to-string (s)
                 (dump-list view :page 1 :page-size 2
                            :path "/application/drawings[1]/cad-view/entities"
                            :stream s))))
      (is (search "D1 /application/drawings[1]/cad-view/entities (2/5, 2 per page)" out))
      (is (search "entity:e1" out))
      (is (search "entity:e2" out))
      (is (not (search "entity:e3" out))))
    ;; page 2 under the SAME D1
    (let ((out (with-output-to-string (s)
                 (dump-page *last-dump* 2 :stream s))))
      (is (search "D1 " out))                 ; same number
      (is (= 2 (dump-descriptor-page *last-dump*)))
      (is (search "entity:e3" out))
      (is (search "entity:e4" out))
      (is (not (search "entity:e1" out))))
    ;; out-of-range page returns nil
    (is (null (dump-page *last-dump* 9)))))
