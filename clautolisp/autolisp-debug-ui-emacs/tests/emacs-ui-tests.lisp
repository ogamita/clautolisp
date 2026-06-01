;;;; clautolisp/autolisp-debug-ui-emacs/tests/emacs-ui-tests.lisp
;;;;
;;;; The Emacs RPC shim driven over string streams: command forms in,
;;;; wire messages (readable S-expressions) out.

(in-package #:clautolisp.ui.emacs.tests)

(in-suite emacs-suite)

(test wire-messages-are-readable-sexps
  (let* ((context (fresh-context))
         (metas (load-and-instrument context +two-source+ "TWO" "ID"))
         (ti (break-at metas 3)))
    (multiple-value-bind (result text messages)
        (run-emacs '((:continue)) :context context :thread-info ti
                   :thunk (lambda () (call-two context)))
      (is (eql 7 result))
      ;; every line the shim wrote is a well-formed list read with `read`
      (is (every #'consp messages))
      ;; attach announces the protocol version, then a hit, then resumed
      (is (eq :attached (car (first messages))))
      (is (member :breakpoint-hit (message-tags messages)))
      (is (member :resumed (message-tags messages)))
      (is (search "(:ATTACHED" (string-upcase text))))))

(test hit-message-carries-serialized-snapshot
  (let* ((context (fresh-context))
         (metas (load-and-instrument context +two-source+ "TWO" "ID"))
         (ti (break-at metas 3)))
    (multiple-value-bind (result text messages)
        (run-emacs '((:continue)) :context context :thread-info ti
                   :thunk (lambda () (call-two context)))
      (declare (ignore result text))
      (let* ((hit (message-of messages :breakpoint-hit))
             (plist (second hit)))
        (is (consp plist))
        (is (string= "TWO" (getf plist :function)))
        ;; position is (:pos FILE LINE COL) with line 3
        (is (eq :pos (first (getf plist :position))))
        (is (= 3 (third (getf plist :position))))
        ;; X is visible and bound to 7 — sent as (NAME PREVIEW) strings
        (is (member "X" (getf plist :bindings) :key #'first :test #'string=))
        ;; one call frame on the stack
        (is (= 1 (length (getf plist :frames))))))))

(test eval-command-replies-with-result
  (let* ((context (fresh-context))
         (metas (load-and-instrument context +two-source+ "TWO" "ID"))
         (ti (break-at metas 3)))
    (multiple-value-bind (result text messages)
        (run-emacs '((:eval "X") (:continue)) :context context :thread-info ti
                   :thunk (lambda () (call-two context)))
      (declare (ignore result text))
      (let ((reply (message-of messages :eval-result)))
        (is (consp reply))
        (is (string= "7" (second reply)))))))

(test step-command-resumes-and-stops-again
  (let* ((context (fresh-context))
         (metas (load-and-instrument context +two-source+ "TWO" "ID"))
         (ti (break-at metas 3)))
    ;; step over the setq, then continue to completion
    (multiple-value-bind (result text messages)
        (run-emacs '((:step :over) (:continue)) :context context :thread-info ti
                   :thunk (lambda () (call-two context)))
      (declare (ignore text))
      (is (eql 7 result))
      ;; two stops: the breakpoint hit, then the step landing
      (is (= 1 (count :breakpoint-hit (message-tags messages))))
      (is (= 1 (count :step-hit (message-tags messages)))))))

(test abort-command-aborts
  (let* ((context (fresh-context))
         (metas (load-and-instrument context +two-source+ "TWO" "ID"))
         (ti (break-at metas 3)))
    (multiple-value-bind (result text messages)
        (run-emacs '((:abort)) :context context :thread-info ti
                   :thunk (lambda () (call-two context)))
      (declare (ignore text messages))
      (is (eq :aborted result)))))

(test set-breakpoint-line-replies-and-registers
  (let* ((context (fresh-context))
         (metas (load-and-instrument context +two-source+ "TWO" "ID"))
         (ti (break-at metas 3)))
    (multiple-value-bind (result text messages)
        (run-emacs '((:set-breakpoint-line 4) (:list-breakpoints) (:continue))
                   :context context :thread-info ti :thunk (lambda () (call-two context)))
      (declare (ignore result text))
      (is (message-of messages :breakpoint-set))
      ;; the list reply now contains two breakpoints (line 3 + the new line 4)
      (let ((listing (message-of messages :breakpoints)))
        (is (= 2 (length (second listing))))))))

(test select-frame-and-eval-in-stack
  (let* ((context (fresh-context))
         (metas (load-and-instrument context +two-source+ "TWO" "ID"))
         (id (second metas))
         (ti (clautolisp.debug:make-thread-debug-info :debug-flag t)))
    (clautolisp.debug:add-breakpoint ti (fid-of id) 0 :when :before)
    ;; at ID entry (2 frames); select frame 1 (TWO) then continue (abort to
    ;; avoid the second ID hit)
    (multiple-value-bind (result text messages)
        (run-emacs '((:select-frame 1) (:abort)) :context context :thread-info ti
                   :thunk (lambda () (call-two context)))
      (declare (ignore result text))
      ;; the hit snapshot listed 2 frames
      (let ((hit (message-of messages :breakpoint-hit)))
        (is (= 2 (length (getf (second hit) :frames))))))))

(test inspector-descend-and-path-over-the-wire
  (let* ((context (fresh-context))
         (metas (load-and-instrument context +two-source+ "TWO" "ID"))
         (ti (break-at metas 3)))
    (clautolisp.autolisp-runtime:set-variable
     (rt-sym "L") (first (clautolisp.autolisp-runtime:read-runtime-from-string "(10 20)")) context)
    (multiple-value-bind (result text messages)
        (run-emacs '((:inspect "L") (:inspector-descend 0) (:inspector-path) (:continue))
                   :context context :thread-info ti :thunk (lambda () (call-two context)))
      (declare (ignore result text))
      ;; two inspect-page replies (open + after descend) and a path reply
      (is (= 2 (count :inspect-page (message-tags messages))))
      (let ((path (message-of messages :path)))
        (is (consp path))
        (is (search "(CAR L)" (string-upcase (second path))))))))

(test unhandled-error-message-and-return
  (let* ((context (fresh-context)))
    (load-and-instrument context "(defun boom () (nosuchfn 1))" "BOOM")
    (let ((ti (clautolisp.debug:make-thread-debug-info :debug-flag t)))
      ;; supply a return value for the erroring form (continue-with-return)
      (multiple-value-bind (result text messages)
          (run-emacs '((:return "42"))
                     :context context :thread-info ti
                     :thunk (lambda () (clautolisp.autolisp-runtime:autolisp-eval
                                        (list (rt-sym "BOOM")) context)))
        (declare (ignore text))
        (is (eql 42 result))
        (is (message-of messages :unhandled-error))))))

(test eof-continues
  (let* ((context (fresh-context))
         (metas (load-and-instrument context +two-source+ "TWO" "ID"))
         (ti (break-at metas 3)))
    (multiple-value-bind (result text messages)
        (run-emacs '() :context context :thread-info ti
                   :thunk (lambda () (call-two context)))
      (declare (ignore text messages))
      (is (eql 7 result)))))
