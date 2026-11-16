(in-package #:clautolisp.cador)

;;;; Selection-set HAL methods on cador (Phase 11).
;;;;
;;;; Implements: host-ssget, host-ssadd, host-ssdel, host-ssname,
;;;; host-sslength, host-ssmemb, host-ssgetfirst, host-sssetfirst.
;;;;
;;;; AutoLISP-visible PICKSET wraps the host-internal pickset's id;
;;;; the host stores the pickset itself in cador-picksets keyed
;;;; on that same id.

;;; --- Pickset wrapping helpers ------------------------------------

(defun pickset->ap (pickset)
  "Wrap a host-internal pickset in an AutoLISP autolisp-pickset
value carrying its id."
  (clautolisp.autolisp-runtime:make-autolisp-pickset
   :value (pickset-id pickset)))

(defun ap->pickset (host ap operator-name)
  "Resolve an AutoLISP autolisp-pickset value back to the host's
internal pickset struct, signalling :invalid-pickset on type or
identity mismatch."
  (unless (typep ap 'clautolisp.autolisp-runtime:autolisp-pickset)
    (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
     :invalid-pickset
     "~A expects a PICKSET, got ~S."
     operator-name ap))
  (let* ((id (clautolisp.autolisp-runtime:autolisp-pickset-value ap))
         (set (gethash id (cador-picksets host))))
    (or set
        (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
         :invalid-pickset
         "~A: pickset has been released or never existed: ~S."
         operator-name ap))))

(defun cador-register-pickset (host pickset)
  (setf (gethash (pickset-id pickset) (cador-picksets host)) pickset)
  pickset)

;;; --- Filter-list matching ----------------------------------------
;;;
;;; A filter list is a list of dotted pairs (CODE . VALUE). An entity
;;; matches the filter iff every pair matches one of its data list
;;; entries with the same CODE and a compatible VALUE.
;;;
;;; String values support comma-separated alternation and the AutoCAD
;;; wildcard grammar (re-using wcmatch via the autolisp-builtins-core
;;; layer's helpers — but those live in a sibling system, so we
;;; reimplement the small subset we need here to keep the dependency
;;; graph clean).
;;;
;;; Group code -4 (logical-operator alternation: <AND, <OR, <NOT,
;;; <XOR plus their > closers) is *not* yet honoured; entities are
;;; assumed to AND-match every supplied pair. Phase 12+ may extend.

(defun cador-string-value (object)
  "Return the host CL-string corresponding to OBJECT (an
AutoLISP-string wrapper, a CL string, or nil)."
  (cond
    ((null object) nil)
    ((typep object 'clautolisp.autolisp-runtime:autolisp-string)
     (clautolisp.autolisp-runtime:autolisp-string-value object))
    ((stringp object) object)
    (t nil)))

(defun simple-wildcard-match-p (text pattern)
  "Minimal AutoCAD WCMATCH grammar — comma-separated alternation
with `*` and `?` wildcards. Sufficient for ssget filters; the
full grammar lives in autolisp-builtins-core."
  (loop for s = 0 then (1+ pos)
        for pos = (position #\, pattern :start s)
        for alt = (subseq pattern s (or pos (length pattern)))
        thereis (single-wildcard-match-p text alt)
        while pos))

(defun single-wildcard-match-p (text pattern)
  (let ((tlen (length text))
        (plen (length pattern)))
    (labels ((rec (ti pj)
               (cond
                 ((= pj plen) (= ti tlen))
                 ((char= (char pattern pj) #\*)
                  (or (rec ti (1+ pj))
                      (and (< ti tlen) (rec (1+ ti) pj))))
                 ((= ti tlen) nil)
                 ((char= (char pattern pj) #\?) (rec (1+ ti) (1+ pj)))
                 (t (and (char= (char pattern pj) (char text ti))
                         (rec (1+ ti) (1+ pj)))))))
      (rec 0 0))))

(defun filter-value-match-p (target actual)
  "Return non-nil iff ACTUAL satisfies the filter TARGET. Strings
match by alternation/wildcard; numbers by =; everything else by
EQUAL."
  (cond
    ((or (stringp target)
         (typep target 'clautolisp.autolisp-runtime:autolisp-string))
     (let ((target-str (cador-string-value target))
           (actual-str (cador-string-value actual)))
       (and target-str actual-str
            (simple-wildcard-match-p actual-str target-str))))
    ((and (numberp target) (numberp actual)) (= target actual))
    (t (equal target actual))))

(defun group-code-equal-pair (code pair)
  (and (consp pair) (group-code-equal-p code (car pair))))

;;; --- ssget filter grammar (full) ---------------------------------
;;;
;;; A filter list is a flat list of dotted pairs. Most pairs are
;;; ordinary attribute tests (CODE . VALUE). Interspersed are:
;;;
;;;   -3  xdata application filter: value is a list of per-application
;;;       sublists ((APPNAME . xdata-pairs) ...); an entity matches when
;;;       it carries xdata registered under each requested application.
;;;
;;;   -4  a relational or logical operator, encoded as a string:
;;;         relational: "=", "/=", "!=", "<", ">", "<=", ">=",
;;;                     "&" (bit-AND non-zero), "&=" (masked-equal),
;;;                     "*" (value present, any) — applies to the pair
;;;                     that immediately follows.
;;;         logical:    "<AND".."AND>", "<OR".."OR>", "<XOR".."XOR>",
;;;                     "<NOT".."NOT>" — bracket a nested test sequence.
;;;
;;; Top-level tests combine with implicit AND. The grammar is parsed
;;; into a tree of predicate closures once, then evaluated per entity.

(defparameter *ss-logical-openers*
  '(("<AND" . "AND>") ("<OR" . "OR>") ("<XOR" . "XOR>") ("<NOT" . "NOT>")))

(defparameter *ss-relational-ops*
  '("=" "/=" "!=" "<" ">" "<=" ">=" "&" "&=" "*"))

(defun %ss-operator (pair)
  "The operator string of a (-4 . \"OP\") cell, or NIL if PAIR is not one."
  (and (consp pair) (group-code-equal-p (car pair) -4)
       (cador-string-value (cdr pair))))

(defun %entity-values-for-code (entity code)
  "All values the entity carries under group CODE, in order (a code may
repeat, e.g. multiple 10 vertices)."
  (loop for pair in (entity-handle-data entity)
        when (and (consp pair) (group-code-equal-p code (car pair)))
          collect (cdr pair)))

(defun %ss-numeric (x)
  (and (numberp x) x))

(defun %ss-relational-satisfied-p (op target-value actual-value)
  "True iff ACTUAL-VALUE (a stored pure-CL value) satisfies OP against
the filter TARGET-VALUE."
  (cond
    ((string= op "*") t)                ; presence: any value matches
    ((or (string= op "=")) (filter-value-match-p target-value actual-value))
    ((or (string= op "/=") (string= op "!="))
     (not (filter-value-match-p target-value actual-value)))
    ;; Numeric / ordered comparisons.
    ((member op '("<" ">" "<=" ">=") :test #'string=)
     (let ((tv (%ss-numeric target-value)) (av (%ss-numeric actual-value)))
       (if (and tv av)
           (cond ((string= op "<")  (< av tv))
                 ((string= op ">")  (> av tv))
                 ((string= op "<=") (<= av tv))
                 ((string= op ">=") (>= av tv)))
           ;; String ordering fallback.
           (let ((ts (cador-string-value target-value))
                 (as (cador-string-value actual-value)))
             (and ts as
                  (cond ((string= op "<")  (string< as ts))
                        ((string= op ">")  (string> as ts))
                        ((string= op "<=") (string<= as ts))
                        ((string= op ">=") (string>= as ts))))))))
    ;; Bitwise group tests (integer codes).
    ((string= op "&")
     (let ((tv (%ss-numeric target-value)) (av (%ss-numeric actual-value)))
       (and tv av (integerp tv) (integerp av) (not (zerop (logand tv av))))))
    ((string= op "&=")
     (let ((tv (%ss-numeric target-value)) (av (%ss-numeric actual-value)))
       (and tv av (integerp tv) (integerp av) (= (logand tv av) tv))))
    (t nil)))

(defun %ss-xdata-groups (entity)
  "The entity's per-application xdata groups ((APPNAME . pairs) ...),
or NIL."
  (let ((cell (find-if #'xdata-cell-p (entity-handle-data entity))))
    (and cell (cdr cell))))

(defun %ss-xdata-matches-p (entity app-sublists)
  "True iff ENTITY carries xdata satisfying every APP sublist in the -3
filter APP-SUBLISTS. Each sublist is (APPNAME . xdata-pairs); the entity
must have xdata under an application matching APPNAME (wildcard), and any
extra xdata pairs in the sublist must be present under that application."
  (let ((groups (%ss-xdata-groups entity)))
    (every
     (lambda (sub)
       (let* ((name (cador-string-value (car sub)))
              (match (and name
                          (find-if (lambda (g)
                                     (and (consp g) (stringp (car g))
                                          (simple-wildcard-match-p (car g) name)))
                                   groups))))
         (and match
              ;; Optional inner pair constraints (rarely used): each
              ;; requested (code . value) pair must appear in the app's
              ;; xdata.
              (every (lambda (want)
                       (and (consp want)
                            (find-if (lambda (have)
                                       (and (consp have)
                                            (group-code-equal-p (car want) (car have))
                                            (filter-value-match-p (cdr want) (cdr have))))
                                     (cdr match))))
                     (cdr sub)))))
     app-sublists)))

(defun %ss-plain-node (pair)
  "A predicate for an ordinary (CODE . VALUE) filter pair. Group -3 is
the xdata application filter; every other code is an attribute test that
succeeds when any of the entity's pairs under CODE matches VALUE."
  (let ((code (car pair)) (value (cdr pair)))
    (if (group-code-equal-p code -3)
        (let ((app-sublists (if (listp value) value (list value))))
          (lambda (entity) (%ss-xdata-matches-p entity app-sublists)))
        (lambda (entity)
          (some (lambda (actual) (filter-value-match-p value actual))
                (%entity-values-for-code entity code))))))

(defun %ss-relational-node (op target-pair)
  "A predicate applying relational OP to TARGET-PAIR (CODE . VALUE)."
  (if (null target-pair)
      (constantly nil)
      (let ((code (car target-pair)) (value (cdr target-pair)))
        (lambda (entity)
          (let ((actuals (%entity-values-for-code entity code)))
            (if (string= op "*")
                (and actuals t)
                (some (lambda (actual)
                        (%ss-relational-satisfied-p op value actual))
                      actuals)))))))

(defun %ss-group-node (opener sub-nodes)
  "A predicate combining SUB-NODES under the logical OPENER string."
  (cond
    ((string= opener "<AND")
     (lambda (entity) (every (lambda (n) (funcall n entity)) sub-nodes)))
    ((string= opener "<OR")
     (lambda (entity) (some (lambda (n) (funcall n entity)) sub-nodes)))
    ((string= opener "<XOR")
     (lambda (entity)
       (oddp (count-if (lambda (n) (funcall n entity)) sub-nodes))))
    ((string= opener "<NOT")
     (lambda (entity)
       (not (every (lambda (n) (funcall n entity)) sub-nodes))))
    (t (constantly nil))))

(defun %parse-ss-tests (pairs closer)
  "Parse PAIRS into a list of predicate closures until CLOSER (an
operator string like \"AND>\") is consumed, or the list ends. Returns
 (values NODES REMAINING-PAIRS)."
  (let ((nodes '()))
    (loop
      (when (null pairs)
        (return (values (nreverse nodes) nil)))
      (let* ((pair (first pairs))
             (op (%ss-operator pair)))
        (cond
          ((and closer op (string= op closer))
           (return (values (nreverse nodes) (rest pairs))))
          ((and op (assoc op *ss-logical-openers* :test #'string=))
           (let ((sub-closer (cdr (assoc op *ss-logical-openers* :test #'string=))))
             (multiple-value-bind (sub-nodes rest)
                 (%parse-ss-tests (rest pairs) sub-closer)
               (push (%ss-group-node op sub-nodes) nodes)
               (setf pairs rest))))
          ((and op (member op *ss-relational-ops* :test #'string=))
           (push (%ss-relational-node op (second pairs)) nodes)
           (setf pairs (cddr pairs)))
          (op
           ;; Unknown / stray -4 operator (including an unmatched closer):
           ;; skip it rather than crash — vendor tolerates malformed tails.
           (setf pairs (rest pairs)))
          (t
           (push (%ss-plain-node pair) nodes)
           (setf pairs (rest pairs))))))))

(defun entity-matches-filter-p (entity filter)
  "True iff ENTITY satisfies the ssget FILTER list. Top-level tests
combine with AND. Malformed filters degrade to a partial match rather
than signalling (the builtin layer validates gross filter shape)."
  (or (null filter)
      (multiple-value-bind (nodes rest) (%parse-ss-tests filter nil)
        (declare (ignore rest))
        (every (lambda (node) (funcall node entity)) nodes))))

;;; --- Window / crossing geometry ---------------------------------------
;;;
;;; (ssget "_W" P1 P2) selects the entities lying ENTIRELY inside the
;;; rectangle P1-P2, (ssget "_C" P1 P2) those INSIDE OR CROSSING it -- an
;;; entity crossing a boundary with no vertex inside included
;;; (ssget-crossing-selection-unsupported). The rectangle is taken in the XY
;;; plane of the WCS: cador has no view, and its UCS is the WCS.
;;; SPEC-UNCERTAIN: the vendors' view-dependent behaviour (an entity off
;;; screen) and a non-world UCS are not modelled.
;;;
;;; Exact for LINE, LWPOLYLINE (straight segments; a bulge is taken as its
;;; chord), CIRCLE, ARC (sampled), POINT; the other kinds use the entity's
;;; conservative bounding box (%ENTITY-BOUNDING-BOX), so a crossing may
;;; over-select one whose box, not its ink, meets the rectangle.

(defun %ss-num (x) (coerce x 'double-float))

(defun %ss-rect (p1 p2)
  "(XMIN YMIN XMAX YMAX) of the rectangle with corners P1 and P2."
  (let ((x1 (%ss-num (first p1))) (y1 (%ss-num (second p1)))
        (x2 (%ss-num (first p2))) (y2 (%ss-num (second p2))))
    (list (min x1 x2) (min y1 y2) (max x1 x2) (max y1 y2))))

(defun %ss-in-rect-p (x y rect)
  (destructuring-bind (x0 y0 x1 y1) rect
    (and (<= x0 x x1) (<= y0 y y1))))

(defun %ss-segment-meets-rect-p (ax ay bx by rect)
  "True when the segment A-B has a point in RECT (Liang-Barsky clipping)."
  (destructuring-bind (x0 y0 x1 y1) rect
    (let ((dx (- bx ax)) (dy (- by ay)) (t0 0d0) (t1 1d0))
      (flet ((clip (p q)
               ;; p * t <= q
               (cond ((zerop p) (>= q 0))
                     (t (let ((r (/ q p)))
                          (if (< p 0)
                              (when (<= r t1) (setf t0 (max t0 r)) t)
                              (when (>= r t0) (setf t1 (min t1 r)) t)))))))
        (and (clip (- dx) (- ax x0))
             (clip dx (- x1 ax))
             (clip (- dy) (- ay y0))
             (clip dy (- y1 ay))
             (<= t0 t1))))))

(defun %ss-polyline-meets-rect-p (points closed rect)
  (loop for (a b) on (if (and closed (cddr points))
                         (append points (list (first points)))
                         points)
        while b
        thereis (%ss-segment-meets-rect-p (first a) (second a) (first b) (second b) rect)))

(defun %ss-circle-meets-rect-p (cx cy r rect)
  "True when the CIRCLE (the curve, not the disk) has a point in RECT: the
rectangle's nearest point is within R of the centre, and its farthest
corner is not strictly inside the circle (else the rectangle sits inside
the circle, touching no part of the curve)."
  (destructuring-bind (x0 y0 x1 y1) rect
    (let* ((nx (max x0 (min cx x1))) (ny (max y0 (min cy y1)))
           (near (sqrt (+ (expt (- nx cx) 2) (expt (- ny cy) 2))))
           (far (sqrt (+ (expt (max (abs (- x0 cx)) (abs (- x1 cx))) 2)
                         (expt (max (abs (- y0 cy)) (abs (- y1 cy))) 2)))))
      (and (<= near r) (>= far r)))))

(defun %ss-arc-points (cx cy r a0 a1 &optional (steps 64))
  "Points along the counter-clockwise arc from A0 to A1 (radians)."
  (let ((sweep (let ((s (- a1 a0))) (if (<= s 0) (+ s (* 2 pi)) s))))
    (loop for i from 0 to steps
          for a = (+ a0 (* sweep (/ i steps)))
          collect (list (+ cx (* r (cos a))) (+ cy (* r (sin a)))))))

(defun %ss-xy (point) (list (%ss-num (first point)) (%ss-num (second point))))

(defun %ss-lwpolyline-points (entity)
  (loop for pair in (entity-handle-data entity)
        when (and (consp pair) (group-code-equal-p (car pair) 10) (consp (cdr pair)))
          collect (%ss-xy (cdr pair))))

(defun %ss-entity-outline (entity)
  "(values POINTS CLOSED) tracing ENTITY's ink as a polyline, or NIL for a
kind with no exact outline here (the bounding box is used for it)."
  (case (entity-handle-kind entity)
    (:line (let ((a (%entity-group-value entity 10)) (b (%entity-group-value entity 11)))
             (and a b (values (list (%ss-xy a) (%ss-xy b)) nil))))
    (:lwpolyline (values (%ss-lwpolyline-points entity)
                         (let ((flags (%entity-group-value entity 70)))
                           (and (integerp flags) (logtest flags 1)))))
    (:arc (let ((c (%entity-group-value entity 10)) (r (%entity-group-value entity 40))
                (a0 (%entity-group-value entity 50)) (a1 (%entity-group-value entity 51)))
            (and c (realp r) (realp a0) (realp a1)
                 (values (%ss-arc-points (%ss-num (first c)) (%ss-num (second c)) (%ss-num r)
                                         (%ss-num a0) (%ss-num a1))
                         nil))))
    (:point (let ((p (%entity-group-value entity 10))) (and p (values (list (%ss-xy p)) nil))))
    (t nil)))

(defun %ss-entity-box (host entity)
  "ENTITY's (XMIN YMIN XMAX YMAX): exact for a CIRCLE, else from its outline,
else from %ENTITY-BOUNDING-BOX; NIL when it has no geometry."
  (if (eq (entity-handle-kind entity) :circle)
      (let ((c (%entity-group-value entity 10)) (r (%entity-group-value entity 40)))
        (and c (realp r)
             (let ((x (%ss-num (first c))) (y (%ss-num (second c))) (r (%ss-num r)))
               (list (- x r) (- y r) (+ x r) (+ y r)))))
      (let ((points (%ss-entity-outline entity)))
        (if points
            (list (reduce #'min points :key #'first) (reduce #'min points :key #'second)
                  (reduce #'max points :key #'first) (reduce #'max points :key #'second))
            (let ((box (ignore-errors (%entity-bounding-box host entity))))
              (and box (first box) (second box)
                   (list (%ss-num (first (first box))) (%ss-num (second (first box)))
                         (%ss-num (first (second box))) (%ss-num (second (second box))))))))))

(defun %ss-entity-inside-rect-p (host entity rect)
  "Window selection: ENTITY lies entirely inside RECT."
  (let ((box (%ss-entity-box host entity)))
    (and box
         (destructuring-bind (x0 y0 x1 y1) rect
           (destructuring-bind (bx0 by0 bx1 by1) box
             (and (<= x0 bx0) (<= bx1 x1) (<= y0 by0) (<= by1 y1)))))))

(defun %ss-entity-meets-rect-p (host entity rect)
  "Crossing selection: ENTITY has a point inside RECT or crosses its boundary."
  (if (eq (entity-handle-kind entity) :circle)
      (let ((c (%entity-group-value entity 10)) (r (%entity-group-value entity 40)))
        (and c (realp r)
             (%ss-circle-meets-rect-p (%ss-num (first c)) (%ss-num (second c)) (%ss-num r) rect)))
      (multiple-value-bind (points closed) (%ss-entity-outline entity)
        (if points
            (if (rest points)
                (%ss-polyline-meets-rect-p points closed rect)
                (%ss-in-rect-p (first (first points)) (second (first points)) rect))
            (let ((box (%ss-entity-box host entity)))
              (and box
                   (destructuring-bind (x0 y0 x1 y1) rect
                     (destructuring-bind (bx0 by0 bx1 by1) box
                       (and (<= bx0 x1) (<= x0 bx1) (<= by0 y1) (<= y0 by1))))))))))

(defun %ss-select-in-rect (host filter rect predicate)
  "The pickset AP of the graphical main-space entities satisfying PREDICATE
over RECT and FILTER, in creation order, or NIL when none does."
  (let ((matches '()))
    (dolist (handle (reverse (cador-creation-order host)))
      (let ((entity (gethash handle (cador-entities host))))
        (when (and entity (not (entity-handle-deleted-p entity))
                   (main-space-entity-p entity)
                   (clautolisp.drawing:graphical-entity-p entity)
                   (or (null filter) (entity-matches-filter-p entity filter))
                   (funcall predicate host entity rect))
          (push entity matches))))
    (and matches
         (let ((set (make-pickset :members (nreverse matches))))
           (cador-register-pickset host set)
           (pickset->ap set)))))

;;; --- Method definitions ------------------------------------------

(defmethod host-ssget ((host cador) filter &key mode points)
  ;; Phase-11 supported modes:
  ;;   "X" / "_X"     all entities, optionally filtered.
  ;;   nil            (interactive pick) — needs a pointer: signals
  ;;                  UNAVAILABLE-IN-HEADLESS-CONTEXT, code
  ;;                  :host-unavailable-headless (D1 §15). A design
  ;;                  boundary of a headless host, not a gap.
  ;; Other modes (window, crossing, fence, last, previous, etc.)
  ;; signal :unsupported-ssget-mode for now.
  (let ((mode-string (and mode (cador-string-value mode))))
    (cond
      ;; Inside a LISP command run by COMMAND, the selection comes from
      ;; COMMAND's remaining input, up to its RETURN (as on the vendors).
      ((and (null mode-string) (cador-pending-input host))
       (multiple-value-bind (entities rest)
           (%command-selection host (cador-pending-input host))
         (setf (cador-pending-input host) rest)
         (let ((members (remove-if-not (lambda (e) (or (null filter)
                                                       (entity-matches-filter-p e filter)))
                                       entities)))
           (and members
                (let ((set (make-pickset :members members)))
                  (cador-register-pickset host set)
                  (pickset->ap set))))))
      ((null mode-string)
       (signal-unavailable-in-headless host 'ssget))
      ((or (string-equal mode-string "X")
           (string-equal mode-string "_X"))
       (let* ((order (reverse (cador-creation-order host)))
              (matches '()))
         (dolist (handle order)
           (let ((entity (gethash handle (cador-entities host))))
             ;; The whole-database scan returns only graphical
             ;; main-space entities, exactly like the vendor:
             ;; dictionaries, xrecords and other non-graphical objects
             ;; are never selected by ssget, and neither are the
             ;; contents of block definitions.
             (when (and entity (not (entity-handle-deleted-p entity))
                        (main-space-entity-p entity)
                        (clautolisp.drawing:graphical-entity-p entity)
                        (or (null filter)
                            (entity-matches-filter-p entity filter)))
               (push entity matches))))
         (let ((set (make-pickset :members (nreverse matches))))
           (and (pickset-members set)
                (progn (cador-register-pickset host set)
                       (pickset->ap set))))))
      ((or (string-equal mode-string "I")
           (string-equal mode-string "_I"))
       ;; Implied (pickfirst) selection — the read side of sssetfirst's
       ;; storage. It is passive: no pointer, no geometry, no prompt, and
       ;; it never signals (ssget-implied-selection-not-graphical.issue).
       ;;   - PICKFIRST 0 suppresses it regardless of what is stored.
       ;;   - The stored set is *consumed* on read (vendor parity, pjb
       ;;     decision): a second (ssget "_I") without an intervening
       ;;     sssetfirst returns nil.
       ;;   - A FILTER applies the shared "_X" grammar to that set.
       (let ((pf (cador-pickfirst host))
             (cell (cador-sysvar host "PICKFIRST")))
         (cond
           ((and cell (eql 0 (sysvar-cell-value cell))) nil)
           ((null pf) nil)
           (t
            (let ((matches '()))
              (dolist (entity (pickset-members pf))
                (when (and entity (not (entity-handle-deleted-p entity))
                           (clautolisp.drawing:graphical-entity-p entity)
                           (or (null filter)
                               (entity-matches-filter-p entity filter)))
                  (push entity matches)))
              ;; Consume-on-read: taking the implied set clears it.
              (setf (cador-pickfirst host) nil)
              (let ((set (make-pickset :members (nreverse matches))))
                (and (pickset-members set)
                     (progn (cador-register-pickset host set)
                            (pickset->ap set)))))))))
      ((member mode-string '("W" "_W" "C" "_C") :test #'string-equal)
       ;; Window / crossing over the rectangle POINTS (two corners).
       (unless (and (= (length points) 2)
                    (every (lambda (p) (and (consp p) (realp (first p)) (realp (second p))))
                           points))
         (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
          :invalid-ssget-arguments
          "SSGET ~S needs two corner points, got ~S." mode-string points))
       (%ss-select-in-rect host filter (%ss-rect (first points) (second points))
                           (if (string-equal (string-left-trim "_" mode-string) "W")
                               #'%ss-entity-inside-rect-p
                               #'%ss-entity-meets-rect-p)))
      (t
       (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
        :unsupported-ssget-mode
        "cador does not yet support ssget mode ~S; accepted modes are ~S, ~S, ~S, ~S and ~S."
        mode-string "X" "_X" "_I" "_W" "_C")))))

(defmethod host-ssadd ((host cador) ap ename)
  ;; (ssadd)        — create a new empty pickset (handled via the
  ;;                  builtin's optional args).
  ;; (ssadd ENAME)  — create a new pickset containing one entity.
  ;; (ssadd ENAME PICKSET) — add ENAME to PICKSET, returning the
  ;;                          updated pickset (or PICKSET unchanged
  ;;                          if ENAME already a member).
  (cond
    ((and (null ap) (null ename))
     ;; (ssadd) -> empty pickset.
     (let ((set (make-pickset)))
       (cador-register-pickset host set)
       (pickset->ap set)))
    ((null ap)
     (let* ((handle (clautolisp.autolisp-runtime:autolisp-ename-value ename))
            (entity (cador-find-entity-by-handle host handle))
            (set (make-pickset :members (and entity (list entity)))))
       (cador-register-pickset host set)
       (pickset->ap set)))
    (t
     (let* ((set (ap->pickset host ap 'ssadd))
            (handle (clautolisp.autolisp-runtime:autolisp-ename-value ename))
            (entity (cador-find-entity-by-handle host handle)))
       (when (and entity (not (member entity (pickset-members set))))
         (setf (pickset-members set)
               (append (pickset-members set) (list entity))))
       ap))))

(defmethod host-ssdel ((host cador) ap ename)
  (let* ((set (ap->pickset host ap 'ssdel))
         (handle (clautolisp.autolisp-runtime:autolisp-ename-value ename))
         (entity (cador-find-entity-by-handle host handle)))
    (cond
      ((and entity (member entity (pickset-members set)))
       (setf (pickset-members set)
             (remove entity (pickset-members set)))
       ap)
      (t nil))))

(defmethod host-ssname ((host cador) ap index)
  (let* ((set (ap->pickset host ap 'ssname))
         (i (cond
              ((integerp index) index)
              (t
               (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
                :invalid-number-argument
                "ssname expects an integer index, got ~S."
                index))))
         (members (pickset-members set)))
    (cond
      ((or (minusp i) (>= i (length members))) nil)
      (t
       (let ((entity (nth i members)))
         (handle->ename host (entity-handle-id entity)))))))

(defmethod host-sslength ((host cador) ap)
  (length (pickset-members (ap->pickset host ap 'sslength))))

(defmethod host-ssmemb ((host cador) ap ename)
  (let* ((set (ap->pickset host ap 'ssmemb))
         (handle (clautolisp.autolisp-runtime:autolisp-ename-value ename))
         (entity (cador-find-entity-by-handle host handle)))
    (and entity (member entity (pickset-members set)) ename)))

(defmethod host-ssgetfirst ((host cador))
  ;; AutoLISP returns a list of (grip-set . pickset). cador has
  ;; no grip semantics; we model it as (nil . PICKSET).
  (let ((current (cador-pickfirst host)))
    (and current
         (list nil (pickset->ap current)))))

(defmethod host-sssetfirst ((host cador) ap)
  (cond
    ((null ap)
     (setf (cador-pickfirst host) nil)
     nil)
    (t
     (let ((set (ap->pickset host ap 'sssetfirst)))
       (setf (cador-pickfirst host) set)
       ap))))
