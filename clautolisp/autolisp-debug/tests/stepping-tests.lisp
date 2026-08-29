;;;; clautolisp/autolisp-debug/tests/stepping-tests.lisp
;;;;
;;;; Stepping (spec §6). Fixtures use only user functions; form-id
;;;; numbering is dense per function in instrumentation order:
;;;;   (defun id (a) a)                          ; 0=entry
;;;;   (defun frob (x / z) (setq z (id x)) z)    ; 0=entry 1=setq 2=(id x)
;;;;   (defun two (x / z) (setq z (id x)) (id z)); 0 1 2 3=(id z)

(in-package #:clautolisp.debug.tests)

(in-suite debug-suite)

(defun run-steps (context ti name args directive-fn)
  "Run (NAME . ARGS) under debugging; on each hit push it and return
(funcall DIRECTIVE-FN hit count). Returns (values result hits-in-order)."
  (let ((hits '()))
    (let ((clautolisp.debug:*debug-hit-handler*
            (lambda (hit)
              (push hit hits)
              (funcall directive-fn hit (length hits)))))
      (let ((result (clautolisp.debug:call-with-debugging
                     (lambda () (apply #'eval-call context name args))
                     :thread-info ti)))
        (values result (nreverse hits))))))

(defun hit-key (hit)
  (list (clautolisp.debug:hit-fid hit)
        (clautolisp.debug:hit-form-id hit)
        (clautolisp.debug:hit-when hit)))

(test step-into-descends-form-by-form-and-into-callee
  (let* ((context (fresh-context))
         (metas (define-and-instrument context +frob-source+ "FROB" "ID"))
         (frob (fid-of (first metas)))
         (id (fid-of (second metas)))
         (ti (clautolisp.debug:make-thread-debug-info :debug-flag t)))
    (clautolisp.debug:add-breakpoint ti frob 0 :when :before)   ; FROB entry
    (multiple-value-bind (result hits)
        (run-steps context ti "FROB" '(7)
                   (lambda (hit count) (declare (ignore hit))
                     (if (< count 4) '(:step :into) :continue)))
      (is (eql 7 result))
      ;; entry → setq stmt → (id x) → ID entry
      (is (equal (list (list frob 0 :before)
                       (list frob 1 :before)
                       (list frob 2 :before)
                       (list id 0 :before))
                 (mapcar #'hit-key hits))))))

(test step-over-skips-into-the-next-statement
  (let* ((context (fresh-context))
         (source (format nil "(defun id (a) a)~%(defun two (x / z)~%  (setq z (id x))~%  (id z))"))
         (metas (define-and-instrument context source "TWO" "ID"))
         (two (fid-of (first metas)))
         (ti (clautolisp.debug:make-thread-debug-info :debug-flag t)))
    ;; break at the setq statement (form-id 1); step over → next statement (id z) = form-id 3
    (clautolisp.debug:add-breakpoint ti two 1 :when :before)
    (multiple-value-bind (result hits)
        (run-steps context ti "TWO" '(5)
                   (lambda (hit count)
                     (if (eq (clautolisp.debug:hit-stop-reason hit) :breakpoint)
                         (progn (clautolisp.debug:clear-breakpoints ti) '(:step :over))
                         :continue)))
      (declare (ignore result))
      (is (= 2 (length hits)))
      (is (equal (list two 1 :before) (hit-key (first hits))))    ; the breakpoint
      (is (equal (list two 3 :before) (hit-key (second hits)))))))  ; stepped over (id x) to (id z)

(test step-out-returns-to-caller
  (let* ((context (fresh-context))
         (source (format nil "(defun id (a) a)~%(defun two (x / z)~%  (setq z (id x))~%  (id z))"))
         (metas (define-and-instrument context source "TWO" "ID"))
         (two (fid-of (first metas)))
         (id (fid-of (second metas)))
         (ti (clautolisp.debug:make-thread-debug-info :debug-flag t)))
    ;; break at ID entry (reached first via (id x)); step out → back in TWO,
    ;; at the :after of the call form (id x) = form-id 2 (just after the call).
    (clautolisp.debug:add-breakpoint ti id 0 :when :before)
    (multiple-value-bind (result hits)
        (run-steps context ti "TWO" '(5)
                   (lambda (hit count)
                     (if (eq (clautolisp.debug:hit-stop-reason hit) :breakpoint)
                         (progn (clautolisp.debug:clear-breakpoints ti) '(:step :out))
                         :continue)))
      (declare (ignore result))
      (is (= 2 (length hits)))
      (is (equal (list id 0 :before) (hit-key (first hits))))
      (is (= two (clautolisp.debug:hit-fid (second hits))))       ; returned to TWO
      (is (equal (list two 2 :after) (hit-key (second hits))))))) ; just after the (id x) call

(test advance-to-point-sets-volatile-breakpoint
  (let* ((context (fresh-context))
         (frob-meta (first (define-and-instrument context +frob-source+ "FROB" "ID")))
         (frob (fid-of frob-meta))
         (target (clautolisp.debug:find-form-id-at-line frob-meta 3))   ; (id x)
         (ti (clautolisp.debug:make-thread-debug-info :debug-flag t)))
    (clautolisp.debug:add-breakpoint ti frob 0 :when :before)   ; entry
    (multiple-value-bind (result hits)
        (run-steps context ti "FROB" '(7)
                   (lambda (hit count)
                     (if (eq (clautolisp.debug:hit-stop-reason hit) :breakpoint)
                         (progn (clautolisp.debug:clear-breakpoints ti)
                                (list :advance frob target :before))
                         :continue)))
      (is (eql 7 result))
      (is (= 2 (length hits)))
      (is (equal (list frob target :before) (hit-key (second hits)))))))

(test poll-point-at-maps-source-position-to-poll-point
  (let* ((context (fresh-context))
         (frob-meta (first (define-and-instrument context +frob-source+ "FROB" "ID")))
         (frob (fid-of frob-meta))
         (target 2)
         (position (clautolisp.debug:form-id-position frob-meta target)))
    (multiple-value-bind (fid form-id) (clautolisp.debug:poll-point-at position)
      (is (= frob fid))
      (is (= target form-id)))))

(test two-thread-stepping-over-the-queue
  (let* ((context (fresh-context))
         (frob-meta (first (define-and-instrument context +frob-source+ "FROB" "ID")))
         (frob (fid-of frob-meta))
         (ti (clautolisp.debug:make-thread-debug-info
              :debug-flag t
              :inbound (clautolisp.debug:make-blocking-queue)
              :outbound (clautolisp.debug:make-blocking-queue))))
    (clautolisp.debug:add-breakpoint ti frob 0 :when :before)
    (clautolisp.debug:run-debugged-thread
     (lambda () (eval-call context "FROB" 7)) :thread-info ti)
    (let ((m1 (clautolisp.debug:bq-pop (clautolisp.debug:thread-debug-info-outbound ti) 10)))
      (is (eq :hit (first m1)))
      (is (= 0 (clautolisp.debug:hit-form-id (second m1)))))     ; at entry
    (clautolisp.debug:step-thread ti :into)
    (let ((m2 (clautolisp.debug:bq-pop (clautolisp.debug:thread-debug-info-outbound ti) 10)))
      (is (eq :hit (first m2)))
      (is (= 1 (clautolisp.debug:hit-form-id (second m2)))))     ; stepped to setq stmt
    (clautolisp.debug:continue-thread ti)
    (let ((m3 (clautolisp.debug:bq-pop (clautolisp.debug:thread-debug-info-outbound ti) 10)))
      (is (eq :thread-exit (first m3)))
      (is (equal '(:value . 7) (second m3))))))
;;;; Where execution is: the CURRENT-PP slots.
;;;;
;;;; The poll point most recently entered is recorded on every poll point
;;;; -- twice per instrumented form -- so it is kept in two FIXNUM slots
;;;; rather than a cons: a cons there was two allocations per form of a
;;;; program that is merely being RUN under a session, and removing them
;;;; took 28% off everything a debugged run allocates.
;;;;
;;;; The subtlety a boolean replaced: NIL used to mean `no poll point
;;;; yet', which a cons could say and a pair of zeros cannot -- (0 . 0) is
;;;; a REAL poll point, function 0's entry form. Hence the separate
;;;; validity flag, and hence these tests.

(test current-pp-starts-invalid-and-reports-zeros
  "A fresh thread-debug-info has entered no poll point. The two readers
(BREAK-HERE and the error stop) must then report fid 0 / form-id 0 --
which is what they did when the slot was NIL, and what the validity flag
is for now that zeros are also a legitimate answer."
  (let ((ti (clautolisp.debug:make-thread-debug-info :debug-flag t)))
    (is (null (clautolisp.debug:thread-debug-info-current-pp-valid-p ti)))
    (is (eql 0 (clautolisp.debug:thread-debug-info-current-pp-fid ti)))
    (is (eql 0 (clautolisp.debug:thread-debug-info-current-pp-form-id ti)))))

(test current-pp-tracks-the-poll-point-execution-reached
  "Running instrumented code fills it in, and the values are the poll
point the run last entered -- which is what a stop reports as `where you
are'."
  (let* ((context (fresh-context))
         (metas (define-and-instrument context +frob-source+ "FROB" "ID"))
         (frob (fid-of (first metas)))
         (ti (clautolisp.debug:make-thread-debug-info :debug-flag t)))
    (clautolisp.debug:call-with-debugging
     (lambda () (eval-call context "FROB" 7))
     :thread-info ti)
    (is (not (null (clautolisp.debug:thread-debug-info-current-pp-valid-p ti)))
        "no poll point was recorded by a run of instrumented code")
    ;; FROB's poll points are the ones that ran last, so the recorded fid
    ;; is FROB's -- not ID's, whose activation finished earlier.
    (is (eql frob (clautolisp.debug:thread-debug-info-current-pp-fid ti))
        "recorded fid ~S, expected FROB's ~S"
        (clautolisp.debug:thread-debug-info-current-pp-fid ti) frob)))

(test a-stop-reports-the-poll-point-it-stopped-at
  "The end-to-end statement: the fid/form-id a hit carries are the ones
the slots held. This is what would break, silently and only at a stop, if
the two writers and the two readers ever disagreed about the encoding."
  (let* ((context (fresh-context))
         (metas (define-and-instrument context +frob-source+ "FROB" "ID"))
         (frob (fid-of (first metas)))
         (ti (clautolisp.debug:make-thread-debug-info :debug-flag t)))
    (clautolisp.debug:add-breakpoint ti frob 1 :when :before)
    (multiple-value-bind (result hits)
        (run-steps context ti "FROB" '(7) (lambda (hit count)
                                            (declare (ignore hit count))
                                            :continue))
      (declare (ignore result))
      (is (= 1 (length hits)) "expected exactly one hit, got ~S" (length hits))
      (is (equal (list frob 1 :before) (hit-key (first hits)))))))
