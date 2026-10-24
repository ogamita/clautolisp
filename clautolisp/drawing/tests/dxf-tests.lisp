(in-package #:clautolisp.drawing.tests)

(in-suite drawing-suite)

;;; --- Group-code typing -------------------------------------------

(test dxf-code-typing
  (is (eq :string  (dxf-code-type 0)))
  (is (eq :string  (dxf-code-type 8)))
  (is (eq :double  (dxf-code-type 10)))
  (is (eq :double  (dxf-code-type 40)))
  (is (eq :integer (dxf-code-type 62)))
  (is (eq :integer (dxf-code-type 90)))
  (is (eq :string  (dxf-code-type 330))))   ; handle reference

;;; --- Parsing a hand-written DXF ----------------------------------

(defparameter +sample-dxf+
  (format nil "~{~A~%~}"
          '("0" "SECTION" "2" "HEADER"
            "9" "$ACADVER" "1" "AC1027"
            "9" "$HANDSEED" "5" "64"
            "9" "$CLAYER" "1" "WALLS"
            "0" "ENDSEC"
            "0" "SECTION" "2" "TABLES"
            "0" "TABLE" "2" "LAYER" "70" "1"
            "0" "LAYER" "5" "10" "2" "WALLS" "70" "0" "62" "7"
            "0" "ENDTAB"
            "0" "ENDSEC"
            "0" "SECTION" "2" "ENTITIES"
            "0" "LINE" "5" "20" "8" "WALLS"
            "10" "1.0" "20" "2.0" "30" "0.0"
            "11" "3.0" "21" "4.0" "31" "0.0"
            "0" "ENDSEC"
            "0" "EOF")))

