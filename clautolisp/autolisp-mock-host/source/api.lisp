(in-package #:clautolisp.autolisp-mock-host)

;;;; Constructor + snapshot helpers for MockHost.
;;;;
;;;; Phase 9 deliverable. The `mock-host` class itself is defined in
;;;; model.lisp; this file ties together the populate-* helpers and
;;;; provides the test-friendly constructor and snapshot/restore
;;;; primitives the implementation roadmap calls for.

(defun make-mock-host (&key (name "mock-host")
                              (populate-tables-p t)
                              (populate-sysvars-p t)
                              prompt-stream)
  "Build a fresh MockHost. By default the standard AutoCAD symbol
tables and the conservative sysvar subset are populated; pass
:populate-tables-p nil or :populate-sysvars-p nil for a bare mock
host (e.g. for empty-fixture tests). PROMPT-STREAM, if supplied,
is the input source the headless interactive prompts will read
from."
  (let ((mock (make-instance 'mock-host :name name)))
    (when populate-tables-p (populate-default-tables mock))
    (when populate-sysvars-p (populate-default-sysvars mock))
    (when prompt-stream
      (setf (mock-host-prompt-stream mock) prompt-stream))
    mock))

;;; --- Snapshot / restore ----------------------------------------
;;;
;;; The serialised form is a property list that can be read /
;;; written via the host CL printer. It captures only the
;;; AutoLISP-visible state: entities, picksets, table records,
;;; named-object dictionary entries, and sysvars. The display log
;;; and prompt streams are *not* part of the snapshot — tests that
;;; care about those compare them separately.

(defun snapshot-table (table render-value)
  (let ((entries '()))
    (maphash (lambda (k v)
               (push (cons k (funcall render-value v)) entries))
             table)
    (sort entries (lambda (a b)
                    (string< (princ-to-string (car a))
                             (princ-to-string (car b)))))))

(defun snapshot-entity (entity)
  (list :id        (princ-to-string (entity-handle-id entity))
        :kind      (entity-handle-kind entity)
        :block     (entity-handle-block entity)
        :layer     (entity-handle-layer entity)
        :data      (entity-handle-data entity)
        :deleted-p (entity-handle-deleted-p entity)))

(defun snapshot-pickset (pickset)
  (list :id      (princ-to-string (pickset-id pickset))
        :members (mapcar (lambda (e) (princ-to-string (entity-handle-id e)))
                         (pickset-members pickset))))

(defun snapshot-table-record (record)
  (list :id   (princ-to-string (symbol-table-record-id record))
        :kind (symbol-table-record-kind record)
        :name (symbol-table-record-name record)
        :data (symbol-table-record-data record)))

(defun snapshot-sysvar (cell)
  (list :name (sysvar-cell-name cell)
        :kind (sysvar-cell-kind cell)
        :value (sysvar-cell-value cell)
        :read-only-p (sysvar-cell-read-only-p cell)))

(defun mock-host-snapshot (mock)
  "Return a serialisable snapshot of MOCK's host-visible state. The
value is a property list suitable for round-trip through ~prin1~ /
~read~ (with ~with-standard-io-syntax~)."
  (let* ((entity-snapshot
          (snapshot-table (mock-host-entities mock) #'snapshot-entity))
         (pickset-snapshot
          (snapshot-table (mock-host-picksets mock) #'snapshot-pickset))
         (tables-snapshot
          (let ((acc '()))
            (maphash
             (lambda (kind per-kind)
               (push (cons kind
                           (snapshot-table per-kind #'snapshot-table-record))
                     acc))
             (mock-host-tables mock))
            (sort acc (lambda (a b) (string< (symbol-name (car a))
                                              (symbol-name (car b)))))))
         (sysvars-snapshot
          (snapshot-table (mock-host-sysvars mock) #'snapshot-sysvar)))
    (list :name (host-name mock)
          :entities entity-snapshot
          :picksets pickset-snapshot
          :tables tables-snapshot
          :sysvars sysvars-snapshot
          :pickfirst (and (mock-host-pickfirst mock)
                          (princ-to-string
                           (pickset-id (mock-host-pickfirst mock)))))))

(defun mock-host-restore (mock snapshot)
  "Restore MOCK from a snapshot produced by mock-host-snapshot.
Mutates MOCK in place; returns MOCK. Existing state is *replaced*,
not merged: the entities / picksets / tables / sysvars hash-tables
are cleared first."
  ;; Clear.
  (clrhash (mock-host-entities mock))
  (clrhash (mock-host-picksets mock))
  (let ((tables (mock-host-tables mock)))
    (maphash (lambda (k per-kind)
               (declare (ignore k))
               (clrhash per-kind))
             tables)
    (clrhash tables))
  (clrhash (mock-host-sysvars mock))
  (setf (mock-host-pickfirst mock) nil)
  ;; Restore.
  (let ((entity-by-id (make-hash-table :test #'equal)))
    (dolist (pair (getf snapshot :entities))
      (let* ((plist (cdr pair))
             (id-string (getf plist :id))
             (handle (make-entity-handle
                      :kind      (getf plist :kind)
                      :block     (getf plist :block)
                      :layer     (getf plist :layer)
                      :data      (getf plist :data)
                      :deleted-p (getf plist :deleted-p))))
        (setf (gethash id-string entity-by-id) handle
              (gethash (entity-handle-id handle)
                       (mock-host-entities mock))
              handle)))
    (dolist (pair (getf snapshot :picksets))
      (let* ((plist   (cdr pair))
             (members (mapcar (lambda (id)
                                (gethash id entity-by-id))
                              (getf plist :members)))
             (set     (make-pickset :members members)))
        (setf (gethash (pickset-id set) (mock-host-picksets mock)) set))))
  (dolist (pair (getf snapshot :tables))
    (let ((kind (car pair)))
      (dolist (record-pair (cdr pair))
        (let* ((plist  (cdr record-pair))
               (record (make-symbol-table-record
                        :kind (or (getf plist :kind) kind)
                        :name (getf plist :name)
                        :data (getf plist :data))))
          (mock-host-add-table-record mock record)))))
  (dolist (pair (getf snapshot :sysvars))
    (let* ((plist (cdr pair))
           (cell  (make-sysvar-cell
                   :name        (getf plist :name)
                   :kind        (getf plist :kind)
                   :value       (getf plist :value)
                   :read-only-p (getf plist :read-only-p))))
      (setf (gethash (sysvar-cell-name cell) (mock-host-sysvars mock)) cell)))
  mock)
