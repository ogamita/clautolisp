;;;; Tests for the cador scene view (scene-view.lisp) -- the drawable display
;;;; list the cadgui canvas paints. cadgui-2-qt6-gui-host.issue slice B.

(in-package #:clautolisp.cador.tests)

(in-suite cador-suite)

(defun %scene-list (mock) (cador-scene-display-list mock))

(test scene-empty-host-has-empty-display-list
  (let ((mock (make-cador)))
    (is (null (cador-scene-display-list mock)))
    (is (null (cador-scene-extents mock)))))

(test scene-line-becomes-an-open-polyline
  (let ((mock (make-cador)))
    (host-entmake mock (list (cons 0 "LINE") (cons 8 "L1")
                             (cons 10 '(0.0d0 0.0d0 0.0d0))
                             (cons 11 '(1.0d0 1.0d0 0.0d0))))
    (let ((prims (%scene-list mock)))
      (is (= 1 (length prims)))
      (destructuring-bind (type handle layer aci closed points) (first prims)
        (is (eq :polyline type))
        (is (stringp handle))
        (is (string= "L1" layer))
        (is (integerp aci))
        (is (null closed))
        (is (equal '(0.0d0 0.0d0 1.0d0 1.0d0) points))
        ;; coordinates are double-floats (clean to read across the ECL boundary)
        (is (every (lambda (x) (typep x 'double-float)) points))))))

(test scene-line-honours-its-colour-index
  (let ((mock (make-cador)))
    (host-entmake mock (list (cons 0 "LINE") (cons 8 "WALL") (cons 62 3)
                             (cons 10 '(0.0d0 0.0d0 0.0d0))
                             (cons 11 '(2.0d0 0.0d0 0.0d0))))
    (destructuring-bind (type handle layer aci closed points) (first (%scene-list mock))
      (declare (ignore type handle layer closed points))
      (is (= 3 aci)))))

(test scene-line-without-colour-reports-bylayer-256
  (let ((mock (make-cador)))
    (host-entmake mock (list (cons 0 "LINE") (cons 8 "0")
                             (cons 10 '(0.0d0 0.0d0 0.0d0))
                             (cons 11 '(1.0d0 0.0d0 0.0d0))))
    (is (= 256 (fourth (first (%scene-list mock)))))))

(test scene-circle-becomes-a-closed-sampled-polyline
  (let ((mock (make-cador)))
    (host-entmake mock (list (cons 0 "CIRCLE") (cons 8 "0")
                             (cons 10 '(0.0d0 0.0d0 0.0d0)) (cons 40 1.0d0)))
    (destructuring-bind (type handle layer aci closed points) (first (%scene-list mock))
      (declare (ignore type handle layer aci))
      (is (eq t closed))
      (is (> (length points) 16))      ; many sampled points
      (is (evenp (length points)))
      ;; every sampled vertex lies (within tolerance) on the unit circle
      (is (loop for (x y) on points by #'cddr
                always (< (abs (- 1.0d0 (sqrt (+ (* x x) (* y y))))) 1.0d-6))))))

(test scene-preserves-creation-order-back-to-front
  (let ((mock (make-cador)))
    (host-entmake mock (list (cons 0 "LINE") (cons 8 "A")
                             (cons 10 '(0.0d0 0.0d0 0.0d0)) (cons 11 '(1.0d0 0.0d0 0.0d0))))
    (host-entmake mock (list (cons 0 "LINE") (cons 8 "B")
                             (cons 10 '(0.0d0 0.0d0 0.0d0)) (cons 11 '(2.0d0 0.0d0 0.0d0))))
    (let ((prims (%scene-list mock)))
      (is (= 2 (length prims)))
      (is (string= "A" (third (first prims))))   ; oldest first (painted first)
      (is (string= "B" (third (second prims)))))))

(test scene-extents-span-all-entities
  (let ((mock (make-cador)))
    (host-entmake mock (list (cons 0 "LINE") (cons 8 "0")
                             (cons 10 '(-1.0d0 -2.0d0 0.0d0)) (cons 11 '(3.0d0 4.0d0 0.0d0))))
    (destructuring-bind (x0 y0 x1 y1) (cador-scene-extents mock)
      (is (= -1.0d0 x0)) (is (= -2.0d0 y0))
      (is (= 3.0d0 x1)) (is (= 4.0d0 y1))
      (is (every (lambda (v) (typep v 'double-float)) (list x0 y0 x1 y1))))))
