(in-package #:clautolisp.autolisp-mock-host)

;;;; Symbol-table walker HAL methods on MockHost (Phase 11).
;;;;
;;;; Implements: host-tblsearch, host-tblnext, host-tblobjname.
;;;;
;;;; Per-kind iteration state is kept on mock-host-tblnext-iterators
;;;; (a hash-table from kind keyword to remaining-list). REWIND
;;;; restarts the walk; without REWIND, each call advances by one.

;;; --- Helpers -----------------------------------------------------

(defun resolve-table-kind (kind operator-name)
  "Coerce KIND from an AutoLISP-string / CL-string / keyword to
the MockHost's per-kind keyword."
  (let ((string (cond
                  ((typep kind 'clautolisp.autolisp-runtime:autolisp-string)
                   (clautolisp.autolisp-runtime:autolisp-string-value kind))
                  ((stringp kind) kind)
                  ((keywordp kind) (string-downcase (symbol-name kind)))
                  (t nil))))
    (unless (and string (plusp (length string)))
      (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
       :invalid-table-kind
       "~A expects a table-kind name, got ~S."
       operator-name kind))
    (let ((upcased (string-upcase string)))
      (cond
        ((member upcased '("LAYER") :test #'string=) :layer)
        ((member upcased '("LTYPE" "LINETYPE") :test #'string=) :ltype)
        ((member upcased '("STYLE" "TEXTSTYLE") :test #'string=) :style)
        ((member upcased '("DIMSTYLE") :test #'string=) :dimstyle)
        ((member upcased '("VIEW") :test #'string=) :view)
        ((member upcased '("UCS") :test #'string=) :ucs)
        ((member upcased '("VPORT" "VIEWPORT") :test #'string=) :vport)
        ((member upcased '("APPID") :test #'string=) :appid)
        ((member upcased '("BLOCK" "BLOCK_RECORD") :test #'string=)
         :block-record)
        (t (intern (string-downcase upcased) "KEYWORD"))))))

(defun resolve-record-name (name operator-name)
  (cond
    ((typep name 'clautolisp.autolisp-runtime:autolisp-string)
     (clautolisp.autolisp-runtime:autolisp-string-value name))
    ((stringp name) name)
    (t
     (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
      :invalid-table-name
      "~A expects a record name string, got ~S."
      operator-name name))))

(defun table-record->ename (record)
  "Wrap a table-record's id in an ENAME so AutoLISP code can
round-trip table identity through tblobjname."
  (clautolisp.autolisp-runtime:make-autolisp-ename
   :value (symbol-table-record-id record)))

;;; --- Method definitions ------------------------------------------

;;; Table records store PURE Common-Lisp values (CL strings). The
;;; AutoLISP view wraps every string value as an autolisp-string —
;;; exactly like ENTITY->AL-VIEW does for entities — so that user code
;;; can (strcat), (=) and (type) the values a tblsearch / tblnext record
;;; yields. Without this wrap the raw CL strings would reject those
;;; operators. Table records carry no (-1 . ename) head (tblobjname is
;;; the way to an ename), so we wrap the data list as-is.

(defun table-record->al-view (record)
  "The AutoLISP tblsearch / tblnext view of a table RECORD: its
group-code list with every string value wrapped as an autolisp-string."
  (pure->al-value (symbol-table-record-data record)))

(defmethod host-tblsearch ((host mock-host) kind name)
  (let ((record (mock-host-find-table-record host
                                              (resolve-table-kind kind 'tblsearch)
                                              (resolve-record-name name 'tblsearch))))
    (and record (table-record->al-view record))))

(defmethod host-tblnext ((host mock-host) kind &key rewind)
  (let* ((k (resolve-table-kind kind 'tblnext))
         (iterators (mock-host-tblnext-iterators host))
         (table (mock-host-table host k)))
    (when (or rewind (not (nth-value 1 (gethash k iterators))))
      ;; (Re)build the iterator only on first reference or on
      ;; explicit rewind; once exhausted (value = nil but key
      ;; present) further calls return nil until rewound.
      (let ((records '()))
        (maphash (lambda (name record)
                   (declare (ignore name))
                   (push record records))
                 table)
        (setf (gethash k iterators)
              (sort records (lambda (a b)
                              (string< (symbol-table-record-name a)
                                       (symbol-table-record-name b)))))))
    (let ((remaining (gethash k iterators)))
      (cond
        ((null remaining) nil)
        (t
         (let ((next (first remaining)))
           (setf (gethash k iterators) (rest remaining))
           (table-record->al-view next)))))))

(defmethod host-tblobjname ((host mock-host) kind name)
  (let ((record (mock-host-find-table-record host
                                              (resolve-table-kind kind 'tblobjname)
                                              (resolve-record-name name 'tblobjname))))
    (and record (table-record->ename record))))
