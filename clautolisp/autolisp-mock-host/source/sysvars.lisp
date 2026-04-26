(in-package #:clautolisp.autolisp-mock-host)

;;;; Default symbol-table records and sysvar cells installed in a
;;;; freshly-constructed MockHost.
;;;;
;;;; The defaults track the conservative subset called out in the
;;;; implementation roadmap. They are deliberately small: real-world
;;;; AutoCAD has many hundreds of sysvars; we ship the ones that
;;;; published AutoLISP corpora actually consult.

;;; --- Symbol-table defaults --------------------------------------

(defparameter *default-table-records*
  ;; (table-kind . list-of-record-names)
  '((:block-record . ("*Model_Space" "*Paper_Space"))
    (:layer        . ("0"))
    (:ltype        . ("BYBLOCK" "BYLAYER" "Continuous"))
    (:style        . ("Standard"))
    (:dimstyle     . ("Standard"))
    (:vport        . ("*Active"))
    (:ucs          . ())
    (:view         . ())
    (:appid        . ("ACAD"))))

(defun populate-default-tables (mock)
  "Pre-populate MOCK with the standard empty AutoCAD symbol
tables so tblsearch / tblnext have a sensible baseline."
  (let ((tables (mock-host-tables mock)))
    (dolist (entry *default-table-records*)
      (let* ((kind  (car entry))
             (names (cdr entry))
             (per-kind (or (gethash kind tables)
                           (setf (gethash kind tables)
                                 (make-hash-table :test #'equalp)))))
        (dolist (name names)
          (setf (gethash name per-kind)
                (make-symbol-table-record
                 :kind kind :name name
                 :data (list (cons 0 (string-upcase (symbol-name kind)))
                             (cons 2 name))))))))
  mock)

;;; --- Sysvar defaults --------------------------------------------

(defparameter *default-sysvars*
  ;; (NAME KIND DEFAULT-VALUE READ-ONLY-P)
  '(("CMDECHO" :integer 1 nil)
    ("CECOLOR" :string  "BYLAYER" nil)
    ("CLAYER"  :string  "0" nil)
    ("ANGBASE" :real    0.0d0 nil)
    ("ANGDIR"  :integer 0 nil)
    ("AUNITS"  :integer 0 nil)
    ("OSMODE"  :integer 0 nil)
    ;; User-extensible scratch slots traditionally available on
    ;; every AutoLISP host. Useful for tests as well.
    ("USERR1" :real 0.0d0 nil) ("USERR2" :real 0.0d0 nil)
    ("USERR3" :real 0.0d0 nil) ("USERR4" :real 0.0d0 nil)
    ("USERR5" :real 0.0d0 nil)
    ("USERI1" :integer 0 nil) ("USERI2" :integer 0 nil)
    ("USERI3" :integer 0 nil) ("USERI4" :integer 0 nil)
    ("USERI5" :integer 0 nil)
    ("USERS1" :string "" nil) ("USERS2" :string "" nil)
    ("USERS3" :string "" nil) ("USERS4" :string "" nil)
    ("USERS5" :string "" nil)
    ;; A handful of read-only conveniences used by typical
    ;; programs; the values are mockup and may diverge from any
    ;; specific real-host build.
    ("DWGNAME" :string "Drawing.dwg" t)
    ("DWGPREFIX" :string "" t)
    ("PLATFORM"  :string "Mock CAD" t)
    ("LISPSYS"   :integer 1 nil)))

(defun populate-default-sysvars (mock)
  "Pre-populate MOCK's sysvar table with the conservative subset."
  (let ((table (mock-host-sysvars mock)))
    (dolist (spec *default-sysvars* mock)
      (destructuring-bind (name kind default read-only-p) spec
        (setf (gethash name table)
              (make-sysvar-cell :name name
                                :kind kind
                                :value default
                                :read-only-p read-only-p))))))

;;; --- Convenience accessors -------------------------------------

(defun mock-host-table (mock kind)
  "Return the per-kind symbol-table hash-table for MOCK, creating
it on first reference."
  (let ((tables (mock-host-tables mock)))
    (or (gethash kind tables)
        (setf (gethash kind tables)
              (make-hash-table :test #'equalp)))))

(defun mock-host-find-table-record (mock kind name)
  (gethash name (mock-host-table mock kind)))

(defun mock-host-add-table-record (mock record)
  (let ((per-kind (mock-host-table mock (symbol-table-record-kind record))))
    (setf (gethash (symbol-table-record-name record) per-kind) record)
    record))

(defun mock-host-sysvar (mock name)
  (gethash name (mock-host-sysvars mock)))

(defun mock-host-set-sysvar (mock name value)
  (let ((cell (mock-host-sysvar mock name)))
    (when cell
      (when (sysvar-cell-read-only-p cell)
        (signal-host-not-supported mock 'setvar))
      (setf (sysvar-cell-value cell) value)
      value)))
