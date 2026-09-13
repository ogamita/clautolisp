(in-package #:clautolisp.cadtui.tests)

(in-suite cadtui-suite)

;;;; Phase 1 slice 3: find-node and absolute-path target resolution.
;;;; Canonical address tokens are English (a Phase-7 locale layer maps localised
;;;; surface forms, e.g. the fr_FR "dessins"/"dessin-actif" of spec §5.2).

(defun %make-addressing-tree ()
  "A small tree exercising the address forms: /application with menu-bar,
console, and two drawings; drawing 1 has a cad-view with an entity carrying two
grips, plus its own console."
  (let ((app (make-application-tree))          ; app + menu-bar + console
        (d1 (make-instance 'ui-drawing :key "plan.dwg"))
        (d2 (make-instance 'ui-drawing :key "coupe.dwg")))
    (add-child app d1)
    (add-child app d2)
    (let ((view (make-instance 'ui-cad-view :key "cad-view"))
          (ent (make-instance 'ui-entity :key "2A" :entity-type "LINE")))
      (add-child d1 view)
      (add-child view ent)
      (add-child ent (make-instance 'ui-grip :key "1"))
      (add-child ent (make-instance 'ui-grip :key "2"))
      (add-child d1 (make-instance 'ui-console :key "console")))
    app))

(test find-node-depth-first
  (let* ((app (%make-addressing-tree))
         (ent (find-node app (lambda (n) (and (eq :entity (ui-role n))
                                              (string= "2A" (ui-key n)))))))
    (is (eq :entity (ui-role ent)))
    (is (string= "2A" (ui-key ent)))
    (is (null (find-node app (lambda (n) (string= "absent" (ui-key n))))))))

(test resolve-root-and-bare-segments
  (let ((app (%make-addressing-tree)))
    (is (eq app (resolve-target app "/application")))
    (is (eq (ui-find-child app "console") (resolve-target app "/application/console")))
    (is (eq (ui-find-child app "menu-bar")
            (resolve-target app "/application/menu-bar")))))

(test resolve-indexed-and-active-drawing
  (let* ((app (%make-addressing-tree))
         (d1 (ui-find-child app "plan.dwg"))
         (d2 (ui-find-child app "coupe.dwg")))
    (is (eq d1 (resolve-target app "/application/drawings[1]")))
    (is (eq d2 (resolve-target app "/application/drawings[2]")))
    (is (eq d1 (resolve-target app "/application/active-drawing")))))  ; = drawings[1]

(test resolve-role-key-deep-path
  (let* ((app (%make-addressing-tree))
         (ent (resolve-target app "/application/drawings[1]/cad-view/entity:2A")))
    (is (eq :entity (ui-role ent)))
    (is (string= "2A" (ui-key ent)))
    (let ((grip (resolve-target app
                                "/application/drawings[1]/cad-view/entity:2A/grip:2")))
      (is (eq :grip (ui-role grip)))
      (is (string= "2" (ui-key grip))))
    ;; a drawing-local console, distinct from the application console.
    (is (eq (ui-find-child (ui-find-child app "plan.dwg") "console")
            (resolve-target app "/application/drawings[1]/console")))))

(test resolve-not-found
  (let ((app (%make-addressing-tree)))
    ;; unknown bare segment
    (is (eq :nf (handler-case (resolve-target app "/application/nope")
                  (target-not-found () :nf))))
    ;; index out of range
    (is (eq :nf (handler-case (resolve-target app "/application/drawings[9]")
                  (target-not-found () :nf))))
    ;; role:cle miss
    (is (eq :nf (handler-case
                    (resolve-target app "/application/drawings[1]/cad-view/entity:ZZ")
                  (target-not-found () :nf))))
    ;; a relative / bare path is deferred to Phase 2 -> not found here
    (is (eq :nf (handler-case (resolve-target app "plan.dwg")
                  (target-not-found () :nf))))))

(test resolve-ambiguous-lists-candidates
  ;; The bare role name "drawing" matches both drawings -> ambiguous, and the
  ;; condition carries the candidates.
  (let* ((app (%make-addressing-tree))
         (candidates nil)
         (outcome (handler-case (resolve-target app "/application/drawing")
                    (ambiguous-target (c)
                      (setf candidates (ambiguous-target-candidates c))
                      :ambiguous))))
    (is (eq :ambiguous outcome))
    (is (= 2 (length candidates)))
    (is (equal '("plan.dwg" "coupe.dwg") (mapcar #'ui-key candidates)))))
