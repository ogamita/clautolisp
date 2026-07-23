;;;; clautolisp/autolisp-debug/tests/breakpoint-tests.lisp

(in-package #:clautolisp.debug.tests)

(in-suite debug-suite)

(defun run-collecting (context thread-info name &rest args)
  "Run (NAME . ARGS) under debugging on THREAD-INFO, collecting every
hit. Returns (values result hits-in-order)."
  (let ((hits '()))
    (let ((clautolisp.debug:*debug-hit-handler*
            (lambda (hit) (push hit hits) :continue)))
      (let ((result (clautolisp.debug:call-with-debugging
                     (lambda () (apply #'eval-call context name args))
                     :thread-info thread-info)))
        (values result (nreverse hits))))))

(defun fid-of (metadata)
  (clautolisp.debug:function-debug-metadata-function-id metadata))

(test breakpoint-fires-at-form-and-continues
  (let* ((context (fresh-context))
         (metas (define-and-instrument context +frob-source+ "FROB" "ID"))
         (frob-meta (first metas))
         (form-id (clautolisp.debug:find-form-id-at-line frob-meta 3))  ; (id x)
         (ti (clautolisp.debug:make-thread-debug-info :debug-flag t)))
    (clautolisp.debug:add-breakpoint ti (fid-of frob-meta) form-id :when :before)
    (multiple-value-bind (result hits) (run-collecting context ti "FROB" 7)
      (is (eql 7 result))                       ; continue resumes, value intact
      (is (= 1 (length hits)))
      (let ((hit (first hits)))
        (is (= form-id (clautolisp.debug:hit-form-id hit)))
        (is (eq :before (clautolisp.debug:hit-when hit)))
        (is (= 3 (clautolisp.source:source-position-start-line
                  (clautolisp.debug:hit-source-position hit))))))))

(test two-body-dispatch-skips-instrumentation-without-debugging
  ;; The same breakpoint never fires when the call runs outside a debug
  ;; session: the plain body has no poll points (plan §3a).
  (let* ((context (fresh-context))
         (frob-meta (first (define-and-instrument context +frob-source+ "FROB" "ID")))
         (form-id (clautolisp.debug:find-form-id-at-line frob-meta 3))
         (ti (clautolisp.debug:make-thread-debug-info :debug-flag t))
         (hits '()))
    (clautolisp.debug:add-breakpoint ti (fid-of frob-meta) form-id :when :before)
    (let ((clautolisp.debug:*debug-hit-handler* (lambda (h) (push h hits) :continue)))
      ;; plain eval — no call-with-debugging, *debugging* stays nil
      (let ((result (eval-call context "FROB" 7)))
        (is (eql 7 result))
        (is (null hits))))))

(test add-remove-list-breakpoints
  (let* ((context (fresh-context))
         (frob-meta (first (define-and-instrument context +frob-source+ "FROB" "ID")))
         (ti (clautolisp.debug:make-thread-debug-info :debug-flag t))
         (bp1 (clautolisp.debug:add-breakpoint ti (fid-of frob-meta) 0 :when :before))
         (bp2 (clautolisp.debug:add-breakpoint ti (fid-of frob-meta) 1 :when :after)))
    (is (= 2 (length (clautolisp.debug:list-breakpoints ti))))
    (clautolisp.debug:remove-breakpoint ti bp1)
    (is (= 1 (length (clautolisp.debug:list-breakpoints ti))))
    (is (eq bp2 (first (clautolisp.debug:list-breakpoints ti))))
    (clautolisp.debug:clear-breakpoints ti)
    (is (null (clautolisp.debug:list-breakpoints ti)))))

(test idempotent-breakpoint-keeps-one-per-poll-point
  ;; bug-aldo-duplicate-breakpoint: setting a plain breakpoint twice on the same
  ;; poll point keeps a single breakpoint (returned again, reported not-new),
  ;; never a duplicate. A conditioned breakpoint on the same point IS distinct.
  (let* ((context (fresh-context))
         (frob-meta (first (define-and-instrument context +frob-source+ "FROB" "ID")))
         (fid (fid-of frob-meta))
         (ti (clautolisp.debug:make-thread-debug-info :debug-flag t)))
    (multiple-value-bind (bp1 new1)
        (clautolisp.debug:add-breakpoint ti fid 1 :when :before)
      (is (not (null bp1)))
      (is (eq t new1))
      (multiple-value-bind (bp2 new2)
          (clautolisp.debug:add-breakpoint ti fid 1 :when :before)
        (is (eq bp1 bp2))            ; the same breakpoint is returned
        (is (null new2))             ; and reported as not newly created
        (is (= 1 (length (clautolisp.debug:list-breakpoints ti))))))
    ;; a conditioned breakpoint on the same poll point is a distinct behaviour
    (clautolisp.debug:add-breakpoint ti fid 1 :when :before
                                     :condition (lambda (hit) (declare (ignore hit)) t))
    (is (= 2 (length (clautolisp.debug:list-breakpoints ti))))))

(test request-nav-defers-without-a-fake-break
  ;; bug-aldo-nav-entry-and-breakpoint-flow §2: with *defer-nav-request* set,
  ;; REQUEST-NAV only queues the request and does NOT break (so the REPL opens it
  ;; afterwards, no synthetic toplevel poll-point). Without deferral it breaks
  ;; (the legacy path) and clears the request.
  (let* ((ti (clautolisp.debug:make-thread-debug-info :debug-flag t))
         (broke nil)
         (clautolisp.debug::*thread-debug-info* ti)
         (clautolisp.debug:*debug-hit-handler*
           (lambda (hit) (declare (ignore hit)) (setf broke t) :continue))
         (clautolisp.debug:*pending-nav-request* nil))
    ;; deferred: queue only, no break
    (let ((clautolisp.debug:*defer-nav-request* t))
      (clautolisp.debug:request-nav '(:function "FOO")))
    (is (equal '(:function "FOO") clautolisp.debug:*pending-nav-request*))
    (is (null broke))
    ;; not deferred: break, and the request is cleared afterwards
    (setf clautolisp.debug:*pending-nav-request* nil)
    (clautolisp.debug:request-nav '(:function "BAR"))
    (is (eq t broke))
    (is (null clautolisp.debug:*pending-nav-request*))))

(test bloom-summary-discriminates
  (let* ((context (fresh-context))
         (frob-meta (first (define-and-instrument context +frob-source+ "FROB" "ID")))
         (fid (fid-of frob-meta))
         (ti (clautolisp.debug:make-thread-debug-info :debug-flag t)))
    (clautolisp.debug:add-breakpoint ti fid 2 :when :before)
    (is (clautolisp.debug::summary-test ti fid 2))
    ;; an unrelated point is (almost surely) clear — different hash bucket
    (is (not (clautolisp.debug::summary-test ti 987654 321)))))

(test volatile-breakpoint-removed-on-first-hit
  (let* ((context (fresh-context))
         (frob-meta (first (define-and-instrument context +frob-source+ "FROB" "ID")))
         (form-id (clautolisp.debug:find-form-id-at-line frob-meta 3))
         (ti (clautolisp.debug:make-thread-debug-info :debug-flag t)))
    (clautolisp.debug:add-breakpoint ti (fid-of frob-meta) form-id :when :before :steady nil)
    (multiple-value-bind (result hits) (run-collecting context ti "FROB" 7)
      (is (eql 7 result))
      (is (= 1 (length hits)))
      ;; volatile breakpoint cleared the first time it fired (spec §6)
      (is (null (clautolisp.debug:list-breakpoints ti))))))

(test breakpoint-condition-gates-firing
  (let* ((context (fresh-context))
         (frob-meta (first (define-and-instrument context +frob-source+ "FROB" "ID")))
         (form-id (clautolisp.debug:find-form-id-at-line frob-meta 3)))
    ;; condition returns NIL → never stops
    (let ((ti (clautolisp.debug:make-thread-debug-info :debug-flag t)))
      (clautolisp.debug:add-breakpoint ti (fid-of frob-meta) form-id
                                       :when :before :condition (lambda (hit) (declare (ignore hit)) nil))
      (multiple-value-bind (result hits) (run-collecting context ti "FROB" 7)
        (is (eql 7 result))
        (is (null hits))))
    ;; condition returns T → stops
    (let ((ti (clautolisp.debug:make-thread-debug-info :debug-flag t)))
      (clautolisp.debug:add-breakpoint ti (fid-of frob-meta) form-id
                                       :when :before :condition (lambda (hit) (declare (ignore hit)) t))
      (multiple-value-bind (result hits) (run-collecting context ti "FROB" 7)
        (is (eql 7 result))
        (is (= 1 (length hits)))))))

(test debugging-reaches-instrumented-callee-from-instrumented-caller
  ;; A breakpoint at ID's entry fires when FROB (which calls ID) runs
  ;; under debugging — both are instrumented.
  (let* ((context (fresh-context))
         (metas (define-and-instrument context +frob-source+ "FROB" "ID"))
         (id-meta (second metas))
         (ti (clautolisp.debug:make-thread-debug-info :debug-flag t)))
    (clautolisp.debug:add-breakpoint ti (fid-of id-meta) 0 :when :before)  ; ID function entry
    (multiple-value-bind (result hits) (run-collecting context ti "FROB" 7)
      (is (eql 7 result))
      (is (= 1 (length hits)))
      (is (= (fid-of id-meta) (clautolisp.debug:hit-fid (first hits)))))))

(test instrumented-callee-debugged-through-uninstrumented-caller
  ;; DN-2: an instrumented function is debugged wherever it is called
  ;; from — including through an UNinstrumented caller (e.g. a library
  ;; function with no source). Here CALLER is loaded but NOT instrumented
  ;; and INNER is instrumented; a breakpoint in INNER must still fire.
  (let* ((context (fresh-context))
         (source (format nil "(defun inner (a) a)~%(defun caller (x) (inner x))")))
    ;; instrument ONLY inner; caller stays uninstrumented (no source / library)
    (load-tracked context source)
    (let* ((inner-meta (clautolisp.debug:instrument-usubr (usubr-named context "INNER")))
           (ti (clautolisp.debug:make-thread-debug-info :debug-flag t)))
      (is (not (clautolisp.debug:instrumentedp (usubr-named context "CALLER"))))
      (clautolisp.debug:add-breakpoint ti (fid-of inner-meta) 0 :when :before) ; INNER entry
      (multiple-value-bind (result hits) (run-collecting context ti "CALLER" 42)
        (is (eql 42 result))
        (is (= 1 (length hits)))                       ; fired despite uninstrumented CALLER
        (is (= (fid-of inner-meta) (clautolisp.debug:hit-fid (first hits))))))))

(test trace-action-runs-and-continues-without-stopping
  (let* ((context (fresh-context))
         (frob-meta (first (define-and-instrument context +frob-source+ "FROB" "ID")))
         (form-id (clautolisp.debug:find-form-id-at-line frob-meta 3))
         (ti (clautolisp.debug:make-thread-debug-info :debug-flag t))
         (traced '())
         (stops '()))
    (clautolisp.debug:add-breakpoint ti (fid-of frob-meta) form-id :when :before
                                     :action (lambda (hit) (push hit traced)))
    (let ((clautolisp.debug:*debug-hit-handler* (lambda (h) (push h stops) :continue)))
      (let ((result (clautolisp.debug:call-with-debugging
                     (lambda () (eval-call context "FROB" 7)) :thread-info ti)))
        (is (eql 7 result))
        (is (= 1 (length traced)))    ; the trace action ran
        (is (null stops))))))         ; but the program never stopped

;;; --- virtual (deferred) breakpoints — a not-yet-loaded file ---------
;;; (aldo-pre-debug.issue: recorded with top-level-form-relative
;;; positions, armed when the file is loaded / the function
;;; instrumented.)

(test virtual-breakpoint-arms-when-the-function-is-instrumented
  ;; Record a virtual breakpoint on FROB's (setq z (id x)) — line 3 col 3
  ;; of frob.lsp, anchored to the first body form (also line 3) — with
  ;; the file "not loaded" (no metadata). Instrumenting FROB must arm a
  ;; real breakpoint at that poll point on the recorded ti, drop the
  ;; pending record, and the breakpoint must fire.
  (let* ((context (fresh-context))
         (ti (clautolisp.debug:make-thread-debug-info :debug-flag t)))
    (multiple-value-bind (vb new-p)
        (clautolisp.debug:add-virtual-breakpoint ti "frob.lsp" "FROB" 3 3 3)
      (is (eq t new-p))
      (is (= 1 (length (clautolisp.debug:list-virtual-breakpoints))))
      ;; re-recording the same target is idempotent
      (multiple-value-bind (vb2 new2-p)
          (clautolisp.debug:add-virtual-breakpoint ti "frob.lsp" "FROB" 3 3 3)
        (is (eq vb vb2))
        (is (null new2-p))))
    (is (null (clautolisp.debug:list-breakpoints ti)))
    ;; "load" the file and instrument (as the first call under a debug
    ;; session would): the virtual breakpoint materializes.
    (load-tracked context +frob-source+ :source-name "frob.lsp")
    (let ((frob-meta (clautolisp.debug:instrument-usubr (usubr-named context "FROB"))))
      (is (null (clautolisp.debug:list-virtual-breakpoints)))       ; armed + dropped
      (let ((bps (clautolisp.debug:list-breakpoints ti)))
        (is (= 1 (length bps)))
        (is (= (fid-of frob-meta) (clautolisp.debug:breakpoint-fid (first bps))))
        (is (eql (clautolisp.debug:form-id-at-line-col frob-meta 3 3)
                 (clautolisp.debug:breakpoint-form-id (first bps)))))
      ;; and it fires
      (multiple-value-bind (result hits) (run-collecting context ti "FROB" 7)
        (is (eql 7 result))
        (is (= 1 (length hits)))
        (is (= 3 (clautolisp.source:source-position-start-line
                  (clautolisp.debug:hit-source-position (first hits)))))))))

(test virtual-breakpoint-survives-toplevel-forms-moving
  ;; The issue's core requirement: the record is RELATIVE to its
  ;; top-level form. Record against the original +frob-source+ layout
  ;; (target 3:3, anchor 3 — the first body form's line), then load a
  ;; file where the text above the defun changed (two comment lines
  ;; replace the one-line id defun): the whole form moved down by 1.
  ;; The anchor delta (new first-body-form line 4 - recorded 3)
  ;; re-derives the target as 4:3, which must resolve and arm — even
  ;; though the body form itself changed.
  (let* ((context (fresh-context))
         (ti (clautolisp.debug:make-thread-debug-info :debug-flag t))
         (moved-source (format nil ";; two lines were~%;; inserted above~%(defun frob (x / z)~%  (setq z (+ x 1))~%  z)")))
    (clautolisp.debug:add-virtual-breakpoint ti "frob.lsp" "FROB" 3 3 3)
    (load-tracked context moved-source :source-name "frob.lsp")
    (let ((frob-meta (clautolisp.debug:instrument-usubr (usubr-named context "FROB"))))
      (is (null (clautolisp.debug:list-virtual-breakpoints)))
      (let ((bps (clautolisp.debug:list-breakpoints ti)))
        (is (= 1 (length bps)))
        ;; the armed poll point is the (setq …) on the MOVED line 4
        (let ((pos (clautolisp.debug:form-id-position
                    frob-meta (clautolisp.debug:breakpoint-form-id (first bps)))))
          (is (= 4 (clautolisp.source:source-position-start-line pos)))
          (is (= 3 (clautolisp.source:source-position-start-column pos))))))))

(test virtual-breakpoint-for-another-function-stays-pending
  ;; A record naming a function OTHER than the one being instrumented
  ;; (or recorded on another file) must stay pending.
  (let* ((context (fresh-context))
         (ti (clautolisp.debug:make-thread-debug-info :debug-flag t)))
    (clautolisp.debug:add-virtual-breakpoint ti "other.lsp" "MISSING" 3 3 3)
    (load-tracked context +frob-source+ :source-name "frob.lsp")
    (clautolisp.debug:instrument-usubr (usubr-named context "FROB"))
    (is (= 1 (length (clautolisp.debug:list-virtual-breakpoints))))
    (is (null (clautolisp.debug:list-breakpoints ti)))
    ;; and the helpers see it
    (is (= 1 (length (clautolisp.debug:virtual-breakpoints-for-file "other.lsp"))))
    (let ((vb (first (clautolisp.debug:list-virtual-breakpoints))))
      (is (eq vb (clautolisp.debug:find-virtual-breakpoint
                  (clautolisp.debug:virtual-breakpoint-id vb))))
      (clautolisp.debug:remove-virtual-breakpoint vb)
      (is (null (clautolisp.debug:list-virtual-breakpoints))))))
