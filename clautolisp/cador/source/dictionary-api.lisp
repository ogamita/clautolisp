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
;;; cador-entget-subclass-layout-and-record-pointers, item 5, and
;;; deferred-nod-default-contents. A new drawing's NOD holds, per product,
;;; the objects *MEASURED-DEFAULT-OBJECTS* (default-objects.lisp, generated
;;; from the entget-pointers probe, section 12) lists: the dictionaries and
;;; what they contain -- layouts, materials, styles, scales, visual styles,
;;; the variable dictionary -- with their measured groups. BricsCAD dialects
;;; get BricsCAD's set, every other dialect AutoCAD's. A layer record's 390
;;; is the Normal plot style name (ACAD_PLOTSTYLENAME's placeholder), its 347
;;; the Global material.

(defparameter *default-object-record-kinds*
  ;; a pointer's TYPE naming a symbol table record -> the table kind
  '(("BLOCK_RECORD" . :block-record) ("LAYER" . :layer) ("LTYPE" . :ltype)
    ("STYLE" . :style) ("VPORT" . :vport) ("DIMSTYLE" . :dimstyle)
    ("APPID" . :appid) ("UCS" . :ucs) ("VIEW" . :view)))

(defun %default-ref-p (pair)
  (and (consp pair) (consp (cdr pair)) (eq :ref (cadr pair))))

