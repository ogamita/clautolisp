(in-package #:clautolisp.cador)

;;;; Draw constructions of the command engine (alref Phase 4 S1,
;;;; autolisp-spec-alref-commands.issue).
;;;;
;;;; Each command is built against what the vendors MAKE, measured by
;;;; probes/sources/probe-commands.lsp, not against their documentation:
;;;; the entity type, the groups, the vertex order and where a polygon
;;;; starts are all read off the probe results (BricsCAD V26 macOS
;;;; 20261003T151707Z; AutoCAD 2022 alongside). Input is the token
;;;; sequence of one (command ...) call; malformed input degrades to
;;;; record-only, as everywhere in the engine.

(defun %pt2 (p) (list (first p) (second p)))

(defun %v- (a b) (mapcar #'- a b))

(defun %v+ (a b) (mapcar #'+ a b))

(defun %v* (k v) (mapcar (lambda (x) (* k x)) v))

(defun %vlen (v) (sqrt (reduce #'+ (mapcar (lambda (x) (* x x)) v))))

(defun %vunit (v)
  (let ((l (%vlen v)))
    (if (zerop l) v (%v* (/ 1.0d0 l) v))))

(defun %take-points (tokens)
  "Consume point tokens up to RETURN (consumed) or the first non-point.
Returns (values POINTS REMAINING)."
  (let ((points '()))
    (loop
      (let ((token (first tokens)))
        (cond ((null tokens) (return))
              ((equal token "") (pop tokens) (return))
              ((%command-token-point token)
               (push (%command-token-point token) points)
               (pop tokens))
              (t (return)))))
    (values (nreverse points) tokens)))

(defun %lwpolyline-data (host points &key closed)
  "An LWPOLYLINE through POINTS (2D vertices), with the subclass markers
a command-made R13+ entity needs."
  (append (list (cons 0 "LWPOLYLINE")
                (cons 100 "AcDbEntity") (cons 100 "AcDbPolyline")
                (cons 8 (%current-layer-name host))
                (cons 90 (length points))
                (cons 70 (if closed 1 0)))
          (mapcar (lambda (p) (cons 10 (%pt2 p))) points)))

;;; POINT: one point.
(defun %cmd-point (host tokens)
  (let ((p (%command-token-point (first tokens))))
    (when p
      (pop tokens)
      (%command-entity host (list (cons 0 "POINT")
                                  (cons 8 (%current-layer-name host))
                                  (cons 10 p) (cons 50 0.0d0)))))
  tokens)

;;; RAY: a base point, then through points until RETURN -- one RAY each,
;;; group 11 the UNIT direction (measured: "1,1" -> 0.707107,0.707107).
(defun %cmd-ray (host tokens)
  (let ((base (%command-token-point (first tokens))))
    (unless base (return-from %cmd-ray tokens))
    (pop tokens)
    (multiple-value-bind (throughs rest) (%take-points tokens)
      (dolist (p throughs)
        (%command-entity host (list (cons 0 "RAY")
                                    (cons 100 "AcDbEntity") (cons 100 "AcDbRay")
                                    (cons 8 (%current-layer-name host))
                                    (cons 10 base)
                                    (cons 11 (%vunit (%v- p base))))))
      rest)))

;;; XLINE: a point, then through points until RETURN (the default
;;; two-point form; Hor/Ver/Ang/Bisect/Offset are not modelled).
(defun %cmd-xline (host tokens)
  (let ((base (%command-token-point (first tokens))))
    (unless base (return-from %cmd-xline tokens))
    (pop tokens)
    (multiple-value-bind (throughs rest) (%take-points tokens)
      (dolist (p throughs)
        (%command-entity host (list (cons 0 "XLINE")
                                    (cons 100 "AcDbEntity") (cons 100 "AcDbXline")
                                    (cons 8 (%current-layer-name host))
                                    (cons 10 base)
                                    (cons 11 (%vunit (%v- p base))))))
      rest)))

;;; ELLIPSE: axis endpoint, axis endpoint, distance to the other axis --
;;; or _Center: center, axis endpoint, distance. Measured: the center is
;;; the axis midpoint (or the given center), group 11 the vector from the
;;; center to the FIRST axis point given, 40 = distance / half-axis.
(defun %ellipse-data (host center axis-end distance)
  (let* ((major (%v- axis-end center))
         (a (%vlen major)))
    (when (and (plusp a) (plusp distance))
      (when (> distance a)
        ;; The other axis is the longer one: it becomes the major axis.
        (let ((perp (%v* (/ distance a) (list (- (second major)) (first major) 0.0d0))))
          (setf a distance major perp distance (%vlen (%v- axis-end center)))))
      (list (cons 0 "ELLIPSE")
            (cons 100 "AcDbEntity") (cons 100 "AcDbEllipse")
            (cons 8 (%current-layer-name host))
            (cons 10 center) (cons 11 major)
            (cons 40 (/ distance a))
            (cons 41 0.0d0) (cons 42 (* 2 pi))))))

(defun %cmd-ellipse (host tokens)
  (let ((centered (%command-option-p (first tokens) "c" "center")))
    (when centered (pop tokens))
    (let ((p1 (%command-token-point (first tokens)))
          (p2 (%command-token-point (second tokens)))
          (d (%command-token-number (third tokens))))
      (unless (and p1 p2 d) (return-from %cmd-ellipse tokens))
      (setf tokens (cdddr tokens))
      (let* ((center (if centered p1 (%v* 0.5d0 (%v+ p1 p2))))
             (axis-end (if centered p2 p1))
             (data (%ellipse-data host center axis-end d)))
        (when data (%command-entity host data)))
      tokens)))

;;; POLYGON: sides, then a center and Inscribed/Circumscribed with a
;;; radius -- or _Edge and two points. Measured vertex order (6 inscribed
;;; r2, 5 circumscribed r2): counter-clockwise, the bottom edge
;;; horizontal, starting at vertex floor(n/2) of the sequence that begins
;;; just right of straight down: angle_j = 270 + 180/n + (floor(n/2)+j)
;;; x 360/n degrees. A circumscribed radius is the apothem. By edge: the
;;; two points, then onward counter-clockwise (the polygon on their left).
(defun %polygon-vertices (center radius n inscribed)
  (let ((r (if inscribed radius (/ radius (cos (/ pi n)))))
        (step (/ (* 2 pi) n))
        (start (+ (* 1.5d0 pi) (/ pi n) (* (floor n 2) (/ (* 2 pi) n)))))
    (loop for j below n
          for a = (+ start (* j step))
          collect (list (+ (first center) (* r (cos a)))
                        (+ (second center) (* r (sin a)))))))

(defun %polygon-edge-vertices (p1 p2 n)
  (let ((step (/ (* 2 pi) n))
        (side (%vlen (%v- (%pt2 p2) (%pt2 p1))))
        (heading (atan (- (second p2) (second p1)) (- (first p2) (first p1))))
        (points (list (%pt2 p1))))
    (loop repeat (1- n)
          for a = heading then (+ a step)
          do (let ((last (first points)))
               (push (list (+ (first last) (* side (cos a)))
                           (+ (second last) (* side (sin a))))
                     points)))
    (nreverse points)))

(defun %cmd-polygon (host tokens)
  (let ((n (%command-token-number (first tokens))))
    (unless (and n (>= n 3) (= n (ffloor n))) (return-from %cmd-polygon tokens))
    (pop tokens)
    (setf n (round n))
    (cond
      ((%command-option-p (first tokens) "e" "edge")
       (pop tokens)
       (let ((p1 (%command-token-point (first tokens)))
             (p2 (%command-token-point (second tokens))))
         (when (and p1 p2)
           (setf tokens (cddr tokens))
           (%command-entity host (%lwpolyline-data
                                  host (%polygon-edge-vertices p1 p2 n) :closed t)))))
      (t
       (let ((center (%command-token-point (first tokens))))
         (when center
           (pop tokens)
           (let ((inscribed t))
             (cond ((%command-option-p (first tokens) "i" "inscribed") (pop tokens))
                   ((%command-option-p (first tokens) "c" "circumscribed")
                    (setf inscribed nil) (pop tokens)))
             (let ((radius (%command-token-number (first tokens))))
               (when radius
                 (pop tokens)
                 (%command-entity host (%lwpolyline-data
                                        host (%polygon-vertices center radius n inscribed)
                                        :closed t)))))))))
    tokens))

;;; RECTANG: two corners -> a closed 4-vertex LWPOLYLINE, measured order
;;; c1, (c2.x c1.y), c2, (c1.x c2.y) -- whichever way the corners go.
(defun %cmd-rectang (host tokens)
  (let ((c1 (%command-token-point (first tokens)))
        (c2 (%command-token-point (second tokens))))
    (when (and c1 c2)
      (setf tokens (cddr tokens))
      (%command-entity host (%lwpolyline-data
                             host (list (%pt2 c1)
                                        (list (first c2) (second c1))
                                        (%pt2 c2)
                                        (list (first c1) (second c2)))
                             :closed t))))
  tokens)

;;; TRACE: width, then points until RETURN. One TRACE per segment, its
;;; corners start-left, start-right, end-left, end-right; consecutive
;;; segments meet MITERED (measured: (0,0)-(4,0)-(4,3) width 0.5 ->
;;; (0,0.25) (0,-0.25) (3.75,0.25) (4.25,-0.25), then from the miter).
(defun %offset-line-intersection (p d q e)
  "Intersection of the lines P + tD and Q + uE (2D), or NIL if parallel."
  (let ((den (- (* (first d) (second e)) (* (second d) (first e)))))
    (unless (< (abs den) 1d-12)
      (let ((tt (/ (- (* (- (first q) (first p)) (second e))
                      (* (- (second q) (second p)) (first e)))
                   den)))
        (list (+ (first p) (* tt (first d))) (+ (second p) (* tt (second d))))))))

(defun %cmd-trace (host tokens)
  (let ((w (%command-token-number (first tokens))))
    (unless w (return-from %cmd-trace tokens))
    (pop tokens)
    (multiple-value-bind (points rest) (%take-points tokens)
      (let* ((h (/ w 2.0d0))
             (pts (mapcar #'%pt2 points))
             (n (length pts)))
        (when (>= n 2)
          (flet ((left (d) (list (- (second d)) (first d))))
            (let ((dirs (loop for (a b) on pts while b collect (%vunit (%v- b a))))
                  (start-l nil) (start-r nil))
              (loop for i from 0
                    for (a b) on pts while b
                    for d = (nth i dirs)
                    for nl = (%v* h (left d))
                    do (let* ((sl (or start-l (%v+ a nl)))
                              (sr (or start-r (%v- a nl)))
                              (next (nth (1+ i) dirs))
                              (el (or (and next (%offset-line-intersection
                                                 (%v+ a nl) d
                                                 (%v+ b (%v* h (left next))) next))
                                      (%v+ b nl)))
                              (er (or (and next (%offset-line-intersection
                                                 (%v- a nl) d
                                                 (%v- b (%v* h (left next))) next))
                                      (%v- b nl))))
                         (%command-entity host
                                          (list (cons 0 "TRACE")
                                                (cons 8 (%current-layer-name host))
                                                (cons 10 (append sl '(0.0d0)))
                                                (cons 11 (append sr '(0.0d0)))
                                                (cons 12 (append el '(0.0d0)))
                                                (cons 13 (append er '(0.0d0)))))
                         (setf start-l el start-r er))))))
        rest))))

;;; 3DPOLY: points until RETURN -> a 3D POLYLINE (70 = 8) with one VERTEX
;;; (70 = 32) per point and a SEQEND, as measured.
(defun %cmd-3dpoly (host tokens)
  (multiple-value-bind (points rest) (%take-points tokens)
    (when (>= (length points) 2)
      (let ((layer (%current-layer-name host)))
        (%command-entity host (list (cons 0 "POLYLINE") (cons 8 layer)
                                    (cons 66 1) (cons 10 (list 0.0d0 0.0d0 0.0d0))
                                    (cons 70 8)))
        (dolist (p points)
          (%command-entity host (list (cons 0 "VERTEX") (cons 8 layer)
                                      (cons 10 p) (cons 70 32))))
        (%command-entity host (list (cons 0 "SEQEND") (cons 8 layer)))))
    rest))

(define-cador-command "POINT"   '%cmd-point)
(define-cador-command "RAY"     '%cmd-ray)
(define-cador-command "XLINE"   '%cmd-xline)
(define-cador-command "ELLIPSE" '%cmd-ellipse)
(define-cador-command "POLYGON" '%cmd-polygon)
(define-cador-command "RECTANG" '%cmd-rectang)
(define-cador-command "TRACE"   '%cmd-trace)
(define-cador-command "3DPOLY"  '%cmd-3dpoly)

;;; SPLINE (fit points): points until RETURN, then the start and end
;;; tangent prompts answered by RETURN (default tangents). Measured on
;;; BricsCAD (0,0) (1,1) (2,0) (3,1): a degree-3 SPLINE, flags 1064, with
;;; CHORD-LENGTH parameters, a clamped knot vector whose interior knots
;;; are the interior fit points' parameters, and n+2 control points
;;; solving the interpolation with NATURAL ends (zero second derivative)
;;; -- reproduced to 1e-6 by this construction (.spline-fit check).

(defun %bspline-basis (i k u knots)
  "Cox-de Boor B-spline basis N(i,k) at U; the last span is closed."
  (if (zerop k)
      (let ((a (aref knots i)) (b (aref knots (1+ i))))
        (if (or (and (<= a u) (< u b))
                (and (= u (aref knots (1- (length knots)))) (< a u) (<= u b)))
            1.0d0 0.0d0))
      (let* ((d1 (- (aref knots (+ i k)) (aref knots i)))
             (d2 (- (aref knots (+ i k 1)) (aref knots (1+ i))))
             (l (if (zerop d1) 0.0d0
                    (* (/ (- u (aref knots i)) d1) (%bspline-basis i (1- k) u knots))))
             (r (if (zerop d2) 0.0d0
                    (* (/ (- (aref knots (+ i k 1)) u) d2)
                       (%bspline-basis (1+ i) (1- k) u knots)))))
        (+ l r))))

(defun %second-derivative-row (n knots p i)
  "Coefficients over the N control points of R_I, the I-th control point
of the spline's second derivative."
  (flet ((q (j)
           (let ((row (make-array n :initial-element 0.0d0))
                 (s (/ p (- (aref knots (+ j p 1)) (aref knots (1+ j))))))
             (incf (aref row (1+ j)) s)
             (decf (aref row j) s)
             row)))
    (let ((s (/ (1- p) (- (aref knots (+ i p 1)) (aref knots (+ i 2)))))
          (q1 (q (1+ i))) (q0 (q i)))
      (map 'vector (lambda (a b) (* s (- a b))) q1 q0))))

(defun %solve-linear (rows rhs)
  "Solve ROWS X = RHS (vectors) by Gaussian elimination with pivoting."
  (let* ((n (length rows))
         (m (make-array (list n (1+ n)))))
    (dotimes (r n)
      (dotimes (c n) (setf (aref m r c) (aref (elt rows r) c)))
      (setf (aref m r n) (elt rhs r)))
    (dotimes (c n)
      (let ((piv c))
        (loop for r from c below n
              when (> (abs (aref m r c)) (abs (aref m piv c))) do (setf piv r))
        (dotimes (k (1+ n)) (rotatef (aref m c k) (aref m piv k)))
        (dotimes (r n)
          (unless (= r c)
            (let ((f (/ (aref m r c) (aref m c c))))
              (dotimes (k (1+ n)) (decf (aref m r k) (* f (aref m c k)))))))))
    (loop for r below n collect (/ (aref m r n) (aref m r r)))))

(defun %fit-spline (fit)
  "Knots and control points of the natural cubic through the FIT points."
  (let* ((p 3)
         (params (let ((acc (list 0.0d0)))
                   (loop for (a b) on fit while b
                         do (push (+ (first acc) (%vlen (%v- b a))) acc))
                   (nreverse acc)))
         (last-u (car (last params)))
         (knots (coerce (append (make-list 4 :initial-element 0.0d0)
                                (butlast (rest params))
                                (make-list 4 :initial-element last-u))
                        'vector))
         (n (+ (length fit) 2))
         (rows (append (loop for u in params
                             collect (let ((row (make-array n)))
                                       (dotimes (i n)
                                         (setf (aref row i) (%bspline-basis i p u knots)))
                                       row))
                       (list (%second-derivative-row n knots p 0)
                             (%second-derivative-row n knots p (- n 3))))))
    (values knots
            (let ((coords (loop for axis below 3
                                collect (%solve-linear
                                         rows
                                         (append (mapcar (lambda (pt) (nth axis pt)) fit)
                                                 (list 0.0d0 0.0d0))))))
              (apply #'mapcar #'list coords)))))

(defun %cmd-spline (host tokens)
  (multiple-value-bind (fit rest) (%take-points tokens)
    ;; The start / end tangent prompts, answered by RETURN.
    (loop repeat 2 while (equal (first rest) "") do (pop rest))
    (when (>= (length fit) 2)
      (multiple-value-bind (knots controls) (%fit-spline fit)
        (%command-entity
         host
         (append (list (cons 0 "SPLINE")
                       (cons 100 "AcDbEntity") (cons 100 "AcDbSpline")
                       (cons 8 (%current-layer-name host))
                       (cons 70 1064) (cons 71 3)
                       (cons 72 (length knots)) (cons 73 (length controls))
                       (cons 74 (length fit))
                       (cons 42 1d-10) (cons 43 1d-10) (cons 44 0.0d0)
                       (cons 12 (list 0.0d0 0.0d0 0.0d0))
                       (cons 13 (list 0.0d0 0.0d0 0.0d0)))
                 (map 'list (lambda (k) (cons 40 k)) knots)
                 (mapcar (lambda (c) (cons 10 c)) controls)
                 (mapcar (lambda (f) (cons 11 f)) fit)))))
    rest))

(define-cador-command "SPLINE" '%cmd-spline)

;;; MLINE: points until RETURN (or _Close), in the current multiline
;;; style, scale and justification (CMLSTYLE, CMLSCALE, CMLJUST). Only the
;;; STANDARD style's two elements (offsets +0.5 and -0.5) are modelled.
;;; Measured on BricsCAD (0,0) (4,0) (4,3), scale 20, Top: per vertex the
;;; vertex (11), the outgoing segment direction (12; the last segment's at
;;; the end), the miter (13: the normalised sum of the adjacent segments'
;;; left normals), then per element 74=2, the distance along the miter
;;; (offset x scale / (miter . left normal)), 0, 75=0.

(defun %sysvar-value (host name default)
  (let ((cell (ignore-errors (cador-sysvar host name))))
    (if cell (sysvar-cell-value cell) default)))

(defun %cmd-mline (host tokens)
  (let ((closed nil) (points '()))
    (loop
      (let ((token (first tokens)))
        (cond ((null tokens) (return))
              ((equal token "") (pop tokens) (return))
              ((%command-option-p token "c" "close") (setf closed t) (pop tokens) (return))
              ((%command-token-point token)
               (push (%command-token-point token) points) (pop tokens))
              (t (return)))))
    (setf points (nreverse points))
    (when (>= (length points) 2)
      (let* ((scale (coerce (%sysvar-value host "CMLSCALE" 1.0d0) 'double-float))
             (just (%sysvar-value host "CMLJUST" 0))
             (style (%sysvar-value host "CMLSTYLE" "Standard"))
             (offsets (let ((raw '(0.5d0 -0.5d0)))
                        (case just
                          (0 (mapcar (lambda (o) (- o (reduce #'max raw))) raw))
                          (2 (mapcar (lambda (o) (- o (reduce #'min raw))) raw))
                          (t raw))))
             (n (length points))
             (dirs (loop for (a b) on (if closed (append points (list (first points))) points)
                         while b collect (%vunit (%v- b a))))
             (data (list (cons 0 "MLINE")
                         (cons 100 "AcDbEntity") (cons 100 "AcDbMline")
                         (cons 8 (%current-layer-name host))
                         (cons 2 (if (stringp style) style "Standard"))
                         (cons 40 scale) (cons 70 just)
                         (cons 71 (if closed 3 1))
                         (cons 72 n) (cons 73 (length offsets))
                         (cons 10 (first points)))))
        (flet ((left (d) (list (- (second d)) (first d) 0.0d0)))
          (loop for i below n
                for p = (nth i points)
                for in = (if (plusp i) (nth (1- i) dirs) (and closed (car (last dirs))))
                for out = (or (nth i dirs) (car (last dirs)))
                for miter = (if in (%vunit (%v+ (left in) (left out))) (left out))
                for cosine = (reduce #'+ (mapcar #'* miter (left out)))
                do (setf data (append data
                                      (list (cons 11 p) (cons 12 out) (cons 13 miter))))
                   (dolist (o offsets)
                     (setf data (append data
                                        (list (cons 74 2)
                                              (cons 41 (if (zerop cosine) 0.0d0
                                                           (/ (* o scale) cosine)))
                                              (cons 41 0.0d0)
                                              (cons 75 0)))))))
        (%command-entity host data)))
    tokens))

(define-cador-command "MLINE" '%cmd-mline)
