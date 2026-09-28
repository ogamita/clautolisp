;;;; clautolisp/autolisp-debug/tests/instrument-tests.lisp

(in-package #:clautolisp.debug.tests)

(in-suite debug-suite)

(defparameter +frob-source+
  ;; line 1: (defun id (a) a)
  ;; line 2: (defun frob (x / z)
  ;; line 3:   (setq z (id x))
  ;; line 4:   z)
  (format nil "(defun id (a) a)~%(defun frob (x / z)~%  (setq z (id x))~%  z)"))

(test instrument-builds-metadata-and-body
  (let* ((context (fresh-context))
         (metadata (first (define-and-instrument context +frob-source+ "FROB"))))
    (let ((usubr (usubr-named context "FROB")))
      (is (clautolisp.debug:instrumentedp usubr))
      ;; idempotent: re-instrumenting returns the same metadata
      (is (eq metadata (clautolisp.debug:instrument-usubr usubr)))
      ;; bound-names = formals + /-locals, in binding order: X then Z
      (is (equal '("X" "Z")
                 (mapcar #'clautolisp.autolisp-runtime:autolisp-symbol-name
                         (clautolisp.debug:function-debug-metadata-bound-names metadata))))
      ;; form-id 0 is the function wrapper (entry/exit)
      (is (eq :function-entry (clautolisp.debug:form-id-kind metadata 0)))
      ;; there is more than one poll point (entry + statements/sub-forms)
      (is (> (clautolisp.debug:function-debug-metadata-poll-point-count metadata) 1)))))

(test instrument-resolves-source-positions
  (let* ((context (fresh-context))
         (metadata (first (define-and-instrument context +frob-source+ "FROB")))
         ;; the (id x) call is on line 3
         (form-id (clautolisp.debug:find-form-id-at-line metadata 3)))
    (is (integerp form-id))
    (let ((position (clautolisp.debug:form-id-position metadata form-id)))
      (is (clautolisp.source:source-position-p position))
      (is (= 3 (clautolisp.source:source-position-start-line position))))))

(test registry-maps-function-id-to-metadata
  (let* ((context (fresh-context))
         (metadata (first (define-and-instrument context +frob-source+ "FROB")))
         (fid (clautolisp.debug:function-debug-metadata-function-id metadata)))
    (is (eq metadata (clautolisp.debug:metadata-for-function-id fid)))
    (is (eq metadata (clautolisp.debug:metadata-for-usubr (usubr-named context "FROB"))))))

(test quote-data-is-not-instrumented
  ;; A quoted list must survive instrumentation intact — the instrumenter
  ;; must not weave poll points into data.
  (let* ((context (fresh-context)))
    (define-and-instrument context "(defun q () (quote (a b c)))" "Q")
    ;; runs to the literal list under debugging without corruption
    (let ((result (clautolisp.debug:with-debugging ()
                    (eval-call context "Q"))))
      (is (equal '("A" "B" "C")
                 (mapcar #'clautolisp.autolisp-runtime:autolisp-symbol-name result))))))

;;; --- ensure-metadata-for-name: instrument on demand (aldo-pre-debug.issue) ---

(test ensure-metadata-instruments-a-loaded-but-uncalled-function
  ;; A function defined/loaded but never called has no metadata yet;
  ;; ensure-metadata-for-name must instrument it on demand so pre-debug
  ;; navigation and breakpoints work.
  (let ((context (fresh-context)))
    (load-tracked context +frob-source+)
    (let ((usubr (usubr-named context "FROB")))
      (is (not (clautolisp.debug:instrumentedp usubr)))       ; not yet instrumented
      (is (null (clautolisp.debug:metadata-for-name "FROB"))) ; not registered
      (let ((metadata (clautolisp.debug:ensure-metadata-for-name "FROB" context)))
        (is (not (null metadata)))
        (is (clautolisp.debug:instrumentedp usubr))            ; now instrumented
        (is (eq metadata (clautolisp.debug:metadata-for-name "FROB")))
        ;; case-insensitive, and idempotent (returns the same metadata)
        (is (eq metadata (clautolisp.debug:ensure-metadata-for-name "frob" context)))))))

(test ensure-metadata-returns-nil-for-unknown-name
  (let ((context (fresh-context)))
    (load-tracked context +frob-source+)
    (is (null (clautolisp.debug:ensure-metadata-for-name "NOSUCHFN" context)))))

;;; --- DEBUG-level instrument-on-defun + surfaced weave failures --------
;;; (the loader instruments interpreted code under a session; a weave that
;;; raises is reported, not silently swallowed into a frameless function).

(test defun-under-a-session-instruments-eagerly
  ;; A function DEFINED under an active debug session (as the loader runs a
  ;; file under --on-error debug) is instrumented at defun — debuggable
  ;; immediately, before any call. Outside a session it is not (covered by
  ;; ENSURE-METADATA-INSTRUMENTS-A-LOADED-BUT-UNCALLED-FUNCTION above).
  (let ((context (fresh-context)))
    (clautolisp.debug:with-debugging ()
      (load-tracked context +frob-source+))
    (is (clautolisp.debug:instrumentedp (usubr-named context "FROB")))
    (is (clautolisp.debug:instrumentedp (usubr-named context "ID")))))

(test weave-failure-is-surfaced-once-not-swallowed
  ;; When the instrumenter cannot weave a function, the runtime must WARN
  ;; (naming it) instead of silently leaving it frameless — and remember the
  ;; failure so it neither re-warns nor re-attempts on every call.
  (let ((context (fresh-context)))
    (load-tracked context +frob-source+)
    (let ((usubr (usubr-named context "FROB"))
          (calls 0))
      (let ((clautolisp.autolisp-runtime:*instrument-usubr-hook*
              (lambda (fn) (declare (ignore fn)) (incf calls) (error "synthetic gap"))))
        (signals warning
          (clautolisp.autolisp-runtime:instrument-usubr-if-possible usubr))
        (is (clautolisp.autolisp-runtime:autolisp-usubr-instrumentation-failed usubr))
        ;; second attempt: plain body (nil), no re-attempt of the failing weave
        (is (null (clautolisp.autolisp-runtime:instrument-usubr-if-possible usubr)))
        (is (= 1 calls))))))

;;; --- atom poll points (instrumenter-no-pollpoints-on-atoms) --------------

(defun %kinds (metadata)
  (coerce (clautolisp.debug:function-debug-metadata-form-id->kind metadata) 'list))

(defun %atom-form-ids (metadata)
  (loop for kind in (%kinds metadata)
        for form-id from 0
        when (clautolisp.debug:atom-form-kind-p kind) collect form-id))

(test atoms-get-no-poll-points-by-default
  "Off by default: turning it on renumbers poll points and changes what a step
stops on, so nothing changes for anyone who does not ask."
  (let* ((context (fresh-context))
         (clautolisp.debug:*instrument-atoms* nil)
         (clautolisp.debug:*instrument-atoms-predicate* nil)
         (metadata (first (define-and-instrument context +frob-source+ "FROB"))))
    (is (null (%atom-form-ids metadata)))
    ;; entry, (setq z (id x)), (id x)
    (is (= 3 (clautolisp.debug:function-debug-metadata-poll-point-count metadata)))))

(test atoms-get-poll-points-when-asked
  "With atom poll points on, the variable reference X in (id x) and the bare Z
that returns the local get their own poll points, positioned where they are
written -- but SETQ's place Z does not: it is not evaluated."
  (let* ((context (fresh-context))
         (clautolisp.debug:*instrument-atoms* t)
         (metadata (first (define-and-instrument context +frob-source+ "FROB")))
         (atoms (%atom-form-ids metadata)))
    ;; line 3 "  (setq z (id x))": X at column 15; line 4 "  z)": Z at column 3
    (is (= 2 (length atoms)) "the atoms woven: ~S (kinds ~S)" atoms (%kinds metadata))
    (is (every (lambda (id) (eq :variable (clautolisp.debug:form-id-kind metadata id))) atoms))
    (is (equal '((3 . 15) (4 . 3))
               (mapcar (lambda (id)
                         (let ((p (clautolisp.debug:form-id-position metadata id)))
                           (cons (clautolisp.source:source-position-start-line p)
                                 (clautolisp.source:source-position-start-column p))))
                       atoms)))
    ;; `break LINE' still means the statement: line 3 resolves to a compound
    ;; form, while line 4, which holds only the bare Z, falls back to it.
    (is (eq :form (clautolisp.debug:form-id-kind
                   metadata (clautolisp.debug:find-form-id-at-line metadata 3))))
    (is (eq :variable (clautolisp.debug:form-id-kind
                       metadata (clautolisp.debug:find-form-id-at-line metadata 4))))))

(test the-predicate-turns-atom-poll-points-on
  "The UI layer's `atom-poll-points' setting reaches the engine through
*INSTRUMENT-ATOMS-PREDICATE*, read when a function is woven."
  (let* ((context (fresh-context))
         (clautolisp.debug:*instrument-atoms* nil)
         (clautolisp.debug:*instrument-atoms-predicate* (lambda () t))
         (metadata (first (define-and-instrument context +frob-source+ "FROB"))))
    (is (= 2 (length (%atom-form-ids metadata))))))

(test a-breakpoint-stops-before-a-variable-is-read
  "The point of the feature: stop BEFORE X is evaluated in (id x), and running
on still gives the same answer -- the poll point around an atom is transparent."
  (let* ((context (fresh-context))
         (clautolisp.debug:*instrument-atoms* t)
         (metas (define-and-instrument context +frob-source+ "FROB" "ID"))
         (frob-meta (first metas))
         (x-id (first (%atom-form-ids frob-meta)))
         (ti (clautolisp.debug:make-thread-debug-info :debug-flag t)))
    (clautolisp.debug:add-breakpoint ti (fid-of frob-meta) x-id :when :before)
    (multiple-value-bind (result hits) (run-collecting context ti "FROB" 7)
      (is (eql 7 result))
      (is (= 1 (length hits)))
      (let ((hit (first hits)))
        (is (= x-id (clautolisp.debug:hit-form-id hit)))
        (is (eq :before (clautolisp.debug:hit-when hit)))
        (is (= 15 (clautolisp.source:source-position-start-column
                   (clautolisp.debug:hit-source-position hit))))))))

(test atom-poll-points-skip-the-places-that-are-not-evaluated
  "FOREACH's variable and SETQ's places are names, not references: a poll point
around them would turn them into forms. COND clauses are walked like any
operand list, so the test T is a :LITERAL and the clause bodies' atoms are
woven."
  (let* ((context (fresh-context))
         (clautolisp.debug:*instrument-atoms* t)
         (metadata (first (define-and-instrument
                              context
                              (format nil "(defun g (a / s)~%  (foreach v (quote (1 2)) (setq s v))~%  (cond (a s) (t 0)))")
                              "G")))
         (kinds (mapcar (lambda (id) (clautolisp.debug:form-id-kind metadata id))
                        (%atom-form-ids metadata))))
    ;; woven: V (the setq VALUE), A, S, T, 0 -- not the FOREACH V, not SETQ's S
    (is (= 3 (count :variable kinds)) "kinds ~S" kinds)
    (is (= 2 (count :literal kinds)) "kinds ~S" kinds)
    ;; and the function still runs correctly under debugging
    (let ((result (clautolisp.debug:with-debugging () (eval-call context "G" (rt-sym "T")))))
      (is (eql 2 result)))
    (let ((result (clautolisp.debug:with-debugging () (eval-call context "G" nil))))
      (is (eql 0 result)))))