(defun %populate-default-named-objects (host drawing root-handle)
  "File the product's default objects in the fresh root dictionary ROOT-HANDLE.
Two passes: make every object (filed in its dictionary), then resolve each
(CODE :REF TYPE NAME) pointer -- to the table record of that name, else to
the made object of that type and key; an unresolved one is left out."
  (let* ((made '())
         (product (if (eq (%current-product) :bricscad) :bricscad :autocad))
         (forms (cdr (assoc product *measured-default-objects*))))
    (labels ((make (dict-handle form)
               (destructuring-bind (key type body members &optional xdict) form
                 (let* ((object (clautolisp.drawing:add-entity
                                 drawing (list (cons 0 type))))
                        (handle (clautolisp.drawing:entity-handle-id object)))
                   ;; filed first, its body after: filing stamps the owner
                   ;; by removing every 330, and a LAYOUT has a second one
                   ;; (its block record)
                   (clautolisp.drawing:dictionary-add-entry drawing dict-handle key handle)
                   (setf (clautolisp.drawing:entity-handle-data object)
                         (append (clautolisp.drawing:entity-handle-data object)
                                 (copy-tree body)))
                   (push (list type key handle) made)
                   (dolist (member members)
                     (make handle member))
                   (when xdict
                     (attach-xdict object xdict)))))
             (attach-xdict (owner form)
               ;; OWNER's own extension dictionary FORM, owned by it, and the
               ;; {ACAD_XDICTIONARY (360 . xdict)} group in OWNER's data
               (destructuring-bind (key type body members &optional xdict) form
                 (declare (ignore key xdict))
                 (let* ((object (clautolisp.drawing:add-entity drawing (list (cons 0 type))))
                        (handle (clautolisp.drawing:entity-handle-id object))
                        (data (clautolisp.drawing:entity-handle-data owner)))
                   (setf (clautolisp.drawing:entity-handle-data object)
                         (append (clautolisp.drawing:entity-handle-data object)
                                 (list (cons 330 (clautolisp.drawing:entity-handle-id owner)))
                                 (copy-tree body)))
                   (setf (clautolisp.drawing:entity-handle-data owner)
                         (append (list (first data))
                                 (list (cons 102 "{ACAD_XDICTIONARY") (cons 360 handle)
                                       (cons 102 "}"))
                                 (rest data)))
                   (dolist (member members)
                     (make handle member)))))
             (resolve (type name)
               (let ((kind (cdr (assoc type *default-object-record-kinds*
                                       :test #'string-equal))))
                 (if kind
                     (let ((record (cador-find-table-record host kind name)))
                       (and record (symbol-table-record-id record)))
                     (third (find-if (lambda (m)
                                       (and (string-equal type (first m))
                                            (string= name (second m))))
                                     made))))))
      (dolist (form forms)
        (make root-handle form))
      ;; The extension dictionaries (AutoCAD's: layer 0, *Model_Space's
      ;; BLOCK_RECORD, the LAYER TABLE with ACAD_LAYERSTATES), owned by the
      ;; object itself: -1 0 330 5 100 280 281, no reactor group.
      (dolist (entry (cdr (assoc product *measured-extension-dictionaries*)))
        (destructuring-bind (owner (key type body members)) entry
          (declare (ignore key))
          (let ((owner-handle (%extension-dictionary-owner-handle host owner)))
            (when owner-handle
              (let* ((object (clautolisp.drawing:add-entity drawing (list (cons 0 type))))
                     (handle (clautolisp.drawing:entity-handle-id object)))
                (setf (clautolisp.drawing:entity-handle-data object)
                      (append (clautolisp.drawing:entity-handle-data object)
                              (list (cons 330 owner-handle))
                              (copy-tree body)))
                (setf (gethash owner-handle (%cador-extension-dictionaries host)) handle)
                (dolist (member members)
                  (make handle member)))))))
      (dolist (m made)
        (let* ((entity (clautolisp.drawing:find-entity drawing (third m)))
               (data (clautolisp.drawing:entity-handle-data entity)))
          (when (find-if #'%default-ref-p data)
            (setf data
                  (loop for pair in data
                        for target = (and (%default-ref-p pair)
                                          (resolve (third pair) (fourth pair)))
                        if (not (%default-ref-p pair)) collect pair
                        else if target collect (cons (car pair) target)))
            (when (string-equal (first m) "ACDBDICTIONARYWDFLT")
              ;; the default after the entries, as listed:
              ;; ... 3 350 (100 . "AcDbDictionaryWithDefault") (340 . default)
              (let ((tail (member "AcDbDictionaryWithDefault" data
                                  :key (lambda (p) (and (consp p) (cdr p)))
                                  :test #'equal)))
                (when tail
                  (setf data (append (ldiff data tail)
                                     (remove-if-not (lambda (p) (member (car p) '(3 350)))
                                                    tail)
                                     (remove-if (lambda (p) (member (car p) '(3 350)))
                                                tail))))))
            (setf (clautolisp.drawing:entity-handle-data entity) data)))))))

(defun %extension-dictionary-owner-handle (host owner)
  "The handle of OWNER, (KIND NAME) a table record or (:TABLE KIND) a symbol
TABLE object, or NIL when the drawing has none."
  (if (eq (first owner) :table)
      (second (assoc (second owner) *symbol-tables*))
      (let ((record (cador-find-table-record host (first owner) (second owner))))
        (and record (symbol-table-record-id record)))))

(defun %cador-extension-dictionaries (host)
  "Owner handle -> extension dictionary handle, for the active drawing."
  (let ((cell (%cador-extension-dictionary-cell host))
        (drawing (cador-active-drawing host)))
    (if (and cell (eq (car cell) drawing))
        (cdr cell)
        (cdr (setf (%cador-extension-dictionary-cell host)
                   (cons drawing (make-hash-table :test #'equalp)))))))

(defun %extension-dictionary-handle (host owner-handle)
  "The handle of the extension dictionary of the object OWNER-HANDLE (a
table record or TABLE object), or NIL; the defaults are made first."
  (%ensure-root-dictionary host)
  (values (gethash owner-handle (%cador-extension-dictionaries host))))

(defun %extension-dictionary-group (host owner-handle)
  "The (102 . \"{ACAD_XDICTIONARY\") (360 . h) (102 . \"}\") pure pairs of
OWNER-HANDLE's extension dictionary, or NIL."
  (let ((xdict (%extension-dictionary-handle host owner-handle)))
    (and xdict
         (list (cons 102 "{ACAD_XDICTIONARY") (cons 360 xdict) (cons 102 "}")))))

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
             host drawing (clautolisp.drawing:entity-handle-id root))
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
