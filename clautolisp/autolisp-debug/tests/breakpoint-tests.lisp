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
