(in-package #:clautolisp.cador)

;;;; Geometry the command engine selects and edits by (alref Phase 4 S2).
;;;;
;;;; An entity's OUTLINE is a list of 2D segments: exact for lines and
;;;; straight polyline spans, a fine polygon for circles, arcs, ellipses
;;;; and bulged spans, and the bounding box as a last resort. Window
;;;; selection, crossing selection and picking an object by a point on it
;;;; are all answered from the outline.

(defun %v- (a b) (mapcar #'- a b))

(defun %v+ (a b) (mapcar #'+ a b))

(defun %v* (k v) (mapcar (lambda (x) (* k x)) v))

(defun %vlen (v) (sqrt (reduce #'+ (mapcar (lambda (x) (* x x)) v))))

(defun %vunit (v)
  (let ((l (%vlen v)))
    (if (zerop l) v (%v* (/ 1.0d0 l) v))))

(defparameter *outline-arc-steps* 72
  "Segments per full turn when a curve is approximated by its outline.")

(defparameter *pick-tolerance* 1d-3
  "How far (drawing units) a picked point may lie from an object's outline.
The vendors use PICKBOX pixels; headless there are no pixels, and a point
ON the object -- what a driven command supplies -- is within this.")

(defun %num (x) (coerce x 'double-float))

(defun %xy (p) (list (%num (first p)) (%num (second p))))

(defun %arc-points (cx cy r a0 a1)
  "Points along the arc from A0 to A1 (radians, counter-clockwise)."
  (let* ((sweep (let ((s (- a1 a0))) (if (<= s 0) (+ s (* 2 pi)) s)))
         (n (max 2 (ceiling (* *outline-arc-steps* (/ sweep (* 2 pi)))))))
    (loop for i from 0 to n
          for a = (+ a0 (* sweep (/ i n)))
          collect (list (+ cx (* r (cos a))) (+ cy (* r (sin a)))))))

(defun %bulge-points (p q bulge)
  "Points along the span P->Q with BULGE (tan of a quarter of the sweep)."
  (if (< (abs bulge) 1d-12)
      (list p q)
      (let* ((sweep (* 4 (atan bulge)))
             (chord (%vlen (%v- q p)))
             (r (/ chord (* 2 (sin (/ sweep 2)))))
             (mid (%v* 0.5d0 (%v+ p q)))
             (dir (%vunit (%v- q p)))
             (normal (list (- (second dir)) (first dir)))
             (h (* r (cos (/ sweep 2))))
             (c (%v+ mid (%v* h normal)))
             (a0 (atan (- (second p) (second c)) (- (first p) (first c))))
             (n (max 2 (ceiling (* *outline-arc-steps* (/ (abs sweep) (* 2 pi)))))))
        (loop for i from 0 to n
              for a = (+ a0 (* sweep (/ i n)))
              collect (list (+ (first c) (* (abs r) (cos a)))
                            (+ (second c) (* (abs r) (sin a))))))))

(defun %polyline-outline-points (pairs closed)
  "Vertex/bulge PAIRS -> the outline's point chain."
  (let ((spans (if closed (append pairs (list (first pairs))) pairs))
        (points '()))
    (loop for ((p . b) (q . nil)) on spans while q
          do (let ((pts (%bulge-points p q (or b 0.0d0))))
               (setf points (append points (if points (rest pts) pts)))))
    (or points (mapcar #'car pairs))))

(defun %chain->segments (points)
  (loop for (a b) on points while b collect (list a b)))

(defun %entity-outline (host entity)
  "ENTITY's outline as a list of 2D segments ((x y) (x y))."
  (let ((data (entity-handle-data entity)))
    (flet ((g (code &optional default)
             (let ((cell (assoc code data :test #'group-code-equal-p)))
               (if cell (cdr cell) default))))
      (case (entity-handle-kind entity)
        (:line (list (list (%xy (g 10)) (%xy (g 11)))))
        (:point (let ((p (%xy (g 10)))) (list (list p p))))
        (:circle (let ((c (%xy (g 10))))
                   (%chain->segments (%arc-points (first c) (second c) (%num (g 40))
                                                  0.0d0 (* 2 pi)))))
        (:arc (let ((c (%xy (g 10))))
                (%chain->segments (%arc-points (first c) (second c) (%num (g 40))
                                               (%num (g 50)) (%num (g 51))))))
        (:lwpolyline
         (let ((pairs '()) (closed (logtest 1 (or (g 70) 0))))
           (dolist (pair data)
             (when (consp pair)
               (cond ((group-code-equal-p (car pair) 10)
                      (push (cons (%xy (cdr pair)) 0.0d0) pairs))
                     ((and pairs (group-code-equal-p (car pair) 42))
                      (setf (cdr (first pairs)) (%num (cdr pair)))))))
           (%chain->segments (%polyline-outline-points (nreverse pairs) closed))))
        (t
         ;; Anything else: the bounding box's rectangle.
         (destructuring-bind ((x0 y0 &rest r0) (x1 y1 &rest r1))
             (%entity-bounding-box host entity)
           (declare (ignore r0 r1))
           (%chain->segments (list (list x0 y0) (list x1 y0) (list x1 y1)
                                   (list x0 y1) (list x0 y0)))))))))

(defun %point-in-rect-p (p x0 y0 x1 y1)
  (and (<= x0 (first p) x1) (<= y0 (second p) y1)))

(defun %segments-intersect-p (a b c d)
  "Whether the closed 2D segments AB and CD meet."
  (flet ((orient (p q r)
           (let ((v (- (* (- (first q) (first p)) (- (second r) (second p)))
                       (* (- (second q) (second p)) (- (first r) (first p))))))
             (cond ((> v 1d-12) 1) ((< v -1d-12) -1) (t 0))))
         (on (p q r)
           (and (<= (min (first p) (first q)) (first r) (max (first p) (first q)))
                (<= (min (second p) (second q)) (second r) (max (second p) (second q))))))
    (let ((o1 (orient a b c)) (o2 (orient a b d))
          (o3 (orient c d a)) (o4 (orient c d b)))
      (or (and (/= o1 o2) (/= o3 o4))
          (and (zerop o1) (on a b c)) (and (zerop o2) (on a b d))
          (and (zerop o3) (on c d a)) (and (zerop o4) (on c d b))))))

(defun %rect-corners (p1 p2)
  (values (min (first p1) (first p2)) (min (second p1) (second p2))
          (max (first p1) (first p2)) (max (second p1) (second p2))))

(defun %outline-in-window-p (outline p1 p2)
  "Window selection: the whole outline lies inside the rectangle."
  (multiple-value-bind (x0 y0 x1 y1) (%rect-corners p1 p2)
    (every (lambda (s) (and (%point-in-rect-p (first s) x0 y0 x1 y1)
                            (%point-in-rect-p (second s) x0 y0 x1 y1)))
           outline)))

(defun %outline-crosses-window-p (outline p1 p2)
  "Crossing selection: any of the outline inside, or crossing an edge."
  (multiple-value-bind (x0 y0 x1 y1) (%rect-corners p1 p2)
    (let ((edges (%chain->segments (list (list x0 y0) (list x1 y0) (list x1 y1)
                                         (list x0 y1) (list x0 y0)))))
      (some (lambda (s)
              (or (%point-in-rect-p (first s) x0 y0 x1 y1)
                  (%point-in-rect-p (second s) x0 y0 x1 y1)
                  (some (lambda (e) (%segments-intersect-p (first s) (second s)
                                                           (first e) (second e)))
                        edges)))
            outline))))

(defun %point-segment-distance (p a b)
  (let* ((ab (%v- b a)) (ap (%v- p a))
         (len2 (reduce #'+ (mapcar #'* ab ab)))
         (tt (if (zerop len2) 0 (max 0 (min 1 (/ (reduce #'+ (mapcar #'* ap ab)) len2))))))
    (%vlen (%v- p (%v+ a (%v* tt ab))))))

(defun %entity-point-distance (host entity p)
  "Distance from the 2D point P to ENTITY: exact for circles and arcs
\(their outline is only a polygon), from the outline otherwise."
  (let ((data (entity-handle-data entity)) (p (%xy p)))
    (flet ((g (code) (cdr (assoc code data :test #'group-code-equal-p))))
      (case (entity-handle-kind entity)
        (:circle (abs (- (%vlen (%v- p (%xy (g 10)))) (%num (g 40)))))
        (:arc
         (let* ((c (%xy (g 10)))
                (a (atan (- (second p) (second c)) (- (first p) (first c))))
                (a0 (%num (g 50))) (a1 (%num (g 51)))
                (in (let ((s (mod (- a a0) (* 2 pi))) (e (mod (- a1 a0) (* 2 pi))))
                      (<= s e))))
           (if in
               (abs (- (%vlen (%v- p c)) (%num (g 40))))
               (reduce #'min (mapcar (lambda (s) (min (%vlen (%v- p (first s)))
                                                      (%vlen (%v- p (second s)))))
                                     (%entity-outline host entity))))))
        (t (reduce #'min (mapcar (lambda (s) (%point-segment-distance p (first s) (second s)))
                                 (%entity-outline host entity))
                   :initial-value most-positive-double-float))))))

(defun %selectable-entities (host)
  "Live main-space entities (no subentities), NEWEST first -- the vendors
pick the topmost of objects under the pick point."
  (let ((drawing (cador-active-drawing host)))
    (loop for handle in (clautolisp.drawing:drawing-creation-order drawing)
          for entity = (clautolisp.drawing:find-entity drawing handle)
          when (and entity
                    (not (entity-handle-deleted-p entity))
                    (main-space-entity-p entity)
                    (not (member (entity-handle-kind entity) '(:attrib :vertex :seqend))))
            collect entity)))

(defun %pick-entity (host point)
  "The newest entity whose outline passes within *PICK-TOLERANCE* of POINT."
  (find-if (lambda (e) (<= (%entity-point-distance host e point) *pick-tolerance*))
           (%selectable-entities host)))

(defun %window-selection (host p1 p2 crossing)
  (remove-if-not (lambda (e)
                   (let ((outline (%entity-outline host e)))
                     (if crossing
                         (%outline-crosses-window-p outline p1 p2)
                         (%outline-in-window-p outline p1 p2))))
                 (reverse (%selectable-entities host))))
