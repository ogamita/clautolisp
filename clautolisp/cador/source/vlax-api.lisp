(in-package #:clautolisp.cador)

;;;; Visual LISP COM-bridge HAL methods on MockHost (Phase 13).
;;;;
;;;; Implements: host-vlax-create-object, host-vlax-get-object,
;;;; host-vlax-release-object, host-vlax-get-property,
;;;; host-vlax-put-property, host-vlax-invoke-method,
;;;; host-vlax-property-available-p, host-vlax-method-applicable-p.
;;;;
;;;; The AutoLISP-visible VLA-OBJECT (autolisp-runtime:autolisp-vla-object)
;;;; wraps the host-allocated COM-object id; the host stores the
;;;; mock-com-object struct in cador-com-objects keyed on that
;;;; same id.

(defun ensure-progid-string (progid operator-name)
  (cond
    ((typep progid 'clautolisp.autolisp-runtime:autolisp-string)
     (clautolisp.autolisp-runtime:autolisp-string-value progid))
    ((stringp progid) progid)
    (t
     (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
      :invalid-progid
      "~A expects a ProgID string, got ~S."
      operator-name progid))))

(defun ensure-vla-object (object operator-name)
  (unless (typep object 'clautolisp.autolisp-runtime:autolisp-vla-object)
    (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
     :invalid-vla-object
     "~A expects a VLA-OBJECT, got ~S."
     operator-name object))
  object)

(defun ensure-property-name-string (name operator-name)
  (cond
    ((typep name 'clautolisp.autolisp-runtime:autolisp-string)
     (clautolisp.autolisp-runtime:autolisp-string-value name))
    ((stringp name) name)
    ((typep name 'clautolisp.autolisp-runtime:autolisp-symbol)
     (clautolisp.autolisp-runtime:autolisp-symbol-name name))
    (t
     (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
      :invalid-com-property-name
      "~A expects a property name, got ~S."
      operator-name name))))

(defun com-object->vla (mock-com-object)
  (clautolisp.autolisp-runtime:make-autolisp-vla-object
   :value (mock-com-object-id mock-com-object)))

(defun resolve-vla-object (host vla operator-name)
  "Return the live mock-com-object referenced by VLA, signalling
:released-vla-object if the underlying COM object has been
released and :unknown-vla-object if it never existed."
  (ensure-vla-object vla operator-name)
  (let* ((id (clautolisp.autolisp-runtime:autolisp-vla-object-value vla))
         (object (cador-find-com-object host id)))
    (cond
      ((null object)
       (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
        :unknown-vla-object
        "~A: VLA-OBJECT ~A is not known to the active host."
        operator-name id))
      ((mock-com-object-released-p object)
       (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
        :released-vla-object
        "~A: VLA-OBJECT ~A has been released."
        operator-name id))
      (t object))))

;;; --- Live drawing-backed collections ------------------------------
;;;
;;; The document's object-valued collections (Blocks, Layers,
;;; ModelSpace, PaperSpace) are backed by the drawing database rather
;;; than a static member list: their members and Count are recomputed
;;; on each access, so entmake / DXF loads / Add / Delete are always
;;; reflected. Each live object is identity-stable — repeated
;;; vla-get-blocks or Item calls hand back the same VLA object, as
;;; vendor ActiveX does. (vla-accessor-family.issue, P2 remainder.)

(defun %al-string (string)
  "Wrap STRING as the AutoLISP string value COM properties hand back,
so user code can strcat / strcase / = the result."
  (clautolisp.autolisp-runtime:make-autolisp-string string))

(defun %com-string (value)
  "Coerce a COM property value or method argument to a CL string, or
NIL when VALUE is not string-like."
  (cond
    ((typep value 'clautolisp.autolisp-runtime:autolisp-string)
     (clautolisp.autolisp-runtime:autolisp-string-value value))
    ((stringp value) value)
    (t nil)))

(defun %layout-block-name-p (name)
  (or (string-equal name "*Model_Space")
      (string-equal name "*Paper_Space")))

(defun %live-com-object (host key constructor)
  "Return the identity-stable live COM object registered under KEY,
building it with CONSTRUCTOR (a thunk yielding a mock-com-object) and
registering it on first reference."
  (let* ((ids (cador-live-collection-ids host))
         (id (gethash key ids))
         (cached (and id (cador-find-com-object host id))))
    (if (and cached (not (mock-com-object-released-p cached)))
        cached
        (let ((object (%register-mock-com-object host (funcall constructor))))
          (setf (gethash key ids) (mock-com-object-id object))
          object))))

(defun %block-object (host name)
  "The identity-stable AutoCAD.Block COM object for block NAME —
itself a live collection of the entities the block owns."
  (%live-com-object
   host (concatenate 'string "BLOCK:" (string-upcase name))
   (lambda ()
     (let* ((object (make-mock-com-object
                     :progid "AutoCAD.Block"
                     :collection-p t
                     :collection-kind (cons :block-entities name)))
            (props (mock-com-object-properties object)))
       (setf (gethash "Name" props)       (%al-string name)
             (gethash "ObjectName" props) (%al-string "AcDbBlockTableRecord")
             (gethash "IsLayout" props)   (%layout-block-name-p name)
             (gethash "IsXRef" props)     nil
             (gethash "IsDynamicBlock" props) nil
             (gethash "Explodable" props) t)
       object))))

(defun %layer-object (host name)
  "The identity-stable AutoCAD.Layer COM object for layer NAME."
  (%live-com-object
   host (concatenate 'string "LAYER:" (string-upcase name))
   (lambda ()
     (let* ((object (make-mock-com-object :progid "AutoCAD.Layer"))
            (props (mock-com-object-properties object)))
       (setf (gethash "Name" props)       (%al-string name)
             (gethash "ObjectName" props) (%al-string "AcDbLayerTableRecord"))
       object))))

(defun %blocks-collection (host)
  "The document's live Blocks collection object."
  (%live-com-object
   host "BLOCKS"
   (lambda () (make-mock-com-object :progid "AutoCAD.Blocks"
                                    :collection-p t
                                    :collection-kind :blocks))))

(defun %layers-collection (host)
  "The document's live Layers collection object."
  (%live-com-object
   host "LAYERS"
   (lambda () (make-mock-com-object :progid "AutoCAD.Layers"
                                    :collection-p t
                                    :collection-kind :layers))))

(defun %block-names (host)
  "Ordered names of the document's block definitions: *Model_Space and
*Paper_Space first (as vendor Blocks collections have them), then every
other :block-record table entry and DXF-loaded block definition, sorted
case-insensitively."
  (let ((names '()))
    (maphash (lambda (name record)
               (declare (ignore record))
               (pushnew name names :test #'string-equal))
             (cador-table host :block-record))
    (maphash (lambda (name header)
               (declare (ignore header))
               (pushnew name names :test #'string-equal))
             (drawing-blocks (cador-active-drawing host)))
    (append (list "*Model_Space" "*Paper_Space")
            (sort (remove-if #'%layout-block-name-p names)
                  #'string-lessp))))

(defun live-collection-members (host object)
  "The current member VLA-objects of collection OBJECT: computed from
the drawing for a live collection, the stored list for a static one."
  (let ((kind (mock-com-object-collection-kind object)))
    (cond
      ((eq kind :blocks)
       (mapcar (lambda (name) (com-object->vla (%block-object host name)))
               (%block-names host)))
      ((eq kind :layers)
       (let ((names '()))
         (maphash (lambda (name record)
                    (declare (ignore record))
                    (push name names))
                  (cador-table host :layer))
         (mapcar (lambda (name) (com-object->vla (%layer-object host name)))
                 (sort names #'string-lessp))))
      ((and (consp kind) (eq (car kind) :block-entities))
       (mapcar (lambda (handle)
                 (host-vlax-ename->vla-object host (handle->ename host handle)))
               (%block-entity-handles host (cdr kind))))
      (t (copy-list (mock-com-object-collection-members object))))))

(defun %collection-item (host object args operator-name)
  "Generic collection Item: ARGS is (INDEX-OR-NAME). An integer indexes
the member list 0-based (the ActiveX convention); a string matches the
members' Name property case-insensitively. A missing item signals
:com-item-not-found — the mock's analogue of the ActiveX exception,
catchable through vl-catch-all-apply."
  (let ((key (first args))
        (members (live-collection-members host object)))
    (cond
      ((integerp key)
       (if (and (<= 0 key) (< key (length members)))
           (nth key members)
           (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
            :com-item-not-found
            "~A: index ~D is out of range for collection ~A (Count = ~D)."
            operator-name key (mock-com-object-progid object) (length members))))
      ((%com-string key)
       (let ((name (%com-string key)))
         (or (find-if (lambda (member-vla)
                        (let* ((member (resolve-vla-object host member-vla
                                                           operator-name))
                               (member-name (%com-string
                                             (gethash "Name"
                                                      (mock-com-object-properties
                                                       member)))))
                          (and member-name (string-equal member-name name))))
                      members)
             (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
              :com-item-not-found
              "~A: no item named ~A in collection ~A."
              operator-name name (mock-com-object-progid object)))))
      (t
       (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
        :invalid-com-item-key
        "~A expects an integer index or a name string, got ~S."
        operator-name key)))))

(defun %require-com-string-argument (args operator-name)
  "The first string-like element of ARGS, or an :invalid-com-argument
error. Vendor Add signatures differ in argument order (Blocks.Add takes
Origin then Name, Layers.Add takes Name); picking the string argument
covers both."
  (or (some #'%com-string args)
      (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
       :invalid-com-argument
       "~A expects a name string argument, got ~S."
       operator-name args)))

(defun %blocks-add (host args)
  "Blocks.Add(Origin, Name): register a block-definition record and
return its (live, initially empty) AutoCAD.Block object."
  (let ((name (%require-com-string-argument args "Blocks.Add")))
    (unless (cador-find-table-record host :block-record name)
      (cador-add-table-record
       host (make-symbol-table-record
             :kind :block-record :name name
             :data (list (cons 0 "BLOCK") (cons 2 name) (cons 70 0)))))
    (com-object->vla (%block-object host name))))

(defun %layers-add (host args)
  "Layers.Add(Name): register a layer record and return its
AutoCAD.Layer object."
  (let ((name (%require-com-string-argument args "Layers.Add")))
    (unless (cador-find-table-record host :layer name)
      (cador-add-table-record
       host (make-symbol-table-record
             :kind :layer :name name
             :data (list (cons 0 "LAYER") (cons 2 name) (cons 70 0)
                         (cons 62 7) (cons 6 "Continuous")))))
    (com-object->vla (%layer-object host name))))

(defun %block-delete (host object)
  "Block.Delete: erase the block definition OBJECT wraps — its owned
entities, its table records, and the COM object itself. The layout
blocks *Model_Space / *Paper_Space cannot be deleted, as in vendor
ActiveX."
  (let ((name (cdr (mock-com-object-collection-kind object))))
    (when (%layout-block-name-p name)
      (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
       :com-cannot-delete-layout-block
       "Delete: block ~A is a layout block and cannot be deleted." name))
    (dolist (handle (%block-entity-handles host name))
      (let ((entity (cador-find-entity-by-handle host handle)))
        (when entity (setf (entity-handle-deleted-p entity) t))))
    (remhash name (cador-table host :block-record))
    (remhash name (drawing-blocks (cador-active-drawing host)))
    (remhash (concatenate 'string "BLOCK:" (string-upcase name))
             (cador-live-collection-ids host))
    (setf (mock-com-object-released-p object) t)
    nil))

;;; --- Entity methods: InsertBlock, GetAttributes, Move/Rotate/Copy… -
;;;
;;; The mutation surface the SCHMS corpus drives against block
;;; references and their attributes. Geometry is the entget-convention
;;; one: points are (x y z) doubles lists on the DXF groups, angles are
;;; radians.

(defun %wrap-com-objects (values)
  (let ((wrap clautolisp.autolisp-runtime:*com-objects-wrap-hook*))
    (if wrap (funcall wrap values) values)))

(defun %transform-block-point (p ip xs ys zs rot)
  "Transform definition-space point P by the block-reference placement:
scale by (XS YS ZS), rotate by ROT (radians, about +Z), translate to IP."
  (let* ((x (* (coerce (first p) 'double-float) xs))
         (y (* (coerce (second p) 'double-float) ys))
         (z (* (coerce (or (third p) 0.0d0) 'double-float) zs))
         (c (cos rot))
         (s (sin rot)))
    (list (+ (first ip) (- (* c x) (* s y)))
          (+ (second ip) (+ (* s x) (* c y)))
          (+ (or (third ip) 0.0d0) z))))

(defun %space-owner-name (collection-kind)
  "The entity owner name for entities created inside the block-entities
collection COLLECTION-KIND: NIL for *Model_Space (main space), the
block's name otherwise."
  (let ((name (cdr collection-kind)))
    (if (string-equal name "*Model_Space") nil name)))

(defun %parse-insert-block-args (args operator-name)
  "Destructure the vendor InsertBlock argument list (InsertionPoint,
Name, Xscale, Yscale, Zscale, Rotation) tolerantly: the first
point-like argument is the insertion point, the first string-like the
block name, the remaining numbers fill the scales and rotation in
order. Returns (values IP NAME XS YS ZS ROT)."
  (let ((point nil) (name nil) (numbers '()))
    (dolist (argument args)
      (let ((string (%com-string argument)))
        (cond
          ((and (null name) string) (setf name string))
          ((realp argument) (push argument numbers))
          ((and (null point) (%maybe-com-point argument))
           (setf point (%maybe-com-point argument))))))
    (unless name
      (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
       :invalid-com-argument
       "~A expects a block-name string argument, got ~S."
       operator-name args))
    (let ((numbers (nreverse numbers)))
      (values (or point '(0.0d0 0.0d0 0.0d0))
              name
              (coerce (or (first numbers) 1) 'double-float)
              (coerce (or (second numbers) 1) 'double-float)
              (coerce (or (third numbers) 1) 'double-float)
              (coerce (or (fourth numbers) 0) 'double-float)))))

(defun %attrib-from-attdef (attdef ip xs ys zs rot)
  "The ATTRIB group-code list instantiating ATTDEF at the
block-reference placement (IP XS YS ZS ROT)."
  (flet ((g (code) (%entity-group-value attdef code)))
    (let ((p10 (g 10)) (p11 (g 11)))
      (remove nil
              (list (cons 0 "ATTRIB")
                    (cons 8 (or (g 8) "0"))
                    (cons 10 (%transform-block-point (or p10 '(0.0d0 0.0d0 0.0d0))
                                                    ip xs ys zs rot))
                    (and p11
                         (cons 11 (%transform-block-point p11 ip xs ys zs rot)))
                    (cons 40 (* (coerce (or (g 40) 2.5d0) 'double-float) ys))
                    (cons 1 (or (g 1) ""))
                    (cons 2 (or (g 2) ""))
                    (cons 70 (or (g 70) 0))
                    (and (g 7) (cons 7 (g 7)))
                    (cons 50 (+ (coerce (or (g 50) 0.0d0) 'double-float) rot))
                    (and (g 72) (cons 72 (g 72)))
                    (and (g 74) (cons 74 (g 74))))))))

(defun %block-attdefs (host name)
  "The non-constant ATTDEF entities of block definition NAME, oldest
first (constant attributes — 70 bit 1 — are not instantiated, as in
the vendors)."
  (loop for handle in (%block-entity-handles host name)
        for entity = (cador-find-entity-by-handle host handle)
        when (and entity
                  (eq (entity-handle-kind entity) :attdef)
                  (not (logbitp 1 (or (%entity-group-value entity 70) 0))))
          collect entity))

(defun %insert-block (host collection-kind args)
  "InsertBlock(InsertionPoint, Name, Xscale, Yscale, Zscale, Rotation)
on a space / block collection: create the INSERT (with an ATTRIB per
non-constant ATTDEF of the definition, transformed to the placement,
and a closing SEQEND) owned by the collection's space, and return the
new block reference's VLA-object."
  (multiple-value-bind (ip name xs ys zs rot)
      (%parse-insert-block-args args "InsertBlock")
    (unless (or (cador-find-table-record host :block-record name)
                (find-block-definition-p host name))
      (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
       :unknown-block-definition
       "InsertBlock: no block definition named ~A." name))
    (let* ((owner (%space-owner-name collection-kind))
           (attdefs (%block-attdefs host name))
           (insert-data
             (append (list (cons 0 "INSERT") (cons 8 "0") (cons 2 name)
                           (cons 10 (copy-list ip))
                           (cons 41 xs) (cons 42 ys) (cons 43 zs)
                           (cons 50 rot))
                     (and attdefs (list (cons 66 1))))))
      (multiple-value-bind (entity ename)
          (%host-add-entity host insert-data 'insert-block owner)
        (unless entity
          (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
           :insert-block-failed
           "InsertBlock: could not create an INSERT for block ~A." name))
        (if attdefs
            (progn
              (dolist (attdef attdefs)
                (%host-add-entity host
                                  (%attrib-from-attdef attdef ip xs ys zs rot)
                                  'insert-block owner))
              (%host-add-entity host (list (cons 0 "SEQEND") (cons 8 "0"))
                                'insert-block owner))
            ;; No attribute run: the INSERT's complex run has nothing
            ;; to own — close it so later entmakes are unaffected.
            (setf (cador-open-complex-handle host) nil))
        (host-vlax-ename->vla-object host ename)))))

(defun find-block-definition-p (host name)
  (nth-value 1 (gethash name (drawing-blocks (cador-active-drawing host)))))

(defun %entity-attributes (host entity)
  "The ATTRIB VLA-objects of block reference ENTITY, oldest first."
  (loop for handle in (%entity-subentity-handles host entity)
        for sub = (cador-find-entity-by-handle host handle)
        when (and sub (eq (entity-handle-kind sub) :attrib))
          collect (host-vlax-ename->vla-object host (handle->ename host handle))))

(defun %entity-delete (host entity)
  "Erase ENTITY and its subentity run."
  (dolist (handle (%entity-subentity-handles host entity))
    (let ((sub (cador-find-entity-by-handle host handle)))
      (when sub (setf (entity-handle-deleted-p sub) t))))
  (setf (entity-handle-deleted-p entity) t)
  nil)

(defun %entity-move (host entity args)
  "Move(FromPoint, ToPoint): translate ENTITY and its subentities by
the displacement between the two points."
  (let* ((from (%unwrap-com-point (first args) "Move"))
         (to (%unwrap-com-point (second args) "Move"))
         (dx (- (first to) (first from)))
         (dy (- (second to) (second from)))
         (dz (- (or (third to) 0.0d0) (or (third from) 0.0d0))))
    (%entity-translate entity dx dy dz)
    (dolist (handle (%entity-subentity-handles host entity))
      (let ((sub (cador-find-entity-by-handle host handle)))
        (when sub (%entity-translate sub dx dy dz))))
    nil))

(defun %entity-rotate (host entity args)
  "Rotate(BasePoint, RotationAngle): rotate ENTITY (and its
subentities) about the base point, in radians about +Z."
  (let* ((base (%unwrap-com-point (first args) "Rotate"))
         (angle (let ((a (second args)))
                  (unless (realp a)
                    (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
                     :invalid-com-argument
                     "Rotate expects a rotation angle in radians, got ~S." a))
                  (coerce a 'double-float)))
         (bx (first base))
         (by (second base)))
    (%entity-rotate-one entity bx by angle)
    (dolist (handle (%entity-subentity-handles host entity))
      (let ((sub (cador-find-entity-by-handle host handle)))
        (when sub (%entity-rotate-one sub bx by angle))))
    nil))

(defun %entity-copy (host entity)
  "Copy(): duplicate ENTITY (and its subentity run) in place; return
the new VLA-object."
  (let ((new (%clone-entity-with-run host entity)))
    (host-vlax-ename->vla-object host (handle->ename host
                                                     (entity-handle-id new)))))

(defun %entity-bounding-box (host entity)
  "A conservative ((minx miny minz) (maxx maxy maxz)) box over ENTITY's
own point groups, its subentities', and — for an INSERT — the
definition's transformed points. Text-bearing kinds extend max-y by the
text height. SPEC-UNCERTAIN: vendor boxes account for glyph metrics;
the mock approximates from the stored groups (deferred-spec-research)."
  (let ((points '()))
    (labels ((entity-points (e)
               ;; EVERY point-group occurrence — a LWPOLYLINE has one
               ;; 10 group per vertex.
               (loop for pair in (entity-handle-data e)
                     when (and (consp pair)
                               (member (car pair) '(10 11 12 13)
                                       :test #'group-code-equal-p)
                               (consp (cdr pair)))
                       collect (cdr pair)))
             (collect-entity (e)
               (dolist (p (entity-points e)) (push p points))
               ;; Text-bearing kinds: extend the box by the text height
               ;; in the direction the VERTICAL JUSTIFICATION dictates —
               ;; a top-anchored (_TL/_TC/_TR) text grows DOWNWARD from
               ;; its anchor, a baseline/bottom one upward, a middle one
               ;; both ways. Getting this wrong flips topological
               ;; above/below readings of justified labels (the SCHMS
               ;; côté BAS bug, 1.8.20).
               (let ((kind (entity-handle-kind e)))
                 (when (member kind '(:text :mtext :attrib :attdef))
                   (let* ((anchor (or (and (not (eq kind :mtext))
                                           (%entity-group-value e 11))
                                      (%entity-group-value e 10)))
                          (h (%entity-group-value e 40))
                          (v (cond
                               ;; MTEXT's default attachment is top-left.
                               ((eq kind :mtext) 3)
                               ((eq kind :text)
                                (or (%entity-group-value e 73) 0))
                               (t (or (%entity-group-value e 74) 0)))))
                     (when (and (consp anchor) (realp h))
                       (let ((x (first anchor))
                             (y (second anchor))
                             (z (or (third anchor) 0.0d0)))
                         (case v
                           (3 (push (list x (- y h) z) points))
                           (2 (push (list x (- y (/ h 2)) z) points)
                              (push (list x (+ y (/ h 2)) z) points))
                           (t (push (list x (+ y h) z) points))))))))))
      (collect-entity entity)
      (dolist (handle (%entity-subentity-handles host entity))
        (let ((sub (cador-find-entity-by-handle host handle)))
          (when sub (collect-entity sub))))
      (when (eq (entity-handle-kind entity) :insert)
        (let ((name (%entity-group-value entity 2))
              (ip (or (%entity-group-value entity 10) '(0.0d0 0.0d0 0.0d0)))
              (xs (or (%entity-group-value entity 41) 1.0d0))
              (ys (or (%entity-group-value entity 42) 1.0d0))
              (zs (or (%entity-group-value entity 43) 1.0d0))
              (rot (or (%entity-group-value entity 50) 0.0d0)))
          (when name
            (dolist (handle (%block-entity-handles host name))
              (let ((member (cador-find-entity-by-handle host handle)))
                (when member
                  (dolist (p (entity-points member))
                    (push (%transform-block-point
                           p ip
                           (coerce xs 'double-float)
                           (coerce ys 'double-float)
                           (coerce zs 'double-float)
                           (coerce rot 'double-float))
                          points)))))))))
    (if (null points)
        nil
        (list (list (reduce #'min points :key #'first)
                    (reduce #'min points :key #'second)
                    (reduce #'min points :key (lambda (p)
                                                (or (third p) 0.0d0))))
              (list (reduce #'max points :key #'first)
                    (reduce #'max points :key #'second)
                    (reduce #'max points :key (lambda (p)
                                                (or (third p) 0.0d0))))))))

(defun %entity-fallback-method (host object name args)
  "The entity-backed method surface. Returns (values RESULT T) when
handled, (values NIL NIL) otherwise."
  (let ((entity (%resolve-backing-entity host object)))
    (if (null entity)
        (values nil nil)
        (cond
          ((and (string-equal name "GetAttributes")
                (eq (entity-handle-kind entity) :insert))
           (values (%wrap-com-objects (%entity-attributes host entity)) t))
          ((or (string-equal name "Delete") (string-equal name "Erase"))
           (values (%entity-delete host entity) t))
          ((string-equal name "Update")
           (values nil t))
          ((string-equal name "Move")
           (values (%entity-move host entity args) t))
          ((string-equal name "Rotate")
           (values (%entity-rotate host entity args) t))
          ((string-equal name "Copy")
           (values (%entity-copy host entity) t))
          ((string-equal name "GetBoundingBox")
           ;; Returns the plain (min max) box; the builtins layer
           ;; assigns the caller's two output symbols (the vendor
           ;; by-reference contract) and wraps the points.
           (values (%entity-bounding-box host entity) t))
          (t (values nil nil))))))

(defun %entity-fallback-method-p (host object name)
  (let ((entity (%resolve-backing-entity host object)))
    (and entity
         (or (and (string-equal name "GetAttributes")
                  (eq (entity-handle-kind entity) :insert))
             (member name '("Delete" "Erase" "Update" "Move" "Rotate"
                            "Copy" "GetBoundingBox")
                     :test #'string-equal))
         t)))

(defun %collection-fallback-method (host object name args)
  "Handle the generic collection methods (Item, Add, Delete) that live
collections support without a per-object handler. Returns (values
RESULT T) when NAME was handled, (values NIL NIL) otherwise."
  (let ((kind (mock-com-object-collection-kind object)))
    (cond
      ((and (mock-com-object-collection-p object) (string-equal name "Item"))
       (values (%collection-item host object args "Item") t))
      ((and (eq kind :blocks) (string-equal name "Add"))
       (values (%blocks-add host args) t))
      ((and (eq kind :layers) (string-equal name "Add"))
       (values (%layers-add host args) t))
      ((and (consp kind) (eq (car kind) :block-entities)
            (string-equal name "InsertBlock"))
       (values (%insert-block host kind args) t))
      ((and (consp kind) (eq (car kind) :block-entities)
            (string-equal name "Delete"))
       (values (%block-delete host object) t))
      (t (%entity-fallback-method host object name args)))))

(defun %collection-fallback-method-p (host object name)
  "Whether %COLLECTION-FALLBACK-METHOD would handle NAME on OBJECT."
  (let ((kind (mock-com-object-collection-kind object)))
    (or (and (mock-com-object-collection-p object) (string-equal name "Item"))
        (and (member kind '(:blocks :layers)) (string-equal name "Add") t)
        (and (consp kind) (eq (car kind) :block-entities)
             (or (string-equal name "Delete")
                 (string-equal name "InsertBlock"))
             t)
        (%entity-fallback-method-p host object name))))

;;; --- Entity-backed COM properties (DXF-group bridge) --------------
;;;
;;; An entity's ActiveX properties read and write its DXF groups: the
;;; entity behind a vlax-ename->vla-object wrapper carries no property
;;; hash — instead vlax-get/put-property dispatch on the declarative
;;; table below (vla-entity-property-bridge.issue). Angular values
;;; follow the entget convention (radians), which is also the ActiveX
;;; convention, so Rotation maps to group 50 without conversion.
;;; Point-valued properties cross the layer boundary through the
;;; runtime's *com-point-wrap-hook* / *com-point-unwrap-hook* (owned by
;;; the builtins layer, which has the safearray representation): with
;;; the hooks installed they are VARIANT-wrapped double SAFEARRAYs, as
;;; the vendor surface hands back; without (bare host unit tests) they
;;; pass as plain lists.

(defparameter *entity-com-object-names*
  '((:line . "AcDbLine") (:point . "AcDbPoint") (:circle . "AcDbCircle")
    (:arc . "AcDbArc") (:ellipse . "AcDbEllipse") (:ray . "AcDbRay")
    (:xline . "AcDbXline") (:lwpolyline . "AcDbPolyline")
    (:polyline . "AcDb2dPolyline") (:vertex . "AcDb2dVertex")
    (:seqend . "AcDbSequenceEnd") (:spline . "AcDbSpline")
    (:text . "AcDbText") (:mtext . "AcDbMText")
    (:attdef . "AcDbAttributeDefinition") (:attrib . "AcDbAttribute")
    (:insert . "AcDbBlockReference") (:3dface . "AcDbFace")
    (:solid . "AcDbSolid") (:trace . "AcDbTrace")
    (:xrecord . "AcDbXrecord") (:dictionary . "AcDbDictionary"))
  "Entity kind -> the ActiveX ObjectName class string.")

(defparameter *entity-com-properties*
  ;; (NAME . plist) — :group DXF-GROUP, :type :string|:real|:integer|:point,
  ;; :kinds (KEYWORD…) restricting applicability (absent = every kind),
  ;; :default value when the group is absent, :read-only t.
  '(("Handle"             :group 5   :type :string  :read-only t)
    ("Layer"              :group 8   :type :string  :default "0")
    ("Linetype"           :group 6   :type :string  :default "BYLAYER")
    ("Color"              :group 62  :type :integer :default 256)
    ("Lineweight"         :group 370 :type :integer :default -1)
    ("Thickness"          :group 39  :type :real    :default 0.0d0)
    ("TextString"         :group 1   :type :string  :default ""
                          :kinds (:text :mtext :attrib :attdef))
    ("TagString"          :group 2   :type :string  :default ""
                          :kinds (:attrib :attdef))
    ("PromptString"       :group 3   :type :string  :default ""
                          :kinds (:attdef))
    ("StyleName"          :group 7   :type :string  :default "Standard"
                          :kinds (:text :mtext :attrib :attdef))
    ("Height"             :group 40  :type :real    :default 0.0d0
                          :kinds (:text :mtext :attrib :attdef))
    ("Rotation"           :group 50  :type :real    :default 0.0d0
                          :kinds (:text :attrib :attdef :insert))
    ("Mode"               :group 70  :type :integer :default 0
                          :kinds (:attrib :attdef))
    ("Elevation"          :group 38  :type :real    :default 0.0d0
                          :kinds (:lwpolyline))
    ("Name"               :group 2   :type :string  :default ""
                          :kinds (:insert))
    ("EffectiveName"      :group 2   :type :string  :read-only t
                          :kinds (:insert))
    ("XScaleFactor"       :group 41  :type :real    :default 1.0d0
                          :kinds (:insert))
    ("YScaleFactor"       :group 42  :type :real    :default 1.0d0
                          :kinds (:insert))
    ("ZScaleFactor"       :group 43  :type :real    :default 1.0d0
                          :kinds (:insert))
    ("InsertionPoint"     :group 10  :type :point
                          :kinds (:text :mtext :attrib :attdef :insert :point))
    ("TextAlignmentPoint" :group 11  :type :point
                          :kinds (:text :attrib :attdef)))
  "Scalar / point entity COM properties bridged onto DXF groups.
EffectiveName = Name headless — the mock has no dynamic blocks
(SPEC-UNCERTAIN; vla-entity-property-bridge.issue). ObjectName and
Alignment are computed outside this table.")

(defun %resolve-backing-entity (host object)
  "The live ENTITY-HANDLE behind an entity-backed COM object, or NIL."
  (let ((handle (mock-com-object-backing-ename object)))
    (and handle (safe-find-entity (cador-active-drawing host) handle))))

(defun %entity-property-descriptor (entity name)
  "The *entity-com-properties* plist applicable to ENTITY for property
NAME, or NIL."
  (let ((entry (assoc name *entity-com-properties* :test #'string-equal)))
    (and entry
         (let ((kinds (getf (cdr entry) :kinds)))
           (or (null kinds)
               (member (entity-handle-kind entity) kinds)))
         (cdr entry))))


(defun %wrap-com-point (doubles)
  (let ((wrap clautolisp.autolisp-runtime:*com-point-wrap-hook*))
    (if wrap (funcall wrap doubles) doubles)))

(defun %maybe-com-point (value)
  "The list of CL doubles inside VALUE — a VARIANT / SAFEARRAY (via the
unwrap hook) or a plain number list — or NIL when VALUE is neither."
  (let* ((unwrap clautolisp.autolisp-runtime:*com-point-unwrap-hook*)
         (doubles (or (and unwrap (funcall unwrap value))
                      (and (consp value)
                           (every #'realp value)
                           value))))
    (and doubles
         (mapcar (lambda (x) (coerce x 'double-float)) doubles))))

(defun %unwrap-com-point (value operator-name)
  "Coerce VALUE — a VARIANT / SAFEARRAY (via the unwrap hook) or a
plain number list — to a list of CL doubles."
  (or (%maybe-com-point value)
      (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
       :invalid-com-point
       "~A expects a point (a VARIANT/SAFEARRAY of doubles or a number list), got ~S."
       operator-name value)))

(defun %alignment-vertical-code (kind)
  "The DXF vertical-justification group for KIND: 73 on TEXT, 74 on
ATTRIB / ATTDEF."
  (if (eq kind :text) 73 74))

(defun %entity-alignment (entity)
  "The acAlignment enum value from the 72 + 73/74 groups."
  (let* ((kind (entity-handle-kind entity))
         (h (min (or (%entity-group-value entity 72) 0) 5))
         (v (or (%entity-group-value entity (%alignment-vertical-code kind)) 0)))
    (case v
      (3 (+ 6 (min h 2)))                 ; top row
      (2 (+ 9 (min h 2)))                 ; middle row
      (1 (+ 12 (min h 2)))                ; bottom row
      (t h))))                            ; baseline: 0..5 direct

(defun (setf %entity-alignment) (value entity)
  (multiple-value-bind (h v)
      (cond
        ((and (integerp value) (<= 0 value 5))  (values value 0))
        ((and (integerp value) (<= 6 value 8))  (values (- value 6) 3))
        ((and (integerp value) (<= 9 value 11)) (values (- value 9) 2))
        ((and (integerp value) (<= 12 value 14)) (values (- value 12) 1))
        (t (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
            :invalid-com-alignment
            "Alignment expects an acAlignment value 0-14, got ~S." value)))
    (%entity-set-group entity 72 h)
    (%entity-set-group entity
                       (%alignment-vertical-code (entity-handle-kind entity))
                       v)
    value))

(defun %alignment-property-p (entity name)
  (and (string-equal name "Alignment")
       (member (entity-handle-kind entity) '(:text :attrib :attdef))))

(defun %hasattributes-property-p (entity name)
  (and (string-equal name "HasAttributes")
       (eq (entity-handle-kind entity) :insert)))

(defun %entity-com-property-get (host object name)
  "Read entity-backed COM property NAME. Returns (values VALUE T) when
bridged, (values NIL NIL) otherwise."
  (let ((entity (%resolve-backing-entity host object)))
    (cond
      ((null entity) (values nil nil))
      ((string-equal name "ObjectName")
       (let ((kind (entity-handle-kind entity)))
         (values (%al-string
                  (or (cdr (assoc kind *entity-com-object-names*))
                      (concatenate 'string "AcDb"
                                   (string-capitalize (symbol-name kind)))))
                 t)))
      ((%alignment-property-p entity name)
       (values (%entity-alignment entity) t))
      ((%hasattributes-property-p entity name)
       (values (eql 1 (%entity-group-value entity 66)) t))
      (t
       (let ((descriptor (%entity-property-descriptor entity name)))
         (if (null descriptor)
             (values nil nil)
             (let* ((raw (%entity-group-value entity
                                              (getf descriptor :group)))
                    (value (if (null raw) (getf descriptor :default) raw)))
               (values
                (ecase (getf descriptor :type)
                  (:string (%al-string (if (stringp value) value
                                           (princ-to-string value))))
                  (:real (if (realp value) (coerce value 'double-float) value))
                  (:integer value)
                  (:point (%wrap-com-point
                           (mapcar (lambda (x) (coerce x 'double-float))
                                   (or value '(0.0d0 0.0d0 0.0d0))))))
                t))))))))

(defun %entity-com-property-put (host object name value)
  "Write entity-backed COM property NAME. Returns (values VALUE T) when
bridged, (values NIL NIL) when unknown; a read-only property signals
:com-read-only-property."
  (let ((entity (%resolve-backing-entity host object)))
    (cond
      ((null entity) (values nil nil))
      ((or (string-equal name "ObjectName")
           (%hasattributes-property-p entity name)
           (and (%entity-property-descriptor entity name)
                (getf (%entity-property-descriptor entity name) :read-only)))
       (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
        :com-read-only-property
        "VLA-OBJECT property ~A is read-only." name))
      ((%alignment-property-p entity name)
       (values (setf (%entity-alignment entity) value) t))
      (t
       (let ((descriptor (%entity-property-descriptor entity name)))
         (if (null descriptor)
             (values nil nil)
             (let ((group (getf descriptor :group)))
               (ecase (getf descriptor :type)
                 (:string
                  (let ((string (%com-string value)))
                    (unless string
                      (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
                       :invalid-com-property-value
                       "Property ~A expects a string, got ~S." name value))
                    (%entity-set-group entity group string)))
                 (:real
                  (unless (realp value)
                    (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
                     :invalid-com-property-value
                     "Property ~A expects a number, got ~S." name value))
                  (%entity-set-group entity group (coerce value 'double-float)))
                 (:integer
                  (unless (integerp value)
                    (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
                     :invalid-com-property-value
                     "Property ~A expects an integer, got ~S." name value))
                  (%entity-set-group entity group value))
                 (:point
                  (%entity-set-group entity group
                                     (%unwrap-com-point value name))))
               (values value t))))))))

(defun %entity-com-property-known-p (host object name)
  (let ((entity (%resolve-backing-entity host object)))
    (and entity
         (or (string-equal name "ObjectName")
             (%alignment-property-p entity name)
             (%hasattributes-property-p entity name)
             (%entity-property-descriptor entity name))
         t)))

;;; --- Method definitions ------------------------------------------

(defmethod host-vlax-create-object ((host cador) progid)
  (let ((id-string (ensure-progid-string progid 'vlax-create-object)))
    (let ((object (build-mock-com-object host id-string)))
      (cond
        ((null object)
         (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
          :unknown-progid
          "MockHost has no COM template registered for ProgID ~A."
          id-string))
        (t
         (setf (gethash (mock-com-object-id object)
                        (cador-com-objects host))
               object)
         (com-object->vla object))))))

(defmethod host-vlax-get-object ((host cador) progid)
  ;; "Get" rather than "create": find the most recently-created
  ;; non-released instance of this ProgID, or nil.
  (let ((id-string (ensure-progid-string progid 'vlax-get-object))
        (best nil))
    (maphash (lambda (id object)
               (declare (ignore id))
               (when (and (not (mock-com-object-released-p object))
                          (string-equal (mock-com-object-progid object) id-string))
                 (setf best object)))
             (cador-com-objects host))
    (and best (com-object->vla best))))

(defmethod host-vlax-release-object ((host cador) vla)
  (let ((object (resolve-vla-object host vla 'vlax-release-object)))
    (setf (mock-com-object-released-p object) t)
    nil))

(defmethod host-vlax-get-property ((host cador) vla name)
  (let* ((object (resolve-vla-object host vla 'vlax-get-property))
         (string (ensure-property-name-string name 'vlax-get-property)))
    (multiple-value-bind (value present-p)
        (gethash string (mock-com-object-properties object))
      (cond
        (present-p value)
        ;; Collections answer Count from their (live) member list.
        ((and (mock-com-object-collection-p object)
              (string-equal string "Count"))
         (length (live-collection-members host object)))
        (t
         ;; Entity-backed objects read their properties off the
         ;; entity's DXF groups.
         (multiple-value-bind (result handled-p)
             (%entity-com-property-get host object string)
           (if handled-p
               result
               (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
                :unknown-com-property
                "VLA-OBJECT ~A has no property named ~A."
                (mock-com-object-progid object) string))))))))

(defmethod host-vlax-put-property ((host cador) vla name value)
  (let* ((object (resolve-vla-object host vla 'vlax-put-property))
         (string (ensure-property-name-string name 'vlax-put-property)))
    (if (nth-value 1 (gethash string (mock-com-object-properties object)))
        (setf (gethash string (mock-com-object-properties object)) value)
        ;; Entity-backed objects write their properties into the
        ;; entity's DXF groups.
        (multiple-value-bind (result handled-p)
            (%entity-com-property-put host object string value)
          (declare (ignore result))
          (unless handled-p
            (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
             :unknown-com-property
             "VLA-OBJECT ~A has no property named ~A."
             (mock-com-object-progid object) string))))
    value))

(defmethod host-vlax-invoke-method ((host cador) vla name args)
  (let* ((object (resolve-vla-object host vla 'vlax-invoke-method))
         (string (ensure-property-name-string name 'vlax-invoke-method))
         (handler (gethash string (mock-com-object-methods object))))
    (if handler
        (funcall handler host object args)
        (multiple-value-bind (result handled-p)
            (%collection-fallback-method host object string args)
          (if handled-p
              result
              (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
               :unknown-com-method
               "VLA-OBJECT ~A has no method named ~A."
               (mock-com-object-progid object) string))))))

(defmethod host-vlax-property-available-p ((host cador) vla name)
  (let* ((object (resolve-vla-object host vla 'vlax-property-available-p))
         (string (ensure-property-name-string name 'vlax-property-available-p)))
    (or (and (nth-value 1 (gethash string (mock-com-object-properties object))) t)
        (and (mock-com-object-collection-p object)
             (string-equal string "Count"))
        (%entity-com-property-known-p host object string))))

(defmethod host-vlax-method-applicable-p ((host cador) vla name)
  (let* ((object (resolve-vla-object host vla 'vlax-method-applicable-p))
         (string (ensure-property-name-string name 'vlax-method-applicable-p)))
    (or (and (gethash string (mock-com-object-methods object)) t)
        (%collection-fallback-method-p host object string))))

(defun %register-mock-com-object (host object)
  "Store OBJECT in HOST's com-objects table (build-mock-com-object
allocates but does not register). Returns OBJECT."
  (setf (gethash (mock-com-object-id object) (cador-com-objects host))
        object))

(defmethod host-vlax-get-acad-object ((host cador))
  "Return the singleton AutoCAD.Application VLA-OBJECT, creating it — and
its ActiveDocument — on first call. Object-valued properties are stored
as VLA-OBJECT references so vla-get-activedocument yields a usable
document. Repeated calls return the same application object."
  (let* ((cached-id (cador-acad-application-id host))
         (cached (and cached-id (cador-find-com-object host cached-id))))
    (if (and cached (not (mock-com-object-released-p cached)))
        (com-object->vla cached)
        (let ((app (%register-mock-com-object
                    host (build-mock-com-object host "AutoCAD.Application")))
              (doc (%register-mock-com-object
                    host (build-mock-com-object host "AutoCAD.Document"))))
          ;; Wire the object graph: Application.ActiveDocument -> the
          ;; document, and Document.Application -> back to the app.
          (setf (gethash "ActiveDocument" (mock-com-object-properties app))
                (com-object->vla doc))
          (setf (gethash "Application" (mock-com-object-properties doc))
                (com-object->vla app))
          ;; Drawing-backed collections: Blocks / Layers, and the
          ;; ModelSpace / PaperSpace layout blocks (replacing the
          ;; template's placeholder strings), so vla-get-blocks /
          ;; vla-item / vlax-for resolve against the live drawing.
          (let ((props (mock-com-object-properties doc)))
            (setf (gethash "Blocks" props)
                  (com-object->vla (%blocks-collection host))
                  (gethash "Layers" props)
                  (com-object->vla (%layers-collection host))
                  (gethash "ModelSpace" props)
                  (com-object->vla (%block-object host "*Model_Space"))
                  (gethash "PaperSpace" props)
                  (com-object->vla (%block-object host "*Paper_Space"))))
          ;; A Documents collection holding the one open document, so
          ;; vlax-for / vlax-map-collection have something to iterate.
          (let ((docs (%register-mock-com-object
                       host (make-mock-com-object
                             :progid "AutoCAD.Documents"
                             :collection-p t
                             :collection-members (list (com-object->vla doc))))))
            (setf (gethash "Documents" (mock-com-object-properties app))
                  (com-object->vla docs)))
          (setf (cador-acad-application-id host) (mock-com-object-id app))
          (com-object->vla app)))))

(defmethod host-vlax-collection-items ((host cador) vla)
  "Return the collection's member VLA-objects as a CL list; signal
:not-a-collection if VLA is not a collection object."
  (let ((obj (resolve-vla-object host vla 'vlax-collection-items)))
    (if (mock-com-object-collection-p obj)
        (live-collection-members host obj)
        (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
         :not-a-collection
         "vlax-for / vlax-map-collection: ~A is not an ActiveX collection."
         (mock-com-object-progid obj)))))

;;; --- Entity <-> VLA-object bridge + introspection ----------------

(defmethod host-vlax-ename->vla-object ((host cador) ename)
  "Wrap entity ENAME in an identity-stable COM object (progid
\"AutoCAD.Entity\") carrying its hex handle, so vlax-vla-object->ename
round-trips and vlax-curve-* can recover the entity."
  (let* ((handle (ename->handle ename 'vlax-ename->vla-object))
         (cached-id (gethash handle (cador-entity-vla-map host)))
         (cached (and cached-id (cador-find-com-object host cached-id))))
    (if (and cached (not (mock-com-object-released-p cached)))
        (com-object->vla cached)
        (let ((obj (%register-mock-com-object
                    host (make-mock-com-object :progid "AutoCAD.Entity"
                                               :backing-ename handle))))
          (setf (gethash handle (cador-entity-vla-map host))
                (mock-com-object-id obj))
          (com-object->vla obj)))))

(defmethod host-vlax-vla-object->ename ((host cador) vla)
  (let* ((obj (resolve-vla-object host vla 'vlax-vla-object->ename))
         (handle (mock-com-object-backing-ename obj)))
    (if handle
        (handle->ename host handle)
        (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
         :not-an-entity-vla-object
         "vlax-vla-object->ename: ~A is not an entity-backed VLA-OBJECT."
         (mock-com-object-progid obj)))))

(defmethod host-vlax-erased-p ((host cador) vla)
  ;; Do NOT go through resolve-vla-object: a released object must report
  ;; erased = T, not signal :released-vla-object.
  (ensure-vla-object vla 'vlax-erased-p)
  (let* ((id (clautolisp.autolisp-runtime:autolisp-vla-object-value vla))
         (obj (cador-find-com-object host id)))
    (cond
      ((null obj) t)                    ; unknown -> gone
      ((mock-com-object-backing-ename obj)
       (null (safe-find-entity (cador-active-drawing host)
                               (mock-com-object-backing-ename obj))))
      (t (mock-com-object-released-p obj)))))

(defmethod host-vlax-describe-object ((host cador) vla)
  (let ((obj (resolve-vla-object host vla 'vlax-describe-object))
        (props '())
        (methods '()))
    (maphash (lambda (k v) (push (cons k v) props))
             (mock-com-object-properties obj))
    (maphash (lambda (k v) (declare (ignore v)) (push k methods))
             (mock-com-object-methods obj))
    (values (nreverse props) (nreverse methods))))

;;; --- LDATA (persistent extension-dictionary LISP data) -----------

(defun %ldata-namespace (host dictionary private operator-name)
  "Namespace string identifying a (dictionary, public/private) ldata
keyspace. DICTIONARY is a VLA-object or a global-dictionary name string."
  (let ((dict-id
          (cond
            ((typep dictionary 'clautolisp.autolisp-runtime:autolisp-vla-object)
             (let ((obj (resolve-vla-object host dictionary operator-name)))
               (or (mock-com-object-backing-ename obj)
                   (princ-to-string (mock-com-object-id obj)))))
            ((typep dictionary 'clautolisp.autolisp-runtime:autolisp-string)
             (clautolisp.autolisp-runtime:autolisp-string-value dictionary))
            ((stringp dictionary) dictionary)
            (t (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
                :invalid-ldata-dictionary
                "~A: dictionary must be a VLA-object or a string, got ~S."
                operator-name dictionary)))))
    (format nil "~A|~:[pub~;prv~]" dict-id private)))

(defun %ldata-key (key operator-name)
  (cond
    ((typep key 'clautolisp.autolisp-runtime:autolisp-string)
     (clautolisp.autolisp-runtime:autolisp-string-value key))
    ((stringp key) key)
    (t (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
        :invalid-ldata-key
        "~A: key must be a string, got ~S." operator-name key))))

(defmethod host-vlax-ldata-put ((host cador) dictionary key value private)
  (let* ((ns (%ldata-namespace host dictionary private 'vlax-ldata-put))
         (k (%ldata-key key 'vlax-ldata-put))
         (store (cador-ldata-store host))
         (alist (gethash ns store))
         (cell (assoc k alist :test #'string=)))
    (if cell
        (setf (cdr cell) value)
        (setf (gethash ns store) (append alist (list (cons k value)))))
    value))

(defmethod host-vlax-ldata-get ((host cador) dictionary key default private)
  (let* ((ns (%ldata-namespace host dictionary private 'vlax-ldata-get))
         (k (%ldata-key key 'vlax-ldata-get))
         (cell (assoc k (gethash ns (cador-ldata-store host)) :test #'string=)))
    (if cell (cdr cell) default)))

(defmethod host-vlax-ldata-delete ((host cador) dictionary key private)
  (let* ((ns (%ldata-namespace host dictionary private 'vlax-ldata-delete))
         (k (%ldata-key key 'vlax-ldata-delete))
         (store (cador-ldata-store host))
         (alist (gethash ns store)))
    (when (assoc k alist :test #'string=)
      (setf (gethash ns store) (remove k alist :key #'car :test #'string=))
      t)))

(defmethod host-vlax-ldata-list ((host cador) dictionary private)
  (let ((ns (%ldata-namespace host dictionary private 'vlax-ldata-list)))
    (mapcar (lambda (pair) (cons (car pair) (cdr pair)))
            (gethash ns (cador-ldata-store host)))))

;;; --- Command registration + async expression queue --------------

(defmethod host-vlax-add-cmd ((host cador) global-name function local-name flags)
  (declare (ignore flags))
  (push (list :cmd global-name (or local-name global-name) function)
        (cador-registered-commands host))
  global-name)

(defmethod host-vlax-remove-cmd ((host cador) global-name)
  (let* ((cmds (cador-registered-commands host))
         (kept (if (eq global-name t)
                   (remove :cmd cmds :key #'car)
                   (remove-if (lambda (e)
                                (and (eq (car e) :cmd)
                                     (string-equal (second e) global-name)))
                              cmds))))
    (setf (cador-registered-commands host) kept)
    (and (< (length kept) (length cmds)) t)))

(defmethod host-vlax-queueexpr ((host cador) string)
  (push (list :queue string) (cador-registered-commands host))
  nil)
