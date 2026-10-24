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
                       '(-1 0 330 5 100 100 2 70 62 6 290 370 390 347))
                   (mapcar #'car view))
            "~A layer record: ~S" dialect (mapcar #'car view))
        (is (eq layer (host-handent mock (cdr (assoc 5 view)))) "~A handent" dialect)
        (let ((table (host-entget mock (cdr (assoc 330 view)))))
          (is (equal "TABLE" (autolisp-string-value (cdr (assoc 0 table)))))
          (is (equal "LAYER" (autolisp-string-value (cdr (assoc 2 table)))))
          (is (equal (if bricscad '(-1 0 2 5 100 70) '(-1 0 2 5 330 100 70))
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
                         '(-1 0 5 330 100 67 8 100 2 70 10 3 1 -2)
                         '(-1 0 330 5 100 67 8 100 70 10 -2 2 1))
                     (mapcar #'car (host-entget mock block)))
              "~A BLOCK: ~S" dialect (mapcar #'car (host-entget mock block)))
          (is (equal "LINE" (%rt-type mock (host-entnext mock block))))
          (is (eq block (host-handent mock (autolisp-string-value
                                            (cdr (assoc 5 (host-entget mock block))))))))
        ;; item 5: the named-object dictionary
        (let ((keys (loop for (code . value) in (host-entget mock (host-namedobjdict mock))
                          when (eql code 3) collect (autolisp-string-value value))))
          (is (= (if bricscad 16 15) (length keys)) "~A NOD: ~S" dialect keys)
          (dolist (key '("ACAD_GROUP" "ACAD_LAYOUT" "ACAD_MATERIAL" "ACAD_PLOTSTYLENAME"))
            (is (member key keys :test #'string=)))
          (is (eq (not bricscad) (and (member "ACAD_COLOR" keys :test #'string=) t)))
          (is (eq bricscad (and (member "ACAD_IMAGE_DICT" keys :test #'string=) t))))
        ;; the walk sees the LINE only, no dictionary
        (is (eq line (host-entnext mock nil)))
        (is (null (host-entnext mock line)))))))
