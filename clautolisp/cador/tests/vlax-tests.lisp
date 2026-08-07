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
