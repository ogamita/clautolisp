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
             (gethash "IsXRef" props)     nil)
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

(defun %block-entity-handles (host name)
  "Hex handles of the live entities owned by block NAME, oldest first.
Model-space entities are those with a NIL owner (plus any explicitly
owned by *Model_Space); other blocks own by name."
  (let ((model-p (string-equal name "*Model_Space")))
    (loop for handle in (reverse (cador-creation-order host))
          for entity = (cador-find-entity-by-handle host handle)
          when (and entity
                    (let ((owner (entity-handle-block entity)))
                      (if owner
                          (string-equal owner name)
                          model-p)))
            collect handle)))

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
            (string-equal name "Delete"))
       (values (%block-delete host object) t))
      (t (values nil nil)))))

(defun %collection-fallback-method-p (object name)
  "Whether %COLLECTION-FALLBACK-METHOD would handle NAME on OBJECT."
  (let ((kind (mock-com-object-collection-kind object)))
    (or (and (mock-com-object-collection-p object) (string-equal name "Item"))
        (and (member kind '(:blocks :layers)) (string-equal name "Add") t)
        (and (consp kind) (eq (car kind) :block-entities)
             (string-equal name "Delete")))))

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
         (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
          :unknown-com-property
          "VLA-OBJECT ~A has no property named ~A."
          (mock-com-object-progid object) string))))))

(defmethod host-vlax-put-property ((host cador) vla name value)
  (let* ((object (resolve-vla-object host vla 'vlax-put-property))
         (string (ensure-property-name-string name 'vlax-put-property)))
    (unless (nth-value 1 (gethash string (mock-com-object-properties object)))
      (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
       :unknown-com-property
       "VLA-OBJECT ~A has no property named ~A."
       (mock-com-object-progid object) string))
    (setf (gethash string (mock-com-object-properties object)) value)
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
             (string-equal string "Count")))))

(defmethod host-vlax-method-applicable-p ((host cador) vla name)
  (let* ((object (resolve-vla-object host vla 'vlax-method-applicable-p))
         (string (ensure-property-name-string name 'vlax-method-applicable-p)))
    (or (and (gethash string (mock-com-object-methods object)) t)
        (%collection-fallback-method-p object string))))

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
