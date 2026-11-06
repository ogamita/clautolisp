(in-package #:clautolisp.autolisp-host.tests)

(in-suite autolisp-host-suite)

;;; The analytic curve model (curve-geometry.lisp), on plain entget lists:
;;; the cases a host-level test can state without a CAD database
;;; (cador-curve-length-and-sampling.issue). The AutoLISP-level behaviour is
;;; tested through vlax-curve-* in autolisp-builtins-core.

(defun %cg~ (got expected &optional (eps 1d-9))
  (and (numberp got) (< (abs (- got expected)) eps)))

(defun %cg-pt~ (got expected &optional (eps 1d-9))
  (and (listp got) (= (length got) (length expected))
       (every (lambda (g e) (%cg~ g e eps)) got expected)))

(defun %cg-curve (dxf) (clautolisp.autolisp-host:parse-curve-dxf dxf))

(test curve-arc-angles-are-radians
  (let ((arc (%cg-curve '((0 . "ARC") (10 0.0d0 0.0d0 0.0d0) (40 . 10.0d0)
                          (50 . 0.0d0) (51 . 1.5707963267948966d0)))))
    (is (%cg~ (clautolisp.autolisp-host:curve-length arc) (* 5 pi)))
    (is (%cg~ (clautolisp.autolisp-host:curve-total-angle arc) (/ pi 2)))
    (is (%cg-pt~ (clautolisp.autolisp-host:curve-end-point arc) '(0 10 0)))))

(test curve-arc-angles-out-of-range-are-normalised
  ;; -pi/4 .. pi/4 (an entmake may store unnormalised angles)
  (let ((arc (%cg-curve '((0 . "ARC") (10 0.0d0 0.0d0 0.0d0) (40 . 10.0d0)
                          (50 . -0.7853981633974483d0) (51 . 0.7853981633974483d0)))))
    (is (%cg~ (clautolisp.autolisp-host:curve-start-param arc) (* 7/4 pi)))
    (is (%cg~ (clautolisp.autolisp-host:curve-end-param arc) (* 9/4 pi)))
    (is (%cg~ (clautolisp.autolisp-host:curve-length arc) (* 5 pi)))))

(test curve-negative-bulge-turns-clockwise
  ;; (0,0) bulge -1 (10,0): the half circle ABOVE the chord
  (let ((pl (%cg-curve '((0 . "LWPOLYLINE") (90 . 2) (70 . 0)
                         (10 0.0d0 0.0d0) (42 . -1.0d0) (10 10.0d0 0.0d0)))))
    (is (%cg-pt~ (clautolisp.autolisp-host:curve-point-at-param pl 0.5) '(5 5 0)))
    (is (%cg~ (clautolisp.autolisp-host:curve-length pl) (* 5 pi)))
    (is (%cg~ (clautolisp.autolisp-host:curve-area pl) (* 12.5 pi)))))

(test curve-quarter-bulge-geometry
  ;; bulge tan(pi/8): a 90-degree arc from (10,0) to (0,10) about the origin
  (let ((pl (%cg-curve (list '(0 . "LWPOLYLINE") '(90 . 2) '(70 . 0)
                             '(10 10.0d0 0.0d0) (cons 42 (tan (/ pi 8)))
                             '(10 0.0d0 10.0d0)))))
    (is (%cg~ (clautolisp.autolisp-host:curve-length pl) (* 5 pi)))
    (is (%cg-pt~ (clautolisp.autolisp-host:curve-point-at-param pl 0.5)
                 (list (* 10 (cos (/ pi 4))) (* 10 (sin (/ pi 4))) 0)))
    (is (%cg~ (clautolisp.autolisp-host:curve-param-at-point pl (list 0.0d0 10.0d0 0.0d0)) 1.0d0))))

(test curve-two-bulges-make-a-disc
  (let ((pl (%cg-curve '((0 . "LWPOLYLINE") (90 . 2) (70 . 1)
                         (10 0.0d0 0.0d0) (42 . 1.0d0) (10 10.0d0 0.0d0) (42 . 1.0d0)))))
    (is (%cg~ (clautolisp.autolisp-host:curve-area pl) (* 25 pi)))
    (is (%cg~ (clautolisp.autolisp-host:curve-length pl) (* 10 pi)))
    (is (%cg~ (clautolisp.autolisp-host:curve-end-param pl) 2.0d0))))

(test curve-lwpolyline-elevation-is-the-z
  (let ((pl (%cg-curve '((0 . "LWPOLYLINE") (90 . 2) (70 . 0) (38 . 5.0d0)
                         (10 0.0d0 0.0d0) (10 10.0d0 0.0d0)))))
    (is (%cg-pt~ (clautolisp.autolisp-host:curve-end-point pl) '(10 0 5)))
    ;; a 2D query point is taken in the polyline's plane
    (is (%cg~ (clautolisp.autolisp-host:curve-param-at-point pl '(4.0d0 0.0d0)) 0.4d0))))

(test curve-unsupported-entities-are-nil
  (is (null (%cg-curve '((0 . "ELLIPSE")))))
  (is (null (%cg-curve '((0 . "POINT") (10 0.0d0 0.0d0 0.0d0)))))
  (is (null (%cg-curve '((0 . "LWPOLYLINE") (90 . 1) (70 . 0) (10 0.0d0 0.0d0))))))
