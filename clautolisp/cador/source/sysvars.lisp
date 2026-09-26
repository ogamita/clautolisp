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
          ;; FILL A GAP, never overwrite. A drawing created from the DXF
          ;; template already carries these records WITH their handles and
          ;; subclass markers, and replacing them with the bare pair below
          ;; is what would lose the structure a DWG write needs
          ;; (dwg-round-trip-loses-entities). The bare record remains the
          ;; right thing when nothing supplied one.
          (unless (gethash name per-kind)
            (setf (gethash name per-kind)
                  (make-symbol-table-record
                   :kind kind :name name
                   :data (list (cons 0 (substitute #\_ #\- (string-upcase (symbol-name kind))))
                               (cons 2 name)))))))))
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

;;; --- default drawing write format (container + version) --------
;;;
;;; The file format a drawing is written in when nothing else determines one
;;; (SaveAs to a path whose extension names no known drawing type, or a fresh
;;; drawing never read from disk) has two axes: the CONTAINER (ASCII DXF,
;;; binary DXF, or DWG) and the VERSION (DWG 2018 down to R9). Two system
;;; variables select it, and cador consults whichever suits the active dialect:
;;;
;;;   SAVEFORMAT — a *BricsCAD* system variable (integer 1..30, default 1 =
;;;   DWG 2018), already in the vendor catalogue. AutoCAD has NO counterpart —
;;;   its default save format lives in the Options dialog, not a sysvar — so
;;;   under a BricsCAD dialect SAVEFORMAT is the authoritative knob.
;;;
;;;   CLAUTOLISPDEFAULTDRAWINGFORMAT — a clautolisp extension system variable
;;;   (string, default "DXF"; e.g. "DWG", "DWG-2013", "DXFB-2000"). It is the
;;;   cross-dialect knob (and the only one AutoCAD-emulation runs have, since
;;;   AutoCAD offers no sysvar), seeded from the environment variable of the
;;;   same name. Shared by cador and cadtui.
;;;
;;; A recognised destination extension or a drawing that already knows its own
;;; format still wins over both. The VERSION axis is currently RECORDED (in the
;;; drawing and the DXF $ACADVER header) but the DXF/DWG writers still emit a
;;; fixed version — see the STUB in drawing/dxf.lisp / drawing-dwg/codec.lisp
;;; and issues/open/drawing-codec-version-output.issue.

