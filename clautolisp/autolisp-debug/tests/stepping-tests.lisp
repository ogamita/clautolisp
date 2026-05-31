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