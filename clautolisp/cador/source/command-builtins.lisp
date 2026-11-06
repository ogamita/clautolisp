(in-package #:clautolisp.cador)

;;;; alref Phase 4, the built-ins left after S6 (2026-10-04): XPLODE,
;;;; ROTATE3D / 3DROTATE, ARRAYPATH, SPLINEDIT; ARRAYCLASSIC recognised.
;;;;
;;;; Inputs from the vendors' documented command-line prompts (AutoCAD
;;;; 2022 help, BricsCAD V17/V18/V26 command reference); results measured
;;;; by probes/sources/probe-commands.lsp (BricsCAD V26 job 16920731857,
;;;; AutoCAD 2022 job 16920731856):
;;;;   XPLODE      a rectangle with the defaults -> its 4 LINEs (BricsCAD;
;;;;               AutoCAD's console lacks XPLODE)
;;;;   ROTATE3D    (1,0)-(3,0) about Z through the origin, 90 -> (0,1)-(0,3)
;;;;               (both); 3DROTATE by axis keyword the same (BricsCAD --
;;;;               AutoCAD's axis is a gizmo pick)
;;;;   ARRAYPATH   a circle along (0,0)-(9,0), divide 4, non-associative ->
;;;;               the source replaced by circles at 0 3 6 9 (BricsCAD;
;;;;               AutoCAD left the input unanswered)
;;;;   SPLINEDIT   Reverse: control and fit points reversed (BricsCAD;
;;;;               AutoCAD unanswered). Close: identical on both -- the
;;;;               closed cubic through the fit points and back to the
;;;;               first, chord-length knots, clamped, with equal first and
;;;;               second derivatives at the join; the fit data dropped;
;;;;               flags + 1 + 2 + 2048.

;;; --- XPLODE ---------------------------------------------------------------
;;; Selection, RETURN; BricsCAD then asks Separately /<All>, and both ask
;;; for the property option with the default "explode" (AutoCAD E(xplode),
;;; BricsCAD X(plode)). RETURNs take the defaults, which explode as EXPLODE.

(defun %cmd-xplode (host tokens)
  (multiple-value-bind (entities rest) (%command-selection host tokens)
    (loop repeat (if (%command-bricscad-p) 2 1)
          while (or (equal (first rest) "")
                    (%command-option-p (first rest) "a" "all" "s" "separately"
                                       "i" "individually" "g" "globally"
                                       "x" "xplode" "e" "explode"))
          do (pop rest))
    (dolist (e entities)
      (case (entity-handle-kind e)
        (:lwpolyline (%explode-lwpolyline host e))))
    rest))

;;; --- ROTATE3D / 3DROTATE -------------------------------------------------
;;; Selection, RETURN, the axis (Xaxis / Yaxis / Zaxis, then a point on it;
;;; or two points), the angle in degrees.

(defun %rotate-point-about-axis (p origin axis angle)
  "P turned by ANGLE (radians) about the line through ORIGIN along the unit
vector AXIS (Rodrigues)."
  (let* ((v (%v- p origin))
         (c (cos angle)) (s (sin angle))
         (k axis)
         (kxv (list (- (* (second k) (third v)) (* (third k) (second v)))
                    (- (* (third k) (first v)) (* (first k) (third v)))
                    (- (* (first k) (second v)) (* (second k) (first v)))))
         (kdv (reduce #'+ (mapcar #'* k v))))
    (%v+ origin (mapcar (lambda (vi kxvi ki) (+ (* vi c) (* kxvi s) (* ki kdv (- 1 c))))
                        v kxv k))))

(defun %entity-rotate-3d (entity origin axis angle)
  "Turn ENTITY about an arbitrary axis: about Z (or -Z) as ROTATE does, so
angles and directions follow; otherwise every 3D point group (10-18)."
  (let ((z (third axis)))
    (if (and (< (abs (first axis)) 1d-12) (< (abs (second axis)) 1d-12))
        (%entity-rotate-one entity (first origin) (second origin)
                            (if (minusp z) (- angle) angle))
        (dolist (pair (entity-handle-data entity))
          (when (and (consp pair) (integerp (car pair)) (<= 10 (car pair) 18)
                     (consp (cdr pair)) (= 3 (length (cdr pair))))
            (setf (cdr pair) (%rotate-point-about-axis
                              (mapcar #'%num (cdr pair)) origin axis angle)))))))

(defun %cmd-rotate3d (host tokens)
  (multiple-value-bind (entities rest) (%command-selection host tokens)
    (let ((axis nil) (origin nil))
      (cond ((%command-option-p (first rest) "x" "xaxis")
             (pop rest) (setf axis '(1d0 0d0 0d0)))
            ((%command-option-p (first rest) "y" "yaxis")
             (pop rest) (setf axis '(0d0 1d0 0d0)))
            ((%command-option-p (first rest) "z" "zaxis")
             (pop rest) (setf axis '(0d0 0d0 1d0))))
      (if axis
          (let ((p (%command-token-point (first rest))))
            (setf origin (if p (progn (pop rest) (mapcar #'%num p)) '(0d0 0d0 0d0))))
          (progn
            (when (%command-option-p (first rest) "2" "2points") (pop rest))
            (let ((a (%command-token-point (first rest)))
                  (b (%command-token-point (second rest))))
              (when (and a b)
                (setf rest (cddr rest)
                      origin (mapcar #'%num a)
                      axis (%vunit (%v- (mapcar #'%num b) origin)))))))
      (let ((angle (%command-token-number (first rest))))
        (when (and axis angle)
          (pop rest)
          (dolist (e entities)
            (%entity-rotate-3d e origin axis (* (%num angle) (/ pi 180)))))))
    rest))

;;; --- ARRAYPATH ------------------------------------------------------------
;;; Selection, RETURN, the path, then options until eXit / RETURN:
;;; ASsociative (Yes / No: modelled non-associative), Method (Divide /
;;; Measure), Base point, Items (Divide: the count; Measure: the distance,
;;; then the count), Align items (Yes / No). The copies are laid with the
;;; selection's base point (its bounding-box centre) on the path points, and
;;; the source is erased (measured: BricsCAD lists the path, then the 4 new
;;; circles).

(defun %selection-centre (host entities)
  (let ((boxes (mapcar (lambda (e) (%entity-bounding-box host e)) entities)))
    (list (/ (+ (reduce #'min (mapcar #'caar boxes)) (reduce #'max (mapcar #'caadr boxes))) 2)
          (/ (+ (reduce #'min (mapcar #'cadar boxes)) (reduce #'max (mapcar #'cadadr boxes))) 2))))

(defun %cmd-arraypath (host tokens)
  (multiple-value-bind (entities rest) (%command-selection host tokens)
    (multiple-value-bind (path pick more) (%take-pick host rest)
      (declare (ignore pick))
      (unless (and entities path)
        (return-from %cmd-arraypath (%consume-through-return rest)))
      (setf rest more)
      (let ((method :measure) (count nil) (distance nil) (base nil) (align t))
        (loop
          (let ((token (first rest)))
            (cond ((or (null rest) (equal token "") (%command-option-p token "x" "exit"))
                   (when rest (pop rest)) (return))
                  ((%command-option-p token "as" "associative")
                   (pop rest)
                   (when (%command-option-p (first rest) "y" "yes" "n" "no") (pop rest)))
                  ((%command-option-p token "m" "method")
                   (pop rest)
                   (cond ((%command-option-p (first rest) "d" "divide") (pop rest) (setf method :divide))
                         ((%command-option-p (first rest) "m" "measure") (pop rest) (setf method :measure))))
                  ((%command-option-p token "b" "base" "basepoint")
                   (pop rest)
                   (let ((p (%command-token-point (first rest))))
                     (when p (pop rest) (setf base (%xy p)))))
                  ((%command-option-p token "i" "items")
                   (pop rest)
                   (let ((n (%command-token-number (first rest))))
                     (when n
                       (pop rest)
                       (if (eq method :divide)
                           (setf count (round n))
                           (progn
                             (setf distance (%num n))
                             (let ((c (%command-token-number (first rest))))
                               (when c (pop rest) (setf count (round c)))))))))
                  ((%command-option-p token "a" "align" "alignitems")
                   (pop rest)
                   (cond ((%command-option-p (first rest) "y" "yes") (pop rest) (setf align t))
                         ((%command-option-p (first rest) "n" "no") (pop rest) (setf align nil))))
                  (t (return)))))
        (let* ((segments (%entity-outline host path))
               (length (%outline-length segments))
               (n (or count
                      (if distance (1+ (floor (+ length 1d-9) distance)) 1)))
               (step (cond ((eq method :divide) (if (> n 1) (/ length (1- n)) 0))
                           (distance distance)
                           (t (if (> n 1) (/ length (1- n)) 0))))
               (origin (or base (%selection-centre host entities)))
               (start-angle (%path-tangent-angle segments 0)))
          (dotimes (i n)
            (let* ((d (min length (* i step)))
                   (p (%point-at-length segments d))
                   (turn (if align (- (%path-tangent-angle segments d) start-angle) 0)))
              (dolist (e entities)
                (let ((copy (%clone-entity-with-run host e)))
                  (%entity-translate copy (- (first p) (first origin)) (- (second p) (second origin)) 0)
                  (unless (zerop turn)
                    (%entity-rotate-one copy (first p) (second p) turn))))))
          (dolist (e entities) (%erase-entity-and-run host e)))))
    rest))

(defun %path-tangent-angle (segments d)
  "The direction (radians) of the outline SEGMENTS at length D."
  (loop for (a b) in segments
        for len = (%vlen (%v- b a))
        do (if (or (<= d len) (zerop len))
               (return (atan (- (second b) (second a)) (- (first b) (first a))))
               (decf d len))
        finally (let ((s (car (last segments))))
                  (return (atan (- (second (second s)) (second (first s)))
                                (- (first (second s)) (first (first s))))))))

;;; --- SPLINEDIT -------------------------------------------------------------
;;; The spline, then options until eXit / RETURN: Close / Open, Reverse.

(defun %spline-groups (data code)
  (loop for (c . v) in data when (eql c code) collect v))

(defun %first-derivative-row (n knots p i)
  "Coefficients over the N control points of Q_I, the I-th control point
of the spline's first derivative."
  (let ((row (make-array n :initial-element 0.0d0))
        (s (/ p (- (aref knots (+ i p 1)) (aref knots (1+ i))))))
    (incf (aref row (1+ i)) s)
    (decf (aref row i) s)
    row))

(defun %fit-closed-spline (fit)
  "Knots and control points of the closed cubic through FIT and back to its
first point: clamped, chord-length knots, first and second derivatives
equal at the join (measured on both vendors)."
  (let* ((p 3)
         (closed (append fit (list (first fit))))
         (params (let ((acc (list 0.0d0)))
                   (loop for (a b) on closed while b
                         do (push (+ (first acc) (%vlen (%v- b a))) acc))
                   (nreverse acc)))
         (last-u (car (last params)))
         (knots (coerce (append (make-list 4 :initial-element 0.0d0)
                                (butlast (rest params))
                                (make-list 4 :initial-element last-u))
                        'vector))
         (n (+ (length closed) 2))
         (rows (append (loop for u in params
                             collect (let ((row (make-array n)))
                                       (dotimes (i n)
                                         (setf (aref row i) (%bspline-basis i p u knots)))
                                       row))
                       (list (map 'vector #'- (%first-derivative-row n knots p 0)
                                  (%first-derivative-row n knots p (- n 2)))
                             (map 'vector #'- (%second-derivative-row n knots p 0)
                                  (%second-derivative-row n knots p (- n 3)))))))
    (values knots
            (let ((coords (loop for axis below 3
                                collect (%solve-linear
                                         rows
                                         (append (mapcar (lambda (pt) (%num (or (nth axis pt) 0))) closed)
                                                 (list 0.0d0 0.0d0))))))
              (apply #'mapcar #'list coords)))))

(defun %spline-close (e)
  (let* ((data (entity-handle-data e))
         (fit (mapcar (lambda (f) (mapcar #'%num f)) (%spline-groups data 11))))
    (when (>= (length fit) 3)
      (multiple-value-bind (knots controls) (%fit-closed-spline fit)
        (let ((head (loop for pair in data
                          until (and (consp pair) (member (car pair) '(70 71 72 73 74 42 43 44 12 13 40 10 11)))
                          collect pair)))
          (setf (entity-handle-data e)
                (append head
                        (list (cons 70 (logior (or (cdr (assoc 70 data)) 0) 1 2 2048))
                              (cons 71 3) (cons 72 (length knots)) (cons 73 (length controls))
                              (cons 74 0))
                        (remove nil (list (assoc 42 data) (assoc 43 data)))
                        (map 'list (lambda (k) (cons 40 k)) knots)
                        (mapcar (lambda (c) (cons 10 c)) controls))))))))

(defun %spline-reverse (e)
  (let* ((data (entity-handle-data e))
         (knots (%spline-groups data 40))
         (k0 (if knots (reduce #'min knots) 0)) (k1 (if knots (reduce #'max knots) 0))
         (rknots (reverse (mapcar (lambda (k) (- (+ k0 k1) k)) knots)))
         (controls (reverse (%spline-groups data 10)))
         (fits (reverse (%spline-groups data 11))))
    (setf (entity-handle-data e)
          (loop for pair in data
                collect (if (consp pair)
                            (case (car pair)
                              (40 (cons 40 (pop rknots)))
                              (10 (cons 10 (pop controls)))
                              (11 (cons 11 (pop fits)))
                              (t pair))
                            pair)))))

(defun %cmd-splinedit (host tokens)
  (multiple-value-bind (e pick rest) (%take-pick host tokens)
    (declare (ignore pick))
    (unless (and e (eq (entity-handle-kind e) :spline))
      (return-from %cmd-splinedit (%consume-through-return tokens)))
    (loop
      (let ((token (first rest)))
        (cond ((or (null rest) (equal token "") (%command-option-p token "x" "exit"))
               (when rest (pop rest)) (return))
              ((%command-option-p token "c" "close") (pop rest) (%spline-close e))
              ((%command-option-p token "r" "reverse") (pop rest) (%spline-reverse e))
              (t (return)))))
    rest))

(define-cador-command "XPLODE" '%cmd-xplode)
(define-cador-command '("ROTATE3D" "3DROTATE") '%cmd-rotate3d)
(define-cador-command "ARRAYPATH" '%cmd-arraypath)
(define-cador-command "SPLINEDIT" '%cmd-splinedit)
;; ARRAYCLASSIC is a dialog on both vendors.
(define-cador-command "ARRAYCLASSIC" '%cmd-recognised-noop)
