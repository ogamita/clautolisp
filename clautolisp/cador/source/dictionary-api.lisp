(in-package #:clautolisp.cador)

;;;; Named-object-dictionary, xrecord and REGAPP HAL methods on
;;;; MockHost — the AutoLISP adapter over the pure-CL dictionary /
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
  (let* ((handle (ename->handle dict-ename operator-name))
         (drawing (cador-active-drawing host)))
    (and (clautolisp.drawing:find-dictionary drawing handle) handle)))

;;; --- Method definitions -----------------------------------------

(defmethod host-namedobjdict ((host cador))
  (let* ((drawing (cador-active-drawing host))
         (root (clautolisp.drawing:ensure-root-dictionary drawing)))
    (handle->ename host (clautolisp.drawing:entity-handle-id root))))

(defmethod host-dictsearch ((host cador) dict-ename name &key next-after)
  (let* ((drawing (cador-active-drawing host))
         (dict-handle (%require-dict-handle host dict-ename 'dictsearch)))
    (when dict-handle
      (let* ((key (mock-string-value name))
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
      (let ((key (mock-string-value name))
            (object-handle (ename->handle object-ename 'dictadd)))
        (when (and key
                   (clautolisp.drawing:dictionary-add-entry
                    drawing dict-handle key object-handle))
          object-ename)))))

(defmethod host-dictremove ((host cador) dict-ename name)
  (let* ((drawing (cador-active-drawing host))
         (dict-handle (%require-dict-handle host dict-ename 'dictremove)))
    (when dict-handle
      (let* ((key (mock-string-value name))
             (removed (and key (clautolisp.drawing:dictionary-remove-entry
                                drawing dict-handle key))))
        (and removed (handle->ename host removed))))))

(defmethod host-dictrename ((host cador) dict-ename old new)
  (let* ((drawing (cador-active-drawing host))
         (dict-handle (%require-dict-handle host dict-ename 'dictrename)))
    (when dict-handle
      (let ((old-key (mock-string-value old))
            (new-key (mock-string-value new)))
        (when (and old-key new-key
                   (clautolisp.drawing:dictionary-rename-entry
                    drawing dict-handle old-key new-key))
          (clautolisp.autolisp-runtime:make-autolisp-string new-key))))))

(defmethod host-dictobjname ((host cador) dict-ename name)
  (let* ((drawing (cador-active-drawing host))
         (dict-handle (%require-dict-handle host dict-ename 'dictobjname)))
    (when dict-handle
      (let* ((key (mock-string-value name))
             (member (and key (clautolisp.drawing:dictionary-member-handle
                               drawing dict-handle key))))
        (and member (safe-find-entity drawing member) (handle->ename host member))))))

(defmethod host-regapp ((host cador) name)
  (let ((app (mock-string-value name)))
    (and app
         (clautolisp.drawing:register-appid (cador-active-drawing host) app)
         (clautolisp.autolisp-runtime:make-autolisp-string app))))
