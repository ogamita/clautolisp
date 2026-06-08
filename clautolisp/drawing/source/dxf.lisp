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

(defun dxf-read-pair (stream)
  "Read one (CODE . RAW-STRING) group pair from STREAM, or :eof. The
value line is returned verbatim (trimmed); typing happens later."
  (let ((code-line (read-line stream nil :eof)))
    (if (eq code-line :eof)
        :eof
        (let ((value-line (read-line stream nil :eof)))
          (when (eq value-line :eof)
            (error 'drawing-error
                   :format-control "truncated DXF: group code ~S without a value"
                   :format-arguments (list code-line)))
          (let ((code (parse-integer code-line :junk-allowed nil)))
            (cons code (string-trim '(#\Space #\Tab #\Return) value-line)))))))

(defun dxf-parse-value (code raw)
  "Convert the RAW string value of group CODE to its typed CL value."
  (ecase (dxf-code-type code)
    (:string raw)
    (:integer (values (parse-integer raw :junk-allowed t)))
    (:double (let ((*read-default-float-format* 'double-float))
               (coerce (read-from-string raw) 'double-float)))))

(defun dxf-read-typed-pairs (stream)
  "Read STREAM fully into a list of (CODE . TYPED-VALUE) pairs,
stopping after the terminating (0 . \"EOF\"). Comments (999) are
dropped."
  (let ((pairs '()))
    (loop
      (let ((pair (dxf-read-pair stream)))
        (when (eq pair :eof) (return))
        (let ((code (car pair)))
          (unless (= code 999)
            (push (cons code (dxf-parse-value code (cdr pair))) pairs))
          (when (and (= code 0) (string-equal (cdr pair) "EOF"))
            (return)))))
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
                 :kind current-kind :name rname :data group))))))))))

(defun dxf-load-entities (drawing body &optional block)
  "Add the entities in a flat BODY (the ENTITIES section, or the entity
run inside a block) to DRAWING, owned by BLOCK (NIL = model space)."
  (dolist (entity (dxf-split-objects (dxf-coalesce-points body) '(0)))
    (let ((handle-pair (find 5 entity :key #'car)))
      (add-entity drawing entity
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
             (add-entity drawing group
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
          (add-object drawing h obj))))))

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
    (:string  (format stream "~A~%" value))
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

(defun dxf-header-value-code (kind value)
  "Choose a DXF group code to carry a header variable of KIND."
  (case kind
    (:string 1)
    (:integer 70)
    (:short 70)
    (:real 40)
    (:point 10)
    (t (if (consp value) 10 (if (integerp value) 70 (if (stringp value) 1 40))))))

(defun dxf-write-header (drawing)
  (dxf-write-section
   "HEADER"
   (lambda ()
     (dxf-emit 9 "$ACADVER")
     (dxf-emit 1 (or (and (drawing-version drawing)
                          (string-upcase (symbol-name (drawing-version drawing))))
                     "AC1027"))
     (dxf-emit 9 "$HANDSEED")
     (dxf-emit 5 (format nil "~X" (drawing-handle-seed drawing)))
     (map-variables
      (lambda (cell)
        (let ((name (sysvar-cell-name cell))
              (value (sysvar-cell-value cell)))
          (unless (string-equal name "HANDSEED")
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
                   (dxf-write-object (symbol-table-record-data record)))
                 table)
        (dxf-emit 0 "ENDTAB"))
      (drawing-tables drawing)))))

(defun dxf-ordered-entity-data (data)
  "Return DATA with its (0 . TYPE) pair first: a DXF entity must begin
with group code 0, but the drawing stores (5 . handle) first."
  (let ((zero (assoc 0 data)))
    (if zero (cons zero (remove zero data :test #'eq)) data)))

(defun dxf-write-entities (drawing)
  "Emit the ENTITIES section: model-space entities only (those with a
NIL block owner). Block-owned entities are emitted inside BLOCKS."
  (dxf-write-section
   "ENTITIES"
   (lambda ()
     (map-entities (lambda (entity)
                     (unless (entity-handle-block entity)
                       (dxf-write-object
                        (dxf-ordered-entity-data (entity-handle-data entity)))))
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
        (dolist (entity (block-entities drawing name))
          (dxf-write-object (dxf-ordered-entity-data (entity-handle-data entity))))
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

(defun dxf-write-objects (drawing)
  "Emit the OBJECTS section: the named-object dictionary tree (handle
-linked) followed by the standalone non-graphical objects (xrecords)."
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

(defun dxf-write-drawing-body (drawing)
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

(defun dxf-read-drawing (source)
  "Read SOURCE as DXF, auto-detecting ASCII vs binary by its sentinel.
Sets DRAWING-FORMAT precisely (READ-DRAWING leaves it as set)."
  (if (dxf-binary-file-p source)
      (let ((drawing (with-open-file (s source :element-type '(unsigned-byte 8))
                       (dxf-read-binary-drawing-from-stream s))))
        (setf (drawing-format drawing) :dxf-binary)
        drawing)
      (let ((drawing (with-open-file (s source :external-format :utf-8)
                       (dxf-read-drawing-from-stream s))))
        (setf (drawing-format drawing) :dxf-ascii)
        drawing)))

(defun dxf-write-drawing (drawing destination &key version)
  (declare (ignore version))
  (with-open-file (stream destination :direction :output
                                      :if-exists :supersede
                                      :if-does-not-exist :create
                                      :external-format :utf-8)
    (dxf-write-drawing-to-stream drawing stream)))

(defun dxf-write-binary-drawing (drawing destination &key version)
  (declare (ignore version))
  (with-open-file (stream destination :direction :output
                                      :if-exists :supersede
                                      :if-does-not-exist :create
                                      :element-type '(unsigned-byte 8))
    (dxf-write-binary-drawing-to-stream drawing stream)))

(register-drawing-codec :dxf-ascii
                        :reader #'dxf-read-drawing
                        :writer #'dxf-write-drawing)

(register-drawing-codec :dxf-binary
                        :reader #'dxf-read-drawing
                        :writer #'dxf-write-binary-drawing)
