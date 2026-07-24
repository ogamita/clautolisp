(in-package #:clautolisp.drawing.tests)

(in-suite drawing-suite)

;;;; VALIDATE-ENTITY-DXF (the ENTMAKE/ENTMAKEX family registry) and the
;;;; xdata-aware MODIFY-ENTITY (schms-parity, entity-mutation-parity).

;;; --- Registry ---------------------------------------------------

(test entity-family-registry-covers-the-core-families
  (dolist (name '("LINE" "POINT" "CIRCLE" "ARC" "ELLIPSE" "LWPOLYLINE"
                  "POLYLINE" "VERTEX" "SEQEND" "SPLINE" "TEXT" "MTEXT"
                  "ATTDEF" "ATTRIB" "INSERT" "3DFACE" "SOLID" "TRACE"
                  "RAY" "XLINE" "XRECORD"))
    (is (not (null (find-entity-family name)))
        "family ~A should be registered" name))
  ;; Case-insensitive lookup.
  (is (eq (find-entity-family "line") (find-entity-family "LINE")))
  ;; An unknown type has no descriptor.
  (is (null (find-entity-family "NO-SUCH-ENTITY"))))

(test entity-family-flags
  (is (entity-family-complex-p (find-entity-family "POLYLINE")))
  (is (entity-family-complex-p (find-entity-family "INSERT")))
  (is (entity-family-subentity-p (find-entity-family "VERTEX")))
  (is (entity-family-subentity-p (find-entity-family "ATTRIB")))
  (is (entity-family-subentity-p (find-entity-family "SEQEND")))
  (is (not (entity-family-graphical-p (find-entity-family "XRECORD"))))
  (is (entity-family-graphical-p (find-entity-family "LINE"))))

;;; --- Validation -------------------------------------------------

(test validate-rejects-missing-type-marker
  (multiple-value-bind (data reason) (validate-entity-dxf '((8 . "0")))
    (is (null data))
    (is (stringp reason))))

(test validate-rejects-missing-required-code
  ;; CIRCLE needs 40 (radius).
  (is (null (validate-entity-dxf '((0 . "CIRCLE") (10 0.0d0 0.0d0 0.0d0)))))
  ;; ARC needs the two angles.
  (is (null (validate-entity-dxf '((0 . "ARC") (10 0.0d0 0.0d0 0.0d0) (40 . 1.0d0)))))
  ;; With every required code it validates.
  (is (not (null (validate-entity-dxf
                  '((0 . "ARC") (10 0.0d0 0.0d0 0.0d0) (40 . 1.0d0)
                    (50 . 0.0d0) (51 . 1.5d0)))))))

(test validate-defaults-layer-and-stamps-subclasses
  (multiple-value-bind (data reason)
      (validate-entity-dxf '((0 . "LINE") (10 0.0d0 0.0d0 0.0d0) (11 1.0d0 1.0d0 0.0d0)))
    (is (null reason))
    ;; Layer "0" injected.
    (is (equal "0" (cdr (assoc 8 data))))
    ;; Subclass markers present.
    (let ((markers (loop for (code . val) in data
                         when (and (numberp code) (= code 100)) collect val)))
      (is (member "AcDbEntity" markers :test #'string=))
      (is (member "AcDbLine" markers :test #'string=)))))

(test validate-keeps-explicit-layer
  (multiple-value-bind (data reason)
      (validate-entity-dxf '((0 . "POINT") (8 . "MyLayer") (10 0.0d0 0.0d0 0.0d0)))
    (is (null reason))
    (is (equal "MyLayer" (cdr (assoc 8 data))))
    ;; Only one layer pair.
    (is (= 1 (count 8 data :key (lambda (p) (and (consp p) (car p))))))))

(test validate-passes-through-unknown-type
  ;; Permissive: an unregistered type is accepted unchanged.
  (multiple-value-bind (data reason)
      (validate-entity-dxf '((0 . "WIPEOUT") (8 . "0") (90 . 5)))
    (is (null reason))
    (is (equal "WIPEOUT" (cdr (assoc 0 data))))))

;;; --- XData-aware MODIFY-ENTITY -----------------------------------

(defun %make-circle (drawing)
  (add-entity drawing '((0 . "CIRCLE") (8 . "0")
                        (10 0.0d0 0.0d0 0.0d0) (40 . 1.0d0))))

(test modify-entity-preserves-xdata-when-none-supplied
  (let* ((d (make-drawing))
         (e (%make-circle d))
         (h (entity-handle-id e)))
    ;; Attach xdata via a modify that carries a -3 cell.
    (modify-entity d h '((0 . "CIRCLE") (10 0.0d0 0.0d0 0.0d0) (40 . 2.0d0)
                         (-3 ("MYAPP" (1000 . "hello") (1070 . 42)))))
    ;; A second modify with NO xdata cell must keep the xdata.
    (modify-entity d h '((0 . "CIRCLE") (10 1.0d0 1.0d0 0.0d0) (40 . 3.0d0)))
    (let* ((data (entity-handle-data (find-entity d h)))
           (xdata (find-if (lambda (p) (and (consp p) (eql -3 (car p)))) data)))
      (is (not (null xdata)))
      (is (equal "MYAPP" (car (first (cdr xdata)))))
      ;; Ordinary code updated (radius 3.0).
      (is (= 3.0d0 (cdr (assoc 40 data)))))))

(test modify-entity-merges-xdata-per-application
  (let* ((d (make-drawing))
         (e (%make-circle d))
         (h (entity-handle-id e)))
    (modify-entity d h '((0 . "CIRCLE") (10 0.0d0 0.0d0 0.0d0) (40 . 1.0d0)
                         (-3 ("APP-A" (1000 . "a"))
                             ("APP-B" (1000 . "b")))))
    ;; Replace APP-A, leave APP-B untouched, add APP-C.
    (modify-entity d h '((0 . "CIRCLE") (10 0.0d0 0.0d0 0.0d0) (40 . 1.0d0)
                         (-3 ("APP-A" (1000 . "a2"))
                             ("APP-C" (1000 . "c")))))
    (let* ((data (entity-handle-data (find-entity d h)))
           (groups (cdr (find-if (lambda (p) (and (consp p) (eql -3 (car p)))) data))))
      (is (equal "a2" (cdr (assoc 1000 (cdr (assoc "APP-A" groups :test #'string-equal))))))
      (is (equal "b"  (cdr (assoc 1000 (cdr (assoc "APP-B" groups :test #'string-equal))))))
      (is (equal "c"  (cdr (assoc 1000 (cdr (assoc "APP-C" groups :test #'string-equal)))))))))

(test modify-entity-removes-xdata-for-empty-application
  (let* ((d (make-drawing))
         (e (%make-circle d))
         (h (entity-handle-id e)))
    (modify-entity d h '((0 . "CIRCLE") (10 0.0d0 0.0d0 0.0d0) (40 . 1.0d0)
                         (-3 ("APP-A" (1000 . "a"))
                             ("APP-B" (1000 . "b")))))
    ;; An empty application group removes that application's xdata.
    (modify-entity d h '((0 . "CIRCLE") (10 0.0d0 0.0d0 0.0d0) (40 . 1.0d0)
                         (-3 ("APP-A"))))
    (let* ((data (entity-handle-data (find-entity d h)))
           (groups (cdr (find-if (lambda (p) (and (consp p) (eql -3 (car p)))) data))))
      (is (null (assoc "APP-A" groups :test #'string-equal)))
      (is (not (null (assoc "APP-B" groups :test #'string-equal)))))))
