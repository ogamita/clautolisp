(in-package #:clautolisp.cador)

;;;; Named-object-dictionary, xrecord and REGAPP HAL methods on
;;;; cador — the AutoLISP adapter over the pure-CL dictionary /
;;;; appid layer in clautolisp.drawing (dictionary.lisp).
;;;;
;;;; Dictionaries and xrecords are stored in the ACTIVE-DRAWING's
;;;; ENTITIES table as handle-bearing entities (see dictionary.lisp),
;;;; so DICTSEARCH / DICTNEXT return the same entget-style
;;;; (-1 . ename)-headed group-code list that ENTGET produces, and the
;;;; object enames feed straight back into ENTGET / ENTMOD / ENTDEL.

;;; --- Helpers ----------------------------------------------------

(defun %dict-member-view (host member-handle)
  "The entget-style AutoLISP view of the dictionary member stored under
MEMBER-HANDLE, or NIL if it no longer exists. XData is suppressed, like
plain ENTGET / DICTSEARCH. HOST supplies the ename intern cache."
  (let ((entity (safe-find-entity (cador-active-drawing host) member-handle)))
    (and entity (entity->al-view host entity))))

(defun %require-dict-handle (host dict-ename operator-name)
  "Resolve DICT-ENAME to a live dictionary hex handle, or NIL when it
is not a dictionary. Signals :invalid-ename only when DICT-ENAME is not
an ename at all."
  (let* ((handle (ename->handle dict-ename operator-name host))
         (drawing (cador-active-drawing host)))
    (and (clautolisp.drawing:find-dictionary drawing handle) handle)))

;;; --- Method definitions -----------------------------------------

;;; --- The named-object dictionary of a fresh drawing -------------
;;;
;;; cador-entget-subclass-layout-and-record-pointers, item 5. Measured
;;; (entget-pointers section 11; BricsCAD V26 macOS job 17439813492, AutoCAD
;;; 2022 job 17439813490): a new drawing's NOD holds the entries below, per
;;; product (the PRORD<n> / PRPTR<n> XRECORDs it also lists are the probe's
;;; own, filed by its sections 2 and 10). BricsCAD dialects get BricsCAD's
;;; set, every other dialect AutoCAD's. A layer record's 390 is the Normal
;;; plot style name (ACAD_PLOTSTYLENAME's placeholder), its 347 the Global
;;; material.
;;; Only the containers and the objects a record points at are made; what
;;; the vendors put in the other dictionaries (layouts, styles, scales) is
;;; issues/open/deferred-nod-default-contents.issue.

(defparameter *default-named-objects*
  ;; (KEY TYPE PRODUCTS (ENTRY-KEY ENTRY-TYPE) ...), in the order dictnext
  ;; lists them; PRODUCTS is :both, :autocad or :bricscad.
  '(("ACAD_CIP_PREVIOUS_PRODUCT_INFO" "XRECORD" :autocad)
    ("ACAD_COLOR" "DICTIONARY" :autocad)
    ("ACAD_DETAILVIEWSTYLE" "DICTIONARY" :both)
    ("ACAD_GROUP" "DICTIONARY" :both)
    ("ACAD_IMAGE_DICT" "DICTIONARY" :bricscad)
    ("ACAD_IMAGE_VARS" "RASTERVARIABLES" :bricscad)
    ("ACAD_LAYOUT" "DICTIONARY" :both)
    ("ACAD_MATERIAL" "DICTIONARY" :both
     ("ByBlock" "MATERIAL") ("ByLayer" "MATERIAL") ("Global" "MATERIAL"))
    ("ACAD_MLEADERSTYLE" "DICTIONARY" :both)
    ("ACAD_MLINESTYLE" "DICTIONARY" :both)
    ("ACAD_PLOTSETTINGS" "DICTIONARY" :both)
    ("ACAD_PLOTSTYLENAME" "ACDBDICTIONARYWDFLT" :both ("Normal" "ACDBPLACEHOLDER"))
    ("ACAD_RENDER_ACTIVE_SETTINGS" "MENTALRAYRENDERSETTINGS" :bricscad)
    ("ACAD_SCALELIST" "DICTIONARY" :both)
    ("ACAD_SECTIONVIEWSTYLE" "DICTIONARY" :both)
    ("ACAD_TABLESTYLE" "DICTIONARY" :both)
    ("ACAD_VISUALSTYLE" "DICTIONARY" :both)
    ("AcDbVariableDictionary" "DICTIONARY" :both)))

(defun %default-object-data (type key)
  "The stored group-code list of a default object of TYPE filed under KEY."
  (cons (cons 0 type)
        (cond
          ((string= type "DICTIONARY")
           (list (cons 100 "AcDbDictionary") (cons 280 0) (cons 281 1)))
          ((string= type "ACDBDICTIONARYWDFLT")
           (list (cons 100 "AcDbDictionary") (cons 281 1)))
          ((string= type "XRECORD")
           (list (cons 100 "AcDbXrecord") (cons 280 1)))
          ((string= type "MATERIAL")
           (list (cons 100 "AcDbMaterial") (cons 1 key)))
          ((string= type "RASTERVARIABLES")
           (list (cons 100 "AcDbRasterVariables")
                 (cons 90 0) (cons 70 1) (cons 71 1) (cons 72 0)))
          ((string= type "MENTALRAYRENDERSETTINGS")
           (list (cons 100 "AcDbRenderSettings")
                 (cons 100 "AcDbMentalRayRenderSettings")))
          (t '()))))

(defun %populate-default-named-objects (drawing root-handle)
  "File the vendors' default entries in the fresh root dictionary ROOT-HANDLE."
  (flet ((make-member (dict-handle key type)
           (let ((object (clautolisp.drawing:add-entity
                          drawing (%default-object-data type key))))
             (clautolisp.drawing:dictionary-add-entry
              drawing dict-handle key (clautolisp.drawing:entity-handle-id object))
             (clautolisp.drawing:entity-handle-id object))))
    (loop with product = (if (eq (%current-product) :bricscad) :bricscad :autocad)
          for (key type products . entries) in *default-named-objects*
          for handle = (and (member products (list :both product))
                            (make-member root-handle key type))
          when handle
            do (loop for (entry-key entry-type) in entries
                   for member = (make-member handle entry-key entry-type)
                   when (string= type "ACDBDICTIONARYWDFLT")
                     ;; the dictionary's default: its (340 . Normal)
                     do (let ((dict (clautolisp.drawing:find-entity drawing handle)))
                          (setf (clautolisp.drawing:entity-handle-data dict)
                                (append (clautolisp.drawing:entity-handle-data dict)
                                        (list (cons 100 "AcDbDictionaryWithDefault")
                                              (cons 340 member)))))))))

(defun %ensure-root-dictionary (host)
  "The active drawing's root named-object dictionary, made on first need
with the vendors' default entries. Making the objects every drawing has
is no change of the drawing: DBMOD is left as it was."
  (let ((drawing (cador-active-drawing host)))
    (if (clautolisp.drawing:drawing-root-dictionary-handle drawing)
        (clautolisp.drawing:ensure-root-dictionary drawing)
        (let ((dbmod (clautolisp.drawing:drawing-dbmod drawing))
              (clautolisp.drawing:*drawing-modification-hook* nil))
          (let ((root (clautolisp.drawing:ensure-root-dictionary drawing)))
            (%populate-default-named-objects
             drawing (clautolisp.drawing:entity-handle-id root))
            (setf (clautolisp.drawing:drawing-dbmod drawing) dbmod)
            root)))))

(defun %named-object-handle (host &rest keys)
  "The handle of the object reached from the root dictionary through KEYS
\(e.g. \"ACAD_MATERIAL\" \"Global\"), or NIL."
  (let ((drawing (cador-active-drawing host))
        (handle (clautolisp.drawing:entity-handle-id (%ensure-root-dictionary host))))
    (dolist (key keys handle)
      (setf handle (and handle
                        (clautolisp.drawing:dictionary-member-handle drawing handle key))))))

(defmethod host-namedobjdict ((host cador))
  (handle->ename host (clautolisp.drawing:entity-handle-id (%ensure-root-dictionary host))))

(defmethod host-dictsearch ((host cador) dict-ename name &key next-after)
  (let* ((drawing (cador-active-drawing host))
         (dict-handle (%require-dict-handle host dict-ename 'dictsearch)))
    (when dict-handle
      (let* ((key (cador-string-value name))
             (member (and key (clautolisp.drawing:dictionary-member-handle
                               drawing dict-handle key))))
        (when member
          ;; The optional NEXT-AFTER flag primes the dictnext walk to
          ;; resume just past this entry (vendor dictsearch 3rd arg).
          (when next-after
            (let* ((entries (clautolisp.drawing:dictionary-object-entries drawing dict-handle))
                   (tail (member key entries :test #'string-equal :key #'car)))
              (setf (gethash dict-handle (cador-dictnext-iterators host))
                    (rest tail))))
          (%dict-member-view host member))))))

(defmethod host-dictnext ((host cador) dict-ename &key rewind)
  (let* ((drawing (cador-active-drawing host))
         (dict-handle (%require-dict-handle host dict-ename 'dictnext)))
    (when dict-handle
      (let ((iterators (cador-dictnext-iterators host)))
        (when (or rewind (not (nth-value 1 (gethash dict-handle iterators))))
          (setf (gethash dict-handle iterators)
                (clautolisp.drawing:dictionary-object-entries drawing dict-handle)))
        ;; Skip entries whose object has vanished; return the first live
        ;; member view, or nil at end-of-dictionary.
        (loop
          (let ((remaining (gethash dict-handle iterators)))
            (when (null remaining) (return nil))
            (let ((entry (first remaining)))
              (setf (gethash dict-handle iterators) (rest remaining))
              (let ((view (%dict-member-view host (cdr entry))))
                (when view (return view))))))))))

(defmethod host-dictadd ((host cador) dict-ename name object-ename)
  (let* ((drawing (cador-active-drawing host))
         (dict-handle (%require-dict-handle host dict-ename 'dictadd)))
    (when dict-handle
      (let ((key (cador-string-value name))
            (object-handle (ename->handle object-ename 'dictadd host)))
        (when (and key
                   (clautolisp.drawing:dictionary-add-entry
                    drawing dict-handle key object-handle))
          object-ename)))))

(defmethod host-dictremove ((host cador) dict-ename name)
  (let* ((drawing (cador-active-drawing host))
         (dict-handle (%require-dict-handle host dict-ename 'dictremove)))
    (when dict-handle
      (let* ((key (cador-string-value name))
             (removed (and key (clautolisp.drawing:dictionary-remove-entry
                                drawing dict-handle key))))
        (and removed (handle->ename host removed))))))

(defmethod host-dictrename ((host cador) dict-ename old new)
  (let* ((drawing (cador-active-drawing host))
         (dict-handle (%require-dict-handle host dict-ename 'dictrename)))
    (when dict-handle
      (let ((old-key (cador-string-value old))
            (new-key (cador-string-value new)))
        (when (and old-key new-key
                   (clautolisp.drawing:dictionary-rename-entry
                    drawing dict-handle old-key new-key))
          (clautolisp.autolisp-runtime:make-autolisp-string new-key))))))

(defmethod host-dictobjname ((host cador) dict-ename name)
  (let* ((drawing (cador-active-drawing host))
         (dict-handle (%require-dict-handle host dict-ename 'dictobjname)))
    (when dict-handle
      (let* ((key (cador-string-value name))
             (member (and key (clautolisp.drawing:dictionary-member-handle
                               drawing dict-handle key))))
        (and member (safe-find-entity drawing member) (handle->ename host member))))))

(defmethod host-regapp ((host cador) name)
  (let ((app (cador-string-value name)))
    (and app
         (clautolisp.drawing:register-appid (cador-active-drawing host) app)
         (clautolisp.autolisp-runtime:make-autolisp-string app))))
