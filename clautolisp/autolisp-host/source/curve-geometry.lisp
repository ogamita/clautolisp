(in-package #:clautolisp.autolisp-host)

;;;; Curve geometry — the analytic model behind vlax-curve-* and the
;;;; geometric ActiveX properties (ArcLength, TotalAngle, Length, Area, ...).
;;;;
;;;; It lives in the host layer because BOTH consumers sit on top of it and
;;;; must agree: the vlax-curve-* builtins (autolisp-builtins-core) and the
;;;; cador ActiveX property bridge (cador/vlax-api). Neither depends on the
;;;; other.
;;;;
;;;; Input is the entget DXF of the curve (entget conventions: angles in
;;;; RADIANS, points WCS for LINE, OCS = WCS for the default +Z normal); a
;;;; 2D POLYLINE also needs the entget DXF of its VERTEX entities.
;;;;
;;;; Parameter conventions (AcDbCurve; MEASURED on AutoCAD 2022 GUI and
;;;; AcCoreConsole, BricsCAD V25 Windows and V26 macOS by the
;;;; curve-geometry:probe:* jobs, 2026-10-08 -- see
;;;; issues/*/cador-curve-length-and-sampling.issue for every data point):
;;;;   LINE        param = distance from the start point, 0 .. length;
;;;;   RAY / XLINE param = distance along the unit direction;
;;;;   CIRCLE      param = angle in radians, 0 .. 2pi;
;;;;   ARC         param = angle in radians, start angle .. end angle, the end
;;;;               angle raised by 2pi when it is not above the start angle;
;;;;   LWPOLYLINE / 2D / 3D POLYLINE
;;;;               param = vertex index + fraction of the segment, 0 .. n-1
;;;;               (open) or 0 .. n (closed); on a bulge (arc) segment the
;;;;               fraction is proportional to the swept angle.
;;;; Distances are arc lengths from the start of the curve: a bulge segment
;;;; contributes R * |theta|, theta = 4 * atan(bulge).
;;;;
;;;; What happens OUTSIDE the curve, at its ends and off it differs per entity
;;;; and per PRODUCT (the measured behaviour, AutoCAD's for every dialect but
;;;; the BricsCAD ones). The rules live in the functions below, each with its
;;;; evidence; the product is the current evaluation dialect's.

(defparameter *curve-point-tolerance* 1d-10
  "Absolute distance under which a point counts as lying on a curve (the
AcGe default equalPoint tolerance). Both vendors reject a point 1e-7 off an
ARC, a LINE or a 2D POLYLINE (measured); it is widened by the magnitude of
the coordinates (see %POINT-TOLERANCE) so that rounding on real-world
coordinates does not reject a point computed on the curve.")

(defparameter *curve-param-tolerance* 1d-9
  "Relative slack accepted on a parameter or distance at a curve's ends.")

(defparameter *curve-bricscad-dist-tolerance* 1d-6
  "BricsCAD answers getParamAtDist a little past an end like at the end, and
far past it with the curve's LENGTH (measured at 1e-9 and 1.0; the
threshold in between is not measured).")

(defconstant +two-pi+ (* 2 pi))

;;; --- product --------------------------------------------------------------

(defun current-curve-product ()
  "The product whose curve behaviour applies: :BRICSCAD under a BricsCAD
dialect, :AUTOCAD otherwise (AutoCAD is the behavioural template of the
strict, autocad, clautolisp and lax dialects)."
  (let ((dialect (ignore-errors
                  (clautolisp.autolisp-runtime:current-evaluation-dialect))))
    (if (and dialect
             (eq :bricscad (ignore-errors
                            (clautolisp.autolisp-reader:autolisp-dialect-product dialect))))
        :bricscad
        :autocad)))

(defun %bricscad-p (curve) (eq (getf curve :product) :bricscad))

;;; --- small vector kit ---------------------------------------------------

(defun %cg-d (x) (coerce (if (realp x) x 0) 'double-float))
(defun %cg-v (p &optional (z 0.0d0))
  "Coerce a point list to (x y z) doubles; a 2D point takes Z."
  (list (%cg-d (nth 0 p)) (%cg-d (nth 1 p))
        (if (and (consp (cddr p)) (realp (third p))) (%cg-d (third p)) (%cg-d z))))
(defun %cg+ (a b) (mapcar #'+ a b))
(defun %cg- (a b) (mapcar #'- a b))
(defun %cg* (a s) (mapcar (lambda (x) (* x s)) a))
(defun %cg-dot (a b) (reduce #'+ (mapcar #'* a b)))
(defun %cg-len (a) (sqrt (%cg-dot a a)))
(defun %cg-dist (a b) (%cg-len (%cg- a b)))
(defun %cg-unit (a) (let ((l (%cg-len a))) (if (zerop l) a (%cg* a (/ 1.0d0 l)))))
(defun %cg-polar (center radius angle)
  (list (+ (first center) (* radius (cos angle)))
        (+ (second center) (* radius (sin angle)))
        (third center)))
(defun %cg-angle-of (center p)
  (atan (- (second p) (second center)) (- (first p) (first center))))
(defun %cg-norm-angle (a)
  "A in [0, 2pi)."
  (let ((m (mod a +two-pi+))) (if (>= m +two-pi+) 0.0d0 m)))

(defun %cg-string (x)
  (cond ((stringp x) x)
        ((typep x 'clautolisp.autolisp-runtime:autolisp-string)
         (clautolisp.autolisp-runtime:autolisp-string-value x))
        (t x)))

(defun %cg-ref (dxf code)
  (cdr (find-if (lambda (e) (and (consp e) (eql (car e) code))) dxf)))

;;; --- segments -------------------------------------------------------------
;;;
;;; A polyline is a list of segments, each a plist:
;;;   (:kind :line :a A :b B :len L)
;;;   (:kind :arc  :a A :b B :len L :center C :radius R :a0 START-ANGLE
;;;                :theta SIGNED-SWEEP)

(defun make-curve-segment (a b bulge)
  "The segment from A to B (3D points) with BULGE (0 = straight)."
  (let ((chord (%cg-dist a b)))
    (if (or (null bulge) (zerop bulge) (zerop chord))
        (list :kind :line :a a :b b :len chord)
        (let* ((theta (* 4 (atan bulge)))
               (half (/ theta 2))
               (radius (abs (/ chord (* 2 (sin half)))))
               (mid (%cg* (%cg+ a b) 0.5d0))
               (dir (%cg-unit (%cg- b a)))
               (left (list (- (second dir)) (first dir) 0.0d0))
               (center (%cg+ mid (%cg* left (* 0.5d0 chord (/ (cos half) (sin half)))))))
          (setf (third center) (third a))
          (list :kind :arc :a a :b b :center center :radius radius
                :a0 (%cg-angle-of center a) :theta theta
                :len (* radius (abs theta)))))))

(defun %segment-point (seg f)
  "The point at fraction F of SEG; F outside [0, 1] extrapolates along the
segment's own geometry (the AutoCAD 2D POLYLINE below its start)."
  (if (eq (getf seg :kind) :line)
      (%cg+ (getf seg :a) (%cg* (%cg- (getf seg :b) (getf seg :a)) f))
      (cond ((= f 1) (copy-list (getf seg :b)))
            ((= f 0) (copy-list (getf seg :a)))
            (t (%cg-polar (getf seg :center) (getf seg :radius)
                          (+ (getf seg :a0) (* f (getf seg :theta))))))))

(defun %segment-deriv (seg f)
  "First derivative on SEG. Measured: a straight segment answers its chord
vector B - A; a bulge segment answers the tangent of length R (the
derivative with respect to the swept ANGLE, not to the segment fraction),
oriented along the travel."
  (if (eq (getf seg :kind) :line)
      (%cg- (getf seg :b) (getf seg :a))
      (let* ((r (getf seg :radius)) (th (getf seg :theta))
             (ang (+ (getf seg :a0) (* f th)))
             (s (float (signum th) 1d0)))
        (list (* s -1 r (sin ang)) (* s r (cos ang)) 0.0d0))))

(defun %segment-deriv2 (seg f product)
  "Second derivative on SEG: -R (cos, sin) on a bulge segment, multiplied by
the sign of the bulge on AutoCAD (measured: a negative bulge answers
(-5 0 0) on AutoCAD and (5 0 0) on BricsCAD at the same point)."
  (if (eq (getf seg :kind) :line)
      (list 0.0d0 0.0d0 0.0d0)
      (let* ((r (getf seg :radius)) (th (getf seg :theta))
             (ang (+ (getf seg :a0) (* f th)))
             (s (if (eq product :autocad) (float (signum th) 1d0) 1d0)))
        (list (* s -1 r (cos ang)) (* s -1 r (sin ang)) 0.0d0))))

(defun %segment-closest (seg pt &optional extend-start extend-end)
  "(values POINT FRACTION) of the point of SEG nearest PT."
  (if (eq (getf seg :kind) :line)
      (let* ((a (getf seg :a)) (ab (%cg- (getf seg :b) a)) (l2 (%cg-dot ab ab)))
        (if (zerop l2)
            (values (copy-list a) 0.0d0)
            (let ((f (/ (%cg-dot (%cg- pt a) ab) l2)))
              (unless extend-start (setf f (max 0.0d0 f)))
              (unless extend-end (setf f (min 1.0d0 f)))
              (values (%cg+ a (%cg* ab f)) f))))
      (let* ((c (getf seg :center)) (th (getf seg :theta))
             (sweep (abs th))
             (ang (%cg-angle-of c pt))
             (delta (%cg-norm-angle (if (plusp th)
                                        (- ang (getf seg :a0))
                                        (- (getf seg :a0) ang)))))
        (if (<= delta sweep)
            (let ((f (/ delta sweep)))
              (values (%segment-point seg f) f))
            (if (< (%cg-dist pt (getf seg :a)) (%cg-dist pt (getf seg :b)))
                (values (copy-list (getf seg :a)) 0.0d0)
                (values (copy-list (getf seg :b)) 1.0d0))))))

;;; --- parsing ----------------------------------------------------------------

(defun %polyline-vertices-from-lwpolyline (dxf)
  "List of (point bulge) from an LWPOLYLINE's ordered 10/42 groups."
  (let ((z (%cg-d (or (%cg-ref dxf 38) 0))) (out '()))
    (dolist (pair dxf)
      (when (consp pair)
        (case (car pair)
          (10 (push (list (%cg-v (cdr pair) z) 0.0d0) out))
          (42 (when (and out (realp (cdr pair)))
                (setf (second (first out)) (%cg-d (cdr pair))))))))
    (nreverse out)))

(defun %polyline-vertices-from-vertex-dxfs (header vertex-dxfs)
  (let ((z (third (%cg-v (or (%cg-ref header 10) '(0 0 0))))))
    (loop for v in vertex-dxfs
          for flags = (let ((f (%cg-ref v 70))) (if (integerp f) f 0))
          unless (logbitp 4 flags)          ; spline frame control point
            collect (list (%cg-v (%cg-ref v 10) z) (%cg-d (or (%cg-ref v 42) 0))))))

(defun %make-polyline-curve (vertices closed subtype elevation product)
  (when (>= (length vertices) 2)
    (let ((segs (loop for (v w) on vertices while w
                      collect (make-curve-segment (first v) (first w) (second v)))))
      (when closed
        (let ((last (car (last vertices))))
          (setf segs (append segs (list (make-curve-segment
                                         (first last) (first (first vertices))
                                         (second last)))))))
      (list :type :polyline :segments segs :closed (and closed t)
            :subtype subtype :elevation elevation :product product))))

(defun parse-curve-dxf (dxf &optional vertex-dxfs (product (current-curve-product)))
  "Parse the entget DXF of a curve into a descriptor plist, or NIL when the
entity is not an analytically supported curve. VERTEX-DXFS are the entget
lists of a 2D/3D POLYLINE's VERTEX sub-entities. PRODUCT (:autocad or
:bricscad) selects the measured vendor behaviour."
  (let ((type (%cg-string (%cg-ref dxf 0))))
    (cond
      ((equal type "LINE")
       (let ((a (%cg-v (%cg-ref dxf 10))) (b (%cg-v (%cg-ref dxf 11))))
         (list :type :line :start a :end b :length (%cg-dist a b) :product product)))
      ((member type '("RAY" "XLINE") :test #'equal)
       (list :type (if (equal type "RAY") :ray :xline) :product product
             :base (%cg-v (%cg-ref dxf 10)) :dir (%cg-unit (%cg-v (%cg-ref dxf 11)))))
      ((equal type "CIRCLE")
       (list :type :circle :center (%cg-v (%cg-ref dxf 10)) :product product
             :radius (%cg-d (%cg-ref dxf 40))))
      ((equal type "ARC")
       ;; entget angles are RADIANS (only a DXF *file* stores degrees).
       ;; AutoCAD stores them normalised into [0, 2pi) (entmake normalises);
       ;; BricsCAD keeps an entmade angle as given and measures from it: the
       ;; start param is the stored start angle, the end param start +
       ;; (end - start) mod 2pi (measured: 50 = -pi/4, 51 = 7 -> params
       ;; -0.785398 .. 0.716815).
       (let* ((raw-s (%cg-d (%cg-ref dxf 50)))
              (raw-e (%cg-d (%cg-ref dxf 51)))
              (s (if (eq product :bricscad) raw-s (%cg-norm-angle raw-s)))
              (sweep (%cg-norm-angle (- raw-e raw-s))))
         (when (zerop sweep) (setf sweep +two-pi+))
         (list :type :arc :center (%cg-v (%cg-ref dxf 10)) :product product
               :radius (%cg-d (%cg-ref dxf 40)) :start-angle s :end-angle (+ s sweep)
               :raw-out-of-range (not (and (<= 0 raw-s) (< raw-s +two-pi+)
                                           (<= 0 raw-e) (< raw-e +two-pi+))))))
      ((equal type "LWPOLYLINE")
       (%make-polyline-curve (%polyline-vertices-from-lwpolyline dxf)
                             (logbitp 0 (let ((f (%cg-ref dxf 70))) (if (integerp f) f 0)))
                             :lwpolyline (%cg-d (or (%cg-ref dxf 38) 0)) product))
      ((equal type "POLYLINE")
       (let ((flags (let ((f (%cg-ref dxf 70))) (if (integerp f) f 0))))
         ;; polyface (64) and polygon mesh (16) are not curves
         (unless (or (logbitp 4 flags) (logbitp 6 flags))
           (%make-polyline-curve
            (%polyline-vertices-from-vertex-dxfs dxf vertex-dxfs)
            (logbitp 0 flags) :polyline
            (third (%cg-v (or (%cg-ref dxf 10) '(0 0 0)))) product))))
      (t nil))))

(defun host-curve-descriptor (host ename)
  "The curve descriptor of entity ENAME on HOST (entget, and for a heavy
POLYLINE the following VERTEX entities up to SEQEND), or NIL."
  (let ((dxf (host-entget host ename nil)))
    (when dxf
      (if (equal (%cg-string (%cg-ref dxf 0)) "POLYLINE")
          (let ((vertices '()))
            (loop for next = (host-entnext host ename) then (host-entnext host next)
                  for vdxf = (and next (host-entget host next nil))
                  while (and vdxf (equal (%cg-string (%cg-ref vdxf 0)) "VERTEX"))
                  do (push vdxf vertices))
            (parse-curve-dxf dxf (nreverse vertices)))
          (parse-curve-dxf dxf)))))

;;; --- queries ---------------------------------------------------------------

(defun curve-type (curve) (getf curve :type))

(defun %segments (curve) (getf curve :segments))

(defun curve-length (curve)
  (case (getf curve :type)
    (:line (getf curve :length))
    (:circle (* +two-pi+ (getf curve :radius)))
    (:arc (* (getf curve :radius) (- (getf curve :end-angle) (getf curve :start-angle))))
    (:polyline (reduce #'+ (%segments curve) :key (lambda (s) (getf s :len))
                                             :initial-value 0.0d0))
    (t nil)))

(defun curve-total-angle (curve)
  "The swept angle of an ARC (end - start, in (0, 2pi]) or 2pi for a CIRCLE."
  (case (getf curve :type)
    (:arc (- (getf curve :end-angle) (getf curve :start-angle)))
    (:circle +two-pi+)
    (t nil)))

(defun curve-start-param (curve)
  (case (getf curve :type)
    ((:line :circle :polyline :ray) 0.0d0)
    (:arc (getf curve :start-angle))
    (t nil)))

(defun curve-end-param (curve)
  (case (getf curve :type)
    (:line (getf curve :length))
    (:circle +two-pi+)
    (:arc (getf curve :end-angle))
    (:polyline (coerce (length (%segments curve)) 'double-float))
    (t nil)))

(defun %clamp-into (x lo hi scale)
  "X clamped onto [LO, HI] when within the tolerance, else NIL. A NIL bound
is unbounded."
  (let ((eps (* *curve-param-tolerance* (max 1.0d0 (abs scale)))))
    (cond ((and lo (< x (- lo eps))) nil)
          ((and hi (> x (+ hi eps))) nil)
          ((and lo (< x lo)) lo)
          ((and hi (> x hi)) hi)
          (t x))))

(defun %valid-param (curve p)
  "P clamped into the curve's parameter range, or NIL when outside."
  (let ((s (curve-start-param curve)) (e (curve-end-param curve)))
    (%clamp-into p s e (max (abs (or s 0)) (abs (or e 0))))))

(defun %arc-param-on-arc (curve p)
  "The parameter of angle P on an ARC, brought into [start, end] modulo 2pi,
or NIL when the angle is not on the arc. Measured on both vendors:
getPointAtParam of the ARC 315-45 deg at 0.1 answers the point at angle 0.1,
and at end + 0.5 answers nil."
  (let* ((s (getf curve :start-angle)) (e (getf curve :end-angle))
         (eps (* *curve-param-tolerance* (max 1d0 (abs s) (abs e)))))
    (cond ((<= (- s eps) p (+ e eps)) (max s (min e p)))
          (t (let ((q (+ s (%cg-norm-angle (- p s)))))
               (cond ((<= q (+ e eps)) (min q e))
                     ((>= q (- (+ s +two-pi+) eps)) s)
                     (t nil)))))))

(defun %polyline-locate (curve p)
  "(values SEGMENT FRACTION INDEX) of parameter P on a polyline."
  (let* ((segs (%segments curve)) (n (length segs))
         (i (max 0 (min (floor p) (1- n)))))
    (values (nth i segs) (- p i) i)))

(defun %heavy-autocad-p (curve)
  (and (eq (getf curve :type) :polyline)
       (eq (getf curve :subtype) :polyline)
       (not (%bricscad-p curve))))

(defun curve-point-at-param (curve param)
  "LINE / LWPOLYLINE: nil outside the range (both vendors). CIRCLE: any
angle. ARC: an angle on the arc modulo 2pi. AutoCAD's 2D POLYLINE
extrapolates BELOW its start along its first segment (measured at -0.5 on a
bulge segment: (5 5 0)), not above its end."
  (case (getf curve :type)
    (:circle (%cg-polar (getf curve :center) (getf curve :radius) param))
    (:arc (let ((p (%arc-param-on-arc curve param)))
            (and p (%cg-polar (getf curve :center) (getf curve :radius) p))))
    (t
     (let ((p (%valid-param curve param)))
       (cond
         (p
          (case (getf curve :type)
            (:line (%cg+ (getf curve :start)
                         (%cg* (%cg-unit (%cg- (getf curve :end) (getf curve :start))) p)))
            ((:ray :xline) (%cg+ (getf curve :base) (%cg* (getf curve :dir) p)))
            (:polyline (multiple-value-bind (seg f) (%polyline-locate curve p)
                         (%segment-point seg f)))))
         ((and (%heavy-autocad-p curve) (< param 0))
          (%segment-point (first (%segments curve)) param))
         (t nil))))))

(defun curve-start-point (curve)
  (let ((p (curve-start-param curve))) (and p (curve-point-at-param curve p))))

(defun curve-end-point (curve)
  (let ((p (curve-end-param curve))) (and p (curve-point-at-param curve p))))

(defun curve-dist-at-param (curve param)
  "LINE / CIRCLE: extrapolated (p, R*p) on both vendors. ARC: R*(p - start)
extrapolated on AutoCAD, nil outside [start, end] on BricsCAD. LWPOLYLINE:
nil outside. AutoCAD's 2D POLYLINE extrapolates below its start along the
first segment (measured -0.1 -> -0.1 * 5pi), nil above its end."
  (case (getf curve :type)
    ((:line :ray :xline) param)
    (:circle (* (getf curve :radius) param))
    (:arc (let ((p (if (%bricscad-p curve) (%valid-param curve param) param)))
            (and p (* (getf curve :radius) (- p (getf curve :start-angle))))))
    (:polyline
     (let ((p (%valid-param curve param)))
       (cond
         (p (multiple-value-bind (seg f i) (%polyline-locate curve p)
              (+ (reduce #'+ (subseq (%segments curve) 0 i)
                         :key (lambda (s) (getf s :len)) :initial-value 0.0d0)
                 (* f (getf seg :len)))))
         ((and (%heavy-autocad-p curve) (< param 0))
          (* param (getf (first (%segments curve)) :len)))
         (t nil))))
    (t nil)))

(defun %polyline-param-at-dist (curve d)
  (let ((acc 0.0d0) (segs (%segments curve)))
    (loop for seg in segs for i from 0
          for l = (getf seg :len)
          when (or (<= d (+ acc l)) (null (nthcdr (1+ i) segs)))
            do (return (+ i (if (zerop l) 0.0d0 (max 0d0 (min 1.0d0 (/ (- d acc) l))))))
          do (incf acc l))))

(defun curve-param-at-dist (curve dist)
  "LINE: extrapolated (both). CIRCLE: d/R, wrapped into [0, 2pi) on AutoCAD
(len + 1 -> 0.2 for R 5), extrapolated on BricsCAD (-1 -> -0.2). ARC:
start + d/R extrapolated on AutoCAD; on BricsCAD the same within a small
tolerance of the ends and the arc's LENGTH beyond it. LWPOLYLINE: clamped
within the tolerance, else nil on AutoCAD and the LENGTH on BricsCAD.
AutoCAD's 2D POLYLINE refuses a distance at or past its length (measured:
nil at exactly getDistAtParam of the end param)."
  (let ((len (curve-length curve))
        (bricscad (%bricscad-p curve)))
    (case (getf curve :type)
      (:line dist)
      (:ray (and (>= dist (- *curve-param-tolerance*)) (max 0d0 dist)))
      (:xline dist)
      (:circle (let ((p (/ dist (getf curve :radius))))
                 ;; AutoCAD: exactly 2pi stays 2pi (measured), beyond wraps
                 (if (or bricscad (<= 0 p +two-pi+)) p (%cg-norm-angle p))))
      (:arc
       (if (and bricscad
                (or (< dist (- *curve-bricscad-dist-tolerance*))
                    (> dist (+ len *curve-bricscad-dist-tolerance*))))
           len
           (+ (getf curve :start-angle) (/ dist (getf curve :radius)))))
      (:polyline
       (cond
         ((%heavy-autocad-p curve)
          (and (<= 0 dist) (< dist len) (%polyline-param-at-dist curve dist)))
         (t
          (let ((d (%clamp-into dist 0.0d0 len len)))
            (cond (d (%polyline-param-at-dist curve d))
                  (bricscad
                   (if (<= (- *curve-bricscad-dist-tolerance*) dist
                           (+ len *curve-bricscad-dist-tolerance*))
                       (%polyline-param-at-dist curve (max 0d0 (min len dist)))
                       len))
                  (t nil))))))
      (t nil))))

(defun curve-point-at-dist (curve dist)
  (let ((p (curve-param-at-dist curve dist)))
    (and p (curve-point-at-param curve p))))

(defun curve-first-deriv (curve param)
  "LINE: END - START whatever the param (both vendors; not the unit vector).
CIRCLE / ARC: R (-sin, cos). Polylines: see %SEGMENT-DERIV."
  (case (getf curve :type)
    (:line (and (%valid-param curve param) (%cg- (getf curve :end) (getf curve :start))))
    ((:ray :xline) (copy-list (getf curve :dir)))
    ((:circle :arc) (let ((r (getf curve :radius)))
                      (list (* (- r) (sin param)) (* r (cos param)) 0.0d0)))
    (:polyline (let ((p (%valid-param curve param)))
                 (and p (multiple-value-bind (seg f) (%polyline-locate curve p)
                          (%segment-deriv seg f)))))
    (t nil)))

(defun curve-second-deriv (curve param)
  "Polylines: see %SEGMENT-DERIV2. AutoCAD's LWPOLYLINE answers the
ELEVATION as the Z of its second derivative (measured: (0 0 5) on a
straight segment at elevation 5; BricsCAD (0 0 0))."
  (case (getf curve :type)
    ((:line :ray :xline) (list 0.0d0 0.0d0 0.0d0))
    ((:circle :arc) (let ((r (getf curve :radius)))
                      (list (* (- r) (cos param)) (* (- r) (sin param)) 0.0d0)))
    (:polyline
     (let ((p (%valid-param curve param)))
       (and p (multiple-value-bind (seg f) (%polyline-locate curve p)
                (let ((v (%segment-deriv2 seg f (getf curve :product))))
                  (when (and (not (%bricscad-p curve))
                             (eq (getf curve :subtype) :lwpolyline))
                    (setf (third v) (getf curve :elevation)))
                  v)))))
    (t nil)))

(defun %curve-plane-z (curve)
  (let ((start (case (getf curve :type)
                 (:line (getf curve :start))
                 ((:ray :xline) (getf curve :base))
                 ((:circle :arc) (getf curve :center))
                 (:polyline (getf (first (%segments curve)) :a)))))
    (if start (third start) 0.0d0)))

(defun %plane-point (curve pt)
  "PT as a 3D point. A 2D point takes the Z of the curve's plane on AutoCAD
and 0 on BricsCAD (measured on an LWPOLYLINE at elevation 5: (4 0) is on it
for AutoCAD, not for BricsCAD)."
  (%cg-v pt (if (%bricscad-p curve) 0.0d0 (%curve-plane-z curve))))

(defun %closest-and-param (curve pt extend)
  "(values POINT PARAM) of the curve point nearest PT (3D)."
  (case (getf curve :type)
    (:line
     (let* ((a (getf curve :start)) (len (getf curve :length)))
       (multiple-value-bind (cp f)
           (%segment-closest (list :kind :line :a a :b (getf curve :end)) pt extend extend)
         (values cp (* f len)))))
    (:ray
     (let* ((base (getf curve :base)) (dir (getf curve :dir))
            (p (%cg-dot (%cg- pt base) dir)))
       (unless extend (setf p (max 0.0d0 p)))
       (values (%cg+ base (%cg* dir p)) p)))
    (:xline
     (let* ((base (getf curve :base)) (dir (getf curve :dir))
            (p (%cg-dot (%cg- pt base) dir)))
       (values (%cg+ base (%cg* dir p)) p)))
    (:circle
     (let ((a (%cg-norm-angle (%cg-angle-of (getf curve :center) pt))))
       (values (%cg-polar (getf curve :center) (getf curve :radius) a) a)))
    (:arc
     (let* ((s (getf curve :start-angle)) (e (getf curve :end-angle))
            (a (+ s (%cg-norm-angle (- (%cg-angle-of (getf curve :center) pt) s)))))
       (cond ((or extend (<= a e))
              (values (%cg-polar (getf curve :center) (getf curve :radius) a) a))
             (t (let ((ps (%cg-polar (getf curve :center) (getf curve :radius) s))
                      (pe (%cg-polar (getf curve :center) (getf curve :radius) e)))
                  (if (< (%cg-dist pt ps) (%cg-dist pt pe))
                      (values ps s) (values pe e)))))))
    (:polyline
     ;; EXTEND: ignored on an LWPOLYLINE, honoured on the straight end
     ;; segments of a 2D POLYLINE (both vendors measured: (1000 1000 0) with
     ;; extend -> (10 10 0) on the LWPOLYLINE, (10 1000 0) on the POLYLINE).
     (let* ((best nil) (best-d nil) (best-p nil)
            (segs (%segments curve))
            (ext (and extend (eq (getf curve :subtype) :polyline)
                      (not (getf curve :closed)))))
       (loop for seg in segs for i from 0
             do (multiple-value-bind (cp f)
                    (%segment-closest seg pt (and ext (= i 0))
                                      (and ext (null (nthcdr (1+ i) segs))))
                  (let ((d (%cg-dist pt cp)))
                    ;; strict < keeps the first segment at a shared vertex
                    (when (or (null best-d) (< d (- best-d 1d-12)))
                      (setf best cp best-d d best-p (+ i f))))))
       (values best best-p)))
    (t (values nil nil))))

(defun curve-closest-point (curve pt &optional extend)
  (values (%closest-and-param curve (%plane-point curve pt) extend)))

(defparameter *curve-bricscad-lwpolyline-tolerance* 1d-6
  "BricsCAD's LWPOLYLINE accepts a point 1e-7 above its end vertex and
rejects one 1e-4 above (measured); the threshold in between is not.")

(defun %point-tolerance (curve pt)
  (max (if (and (%bricscad-p curve)
                (eq (getf curve :type) :polyline)
                (eq (getf curve :subtype) :lwpolyline))
           *curve-bricscad-lwpolyline-tolerance*
           *curve-point-tolerance*)
       (* 1d-14 (reduce #'max (mapcar #'abs pt) :initial-value 1d0))))

(defun curve-param-at-point (curve pt)
  "Parameter of PT when it lies on the curve, else NIL -- with the measured
vendor exceptions: AutoCAD's LWPOLYLINE ignores the Z of PT (1e-4 above
the end vertex answers the end param); BricsCAD answers 0 instead of nil
for a point off a LINE or a polyline lying in the plane Z = 0 (nil when
elevated); a CIRCLE point just below angle 0 answers 2pi - epsilon on
AutoCAD and 0 on BricsCAD."
  (let ((pt (%plane-point curve pt))
        (bricscad (%bricscad-p curve)))
    (when (and (not bricscad)
               (eq (getf curve :type) :polyline)
               (eq (getf curve :subtype) :lwpolyline))
      (setf pt (list (first pt) (second pt) (%curve-plane-z curve))))
    (multiple-value-bind (cp p) (%closest-and-param curve pt nil)
      (cond
        ((and cp (< (%cg-dist pt cp) (%point-tolerance curve pt)))
         (if (and bricscad (eq (getf curve :type) :circle)
                  (> p (- +two-pi+ 1d-10)))
             0.0d0
             p))
        ((and bricscad cp
              (member (getf curve :type) '(:line :polyline))
              (zerop (%curve-plane-z curve)))
         0.0d0)
        (t nil)))))

(defun curve-dist-at-point (curve pt)
  (let ((p (curve-param-at-point curve pt))) (and p (curve-dist-at-param curve p))))

(defun curve-closed-p (curve)
  (case (getf curve :type)
    (:circle t)
    (:polyline (getf curve :closed))
    (t nil)))

(defun curve-periodic-p (curve)
  "CIRCLE and closed polylines (measured T on both vendors)."
  (case (getf curve :type)
    (:circle t)
    (:polyline (getf curve :closed))
    (t nil)))

(defun curve-area (curve)
  "Enclosed area; an open curve is closed by the chord from its end to its
start (the vendor Area convention); a LINE has area 0. BricsCAD answers 0
for an ARC whose stored angles lie outside [0, 2pi) (measured)."
  (case (getf curve :type)
    (:line 0.0d0)
    (:circle (* pi (getf curve :radius) (getf curve :radius)))
    (:arc (if (and (%bricscad-p curve) (getf curve :raw-out-of-range))
              0.0d0
              (let ((r (getf curve :radius))
                    (dt (- (getf curve :end-angle) (getf curve :start-angle))))
                (* 0.5d0 r r (- dt (sin dt))))))
    (:polyline
     (let ((a 0.0d0))
       (dolist (seg (%segments curve))
         (let ((p (getf seg :a)) (q (getf seg :b)))
           (incf a (* 0.5d0 (- (* (first p) (second q)) (* (first q) (second p)))))
           (when (eq (getf seg :kind) :arc)
             (let ((th (getf seg :theta)) (r (getf seg :radius)))
               (incf a (* (signum th) 0.5d0 r r (- (abs th) (sin (abs th)))))))))
       (unless (getf curve :closed)         ; the closing chord
         (let ((p (getf (car (last (%segments curve))) :b))
               (q (getf (first (%segments curve)) :a)))
           (incf a (* 0.5d0 (- (* (first p) (second q)) (* (first q) (second p)))))))
       (abs a)))
    (t nil)))
