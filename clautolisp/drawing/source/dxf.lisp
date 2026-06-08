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

(defun dxf-load-entities (drawing body)
  (dolist (entity (dxf-split-objects (dxf-coalesce-points body) '(0)))
    (let ((handle-pair (find 5 entity :key #'car)))
      (add-entity drawing entity
                  :handle (and handle-pair (cdr handle-pair))))))

(defun dxf-read-drawing-from-stream (stream)
  "Parse an ASCII DXF STREAM into a fresh DRAWING."
  (let ((drawing (make-drawing))
        (sections (dxf-section-bodies (dxf-read-typed-pairs stream))))
    (let ((header (assoc "HEADER" sections :test #'string-equal)))
      (when header (dxf-load-header drawing (cdr header))))
    (let ((tables (assoc "TABLES" sections :test #'string-equal)))
      (when tables (dxf-load-tables drawing (cdr tables))))
    (let ((entities (assoc "ENTITIES" sections :test #'string-equal)))
      (when entities (dxf-load-entities drawing (cdr entities))))
    drawing))

;;; --- Writer -----------------------------------------------------

(defun dxf-write-pair (stream code value)
  (format stream "~D~%" code)
  (ecase (dxf-code-type code)
    (:string (format stream "~A~%" value))
    (:integer (format stream "~D~%" value))
    (:double (format stream "~A~%" (dxf-format-double value)))))

(defun dxf-format-double (x)
  "Print a double in DXF's plain decimal style (fixed-point, no
exponent marker)."
  (let ((*read-default-float-format* 'double-float))
    (format nil "~F" (coerce x 'double-float))))

(defun dxf-write-data-pair (stream pair)
  "Write one entget-style PAIR, expanding a point value into its
X/Y/Z group codes."
  (let ((code (car pair)) (value (cdr pair)))
    (if (and (dxf-x-coordinate-code-p code)
             (consp value) (every #'numberp value))
        (loop for component in value
              for sub from code by 10
              do (format stream "~D~%~A~%" sub (dxf-format-double component)))
        (dxf-write-pair stream code value))))

(defun dxf-write-object (stream pairs)
  (dolist (pair pairs)
    (when (consp pair) (dxf-write-data-pair stream pair))))

(defun dxf-write-section (stream name body-thunk)
  (format stream "0~%SECTION~%2~%~A~%" name)
  (funcall body-thunk)
  (format stream "0~%ENDSEC~%"))

(defun dxf-write-header (stream drawing)
  (dxf-write-section
   stream "HEADER"
   (lambda ()
     (format stream "9~%$ACADVER~%1~%~A~%"
             (or (and (drawing-version drawing)
                      (string-upcase (symbol-name (drawing-version drawing))))
                 "AC1027"))
     (format stream "9~%$HANDSEED~%5~%~X~%" (drawing-handle-seed drawing))
     (map-variables
      (lambda (cell)
        (let* ((name (sysvar-cell-name cell))
               (value (sysvar-cell-value cell)))
          (unless (string-equal name "HANDSEED")
            (format stream "9~%$~A~%" name)
            (dxf-write-data-pair
             stream (cons (dxf-header-value-code (sysvar-cell-kind cell) value)
                          value)))))
      drawing))))

(defun dxf-header-value-code (kind value)
  "Choose a DXF group code to carry a header variable of KIND."
  (case kind
    (:string 1)
    (:integer 70)
    (:short 70)
    (:real 40)
    (:point 10)
    (t (if (consp value) 10 (if (integerp value) 70 (if (stringp value) 1 40))))))

(defun dxf-write-tables (stream drawing)
  (dxf-write-section
   stream "TABLES"
   (lambda ()
     (maphash
      (lambda (kind table)
        (format stream "0~%TABLE~%2~%~A~%70~%~D~%"
                (dxf-table-name kind) (hash-table-count table))
        (maphash (lambda (name record)
                   (declare (ignore name))
                   (dxf-write-object stream (symbol-table-record-data record)))
                 table)
        (format stream "0~%ENDTAB~%"))
      (drawing-tables drawing)))))

(defun dxf-ordered-entity-data (data)
  "Return DATA with its (0 . TYPE) pair first: a DXF entity must begin
with group code 0, but the drawing stores (5 . handle) first."
  (let ((zero (assoc 0 data)))
    (if zero (cons zero (remove zero data :test #'eq)) data)))

(defun dxf-write-entities (stream drawing)
  (dxf-write-section
   stream "ENTITIES"
   (lambda ()
     (map-entities (lambda (entity)
                     (dxf-write-object
                      stream (dxf-ordered-entity-data (entity-handle-data entity))))
                   drawing))))

(defun dxf-write-drawing-to-stream (drawing stream)
  (dxf-write-header stream drawing)
  (dxf-write-tables stream drawing)
  (dxf-write-entities stream drawing)
  (format stream "0~%EOF~%")
  drawing)

;;; --- Codec registration -----------------------------------------

(defun dxf-read-drawing (source)
  (with-open-file (stream source :direction :input
                                 :external-format :utf-8)
    (dxf-read-drawing-from-stream stream)))

(defun dxf-write-drawing (drawing destination &key version)
  (declare (ignore version))
  (with-open-file (stream destination :direction :output
                                      :if-exists :supersede
                                      :if-does-not-exist :create
                                      :external-format :utf-8)
    (dxf-write-drawing-to-stream drawing stream)))

(register-drawing-codec :dxf-ascii
                        :reader #'dxf-read-drawing
                        :writer #'dxf-write-drawing)
