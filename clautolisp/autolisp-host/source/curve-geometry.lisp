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
;;;; Parameter conventions (the AutoCAD AcDbCurve ones, see the spec pages
;;;; of vlax-curve-getStartParam & co.):
;;;;   LINE        param = distance from the start point, 0 .. length;
;;;;   RAY / XLINE param = distance along the unit direction;
;;;;   CIRCLE      param = angle in radians, 0 .. 2pi;
;;;;   ARC         param = angle in radians, start angle .. end angle, the end
;;;;               angle raised by 2pi when it is not above the start angle;
;;;;   LWPOLYLINE / 2D / 3D POLYLINE
;;;;               param = vertex index + fraction of the segment, 0 .. n-1
;;;;               (open) or 0 .. n (closed); on a bulge (arc) segment the
;;;;               fraction is proportional to the swept angle, hence to the
;;;;               arc length.
;;;; Distances are arc lengths from the start of the curve: a bulge segment
;;;; contributes R * |theta|, theta = 4 * atan(bulge).
;;;;
;;;; Every function returns NIL when the quantity is undefined or the
;;;; argument is outside the curve (beyond a small tolerance; a value within
;;;; the tolerance of an end is clamped onto it).

(defparameter *curve-point-tolerance* 1d-6
  "Distance under which a point counts as lying on a curve.")

(defparameter *curve-param-tolerance* 1d-9
  "Relative slack accepted on a parameter or distance at a curve's ends.")

(defconstant +two-pi+ (* 2 pi))

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
  (if (eq (getf seg :kind) :line)
      (%cg+ (getf seg :a) (%cg* (%cg- (getf seg :b) (getf seg :a)) f))
      (if (>= f 1) (copy-list (getf seg :b))
          (if (<= f 0) (copy-list (getf seg :a))
              (%cg-polar (getf seg :center) (getf seg :radius)
                         (+ (getf seg :a0) (* f (getf seg :theta))))))))

(defun %segment-deriv (seg f)
  "d point / d param on SEG (param spans 1 over the segment)."
  (if (eq (getf seg :kind) :line)
      (%cg- (getf seg :b) (getf seg :a))
      (let* ((r (getf seg :radius)) (th (getf seg :theta))
             (ang (+ (getf seg :a0) (* f th))))
        (list (* -1 r th (sin ang)) (* r th (cos ang)) 0.0d0))))

(defun %segment-deriv2 (seg f)
  (if (eq (getf seg :kind) :line)
      (list 0.0d0 0.0d0 0.0d0)
      (let* ((r (getf seg :radius)) (th (getf seg :theta))
             (ang (+ (getf seg :a0) (* f th))))
        (list (* -1 r th th (cos ang)) (* -1 r th th (sin ang)) 0.0d0))))

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
            ;; outside the sweep: the nearer end point
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

(defun %make-polyline-curve (vertices closed)
  (when (>= (length vertices) 2)
    (let ((segs (loop for (v w) on vertices while w
                      collect (make-curve-segment (first v) (first w) (second v)))))
      (when closed
        (let ((last (car (last vertices))))
          (setf segs (append segs (list (make-curve-segment
                                         (first last) (first (first vertices))
                                         (second last)))))))
      (list :type :polyline :segments segs :closed (and closed t)))))

