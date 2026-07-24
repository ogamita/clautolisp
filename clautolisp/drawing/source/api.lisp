(in-package #:clautolisp.drawing)

;;;; The public Common-Lisp drawing API (Phase 17b).
;;;;
;;;; See clautolisp/drawing/documentation/drawing-specifications.org
;;;; for the contract and the design decisions (REVIEW-1..7) realised
;;;; here. Summary of the load-bearing ones:
;;;;
;;;;  - Handles are INTEGERS in this API (REVIEW-3). Functions that
;;;;    take a handle also accept a hexadecimal string (AutoLISP uses
;;;;    strings for lack of bignums); the canonical entity-table key is
;;;;    an uppercase hex string with no leading zeros. allocate-handle
;;;;    returns an integer; add-entity converts it to the hex string it
;;;;    injects as group code 5.
;;;;  - Stored entity data is PURE Common-Lisp values (REVIEW-1): no
;;;;    (-1 . ename) pair is stored — the ename is synthesised by the
;;;;    host adapter from the handle. Group code 5 is the hex string;
;;;;    group code 0 is a CL string.
;;;;  - This layer never signals AutoLISP runtime errors, never touches
;;;;    host/session state, and never fires document events.

;;; --- Handle normalisation ---------------------------------------

(defun handle->integer (handle)
  "The integer value of HANDLE, given as an integer or a hexadecimal
string. Signals DRAWING-ERROR on a malformed string."
  (etypecase handle
    (integer handle)
    (string  (multiple-value-bind (value end)
                 (ignore-errors (parse-integer handle :radix 16))
               (if (and value (= end (length handle)))
                   value
                   (error 'drawing-error :handle handle
                          :format-control "~S is not a valid hexadecimal handle"
                          :format-arguments (list handle)))))))

(defun handle->string (handle)
  "The canonical AutoLISP/DXF hexadecimal-string form of HANDLE
(uppercase, no leading zeros)."
  (format nil "~X" (handle->integer handle)))

;; The entity-table key is the canonical hex string.
(declaim (inline handle->key))
(defun handle->key (handle)
  (handle->string handle))

;;; --- Construction -----------------------------------------------
;;;
;;; MAKE-DRAWING lives in model.lisp. COPY-DRAWING is here.

(defun %copy-entity (e)
  (make-entity-handle :id        (entity-handle-id e)
                      :kind      (entity-handle-kind e)
                      :block     (entity-handle-block e)
                      :layer     (entity-handle-layer e)
                      :data      (copy-tree (entity-handle-data e))
                      :deleted-p (entity-handle-deleted-p e)))

(defun %copy-record (r)
  (make-symbol-table-record :id   (symbol-table-record-id r)
                            :kind (symbol-table-record-kind r)
                            :name (symbol-table-record-name r)
                            :data (copy-tree (symbol-table-record-data r))))

(defun %copy-cell (c)
  (make-sysvar-cell :name           (sysvar-cell-name c)
                    :kind           (sysvar-cell-kind c)
                    :value          (let ((v (sysvar-cell-value c)))
                                      (if (consp v) (copy-tree v) v))
                    :read-only-p    (sysvar-cell-read-only-p c)
                    :host-derived-p (sysvar-cell-host-derived-p c)))

(defun %copy-dictionary-tree (d)
  (let ((new (make-dictionary)))
    (maphash (lambda (k v)
               (setf (gethash k (dictionary-entries new))
                     (cond ((dictionary-p v)     (%copy-dictionary-tree v))
                           ((entity-handle-p v)  (%copy-entity v))
                           ((consp v)            (copy-tree v))
                           (t                    v))))
             (dictionary-entries d))
    new))

(defun copy-drawing (drawing)
  "Return a structurally independent deep copy of DRAWING: mutating
the copy's entities, tables, header, dictionary tree, or data lists
does not affect the original."
  (let ((new (make-drawing :name        (drawing-name drawing)
                           :path        (drawing-path drawing)
                           :format      (drawing-format drawing)
                           :version     (drawing-version drawing)
                           :codepage    (drawing-codepage drawing)
                           :handle-seed (drawing-handle-seed drawing))))
    (maphash (lambda (k e) (setf (gethash k (drawing-entities new)) (%copy-entity e)))
             (drawing-entities drawing))
    (setf (drawing-creation-order new) (copy-list (drawing-creation-order drawing)))
    (maphash (lambda (kind tbl)
               (let ((nt (make-hash-table :test #'equalp)))
                 (maphash (lambda (nm r) (setf (gethash nm nt) (%copy-record r))) tbl)
                 (setf (gethash kind (drawing-tables new)) nt)))
             (drawing-tables drawing))
    (maphash (lambda (nm c) (setf (gethash nm (drawing-header-variables new)) (%copy-cell c)))
             (drawing-header-variables drawing))
    (setf (drawing-named-object-dictionary new)
          (%copy-dictionary-tree (drawing-named-object-dictionary drawing)))
    (setf (drawing-classes new) (copy-tree (drawing-classes drawing)))
    (maphash (lambda (name header)
               (setf (gethash name (drawing-blocks new)) (copy-tree header)))
             (drawing-blocks drawing))
    (maphash (lambda (handle obj)
               (setf (gethash handle (drawing-objects new)) (copy-tree obj)))
             (drawing-objects drawing))
    new))

;;; --- Entity introspection ---------------------------------------

(defun %entity-raw (drawing handle)
  "The ENTITY-HANDLE stored under HANDLE regardless of its deleted
flag, or NIL."
  (gethash (handle->key handle) (drawing-entities drawing)))

(defun find-entity (drawing handle &key include-deleted)
  "The ENTITY-HANDLE for HANDLE (an integer or hex string), or NIL.
Deleted entities are hidden unless INCLUDE-DELETED."
  (let ((e (%entity-raw drawing handle)))
    (and e (or include-deleted (not (entity-handle-deleted-p e))) e)))

(defun map-entities (function drawing &key include-deleted)
  "Call FUNCTION on each ENTITY-HANDLE in creation order (oldest
first). Deleted entities are skipped unless INCLUDE-DELETED. Returns
NIL."
  (dolist (key (reverse (drawing-creation-order drawing)) nil)
    (let ((e (gethash key (drawing-entities drawing))))
      (when (and e (or include-deleted (not (entity-handle-deleted-p e))))
        (funcall function e)))))

(defmacro do-entities ((var drawing &key include-deleted) &body body)
  "Iterate VAR over the entities of DRAWING in creation order. An
explicit (RETURN value) exits the loop early."
  `(block nil
     (map-entities (lambda (,var) ,@body) ,drawing :include-deleted ,include-deleted)))

(defun drawing-entity-count (drawing &key include-deleted)
  "The number of (non-deleted, unless INCLUDE-DELETED) entities."
  (let ((n 0))
    (map-entities (lambda (e) (declare (ignore e)) (incf n))
                  drawing :include-deleted include-deleted)
    n))

(defun entity-dxf (entity-handle)
  "The DXF group-code list stored for ENTITY-HANDLE (pure CL values)."
  (entity-handle-data entity-handle))

(defun entity-kind (entity-handle)
  "The entity kind keyword (the group-0 type)."
  (entity-handle-kind entity-handle))

(defun entity-handle-string (entity-handle)
  "The entity's handle as the canonical hexadecimal string."
  (entity-handle-id entity-handle))

(defun entity-handle-integer (entity-handle)
  "The entity's handle as an integer."
  (handle->integer (entity-handle-id entity-handle)))

;;; --- Symbol-table introspection ---------------------------------

(defun drawing-table (drawing kind)
  "The per-kind symbol-table hash-table (name -> record), or NIL."
  (gethash kind (drawing-tables drawing)))

(defun map-table-records (function drawing kind)
  "Call FUNCTION on each SYMBOL-TABLE-RECORD of KIND. Returns NIL."
  (let ((tbl (drawing-table drawing kind)))
    (when tbl
      (maphash (lambda (name rec) (declare (ignore name)) (funcall function rec)) tbl)))
  nil)

(defun find-table-record (drawing kind name)
  "The SYMBOL-TABLE-RECORD of KIND named NAME (case-insensitive), or NIL."
  (let ((tbl (drawing-table drawing kind)))
    (and tbl (gethash name tbl))))

(defun table-record-dxf (record)
  "The DXF group-code list of a symbol-table RECORD."
  (symbol-table-record-data record))

;;; --- Dictionary introspection / mutation ------------------------

(defun drawing-dictionary (drawing)
  "The root named-object dictionary of DRAWING."
  (drawing-named-object-dictionary drawing))

(defun dictionary-get (dictionary key)
  "The value stored under KEY in DICTIONARY, or NIL. KEY is a
case-folded string (the caller folds)."
  (values (gethash key (dictionary-entries dictionary))))

(defun map-dictionary (function dictionary)
  "Call FUNCTION with (KEY VALUE) for each entry of DICTIONARY. NIL."
  (maphash function (dictionary-entries dictionary))
  nil)

(defun dictionary-put (dictionary key value)
  "Store VALUE under KEY in DICTIONARY; returns VALUE."
  (setf (gethash key (dictionary-entries dictionary)) value))

(defun dictionary-remove (dictionary key)
  "Remove KEY from DICTIONARY; T iff it was present."
  (remhash key (dictionary-entries dictionary)))

;;; --- Header (drawing-resident system) variables -----------------

(defun drawing-variable-cell (drawing name)
  "The SYSVAR-CELL named NAME (case-insensitive), or NIL."
  (gethash name (drawing-header-variables drawing)))

(defun drawing-variable (drawing name)
  "The value of the header variable NAME, or NIL if unknown. Searches
the drawing only; the drawing-then-host two-level search (REVIEW-7)
is a host-layer concern."
  (let ((cell (drawing-variable-cell drawing name)))
    (and cell (sysvar-cell-value cell))))

(defun map-variables (function drawing)
  "Call FUNCTION on each header-variable SYSVAR-CELL. Returns NIL."
  (maphash (lambda (name cell) (declare (ignore name)) (funcall function cell))
           (drawing-header-variables drawing))
  nil)

;;; --- Handle allocation ------------------------------------------

(defun allocate-handle (drawing)
  "Return the next integer handle for DRAWING and bump its seed."
  (prog1 (drawing-handle-seed drawing)
    (incf (drawing-handle-seed drawing))))

;;; --- Entity mutation --------------------------------------------

(defun %group-code= (a b)
  (and (numberp a) (numberp b) (= a b)))

(defun %strip-codes (data codes)
  "DATA without the dotted pairs whose group code is in CODES."
  (remove-if (lambda (pair)
               (and (consp pair)
                    (member (car pair) codes :test #'%group-code=)))
             data))

(defun %entity-kind-from-data (data)
  "The kind keyword from the (0 . \"TYPE\") marker in DATA, or signal."
  (dolist (pair data)
    (when (and (consp pair) (%group-code= (car pair) 0) (stringp (cdr pair)))
      (return-from %entity-kind-from-data
        (intern (string-upcase (cdr pair)) "KEYWORD"))))
  (error 'drawing-error
         :format-control "entity data requires a (0 . \"TYPE\") marker, got ~S"
         :format-arguments (list data)))

(defun add-entity (drawing dxf &key handle block)
  "Add an entity from the DXF group-code list DXF to DRAWING. HANDLE,
if supplied (a loader preserving file handles), fixes the handle;
otherwise a fresh one is allocated. BLOCK, if supplied, is the name of
the block definition that owns the entity (NIL = model space). DXF must
carry a (0 . \"TYPE\") marker. Any caller-supplied -1 / 5 pairs are
stripped; (5 . hex) is injected. The drawing's seed is kept strictly
greater than every used handle. Returns the new ENTITY-HANDLE."
  (let* ((kind (%entity-kind-from-data dxf))
         (int  (if handle (handle->integer handle) (allocate-handle drawing)))
         (key  (format nil "~X" int))
         (data (cons (cons 5 key) (%strip-codes dxf '(-1 5))))
         (entity (make-entity-handle :id key :kind kind :data data :block block)))
    (when (>= int (drawing-handle-seed drawing))
      (setf (drawing-handle-seed drawing) (1+ int)))
    (setf (gethash key (drawing-entities drawing)) entity)
    (push key (drawing-creation-order drawing))
    entity))

;;; --- Block definitions ------------------------------------------

(defun add-block (drawing name header-data)
  "Register a block definition named NAME whose BLOCK header is the
group-code list HEADER-DATA. The block's entities are ordinary
entities added with :block NAME. Returns HEADER-DATA."
  (setf (gethash name (drawing-blocks drawing)) header-data))

(defun find-block (drawing name)
  "The BLOCK-header group-code list of the block named NAME, or NIL."
  (gethash name (drawing-blocks drawing)))

(defun map-blocks (function drawing)
  "Call FUNCTION with (NAME HEADER-DATA) for each block definition.
Returns NIL."
  (maphash function (drawing-blocks drawing))
  nil)

(defun block-entities (drawing name)
  "The entities owned by block NAME, in creation order (oldest first)."
  (let ((result '()))
    (map-entities (lambda (e)
                    (when (and (entity-handle-block e)
                               (string-equal (entity-handle-block e) name))
                      (push e result)))
                  drawing)
    (nreverse result)))

;;; --- Non-graphical objects (xrecords etc.) ----------------------

(defun add-object (drawing handle object-data)
  "Register a non-graphical OBJECTS-section object (an xrecord or other
non-dictionary object) under its hex HANDLE string. OBJECT-DATA is its
group-code list. Returns OBJECT-DATA."
  (setf (gethash (handle->key handle) (drawing-objects drawing)) object-data))

(defun find-object (drawing handle)
  "The group-code list of the non-graphical object stored under HANDLE
(integer or hex string), or NIL."
  (gethash (handle->key handle) (drawing-objects drawing)))

(defun map-objects (function drawing)
  "Call FUNCTION with (HANDLE OBJECT-DATA) for each non-graphical
object. Returns NIL."
  (maphash function (drawing-objects drawing))
  nil)

(defun %xdata-cell-p (pair)
  "True iff PAIR is the (-3 . groups) xdata cell of an entity."
  (and (consp pair) (%group-code= (car pair) -3)))

(defun %xdata-cell (data)
  "The (-3 . groups) xdata cell of DATA, or NIL."
  (find-if #'%xdata-cell-p data))

(defun %merge-xdata (existing-groups new-groups)
  "Merge the per-application xdata NEW-GROUPS into EXISTING-GROUPS (each
a list of (APPNAME . xdata-pairs)). An application present in NEW-GROUPS
with a non-empty pair list replaces that application's group; present
with an EMPTY pair list removes it; applications absent from NEW-GROUPS
are preserved. This is the vendor ENTMOD xdata contract: xdata is edited
per application, not wholesale."
  (let ((result (copy-list existing-groups)))
    (dolist (grp new-groups result)
      (when (and (consp grp) (stringp (car grp)))
        (let ((name (car grp)))
          (setf result (remove name result
                               :key (lambda (g) (and (consp g) (car g)))
                               :test (lambda (a b) (and (stringp b) (string-equal a b)))))
          (when (cdr grp)               ; non-empty -> add/replace
            (setf result (append result (list grp)))))))))

(defun modify-entity (drawing handle dxf)
  "Replace the ordinary group codes of the live entity HANDLE with those
in DXF (the handle is preserved: (5 . hex) is re-injected, caller -1 / 5
stripped). XData is edited per the vendor ENTMOD contract: when DXF
carries a (-3 ...) xdata cell it is merged application-by-application
(see %MERGE-XDATA); when DXF carries no xdata cell the entity's existing
xdata is preserved untouched. NIL if no such live entity. Returns the
ENTITY-HANDLE."
  (let* ((key (handle->key handle))
         (entity (gethash key (drawing-entities drawing))))
    (when (and entity (not (entity-handle-deleted-p entity)))
      (let* ((old-data      (entity-handle-data entity))
             (old-xdata     (%xdata-cell old-data))
             (new-xdata     (%xdata-cell dxf))
             (new-ordinary  (%strip-codes (remove-if #'%xdata-cell-p dxf) '(-1 5)))
             (merged-groups (if new-xdata
                                (%merge-xdata (and old-xdata (cdr old-xdata))
                                              (cdr new-xdata))
                                (and old-xdata (cdr old-xdata)))))
        (setf (entity-handle-data entity)
              (append (list (cons 5 key))
                      new-ordinary
                      (when merged-groups (list (cons -3 merged-groups))))))
      entity)))

(defun entity-deleted-status (drawing handle)
  "Whether the entity HANDLE is flagged deleted. Signals DRAWING-ERROR
if no such entity exists."
  (let ((e (%entity-raw drawing handle)))
    (if e
        (entity-handle-deleted-p e)
        (error 'drawing-error :drawing drawing :handle handle
               :format-control "no entity with handle ~A"
               :format-arguments (list handle)))))

(defun set-entity-deleted-status (drawing handle deletedp)
  "Set the deleted flag of entity HANDLE to (and DELETEDP t); returns
that boolean. Signals DRAWING-ERROR if no such entity exists."
  (let ((e (%entity-raw drawing handle)))
    (if e
        (setf (entity-handle-deleted-p e) (and deletedp t))
        (error 'drawing-error :drawing drawing :handle handle
               :format-control "no entity with handle ~A"
               :format-arguments (list handle)))))

(defsetf entity-deleted-status set-entity-deleted-status)

(define-modify-macro togglef () not
  "Toggle a generalised boolean place: (togglef place) ==
 (setf place (not place)).")

;;; --- Symbol-table mutation --------------------------------------

(defun add-table-record (drawing record)
  "Add (or replace) RECORD in DRAWING's table for its kind; returns it."
  (let* ((kind (symbol-table-record-kind record))
         (tbl (or (gethash kind (drawing-tables drawing))
                  (setf (gethash kind (drawing-tables drawing))
                        (make-hash-table :test #'equalp)))))
    (setf (gethash (symbol-table-record-name record) tbl) record)
    record))

(defun remove-table-record (drawing kind name)
  "Remove the KIND record named NAME; T iff it was present."
  (let ((tbl (gethash kind (drawing-tables drawing))))
    (and tbl (remhash name tbl))))

;;; --- Header-variable mutation -----------------------------------

(defun set-drawing-variable (drawing name value &key force)
  "Set header variable NAME to VALUE, honouring the cell's read-only
flag unless FORCE. Returns VALUE, or NIL if NAME is unknown (does not
create cells — see ENSURE-DRAWING-VARIABLE). Signals DRAWING-ERROR on a
read-only cell without FORCE."
  (let ((cell (drawing-variable-cell drawing name)))
    (cond
      ((null cell) nil)
      ((and (sysvar-cell-read-only-p cell) (not force))
       (error 'drawing-error :drawing drawing
              :format-control "header variable ~A is read-only"
              :format-arguments (list name)))
      (t (setf (sysvar-cell-value cell) value)))))

(defun ensure-drawing-variable (drawing name &key (kind :string) value
                                                  read-only-p host-derived-p)
  "Return the SYSVAR-CELL named NAME, creating it from the supplied
defaults if absent. Loaders use this to populate the header."
  (or (drawing-variable-cell drawing name)
      (setf (gethash name (drawing-header-variables drawing))
            (make-sysvar-cell :name name :kind kind :value value
                              :read-only-p read-only-p
                              :host-derived-p host-derived-p))))
