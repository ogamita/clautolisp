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

(defun %register-mock-com-object (host object)
  "Store OBJECT in HOST's com-objects table (build-mock-com-object
allocates but does not register). Returns OBJECT."
  (setf (gethash (mock-com-object-id object) (mock-host-com-objects host))
        object))

(defmethod host-vlax-get-acad-object ((host mock-host))
  "Return the singleton AutoCAD.Application VLA-OBJECT, creating it — and
its ActiveDocument — on first call. Object-valued properties are stored
as VLA-OBJECT references so vla-get-activedocument yields a usable
document. Repeated calls return the same application object."
  (let* ((cached-id (mock-host-acad-application-id host))
         (cached (and cached-id (mock-host-find-com-object host cached-id))))
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
          (setf (mock-host-acad-application-id host) (mock-com-object-id app))
          (com-object->vla app)))))

;;; --- Entity <-> VLA-object bridge + introspection ----------------

(defmethod host-vlax-ename->vla-object ((host mock-host) ename)
  "Wrap entity ENAME in an identity-stable COM object (progid
\"AutoCAD.Entity\") carrying its hex handle, so vlax-vla-object->ename
round-trips and vlax-curve-* can recover the entity."
  (let* ((handle (ename->handle ename 'vlax-ename->vla-object))
         (cached-id (gethash handle (mock-host-entity-vla-map host)))
         (cached (and cached-id (mock-host-find-com-object host cached-id))))
    (if (and cached (not (mock-com-object-released-p cached)))
        (com-object->vla cached)
        (let ((obj (%register-mock-com-object
                    host (make-mock-com-object :progid "AutoCAD.Entity"
                                               :backing-ename handle))))
          (setf (gethash handle (mock-host-entity-vla-map host))
                (mock-com-object-id obj))
          (com-object->vla obj)))))

(defmethod host-vlax-vla-object->ename ((host mock-host) vla)
  (let* ((obj (resolve-vla-object host vla 'vlax-vla-object->ename))
         (handle (mock-com-object-backing-ename obj)))
    (if handle
        (handle->ename host handle)
        (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
         :not-an-entity-vla-object
         "vlax-vla-object->ename: ~A is not an entity-backed VLA-OBJECT."
         (mock-com-object-progid obj)))))

(defmethod host-vlax-erased-p ((host mock-host) vla)
  ;; Do NOT go through resolve-vla-object: a released object must report
  ;; erased = T, not signal :released-vla-object.
  (ensure-vla-object vla 'vlax-erased-p)
  (let* ((id (clautolisp.autolisp-runtime:autolisp-vla-object-value vla))
         (obj (mock-host-find-com-object host id)))
    (cond
      ((null obj) t)                    ; unknown -> gone
      ((mock-com-object-backing-ename obj)
       (null (safe-find-entity (mock-host-active-drawing host)
                               (mock-com-object-backing-ename obj))))
      (t (mock-com-object-released-p obj)))))

(defmethod host-vlax-describe-object ((host mock-host) vla)
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

(defmethod host-vlax-ldata-put ((host mock-host) dictionary key value private)
  (let* ((ns (%ldata-namespace host dictionary private 'vlax-ldata-put))
         (k (%ldata-key key 'vlax-ldata-put))
         (store (mock-host-ldata-store host))
         (alist (gethash ns store))
         (cell (assoc k alist :test #'string=)))
    (if cell
        (setf (cdr cell) value)
        (setf (gethash ns store) (append alist (list (cons k value)))))
    value))

(defmethod host-vlax-ldata-get ((host mock-host) dictionary key default private)
  (let* ((ns (%ldata-namespace host dictionary private 'vlax-ldata-get))
         (k (%ldata-key key 'vlax-ldata-get))
         (cell (assoc k (gethash ns (mock-host-ldata-store host)) :test #'string=)))
    (if cell (cdr cell) default)))

(defmethod host-vlax-ldata-delete ((host mock-host) dictionary key private)
  (let* ((ns (%ldata-namespace host dictionary private 'vlax-ldata-delete))
         (k (%ldata-key key 'vlax-ldata-delete))
         (store (mock-host-ldata-store host))
         (alist (gethash ns store)))
    (when (assoc k alist :test #'string=)
      (setf (gethash ns store) (remove k alist :key #'car :test #'string=))
      t)))

(defmethod host-vlax-ldata-list ((host mock-host) dictionary private)
  (let ((ns (%ldata-namespace host dictionary private 'vlax-ldata-list)))
    (mapcar (lambda (pair) (cons (car pair) (cdr pair)))
            (gethash ns (mock-host-ldata-store host)))))

;;; --- Command registration + async expression queue --------------

(defmethod host-vlax-add-cmd ((host mock-host) global-name function local-name flags)
  (declare (ignore flags))
  (push (list :cmd global-name (or local-name global-name) function)
        (mock-host-registered-commands host))
  global-name)

(defmethod host-vlax-remove-cmd ((host mock-host) global-name)
  (let* ((cmds (mock-host-registered-commands host))
         (kept (if (eq global-name t)
                   (remove :cmd cmds :key #'car)
                   (remove-if (lambda (e)
                                (and (eq (car e) :cmd)
                                     (string-equal (second e) global-name)))
                              cmds))))
    (setf (mock-host-registered-commands host) kept)
    (and (< (length kept) (length cmds)) t)))

(defmethod host-vlax-queueexpr ((host mock-host) string)
  (push (list :queue string) (mock-host-registered-commands host))
  nil)