(defun parse-curve-dxf (dxf &optional vertex-dxfs)
  "Parse the entget DXF of a curve into a descriptor plist, or NIL when the
entity is not an analytically supported curve. VERTEX-DXFS are the entget
lists of a 2D/3D POLYLINE's VERTEX sub-entities."
  (let ((type (%cg-string (%cg-ref dxf 0))))
    (cond
      ((equal type "LINE")
       (let ((a (%cg-v (%cg-ref dxf 10))) (b (%cg-v (%cg-ref dxf 11))))
         (list :type :line :start a :end b :length (%cg-dist a b))))
      ((member type '("RAY" "XLINE") :test #'equal)
       (list :type (if (equal type "RAY") :ray :xline)
             :base (%cg-v (%cg-ref dxf 10)) :dir (%cg-unit (%cg-v (%cg-ref dxf 11)))))
      ((equal type "CIRCLE")
       (list :type :circle :center (%cg-v (%cg-ref dxf 10))
             :radius (%cg-d (%cg-ref dxf 40))))
      ((equal type "ARC")
       ;; entget angles are RADIANS (only a DXF *file* stores degrees).
       (let* ((s (%cg-norm-angle (%cg-d (%cg-ref dxf 50))))
              (e (%cg-norm-angle (%cg-d (%cg-ref dxf 51)))))
         (when (<= e s) (incf e +two-pi+))
         (list :type :arc :center (%cg-v (%cg-ref dxf 10))
               :radius (%cg-d (%cg-ref dxf 40)) :start-angle s :end-angle e)))
      ((equal type "LWPOLYLINE")
       (%make-polyline-curve (%polyline-vertices-from-lwpolyline dxf)
                             (logbitp 0 (let ((f (%cg-ref dxf 70))) (if (integerp f) f 0)))))
      ((equal type "POLYLINE")
       (let ((flags (let ((f (%cg-ref dxf 70))) (if (integerp f) f 0))))
         ;; polyface (64) and polygon mesh (16) are not curves
         (unless (or (logbitp 4 flags) (logbitp 6 flags))
           (%make-polyline-curve
            (%polyline-vertices-from-vertex-dxfs dxf vertex-dxfs)
            (logbitp 0 flags)))))
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

(defun %polyline-locate (curve p)
  "(values SEGMENT FRACTION INDEX) of parameter P on a polyline."
  (let* ((segs (%segments curve)) (n (length segs))
         (i (min (floor p) (1- n))))
    (values (nth i segs) (- p i) i)))

(defun curve-point-at-param (curve param)
  (let ((p (%valid-param curve param)))
    (when p
      (case (getf curve :type)
        (:line (%cg+ (getf curve :start)
                     (%cg* (%cg-unit (%cg- (getf curve :end) (getf curve :start))) p)))
        ((:ray :xline) (%cg+ (getf curve :base) (%cg* (getf curve :dir) p)))
        ((:circle :arc) (%cg-polar (getf curve :center) (getf curve :radius) p))
        (:polyline (multiple-value-bind (seg f) (%polyline-locate curve p)
                     (%segment-point seg f)))))))

(defun curve-start-point (curve)
  (let ((p (curve-start-param curve))) (and p (curve-point-at-param curve p))))

(defun curve-end-point (curve)
  (let ((p (curve-end-param curve))) (and p (curve-point-at-param curve p))))

(defun curve-dist-at-param (curve param)
  (let ((p (%valid-param curve param)))
    (when p
      (case (getf curve :type)
        ((:line :ray :xline) p)
        (:circle (* (getf curve :radius) p))
        (:arc (* (getf curve :radius) (- p (getf curve :start-angle))))
        (:polyline
         (multiple-value-bind (seg f i) (%polyline-locate curve p)
           (+ (reduce #'+ (subseq (%segments curve) 0 i)
                      :key (lambda (s) (getf s :len)) :initial-value 0.0d0)
              (* f (getf seg :len)))))))))

(defun curve-param-at-dist (curve dist)
  (let* ((len (curve-length curve))
         (d (case (getf curve :type)
              (:ray (%clamp-into dist 0.0d0 nil 1.0d0))
              (:xline dist)
              (t (and len (%clamp-into dist 0.0d0 len len))))))
    (when d
      (case (getf curve :type)
        ((:line :ray :xline) d)
        (:circle (/ d (getf curve :radius)))
        (:arc (+ (getf curve :start-angle) (/ d (getf curve :radius))))
        (:polyline
         (let ((acc 0.0d0) (segs (%segments curve)))
           (loop for seg in segs for i from 0
                 for l = (getf seg :len)
                 when (or (<= d (+ acc l)) (null (rest (nthcdr i segs))))
                   do (return (+ i (if (zerop l) 0.0d0 (min 1.0d0 (/ (- d acc) l)))))
                 do (incf acc l))))))))

(defun curve-point-at-dist (curve dist)
  (let ((p (curve-param-at-dist curve dist))) (and p (curve-point-at-param curve p))))

(defun curve-first-deriv (curve param)
  (let ((p (%valid-param curve param)))
    (when p
      (case (getf curve :type)
        (:line (%cg-unit (%cg- (getf curve :end) (getf curve :start))))
        ((:ray :xline) (copy-list (getf curve :dir)))
        ((:circle :arc) (let ((r (getf curve :radius)))
                          (list (* (- r) (sin p)) (* r (cos p)) 0.0d0)))
        (:polyline (multiple-value-bind (seg f) (%polyline-locate curve p)
                     (%segment-deriv seg f)))))))

(defun curve-second-deriv (curve param)
  (let ((p (%valid-param curve param)))
    (when p
      (case (getf curve :type)
        ((:line :ray :xline) (list 0.0d0 0.0d0 0.0d0))
        ((:circle :arc) (let ((r (getf curve :radius)))
                          (list (* (- r) (cos p)) (* (- r) (sin p)) 0.0d0)))
        (:polyline (multiple-value-bind (seg f) (%polyline-locate curve p)
                     (%segment-deriv2 seg f)))))))

(defun %plane-point (curve pt)
  "PT as a 3D point; a 2D point takes the Z of the curve's start."
  (let ((start (case (getf curve :type)
                 (:line (getf curve :start))
                 ((:ray :xline) (getf curve :base))
                 ((:circle :arc) (getf curve :center))
                 (:polyline (getf (first (%segments curve)) :a)))))
    (%cg-v pt (if start (third start) 0.0d0))))

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
             (t (let ((ps (curve-point-at-param curve s))
                      (pe (curve-point-at-param curve e)))
                  (if (< (%cg-dist pt ps) (%cg-dist pt pe))
                      (values ps s) (values pe e)))))))
    (:polyline
     (let ((best nil) (best-d nil) (best-p nil)
           (segs (%segments curve)))
       (loop for seg in segs for i from 0
             do (multiple-value-bind (cp f)
                    (%segment-closest seg pt
                                      (and extend (= i 0) (not (getf curve :closed)))
                                      (and extend (null (nthcdr (1+ i) segs))
                                           (not (getf curve :closed))))
                  (let ((d (%cg-dist pt cp)))
                    ;; strict < keeps the first segment at a shared vertex
                    (when (or (null best-d) (< d (- best-d 1d-12)))
                      (setf best cp best-d d best-p (+ i f))))))
       (values best best-p)))
    (t (values nil nil))))

