(in-package #:clautolisp.cador.tests)

(in-suite cador-suite)

;;;; DXF pointer group codes per product dialect -- the behaviour MEASURED
;;;; on 2026-10-08 by probes/sources/probe-entget-pointers.lsp (jobs
;;;; 17026569911 AutoCAD 2022, 17026569912 BricsCAD V25 Windows,
;;;; 17026569913 BricsCAD V26 macOS).
;;;; issues/closed/cador-entget-pointer-codes-are-handle-strings.issue

(defun %pd-error-text (thunk)
  "The message of the AutoLISP runtime error THUNK signals, or :NO-ERROR."
  (handler-case (progn (funcall thunk) :no-error)
    (autolisp-runtime-error (e) (princ-to-string e))))

(defun %pd-mentions (text needle)
  (and (stringp text) (search needle text) t))

(defun %pd-xrecord (mock &rest groups)
  (host-entmakex mock (list* (cons 0 "XRECORD") (cons 100 "AcDbXrecord") groups)))

(defun %pd-line (mock)
  (host-entmakex mock (list (cons 0 "LINE") (cons 8 "0")
                            (cons 10 '(0.0d0 0.0d0 0.0d0))
                            (cons 11 '(1.0d0 1.0d0 0.0d0)))))

(defun %pd-stderr (thunk)
  "Everything THUNK writes to *ERROR-OUTPUT*."
  (with-output-to-string (*error-output*)
    (funcall thunk)))

;;; --- AutoCAD ------------------------------------------------------

(test autocad-dialect-pointer-codes-follow-autocad
  (%with-dialect (:autocad)
    (let* ((mock (make-cador))
           (line (%pd-line mock))
           (h (autolisp-ename-value line)))
      ;; A handle STRING in a pointer code: "bad DXF group".
      (is (%pd-mentions (%pd-error-text
                         (lambda () (%pd-xrecord mock (cons 340 (mk-str h)))))
                        "bad DXF group: (340 . \""))
      ;; An ENAME in 320-329: refused too.
      (is (%pd-mentions (%pd-error-text
                         (lambda () (%pd-xrecord mock (cons 320 line))))
                        "bad DXF group: (320 . <Entity name: "))
      ;; 320 as a string is fine and reads back a string; 340 an ename.
      (let* ((x (%pd-xrecord mock (cons 340 line) (cons 320 (mk-str h))))
             (view (host-entget mock x)))
        (is (eq line (cdr (assoc 340 view))))
        (is (typep (cdr (assoc 320 view)) 'autolisp-string))
        ;; entmod with a string pointer: refused.
        (is (%pd-mentions (%pd-error-text
                           (lambda ()
                             (host-entmod mock (subst (cons 340 (mk-str h))
                                                      (assoc 340 view) view
                                                      :test #'equal))))
                          "bad DXF group")))
      ;; The null pointer: (330 . <Entity name: 0>), entget nil.
      (let ((owner (assoc 330 (host-entget mock (host-namedobjdict mock)))))
        (is (consp owner))
        (is (typep (cdr owner) 'autolisp-ename))
        (is (string= "0" (autolisp-ename-value (cdr owner))))
        (is (null (host-entget mock (cdr owner)))))
      ;; XRECORD without the AcDbXrecord marker: refused (nil).
      (is (null (host-entmakex mock (list (cons 0 "XRECORD") (cons 1 "C")))))
      ;; XRECORD with an explicit (280 . 0): kept as given.
      (let ((view (host-entget mock (%pd-xrecord mock (cons 280 0) (cons 1 "a")))))
        (is (equal '(280 . 0) (second (member 100 view :key #'car))))))))

;;; --- BricsCAD -----------------------------------------------------

(test bricscad-dialect-pointer-codes-follow-bricscad
  (%with-dialect (:bricscad)
    (let* ((mock (make-cador))
           (line (%pd-line mock))
           (h (autolisp-ename-value line)))
      ;; A handle STRING in a pointer code, and in 320: expected ENTITYNAME.
      (is (%pd-mentions (%pd-error-text
                         (lambda () (%pd-xrecord mock (cons 340 (mk-str h)))))
                        "expected ENTITYNAME"))
      (is (%pd-mentions (%pd-error-text
                         (lambda () (%pd-xrecord mock (cons 320 (mk-str h)))))
                        "bad argument type <(320 . \""))
      ;; 320 as an ENAME reads back an ENAME (EQ).
      (let ((view (host-entget mock (%pd-xrecord mock (cons 320 line)))))
        (is (eq line (cdr (assoc 320 view)))))
      ;; The null pointer is omitted.
      (is (null (assoc 330 (host-entget mock (host-namedobjdict mock)))))
      ;; XRECORD without the marker: accepted, marker + (280 . 1) synthesised.
      (let ((x (host-entmakex mock (list (cons 0 "XRECORD") (cons 1 "C")))))
        (is (typep x 'autolisp-ename))
        (let ((tail (member 100 (host-entget mock x) :key #'car)))
          (is (string= "AcDbXrecord" (autolisp-string-value (cdr (first tail)))))
          (is (equal '(280 . 1) (second tail)))))
      ;; XRECORD with an explicit (280 . 0): no 280 listed at all.
      (let ((view (host-entget mock (%pd-xrecord mock (cons 280 0) (cons 1 "a")))))
        (is (null (assoc 280 view)))
        (is (eql 1 (car (second (member 100 view :key #'car))))))
      ;; ...and without it, (280 . 1).
      (let ((view (host-entget mock (%pd-xrecord mock (cons 1 "a")))))
        (is (equal '(280 . 1) (second (member 100 view :key #'car))))))))

;;; --- clautolisp / lax: accept, warn (or not) ----------------------

(test clautolisp-dialect-accepts-a-string-pointer-with-a-warning
  (%with-dialect (:clautolisp)
    (let* ((mock (make-cador))
           (line (%pd-line mock))
           (x nil)
           (err (%pd-stderr (lambda ()
                              (setf x (%pd-xrecord mock (cons 340 (mk-str (autolisp-ename-value line)))))))))
      (is (%pd-mentions err "[entmake-pointer-value]"))
      (is (eq line (cdr (assoc 340 (host-entget mock x))))))))

(test lax-dialect-accepts-a-string-pointer-silently
  (%with-dialect (:lax)
    (let* ((mock (make-cador))
           (line (%pd-line mock))
           (x nil)
           (err (%pd-stderr (lambda ()
                              (setf x (%pd-xrecord mock (cons 340 (mk-str (autolisp-ename-value line)))))))))
      (is (string= "" err))
      (is (eq line (cdr (assoc 340 (host-entget mock x))))))))

(test erased-pointer-target-is-the-same-ename-on-both-products
  (dolist (dialect '(:autocad :bricscad))
    (%with-dialect (dialect)
      (let* ((mock (make-cador))
             (gone (%pd-line mock))
             (x (%pd-xrecord mock (cons 340 gone))))
        (host-entdel mock gone)
        (let ((p (cdr (assoc 340 (host-entget mock x)))))
          (is (eq gone p))
          (is (null (host-entget mock p))))))))

;;; --- where the owner 330 stands in the entget header ---------------

(test entget-header-owner-position-follows-the-product
  "AutoCAD 2022 lists the owner BEFORE the handle (-1 0 330 5 ...), BricsCAD
after it (-1 0 5 330 ...); a dictionary member is -1 0 5 102 330 102 330 on
both (entget-pointers section 10: AutoCAD job 17398575906, BricsCAD V26 job
17397066992; cador-entget-owner-and-header-layout)."
  (%with-dialect (:autocad)
    (let* ((mock (make-cador))
           (line (host-entmakex mock (make-line-data))))
      (is (equal '(-1 0 330 5) (mapcar #'car (subseq (host-entget mock line) 0 4))))))
  (%with-dialect (:bricscad-v25)
    (let* ((mock (make-cador))
           (line (host-entmakex mock (make-line-data)))
           (nod (host-namedobjdict mock))
           (x (make-xrecord-ename mock "z")))
      (is (equal '(-1 0 5 330) (mapcar #'car (subseq (host-entget mock line) 0 4))))
      (host-dictadd mock nod (mk-str "HDRB") x)
      (is (equal '(-1 0 5 102 330 102 330 100)
                 (mapcar #'car (subseq (host-entget mock x) 0 8)))))))

;;; --- the entget body after the header --------------------------------

(test entget-body-layout-follows-the-vendors
  "cador-entget-subclass-layout-and-record-pointers, items 1 and 2: after
the header, (100 . AcDbEntity), the common groups (67 410 8), the type's
marker, its groups and 210 -- the same on AutoCAD 2022 (job 17436788251) and
BricsCAD V26 (job 17397066992). A round trip through entmod stores nothing
twice."
  (dolist (dialect '(:autocad-2022 :bricscad))
    (%with-dialect (dialect)
      (let* ((mock (make-cador))
             (line (host-entmakex mock (make-line-data)))
             (codes (mapcar #'car (nthcdr 4 (host-entget mock line)))))
        (is (equal '(100 67 410 8 100 10 11 210) codes)
            "~A LINE body: ~S" dialect codes)
        (host-entmod mock (host-entget mock line))
        (is (equal codes (mapcar #'car (nthcdr 4 (host-entget mock line))))
            "~A LINE body after entmod" dialect)
        (let ((model (cdr (assoc 410 (host-entget mock line)))))
          (is (equal "Model" (autolisp-string-value model))))))))


(defun %rt-type (mock ename)
  (let ((v (cdr (assoc 0 (host-entget mock ename)))))
    (and v (autolisp-string-value v))))

(test entget-table-records-blocks-and-nod-follow-the-vendors
  "cador-entget-subclass-layout-and-record-pointers, items 3 to 5, as
measured by entget-pointers section 11 (AutoCAD 2022 job 17439813490,
BricsCAD V26 job 17439813492): a table record has a handle HANDENT reaches,
its TABLE owner, the layer's plot style and material pointers; tblobjname
BLOCK is the BLOCK entity, owned by the BLOCK_RECORD a LINE names; a fresh
NOD holds the product's default entries, which entnext does not walk."
  (dolist (dialect '(:autocad-2022 :bricscad))
    (%with-dialect (dialect)
      (let* ((mock (make-cador))
             (bricscad (eq dialect :bricscad))
             (line (%pd-line mock))
             (layer (host-tblobjname mock "LAYER" "0"))
             (view (host-entget mock layer)))
        ;; item 3: the record
        (is (equal (if bricscad
                       '(-1 0 5 330 100 100 2 70 62 6 290 370 390 347)
                       '(-1 0 5 102 360 102 330 100 100 2 70 62 6 290 370 390 347 348))
                   (mapcar #'car view))
            "~A layer record: ~S" dialect (mapcar #'car view))
        (is (eq layer (host-handent mock (cdr (assoc 5 view)))) "~A handent" dialect)
        (let ((table (host-entget mock (cdr (assoc 330 view)))))
          (is (equal "TABLE" (autolisp-string-value (cdr (assoc 0 table)))))
          (is (equal "LAYER" (autolisp-string-value (cdr (assoc 2 table)))))
          (is (equal (if bricscad '(-1 0 2 5 100 70) '(-1 0 2 5 102 360 102 330 100 70))
                     (mapcar #'car table))
              "~A TABLE: ~S" dialect (mapcar #'car table)))
        (is (equal "ACDBPLACEHOLDER" (%rt-type mock (cdr (assoc 390 view)))))
        (let ((material (host-entget mock (cdr (assoc 347 view)))))
          (is (equal "MATERIAL" (autolisp-string-value (cdr (assoc 0 material)))))
          (is (equal "Global" (autolisp-string-value (cdr (assoc 1 material))))))
        ;; item 4: the BLOCK entity and its BLOCK_RECORD
        (let* ((ms (host-tblobjname mock "BLOCK" "*Model_Space"))
               (record (cdr (assoc 330 (host-entget mock ms)))))
          (is (equal "BLOCK" (%rt-type mock ms)))
          (is (equal "BLOCK_RECORD" (%rt-type mock record)))
          (is (eq record (cdr (assoc 330 (host-entget mock line)))) "~A LINE's owner" dialect))
        (let ((block (host-entmakex mock (list (cons 0 "BLOCK") (cons 2 "RT1") (cons 70 0)
                                               (list 10 0.0d0 0.0d0 0.0d0)))))
          (host-entmakex mock (make-line-data))
          (host-entmakex mock (list (cons 0 "ENDBLK")))
          (is (eq block (host-tblobjname mock "BLOCK" "RT1")))
          (is (equal (if bricscad
                         '(-1 0 5 330 100 67 8 100 2 70 71 10 3 1 -2)
                         '(-1 0 330 5 100 67 8 100 70 10 -2 2 1))
                     (mapcar #'car (host-entget mock block)))
              "~A BLOCK: ~S" dialect (mapcar #'car (host-entget mock block)))
          (is (equal "LINE" (%rt-type mock (host-entnext mock block))))
          (is (eq block (host-handent mock (autolisp-string-value
                                            (cdr (assoc 5 (host-entget mock block))))))))
        ;; item 5: the named-object dictionary
        (let ((keys (loop for (code . value) in (host-entget mock (host-namedobjdict mock))
                          when (eql code 3) collect (autolisp-string-value value))))
          ;; the entries of the product's template (probe:template-defaults:
          ;; AutoCAD 15, BricsCAD 15 or 16 by template)
          (is (equal (mapcar #'first (clautolisp.cador::%measured-set
                                      (clautolisp.cador::%default-objects-key mock)
                                      clautolisp.cador::*measured-default-objects*))
                     keys)
              "~A NOD: ~S" dialect keys)
          (dolist (key '("ACAD_GROUP" "ACAD_LAYOUT" "ACAD_MATERIAL" "ACAD_PLOTSTYLENAME"))
            (is (member key keys :test #'string=)))
          (is (eq (not bricscad) (and (member "ACAD_COLOR" keys :test #'string=) t)))
          (is (eq bricscad (and (member "ACAD_IMAGE_DICT" keys :test #'string=) t))))
        ;; the walk sees the LINE only, no dictionary
        (is (eq line (host-entnext mock nil)))
        (is (null (host-entnext mock line)))))))


(defun %dc-member (mock dict key)
  (host-dictsearch mock (if (consp dict) (cdr (assoc -1 dict)) dict)
                   (make-autolisp-string key)))

(test default-objects-hold-the-measured-contents
  "deferred-nod-default-contents: a fresh drawing's dictionaries hold what
the entget-pointers probe (section 12; AutoCAD 2022 job 17440097863, BricsCAD
V26 job 17440097865) dumped, with their pointers resolved; AutoCAD's layer 0
and LAYER TABLE carry their extension dictionaries, BricsCAD's none."
  (dolist (dialect '(:autocad-2022 :bricscad))
    (%with-dialect (dialect)
      (let* ((mock (make-cador))
             (bricscad (eq dialect :bricscad))
             (nod (host-namedobjdict mock))
             (layouts (%dc-member mock nod "ACAD_LAYOUT"))
             (model (%dc-member mock layouts "Model"))
             (scales (%dc-member mock nod "ACAD_SCALELIST"))
             (mleader (%dc-member mock (%dc-member mock nod "ACAD_MLEADERSTYLE") "Standard")))
        ;; layouts, English-named, each pointing at its block record
        (is (equal "LAYOUT" (autolisp-string-value (cdr (assoc 0 model)))))
        (is (not (null (%dc-member mock layouts "Layout1"))) "~A Layout1" dialect)
        (is (find (%model-space-record mock) model
                  :key (lambda (p) (and (eql 330 (car p)) (cdr p))))
            "~A Model's block record" dialect)
        ;; the scale list: A0 is 1:1
        (let ((a0 (%dc-member mock scales "A0")))
          (is (equal "1:1" (autolisp-string-value (cdr (assoc 300 a0))))))
        ;; the mleader style's text style is the STYLE record Standard
        (is (eq (host-tblobjname mock "STYLE" "Standard") (cdr (assoc 342 mleader))))
        ;; the variables
        (let ((v (%dc-member mock (%dc-member mock nod "AcDbVariableDictionary") "CANNOSCALE")))
          (is (equal "1:1" (autolisp-string-value (cdr (assoc 1 v))))))
        ;; extension dictionaries: AutoCAD's only
        (let ((layer (host-entget mock (host-tblobjname mock "LAYER" "0"))))
          (if bricscad
              (is (null (assoc 360 layer)))
              (let* ((table (host-entget mock (cdr (assoc 330 layer))))
                     (xdict (cdr (assoc 360 table))))
                (is (not (null (assoc 360 layer))))
                (is (not (null (%dc-member mock xdict "ACAD_LAYERSTATES"))))
                (is (eql 1 (cdr (assoc 280 (host-entget mock xdict))))))))
        ;; none of it is walked or selected
        (is (null (host-entnext mock nil)))))))


(test default-objects-member-xdicts-and-block-records
  "deferred-nod-default-contents, items 1 and 2 (entget-pointers section 12,
round 2: AutoCAD 2022 job 17441114651, BricsCAD V26 job 17441114653): the
objects inside the NOD carry their own extension dictionaries (AutoCAD's
materials hold FBXASSET), and a BLOCK_RECORD lists its BLOCK (360), a
space's LAYOUT (340) and the INSERTs referencing it ({BLKREFS 331})."
  (dolist (dialect '(:autocad-2022 :bricscad))
    (%with-dialect (dialect)
      (let* ((mock (make-cador))
             (bricscad (eq dialect :bricscad))
             (nod (host-namedobjdict mock))
             (global (%dc-member mock (%dc-member mock nod "ACAD_MATERIAL") "Global"))
             (xdict (cdr (assoc 360 global))))
        (if bricscad
            (is (null xdict))
            (is (not (null (%dc-member mock xdict "FBXASSET")))))
        ;; model space's record: its BLOCK and its Model layout
        (let* ((ms (host-tblobjname mock "BLOCK" "*Model_Space"))
               (record (host-entget mock (cdr (assoc 330 (host-entget mock ms)))))
               (pointers (remove 360 record :key #'car :test-not #'eql)))
          (is (member ms pointers :key #'cdr) "~A record's 360 is its BLOCK" dialect)
          (is (equal "Model" (autolisp-string-value
                              (cdr (assoc 410 (host-entget mock ms))))))
          (is (equal "LAYOUT" (autolisp-string-value
                               (cdr (assoc 0 (host-entget mock (cdr (assoc 340 record)))))))))
        ;; a block with an INSERT
        (host-entmakex mock (list (cons 0 "BLOCK") (cons 2 "BR1") (cons 70 0)
                                  (list 10 0.0d0 0.0d0 0.0d0)))
        (host-entmakex mock (make-line-data))
        (host-entmakex mock (list (cons 0 "ENDBLK")))
        (let* ((insert (host-entmakex mock (list (cons 0 "INSERT") (cons 8 "0") (cons 2 "BR1")
                                                 (list 10 0.0d0 0.0d0 0.0d0))))
               (record (host-entget mock (cdr (assoc 330 (host-entget
                                                          mock (host-tblobjname mock "BLOCK" "BR1")))))))
          (is (equal '(2 360 102 331 102 70 280 281) (mapcar #'car (nthcdr 6 record)))
              "~A BR1 record: ~S" dialect (mapcar #'car record))
          (is (eq insert (cdr (assoc 331 record)))))))))

(test layer-348-follows-autocad-under-autocad-and-lax
  "Layer 0's 348: AutoCAD lists it, pointing at an erased object (entget nil;
entget-pointers section 12, job 17441114651); BricsCAD lists none. The
AutoCAD and lax dialects follow AutoCAD, the others BricsCAD (pjb,
2026-10-24). Making the erased target leaves DBMOD alone."
  (dolist (case '((:autocad-2022 t) (:lax t) (:clautolisp nil) (:bricscad nil)))
    (destructuring-bind (dialect listed) case
      (%with-dialect (dialect)
        (let* ((mock (make-cador))
               (view (host-entget mock (host-tblobjname mock "LAYER" "0")))
               (pointer (cdr (assoc 348 view))))
          (is (eq listed (and pointer t)) "~A 348" dialect)
          (when pointer
            (is (null (host-entget mock pointer)) "~A 348 is erased" dialect))
          (is (eql 0 (clautolisp.drawing:drawing-dbmod
                      (clautolisp.cador::cador-active-drawing mock)))))))))

(test empty-block-walk-starts-at-its-endblk
  "An empty block's -2 names its ENDBLK (entget-pointers section 13; AutoCAD
2022 job 17448966017, BricsCAD V26 job 17448966216): -1 0 [330 5 | 5 330]
100 67 410 8 100, owned by the BLOCK_RECORD; handent reaches it. A walk of a
block's entities does not end on it."
  (dolist (dialect '(:autocad-2022 :bricscad))
    (%with-dialect (dialect)
      (let* ((mock (make-cador))
             (ps (host-tblobjname mock "BLOCK" "*Paper_Space"))
             (endblk (cdr (assoc -2 (host-entget mock ps))))
             (view (host-entget mock endblk)))
        (is (equal "ENDBLK" (autolisp-string-value (cdr (assoc 0 view)))))
        (is (equal (if (eq dialect :bricscad)
                       '(-1 0 5 330 100 67 410 8 100)
                       '(-1 0 330 5 100 67 410 8 100))
                   (mapcar #'car view))
            "~A ENDBLK: ~S" dialect (mapcar #'car view))
        (is (eq (cdr (assoc 330 (host-entget mock ps))) (cdr (assoc 330 view))))
        (is (eq endblk (host-handent mock (autolisp-string-value (cdr (assoc 5 view))))))
        (is (eq endblk (cdr (assoc -2 (host-tblsearch mock "BLOCK" "*Paper_Space")))))
        ;; a block with contents: -2 is its first entity, the walk ends on nil
        (host-entmakex mock (list (cons 0 "BLOCK") (cons 2 "EB1") (cons 70 0)
                                  (list 10 0.0d0 0.0d0 0.0d0)))
        (host-entmakex mock (make-line-data))
        (host-entmakex mock (list (cons 0 "ENDBLK")))
        (let ((first (cdr (assoc -2 (host-entget mock (host-tblobjname mock "BLOCK" "EB1"))))))
          (is (equal "LINE" (autolisp-string-value (cdr (assoc 0 (host-entget mock first))))))
          (is (null (host-entnext mock first))))))))

(defun %marker-layout (mock ename)
  "The entget codes of ENAME after its header, a marker as its name."
  (mapcar (lambda (p) (if (eql 100 (car p)) (autolisp-string-value (cdr p)) (car p)))
          (member 100 (host-entget mock ename) :key #'car)))

(test entget-lists-each-subclass-marker-once-where-the-vendors-do
  "entmake-duplicates-subclass-markers: whether the ENTMAKE data carried its
markers or BricsCAD-style synthesis added them, the entget view lists each
marker once, AcDbEntity before the common groups and each class marker
before its own groups (%VENDOR-BODY-ORDER, 2.3.51)."
  (%with-dialect (:bricscad)
    (let* ((mock (make-cador))
           (*error-output* (make-broadcast-stream))   ; the D1 warning
           (bare (host-entmakex mock (list (cons 0 "LWPOLYLINE") (cons 8 "0") (cons 90 2)
                                           (cons 70 0) (list 10 0.0d0 0.0d0)
                                           (list 10 1.0d0 1.0d0))))
           (given (host-entmakex mock (list (cons 0 "LWPOLYLINE") (cons 100 "AcDbEntity")
                                            (cons 8 "0") (cons 100 "AcDbPolyline") (cons 90 2)
                                            (cons 70 0) (list 10 0.0d0 0.0d0)
                                            (list 10 1.0d0 1.0d0))))
           (arc (host-entmakex mock (list (cons 0 "ARC") (cons 8 "0")
                                          (list 10 0.0d0 0.0d0 0.0d0) (cons 40 1.0d0)
                                          (cons 50 0.0d0) (cons 51 1.0d0)))))
      (dolist (e (list bare given))
        (let ((layout (%marker-layout mock e)))
          (is (equal '("AcDbEntity" 67 410 8 "AcDbPolyline" 90 70) (subseq layout 0 7))
              "LWPOLYLINE: ~S" layout)
          (is (= 2 (count-if #'stringp layout)) "each marker once: ~S" layout)))
      (is (equal '("AcDbEntity" 67 410 8 "AcDbCircle" 10 40 "AcDbArc" 50 51)
                 (%marker-layout mock arc))
          "ARC: ~S" (%marker-layout mock arc))
      ;; a VERTEX: its two markers (AcDbVertex has no group of its own) first
      (host-entmake mock (list (cons 0 "POLYLINE") (cons 8 "0") (cons 66 1) (cons 70 0)))
      (host-entmake mock (list (cons 0 "VERTEX") (cons 8 "0") (list 10 1.0d0 2.0d0 0.0d0)))
      (let* ((poly (host-entlast mock))
             (vertex (host-entnext mock poly))
             (layout (%marker-layout mock vertex)))
        (host-entmake mock (list (cons 0 "SEQEND")))
        (is (equal '("AcDbEntity" 67 410 8 "AcDbVertex" "AcDb2dVertex" 10)
                   (subseq layout 0 7))
            "VERTEX: ~S" layout)))))

(test entlast-and-entnext-skip-non-graphical-objects
  "entnext-nongraphical-enumeration: after an XRECORD or a DICTIONARY is made
(and dictadded), (entlast) still names the last graphical entity, and the
entnext walk does not reach the objects -- both CADs (entget-pointers
sections 11 and 14)."
  (dolist (dialect '(:autocad-2022 :bricscad))
    (%with-dialect (dialect)
      (let* ((mock (make-cador))
             (line (%pd-line mock))
             (x (%pd-xrecord mock (cons 1 "last")))
             (d (host-entmakex mock (list (cons 0 "DICTIONARY") (cons 100 "AcDbDictionary")))))
        (is (eq line (host-entlast mock)) "~A after XRECORD + DICTIONARY" dialect)
        (host-dictadd mock (host-namedobjdict mock) (make-autolisp-string "LASTX") x)
        (is (eq line (host-entlast mock)) "~A after dictadd" dialect)
        (is (null (host-entnext mock line)))
        (is (not (null d)))))))

(test default-objects-follow-the-dialect-version
  "The measured default objects are keyed (PRODUCT UNITS VERSION), as the
dialects distinguish versions (pjb, 2026-10-25): a measured version gets its
own set, another the nearest measured one (a versionless dialect the newest),
and an unmeasured units the product's other units."
  (let ((table clautolisp.cador::*measured-default-objects*))
    (flet ((set-of (key) (clautolisp.cador::%measured-set key table))
           (row (key) (cdr (assoc key table :test #'equal))))
      (is (eq (row '(:bricscad :imperial 25)) (set-of '(:bricscad :imperial 25))))
      (is (eq (row '(:bricscad :imperial 26)) (set-of '(:bricscad :imperial 26))))
      (is (eq (row '(:bricscad :imperial 26)) (set-of '(:bricscad :imperial nil))))
      (is (eq (row '(:bricscad :imperial 25)) (set-of '(:bricscad :imperial 23))))
      (is (eq (row '(:autocad :metric 2022)) (set-of '(:autocad :metric 2018))))
      (is (eq (row '(:autocad :imperial 2022)) (set-of '(:autocad :imperial 2026))))
      ;; V25's metric template, measured 2026-10-25 (job 17451032321): its
      ;; own set, not V26's (its Model layout has an ISO A4 page setup)
      (is (eq (row '(:bricscad :metric 25)) (set-of '(:bricscad :metric 25))))
      (is (not (eq (row '(:bricscad :metric 26)) (set-of '(:bricscad :metric 25)))))
      (is (eq (row '(:bricscad :metric 25)) (set-of '(:bricscad :metric 23)))))))
