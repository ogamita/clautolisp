(in-package #:clautolisp.cadtui.tests)

(in-suite cadtui-suite)

;;;; Phase 1: the UI-node tree model.

(test ui-node-default-attributes
  ;; A fresh node carries its class role, an unset label/action, :normal state,
  ;; and no parent/children.
  (let ((n (make-instance 'ui-console :key "console")))
    (is (string= "console" (ui-key n)))
    (is (eq :console (ui-role n)))
    (is (null (ui-label n)))
    (is (eq :normal (ui-state n)))
    (is (null (ui-action n)))
    (is (null (ui-parent n)))
    (is (null (ui-children n)))
    (is (eq t (ui-root-p n)))))

(test ui-node-roles-are-per-class
  ;; Each subclass defaults its role to the spec's canonical keyword.
  (is (eq :application (ui-role (make-instance 'ui-application :key "app"))))
  (is (eq :menu-bar  (ui-role (make-instance 'ui-menubar :key "mb"))))
  (is (eq :menu        (ui-role (make-instance 'ui-menu :key "m"))))
  (is (eq :item        (ui-role (make-instance 'ui-menu-item :key "i"))))
  (is (eq :drawing      (ui-role (make-instance 'ui-drawing :key "d"))))
  (is (eq :band     (ui-role (make-instance 'ui-band :key "b"))))
  (is (eq :button      (ui-role (make-instance 'ui-button :key "bt"))))
  (is (eq :ribbon-tab      (ui-role (make-instance 'ui-ribbon-tab :key "t"))))
  (is (eq :ribbon-panel     (ui-role (make-instance 'ui-ribbon-panel :key "p"))))
  (is (eq :cad-view     (ui-role (make-instance 'ui-cad-view :key "v"))))
  (is (eq :entity      (ui-role (make-instance 'ui-entity :key "e"))))
  (is (eq :grip     (ui-role (make-instance 'ui-grip :key "g"))))
  (is (eq :alert      (ui-role (make-instance 'ui-alert :key "a"))))
  (is (eq :dialog    (ui-role (make-instance 'ui-dialog :key "dl"))))
  (is (eq :tile       (ui-role (make-instance 'ui-tile :key "tl")))))

(test add-child-links-parent-and-preserves-order
  ;; add-child appends in call order and back-links each child to its parent.
  (let* ((app (make-instance 'ui-application :key "app"))
         (d1 (make-instance 'ui-drawing :key "plan-masse.dwg"))
         (d2 (make-instance 'ui-drawing :key "coupe.dwg"))
         (console (make-instance 'ui-console :key "console")))
    (add-child app d1)
    (add-child app d2)
    (add-child app console)
    (is (equal (list d1 d2 console) (ui-children app)))       ; registration order
    (is (eq app (ui-parent d1)))
    (is (eq app (ui-parent d2)))
    (is (eq app (ui-parent console)))
    (is (eq nil (ui-root-p d1)))
    (is (eq t (ui-root-p app)))))

(test add-child-returns-the-child
  (let ((app (make-instance 'ui-application :key "app"))
        (console (make-instance 'ui-console :key "console")))
    (is (eq console (add-child app console)))))

(test ui-find-child-finds-by-key
  (let* ((app (make-instance 'ui-application :key "app"))
         (console (make-instance 'ui-console :key "console"))
         (d1 (make-instance 'ui-drawing :key "plan.dwg")))
    (add-child app console)
    (add-child app d1)
    (is (eq console (ui-find-child app "console")))
    (is (eq d1 (ui-find-child app "plan.dwg")))
    (is (null (ui-find-child app "absent")))))

(test add-child-rejects-a-duplicate-sibling-key
  ;; Sibling keys must be unique so addressing stays stable — a second child
  ;; with the same key signals DUPLICATE-SIBLING-KEY and is not added.
  (let* ((app (make-instance 'ui-application :key "app"))
         (c1 (make-instance 'ui-console :key "console"))
         (c2 (make-instance 'ui-console :key "console"))
         (signalled nil))
    (add-child app c1)
    (handler-case (add-child app c2)
      (duplicate-sibling-key () (setf signalled t)))
    (is (eq t signalled))
    (is (equal (list c1) (ui-children app)))     ; c2 was not added
    (is (null (ui-parent c2)))))

(test nested-tree-back-links-hold-at-depth
  ;; A small realistic slice of the tree: application > drawing > cad-view >
  ;; entity > grip. Every parent link is correct.
  (let* ((app (make-instance 'ui-application :key "app"))
         (dwg (make-instance 'ui-drawing :key "plan.dwg"))
         (view (make-instance 'ui-cad-view :key "vue-cad"))
         (ent (make-instance 'ui-entity :key "2A" :entity-type "LINE"))
         (grip (make-instance 'ui-grip :key "1")))
    (add-child app dwg)
    (add-child dwg view)
    (add-child view ent)
    (add-child ent grip)
    (is (eq app (ui-parent dwg)))
    (is (eq dwg (ui-parent view)))
    (is (eq view (ui-parent ent)))
    (is (eq ent (ui-parent grip)))
    (is (equal (list grip) (ui-children ent)))))