(defparameter +default-drawing-format-sysvar+ "CLAUTOLISPDEFAULTDRAWINGFORMAT"
  "Name of the clautolisp default-drawing-format system / environment
variable.")

(defparameter +saveformat-sysvar+ "SAVEFORMAT"
  "Name of BricsCAD's save-format system variable, honoured under a BricsCAD
dialect.")

(defparameter *clautolisp-extension-sysvar-names*
  (list +default-drawing-format-sysvar+)
  "The clautolisp-specific system variables with no vendor counterpart, which
INSTALL-CLAUTOLISP-EXTENSION-SYSVARS adds on top of whichever vendor catalogue
was loaded (SAVEFORMAT is NOT here — it is a BricsCAD sysvar already in the
catalogue). Their count is why a populated mock carries
(length *full-sysvar-catalogue*) + (length *clautolisp-extension-sysvar-names*)
sysvar cells.")

(defparameter *drawing-format-container-values*
  ;; Longest keys first so DXFB is matched before DXF as a prefix.
  '(("DXFB" . :dxf-binary)
    ("BDXF" . :dxf-binary)
    ("DWG"  . :dwg)
    ("DXF"  . :dxf-ascii))
  "CLAUTOLISPDEFAULTDRAWINGFORMAT container tokens -> clautolisp.drawing codec
keyword. DXF is ASCII DXF; DXFB / BDXF are binary DXF.")

(defparameter *drawing-format-version-labels*
  '(("2018" . :ac1032) ("2013" . :ac1027) ("2010" . :ac1024)
    ("2007" . :ac1021) ("2004" . :ac1018) ("2000" . :ac1015)
    ("R14"  . :ac1014) ("R13"  . :ac1012) ("R12"  . :ac1009)
    ("R11"  . :ac1009) ("R10"  . :ac1006) ("R9"   . :ac1004))
  "Version labels a CLAUTOLISPDEFAULTDRAWINGFORMAT value may carry, mapped to
the DXF $ACADVER keyword the drawing model uses.")

(defparameter *saveformat-decode*
  ;; BricsCAD SAVEFORMAT integer -> (CONTAINER VERSION). Value 1 is the
  ;; default (DWG 2018). Table per
  ;; https://help.bricsys.com/en-us/document/system-variable-reference/s/saveformat-system-variable
  '((1  :dwg :ac1032) (2  :dxf-ascii :ac1032) (3  :dxf-binary :ac1032)
    (4  :dwg :ac1027) (5  :dxf-ascii :ac1027) (6  :dxf-binary :ac1027)
    (7  :dwg :ac1024) (8  :dxf-ascii :ac1024) (9  :dxf-binary :ac1024)
    (10 :dwg :ac1021) (11 :dxf-ascii :ac1021) (12 :dxf-binary :ac1021)
    (13 :dwg :ac1018) (14 :dxf-ascii :ac1018) (15 :dxf-binary :ac1018)
    (16 :dwg :ac1015) (17 :dxf-ascii :ac1015) (18 :dxf-binary :ac1015)
    (19 :dwg :ac1014) (20 :dxf-ascii :ac1014) (21 :dxf-binary :ac1014)
    (22 :dwg :ac1012) (23 :dxf-ascii :ac1012) (24 :dxf-binary :ac1012)
    (25 :dwg :ac1009) (26 :dxf-ascii :ac1009) (27 :dxf-binary :ac1009)
    (28 :dxf-ascii :ac1006) (29 :dxf-binary :ac1006)
    (30 :dxf-ascii :ac1004))
  "BricsCAD SAVEFORMAT integer decode: (INT CONTAINER VERSION).")

(defun %string-prefix-p (prefix string)
  (and (<= (length prefix) (length string))
       (string= prefix string :end2 (length prefix))))

(defun %parse-drawing-format-spec (raw)
  "Parse a CLAUTOLISPDEFAULTDRAWINGFORMAT string into (values CONTAINER
VERSION): a container token (DXF / DXFB / DWG) optionally followed by a
version label (\"DWG-2013\", \"DXF2000\"), case- and separator-insensitive.
CONTAINER is NIL when RAW names no known container."
  (when (stringp raw)
    (let* ((s (string-upcase (string-trim '(#\Space #\Tab #\-) raw)))
           (entry (find-if (lambda (e) (%string-prefix-p (car e) s))
                           *drawing-format-container-values*)))
      (if (null entry)
          (values nil nil)
          (let* ((rest (string-trim '(#\Space #\Tab #\- #\_)
                                    (subseq s (length (car entry)))))
                 (version (and (plusp (length rest))
                               (cdr (assoc rest *drawing-format-version-labels*
                                           :test #'string=)))))
            (values (cdr entry) version))))))

(defun %decode-saveformat (value)
  "Decode a BricsCAD SAVEFORMAT integer VALUE into (values CONTAINER VERSION),
or (values NIL NIL) when it is not an integer in the documented 1..30 range."
  (let ((row (and (integerp value) (assoc value *saveformat-decode*))))
    (if row (values (second row) (third row)) (values nil nil))))

(defun %bricscad-dialect-p (dialect-name)
  "True when DIALECT-NAME (a keyword like :bricscad-v26) is a BricsCAD dialect."
  (let ((name (and (symbolp dialect-name) (symbol-name dialect-name))))
    (and name (search "BRICSCAD" name) t)))

(defun %default-drawing-format-initial-value ()
  "The initial CLAUTOLISPDEFAULTDRAWINGFORMAT value: the environment variable
of the same name when it names a known container, otherwise \"DXF\"."
  (let ((env (uiop:getenv +default-drawing-format-sysvar+)))
    (if (and env (nth-value 0 (%parse-drawing-format-spec env)))
        (string-upcase (string-trim '(#\Space #\Tab) env))
        "DXF")))

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
  "Return (values CONTAINER VERSION) — the clautolisp.drawing codec keyword and
the DXF $ACADVER version keyword (or NIL for the codec's newest) MOCK writes a
drawing in when nothing else determines the format. The source is
dialect-dependent: under a BricsCAD dialect the vendor SAVEFORMAT integer
(default 1 = DWG 2018); otherwise the CLAUTOLISPDEFAULTDRAWINGFORMAT string
(default \"DXF\", version unspecified = codec newest)."
  (let ((dialect (ignore-errors
                   (clautolisp.autolisp-runtime:current-evaluation-dialect-name))))
    (if (%bricscad-dialect-p dialect)
        (multiple-value-bind (container version)
            (%decode-saveformat (let ((cell (cador-sysvar mock +saveformat-sysvar+)))
                                  (and cell (sysvar-cell-value cell))))
          (if container
              (values container version)
              (values :dwg :ac1032)))       ; BricsCAD SAVEFORMAT default
        (multiple-value-bind (container version)
            (%parse-drawing-format-spec
             (let ((cell (cador-sysvar mock +default-drawing-format-sysvar+)))
               (and cell (sysvar-cell-value cell))))
          (values (or container :dxf-ascii) version)))))

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
