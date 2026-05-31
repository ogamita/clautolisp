;;;; clautolisp/autolisp-debug/tests/error-tests.lisp
;;;;
;;;; AutoLISP error integration (spec §10). BOOM errors by calling an
;;;; undefined function, which signals an autolisp-runtime-error inside its
;;;; instrumented body.

(in-package #:clautolisp.debug.tests)

(in-suite debug-suite)

(defparameter +boom-source+
  "(defun boom () (nosuchfn 1))")

(defun instrument-boom (context)
  (first (define-and-instrument context +boom-source+ "BOOM")))

(test unhandled-error-breaks-with-snapshot-and-continues-to-error
  (let* ((context (fresh-context))
         (meta (instrument-boom context))
         (ti (clautolisp.debug:make-thread-debug-info :debug-flag t))
         (captured nil))
    (declare (ignore meta))
    (let ((clautolisp.debug:*debug-hit-handler*
            (lambda (hit) (setf captured hit) :continue-with-error)))
      ;; declining (continue-with-error) lets the error propagate
      (signals clautolisp.autolisp-runtime:autolisp-runtime-error
        (clautolisp.debug:call-with-debugging
         (lambda () (eval-call context "BOOM")) :thread-info ti)))
    (is (clautolisp.debug:hit-p captured))
    (is (eq :unhandled-error (clautolisp.debug:hit-stop-reason captured)))
    (is (stringp (clautolisp.debug:hit-error-message captured)))
    ;; the snapshot points at the erroring form (the (nosuchfn 1) call)
    (is (clautolisp.debug:snapshot-p (clautolisp.debug:hit-snapshot captured)))
    (is (string= "BOOM"
                 (clautolisp.debug:snapshot-function-name
                  (clautolisp.debug:hit-snapshot captured))))))

(test abort-unwinds-the-evaluation
  (let* ((context (fresh-context))
         (ti (clautolisp.debug:make-thread-debug-info :debug-flag t)))
    (instrument-boom context)
    (let ((clautolisp.debug:*debug-hit-handler* (lambda (hit) (declare (ignore hit)) :abort)))
      (is (eq :aborted
              (clautolisp.debug:call-with-debugging
               (lambda () (eval-call context "BOOM")) :thread-info ti))))))

(test continue-with-return-supplies-a-value-for-the-erroring-form
  (let* ((context (fresh-context))
         (ti (clautolisp.debug:make-thread-debug-info :debug-flag t)))
    (instrument-boom context)
    (let ((clautolisp.debug:*debug-hit-handler*
            (lambda (hit) (declare (ignore hit)) (list :continue-with-return 42))))
      ;; (nosuchfn 1) yields 42, so BOOM returns 42
      (is (eql 42 (clautolisp.debug:call-with-debugging
                   (lambda () (eval-call context "BOOM")) :thread-info ti))))))

(test snapshot-includes-active-catch-frames
  ;; The snapshot's catch-stack is read from the runtime stack that the
  ;; vl-catch-all-apply builtin maintains; here we bind it directly to
  ;; verify the snapshot integration without the builtins dependency.
  (let* ((context (fresh-context))
         (frob-meta (first (define-and-instrument context +frob-source+ "FROB" "ID")))
         (form-id (clautolisp.debug:find-form-id-at-line frob-meta 3))
         (ti (clautolisp.debug:make-thread-debug-info :debug-flag t))
         (catch-stack-len nil))
    (clautolisp.debug:add-breakpoint ti (fid-of frob-meta) form-id :when :before)
    (let ((clautolisp.debug:*debug-hit-handler*
            (lambda (hit)
              (setf catch-stack-len
                    (length (clautolisp.debug:snapshot-catch-stack
                             (clautolisp.debug:hit-snapshot hit))))
              :continue))
          (clautolisp.autolisp-runtime:*autolisp-catch-stack*
            (list (clautolisp.autolisp-runtime:make-catch-frame
                   :function :the-fn :arguments '(1 2)))))
      (clautolisp.debug:call-with-debugging
       (lambda () (eval-call context "FROB" 7)) :thread-info ti))
    (is (eql 1 catch-stack-len))))

(test break-on-caught-installs-the-runtime-hook
  (let* ((context (fresh-context))
         (ti (clautolisp.debug:make-thread-debug-info :debug-flag t))
         (hook-during nil))
    (clautolisp.debug:call-with-debugging
     (lambda () (setf hook-during clautolisp.autolisp-runtime:*autolisp-caught-error-hook*))
     :thread-info ti :break-on-caught t)
    (is (not (null hook-during)))            ; hook armed under break-on-caught
    ;; and NOT armed by default
    (setf hook-during :unset)
    (clautolisp.debug:call-with-debugging
     (lambda () (setf hook-during clautolisp.autolisp-runtime:*autolisp-caught-error-hook*))
     :thread-info ti)
    (is (null hook-during))))

(test vl-catch-all-apply-records-catch-frame-and-fires-hook
  ;; End-to-end through the real builtin: it pushes a catch-frame onto the
  ;; runtime catch stack and, with the hook armed, calls it on a caught
  ;; error (spec §10.2). nosuchfn errors regardless of context/host.
  (let* ((context (fresh-context))
         (caught-len nil))
    (load-tracked context "(defun boom () (nosuchfn 1))")
    (let* ((boom (usubr-named context "BOOM"))
           (clautolisp.autolisp-runtime:*autolisp-caught-error-hook*
             (lambda (condition)
               (declare (ignore condition))
               (setf caught-len
                     (length clautolisp.autolisp-runtime:*autolisp-catch-stack*)))))
      (let ((result (clautolisp.autolisp-builtins-core::builtin-vl-catch-all-apply
                     boom '())))
        ;; returns an AutoLISP catch-all-error object
        (is (typep result 'clautolisp.autolisp-runtime:autolisp-catch-all-error))
        ;; the catch frame was on the stack when the caught-error hook fired
        (is (eql 1 caught-len))))))

(test two-thread-abort-yields-aborted-outcome
  (let* ((context (fresh-context))
         (ti (clautolisp.debug:make-thread-debug-info
              :debug-flag t
              :inbound (clautolisp.debug:make-blocking-queue)
              :outbound (clautolisp.debug:make-blocking-queue))))
    (instrument-boom context)
    (clautolisp.debug:run-debugged-thread
     (lambda () (eval-call context "BOOM")) :thread-info ti)
    (let ((m1 (clautolisp.debug:bq-pop (clautolisp.debug:thread-debug-info-outbound ti) 10)))
      (is (eq :hit (first m1)))
      (is (eq :unhandled-error (clautolisp.debug:hit-stop-reason (second m1)))))
    (clautolisp.debug:abort-thread ti)
    (let ((m2 (clautolisp.debug:bq-pop (clautolisp.debug:thread-debug-info-outbound ti) 10)))
      (is (eq :thread-exit (first m2)))
      (is (equal '(:aborted) (second m2))))))