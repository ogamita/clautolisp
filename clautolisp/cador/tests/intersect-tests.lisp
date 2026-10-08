(in-package #:clautolisp.cador.tests)

(in-suite cador-suite)

;;;; IntersectWith on entity-backed VLA-objects (cador-intersectwith-missing).
;;;; The host BELOW the builtins layer: the result is the plain flat list of
;;;; doubles X1 Y1 Z1 X2 ... (NIL when the objects do not meet); the VARIANT
;;;; wrapping is tested end-to-end in the builtins suite. Point ORDER is
;;;; the vendors' MEASURED order (intersectwith-probe.lsp, 2026-10-08):
;;;; AutoCAD's by default (the bare host has no dialect), BricsCAD's with
;;;; :vendor :bricscad (intersectwith-bricscad-order).

(defun %iw-obj (mock dxf)
  (let ((view (host-entmake mock dxf)))
    (host-vlax-ename->vla-object mock (cdr (first view)))))

(defun %iw-line (mock p q)
  (%iw-obj mock (list (cons 0 "LINE") (cons 10 p) (cons 11 q))))

(defun %iw-circle (mock c r)
  (%iw-obj mock (list (cons 0 "CIRCLE") (cons 10 c) (cons 40 r))))

(defun %iw-arc (mock c r a0 a1 &optional normal)
  (%iw-obj mock (append (list (cons 0 "ARC") (cons 10 c) (cons 40 r)
                              (cons 50 a0) (cons 51 a1))
                        (and normal (list (cons 210 normal))))))

(defun %iw-lwpoly (mock closed)
  ;; (-3,-3) -> (-3,3) -> clockwise half circle over (0,6) -> (3,3) -> (3,-3)
  (%iw-obj mock (list (cons 0 "LWPOLYLINE") (cons 100 "AcDbEntity")
                      (cons 100 "AcDbPolyline") (cons 90 4) (cons 70 closed)
                      (list 10 -3d0 -3d0) (cons 42 0d0)
                      (list 10 -3d0 3d0) (cons 42 -1d0)
                      (list 10 3d0 3d0) (cons 42 0d0)
                      (list 10 3d0 -3d0) (cons 42 0d0))))

(defun %iw-heavy-poly (mock flags vertices)
  "A POLYLINE header + VERTEX run + SEQEND; VERTICES are (POINT . BULGE)."
  (host-entmake mock (list (cons 0 "POLYLINE") (cons 66 1)
                           (list 10 0d0 0d0 0d0) (cons 70 flags)))
  (dolist (v vertices)
    (host-entmake mock (list (cons 0 "VERTEX") (cons 10 (car v))
                             (cons 42 (cdr v)))))
  (host-entmake mock (list (cons 0 "SEQEND")))
  ;; entlast after SEQEND names the POLYLINE header (the vendor contract).
  (host-vlax-ename->vla-object mock (host-entlast mock)))

(defun %iw (mock a b option)
  (host-vlax-invoke-method mock a "IntersectWith" (list b option)))

(defun %iw-near-p (expected actual &optional (tolerance 1d-9))
  (and (= (length expected) (length actual))
       (every (lambda (e a) (< (abs (- e a)) tolerance)) expected actual)))

(defmacro %iw-check (mock a b &rest per-option)
  "PER-OPTION: four expected flat point lists, for acExtend 0 1 2 3."
  `(loop for option from 0
         for expected in (list ,@per-option)
         do (let ((actual (%iw ,mock ,a ,b option)))
              (is (%iw-near-p expected actual)
                  "~A x ~A, option ~D: expected ~S, got ~S"
                  ',a ',b option expected actual))))

(defparameter *iw-sqrt5* (sqrt 5d0))

(defun %iw-reverse-points (flat)
  "FLAT (X1 Y1 Z1 X2 ...) with its points in the reverse order."
  (loop for p in (reverse (loop for (x y z) on flat by #'cdddr
                                collect (list x y z)))
        append p))

(test intersectwith-line-line
  (clautolisp.autolisp-runtime:without-builtin-layer-hooks
    (let* ((mock (make-cador))
           (diag (%iw-line mock '(0d0 0d0 0d0) '(10d0 10d0 0d0)))
           (anti (%iw-line mock '(0d0 10d0 0d0) '(10d0 0d0 0d0)))
           (par (%iw-line mock '(0d0 1d0 0d0) '(10d0 11d0 0d0)))
           (col (%iw-line mock '(5d0 5d0 0d0) '(15d0 15d0 0d0)))
           (skew (%iw-line mock '(0d0 10d0 1d0) '(10d0 0d0 1d0)))
           (la (%iw-line mock '(0d0 0d0 0d0) '(4d0 0d0 0d0)))
           (lb (%iw-line mock '(6d0 -2d0 0d0) '(6d0 -1d0 0d0)))
           (lc (%iw-line mock '(6d0 -1d0 0d0) '(6d0 1d0 0d0)))
           (x '(5d0 5d0 0d0))
           (m '(6d0 0d0 0d0)))
      (%iw-check mock diag anti x x x x)
      (%iw-check mock diag par nil nil nil nil)
      ;; collinear overlap: no isolated point (TO MEASURE)
      (%iw-check mock diag col nil nil nil nil)
      ;; crossing in plan, one unit apart in Z
      (%iw-check mock diag skew nil nil nil nil)
      ;; meet only when BOTH are extended
      (%iw-check mock la lb nil nil nil m)
      ;; the base must be extended
      (%iw-check mock la lc nil m nil m)
      ;; ... and swapped, the OTHER one must
      (%iw-check mock lc la nil nil m m))))

(test intersectwith-line-circle-and-arc
  (clautolisp.autolisp-runtime:without-builtin-layer-hooks
    (let* ((mock (make-cador))
           (c5 (%iw-circle mock '(0d0 0d0 0d0) 5d0))
           (lx (%iw-line mock '(-10d0 0d0 0d0) '(10d0 0d0 0d0)))
           (lxr (%iw-line mock '(10d0 0d0 0d0) '(-10d0 0d0 0d0)))
           (lv (%iw-line mock '(0d0 -10d0 0d0) '(0d0 10d0 0d0)))
           (tan (%iw-line mock '(-10d0 5d0 0d0) '(10d0 5d0 0d0)))
           (out (%iw-line mock '(-10d0 7d0 0d0) '(10d0 7d0 0d0)))
           (in (%iw-line mock '(-1d0 0d0 0d0) '(1d0 0d0 0d0)))
           (up (%iw-arc mock '(0d0 0d0 0d0) 5d0 0d0 pi))
           (y3 (%iw-line mock '(-10d0 3d0 0d0) '(10d0 3d0 0d0)))
           (ym3 (%iw-line mock '(-10d0 -3d0 0d0) '(10d0 -3d0 0d0)))
           (two '(-5d0 0d0 0d0 5d0 0d0 0d0))
           (owt '(5d0 0d0 0d0 -5d0 0d0 0d0)))
      ;; line x CIRCLE: the point farther from the line's start first,
      ;; whichever is the base
      (%iw-check mock lx c5 owt owt owt owt)
      (%iw-check mock lxr c5 two two two two)
      (%iw-check mock c5 lx owt owt owt owt)
      (%iw-check mock c5 lv '(0d0 5d0 0d0 0d0 -5d0 0d0) '(0d0 5d0 0d0 0d0 -5d0 0d0)
                 '(0d0 5d0 0d0 0d0 -5d0 0d0) '(0d0 5d0 0d0 0d0 -5d0 0d0))
      ;; tangency is ONE point
      (%iw-check mock tan c5 '(0d0 5d0 0d0) '(0d0 5d0 0d0) '(0d0 5d0 0d0) '(0d0 5d0 0d0))
      (%iw-check mock out c5 nil nil nil nil)
      (%iw-check mock in c5 nil owt nil owt)
      (let ((pts '(-4d0 3d0 0d0 4d0 3d0 0d0))
            (low '(-4d0 -3d0 0d0 4d0 -3d0 0d0)))
        ;; line x ARC: descending offset from the arc's start -- (-4,3) at
        ;; 143 degrees before (4,3) at 37
        (%iw-check mock y3 up pts pts pts pts)
        ;; below the upper half arc: only on its full circle; (4,-3) at 323
        ;; before (-4,-3) at 217
        (%iw-check mock ym3 up nil nil (%iw-reverse-points low) (%iw-reverse-points low))
        (%iw-check mock up ym3 nil (%iw-reverse-points low) nil (%iw-reverse-points low))
        ;; the arc's end points are on it; its start counts as a whole turn
        (%iw-check mock lx up owt owt owt owt)))))

(test intersectwith-circle-circle-and-arc-arc
  (clautolisp.autolisp-runtime:without-builtin-layer-hooks
    (let* ((mock (make-cador))
           (c5 (%iw-circle mock '(0d0 0d0 0d0) 5d0))
           (r6 (%iw-circle mock '(6d0 0d0 0d0) 5d0))
           (ctan (%iw-circle mock '(10d0 0d0 0d0) 5d0))
           (far (%iw-circle mock '(20d0 0d0 0d0) 5d0))
           (cin (%iw-circle mock '(0d0 0d0 0d0) 3d0))
           (up (%iw-arc mock '(0d0 0d0 0d0) 5d0 0d0 pi))
           (left (%iw-arc mock '(6d0 0d0 0d0) 5d0 (/ pi 2) (* 1.5d0 pi)))
           (low (%iw-arc mock '(0d0 0d0 0d0) 5d0 pi (* 2 pi)))
           (right (%iw-arc mock '(6d0 0d0 0d0) 5d0 (* 1.5d0 pi) (/ pi 2)))
           (both '(3d0 4d0 0d0 3d0 -4d0 0d0))
           (top '(3d0 4d0 0d0))
           (bottom '(3d0 -4d0 0d0)))
      ;; mid + h perp first (perp: left of base centre -> other centre); AutoCAD
      ;; computes options 2 / 3 as the OTHER object's IntersectWith
      (%iw-check mock c5 r6 both both (%iw-reverse-points both) (%iw-reverse-points both))
      (%iw-check mock r6 c5 (%iw-reverse-points both) (%iw-reverse-points both) both both)
      (%iw-check mock c5 ctan '(5d0 0d0 0d0) '(5d0 0d0 0d0) '(5d0 0d0 0d0) '(5d0 0d0 0d0))
      (%iw-check mock c5 far nil nil nil nil)
      (%iw-check mock c5 cin nil nil nil nil)
      ;; (3,4) is on both arcs, (3,-4) only on LEFT
      (%iw-check mock up left top both top (%iw-reverse-points both))
      (%iw-check mock left up top top both both)
      ;; (3,-4) is on LOW only, (3,4) on neither
      (%iw-check mock low right nil nil bottom (list 3d0 -4d0 0d0 3d0 4d0 0d0)))))

(test intersectwith-polylines
  (clautolisp.autolisp-runtime:without-builtin-layer-hooks
    (let* ((mock (make-cador))
           (pl (%iw-lwpoly mock 0))
           (plc (%iw-lwpoly mock 1))
           (p2d (%iw-heavy-poly mock 0 '(((-3d0 -3d0 0d0) . 0d0)
                                         ((-3d0 3d0 0d0) . -1d0)
                                         ((3d0 3d0 0d0) . 0d0)
                                         ((3d0 -3d0 0d0) . 0d0))))
           (c5 (%iw-circle mock '(0d0 0d0 0d0) 5d0))
           (lx (%iw-line mock '(-10d0 0d0 0d0) '(10d0 0d0 0d0)))
           (y5 (%iw-line mock '(-10d0 5d0 0d0) '(10d0 5d0 0d0)))
           (y3 (%iw-line mock '(-10d0 3d0 0d0) '(10d0 3d0 0d0)))
           (ym5 (%iw-line mock '(-10d0 -5d0 0d0) '(10d0 -5d0 0d0)))
           (two '(-3d0 0d0 0d0 3d0 0d0 0d0))
           (arc (list (- *iw-sqrt5*) 5d0 0d0 *iw-sqrt5* 5d0 0d0))
           (vertices '(-3d0 3d0 0d0 3d0 3d0 0d0))
           (ext '(-3d0 -5d0 0d0 3d0 -5d0 0d0)))
      (dolist (poly (list pl p2d))
        (%iw-check mock poly lx two two two two)
        (%iw-check mock lx poly two two two two)
        ;; the bulge span is a true arc
        (%iw-check mock poly y5 arc arc arc arc)
        ;; a crossing at a shared vertex is reported once
        (%iw-check mock poly y3 vertices vertices vertices vertices)
        ;; extended: the first span backwards, the last forwards
        (%iw-check mock poly ym5 nil ext nil ext)
        (%iw-check mock ym5 poly nil nil ext ext))
      ;; a closed polyline does not extend
      (%iw-check mock plc ym5 nil nil nil nil)
      (%iw-check mock plc lx two two two two)
      ;; the arc span against a circle, and the extended end spans
      (let* ((y (/ 25d0 6))
             (x (sqrt (- 25d0 (* y y))))
             (pair (list (- x) y 0d0 x y 0d0))
             (four (append '(-3d0 -4d0 0d0) pair '(3d0 -4d0 0d0))))
        (%iw-check mock pl c5 pair four pair four)))))

(test intersectwith-3d-polyline-rays-xlines-ellipses
  (clautolisp.autolisp-runtime:without-builtin-layer-hooks
    (let* ((mock (make-cador))
           (lx (%iw-line mock '(-10d0 0d0 0d0) '(10d0 0d0 0d0)))
           ;; 3D polyline: its first span rises through Z = 0 at x = 0
           (p3d (%iw-heavy-poly mock 8 '(((0d0 -5d0 -5d0) . 0d0)
                                         ((0d0 5d0 5d0) . 0d0)
                                         ((5d0 5d0 5d0) . 0d0))))
           (ray (%iw-obj mock (list (cons 0 "RAY") (cons 100 "AcDbEntity") (cons 100 "AcDbRay")
                                    (list 10 0d0 5d0 0d0)
                                    (list 11 0d0 -1d0 0d0))))
           (away (%iw-obj mock (list (cons 0 "RAY") (cons 100 "AcDbEntity") (cons 100 "AcDbRay")
                                    (list 10 2d0 5d0 0d0)
                                     (list 11 0d0 1d0 0d0))))
           (xl (%iw-obj mock (list (cons 0 "XLINE") (cons 100 "AcDbEntity") (cons 100 "AcDbXline")
                                   (list 10 2d0 50d0 0d0)
                                   (list 11 0d0 1d0 0d0))))
           ;; a quarter arc with extrusion -Z: in WCS from (-5,0) to (0,5)
           (mirrored (%iw-arc mock '(0d0 0d0 0d0) 5d0 0d0 (/ pi 2) '(0d0 0d0 -1d0)))
           (el (%iw-obj mock (list (cons 0 "ELLIPSE") (cons 100 "AcDbEntity") (cons 100 "AcDbEllipse")
                                   (list 10 0d0 0d0 0d0)
                                   (list 11 8d0 0d0 0d0) (list 210 0d0 0d0 1d0)
                                   (cons 40 0.5d0) (cons 41 0d0) (cons 42 (* 2 pi)))))
           (half (%iw-obj mock (list (cons 0 "ELLIPSE") (cons 100 "AcDbEntity") (cons 100 "AcDbEllipse")
                                   (list 10 0d0 0d0 0d0)
                                     (list 11 8d0 0d0 0d0) (cons 40 0.5d0)
                                     (cons 41 0d0) (cons 42 pi))))
           (c5 (%iw-circle mock '(0d0 0d0 0d0) 5d0))
           (ym2 (%iw-line mock '(-10d0 -2d0 0d0) '(10d0 -2d0 0d0)))
           (o '(0d0 0d0 0d0)))
      (%iw-check mock lx p3d o o o o)
      (%iw-check mock lx ray o o o o)
      ;; a ray pointing away meets the line only extended backwards
      (%iw-check mock lx away nil nil '(2d0 0d0 0d0) '(2d0 0d0 0d0))
      (%iw-check mock lx xl '(2d0 0d0 0d0) '(2d0 0d0 0d0) '(2d0 0d0 0d0) '(2d0 0d0 0d0))
      (%iw-check mock lx mirrored '(-5d0 0d0 0d0) '(-5d0 0d0 0d0) '(-5d0 0d0 0d0 5d0 0d0 0d0) '(-5d0 0d0 0d0 5d0 0d0 0d0))
      (%iw-check mock el lx '(8d0 0d0 0d0 -8d0 0d0 0d0) '(8d0 0d0 0d0 -8d0 0d0 0d0)
                 '(8d0 0d0 0d0 -8d0 0d0 0d0) '(8d0 0d0 0d0 -8d0 0d0 0d0))
      ;; the upper half ellipse meets y = -2 only when extended
      (let* ((x (* 8 (sqrt 0.75d0)))
             ;; line x ellipse: the point farther from the line's start first
             (pts (list x -2d0 0d0 (- x) -2d0 0d0)))
        (%iw-check mock half ym2 nil pts nil pts))
      ;; ellipse x circle is found numerically: x^2 = 12, y^2 = 13
      (let* ((x (sqrt 12d0)) (y (sqrt 13d0))
             (expected (list x y 0d0 (- x) y 0d0 (- x) (- y) 0d0 x (- y) 0d0)))
        (is (%iw-near-p expected (%iw mock el c5 0) 1d-7))
        (is (%iw-near-p expected (%iw mock c5 el 3) 1d-7))))))

(test intersectwith-arguments-and-unsupported-geometry
  (clautolisp.autolisp-runtime:without-builtin-layer-hooks
    (let* ((mock (make-cador))
           (lx (%iw-line mock '(-10d0 0d0 0d0) '(10d0 0d0 0d0)))
           (pt (%iw-obj mock (list (cons 0 "POINT") (list 10 0d0 0d0 0d0))))
           (text (%iw-obj mock (%tv-text-dxf "t"))))
      (flet ((code (thunk)
               (handler-case (progn (funcall thunk) :no-error)
                 (autolisp-runtime-error (e) (autolisp-runtime-error-code e)))))
        (is (eq :unsupported-com-geometry (code (lambda () (%iw mock lx pt 0)))))
        (is (eq :unsupported-com-geometry (code (lambda () (%iw mock text lx 0)))))
        (is (eq :invalid-com-argument (code (lambda () (%iw mock lx lx 7)))))
        (is (eq :invalid-com-argument
                (code (lambda () (host-vlax-invoke-method
                                  mock lx "IntersectWith" (list lx 0 0))))))
        (is (host-vlax-method-applicable-p mock lx "IntersectWith"))
        (is (host-vlax-method-applicable-p mock lx "intersectwith"))))))

;;; BricsCAD's order (intersectwith-probe.lsp on BricsCAD V26 macOS, job
;;; 17029587293, and V25 Windows, 17029587294): no role swap for options
;;; 2 / 3, a bulge span taken in its travel direction (and as the FIRST of
;;; a span x circle pair), ellipse x circle by ascending X then descending Y.

(defun %iw-entity (mock dxf)
  (let ((view (host-entmake mock dxf)))
    (clautolisp.cador::cador-find-entity-by-handle
     mock (autolisp-ename-value (cdr (first view))))))

(test intersectwith-bricscad-order
  (clautolisp.autolisp-runtime:without-builtin-layer-hooks
    (let* ((mock (make-cador))
           (c5 (%iw-entity mock (list (cons 0 "CIRCLE") (list 10 0d0 0d0 0d0) (cons 40 5d0))))
           (r6 (%iw-entity mock (list (cons 0 "CIRCLE") (list 10 6d0 0d0 0d0) (cons 40 5d0))))
           (y5 (%iw-entity mock (list (cons 0 "LINE") (list 10 -10d0 5d0 0d0)
                                      (list 11 10d0 5d0 0d0))))
           (pl (%iw-entity mock (list (cons 0 "LWPOLYLINE") (cons 100 "AcDbEntity")
                                      (cons 100 "AcDbPolyline") (cons 90 4) (cons 70 0)
                                      (list 10 -3d0 -3d0) (cons 42 0d0)
                                      (list 10 -3d0 3d0) (cons 42 -1d0)
                                      (list 10 3d0 3d0) (cons 42 0d0)
                                      (list 10 3d0 -3d0) (cons 42 0d0))))
           (el (%iw-entity mock (list (cons 0 "ELLIPSE") (cons 100 "AcDbEntity")
                                      (cons 100 "AcDbEllipse") (list 10 0d0 0d0 0d0)
                                      (list 11 8d0 0d0 0d0) (cons 40 0.5d0)
                                      (cons 41 0d0) (cons 42 (* 2 pi)))))
           (s5 *iw-sqrt5*)
           (x (sqrt 12d0)) (y (sqrt 13d0))
           (cy (/ 25d0 6)) (cx (sqrt (- 25d0 (* cy cy)))))
      (flet ((both (base other option)
               (values (clautolisp.cador::entity-intersect-with mock base other option
                                                                :vendor :autocad)
                       (clautolisp.cador::entity-intersect-with mock base other option
                                                                :vendor :bricscad))))
        ;; circle x circle, option 2: AutoCAD follows the argument, BricsCAD not
        (multiple-value-bind (a b) (both c5 r6 2)
          (is (%iw-near-p '(3d0 -4d0 0d0 3d0 4d0 0d0) a))
          (is (%iw-near-p '(3d0 4d0 0d0 3d0 -4d0 0d0) b)))
        ;; the bulge span against a line
        (multiple-value-bind (a b) (both pl y5 0)
          (is (%iw-near-p (list (- s5) 5d0 0d0 s5 5d0 0d0) a))
          (is (%iw-near-p (list s5 5d0 0d0 (- s5) 5d0 0d0) b)))
        ;; ... and against a circle, the first span extended
        (multiple-value-bind (a b) (both pl c5 1)
          (is (%iw-near-p (list -3d0 -4d0 0d0 (- cx) cy 0d0 cx cy 0d0 3d0 -4d0 0d0) a))
          (is (%iw-near-p (list -3d0 -4d0 0d0 cx cy 0d0 (- cx) cy 0d0 3d0 -4d0 0d0) b)))
        ;; ellipse x circle
        (multiple-value-bind (a b) (both el c5 0)
          (is (%iw-near-p (list x y 0d0 (- x) y 0d0 (- x) (- y) 0d0 x (- y) 0d0) a 1d-7))
          (is (%iw-near-p (list (- x) y 0d0 (- x) (- y) 0d0 x y 0d0 x (- y) 0d0) b 1d-7)))
        ;; the point SETS agree: an empty result is empty for both
        (multiple-value-bind (a b) (both c5 y5 0)
          (is (%iw-near-p '(0d0 5d0 0d0) a))
          (is (%iw-near-p '(0d0 5d0 0d0) b)))))))
