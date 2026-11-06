(in-package #:clautolisp.cador.tests)

(in-suite cador-suite)

;;;; What ENTGET shows of an entity made with its REQUIRED codes only, as
;;;; measured by the probe entity-defaults (2026-10-27: AutoCAD 2022 job
;;;; 17511443216, BricsCAD V25 Windows 17511443220): entity-mutation-parity.
;;;; Each row: the ENTMAKEX data, then the codes after the header (a marker
;;;; as its name) under AutoCAD and under BricsCAD.

(defun %ed-make (mock data)
  (host-entmakex mock (mapcar (lambda (p) (if (stringp (cdr p)) (cons (car p) (mk-str (cdr p))) p))
                              data)))

(defparameter *entity-defaults-measured*
  '((((0 . "POINT") (100 . "AcDbEntity") (100 . "AcDbPoint") (10 2.0d0 2.0d0 0.0d0))
     ("AcDbEntity" 67 410 8 "AcDbPoint" 10 210 50)
     ("AcDbEntity" 67 410 8 "AcDbPoint" 10 210 50))
    (((0 . "ELLIPSE") (100 . "AcDbEntity") (100 . "AcDbEllipse") (10 0.0d0 0.0d0 0.0d0)
      (11 2.0d0 0.0d0 0.0d0) (40 . 0.5d0) (41 . 0.0d0) (42 . 6.283185307179586d0))
     ("AcDbEntity" 67 410 8 "AcDbEllipse" 10 11 210 40 41 42)
     ("AcDbEntity" 67 410 8 "AcDbEllipse" 10 11 210 40 41 42))
    (((0 . "SOLID") (100 . "AcDbEntity") (100 . "AcDbTrace") (10 0.0d0 0.0d0 0.0d0)
      (11 1.0d0 0.0d0 0.0d0) (12 0.0d0 1.0d0 0.0d0) (13 1.0d0 1.0d0 0.0d0))
     ("AcDbEntity" 67 410 8 "AcDbTrace" 10 11 12 13 39 210)
     ("AcDbEntity" 67 410 8 "AcDbTrace" 10 11 12 13 210))
    (((0 . "3DFACE") (100 . "AcDbEntity") (100 . "AcDbFace") (10 0.0d0 0.0d0 0.0d0)
      (11 1.0d0 0.0d0 0.0d0) (12 1.0d0 1.0d0 0.0d0) (13 0.0d0 1.0d0 0.0d0))
     ("AcDbEntity" 67 410 8 "AcDbFace" 10 11 12 13 70)
     ("AcDbEntity" 67 410 8 "AcDbFace" 10 11 12 13 70))
    (((0 . "LWPOLYLINE") (100 . "AcDbEntity") (100 . "AcDbPolyline") (90 . 2) (70 . 0)
      (10 0.0d0 0.0d0) (10 1.0d0 0.0d0))
     ("AcDbEntity" 67 410 8 "AcDbPolyline" 90 70 43 38 39 10 40 41 42 91 10 40 41 42 91 210)
     ("AcDbEntity" 67 410 8 "AcDbPolyline" 90 70 43 38 39 10 40 41 42 91 10 40 41 42 91 210))
    (((0 . "SPLINE") (100 . "AcDbEntity") (100 . "AcDbSpline") (70 . 8) (71 . 2) (72 . 6) (73 . 3)
      (40 . 0.0d0) (40 . 0.0d0) (40 . 0.0d0) (40 . 1.0d0) (40 . 1.0d0) (40 . 1.0d0)
      (10 0.0d0 0.0d0 0.0d0) (10 1.0d0 1.0d0 0.0d0) (10 2.0d0 0.0d0 0.0d0))
     ("AcDbEntity" 67 410 8 "AcDbSpline" 210 70 71 72 73 74 42 43 40 40 40 40 40 40 10 10 10)
     ("AcDbEntity" 67 410 8 "AcDbSpline" 210 70 71 72 73 74 42 43 40 40 40 40 40 40 10 10 10))
    (((0 . "ATTDEF") (100 . "AcDbEntity") (100 . "AcDbText") (10 0.0d0 0.0d0 0.0d0) (40 . 0.2d0)
      (1 . "v") (100 . "AcDbAttributeDefinition") (3 . "Prompt") (2 . "TAG") (70 . 0))
     ("AcDbEntity" 67 410 8 "AcDbText" 10 40 1 50 41 51 7 71 72 11 210
      "AcDbAttributeDefinition" 280 3 2 70 73 74 280)
     ("AcDbEntity" 67 410 8 "AcDbText" 10 40 1 50 41 51 7 71 72 11 210
      "AcDbAttributeDefinition" 3 2 70 73 74 280))))