(test dxf-reads-header-tables-entities
  (let ((d (with-input-from-string (s +sample-dxf+)
             (dxf-read-drawing-from-stream s))))
    ;; Header: $HANDSEED 0x64 = 100; $ACADVER -> version; $CLAYER var.
    (is (= 100 (drawing-handle-seed d)))
    (is (eq :ac1027 (drawing-version d)))
    (is (string= "WALLS" (drawing-variable d "CLAYER")))
    ;; Table: one LAYER record named WALLS.
    (let ((rec (find-table-record d :layer "WALLS")))
      (is (not (null rec)))
      (is (eql 7 (cdr (assoc 62 (table-record-dxf rec))))))
    ;; Entity: one LINE; points coalesced into (x y z).
    (is (= 1 (drawing-entity-count d)))
    (let* ((e (find-entity d "20"))
           (dxf (and e (entity-dxf e))))
      (is (not (null e)))
      (is (eq :line (entity-kind e)))
      (is (string= "WALLS" (cdr (assoc 8 dxf))))
      (is (equal '(1.0d0 2.0d0 0.0d0) (cdr (assoc 10 dxf))))
      (is (equal '(3.0d0 4.0d0 0.0d0) (cdr (assoc 11 dxf)))))))

;;; --- Round-trip through write then read --------------------------

(defun build-sample-drawing ()
  (let ((d (make-drawing :version :ac1027)))
    (ensure-drawing-variable d "CLAYER" :kind :string :value "0")
    (add-table-record d (make-symbol-table-record
                         :kind :layer :name "WALLS"
                         :data '((0 . "LAYER") (2 . "WALLS") (70 . 0) (62 . 1))))
    (add-entity d '((0 . "LINE") (8 . "0") (10 1.0d0 2.0d0 0.0d0)
                    (11 3.0d0 4.0d0 0.0d0)))
    (add-entity d '((0 . "CIRCLE") (8 . "WALLS") (10 5.0d0 6.0d0 0.0d0)
                    (40 . 2.5d0)))
    d))

(test dxf-round-trip-preserves-entities-tables-seed
  (let* ((original (build-sample-drawing))
         (text (with-output-to-string (s)
                 (dxf-write-drawing-to-stream original s)))
         (restored (with-input-from-string (s text)
                     (dxf-read-drawing-from-stream s))))
    ;; Handle allocator preserved.
    (is (= (drawing-handle-seed original) (drawing-handle-seed restored)))
    ;; Entity count and per-entity data preserved (pure-form equalp).
    (is (= (drawing-entity-count original) (drawing-entity-count restored)))
    (let ((orig '()) (rest '()))
      (map-entities (lambda (e) (push (entity-dxf e) orig)) original)
      (map-entities (lambda (e) (push (entity-dxf e) rest)) restored)
      (is (equalp (nreverse orig) (nreverse rest))))
    ;; Layer table record preserved.
    (let ((r (find-table-record restored :layer "WALLS")))
      (is (not (null r)))
      (is (eql 1 (cdr (assoc 62 (table-record-dxf r))))))
    ;; Header variable value preserved.
    (is (string= "0" (drawing-variable restored "CLAYER")))))

(test dxf-round-trip-keeps-handles-stable
  ;; The layer record added first takes handle 10 (table records share the
  ;; entities' handle space, cador-entget-subclass-layout-and-record-pointers
  ;; item 3); the entities follow.
  (let* ((original (build-sample-drawing))
         (e1 (entity-handle-string (find-entity original "11")))
         (text (with-output-to-string (s)
                 (dxf-write-drawing-to-stream original s)))
         (restored (with-input-from-string (s text)
                     (dxf-read-drawing-from-stream s))))
    (is (string= "11" e1))
    (is (equal "10" (symbol-table-record-id (find-table-record original :layer "WALLS"))))
    (is (equal "10" (symbol-table-record-id (find-table-record restored :layer "WALLS"))))
    (is (not (null (find-entity restored "11"))))     ; first entity
    (is (not (null (find-entity restored "12"))))))    ; second entity

;;; --- BLOCKS round-trip -------------------------------------------

(defun build-drawing-with-block ()
  (let ((d (make-drawing :version :ac1027)))
    (add-block d "MYBLOCK"
               '((0 . "BLOCK") (2 . "MYBLOCK") (70 . 0)
                 (10 0.0d0 0.0d0 0.0d0)))
    ;; one entity owned by the block, one in model space
    (add-entity d '((0 . "LINE") (8 . "0") (10 0.0d0 0.0d0 0.0d0)
                    (11 1.0d0 1.0d0 0.0d0))
                :block "MYBLOCK")
    (add-entity d '((0 . "CIRCLE") (8 . "0") (10 5.0d0 5.0d0 0.0d0)
                    (40 . 1.0d0)))
    d))

(test dxf-round-trip-preserves-blocks-and-ownership
  (let* ((original (build-drawing-with-block))
         (text (with-output-to-string (s)
                 (dxf-write-drawing-to-stream original s)))
         (restored (with-input-from-string (s text)
                     (dxf-read-drawing-from-stream s))))
    ;; The block definition survives.
    (is (not (null (find-block restored "MYBLOCK"))))
    (is (string= "MYBLOCK" (cdr (assoc 2 (find-block restored "MYBLOCK")))))
    ;; Exactly one entity is owned by the block; it is a LINE.
    (let ((owned (block-entities restored "MYBLOCK")))
      (is (= 1 (length owned)))
      (is (eq :line (entity-kind (first owned))))
      (is (string-equal "MYBLOCK" (entity-handle-block (first owned)))))
    ;; The model-space CIRCLE has no block owner.
    (is (= 2 (drawing-entity-count restored)))
    (let ((circle (find-if (lambda (e) (eq :circle (entity-kind e)))
                           (let (acc) (map-entities (lambda (e) (push e acc)) restored)
                                (nreverse acc)))))
      (is (not (null circle)))
      (is (null (entity-handle-block circle))))))

;;; --- OBJECTS (named-object dictionary) round-trip ----------------

(test dxf-round-trip-preserves-named-object-dictionary
  (let* ((original (make-drawing))
         (nod (drawing-dictionary original)))
    (dictionary-put nod "ACAD_GROUP" "2F")
    (dictionary-put nod "ACAD_LAYOUT" "1C")
    (let* ((text (with-output-to-string (s)
                   (dxf-write-drawing-to-stream original s)))
           (restored (with-input-from-string (s text)
                       (dxf-read-drawing-from-stream s)))
           (rnod (drawing-dictionary restored)))
      (is (string= "2F" (dictionary-get rnod "ACAD_GROUP")))
      (is (string= "1C" (dictionary-get rnod "ACAD_LAYOUT"))))))

(test dxf-reads-blocks-and-objects-from-literal
  (let* ((dxf (format nil "~{~A~%~}"
                      '("0" "SECTION" "2" "BLOCKS"
                        "0" "BLOCK" "5" "30" "2" "FRAME" "70" "0"
                        "10" "0.0" "20" "0.0" "30" "0.0"
                        "0" "LINE" "5" "31" "8" "0"
                        "10" "0.0" "20" "0.0" "30" "0.0"
                        "11" "1.0" "21" "0.0" "31" "0.0"
                        "0" "ENDBLK"
                        "0" "ENDSEC"
                        "0" "SECTION" "2" "OBJECTS"
                        "0" "DICTIONARY" "5" "C"
                        "3" "ACAD_MLINESTYLE" "350" "17"
                        "0" "ENDSEC"
                        "0" "EOF")))
         (d (with-input-from-string (s dxf) (dxf-read-drawing-from-stream s))))
    (is (not (null (find-block d "FRAME"))))
    (is (= 1 (length (block-entities d "FRAME"))))
    (is (string= "17" (dictionary-get (drawing-dictionary d) "ACAD_MLINESTYLE")))))

;;; --- Deep OBJECTS: nested dictionaries + xrecords ----------------

(test dxf-round-trip-preserves-nested-dictionaries
  (let* ((original (make-drawing))
         (nod (drawing-dictionary original))
         (sub (make-dictionary)))
    (dictionary-put sub "ENTRY1" "A1")
    (dictionary-put nod "ACAD_GROUP" "2F")    ; plain handle entry
    (dictionary-put nod "ACAD_LAYOUT" sub)    ; nested sub-dictionary
    (let* ((text (with-output-to-string (s) (dxf-write-drawing-to-stream original s)))
           (restored (with-input-from-string (s text) (dxf-read-drawing-from-stream s)))
           (rnod (drawing-dictionary restored)))
      (is (string= "2F" (dictionary-get rnod "ACAD_GROUP")))
      (let ((rsub (dictionary-get rnod "ACAD_LAYOUT")))
        (is (dictionary-p rsub))
        (is (string= "A1" (dictionary-get rsub "ENTRY1")))))))

(test dxf-round-trip-preserves-xrecords
  (let* ((original (make-drawing))
         (nod (drawing-dictionary original)))
    (add-object original "1A"
                '((0 . "XRECORD") (5 . "1A") (100 . "AcDbXrecord")
                  (1 . "schms-payload") (90 . 42)))
    (dictionary-put nod "SCHMS_DATA" "1A")
    (let* ((text (with-output-to-string (s) (dxf-write-drawing-to-stream original s)))
           (restored (with-input-from-string (s text) (dxf-read-drawing-from-stream s))))
      ;; The dictionary entry still points at the xrecord's handle.
      (is (string= "1A" (dictionary-get (drawing-dictionary restored) "SCHMS_DATA")))
      ;; The xrecord object itself round-trips, retrievable by handle.
      (let ((xr (find-object restored "1A")))
        (is (not (null xr)))
        (is (string= "schms-payload" (cdr (assoc 1 xr))))
        (is (eql 42 (cdr (assoc 90 xr))))))))

;;; --- Robustness: string values with embedded newlines ------------

(test dxf-reads-multiline-string-values
  ;; Some writers (e.g. libredwg's MTEXT output) emit a string value
  ;; that spans several physical lines instead of escaping the breaks.
  ;; The reader must re-join the continuation lines, not mistake them
  ;; for group codes.
  (let* ((dxf (format nil "~{~A~%~}"
                      '("0" "SECTION" "2" "ENTITIES"
                        "0" "MTEXT" "5" "2A"
                        "1" "first line"
                        "second line: reperes 1143, 1149"
                        "third line"
                        "8" "0"
                        "0" "ENDSEC" "0" "EOF")))
         (d (with-input-from-string (s dxf) (dxf-read-drawing-from-stream s)))
         (e (first (let (acc) (map-entities (lambda (x) (push x acc)) d) acc)))
         (text (cdr (assoc 1 (entity-dxf e)))))
    (is (eq :mtext (entity-kind e)))
    (is (search "first line" text))
    (is (search "second line: reperes 1143, 1149" text))
    (is (search "third line" text))
    ;; the group code 8 after the multiline value is still parsed
    (is (string= "0" (cdr (assoc 8 (entity-dxf e)))))))

;;; --- Binary DXF --------------------------------------------------

(test dxf-double-bit-codec-round-trips
  (dolist (x '(0.0d0 1.0d0 -1.0d0 2.5d0 0.5d0 100.0d0
               3.141592653589793d0 1234.5d0 1.0d300 -1.0d-300))
    (is (= x (bits->double (double->bits x))))))

(test dxf-binary-round-trip-via-file
  (uiop:with-temporary-file (:pathname p :type "dxf")
    (let ((original (build-drawing-with-block)))
      (write-drawing original p :format :dxf-binary)
      ;; The file is binary (begins with the sentinel) and reads back
      ;; with its format detected.
      (is (dxf-binary-file-p p))
      (let ((restored (read-drawing p)))
        (is (eq :dxf-binary (drawing-format restored)))
        (is (= (drawing-entity-count original) (drawing-entity-count restored)))
        (is (= (drawing-handle-seed original) (drawing-handle-seed restored)))
        (is (not (null (find-block restored "MYBLOCK"))))
        (is (= 1 (length (block-entities restored "MYBLOCK"))))
        ;; Entity data (incl. doubles and points) round-trips exactly.
        (let ((o '()) (r '()))
          (map-entities (lambda (e) (push (entity-dxf e) o)) original)
          (map-entities (lambda (e) (push (entity-dxf e) r)) restored)
          (is (equalp (nreverse o) (nreverse r))))))))

(test dxf-ascii-and-binary-agree-on-content
  (uiop:with-temporary-file (:pathname pa :type "dxf")
    (uiop:with-temporary-file (:pathname pb :type "dxf")
      (let ((d (build-sample-drawing)))
        (write-drawing d pa :format :dxf-ascii)
        (write-drawing d pb :format :dxf-binary)
        (is (not (dxf-binary-file-p pa)))
        (is (dxf-binary-file-p pb))
        (let ((from-ascii (read-drawing pa))
              (from-binary (read-drawing pb))
              (entities (lambda (dr)
                          (let (acc) (map-entities (lambda (e) (push (entity-dxf e) acc)) dr)
                               (nreverse acc)))))
          (is (equalp (funcall entities from-ascii)
                      (funcall entities from-binary))))))))

;;; --- Dispatch integration (probe + read/write via the registry) --

(test dxf-registered-on-the-format-dispatch
  (is (eq :dxf-ascii (probe-drawing-format "/tmp/plan.dxf")))
  (is (not (null (find-drawing-codec :dxf-ascii)))))

;;; --- Header variables a reader can actually take -------------------
;;;
;;; dwg-write-rejects-a-drawing-built-in-memory. Two header defects made
;;; libredwg refuse every DXF a clautolisp session produced, while a
;;; drawing READ from a DWG round-tripped -- because a parsed drawing's
;;; sysvars come from the file, where they are already DXF-shaped.

(test dxf-header-writes-acadver-once-and-as-the-format-version
  "$ACADVER is the FILE FORMAT version in a DXF header. As a sysvar it is
the PRODUCT version -- \"24.1s (LMS Tech)\" on AutoCAD, clautolisp's own
version here -- so the sysvar pass must not emit it a second time: DXF
has one slot per variable and the last one wins, which replaced AC1027
with something no reader accepts (libredwg: DWG_ERR_INVALIDDWG)."
  (let ((d (make-drawing :version :ac1027)))
    (ensure-drawing-variable d "ACADVER" :kind :string :value "2.2.99")
    (ensure-drawing-variable d "HANDSEED" :kind :string :value "ZZZ")
    (let* ((text (with-output-to-string (s) (dxf-write-drawing-to-stream d s)))
           (count 0) (start 0))
      (loop for pos = (search "$ACADVER" text :start2 start)
            while pos do (incf count) (setf start (1+ pos)))
      (is (= 1 count) "exactly one $ACADVER, got ~D" count)
      (is (search "AC1027" text) "the format version must be written")
      (is (not (search "2.2.99" text))
          "the PRODUCT version must not reach the header")
      ;; Same reasoning for HANDSEED, which was already excluded.
      (let ((seeds 0) (from 0))
        (loop for pos = (search "$HANDSEED" text :start2 from)
              while pos do (incf seeds) (setf from (1+ pos)))
        (is (= 1 seeds) "exactly one $HANDSEED, got ~D" seeds)))))

(test dxf-header-integer-group-code-follows-the-value
  "Group 70 carries a signed 16-bit integer; 90 is the 32-bit one. A
sysvar can exceed the smaller range -- CMPDIFFLIMIT is 10000000 by
default -- and writing it as 70 gave a header libredwg would not read at
all (DWG_ERR_IOERROR). The code is chosen from the VALUE, so a small one
still uses 70 and nothing else about the header changes."
  (is (= 70 (clautolisp.drawing::dxf-header-value-code :integer 40)))
  (is (= 70 (clautolisp.drawing::dxf-header-value-code :integer -32768)))
  (is (= 70 (clautolisp.drawing::dxf-header-value-code :integer 32767)))
  (is (= 90 (clautolisp.drawing::dxf-header-value-code :integer 32768)))
  (is (= 90 (clautolisp.drawing::dxf-header-value-code :integer -32769)))
  (is (= 90 (clautolisp.drawing::dxf-header-value-code :integer 10000000)))
  (is (= 70 (clautolisp.drawing::dxf-header-value-code :short 1)))
  (is (= 90 (clautolisp.drawing::dxf-header-value-code :short 10000000)))
  ;; The untyped fallback follows the same rule.
  (is (= 70 (clautolisp.drawing::dxf-header-value-code nil 7)))
  (is (= 90 (clautolisp.drawing::dxf-header-value-code nil 10000000)))
  ;; And a big integer really is emitted as 90 in a written header.
  (let ((d (make-drawing :version :ac1027)))
    (ensure-drawing-variable d "CMPDIFFLIMIT" :kind :integer :value 10000000)
    (let ((text (with-output-to-string (s) (dxf-write-drawing-to-stream d s))))
      (is (search "$CMPDIFFLIMIT" text))
      (let ((pos (search "$CMPDIFFLIMIT" text)))
        (is (search "90" text :start2 pos :end2 (min (length text) (+ pos 24)))
            "a 10000000 sysvar must be written with group 90: ~S"
            (subseq text pos (min (length text) (+ pos 24))))))))

;;; --- Entities name their owner -------------------------------------
;;;
;;; dwg-round-trip-loses-entities. An entity in a DXF belongs to a block
;;; record -- model space is the record named "*Model_Space" -- and says
;;; so with group 330. libredwg SILENTLY DROPS an entity that does not,
;;; or whose owner handle does not resolve: a LINE written without it came
;;; back from a DWG round trip as nothing, with rc 0. The 100 AcDbEntity /
;;; AcDbLine subclass markers turned out not to matter; the owner does.

(test dxf-entities-carry-their-owner-block-record
  "A model-space entity is written with (330 . H) where H is the handle of
the *Model_Space BLOCK_RECORD, and the record is written WITH that handle
-- so the reference resolves. The handle is allocated when the record has
none, which is what a from-scratch drawing has, and it lands AFTER the
record's (0 . \"BLOCK_RECORD\") marker, because a DXF object must begin
with its type."
  (let ((d (make-drawing :version :ac1027)))
    (add-table-record d (make-symbol-table-record
                         :kind :block-record :name "*Model_Space"
                         :data (list (cons 0 "BLOCK_RECORD")
                                     (cons 2 "*Model_Space"))))
    (add-entity d (list (cons 0 "LINE") (cons 8 "0")
                        (cons 10 0.0d0) (cons 20 0.0d0) (cons 30 0.0d0)
                        (cons 11 1.0d0) (cons 21 1.0d0) (cons 31 0.0d0)))
    (let* ((text (with-output-to-string (s) (dxf-write-drawing-to-stream d s)))
           (record (find-table-record d :block-record "*Model_Space"))
           (handle (cdr (assoc 5 (symbol-table-record-data record)))))
      (is (stringp handle) "the record must have been given a handle")
      ;; The record's data starts with its type, then the handle.
      (is (= 0 (car (first (symbol-table-record-data record))))
          "the (0 . type) pair must stay first: ~S"
          (subseq (symbol-table-record-data record) 0 2))
      (is (= 5 (car (second (symbol-table-record-data record)))))
      ;; The entity names it.
      (let* ((pos (search (format nil "~%LINE~%") text))
             (window (and pos (subseq text pos (min (length text) (+ pos 120))))))
        (is (not (null pos)) "the LINE must be written")
        (is (search (format nil "~%330~%~A~%" handle) window)
            "the entity must name the owner handle ~S: ~S" handle window))
      ;; And the record itself carries that handle, so the reference resolves.
      (is (search (format nil "~%5~%~A~%" handle) text)))))

(test dxf-entities-keep-an-owner-they-already-have
  "An entity that already carries a 330 keeps it: a drawing read from a
file has real owners, and the writer must not overwrite them with model
space."
  (let ((d (make-drawing :version :ac1027)))
    (add-table-record d (make-symbol-table-record
                         :kind :block-record :name "*Model_Space"
                         :data (list (cons 0 "BLOCK_RECORD") (cons 5 "1F")
                                     (cons 2 "*Model_Space"))))
    (add-entity d (list (cons 0 "LINE") (cons 8 "0") (cons 330 "ABC")
                        (cons 10 0.0d0) (cons 20 0.0d0) (cons 30 0.0d0)
                        (cons 11 1.0d0) (cons 21 1.0d0) (cons 31 0.0d0)))
    (let ((text (with-output-to-string (s) (dxf-write-drawing-to-stream d s))))
      (is (search (format nil "~%330~%ABC~%") text)
          "the entity's own owner must survive")
      (is (not (search (format nil "~%330~%1F~%") text))
          "and must not be replaced by model space"))))

;;; --- version output (drawing-codec-version-output.issue) ----------
;;; The writers honour the requested version: it becomes the file's
;;; $ACADVER, which a round-trip reads back into drawing-version.

(test dxf-write-honors-requested-version
  (let ((d (build-sample-drawing)))               ; own version :ac1027
    (uiop:with-temporary-file (:pathname p :type "dxf")
      (dxf-write-drawing d p :version :ac1032)     ; DWG 2018
      (is (eq :ac1032 (drawing-version (dxf-read-drawing p))))
      (is (search "AC1032" (uiop:read-file-string p))))
    ;; With no explicit version the drawing's own version is used.
    (uiop:with-temporary-file (:pathname p :type "dxf")
      (dxf-write-drawing d p)
      (is (eq :ac1027 (drawing-version (dxf-read-drawing p)))))))

(test dxf-binary-write-honors-requested-version
  (let ((d (build-sample-drawing)))
    (uiop:with-temporary-file (:pathname p :type "dxf")
      (dxf-write-binary-drawing d p :version :ac1024) ; DWG 2010
      (with-open-file (s p :element-type '(unsigned-byte 8))
        (is (eq :ac1024 (drawing-version (dxf-read-binary-drawing-from-stream s))))))))

(test dxf-acadver-string-validates-version
  ;; An accepted version keyword -> its $ACADVER string; a bad one and a
  ;; string are handled without erroring.
  (is (string= "AC1032" (clautolisp.drawing::%dxf-acadver-string :ac1032)))
  (is (string= "AC1027" (clautolisp.drawing::%dxf-acadver-string :ac1027)))
  (is (string= "AC1027" (clautolisp.drawing::%dxf-acadver-string :bogus)))
  (is (string= "AC1027" (clautolisp.drawing::%dxf-acadver-string nil)))
  (is (string= "AC1015" (clautolisp.drawing::%dxf-acadver-string "ac1015"))))

;;; --- Angle units (dxf-file-angle-units.issue) -----------------------
;;; A DXF file stores entity angles in DEGREES; entget reports them in
;;; RADIANS. The codec converts per entity type, on read and on write.

(defun %angle-close-p (a b)
  (and (realp a) (realp b) (< (abs (- a b)) 1d-9)))

(defun %entities-by-type (drawing)
  "Model-space entities of DRAWING as an alist type -> entity data."
  (let ((acc '()))
    (map-entities (lambda (e)
                    (unless (entity-handle-block e)
                      (push (cons (cdr (assoc 0 (entity-dxf e))) (entity-dxf e)) acc)))
                  drawing)
    (nreverse acc)))

(defparameter +angle-sample-dxf+
  (format nil "~{~A~%~}"
          '("0" "SECTION" "2" "BLOCKS"
            "0" "BLOCK" "5" "30" "2" "TAG" "70" "0"
            "10" "0.0" "20" "0.0" "30" "0.0"
            "0" "TEXT" "5" "31" "8" "0"
            "10" "0.0" "20" "0.0" "30" "0.0" "40" "1.0" "1" "IN-BLOCK"
            "50" "180.0"
            "0" "ENDBLK"
            "0" "ENDSEC"
            "0" "SECTION" "2" "ENTITIES"
            "0" "ARC" "5" "2A" "8" "0"
            "10" "0.0" "20" "0.0" "30" "0.0" "40" "10.0"
            "50" "0.0" "51" "90.0"
            "0" "TEXT" "5" "2B" "8" "0"
            "10" "1.0" "20" "2.0" "30" "0.0" "40" "2.5" "1" "HELLO"
            "50" "45.0" "51" "15.0"
            "0" "INSERT" "5" "2C" "8" "0" "2" "TAG"
            "10" "5.0" "20" "5.0" "30" "0.0"
            "50" "30.0"
            "0" "ELLIPSE" "5" "2D" "8" "0"
            "10" "0.0" "20" "0.0" "30" "0.0"
            "11" "4.0" "21" "0.0" "31" "0.0" "40" "0.5"
            "41" "0.0" "42" "3.141592653589793"
            "0" "ENDSEC"
            "0" "EOF")))

(test dxf-read-converts-file-degrees-to-radians
  "A vendor DXF says ARC 0..90, TEXT rotation 45 / oblique 15, INSERT
rotation 30 -- in DEGREES. entget must see radians. ELLIPSE 41/42 are
parameters (radians in the file too) and must not be touched."
  (let* ((d (with-input-from-string (s +angle-sample-dxf+)
              (dxf-read-drawing-from-stream s)))
         (by-type (%entities-by-type d))
         (arc (cdr (assoc "ARC" by-type :test #'equal)))
         (text (cdr (assoc "TEXT" by-type :test #'equal)))
         (insert (cdr (assoc "INSERT" by-type :test #'equal)))
         (ellipse (cdr (assoc "ELLIPSE" by-type :test #'equal))))
    (is (%angle-close-p 0d0 (cdr (assoc 50 arc))))
    (is (%angle-close-p (/ pi 2) (cdr (assoc 51 arc)))
        "ARC end angle 90 deg must read as pi/2, got ~S" (cdr (assoc 51 arc)))
    (is (%angle-close-p (/ pi 4) (cdr (assoc 50 text)))
        "TEXT rotation 45 deg must read as pi/4, got ~S" (cdr (assoc 50 text)))
    (is (%angle-close-p (/ pi 12) (cdr (assoc 51 text))))
    (is (%angle-close-p (/ pi 6) (cdr (assoc 50 insert)))
        "INSERT rotation 30 deg must read as pi/6, got ~S" (cdr (assoc 50 insert)))
    (is (%angle-close-p pi (cdr (assoc 42 ellipse)))
        "ELLIPSE 42 is a parameter, already radians: ~S" (cdr (assoc 42 ellipse)))
    ;; Block-owned entities are converted too.
    (let ((owned (first (block-entities d "TAG"))))
      (is (not (null owned)))
      (is (%angle-close-p pi (cdr (assoc 50 (entity-dxf owned))))))))

(defun %dxf-value-after (text code-line start-marker)
  "The value line following the first CODE-LINE group after START-MARKER
in the ASCII DXF TEXT, parsed as a double."
  (let* ((from (search start-marker text))
         (pos (and from (search (format nil "~%~A~%" code-line) text :start2 from))))
    (when pos
      (let* ((vstart (+ pos (length code-line) 2))
             (vend (position #\Newline text :start vstart)))
        (let ((*read-default-float-format* 'double-float))
          (coerce (read-from-string (subseq text vstart vend)) 'double-float))))))

(test dxf-write-emits-degrees
  "An ARC of 0..pi/2 in entget units is written as 0 and 90 in the file,
which is what AutoCAD / BricsCAD read; a lone LWPOLYLINE bulge 42 is not
an angle and is written unchanged."
  (let ((d (make-drawing :version :ac1027)))
    (add-entity d (list (cons 0 "ARC") (cons 8 "0") (list 10 0d0 0d0 0d0)
                        (cons 40 10d0) (cons 50 0d0) (cons 51 (/ pi 2))))
    (add-entity d (list (cons 0 "LWPOLYLINE") (cons 8 "0") (cons 90 2) (cons 70 0)
                        (list 10 0d0 0d0) (cons 42 1d0) (list 10 1d0 0d0)))
    (let ((text (with-output-to-string (s) (dxf-write-drawing-to-stream d s))))
      (let ((start (%dxf-value-after text "50" (format nil "~%ARC~%")))
            (end (%dxf-value-after text "51" (format nil "~%ARC~%"))))
        (is (%angle-close-p 0d0 start) "ARC 50 in the file: ~S" start)
        (is (%angle-close-p 90d0 end) "ARC 51 in the file must be 90: ~S" end))
      (is (%angle-close-p 1d0 (%dxf-value-after text "42" (format nil "~%LWPOLYLINE~%")))))))

(test dxf-mtext-rotation-is-the-direction-in-the-file
  "MTEXT, as AutoCAD 2022 and BricsCAD V25 / V26 do it (dxf-angles probe,
MR !472): the file carries the rotation as the 11 direction only, entget as
50. Reading an 11-only MTEXT derives 50; writing one with an 11 leaves 50 out."
  (let* ((text (format nil "0~%SECTION~%2~%ENTITIES~%0~%MTEXT~%5~%2A~%8~%0~%10~%0.0~%20~%0.0~%30~%0.0~%40~%1.0~%1~%x~%11~%0.5~%21~%0.8660254037844386~%31~%0.0~%0~%ENDSEC~%0~%EOF~%"))
         (d (with-input-from-string (s text) (dxf-read-drawing-from-stream s)))
         (mtext (cdr (assoc "MTEXT" (%entities-by-type d) :test #'equal))))
    (is (%angle-close-p (/ pi 3) (cdr (assoc 50 mtext)))
        "an 11-only MTEXT must load with (50 . pi/3): ~S" (assoc 50 mtext))
    (let ((out (with-output-to-string (s) (dxf-write-drawing-to-stream d s))))
      (let* ((from (search (format nil "~%MTEXT~%") out))
             (to (and from (search (format nil "~%0~%") out :start2 (1+ from))))
             (entity (and from (subseq out from to))))
        (is (and entity (not (search (format nil "~%50~%") entity)))
            "an MTEXT with an 11 direction is written without 50: ~S" entity))
      (is (%angle-close-p 0.5d0 (%dxf-value-after out "11" (format nil "~%MTEXT~%")))))))

(test dxf-angle-round-trip
  "Write then read: the entget angles come back (to rounding)."
  (let ((d (make-drawing :version :ac1027)))
    (add-entity d (list (cons 0 "ARC") (cons 8 "0") (list 10 0d0 0d0 0d0)
                        (cons 40 10d0) (cons 50 (/ pi 3)) (cons 51 (* 1.5d0 pi))))
    (add-entity d (list (cons 0 "INSERT") (cons 8 "0") (cons 2 "X")
                        (list 10 0d0 0d0 0d0) (cons 50 0.7d0)))
    (let* ((text (with-output-to-string (s) (dxf-write-drawing-to-stream d s)))
           (restored (with-input-from-string (s text) (dxf-read-drawing-from-stream s)))
           (by-type (%entities-by-type restored))
           (arc (cdr (assoc "ARC" by-type :test #'equal)))
           (insert (cdr (assoc "INSERT" by-type :test #'equal))))
      (is (%angle-close-p (/ pi 3) (cdr (assoc 50 arc))))
      (is (%angle-close-p (* 1.5d0 pi) (cdr (assoc 51 arc))))
      (is (%angle-close-p 0.7d0 (cdr (assoc 50 insert))))
      ;; The source drawing's data is not mutated by the writer.
      (let ((src (cdr (assoc "ARC" (%entities-by-type d) :test #'equal))))
        (is (%angle-close-p (* 1.5d0 pi) (cdr (assoc 51 src))))))))

(test dxf-mtext-column-heights-are-not-angles
  "MTEXT reuses 50 for column heights after its 75/76 column data; only a
rotation 50 BEFORE that is an angle."
  (let ((data '((0 . "MTEXT") (50 . 90d0) (75 . 2) (76 . 2) (50 . 3d0) (50 . 4d0))))
    (let ((out (clautolisp.drawing::dxf-entity-from-file data)))
      (is (%angle-close-p (/ pi 2) (cdr (second out))))
      (is (equal '((75 . 2) (76 . 2) (50 . 3d0) (50 . 4d0)) (cddr out))))))

;;; --- Angle units: HATCH, VIEWPORT, table records ------------------
;;; (dxf-angle-units-hatch-viewport-tables.issue) Group codes 50-58 are
;;; angles: degrees in the DXF file, radians through AutoLISP. HATCH
;;; repeats them (boundary arc / elliptic-arc edges 50/51, one 53 per
;;; pattern line), so every occurrence is converted there.

(defparameter +hatch-viewport-angle-dxf+
  (format nil "~{~A~%~}"
          '("0" "SECTION" "2" "TABLES"
            "0" "TABLE" "2" "VPORT" "70" "1"
            "0" "VPORT" "5" "40" "2" "*ACTIVE" "70" "0"
            "10" "0.0" "20" "0.0" "11" "1.0" "21" "1.0"
            "50" "15.0" "51" "30.0" "75" "0" "76" "0"
            "0" "ENDTAB"
            "0" "TABLE" "2" "VIEW" "70" "1"
            "0" "VIEW" "5" "41" "2" "V1" "70" "0" "40" "10.0"
            "10" "0.0" "20" "0.0" "41" "10.0"
            "50" "45.0"
            "0" "ENDTAB"
            "0" "TABLE" "2" "STYLE" "70" "1"
            "0" "STYLE" "5" "42" "2" "SLANT" "70" "0" "40" "0.0" "41" "1.0"
            "50" "15.0" "71" "0" "42" "2.5" "3" "txt"
            "0" "ENDTAB"
            "0" "ENDSEC"
            "0" "SECTION" "2" "ENTITIES"
            "0" "HATCH" "5" "50" "8" "0"
            "10" "0.0" "20" "0.0" "30" "0.0"
            "2" "ANSI31" "70" "0" "71" "0" "91" "1"
            "92" "1" "93" "3"
            "72" "1" "10" "0.0" "20" "0.0" "11" "10.0" "21" "0.0"
            "72" "2" "10" "0.0" "20" "0.0" "40" "10.0"
            "50" "0.0" "51" "90.0" "73" "1"
            "72" "3" "10" "0.0" "20" "0.0" "11" "10.0" "21" "0.0" "40" "0.5"
            "50" "90.0" "51" "180.0" "73" "1"
            "97" "0"
            "75" "0" "76" "1" "52" "30.0" "41" "1.0" "77" "0" "78" "2"
            "53" "75.0" "43" "0.0" "44" "0.0" "45" "-2.2" "46" "2.2" "79" "0"
            "53" "165.0" "43" "0.0" "44" "0.0" "45" "-2.2" "46" "2.2" "79" "2"
            "49" "1.0" "49" "-0.5"
            "98" "0"
            "0" "VIEWPORT" "5" "51" "8" "0"
            "10" "5.0" "20" "5.0" "30" "0.0" "40" "10.0" "41" "8.0"
            "68" "1" "69" "2" "45" "8.0"
            "50" "10.0" "51" "20.0" "72" "100"
            "0" "ENDSEC"
            "0" "EOF")))

(defun %all-values (code data)
  (loop for pair in data when (eql (car pair) code) collect (cdr pair)))

(test dxf-read-converts-hatch-and-viewport-angles
  "HATCH 52 (pattern angle), every 53 (pattern line angle) and the 50/51
of each arc / elliptic-arc boundary edge, VIEWPORT 50/51: degrees in the
file, radians in entget. Lengths (40 radius, 41 scale, 45/46 offsets,
49 dashes) are not touched."
  (let* ((d (with-input-from-string (s +hatch-viewport-angle-dxf+)
              (dxf-read-drawing-from-stream s)))
         (by-type (%entities-by-type d))
         (hatch (cdr (assoc "HATCH" by-type :test #'equal)))
         (viewport (cdr (assoc "VIEWPORT" by-type :test #'equal))))
    (is (%angle-close-p (/ pi 6) (cdr (assoc 52 hatch)))
        "HATCH 52 = 30 deg must read as pi/6, got ~S" (cdr (assoc 52 hatch)))
    (let ((l53 (%all-values 53 hatch)))
      (is (= 2 (length l53)))
      (is (%angle-close-p (* 5/12 pi) (first l53)) "first 53: ~S" (first l53))
      (is (%angle-close-p (* 11/12 pi) (second l53)) "second 53: ~S" (second l53)))
    (let ((l50 (%all-values 50 hatch))
          (l51 (%all-values 51 hatch)))
      (is (= 2 (length l50)))
      (is (%angle-close-p 0d0 (first l50)))
      (is (%angle-close-p (/ pi 2) (first l51))
          "arc edge end 90 deg must read as pi/2, got ~S" (first l51))
      (is (%angle-close-p (/ pi 2) (second l50))
          "elliptic edge start 90 deg must read as pi/2, got ~S" (second l50))
      (is (%angle-close-p pi (second l51))))
    (is (equal '(10.0d0 0.5d0) (mapcar (lambda (x) (coerce x 'double-float))
                                       (%all-values 40 hatch))))
    (is (%angle-close-p 1d0 (cdr (assoc 41 hatch))))
    (is (equal '(1.0d0 -0.5d0) (mapcar (lambda (x) (coerce x 'double-float))
                                        (%all-values 49 hatch))))
    (is (%angle-close-p (/ pi 18) (cdr (assoc 50 viewport))))
    (is (%angle-close-p (/ pi 9) (cdr (assoc 51 viewport)))
        "VIEWPORT 51 = 20 deg must read as pi/9, got ~S" (cdr (assoc 51 viewport)))))

(test dxf-read-converts-table-record-angles
  "tblsearch shows table records as stored: VPORT 50/51, VIEW 50 and
STYLE 50 must be radians there, as on the vendors."
  (let* ((d (with-input-from-string (s +hatch-viewport-angle-dxf+)
              (dxf-read-drawing-from-stream s)))
         (vport (symbol-table-record-data (find-table-record d :vport "*ACTIVE")))
         (view (symbol-table-record-data (find-table-record d :view "V1")))
         (style (symbol-table-record-data (find-table-record d :style "SLANT"))))
    (is (%angle-close-p (/ pi 12) (cdr (assoc 50 vport)))
        "VPORT 50 = 15 deg must read as pi/12, got ~S" (cdr (assoc 50 vport)))
    (is (%angle-close-p (/ pi 6) (cdr (assoc 51 vport))))
    (is (%angle-close-p (/ pi 4) (cdr (assoc 50 view))))
    (is (%angle-close-p (/ pi 12) (cdr (assoc 50 style))))
    (is (%angle-close-p 2.5d0 (cdr (assoc 42 style))))))

(defun %cador-like-hatch ()
  "A HATCH as cador's HATCH command builds it: every angle in radians."
  (list (cons 0 "HATCH") (cons 8 "0") (list 10 0d0 0d0 0d0)
        (cons 2 "ANSI31") (cons 70 0) (cons 71 0) (cons 91 1)
        (cons 92 1) (cons 93 1) (cons 72 2) (list 10 0d0 0d0 0d0) (cons 40 10d0)
        (cons 50 0d0) (cons 51 (/ pi 2)) (cons 73 1)
        (cons 97 0) (cons 75 0) (cons 76 1)
        (cons 52 (/ pi 6)) (cons 41 1d0) (cons 77 0) (cons 78 1)
        (cons 53 (* 5/12 pi)) (cons 43 0d0) (cons 44 0d0) (cons 45 -2.2d0)
        (cons 46 2.2d0) (cons 79 0) (cons 98 0)))

(test dxf-write-emits-hatch-and-viewport-degrees
  "HATCH and VIEWPORT angles in entget units are written in degrees."
  (let ((d (make-drawing :version :ac1027)))
    (add-entity d (%cador-like-hatch))
    (add-entity d (list (cons 0 "VIEWPORT") (cons 8 "0") (list 10 5d0 5d0 0d0)
                        (cons 40 10d0) (cons 41 8d0) (cons 68 1) (cons 69 2)
                        (cons 50 0d0) (cons 51 (/ pi 9))))
    (let ((text (with-output-to-string (s) (dxf-write-drawing-to-stream d s)))
          (hatch (format nil "~%HATCH~%"))
          (viewport (format nil "~%VIEWPORT~%")))
      (is (%angle-close-p 90d0 (%dxf-value-after text "51" hatch))
          "HATCH arc edge 51 in the file must be 90: ~S" (%dxf-value-after text "51" hatch))
      (is (%angle-close-p 30d0 (%dxf-value-after text "52" hatch))
          "HATCH 52 in the file must be 30: ~S" (%dxf-value-after text "52" hatch))
      (is (%angle-close-p 75d0 (%dxf-value-after text "53" hatch)))
      (is (%angle-close-p 10d0 (%dxf-value-after text "40" hatch)))
      (is (%angle-close-p 20d0 (%dxf-value-after text "51" viewport))
          "VIEWPORT 51 in the file must be 20: ~S" (%dxf-value-after text "51" viewport)))))

(test dxf-hatch-viewport-table-angle-round-trip
  "Write then read: HATCH, VIEWPORT and table-record angles come back."
  (let ((d (with-input-from-string (s +hatch-viewport-angle-dxf+)
             (dxf-read-drawing-from-stream s))))
    (add-entity d (%cador-like-hatch))
    (let* ((text (with-output-to-string (s) (dxf-write-drawing-to-stream d s)))
           (restored (with-input-from-string (s text) (dxf-read-drawing-from-stream s)))
           (hatches (loop for (type . data) in (%entities-by-type restored)
                          when (equal type "HATCH") collect data))
           (viewport (cdr (assoc "VIEWPORT" (%entities-by-type restored) :test #'equal)))
           (vport (symbol-table-record-data
                   (find-table-record restored :vport "*ACTIVE"))))
      (is (= 2 (length hatches)))
      (is (%angle-close-p (/ pi 6) (cdr (assoc 52 (first hatches)))))
      (is (%angle-close-p (* 11/12 pi) (second (%all-values 53 (first hatches)))))
      (is (%angle-close-p pi (second (%all-values 51 (first hatches)))))
      (is (%angle-close-p (/ pi 2) (cdr (assoc 51 (second hatches)))))
      (is (%angle-close-p (* 5/12 pi) (cdr (assoc 53 (second hatches)))))
      (is (%angle-close-p (/ pi 9) (cdr (assoc 51 viewport))))
      (is (%angle-close-p (/ pi 6) (cdr (assoc 51 vport))))
      ;; The source drawing is not mutated by the writer.
      (is (%angle-close-p (/ pi 6)
                          (cdr (assoc 51 (symbol-table-record-data
                                          (find-table-record d :vport "*ACTIVE")))))))))

;;; --- Vendor-written DXF fixtures (dxf-angles probe) ------------------
;;; scripts/run-dxf-angles-probe.{sh,ps1} make AutoCAD / BricsCAD write a
;;; DXF holding entities with known angles, all on layer DXFANG, plus the
;;; VPORT *Active (SNAPANG 20), STYLE DXFANG (oblique 10) and VIEW DXFANG
;;; (twist 45) records; the report beside it holds entget's values. Once
;;; such a pair is copied into fixtures/vendor-dxf/ (see the README.org
;;; there), this test checks that the codec turns what the VENDOR wrote
;;; into what the VENDOR's entget says. With no fixture it checks nothing.

(defparameter +vendor-dxf-claimed-degree-groups+
  '(("ARC" 50 51) ("TEXT" 50 51) ("ATTRIB" 50 51) ("ATTDEF" 50 51)
    ("SHAPE" 50 51) ("MTEXT" 50) ("INSERT" 50) ("DIMENSION" 50 51 52 53)
    ("VERTEX" 50) ("VIEWPORT" 50 51) ("HATCH" 50 51 52 53)
    ("VPORT" 50 51) ("VIEW" 50) ("STYLE" 50))
  "The claim under test, written out independently of the codec's tables:
type -> the groups a DXF file stores in degrees and entget reports in
radians. HATCH: every occurrence (pattern angle, pattern lines, arc and
elliptic-arc edges); the others: the first occurrence.")

(defun %vendor-dxf-fixture-directory ()
  (asdf:system-relative-pathname "clautolisp" "drawing/tests/fixtures/vendor-dxf/"))

(defun %vendor-dxf-raw-objects (path)
  "The objects of the ASCII DXF at PATH as a list of (TYPE . PAIRS), PAIRS
the (CODE . TEXT) groups after the 0 group, in file order. Read as
ISO-8859-1 so no byte can stop the scan."
  (let ((objects '()) (current nil))
    (with-open-file (s path :external-format :iso-8859-1)
      (loop for code-line = (read-line s nil nil)
            for value-line = (and code-line (read-line s nil ""))
            while code-line
            do (let ((code (parse-integer (string-trim '(#\Space #\Tab #\Return) code-line)
                                          :junk-allowed t))
                     (value (string-trim '(#\Space #\Tab #\Return) value-line)))
                 (cond
                   ((null code))
                   ((= code 0)
                    (when current (push (cons (car current) (nreverse (cdr current))) objects))
                    (setf current (list value)))
                   (current (push (cons code value) (cdr current)))))))
    (when current (push (cons (car current) (nreverse (cdr current))) objects))
    (nreverse objects)))

(defun %claimed-occurrences (type pairs)
  "The (CODE . VALUE) pairs of PAIRS the claim covers for TYPE, in order:
every one for HATCH (up to 101 / 1001), the first of each code for the
others (up to 75 / 76 / 101 / 1001)."
  (let* ((entry (assoc type +vendor-dxf-claimed-degree-groups+ :test #'string-equal))
         (repeated (string-equal type "HATCH"))
         (pending (copy-list (rest entry)))
         (stops (cond (repeated '(101 1001))
                      ((string-equal type "MTEXT") '(75 76 101 1001))
                      (t '(101 1001))))
         (acc '()))
    (dolist (pair pairs (nreverse acc))
      (when (and (consp pair) (member (car pair) stops)) (return (nreverse acc)))
      (when (and (consp pair) (member (car pair) pending))
        (unless repeated (setf pending (remove (car pair) pending)))
        (push pair acc)))))

(defun %raw-handle (pairs)
  (cdr (or (assoc 5 pairs) (assoc 105 pairs))))

(defun %vendor-probe-objects (raw-objects)
  "The probe's objects among RAW-OBJECTS: entities (ENTITIES or BLOCKS
section) on layer DXFANG of a claimed type, and the VPORT *Active, STYLE
DXFANG and VIEW DXFANG records of the TABLES section, as (TYPE HANDLE
NAME PAIRS)."
  (let ((section nil))
    (loop for (type . pairs) in raw-objects
          for name = (cdr (assoc 2 pairs))
          for table-record-p = (member type '("VPORT" "VIEW" "STYLE") :test #'string-equal)
          do (when (string-equal type "SECTION") (setf section name))
          when (and (assoc type +vendor-dxf-claimed-degree-groups+ :test #'string-equal)
                    (%raw-handle pairs)
                    (if table-record-p
                        (and (equalp section "TABLES")
                             (equalp name (if (string-equal type "VPORT") "*ACTIVE" "DXFANG")))
                        (and (member section '("ENTITIES" "BLOCKS") :test #'equalp)
                             (equalp (cdr (assoc 8 pairs)) "DXFANG"))))
            collect (list type (%raw-handle pairs) name pairs))))

(defun %split-words (string)
  (let ((words '()) (start nil))
    (loop for i from 0 to (length string)
          for c = (if (< i (length string)) (char string i) #\Space)
          do (if (char= c #\Space)
                 (when start (push (subseq string start i) words) (setf start nil))
                 (unless start (setf start i))))
    (nreverse words)))

(defun %vendor-report-entget (report-path)
  "From the probe report at REPORT-PATH: an alist HANDLE -> the (CODE .
REAL) ENTGET values of codes 50-53, in report order."
  (let ((case->handle '()) (case->values '()))
    (when (probe-file report-path)
      (with-open-file (s report-path :external-format :iso-8859-1)
        (loop for line = (read-line s nil nil)
              while line
              do (let ((words (%split-words (string-trim '(#\Return #\Space) line))))
                   (cond
                     ((and (>= (length words) 5) (equal (first words) "DXFANG")
                           (equal (second words) "HANDLE"))
                      (push (cons (third words) (fifth words)) case->handle))
                     ((and (= (length words) 5) (equal (first words) "DXFANG")
                           (equal (second words) "ENTGET"))
                      (let ((code (parse-integer (fourth words) :junk-allowed t))
                            (value (let ((*read-default-float-format* 'double-float))
                                     (ignore-errors (read-from-string (fifth words))))))
                        (when (and code (<= 50 code 53) (realp value))
                          (let ((cell (assoc (third words) case->values :test #'equal)))
                            (if cell
                                (push (cons code value) (cdr cell))
                                (push (list (third words) (cons code value)) case->values)))))))))))
    (loop for (case . handle) in case->handle
          for values = (cdr (assoc case case->values :test #'equal))
          collect (cons (string-upcase handle) (reverse values)))))

(defun %loaded-object-data (drawing type handle name)
  (cond
    ((string-equal type "VPORT")
     (let ((r (find-table-record drawing :vport name))) (and r (symbol-table-record-data r))))
    ((string-equal type "VIEW")
     (let ((r (find-table-record drawing :view name))) (and r (symbol-table-record-data r))))
    ((string-equal type "STYLE")
     (let ((r (find-table-record drawing :style name))) (and r (symbol-table-record-data r))))
    (t (let ((e (find-entity drawing handle))) (and e (entity-dxf e))))))

(defun %fixture-real (text)
  (let ((*read-default-float-format* 'double-float))
    (let ((v (ignore-errors (read-from-string text))))
      (and (realp v) v))))

(test dxf-vendor-fixtures-angle-units
  "Every vendor-written DXF under fixtures/vendor-dxf/: each probe object's
claimed angle groups load as (file degrees) * pi/180, and -- when the
probe report <name>.txt sits beside <name>.dxf -- as the vendor's entget
reported them."
  (let ((files (directory (merge-pathnames "*.dxf" (%vendor-dxf-fixture-directory)))))
    (is (listp files))
    (dolist (path files)
      (let* ((drawing (dxf-read-drawing path))
             (report (%vendor-report-entget (make-pathname :type "txt" :defaults path)))
             (objects (%vendor-probe-objects (%vendor-dxf-raw-objects path))))
        (is (not (null objects)) "~A: no probe object (layer DXFANG) found" (file-namestring path))
        (dolist (object objects)
          (destructuring-bind (type handle name pairs) object
            (let* ((loaded (%loaded-object-data drawing type handle name))
                   (raw (%claimed-occurrences type pairs))
                   (got-all (%claimed-occurrences type loaded))
                   ;; An MTEXT the file gives no 50 gets one DERIVED from its
                   ;; 11 direction on load (the vendors' entget lists it):
                   ;; not a file group -- the entget check below covers it.
                   (got (if (and (string-equal type "MTEXT") (not (assoc 50 raw)))
                            (remove 50 got-all :key #'car)
                            got-all)))
              (is (not (null loaded)) "~A: ~A ~A not loaded" (file-namestring path) type handle)
              (is (equal (mapcar #'car raw) (mapcar #'car got))
                  "~A: ~A ~A file groups ~S, loaded groups ~S"
                  (file-namestring path) type handle (mapcar #'car raw) (mapcar #'car got))
              (loop for (code . text) in raw
                    for (nil . value) in got
                    for degrees = (%fixture-real text)
                    do (is (and degrees
                                (%angle-close-p value (* degrees (/ pi 180d0))))
                           "~A: ~A ~A group ~D: file ~A deg, loaded ~S (want ~S)"
                           (file-namestring path) type handle code text value
                           (and degrees (* degrees (/ pi 180d0)))))
              ;; Against the vendor's own entget, code by code (first
              ;; occurrence; every occurrence, in order, for HATCH). A code
              ;; entget lists with value 0 that the file omits is a default
              ;; the CAD does not write (DIMENSION 51 / 52) -- loaded absent
              ;; is right. The VPORT *Active record is not compared: AutoCAD's
              ;; entget of it still showed 0 after SETVAR SNAPANG, while the
              ;; file it wrote holds the new angle (measured, job 17409369691).
              (let ((entget (cdr (assoc (string-upcase handle) report :test #'equal))))
                (when (and entget (not (string-equal type "VPORT")))
                  (let ((mine (remove-if-not (lambda (pair) (<= 50 (car pair) 53)) got-all))
                        (entget (%claimed-occurrences type entget)))
                    (if (string-equal type "HATCH")
                        (loop for (code . vendor) in entget
                              for (nil . value) in mine
                              do (is (and value (%angle-close-p value vendor))
                                     "~A: ~A ~A group ~D: vendor entget ~S, loaded ~S"
                                     (file-namestring path) type handle code vendor value))
                        (loop for (code . vendor) in entget
                              for value = (cdr (assoc code mine))
                              do (is (if value
                                         (%angle-close-p value vendor)
                                         (zerop vendor))
                                     "~A: ~A ~A group ~D: vendor entget ~S, loaded ~S"
                                     (file-namestring path) type handle code vendor value)))))))))))))

(test dxf-round-trip-keeps-handle-addressed-objects
  "deferred-nod-default-contents, item 4: the handle-addressed dictionaries
and xrecords are written to OBJECTS (the root first), not ENTITIES, and read
back as handle-addressed objects: the root is the drawing's NOD again, its
entry reaches the xrecord, and none of them counts as an entity."
  (let* ((d (build-sample-drawing))
         (root (ensure-root-dictionary d))
         (x (add-entity d '((0 . "XRECORD") (100 . "AcDbXrecord") (280 . 1) (1 . "kept"))))
         (text (progn
                 (dictionary-add-entry d (entity-handle-id root) "MYKEY" (entity-handle-id x))
                 (with-output-to-string (s) (dxf-write-drawing-to-stream d s))))
         (entities (subseq text (search "ENTITIES" text) (search "ENDSEC" text :start2 (search "ENTITIES" text))))
         (back (with-input-from-string (s text) (dxf-read-drawing-from-stream s))))
    (is (null (search "DICTIONARY" entities)) "no object in ENTITIES")
    (is (null (search "XRECORD" entities)))
    (is (equal (entity-handle-id root) (drawing-root-dictionary-handle back)))
    (let ((member (dictionary-member-handle back (drawing-root-dictionary-handle back) "MYKEY")))
      (is (equal (entity-handle-id x) member))
      (is (equal "kept" (cdr (assoc 1 (entity-handle-data (find-entity back member)))))))
    (is (= (drawing-entity-count d) (drawing-entity-count back)))
    (is (not (graphical-entity-p (find-entity back (drawing-root-dictionary-handle back)))))))
