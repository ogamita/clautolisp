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
