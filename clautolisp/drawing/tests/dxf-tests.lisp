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
  (let* ((original (build-sample-drawing))
         (e1 (entity-handle-string (find-entity original "10")))
         (text (with-output-to-string (s)
                 (dxf-write-drawing-to-stream original s)))
         (restored (with-input-from-string (s text)
                     (dxf-read-drawing-from-stream s))))
    (is (string= "10" e1))
    (is (not (null (find-entity restored "10"))))     ; first entity
    (is (not (null (find-entity restored "11"))))))    ; second entity

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
