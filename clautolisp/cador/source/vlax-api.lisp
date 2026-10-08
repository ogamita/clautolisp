(in-package #:clautolisp.cador)

;;;; Visual LISP COM-bridge HAL methods on cador (Phase 13).
;;;;
;;;; Implements: host-vlax-create-object, host-vlax-get-object,
;;;; host-vlax-release-object, host-vlax-get-property,
;;;; host-vlax-put-property, host-vlax-invoke-method,
;;;; host-vlax-property-available-p, host-vlax-method-applicable-p.
;;;;
;;;; The AutoLISP-visible VLA-OBJECT (autolisp-runtime:autolisp-vla-object)
;;;; wraps the host-allocated COM-object id; the host stores the
;;;; cador-com-object struct in cador-com-objects keyed on that
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

(defun com-object->vla (cador-com-object)
  (clautolisp.autolisp-runtime:make-autolisp-vla-object
   :value (cador-com-object-id cador-com-object)))

(defun resolve-vla-object (host vla operator-name)
  "Return the live cador-com-object referenced by VLA, signalling
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
      ((cador-com-object-released-p object)
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
building it with CONSTRUCTOR (a thunk yielding a cador-com-object) and
registering it on first reference."
  (let* ((ids (cador-live-collection-ids host))
         (id (gethash key ids))
         (cached (and id (cador-find-com-object host id))))
    (if (and cached (not (cador-com-object-released-p cached)))
        cached
        (let ((object (%register-cador-com-object host (funcall constructor))))
          (setf (gethash key ids) (cador-com-object-id object))
          object))))

(defun %block-object (host name)
  "The identity-stable AutoCAD.Block COM object for block NAME —
itself a live collection of the entities the block owns."
  (%live-com-object
   host (concatenate 'string "BLOCK:" (string-upcase name))
   (lambda ()
     (let* ((object (make-cador-com-object
                     :progid "AutoCAD.Block"
                     :collection-p t
                     :collection-kind (cons :block-entities name)))
            (props (cador-com-object-properties object)))
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
     (let* ((object (make-cador-com-object :progid "AutoCAD.Layer"))
            (props (cador-com-object-properties object)))
       (setf (gethash "Name" props)       (%al-string name)
             (gethash "ObjectName" props) (%al-string "AcDbLayerTableRecord"))
       object))))

(defun %blocks-collection (host)
  "The document's live Blocks collection object."
  (%live-com-object
   host "BLOCKS"
   (lambda () (make-cador-com-object :progid "AutoCAD.Blocks"
                                    :collection-p t
                                    :collection-kind :blocks))))

(defun %vlax-boolean (generalized-boolean)
  "The ActiveX boolean symbol :VLAX-TRUE or :VLAX-FALSE."
  (clautolisp.autolisp-runtime:intern-autolisp-symbol
   (if generalized-boolean ":VLAX-TRUE" ":VLAX-FALSE")))

(defun %layout-name (block-name)
  "The layout a layout block belongs to: *Model_Space is \"Model\",
*Paper_Space the first paper layout, \"Layout1\" (a fresh drawing's)."
  (if (string-equal block-name "*Model_Space") "Model" "Layout1"))

(defun %layout-object (host block-name)
  "The identity-stable AutoCAD.Layout COM object of layout block BLOCK-NAME."
  (%live-com-object
   host (concatenate 'string "LAYOUT:" (string-upcase block-name))
   (lambda ()
     (let* ((object (make-cador-com-object :progid "AutoCAD.Layout"))
            (props (cador-com-object-properties object))
            (model-p (string-equal block-name "*Model_Space")))
       (setf (gethash "Name" props)       (%al-string (%layout-name block-name))
             (gethash "ObjectName" props) (%al-string "AcDbLayout")
             (gethash "ModelType" props)  (%vlax-boolean model-p)
             (gethash "TabOrder" props)   (if model-p 0 1)
             (gethash "Block" props)      (com-object->vla (%block-object host block-name)))
       object))))

(defmethod clautolisp.autolisp-host:host-layout-names ((host cador))
  "The paper layouts of the drawing, in tab order: one per paper-space
layout block (*Paper_Space is a fresh drawing's \"Layout1\")."
  (mapcar #'%layout-name
          (remove "*Model_Space"
                  (remove-if-not #'%layout-block-name-p (%block-names host))
                  :test #'string-equal)))

(defun %layouts-collection (host)
  "Document.Layouts: a live collection of the drawing's layouts."
  (%live-com-object host "LAYOUTS"
   (lambda () (make-cador-com-object :progid "AutoCAD.Layouts"
                                    :collection-p t :collection-kind :layouts))))

(defun %preferences-object (host)
  "Application.Preferences, with its Files and Profiles objects."
  (%live-com-object host "PREFERENCES"
   (lambda ()
     (let ((object (make-cador-com-object :progid "AutoCAD.Preferences")))
       (setf (gethash "Files" (cador-com-object-properties object))
             (com-object->vla
              (%live-com-object host "PREFERENCES-FILES"
               (lambda () (make-cador-com-object :progid "AutoCAD.PreferencesFiles"))))
             (gethash "Profiles" (cador-com-object-properties object))
             (com-object->vla
              (%live-com-object host "PREFERENCES-PROFILES"
               (lambda () (make-cador-com-object :progid "AutoCAD.PreferencesProfiles")))))
       object))))

(defun %layers-collection (host)
  "The document's live Layers collection object."
  (%live-com-object
   host "LAYERS"
   (lambda () (make-cador-com-object :progid "AutoCAD.Layers"
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
  (let ((kind (cador-com-object-collection-kind object)))
    (cond
      ((eq kind :blocks)
       (mapcar (lambda (name) (com-object->vla (%block-object host name)))
               (%block-names host)))
      ((eq kind :documents)
       (mapcar (lambda (key) (com-object->vla (%document-object host key)))
               (host-document-list host)))
      ;; Paper layouts first, then Model: the order vlax-for walks them in
      ;; on BricsCAD (V26 macOS, V25 Windows).
      ((eq kind :layouts)
       (mapcar (lambda (name) (com-object->vla (%layout-object host name)))
               (append (remove "*Model_Space"
                               (remove-if-not #'%layout-block-name-p (%block-names host))
                               :test #'string-equal)
                       (list "*Model_Space"))))
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
      (t (copy-list (cador-com-object-collection-members object))))))

(defun %collection-item (host object args operator-name)
  "Generic collection Item: ARGS is (INDEX-OR-NAME). An integer indexes
the member list 0-based (the ActiveX convention); a string matches the
members' Name property case-insensitively. A missing item signals
:com-item-not-found — cador's analogue of the ActiveX exception,
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
            operator-name key (cador-com-object-progid object) (length members))))
      ((%com-string key)
       (let ((name (%com-string key)))
         (or (find-if (lambda (member-vla)
                        (let* ((member (resolve-vla-object host member-vla
                                                           operator-name))
                               (member-name (%com-string
                                             (gethash "Name"
                                                      (cador-com-object-properties
                                                       member)))))
                          (and member-name (string-equal member-name name))))
                      members)
             (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
              :com-item-not-found
              "~A: no item named ~A in collection ~A."
              operator-name name (cador-com-object-progid object)))))
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
  (let ((name (cdr (cador-com-object-collection-kind object))))
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
    (setf (cador-com-object-released-p object) t)
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
cador approximates from the stored groups (deferred-spec-research)."
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
             (text-box (e kind)
               ;; TEXT / ATTRIB / ATTDEF: the MEASURED ink box (TEXT-INK-BOX,
               ;; as TEXTBOX gives it) placed at the insertion point -- the
               ;; alignment point 11 when justified -- shifted by the
               ;; justification, turned by the rotation 50. BricsCAD's
               ;; GetBoundingBox equals TEXTBOX for text at the origin
               ;; (probe-block-walk.lsp, 2026-10-03). This replaced a box
               ;; with NO width: only the height was ever added.
               (let* ((string (let ((s (%entity-group-value e 1)))
                                (cond ((stringp s) s)
                                      ((typep s 'clautolisp.autolisp-runtime:autolisp-string)
                                       (clautolisp.autolisp-runtime:autolisp-string-value s))
                                      (t ""))))
                      (h (let ((v (%entity-group-value e 40))) (if (realp v) v 1.0d0)))
                      (wf (let ((v (%entity-group-value e 41))) (if (realp v) v 1.0d0)))
                      (rot (let ((v (%entity-group-value e 50))) (if (realp v) v 0.0d0)))
                      (hj (or (%entity-group-value e 72) 0))
                      (vj (or (%entity-group-value e (if (eq kind :text) 73 74)) 0))
                      (justified (or (and (integerp hj) (/= hj 0))
                                     (and (integerp vj) (/= vj 0))))
                      (anchor (or (and justified (%entity-group-value e 11))
                                  (%entity-group-value e 10)
                                  '(0.0d0 0.0d0 0.0d0)))
                      (dialect (ignore-errors
                                (clautolisp.autolisp-runtime:current-evaluation-dialect)))
                      (bricscad (and dialect
                                     (eq :bricscad
                                         (clautolisp.autolisp-reader:autolisp-dialect-product
                                          dialect)))))
                 (multiple-value-bind (x0 y0 x1 y1 advance)
                     (clautolisp.autolisp-runtime:text-ink-box
                      string h :width-factor wf :bricscad bricscad)
                   (let* ((dx (case hj ((1 4) (- (/ advance 2))) (2 (- advance)) (t 0d0)))
                          (dy (cond ((eql hj 4) (- (/ h 2)))
                                    (t (case vj (3 (- h)) (2 (- (/ h 2))) (1 (- y0)) (t 0d0)))))
                          (c (cos rot)) (s (sin rot))
                          (ax (first anchor)) (ay (second anchor))
                          (az (or (third anchor) 0.0d0)))
                     (dolist (corner (list (list x0 y0) (list x1 y0) (list x0 y1) (list x1 y1)))
                       (let ((lx (+ (first corner) dx)) (ly (+ (second corner) dy)))
                         (push (list (+ ax (- (* lx c) (* ly s)))
                                     (+ ay (+ (* lx s) (* ly c)))
                                     az)
                               points)))))))
             (collect-entity (e)
               (if (member (entity-handle-kind e) '(:text :attrib :attdef))
                   (text-box e (entity-handle-kind e))
                   (dolist (p (entity-points e)) (push p points)))
               ;; MTEXT (TEXT / ATTRIB / ATTDEF have their measured box
               ;; above): extend the box by the text height in the
               ;; direction the VERTICAL JUSTIFICATION dictates -- a
               ;; top-anchored text grows DOWNWARD from its anchor, a
               ;; baseline/bottom one upward, a middle one both ways.
               ;; Getting this wrong flips topological above/below readings
               ;; of justified labels (the SCHMS côté BAS bug, 1.8.20).
               (let ((kind (entity-handle-kind e)))
                 (when (member kind '(:mtext))
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
          ((and (string-equal name "GetBulge")
                (eq (entity-handle-kind entity) :lwpolyline))
           (values (%lwpolyline-bulge entity (first args)) t))
          ((and (string-equal name "SetBulge")
                (eq (entity-handle-kind entity) :lwpolyline))
           (values (%lwpolyline-set-bulge entity (first args) (second args)) t))
          ((string-equal name "IntersectWith")
           (values (%entity-intersect-with host entity args) t))
          (t (values nil nil))))))

(defun %lwpolyline-vertex-tail (entity index operator-name)
  "The data tail starting at the INDEX-th 10 group of an LWPOLYLINE."
  (let ((tail (and (integerp index) (>= index 0)
                   (let ((i -1))
                     (loop for tail on (entity-handle-data entity)
                           when (and (consp (car tail)) (eql (caar tail) 10))
                             do (incf i)
                                (when (= i index) (return tail)))))))
    (or tail
        (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
         :invalid-com-argument
         "~A: no vertex ~S on this polyline." operator-name index))))

(defun %lwpolyline-bulge (entity index)
  "Polyline.GetBulge(Index): the 42 group following vertex INDEX, 0.0 when absent."
  (let ((tail (%lwpolyline-vertex-tail entity index "GetBulge")))
    (loop for pair in (rest tail)
          until (and (consp pair) (eql (car pair) 10))
          when (and (consp pair) (eql (car pair) 42))
            do (return (coerce (cdr pair) 'double-float))
          finally (return 0.0d0))))

(defun %lwpolyline-set-bulge (entity index bulge)
  "Polyline.SetBulge(Index, Bulge): set (or insert) the 42 group of vertex INDEX."
  (unless (realp bulge)
    (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
     :invalid-com-argument "SetBulge expects a number, got ~S." bulge))
  (let* ((tail (%lwpolyline-vertex-tail entity index "SetBulge"))
         (cell (loop for pair in (rest tail)
                     until (and (consp pair) (eql (car pair) 10))
                     when (and (consp pair) (eql (car pair) 42)) do (return pair))))
    (if cell
        (setf (cdr cell) (coerce bulge 'double-float))
        (setf (cdr tail) (cons (cons 42 (coerce bulge 'double-float)) (cdr tail))))
    nil))

(defun %entity-intersect-with (host entity args)
  "IntersectWith(IntersectObject, ExtendOption): the points where ENTITY
meets the other entity, as the VARIANT-wrapped double SAFEARRAY the vendor
returns (X1 Y1 Z1 X2 ...) -- an EMPTY one when they do not meet
(intersect.lisp; cador-intersectwith-missing)."
  (destructuring-bind (&optional other-vla (option 0) &rest more) args
    (when more
      (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
       :invalid-com-argument
       "IntersectWith expects (IntersectObject ExtendOption), got ~D arguments."
       (length args)))
    (let* ((object (resolve-vla-object host other-vla "IntersectWith"))
           (other (or (%resolve-backing-entity host object)
                      (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
                       :invalid-com-argument
                       "IntersectWith expects an entity, got ~A."
                       (cador-com-object-progid object))))
           (option (cond ((null option) 0)
                         ((and (integerp option) (<= 0 option 3)) option)
                         (t (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
                             :invalid-com-argument
                             "IntersectWith expects an acExtendOption 0-3, got ~S."
                             option)))))
      (%wrap-com-point (entity-intersect-with host entity other option)))))

(defun %entity-fallback-method-p (host object name)
  (let ((entity (%resolve-backing-entity host object)))
    (and entity
         (or (and (string-equal name "GetAttributes")
                  (eq (entity-handle-kind entity) :insert))
             (and (member name '("GetBulge" "SetBulge") :test #'string-equal)
                  (eq (entity-handle-kind entity) :lwpolyline))
             (member name '("Delete" "Erase" "Update" "Move" "Rotate"
                            "Copy" "GetBoundingBox" "IntersectWith")
                     :test #'string-equal))
         t)))

(defun %collection-fallback-method (host object name args)
  "Handle the generic collection methods (Item, Add, Delete) that live
collections support without a per-object handler. Returns (values
RESULT T) when NAME was handled, (values NIL NIL) otherwise."
  (let ((kind (cador-com-object-collection-kind object)))
    (cond
      ((and (cador-com-object-collection-p object) (string-equal name "Item"))
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
      ((and (consp kind) (eq (car kind) :block-entities)
            (string-equal name "AddLine"))
       (values (%model-add-line host kind args) t))
      ((and (consp kind) (eq (car kind) :block-entities)
            (string-equal name "AddAttribute"))
       (values (%block-add-attribute host kind args) t))
      ((and (consp kind) (eq (car kind) :block-entities)
            (string-equal name "AddArc"))
       (values (%model-add-arc host kind args) t))
      ((and (consp kind) (eq (car kind) :block-entities)
            (string-equal name "AddCircle"))
       (values (%model-add-circle host kind args) t))
      ((and (consp kind) (eq (car kind) :block-entities)
            (string-equal name "AddLightWeightPolyline"))
       (values (%model-add-lwpolyline host kind args) t))
      ((and (eq kind :documents) (string-equal name "Add"))
       (values (%documents-add host) t))
      ((and (eq kind :documents) (string-equal name "Open"))
       (values (%documents-open host args) t))
      ((and (eq kind :documents) (string-equal name "Close"))
       ;; Documents.Close: close them all (a session keeps one fresh drawing).
       (dolist (key (host-document-list host))
         (cador-close-document host key))
       (values nil t))
      ((and (eq kind :linetypes) (string-equal name "Load"))
       (values (%linetypes-load host args) t))
      ((and (%layer-object-p object) (string-equal name "Delete"))
       (values (%layer-delete host object) t))
      (t (%entity-fallback-method host object name args)))))

(defun %collection-fallback-method-p (host object name)
  "Whether %COLLECTION-FALLBACK-METHOD would handle NAME on OBJECT."
  (let ((kind (cador-com-object-collection-kind object)))
    (or (and (cador-com-object-collection-p object) (string-equal name "Item"))
        (and (member kind '(:blocks :layers)) (string-equal name "Add") t)
        (and (eq kind :documents)
             (member name '("Add" "Open" "Close") :test #'string-equal) t)
        (and (eq kind :linetypes) (string-equal name "Load") t)
        (and (consp kind) (eq (car kind) :block-entities)
             (member name '("Delete" "InsertBlock" "AddLine" "AddAttribute"
                            "AddArc" "AddCircle" "AddLightWeightPolyline")
                     :test #'string-equal)
             t)
        (and (%layer-object-p object) (string-equal name "Delete") t)
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
                          :kinds (:text :attrib :attdef))
    ;; curve geometry stored in groups (cador-curve-length-and-sampling);
    ;; angles are radians, as in entget and ActiveX.
    ("Center"             :group 10  :type :point   :kinds (:circle :arc))
    ("Radius"             :group 40  :type :real    :kinds (:circle :arc))
    ("StartAngle"         :group 50  :type :real    :kinds (:arc))
    ("EndAngle"           :group 51  :type :real    :kinds (:arc))
    ("StartPoint"         :group 10  :type :point   :kinds (:line))
    ("EndPoint"           :group 11  :type :point   :kinds (:line)))
  "Scalar / point entity COM properties bridged onto DXF groups.
EffectiveName = Name headless — the host has no dynamic blocks
(SPEC-UNCERTAIN; vla-entity-property-bridge.issue). ObjectName and
Alignment are computed outside this table.")

(defun %resolve-backing-entity (host object)
  "The live ENTITY-HANDLE behind an entity-backed COM object, or NIL."
  (let ((handle (cador-com-object-backing-ename object)))
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
      ((%curve-com-property-p entity name)
       (values (%curve-com-property-get host object entity name) t))
      ;; Visible: group 60, 0 (or absent) visible, 1 invisible.
      ((string-equal name "Visible")
       (values (not (eql 1 (%entity-group-value entity 60))) t))
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
      ((%curve-com-property-p entity name)
       (values (%curve-com-property-put entity name value) t))
      ((string-equal name "Visible")
       (%entity-set-group entity 60 (if value 0 1))
       (values value t))
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
             (string-equal name "Visible")
             (%alignment-property-p entity name)
             (%hasattributes-property-p entity name)
             (%curve-com-property-p entity name)
             (%entity-property-descriptor entity name))
         t)))

;;; --- Computed curve properties ------------------------------------------
;;;
;;; ArcLength, TotalAngle, Length, Area, Circumference, Diameter, the ARC's
;;; StartPoint / EndPoint, the LINE's Angle / Delta and the polylines'
;;; Closed are derived from the entity's geometry with the same analytic
;;; curve model as vlax-curve-* (autolisp-host curve-geometry), so the two
;;; surfaces cannot disagree (cador-curve-length-and-sampling.issue: before
;;; 2.3.8 none of them existed and vla-get-ArcLength signalled "no property
;;; named ARCLENGTH").

(defparameter *curve-com-properties*
  ;; (NAME KINDS WRITABLE-P)
  '(("ArcLength"     (:arc)                           nil)
    ("TotalAngle"    (:arc)                           nil)
    ("Length"        (:line :lwpolyline :polyline)    nil)
    ("Area"          (:circle :arc :lwpolyline :polyline) nil)
    ("Circumference" (:circle)                        t)
    ("Diameter"      (:circle)                        t)
    ("StartPoint"    (:arc)                           nil)
    ("EndPoint"      (:arc)                           nil)
    ("Angle"         (:line)                          nil)
    ("Delta"         (:line)                          nil)
    ("Closed"        (:lwpolyline :polyline)          t)
    ;; measured on AutoCAD and BricsCAD: (vlax-get pl 'Coordinates) of the
    ;; LWPOLYLINE (0,0) (10,0) (10,10) => (0 0 10 0 10 10)
    ("Coordinates"   (:lwpolyline)                    t))
  "Computed (geometry-derived) entity COM properties.")

(defun %curve-com-property-entry (entity name)
  (let ((entry (assoc name *curve-com-properties* :test #'string-equal)))
    (and entry (member (entity-handle-kind entity) (second entry)) entry)))

(defun %curve-com-property-p (entity name)
  (and (%curve-com-property-entry entity name) t))

(defun %entity-curve (host object)
  (clautolisp.autolisp-host:host-curve-descriptor
   host (handle->ename host (cador-com-object-backing-ename object))))

(defun %curve-com-property-get (host object entity name)
  (let ((curve (%entity-curve host object)))
    (flet ((is (n) (string-equal name n))
           (pt (p) (and p (%wrap-com-point
                           (mapcar (lambda (x) (coerce x 'double-float)) p)))))
      (cond
        ((or (is "ArcLength") (is "Length") (is "Circumference"))
         (and curve (clautolisp.autolisp-host:curve-length curve)))
        ((is "TotalAngle") (and curve (clautolisp.autolisp-host:curve-total-angle curve)))
        ((is "Area") (and curve (clautolisp.autolisp-host:curve-area curve)))
        ((is "Diameter") (* 2.0d0 (coerce (or (%entity-group-value entity 40) 0) 'double-float)))
        ((is "StartPoint") (pt (and curve (clautolisp.autolisp-host:curve-start-point curve))))
        ((is "EndPoint") (pt (and curve (clautolisp.autolisp-host:curve-end-point curve))))
        ((or (is "Angle") (is "Delta"))
         (let* ((a (%entity-group-value entity 10)) (b (%entity-group-value entity 11))
                (d (mapcar (lambda (u v) (coerce (- v u) 'double-float))
                           (subseq (append a (list 0 0 0)) 0 3)
                           (subseq (append b (list 0 0 0)) 0 3))))
           (if (is "Delta")
               (pt d)
               (let ((ang (atan (second d) (first d))))
                 (if (minusp ang) (+ ang (* 2 pi)) ang)))))
        ((is "Closed")
         (logbitp 0 (let ((f (%entity-group-value entity 70))) (if (integerp f) f 0))))
        ((is "Coordinates")
         (%wrap-com-point
          (loop for pair in (entity-handle-data entity)
                when (and (consp pair) (eql (car pair) 10))
                  append (list (coerce (first (cdr pair)) 'double-float)
                               (coerce (second (cdr pair)) 'double-float)))))))))

(defun %curve-com-property-put (entity name value)
  (let ((entry (%curve-com-property-entry entity name)))
    (unless (third entry)
      (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
       :com-read-only-property
       "VLA-OBJECT property ~A is read-only." name))
    (flet ((real-value ()
             (unless (realp value)
               (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
                :invalid-com-property-value
                "Property ~A expects a number, got ~S." name value))
             (coerce value 'double-float)))
      (cond
        ((string-equal name "Diameter") (%entity-set-group entity 40 (/ (real-value) 2)))
        ((string-equal name "Circumference")
         (%entity-set-group entity 40 (/ (real-value) (* 2 pi))))
        ((string-equal name "Coordinates")
         (let* ((xs (%unwrap-com-point value name))
                (cells (remove-if-not (lambda (pair) (and (consp pair) (eql (car pair) 10)))
                                      (entity-handle-data entity))))
           (unless (= (length xs) (* 2 (length cells)))
             (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
              :invalid-com-property-value
              "Coordinates expects ~D numbers (x y per vertex), got ~D."
              (* 2 (length cells)) (length xs)))
           (loop for cell in cells for (x y) on xs by #'cddr
                 do (setf (cdr cell) (list x y)))))
        ((string-equal name "Closed")
         (let ((f (%entity-group-value entity 70)))
           (%entity-set-group entity 70
                              (if value
                                  (logior (if (integerp f) f 0) 1)
                                  (logandc2 (if (integerp f) f 0) 1))))))
      value)))

;;; --- Layer / Linetype / Document object surface ------------------
;;; (cador-schme-a1-activex-coverage.issue). The AutoCAD.Layer and
;;; AutoCAD.Linetype table-record objects carry a Name in their property hash;
;;; their mutable attributes (Layer.Color, Layer.Linetype) read and write the
;;; live :layer table record's DXF groups, so getvar / tblsearch and ActiveX
;;; observe the same value. Document.ActiveLayer is dynamic (CLAYER), and
;;; Document.Linetypes is a live collection like Layers.

(defun %linetype-object (host name)
  "The identity-stable AutoCAD.Linetype COM object for linetype NAME."
  (%live-com-object
   host (concatenate 'string "LTYPE:" (string-upcase name))
   (lambda ()
     (let* ((object (make-cador-com-object :progid "AutoCAD.Linetype"))
            (props (cador-com-object-properties object)))
       (setf (gethash "Name" props)       (%al-string name)
             (gethash "ObjectName" props) (%al-string "AcDbLinetypeTableRecord"))
       object))))

(defun %linetypes-collection (host)
  "The document's live Linetypes collection object."
  (%live-com-object
   host "LINETYPES"
   (lambda () (make-cador-com-object :progid "AutoCAD.Linetypes"
                                    :collection-p t
                                    :collection-kind :linetypes))))

(defun %layer-record-group (host name code)
  "The value of DXF group CODE in layer NAME's :layer table record, or NIL."
  (let ((record (cador-find-table-record host :layer name)))
    (and record (cdr (assoc code (symbol-table-record-data record))))))

(defun %set-layer-record-group (host name code value)
  "Set DXF group CODE of layer NAME's :layer table record to VALUE, so
tblsearch \"LAYER\" and ActiveX read back the same value."
  (let ((record (cador-find-table-record host :layer name)))
    (when record
      (let* ((data (symbol-table-record-data record))
             (pair (assoc code data)))
        (if pair
            (setf (cdr pair) value)
            (setf (symbol-table-record-data record)
                  (append data (list (cons code value)))))))
    value))

(defun %layer-object-p (object)
  (string-equal (cador-com-object-progid object) "AutoCAD.Layer"))

(defun %table-object-name (object)
  (%com-string (gethash "Name" (cador-com-object-properties object))))

(defparameter *com-boolean-properties*
  '("Visible" "Saved" "ReadOnly" "IsLayout" "IsXRef" "IsDynamicBlock"
    "Explodable" "HasAttributes" "LayerOn" "Freeze" "Lock" "Plottable"
    "Active" "ModelType" "Closed")
  "ActiveX properties of type Boolean (VARIANT_BOOL): read as :VLAX-TRUE /
:VLAX-FALSE, written as those, T / nil, or -1 / 0 (probe-triage3, BricsCAD
V26 macOS job 16931597044 and V25 Windows job 16931597047).")

(defun %com-boolean-property-p (name)
  (member name *com-boolean-properties* :test #'string-equal))

(defun %com-symbol-named-p (value name)
  (and (typep value 'clautolisp.autolisp-runtime:autolisp-symbol)
       (string-equal (clautolisp.autolisp-runtime:autolisp-symbol-name value) name)))

(defun %com-boolean-out (value)
  "VALUE as the ActiveX boolean symbol: the CL generalized boolean of a
host property, or an already-converted :VLAX-TRUE / :VLAX-FALSE."
  (cond ((or (%com-symbol-named-p value ":VLAX-TRUE")
             (%com-symbol-named-p value ":VLAX-FALSE"))
         value)
        (t (%vlax-boolean value))))

(defun %com-boolean-in (value name)
  "The CL boolean a written VALUE means: :VLAX-TRUE, T or -1 true;
:VLAX-FALSE, nil or 0 false (both measured on BricsCAD V25 Windows). V26
macOS refuses the integers (E_INVALIDARG), so a macOS dialect does too.
Anything else is an invalid argument, as on the vendors."
  (flet ((invalid ()
           (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
            :invalid-com-property-value
            "Automation Error E_INVALIDARG; invalid argument for [~A] property: ~S."
            (string-upcase name) value)))
    (cond
      ((null value) nil)
      ((%com-symbol-named-p value ":VLAX-FALSE") nil)
      ((or (%com-symbol-named-p value ":VLAX-TRUE") (%com-symbol-named-p value "T")) t)
      ((and (integerp value) (member value '(0 -1)))
       (if (eq :macos (%current-dialect-platform))
           (invalid)
           (eql value -1)))
      (t (invalid)))))

(defun %layer-com-property-get (host object name)
  "Read a mutable AutoCAD.Layer property (Color, Linetype) off the layer's
:layer table record. Returns (values VALUE T) when handled."
  (if (%layer-object-p object)
      (let ((layer (%table-object-name object)))
        (cond
          ((string-equal name "Color")
           (values (or (%layer-record-group host layer 62) 7) t))
          ((string-equal name "Linetype")
           (values (%al-string (or (%layer-record-group host layer 6) "Continuous")) t))
          ;; On: a non-negative colour (a layer is turned off by negating 62).
          ((string-equal name "LayerOn")
           (values (>= (or (%layer-record-group host layer 62) 7) 0) t))
          ((string-equal name "Freeze")
           (values (logbitp 0 (or (%layer-record-group host layer 70) 0)) t))
          ((string-equal name "Lock")
           (values (logbitp 2 (or (%layer-record-group host layer 70) 0)) t))
          ((string-equal name "Plottable")
           (values (not (eql 0 (%layer-record-group host layer 290))) t))
          (t (values nil nil))))
      (values nil nil)))

(defun %layer-com-property-put (host object name value)
  "Write a mutable AutoCAD.Layer property (Color, Linetype, LayerOn, Freeze,
Lock, Plottable) into the layer's :layer table record. Returns (values VALUE
T) when handled."
  (if (%layer-object-p object)
      (let ((layer (%table-object-name object)))
        (cond
          ((string-equal name "LayerOn")
           (let ((color (abs (or (%layer-record-group host layer 62) 7))))
             (%set-layer-record-group host layer 62 (if value color (- color)))
             (values value t)))
          ((or (string-equal name "Freeze") (string-equal name "Lock"))
           (let ((flags (or (%layer-record-group host layer 70) 0))
                 (bit (if (string-equal name "Freeze") 1 4)))
             (%set-layer-record-group host layer 70
                                      (if value (logior flags bit) (logandc2 flags bit)))
             (values value t)))
          ((string-equal name "Plottable")
           (%set-layer-record-group host layer 290 (if value 1 0))
           (values value t))
          ((string-equal name "Color")
           (unless (integerp value)
             (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
              :invalid-com-property-value
              "Layer.Color expects an integer color index, got ~S." value))
           (%set-layer-record-group host layer 62 value)
           (values value t))
          ((string-equal name "Linetype")
           (let ((string (%com-string value)))
             (unless string
               (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
                :invalid-com-property-value
                "Layer.Linetype expects a string, got ~S." value))
             (%set-layer-record-group host layer 6 string)
             (values value t)))
          (t (values nil nil))))
      (values nil nil)))

(defun %document-object-p (object)
  (string-equal (cador-com-object-progid object) "AutoCAD.Document"))

(defun %active-document-p (host document)
  "True when DOCUMENT is the Application's ActiveDocument."
  (let* ((app-id (cador-acad-application-id host))
         (app (and app-id (cador-find-com-object host app-id)))
         (active (and app (gethash "ActiveDocument" (cador-com-object-properties app)))))
    (and (typep active 'clautolisp.autolisp-runtime:autolisp-vla-object)
         (eql (clautolisp.autolisp-runtime:autolisp-vla-object-value active)
              (cador-com-object-id document)))))

(defun %document-drawing (host object)
  (cdr (assoc (cador-com-object-document-key object) (cador-documents host) :test #'equal)))

(defun %application-com-property-get (host object name)
  "Application.ActiveDocument: the current document's object."
  (if (and (string-equal (cador-com-object-progid object) "AutoCAD.Application")
           (string-equal name "ActiveDocument"))
      (values (com-object->vla (%document-object host (cador-current-document-key host))) t)
      (values nil nil)))

(defun %application-com-property-put (host object name value)
  "Setting Application.ActiveDocument activates that document."
  (if (and (string-equal (cador-com-object-progid object) "AutoCAD.Application")
           (string-equal name "ActiveDocument"))
      (progn
        (clautolisp.autolisp-host:request-host-document-activation
         host (%document-key-of host value 'vlax-put-property))
        (values value t))
      (values nil nil)))

(defun %document-com-property-get (host object name)
  "Document.ActiveLayer is the AutoCAD.Layer for the current CLAYER (dynamic,
so it tracks setvar/ActiveLayer changes); Document.Active is :VLAX-TRUE for
the Application's ActiveDocument, :VLAX-FALSE for another. Returns (values
VALUE T) when handled."
  (cond
    ((not (%document-object-p object)) (values nil nil))
    ((string-equal name "ActiveLayer")
     (values (com-object->vla (%layer-object host (%current-layer-name host))) t))
    ((string-equal name "Active")
     (values (%vlax-boolean (equal (cador-com-object-document-key object)
                                   (cador-current-document-key host)))
             t))
    ((member name '("Name" "FullName" "Path" "Saved" "ReadOnly") :test #'string-equal)
     (let* ((drawing (%document-drawing host object))
            (path (and drawing (clautolisp.drawing:drawing-path drawing))))
       (values
        (cond
          ((string-equal name "Name") (%al-string (if drawing (clautolisp.drawing:drawing-name drawing) "")))
          ((string-equal name "FullName") (%al-string (if path (namestring path) "")))
          ((string-equal name "Path")
           (%al-string (if path (namestring (uiop:pathname-directory-pathname path)) "")))
          ((string-equal name "Saved")
           (and drawing (zerop (clautolisp.drawing:drawing-dbmod drawing))))
          (t (doc-session-read-only
              (cador-document-session host (cador-com-object-document-key object)))))
        t)))
    (t (values nil nil))))

(defun %preferences-com-property-get (host object name)
  "Preferences.Files.SupportPath is the support path findfile and load search
(and (getenv \"ACAD\")); Preferences.Profiles.ActiveProfile is the current
profile, CPROFILE. Returns (values VALUE T) when handled."
  (let ((progid (cador-com-object-progid object)))
    (cond
      ((and (string-equal progid "AutoCAD.PreferencesFiles")
            (string-equal name "SupportPath"))
       (values (%al-string (clautolisp.autolisp-runtime:autolisp-support-path-string)) t))
      ((and (string-equal progid "AutoCAD.PreferencesProfiles")
            (string-equal name "ActiveProfile"))
       (values (host-getvar host "CPROFILE") t))
      (t (values nil nil)))))

(defun %preferences-com-property-put (host object name value)
  "Setting Preferences.Files.SupportPath sets the support path."
  (declare (ignore host))
  (if (and (string-equal (cador-com-object-progid object) "AutoCAD.PreferencesFiles")
           (string-equal name "SupportPath"))
      (let ((string (%com-string value)))
        (unless string
          (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
           :invalid-com-property-value
           "SupportPath expects a string, got ~S." value))
        (clautolisp.autolisp-runtime:set-autolisp-support-path-string string)
        (values value t))
      (values nil nil)))

(defun %document-com-property-put (host object name value)
  "Setting Document.ActiveLayer makes VALUE's layer current (CLAYER)."
  (if (and (%document-object-p object) (string-equal name "ActiveLayer"))
      (let* ((layer (resolve-vla-object host value 'vlax-put-property))
             (layer-name (%table-object-name layer)))
        (when layer-name (cador-set-sysvar host "CLAYER" layer-name))
        (values value t))
      (values nil nil)))

;;; The object-property dispatch: entity-backed, then the Layer table record,
;;; then the Document's dynamic properties.

(defun %object-com-property-get (host object name)
  (multiple-value-bind (value0 handled0) (%application-com-property-get host object name)
    (if handled0
        (values value0 handled0)
        (%object-com-property-get-1 host object name))))

(defun %object-com-property-get-1 (host object name)
  (multiple-value-bind (value handled) (%entity-com-property-get host object name)
    (if handled
        (values value handled)
        (multiple-value-bind (value2 handled2) (%layer-com-property-get host object name)
          (if handled2
              (values value2 handled2)
              (multiple-value-bind (value3 handled3) (%document-com-property-get host object name)
                (if handled3
                    (values value3 handled3)
                    (%preferences-com-property-get host object name))))))))

(defun %object-com-property-put (host object name value)
  (multiple-value-bind (result0 handled0) (%application-com-property-put host object name value)
    (if handled0
        (values result0 handled0)
        (%object-com-property-put-1 host object name value))))

(defun %object-com-property-put-1 (host object name value)
  (multiple-value-bind (result handled) (%entity-com-property-put host object name value)
    (if handled
        (values result handled)
        (multiple-value-bind (result2 handled2) (%layer-com-property-put host object name value)
          (if handled2
              (values result2 handled2)
              (multiple-value-bind (result3 handled3)
                  (%document-com-property-put host object name value)
                (if handled3
                    (values result3 handled3)
                    (%preferences-com-property-put host object name value))))))))

(defun %object-com-property-known-p (host object name)
  (or (%entity-com-property-known-p host object name)
      (and (%layer-object-p object)
           (member name '("Color" "Linetype" "LayerOn" "Freeze" "Lock" "Plottable")
                   :test #'string-equal)
           t)
      (and (%document-object-p object)
           (member name '("ActiveLayer" "Active" "Name" "FullName" "Path" "Saved" "ReadOnly")
                   :test #'string-equal)
           t)
      (and (string-equal (cador-com-object-progid object) "AutoCAD.Application")
           (string-equal name "ActiveDocument"))
      (and (string-equal (cador-com-object-progid object) "AutoCAD.PreferencesFiles")
           (string-equal name "SupportPath"))
      (and (string-equal (cador-com-object-progid object) "AutoCAD.PreferencesProfiles")
           (string-equal name "ActiveProfile"))))

;;; --- Layer.Delete / Document lifecycle / AddLine / AddAttribute / Load ---

(defun %layer-delete (host object)
  "Layer.Delete: drop the layer's :layer table record. Layer 0 and the current
layer (CLAYER) cannot be deleted, as in vendor ActiveX. Returns nil."
  (let ((name (%table-object-name object)))
    (when (and name
               (not (string-equal name "0"))
               (not (string-equal name (%current-layer-name host))))
      (remhash name (cador-table host :layer))
      (setf (cador-com-object-released-p object) t))
    nil))

(defun %install-document-persistence (host doc)
  "Override DOC's SaveAs / Save method closures so they reach the live
drawing: SaveAs writes the drawing to its FullName argument (and records
the new Name, as the vendor object does), Save is a no-op that clears the
dirty flag. The bare template's SaveAs only renames — a live document must
actually persist. Returns DOC."
  (let ((methods (cador-com-object-methods doc)))
    (setf (gethash "SaveAs" methods)
          (lambda (host object args)
            (let ((path (%require-com-string-argument args "SaveAs")))
              ;; Last-resort format+version when neither the drawing nor the
              ;; path extension determines one: SAVEFORMAT (BricsCAD dialect)
              ;; or CLAUTOLISPDEFAULTDRAWINGFORMAT (default DXF).
              (handler-case
                  (cador-save-drawing host (cador-active-drawing host) path)
                (error (condition)
                  (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
                   :com-save-failed
                   "SaveAs could not write ~A: ~A." path condition)))
              nil))
          (gethash "Save" methods)
          (lambda (host object args)
            (declare (ignore args))
            (let ((drawing (cador-active-drawing host)))
              (when (doc-session-read-only (cador-document-session host))
                (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
                 :com-save-failed "Save: ~A is open read-only; use SaveAs."
                 (clautolisp.drawing:drawing-name drawing)))
              (when (clautolisp.drawing:drawing-path drawing)
                (cador-save-drawing host drawing (namestring (clautolisp.drawing:drawing-path drawing)))))
            (setf (cador-com-object-released-p object) (cador-com-object-released-p object))
            nil)))
  doc)

(defun %documents-add (host)
  "AutoCAD.Documents.Add: a new drawing with its own database, NOT made
active (BricsCAD V26: the new document's Active is :vlax-false, ActiveDocument
and DWGNAME unchanged, its ModelSpace empty -- probe-documents job
16932759882). Returns the new document's VLA-object."
  (com-object->vla (%document-object host (host-open-document host))))

(defun %documents-open (host args)
  "AutoCAD.Documents.Open(Name [, ReadOnly]): read the drawing, register it
and make it the active document (AutoCAD's documented behaviour) -- at the
switch time of the dialect. Returns its VLA-object."
  (let* ((path (%require-com-string-argument args "Open"))
         (read-only (and (second args) (%com-true-p (second args))))
         (key (handler-case (host-open-document-from-file host path :read-only read-only)
                (error (condition)
                  (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
                   :com-open-failed "Open could not read ~A: ~A." path condition)))))
    (clautolisp.autolisp-host:request-host-document-activation host key)
    (com-object->vla (%document-object host key))))

(defun %model-add-line (host collection-kind args)
  "ModelSpace.AddLine(StartPoint, EndPoint): create a LINE on the current layer
in the collection's space; return its VLA-object."
  (let ((p1 (%unwrap-com-point (first args) "AddLine"))
        (p2 (%unwrap-com-point (second args) "AddLine"))
        (owner (%space-owner-name collection-kind)))
    (multiple-value-bind (entity ename)
        (%host-add-entity host
                          (list (cons 0 "LINE")
                                (cons 8 (%current-layer-name host))
                                (cons 10 (copy-list p1))
                                (cons 11 (copy-list p2)))
                          'add-line owner)
      (declare (ignore entity))
      (host-vlax-ename->vla-object host ename))))

(defun %model-add-curve (host collection-kind data operator)
  (multiple-value-bind (entity ename)
      (%host-add-entity host data operator (%space-owner-name collection-kind))
    (declare (ignore entity))
    (and ename (host-vlax-ename->vla-object host ename))))

(defun %com-real-argument (value operator-name)
  (unless (realp value)
    (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
     :invalid-com-argument "~A expects a number, got ~S." operator-name value))
  (coerce value 'double-float))

(defun %model-add-arc (host collection-kind args)
  "ModelSpace.AddArc(Center, Radius, StartAngle, EndAngle): angles in
radians, stored normalised into [0, 2pi) as entget reports them."
  (destructuring-bind (&optional center radius start end &rest ignore) args
    (declare (ignore ignore))
    (flet ((norm (a) (let ((m (mod a (* 2.0d0 pi)))) (if (>= m (* 2.0d0 pi)) 0.0d0 m))))
      (%model-add-curve
       host collection-kind
       (list (cons 0 "ARC") (cons 8 (%current-layer-name host))
             (cons 10 (copy-list (%unwrap-com-point center "AddArc")))
             (cons 40 (%com-real-argument radius "AddArc"))
             (cons 50 (norm (%com-real-argument start "AddArc")))
             (cons 51 (norm (%com-real-argument end "AddArc"))))
       'add-arc))))

(defun %model-add-circle (host collection-kind args)
  "ModelSpace.AddCircle(Center, Radius)."
  (%model-add-curve
   host collection-kind
   (list (cons 0 "CIRCLE") (cons 8 (%current-layer-name host))
         (cons 10 (copy-list (%unwrap-com-point (first args) "AddCircle")))
         (cons 40 (%com-real-argument (second args) "AddCircle")))
   'add-circle))

(defun %model-add-lwpolyline (host collection-kind args)
  "ModelSpace.AddLightWeightPolyline(Vertices): a flat array of doubles
x1 y1 x2 y2 ...; bulges are set afterwards with SetBulge."
  (let ((xs (%unwrap-com-point (first args) "AddLightWeightPolyline")))
    (when (or (oddp (length xs)) (< (length xs) 4))
      (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
       :invalid-com-argument
       "AddLightWeightPolyline expects an even number (>= 4) of coordinates, got ~S." xs))
    (%model-add-curve
     host collection-kind
     (append (list (cons 0 "LWPOLYLINE") (cons 100 "AcDbEntity")
                   (cons 100 "AcDbPolyline") (cons 8 (%current-layer-name host))
                   (cons 90 (/ (length xs) 2)) (cons 70 0))
             (loop for (x y) on xs by #'cddr collect (list 10 x y)))
     'add-lwpolyline)))

(defun %block-add-attribute (host collection-kind args)
  "Block.AddAttribute(Height, Mode, Prompt, InsertionPoint, Tag, Value): add an
ATTDEF to the block definition the collection wraps, so a later InsertBlock
instantiates it. Returns the ATTDEF's VLA-object.

The argument order is the vendor's, which AutoCAD and BricsCAD both
accept (cador-addattribute-argument-order). Until 2.2.97 this adapter
read argument 4 as the Tag and argument 5 as the InsertionPoint, and
dropped argument 6 while hard-coding DXF group 1 to the empty string --
so an application written against the vendor signature handed the
insertion point where a tag was expected and failed with `AddAttribute
expects a point ... got \"REPERE\"', and no default value could ever be
stored. The whole six are mapped here: 40 Height, 70 Mode, 3 Prompt,
10 InsertionPoint, 2 Tag, 1 Value."
  (destructuring-bind (&optional height mode prompt insertion-point tag value
                       &rest ignore)
      args
    (declare (ignore ignore))
    (let* ((owner (%space-owner-name collection-kind))
           (ip (%unwrap-com-point insertion-point "AddAttribute"))
           (data (list (cons 0 "ATTDEF") (cons 8 "0")
                       (cons 10 (copy-list ip))
                       (cons 40 (coerce (if (realp height) height 2.5) 'double-float))
                       (cons 1 (or (%com-string value) ""))
                       (cons 3 (or (%com-string prompt) ""))
                       (cons 2 (or (%com-string tag) ""))
                       (cons 70 (if (integerp mode) mode 0))
                       (cons 7 "Standard"))))
      (multiple-value-bind (entity ename)
          (%host-add-entity host data 'add-attribute owner)
        (declare (ignore entity))
        (host-vlax-ename->vla-object host ename)))))

(defun %linetypes-load (host args)
  "Linetypes.Load(Name [, File]): register a :ltype table record so the linetype
is available; the .lin file is not parsed (cador has none). Returns nil."
  (let ((name (%require-com-string-argument args "Linetypes.Load")))
    (unless (cador-find-table-record host :ltype name)
      (cador-add-table-record
       host (make-symbol-table-record
             :kind :ltype :name name
             :data (list (cons 0 "LTYPE") (cons 2 name) (cons 70 0)
                         (cons 3 "") (cons 72 65) (cons 73 0) (cons 40 0.0d0)))))
    nil))

;;; --- Method definitions ------------------------------------------

(defmethod host-vlax-create-object ((host cador) progid)
  (let ((id-string (ensure-progid-string progid 'vlax-create-object)))
    (let ((object (build-cador-com-object host id-string)))
      (cond
        ((null object)
         (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
          :unknown-progid
          "cador has no COM template registered for ProgID ~A."
          id-string))
        (t
         (setf (gethash (cador-com-object-id object)
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
               (when (and (not (cador-com-object-released-p object))
                          (string-equal (cador-com-object-progid object) id-string))
                 (setf best object)))
             (cador-com-objects host))
    (and best (com-object->vla best))))

(defmethod host-vlax-release-object ((host cador) vla)
  (let ((object (resolve-vla-object host vla 'vlax-release-object)))
    (setf (cador-com-object-released-p object) t)
    nil))

(defmethod host-vlax-get-property ((host cador) vla name)
  (let ((value (%host-vlax-get-property-raw host vla name)))
    ;; ActiveX Boolean properties read as :VLAX-TRUE / :VLAX-FALSE
    ;; (vlax-boolean-properties-return-t), never as CL T / NIL.
    (if (%com-boolean-property-p (ensure-property-name-string name 'vlax-get-property))
        (%com-boolean-out value)
        value)))

(defun %host-vlax-get-property-raw (host vla name)
  (let* ((object (resolve-vla-object host vla 'vlax-get-property))
         (string (ensure-property-name-string name 'vlax-get-property)))
    (multiple-value-bind (value present-p)
        (gethash string (cador-com-object-properties object))
      (cond
        (present-p value)
        ;; Collections answer Count from their (live) member list.
        ((and (cador-com-object-collection-p object)
              (string-equal string "Count"))
         (length (live-collection-members host object)))
        (t
         ;; Entity-backed objects read their properties off the
         ;; entity's DXF groups.
         (multiple-value-bind (result handled-p)
             (%object-com-property-get host object string)
           (if handled-p
               result
               (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
                :unknown-com-property
                "VLA-OBJECT ~A has no property named ~A."
                (cador-com-object-progid object) string))))))))

(defmethod host-vlax-put-property ((host cador) vla name value)
  (let* ((object (resolve-vla-object host vla 'vlax-put-property))
         (string (ensure-property-name-string name 'vlax-put-property))
         (value (if (%com-boolean-property-p string)
                    (%com-boolean-in value string)
                    value)))
    (if (nth-value 1 (gethash string (cador-com-object-properties object)))
        (setf (gethash string (cador-com-object-properties object)) value)
        ;; Entity-backed objects write their properties into the
        ;; entity's DXF groups.
        (multiple-value-bind (result handled-p)
            (%object-com-property-put host object string value)
          (declare (ignore result))
          (unless handled-p
            (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
             :unknown-com-property
             "VLA-OBJECT ~A has no property named ~A."
             (cador-com-object-progid object) string))))
    value))

(defmethod host-vlax-invoke-method ((host cador) vla name args)
  (let* ((object (resolve-vla-object host vla 'vlax-invoke-method))
         (string (ensure-property-name-string name 'vlax-invoke-method))
         (handler (gethash string (cador-com-object-methods object))))
    (if handler
        (funcall handler host object args)
        (multiple-value-bind (result handled-p)
            (%collection-fallback-method host object string args)
          (if handled-p
              result
              (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
               :unknown-com-method
               "VLA-OBJECT ~A has no method named ~A."
               (cador-com-object-progid object) string))))))

(defmethod host-vlax-property-available-p ((host cador) vla name)
  (let* ((object (resolve-vla-object host vla 'vlax-property-available-p))
         (string (ensure-property-name-string name 'vlax-property-available-p)))
    (or (and (nth-value 1 (gethash string (cador-com-object-properties object))) t)
        (and (cador-com-object-collection-p object)
             (string-equal string "Count"))
        (%object-com-property-known-p host object string))))

(defmethod host-vlax-method-applicable-p ((host cador) vla name)
  (let* ((object (resolve-vla-object host vla 'vlax-method-applicable-p))
         (string (ensure-property-name-string name 'vlax-method-applicable-p)))
    (or (and (gethash string (cador-com-object-methods object)) t)
        (%collection-fallback-method-p host object string))))

(defun %register-cador-com-object (host object)
  "Store OBJECT in HOST's com-objects table (build-cador-com-object
allocates but does not register), attributing it to the current document
unless it already names one (or :APPLICATION). Returns OBJECT."
  (unless (cador-com-object-document-key object)
    (setf (cador-com-object-document-key object) (cador-active-document-key host)))
  (setf (gethash (cador-com-object-id object) (cador-com-objects host))
        object))

;;; --- Each object addresses its own document (multi-document slice 5) ----

(defvar *cador-current-document-key* nil
  "While CALL-WITH-CADOR-DOCUMENT makes another document's drawing current for
an object access, the document that is REALLY current (Document.Active,
Application.ActiveDocument); NIL otherwise.")

(defun cador-current-document-key (host)
  "The really current document of HOST, even inside an object's document binding."
  (or *cador-current-document-key* (cador-active-document-key host)))

(defun %com-true-p (value)
  "A COM Boolean argument as a CL boolean: :vlax-true, T or -1 are true."
  (or (eql value -1)
      (and (typep value 'clautolisp.autolisp-runtime:autolisp-symbol)
           (member (clautolisp.autolisp-runtime:autolisp-symbol-name value)
                   '(":VLAX-TRUE" "T") :test #'string-equal)
           t)))

(defun call-with-cador-document (host key thunk)
  "Call THUNK with document KEY's drawing current (HOST's ACTIVE-DRAWING and
ACTIVE-DOCUMENT-KEY), restoring them after; directly when KEY is current, NIL
or :APPLICATION. A closed document's object signals :document-closed."
  (if (or (null key) (eq key :application)
          (equal key (cador-active-document-key host)))
      (funcall thunk)
      (let ((cell (assoc key (cador-documents host) :test #'equal))
            (drawing (cador-active-drawing host))
            (active-key (cador-active-document-key host)))
        (unless cell
          (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
           :document-closed
           "Automation error: the document ~A has been closed." key))
        (unwind-protect
             (let* ((*cador-current-document-key* (cador-current-document-key host))
                    ;; D1 §10, the checked no-op: a change to this
                    ;; non-current document is checked against its lock.
                    (outer clautolisp.drawing:*drawing-modification-hook*)
                    (clautolisp.drawing:*drawing-modification-hook*
                      (lambda (target)
                        (when (eq target (cdr cell)) (%check-document-lock host key))
                        (when outer (funcall outer target)))))
               (setf (cador-active-drawing host) (cdr cell)
                     (cador-active-document-key host) key)
               (funcall thunk))
          (setf (cador-active-drawing host) drawing
                (cador-active-document-key host) active-key)))))

(defun %vla-document-key (host vla)
  (let ((object (ignore-errors (resolve-vla-object host vla 'vlax))))
    (and object (cador-com-object-document-key object))))

(defmacro %define-document-bound-com-method (name (&rest args))
  `(defmethod ,name :around ((host cador) vla ,@args)
     (call-with-cador-document host (%vla-document-key host vla)
                               (lambda () (call-next-method)))))

(%define-document-bound-com-method host-vlax-get-property (name))
(%define-document-bound-com-method host-vlax-put-property (name value))
(%define-document-bound-com-method host-vlax-invoke-method (name args))
(%define-document-bound-com-method host-vlax-collection-items ())
(%define-document-bound-com-method host-vlax-property-available-p (name))
(%define-document-bound-com-method host-vlax-method-applicable-p (name))

;;; --- Documents: one AutoCAD.Document per open document ----------------------

(defun %application-vla (host)
  (com-object->vla (cador-find-com-object host (cador-acad-application-id host))))

(defun %document-object (host key)
  "The identity-stable AutoCAD.Document of open document KEY, its collections
built against that document's drawing."
  (let* ((ids (cador-document-com-ids host))
         (cached (let ((id (gethash key ids)))
                   (and id (cador-find-com-object host id)))))
    (or cached
        (let ((doc (build-cador-com-object host "AutoCAD.Document")))
          (setf (cador-com-object-document-key doc) key)
          (%register-cador-com-object host doc)
          (setf (gethash key ids) (cador-com-object-id doc))
          ;; Name / FullName / Path / Saved / ReadOnly are the drawing's
          ;; (%document-com-property-get), not stored.
          (dolist (name '("Name" "FullName" "Path" "Saved" "ReadOnly"))
            (remhash name (cador-com-object-properties doc)))
          (when (cador-acad-application-id host)
            (setf (gethash "Application" (cador-com-object-properties doc))
                  (%application-vla host)))
          (%install-document-persistence host doc)
          (call-with-cador-document
           host key
           (lambda ()
             (let ((props (cador-com-object-properties doc)))
               (setf (gethash "Blocks" props) (com-object->vla (%blocks-collection host))
                     (gethash "Layers" props) (com-object->vla (%layers-collection host))
                     (gethash "Linetypes" props) (com-object->vla (%linetypes-collection host))
                     (gethash "ModelSpace" props) (com-object->vla (%block-object host "*Model_Space"))
                     (gethash "PaperSpace" props) (com-object->vla (%block-object host "*Paper_Space"))
                     (gethash "Layouts" props) (com-object->vla (%layouts-collection host))))))
          (setf (gethash "Activate" (cador-com-object-methods doc))
                (lambda (host object args)
                  (declare (ignore args))
                  (clautolisp.autolisp-host:request-host-document-activation
                   host (cador-com-object-document-key object))
                  nil)
                (gethash "Close" (cador-com-object-methods doc))
                (lambda (host object args)
                  ;; Close([SaveChanges [, FileName]])
                  (let ((save (and args (%com-true-p (first args))))
                        (file (and (second args) (%com-string (second args)))))
                    (cador-close-document host (cador-com-object-document-key object)
                                          :save save :file file)
                    (setf (cador-com-object-released-p object) t)
                    nil)))
          doc))))

(defun %document-key-of (host vla operator)
  (let ((object (resolve-vla-object host vla operator)))
    (cador-com-object-document-key object)))

(defmethod host-vlax-get-acad-object ((host cador))
  "Return the singleton AutoCAD.Application VLA-OBJECT, creating it — and
its ActiveDocument — on first call. Object-valued properties are stored
as VLA-OBJECT references so vla-get-activedocument yields a usable
document. Repeated calls return the same application object."
  (let* ((cached-id (cador-acad-application-id host))
         (cached (and cached-id (cador-find-com-object host cached-id))))
    (if (and cached (not (cador-com-object-released-p cached)))
        (com-object->vla cached)
        (let ((app (build-cador-com-object host "AutoCAD.Application")))
          (setf (cador-com-object-document-key app) :application)
          (%register-cador-com-object host app)
          (setf (cador-acad-application-id host) (cador-com-object-id app))
          ;; ActiveDocument is the host's current document's object, live
          ;; (%application-com-property-get); not stored.
          (remhash "ActiveDocument" (cador-com-object-properties app))
          (let ((prefs (%preferences-object host)))
            (setf (cador-com-object-document-key prefs) :application)
            (setf (gethash "Preferences" (cador-com-object-properties app))
                  (com-object->vla prefs)))
          ;; Documents: a live collection over the open documents.
          (let ((docs (make-cador-com-object :progid "AutoCAD.Documents"
                                            :collection-p t
                                            :collection-kind :documents
                                            :document-key :application)))
            (%register-cador-com-object host docs)
            (setf (gethash "Documents" (cador-com-object-properties app))
                  (com-object->vla docs)))
          ;; Every open document's object, so each has its Application.
          (dolist (key (host-document-list host))
            (%document-object host key))
          (com-object->vla app)))))

(defmethod host-vlax-collection-items ((host cador) vla)
  "Return the collection's member VLA-objects as a CL list; signal
:not-a-collection if VLA is not a collection object."
  (let ((obj (resolve-vla-object host vla 'vlax-collection-items)))
    (if (cador-com-object-collection-p obj)
        (live-collection-members host obj)
        (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
         :not-a-collection
         "vlax-for / vlax-map-collection: ~A is not an ActiveX collection."
         (cador-com-object-progid obj)))))

;;; --- Entity <-> VLA-object bridge + introspection ----------------

(defmethod host-vlax-ename->vla-object ((host cador) ename)
  "Wrap entity ENAME in an identity-stable COM object (progid
\"AutoCAD.Entity\") carrying its hex handle, so vlax-vla-object->ename
round-trips and vlax-curve-* can recover the entity."
  (let* ((handle (ename->handle ename 'vlax-ename->vla-object host))
         (cached-id (gethash handle (cador-entity-vla-map host)))
         (cached (and cached-id (cador-find-com-object host cached-id))))
    (if (and cached (not (cador-com-object-released-p cached)))
        (com-object->vla cached)
        (let ((obj (%register-cador-com-object
                    host (make-cador-com-object :progid "AutoCAD.Entity"
                                               :backing-ename handle))))
          (setf (gethash handle (cador-entity-vla-map host))
                (cador-com-object-id obj))
          (com-object->vla obj)))))

(defmethod host-vlax-vla-object->ename ((host cador) vla)
  (let* ((obj (resolve-vla-object host vla 'vlax-vla-object->ename))
         (handle (cador-com-object-backing-ename obj)))
    (if handle
        (handle->ename host handle)
        (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
         :not-an-entity-vla-object
         "vlax-vla-object->ename: ~A is not an entity-backed VLA-OBJECT."
         (cador-com-object-progid obj)))))

(defmethod host-vlax-erased-p ((host cador) vla)
  ;; Do NOT go through resolve-vla-object: a released object must report
  ;; erased = T, not signal :released-vla-object.
  (ensure-vla-object vla 'vlax-erased-p)
  (let* ((id (clautolisp.autolisp-runtime:autolisp-vla-object-value vla))
         (obj (cador-find-com-object host id)))
    (cond
      ((null obj) t)                    ; unknown -> gone
      ((cador-com-object-backing-ename obj)
       (null (safe-find-entity (cador-active-drawing host)
                               (cador-com-object-backing-ename obj))))
      (t (cador-com-object-released-p obj)))))

(defmethod host-vlax-describe-object ((host cador) vla)
  (let ((obj (resolve-vla-object host vla 'vlax-describe-object))
        (props '())
        (methods '()))
    (maphash (lambda (k v) (push (cons k v) props))
             (cador-com-object-properties obj))
    (maphash (lambda (k v) (declare (ignore v)) (push k methods))
             (cador-com-object-methods obj))
    (values (nreverse props) (nreverse methods))))

;;; --- LDATA (persistent extension-dictionary LISP data) -----------

(defun %ldata-namespace (host dictionary private operator-name)
  "Namespace string identifying a (dictionary, public/private) ldata
keyspace. DICTIONARY is a VLA-object or a global-dictionary name string."
  (let ((dict-id
          (cond
            ((typep dictionary 'clautolisp.autolisp-runtime:autolisp-vla-object)
             (let ((obj (resolve-vla-object host dictionary operator-name)))
               (or (cador-com-object-backing-ename obj)
                   (princ-to-string (cador-com-object-id obj)))))
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
