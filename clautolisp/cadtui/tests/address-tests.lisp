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
  (reset-dump-registry)               ; no last dump => a bare key is not-found
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

;;;; Phase 2 slice 3: D<n>.cle and bare-key-in-last-dump addressing.

(test resolve-d-reference-survives-later-dumps
  (reset-dump-registry)
  (let* ((app (%make-addressing-tree))
         (view (resolve-target app "/application/drawings[1]/cad-view")))
    ;; D1 dumps the entity subtree (records entity + grip keys)...
    (register-dump view :path "/application/drawings[1]/cad-view")
    ;; ...then an unrelated D2 dump happens.
    (register-dump app :path "/application")
    ;; D1.2A still resolves to the entity; D1.2A.grip2 to its 2nd grip.
    (let ((ent (resolve-target app "D1.2A")))
      (is (eq :entity (ui-role ent)))
      (is (string= "2A" (ui-key ent))))
    (let ((grip (resolve-target app "D1.2A.grip2")))
      (is (eq :grip (ui-role grip)))
      (is (string= "2" (ui-key grip))))))

(test resolve-bare-key-in-last-dump
  (reset-dump-registry)
  (let* ((app (%make-addressing-tree))
         (view (resolve-target app "/application/drawings[1]/cad-view")))
    (register-dump view :path "/application/drawings[1]/cad-view")
    ;; "2A" alone resolves in the last dump.
    (let ((ent (resolve-target app "2A")))
      (is (eq :entity (ui-role ent)))
      (is (string= "2A" (ui-key ent))))))

(test resolve-d-reference-errors
  (reset-dump-registry)
  (let ((app (%make-addressing-tree)))
    ;; unknown dump number
    (is (eq :nf (handler-case (resolve-target app "D9.2A")
                  (target-not-found () :nf))))
    ;; a bare key with no dump recorded
    (is (eq :nf (handler-case (resolve-target app "2A")
                  (target-not-found () :nf))))
    ;; register a dump whose entries have two grips keyed "1"/"2" -> a bare key
    ;; that appears twice would be ambiguous; here the cad-view dump has one 2A.
    (register-dump (resolve-target app "/application/drawings[1]/cad-view"))
    (let ((grip1 (resolve-target app "1")))
      (is (eq :grip (ui-role grip1))))))

;;;; Phase 5 slice 4: general dotted-relative addressing.

(test resolve-root-relative-dotted-chain
  (let* ((app (%make-addressing-tree))
         (view (resolve-target app "/application/drawings[1]/cad-view")))
    ;; drawings[1].cad-view is the same node as the absolute path.
    (is (eq view (resolve-target app "drawings[1].cad-view")))
    ;; and a longer chain down to a grip, via role[i] segments (a chain uses no
    ;; ':' so a dotted key like a filename is never split; role:cle addressing
    ;; stays a single segment or an absolute /path).
    (let ((grip (resolve-target app "drawings[1].cad-view.entities[1].grips[2]")))
      (is (eq :grip (ui-role grip)))
      (is (string= "2" (ui-key grip))))
    ;; active-drawing as the first part works too.
    (is (eq view (resolve-target app "active-drawing.cad-view")))))

(test resolve-last-dump-dotted-chain-vs-dotted-key
  (reset-dump-registry)
  (let* ((app (%make-addressing-tree))
         (view (resolve-target app "/application/drawings[1]/cad-view")))
    (register-dump view :path "/application/drawings[1]/cad-view")
    ;; "2A.2" is a dotted chain in the last dump: entity 2A, then its grip 2.
    (let ((grip (resolve-target app "2A.2")))
      (is (eq :grip (ui-role grip)))
      (is (string= "2" (ui-key grip))))))

(test resolve-dotted-key-filename-not-split
  (reset-dump-registry)
  (let* ((app (%make-addressing-tree))
         (d1 (resolve-target app "/application/drawings[1]")))
    ;; a dump of /application records the drawing keyed "plan.dwg".
    (register-dump app :path "/application")
    ;; the dotted KEY resolves whole, not split into plan . dwg.
    (is (eq d1 (resolve-target app "plan.dwg")))))
