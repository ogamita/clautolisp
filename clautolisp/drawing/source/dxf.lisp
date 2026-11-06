(in-package #:clautolisp.drawing)

;;;; ASCII DXF codec (Phase 17c).
;;;;
;;;; A pure-Common-Lisp reader and writer for ASCII DXF, registered
;;;; against READ-DRAWING / WRITE-DRAWING for the :DXF-ASCII format.
;;;; DXF is the documented interchange format; it maps almost 1:1 onto
;;;; the drawing's group-code lists. SCHMS-family drawings are ordinary
;;;; DXF/DWG, so a faithful reader handles them.
;;;;
;;;; Scope of this phase: the HEADER, TABLES and ENTITIES sections —
;;;; the core the introspection tools (Phase 17d) need. BLOCKS and
;;;; OBJECTS are skipped on read and not emitted on write yet; binary
;;;; DXF and DWG come later (17e). The reader tolerates and skips any
;;;; section it does not model.
;;;;
;;;; Two representational conversions bridge DXF and the drawing's
;;;; entget-style group-code lists:
;;;;
;;;;   * Value typing. DXF is untyped on the wire; each group code has
;;;;     a documented value type (string / integer / double). The
;;;;     reader parses accordingly; the writer prints accordingly.
;;;;   * Points. DXF stores a point as separate X/Y/Z group codes
;;;;     (10, 20, 30). entget groups them into one pair (10 x y z).
;;;;     The reader coalesces; the writer expands.
;;;;   * Angles. DXF stores entity angles in degrees, entget in radians;
;;;;     per-type tables (*DXF-DEGREE-GROUPS*, *DXF-REPEATED-DEGREE-GROUPS*)
;;;;     drive the conversion in the entity and table-record loaders and
;;;;     writers.

;;; --- Group-code value typing ------------------------------------

(defun dxf-code-type (code)
  "The value type of DXF group CODE: :string, :integer or :double."
  (cond
    ((or (<= 0 code 9) (= code 100) (= code 102) (= code 105)
         (<= 300 code 309) (<= 320 code 369) (<= 390 code 399)
         (<= 410 code 419) (<= 430 code 439) (<= 470 code 481)
         (<= 999 code 1009))
     :string)
    ((or (<= 10 code 59) (<= 110 code 149) (<= 210 code 239)
         (<= 460 code 469) (<= 1010 code 1059))
     :double)
    ((or (<= 60 code 79) (<= 90 code 99) (<= 160 code 179)
         (<= 270 code 289) (<= 290 code 299) (<= 370 code 389)
         (<= 400 code 409) (<= 420 code 429) (<= 440 code 459)
         (<= 1060 code 1071))
     :integer)
    (t :string)))

(defun dxf-x-coordinate-code-p (code)
  "True if CODE is the X of a DXF point triple (its Y is CODE+10, its
Z is CODE+20)."
  (or (<= 10 code 18) (= code 210)
      (<= 110 code 112) (<= 1010 code 1013)))

;;; --- Reader: tokeniser ------------------------------------------

