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

;;; --- Dispatch integration (probe + read/write via the registry) --

(test dxf-registered-on-the-format-dispatch
  (is (eq :dxf-ascii (probe-drawing-format "/tmp/plan.dxf")))
  (is (not (null (find-drawing-codec :dxf-ascii)))))
