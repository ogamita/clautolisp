;;;; clautolisp/autolisp-debug/tests/snapshot-tests.lisp
;;;;
;;;; Snapshot, binding navigation/writes, and eval-in-frame (spec §9).

(in-package #:clautolisp.debug.tests)

(in-suite debug-suite)

(test snapshot-reports-position-bindings-and-call-stack
  (let* ((context (fresh-context))
         (frob-meta (first (define-and-instrument context +frob-source+ "FROB" "ID")))
         (form-id (clautolisp.debug:find-form-id-at-line frob-meta 3)) ; (id x)
         (ti (clautolisp.debug:make-thread-debug-info :debug-flag t))
         (snap nil))
    (clautolisp.debug:add-breakpoint ti (fid-of frob-meta) form-id :when :before)
    (let ((clautolisp.debug:*debug-hit-handler*
            (lambda (hit) (setf snap (clautolisp.debug:hit-snapshot hit)) :continue)))
      (clautolisp.debug:call-with-debugging
       (lambda () (eval-call context "FROB" 7)) :thread-info ti))
    (is (clautolisp.debug:snapshot-p snap))
    (is (string= "FROB" (clautolisp.debug:snapshot-function-name snap)))
    (is (= 3 (clautolisp.source:source-position-start-line
              (clautolisp.debug:snapshot-source-position snap))))
    ;; X is visible and bound to 7 at this point
    (let ((visible (mapcar (lambda (cell)
                             (cons (clautolisp.autolisp-runtime:autolisp-symbol-name (car cell))
                                   (cdr cell)))
                           (clautolisp.debug:snapshot-visible-names snap))))
      (is (equal 7 (cdr (assoc "X" visible :test #'string=)))))
    ;; one call frame, FROB, on the shadow stack
    (let ((frames (clautolisp.debug:snapshot-call-stack snap)))
      (is (= 1 (length frames)))
      (is (string= "FROB" (clautolisp.debug:stack-frame-function-name (first frames)))))))

(test snapshot-call-stack-grows-into-callee
  ;; Break at ID's entry, reached via FROB: the shadow call stack shows
  ;; ID (innermost) then FROB.
  (let* ((context (fresh-context))
         (metas (define-and-instrument context +frob-source+ "FROB" "ID"))
         (id-meta (second metas))
         (ti (clautolisp.debug:make-thread-debug-info :debug-flag t))
         (snap nil))
    (clautolisp.debug:add-breakpoint ti (fid-of id-meta) 0 :when :before)
    (let ((clautolisp.debug:*debug-hit-handler*
            (lambda (hit) (setf snap (clautolisp.debug:hit-snapshot hit)) :continue)))
      (clautolisp.debug:call-with-debugging
       (lambda () (eval-call context "FROB" 7)) :thread-info ti))
    (let ((names (mapcar #'clautolisp.debug:stack-frame-function-name
                         (clautolisp.debug:snapshot-call-stack snap))))
      (is (equal '("ID" "FROB") names)))))

(test set-binding-entry-writes-visible-binding
  ;; Overwrite X at the (id x) stopping point; FROB returns z = (id x), so
  ;; the result reflects the written value (spec §9.4/§9.5).
  (let* ((context (fresh-context))
         (frob-meta (first (define-and-instrument context +frob-source+ "FROB" "ID")))
         (form-id (clautolisp.debug:find-form-id-at-line frob-meta 3))
         (ti (clautolisp.debug:make-thread-debug-info :debug-flag t)))
    (clautolisp.debug:add-breakpoint ti (fid-of frob-meta) form-id :when :before)
    (let ((clautolisp.debug:*debug-hit-handler*
            (lambda (hit)
              (let* ((snap (clautolisp.debug:hit-snapshot hit))
                     (entry (find (rt-sym "X") (clautolisp.debug:snapshot-binding-stack snap)
                                  :key #'clautolisp.debug:binding-entry-symbol)))
                (clautolisp.debug:set-binding-entry entry 99))
              :continue)))
      (is (eql 99 (clautolisp.debug:call-with-debugging
                   (lambda () (eval-call context "FROB" 7)) :thread-info ti))))))

(test shadowed-binding-is-visible-in-stack
  ;; OUTER binds V, calls INNER which also binds V. At INNER's entry the
  ;; stack holds both bindings; INNER's is visible, OUTER's is shadowed.
  (let* ((context (fresh-context))
         (source (format nil "(defun inner (v) v)~%(defun outer (v) (inner 2))"))
         (metas (define-and-instrument context source "INNER" "OUTER"))
         (inner-meta (first metas))
         (ti (clautolisp.debug:make-thread-debug-info :debug-flag t))
         (snap nil))
    (clautolisp.debug:add-breakpoint ti (fid-of inner-meta) 0 :when :before)
    (let ((clautolisp.debug:*debug-hit-handler*
            (lambda (hit) (setf snap (clautolisp.debug:hit-snapshot hit)) :continue)))
      (clautolisp.debug:call-with-debugging
       (lambda () (eval-call context "OUTER" 1)) :thread-info ti))
    (let ((vs (clautolisp.debug:bindings-of-name snap (rt-sym "V"))))
      (is (= 2 (length vs)))                                  ; two bindings of V
      (is (eql 2 (clautolisp.debug:binding-entry-value (first vs))))   ; inner, visible
      (is (not (clautolisp.debug:binding-entry-shadowed-p (first vs))))
      (is (eql 1 (clautolisp.debug:binding-entry-value (second vs))))  ; outer, shadowed
      (is (clautolisp.debug:binding-entry-shadowed-p (second vs))))
    (multiple-value-bind (value boundp) (clautolisp.debug:visible-value snap (rt-sym "V"))
      (is (not (null boundp)))
      (is (eql 2 value)))))

(test eval-in-frame-evaluates-in-stopping-context
  (let* ((context (fresh-context))
         (frob-meta (first (define-and-instrument context +frob-source+ "FROB" "ID")))
         (form-id (clautolisp.debug:find-form-id-at-line frob-meta 3))
         (ti (clautolisp.debug:make-thread-debug-info :debug-flag t))
         (x-value :unset))
    (clautolisp.debug:add-breakpoint ti (fid-of frob-meta) form-id :when :before)
    (let ((clautolisp.debug:*debug-hit-handler*
            (lambda (hit)
              (setf x-value (clautolisp.debug:eval-in-frame
                             (clautolisp.debug:hit-snapshot hit) (rt-sym "X")))
              :continue)))
      (clautolisp.debug:call-with-debugging
       (lambda () (eval-call context "FROB" 7)) :thread-info ti))
    (is (eql 7 x-value))))