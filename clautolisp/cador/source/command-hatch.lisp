(in-package #:clautolisp.cador)

;;;; Hatch and boundary commands (alref Phase 4 S6): HATCH -HATCH
;;;; HATCHEDIT -HATCHEDIT HATCHGENERATEBOUNDARY BOUNDARY -BOUNDARY;
;;;; GRADIENT and SUPERHATCH (dialogs) are recognised no-ops.
;;;;
;;;; Built against probes/sources/probe-commands.lsp, round 1 (AutoCAD 2022
;;;; job 16916189663, BricsCAD V26 macOS job 16916189664). The two vendors
;;;; store the same hatch differently:
;;;;   AutoCAD   EDGE loops: 92=1, 93=edges, a side 72=1 10=start 11=end,
;;;;             a circle one arc edge 72=2 10=centre 40=r 50=0 51=2pi
;;;;             73=1; then 75=1, and one seed point 98=1 10=0,0,0.
;;;;   BricsCAD  POLYLINE loops: 92=3 72=has-bulge 73=1 93=vertices,
;;;;             10 [42] per vertex, a circle two vertices of bulge 1
;;;;             from (cx+r, cy); then 75=0 and no seed point (98=0).
;;;; Both: 70=1 for SOLID, 71 / 97 the associativity (HPASSOC) and the
;;;; source-object count, 76=1, and the same pattern-line data:
;;;; ANSI31 at scale 2 angle 45 -> 43=0 44=0 45=-6.35 46=0 79=0, i.e. a
;;;; line's offset (0, 3.175) scaled and turned by (line angle + hatch
;;;; angle). The pattern spacings measured are the METRIC ones (both
;;;; probe drawings had MEASUREMENT 1). Round 2 (BricsCAD job 16916238723):
;;;; 52 = the hatch angle and 53 = pattern angle + hatch angle, both in
;;;; radians; the imperial (MEASUREMENT 0) spacings; an island loop is
;;;; 92=18 walked backwards on BricsCAD, 92=16 in its own order on AutoCAD
;;;; (job 16916238722, which also put the seed point at 0,0,0 for a
;;;; rectangle away from the origin).

;;; --- Patterns ---------------------------------------------------------

(defparameter *hatch-patterns-metric*
  ;; name -> lines (angle-degrees x0 y0 dx dy . dashes), as measured.
  '(("ANSI31" (45 0 0 0 3.175))
    ("ANSI37" (45 0 0 0 3.175) (135 0 0 0 3.175))))

(defparameter *hatch-patterns-imperial*
  ;; MEASUREMENT 0, measured in round 2 (BricsCAD job 16916238723):
  ;; ANSI31 / ANSI37 lines 0.125 apart (offset -0.088388, 0.088388 at 45).
  '(("ANSI31" (45 0 0 0 0.125))
    ("ANSI37" (45 0 0 0 0.125) (135 0 0 0 0.125))))