(defvar *dxf-unicode-escapes* nil
  "True while reading or writing an ASCII DXF before AC1021: a character
above #xFF travels as \\U+XXXX (see +DXF-EXTERNAL-FORMAT+).")

(defun dxf-code-line-p (line)
  "True if LINE is a bare DXF group code — a trimmed (optionally
signed) integer. Used to detect when a string value has spilled onto
following physical lines."
  (let ((s (string-trim '(#\Space #\Tab #\Return) line)))
    (and (plusp (length s))
         (multiple-value-bind (value end)
             (ignore-errors (parse-integer s :junk-allowed nil))
           (and value end t)))))

(defun dxf-parse-value (code raw)
  "Convert the RAW string value of group CODE to its typed CL value."
  (ecase (dxf-code-type code)
    (:string (if *dxf-unicode-escapes* (%dxf-unescape-string raw) raw))
    (:integer (values (parse-integer raw :junk-allowed t)))
    (:double (let ((*read-default-float-format* 'double-float))
               (coerce (read-from-string raw) 'double-float)))))

(defun dxf-read-typed-pairs (stream)
  "Read STREAM fully into a list of (CODE . TYPED-VALUE) pairs, stopping
after the terminating (0 . \"EOF\"). Comments (999) are dropped.

Robust against string values that contain embedded newlines: some
writers (e.g. libredwg's DXF output of MTEXT) emit a string value
spanning several physical lines instead of escaping the breaks. A line
following a *string* value that is not itself a bare group code is
treated as a continuation of that value (re-joined with newlines)."
  (let ((pairs '())
        (pending nil))                  ; one-line lookahead buffer
    (flet ((next-line ()
             (if pending (prog1 pending (setf pending nil))
                 (read-line stream nil :eof))))
      (loop
        (let ((code-line (next-line)))
          (when (eq code-line :eof) (return))
          (let ((code (parse-integer code-line :junk-allowed nil))
                (value-line (next-line)))
            (when (eq value-line :eof)
              (error 'drawing-error
                     :format-control "truncated DXF: group code ~S without a value"
                     :format-arguments (list code)))
            (let ((raw (string-right-trim '(#\Return) value-line)))
              ;; Re-join a string value that spilled onto later lines.
              (when (eq (dxf-code-type code) :string)
                (loop for la = (read-line stream nil :eof)
                      until (eq la :eof)
                      do (if (dxf-code-line-p la)
                             (progn (setf pending la) (loop-finish))
                             (setf raw (concatenate 'string raw
                                                    (string #\Newline)
                                                    (string-right-trim '(#\Return) la))))))
              (let ((value (string-trim '(#\Space #\Tab) raw)))
                (unless (= code 999)
                  (push (cons code (dxf-parse-value code value)) pairs))
                (when (and (= code 0) (string-equal value "EOF"))
                  (return))))))))
    (nreverse pairs)))

;;; --- Reader: point coalescing -----------------------------------

(defun dxf-coalesce-points (pairs)
  "Fold consecutive X/Y/Z coordinate pairs (10,20,30 / 11,21,31 / …)
into single entget-style point pairs (10 x y z)."
  (let ((out '()))
    (loop with rest = pairs
          while rest
          for pair = (car rest)
          do (let ((code (car pair)))
               (cond
                 ((and (dxf-x-coordinate-code-p code)
                       (cdr rest)
                       (eql (car (cadr rest)) (+ code 10)))
                  (let* ((x (cdr pair))
                         (y (cdr (cadr rest)))
                         (zcell (caddr rest))
                         (has-z (and zcell (eql (car zcell) (+ code 20)))))
                    (push (cons code (if has-z
                                         (list x y (cdr zcell))
                                         (list x y)))
                          out)
                    (setf rest (if has-z (cdddr rest) (cddr rest)))))
                 (t
                  (push pair out)
                  (setf rest (cdr rest))))))
    (nreverse out)))

;;; --- Angle units: degrees in the file, radians in entget ---------
;;;
;;; A DXF file stores most entity angles in DEGREES; entget (and so the
;;; drawing's entity data, which every consumer -- vlax-curve-*, ActiveX,
;;; the commands -- reads as entget) carries them in RADIANS. Which real
;;; groups are angles depends on the entity type: ELLIPSE 41/42 are
;;; parameters already in radians, LWPOLYLINE / VERTEX 42 is a bulge, an
;;; MTEXT 50 after its column data is a column height. So the conversion
;;; is driven by a per-type table, applied by the entity / block loaders
;;; (degrees -> radians) and by the entity writer (radians -> degrees),
;;; and to the symbol-table records (VPORT, VIEW, STYLE) by the TABLES
;;; loader and writer, since tblsearch shows them as stored. Block
;;; headers, OBJECTS and HEADER variables are not converted (cador's
;;; getvar does not read the DXF header variables).
;;;
;;; Only the FIRST occurrence of each listed code is converted, and the
;;; scan stops at a STOP code (an MTEXT 75/76 column section, a 101
;;; embedded object, a 1001 XDATA application), so a later group that
;;; reuses the code for something else is left alone. The DWG codec goes
;;; through this DXF codec (libredwg's DXF is degree-valued too), so it
;;; is converted by the same code. HATCH repeats its angle groups
;;; (boundary edges, pattern lines): every occurrence is converted.
;;; See issues/open/dxf-file-angle-units.issue and
;;; issues/open/dxf-angle-units-hatch-viewport-tables.issue.

(defparameter *dxf-degree-groups*
  '(("ARC"       50 51)          ; start angle, end angle
    ("TEXT"      50 51)          ; rotation, oblique angle
    ("ATTRIB"    50 51)          ; rotation, oblique angle
    ("ATTDEF"    50 51)          ; rotation, oblique angle
    ("SHAPE"     50 51)          ; rotation, oblique angle
    ("MTEXT"     50)             ; rotation (when written instead of 11)
    ("INSERT"    50)             ; rotation
    ("DIMENSION" 50 51 52 53)    ; rotation, horizontal dir, oblique, text rotation
    ("VERTEX"    50)             ; curve-fit tangent direction
    ("VIEWPORT"  50 51)          ; snap angle, view twist angle
    ;; Symbol-table records (TABLES section), shown as stored by
    ;; tblsearch / tblnext:
    ("VPORT"     50 51)          ; snap rotation angle, view twist angle
    ("VIEW"      50)             ; twist angle
    ("STYLE"     50))            ; oblique angle
  "Entity / table-record type -> the real group codes a DXF file stores in
degrees and entget / tblsearch report in radians (DXF reference: group
codes 50-58 are angles, \"output in degrees to DXF files and radians
through AutoLISP and ObjectARX applications\"). Deliberately absent:
ELLIPSE 41/42 (parameters, radians in the file too) and the 42 bulge of
LWPOLYLINE / VERTEX. HATCH is in *DXF-REPEATED-DEGREE-GROUPS*.")

(defparameter *dxf-repeated-degree-groups*
  '(("HATCH" 50 51 52 53))
  "Types whose degree-valued groups REPEAT, so EVERY occurrence (up to a
101 embedded object or 1001 XDATA) is converted. HATCH (DXF reference):
52 pattern angle; 53 pattern line angle, once per pattern line (78
lines); 50 / 51 start / end angle of each circular-arc (72 = 2) and
elliptic-arc (72 = 3) boundary edge. No other HATCH group uses these
codes (the polyline-path 72 / 73 flags, the spline-edge groups, the
gradient 450-470 groups -- whose 460 angle is radians -- are distinct
codes), and HATCH's own 75 / 76 come before 52 / 53, so the first
occurrence / 75-76 stop rule of *DXF-DEGREE-GROUPS* does not fit it.")

(defparameter *dxf-repeated-degree-scan-stop-codes* '(101 1001)
  "Stop codes for *DXF-REPEATED-DEGREE-GROUPS* types (embedded object,
XDATA).")

(defparameter *dxf-degree-scan-stop-codes* '(75 76 101 1001)
  "Group codes after which no angle conversion is done in an entity (MTEXT
column data, embedded object, XDATA).")

(defun dxf-convert-entity-angles (data function)
  "DATA (an entity's group-code list, ENTGET shaped) with FUNCTION applied
to the value of each degree-valued group of its type, first occurrence
only (every occurrence for a *DXF-REPEATED-DEGREE-GROUPS* type), up to
the first stop code. DATA is not modified. Also used for symbol-table
records, whose (0 . TYPE) names the record type."
  (let* ((type (cdr (assoc 0 data)))
         (repeated (and (stringp type)
                        (rest (assoc type *dxf-repeated-degree-groups*
                                     :test #'string-equal))))
         (codes (or repeated
                    (and (stringp type)
                         (rest (assoc type *dxf-degree-groups* :test #'string-equal)))))
         ;; 75 / 76 stop the scan only in an MTEXT, where they open its
         ;; column section (column heights reuse 50). A DIMENSION has a
         ;; 75 (text-placement flag) BEFORE its 53 and 50 -- measured in
         ;; AutoCAD's and BricsCAD's DXFOUT (dxf-angles probe, MR !472) --
         ;; and the general stop left both in degrees on load.
         (stop-codes (cond (repeated *dxf-repeated-degree-scan-stop-codes*)
                           ((string-equal type "MTEXT") *dxf-degree-scan-stop-codes*)
                           (t (remove-if (lambda (c) (member c '(75 76)))
                                         *dxf-degree-scan-stop-codes*)))))
    (if (null codes)
        data
        (let ((pending (copy-list codes)) (stopped nil))
          (mapcar (lambda (pair)
                    (cond
                      ((or stopped (not (consp pair))) pair)
                      ((member (car pair) stop-codes)
                       (setf stopped t)
                       pair)
                      ((and (member (car pair) pending) (realp (cdr pair)))
                       (unless repeated
                         (setf pending (remove (car pair) pending)))
                       (cons (car pair) (funcall function (cdr pair))))
                      (t pair)))
                  data)))))

(defun dxf-degrees->radians (degrees)
  (* (coerce degrees 'double-float) (/ pi 180d0)))

(defun dxf-radians->degrees (radians)
  (* (coerce radians 'double-float) (/ 180d0 pi)))

;;; An MTEXT's rotation travels as its X-axis DIRECTION (11 / 21 / 31) in
;;; the files AutoCAD 2022 and BricsCAD V25 / V26 write -- they write no 50
;;; -- while their entget of the same MTEXT reports (50 . angle) in radians
;;; (dxf-angles probe, MR !472: an MTEXT rotated 60 degrees is 11 = 0.5,
;;; 21 = 0.866 in the file, (50 . 1.0472) in entget). So the loader derives
;;; 50 from the direction when the file gives none, and the writer leaves
;;; 50 out when the direction is there, as the vendors do.

(defun %mtext-p (data)
  (let ((type (cdr (assoc 0 data))))
    (and (stringp type) (string-equal type "MTEXT"))))

(defun %mtext-direction-angle (data)
  "The rotation (radians) of the MTEXT DATA's 11 direction, or NIL."
  (let ((dir (cdr (assoc 11 data))))
    (and (consp dir) (realp (first dir)) (realp (second dir))
         (not (and (zerop (first dir)) (zerop (second dir))))
         (let ((a (atan (coerce (second dir) 'double-float)
                        (coerce (first dir) 'double-float))))
           (if (minusp a) (+ a (* 2 pi)) a)))))

(defun dxf-entity-from-file (data)
  "Entity DATA as read from a DXF file -> entget units (radians); an MTEXT
without 50 gets the rotation of its 11 direction."
  (let ((data (dxf-convert-entity-angles data #'dxf-degrees->radians)))
    (if (and (%mtext-p data) (not (assoc 50 data)))
        (let ((angle (%mtext-direction-angle data)))
          (if angle (append data (list (cons 50 angle))) data))
        data)))

(defun dxf-entity-for-file (data)
  "Entity DATA in entget units -> DXF file units (degrees); an MTEXT that
has an 11 direction is written without its 50."
  (let ((data (dxf-convert-entity-angles data #'dxf-radians->degrees)))
    (if (and (%mtext-p data) (assoc 11 data))
        (remove 50 data :key (lambda (p) (and (consp p) (car p))))
        data)))

;;; --- Reader: section splitting ----------------------------------

(defun dxf-split-objects (pairs starter-codes)
  "Split a flat PAIRS list into sublists, each beginning at a pair
whose code is in STARTER-CODES (typically (0)). Pairs before the
first starter are dropped."
  (let ((groups '()) (current nil))
    (dolist (pair pairs)
      (if (member (car pair) starter-codes)
          (progn (when current (push (nreverse current) groups))
                 (setf current (list pair)))
          (when current (push pair current))))
    (when current (push (nreverse current) groups))
    (nreverse groups)))

(defparameter *dxf-table-kinds*
  '(("LAYER" . :layer) ("LTYPE" . :ltype) ("STYLE" . :style)
    ("VIEW" . :view) ("UCS" . :ucs) ("VPORT" . :vport)
    ("DIMSTYLE" . :dimstyle) ("APPID" . :appid)
    ("BLOCK_RECORD" . :block-record))
  "DXF table name <-> drawing table-kind keyword.")

(defun dxf-table-kind (name)
  (or (cdr (assoc name *dxf-table-kinds* :test #'string-equal))
      (intern (string-downcase name) "KEYWORD")))

(defun dxf-table-name (kind)
  (or (car (rassoc kind *dxf-table-kinds*))
      (string-upcase (symbol-name kind))))

;;; --- Reader: driver ---------------------------------------------

(defun dxf-section-bodies (pairs)
  "Return an alist of section-name -> body-pairs (between each
(2 . NAME) after (0 . \"SECTION\") and the matching (0 . \"ENDSEC\"))."
  (let ((sections '()) (i 0) (n (length pairs)) (vec (coerce pairs 'vector)))
    (loop while (< i n)
          for pair = (aref vec i)
          do (if (and (= (car pair) 0) (string-equal (cdr pair) "SECTION"))
                 (let ((name (and (< (1+ i) n)
                                  (= (car (aref vec (1+ i))) 2)
                                  (cdr (aref vec (1+ i)))))
                       (body '())
                       (j (+ i 2)))
                   (loop while (and (< j n)
                                    (not (and (= (car (aref vec j)) 0)
                                              (string-equal (cdr (aref vec j)) "ENDSEC"))))
                         do (push (aref vec j) body) (incf j))
                   (push (cons name (nreverse body)) sections)
                   (setf i (1+ j)))
                 (incf i)))
    (nreverse sections)))

(defun dxf-load-header (drawing body)
  "Populate DRAWING's header variables (and handle-seed) from a
HEADER section body: a sequence of (9 . \"$NAME\") followed by the
variable's value group(s)."
  (let ((groups (dxf-split-objects (dxf-coalesce-points body) '(9))))
    (dolist (group groups)
      (let* ((name (string-left-trim "$" (cdr (first group))))
             (value-pair (second group)))
        (when value-pair
          (let* ((code (car value-pair))
                 (value (cdr value-pair)))
            (cond
              ((string-equal name "HANDSEED")
               (setf (drawing-handle-seed drawing)
                     (handle->integer value)))
              ((string-equal name "ACADVER")
               (setf (drawing-version drawing)
                     (intern (string-upcase value) "KEYWORD")))
              (t
               (ensure-drawing-variable
                drawing name
                :kind (case (dxf-code-type code)
                        (:string (if (consp value) :point :string))
                        (:integer :integer)
                        (:double (if (consp value) :point :real)))
                :value value)))))))))

(defun dxf-load-tables (drawing body)
  ;; The TABLES body is a flat sequence of 0-started objects: a
  ;; (0 . "TABLE") header (carrying 2 KINDNAME), then the record
  ;; objects of that kind, then (0 . "ENDTAB"), repeating. Walk them
  ;; linearly, tracking the current table kind.
  (let ((current-kind nil))
    (dolist (group (dxf-split-objects (dxf-coalesce-points body) '(0)))
      (let* ((head (first group))
             (tag (and (= (car head) 0) (cdr head))))
        (cond
          ((string-equal tag "TABLE")
           (let ((name-pair (find 2 (rest group) :key #'car)))
             (setf current-kind (and name-pair (dxf-table-kind (cdr name-pair))))))
          ((string-equal tag "ENDTAB")
           (setf current-kind nil))
          (current-kind
           (let ((rname (cdr (find 2 group :key #'car))))
             (when rname
               (add-table-record
                drawing
                (make-symbol-table-record
                 :kind current-kind :name rname
                 ;; Degrees -> radians (VPORT, VIEW, STYLE angles).
                 :data (dxf-entity-from-file group)))))))))))

(defun dxf-load-entities (drawing body &optional block)
  "Add the entities in a flat BODY (the ENTITIES section, or the entity
run inside a block) to DRAWING, owned by BLOCK (NIL = model space)."
  (dolist (entity (dxf-split-objects (dxf-coalesce-points body) '(0)))
    (let ((handle-pair (find 5 entity :key #'car)))
      (add-entity drawing (dxf-entity-from-file entity)
                  :handle (and handle-pair (cdr handle-pair))
                  :block block))))

(defun dxf-load-blocks (drawing body)
  "Load BLOCK definitions. The BLOCKS body is a flat run of 0-started
objects: (0 . \"BLOCK\") header, the block's owned entities, then
(0 . \"ENDBLK\"), repeating. The header is registered with ADD-BLOCK;
the entities are added with their :block owner set."
  (let ((current-block nil))
    (dolist (group (dxf-split-objects (dxf-coalesce-points body) '(0)))
      (let* ((head (first group))
             (tag (and (= (car head) 0) (cdr head))))
        (cond
          ((string-equal tag "BLOCK")
           (let ((name (cdr (find 2 group :key #'car))))
             (setf current-block name)
             (when name (add-block drawing name group))))
          ((string-equal tag "ENDBLK")
           (setf current-block nil))
          (current-block
           (let ((handle-pair (find 5 group :key #'car)))
             (add-entity drawing (dxf-entity-from-file group)
                         :handle (and handle-pair (cdr handle-pair))
                         :block current-block))))))))

(defun dxf-object-handle (obj)
  (cdr (find 5 obj :key #'car)))

(defun dxf-dictionary-object-p (obj)
  (and obj (consp (first obj)) (= (car (first obj)) 0)
       (string-equal (cdr (first obj)) "DICTIONARY")))

(defun dxf-load-objects (drawing body)
  "Load the OBJECTS section. The root DICTIONARY is rebuilt into the
drawing's named-object-dictionary tree, following (3 key)(350|360
handle) links: a link to another DICTIONARY nests a sub-dictionary; a
link to any other object keeps the handle string. Every non-dictionary
object (xrecords and the rest) is stored in DRAWING-OBJECTS by handle so
the section round-trips losslessly."
  (let* ((objs (dxf-split-objects (dxf-coalesce-points body) '(0)))
         (by-handle (make-hash-table :test #'equalp))
         (visited (make-hash-table :test #'equalp))
         (root nil))
    (dolist (obj objs)
      (let ((h (dxf-object-handle obj)))
        (when h (setf (gethash h by-handle) obj)))
      (when (and (null root) (dxf-dictionary-object-p obj))
        (setf root obj)))
    (labels ((build (obj)
               (let ((d (make-dictionary)) (pending nil)
                     (h (dxf-object-handle obj)))
                 (when h (setf (gethash h visited) t))
                 (dolist (pair (rest obj))
                   (case (car pair)
                     (3 (setf pending (cdr pair)))
                     ((350 360)
                      (when pending
                        (let* ((target-handle (cdr pair))
                               (target (gethash target-handle by-handle)))
                          (if (and (dxf-dictionary-object-p target)
                                   (not (gethash target-handle visited)))
                              (dictionary-put d pending (build target))
                              (dictionary-put d pending target-handle)))
                        (setf pending nil)))))
                 d)))
      (when root
        (setf (drawing-named-object-dictionary drawing) (build root))))
    ;; Store every non-dictionary object for lossless round-trip.
    (dolist (obj objs)
      (let ((h (dxf-object-handle obj)))
        (when (and h (not (dxf-dictionary-object-p obj)))
          (add-object drawing h obj))))
    ;; ... and every object, dictionaries included, as a handle-addressed
    ;; object -- what (namedobjdict) / entget / dictsearch reach and the
    ;; writer writes back (deferred-nod-default-contents, item 4). The root
    ;; is the section's first dictionary.
    (dolist (obj objs)
      (let ((h (dxf-object-handle obj)))
        (when (and h (not (find-entity drawing h :include-deleted t)))
          (add-entity drawing (dxf-entity-from-file obj) :handle h :object-p t))))
    (when root
      (let ((h (dxf-object-handle root)))
        (when (and h (find-entity drawing h))
          (setf (drawing-root-dictionary-handle drawing)
                (entity-handle-id (find-entity drawing h))))))))

(defun dxf-build-drawing (typed-pairs)
  "Build a DRAWING from a flat list of (CODE . TYPED-VALUE) pairs,
whatever tokeniser (ASCII or binary) produced them."
  (let ((drawing (make-drawing))
        (sections (dxf-section-bodies typed-pairs)))
    (flet ((section (name) (cdr (assoc name sections :test #'string-equal))))
      (let ((b (section "HEADER")))   (when b (dxf-load-header   drawing b)))
      (let ((b (section "TABLES")))   (when b (dxf-load-tables   drawing b)))
      (let ((b (section "BLOCKS")))   (when b (dxf-load-blocks   drawing b)))
      (let ((b (section "ENTITIES"))) (when b (dxf-load-entities drawing b)))
      (let ((b (section "OBJECTS")))  (when b (dxf-load-objects  drawing b))))
    drawing))

(defun dxf-read-drawing-from-stream (stream)
  "Parse an ASCII DXF STREAM into a fresh DRAWING."
  (dxf-build-drawing (dxf-read-typed-pairs stream)))

;;; --- Writer: pluggable pair emitter -----------------------------
;;;
;;; The structural writers below emit *every* group pair — including
;;; the (0 . "SECTION") / (2 . name) markers — through DXF-EMIT, which
;;; dispatches to the format-specific emitter bound in *DXF-EMIT-PAIR*.
;;; ASCII and binary therefore share all of the section / table / block
;;; / entity / object structure; only the per-pair encoding differs.

(defvar *dxf-out* nil  "Stream the current writer emits to.")
(defvar *dxf-emit-pair* nil  "Function (stream code value) for one pair.")

(declaim (inline dxf-emit))
(defun dxf-emit (code value)
  (funcall *dxf-emit-pair* *dxf-out* code value))

(defun dxf-format-double (x)
  "Print a double in DXF's plain decimal style (fixed-point, no
exponent marker)."
  (let ((*read-default-float-format* 'double-float))
    (format nil "~F" (coerce x 'double-float))))

(defun dxf-ascii-emit-pair (stream code value)
  (format stream "~D~%" code)
  (ecase (dxf-code-type code)
    (:string  (format stream "~A~%" (if *dxf-unicode-escapes*
                                        (%dxf-escape-string (princ-to-string value))
                                        value)))
    (:integer (format stream "~D~%" value))
    (:double  (format stream "~A~%" (dxf-format-double value)))))

(defun dxf-write-data-pair (pair)
  "Emit one entget-style PAIR, expanding a point value into its X/Y/Z
group codes."
  (let ((code (car pair)) (value (cdr pair)))
    (if (and (dxf-x-coordinate-code-p code)
             (consp value) (every #'numberp value))
        (loop for component in value
              for sub from code by 10
              do (dxf-emit sub (coerce component 'double-float)))
        (dxf-emit code value))))

(defun dxf-write-object (pairs)
  (dolist (pair pairs)
    (when (consp pair) (dxf-write-data-pair pair))))

(defun dxf-write-section (name body-thunk)
  (dxf-emit 0 "SECTION")
  (dxf-emit 2 name)
  (funcall body-thunk)
  (dxf-emit 0 "ENDSEC"))

(defun dxf-integer-group-code (value)
  "70 for an integer that FITS a DXF 16-bit group, 90 otherwise.
Group 70 is a signed 16-bit int (-32768..32767); 90 is the 32-bit one.
A sysvar can exceed the smaller range -- CMPDIFFLIMIT is 10000000 by
default -- and emitting it as 70 produces a header a reader cannot take:
libredwg refused the whole file with DWG_ERR_IOERROR, which is why an
ActiveX SaveAs to .dwg failed from a clautolisp session while the same
drawing read from a DWG round-tripped. See
dwg-write-rejects-a-drawing-built-in-memory."
  (if (typep value '(signed-byte 16)) 70 90))

(defvar *dxf-output-version* nil
  "The DXF $ACADVER version (a keyword such as :ac1032 for DWG 2018) the
writer emits. Bound by DXF-WRITE-DRAWING / -BINARY-DRAWING from their VERSION
argument; NIL falls back to the drawing's own version, then the R2013 default.")

(defparameter +dxf-acadver-versions+
  '(:ac1004 :ac1006 :ac1009 :ac1012 :ac1014 :ac1015 :ac1018 :ac1021 :ac1024
    :ac1027 :ac1032)
  "The DXF $ACADVER version keywords the writer accepts (R9 .. R2018). The
keyword name is the literal $ACADVER string, e.g. :ac1032 -> \"AC1032\".")

(defun %dxf-acadver-string (version)
  "The $ACADVER string for VERSION: an accepted version keyword's name, a
string used as-is (upcased), or the R2013 default (\"AC1027\") otherwise."
  (cond
    ((and (keywordp version) (member version +dxf-acadver-versions+))
     (string-upcase (symbol-name version)))
    ((stringp version) (string-upcase version))
    (t "AC1027")))

(defun dxf-header-value-code (kind value)
  "Choose a DXF group code to carry a header variable of KIND."
  (case kind
    (:string 1)
    (:integer (dxf-integer-group-code value))
    (:short (dxf-integer-group-code value))
    (:real 40)
    (:point 10)
    (t (cond ((consp value) 10)
             ((integerp value) (dxf-integer-group-code value))
             ((stringp value) 1)
             (t 40)))))

(defun dxf-write-header (drawing)
  (dxf-write-section
   "HEADER"
   (lambda ()
     (dxf-emit 9 "$ACADVER")
     (dxf-emit 1 (%dxf-acadver-string
                  (or *dxf-output-version* (drawing-version drawing))))
     (dxf-emit 9 "$HANDSEED")
     (dxf-emit 5 (format nil "~X" (drawing-handle-seed drawing)))
     (map-variables
      (lambda (cell)
        (let ((name (sysvar-cell-name cell))
              (value (sysvar-cell-value cell)))
          ;; HANDSEED and ACADVER are written ABOVE, from the drawing
          ;; itself, so the sysvar of the same name must not be written
          ;; again: DXF has one slot per variable and the LAST one wins.
          ;; ACADVER is the trap. In the DXF header it is the FILE FORMAT
          ;; version (AC1027); as a sysvar it is the PRODUCT version --
          ;; "24.1s (LMS Tech)" on AutoCAD, clautolisp's own "2.2.98"
          ;; here -- so emitting the sysvar overwrote the format version
          ;; with something no reader can make sense of. libredwg then
          ;; refused the file with DWG_ERR_INVALIDDWG, which is what made
          ;; every ActiveX SaveAs to .dwg from a clautolisp session fail
          ;; while a drawing READ from a DWG round-tripped (its sysvars
          ;; come from the file, where ACADVER already IS the format
          ;; version). See dwg-write-rejects-a-drawing-built-in-memory.
          (unless (or (string-equal name "HANDSEED")
                      (string-equal name "ACADVER"))
            ;; A file before AC1021 is written as ISO-8859-1, not as the
            ;; session's "UTF-8": say so with the codepage the CADs write
            ;; (ANSI_1252, which ISO-8859-1 matches but for #x80-#x9F).
            (when (and *dxf-unicode-escapes* (string-equal name "DWGCODEPAGE"))
              (setf value "ANSI_1252"))
            (dxf-emit 9 (format nil "$~A" name))
            (dxf-write-data-pair
             (cons (dxf-header-value-code (sysvar-cell-kind cell) value) value)))))
      drawing))))

(defun dxf-write-tables (drawing)
  (dxf-write-section
   "TABLES"
   (lambda ()
     (maphash
      (lambda (kind table)
        (dxf-emit 0 "TABLE")
        (dxf-emit 2 (dxf-table-name kind))
        (dxf-emit 70 (hash-table-count table))
        (maphash (lambda (name record)
                   (declare (ignore name))
                   ;; Radians -> degrees, on a copy; with the record's
                   ;; handle, so a reload gives it the same one.
                   (dxf-write-object
                    (dxf-entity-for-file (dxf-record-data-with-handle record))))
                 table)
        (dxf-emit 0 "ENDTAB"))
      (drawing-tables drawing)))))

(defun dxf-record-data-with-handle (record)
  "RECORD's group-code list with its (5 . handle) after the (0 . type) pair
when the data carries none (ADD-TABLE-RECORD gave the record one)."
  (let ((data (symbol-table-record-data record))
        (id (symbol-table-record-id record)))
    (if (or (assoc 5 data) (not (stringp id)))
        data
        (let ((zero (assoc 0 data)))
          (if zero
              (list* zero (cons 5 id) (remove zero data :test #'eq))
              (cons (cons 5 id) data))))))

(defun dxf-ordered-entity-data (data)
  "Return DATA with its (0 . TYPE) pair first: a DXF entity must begin
with group code 0, but the drawing stores (5 . handle) first."
  (let ((zero (assoc 0 data)))
    (if zero (cons zero (remove zero data :test #'eq)) data)))

(defun dxf-owner-handle (drawing owner-name)
  "The handle of the BLOCK_RECORD named OWNER-NAME, allocating one if the
record has none, or NIL when there is no such record.

Every entity in a DXF belongs to a block record -- model space is the
record named \"*Model_Space\" -- and says so with group 330. libredwg
SILENTLY DROPS an entity that does not: a LINE written without it came
back from a DWG round trip as nothing at all, with rc 0
(dwg-round-trip-loses-entities). The 100 AcDbEntity / AcDbLine subclass
markers, by contrast, turned out not to matter.

A record with no handle gets one here: a DXF handle is not optional, and
a writer assigning the missing ones is what AutoCAD does too. That is why
this takes the DRAWING -- the seed lives there."
  (let ((record (find-table-record drawing :block-record owner-name)))
    (when record
      (let* ((data (symbol-table-record-data record))
             (existing (cdr (assoc 5 data))))
        (or existing
            ;; The record's own handle (ADD-TABLE-RECORD gives every record
            ;; one), so TBLOBJNAME, HANDENT and the file agree.
            (let ((handle (let ((id (symbol-table-record-id record)))
                            (if (stringp id)
                                id
                                (format nil "~X" (allocate-handle drawing)))))
                  (zero (assoc 0 data)))
              ;; AFTER the (0 . type) pair: a DXF object must begin with
              ;; its type marker, and a table record is written in the
              ;; order it is stored (only ENTITIES get reordered). Putting
              ;; the handle first emitted `5 <h>' before
              ;; `0 BLOCK_RECORD', which breaks the table.
              (setf (symbol-table-record-data record)
                    (if zero
                        (cons zero (cons (cons 5 handle)
                                         (remove zero data :test #'eq)))
                        (cons (cons 5 handle) data)))
              handle))))))

(defun dxf-entity-data-with-owner (drawing entity)
  "ENTITY's group-code list with (330 . owner-handle) inserted after its
handle when it carries no owner of its own. The owner is the entity's
block, or model space for a model-space entity."
  (let ((data (dxf-entity-for-file
               (dxf-ordered-entity-data (entity-handle-data entity)))))
    (if (assoc 330 data)
        data
        (let ((handle (dxf-owner-handle
                       drawing
                       (or (entity-handle-block entity) "*Model_Space"))))
          (if (null handle)
              data
              ;; After (0 . type) and (5 . handle), as the vendor writes it.
              (let ((head '()) (rest data))
                (loop while (and rest (member (car (first rest)) '(0 5)))
                      do (push (pop rest) head))
                (append (nreverse head) (list (cons 330 handle)) rest)))))))

(defun dxf-write-entities (drawing)
  "Emit the ENTITIES section: model-space entities only (those with a
NIL block owner). Block-owned entities are emitted inside BLOCKS."
  (dxf-write-section
   "ENTITIES"
   (lambda ()
     (map-entities (lambda (entity)
                     ;; the objects go to OBJECTS
                     (unless (or (entity-handle-block entity)
                                 (not (graphical-entity-p entity)))
                       (dxf-write-object
                        (dxf-entity-data-with-owner drawing entity))))
                   drawing))))

(defun dxf-write-blocks (drawing)
  "Emit the BLOCKS section: each block definition's header, then its
owned entities, then ENDBLK."
  (dxf-write-section
   "BLOCKS"
   (lambda ()
     (map-blocks
      (lambda (name header)
        (dxf-write-object (dxf-ordered-entity-data header))
        (dolist (entity (remove-if-not #'graphical-entity-p
                                       (block-entities drawing name)))
          ;; Same owner rule inside a block: the entity belongs to that
          ;; block's record, and without group 330 libredwg drops it.
          (dxf-write-object (dxf-entity-data-with-owner drawing entity)))
        (dxf-emit 0 "ENDBLK"))
      drawing))))

(defun dxf-assign-dictionary-handles (root start)
  "Walk the dictionary tree from ROOT, assigning each dictionary a fresh
hex handle from a counter starting at START (the drawing's seed; not
mutated). Returns an EQ hash-table dict -> hex-handle."
  (let ((handles (make-hash-table :test #'eq))
        (counter start))
    (labels ((assign (d)
               (unless (gethash d handles)
                 (setf (gethash d handles) (format nil "~X" counter))
                 (incf counter)
                 (map-dictionary (lambda (k v)
                                   (declare (ignore k))
                                   (when (dictionary-p v) (assign v)))
                                 d))))
      (assign root))
    handles))

(defun dxf-write-dictionary-tree (dict handles)
  "Emit DICT as a DICTIONARY object (using its assigned handle), then
recursively its sub-dictionaries. Entry links: a sub-dictionary uses
its assigned handle; any other value is emitted as its handle string."
  (dxf-emit 0 "DICTIONARY")
  (dxf-emit 5 (gethash dict handles))
  (map-dictionary
   (lambda (key value)
     (dxf-emit 3 key)
     (dxf-emit 350 (cond ((dictionary-p value) (gethash value handles))
                         ((stringp value) value)
                         (t (princ-to-string value)))))
   dict)
  (map-dictionary (lambda (key value)
                    (declare (ignore key))
                    (when (dictionary-p value)
                      (dxf-write-dictionary-tree value handles)))
                  dict))

(defun dxf-write-handle-addressed-objects (drawing)
  "Emit the OBJECTS section from the handle-addressed objects: the root
dictionary first (a reader takes the first DICTIONARY for the NOD), then
every other non-graphical object in creation order, each as stored (its
owner and entries are handles already); then the stored OBJECTS-section
objects no handle-addressed one replaced."
  (let ((root (find-entity drawing (drawing-root-dictionary-handle drawing))))
    (dxf-write-section
     "OBJECTS"
     (lambda ()
       (when root
         (dxf-write-object (dxf-ordered-entity-data (entity-handle-data root))))
       (map-entities (lambda (entity)
                       (unless (or (eq entity root) (graphical-entity-p entity))
                         (dxf-write-object
                          (dxf-ordered-entity-data (entity-handle-data entity)))))
                     drawing)
       (maphash (lambda (handle obj)
                  (unless (find-entity drawing handle :include-deleted t)
                    (dxf-write-object (dxf-ordered-entity-data obj))))
                (drawing-objects drawing))))))

(defun dxf-write-objects (drawing)
  "Emit the OBJECTS section: the handle-addressed objects when the drawing
has its root dictionary as one (DXF-WRITE-HANDLE-ADDRESSED-OBJECTS), else
the legacy named-object dictionary tree (handle-linked) followed by the
standalone non-graphical objects (xrecords)."
  (when (drawing-root-dictionary-handle drawing)
    (return-from dxf-write-objects (dxf-write-handle-addressed-objects drawing)))
  (let ((nod (drawing-named-object-dictionary drawing))
        (objects (drawing-objects drawing)))
    (when (or (plusp (hash-table-count (dictionary-entries nod)))
              (plusp (hash-table-count objects)))
      (dxf-write-section
       "OBJECTS"
       (lambda ()
         (let ((handles (dxf-assign-dictionary-handles
                         nod (drawing-handle-seed drawing))))
           (dxf-write-dictionary-tree nod handles))
         (maphash (lambda (handle obj)
                    (declare (ignore handle))
                    (dxf-write-object (dxf-ordered-entity-data obj)))
                  objects))))))

(defun dxf-complete-block-header (drawing name header)
  "HEADER with what libredwg needs in order to RECOGNISE a block: its own
handle, its block record as owner (330), and the AcDbEntity /
AcDbBlockBegin subclass markers. Pairs already present are left alone.

A resolving owner on the entity is necessary but not sufficient: with a
bare `(0 . BLOCK) (2 . name)' header -- which is what a drawing built in
this process has -- libredwg still drops every entity of that block, and
with the header below it keeps them. Measured both ways
(dwg-round-trip-loses-entities)."
  (let ((record-handle (dxf-owner-handle drawing name)))
    (if (or (null record-handle) (assoc 330 header))
        header
        (let* ((zero (assoc 0 header))
               (rest (remove zero header :test #'eq))
               (handle (or (cdr (assoc 5 header))
                           (format nil "~X" (allocate-handle drawing)))))
          (append (when zero (list zero))
                  (list (cons 5 handle)
                        (cons 330 record-handle)
                        (cons 100 "AcDbEntity")
                        (cons 8 (or (cdr (assoc 8 rest)) "0"))
                        (cons 100 "AcDbBlockBegin"))
                  (remove-if (lambda (pair) (member (car pair) '(5 8))) rest))))))

(defun dxf-ensure-write-handles (drawing)
  "Assign, BEFORE any section is written, the handles the later sections
must agree on: a handle on every block record an entity names as its
owner, and the identity pairs on every block header. The ENTITIES and
BLOCKS sections are written after TABLES, so a handle allocated while
writing them would name a record that had already gone out without it."
  (map-entities (lambda (entity)
                  (dxf-owner-handle drawing
                                    (or (entity-handle-block entity)
                                        "*Model_Space")))
                drawing)
  (let ((names '()))
    (map-blocks (lambda (name header) (declare (ignore header))
                  (push name names))
                drawing)
    (dolist (name names)
      (let ((header (find-block drawing name)))
        (when header
          (setf (gethash name (drawing-blocks drawing))
                (dxf-complete-block-header drawing name header))))))
  nil)

(defun dxf-write-drawing-body (drawing)
  (dxf-ensure-write-handles drawing)
  (dxf-write-header drawing)
  (dxf-write-tables drawing)
  (dxf-write-blocks drawing)
  (dxf-write-entities drawing)
  (dxf-write-objects drawing)
  (dxf-emit 0 "EOF"))

(defun dxf-write-drawing-to-stream (drawing stream)
  "Write DRAWING to a character STREAM as ASCII DXF."
  (let ((*dxf-out* stream)
        (*dxf-emit-pair* #'dxf-ascii-emit-pair))
    (dxf-write-drawing-body drawing))
  drawing)

;;; --- Binary DXF -------------------------------------------------
;;;
;;; The R13+ binary DXF variant: a 22-byte sentinel, then group codes
;;; as 2-byte little-endian shorts and values encoded per the group
;;; code's type. Reader and writer here are mutually consistent and
;;; read/write that variant. (Binary extended-data chunks (310/1004)
;;; and non-ASCII codepage strings are out of scope; strings are
;;; treated as null-terminated Latin-1.)

(defparameter +dxf-binary-sentinel+ "AutoCAD Binary DXF")

(defun dxf-binary-value-kind (code)
  "Refine DXF-CODE-TYPE to a binary width: :string, :double, :bool
(1 byte), :int16, :int32 or :int64."
  (case (dxf-code-type code)
    (:string :string)
    (:double :double)
    (t (cond
         ((<= 290 code 299) :bool)
         ((<= 160 code 169) :int64)
         ((or (<= 90 code 99) (<= 420 code 429) (<= 440 code 459) (= code 1071))
          :int32)
         (t :int16)))))

;; Portable IEEE-754 double <-> 64-bit integer (no external deps;
;; exact for finite normal/zero values, which is all DXF carries).

(defun double->bits (x)
  (let ((x (coerce x 'double-float)))
    (if (zerop x)
        (if (minusp (float-sign x)) #x8000000000000000 0)
        (multiple-value-bind (m e s) (integer-decode-float (abs x))
          (declare (ignore s))
          (let ((sign (if (minusp x) 1 0))
                (biased (+ e 1075)))
            (cond
              ((>= biased 2047) (logior (ash sign 63) (ash 2047 52)))
              ((<= biased 0)
               (logior (ash sign 63) (ldb (byte 52 0) (ash m (1- biased)))))
              (t (logior (ash sign 63) (ash biased 52) (ldb (byte 52 0) m)))))))))

(defun bits->double (bits)
  (let ((sign (if (logbitp 63 bits) -1d0 1d0))
        (exp (ldb (byte 11 52) bits))
        (frac (ldb (byte 52 0) bits)))
    (cond
      ((= exp 2047) (if (zerop frac) (* sign most-positive-double-float) 0d0))
      ((zerop exp) (* sign (scale-float (coerce frac 'double-float) -1074)))
      (t (* sign (scale-float (coerce (logior frac (ash 1 52)) 'double-float)
                              (- exp 1075)))))))

(defun dxf-write-uint (stream value n)
  (dotimes (i n) (write-byte (ldb (byte 8 (* 8 i)) value) stream)))

(defun dxf-read-uint (stream n)
  (let ((v 0))
    (dotimes (i n v)
      (let ((b (read-byte stream nil :eof)))
        (when (eq b :eof) (return-from dxf-read-uint nil))
        (setf v (logior v (ash b (* 8 i))))))))

(defun dxf-sign-extend (v bits)
  (if (and v (logbitp (1- bits) v)) (- v (ash 1 bits)) v))

(defun dxf-binary-emit-pair (stream code value)
  (dxf-write-uint stream code 2)
  (ecase (dxf-binary-value-kind code)
    (:string (loop for c across (string value)
                   do (write-byte (logand (char-code c) #xff) stream))
             (write-byte 0 stream))
    (:double (dxf-write-uint stream (double->bits value) 8))
    (:bool   (write-byte (if (and value (not (eql value 0))) 1 0) stream))
    (:int16  (dxf-write-uint stream (ldb (byte 16 0) value) 2))
    (:int32  (dxf-write-uint stream (ldb (byte 32 0) value) 4))
    (:int64  (dxf-write-uint stream (ldb (byte 64 0) value) 8))))

(defun dxf-read-binary-string (stream)
  (with-output-to-string (s)
    (loop for b = (read-byte stream nil 0)
          until (or (null b) (eql b 0))
          do (write-char (code-char b) s))))

(defun dxf-read-binary-pairs (stream)
  "Tokenise a binary DXF STREAM (sentinel already consumed) into a list
of (CODE . TYPED-VALUE) pairs."
  (let ((pairs '()))
    (loop
      (let ((code (dxf-read-uint stream 2)))
        (when (null code) (return))
        (let ((value
               (ecase (dxf-binary-value-kind code)
                 (:string (dxf-read-binary-string stream))
                 (:double (bits->double (dxf-read-uint stream 8)))
                 (:bool   (read-byte stream nil 0))
                 (:int16  (dxf-sign-extend (dxf-read-uint stream 2) 16))
                 (:int32  (dxf-sign-extend (dxf-read-uint stream 4) 32))
                 (:int64  (dxf-sign-extend (dxf-read-uint stream 8) 64)))))
          (unless (= code 999) (push (cons code value) pairs))
          (when (and (= code 0) (stringp value) (string-equal value "EOF"))
            (return)))))
    (nreverse pairs)))

(defun dxf-write-binary-drawing-to-stream (drawing stream)
  "Write DRAWING to a byte STREAM as R13+ binary DXF."
  (loop for c across +dxf-binary-sentinel+ do (write-byte (char-code c) stream))
  (write-byte 13 stream) (write-byte 10 stream)   ; CR LF
  (write-byte 26 stream) (write-byte 0 stream)    ; SUB NUL
  (let ((*dxf-out* stream)
        (*dxf-emit-pair* #'dxf-binary-emit-pair))
    (dxf-write-drawing-body drawing))
  drawing)

(defun dxf-read-binary-drawing-from-stream (stream)
  "Parse a binary DXF byte STREAM (positioned at the start) into a
DRAWING. Consumes and ignores the 22-byte sentinel."
  (dotimes (i 22) (read-byte stream nil :eof))
  (dxf-build-drawing (dxf-read-binary-pairs stream)))

(defun dxf-binary-file-p (source)
  "True if the file SOURCE begins with the binary DXF sentinel."
  (and (probe-file source)
       (with-open-file (s source :element-type '(unsigned-byte 8))
         (let* ((len (length +dxf-binary-sentinel+))
                (buf (make-array len :element-type '(unsigned-byte 8))))
           (and (= len (read-sequence buf s))
                (string= +dxf-binary-sentinel+ (map 'string #'code-char buf)))))))

;;; --- Codec registration -----------------------------------------

;;; An ASCII DXF of AC1021 (2007) or later is UTF-8. Before AC1021 it is
;;; a codepage text ($DWGCODEPAGE, ANSI_xxxx) with \U+XXXX escapes for
;;; the characters outside it: those files are read and written as
;;; ISO-8859-1, which maps every byte 1:1 (never a decoding error, bytes
;;; preserved), and a character above #xFF goes as \U+XXXX. (Honouring
;;; $DWGCODEPAGE precisely, e.g. ANSI_1252's #x80-#x9F, is a future
;;; refinement.) dxf-writer-header-not-utf8: the header's unit lists hold
;;; a MICRO SIGN, written as the lone byte #xB5 in an AC1027 file.
(defparameter +dxf-external-format+ :iso-8859-1
  "The external format of an ASCII DXF before AC1021.")

(defun %dxf-utf-8-version-p (acadver)
  "True when ACADVER (a $ACADVER string such as \"AC1027\") is AC1021 or
later, the versions whose ASCII DXF is UTF-8."
  (let ((number (and (stringp acadver) (> (length acadver) 2)
                     (string-equal "AC" acadver :end2 2)
                     (parse-integer acadver :start 2 :junk-allowed t))))
    (and number (>= number 1021))))

(defun %dxf-escape-string (string)
  "STRING with every character above #xFF written \\U+XXXX."
  (if (every (lambda (c) (<= (char-code c) #xFF)) string)
      string
      (with-output-to-string (out)
        (loop for c across string
              do (if (<= (char-code c) #xFF)
                     (write-char c out)
                     (format out "\\U+~4,'0X" (char-code c)))))))

(defun %dxf-unescape-string (string)
  "STRING with every \\U+XXXX (four hex digits) replaced by its character."
  (let ((start (search "\\U+" string)))
    (if (null start)
        string
        (with-output-to-string (out)
          (loop with i = 0
                with n = (length string)
                while (< i n)
                do (let ((code (and (char= (char string i) #\\)
                                    (<= (+ i 7) n)
                                    (string= "\\U+" string :start2 i :end2 (+ i 3))
                                    (every (lambda (c) (digit-char-p c 16))
                                           (subseq string (+ i 3) (+ i 7)))
                                    (parse-integer string :start (+ i 3) :end (+ i 7)
                                                          :radix 16))))
                     (if code
                         (progn (write-char (code-char code) out) (incf i 7))
                         (progn (write-char (char string i) out) (incf i)))))))))

(defun %dxf-sniff-acadver (source)
  "The $ACADVER string of the ASCII DXF SOURCE, or NIL when its header
does not give one. Reads only the header's head, as ISO-8859-1."
  (with-open-file (s source :external-format :iso-8859-1)
    (loop repeat 2000
          for line = (read-line s nil :eof)
          until (eq line :eof)
          do (let ((text (string-trim '(#\Space #\Tab #\Return) line)))
               (cond ((string-equal text "$ACADVER")
                      (read-line s nil :eof)    ; its group code (1)
                      (let ((value (read-line s nil :eof)))
                        (return (and (stringp value)
                                     (string-trim '(#\Space #\Tab #\Return) value)))))
                     ((string-equal text "ENDSEC") (return nil)))))))

(defun %dxf-valid-utf-8-p (source)
  "True when the bytes of SOURCE are well-formed UTF-8. Checked on the bytes
rather than by catching a decoding error: CCL's UTF-8 decoder substitutes
U+FFFD for a bad byte where SBCL's signals."
  (with-open-file (s source :element-type '(unsigned-byte 8))
    (let ((pending 0))                  ; continuation bytes still expected
      (loop for b = (read-byte s nil nil)
            while b
            do (cond ((plusp pending)
                      (if (= (logand b #xC0) #x80)
                          (decf pending)
                          (return-from %dxf-valid-utf-8-p nil)))
                     ((< b #x80))
                     ((<= #xC2 b #xDF) (setf pending 1))
                     ((<= #xE0 b #xEF) (setf pending 2))
                     ((<= #xF0 b #xF4) (setf pending 3))
                     (t (return-from %dxf-valid-utf-8-p nil))))
      (zerop pending))))

(defun %dxf-read-ascii (source external-format unicode-escapes)
  (let ((*dxf-unicode-escapes* unicode-escapes))
    (with-open-file (s source :external-format external-format)
      (dxf-read-drawing-from-stream s))))

(defun dxf-read-drawing (source)
  "Read SOURCE as DXF, auto-detecting ASCII vs binary by its sentinel.
Sets DRAWING-FORMAT precisely (READ-DRAWING leaves it as set). An ASCII
DXF of AC1021 or later is read as UTF-8 (as ISO-8859-1 if it is not
valid UTF-8), an earlier one as ISO-8859-1 with its \\U+XXXX escapes
decoded."
  (if (dxf-binary-file-p source)
      (let ((drawing (with-open-file (s source :element-type '(unsigned-byte 8))
                       (dxf-read-binary-drawing-from-stream s))))
        (setf (drawing-format drawing) :dxf-binary)
        drawing)
      (let ((drawing (if (%dxf-utf-8-version-p (%dxf-sniff-acadver source))
                         (%dxf-read-ascii source
                                          (if (%dxf-valid-utf-8-p source)
                                              :utf-8
                                              +dxf-external-format+)
                                          nil)
                         (%dxf-read-ascii source +dxf-external-format+ t))))
        (setf (drawing-format drawing) :dxf-ascii)
        drawing)))

(defun dxf-write-drawing (drawing destination &key version)
  "Write DRAWING to DESTINATION as ASCII DXF. VERSION (a $ACADVER keyword
such as :ac1032) sets the emitted $ACADVER; NIL uses the drawing's own
version, then the R2013 default. AC1021 and later are written as UTF-8,
earlier versions as ISO-8859-1 with \\U+XXXX for the characters above
#xFF."
  (let* ((*dxf-output-version* (or version (drawing-version drawing)))
         (utf-8 (%dxf-utf-8-version-p (%dxf-acadver-string *dxf-output-version*)))
         (*dxf-unicode-escapes* (not utf-8)))
    (with-open-file (stream destination :direction :output
                                        :if-exists :supersede
                                        :if-does-not-exist :create
                                        :external-format (if utf-8
                                                             :utf-8
                                                             +dxf-external-format+))
      (dxf-write-drawing-to-stream drawing stream))))

(defun dxf-write-binary-drawing (drawing destination &key version)
  "Write DRAWING to DESTINATION as Binary DXF. VERSION sets $ACADVER as in
DXF-WRITE-DRAWING."
  (let ((*dxf-output-version* (or version (drawing-version drawing))))
    (with-open-file (stream destination :direction :output
                                        :if-exists :supersede
                                        :if-does-not-exist :create
                                        :element-type '(unsigned-byte 8))
      (dxf-write-binary-drawing-to-stream drawing stream))))

(register-drawing-codec :dxf-ascii
                        :reader #'dxf-read-drawing
                        :writer #'dxf-write-drawing)

(register-drawing-codec :dxf-binary
                        :reader #'dxf-read-drawing
                        :writer #'dxf-write-binary-drawing)
