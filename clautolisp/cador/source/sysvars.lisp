(in-package #:clautolisp.cador)

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
  (let ((tables (cador-tables mock)))
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

;;; --- clautolisp-specific default drawing format ----------------
;;;
;;; CLAUTOLISPDEFAULTDRAWINGFORMAT (a clautolisp extension system variable —
;;; no vendor counterpart; documented in the autolisp-spec clautolisp
;;; deviation note and in the clautolisp user manual) names the file format
;;; a drawing is written in when nothing else determines one: SaveAs to a
;;; path whose extension is not a known drawing type, or a freshly created
;;; drawing that has never been read from disk. It is shared by cador and
;;; cadtui (cadtui runs on the cador core). Its initial value comes from the
;;; environment variable of the same name, and is DXF (ASCII DXF, the
;;; portable form) when that is unset or invalid. A recognised extension or
;;; a drawing that already knows its own format still wins over it.

(defparameter +default-drawing-format-sysvar+ "CLAUTOLISPDEFAULTDRAWINGFORMAT"
  "Name of the clautolisp default-drawing-format system / environment
variable.")

(defparameter *clautolisp-extension-sysvar-names*
  (list +default-drawing-format-sysvar+)
  "The clautolisp-specific system variables with no vendor counterpart, which
INSTALL-CLAUTOLISP-EXTENSION-SYSVARS adds on top of whichever vendor catalogue
was loaded. Their count is why a populated mock carries
(length *full-sysvar-catalogue*) + (length *clautolisp-extension-sysvar-names*)
sysvar cells.")

(defparameter *default-drawing-format-values*
  '(("DXF" . :dxf-ascii)
    ("DWG" . :dwg))
  "Accepted CLAUTOLISPDEFAULTDRAWINGFORMAT values: the sysvar string (upcased)
mapped to a clautolisp.drawing codec keyword. DXF is ASCII DXF.")

(defun %canonical-default-drawing-format (raw)
  "The accepted format NAME (\"DXF\" / \"DWG\") RAW denotes, case- and
whitespace-insensitively, or NIL if RAW is not one of them."
  (and (stringp raw)
       (car (assoc (string-upcase (string-trim '(#\Space #\Tab) raw))
                   *default-drawing-format-values* :test #'string=))))

(defun %default-drawing-format-initial-value ()
  "The initial CLAUTOLISPDEFAULTDRAWINGFORMAT value: the environment variable
of the same name when it names an accepted format, otherwise \"DXF\"."
  (or (%canonical-default-drawing-format
       (uiop:getenv +default-drawing-format-sysvar+))
      "DXF"))

(defun install-clautolisp-extension-sysvars (mock)
  "Install the clautolisp-specific system variables that have no vendor
counterpart, on top of whichever vendor catalogue was loaded. Currently just
CLAUTOLISPDEFAULTDRAWINGFORMAT. Returns MOCK."
  (setf (gethash +default-drawing-format-sysvar+ (cador-sysvars mock))
        (make-sysvar-cell :name +default-drawing-format-sysvar+
                          :kind :string
                          :value (%default-drawing-format-initial-value)
                          :read-only-p nil
                          :host-derived-p nil))
  mock)

(defun cador-default-drawing-format (mock)
  "The clautolisp.drawing codec keyword MOCK writes a drawing in when nothing
else determines the format — parsed from the CLAUTOLISPDEFAULTDRAWINGFORMAT
system variable, or :dxf-ascii when it is unset or holds an unrecognised
value."
  (let* ((cell (cador-sysvar mock +default-drawing-format-sysvar+))
         (name (and cell (%canonical-default-drawing-format
                          (sysvar-cell-value cell)))))
    (cdr (assoc (or name "DXF") *default-drawing-format-values* :test #'string=))))

(defun populate-default-sysvars (mock &key (catalogue :full))
  "Pre-populate MOCK's sysvar table.

CATALOGUE selects the table installed:

  :FULL (default) installs the 1836-entry catalogue generated from
    autolisp-spec/documentation/system-variables-inventory.sexp
    (see sysvar-catalogue.lisp). This mirrors what AutoCAD 2026 ENU
    and BricsCAD V25 document and is what production callers want.

  :SEED installs only the small *DEFAULT-SYSVARS* list above (the
    legacy ~30-entry stand-in). Useful for low-overhead test
    fixtures that need a deterministic, hand-curated subset.

In both modes the entries are five-tuples
  (NAME KIND DEFAULT READ-ONLY-P [HOST-DERIVED-P])
with HOST-DERIVED-P defaulting to NIL for the :SEED list."
  (let ((table (cador-sysvars mock))
        (entries (ecase catalogue
                   (:full *full-sysvar-catalogue*)
                   (:seed *default-sysvars*))))
    (dolist (spec entries)
      ;; Tolerate both the 4-tuple (legacy) and 5-tuple (full) shapes.
      (let* ((name        (first spec))
             (kind        (second spec))
             (default     (third spec))
             (read-only-p (fourth spec))
             (host-derived-p (and (cdr (cdddr spec)) (fifth spec))))
        (setf (gethash name table)
              (make-sysvar-cell :name name
                                :kind kind
                                :value default
                                :read-only-p read-only-p
                                :host-derived-p host-derived-p))))
    ;; The clautolisp extension sysvars sit on top of either catalogue.
    (install-clautolisp-extension-sysvars mock)))

;;; --- Convenience accessors -------------------------------------

(defun cador-table (mock kind)
  "Return the per-kind symbol-table hash-table for MOCK, creating
it on first reference."
  (let ((tables (cador-tables mock)))
    (or (gethash kind tables)
        (setf (gethash kind tables)
              (make-hash-table :test #'equalp)))))

(defun cador-find-table-record (mock kind name)
  (gethash name (cador-table mock kind)))

(defun cador-add-table-record (mock record)
  (let ((per-kind (cador-table mock (symbol-table-record-kind record))))
    (setf (gethash (symbol-table-record-name record) per-kind) record)
    record))

(defun cador-sysvar (mock name)
  (gethash name (cador-sysvars mock)))

(defun cador-set-sysvar (mock name value)
  (let ((cell (cador-sysvar mock name)))
    (when cell
      (when (sysvar-cell-read-only-p cell)
        (signal-host-not-supported mock 'setvar))
      (setf (sysvar-cell-value cell) value)
      value)))

(defun cador-copy-sysvar-table (table)
  "An independent copy of a sysvar TABLE: a fresh hash-table holding
fresh cells. Sharing a cell would make a `snapshot' a live view, and the
whole point of one is that restoring it undoes every intervening
define / undefine / setvar."
  (let ((copy (make-hash-table :test #'equalp :size (hash-table-count table))))
    (maphash (lambda (name cell)
               (setf (gethash name copy) (copy-sysvar-cell cell)))
             table)
    copy))

(defun cador-remove-sysvar (mock name)
  "Drop the sysvar cell NAME from MOCK. After this, getvar returns nil
\(unknown name) and setvar signals unknown-sysvar — the behaviour of a
real CAD for a variable it does not define. Returns T when a cell was
removed, nil when NAME was already absent."
  (remhash name (cador-sysvars mock)))
