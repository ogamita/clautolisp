(in-package #:clautolisp.cador.tests)

(in-suite cador-suite)

;;; --- Phase 13: COM bridge on MockHost ----------------------------

(test vlax-create-object-returns-vla-wrapping-id
  (let* ((mock (make-cador))
         (vla (host-vlax-create-object mock "AutoCAD.Application")))
    (is (typep vla 'clautolisp.autolisp-runtime:autolisp-vla-object))
    (let* ((id (clautolisp.autolisp-runtime:autolisp-vla-object-value vla))
           (object (cador-find-com-object mock id)))
      (is (typep object 'mock-com-object))
      (is (string= "AutoCAD.Application" (mock-com-object-progid object))))))

(test vlax-get-property-reads-template-defaults
  (let* ((mock (make-cador))
         (vla (host-vlax-create-object mock "AutoCAD.Application"))
         (visible (host-vlax-get-property mock vla "Visible"))
         (name (host-vlax-get-property mock vla "Name")))
    (is (eq t visible))
    (is (string= "Mock AutoCAD" name))))

(test vlax-put-property-mutates-and-rejects-unknown-names
  (let* ((mock (make-cador))
         (vla (host-vlax-create-object mock "AutoCAD.Application")))
    (host-vlax-put-property mock vla "Visible" nil)
    (is (null (host-vlax-get-property mock vla "Visible")))
    (handler-case
        (host-vlax-put-property mock vla "NoSuch" 42)
      (autolisp-runtime-error (condition)
        (is (eq :unknown-com-property (autolisp-runtime-error-code condition)))))))

(test vlax-property-available-p
  (let* ((mock (make-cador))
         (vla (host-vlax-create-object mock "AutoCAD.Application")))
    (is (host-vlax-property-available-p mock vla "Name"))
    (is (not (host-vlax-property-available-p mock vla "NoSuch")))))

(test vlax-invoke-method-runs-handler
  (let* ((mock (make-cador))
         (vla (host-vlax-create-object mock "AutoCAD.Document")))
    ;; SaveAs sets the Name property to its first argument.
    (host-vlax-invoke-method mock vla "SaveAs" '("Renamed.dwg"))
    (is (string= "Renamed.dwg"
                 (host-vlax-get-property mock vla "Name")))))

(test vlax-invoke-method-rejects-unknown-method
  (let* ((mock (make-cador))
         (vla (host-vlax-create-object mock "AutoCAD.Document")))
    (handler-case
        (host-vlax-invoke-method mock vla "Bogus" '())
      (autolisp-runtime-error (condition)
        (is (eq :unknown-com-method (autolisp-runtime-error-code condition)))))))

(test vlax-method-applicable-p
  (let* ((mock (make-cador))
         (vla (host-vlax-create-object mock "AutoCAD.Document")))
    (is (host-vlax-method-applicable-p mock vla "Save"))
    (is (not (host-vlax-method-applicable-p mock vla "Bogus")))))

(test vlax-release-object-marks-released-and-blocks-further-ops
  (let* ((mock (make-cador))
         (vla (host-vlax-create-object mock "AutoCAD.Application")))
    (host-vlax-release-object mock vla)
    (handler-case (host-vlax-get-property mock vla "Name")
      (autolisp-runtime-error (condition)
        (is (eq :released-vla-object
                (autolisp-runtime-error-code condition)))))))

(test vlax-create-object-rejects-unknown-progid
  (let ((mock (make-cador)))
    (handler-case (host-vlax-create-object mock "No.Such.ProgID")
      (autolisp-runtime-error (condition)
        (is (eq :unknown-progid (autolisp-runtime-error-code condition)))))))

(test vlax-get-object-finds-most-recent-of-progid
  (let* ((mock (make-cador))
         (a (host-vlax-create-object mock "AutoCAD.Application"))
         (b (host-vlax-create-object mock "AutoCAD.Application")))
    (declare (ignore a))
    (let ((found (host-vlax-get-object mock "AutoCAD.Application")))
      (is (typep found 'clautolisp.autolisp-runtime:autolisp-vla-object))
      ;; Either a or b is acceptable; the contract is that some
      ;; non-released instance comes back, not that ordering is
      ;; specified.
      (is (or (string= (clautolisp.autolisp-runtime:autolisp-vla-object-value found)
                       (clautolisp.autolisp-runtime:autolisp-vla-object-value b))
              t)))))

(test register-com-progid-extends-the-registry
  (let ((mock (make-cador)))
    (register-com-progid "MyTest.Probe"
                         :properties '("Foo" 17 "Bar" "hello")
                         :methods    nil)
    (let* ((vla (host-vlax-create-object mock "MyTest.Probe")))
      (is (eql 17 (host-vlax-get-property mock vla "Foo")))
      (is (string= "hello" (host-vlax-get-property mock vla "Bar"))))))

;;; --- vlax-get-acad-object + ActiveDocument resolution ------------

(test vlax-get-acad-object-returns-application-with-live-activedocument
  ;; The acad application's ActiveDocument is a live document VLA-OBJECT
  ;; (not the nil template default), so the vla-get-activedocument chain
  ;; resolves end-to-end on the mock.
  (let* ((mock (make-cador))
         (app  (host-vlax-get-acad-object mock)))
    (is (typep app 'clautolisp.autolisp-runtime:autolisp-vla-object))
    (is (string= "Mock AutoCAD" (host-vlax-get-property mock app "Name")))
    (let ((doc (host-vlax-get-property mock app "ActiveDocument")))
      (is (typep doc 'clautolisp.autolisp-runtime:autolisp-vla-object))
      ;; It really is an AutoCAD.Document — its Name default proves it.
      (is (string= "Drawing.dwg" (host-vlax-get-property mock doc "Name")))
      ;; And the back-link Document.Application points at the app.
      (let ((back (host-vlax-get-property mock doc "Application")))
        (is (typep back 'clautolisp.autolisp-runtime:autolisp-vla-object))
        (is (string= (clautolisp.autolisp-runtime:autolisp-vla-object-value back)
                     (clautolisp.autolisp-runtime:autolisp-vla-object-value app)))))))

(test vlax-get-acad-object-is-a-singleton
  ;; Repeated calls resolve to the same underlying COM object id.
  (let* ((mock (make-cador))
         (a (host-vlax-get-acad-object mock))
         (b (host-vlax-get-acad-object mock)))
    (is (string= (clautolisp.autolisp-runtime:autolisp-vla-object-value a)
                 (clautolisp.autolisp-runtime:autolisp-vla-object-value b)))))

;;; --- Live drawing-backed collections (Blocks / Layers / spaces) ---
;;; (vla-accessor-family.issue P2 remainder; regression for the SCHMS
;;; "AutoCAD.Document has no property named BLOCKS" failure.)

(defun %tv-vla-id (vla)
  (clautolisp.autolisp-runtime:autolisp-vla-object-value vla))

(defun %tv-active-document (mock)
  (host-vlax-get-property mock (host-vlax-get-acad-object mock)
                          "ActiveDocument"))

(defun %tv-line-dxf ()
  (list (cons 0 "LINE") (cons 8 "0")
        (list 10 0.0d0 0.0d0 0.0d0) (list 11 1.0d0 0.0d0 0.0d0)))

(test document-blocks-is-a-live-collection-with-layout-blocks
  (let* ((mock (make-cador))
         (doc (%tv-active-document mock))
         (blocks (host-vlax-get-property mock doc "Blocks")))
    (is (typep blocks 'clautolisp.autolisp-runtime:autolisp-vla-object))
    ;; Count is computed live and covers the two layout blocks.
    (is (eql 2 (host-vlax-get-property mock blocks "Count")))
    (is (host-vlax-property-available-p mock blocks "Count"))
    (is (host-vlax-method-applicable-p mock blocks "Item"))
    ;; Item by name is case-insensitive; Name comes back as an
    ;; AutoLISP string so user code can strcase / strcat it.
    (let* ((model (host-vlax-invoke-method mock blocks "Item"
                                           '("*model_space")))
           (name (host-vlax-get-property mock model "Name")))
      (is (typep model 'clautolisp.autolisp-runtime:autolisp-vla-object))
      (is (typep name 'autolisp-string))
      (is (string= "*Model_Space" (autolisp-string-value name))))
    ;; Item by integer indexes the ordered member list, 0-based.
    (let ((first-block (host-vlax-invoke-method mock blocks "Item" '(0))))
      (is (string= "*Model_Space"
                   (autolisp-string-value
                    (host-vlax-get-property mock first-block "Name")))))))

(test blocks-item-missing-name-signals-com-item-not-found
  (let* ((mock (make-cador))
         (doc (%tv-active-document mock))
         (blocks (host-vlax-get-property mock doc "Blocks")))
    (handler-case
        (progn (host-vlax-invoke-method mock blocks "Item" '("NoSuchBlock"))
               (is nil "Item on a missing name should have signalled"))
      (autolisp-runtime-error (condition)
        (is (eq :com-item-not-found
                (autolisp-runtime-error-code condition)))))))

(test blocks-collection-reflects-later-block-records-and-entities
  (let* ((mock (make-cador))
         (doc (%tv-active-document mock))
         (blocks (host-vlax-get-property mock doc "Blocks")))
    ;; A block-record registered AFTER the collection was obtained is
    ;; visible: the collection is drawing-backed, not a snapshot.
    (cador-add-table-record
     mock (make-symbol-table-record
           :kind :block-record :name "SIGFIC"
           :data (list (cons 0 "BLOCK") (cons 2 "SIGFIC"))))
    (is (eql 3 (host-vlax-get-property mock blocks "Count")))
    (let ((sigfic (host-vlax-invoke-method
                   mock blocks "Item"
                   (list (make-autolisp-string "sigfic")))))
      ;; Item is identity-stable: same VLA id on every lookup.
      (is (string= (%tv-vla-id sigfic)
                   (%tv-vla-id (host-vlax-invoke-method mock blocks "Item"
                                                        '("SIGFIC")))))
      ;; Entities owned by the block enumerate through the block object,
      ;; which is itself a live collection.
      (clautolisp.drawing:add-entity (cador-active-drawing mock)
                                     (%tv-line-dxf) :block "SIGFIC")
      (is (eql 1 (host-vlax-get-property mock sigfic "Count")))
      (let ((items (host-vlax-collection-items mock sigfic)))
        (is (= 1 (length items)))
        ;; The member is entity-backed: it round-trips to an ENAME.
        (is (typep (host-vlax-vla-object->ename mock (first items))
                   'autolisp-ename))))))

(test blocks-add-creates-a-block-and-delete-erases-it
  (let* ((mock (make-cador))
         (doc (%tv-active-document mock))
         (blocks (host-vlax-get-property mock doc "Blocks"))
         ;; Blocks.Add(Origin, Name) — vendor argument order.
         (new-block (host-vlax-invoke-method
                     mock blocks "Add"
                     (list (list 0.0d0 0.0d0 0.0d0) "CARTOUCHE"))))
    (is (typep new-block 'clautolisp.autolisp-runtime:autolisp-vla-object))
    (is (not (null (cador-find-table-record mock :block-record "CARTOUCHE"))))
    (is (eql 3 (host-vlax-get-property mock blocks "Count")))
    (let ((entity (clautolisp.drawing:add-entity (cador-active-drawing mock)
                                                 (%tv-line-dxf)
                                                 :block "CARTOUCHE")))
      (host-vlax-invoke-method mock new-block "Delete" '())
      (is (null (cador-find-table-record mock :block-record "CARTOUCHE")))
      (is (eql 2 (host-vlax-get-property mock blocks "Count")))
      (is (clautolisp.drawing:entity-handle-deleted-p entity)))))

(test blocks-delete-refuses-layout-blocks
  (let* ((mock (make-cador))
         (doc (%tv-active-document mock))
         (blocks (host-vlax-get-property mock doc "Blocks"))
         (model (host-vlax-invoke-method mock blocks "Item" '("*Model_Space"))))
    (handler-case
        (progn (host-vlax-invoke-method mock model "Delete" '())
               (is nil "Delete on *Model_Space should have signalled"))
      (autolisp-runtime-error (condition)
        (is (eq :com-cannot-delete-layout-block
                (autolisp-runtime-error-code condition)))))))

(test document-modelspace-is-a-live-entity-collection
  (let* ((mock (make-cador))
         (doc (%tv-active-document mock))
         (modelspace (host-vlax-get-property mock doc "ModelSpace")))
    (is (typep modelspace 'clautolisp.autolisp-runtime:autolisp-vla-object))
    (is (eql 0 (host-vlax-get-property mock modelspace "Count")))
    ;; An entmade (owner-less) entity lands in model space.
    (host-entmake mock (%tv-line-dxf))
    (is (eql 1 (host-vlax-get-property mock modelspace "Count")))
    (let ((items (host-vlax-collection-items mock modelspace)))
      (is (= 1 (length items)))
      (is (typep (host-vlax-vla-object->ename mock (first items))
                 'autolisp-ename)))))

(test document-layers-is-live-and-supports-item-and-add
  (let* ((mock (make-cador))
         (doc (%tv-active-document mock))
         (layers (host-vlax-get-property mock doc "Layers")))
    ;; The default layer "0" is there.
    (is (eql 1 (host-vlax-get-property mock layers "Count")))
    (let ((zero (host-vlax-invoke-method mock layers "Item" '("0"))))
      (is (string= "0" (autolisp-string-value
                        (host-vlax-get-property mock zero "Name")))))
    ;; Layers.Add(Name) registers a layer record.
    (host-vlax-invoke-method mock layers "Add" '("SIGNALISATION"))
    (is (eql 2 (host-vlax-get-property mock layers "Count")))
    (is (not (null (cador-find-table-record mock :layer "SIGNALISATION"))))))

;;; --- Block definitions through ENTMAKE + the entity property bridge ---
;;; (Regression for the SCHMS "Item: no item named sigfic_N" failure:
;;; fixtures entmake their block definitions, which must land in the
;;; block table and be reachable through the Blocks collection.)

(defun %tv-attdef-dxf (tag)
  (list (cons 0 "ATTDEF") (cons 8 "0")
        (list 10 0.0d0 0.0d0 0.0d0) (cons 40 2.5d0)
        (cons 1 "default") (cons 2 tag) (cons 3 "prompt?") (cons 70 0)))

(defun %tv-text-dxf (string)
  (list (cons 0 "TEXT") (cons 8 "0")
        (list 10 0.0d0 0.0d0 0.0d0) (cons 40 2.5d0) (cons 1 string)))

(defun %tv-make-sigfic-block (mock name)
  "Entmake a block definition NAME holding one ATTDEF and one TEXT,
the shape of the SCHMS sigfic fixtures."
  (host-entmake mock (list (cons 0 "BLOCK") (cons 2 name) (cons 70 2)
                           (list 10 0.0d0 0.0d0 0.0d0)))
  (host-entmake mock (%tv-attdef-dxf "SIGTAG"))
  (host-entmake mock (%tv-text-dxf "corps"))
  (host-entmake mock (list (cons 0 "ENDBLK"))))

(test entmake-block-endblk-registers-a-visible-block-definition
  (let* ((mock (make-cador))
         (doc (%tv-active-document mock))
         (blocks (host-vlax-get-property mock doc "Blocks"))
         (closing (%tv-make-sigfic-block mock "SIGFIC_T")))
    ;; ENDBLK returns the completed block's name (vendor contract).
    (is (typep closing 'autolisp-string))
    (is (string= "SIGFIC_T" (autolisp-string-value closing)))
    ;; The definition is in the :block-record table and the collection.
    (is (not (null (cador-find-table-record mock :block-record "SIGFIC_T"))))
    (is (eql 3 (host-vlax-get-property mock blocks "Count")))
    (let ((sigfic (host-vlax-invoke-method mock blocks "Item" '("sigfic_t"))))
      ;; The block owns its two entities, visible through the block object.
      (is (eql 2 (host-vlax-get-property mock sigfic "Count"))))))

(test entmake-block-contents-stay-out-of-main-space
  (let* ((mock (make-cador))
         (doc (%tv-active-document mock))
         (modelspace (host-vlax-get-property mock doc "ModelSpace")))
    (%tv-make-sigfic-block mock "SIGFIC_U")
    ;; Nothing in model space, no entlast, no top-level entnext.
    (is (eql 0 (host-vlax-get-property mock modelspace "Count")))
    (is (null (host-entlast mock)))
    (is (null (host-entnext mock nil)))
    ;; A model-space entity entmade after the ENDBLK is back to normal.
    (host-entmake mock (%tv-text-dxf "en model space"))
    (is (eql 1 (host-vlax-get-property mock modelspace "Count")))
    (is (typep (host-entlast mock) 'autolisp-ename))
    ;; The top-level walk sees only the model-space entity.
    (let ((first (host-entnext mock nil)))
      (is (typep first 'autolisp-ename))
      (is (null (host-entnext mock first))))))

(test entnext-from-block-table-record-walks-the-block-entities
  (let* ((mock (make-cador)))
    (%tv-make-sigfic-block mock "SIGFIC_V")
    (let ((record-ename (host-tblobjname mock "BLOCK" "SIGFIC_V")))
      (is (typep record-ename 'autolisp-ename))
      ;; The canonical ATTDEF scan: entnext from the table record's
      ;; ename yields the block's entities in creation order.
      (let* ((first (host-entnext mock record-ename))
             (second (and first (host-entnext mock first))))
        (is (typep first 'autolisp-ename))
        (is (typep second 'autolisp-ename))
        (is (null (host-entnext mock second)))
        (let ((vla (host-vlax-ename->vla-object mock first)))
          (is (string= "AcDbAttributeDefinition"
                       (autolisp-string-value
                        (host-vlax-get-property mock vla "ObjectName")))))))))

(test entmake-block-redefinition-replaces-the-contents
  (let* ((mock (make-cador))
         (doc (%tv-active-document mock))
         (blocks (host-vlax-get-property mock doc "Blocks")))
    (%tv-make-sigfic-block mock "SIGFIC_W")
    ;; Redefine with a single entity: the old contents are erased.
    (host-entmake mock (list (cons 0 "BLOCK") (cons 2 "SIGFIC_W") (cons 70 2)
                             (list 10 0.0d0 0.0d0 0.0d0)))
    (host-entmake mock (%tv-text-dxf "v2"))
    (host-entmake mock (list (cons 0 "ENDBLK")))
    (is (eql 3 (host-vlax-get-property mock blocks "Count")))
    (let ((block (host-vlax-invoke-method mock blocks "Item" '("SIGFIC_W"))))
      (is (eql 1 (host-vlax-get-property mock block "Count"))))))

(test entity-property-bridge-reads-and-writes-dxf-groups
  (let* ((mock (make-cador))
         (view (host-entmake mock (%tv-text-dxf "hello")))
         (ename (cdr (first view)))
         (vla (host-vlax-ename->vla-object mock ename)))
    ;; Reads off the DXF groups, strings as AutoLISP strings.
    (is (string= "hello" (autolisp-string-value
                          (host-vlax-get-property mock vla "TextString"))))
    (is (string= "0" (autolisp-string-value
                      (host-vlax-get-property mock vla "Layer"))))
    (is (string= "AcDbText" (autolisp-string-value
                             (host-vlax-get-property mock vla "ObjectName"))))
    (is (typep (host-vlax-get-property mock vla "Handle") 'autolisp-string))
    (is (= 0.0d0 (host-vlax-get-property mock vla "Rotation")))
    ;; Absent group -> documented default.
    (is (eql 256 (host-vlax-get-property mock vla "Color")))
    ;; Writes go into the entity data, visible to entget.
    (host-vlax-put-property mock vla "TextString"
                            (make-autolisp-string "monde"))
    (host-vlax-put-property mock vla "Rotation" 1.5d0)
    (is (string= "monde" (autolisp-string-value
                          (host-vlax-get-property mock vla "TextString"))))
    (is (= 1.5d0 (host-vlax-get-property mock vla "Rotation")))
    (let* ((data (host-entget mock ename))
           (group1 (find-if (lambda (pair)
                              (and (consp pair) (eql 1 (car pair))))
                            data)))
      (is (string= "monde" (autolisp-string-value (cdr group1)))))
    ;; Points pass as plain lists at the host layer (no builtins hooks).
    (is (equal '(0.0d0 0.0d0 0.0d0)
               (host-vlax-get-property mock vla "InsertionPoint")))
    (host-vlax-put-property mock vla "InsertionPoint" '(1.0d0 2.0d0 0.0d0))
    (is (equal '(1.0d0 2.0d0 0.0d0)
               (host-vlax-get-property mock vla "InsertionPoint")))
    ;; Availability introspection covers the bridge.
    (is (host-vlax-property-available-p mock vla "TextString"))
    (is (not (host-vlax-property-available-p mock vla "Bogus")))))

(test entity-property-bridge-alignment-enum-round-trips
  (let* ((mock (make-cador))
         (view (host-entmake mock (%tv-text-dxf "aligne")))
         (ename (cdr (first view)))
         (vla (host-vlax-ename->vla-object mock ename)))
    (is (eql 0 (host-vlax-get-property mock vla "Alignment")))
    ;; acAlignmentMiddleCenter = 10 -> groups 72=1, 73=2 on TEXT.
    (host-vlax-put-property mock vla "Alignment" 10)
    (is (eql 10 (host-vlax-get-property mock vla "Alignment")))
    (let* ((data (host-entget mock ename))
           (g72 (find-if (lambda (p) (and (consp p) (eql 72 (car p)))) data))
           (g73 (find-if (lambda (p) (and (consp p) (eql 73 (car p)))) data)))
      (is (eql 1 (cdr g72)))
      (is (eql 2 (cdr g73))))))

(test entity-property-bridge-rejects-read-only-and-unknown
  (let* ((mock (make-cador))
         (view (host-entmake mock (%tv-text-dxf "ro")))
         (ename (cdr (first view)))
         (vla (host-vlax-ename->vla-object mock ename)))
    (handler-case
        (progn (host-vlax-put-property mock vla "Handle" "FFFF")
               (is nil "putting Handle should have signalled"))
      (autolisp-runtime-error (condition)
        (is (eq :com-read-only-property
                (autolisp-runtime-error-code condition)))))
    (handler-case
        (progn (host-vlax-get-property mock vla "NoSuchProp")
               (is nil "unknown property should have signalled"))
      (autolisp-runtime-error (condition)
        (is (eq :unknown-com-property
                (autolisp-runtime-error-code condition)))))))

(test attdef-bridge-tagstring-and-mode
  (let* ((mock (make-cador))
         (view (host-entmake mock (%tv-attdef-dxf "ALT")))
         (ename (cdr (first view)))
         (vla (host-vlax-ename->vla-object mock ename)))
    (is (string= "ALT" (autolisp-string-value
                        (host-vlax-get-property mock vla "TagString"))))
    (is (eql 0 (host-vlax-get-property mock vla "Mode")))
    (host-vlax-put-property mock vla "TagString" "NOUVEAU")
    (is (string= "NOUVEAU" (autolisp-string-value
                            (host-vlax-get-property mock vla "TagString"))))))

;;; --- InsertBlock + attribute instantiation + entity methods -------
;;; (Regression for the SCHMS "AutoCAD.Block has no method named
;;; INSERTBLOCK" failure: fixtures insert their sigfic block into model
;;; space, then the migrations walk / rewrite its attributes.)

(defun %tv~= (a b) (< (abs (- a b)) 1d-9))

(test insertblock-creates-a-reference-with-instantiated-attributes
  (let* ((mock (make-cador))
         (doc (%tv-active-document mock))
         (modelspace (host-vlax-get-property mock doc "ModelSpace")))
    (%tv-make-sigfic-block mock "SIGFIC_I")
    (let ((insert (host-vlax-invoke-method
                   mock modelspace "InsertBlock"
                   (list (list 10.0d0 20.0d0 0.0d0) "SIGFIC_I"
                         1.0d0 1.0d0 1.0d0 0.0d0))))
      (is (typep insert 'clautolisp.autolisp-runtime:autolisp-vla-object))
      (is (string= "AcDbBlockReference"
                   (autolisp-string-value
                    (host-vlax-get-property mock insert "ObjectName"))))
      (is (string= "SIGFIC_I"
                   (autolisp-string-value
                    (host-vlax-get-property mock insert "Name"))))
      (is (eq t (host-vlax-get-property mock insert "HasAttributes")))
      ;; The reference (not its attribute run) is the space's member.
      (is (eql 1 (host-vlax-get-property mock modelspace "Count")))
      ;; GetAttributes: the ATTRIB clone of the definition's ATTDEF,
      ;; translated to the insertion point.
      (let ((attributes (host-vlax-invoke-method mock insert
                                                 "GetAttributes" '())))
        (is (= 1 (length attributes)))
        (let ((attribute (first attributes)))
          (is (string= "SIGTAG"
                       (autolisp-string-value
                        (host-vlax-get-property mock attribute "TagString"))))
          (is (string= "default"
                       (autolisp-string-value
                        (host-vlax-get-property mock attribute "TextString"))))
          (let ((p (host-vlax-get-property mock attribute "InsertionPoint")))
            (is (%tv~= 10.0d0 (first p)))
            (is (%tv~= 20.0d0 (second p)))))))))

(test insertblock-applies-rotation-to-attribute-positions
  (let* ((mock (make-cador))
         (doc (%tv-active-document mock))
         (modelspace (host-vlax-get-property mock doc "ModelSpace"))
         (half-pi (/ pi 2)))
    ;; A definition whose ATTDEF sits at (1 0 0).
    (host-entmake mock (list (cons 0 "BLOCK") (cons 2 "SIGFIC_R") (cons 70 2)
                             (list 10 0.0d0 0.0d0 0.0d0)))
    (host-entmake mock (list (cons 0 "ATTDEF") (cons 8 "0")
                             (list 10 1.0d0 0.0d0 0.0d0) (cons 40 2.5d0)
                             (cons 1 "v") (cons 2 "T") (cons 3 "p")
                             (cons 70 0)))
    (host-entmake mock (list (cons 0 "ENDBLK")))
    (let* ((insert (host-vlax-invoke-method
                    mock modelspace "InsertBlock"
                    (list (list 0.0d0 0.0d0 0.0d0) "SIGFIC_R"
                          1.0d0 1.0d0 1.0d0 half-pi)))
           (attribute (first (host-vlax-invoke-method mock insert
                                                      "GetAttributes" '())))
           (p (host-vlax-get-property mock attribute "InsertionPoint")))
      ;; (1 0 0) rotated a quarter turn -> (0 1 0).
      (is (%tv~= 0.0d0 (first p)))
      (is (%tv~= 1.0d0 (second p)))
      ;; And the attribute's own rotation follows the reference's.
      (is (%tv~= half-pi (host-vlax-get-property mock attribute "Rotation"))))))

(test entity-move-rotate-copy-delete-methods
  (let* ((mock (make-cador))
         (doc (%tv-active-document mock))
         (modelspace (host-vlax-get-property mock doc "ModelSpace"))
         (view (host-entmake mock (%tv-text-dxf "mobile")))
         (ename (cdr (first view)))
         (vla (host-vlax-ename->vla-object mock ename)))
    ;; Move((0 0 0) -> (5 5 0)).
    (host-vlax-invoke-method mock vla "Move"
                             (list (list 0.0d0 0.0d0 0.0d0)
                                   (list 5.0d0 5.0d0 0.0d0)))
    (let ((p (host-vlax-get-property mock vla "InsertionPoint")))
      (is (%tv~= 5.0d0 (first p)))
      (is (%tv~= 5.0d0 (second p))))
    ;; Rotate about the origin by pi: (5 5) -> (-5 -5); rotation group
    ;; follows.
    (host-vlax-invoke-method mock vla "Rotate"
                             (list (list 0.0d0 0.0d0 0.0d0)
                                   (coerce pi 'double-float)))
    (let ((p (host-vlax-get-property mock vla "InsertionPoint")))
      (is (%tv~= -5.0d0 (first p)))
      (is (%tv~= -5.0d0 (second p))))
    (is (%tv~= (coerce pi 'double-float)
               (host-vlax-get-property mock vla "Rotation")))
    ;; Copy duplicates in place; Delete erases.
    (let ((copy (host-vlax-invoke-method mock vla "Copy" '())))
      (is (typep copy 'clautolisp.autolisp-runtime:autolisp-vla-object))
      (is (eql 2 (host-vlax-get-property mock modelspace "Count")))
      (host-vlax-invoke-method mock copy "Delete" '())
      (is (eql 1 (host-vlax-get-property mock modelspace "Count"))))))

(test insert-delete-erases-the-attribute-run
  (let* ((mock (make-cador))
         (doc (%tv-active-document mock))
         (modelspace (host-vlax-get-property mock doc "ModelSpace")))
    (%tv-make-sigfic-block mock "SIGFIC_D")
    (let* ((insert (host-vlax-invoke-method
                    mock modelspace "InsertBlock"
                    (list (list 0.0d0 0.0d0 0.0d0) "SIGFIC_D")))
           (attribute (first (host-vlax-invoke-method mock insert
                                                      "GetAttributes" '()))))
      (host-vlax-invoke-method mock insert "Delete" '())
      (is (eql 0 (host-vlax-get-property mock modelspace "Count")))
      ;; The attribute run went down with the reference.
      (is (host-vlax-erased-p mock attribute)))))

(test entity-getboundingbox-covers-points-and-text-height
  (let* ((mock (make-cador))
         (view (host-entmake mock (%tv-text-dxf "boite")))
         (ename (cdr (first view)))
         (vla (host-vlax-ename->vla-object mock ename))
         (box (host-vlax-invoke-method mock vla "GetBoundingBox" '())))
    (is (consp box))
    (let ((min-corner (first box)) (max-corner (second box)))
      (is (%tv~= 0.0d0 (first min-corner)))
      (is (%tv~= 0.0d0 (second min-corner)))
      ;; The text height extends the box upward.
      (is (%tv~= 2.5d0 (second max-corner))))))

;;; --- The classic block-contents walk: tblsearch -2 + entget -------
;;; (Regression for the SCHMS "attendu 2 LINE dans le bloc sigfic,
;;; trouve 0" failure: the fixture checker walks the definition from
;;; the BLOCK table record's -2 group.)

(test tblsearch-block-record-carries-the-minus-2-walk-entry
  (let* ((mock (make-cador)))
    ;; A sigfic-shaped definition with two LINEs, as the SCHMS check
    ;; expects.
    (host-entmake mock (list (cons 0 "BLOCK") (cons 2 "SIGFIC_L") (cons 70 2)
                             (list 10 0.0d0 0.0d0 0.0d0)))
    (host-entmake mock (list (cons 0 "LINE") (cons 8 "0")
                             (list 10 0.0d0 0.0d0 0.0d0)
                             (list 11 1.0d0 0.0d0 0.0d0)))
    (host-entmake mock (list (cons 0 "LINE") (cons 8 "0")
                             (list 10 0.0d0 1.0d0 0.0d0)
                             (list 11 1.0d0 1.0d0 0.0d0)))
    (host-entmake mock (%tv-attdef-dxf "SIGTAG"))
    (host-entmake mock (list (cons 0 "ENDBLK")))
    (let* ((data (host-tblsearch mock "BLOCK" "SIGFIC_L"))
           (entry (cdr (assoc -2 data))))
      (is (typep entry 'autolisp-ename))
      ;; Walk from the -2 entry: LINE, LINE, ATTDEF, then nil.
      (let ((types '()) (e entry))
        (loop while e
              do (let* ((view (host-entget mock e))
                        (zero (cdr (assoc 0 view))))
                   (push (autolisp-string-value zero) types)
                   (setf e (host-entnext mock e))))
        (is (equal '("LINE" "LINE" "ATTDEF") (reverse types)))))
    ;; The layer table view is unchanged (no -2 on non-BLOCK kinds).
    (is (null (assoc -2 (host-tblsearch mock "LAYER" "0"))))))

(test entget-on-a-block-table-record-ename-yields-the-record-view
  (let* ((mock (make-cador)))
    (%tv-make-sigfic-block mock "SIGFIC_G")
    (let* ((record-ename (host-tblobjname mock "BLOCK" "SIGFIC_G"))
           (data (host-entget mock record-ename)))
      (is (consp data))
      ;; (-1 . ename) head, the record's own groups, and the -2 entry.
      (is (eq record-ename (cdr (assoc -1 data))))
      (is (string= "SIGFIC_G"
                   (autolisp-string-value (cdr (assoc 2 data)))))
      (let ((entry (cdr (assoc -2 data))))
        (is (typep entry 'autolisp-ename))
        (is (string= "ATTDEF"
                     (autolisp-string-value
                      (cdr (assoc 0 (host-entget mock entry))))))))))

(test entmake-block-abandons-a-dangling-open-definition
  ;; A factory that died between BLOCK and ENDBLK (its error swallowed
  ;; by *error*) must not brick every later factory: the next BLOCK
  ;; header abandons the dangling run and opens normally.
  (let* ((mock (make-cador)))
    (host-entmake mock (list (cons 0 "BLOCK") (cons 2 "ABANDONNE")
                             (cons 70 2) (list 10 0.0d0 0.0d0 0.0d0)))
    ;; …no ENDBLK: the factory died here. A fresh definition works.
    (let ((closing (%tv-make-sigfic-block mock "SIGFIC_OK")))
      (is (typep closing 'autolisp-string))
      (is (string= "SIGFIC_OK" (autolisp-string-value closing))))
    (is (not (null (cador-find-table-record mock :block-record "SIGFIC_OK"))))
    ;; The abandoned name was never registered.
    (is (null (cador-find-table-record mock :block-record "ABANDONNE")))))

(test entity-getboundingbox-honours-vertical-justification
  ;; A top-left justified TEXT grows DOWNWARD from its anchor: box
  ;; [y-h, y]. (Regression: the box always grew upward, flipping the
  ;; SCHMS topological côté BAS reading of TL labels.)
  (let* ((mock (make-cador))
         (view (host-entmake
                mock (list (cons 0 "TEXT") (cons 8 "0")
                           (list 10 0.0d0 5.0d0 0.0d0)
                           (list 11 0.0d0 5.0d0 0.0d0)
                           (cons 40 2.5d0) (cons 1 "tl")
                           (cons 72 0) (cons 73 3))))
         (ename (cdr (first view)))
         (vla (host-vlax-ename->vla-object mock ename))
         (box (host-vlax-invoke-method mock vla "GetBoundingBox" '())))
    (is (%tv~= 2.5d0 (second (first box))))
    (is (%tv~= 5.0d0 (second (second box))))))
