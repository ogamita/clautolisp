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

(defun %cador-next-drawing-name (host)
  "The next untitled drawing name, numbered for the session as AutoCAD does:
Drawing2.dwg, Drawing3.dwg ... (Drawing1.dwg is the startup drawing)."
  (format nil "Drawing~D.dwg" (incf (cador-untitled-counter host))))

(defmethod initialize-instance :after ((host cador) &key)
  "Seed the document registry with the initial ACTIVE-DRAWING as the first,
current document, so DOCUMENTS is never empty and HOST-CURRENT-DOCUMENT has an
answer from the start."
  (let* ((drawing (cador-active-drawing host))
         (key (%cador-fresh-document-key host (drawing-name drawing))))
    (setf (cador-documents host) (list (cons key drawing))
          (cador-active-document-key host) key)))

(defun cador-prepare-document-drawing (host drawing)
  "Make DRAWING ready to be an open document of HOST, as the startup drawing
is (MAKE-CADOR): the default symbol tables where it has none, a full header
-- the catalogue with the template / locale values -- for the variables SAVED
IN THE DRAWING, with a file's own header values kept on top; and, for every
other variable (registry / preference / session: the application's), the
SAME cell as the current document's, so a SETVAR of OSMODE is seen by every
drawing (D2 §I.6). A drawing made by NEW used to have an empty header: every
GETVAR answered nil there. Returns DRAWING."
  (let ((file-cells (make-hash-table :test #'equalp))
        (shared (cador-sysvars host))
        (active (cador-active-drawing host)))
    (maphash (lambda (name cell) (setf (gethash name file-cells) cell))
             (clautolisp.drawing:drawing-header-variables drawing))
    (unwind-protect
         (progn
           (setf (cador-active-drawing host) drawing)
           (populate-default-tables host)
           (populate-default-sysvars host)
           (maphash (lambda (name cell)
                      (when (drawing-saved-sysvar-p name)
                        (let ((fresh (gethash name (cador-sysvars host))))
                          (if fresh
                              (setf (sysvar-cell-value fresh) (sysvar-cell-value cell))
                              (setf (gethash name (cador-sysvars host)) cell)))))
                    file-cells))
      (setf (cador-active-drawing host) active))
    (unless (eq shared (clautolisp.drawing:drawing-header-variables drawing))
      (maphash (lambda (name cell)
                 (unless (drawing-saved-sysvar-p name)
                   (setf (gethash name (clautolisp.drawing:drawing-header-variables drawing))
                         cell)))
               shared))
    ;; Preparing is not modifying.
    (setf (clautolisp.drawing:drawing-dbmod drawing) 0)
    drawing))

(defun cador-save-drawing (host drawing path &key format version)
  "Write DRAWING to PATH -- FORMAT / VERSION, then the drawing's own, the
path's extension, and as a last resort the dialect's default (SAVEFORMAT /
CLAUTOLISPDEFAULTDRAWINGFORMAT) -- and name it after the file, as AutoCAD's
DWGNAME then reports. Clears DBMOD (WRITE-DRAWING). Returns PATH."
  (multiple-value-bind (container default-version) (cador-default-drawing-format host)
    (let ((clautolisp.drawing:*default-drawing-format* container)
          (clautolisp.drawing:*default-drawing-version* default-version))
      (clautolisp.drawing:write-drawing drawing path :format format :version version)))
  (setf (clautolisp.drawing:drawing-name drawing) (file-namestring path))
  path)

(defun cador-close-document (host key &key save file)
  "Close open document KEY -- after saving it when SAVE (to FILE, or its own
file) -- making the next open drawing current and dropping the document's
LISP namespace; a session keeps a drawing, so the last one is replaced by a
fresh untitled one. Returns KEY."
  (let ((drawing (cdr (assoc key (cador-documents host) :test #'equal))))
    (when (and drawing save)
      (let ((path (or file (let ((p (clautolisp.drawing:drawing-path drawing)))
                             (and p (namestring p))))))
        (when path (cador-save-drawing host drawing path))))
    (when drawing
      (when (null (cdr (cador-documents host)))
        (host-open-document host))
      (host-close-document host key)
      (remhash key (cador-document-com-ids host))
      (remhash key (cador-document-sessions host))
      (clautolisp.autolisp-host:note-host-document-closed host key)
      (when (fboundp '%notify-ui) (funcall '%notify-ui host :document-closed key)))
    key))

(defmethod host-open-document ((host cador) &optional name)
  "Open a new empty drawing named NAME (default \"Drawing.dwg\"), register it,
and return its KEY. Does not change the current document."
  (let* ((dname (or name (%cador-next-drawing-name host)))
         (key (%cador-fresh-document-key host dname))
         ;; Empty unless CLAUTOLISPNEWDRAWINGTEMPLATE names a readable drawing
         ;; (pjb, 2026-09-26: the template is a sysvar, not a built-in change of
         ;; what `new document' means). CADOR-MAKE-NEW-DRAWING is the single
         ;; place that choice is made.
         (drawing (cador-prepare-document-drawing
                   host (cador-make-new-drawing host :name dname))))
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
