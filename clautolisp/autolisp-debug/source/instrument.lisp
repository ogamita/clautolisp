(in-package #:clautolisp.debug)

;;;; The instrumentation pass (clautolisp-debugger plan §3a; spec §5.3).
;;;; Given a usubr, build INSTRUMENTED-BODY — a copy of BODY with
;;;; %CLAL-POLL poll-point nodes woven around every evaluated compound
;;;; form — plus the function-debug-metadata. The plain BODY is never
;;;; modified; the evaluator chooses between them via *DEBUGGING* (the
;;;; two-bodies discipline in call-autolisp-function-in-context).

(defparameter +control-operators+
  '("SETQ" "SET" "IF" "COND" "PROGN" "AND" "OR" "WHILE" "REPEAT" "FOREACH")
  "Special operators whose operands ARE evaluated forms (so the
instrumenter recurses into them). All other special operators have
unevaluated operands (QUOTE, FUNCTION, DEFUN, DEFUN-Q, LAMBDA, TRACE,
UNTRACE, %CLAL-POLL, …) and are treated as leaves — see LEAF-FORM-P.")

;;;; --- instrumentation state -----------------------------------------

(defstruct instr-state
  (fid 0 :type fixnum)
  poll-symbol
  (next-id 0 :type fixnum)
  (positions (make-array 8 :adjustable t :fill-pointer 0))
  (kinds (make-array 8 :adjustable t :fill-pointer 0))
  (parents (make-array 8 :adjustable t :fill-pointer 0)))

(defun alloc-form-id (state form kind parent-id)
  "Allocate a dense form-id for FORM, recording its source position,
KIND, and enclosing PARENT-ID. Returns the new form-id."
  (let ((form-id (instr-state-next-id state)))
    (incf (instr-state-next-id state))
    (vector-push-extend (and form (position-of form)) (instr-state-positions state))
    (vector-push-extend kind (instr-state-kinds state))
    (vector-push-extend parent-id (instr-state-parents state))
    form-id))

(defun wrap-poll (state form-id inner)
  "Build a (%CLAL-POLL fid form-id INNER) node."
  (list (instr-state-poll-symbol state)
        (instr-state-fid state)
        form-id
        inner))

;;;; --- form classification -------------------------------------------

(defun form-operator-name (form)
  "Upper-case name of FORM's operator symbol, or NIL if the operator is
not a plain symbol (e.g. a lambda-form in operator position)."
  (let ((operator (first form)))
    (and (typep operator 'autolisp-symbol)
         (string-upcase (autolisp-symbol-name operator)))))

(defun control-operator-p (name)
  (and name (member name +control-operators+ :test #'string=)))

(defun leaf-form-p (form)
  "True iff the compound FORM must NOT be instrumented or recursed into:
either its operator is a special operator with unevaluated operands
(QUOTE's datum, a nested DEFUN's body, an already-woven %CLAL-POLL, …),
in which case touching its operands would corrupt them. Control special
operators and ordinary function calls are NOT leaves."
  (let ((name (form-operator-name form)))
    (and name
         (not (control-operator-p name))
         (known-special-operator-p name))))

;;;; --- the walker ----------------------------------------------------

(defun instrument-eval-form (form state parent-id)
  "Instrument FORM appearing in an evaluated position. Atoms pass through
unchanged (no poll point); leaf special forms pass through whole; every
other compound form gets a fresh form-id and is wrapped in a poll point,
with its evaluated sub-forms instrumented recursively."
  (cond
    ((not (consp form)) form)
    ((leaf-form-p form) form)
    (t
     (let* ((form-id (alloc-form-id state form :form parent-id))
            (inner (instrument-inner form state form-id)))
       (wrap-poll state form-id inner)))))

(defun instrument-inner (form state form-id)
  "Rebuild FORM keeping its operator, instrumenting its evaluated
operands. COND is special: its operands are clauses, not forms."
  (let ((name (form-operator-name form)))
    (if (and name (string= name "COND"))
        (cons (first form)
              (mapcar (lambda (clause) (instrument-cond-clause clause state form-id))
                      (rest form)))
        ;; Every other recursable form (control op or function call):
        ;; instrument each operand. Atom operands — SETQ places, the
        ;; FOREACH binding name, literals — are returned unchanged by
        ;; INSTRUMENT-EVAL-FORM, so no special-casing is needed.
        (cons (first form)
              (mapcar (lambda (operand) (instrument-eval-form operand state form-id))
                      (rest form))))))

(defun instrument-cond-clause (clause state parent-id)
  "Instrument a COND clause (test . body) without wrapping the clause
itself; the test and each body form are instrumented in place."
  (if (consp clause)
      (cons (instrument-eval-form (first clause) state parent-id)
            (mapcar (lambda (form) (instrument-eval-form form state parent-id))
                    (rest clause)))
      clause))

;;;; --- entry point ---------------------------------------------------

(defun instrumentedp (usubr)
  "True iff USUBR has an instrumented body."
  (and (autolisp-usubr-instrumented-body usubr) t))

(defun instrument-usubr (usubr)
  "Instrument USUBR in place: build its INSTRUMENTED-BODY and
DEBUG-METADATA, register a function-id, and return the metadata.
Idempotent — returns the existing metadata if already instrumented.
USUBR's body conses must have been recorded by a tracked load
(clautolisp.source) for source positions to resolve."
  (or (metadata-for-usubr usubr)
      (progn
        (ensure-poll-operator)
        (let* ((fid (next-function-id))
               (poll-symbol (intern-autolisp-symbol +poll-operator-name+))
               (state (make-instr-state :fid fid :poll-symbol poll-symbol))
               ;; The whole body is wrapped under one form-id whose :before
               ;; poll point is the function entry and :after the exit.
               (entry-id (alloc-form-id state nil :function-entry -1))
               (statements (mapcar (lambda (form)
                                     (instrument-eval-form form state entry-id))
                                   (autolisp-usubr-body usubr)))
               (progn-symbol (intern-autolisp-symbol "PROGN"))
               (body-progn (cons progn-symbol statements))
               (instrumented-body (list (wrap-poll state entry-id body-progn)))
               (bound-names (multiple-value-bind (required rest-param locals)
                                (split-usubr-lambda-list
                                 (autolisp-usubr-lambda-list usubr))
                              ;; Variadic functions: REST-PARAM (the
                              ;; symbol after `&') participates in the
                              ;; debugger's bound-names list right between
                              ;; the required formals and the /-locals,
                              ;; mirroring the order the runtime binds
                              ;; them in `bind-usubr-frame'.
                              (append required
                                      (when rest-param (list rest-param))
                                      locals)))
               (metadata
                 (make-function-debug-metadata
                  :function-id fid
                  :name (autolisp-usubr-name usubr)
                  :usubr usubr
                  :source-position (let ((first-form (first (autolisp-usubr-body usubr))))
                                     (and (consp first-form) (position-of first-form)))
                  :form-id->position (coerce (instr-state-positions state) 'simple-vector)
                  :form-id->kind (coerce (instr-state-kinds state) 'simple-vector)
                  :parent-form-map (coerce (instr-state-parents state) 'simple-vector)
                  :poll-point-count (instr-state-next-id state)
                  :bound-names bound-names
                  :source-text nil)))
          (setf (autolisp-usubr-instrumented-body usubr) instrumented-body
                (autolisp-usubr-debug-metadata usubr) metadata)
          (register-metadata metadata)
          metadata))))
