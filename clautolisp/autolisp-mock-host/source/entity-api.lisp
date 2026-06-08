(in-package #:clautolisp.autolisp-mock-host)

;;;; Entity-level HAL methods for MockHost.
;;;;
;;;; Phase 17b/(a): these methods are now a thin AutoLISP adapter over
;;;; the clautolisp.drawing CL API, operating on the host's
;;;; ACTIVE-DRAWING. The drawing stores PURE Common-Lisp values
;;;; (REVIEW-1): no (-1 . ename) pair is stored, group code 5 is the
;;;; hexadecimal handle string, and string values are CL strings. The
;;;; AutoLISP view — the (-1 . ename) head and autolisp-string-wrapped
;;;; string values — is synthesised here, at the boundary:
;;;;
;;;;   host-entget  ⇒ find-entity            + al-view wrapping
;;;;   host-entmake ⇒ add-entity             + event signalling
;;;;   host-entmod  ⇒ modify-entity          + event signalling
;;;;   host-entdel  ⇒ entity-deleted-status  toggle + events
;;;;
;;;; The storage mechanics (handle allocation, the entity table,
;;;; creation order, the deleted flag) live once in clautolisp.drawing.

;;; --- ENAME <-> handle helpers ------------------------------------

(defun handle->ename (handle)
  "Wrap a hex handle string in an AutoLISP ENAME."
  (clautolisp.autolisp-runtime:make-autolisp-ename :value handle))

(defun ename->handle (ename operator-name)
  "Extract the hex handle string from an AutoLISP ENAME, signalling
an :invalid-ename runtime error if ENAME is not an ename."
  (unless (typep ename 'clautolisp.autolisp-runtime:autolisp-ename)
    (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
     :invalid-ename
     "~A expects an ENAME, got ~S."
     operator-name ename))
  (clautolisp.autolisp-runtime:autolisp-ename-value ename))

(defun group-code-equal-p (a b)
  "Equality predicate for DXF group-code keys: both are usually
integers, but real AutoLISP corpora occasionally encode them as
small reals when read from a file. (Also used by selection-api.)"
  (or (eql a b) (and (numberp a) (numberp b) (= a b))))

;;; --- AutoLISP <-> pure-CL boundary converter --------------------

(defun al->pure-value (value)
  "Convert an AutoLISP runtime value to the pure CL value stored in
the drawing: autolisp-string -> string, autolisp-ename -> its handle
string; conses recurse; everything else passes through."
  (typecase value
    (clautolisp.autolisp-runtime:autolisp-string
     (clautolisp.autolisp-runtime:autolisp-string-value value))
    (clautolisp.autolisp-runtime:autolisp-ename
     (clautolisp.autolisp-runtime:autolisp-ename-value value))
    (cons (cons (al->pure-value (car value)) (al->pure-value (cdr value))))
    (t value)))

(defun pure->al-value (value)
  "Convert a stored pure CL value to its AutoLISP view: CL string ->
autolisp-string; conses recurse; everything else passes through.
(Enames are reconstructed only for the -1 head, by ENTITY->AL-VIEW.)"
  (typecase value
    (string (clautolisp.autolisp-runtime:make-autolisp-string value))
    (cons (cons (pure->al-value (car value)) (pure->al-value (cdr value))))
    (t value)))

(defun al-data->pure (data operator-name)
  "Convert an AutoLISP DXF group-code list to a pure-CL list. The
integer group code of each pair is kept; the value is converted."
  (unless (listp data)
    (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
     :invalid-entity-data
     "~A expects a DXF group-code list, got ~S."
     operator-name data))
  (mapcar (lambda (pair)
            (if (consp pair)
                (cons (car pair) (al->pure-value (cdr pair)))
                pair))
          data))

(defun entity->al-view (entity)
  "The AutoLISP entget / entmake view of a stored ENTITY-HANDLE: the
(-1 . ename) head followed by the wrapped pure data."
  (cons (cons -1 (handle->ename (entity-handle-id entity)))
        (mapcar (lambda (pair)
                  (if (consp pair)
                      (cons (car pair) (pure->al-value (cdr pair)))
                      pair))
                (entity-handle-data entity))))

(defun extract-modified-handle (data operator-name)
  "Return the hex handle of the entity DATA refers to, from its
(-1 . <ENAME>) entry, signalling :invalid-entity-data if missing."
  (dolist (pair data)
    (when (and (consp pair) (group-code-equal-p (car pair) -1)
               (typep (cdr pair) 'clautolisp.autolisp-runtime:autolisp-ename))
      (return-from extract-modified-handle
        (clautolisp.autolisp-runtime:autolisp-ename-value (cdr pair)))))
  (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
   :invalid-entity-data
   "~A requires the modified entity's (-1 . <ENAME>) entry in the data list."
   operator-name))

;;; --- Compatibility helpers (kept; used by selection-api etc.) ----

(defun mock-host-allocate-handle (mock)
  "Allocate the next hex handle string for MOCK's active drawing and
bump its seed. Retained for API compatibility; the entity methods now
let clautolisp.drawing:ADD-ENTITY allocate internally."
  (format nil "~X" (clautolisp.drawing:allocate-handle
                    (mock-host-active-drawing mock))))

(defun safe-find-entity (drawing handle &key include-deleted)
  "Like clautolisp.drawing:find-entity, but a malformed handle (one
that is not valid hexadecimal — e.g. a fabricated ENAME or HANDENT
argument) is treated as simply not found (nil) rather than signalled.
This is the AutoLISP contract: entget / handent on garbage return nil
and set ERRNO, they do not raise."
  (handler-case
      (clautolisp.drawing:find-entity drawing handle
                                      :include-deleted include-deleted)
    (clautolisp.drawing:drawing-error () nil)))

(defun mock-host-find-entity-by-handle (mock handle)
  "Return the live ENTITY-HANDLE stored under HANDLE, or nil if no
such entity exists or it has been deleted."
  (safe-find-entity (mock-host-active-drawing mock) handle))

(defun current-document ()
  (clautolisp.autolisp-runtime:evaluation-context-current-document
   (clautolisp.autolisp-runtime:current-evaluation-context)))

;;; --- Host method implementations ---------------------------------

(defmethod host-entget ((host mock-host) ename)
  (let* ((handle (ename->handle ename 'entget))
         (entity (safe-find-entity (mock-host-active-drawing host) handle)))
    (and entity (entity->al-view entity))))

(defmethod host-entmake ((host mock-host) data)
  (let* ((pure (al-data->pure data 'entmake))
         (drawing (mock-host-active-drawing host))
         (entity (handler-case (clautolisp.drawing:add-entity drawing pure)
                   (clautolisp.drawing:drawing-error (c)
                     (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
                      :invalid-entity-data "~A" c))))
         (ename (handle->ename (entity-handle-id entity)))
         (document (current-document)))
    (clautolisp.autolisp-runtime:signal-document-event
     document :acdb :vlr-objectappended (list ename))
    (clautolisp.autolisp-runtime:signal-document-event
     document :acdb :vlr-objectreappended (list ename))
    (entity->al-view entity)))

(defmethod host-entmakex ((host mock-host) data)
  ;; MockHost does not yet distinguish graphical from non-graphical
  ;; entities for storage purposes.
  (host-entmake host data))

(defmethod host-entmod ((host mock-host) data)
  (let* ((handle (extract-modified-handle data 'entmod))
         (pure (al-data->pure data 'entmod))
         (drawing (mock-host-active-drawing host))
         (entity (handler-case (clautolisp.drawing:modify-entity drawing handle pure)
                   (clautolisp.drawing:drawing-error () nil))))
    (when entity
      (let ((document (current-document))
            (ename (handle->ename handle)))
        (clautolisp.autolisp-runtime:signal-document-event
         document :acdb :vlr-objectmodified (list ename))
        (clautolisp.autolisp-runtime:signal-document-event
         document :object :vlr-modified (list ename)))
      (entity->al-view entity))))

(defmethod host-entdel ((host mock-host) ename)
  (let* ((handle (ename->handle ename 'entdel))
         (drawing (mock-host-active-drawing host))
         (entity (safe-find-entity drawing handle :include-deleted t)))
    (when entity
      ;; AutoLISP's entdel is a toggle: a second call undeletes.
      (let ((now (setf (clautolisp.drawing:entity-deleted-status drawing handle)
                       (not (clautolisp.drawing:entity-deleted-status
                             drawing handle))))
            (document (current-document)))
        (let ((event (if now :vlr-objecterased :vlr-objectunerased)))
          (clautolisp.autolisp-runtime:signal-document-event
           document :acdb event (list ename))
          (clautolisp.autolisp-runtime:signal-document-event
           document :object event (list ename))))
      ename)))

(defmethod host-entupd ((host mock-host) ename)
  (let* ((handle (ename->handle ename 'entupd)))
    (and (safe-find-entity (mock-host-active-drawing host) handle)
         ename)))

(defmethod host-entlast ((host mock-host))
  ;; Most recently created entity that is not deleted. creation-order
  ;; is newest-first.
  (let ((drawing (mock-host-active-drawing host)))
    (loop for handle in (clautolisp.drawing:drawing-creation-order drawing)
          when (clautolisp.drawing:find-entity drawing handle)
            return (handle->ename handle)
          finally (return nil))))

(defmethod host-entnext ((host mock-host) ename)
  ;; (entnext)       -> first non-deleted entity, or nil.
  ;; (entnext ENAME) -> next non-deleted entity after ENAME, or nil.
  (let* ((drawing (mock-host-active-drawing host))
         (order (reverse (clautolisp.drawing:drawing-creation-order drawing))))
    (flet ((first-live (handles)
             (loop for handle in handles
                   when (clautolisp.drawing:find-entity drawing handle)
                     return (handle->ename handle)
                   finally (return nil))))
      (if (null ename)
          (first-live order)
          (let* ((needle (ename->handle ename 'entnext))
                 (tail (member needle order :test #'string=)))
            (first-live (rest tail)))))))

(defmethod host-handent ((host mock-host) handle-string)
  (let ((value
         (etypecase handle-string
           (string handle-string)
           (clautolisp.autolisp-runtime:autolisp-string
            (clautolisp.autolisp-runtime:autolisp-string-value handle-string)))))
    (and (safe-find-entity (mock-host-active-drawing host) value)
         (handle->ename value))))
