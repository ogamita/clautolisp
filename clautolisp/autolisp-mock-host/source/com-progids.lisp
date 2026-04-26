(in-package #:clautolisp.autolisp-mock-host)

;;;; COM ProgID registry for MockHost (Phase 13).
;;;;
;;;; Each ProgID maps to a TEMPLATE that vlax-create-object copies
;;;; into a new mock-com-object: a property alist (name -> initial
;;;; value) and a method alist (name -> handler closure). Programs
;;;; running against the mock host can introspect AutoCAD's COM
;;;; surface without a real CAD process.
;;;;
;;;; The seed registry covers a small set of ProgIDs commonly
;;;; consulted by AutoLISP programs at startup. It is *not*
;;;; exhaustive; user code may extend it via REGISTER-COM-PROGID.

(defvar *com-progids* (make-hash-table :test #'equalp)
  "Hash-table mapping a ProgID string (case-insensitive) to a
plist describing the object's defaults: (:properties ALIST
:methods ALIST). vlax-create-object copies a fresh per-instance
hash-table from each ALIST.")

(defun register-com-progid (progid &key properties methods)
  "Install (or replace) the template for PROGID in *com-progids*."
  (setf (gethash progid *com-progids*)
        (list :properties properties :methods methods))
  progid)

(defun mock-host-allocate-com-id (host)
  (let ((n (mock-host-next-com-counter host)))
    (incf (mock-host-next-com-counter host))
    (format nil "COM-~D" n)))

(defun build-mock-com-object (host progid)
  "Construct a fresh mock-com-object from the *com-progids*
template for PROGID. Returns nil if PROGID is unknown."
  (let ((template (gethash progid *com-progids*)))
    (and template
         (let* ((id (mock-host-allocate-com-id host))
                (object (make-mock-com-object :id id :progid progid))
                (props (mock-com-object-properties object))
                (methods (mock-com-object-methods object)))
           (loop for (name value) on (getf template :properties) by #'cddr
                 do (setf (gethash name props) value))
           (loop for (name handler) on (getf template :methods) by #'cddr
                 do (setf (gethash name methods) handler))
           object))))

(defun mock-host-find-com-object (host vla-id)
  (gethash vla-id (mock-host-com-objects host)))

;;; --- Default templates --------------------------------------------

(defun populate-default-com-progids ()
  "Seed *com-progids* with a conservative subset of AutoCAD's COM
type-library ProgIDs. Idempotent."
  ;; AutoCAD.Application — top-level application object.
  (register-com-progid
   "AutoCAD.Application"
   :properties (list "Name"            "Mock AutoCAD"
                     "Visible"         t
                     "Caption"         "Mock AutoCAD"
                     "Version"         "Mock 0.1"
                     "Path"            ""
                     "FullName"        "Mock AutoCAD"
                     "ActiveDocument"  nil
                     "Documents"       nil
                     "Preferences"     nil)
   :methods    (list "Quit" (lambda (host object args)
                              (declare (ignore host args))
                              (setf (mock-com-object-released-p object) t)
                              nil)
                     "ListArx" (lambda (host object args)
                                 (declare (ignore host object args))
                                 '())))
  ;; AutoCAD.Document — drawing document.
  (register-com-progid
   "AutoCAD.Document"
   :properties (list "Name"             "Drawing.dwg"
                     "FullName"         "Drawing.dwg"
                     "Path"             ""
                     "Saved"            t
                     "ReadOnly"         nil
                     "ModelSpace"       "ModelSpace"
                     "PaperSpace"       "PaperSpace"
                     "Layers"           nil
                     "Linetypes"        nil
                     "TextStyles"       nil
                     "Application"      nil)
   :methods    (list "Close"   (lambda (host object args)
                                 (declare (ignore host args))
                                 (setf (mock-com-object-released-p object) t)
                                 nil)
                     "Save"    (lambda (host object args)
                                 (declare (ignore host object args))
                                 nil)
                     "SaveAs"  (lambda (host object args)
                                 (declare (ignore host))
                                 (let ((name (first args)))
                                   (setf (gethash "Name"
                                                  (mock-com-object-properties object))
                                         name)
                                   nil))))
  ;; A minimal Layers collection so simple introspection works.
  (register-com-progid
   "AutoCAD.Layers"
   :properties (list "Count" 1)
   :methods    (list "Item" (lambda (host object args)
                              (declare (ignore host object args))
                              nil)))
  *com-progids*)

;; Populate at load time so MockHost users get the defaults
;; without an extra step.
(eval-when (:load-toplevel :execute)
  (populate-default-com-progids))
