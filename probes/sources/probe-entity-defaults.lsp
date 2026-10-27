;;;; probes/sources/probe-entity-defaults.lsp
;;;;
;;;; entity-mutation-parity, the vendor tail: what a CAD fills in when
;;;; ENTMAKEX is given only a family's REQUIRED codes (the per-family
;;;; optional-code defaulting clautolisp holds until measured -- INSERT
;;;; 41/42/43, TEXT 72/73, ELLIPSE / SPLINE counts ...). For each of the 21
;;;; families of clautolisp/drawing/source/entity-families.lisp: ENTMAKEX
;;;; the minimal data (with the subclass markers AutoCAD requires), then
;;;; record the ENTGET as CODE=VALUE, without the per-run -1 / 5 / 330
;;;; (an ename prints as <ename>); "rejected" when ENTMAKEX gives nil.
;;;; Every step runs under VL-CATCH-ALL-APPLY. Parameter names are unique:
;;;; AutoLISP binds dynamically.

(defun cad-probe--ed-value (cad-probe--ed-v)
  (if (= (type cad-probe--ed-v) 'ENAME) "<ename>" (vl-prin1-to-string cad-probe--ed-v)))

(defun cad-probe--ed-dump (cad-probe--ed-list / out)
  (setq out "")
  (foreach p cad-probe--ed-list
    (if (not (member (car p) '(-1 5 330)))
      (setq out (strcat out (if (= out "") "" " ")
                        (itoa (car p)) "="
                        (cad-probe--ed-value (cdr p))))))
  out)

(defun cad-probe--ed-make (cad-probe--ed-data / e)
  (setq e (entmakex cad-probe--ed-data))
  (cond ((= (type e) 'ENAME) (cad-probe--ed-dump (entget e)))
        (t "rejected")))

(defun cad-probe--ed (cad-probe--ed-name cad-probe--ed-data2)
  (cad-probe-capture "entity-defaults" (strcat "defaults: " cad-probe--ed-name)
    (function (lambda () (cad-probe--ed-make cad-probe--ed-data2)))))

(defun cad-probe--ed-entity (cad-probe--ed-type cad-probe--ed-markers cad-probe--ed-rest)
  ;; (0 . TYPE) (100 . "AcDbEntity") (100 . marker) ... REST
  (append (list (cons 0 cad-probe--ed-type) (cons 100 "AcDbEntity"))
          (mapcar (function (lambda (m) (cons 100 m))) cad-probe--ed-markers)
          cad-probe--ed-rest))

(defun cad-probe-run-entity-defaults-probes ( / blk)
  (cad-probe--ed "LINE"
    (cad-probe--ed-entity "LINE" '("AcDbLine") '((10 0.0 0.0 0.0) (11 1.0 1.0 0.0))))
  (cad-probe--ed "POINT"
    (cad-probe--ed-entity "POINT" '("AcDbPoint") '((10 2.0 2.0 0.0))))
  (cad-probe--ed "CIRCLE"
    (cad-probe--ed-entity "CIRCLE" '("AcDbCircle") '((10 4.0 3.0 0.0) (40 . 1.0))))
  (cad-probe--ed "ARC"
    (cad-probe--ed-entity "ARC" '("AcDbCircle" "AcDbArc")
                          '((10 4.0 3.0 0.0) (40 . 2.0) (50 . 0.0) (51 . 1.5))))
  (cad-probe--ed "ELLIPSE"
    (cad-probe--ed-entity "ELLIPSE" '("AcDbEllipse")
                          '((10 0.0 0.0 0.0) (11 2.0 0.0 0.0) (40 . 0.5) (41 . 0.0) (42 . 6.283185307179586))))
  (cad-probe--ed "RAY"
    (cad-probe--ed-entity "RAY" '("AcDbRay") '((10 0.0 0.0 0.0) (11 1.0 0.0 0.0))))
  (cad-probe--ed "XLINE"
    (cad-probe--ed-entity "XLINE" '("AcDbXline") '((10 0.0 0.0 0.0) (11 0.0 1.0 0.0))))
  (cad-probe--ed "LWPOLYLINE"
    (cad-probe--ed-entity "LWPOLYLINE" '("AcDbPolyline")
                          '((90 . 2) (70 . 0) (10 0.0 0.0) (10 1.0 0.0))))
  (cad-probe--ed "SPLINE"
    (cad-probe--ed-entity "SPLINE" '("AcDbSpline")
                          '((70 . 8) (71 . 2) (72 . 6) (73 . 3)
                            (40 . 0.0) (40 . 0.0) (40 . 0.0) (40 . 1.0) (40 . 1.0) (40 . 1.0)
                            (10 0.0 0.0 0.0) (10 1.0 1.0 0.0) (10 2.0 0.0 0.0))))
  (cad-probe--ed "TEXT"
    (cad-probe--ed-entity "TEXT" '("AcDbText") '((10 1.0 1.0 0.0) (40 . 0.2) (1 . "hi"))))
  (cad-probe--ed "MTEXT"
    (cad-probe--ed-entity "MTEXT" '("AcDbMText") '((10 1.0 1.0 0.0) (40 . 0.2) (1 . "hi"))))
  (cad-probe--ed "ATTDEF"
    (cad-probe--ed-entity "ATTDEF" '("AcDbText" "AcDbAttributeDefinition")
                          '((10 0.0 0.0 0.0) (40 . 0.2) (1 . "v") (3 . "Prompt") (2 . "TAG") (70 . 0))))
  (cad-probe--ed "3DFACE"
    (cad-probe--ed-entity "3DFACE" '("AcDbFace")
                          '((10 0.0 0.0 0.0) (11 1.0 0.0 0.0) (12 1.0 1.0 0.0) (13 0.0 1.0 0.0))))
  (cad-probe--ed "SOLID"
    (cad-probe--ed-entity "SOLID" '("AcDbTrace")
                          '((10 0.0 0.0 0.0) (11 1.0 0.0 0.0) (12 0.0 1.0 0.0) (13 1.0 1.0 0.0))))
  (cad-probe--ed "TRACE"
    (cad-probe--ed-entity "TRACE" '("AcDbTrace")
                          '((10 0.0 0.0 0.0) (11 1.0 0.0 0.0) (12 0.0 1.0 0.0) (13 1.0 1.0 0.0))))
  (cad-probe--ed "XRECORD"
    '((0 . "XRECORD") (100 . "AcDbXrecord") (1 . "x")))
  ;; POLYLINE: header, one VERTEX, SEQEND -- the dumps of each
  (cad-probe-capture "entity-defaults" "defaults: POLYLINE run"
    (function (lambda ( / h v s)
      (setq h (entmake (cad-probe--ed-entity "POLYLINE" '("AcDb2dPolyline")
                                              '((66 . 1) (10 0.0 0.0 0.0) (70 . 0)))))
      (setq v (entmake (cad-probe--ed-entity "VERTEX" '("AcDbVertex" "AcDb2dVertex")
                                              '((10 1.0 2.0 0.0)))))
      (setq s (entmake (list (cons 0 "SEQEND"))))
      (if (and h v s)
          (strcat "POLYLINE " (cad-probe--ed-dump (entget (entlast)))
                  " | entmake: " (vl-prin1-to-string (list (not (null h)) (not (null v)) (not (null s)))))
          (vl-prin1-to-string (list 'polyline h 'vertex v 'seqend s))))))
  (cad-probe-capture "entity-defaults" "defaults: POLYLINE header"
    (function (lambda ( / e)
      (setq e (entlast))
      (cad-probe--ed-dump (entget e)))))
  (cad-probe-capture "entity-defaults" "defaults: VERTEX"
    (function (lambda ( / e)
      (setq e (entnext (entlast)))
      (if e (cad-probe--ed-dump (entget e)) "none"))))
  ;; INSERT of a one-LINE block, then an INSERT with an ATTRIB run
  (setq blk "CLAL_ED_BLK")
  (vl-catch-all-apply 'entmake
    (list (list (cons 0 "BLOCK") (cons 2 blk) (cons 70 2) (cons 10 (list 0.0 0.0 0.0)))))
  (vl-catch-all-apply 'entmake
    (list (list (cons 0 "ATTDEF") (cons 100 "AcDbEntity") (cons 100 "AcDbText")
                (cons 10 (list 0.0 0.0 0.0)) (cons 40 0.2) (cons 1 "d")
                (cons 100 "AcDbAttributeDefinition") (cons 3 "P") (cons 2 "TAG") (cons 70 0))))
  (vl-catch-all-apply 'entmake (list (list (cons 0 "ENDBLK"))))
  (cad-probe--ed "INSERT"
    (cad-probe--ed-entity "INSERT" '("AcDbBlockReference")
                          (list (cons 2 blk) (list 10 5.0 5.0 0.0))))
  (cad-probe-capture "entity-defaults" "defaults: INSERT with ATTRIB run"
    (function (lambda ( / i a s)
      (setq i (entmake (cad-probe--ed-entity "INSERT" '("AcDbBlockReference")
                                              (list (cons 66 1) (cons 2 blk) (list 10 6.0 6.0 0.0)))))
      (setq a (entmake (cad-probe--ed-entity "ATTRIB" '("AcDbText" "AcDbAttribute")
                                              '((10 6.0 6.0 0.0) (40 . 0.2) (1 . "v") (2 . "TAG") (70 . 0)))))
      (setq s (entmake (list (cons 0 "SEQEND"))))
      (vl-prin1-to-string (list (not (null i)) (not (null a)) (not (null s)))))))
  (cad-probe-capture "entity-defaults" "defaults: ATTRIB"
    (function (lambda ( / e)
      (setq e (entnext (entlast)))
      (if e (cad-probe--ed-dump (entget e)) "none"))))
  (cad-probe-capture "entity-defaults" "defaults: SEQEND"
    (function (lambda ( / e a)
      (setq e (entlast) a (entnext e))
      (if a (setq a (entnext a)))
      (if a (cad-probe--ed-dump (entget a)) "none"))))
  (princ))
