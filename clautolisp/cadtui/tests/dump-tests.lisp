(in-package #:clautolisp.cadtui.tests)

(in-suite cadtui-suite)

;;;; Phase 1 slice 2: structured text dump + tree builders.

(test cador-tree-is-application-plus-console
  ;; The degenerate --host cador config: /application with only the console.
  (let ((app (make-cador-tree)))
    (is (eq :application (ui-role app)))
    (is (equal '("console") (mapcar #'ui-key (ui-children app))))
    (is (string= (format nil "application:application~%  console:console~%")
                 (dump-node-to-string app)))))

(test application-tree-has-menubar-and-console
  ;; The full --host cadtui skeleton: barre-menu then console, dessins[] empty.
  (let ((app (make-application-tree)))
    (is (equal '("barre-menu" "console") (mapcar #'ui-key (ui-children app))))
    (is (string= (format nil "application:application~%  barre-menu:barre-menu~%  console:console~%")
                 (dump-node-to-string app)))))

(test dump-depth-0-shows-only-the-node
  ;; profondeur: 0 dumps the node alone, to inspect just its state.
  (let ((app (make-application-tree)))
    (is (string= (format nil "application:application~%")
                 (dump-node-to-string app :depth 0)))))

(test dump-depth-1-shows-direct-children-only
  (let* ((app (make-instance 'ui-application :key "application"))
         (dwg (make-instance 'ui-drawing :key "plan.dwg"))
         (view (make-instance 'ui-cad-view :key "vue-cad")))
    (add-child app dwg)
    (add-child dwg view)                       ; grandchild, must not appear
    (is (string= (format nil "application:application~%  dessin:plan.dwg~%")
                 (dump-node-to-string app :depth 1)))))

(test dump-line-renders-label-and-attributes
  ;; ROLE:KEY  LABEL, then downcased keyword attributes.
  (let ((menu (make-instance 'ui-menu :key "m1" :label "Dessiner")))
    (is (string= (format nil "menu:m1  Dessiner~%")
                 (dump-node-to-string menu))))
  (let ((band (make-instance 'ui-band :key "b1" :style :ribbon)))
    (is (string= (format nil "bandeau:b1  style=ribbon~%")
                 (dump-node-to-string band))))
  (let ((ent (make-instance 'ui-entity :key "2A" :entity-type "LINE" :layer "0")))
    (is (string= (format nil "entite:2A  type=LINE  calque=0~%")
                 (dump-node-to-string ent)))))

(test dump-line-shows-non-normal-state
  ;; The base attribute every node may carry: a non-:normal display state.
  (let ((item (make-instance 'ui-menu-item :key "i1" :label "Ligne" :state :grise)))
    (is (string= (format nil "item:i1  Ligne  etat=grise~%")
                 (dump-node-to-string item))))
  ;; :normal state is the default and is not rendered.
  (let ((item (make-instance 'ui-menu-item :key "i2" :label "Cercle")))
    (is (string= (format nil "item:i2  Cercle~%")
                 (dump-node-to-string item)))))

(test dump-indents-by-nesting-depth
  (let* ((app (make-instance 'ui-application :key "application"))
         (dwg (make-instance 'ui-drawing :key "plan.dwg"))
         (view (make-instance 'ui-cad-view :key "vue-cad"))
         (ent (make-instance 'ui-entity :key "2A")))
    (add-child app dwg)
    (add-child dwg view)
    (add-child view ent)
    (is (string= (format nil "application:application~%  dessin:plan.dwg~%    vue-cad:vue-cad~%      entite:2A~%")
                 (dump-node-to-string app)))))

(test dump-header-format-and-counter
  ;; The paginated-dump header seam: D<n> <path> (shown/total, size par page),
  ;; with a monotonic dump number.
  (let ((*dump-counter* 0))
    (is (string= (format nil "D1 /application/dessins[1]/vue-cad/entites (50/5000, 50 par page)~%")
                 (with-output-to-string (s)
                   (dump-header "/application/dessins[1]/vue-cad/entites" 5000
                                :shown 50 :page-size 50 :stream s))))
    ;; the number advances for the next distinct dump
    (is (= 2 (next-dump-number)))))
