(in-package #:clautolisp.drawing.tests)

(in-suite drawing-suite)

;;; --- Construction & handle normalisation -------------------------

(test make-drawing-defaults
  (let ((d (make-drawing)))
    (is (drawing-p d))
    (is (string= "Drawing.dwg" (drawing-name d)))
    (is (null (drawing-path d)))
    (is (= 16 (drawing-handle-seed d)))
    (is (zerop (hash-table-count (drawing-entities d))))
    (is (null (drawing-creation-order d)))
    (is (dictionary-p (drawing-named-object-dictionary d)))))

(test handle-normalisation
  (is (= 255 (handle->integer 255)))
  (is (= 255 (handle->integer "FF")))
  (is (= 255 (handle->integer "ff")))          ; case-insensitive
  (is (= 255 (handle->integer "00FF")))         ; leading zeros
  (is (string= "FF" (handle->string 255)))
  (is (string= "FF" (handle->string "ff")))     ; canonicalised
  (is (string= "10" (handle->string 16)))
  (signals drawing-error (handle->integer "xyz")))

(test allocate-handle-returns-integer-and-bumps
  (let ((d (make-drawing)))
    (is (= 16 (allocate-handle d)))
    (is (= 17 (allocate-handle d)))
    (is (= 18 (drawing-handle-seed d)))))

;;; --- add-entity --------------------------------------------------

(test add-entity-allocates-and-stores-pure-form
  (let* ((d (make-drawing))
         (e (add-entity d '((0 . "LINE") (8 . "0") (10 1.0 2.0 0.0)))))
    (is (entity-handle-p e))
    (is (eq :line (entity-kind e)))
    (is (string= "10" (entity-handle-string e)))   ; seed 16 -> "10"
    (is (= 16 (entity-handle-integer e)))
    ;; (5 . "10") injected, no (-1 …) stored (pure form, REVIEW-1).
    (is (equal '(5 . "10") (assoc 5 (entity-dxf e))))
    (is (null (assoc -1 (entity-dxf e))))
    (is (equal '(8 . "0") (assoc 8 (entity-dxf e))))
    (is (= 1 (drawing-entity-count d)))
    (is (eq e (find-entity d 16)))
    (is (eq e (find-entity d "10")))))

(test add-entity-explicit-handle-keeps-seed-ahead
  (let* ((d (make-drawing))
         (e (add-entity d '((0 . "CIRCLE")) :handle 255)))
    (is (string= "FF" (entity-handle-string e)))
    (is (eq e (find-entity d "ff")))               ; case-insensitive lookup
    (is (= 256 (drawing-handle-seed d))))          ; seed bumped past 255
  )

(test add-entity-strips-caller-bookkeeping-codes
  (let* ((d (make-drawing))
         (e (add-entity d '((0 . "TEXT") (-1 . :bogus) (5 . "999") (1 . "hi")))))
    (is (null (assoc -1 (entity-dxf e))))
    (is (string= "10" (cdr (assoc 5 (entity-dxf e)))))   ; host-owned, not "999"
    (is (equal '(1 . "hi") (assoc 1 (entity-dxf e))))))

(test add-entity-requires-group-0-marker
  (let ((d (make-drawing)))
    (signals drawing-error (add-entity d '((8 . "0"))))))

;;; --- find / map / count ------------------------------------------

(test map-entities-walks-in-creation-order
  (let ((d (make-drawing)))
    (add-entity d '((0 . "A")))
    (add-entity d '((0 . "B")))
    (add-entity d '((0 . "C")))
    (let ((kinds '()))
      (map-entities (lambda (e) (push (entity-kind e) kinds)) d)
      (is (equal '(:a :b :c) (nreverse kinds))))
    (is (= 3 (drawing-entity-count d)))))

(test do-entities-supports-early-return
  (let ((d (make-drawing)))
    (add-entity d '((0 . "A")))
    (add-entity d '((0 . "B")))
    (is (eq :a (do-entities (e d) (return (entity-kind e)))))))

;;; --- modify-entity -----------------------------------------------

(test modify-entity-preserves-handle
  (let* ((d (make-drawing))
         (e (add-entity d '((0 . "LINE") (8 . "0")))))
    (is (eq e (modify-entity d 16 '((0 . "LINE") (8 . "WALLS") (5 . "999")))))
    (is (string= "10" (cdr (assoc 5 (entity-dxf e)))))   ; handle preserved
    (is (equal '(8 . "WALLS") (assoc 8 (entity-dxf e))))
    (is (null (modify-entity d 9999 '((0 . "LINE")))))))  ; absent -> nil

;;; --- deleted status: reader / setter / setf / togglef ------------

(test entity-deleted-status-reader-and-setter
  (let ((d (make-drawing)))
    (add-entity d '((0 . "LINE")))
    (is (null (entity-deleted-status d 16)))
    (is (eq t (set-entity-deleted-status d 16 t)))
    (is (eq t (entity-deleted-status d 16)))
    ;; find-entity hides deleted unless :include-deleted
    (is (null (find-entity d 16)))
    (is (entity-handle-p (find-entity d 16 :include-deleted t)))
    ;; setf place
    (setf (entity-deleted-status d 16) nil)
    (is (null (entity-deleted-status d 16)))
    ;; togglef
    (togglef (entity-deleted-status d 16))
    (is (eq t (entity-deleted-status d 16)))
    (togglef (entity-deleted-status d 16))
    (is (null (entity-deleted-status d 16)))))

(test deleted-status-signals-on-absent
  (let ((d (make-drawing)))
    (signals drawing-error (entity-deleted-status d 9999))
    (signals drawing-error (set-entity-deleted-status d 9999 t))))

;;; --- symbol tables -----------------------------------------------

(test table-records
  (let ((d (make-drawing)))
    (add-table-record d (make-symbol-table-record
                         :kind :layer :name "WALLS"
                         :data '((0 . "LAYER") (2 . "WALLS") (62 . 1))))
    (is (string= "WALLS" (symbol-table-record-name (find-table-record d :layer "WALLS"))))
    (is (string= "WALLS" (symbol-table-record-name (find-table-record d :layer "walls")))) ; case-insensitive
    (is (equal '(62 . 1) (assoc 62 (table-record-dxf (find-table-record d :layer "WALLS")))))
    (let ((names '()))
      (map-table-records (lambda (r) (push (symbol-table-record-name r) names)) d :layer)
      (is (equal '("WALLS") names)))
    (is (eq t (remove-table-record d :layer "WALLS")))
    (is (null (find-table-record d :layer "WALLS")))))

;;; --- dictionaries ------------------------------------------------

(test dictionary-put-get-remove
  (let* ((d (make-drawing))
         (nod (drawing-dictionary d)))
    (is (dictionary-p nod))
    (dictionary-put nod "ACAD_GROUP" "2F")
    (is (string= "2F" (dictionary-get nod "ACAD_GROUP")))
    (is (null (dictionary-get nod "MISSING")))
    (let ((pairs '()))
      (map-dictionary (lambda (k v) (push (cons k v) pairs)) nod)
      (is (equal '(("ACAD_GROUP" . "2F")) pairs)))
    (is (eq t (dictionary-remove nod "ACAD_GROUP")))
    (is (null (dictionary-get nod "ACAD_GROUP")))))

;;; --- header variables --------------------------------------------

(test header-variables-ensure-get-set
  (let ((d (make-drawing)))
    (is (null (drawing-variable d "CLAYER")))
    (is (null (set-drawing-variable d "CLAYER" "0")))   ; unknown -> nil, no create
    (let ((cell (ensure-drawing-variable d "CLAYER" :kind :string :value "0")))
      (is (sysvar-cell-p cell))
      (is (string= "0" (drawing-variable d "CLAYER")))
      (is (string= "WALLS" (set-drawing-variable d "CLAYER" "WALLS")))
      (is (string= "WALLS" (drawing-variable d "clayer"))))  ; case-insensitive
    ;; read-only honoured unless :force
    (ensure-drawing-variable d "HANDSEED" :kind :string :value "10" :read-only-p t)
    (signals drawing-error (set-drawing-variable d "HANDSEED" "20"))
    (is (string= "20" (set-drawing-variable d "HANDSEED" "20" :force t)))
    (let ((names '()))
      (map-variables (lambda (c) (push (sysvar-cell-name c) names)) d)
      (is (= 2 (length names))))))

;;; --- copy-drawing deep independence ------------------------------

(test copy-drawing-is-independent
  (let* ((d (make-drawing :name "orig.dwg")))
    (add-entity d '((0 . "LINE") (8 . "0")))
    (ensure-drawing-variable d "CLAYER" :value "0")
    (let ((c (copy-drawing d)))
      (is (string= "orig.dwg" (drawing-name c)))
      (is (= 1 (drawing-entity-count c)))
      ;; mutate the original; the copy is unaffected
      (modify-entity d 16 '((0 . "LINE") (8 . "CHANGED")))
      (set-drawing-variable d "CLAYER" "CHANGED")
      (is (equal '(8 . "0") (assoc 8 (entity-dxf (find-entity c 16)))))
      (is (string= "0" (drawing-variable c "CLAYER"))))))

;;; --- condition slots ---------------------------------------------

(test drawing-error-carries-context
  (let ((d (make-drawing)))
    (handler-case (entity-deleted-status d 9999)
      (drawing-error (e)
        (is (eq d (drawing-error-drawing e)))
        (is (eql 9999 (drawing-error-handle e)))))))
