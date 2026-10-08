(in-package #:clautolisp.cador)

;;;; IntersectWith -- the ActiveX entity method (cador-intersectwith-missing).
;;;;
;;;;   RetVal = object.IntersectWith(IntersectObject, ExtendOption)
;;;;
;;;; ExtendOption (AcExtendOption): 0 acExtendNone, 1 acExtendThisEntity
;;;; (extend the base object), 2 acExtendOtherEntity (extend the argument),
;;;; 3 acExtendBoth. The vendor returns a VARIANT holding a SAFEARRAY of
;;;; doubles, the points flattened X1 Y1 Z1 X2 Y2 Z2 ..., EMPTY when the
;;;; objects do not meet. This file computes the flat list of doubles; the
;;;; COM layer (vlax-api.lisp) wraps it.
;;;;
;;;; Each entity is decomposed into CURVES, every one lying on an underlying
;;;; LINE, CIRCLE or ELLIPSE with a parameter range:
;;;;
;;;;   LINE      segment [0,1]  -- extended: the infinite line
;;;;   RAY       [0,+inf)       -- extended: the infinite line (TO MEASURE)
;;;;   XLINE     (-inf,+inf)
;;;;   CIRCLE    the full circle
;;;;   ARC       its sweep      -- extended: the full circle
;;;;   ELLIPSE   its parameter range -- extended: the full ellipse
;;;;   LWPOLYLINE / 2D POLYLINE   one line or (bulge) arc per span; extended,
;;;;             an OPEN polyline extends only its first span backwards and
;;;;             its last span forwards (an arc span to its full circle); a
;;;;             closed one does not extend (TO MEASURE)
;;;;   3D POLYLINE  one 3D line per span, same extension rule
;;;;
;;;; SPLINE, meshes, polyface meshes, text, blocks and every other kind are
;;;; NOT supported: the call signals :unsupported-com-geometry naming the
;;;; object, rather than inventing an answer. Entities must lie in a plane
;;;; parallel to XY (extrusion +Z or -Z); a 3D LINE (and 3D polyline span)
;;;; is exact in 3D -- two segments that cross in plan but not in Z do not
;;;; meet.
;;;;
;;;; POINT ORDER: SPEC-UNCERTAIN -- the reference says nothing. cador sorts
;;;; the points by their parameter along the BASE object (start to end; a
;;;; full circle from angle 0 counter-clockwise; a polyline span by span),
;;;; and drops a point repeated within tolerance (a crossing exactly at a
;;;; polyline vertex is reported once). Tangency gives ONE point; collinear
;;;; overlapping lines and coincident circles give NONE. All TO MEASURE:
;;;; autolisp-front-end/tests/scenarios/entities/intersectwith-probe.lsp.

(defparameter *intersect-tolerance* 1d-9
  "Distance (drawing units) under which two points, or a point and a curve,
are taken to coincide in IntersectWith.")

(defconstant +iw-2pi+ (* 2 pi))

;;; --- small vector helpers (3D lists of doubles) -----------------------

(defun %iw-point (p)
  "P as a 3D list of doubles (a missing Z is 0)."
  (list (%num (first p)) (%num (second p)) (%num (or (third p) 0))))

(defun %iw- (a b) (mapcar #'- a b))
(defun %iw+ (a b) (mapcar #'+ a b))
(defun %iw* (k v) (mapcar (lambda (x) (* k x)) v))
(defun %iw-dot2 (a b) (+ (* (first a) (first b)) (* (second a) (second b))))
(defun %iw-cross2 (a b) (- (* (first a) (second b)) (* (second a) (first b))))
(defun %iw-len2 (v) (sqrt (%iw-dot2 v v)))

(defun %iw-dist (a b)
  (sqrt (reduce #'+ (mapcar (lambda (x y) (expt (- x y) 2)) a b))))

;;; --- curves -----------------------------------------------------------

(defstruct (iw-curve (:constructor %make-iw-curve))
  shape          ; :line, :circle or :ellipse
  origin         ; :line -- a point of the line (3D)
  direction      ; :line -- P(t) = origin + t direction (3D)
  lo hi          ; :line -- parameter range; NIL is unbounded
  center         ; :circle / :ellipse (3D; its Z is the curve's plane)
  radius         ; :circle
  major minor    ; :ellipse -- P(t) = center + major cos t + minor sin t (2D)
  start sweep    ; :circle / :ellipse -- the range [start, start+sweep];
                 ; sweep is signed (negative: clockwise in plan); |sweep|
                 ; >= 2pi is the whole curve
  extend-start   ; an arc extended backwards from its start
  extend-end     ; an arc extended forwards from its end
  (rank 0))      ; the span's index along its object (point order)

(defun %iw-full-p (curve)
  (or (>= (abs (iw-curve-sweep curve)) (- +iw-2pi+ 1d-12))
      (iw-curve-extend-start curve)
      (iw-curve-extend-end curve)))

(defun %iw-unsupported (entity why &rest args)
  (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
   :unsupported-com-geometry
   "IntersectWith: ~A ~?; clautolisp does not support it."
   (or (cdr (assoc (entity-handle-kind entity) *entity-com-object-names*))
       (entity-handle-kind entity))
   why args))

(defun %iw-normal-sign (entity)
  "+1 or -1: the entity's extrusion (210) is +Z or -Z. Any other extrusion
is outside the plan geometry IntersectWith supports here."
  (let ((n (%entity-group-value entity 210)))
    (cond ((or (null n) (not (consp n))) 1)
          ((and (< (abs (%num (first n))) 1d-9) (< (abs (%num (second n))) 1d-9))
           (if (minusp (%num (third n))) -1 1))
          (t (%iw-unsupported entity "has the extrusion ~S (not +Z / -Z)" n)))))

(defun %iw-ocs (sign p)
  "OCS point P (3D) in WCS, for the extrusion +Z (SIGN 1) or -Z (SIGN -1):
the arbitrary-axis algorithm gives Ax = -X, Ay = Y for -Z."
  (let ((p (%iw-point p)))
    (if (= sign 1)
        p
        (list (- (first p)) (second p) (- (third p))))))

(defun %iw-line-curve (a b lo hi &optional (rank 0))
  (%make-iw-curve :shape :line :origin a :direction (%iw- b a)
                  :lo lo :hi hi :rank rank))

(defun %iw-arc-curve (center radius start sweep extend-start extend-end
                      &optional (rank 0))
  (%make-iw-curve :shape :circle :center center :radius radius
                  :start start :sweep sweep
                  :extend-start extend-start :extend-end extend-end
                  :rank rank))

(defun %iw-ocs-arc (sign center radius a0 a1 extend)
  "An OCS arc from A0 to A1 (counter-clockwise about the extrusion) in WCS."
  (let ((sweep (let ((s (mod (- a1 a0) +iw-2pi+)))
                 (if (< s 1d-12) +iw-2pi+ s))))
    (if (= sign 1)
        (%iw-arc-curve (%iw-ocs sign center) radius a0 sweep extend extend)
        ;; Mirrored in X: the angle a becomes pi - a, the sense reverses.
        (%iw-arc-curve (%iw-ocs sign center) radius (- pi a0) (- sweep)
                       extend extend))))

(defun %iw-span (p q bulge rank extend-start extend-end)
  "The curve of a polyline span P -> Q (WCS, 3D) with BULGE (already in the
WCS sense), or NIL for a zero-length span."
  (cond
    ((< (%iw-dist p q) *intersect-tolerance*) nil)
    ((< (abs bulge) 1d-12)
     (%iw-line-curve p q (if extend-start nil 0d0) (if extend-end nil 1d0) rank))
    (t
     (let* ((sweep (* 4 (atan bulge)))
            (chord (%iw-len2 (%iw- q p)))
            (dir (%iw* (/ 1 chord) (%iw- q p)))
            (normal (list (- (second dir)) (first dir) 0d0))
            (mid (%iw* 0.5d0 (%iw+ p q)))
            (center (%iw+ mid (%iw* (/ (/ chord 2) (tan (/ sweep 2))) normal)))
            (radius (/ chord (* 2 (abs (sin (/ sweep 2))))))
            (start (atan (- (second p) (second center)) (- (first p) (first center)))))
       (setf (third center) (third p))
       (%iw-arc-curve center radius start sweep extend-start extend-end rank)))))

(defun %iw-polyline-curves (vertices closed extend)
  "VERTICES: ((WCS-POINT . BULGE) ...). The spans' curves, the first one
extended backwards and the last forwards when EXTEND and the polyline is open."
  (let* ((spans (loop for ((p . b) (q . nil)) on (if closed
                                                      (append vertices
                                                              (list (first vertices)))
                                                      vertices)
                      while q
                      collect (list p q (or b 0d0))))
         (n (length spans)))
    (loop for (p q b) in spans
          for i from 0
          for curve = (%iw-span p q b i
                                (and extend (not closed) (= i 0))
                                (and extend (not closed) (= i (1- n))))
          when curve collect curve)))

(defun %iw-lwpolyline-curves (entity extend)
  (let* ((sign (%iw-normal-sign entity))
         (elevation (%num (or (%entity-group-value entity 38) 0)))
         (closed (logtest 1 (or (%entity-group-value entity 70) 0)))
         (vertices '()))
    (dolist (pair (entity-handle-data entity))
      (when (consp pair)
        (cond ((group-code-equal-p (car pair) 10)
               (let ((v (cdr pair)))
                 (push (cons (%iw-ocs sign (list (first v) (second v) elevation))
                             0d0)
                       vertices)))
              ((and vertices (group-code-equal-p (car pair) 42))
               (setf (cdr (first vertices)) (* sign (%num (cdr pair))))))))
    (%iw-polyline-curves (nreverse vertices) closed extend)))

(defun %iw-polyline-curves-of (host entity extend)
  "A POLYLINE (2D or 3D) from its VERTEX run."
  (let* ((flags (or (%entity-group-value entity 70) 0))
         (closed (logtest 1 flags))
         (three-d (logtest 8 flags))
         (sign (if three-d 1 (%iw-normal-sign entity)))
         (elevation (%num (or (third (%entity-group-value entity 10)) 0)))
         (vertices '()))
    (when (logtest (logior 16 64) flags)
      (%iw-unsupported entity "is a polygon or polyface mesh"))
    (dolist (handle (%entity-subentity-handles host entity))
      (let ((vertex (cador-find-entity-by-handle host handle)))
        (when (and vertex (eq (entity-handle-kind vertex) :vertex)
                   ;; a spline frame control point is not on the curve
                   (not (logtest 16 (or (%entity-group-value vertex 70) 0))))
          (let ((p (%entity-group-value vertex 10)))
            (push (cons (if three-d
                            (%iw-point p)
                            (%iw-ocs sign (list (first p) (second p) elevation)))
                        (if three-d
                            0d0
                            (* sign (%num (or (%entity-group-value vertex 42) 0)))))
                  vertices)))))
    (%iw-polyline-curves (nreverse vertices) closed extend)))

(defun %iw-ellipse-curve (entity extend)
  (let* ((n (%entity-group-value entity 210))
         (sign (if (and (consp n) (minusp (%num (third n)))) -1 1))
         (center (%iw-point (%entity-group-value entity 10)))
         (u (%iw-point (%entity-group-value entity 11)))
         (ratio (%num (or (%entity-group-value entity 40) 1)))
         (t0 (%num (or (%entity-group-value entity 41) 0)))
         (t1 (%num (or (%entity-group-value entity 42) +iw-2pi+)))
         (sweep (let ((s (mod (- t1 t0) +iw-2pi+)))
                  (if (< s 1d-12) +iw-2pi+ s))))
    (%iw-normal-sign entity)            ; refuses a non-plan extrusion
    (unless (< (abs (third u)) 1d-9)
      (%iw-unsupported entity "has a major axis out of the XY plane"))
    ;; minor = ratio * (N x major), N = (0 0 sign)
    (%make-iw-curve :shape :ellipse :center center
                    :major (list (first u) (second u))
                    :minor (list (* ratio sign (- (second u)))
                                 (* ratio sign (first u)))
                    :start t0 :sweep sweep
                    :extend-start extend :extend-end extend)))

(defun entity-intersection-curves (host entity extend)
  "ENTITY as a list of IW-CURVEs, extended as EXTEND says."
  (flet ((g (code) (%entity-group-value entity code)))
    (case (entity-handle-kind entity)
      (:line
       (list (%iw-line-curve (%iw-point (g 10)) (%iw-point (g 11))
                             (if extend nil 0d0) (if extend nil 1d0))))
      (:ray
       (let ((o (%iw-point (g 10))))
         (list (%iw-line-curve o (%iw+ o (%iw-point (g 11)))
                               (if extend nil 0d0) nil))))
      (:xline
       (let ((o (%iw-point (g 10))))
         (list (%iw-line-curve o (%iw+ o (%iw-point (g 11))) nil nil))))
      (:circle
       (let ((sign (%iw-normal-sign entity)))
         (list (%iw-ocs-arc sign (g 10) (%num (g 40)) 0d0 +iw-2pi+ nil))))
      (:arc
       (let ((sign (%iw-normal-sign entity)))
         (list (%iw-ocs-arc sign (g 10) (%num (g 40))
                            (%num (g 50)) (%num (g 51)) extend))))
      (:ellipse (list (%iw-ellipse-curve entity extend)))
      (:lwpolyline (%iw-lwpolyline-curves entity extend))
      (:polyline (%iw-polyline-curves-of host entity extend))
      (t (%iw-unsupported entity "is not a curve IntersectWith handles")))))

;;; --- where a point sits on a curve ----------------------------------

(defun %iw-line-param (curve p)
  (let ((d (iw-curve-direction curve)))
    (/ (%iw-dot2 (%iw- p (iw-curve-origin curve)) d)
       (max 1d-300 (%iw-dot2 d d)))))

(defun %iw-angle-key (curve angle)
  "The fraction of CURVE's sweep at ANGLE, or NIL off the curve. Extended
arcs cover the whole curve; a point beyond the start of a curve extended
only backwards gets a negative fraction, so it sorts before the start."
  (let* ((sweep (iw-curve-sweep curve))
         (span (abs sweep))
         (offset (mod (* (signum sweep) (- angle (iw-curve-start curve))) +iw-2pi+))
         (eps 1d-9))
    (when (> offset (- +iw-2pi+ eps)) (setf offset 0d0))
    (cond
      ((<= offset (+ span eps)) (/ offset span))
      ((not (%iw-full-p curve)) nil)
      ((and (iw-curve-extend-start curve) (not (iw-curve-extend-end curve)))
       (/ (- offset +iw-2pi+) span))
      (t (/ offset span)))))

(defun %iw-ellipse-frame (curve p)
  "P in the ellipse's own frame, where the ellipse is the unit circle."
  (let ((q (%iw- p (iw-curve-center curve)))
        (u (iw-curve-major curve))
        (v (iw-curve-minor curve)))
    (list (/ (%iw-dot2 q u) (%iw-dot2 u u))
          (/ (%iw-dot2 q v) (%iw-dot2 v v)))))

(defun %iw-key (curve p)
  "The ordering key of point P on CURVE -- its rank plus its fraction along
the curve -- or NIL when P lies outside CURVE's range."
  (let ((fraction
          (ecase (iw-curve-shape curve)
            (:line
             (let* ((tt (%iw-line-param curve p))
                    (len (max 1d-300 (%iw-len2 (iw-curve-direction curve))))
                    (eps (/ *intersect-tolerance* len))
                    (lo (iw-curve-lo curve))
                    (hi (iw-curve-hi curve)))
               (and (or (null lo) (>= tt (- lo eps)))
                    (or (null hi) (<= tt (+ hi eps)))
                    tt)))
            (:circle
             (let ((c (iw-curve-center curve)))
               (%iw-angle-key curve (atan (- (second p) (second c))
                                          (- (first p) (first c))))))
            (:ellipse
             (let ((f (%iw-ellipse-frame curve p)))
               (%iw-angle-key curve (atan (second f) (first f))))))))
    (and fraction (+ (iw-curve-rank curve) fraction))))

;;; --- underlying-shape intersections ---------------------------------

(defun %iw-plane-z (curve) (third (iw-curve-center curve)))

(defun %iw-line-z-at (curve tt)
  (+ (third (iw-curve-origin curve)) (* tt (third (iw-curve-direction curve)))))

(defun %iw-line-point (curve tt)
  (%iw+ (iw-curve-origin curve) (%iw* tt (iw-curve-direction curve))))

(defun %iw-line-line (a b)
  (let* ((d1 (iw-curve-direction a)) (d2 (iw-curve-direction b))
         (w (%iw- (iw-curve-origin b) (iw-curve-origin a)))
         (den (%iw-cross2 d1 d2)))
    (unless (<= (abs den) (* 1d-12 (%iw-len2 d1) (%iw-len2 d2)))
      (let* ((tt (/ (%iw-cross2 w d2) den))
             (s (/ (%iw-cross2 w d1) den))
             (p (%iw-line-point a tt)))
        (when (<= (abs (- (third p) (%iw-line-z-at b s))) *intersect-tolerance*)
          (list p))))))

(defun %iw-line-unit-circle (o d center radius)
  "Parameters t where the plan line O + t D meets the circle CENTER RADIUS
\(one parameter when tangent)."
  (let* ((f (%iw- o center))
         (a (%iw-dot2 d d))
         (t0 (- (/ (%iw-dot2 f d) a)))
         (foot (%iw+ f (%iw* t0 d)))
         (dist (%iw-len2 foot))
         (tol (* *intersect-tolerance* (max 1d0 radius))))
    (cond ((> dist (+ radius tol)) '())
          ((<= (abs (- dist radius)) tol) (list t0))
          (t (let ((h (/ (sqrt (- (* radius radius) (* dist dist))) (sqrt a))))
               (list (- t0 h) (+ t0 h)))))))

(defun %iw-on-plane (points z)
  (remove-if-not (lambda (p) (<= (abs (- (third p) z)) *intersect-tolerance*))
                 points))

(defun %iw-line-circle (line circle)
  (let ((c (iw-curve-center circle)))
    (%iw-on-plane
     (mapcar (lambda (tt) (%iw-line-point line tt))
             (%iw-line-unit-circle (iw-curve-origin line) (iw-curve-direction line)
                                   (list (first c) (second c) 0d0)
                                   (iw-curve-radius circle)))
     (third c))))

(defun %iw-line-ellipse (line ellipse)
  ;; In the ellipse's frame the ellipse is the unit circle and the line is
  ;; still a line, with the same parameter.
  (let* ((o (%iw-ellipse-frame ellipse (iw-curve-origin line)))
         (d (let ((u (iw-curve-major ellipse)) (v (iw-curve-minor ellipse))
                  (dd (iw-curve-direction line)))
              (list (/ (%iw-dot2 dd u) (%iw-dot2 u u))
                    (/ (%iw-dot2 dd v) (%iw-dot2 v v))))))
    (when (> (%iw-dot2 d d) 0)
      (%iw-on-plane
       (mapcar (lambda (tt) (%iw-line-point line tt))
               (%iw-line-unit-circle (list (first o) (second o) 0d0)
                                     (list (first d) (second d) 0d0)
                                     '(0d0 0d0 0d0) 1d0))
       (%iw-plane-z ellipse)))))

(defun %iw-circle-circle (a b)
  (let* ((c1 (iw-curve-center a)) (c2 (iw-curve-center b))
         (r1 (iw-curve-radius a)) (r2 (iw-curve-radius b))
         (dv (%iw- c2 c1))
         (d (%iw-len2 dv))
         (tol (* *intersect-tolerance* (max 1d0 r1 r2))))
    (when (and (<= (abs (- (third c1) (third c2))) *intersect-tolerance*)
               (> d tol)
               (<= d (+ r1 r2 tol))
               (>= d (- (abs (- r1 r2)) tol)))
      (let* ((along (/ (+ (- (* r1 r1) (* r2 r2)) (* d d)) (* 2 d)))
             (h2 (- (* r1 r1) (* along along)))
             (unit (list (/ (first dv) d) (/ (second dv) d) 0d0))
             (perp (list (- (second unit)) (first unit) 0d0))
             (mid (%iw+ c1 (%iw* along unit))))
        (setf (third mid) (third c1))
        (if (or (<= (abs (- d (+ r1 r2))) tol)
                (<= (abs (- d (abs (- r1 r2)))) tol)
                (<= h2 0))
            (list mid)
            (let ((h (sqrt h2)))
              (list (%iw+ mid (%iw* h perp)) (%iw- mid (%iw* h perp)))))))))

(defun %iw-ellipse-point (curve theta)
  (let ((c (iw-curve-center curve)) (u (iw-curve-major curve)) (v (iw-curve-minor curve)))
    (list (+ (first c) (* (first u) (cos theta)) (* (first v) (sin theta)))
          (+ (second c) (* (second u) (cos theta)) (* (second v) (sin theta)))
          (third c))))

(defun %iw-implicit (curve)
  "A function of a plan point, zero on CURVE's underlying circle / ellipse,
of opposite signs inside and outside."
  (ecase (iw-curve-shape curve)
    (:circle
     (let ((c (iw-curve-center curve)) (r (iw-curve-radius curve)))
       (lambda (p) (- (%iw-len2 (%iw- p c)) r))))
    (:ellipse
     (lambda (p)
       (let ((f (%iw-ellipse-frame curve p)))
         (- (%iw-len2 f) 1d0))))))

(defparameter *iw-ellipse-samples* 2048
  "Samples around an ellipse when its intersections are found numerically.")

(defun %iw-ellipse-conic (ellipse other)
  "Points where the ellipse ELLIPSE meets the circle or ellipse OTHER: the
other's implicit function sampled around ELLIPSE, each sign change refined
by bisection, each near-zero local minimum (a tangency) by golden section."
  (when (<= (abs (- (%iw-plane-z ellipse) (%iw-plane-z other))) *intersect-tolerance*)
    (let* ((g (%iw-implicit other))
           (n *iw-ellipse-samples*)
           (step (/ +iw-2pi+ n))
           (f (lambda (theta) (funcall g (%iw-ellipse-point ellipse theta))))
           (samples (make-array (1+ n)))
           (thetas '()))
      (dotimes (i (1+ n))
        (setf (aref samples i) (funcall f (* i step))))
      ;; Coincident curves: no isolated points.
      (unless (every (lambda (v) (< (abs v) 1d-7)) samples)
        (dotimes (i n)
          (let ((a (* i step)) (fa (aref samples i)) (fb (aref samples (1+ i))))
            (cond
              ((zerop fa) (push a thetas))
              ((minusp (* fa fb))
               (let ((lo a) (hi (+ a step)) (flo fa))
                 (loop repeat 100
                       for mid = (/ (+ lo hi) 2)
                       for fm = (funcall f mid)
                       do (if (minusp (* flo fm))
                              (setf hi mid)
                              (setf lo mid flo fm)))
                 (push (/ (+ lo hi) 2) thetas)))
              ;; |f| has a local minimum at sample i+1 without a sign change
              ((and (< (1+ i) n)
                    (< (abs fb) (abs fa))
                    (<= (abs fb) (abs (aref samples (+ i 2))))
                    (plusp (* fb (aref samples (+ i 2))))
                    (plusp (* fa fb)))
               (let ((lo a) (hi (+ a step step))
                     (phi (/ (- (sqrt 5d0) 1) 2)))
                 (loop repeat 100
                       for m1 = (- hi (* phi (- hi lo)))
                       for m2 = (+ lo (* phi (- hi lo)))
                       do (if (< (abs (funcall f m1)) (abs (funcall f m2)))
                              (setf hi m2)
                              (setf lo m1)))
                 (let ((m (/ (+ lo hi) 2)))
                   (when (< (abs (funcall f m)) 1d-7)
                     (push m thetas)))))))))
      (mapcar (lambda (theta) (%iw-ellipse-point ellipse theta)) (nreverse thetas)))))

(defun %iw-shape-intersections (a b)
  "The points where the UNDERLYING shapes of curves A and B meet."
  (let ((sa (iw-curve-shape a)) (sb (iw-curve-shape b)))
    (cond
      ((and (eq sa :line) (eq sb :line)) (%iw-line-line a b))
      ((and (eq sa :line) (eq sb :circle)) (%iw-line-circle a b))
      ((and (eq sa :circle) (eq sb :line)) (%iw-line-circle b a))
      ((and (eq sa :circle) (eq sb :circle)) (%iw-circle-circle a b))
      ((and (eq sa :line) (eq sb :ellipse)) (%iw-line-ellipse a b))
      ((and (eq sa :ellipse) (eq sb :line)) (%iw-line-ellipse b a))
      ((eq sa :ellipse) (%iw-ellipse-conic a b))
      (t (%iw-ellipse-conic b a)))))

(defun entity-intersect-with (host base other option)
  "IntersectWith(OTHER, OPTION) on BASE (entity handles): the points where
they meet, as a flat list of doubles X1 Y1 Z1 X2 ..., sorted along BASE;
NIL when they do not meet."
  (let* ((extend-base (member option '(1 3)))
         (extend-other (member option '(2 3)))
         (curves-a (entity-intersection-curves host base extend-base))
         (curves-b (entity-intersection-curves host other extend-other))
         (hits '()))
    (dolist (a curves-a)
      (dolist (b curves-b)
        (dolist (p (%iw-shape-intersections a b))
          (let ((ka (%iw-key a p)))
            (when (and ka (%iw-key b p))
              (push (cons ka p) hits))))))
    (let ((points '()))
      (dolist (hit (stable-sort (nreverse hits) #'< :key #'car))
        (unless (find-if (lambda (q) (< (%iw-dist q (cdr hit)) (* 10 *intersect-tolerance*)))
                         points)
          (push (cdr hit) points)))
      (loop for p in (nreverse points) append p))))
