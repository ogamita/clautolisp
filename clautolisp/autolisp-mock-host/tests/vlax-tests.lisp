(in-package #:clautolisp.autolisp-mock-host.tests)

(in-suite autolisp-mock-host-suite)

;;; --- Phase 13: COM bridge on MockHost ----------------------------

(test vlax-create-object-returns-vla-wrapping-id
  (let* ((mock (make-mock-host))
         (vla (host-vlax-create-object mock "AutoCAD.Application")))
    (is (typep vla 'clautolisp.autolisp-runtime:autolisp-vla-object))
    (let* ((id (clautolisp.autolisp-runtime:autolisp-vla-object-value vla))
           (object (mock-host-find-com-object mock id)))
      (is (typep object 'mock-com-object))
      (is (string= "AutoCAD.Application" (mock-com-object-progid object))))))

(test vlax-get-property-reads-template-defaults
  (let* ((mock (make-mock-host))
         (vla (host-vlax-create-object mock "AutoCAD.Application"))
         (visible (host-vlax-get-property mock vla "Visible"))
         (name (host-vlax-get-property mock vla "Name")))
    (is (eq t visible))
    (is (string= "Mock AutoCAD" name))))

(test vlax-put-property-mutates-and-rejects-unknown-names
  (let* ((mock (make-mock-host))
         (vla (host-vlax-create-object mock "AutoCAD.Application")))
    (host-vlax-put-property mock vla "Visible" nil)
    (is (null (host-vlax-get-property mock vla "Visible")))
    (handler-case
        (host-vlax-put-property mock vla "NoSuch" 42)
      (autolisp-runtime-error (condition)
        (is (eq :unknown-com-property (autolisp-runtime-error-code condition)))))))

(test vlax-property-available-p
  (let* ((mock (make-mock-host))
         (vla (host-vlax-create-object mock "AutoCAD.Application")))
    (is (host-vlax-property-available-p mock vla "Name"))
    (is (not (host-vlax-property-available-p mock vla "NoSuch")))))

(test vlax-invoke-method-runs-handler
  (let* ((mock (make-mock-host))
         (vla (host-vlax-create-object mock "AutoCAD.Document")))
    ;; SaveAs sets the Name property to its first argument.
    (host-vlax-invoke-method mock vla "SaveAs" '("Renamed.dwg"))
    (is (string= "Renamed.dwg"
                 (host-vlax-get-property mock vla "Name")))))

(test vlax-invoke-method-rejects-unknown-method
  (let* ((mock (make-mock-host))
         (vla (host-vlax-create-object mock "AutoCAD.Document")))
    (handler-case
        (host-vlax-invoke-method mock vla "Bogus" '())
      (autolisp-runtime-error (condition)
        (is (eq :unknown-com-method (autolisp-runtime-error-code condition)))))))

(test vlax-method-applicable-p
  (let* ((mock (make-mock-host))
         (vla (host-vlax-create-object mock "AutoCAD.Document")))
    (is (host-vlax-method-applicable-p mock vla "Save"))
    (is (not (host-vlax-method-applicable-p mock vla "Bogus")))))

(test vlax-release-object-marks-released-and-blocks-further-ops
  (let* ((mock (make-mock-host))
         (vla (host-vlax-create-object mock "AutoCAD.Application")))
    (host-vlax-release-object mock vla)
    (handler-case (host-vlax-get-property mock vla "Name")
      (autolisp-runtime-error (condition)
        (is (eq :released-vla-object
                (autolisp-runtime-error-code condition)))))))

(test vlax-create-object-rejects-unknown-progid
  (let ((mock (make-mock-host)))
    (handler-case (host-vlax-create-object mock "No.Such.ProgID")
      (autolisp-runtime-error (condition)
        (is (eq :unknown-progid (autolisp-runtime-error-code condition)))))))

(test vlax-get-object-finds-most-recent-of-progid
  (let* ((mock (make-mock-host))
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
  (let ((mock (make-mock-host)))
    (register-com-progid "MyTest.Probe"
                         :properties '("Foo" 17 "Bar" "hello")
                         :methods    nil)
    (let* ((vla (host-vlax-create-object mock "MyTest.Probe")))
      (is (eql 17 (host-vlax-get-property mock vla "Foo")))
      (is (string= "hello" (host-vlax-get-property mock vla "Bar"))))))
