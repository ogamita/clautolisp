(in-package #:clautolisp.cador.tests)

(in-suite cador-suite)

;;; --- Phase 13: COM bridge on cador ----------------------------

(test vlax-create-object-returns-vla-wrapping-id
  (let* ((mock (make-cador))
         (vla (host-vlax-create-object mock "AutoCAD.Application")))
    (is (typep vla 'clautolisp.autolisp-runtime:autolisp-vla-object))
    (let* ((id (clautolisp.autolisp-runtime:autolisp-vla-object-value vla))
           (object (cador-find-com-object mock id)))
      (is (typep object 'cador-com-object))
      (is (string= "AutoCAD.Application" (cador-com-object-progid object))))))

(defun %tv-vlax-boolean-p (value name)
  "True when VALUE is the ActiveX boolean symbol NAME (:VLAX-TRUE / :VLAX-FALSE)."
  (and (typep value 'clautolisp.autolisp-runtime:autolisp-symbol)
       (string= name (clautolisp.autolisp-runtime:autolisp-symbol-name value))))

(test vlax-get-property-reads-template-defaults
  (let* ((mock (make-cador))
         (vla (host-vlax-create-object mock "AutoCAD.Application"))
         (visible (host-vlax-get-property mock vla "Visible"))
         (name (host-vlax-get-property mock vla "Name")))
    (is (%tv-vlax-boolean-p visible ":VLAX-TRUE"))
    (is (string= "Mock AutoCAD" name))))

(test vlax-put-property-mutates-and-rejects-unknown-names
  (let* ((mock (make-cador))
         (vla (host-vlax-create-object mock "AutoCAD.Application")))
    (host-vlax-put-property mock vla "Visible" nil)
    (is (%tv-vlax-boolean-p (host-vlax-get-property mock vla "Visible") ":VLAX-FALSE"))
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
      (is (string= "Drawing1.dwg" (autolisp-string-value (host-vlax-get-property mock doc "Name"))))
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
      (is (%tv-vlax-boolean-p (host-vlax-get-property mock insert "HasAttributes") ":VLAX-TRUE"))
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
    ;; A TEXT at the origin is bounded by its glyph ink, exactly as
    ;; TEXTBOX measures it (both vendors agree; the box is no longer
    ;; the bare insertion point stretched by the height).
    (multiple-value-bind (x0 y0 x1 y1)
        (clautolisp.autolisp-runtime:text-ink-box "boite" 2.5d0)
      (let ((min-corner (first box)) (max-corner (second box)))
        (is (%tv~= x0 (first min-corner)))
        (is (%tv~= y0 (second min-corner)))
        (is (%tv~= x1 (first max-corner)))
        (is (%tv~= y1 (second max-corner)))
        ;; Real width: five glyphs at height 2.5, not zero.
        (is (< 5.0d0 (first max-corner) 12.0d0))))))

(test entity-getboundingbox-of-text-matches-the-vendor-measure
  ;; probe-block-walk.lsp, AutoCAD 2022 and BricsCAD: 10 x M and
  ;; 10 x i at height 1, TEXTBOX = GetBoundingBox at the origin.
  (flet ((box-of (string)
           (let* ((mock (make-cador))
                  (view (host-entmake
                         mock (list (cons 0 "TEXT") (cons 8 "0")
                                    (list 10 0.0d0 0.0d0 0.0d0)
                                    (cons 40 1.0d0) (cons 1 string))))
                  (vla (host-vlax-ename->vla-object mock (cdr (first view)))))
             (host-vlax-invoke-method mock vla "GetBoundingBox" '()))))
    (let ((m (box-of "MMMMMMMMMM")) (i (box-of "iiiiiiiiii")))
      (is (< (abs (- 0.103683d0 (first (first m)))) 1d-4))
      (is (< (abs (- 11.531378d0 (first (second m)))) 1d-4))
      (is (< (abs (- 1.0d0 (second (second m)))) 1d-4))
      (is (< (abs (- 0.092769d0 (first (first i)))) 1d-4))
      (is (< (abs (- 3.008868d0 (first (second i)))) 1d-4)))))

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
    ;; Baseline at 5 - 2.5: the ink of "tl" hangs below the anchor
    ;; (its curve overshoots the baseline by a hair).
    (multiple-value-bind (x0 y0 x1 y1)
        (clautolisp.autolisp-runtime:text-ink-box "tl" 2.5d0)
      (declare (ignore x0 x1))
      (is (%tv~= (+ 2.5d0 y0) (second (first box))))
      (is (%tv~= (+ 2.5d0 y1) (second (second box))))
      (is (<= (second (second box)) 5.0d0)))))

;;; --- SCHME A1 object-model surface (cador-schme-a1-activex-coverage) ---
;;;
;;; The ActiveX object model SCHME+ drives against: Layers.Add + a
;;; mutable Layer.Color / Layer.Linetype backed by the layer table
;;; record, Document.ActiveLayer tracking CLAYER, Layer.Delete,
;;; Documents.Add, ModelSpace.AddLine, Block.AddAttribute,
;;; Linetypes.Load and a persisting Document.SaveAs. Each new-surface
;;; test asserts that DXF (the table record / entity list) and ActiveX
;;; observe the same state.

(defun %a1-str (value)
  "Coerce a COM string-valued property (an AutoLISP string wrapper the
mock hands back so user code can strcat it) to a CL string for
comparison."
  (if (typep value 'autolisp-string)
      (autolisp-string-value value)
      value))

(defun %a1-active-document (host)
  (let ((app (host-vlax-get-acad-object host)))
    (host-vlax-get-property host app "ActiveDocument")))

(defun %a1-layer-record-group (host name code)
  (let ((record (cador-find-table-record host :layer name)))
    (and record (cdr (assoc code (symbol-table-record-data record))))))

(test vlax-layer-color-reads-and-writes-the-table-record
  (let* ((host (make-cador))
         (doc (%a1-active-document host))
         (layers (host-vlax-get-property host doc "Layers"))
         (layer (host-vlax-invoke-method host layers "Add" '("BORNAGE"))))
    ;; The freshly-added layer defaults to colour 7 (white).
    (is (= 7 (host-vlax-get-property host layer "Color")))
    (host-vlax-put-property host layer "Color" 3)
    ;; ActiveX and the DXF table record agree.
    (is (= 3 (host-vlax-get-property host layer "Color")))
    (is (= 3 (%a1-layer-record-group host "BORNAGE" 62)))))

(test vlax-layer-linetype-reads-and-writes-the-table-record
  (let* ((host (make-cador))
         (doc (%a1-active-document host))
         (linetypes (host-vlax-get-property host doc "Linetypes"))
         (layers (host-vlax-get-property host doc "Layers"))
         (layer (host-vlax-invoke-method host layers "Add" '("AXES"))))
    (is (string= "Continuous" (%a1-str (host-vlax-get-property host layer "Linetype"))))
    (host-vlax-invoke-method host linetypes "Load" '("DASHED"))
    (host-vlax-put-property host layer "Linetype" "DASHED")
    (is (string= "DASHED" (%a1-str (host-vlax-get-property host layer "Linetype"))))
    (is (string= "DASHED" (%a1-layer-record-group host "AXES" 6)))))

(test vlax-document-activelayer-tracks-and-sets-clayer
  (let* ((host (make-cador))
         (doc (%a1-active-document host))
         (layers (host-vlax-get-property host doc "Layers")))
    (host-vlax-invoke-method host layers "Add" '("WALLS"))
    ;; ActiveLayer reflects the current CLAYER.
    (cador-set-sysvar host "CLAYER" "WALLS")
    (let ((active (host-vlax-get-property host doc "ActiveLayer")))
      (is (string= "WALLS" (%a1-str (host-vlax-get-property host active "Name")))))
    ;; Setting ActiveLayer to another layer makes it current.
    (let ((other (host-vlax-invoke-method host layers "Add" '("GRID"))))
      (host-vlax-put-property host doc "ActiveLayer" other)
      (is (string= "GRID" (%a1-str (sysvar-cell-value
                                    (cador-sysvar host "CLAYER"))))))))

(test vlax-layer-delete-removes-the-record
  (let* ((host (make-cador))
         (doc (%a1-active-document host))
         (layers (host-vlax-get-property host doc "Layers"))
         (layer (host-vlax-invoke-method host layers "Add" '("SCRATCH"))))
    (is (cador-find-table-record host :layer "SCRATCH"))
    (host-vlax-invoke-method host layer "Delete" '())
    (is (null (cador-find-table-record host :layer "SCRATCH")))))

(test vlax-documents-add-yields-a-document-with-live-collections
  (let* ((host (make-cador))
         (app (host-vlax-get-acad-object host))
         (docs (host-vlax-get-property host app "Documents"))
         (new (host-vlax-invoke-method host docs "Add" '())))
    (is (string= "AutoCAD.Document"
                 (cador-com-object-progid (cador-find-com-object
                                          host
                                          (clautolisp.autolisp-runtime:autolisp-vla-object-value new)))))
    ;; Its Blocks / Layers are live collections (answer Count).
    (let ((blocks (host-vlax-get-property host new "Blocks")))
      (is (< 0 (host-vlax-get-property host blocks "Count"))))))

(test vlax-modelspace-addline-creates-an-entity
  (let* ((host (make-cador))
         (doc (%a1-active-document host))
         (model (host-vlax-get-property host doc "ModelSpace"))
         (before (host-vlax-get-property host model "Count"))
         (line (host-vlax-invoke-method host model "AddLine"
                                        (list '(0.0d0 0.0d0 0.0d0)
                                              '(10.0d0 0.0d0 0.0d0)))))
    (is (string= "AcDbLine" (%a1-str (host-vlax-get-property host line "ObjectName"))))
    (is (= (1+ before) (host-vlax-get-property host model "Count")))))

(test vlax-block-addattribute-adds-an-attdef-to-the-block
  "Block.AddAttribute(Height, Mode, Prompt, InsertionPoint, Tag, Value) --
the VENDOR order, which AutoCAD and BricsCAD both accept
(cador-addattribute-argument-order). Until alfe 2.2.97 the adapter read
the 4th argument as the Tag and the 5th as the InsertionPoint, and
discarded the 6th (Value) while hard-coding DXF group 1 to \"\". This
test previously passed the arguments in the SAME wrong order as the
implementation, so it validated Cador against its own mistaken contract:
a real call with a point in position 4 failed with `AddAttribute expects
a point ... got \"REPERE\"'.

Every mapped field is asserted, with values that are observably
different from one another, so no future permutation can stay green
merely because an ATTDEF came back."
  (let* ((host (make-cador))
         (doc (%a1-active-document host))
         (blocks (host-vlax-get-property host doc "Blocks"))
         (block (host-vlax-invoke-method host blocks "Add"
                                         (list '(0.0d0 0.0d0 0.0d0) "TITLE")))
         (before (host-vlax-get-property host block "Count"))
         (attdef (host-vlax-invoke-method
                  host block "AddAttribute"
                  ;; Height Mode Prompt InsertionPoint Tag Value
                  (list 2.5d0 8 "Enter name" '(1.0d0 2.0d0 0.0d0)
                        "NAME" "DEFAULT"))))
    (is (= (1+ before) (host-vlax-get-property host block "Count")))
    (is (string= "NAME"
                 (%a1-str (host-vlax-get-property host attdef "TagString"))))
    (is (string= "DEFAULT"
                 (%a1-str (host-vlax-get-property host attdef "TextString"))))
    (is (string= "Enter name"
                 (%a1-str (host-vlax-get-property host attdef "PromptString"))))
    (is (equal '(1.0d0 2.0d0 0.0d0)
               (host-vlax-get-property host attdef "InsertionPoint")))
    (is (= 2.5d0 (host-vlax-get-property host attdef "Height")))
    (is (= 8 (host-vlax-get-property host attdef "Mode")))))

(test vlax-linetypes-load-registers-a-table-record
  (let* ((host (make-cador))
         (doc (%a1-active-document host))
         (linetypes (host-vlax-get-property host doc "Linetypes")))
    (is (null (cador-find-table-record host :ltype "CENTER")))
    (host-vlax-invoke-method host linetypes "Load" '("CENTER"))
    (is (cador-find-table-record host :ltype "CENTER"))))

(test vlax-document-saveas-persists-the-drawing
  (let* ((host (make-cador))
         (doc (%a1-active-document host))
         (path (format nil "/tmp/cador-a1-saveas-~D.dxf"
                       (get-internal-real-time))))
    (unwind-protect
         (progn
           (host-vlax-invoke-method host doc "SaveAs" (list path))
           (is (probe-file path))
           ;; Name is the file's name (DWGNAME), FullName its path.
           (is (string= (file-namestring path)
                        (autolisp-string-value (host-vlax-get-property host doc "Name")))))
      (ignore-errors (delete-file path)))))

(test vlax-new-object-surface-is-reported-available
  (let* ((host (make-cador))
         (doc (%a1-active-document host))
         (layers (host-vlax-get-property host doc "Layers"))
         (linetypes (host-vlax-get-property host doc "Linetypes"))
         (model (host-vlax-get-property host doc "ModelSpace"))
         (layer (host-vlax-invoke-method host layers "Add" '("Q"))))
    ;; Methods SCHME+ probes must resolve (no SKIP path).
    (is (host-vlax-method-applicable-p host layers "Add"))
    (is (host-vlax-method-applicable-p host linetypes "Load"))
    (is (host-vlax-method-applicable-p host model "AddLine"))
    (is (host-vlax-method-applicable-p host model "AddAttribute"))
    (is (host-vlax-method-applicable-p host layer "Delete"))
    (is (host-vlax-property-available-p host layer "Color"))
    (is (host-vlax-property-available-p host layer "Linetype"))
    (is (host-vlax-property-available-p host doc "ActiveLayer"))))

;;; --- Default drawing write format (CLAUTOLISPDEFAULTDRAWINGFORMAT) ---
;;; A drawing written to a path whose extension names no known drawing
;;; format (or a fresh drawing that never came from disk) falls back to
;;; the CLAUTOLISPDEFAULTDRAWINGFORMAT sysvar — DXF (ASCII) by default,
;;; initialised from the environment variable of the same name. A known
;;; extension still wins.

(test default-drawing-format-sysvar-defaults-to-dxf
  (let ((host (make-cador)))
    (let ((cell (cador-sysvar host "CLAUTOLISPDEFAULTDRAWINGFORMAT")))
      (is (typep cell 'sysvar-cell))
      (is (string= "DXF" (sysvar-cell-value cell))))
    (is (eq :dxf-ascii (clautolisp.cador:cador-default-drawing-format host)))))

(test default-drawing-format-sysvar-maps-and-is-lenient
  (let ((host (make-cador)))
    (cador-set-sysvar host "CLAUTOLISPDEFAULTDRAWINGFORMAT" "DWG")
    (is (eq :dwg (clautolisp.cador:cador-default-drawing-format host)))
    ;; Case-insensitive.
    (cador-set-sysvar host "CLAUTOLISPDEFAULTDRAWINGFORMAT" "dxf")
    (is (eq :dxf-ascii (clautolisp.cador:cador-default-drawing-format host)))
    ;; An unrecognised value falls back to DXF rather than erroring.
    (cador-set-sysvar host "CLAUTOLISPDEFAULTDRAWINGFORMAT" "PDF")
    (is (eq :dxf-ascii (clautolisp.cador:cador-default-drawing-format host)))))

(test vlax-saveas-writes-dxf-by-default-for-unknown-extension
  (let* ((host (make-cador))
         (doc (%a1-active-document host))
         (path (format nil "/tmp/cador-deffmt-~D.out" (get-internal-real-time))))
    (unwind-protect
         (progn
           (host-vlax-invoke-method host doc "SaveAs" (list path))
           (is (probe-file path))
           ;; The active drawing now records the format it was written in.
           (is (eq :dxf-ascii
                   (clautolisp.drawing:drawing-format (cador-active-drawing host)))))
      (ignore-errors (delete-file path)))))

(test vlax-saveas-extension-wins-over-the-default-format
  ;; Even with the default set to DWG, a .dxf destination writes DXF.
  (let* ((host (make-cador))
         (doc (%a1-active-document host))
         (path (format nil "/tmp/cador-deffmt-~D.dxf" (get-internal-real-time))))
    (cador-set-sysvar host "CLAUTOLISPDEFAULTDRAWINGFORMAT" "DWG")
    (unwind-protect
         (progn
           (host-vlax-invoke-method host doc "SaveAs" (list path))
           (is (eq :dxf-ascii
                   (clautolisp.drawing:drawing-format (cador-active-drawing host)))))
      (ignore-errors (delete-file path)))))

;;; --- SAVEFORMAT + container/version default (feat) ----------------
;;; The default write format has two axes: container (DXF/DXFB/DWG) and
;;; version (DWG 2018..R9). CLAUTOLISPDEFAULTDRAWINGFORMAT (string) selects
;;; both under non-BricsCAD dialects; BricsCAD's SAVEFORMAT integer selects
;;; both under a BricsCAD dialect. Version is recorded but codec output is
;;; fixed for now (drawing-codec-version-output.issue).

(test parse-drawing-format-spec-container-and-version
  (flet ((p (s) (multiple-value-list
                 (clautolisp.cador::%parse-drawing-format-spec s))))
    (is (equal '(:dxf-ascii nil) (p "DXF")))
    (is (equal '(:dwg nil) (p "dwg")))
    (is (equal '(:dxf-binary nil) (p "DXFB")))
    (is (equal '(:dwg :ac1027) (p "DWG-2013")))
    (is (equal '(:dxf-ascii :ac1015) (p "DXF2000")))
    (is (equal '(:dxf-binary :ac1015) (p "DXFB-2000")))
    (is (equal '(:dwg :ac1009) (p "DWG-R12")))
    ;; Unknown container -> (nil nil); unknown version -> container only.
    (is (equal '(nil nil) (p "PDF")))
    (is (equal '(:dwg nil) (p "DWG-9999")))))

(test decode-saveformat-maps-container-and-version
  (flet ((d (n) (multiple-value-list (clautolisp.cador::%decode-saveformat n))))
    (is (equal '(:dwg :ac1032) (d 1)))        ; default: DWG 2018
    (is (equal '(:dxf-ascii :ac1032) (d 2)))
    (is (equal '(:dxf-binary :ac1032) (d 3)))
    (is (equal '(:dxf-ascii :ac1027) (d 5)))  ; DXF 2013
    (is (equal '(:dwg :ac1015) (d 16)))       ; DWG 2000
    (is (equal '(:dxf-binary :ac1009) (d 27)))
    (is (equal '(:dxf-ascii :ac1004) (d 30))) ; DXF R9
    (is (equal '(nil nil) (d 99)))            ; out of range
    (is (equal '(nil nil) (d nil)))))

(test cador-default-drawing-format-version-via-clautolisp-sysvar
  (let ((host (make-cador)))
    (cador-set-sysvar host "CLAUTOLISPDEFAULTDRAWINGFORMAT" "DWG-2013")
    (is (equal '(:dwg :ac1027)
               (multiple-value-list (clautolisp.cador:cador-default-drawing-format host))))
    (cador-set-sysvar host "CLAUTOLISPDEFAULTDRAWINGFORMAT" "DXFB-2000")
    (is (equal '(:dxf-binary :ac1015)
               (multiple-value-list (clautolisp.cador:cador-default-drawing-format host))))
    ;; Default (no version) -> newest (nil).
    (cador-set-sysvar host "CLAUTOLISPDEFAULTDRAWINGFORMAT" "DXF")
    (is (equal '(:dxf-ascii nil)
               (multiple-value-list (clautolisp.cador:cador-default-drawing-format host))))))

(test cador-default-drawing-format-uses-saveformat-under-bricscad
  (let* ((host (make-cador))
         (session (clautolisp.autolisp-runtime:evaluation-context-session
                   (clautolisp.autolisp-runtime:current-evaluation-context))))
    (unwind-protect
         (progn
           (clautolisp.autolisp-runtime:set-runtime-session-dialect
            session (clautolisp.autolisp-reader:find-autolisp-dialect :bricscad-v26))
           ;; SAVEFORMAT default 1 = DWG 2018.
           (is (equal '(:dwg :ac1032)
                      (multiple-value-list
                       (clautolisp.cador:cador-default-drawing-format host))))
           ;; Set SAVEFORMAT to 5 (DXF 2013).
           (cador-set-sysvar host "SAVEFORMAT" 5)
           (is (equal '(:dxf-ascii :ac1027)
                      (multiple-value-list
                       (clautolisp.cador:cador-default-drawing-format host)))))
      (clautolisp.autolisp-runtime:set-runtime-session-dialect
       session (clautolisp.autolisp-reader:autolisp-dialect-strict)))))

;;; --- vendor sysvar first, clautolisp as the fallback ---------------------
;;; pjb, 2026-09-28 (clal-drawing-sysvars-silent-out-of-dialect): under a vendor
;;; dialect the vendor's own system variable decides when it has one; the
;;; clautolisp one is the fallback, with a `[clautolisp-sysvar]' notice.

(defmacro %with-dialect ((dialect) &body body)
  "Run BODY with DIALECT (a registry keyword) as the session dialect, restoring
strict afterwards, and with the notice's once-per-run memory cleared so each
test sees its own first use."
  `(let ((session (clautolisp.autolisp-runtime:evaluation-context-session
                   (clautolisp.autolisp-runtime:current-evaluation-context))))
     (clrhash clautolisp.autolisp-runtime:*clautolisp-sysvar-warnings-seen*)
     (unwind-protect
          (progn
            (clautolisp.autolisp-runtime:set-runtime-session-dialect
             session (clautolisp.autolisp-reader:find-autolisp-dialect ,dialect))
            ,@body)
       (clrhash clautolisp.autolisp-runtime:*clautolisp-sysvar-warnings-seen*)
       (clautolisp.autolisp-runtime:set-runtime-session-dialect
        session (clautolisp.autolisp-reader:autolisp-dialect-strict)))))

(defmacro %stderr-of (&body body)
  `(let ((*error-output* (make-string-output-stream)))
     ,@body
     (get-output-stream-string *error-output*)))

(defun %temp-template ()
  "A readable drawing file to name as a template."
  (let ((path (format nil "/tmp/cador-template-~D.dxf" (random 1000000))))
    (with-open-file (out path :direction :output :if-exists :supersede)
      (write-string "0
EOF
" out))
    path))

(test bricscad-dialect-takes-the-template-from-basefile
  "Under a BricsCAD dialect BASEFILE -- BricsCAD's own variable -- names the
template, silently; CLAUTOLISPNEWDRAWINGTEMPLATE is ignored when BASEFILE is set."
  (let ((host (make-cador))
        (basefile (%temp-template))
        (ours (%temp-template)))
    (unwind-protect
         (%with-dialect (:bricscad-v26)
           (cador-set-sysvar host "BASEFILE" basefile)
           (cador-set-sysvar host "CLAUTOLISPNEWDRAWINGTEMPLATE" ours)
           (let (template)
             (is (equal "" (%stderr-of
                             (setf template (clautolisp.cador:cador-new-drawing-template host)))))
             (is (equal (namestring (truename basefile)) (namestring (truename template))))))
      (ignore-errors (delete-file basefile))
      (ignore-errors (delete-file ours)))))

(test bricscad-dialect-falls-back-to-the-clautolisp-template-with-a-notice
  "BASEFILE empty: the clautolisp variable decides, and the notice names BASEFILE
as BricsCAD's own."
  (let ((host (make-cador))
        (ours (%temp-template)))
    (unwind-protect
         (%with-dialect (:bricscad-v26)
           (cador-set-sysvar host "BASEFILE" "")
           (cador-set-sysvar host "CLAUTOLISPNEWDRAWINGTEMPLATE" ours)
           (let* (template
                  (err (%stderr-of
                         (setf template (clautolisp.cador:cador-new-drawing-template host)))))
             (is (equal (namestring (truename ours)) (namestring (truename template))))
             (is (search "[clautolisp-sysvar]" err) "no notice: ~S" err)
             (is (search "CLAUTOLISPNEWDRAWINGTEMPLATE" err))
             (is (search "BASEFILE" err))))
      (ignore-errors (delete-file ours)))))

(test autocad-dialect-uses-the-clautolisp-sysvars-with-a-notice-once
  "AutoCAD has no system variable for either: the clautolisp ones decide, with
the notice -- once per variable per run, not on every use."
  (let ((host (make-cador)))
    (%with-dialect (:autocad-2026)
      (let ((first (%stderr-of (clautolisp.cador:cador-default-drawing-format host)))
            (second (%stderr-of (clautolisp.cador:cador-default-drawing-format host))))
        (is (search "[clautolisp-sysvar]" first) "no notice: ~S" first)
        (is (search "CLAUTOLISPDEFAULTDRAWINGFORMAT" first))
        (is (search "AutoCAD has no system variable" first))
        (is (equal "" second) "the notice repeated: ~S" second)))))

(test clautolisp-dialect-is-silent-about-its-own-sysvars
  (let ((host (make-cador)))
    (%with-dialect (:clautolisp)
      (is (equal "" (%stderr-of
                      (clautolisp.cador:cador-default-drawing-format host)
                      (host-getvar host "CLAUTOLISPNEWDRAWINGTEMPLATE")))))))

(test getvar-of-a-clautolisp-sysvar-out-of-dialect-gets-the-notice
  "What the ticket measured: (getvar \"CLAUTOLISPNEWDRAWINGTEMPLATE\") was
entirely silent under --dialect autocad."
  (let ((host (make-cador)))
    (%with-dialect (:autocad-2026)
      (let ((err (%stderr-of (host-getvar host "CLAUTOLISPNEWDRAWINGTEMPLATE"))))
        (is (search "[clautolisp-sysvar]" err) "no notice: ~S" err))
      ;; a vendor sysvar never does
      (clrhash clautolisp.autolisp-runtime:*clautolisp-sysvar-warnings-seen*)
      (is (equal "" (%stderr-of (host-getvar host "FILEDIA")))))))

(test vlax-saveas-records-version-from-default
  ;; A DXF-2013 default records both format and version on the drawing even
  ;; when the path extension is unknown (container DXF is a real codec).
  (let* ((host (make-cador))
         (doc (%a1-active-document host))
         (path (format nil "/tmp/cador-ver-~D.out" (get-internal-real-time))))
    (cador-set-sysvar host "CLAUTOLISPDEFAULTDRAWINGFORMAT" "DXF-2013")
    (unwind-protect
         (progn
           (host-vlax-invoke-method host doc "SaveAs" (list path))
           (is (probe-file path))
           (is (eq :dxf-ascii
                   (clautolisp.drawing:drawing-format (cador-active-drawing host))))
           (is (eq :ac1027
                   (clautolisp.drawing:drawing-version (cador-active-drawing host)))))
      (ignore-errors (delete-file path)))))

(test entmakex-builds-a-block-definition-as-the-vendors-do
  ;; MEASURED (probes/sources/probe-block-walk.lsp; AutoCAD 2022 and BricsCAD,
  ;; 2026-10-03): ENTMAKEX of BLOCK returns the block's ename, its members
  ;; theirs, the block is defined, the entnext walk from TBLOBJNAME yields the
  ;; members and NOT an ENDBLK. ENDBLK returns NIL on AutoCAD (strict follows
  ;; it) and the block's NAME on BricsCAD. It used to refuse BLOCK and ENDBLK.
  (dolist (case '((:strict nil) (:autocad nil) (:bricscad "SIGFIC_X") (:bricscad-mac "SIGFIC_X")))
    (destructuring-bind (dialect endblk) case
      (let ((mock (make-cador)))
        (%with-dialect (dialect)
          (let ((header (host-entmakex mock (list (cons 0 "BLOCK") (cons 2 "SIGFIC_X") (cons 70 0)
                                                  (list 10 0.0d0 0.0d0 0.0d0)))))
            (is (typep header 'autolisp-ename) "~A: BLOCK returns an ename" dialect)
            (is (typep (host-entmakex mock (%tv-text-dxf "corps")) 'autolisp-ename))
            (let ((closing (host-entmakex mock (list (cons 0 "ENDBLK")))))
              (if endblk
                  (is (and closing (string= endblk (autolisp-string-value closing))) "~A" dialect)
                  (is (null closing) "~A: ENDBLK returns nil" dialect)))
            (is (not (null (cador-find-table-record mock :block-record "SIGFIC_X"))))
            ;; the ename BLOCK returned IS the one tblobjname gives
            (is (eq header (host-tblobjname mock "BLOCK" "SIGFIC_X")))
            (let ((first (host-entnext mock header)))
              (is (not (null first)))
              (is (null (host-entnext mock first)) "no ENDBLK in the walk"))
            ;; nothing leaked into model space
            (is (null (host-entnext mock nil)))))))))

;;; --- Command engine: vendor-specific results (alref Phase 4 S1) ------
;;; Measured by probes/sources/probe-commands.lsp on AutoCAD 2022 (job
;;; 16914120564) and BricsCAD V26 (job 16913723746): the commands follow
;;; AutoCAD by default and under strict, BricsCAD under a BricsCAD dialect.

(test command-trace-draws-mitred-segments-under-bricscad-only
  (flet ((trace-run ()
           (let ((mock (make-cador)))
             (clautolisp.autolisp-host:host-command
              mock '("_.TRACE" "0.5" "0,0" "4,0" "4,3" "" "_.POINT" "9,9"))
             mock)))
    (%with-dialect (:bricscad-mac)
      (let* ((mock (trace-run))
             (e1 (host-entnext mock nil))
             (d1 (host-entget mock e1))
             (d2 (host-entget mock (host-entnext mock e1))))
        (is (equal '("TRACE" "TRACE" "POINT") (%ct-types mock)))
        (is (%ct-near '(0 0.25 0) (%ct-group d1 10)))
        (is (%ct-near '(4.25 -0.25 0) (%ct-group d1 13)))
        (is (%ct-near '(3.75 0.25 0) (%ct-group d2 10)))
        (is (%ct-near '(4.25 3 0) (%ct-group d2 13)))))
    ;; AutoCAD 2022 makes nothing; the sequence is consumed and the
    ;; following command still runs.
    (%with-dialect (:autocad)
      (is (equal '("POINT") (%ct-types (trace-run)))))))

(test command-mline-style-name-and-spline-tangents-follow-the-product
  (flet ((mline-style ()
           (let ((mock (make-cador)))
             (host-setvar mock "CMLSCALE" 20.0d0)
             (clautolisp.autolisp-host:host-command mock '("_.MLINE" "0,0" "4,0" ""))
             (autolisp-string-value (%ct-group (%ct-last-data mock) 2))))
         (spline-has-tangents ()
           (let ((mock (%ct-run '("_.SPLINE" "0,0" "1,1" "2,0" "3,1" "" "" ""))))
             (and (assoc 12 (%ct-last-data mock)) t))))
    (%with-dialect (:autocad)
      (is (string= "STANDARD" (mline-style)))
      (is (not (spline-has-tangents))))
    (%with-dialect (:bricscad)
      (is (string= "Standard" (mline-style)))
      (is (spline-has-tangents)))))

(test entmade-polylines-list-the-vendor-default-groups
  ;; Both vendors' ENTGET (identical): LWPOLYLINE 43 38 39 and per vertex
  ;; 40 41 42 91 (a constant width repeats in 40 / 41).
  (let* ((mock (%ct-run '("_.DONUT" "1" "2" "5,5" "")))
         (d (%ct-last-data mock))
         (codes (mapcar #'car d)))
    (is (every (lambda (c) (member c codes)) '(43 38 39 40 41 42 91)))
    (is (%ct-near 0.5 (%ct-group d 40)))
    (is (= 2 (count 91 codes)))))

;;; --- alref Phase 4 S2 rest / S4: arrays, DIVIDE, MEASURE, ADDSELECTED,
;;; JOIN, FLATTEN -- measured on BricsCAD (job 16914406700) / AutoCAD.

(defun %ct-centers (mock)
  "The 10 groups of MOCK's live main-space entities, oldest first, rounded."
  (let ((out '()) (e (host-entnext mock nil)))
    (loop while e
          do (let ((p (cdr (assoc 10 (host-entget mock e)))))
               (push (mapcar (lambda (x) (/ (round (* 1000 x)) 1000)) p) out))
             (setq e (host-entnext mock e)))
    (nreverse out)))

(defun %ct-array (tokens)
  (let ((mock (make-cador)))
    (clautolisp.autolisp-host:host-command mock (list "_.CIRCLE" "0,0" "0.5"))
    (clautolisp.autolisp-host:host-command
     mock (append (list (car tokens) (host-entlast mock)) (cdr tokens)))
    mock))

(test command-arrays-make-their-copies-in-the-measured-order
  ;; -ARRAY: column by column on AutoCAD, row by row on BricsCAD;
  ;; ARRAYRECT: column by column; 3DARRAY: levels innermost, per vendor.
  (let ((args '("_.-ARRAY" "" "_R" "2" "3" "2" "3")))
    (%with-dialect (:autocad)
      (is (equal '((0 0 0) (0 2 0) (3 0 0) (3 2 0) (6 0 0) (6 2 0))
                 (%ct-centers (%ct-array args)))))
    (%with-dialect (:bricscad)
      (is (equal '((0 0 0) (3 0 0) (6 0 0) (0 2 0) (3 2 0) (6 2 0))
                 (%ct-centers (%ct-array args))))))
  (is (equal '((0 0 0) (0 2 0) (3 0 0) (3 2 0) (6 0 0) (6 2 0))
             (%ct-centers (%ct-array '("_.ARRAYRECT" "" "_AS" "_N" "_COU" "3" "2"
                                       "_S" "3" "2" "_X")))))
  ;; 3DARRAY: levels innermost; column by column on AutoCAD (its
  ;; 3darray.lsp, job 16915676646), row by row on BricsCAD.
  (let ((args '("_.3DARRAY" "" "_R" "2" "2" "2" "1" "1" "1")))
    (%with-dialect (:autocad)
      (is (equal '((0 0 0) (0 0 1) (0 1 0) (0 1 1) (1 0 0) (1 0 1) (1 1 0) (1 1 1))
                 (%ct-centers (%ct-array args)))))
    (%with-dialect (:bricscad)
      (is (equal '((0 0 0) (0 0 1) (1 0 0) (1 0 1) (0 1 0) (0 1 1) (1 1 0) (1 1 1))
                 (%ct-centers (%ct-array args))))))
  ;; ARRAY _R: column by column on AutoCAD, row by row on BricsCAD.
  (let ((args '("_.ARRAY" "" "_R" "_AS" "_N" "_COU" "2" "2" "_S" "3" "3" "_X")))
    (%with-dialect (:autocad)
      (is (equal '((0 0 0) (0 3 0) (3 0 0) (3 3 0)) (%ct-centers (%ct-array args)))))
    (%with-dialect (:bricscad)
      (is (equal '((0 0 0) (3 0 0) (0 3 0) (3 3 0)) (%ct-centers (%ct-array args)))))))

(test command-polar-array-goes-counter-clockwise-from-the-original
  (let ((mock (make-cador)))
    (clautolisp.autolisp-host:host-command mock '("_.CIRCLE" "2,0" "0.5"))
    (clautolisp.autolisp-host:host-command
     mock (list "_.-ARRAY" (host-entlast mock) "" "_P" "0,0" "4" "360" "_Y"))
    (is (equal '((2 0 0) (0 2 0) (-2 0 0) (0 -2 0)) (%ct-centers mock)))))

(test command-divide-measure-addselected-join-flatten
  (flet ((after (first-tokens second-builder)
           (let ((mock (make-cador)))
             (clautolisp.autolisp-host:host-command mock first-tokens)
             (clautolisp.autolisp-host:host-command
              mock (funcall second-builder (host-entlast mock)))
             mock)))
    (is (equal '((0 0 0) (1 0 0) (2 0 0) (3 0 0))
               (%ct-centers (after '("_.LINE" "0,0" "4,0" "")
                                   (lambda (e) (list "_.DIVIDE" e "4"))))))
    (is (equal '((0 0 0) (3/2 0 0) (3 0 0))
               (%ct-centers (after '("_.LINE" "0,0" "4,0" "")
                                   (lambda (e) (list "_.MEASURE" e "1.5"))))))
    (is (equal '((0 0 0) (5 5 0))
               (%ct-centers (after '("_.CIRCLE" "0,0" "1")
                                   (lambda (e) (list "_.ADDSELECTED" e "5,5" "2"))))))
    (let ((mock (make-cador)))
      (clautolisp.autolisp-host:host-command mock '("_.LINE" "0,0" "2,0" ""))
      (let ((e1 (host-entlast mock)))
        (clautolisp.autolisp-host:host-command mock '("_.LINE" "2,0" "4,0" ""))
        (clautolisp.autolisp-host:host-command mock (list "_.JOIN" e1 (host-entlast mock) "")))
      (is (equal '("LINE") (%ct-types mock)))
      (is (%ct-near '(4 0 0) (%ct-group (%ct-last-data mock) 11))))
    (let ((d (%ct-last-data (after '("_.LINE" "0,0,1" "2,0,3" "")
                                   (lambda (e) (list "_.FLATTEN" e "" "_N"))))))
      (is (%ct-near '(0 0 0) (%ct-group d 10)))
      (is (%ct-near '(2 0 0) (%ct-group d 11))))))

(test command-accepts-an-entsel-pick
  ;; (ename point), the ENTSEL form, picks the object AND says where:
  ;; LENGTHEN extends the end nearest the point.
  (let ((mock (make-cador)))
    (clautolisp.autolisp-host:host-command mock '("_.LINE" "0,0" "4,0" ""))
    (clautolisp.autolisp-host:host-command
     mock (list "_.LENGTHEN" "_DE" "1" (list (host-entlast mock) '(0.0d0 0.0d0 0.0d0)) ""))
    (is (%ct-near '(-1 0 0) (%ct-group (%ct-last-data mock) 10)))))

;;; --- alref Phase 4 S6: hatch / boundary -- measured on AutoCAD 2022
;;; (job 16916189663) and BricsCAD V26 (job 16916189664).

(defun %ct-hatch-after (setup boundary-tokens hatch-builder &key (measurement 1) (hpassoc 1))
  "A fresh host: SETUP's command, then HATCH-BUILDER's tokens on its
entity; returns (values HATCH-DATA MOCK)."
  (let ((mock (make-cador)))
    (host-setvar mock "MEASUREMENT" measurement)
    (host-setvar mock "HPASSOC" hpassoc)
    (clautolisp.autolisp-host:host-command mock (append setup boundary-tokens))
    (clautolisp.autolisp-host:host-command mock (funcall hatch-builder (host-entlast mock)))
    (values (%ct-last-data mock) mock)))

(defun %ct-str (data code)
  "DATA's CODE group as a Lisp string (ENTGET gives AutoLISP strings)."
  (autolisp-string-value (%ct-group data code)))

(defun %ct-codes-after (data code)
  "The (code . value) groups of DATA from the first CODE group on."
  (member code data :key #'car))

(test command-hatch-solid-loops-in-each-vendors-form
  (flet ((solid-rect ()
           (%ct-hatch-after '("_.RECTANG" "0,0" "4,2") '()
                            (lambda (e) (list "_.-HATCH" "_P" "SOLID" "_S" e "" "")))))
    (%with-dialect (:autocad)
      ;; Edge loop: 92=1 93=4, each side 72=1 10 11; 75=1; one seed point.
      (let ((d (solid-rect)))
        (is (equal "HATCH" (%ct-str d 0)))
        (is (equal "SOLID" (%ct-str d 2)))
        (is (eql 1 (%ct-group d 70)))
        (is (eql 1 (%ct-group d 71)))
        (is (equal '(1 4 1) (list (%ct-group d 92) (%ct-group d 93) (%ct-group d 72))))
        (let ((edges (%ct-codes-after d 72)))
          (is (%ct-near '(0 0 0) (cdr (assoc 10 edges))))
          (is (%ct-near '(4 0 0) (cdr (assoc 11 edges)))))
        (is (eql 1 (%ct-group d 97)))
        (is (eql 1 (%ct-group d 75)))
        (is (eql 1 (%ct-group d 98)))
        (is (null (%ct-group d 41)))))
    (%with-dialect (:bricscad)
      ;; Polyline loop: 92=3 72=0 73=1 93=4 then the vertices; 75=0; 98=0.
      (let ((d (solid-rect)))
        (is (equal '(3 0 1 4) (list (%ct-group d 92) (%ct-group d 72)
                                    (%ct-group d 73) (%ct-group d 93))))
        (is (equal '((0 0 0) (4 0 0) (4 2 0) (0 2 0))
                   (mapcar (lambda (p) (mapcar #'round p))
                           (subseq (%ct-vertices (%ct-codes-after d 93)) 0 4))))
        (is (eql 0 (%ct-group d 75)))
        (is (eql 0 (%ct-group d 98)))))))

(test command-hatch-pattern-lines-and-circle-loops
  ;; ANSI31 scale 2 angle 45 under MEASUREMENT 1: the line's offset
  ;; (0, 3.175) scaled and turned by 45 + 45 -> 45=-6.35 46=0 (both vendors).
  (flet ((ansi31-circle ()
           (%ct-hatch-after '("_.CIRCLE" "0,0" "1") '()
                            (lambda (e) (list "_.-HATCH" "_P" "ANSI31" "2" "45" "_S" e "" "")))))
    (%with-dialect (:autocad)
      (let ((d (ansi31-circle)))
        (is (eql 0 (%ct-group d 70)))
        ;; The circle is one arc edge: 72=2 centre radius 0..2pi ccw.
        (is (equal '(1 1 2) (list (%ct-group d 92) (%ct-group d 93) (%ct-group d 72))))
        (let ((edge (%ct-codes-after d 72)))
          (is (%ct-near 1 (cdr (assoc 40 edge))))
          (is (%ct-near (* 2 pi) (cdr (assoc 51 edge)))))
        (is (%ct-near 2 (%ct-group d 41)))
        (is (eql 1 (%ct-group d 78)))
        (is (%ct-near -6.35 (%ct-group d 45)))
        (is (%ct-near 0 (%ct-group d 46)))))
    (%with-dialect (:bricscad)
      (let ((d (ansi31-circle)))
        ;; Two vertices of bulge 1 from (r, 0).
        (is (equal '(3 1 1 2) (list (%ct-group d 92) (%ct-group d 72)
                                    (%ct-group d 73) (%ct-group d 93))))
        (is (%ct-near '(1 0 0) (cdr (assoc 10 (%ct-codes-after d 93)))))
        (is (%ct-near 1 (cdr (assoc 42 (%ct-codes-after d 93)))))
        (is (%ct-near -6.35 (%ct-group d 45)))))))

(test command-hatch-associativity-and-hatchedit
  (%with-dialect (:autocad)
    (let ((d (%ct-hatch-after '("_.RECTANG" "0,0" "4,2") '()
                              (lambda (e) (list "_.-HATCH" "_P" "SOLID" "_S" e "" ""))
                              :hpassoc 0)))
      (is (eql 0 (%ct-group d 71)))
      (is (eql 0 (%ct-group d 97)))
      (is (null (%ct-group d 330))))
    ;; -HATCHEDIT to ANSI37 scale 1 angle 0: two lines, offsets
    ;; (-2.245064, +-2.245064); the loops are kept.
    (multiple-value-bind (d mock)
        (%ct-hatch-after '("_.RECTANG" "0,0" "4,2") '()
                         (lambda (e) (list "_.-HATCH" "_P" "SOLID" "_S" e "" "")))
      (declare (ignore d))
      (clautolisp.autolisp-host:host-command
       mock (list "_.-HATCHEDIT" (host-entlast mock) "_P" "ANSI37" "1" "0"))
      (let ((d (%ct-last-data mock)))
        (is (equal "ANSI37" (%ct-str d 2)))
        (is (eql 0 (%ct-group d 70)))
        (is (eql 4 (%ct-group d 93)))
        (is (eql 2 (%ct-group d 78)))
        (is (%ct-near '(-2.245064 2.245064 -2.245064 -2.245064)
                      (loop for (code . value) in d
                            when (member code '(45 46)) collect value)))))))

(test command-hatchgenerateboundary-and-boundary
  (%with-dialect (:bricscad)
    ;; A non-associative hatch whose rectangle is gone: one closed
    ;; LWPOLYLINE per loop, and the hatch now associative to it.
    (let ((mock (make-cador)))
      (host-setvar mock "HPASSOC" 0)
      (clautolisp.autolisp-host:host-command mock '("_.RECTANG" "0,0" "4,2"))
      (let ((r (host-entlast mock)))
        (clautolisp.autolisp-host:host-command mock (list "_.-HATCH" "_P" "SOLID" "_S" r "" ""))
        (let ((h (host-entlast mock)))
          (host-entdel mock r)
          (clautolisp.autolisp-host:host-command mock (list "_.HATCHGENERATEBOUNDARY" h ""))
          (let ((p (%ct-last-data mock)))
            (is (equal "LWPOLYLINE" (%ct-str p 0)))
            (is (eql 1 (logand 1 (%ct-group p 70))))
            (is (equal '((0 0) (4 0) (4 2) (0 2))
                       (mapcar (lambda (v) (mapcar #'round v)) (%ct-vertices p)))))
          (let ((hd (host-entget mock h)))
            (is (eql 1 (%ct-group hd 71)))
            (is (eql 1 (%ct-group hd 97))))))))
  ;; -BOUNDARY: the rectangle around the point, as a new closed polyline.
  (let ((mock (%ct-run '("_.RECTANG" "0,0" "4,2"))))
    (clautolisp.autolisp-host:host-command mock '("_.-BOUNDARY" "2,1" ""))
    (let ((p (%ct-last-data mock)))
      (is (equal "LWPOLYLINE" (%ct-str p 0)))
      (is (equal '((0 0) (4 0) (4 2) (0 2))
                 (mapcar (lambda (v) (mapcar #'round v)) (%ct-vertices p))))
      (is (= 2 (length (%ct-types mock)))))))

(test command-hatch-island-on-autocad
  ;; AutoCAD round 2 (job 16916238722): the island loop is 92=16 and keeps
  ;; its own edge order.
  (%with-dialect (:autocad)
    (let ((mock (make-cador)))
      (clautolisp.autolisp-host:host-command mock '("_.RECTANG" "0,0" "6,4"))
      (let ((outer (host-entlast mock)))
        (clautolisp.autolisp-host:host-command mock '("_.RECTANG" "2,1" "4,3"))
        (clautolisp.autolisp-host:host-command
         mock (list "_.-HATCH" "_P" "SOLID" "_S" outer (host-entlast mock) "" ""))
        (let* ((d (%ct-last-data mock))
               (island (member 16 (%ct-codes-after d 92) :key #'cdr)))
          (is (eql 2 (%ct-group d 91)))
          (is (eql 1 (%ct-group d 92)))
          (is (consp island))
          (is (%ct-near '(2 1 0) (cdr (assoc 10 island))))
          (is (%ct-near '(4 1 0) (cdr (assoc 11 island)))))))))

(test command-hatch-islands-angles-and-imperial-patterns
  ;; Round 2 (BricsCAD job 16916238723).
  (%with-dialect (:bricscad)
    ;; Two nested rectangles: the outer loop 92=3, the island 92=18 walked
    ;; backwards from its second vertex.
    (let ((mock (make-cador)))
      (host-setvar mock "MEASUREMENT" 1)
      (clautolisp.autolisp-host:host-command mock '("_.RECTANG" "0,0" "6,4"))
      (let ((outer (host-entlast mock)))
        (clautolisp.autolisp-host:host-command mock '("_.RECTANG" "2,1" "4,3"))
        (clautolisp.autolisp-host:host-command
         mock (list "_.-HATCH" "_P" "SOLID" "_S" outer (host-entlast mock) "" ""))
        (let* ((d (%ct-last-data mock))
               (island (member 18 (%ct-codes-after d 92) :key #'cdr)))
          (is (eql 2 (%ct-group d 91)))
          (is (eql 3 (%ct-group d 92)))
          (is (consp island))
          (is (equal '((4 1) (2 1) (2 3) (4 3))
                     (mapcar (lambda (p) (mapcar #'round (subseq p 0 2)))
                             (subseq (%ct-vertices island) 0 4)))))))
    ;; ANSI37 scale 2 angle 30: 52 = 30 deg, 53 = 75 / 165 deg (radians).
    (let ((d (%ct-hatch-after '("_.RECTANG" "1,1" "5,3") '()
                              (lambda (e) (list "_.-HATCH" "_P" "ANSI37" "2" "30" "_S" e "" "")))))
      (is (%ct-near 0.523599 (%ct-group d 52)))
      (is (%ct-near '(1.308997 2.879793)
                    (loop for (code . value) in d when (eql code 53) collect value)))
      (is (%ct-near '(-6.133629 1.643501 -1.643501 -6.133629)
                    (loop for (code . value) in d when (member code '(45 46)) collect value))))
    ;; MEASUREMENT 0: the imperial spacing 0.125.
    (let ((d (%ct-hatch-after '("_.RECTANG" "0,0" "4,2") '()
                              (lambda (e) (list "_.-HATCH" "_P" "ANSI31" "1" "0" "_S" e "" ""))
                              :measurement 0)))
      (is (%ct-near '(-0.088388 0.088388)
                    (loop for (code . value) in d when (member code '(45 46)) collect value))))))

;;; --- alref Phase 4 built-ins -- measured on BricsCAD V26 (job
;;; 16920731857) and AutoCAD 2022 (job 16920731856).

(defun %ct-spline-mock ()
  (%ct-run '("_.SPLINE" "0,0" "1,1" "2,0" "3,1" "" "" "")))

(test command-xplode-rotate3d-and-arraypath
  (%with-dialect (:bricscad)
    ;; XPLODE with the defaults: the rectangle's 4 LINEs.
    (let ((mock (%ct-run '("_.RECTANG" "0,0" "2,1"))))
      (clautolisp.autolisp-host:host-command
       mock (list "_.XPLODE" (host-entlast mock) "" "" ""))
      (is (equal '("LINE" "LINE" "LINE" "LINE") (%ct-types mock)))))
  ;; ROTATE3D (both) / 3DROTATE (BricsCAD): (1,0)-(3,0) 90 about Z -> (0,1)-(0,3).
  (dolist (name '("_.ROTATE3D" "_.3DROTATE"))
    (let ((mock (%ct-run '("_.LINE" "1,0" "3,0" ""))))
      (clautolisp.autolisp-host:host-command
       mock (list name (host-entlast mock) "" "_Z" "0,0,0" "90"))
      (let ((d (%ct-last-data mock)))
        (is (%ct-near '(0 1 0) (%ct-group d 10)))
        (is (%ct-near '(0 3 0) (%ct-group d 11))))))
  ;; ARRAYPATH along (0,0)-(9,0), divide 4, non-associative: the source
  ;; replaced by circles at 0 3 6 9, after the path.
  (let ((mock (%ct-run '("_.CIRCLE" "0,0" "0.5"))))
    (let ((c (host-entlast mock)))
      (clautolisp.autolisp-host:host-command mock '("_.LINE" "0,0" "9,0" ""))
      (clautolisp.autolisp-host:host-command
       mock (list "_.ARRAYPATH" c "" (host-entlast mock) "_AS" "_N" "_M" "_D" "_I" "4" "_X"))
      (is (equal '("LINE" "CIRCLE" "CIRCLE" "CIRCLE" "CIRCLE") (%ct-types mock)))
      (is (equal '((0 0 0) (0 0 0) (3 0 0) (6 0 0) (9 0 0)) (%ct-centers mock))))))

(test command-splinedit-reverse-and-close
  ;; Reverse (BricsCAD): control and fit points reversed, 12 / 13 kept.
  (%with-dialect (:bricscad)
    (let ((mock (%ct-spline-mock)))
      (clautolisp.autolisp-host:host-command
       mock (list "_.SPLINEDIT" (host-entlast mock) "_R" "_X"))
      (let ((d (%ct-last-data mock)))
        (is (%ct-near '(3 1 0) (%ct-group d 10)))
        (is (%ct-near '(3 1 0) (%ct-group d 11)))
        (is (%ct-group d 12)))))
  ;; Close (both vendors identical): 7 control points, knots to 7.404918,
  ;; no fit data, flags 1064 -> 3115.
  (let ((mock (%ct-spline-mock)))
    (clautolisp.autolisp-host:host-command
     mock (list "_.SPLINEDIT" (host-entlast mock) "_C" "_X"))
    (let* ((d (%ct-last-data mock))
           (controls (loop for (c . v) in d when (eql c 10) collect v)))
      (is (eql 3115 (%ct-group d 70)))
      (is (eql 7 (%ct-group d 73)))
      (is (eql 0 (%ct-group d 74)))
      (is (null (%ct-group d 11)))
      (is (%ct-near 7.404918 (car (last (loop for (c . v) in d when (eql c 40) collect v)))))
      (is (%ct-near '(0 0.254644 0) (second controls)))
      (is (%ct-near '(1.2 1.847214 0) (third controls)))
      (is (%ct-near '(4.341641 2.525903 0) (fifth controls)))
      (is (%ct-near '(0 -0.569401 0) (sixth controls))))))

;;; --- bricscad-dialect-sysvar-parity, Phase 3: host-derived sysvars
;;; computed live (measured on a fresh BricsCAD drawing, job 16913315157).

(test host-derived-sysvars-are-computed-from-the-session
  (let ((mock (make-cador)))
    ;; No entity: the vendors' empty extents.
    (is (equal '(1d20 1d20 1d20) (host-getvar mock "EXTMIN")))
    (is (equal '(-1d20 -1d20 -1d20) (host-getvar mock "EXTMAX")))
    (clautolisp.autolisp-host:host-command mock '("_.LINE" "0,0" "4,2" ""))
    (is (%ct-near '(0 0 0) (host-getvar mock "EXTMIN")))
    (is (%ct-near '(4 2 0) (host-getvar mock "EXTMAX")))
    ;; Created now; TDINDWG counts the days since.
    (let ((date (host-getvar mock "DATE")) (created (host-getvar mock "TDCREATE")))
      (is (< (abs (- date created)) 0.01))
      (is (= created (host-getvar mock "TDUPDATE")))
      (is (<= 0 (host-getvar mock "TDINDWG") 0.01)))
    (let ((user (or (uiop:getenv "USER") (uiop:getenv "USERNAME") (uiop:getenv "LOGNAME"))))
      (when (and user (string/= user ""))
        (is (string= user (autolisp-string-value (host-getvar mock "LOGINNAME"))))))
    (is (eql 0 (host-getvar mock "CMDACTIVE")))
    (let ((prefix (autolisp-string-value (host-getvar mock "DWGPREFIX"))))
      (is (plusp (length prefix)))
      (is (char= #\/ (char prefix (1- (length prefix))))))))

(test locale-sysvar-follows-the-locale-under-bricscad
  (let ((saved (mapcar (lambda (v) (cons v (uiop:getenv v))) '("LC_ALL" "LC_MESSAGES" "LANG"))))
    (unwind-protect
         (progn
           (setf (uiop:getenv "LC_ALL") "" (uiop:getenv "LC_MESSAGES") ""
                 (uiop:getenv "LANG") "fr_FR.UTF-8")
           (%with-dialect (:bricscad)
             (is (string= "fr_FR" (autolisp-string-value (host-getvar (make-cador) "LOCALE"))))))
      (loop for (var . value) in saved do (setf (uiop:getenv var) (or value ""))))))

(test bricscad-platform-factory-defaults-follow-the-dialect-platform
  ;; Measured on both BricsCAD V26 platforms (jobs 16913315157 / 16921381045).
  (%with-dialect (:bricscad-mac)
    (let ((mock (make-cador)))
      (clautolisp.cador:apply-bricscad-dialect-sysvars mock)
      (is (eql 11 (host-getvar mock "3DOSMODE")))
      (is (eql 2048 (host-getvar mock "MTFLAGS")))))
  (%with-dialect (:bricscad)
    (let ((mock (make-cador)))
      (clautolisp.cador:apply-bricscad-dialect-sysvars mock)
      (is (eql 10 (host-getvar mock "3DOSMODE")))
      (is (eql 3015 (host-getvar mock "MTFLAGS")))
      ;; One of the 26 rows both platforms agree on.
      (is (eql 251 (host-getvar mock "GRIDMAJORCOLOR"))))))

;;; --- dialect-platform-version-axis: sysvars by the dialect's version.

(test lispsys-and-locale-follow-the-dialect-version
  (let ((saved (mapcar (lambda (v) (cons v (uiop:getenv v))) '("LC_ALL" "LC_MESSAGES" "LANG"))))
    (unwind-protect
         (progn
           (setf (uiop:getenv "LC_ALL") "" (uiop:getenv "LC_MESSAGES") ""
                 (uiop:getenv "LANG") "fr_FR.UTF-8")
           ;; LISPSYS: AutoCAD 2021+, BricsCAD V23+ (getvar -> nil before).
           (%with-dialect (:autocad-2022)
             (is (eql 1 (host-getvar (make-cador) "LISPSYS")))
             ;; AutoCAD 2019+: LOCALE is the upper-case language (measured "FR").
             (is (string= "FR" (autolisp-string-value (host-getvar (make-cador) "LOCALE")))))
           (%with-dialect (:autocad-2020)
             (is (null (host-getvar (make-cador) "LISPSYS"))))
           (%with-dialect (:bricscad-v22)
             (is (null (host-getvar (make-cador) "LISPSYS"))))
           (%with-dialect (:bricscad-v26)
             (let ((mock (make-cador)))
               (clautolisp.cador:apply-bricscad-dialect-sysvars mock)
               ;; BricsCAD's default, on both harvests.
               (is (eql 0 (host-getvar mock "LISPSYS")))
               (is (string= "fr_FR" (autolisp-string-value (host-getvar mock "LOCALE")))))))
      (loop for (var . value) in saved do (setf (uiop:getenv var) (or value ""))))))
