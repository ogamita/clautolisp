;;;; clautolisp/autolisp-debug/tests/session-tests.lisp
;;;;
;;;; The two-thread pause loop (spec §8): the application runs in its own
;;;; thread and, on a hit, blocks until the debugger thread resumes it.

(in-package #:clautolisp.debug.tests)

(in-suite debug-suite)

(test two-thread-pause-reports-hit-and-resumes
  (let* ((context (fresh-context))
         (frob-meta (first (define-and-instrument context +frob-source+ "FROB" "ID")))
         (form-id (clautolisp.debug:find-form-id-at-line frob-meta 3))
         (ti (clautolisp.debug:make-thread-debug-info
              :debug-flag t
              :inbound (clautolisp.debug:make-blocking-queue)
              :outbound (clautolisp.debug:make-blocking-queue))))
    (clautolisp.debug:add-breakpoint ti (fid-of frob-meta) form-id :when :before)
    (clautolisp.debug:run-debugged-thread
     (lambda () (eval-call context "FROB" 7))
     :thread-info ti)
    ;; first message: the hit, with the application thread paused on it
    (let ((message (clautolisp.debug:bq-pop (clautolisp.debug:thread-debug-info-outbound ti) 10)))
      (is (consp message))
      (is (eq :hit (first message)))
      (is (= form-id (clautolisp.debug:hit-form-id (second message))))
      (is (eq :stopped (clautolisp.debug:thread-debug-info-status ti))))
    ;; resume; then the thread exits with the function's value
    (clautolisp.debug:continue-thread ti)
    (let ((exit (clautolisp.debug:bq-pop (clautolisp.debug:thread-debug-info-outbound ti) 10)))
      (is (consp exit))
      (is (eq :thread-exit (first exit)))
      (is (equal '(:value . 7) (second exit))))))

(test with-debugging-macro-runs-body
  (let* ((context (fresh-context)))
    (define-and-instrument context +frob-source+ "FROB" "ID")
    (is (eql 7 (clautolisp.debug:with-debugging () (eval-call context "FROB" 7))))))