(defun curve-closest-point (curve pt &optional extend)
  (values (%closest-and-param curve (%plane-point curve pt) extend)))

(defun curve-param-at-point (curve pt)
  "Parameter of PT when it lies on the curve (within *curve-point-tolerance*),
else NIL."
  (let ((pt (%plane-point curve pt)))
    (multiple-value-bind (cp p) (%closest-and-param curve pt nil)
      (when (and cp (< (%cg-dist pt cp) *curve-point-tolerance*))
        (if (and (eq (getf curve :type) :circle)
                 (> p (- +two-pi+ 1d-12)))
            0.0d0
            p)))))

(defun curve-dist-at-point (curve pt)
  (let ((p (curve-param-at-point curve pt))) (and p (curve-dist-at-param curve p))))

(defun curve-closed-p (curve)
  (case (getf curve :type)
    (:circle t)
    (:polyline (getf curve :closed))
    (t nil)))

(defun curve-periodic-p (curve)
  (eq (getf curve :type) :circle))

(defun curve-area (curve)
  "Enclosed area; an open curve is closed by the chord from its end to its
start (the vendor Area convention)."
  (case (getf curve :type)
    (:circle (* pi (getf curve :radius) (getf curve :radius)))
    (:arc (let ((r (getf curve :radius))
                (dt (- (getf curve :end-angle) (getf curve :start-angle))))
            (* 0.5d0 r r (- dt (sin dt)))))
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
