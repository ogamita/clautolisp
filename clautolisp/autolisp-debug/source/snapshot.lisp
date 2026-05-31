(in-package #:clautolisp.debug)

;;;; Snapshot of the live AutoLISP environment at a stopping point
;;;; (spec §9). Built in the application thread at a hit, while its
;;;; dynamic bindings are live. The binding stack comes from the runtime's
;;;; dynamic-frame chain; the call stack comes from the shadow stack the
;;;; instrumentation maintains in eval-poll-form (stepping.lisp).

;;; A live shadow-stack frame (mutated during execution). One per
;;; instrumented function activation; uninstrumented activations do not
;;; appear (they have no poll points to push them).
(defstruct debug-frame
  (fid 0 :type fixnum)
  (current-form-id 0 :type fixnum)
  dynamic-frame)

;;; A binding visible on the dynamic binding stack (spec §9.4). FRAME is
;;; the runtime dynamic-frame that owns this binding; SHADOWED-P is true
;;; when a more-inner frame also binds SYMBOL.
(defstruct binding-entry
  symbol
  value
  frame
  (shadowed-p nil))

;;; A call-stack frame as presented to the UI (spec §9.3).
(defstruct stack-frame
  function-name
  (fid 0 :type fixnum)
  (form-id 0 :type fixnum)
  source-position
  (bindings-introduced '() :type list))

(defstruct snapshot
  thread
  function-name
  (fid 0 :type fixnum)
  (form-id 0 :type fixnum)
  when
  source-position
  (call-stack '() :type list)        ; innermost first
  (binding-stack '() :type list)     ; innermost first
  (visible-names '() :type list)     ; alist symbol -> innermost value
  (globals-touched '() :type list)   ; spec §9.6 — populated in Phase 3
  (catch-stack '() :type list))      ; spec §10.2 — populated in Phase 3

;;; --- binding stack from the dynamic-frame chain --------------------

(defun collect-binding-stack (context)
  "Walk CONTEXT's dynamic-frame chain innermost-first and return a list
of binding-entry, marking each shadowed if an inner frame rebinds it."
  (let ((seen (make-hash-table :test 'eq))
        (result '()))
    (loop for frame = (evaluation-context-dynamic-frame context)
            then (dynamic-frame-parent frame)
          while frame
          do (dolist (symbol (dynamic-frame-symbols frame))
               (let ((shadowed (gethash symbol seen)))
                 (setf (gethash symbol seen) t)
                 (setf result
                       (append result
                               (list (make-binding-entry
                                      :symbol symbol
                                      :value (dynamic-frame-binding-value frame symbol)
                                      :frame frame
                                      :shadowed-p (and shadowed t))))))))
    result))

(defun visible-names-from (binding-stack)
  "Alist symbol -> innermost value, from an innermost-first BINDING-STACK."
  (let ((seen (make-hash-table :test 'eq))
        (result '()))
    (dolist (entry binding-stack (nreverse result))
      (let ((symbol (binding-entry-symbol entry)))
        (unless (gethash symbol seen)
          (setf (gethash symbol seen) t)
          (push (cons symbol (binding-entry-value entry)) result))))))

(defun frame-bindings-introduced (dynamic-frame)
  "The binding-entries a frame introduced — its own formals/locals
(spec §9.3). The shadowed prior value of each is reachable via
BINDINGS-OF-NAME on the full stack."
  (mapcar (lambda (symbol)
            (make-binding-entry :symbol symbol
                                :value (dynamic-frame-binding-value dynamic-frame symbol)
                                :frame dynamic-frame))
          (dynamic-frame-symbols dynamic-frame)))

(defun debug-frame->stack-frame (debug-frame)
  (let* ((fid (debug-frame-fid debug-frame))
         (metadata (metadata-for-function-id fid))
         (form-id (debug-frame-current-form-id debug-frame))
         (dynamic-frame (debug-frame-dynamic-frame debug-frame)))
    (make-stack-frame
     :function-name (and metadata (function-debug-metadata-name metadata))
     :fid fid
     :form-id form-id
     :source-position (and metadata (form-id-position metadata form-id))
     :bindings-introduced (and dynamic-frame
                               (frame-bindings-introduced dynamic-frame)))))

(defun build-snapshot (ti fid form-id when metadata)
  "Build the spec §9 snapshot at a stopping point, from the live context
and TI's shadow call stack."
  (let* ((context (current-evaluation-context))
         (binding-stack (collect-binding-stack context)))
    (make-snapshot
     :thread (bordeaux-threads:current-thread)
     :function-name (and metadata (function-debug-metadata-name metadata))
     :fid fid
     :form-id form-id
     :when when
     :source-position (and metadata (form-id-position metadata form-id))
     :call-stack (mapcar #'debug-frame->stack-frame (thread-debug-info-call-stack ti))
     :binding-stack binding-stack
     :visible-names (visible-names-from binding-stack)
     ;; spec §10.2: active vl-catch-all-apply frames (the builtin maintains
     ;; the runtime stack). globals-touched (§9.6) stays empty until its
     ;; lazy capture lands.
     :catch-stack (copy-list *autolisp-catch-stack*))))

;;; --- binding queries + writes (spec §9.4, §9.5) --------------------

(defun bindings-of-name (snapshot symbol)
  "All binding-entries for SYMBOL on the snapshot's binding stack, from
innermost to outermost; the first is what ordinary lookup returns, the
rest are shadowed (spec §9.4)."
  (remove-if-not (lambda (entry) (eq symbol (binding-entry-symbol entry)))
                 (snapshot-binding-stack snapshot)))

(defun visible-value (snapshot symbol)
  "The value ordinary lookup would return for SYMBOL at the stopping
point (its innermost binding), or (values NIL NIL) if unbound there."
  (let ((cell (assoc symbol (snapshot-visible-names snapshot) :test #'eq)))
    (if cell (values (cdr cell) t) (values nil nil))))

(defun coerce-from-cl (value)
  "Validate/convert VALUE to a valid AutoLISP runtime value for a
debugger write (spec §9.5). Runtime values pass through; a CL string
becomes an autolisp-string. Signals on a clearly non-AutoLISP value."
  (typecase value
    (null value)
    ((signed-byte 32) value)
    (double-float value)
    (string (make-autolisp-string :value value))
    (cons value)
    (t (if (clautolisp.autolisp-runtime:runtime-value-p value)
           value
           (error "~S is not a valid AutoLISP value to write." value)))))

(defun set-binding-entry (entry value)
  "Write a specific binding-entry on the stack (spec §9.4) — including a
currently-shadowed one. VALUE is coerced via COERCE-FROM-CL. When the
function owning a shadowing frame returns, a modified outer binding
becomes visible again."
  (set-dynamic-frame-binding-value (binding-entry-frame entry)
                                   (binding-entry-symbol entry)
                                   (coerce-from-cl value))
  (setf (binding-entry-value entry) value)
  value)

(defun set-visible-variable (symbol value &optional (context (current-evaluation-context)))
  "Set SYMBOL as ordinary (setq SYMBOL value) would at the stopping point
— the innermost binding, or the global namespace if unshadowed (§9.5)."
  (set-variable symbol (coerce-from-cl value) context))

(defun eval-in-frame (snapshot form &key (frame-index 0))
  "Evaluate FORM (a runtime AutoLISP form) in the snapshot's binding
state, with debugging disabled so the evaluation cannot re-enter the
debugger. Phase 2 supports the innermost frame (index 0); outer-frame
evaluation (with-frame-bindings, §9.3) is deferred."
  (declare (ignore snapshot))
  (unless (zerop frame-index)
    (error "eval-in-frame: outer-frame evaluation (index ~D) is not yet supported."
           frame-index))
  (let ((*debugging* nil))
    (autolisp-eval form (current-evaluation-context))))
