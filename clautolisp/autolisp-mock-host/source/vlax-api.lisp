(in-package #:clautolisp.autolisp-mock-host)

;;;; Visual LISP COM-bridge HAL methods on MockHost (Phase 13).
;;;;
;;;; Implements: host-vlax-create-object, host-vlax-get-object,
;;;; host-vlax-release-object, host-vlax-get-property,
;;;; host-vlax-put-property, host-vlax-invoke-method,
;;;; host-vlax-property-available-p, host-vlax-method-applicable-p.
;;;;
;;;; The AutoLISP-visible VLA-OBJECT (autolisp-runtime:autolisp-vla-object)
;;;; wraps the host-allocated COM-object id; the host stores the
;;;; mock-com-object struct in mock-host-com-objects keyed on that
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
         (object (mock-host-find-com-object host id)))
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

;;; --- Method definitions ------------------------------------------

(defmethod host-vlax-create-object ((host mock-host) progid)
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
                        (mock-host-com-objects host))
               object)
         (com-object->vla object))))))

(defmethod host-vlax-get-object ((host mock-host) progid)
  ;; "Get" rather than "create": find the most recently-created
  ;; non-released instance of this ProgID, or nil.
  (let ((id-string (ensure-progid-string progid 'vlax-get-object))
        (best nil))
    (maphash (lambda (id object)
               (declare (ignore id))
               (when (and (not (mock-com-object-released-p object))
                          (string-equal (mock-com-object-progid object) id-string))
                 (setf best object)))
             (mock-host-com-objects host))
    (and best (com-object->vla best))))

(defmethod host-vlax-release-object ((host mock-host) vla)
  (let ((object (resolve-vla-object host vla 'vlax-release-object)))
    (setf (mock-com-object-released-p object) t)
    nil))

(defmethod host-vlax-get-property ((host mock-host) vla name)
  (let* ((object (resolve-vla-object host vla 'vlax-get-property))
         (string (ensure-property-name-string name 'vlax-get-property)))
    (multiple-value-bind (value present-p)
        (gethash string (mock-com-object-properties object))
      (cond
        ((not present-p)
         (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
          :unknown-com-property
          "VLA-OBJECT ~A has no property named ~A."
          (mock-com-object-progid object) string))
        (t value)))))

(defmethod host-vlax-put-property ((host mock-host) vla name value)
  (let* ((object (resolve-vla-object host vla 'vlax-put-property))
         (string (ensure-property-name-string name 'vlax-put-property)))
    (unless (nth-value 1 (gethash string (mock-com-object-properties object)))
      (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
       :unknown-com-property
       "VLA-OBJECT ~A has no property named ~A."
       (mock-com-object-progid object) string))
    (setf (gethash string (mock-com-object-properties object)) value)
    value))

(defmethod host-vlax-invoke-method ((host mock-host) vla name args)
  (let* ((object (resolve-vla-object host vla 'vlax-invoke-method))
         (string (ensure-property-name-string name 'vlax-invoke-method))
         (handler (gethash string (mock-com-object-methods object))))
    (cond
      ((null handler)
       (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
        :unknown-com-method
        "VLA-OBJECT ~A has no method named ~A."
        (mock-com-object-progid object) string))
      (t (funcall handler host object args)))))

(defmethod host-vlax-property-available-p ((host mock-host) vla name)
  (let* ((object (resolve-vla-object host vla 'vlax-property-available-p))
         (string (ensure-property-name-string name 'vlax-property-available-p)))
    (and (nth-value 1 (gethash string (mock-com-object-properties object))) t)))

(defmethod host-vlax-method-applicable-p ((host mock-host) vla name)
  (let* ((object (resolve-vla-object host vla 'vlax-method-applicable-p))
         (string (ensure-property-name-string name 'vlax-method-applicable-p)))
    (and (gethash string (mock-com-object-methods object)) t)))
