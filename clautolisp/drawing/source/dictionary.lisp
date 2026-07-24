(in-package #:clautolisp.drawing)

;;;; Named-object dictionary tree, xrecords, and REGAPP/APPID
;;;; registration — the pure Common-Lisp drawing-data layer added for
;;;; the SCHMS drawing-data-structures parity work.
;;;;
;;;; Representation decision (see drawing-specifications.org, the
;;;; DICT-1 note): dictionaries and xrecords are stored as ordinary
;;;; handle-bearing entities in the ENTITIES table, exactly like a
;;;; graphical entity, so that
;;;;
;;;;   - they get a hex handle and therefore a stable AutoLISP ENAME;
;;;;   - (entget ename) / (entmod data) / (entdel ename) / handent all
;;;;     work on them through the existing entity machinery with no
;;;;     parallel code path;
;;;;   - the dictionary's key->object mapping rides *inside* the
;;;;     dictionary object's DXF data as the interleaved (3 . key) /
;;;;     (350 . handle) pairs the DXF reference specifies.
;;;;
;;;; They are distinguished from graphical entities by their
;;;; entity-family GRAPHICAL-P flag (DICTIONARY and XRECORD are
;;;; registered non-graphical), so the selection scan (ssget "X")
;;;; excludes them — matching the vendor, which never returns a
;;;; dictionary or xrecord from ssget.

;;; --- Graphical / non-graphical classification -------------------

(defun graphical-entity-p (entity)
  "True iff ENTITY is a graphical (drawable) entity — the kind ssget
returns. A registered non-graphical family (DICTIONARY, XRECORD, ...)
is excluded; an unregistered / unknown group-0 type is treated as
graphical (permissive: clautolisp does not know every DXF type and must
not silently drop a client's entity from a selection scan)."
  (let* ((data (entity-handle-data entity))
         (type (%group-0-type data))
         (family (and type (find-entity-family type))))
    (if family
        (entity-family-graphical-p family)
        t)))

;;; --- Dictionary object helpers ----------------------------------

(defun dictionary-entity-p (entity)
  "True iff ENTITY is a DICTIONARY object."
  (let ((type (%group-0-type (entity-handle-data entity))))
    (and type (string-equal type "DICTIONARY"))))

(defun %dict-entries-ordered (data)
  "Parse the interleaved (3 . key) / (350 . handle) entry pairs of a
DICTIONARY object's group-code list DATA into an ordered list of
 (KEY . HANDLE) conses, preserving insertion order and multiplicity.
A (3 . key) with no following (350 . handle) is ignored."
  (let ((result '())
        (pending-key nil))
    (dolist (pair data (nreverse result))
      (when (consp pair)
        (let ((code (car pair)))
          (cond
            ((%group-code= code 3) (setf pending-key (cdr pair)))
            ((and (or (%group-code= code 350) (%group-code= code 360))
                  pending-key)
             (push (cons pending-key (cdr pair)) result)
             (setf pending-key nil))))))))

(defun %dict-strip-entries (data)
  "DATA with all (3 . key) / (350 . h) / (360 . h) entry pairs removed,
keeping the dictionary object's structural codes in order."
  (remove-if (lambda (pair)
               (and (consp pair)
                    (let ((c (car pair)))
                      (or (%group-code= c 3)
                          (%group-code= c 350)
                          (%group-code= c 360)))))
             data))

(defun %dict-rebuild (data entries)
  "Rebuild a DICTIONARY object's group-code list from its structural
DATA (entry pairs stripped) and the ordered ENTRIES alist
 ((KEY . HANDLE) ...), appending each as (3 . key) (350 . handle)."
  (append (%dict-strip-entries data)
          (loop for (key . handle) in entries
                collect (cons 3 key)
                collect (cons 350 handle))))

(defun ensure-root-dictionary (drawing)
  "Return the root named-object-dictionary ENTITY-HANDLE of DRAWING,
creating it (as a DICTIONARY object owned by the database, group
 330 = \"0\") on first reference. Idempotent; the handle is cached in
DRAWING-ROOT-DICTIONARY-HANDLE."
  (let ((cached (drawing-root-dictionary-handle drawing)))
    (or (and cached (find-entity drawing cached))
        (let ((entity (add-entity
                       drawing
                       (list (cons 0 "DICTIONARY")
                             (cons 100 "AcDbObject")
                             (cons 100 "AcDbDictionary")
                             (cons 330 "0")
                             (cons 280 0)
                             (cons 281 1)))))
          (setf (drawing-root-dictionary-handle drawing)
                (entity-handle-id entity))
          entity))))

(defun find-dictionary (drawing handle)
  "The live DICTIONARY ENTITY-HANDLE for HANDLE, or NIL if HANDLE names
no entity, a non-dictionary entity, or a deleted one."
  (let ((entity (find-entity drawing handle)))
    (and entity (dictionary-entity-p entity) entity)))

(defun dictionary-object-entries (drawing dict-handle)
  "The ordered ((KEY . MEMBER-HANDLE) ...) entries of the dictionary
DICT-HANDLE, or NIL when it is not a dictionary."
  (let ((dict (find-dictionary drawing dict-handle)))
    (and dict (%dict-entries-ordered (entity-handle-data dict)))))

(defun dictionary-member-handle (drawing dict-handle key)
  "The member handle stored under KEY (case-insensitive) in dictionary
DICT-HANDLE, or NIL."
  (let ((entry (assoc key (dictionary-object-entries drawing dict-handle)
                      :test #'string-equal)))
    (and entry (cdr entry))))

(defun dictionary-add-entry (drawing dict-handle key member-handle)
  "Add MEMBER-HANDLE under KEY in dictionary DICT-HANDLE and stamp the
member object's owner (group 330) to the dictionary. Returns
MEMBER-HANDLE on success, or NIL when DICT-HANDLE is not a dictionary or
KEY already exists (the vendor DICTADD contract: a duplicate key fails).
Case-insensitive key comparison."
  (let ((dict (find-dictionary drawing dict-handle)))
    (when (and dict
               (not (assoc key (%dict-entries-ordered (entity-handle-data dict))
                           :test #'string-equal)))
      (let* ((data (entity-handle-data dict))
             (entries (%dict-entries-ordered data))
             (member-key (handle->string member-handle)))
        (setf (entity-handle-data dict)
              (%dict-rebuild data (append entries (list (cons key member-key)))))
        ;; Stamp / refresh the member's owner (330) to this dictionary.
        (let ((member (find-entity drawing member-key)))
          (when member
            (%set-owner member (entity-handle-id dict))))
        member-key))))

(defun %set-owner (entity owner-handle)
  "Set ENTITY's owner (group 330) to OWNER-HANDLE, replacing any
existing 330 pair. Mutates ENTITY-HANDLE-DATA in place."
  (let ((data (remove-if (lambda (p) (and (consp p) (%group-code= (car p) 330)))
                         (entity-handle-data entity))))
    ;; Insert the owner right after the (5 . handle) head for a tidy,
    ;; vendor-like ordering; fall back to append.
    (setf (entity-handle-data entity)
          (if (and data (consp (first data)) (%group-code= (car (first data)) 5))
              (list* (first data) (cons 330 owner-handle) (rest data))
              (cons (cons 330 owner-handle) data)))))

(defun dictionary-remove-entry (drawing dict-handle key)
  "Remove the entry KEY from dictionary DICT-HANDLE. Returns the removed
member handle string on success, or NIL when DICT-HANDLE is not a
dictionary or KEY is absent. The member object itself is left in the
drawing (detached); the vendor erases an orphaned object on save, which
is out of scope for the in-memory model."
  (let ((dict (find-dictionary drawing dict-handle)))
    (when dict
      (let* ((data (entity-handle-data dict))
             (entries (%dict-entries-ordered data))
             (entry (assoc key entries :test #'string-equal)))
        (when entry
          (setf (entity-handle-data dict)
                (%dict-rebuild data (remove entry entries)))
          (cdr entry))))))

(defun dictionary-rename-entry (drawing dict-handle old-key new-key)
  "Rename entry OLD-KEY to NEW-KEY in dictionary DICT-HANDLE. Returns the
member handle string on success, or NIL when the dictionary or OLD-KEY is
absent, or NEW-KEY already exists."
  (let ((dict (find-dictionary drawing dict-handle)))
    (when dict
      (let* ((data (entity-handle-data dict))
             (entries (%dict-entries-ordered data))
             (entry (assoc old-key entries :test #'string-equal)))
        (when (and entry
                   (not (assoc new-key entries :test #'string-equal)))
          (setf (entity-handle-data dict)
                (%dict-rebuild data
                               (mapcar (lambda (e)
                                         (if (eq e entry)
                                             (cons new-key (cdr e))
                                             e))
                                       entries)))
          (cdr entry))))))

;;; --- REGAPP / APPID registration --------------------------------

(defun appid-registered-p (drawing name)
  "True iff an APPID (registered application) record named NAME
 (case-insensitive) exists in DRAWING."
  (and (find-table-record drawing :appid name) t))

(defun register-appid (drawing name)
  "Register the application NAME in DRAWING's APPID table. Returns NAME
on success, or NIL when NAME is already registered (the vendor REGAPP
contract). Does not validate the name — the AutoLISP layer does that
via SNVALID before calling."
  (unless (appid-registered-p drawing name)
    (add-table-record drawing
                      (make-symbol-table-record
                       :kind :appid :name name
                       :data (list (cons 0 "APPID")
                                   (cons 2 name)
                                   (cons 70 0))))
    name))
