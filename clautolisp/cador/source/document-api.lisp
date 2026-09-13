(in-package #:clautolisp.cador)

;;;; Session and document management (HAL D1 Group 1) — cador-2 slice 1.
;;;;
;;;; The host now holds a SET of open documents, each carrying its own
;;;; CLAUTOLISP.DRAWING:DRAWING database, and a pointer (ACTIVE-DRAWING /
;;;; ACTIVE-DOCUMENT-KEY) to the current one. Every existing entity / table /
;;;; sysvar operation still goes through ACTIVE-DRAWING (the delegation shims
;;;; in model.lisp), so single-document behaviour is byte-for-byte unchanged:
;;;; a fresh cador has exactly one document, always current.
;;;;
;;;; What this slice adds is the registry and the D1 Group-1 generics to
;;;; open / close / enumerate / switch documents. It deliberately does NOT
;;;; yet migrate the per-document *session* state (picksets, ldata, iterators)
;;;; nor make cross-document handle dereference signal (C5): those, and the
;;;; runtime document-namespace <-> host-document link and the cooperative
;;;; scheduler, are the next increments (see cador-2-multidocument-runtime).
;;;; Handle identity is already per-drawing: ENAME-CACHE-DRAWING clears the
;;;; ename cache when ACTIVE-DRAWING changes, so a handle interned in one
;;;; document never aliases an entity in another; an entget of an unknown
;;;; handle in the current drawing returns nil, as it does today.

(defun %cador-fresh-document-key (host base)
  "A document KEY (string) derived from BASE, unique within HOST's DOCUMENTS.
Collisions get a <N> suffix so opening two \"Drawing.dwg\" yields distinct
keys."
  (let ((base (if (and (stringp base) (plusp (length base))) base "Drawing.dwg")))
    (if (assoc base (cador-documents host) :test #'string=)
        (loop :for i :from 2
              :for k := (format nil "~A<~D>" base i)
              :unless (assoc k (cador-documents host) :test #'string=)
                :return k)
        base)))

(defmethod initialize-instance :after ((host cador) &key)
  "Seed the document registry with the initial ACTIVE-DRAWING as the first,
current document, so DOCUMENTS is never empty and HOST-CURRENT-DOCUMENT has an
answer from the start."
  (let* ((drawing (cador-active-drawing host))
         (key (%cador-fresh-document-key host (drawing-name drawing))))
    (setf (cador-documents host) (list (cons key drawing))
          (cador-active-document-key host) key)))

(defmethod host-open-document ((host cador) &optional name)
  "Open a new empty drawing named NAME (default \"Drawing.dwg\"), register it,
and return its KEY. Does not change the current document."
  (let* ((dname (or name "Drawing.dwg"))
         (key (%cador-fresh-document-key host dname))
         (drawing (make-drawing :name dname)))
    (setf (cador-documents host)
          (append (cador-documents host) (list (cons key drawing))))
    key))

(defmethod host-activate-document ((host cador) key)
  "Make KEY the current document: point ACTIVE-DRAWING at its drawing. Signals
:no-such-document if KEY is not open."
  (let ((cell (assoc key (cador-documents host) :test #'string=)))
    (unless cell
      (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
       :no-such-document "cador has no open document with key ~S." key))
    (setf (cador-active-drawing host) (cdr cell)
          (cador-active-document-key host) key)
    key))

(defmethod host-current-document ((host cador))
  "The KEY of the current document."
  (cador-active-document-key host))

(defmethod host-document-list ((host cador))
  "The open document KEYs, in the order they were opened."
  (mapcar #'car (cador-documents host)))

(defmethod host-close-document ((host cador) key)
  "Close the document KEY. Returns T when a document was closed, NIL when KEY
was unknown. Refuses (signals :cannot-close-last-document) to close the only
open document — a cador must always have a current drawing. Closing the
current document activates the first remaining one."
  (let ((cell (assoc key (cador-documents host) :test #'string=)))
    (cond
      ((null cell) nil)
      ((null (cdr (cador-documents host)))
       (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
        :cannot-close-last-document
        "cador refuses to close the only open document ~S." key))
      (t
       (let ((was-current (string= key (or (cador-active-document-key host) ""))))
         (setf (cador-documents host) (remove cell (cador-documents host)))
         (when was-current
           (host-activate-document host (car (first (cador-documents host))))))
       t))))
