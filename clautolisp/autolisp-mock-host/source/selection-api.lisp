(in-package #:clautolisp.autolisp-mock-host)

;;;; Selection-set HAL methods on MockHost (Phase 11).
;;;;
;;;; Implements: host-ssget, host-ssadd, host-ssdel, host-ssname,
;;;; host-sslength, host-ssmemb, host-ssgetfirst, host-sssetfirst.
;;;;
;;;; AutoLISP-visible PICKSET wraps the host-internal pickset's id;
;;;; the host stores the pickset itself in mock-host-picksets keyed
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
         (set (gethash id (mock-host-picksets host))))
    (or set
        (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
         :invalid-pickset
         "~A: pickset has been released or never existed: ~S."
         operator-name ap))))

(defun mock-host-register-pickset (host pickset)
  (setf (gethash (pickset-id pickset) (mock-host-picksets host)) pickset)
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

(defun mock-string-value (object)
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
     (let ((target-str (mock-string-value target))
           (actual-str (mock-string-value actual)))
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
       (mock-string-value (cdr pair))))

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
           (let ((ts (mock-string-value target-value))
                 (as (mock-string-value actual-value)))
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
       (let* ((name (mock-string-value (car sub)))
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

;;; --- Method definitions ------------------------------------------

(defmethod host-ssget ((host mock-host) filter &key mode)
  ;; Phase-11 supported modes:
  ;;   "X" / "_X"     all entities, optionally filtered.
  ;;   nil            (interactive) — not supported headlessly,
  ;;                  signals :host-not-supported.
  ;; Other modes (window, crossing, fence, last, previous, etc.)
  ;; signal :unsupported-ssget-mode for now.
  (let ((mode-string (and mode (mock-string-value mode))))
    (cond
      ((null mode-string)
       (signal-host-not-supported host 'ssget))
      ((or (string-equal mode-string "X")
           (string-equal mode-string "_X"))
       (let* ((order (reverse (mock-host-creation-order host)))
              (matches '()))
         (dolist (handle order)
           (let ((entity (gethash handle (mock-host-entities host))))
             ;; The whole-database scan returns only graphical entities,
             ;; exactly like the vendor: dictionaries, xrecords and other
             ;; non-graphical objects are never selected by ssget.
             (when (and entity (not (entity-handle-deleted-p entity))
                        (clautolisp.drawing:graphical-entity-p entity)
                        (or (null filter)
                            (entity-matches-filter-p entity filter)))
               (push entity matches))))
         (let ((set (make-pickset :members (nreverse matches))))
           (and (pickset-members set)
                (progn (mock-host-register-pickset host set)
                       (pickset->ap set))))))
      (t
       (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
        :unsupported-ssget-mode
        "MockHost does not yet support ssget mode ~S; accepted modes are ~S and ~S."
        mode-string "X" "_X")))))

(defmethod host-ssadd ((host mock-host) ap ename)
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
       (mock-host-register-pickset host set)
       (pickset->ap set)))
    ((null ap)
     (let* ((handle (clautolisp.autolisp-runtime:autolisp-ename-value ename))
            (entity (mock-host-find-entity-by-handle host handle))
            (set (make-pickset :members (and entity (list entity)))))
       (mock-host-register-pickset host set)
       (pickset->ap set)))
    (t
     (let* ((set (ap->pickset host ap 'ssadd))
            (handle (clautolisp.autolisp-runtime:autolisp-ename-value ename))
            (entity (mock-host-find-entity-by-handle host handle)))
       (when (and entity (not (member entity (pickset-members set))))
         (setf (pickset-members set)
               (append (pickset-members set) (list entity))))
       ap))))

(defmethod host-ssdel ((host mock-host) ap ename)
  (let* ((set (ap->pickset host ap 'ssdel))
         (handle (clautolisp.autolisp-runtime:autolisp-ename-value ename))
         (entity (mock-host-find-entity-by-handle host handle)))
    (cond
      ((and entity (member entity (pickset-members set)))
       (setf (pickset-members set)
             (remove entity (pickset-members set)))
       ap)
      (t nil))))

(defmethod host-ssname ((host mock-host) ap index)
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
         (clautolisp.autolisp-runtime:make-autolisp-ename
          :value (entity-handle-id entity)))))))

(defmethod host-sslength ((host mock-host) ap)
  (length (pickset-members (ap->pickset host ap 'sslength))))

(defmethod host-ssmemb ((host mock-host) ap ename)
  (let* ((set (ap->pickset host ap 'ssmemb))
         (handle (clautolisp.autolisp-runtime:autolisp-ename-value ename))
         (entity (mock-host-find-entity-by-handle host handle)))
    (and entity (member entity (pickset-members set)) ename)))

(defmethod host-ssgetfirst ((host mock-host))
  ;; AutoLISP returns a list of (grip-set . pickset). MockHost has
  ;; no grip semantics; we model it as (nil . PICKSET).
  (let ((current (mock-host-pickfirst host)))
    (and current
         (list nil (pickset->ap current)))))

(defmethod host-sssetfirst ((host mock-host) ap)
  (cond
    ((null ap)
     (setf (mock-host-pickfirst host) nil)
     nil)
    (t
     (let ((set (ap->pickset host ap 'sssetfirst)))
       (setf (mock-host-pickfirst host) set)
       ap))))