(defun %hatch-pattern-lines (host name)
  "The line family of pattern NAME for the drawing's MEASUREMENT, or
:UNKNOWN."
  (let* ((table (if (eql 0 (%sysvar-value host "MEASUREMENT" 0))
                    *hatch-patterns-imperial*
                    *hatch-patterns-metric*))
         (entry (assoc name table :test #'string-equal)))
    (if entry (rest entry) :unknown)))

(defun %rotate (p angle)
  (let ((c (cos angle)) (s (sin angle)))
    (list (- (* c (first p)) (* s (second p)))
          (+ (* s (first p)) (* c (second p))))))

(defun %hatch-pattern-groups (lines scale angle)
  "The pattern groups after 76 for LINES at SCALE and ANGLE (radians)."
  (append (list (cons 52 angle) (cons 41 scale) (cons 77 0) (cons 78 (length lines)))
          (loop for (a x0 y0 dx dy . dashes) in lines
                for line-angle = (+ (* (%num a) (/ pi 180)) angle)
                for base = (%rotate (list (* scale x0) (* scale y0)) angle)
                for offset = (%rotate (list (* scale dx) (* scale dy)) line-angle)
                append (append (list (cons 53 line-angle)
                                     (cons 43 (%num (first base))) (cons 44 (%num (second base)))
                                     (cons 45 (%num (first offset))) (cons 46 (%num (second offset)))
                                     (cons 79 (length dashes)))
                               (mapcar (lambda (d) (cons 49 (%num (* scale d)))) dashes)))))

;;; --- Boundaries -> loops ----------------------------------------------

(defun %closed-boundary-p (e)
  (case (entity-handle-kind e)
    (:circle t)
    (:lwpolyline (logtest 1 (or (%entity-group-value e 70) 0)))
    (t nil)))

(defun %boundary-vertices (e)
  "A closed boundary as ((x y) . bulge) pairs; a circle as the two
vertices of bulge 1 BricsCAD measured."
  (ecase (entity-handle-kind e)
    (:circle
     (let ((c (%xy (%entity-group-value e 10))) (r (%num (%entity-group-value e 40))))
       (list (cons (list (+ (first c) r) (second c)) 1.0d0)
             (cons (list (- (first c) r) (second c)) 1.0d0))))
    (:lwpolyline
     (let ((pairs '()))
       (dolist (pair (entity-handle-data e))
         (when (consp pair)
           (cond ((group-code-equal-p (car pair) 10)
                  (push (cons (%xy (cdr pair)) 0.0d0) pairs))
                 ((and pairs (group-code-equal-p (car pair) 42))
                  (setf (cdr (first pairs)) (%num (cdr pair)))))))
       (nreverse pairs)))))

(defun %xyz (p) (list (%num (first p)) (%num (second p)) 0.0d0))

(defun %bulge-arc-edge (p q bulge)
  "The arc edge groups (72=2) of the span P-Q with BULGE (> 0)."
  (let* ((chord (%v- q p)) (half (/ (%vlen chord) 2))
         (theta (* 4 (atan bulge)))
         (r (/ half (sin (/ theta 2))))
         (mid (%v* 0.5d0 (%v+ p q)))
         (h (* r (cos (/ theta 2))))
         (n (%vunit (list (- (second chord)) (first chord))))
         (c (%v+ mid (%v* h n)))
         (a0 (atan (- (second p) (second c)) (- (first p) (first c))))
         (a1 (atan (- (second q) (second c)) (- (first q) (first c)))))
    (list (cons 72 2) (cons 10 (%xyz c)) (cons 40 (%num r))
          (cons 50 (%num a0)) (cons 51 (%num (if (< a1 a0) (+ a1 (* 2 pi)) a1)))
          (cons 73 1))))

(defun %island-order (pairs)
  "An island's vertices the way BricsCAD stores them (one measurement,
round 2): the boundary walked backwards from its second vertex --
v1 v0 v(n-1) ... v2."
  (if (< (length pairs) 2)
      pairs
      (list* (second pairs) (first pairs) (reverse (cddr pairs)))))

(defun %hatch-loop-groups (e &optional island)
  "ENTITY as one hatch boundary loop, in the dialect's vendor form;
ISLAND when it lies inside another selected boundary."
  (if (%command-bricscad-p)
      (let* ((pairs (if island (%island-order (%boundary-vertices e)) (%boundary-vertices e)))
             (bulged (some (lambda (pair) (/= 0 (cdr pair))) pairs)))
        ;; Flags: 3 (external + polyline); an island 18 (polyline +
        ;; outermost), as measured with two nested rectangles.
        (append (list (cons 92 (if island 18 3)) (cons 72 (if bulged 1 0)) (cons 73 1)
                      (cons 93 (length pairs)))
                (loop for (p . b) in pairs
                      collect (cons 10 (%xyz p))
                      when bulged collect (cons 42 b))))
      (if (eq (entity-handle-kind e) :circle)
          (list (cons 92 (if island 16 1)) (cons 93 1) (cons 72 2)
                (cons 10 (%xyz (%entity-group-value e 10)))
                (cons 40 (%num (%entity-group-value e 40)))
                (cons 50 0.0d0) (cons 51 (* 2 pi)) (cons 73 1))
          ;; An island: 92=16 (outermost), its edges in their own order
          ;; (AutoCAD round 2, job 16916238722).
          (let ((pairs (%boundary-vertices e)))
            (append (list (cons 92 (if island 16 1)) (cons 93 (length pairs)))
                    (loop for ((p . b) (q)) on (append pairs (list (first pairs)))
                          while q
                          append (if (> b 0)
                                     (%bulge-arc-edge p q b)
                                     (list (cons 72 1) (cons 10 (%xyz p)) (cons 11 (%xyz q))))))))))

;;; --- The HATCH entity ---------------------------------------------------

(defun %hatch-tail-groups (host name scale angle)
  "From 75 on: style, pattern type, pattern lines, seed points."
  (let ((solid (string-equal name "SOLID")))
    (append (list (cons 75 (if (%command-bricscad-p) 0 1)) (cons 76 1))
            (unless solid
              (let ((lines (%hatch-pattern-lines host name)))
                (%hatch-pattern-groups (if (eq lines :unknown) '() lines) scale angle)))
            (if (%command-bricscad-p)
                (list (cons 98 0))
                (list (cons 98 1) (cons 10 (list 0.0d0 0.0d0 0.0d0)))))))

(defun %island-p (host e boundaries)
  "Whether boundary E lies inside another of BOUNDARIES."
  (let ((p (car (first (%boundary-vertices e)))))
    (some (lambda (other)
            (and (not (eq other e))
                 (%point-inside-outline-p p (%entity-outline host other))))
          boundaries)))

(defun %hatch-data (host boundaries name scale angle)
  (let ((assoc (eql 1 (%sysvar-value host "HPASSOC" 1)))
        (solid (string-equal name "SOLID")))
    (append (list (cons 0 "HATCH") (cons 100 "AcDbEntity")
                  (cons 8 (%current-layer-name host)) (cons 100 "AcDbHatch")
                  (cons 10 (list 0.0d0 0.0d0 0.0d0)) (cons 210 (list 0.0d0 0.0d0 1.0d0))
                  (cons 2 (string-upcase name)) (cons 70 (if solid 1 0))
                  (cons 71 (if assoc 1 0)) (cons 91 (length boundaries)))
            (loop for e in boundaries
                  append (append (%hatch-loop-groups e (%island-p host e boundaries))
                                 (if assoc
                                     (list (cons 97 1) (cons 330 (entity-handle-id e)))
                                     (list (cons 97 0)))))
            (%hatch-tail-groups host name scale angle))))

(defun %hatch-settings (host)
  "The current pattern: (values NAME SCALE ANGLE-RADIANS)."
  (let ((name (%sysvar-value host "HPNAME" "")))
    (values (if (or (null name) (equal name "")) "ANSI31" name)
            (%num (%sysvar-value host "HPSCALE" 1.0d0))
            (%num (%sysvar-value host "HPANG" 0.0d0)))))

(defun %set-hatch-settings (host name scale angle)
  (ignore-errors (host-setvar host "HPNAME" name))
  (ignore-errors (host-setvar host "HPSCALE" scale))
  (ignore-errors (host-setvar host "HPANG" angle)))

(defun %take-pattern (host tokens)
  "After _Properties: a pattern name, then (not for SOLID) its scale and
angle (degrees); RETURN keeps the current value. Returns (values NAME
SCALE ANGLE-RADIANS REMAINING)."
  (multiple-value-bind (name scale angle) (%hatch-settings host)
    (let ((token (pop tokens)))
      (cond ((%command-option-p token "s" "solid") (setf name "SOLID"))
            ((and (stringp token) (string/= token "")) (setf name (string-upcase token)))))
    (unless (string-equal name "SOLID")
      (let ((s (%command-token-number (first tokens))))
        (when (or s (equal (first tokens) "")) (pop tokens))
        (when s (setf scale (%num s))))
      (let ((a (%command-token-number (first tokens))))
        (when (or a (equal (first tokens) "")) (pop tokens))
        (when a (setf angle (* (%num a) (/ pi 180))))))
    (values name scale angle tokens)))

(defun %polygon-area (points)
  (abs (/ (loop for (a b) on (append points (list (first points))) while b
                sum (- (* (first a) (second b)) (* (first b) (second a))))
          2)))

(defun %point-inside-outline-p (p segments)
  "Even-odd test of P against the closed outline SEGMENTS."
  (let ((inside nil) (x (first p)) (y (second p)))
    (dolist (s segments inside)
      (destructuring-bind ((x1 y1) (x2 y2)) s
        (when (and (not (eq (> y1 y) (> y2 y)))
                   (< x (+ x1 (/ (* (- y y1) (- x2 x1)) (- y2 y1)))))
          (setf inside (not inside)))))))

(defun %enclosing-boundary (host p)
  "The smallest closed boundary (closed LWPOLYLINE, CIRCLE) around P."
  (let ((best nil) (best-area nil))
    (dolist (e (%selectable-entities host) best)
      (when (%closed-boundary-p e)
        (let ((segments (%entity-outline host e)))
          (when (%point-inside-outline-p p segments)
            (let ((area (%polygon-area (mapcar #'first segments))))
              (when (or (null best-area) (< area best-area))
                (setf best e best-area area)))))))))

;;; -HATCH / HATCH: options until the closing RETURN; _Properties sets the
;;; pattern, _Select objects (or an internal point) adds boundaries.
(defun %cmd-hatch (host tokens)
  (multiple-value-bind (name scale angle) (%hatch-settings host)
    (let ((boundaries '()))
      (loop
        (let ((token (first tokens)))
          (cond ((null tokens) (return))
                ((equal token "") (pop tokens) (return))
                ((%command-option-p token "p" "properties")
                 (pop tokens)
                 (multiple-value-setq (name scale angle tokens) (%take-pattern host tokens)))
                ((%command-option-p token "s" "select" "selectobjects")
                 (pop tokens)
                 (multiple-value-bind (entities rest) (%command-selection host tokens)
                   (setf tokens rest)
                   (dolist (e entities)
                     (when (%closed-boundary-p e) (pushnew e boundaries)))))
                ((%command-token-point token)
                 (pop tokens)
                 (let ((e (%enclosing-boundary host (%xy (%command-token-point token)))))
                   (when e (pushnew e boundaries))))
                (t (return)))))
      (when boundaries
        (%command-entity host (%hatch-data host (nreverse boundaries) name scale angle))
        (%set-hatch-settings host name scale angle))))
  tokens)

;;; -HATCHEDIT / HATCHEDIT: the hatch, then _Properties name scale angle
;;; (the command ends there); the loops are kept.
(defun %hatch-loops-segment (data)
  "DATA's groups from the first loop through the last source handle."
  (let* ((start (1+ (position 91 data :key #'car :test #'eql)))
         (end (position 75 data :key #'car :test #'eql :start start)))
    (subseq data start end)))

(defun %cmd-hatchedit (host tokens)
  (multiple-value-bind (e pick rest) (%take-pick host tokens)
    (declare (ignore pick))
    (unless (and e (eq (entity-handle-kind e) :hatch))
      (return-from %cmd-hatchedit (%consume-through-return tokens)))
    (setf tokens rest)
    (when (%command-option-p (first tokens) "p" "properties")
      (pop tokens)
      (multiple-value-bind (name scale angle remaining) (%take-pattern host tokens)
        (setf tokens remaining)
        (let* ((data (entity-handle-data e))
               (prefix (subseq data 0 (position 2 data :key #'car :test #'eql))))
          (setf (entity-handle-data e)
                (append prefix
                        (list (cons 2 (string-upcase name))
                              (cons 70 (if (string-equal name "SOLID") 1 0))
                              (assoc 71 data) (assoc 91 data))
                        (%hatch-loops-segment data)
                        (%hatch-tail-groups host name scale angle))))
        (%set-hatch-settings host name scale angle)))
    tokens))

;;; --- Boundaries out of hatches and points -------------------------------

(defun %loop-vertices (groups)
  "One loop's groups -> ((x y) . bulge) pairs (polyline or edge loop)."
  (let ((pairs '()))
    (if (logtest 2 (cdr (assoc 92 groups)))
        (dolist (g groups)
          (cond ((eql (car g) 10) (push (cons (%xy (cdr g)) 0.0d0) pairs))
                ((and pairs (eql (car g) 42)) (setf (cdr (first pairs)) (%num (cdr g))))))
        (loop for (g . more) on groups
              when (and (eql (car g) 72) (eql (cdr g) 1))
                do (push (cons (%xy (cdr (assoc 10 more))) 0.0d0) pairs)
              when (and (eql (car g) 72) (eql (cdr g) 2))
                do (let ((c (%xy (cdr (assoc 10 more)))) (r (%num (cdr (assoc 40 more)))))
                     (push (cons (list (+ (first c) r) (second c)) 1.0d0) pairs)
                     (push (cons (list (- (first c) r) (second c)) 1.0d0) pairs))))
    (nreverse pairs)))

(defun %hatch-loops (data)
  "The loops of hatch DATA, each a list of its groups (92 to its 97 run)."
  (let ((loops '()) (current nil))
    (dolist (g (%hatch-loops-segment data))
      (when (eql (car g) 92)
        (when current (push (nreverse current) loops))
        (setf current '()))
      (push g current))
    (when current (push (nreverse current) loops))
    (nreverse loops)))

(defun %polyline-from-pairs (host pairs)
  (let ((data (%lwpolyline-data host (mapcar #'car pairs) :closed t)))
    (if (some (lambda (pair) (/= 0 (cdr pair))) pairs)
        ;; Put each vertex's bulge (42) right after it.
        (append (remove 10 data :key #'car)
                (loop for (p . b) in pairs append (list (cons 10 p) (cons 42 b))))
        data)))

(defun %entlast-entity (host)
  (cador-find-entity-by-handle
   host (clautolisp.autolisp-runtime:autolisp-ename-value (host-entlast host))))

;;; HATCHGENERATEBOUNDARY: hatches, RETURN -> one closed LWPOLYLINE per
;;; loop, and the hatch becomes associative to them (measured: 71=1 97=1).
(defun %cmd-hatchgenerateboundary (host tokens)
  (multiple-value-bind (entities rest) (%command-selection host tokens)
    (dolist (h entities)
      (when (eq (entity-handle-kind h) :hatch)
        (let* ((data (entity-handle-data h))
               (made (loop for lp in (%hatch-loops data)
                           collect (progn (%command-entity host (%polyline-from-pairs
                                                                 host (%loop-vertices lp)))
                                          (%entlast-entity host)))))
          (setf (entity-handle-data h)
                (let ((out '()) (i 0))
                  (dolist (g data (nreverse out))
                    (cond ((eql (car g) 71) (push (cons 71 1) out))
                          ((eql (car g) 97)
                           (push (cons 97 1) out)
                           (push (cons 330 (entity-handle-id (nth i made))) out)
                           (incf i))
                          ((and (eql (car g) 330) (plusp i)) nil)
                          (t (push g out)))))))))
    rest))

;;; -BOUNDARY / BOUNDARY: internal points until RETURN -> a closed
;;; LWPOLYLINE copy of the boundary around each (measured: the rectangle's
;;; outline). _Advanced options are skipped.
(defun %cmd-boundary (host tokens)
  (loop
    (let ((token (first tokens)))
      (cond ((null tokens) (return))
            ((equal token "") (pop tokens) (return))
            ((%command-token-point token)
             (pop tokens)
             (let ((e (%enclosing-boundary host (%xy (%command-token-point token)))))
               (when e
                 (%command-entity host (%polyline-from-pairs host (%boundary-vertices e))))))
            ((%command-option-p token "a" "advanced") (pop tokens))
            (t (return)))))
  tokens)

(define-cador-command '("HATCH" "-HATCH") '%cmd-hatch)
(define-cador-command '("HATCHEDIT" "-HATCHEDIT") '%cmd-hatchedit)
(define-cador-command "HATCHGENERATEBOUNDARY" '%cmd-hatchgenerateboundary)
(define-cador-command '("BOUNDARY" "-BOUNDARY") '%cmd-boundary)
;; GRADIENT and SUPERHATCH (Express Tools) work through dialogs.
(define-cador-command '("GRADIENT" "SUPERHATCH") '%cmd-recognised-noop)
