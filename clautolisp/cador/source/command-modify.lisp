(in-package #:clautolisp.cador)

;;;; Modify / property commands of the command engine (alref Phase 4 S2).
;;;;
;;;; Built against probes/sources/probe-commands.lsp: AutoCAD 2022 (job
;;;; 16914186872) and BricsCAD V26 (job 16914186873) agree on SCALE,
;;;; ALIGN, CHPROP, CHANGE and EXPLODE; for STRETCH, LENGTHEN, MATCHPROP,
;;;; SETBYLAYER and CONVERTPOLY the BricsCAD result is the reference (the
;;;; headless AutoCAD run lost those cases -- see the probe).

(defvar *current-command-host* nil
  "The host a property change runs on (CHPROP / CHANGE create a missing layer).")

;;; --- Group editing that keeps the vendors' group order ---------------

(defparameter *property-codes* '(62 6 370 48 39 440)
  "Property groups, in the order the vendors list them right after the
layer (8): colour 62 first (measured: CIRCLE 8=0 62=1 10= ...).")

(defun %entity-remove-group (entity code)
  (setf (entity-handle-data entity)
        (remove-if (lambda (pair) (and (consp pair) (group-code-equal-p (car pair) code)))
                   (entity-handle-data entity))))

(defun %entity-set-property (entity code value)
  "Set property group CODE, inserting it after the layer (and any earlier
property group) when absent."
  (if (assoc code (entity-handle-data entity) :test #'group-code-equal-p)
      (%entity-set-group entity code value)
      (let* ((data (entity-handle-data entity))
             (anchors (cons 8 (loop for c in *property-codes*
                                    until (eql c code) collect c)))
             (pos (loop for i from 0 for pair in data
                        when (and (consp pair)
                                  (member (car pair) anchors :test #'group-code-equal-p))
                          maximize (1+ i))))
        (setf (entity-handle-data entity)
              (append (subseq data 0 (or pos (length data)))
                      (list (cons code value))
                      (subseq data (or pos (length data))))))))

(defun %color-token-value (token)
  "A CHPROP / CHANGE colour answer: :BYLAYER, 0 (ByBlock) or 1..255."
  (let ((name (string-upcase (string-left-trim "_" token))))
    (cond ((string= name "BYLAYER") :bylayer)
          ((string= name "BYBLOCK") 0)
          (t (let ((n (%command-token-number token)))
               (and n (<= 0 n 256) (round n)))))))

(defun %apply-property (entity option value)
  "Apply one CHPROP / CHANGE property OPTION (keyword) with VALUE."
  (ecase option
    (:color (let ((c (%color-token-value value)))
              (cond ((or (eq c :bylayer) (eql c 256)) (%entity-remove-group entity 62))
                    (c (%entity-set-property entity 62 c)))))
    (:layer (%entity-set-group entity 8 value))
    (:ltype (if (string-equal value "BYLAYER")
                (%entity-remove-group entity 6)
                (%entity-set-property entity 6 value)))
    (:ltscale (let ((n (%command-token-number value)))
                (when n (%entity-set-property entity 48 n))))
    (:thickness (let ((n (%command-token-number value)))
                  (when n (%entity-set-property entity 39 n))))
    (:lweight (let ((n (%command-token-number value)))
                (when n (%entity-set-property entity 370 (round (* 100 n))))))))

(defun %property-option (token)
  (cond ((%command-option-p token "c" "color" "colour") :color)
        ((%command-option-p token "la" "layer") :layer)
        ((%command-option-p token "lt" "ltype" "linetype") :ltype)
        ((%command-option-p token "s" "lts" "ltscale") :ltscale)
        ((%command-option-p token "t" "thickness") :thickness)
        ((%command-option-p token "lw" "lweight" "lineweight") :lweight)))

(defun %take-property-changes (entities tokens)
  "Consume 'option value' pairs until RETURN, applying each to ENTITIES."
  (loop
    (let ((token (first tokens)))
      (cond ((null tokens) (return))
            ((equal token "") (pop tokens) (return))
            ((and (stringp token) (%property-option token) (stringp (second tokens)))
             (let ((option (%property-option token)) (value (second tokens)))
               (when (eq option :layer) (%ensure-layer-exists *current-command-host* value))
               (dolist (e entities) (%apply-property e option value))
               (setf tokens (cddr tokens))))
            (t (return)))))
  tokens)

(defun %ensure-layer-exists (host name)
  (when (and host (stringp name)) (ignore-errors (%ensure-layer host name))))

;;; --- CHPROP: selection, then property / value pairs until RETURN ------
(defun %cmd-chprop (host tokens)
  (multiple-value-bind (entities rest) (%command-selection host tokens)
    (let ((*current-command-host* host))
      (%take-property-changes entities rest))))

;;; --- CHANGE: selection, then a change point (or _Properties) ---------
;;; Measured: a LINE's endpoint NEAREST the change point moves to it
;;; ((0,0)-(2,0), change point (3,3) -> (0,0)-(3,3)); a circle takes the
;;; distance from its centre as its radius.
(defun %cmd-change (host tokens)
  (multiple-value-bind (entities rest) (%command-selection host tokens)
    (cond
      ((%command-option-p (first rest) "p" "properties")
       (let ((*current-command-host* host))
         (%take-property-changes entities (rest rest))))
      ((%command-token-point (first rest))
       (let ((pt (%command-token-point (pop rest))))
         (dolist (e entities)
           (case (entity-handle-kind e)
             (:line (let* ((a (%entity-group-value e 10)) (b (%entity-group-value e 11)))
                      (if (<= (%vlen (%v- (%xy pt) (%xy a))) (%vlen (%v- (%xy pt) (%xy b))))
                          (%entity-set-group e 10 pt)
                          (%entity-set-group e 11 pt))))
             (:circle (%entity-set-group e 40 (%vlen (%v- (%xy pt)
                                                          (%xy (%entity-group-value e 10))))))))
         rest))
      (t rest))))

;;; --- SCALE: selection, base point, factor ----------------------------
(defun %entity-scale (entity base k)
  (let ((kind (entity-handle-kind entity))
        (bx (first base)) (by (second base)) (bz (or (third base) 0.0d0)))
    (flet ((about (p)
             (let ((x (+ bx (* k (- (%num (first p)) bx))))
                   (y (+ by (* k (- (%num (second p)) by)))))
               (if (cddr p) (list x y (+ bz (* k (- (%num (third p)) bz)))) (list x y)))))
      (%entity-map-point-groups
       entity #'about
       (case kind
         ((:ellipse :ray :xline) '(10))      ; 11 is a vector / direction there
         (t '(10 11 12 13))))
      (case kind
        ((:circle :arc :text :mtext :attrib :attdef)
         (let ((r (%entity-group-value entity 40)))
           (when r (%entity-set-group entity 40 (* k r)))))
        (:ellipse (%entity-set-group entity 11 (%v* k (%entity-group-value entity 11))))
        (:insert (dolist (c '(41 42 43))
                   (%entity-set-group entity c (* k (or (%entity-group-value entity c) 1.0d0)))))))))

(defun %cmd-scale (host tokens)
  (multiple-value-bind (entities rest) (%command-selection host tokens)
    (let ((base (%command-token-point (first rest)))
          (k (%command-token-number (second rest))))
      (when (and base k)
        (setf rest (cddr rest))
        (dolist (e entities)
          (%entity-scale e base k)
          (dolist (handle (%entity-subentity-handles host e))
            (let ((sub (cador-find-entity-by-handle host handle)))
              (when sub (%entity-scale sub base k))))))
      rest)))

;;; --- ALIGN: selection, source/destination pairs, RETURN, scale? -------
;;; Two pairs, no scaling: s1 goes to d1, the s1->s2 direction turns onto
;;; d1->d2 (measured: (0,0)-(2,0) aligned (0,0)->(1,1), (2,0)->(1,3) gives
;;; (1,1)-(1,3) on both vendors).
(defun %cmd-align (host tokens)
  (multiple-value-bind (entities rest) (%command-selection host tokens)
    (multiple-value-bind (points rest) (%take-points rest)
      (when (%command-option-p (first rest) "n" "no" "y" "yes") (pop rest))
      (when (>= (length points) 2)
        (let* ((s1 (first points)) (d1 (second points))
               (s2 (third points)) (d2 (fourth points))
               (angle (if (and s2 d2)
                          (- (atan (- (second d2) (second d1)) (- (first d2) (first d1)))
                             (atan (- (second s2) (second s1)) (- (first s2) (first s1))))
                          0.0d0))
               (dx (- (first d1) (first s1))) (dy (- (second d1) (second s1))))
          (dolist (e entities)
            (dolist (x (cons e (loop for h in (%entity-subentity-handles host e)
                                     for sub = (cador-find-entity-by-handle host h)
                                     when sub collect sub)))
              (%entity-rotate-one x (first s1) (second s1) angle)
              (%entity-translate x dx dy 0.0d0)))))
      rest)))

;;; --- EXPLODE: polylines into their LINE / ARC spans -------------------
(defun %span-entity-data (entity p q bulge z)
  "The LINE or ARC a polyline span P->Q with BULGE becomes, with ENTITY's
layer and property groups."
  (let ((props (loop for code in (cons 8 *property-codes*)
                     for v = (%entity-group-value entity code)
                     when v collect (cons code v))))
    (if (< (abs bulge) 1d-12)
        (append (list (cons 0 "LINE")) props
                (list (cons 10 (list (first p) (second p) z))
                      (cons 11 (list (first q) (second q) z))))
        (let* ((sweep (* 4 (atan bulge)))
               (chord (%vlen (%v- q p)))
               (r (abs (/ chord (* 2 (sin (/ sweep 2))))))
               (mid (%v* 0.5d0 (%v+ p q)))
               (dir (%vunit (%v- q p)))
               (normal (list (- (second dir)) (first dir)))
               (h (* (/ chord (* 2 (sin (/ sweep 2)))) (cos (/ sweep 2))))
               (c (%v+ mid (%v* h normal)))
               (ap (atan (- (second p) (second c)) (- (first p) (first c))))
               (aq (atan (- (second q) (second c)) (- (first q) (first c))))
               (norm (lambda (a) (if (minusp a) (+ a (* 2 pi)) a))))
          (append (list (cons 0 "ARC")) props
                  (list (cons 10 (list (first c) (second c) z)) (cons 40 r)
                        ;; An ARC runs counter-clockwise: a clockwise span
                        ;; (negative bulge) is the arc from Q to P.
                        (cons 50 (funcall norm (if (plusp bulge) ap aq)))
                        (cons 51 (funcall norm (if (plusp bulge) aq ap)))))))))

(defun %explode-lwpolyline (host entity)
  (let ((pairs '()) (closed (logtest 1 (or (%entity-group-value entity 70) 0)))
        (z (%num (or (%entity-group-value entity 38) 0.0d0))))
    (dolist (pair (entity-handle-data entity))
      (when (consp pair)
        (cond ((group-code-equal-p (car pair) 10) (push (cons (%xy (cdr pair)) 0.0d0) pairs))
              ((and pairs (group-code-equal-p (car pair) 42))
               (setf (cdr (first pairs)) (%num (cdr pair)))))))
    (setf pairs (nreverse pairs))
    (let ((spans (if closed (append pairs (list (first pairs))) pairs)))
      (loop for ((p . b) (q . nil)) on spans while q
            do (%command-entity host (%span-entity-data entity p q b z))))
    (%erase-entity-and-run host entity)))

(defun %cmd-explode (host tokens)
  (multiple-value-bind (entities rest) (%command-selection host tokens)
    (dolist (e entities)
      (case (entity-handle-kind e)
        (:lwpolyline (%explode-lwpolyline host e))))
    rest))

;;; --- STRETCH: crossing window(s), RETURN, base point, second point ----
;;; Measured on BricsCAD: (0,0)-(4,0), crossing (3,-1)-(5,1), (4,0)->(6,1)
;;; moves the end INSIDE the window to (6,1); the other end stays. An
;;; object wholly inside moves whole. (A headless AutoCAD selects nothing
;;; by window -- it has no view.)
(defun %cmd-stretch (host tokens)
  (let ((windows '()) (entities '()))
    (loop
      (let ((token (first tokens)))
        (cond ((null tokens) (return))
              ((equal token "") (pop tokens) (return))
              ((and (%command-option-p token "c" "crossing")
                    (%command-token-point (second tokens))
                    (%command-token-point (third tokens)))
               (let ((p1 (%command-token-point (second tokens)))
                     (p2 (%command-token-point (third tokens))))
                 (push (list p1 p2) windows)
                 (dolist (e (%window-selection host p1 p2 t)) (pushnew e entities))
                 (setf tokens (cdddr tokens))))
              (t (multiple-value-bind (more rest) (%command-selection host (list token))
                   (unless more (return))
                   (dolist (e more) (pushnew e entities))
                   (setf tokens (append rest (rest tokens))))))))
    (let ((base (%command-token-point (first tokens)))
          (second (%command-token-point (second tokens))))
      (when (and base second)
        (setf tokens (cddr tokens))
        (let ((d (%v- second base)))
          (flet ((inside-p (p)
                   (some (lambda (w) (multiple-value-bind (x0 y0 x1 y1)
                                         (%rect-corners (first w) (second w))
                                       (%point-in-rect-p (%xy p) x0 y0 x1 y1)))
                         windows))
                 (moved (p) (if (cddr p)
                                (list (+ (first p) (first d)) (+ (second p) (second d))
                                      (+ (third p) (or (third d) 0.0d0)))
                                (list (+ (first p) (first d)) (+ (second p) (second d))))))
            (dolist (e entities)
              (if (and windows
                       (some (lambda (w) (%outline-in-window-p (%entity-outline host e)
                                                               (first w) (second w)))
                             windows))
                  (%entity-translate e (first d) (second d) (or (third d) 0.0d0))
                  (case (entity-handle-kind e)
                    ((:line :lwpolyline :solid :trace)
                     (dolist (pair (entity-handle-data e))
                       (when (and (consp pair)
                                  (member (car pair) '(10 11 12 13) :test #'group-code-equal-p)
                                  (inside-p (cdr pair)))
                         (setf (cdr pair) (moved (cdr pair))))))
                    (t (when (inside-p (%entity-group-value e 10))
                         (%entity-translate e (first d) (second d)
                                            (or (third d) 0.0d0))))))))))
      tokens)))

;;; --- LENGTHEN: _DElta / _Total / _Percent, then picks until RETURN ----
;;; Measured on BricsCAD: _DE 1, pick (4,0) on (0,0)-(4,0) -> (0,0)-(5,0):
;;; the end NEAREST the pick moves along the line.
(defun %cmd-lengthen (host tokens)
  (let ((mode nil) (amount nil))
    (cond ((%command-option-p (first tokens) "de" "delta") (setf mode :delta))
          ((%command-option-p (first tokens) "t" "total") (setf mode :total))
          ((%command-option-p (first tokens) "p" "percent") (setf mode :percent)))
    (unless mode (return-from %cmd-lengthen tokens))
    (pop tokens)
    (setf amount (%command-token-number (first tokens)))
    (unless amount (return-from %cmd-lengthen tokens))
    (pop tokens)
    (loop
      (let ((pick (%command-token-point (first tokens))))
        (cond ((null tokens) (return))
              ((equal (first tokens) "") (pop tokens) (return))
              ((null pick) (return))
              (t (pop tokens)
                 (let ((e (%pick-entity host pick)))
                   (when (and e (eq (entity-handle-kind e) :line))
                     (let* ((a (%entity-group-value e 10)) (b (%entity-group-value e 11))
                            (at-b (<= (%vlen (%v- (%xy pick) (%xy b)))
                                      (%vlen (%v- (%xy pick) (%xy a)))))
                            (from (if at-b a b)) (to (if at-b b a))
                            (len (%vlen (%v- to from)))
                            (new-len (ecase mode
                                       (:delta (+ len amount))
                                       (:total amount)
                                       (:percent (* len (/ amount 100.0d0)))))
                            (end (%v+ from (%v* new-len (%vunit (%v- to from))))))
                       (%entity-set-group e (if at-b 11 10) end))))))))
    tokens))

;;; --- MATCHPROP: source object, destination objects until RETURN -------
;;; Measured on BricsCAD: the destination takes the source's colour (and
;;; layer, linetype ... ); a property the source has BYLAYER is removed.
(defun %cmd-matchprop (host tokens)
  (multiple-value-bind (sources rest) (%command-selection host (list (first tokens)))
    (declare (ignore rest))
    (let ((source (first sources)))
      (unless source (return-from %cmd-matchprop tokens))
      (multiple-value-bind (targets rest) (%command-selection host (rest tokens))
        (dolist (e targets)
          (unless (eq e source)
            (%entity-set-group e 8 (%entity-group-value source 8))
            (dolist (code *property-codes*)
              (let ((v (%entity-group-value source code)))
                (if v (%entity-set-property e code v) (%entity-remove-group e code))))))
        rest))))

;;; --- SETBYLAYER: selection, RETURN, then the two yes/no questions -----
;;; Measured on BricsCAD: a colour override is removed (ByLayer).
(defun %cmd-setbylayer (host tokens)
  (multiple-value-bind (entities rest) (%command-selection host tokens)
    (loop repeat 2 while (%command-option-p (first rest) "y" "yes" "n" "no") do (pop rest))
    (dolist (e entities)
      (dolist (code '(62 6 370 440)) (%entity-remove-group e code)))
    rest))

;;; --- CONVERTPOLY: _Heavy / _Light, selection --------------------------
;;; Measured on BricsCAD: an LWPOLYLINE becomes a POLYLINE (70 = 0, closed
;;; bit kept) with one VERTEX (70 = 0) per vertex and a SEQEND.
(defun %cmd-convertpoly (host tokens)
  (let ((heavy (%command-option-p (first tokens) "h" "heavy")))
    (unless (or heavy (%command-option-p (first tokens) "l" "light"))
      (return-from %cmd-convertpoly tokens))
    (pop tokens)
    (multiple-value-bind (entities rest) (%command-selection host tokens)
      (when heavy
        (dolist (e entities)
          (when (eq (entity-handle-kind e) :lwpolyline)
            (let ((layer (%entity-group-value e 8))
                  (z (%num (or (%entity-group-value e 38) 0.0d0)))
                  (closed (logtest 1 (or (%entity-group-value e 70) 0)))
                  (vertices '()))
              (dolist (pair (entity-handle-data e))
                (when (consp pair)
                  (cond ((group-code-equal-p (car pair) 10)
                         (push (list (%xy (cdr pair)) 0.0d0) vertices))
                        ((and vertices (group-code-equal-p (car pair) 42))
                         (setf (second (first vertices)) (%num (cdr pair)))))))
              (%command-entity host (list (cons 0 "POLYLINE") (cons 8 layer) (cons 66 1)
                                          (cons 10 (list 0.0d0 0.0d0 z))
                                          (cons 70 (if closed 1 0))))
              (dolist (v (nreverse vertices))
                (%command-entity host (append (list (cons 0 "VERTEX") (cons 8 layer)
                                                    (cons 10 (append (first v) (list z))))
                                              (unless (zerop (second v))
                                                (list (cons 42 (second v))))
                                              (list (cons 70 0)))))
              (%command-entity host (list (cons 0 "SEQEND") (cons 8 layer)))
              (%erase-entity-and-run host e)))))
      rest)))

(define-cador-command "CHPROP"      '%cmd-chprop)
(define-cador-command "CHANGE"      '%cmd-change)
(define-cador-command "SCALE"       '%cmd-scale)
(define-cador-command "ALIGN"       '%cmd-align)
(define-cador-command "EXPLODE"     '%cmd-explode)
(define-cador-command "STRETCH"     '%cmd-stretch)
(define-cador-command "LENGTHEN"    '%cmd-lengthen)
(define-cador-command "MATCHPROP"   '%cmd-matchprop)
(define-cador-command "SETBYLAYER"  '%cmd-setbylayer)
(define-cador-command "CONVERTPOLY" '%cmd-convertpoly)