(test entget-shows-each-familys-measured-defaults
  (loop for (data autocad bricscad) in *entity-defaults-measured*
        do (loop for (dialect expected) in (list (list :autocad-2022 autocad)
                                                 (list :bricscad-v25 bricscad))
                 do (%with-dialect (dialect)
                      (let* ((mock (make-cador))
                             (e (%ed-make mock data)))
                        (is (equal expected (%marker-layout mock e))
                            "~A ~A: ~S" dialect (cdr (first data)) (%marker-layout mock e)))))))

(test entget-defaults-values-per-product
  (flet ((value (dialect data code)
           (%with-dialect (dialect)
             (let ((mock (make-cador)))
               (cdr (assoc code (host-entget mock (%ed-make mock data))))))))
    (let ((spline '((0 . "SPLINE") (100 . "AcDbEntity") (100 . "AcDbSpline") (70 . 8) (71 . 2)
                    (72 . 6) (73 . 3) (40 . 0.0d0) (40 . 0.0d0) (40 . 0.0d0) (40 . 1.0d0)
                    (40 . 1.0d0) (40 . 1.0d0) (10 0.0d0 0.0d0 0.0d0) (10 1.0d0 1.0d0 0.0d0)
                    (10 2.0d0 0.0d0 0.0d0)))
          (mtext '((0 . "MTEXT") (100 . "AcDbEntity") (100 . "AcDbMText") (10 1.0d0 1.0d0 0.0d0)
                   (40 . 0.2d0) (1 . "hi"))))
      (is (= 1.0d-9 (value :autocad-2022 spline 42)))
      (is (= 1.0d-7 (value :bricscad-v25 spline 42)))
      (is (eql 5 (value :autocad-2022 mtext 72)))
      (is (eql 1 (value :bricscad-v25 mtext 72)))
      (is (eql 0 (value :bricscad-v25 mtext 75)))
      (is (null (value :autocad-2022 mtext 75))))))

(test seqend-names-its-header-and-a-2d-vertex-has-no-face-indices
  (dolist (dialect '(:autocad-2022 :bricscad-v25))
    (%with-dialect (dialect)
      (let ((mock (make-cador)))
        (host-entmake mock (list (cons 0 (mk-str "POLYLINE")) (cons 100 (mk-str "AcDbEntity"))
                                 (cons 100 (mk-str "AcDb2dPolyline")) (cons 66 1)
                                 (list 10 0.0d0 0.0d0 0.0d0) (cons 70 0)))
        (host-entmake mock (list (cons 0 (mk-str "VERTEX")) (cons 100 (mk-str "AcDbEntity"))
                                 (cons 100 (mk-str "AcDbVertex")) (cons 100 (mk-str "AcDb2dVertex"))
                                 (list 10 1.0d0 2.0d0 0.0d0)))
        (host-entmake mock (list (cons 0 (mk-str "SEQEND"))))
        (let* ((header (host-entlast mock))
               (vertex (host-entnext mock header))
               (seqend (host-entnext mock vertex))
               (vertex-codes (%marker-layout mock vertex)))
          (is (equal (if (eq dialect :autocad-2022)
                         '("AcDbEntity" 67 410 8 "AcDbVertex" "AcDb2dVertex" 10 40 41 42 91 70 50)
                         '("AcDbEntity" 67 410 8 "AcDbVertex" "AcDb2dVertex" 10 40 41 42 70 50))
                     vertex-codes)
              "~A VERTEX: ~S" dialect vertex-codes)
          (is (eq header (cdr (assoc -2 (host-entget mock seqend)))) "~A SEQEND -2" dialect))))))
