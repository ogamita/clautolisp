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

(defun entity-matches-filter-p (entity filter)
  (every (lambda (filter-pair)
           (let ((entity-pair (find (car filter-pair) (entity-handle-data entity)
                                     :test #'group-code-equal-pair)))
             (and entity-pair
                  (filter-value-match-p (cdr filter-pair) (cdr entity-pair)))))
         filter))

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
             (when (and entity (not (entity-handle-deleted-p entity))
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
