(in-package #:clautolisp.autolisp-mock-host)

;;;; Entity-level HAL methods for MockHost (Phase 10).
;;;;
;;;; Implements: host-entget, host-entmod, host-entmake,
;;;; host-entmakex, host-entdel, host-entupd, host-entlast,
;;;; host-entnext, host-handent.
;;;;
;;;; The AutoLISP-visible ENAME (a `clautolisp.autolisp-runtime:autolisp-ename`)
;;;; wraps the host-allocated hex handle string. MockHost stores a
;;;; reverse-order creation-order list, so ENTLAST returns the most
;;;; recently created non-deleted entity in O(1) amortised, and
;;;; ENTNEXT walks the list in forward order.

;;; --- Internal helpers --------------------------------------------

(defun ename->handle (ename operator-name)
  "Extract the hex handle string from an AutoLISP ENAME, signalling
an :invalid-ename runtime error if ENAME is not an ename."
  (unless (typep ename 'clautolisp.autolisp-runtime:autolisp-ename)
    (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
     :invalid-ename
     "~A expects an ENAME, got ~S."
     operator-name ename))
  (clautolisp.autolisp-runtime:autolisp-ename-value ename))

(defun handle->ename (handle)
  "Wrap a hex handle string in an AutoLISP ENAME."
  (clautolisp.autolisp-runtime:make-autolisp-ename :value handle))

(defun mock-host-allocate-handle (mock)
  "Allocate the next hex handle string for MOCK and bump its
counter. Returns the new handle string."
  (let* ((n (mock-host-next-handle-counter mock))
         (string (format nil "~X" n)))
    (incf (mock-host-next-handle-counter mock))
    string))

(defun mock-host-find-entity-by-handle (mock handle)
  "Return the entity-handle stored under HANDLE, or nil if no such
entity exists or it has been deleted."
  (let ((entity (gethash handle (mock-host-entities mock))))
    (and entity (not (entity-handle-deleted-p entity)) entity)))

(defun group-code-equal-p (a b)
  "Equality predicate for DXF group-code keys: both are usually
integers, but real AutoLISP corpora occasionally encode them as
small reals when read from a file."
  (or (eql a b) (and (numberp a) (numberp b) (= a b))))

(defun normalize-entity-data (data &key handle ename)
  "Inject the host-managed bookkeeping group codes (-1 . ename) and
(5 . handle) into a DXF data list, keeping any caller-supplied
values under other group codes and stripping any caller-supplied
-1 / 5 entries (the host owns those)."
  (let ((stripped '()))
    (dolist (pair data)
      (when (consp pair)
        (let ((code (car pair)))
          (unless (or (group-code-equal-p code -1)
                      (group-code-equal-p code 5))
            (push pair stripped)))))
    (let ((tail (nreverse stripped)))
      (cons (cons -1 ename)
            (cons (cons 5 handle) tail)))))

(defun extract-group-0-marker (data operator-name)
  "Pull the (0 . \"TYPE\") marker out of a DXF data list. Signals
:invalid-entity-data if it is missing or malformed."
  (dolist (pair data)
    (when (and (consp pair) (group-code-equal-p (car pair) 0))
      (let ((value (cdr pair)))
        (cond
          ((typep value 'clautolisp.autolisp-runtime:autolisp-string)
           (return-from extract-group-0-marker
             (clautolisp.autolisp-runtime:autolisp-string-value value)))
          ((stringp value)
           (return-from extract-group-0-marker value))))))
  (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
   :invalid-entity-data
   "~A requires a (0 . \"TYPE\") marker at the head of the entity data, got ~S."
   operator-name data))

(defun ensure-group-code-list (data operator-name)
  (unless (listp data)
    (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
     :invalid-entity-data
     "~A expects a DXF group-code list, got ~S."
     operator-name data)))

(defun extract-ename-from-data (data operator-name)
  "Return the entity-handle's hex string from a (-1 . ENAME) entry
in DATA, signalling :invalid-entity-data if missing."
  (dolist (pair data)
    (when (and (consp pair) (group-code-equal-p (car pair) -1))
      (let ((value (cdr pair)))
        (when (typep value 'clautolisp.autolisp-runtime:autolisp-ename)
          (return-from extract-ename-from-data
            (clautolisp.autolisp-runtime:autolisp-ename-value value))))))
  (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
   :invalid-entity-data
   "~A requires the modified entity's (-1 . <ENAME>) entry in the data list."
   operator-name))

;;; --- Host method implementations ---------------------------------

(defmethod host-entget ((host mock-host) ename)
  (let* ((handle (ename->handle ename 'entget))
         (entity (mock-host-find-entity-by-handle host handle)))
    (and entity (entity-handle-data entity))))

(defmethod host-entmod ((host mock-host) data)
  (ensure-group-code-list data 'entmod)
  (let* ((handle (extract-ename-from-data data 'entmod))
         (entity (gethash handle (mock-host-entities host))))
    (cond
      ((null entity) nil)
      ((entity-handle-deleted-p entity) nil)
      (t
       (setf (entity-handle-data entity)
             (normalize-entity-data data
                                    :handle handle
                                    :ename (handle->ename handle)))
       data))))

(defmethod host-entmake ((host mock-host) data)
  (ensure-group-code-list data 'entmake)
  (let* ((kind-string (extract-group-0-marker data 'entmake))
         (handle (mock-host-allocate-handle host))
         (ename (handle->ename handle))
         (data* (normalize-entity-data data :handle handle :ename ename))
         (entity (make-entity-handle
                  :id   handle
                  :kind (intern (string-upcase kind-string) "KEYWORD")
                  :data data*)))
    (setf (gethash handle (mock-host-entities host)) entity)
    (push handle (mock-host-creation-order host))
    data*))

(defmethod host-entmakex ((host mock-host) data)
  ;; Same shape as entmake — MockHost does not yet distinguish
  ;; graphical from non-graphical entities for storage purposes.
  ;; Phase 10 callers receiving xrecord-shaped data succeed; later
  ;; phases may add a non-graphical flag if it becomes load-bearing.
  (host-entmake host data))

(defmethod host-entdel ((host mock-host) ename)
  (let* ((handle (ename->handle ename 'entdel))
         (entity (gethash handle (mock-host-entities host))))
    (cond
      ((null entity) nil)
      (t
       ;; AutoLISP's entdel is a toggle: if the entity is already
       ;; deleted, calling entdel again undeletes it (within the
       ;; current command's extent). MockHost honours the toggle.
       (setf (entity-handle-deleted-p entity)
             (not (entity-handle-deleted-p entity)))
       ename))))

(defmethod host-entupd ((host mock-host) ename)
  (let* ((handle (ename->handle ename 'entupd))
         (entity (mock-host-find-entity-by-handle host handle)))
    (and entity ename)))

(defmethod host-entlast ((host mock-host))
  ;; Find the most recently created entity that is not deleted.
  (loop for handle in (mock-host-creation-order host)
        for entity = (gethash handle (mock-host-entities host))
        when (and entity (not (entity-handle-deleted-p entity)))
          return (handle->ename handle)
        finally (return nil)))

(defmethod host-entnext ((host mock-host) ename)
  ;; (entnext)         -> the FIRST non-deleted entity, or nil.
  ;; (entnext ENAME)   -> the next non-deleted entity after ENAME
  ;;                       in creation order, or nil.
  (let ((order (reverse (mock-host-creation-order host))))
    (cond
      ((null ename)
       (loop for handle in order
             for entity = (gethash handle (mock-host-entities host))
             when (and entity (not (entity-handle-deleted-p entity)))
               return (handle->ename handle)
             finally (return nil)))
      (t
       (let* ((needle (ename->handle ename 'entnext))
              (tail (member needle order :test #'string=)))
         (loop for handle in (rest tail)
               for entity = (gethash handle (mock-host-entities host))
               when (and entity (not (entity-handle-deleted-p entity)))
                 return (handle->ename handle)
               finally (return nil)))))))

(defmethod host-handent ((host mock-host) handle-string)
  (let ((value
         (etypecase handle-string
           (string handle-string)
           (clautolisp.autolisp-runtime:autolisp-string
            (clautolisp.autolisp-runtime:autolisp-string-value handle-string)))))
    (let ((entity (mock-host-find-entity-by-handle host value)))
      (and entity (handle->ename value)))))
