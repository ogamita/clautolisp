(in-package #:clautolisp.cador)

;;;; Geometry-editing commands (alref Phase 4 S5): TRIM, EXTEND, OFFSET,
;;;; BREAK, FILLET, CHAMFER, PEDIT.
;;;;
;;;; Implemented from the commands' geometry -- each result is determined
;;;; by the inputs (where two lines meet, which side a point is on) -- and
;;;; to be CONFIRMED against probes/sources/probe-commands.lsp's S5 cases
;;;; (TRIM, EXTEND, FILLET, CHAMFER, OFFSET, BREAK, PEDIT), which await the
;;;; CAD runners. Scope: LINEs as the objects edited, LINEs and circles /
;;;; arcs as cutting edges and boundaries; OFFSET also of circles and arcs;
;;;; BREAK of circles; PEDIT turns a LINE into an LWPOLYLINE.

;;; --- Picks: (ename point), a point on an object, or a bare ename -------

(defun %take-pick (host tokens)
  "One object pick from TOKENS: (values ENTITY PICK-POINT REMAINING), or
NIL when the first token is not a pick."
  (let ((token (first tokens)))
    (cond ((%entsel-token-p token)
           (multiple-value-bind (e p) (%entsel-entity host token)
             (values e (and p (%xy p)) (rest tokens))))
          ((typep token 'clautolisp.autolisp-runtime:autolisp-ename)
           (let ((e (cador-find-entity-by-handle
                     host (clautolisp.autolisp-runtime:autolisp-ename-value token))))
             (values e nil (rest tokens))))
          ((%command-token-point token)
           (let ((p (%xy (%command-token-point token))))
             (values (%pick-entity host p) p (rest tokens))))
          ((and (stringp token) (safe-find-entity (cador-active-drawing host) token))
           (values (safe-find-entity (cador-active-drawing host) token) nil (rest tokens)))
          (t nil))))

(defun %line-ends (e)
  (values (%xy (%entity-group-value e 10)) (%xy (%entity-group-value e 11))))

(defun %set-line-ends (e a b)
  (let ((z (or (third (%entity-group-value e 10)) 0.0d0)))
    (%entity-set-group e 10 (list (first a) (second a) z))
    (%entity-set-group e 11 (list (first b) (second b) z))))

(defun %line-param (a b p)
  "The parameter of P's projection on the line A + t (B - A)."
  (let ((d (%v- b a)))
    (/ (reduce #'+ (mapcar #'* (%v- p a) d))
       (max 1d-300 (reduce #'+ (mapcar #'* d d))))))

(defun %intersections-with (host a b edge)
  "Parameters t (on the infinite line A + t (B - A)) where it meets EDGE."
  (let ((d (%v- b a)))
    (case (entity-handle-kind edge)
      (:line
       (multiple-value-bind (c e) (%line-ends edge)
         (let* ((f (%v- e c))
                (den (- (* (first d) (second f)) (* (second d) (first f)))))
           (unless (< (abs den) 1d-12)
             (let ((tt (/ (- (* (- (first c) (first a)) (second f))
                             (* (- (second c) (second a)) (first f)))
                          den))
                   (u (/ (- (* (- (first c) (first a)) (second d))
                            (* (- (second c) (second a)) (first d)))
                         den)))
               ;; on the edge segment itself
               (when (<= -1d-9 u (+ 1 1d-9)) (list tt)))))))
      ((:circle :arc)
       (let* ((c (%xy (%entity-group-value edge 10)))
              (r (%num (%entity-group-value edge 40)))
              (f (%v- a c))
              (qa (reduce #'+ (mapcar #'* d d)))
              (qb (* 2 (reduce #'+ (mapcar #'* f d))))
              (qc (- (reduce #'+ (mapcar #'* f f)) (* r r)))
              (disc (- (* qb qb) (* 4 qa qc))))
         (when (>= disc 0)
           (let ((ts (list (/ (- (- qb) (sqrt disc)) (* 2 qa))
                           (/ (+ (- qb) (sqrt disc)) (* 2 qa)))))
             (if (eq (entity-handle-kind edge) :arc)
                 (remove-if-not
                  (lambda (tt)
                    (let* ((p (%v+ a (%v* tt d)))
                           (ang (atan (- (second p) (second c)) (- (first p) (first c))))
                           (a0 (%num (%entity-group-value edge 50)))
                           (a1 (%num (%entity-group-value edge 51))))
                      (<= (mod (- ang a0) (* 2 pi)) (mod (- a1 a0) (* 2 pi)))))
                  ts)
                 ts)))))
      (t nil))))

(defun %edges-for (host entity edges)
  (remove entity (or edges (%selectable-entities host))))

;;; --- TRIM / EXTEND ---------------------------------------------------
;;; TRIMEXTENDMODE 1 (the vendors' current default): every object is an
;;; edge and picks come at once; 0: edges first, RETURN, then the picks.

(defun %trim-line (host e pick edges)
  (multiple-value-bind (a b) (%line-ends e)
    (let* ((cuts (sort (remove-if-not (lambda (tt) (< 1d-9 tt (- 1 1d-9)))
                                      (loop for edge in (%edges-for host e edges)
                                            append (%intersections-with host a b edge)))
                       #'<))
           (tp (if pick (%line-param a b pick) 0.5d0))
           (lo (or (find-if (lambda (tt) (< tt tp)) cuts :from-end t) 0.0d0))
           (hi (or (find-if (lambda (tt) (> tt tp)) cuts) 1.0d0))
           (d (%v- b a)))
      (cond ((null cuts) nil)
            ((and (= lo 0) (= hi 1)) nil)
            ((= lo 0) (%set-line-ends e (%v+ a (%v* hi d)) b))
            ((= hi 1) (%set-line-ends e a (%v+ a (%v* lo d))))
            (t ;; the picked piece is in the middle: keep both outer parts
             (let ((second (%clone-entity-with-run host e)))
               (%set-line-ends e a (%v+ a (%v* lo d)))
               (%set-line-ends second (%v+ a (%v* hi d)) b)))))))

(defun %extend-line (host e pick edges)
  (multiple-value-bind (a b) (%line-ends e)
    (let* ((tp (if pick (%line-param a b pick) 1.0d0))
           (at-end (>= tp 0.5d0))
           (hits (loop for edge in (%edges-for host e edges)
                       append (%intersections-with host a b edge))))
      (if at-end
          (let ((tt (reduce #'min (remove-if-not (lambda (x) (> x (+ 1 1d-9))) hits)
                            :initial-value most-positive-double-float)))
            (when (< tt most-positive-double-float)
              (%set-line-ends e a (%v+ a (%v* tt (%v- b a))))))
          (let ((tt (reduce #'max (remove-if-not (lambda (x) (< x -1d-9)) hits)
                            :initial-value most-negative-double-float)))
            (when (> tt most-negative-double-float)
              (%set-line-ends e (%v+ a (%v* tt (%v- b a))) b)))))))

(defun %trim-or-extend (host tokens operation)
  (let ((quick (eql 1 (%sysvar-value host "TRIMEXTENDMODE" 1)))
        (edges nil))
    (unless quick
      (multiple-value-bind (selected rest) (%command-selection host tokens)
        (setf edges selected tokens rest)))
    (loop
      (cond ((null tokens) (return))
            ((equal (first tokens) "") (pop tokens) (return))
            (t (multiple-value-bind (e pick rest) (%take-pick host tokens)
                 (unless e (return))
                 (setf tokens rest)
                 (when (eq (entity-handle-kind e) :line)
                   (funcall operation host e pick edges))))))
    tokens))

(defun %cmd-trim (host tokens) (%trim-or-extend host tokens #'%trim-line))
(defun %cmd-extend (host tokens) (%trim-or-extend host tokens #'%extend-line))

;;; --- OFFSET: distance, then (object, side point) pairs until RETURN ---

(defun %side-sign (a b p)
  "+1 when P is left of A->B, -1 when right."
  (if (>= (- (* (- (first b) (first a)) (- (second p) (second a)))
             (* (- (second b) (second a)) (- (first p) (first a))))
          0)
      1 -1))

(defun %offset-entity (host e d side)
  (case (entity-handle-kind e)
    (:line
     (multiple-value-bind (a b) (%line-ends e)
       (let* ((dir (%vunit (%v- b a)))
              (n (%v* (* d (%side-sign a b side)) (list (- (second dir)) (first dir))))
              (copy (%clone-entity-with-run host e)))
         (%set-line-ends copy (%v+ a n) (%v+ b n)))))
    ((:circle :arc)
     (let* ((c (%xy (%entity-group-value e 10)))
            (r (%num (%entity-group-value e 40)))
            (outside (> (%vlen (%v- side c)) r))
            (nr (if outside (+ r d) (- r d))))
       (when (plusp nr)
         (let ((copy (%clone-entity-with-run host e)))
           (%entity-set-group copy 40 nr)))))))

(defun %cmd-offset (host tokens)
  (let ((d (%command-token-number (first tokens))))
    (unless d (return-from %cmd-offset tokens))
    (pop tokens)
    (loop
      (cond ((null tokens) (return))
            ((equal (first tokens) "") (pop tokens) (return))
            (t (multiple-value-bind (e pick rest) (%take-pick host tokens)
                 (declare (ignore pick))
                 (unless e (return))
                 (let ((side (%command-token-point (first rest))))
                   (unless side (return))
                   (setf tokens (rest rest))
                   (%offset-entity host e d (%xy side)))))))
    tokens))

;;; --- BREAK: object (the pick is the first point), second point --------

(defun %cmd-break (host tokens)
  (multiple-value-bind (e pick rest) (%take-pick host tokens)
    (unless e (return-from %cmd-break tokens))
    (setf tokens rest)
    (let ((p1 pick))
      (when (%command-option-p (first tokens) "f" "first")
        (pop tokens)
        (setf p1 (and (%command-token-point (first tokens))
                      (%xy (%command-token-point (pop tokens))))))
      (let ((p2 (and (%command-token-point (first tokens))
                     (%xy (%command-token-point (pop tokens))))))
        (when (and p1 p2)
          (case (entity-handle-kind e)
            (:line
             (multiple-value-bind (a b) (%line-ends e)
               (let* ((t1 (max 0 (min 1 (%line-param a b p1))))
                      (t2 (max 0 (min 1 (%line-param a b p2))))
                      (lo (min t1 t2)) (hi (max t1 t2))
                      (d (%v- b a)))
                 (cond ((and (<= lo 0) (>= hi 1)) (%erase-entity-and-run host e))
                       ((<= lo 0) (%set-line-ends e (%v+ a (%v* hi d)) b))
                       ((>= hi 1) (%set-line-ends e a (%v+ a (%v* lo d))))
                       (t (let ((second (%clone-entity-with-run host e)))
                            (%set-line-ends e a (%v+ a (%v* lo d)))
                            (%set-line-ends second (%v+ a (%v* hi d)) b)))))))
            (:circle
             ;; The run counter-clockwise from the first point to the second
             ;; goes; the circle becomes the ARC from the second to the first.
             (let* ((c (%xy (%entity-group-value e 10)))
                    (ang (lambda (p) (mod (atan (- (second p) (second c)) (- (first p) (first c)))
                                          (* 2 pi))))
                    (data (list (cons 0 "ARC")
                                (cons 8 (%entity-group-value e 8))
                                (cons 10 (%entity-group-value e 10))
                                (cons 40 (%entity-group-value e 40))
                                (cons 50 (funcall ang p2))
                                (cons 51 (funcall ang p1)))))
               (%command-entity host data)
               (%erase-entity-and-run host e)))))))
    tokens))

;;; --- FILLET / CHAMFER of two lines ------------------------------------

(defun %line-intersection-point (a b c d)
  (let* ((r (%v- b a)) (s (%v- d c))
         (den (- (* (first r) (second s)) (* (second r) (first s)))))
    (unless (< (abs den) 1d-12)
      (let ((tt (/ (- (* (- (first c) (first a)) (second s))
                      (* (- (second c) (second a)) (first s)))
                   den)))
        (%v+ a (%v* tt r))))))

(defun %corner-geometry (e1 p1 e2 p2)
  "For two picked lines: (values CORNER U1 U2 FAR1 FAR2) -- the corner, the
unit directions from it toward the PICKED sides, and the end of each line
that is kept (the one on the picked side)."
  (multiple-value-bind (a1 b1) (%line-ends e1)
    (multiple-value-bind (a2 b2) (%line-ends e2)
      (let ((x (%line-intersection-point a1 b1 a2 b2)))
        (when x
          (flet ((toward (a b p)
                   (let* ((pa (or p (if (> (%vlen (%v- a x)) (%vlen (%v- b x))) a b)))
                          (far (if (> (%vlen (%v- a x)) (%vlen (%v- b x))) a b))
                          (u (%vunit (%v- pa x))))
                     (when (< (%vlen (%v- pa x)) 1d-12) (setf u (%vunit (%v- far x))))
                     ;; keep the end on the picked side of the corner
                     (values u (if (> (reduce #'+ (mapcar #'* (%v- a x) u))
                                      (reduce #'+ (mapcar #'* (%v- b x) u)))
                                   a b)))))
            (multiple-value-bind (u1 far1) (toward a1 b1 p1)
              (multiple-value-bind (u2 far2) (toward a2 b2 p2)
                (values x u1 u2 far1 far2)))))))))

(defun %fillet-lines (host e1 p1 e2 p2 r)
  (multiple-value-bind (x u1 u2 far1 far2) (%corner-geometry e1 p1 e2 p2)
    (when x
      (if (< r 1d-12)
          (progn (%set-line-ends e1 far1 x) (%set-line-ends e2 x far2))
          (let* ((cosang (max -1d0 (min 1d0 (reduce #'+ (mapcar #'* u1 u2)))))
                 (half (/ (acos cosang) 2))
                 (dt (/ r (tan half)))
                 (t1 (%v+ x (%v* dt u1)))
                 (t2 (%v+ x (%v* dt u2)))
                 (bis (%vunit (%v+ u1 u2)))
                 (c (%v+ x (%v* (/ r (sin half)) bis)))
                 (a1 (atan (- (second t1) (second c)) (- (first t1) (first c))))
                 (a2 (atan (- (second t2) (second c)) (- (first t2) (first c))))
                 (ccw (plusp (- (* (first u1) (second u2)) (* (second u1) (first u2)))))
                 (norm (lambda (a) (mod a (* 2 pi)))))
            (%set-line-ends e1 far1 t1)
            (%set-line-ends e2 t2 far2)
            (%command-entity host (list (cons 0 "ARC")
                                        (cons 8 (%entity-group-value e1 8))
                                        (cons 10 (list (first c) (second c) 0.0d0))
                                        (cons 40 r)
                                        ;; ARCs run counter-clockwise
                                        (cons 50 (funcall norm (if ccw a2 a1)))
                                        (cons 51 (funcall norm (if ccw a1 a2))))))))))

(defun %chamfer-lines (host e1 p1 e2 p2 d1 d2)
  (multiple-value-bind (x u1 u2 far1 far2) (%corner-geometry e1 p1 e2 p2)
    (when x
      (let ((q1 (%v+ x (%v* d1 u1))) (q2 (%v+ x (%v* d2 u2))))
        (%set-line-ends e1 far1 q1)
        (%set-line-ends e2 q2 far2)
        (unless (and (zerop d1) (zerop d2))
          (%command-entity host (list (cons 0 "LINE")
                                      (cons 8 (%entity-group-value e1 8))
                                      (cons 10 (list (first q1) (second q1) 0.0d0))
                                      (cons 11 (list (first q2) (second q2) 0.0d0)))))))))

(defun %cmd-fillet (host tokens)
  (cond
    ((%command-option-p (first tokens) "r" "radius")
     (let ((r (%command-token-number (second tokens))))
       (when r (ignore-errors (host-setvar host "FILLETRAD" r)))
       (nthcdr 2 tokens)))
    (t
     (multiple-value-bind (e1 p1 rest) (%take-pick host tokens)
       (multiple-value-bind (e2 p2 rest) (and e1 (%take-pick host rest))
         (if (and e1 e2 (eq (entity-handle-kind e1) :line) (eq (entity-handle-kind e2) :line))
             (progn (%fillet-lines host e1 p1 e2 p2
                                   (%num (%sysvar-value host "FILLETRAD" 0.0d0)))
                    rest)
             tokens))))))

(defun %cmd-chamfer (host tokens)
  (cond
    ((%command-option-p (first tokens) "d" "distance")
     (let ((d1 (%command-token-number (second tokens)))
           (d2 (%command-token-number (third tokens))))
       (when d1 (ignore-errors (host-setvar host "CHAMFERA" d1)))
       (when d2 (ignore-errors (host-setvar host "CHAMFERB" d2)))
       (nthcdr 3 tokens)))
    (t
     (multiple-value-bind (e1 p1 rest) (%take-pick host tokens)
       (multiple-value-bind (e2 p2 rest) (and e1 (%take-pick host rest))
         (if (and e1 e2 (eq (entity-handle-kind e1) :line) (eq (entity-handle-kind e2) :line))
             (progn (%chamfer-lines host e1 p1 e2 p2
                                    (%num (%sysvar-value host "CHAMFERA" 0.0d0))
                                    (%num (%sysvar-value host "CHAMFERB" 0.0d0)))
                    rest)
             tokens))))))

;;; --- PEDIT: a LINE becomes an LWPOLYLINE (_Yes); _Width _Close _Open --

(defun %cmd-pedit (host tokens)
  (multiple-value-bind (e pick rest) (%take-pick host tokens)
    (declare (ignore pick))
    (unless e (return-from %cmd-pedit (%consume-through-return tokens)))
    (setf tokens rest)
    (when (eq (entity-handle-kind e) :line)
      ;; "Object selected is not a polyline. Do you want to turn it into one?"
      (if (%command-option-p (first tokens) "n" "no")
          (return-from %cmd-pedit (rest tokens))
          (progn
            (when (%command-option-p (first tokens) "y" "yes") (pop tokens))
            (multiple-value-bind (a b) (%line-ends e)
              (let ((layer (%entity-group-value e 8)))
                (%erase-entity-and-run host e)
                (%command-entity host (%lwpolyline-data host (list a b)))
                (let ((new (cador-find-entity-by-handle
                            host (clautolisp.autolisp-runtime:autolisp-ename-value
                                  (host-entlast host)))))
                  (%entity-set-group new 8 layer)
                  (setf e new)))))))
    (when (eq (entity-handle-kind e) :lwpolyline)
      (loop
        (let ((token (first tokens)))
          (cond ((null tokens) (return))
                ((or (equal token "") (%command-option-p token "x" "exit")) (pop tokens) (return))
                ((%command-option-p token "w" "width")
                 (pop tokens)
                 (let ((w (%command-token-number (pop tokens))))
                   (when w
                     (%entity-set-group e 43 w)
                     (dolist (pair (entity-handle-data e))
                       (when (and (consp pair) (member (car pair) '(40 41)))
                         (setf (cdr pair) w))))))
                ((%command-option-p token "c" "close")
                 (pop tokens) (%entity-set-group e 70 (logior 1 (or (%entity-group-value e 70) 0))))
                ((%command-option-p token "o" "open")
                 (pop tokens) (%entity-set-group e 70 (logandc2 (or (%entity-group-value e 70) 0) 1)))
                (t (return))))))
    tokens))

(define-cador-command "TRIM"    '%cmd-trim)
(define-cador-command "EXTEND"  '%cmd-extend)
(define-cador-command "OFFSET"  '%cmd-offset)
(define-cador-command "BREAK"   '%cmd-break)
(define-cador-command "FILLET"  '%cmd-fillet)
(define-cador-command "CHAMFER" '%cmd-chamfer)
(define-cador-command "PEDIT"   '%cmd-pedit)

;;; --- -OVERKILL (Express Tools): exact duplicates erased -----------------
;;; Selection, RETURN, then the options line (RETURN for the defaults).
;;; Two objects are duplicates when kind, layer and every geometry group
;;; agree; the first created is kept.
(defun %entity-signature (e)
  (cons (entity-handle-kind e)
        (loop for pair in (entity-handle-data e)
              when (and (consp pair) (integerp (car pair))
                        (or (member (car pair) '(8 62 6 40 41 42 50 51 70 90))
                            (<= 10 (car pair) 18)))
                collect (cons (car pair)
                              (if (consp (cdr pair))
                                  (mapcar (lambda (x) (if (realp x) (/ (round (* x 1d6)) 1d6) x))
                                          (cdr pair))
                                  (cdr pair))))))

(defun %cmd-overkill (host tokens)
  (multiple-value-bind (entities rest) (%command-selection host tokens)
    (loop while (equal (first rest) "") do (pop rest) (return))
    (let ((seen (make-hash-table :test #'equal)))
      (dolist (e (sort (copy-list entities) #'<
                       :key (lambda (e) (or (position (entity-handle-id e)
                                                      (reverse (clautolisp.drawing:drawing-creation-order
                                                                (cador-active-drawing host)))
                                                      :test #'equal)
                                            0))))
        (let ((sig (%entity-signature e)))
          (if (gethash sig seen)
              (%erase-entity-and-run host e)
              (setf (gethash sig seen) t)))))
    rest))

(define-cador-command '("-OVERKILL" "OVERKILL") '%cmd-overkill)
