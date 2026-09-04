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

(test frame-wire-carries-its-locals
  ;; each (:frame INDEX NAME POSITION LOCALS) now carries the frame's own locals
  ;; as (NAME PREVIEW) pairs (aldb-toggle-details, aldb-commands.issue).
  (let* ((context (fresh-context))
         (metas (load-and-instrument context +two-source+ "TWO" "ID"))
         (ti (break-at metas 3)))
    (multiple-value-bind (result text messages)
        (run-emacs '((:continue)) :context context :thread-info ti
                   :thunk (lambda () (call-two context)))
      (declare (ignore result text))
      (let* ((hit (message-of messages :breakpoint-hit))
             (frame0 (first (getf (second hit) :frames)))
             (locals (nth 4 frame0)))       ; (:frame 0 NAME POSITION LOCALS)
        (is (member "X" locals :key #'first :test #'string=))))))

(test eval-in-frame-command-uses-that-frames-context
  ;; :eval-in-frame selects the frame then evaluates in it: at ID's entry, X is
  ;; visible in the outer TWO frame (index 1) with value 7.
  (let* ((context (fresh-context))
         (metas (load-and-instrument context +two-source+ "TWO" "ID"))
         (id (second metas))
         (ti (clautolisp.debug:make-thread-debug-info :debug-flag t)))
    (clautolisp.debug:add-breakpoint ti (fid-of id) 0 :when :before)
    (multiple-value-bind (result text messages)
        (run-emacs '((:eval-in-frame 1 "X") (:abort)) :context context :thread-info ti
                   :thunk (lambda () (call-two context)))
      (declare (ignore result text))
      (let ((reply (message-of messages :eval-result)))
        (is (consp reply))
        (is (string= "7" (second reply)))))))

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

;;; --- the wire is ELISP-readable, not CL-readable (§20.1) -----------
;;; Elisp has no packages and is case-sensitive: a CL prin1 emits
;;; COMMON-LISP:NIL / :ATTACHED, which Emacs `read' turns into symbols that do
;;; NOT match the nil/t and lower-case :attached aldb.el pcase / plist-get on.

(test elisp-form-serializer-shapes-atoms
  (flet ((s (x) (with-output-to-string (o)
                  (clautolisp.ui.emacs::write-elisp-form x o))))
    (is (string= "nil" (s nil)))
    (is (string= "t" (s t)))
    (is (string= ":pos" (s :pos)))                    ; keywords lower-cased
    (is (string= "42" (s 42)))
    (is (string= "\"hi\"" (s "hi")))
    (is (string= "\"a\\\"b\"" (s "a\"b")))            ; \ and " escaped
    (is (string= "(:frame 0 \"TWO\" nil)" (s '(:frame 0 "TWO" nil))))
    (is (string= "(:a 1 (:b t) nil)" (s '(:a 1 (:b t) nil))))))

(test write-message-emits-one-elisp-line
  (let ((line (string-right-trim
               '(#\Newline)
               (with-output-to-string (o)
                 (let ((ui (clautolisp.ui.emacs:make-emacs-ui
                            :input (make-string-input-stream "") :output o)))
                   (clautolisp.ui.emacs::write-message
                    ui :attached :protocol-version '(1 0) :empty nil :flag t))))))
    (is (string= "(:attached :protocol-version (1 0) :empty nil :flag t)" line))))

(test hit-snapshot-on-the-wire-has-no-cl-package-atoms
  ;; a real :breakpoint-hit line — the exact text Emacs reads — must carry no
  ;; COMMON-LISP: / uppercase :FOO atoms (a live regression guard on the shim).
  (let* ((context (fresh-context))
         (metas (load-and-instrument context +two-source+ "TWO" "ID"))
         (ti (break-at metas 3)))
    (multiple-value-bind (result text messages)
        (run-emacs '((:continue)) :context context :thread-info ti
                   :thunk (lambda () (call-two context)))
      (declare (ignore result messages))
      (is (not (search "COMMON-LISP" (string-upcase text))))
      (is (search "(:breakpoint-hit" text))          ; lower-case tag, verbatim
      (is (search ":function" text)))))
