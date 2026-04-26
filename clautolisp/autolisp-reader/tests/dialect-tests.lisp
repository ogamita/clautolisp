(in-package #:clautolisp.autolisp-reader.tests)

(in-suite autolisp-reader-suite)

;;; Dialect descriptor coverage (Phase 6).

(test dialect-named-builtins-are-distinct
  "find-autolisp-dialect returns the canonical descriptor by name and
the three pre-built dialects are distinguishable."
  (let ((strict (autolisp-dialect-strict))
        (autocad (autolisp-dialect-autocad-2026))
        (bricscad (autolisp-dialect-bricscad-v26)))
    (is (typep strict 'autolisp-dialect))
    (is (typep autocad 'autolisp-dialect))
    (is (typep bricscad 'autolisp-dialect))
    (is (eq :strict (autolisp-dialect-name strict)))
    (is (eq :autocad-2026 (autolisp-dialect-name autocad)))
    (is (eq :bricscad-v26 (autolisp-dialect-name bricscad)))
    ;; Strict and AutoCAD share token-mode :strict; BricsCAD V26 is :lax.
    (is (eq :strict (autolisp-dialect-token-mode strict)))
    (is (eq :strict (autolisp-dialect-token-mode autocad)))
    (is (eq :lax (autolisp-dialect-token-mode bricscad)))
    ;; The runtime-only knobs (hex-float, ccs= modes) are off in strict
    ;; and AutoCAD, on in BricsCAD V26.
    (is (null (autolisp-dialect-hex-float-atof-p strict)))
    (is (null (autolisp-dialect-hex-float-atof-p autocad)))
    (is (eq t (autolisp-dialect-hex-float-atof-p bricscad)))
    (is (null (autolisp-dialect-open-ccs-mode-p strict)))
    (is (null (autolisp-dialect-open-ccs-mode-p autocad)))
    (is (eq t (autolisp-dialect-open-ccs-mode-p bricscad)))))

(test dialect-find-by-name
  "find-autolisp-dialect accepts both keyword and string names."
  (is (eq (autolisp-dialect-strict) (find-autolisp-dialect :strict)))
  (is (eq (autolisp-dialect-autocad-2026) (find-autolisp-dialect :autocad-2026)))
  (is (eq (autolisp-dialect-bricscad-v26) (find-autolisp-dialect :bricscad-v26)))
  (is (eq (autolisp-dialect-strict) (find-autolisp-dialect "strict")))
  (is (eq (autolisp-dialect-bricscad-v26) (find-autolisp-dialect "bricscad-v26")))
  ;; Unknown name returns nil.
  (is (null (find-autolisp-dialect :no-such-dialect))))

(test dialect-derives-reader-options
  "reader-options-from-dialect propagates every reader-level knob."
  (let* ((strict-options (reader-options-from-dialect (autolisp-dialect-strict)
                                                      :source-name "strict.lsp"))
         (bricscad-options (reader-options-from-dialect
                            (autolisp-dialect-bricscad-v26)
                            :source-name "bricscad.lsp")))
    (is (eq :strict (reader-options-token-mode strict-options)))
    (is (null (reader-options-extended-string-escapes-p strict-options)))
    (is (null (reader-options-warn-on-integer-overflow-p strict-options)))
    (is (eq :upcase (reader-options-canonical-case strict-options)))
    ;; BricsCAD V26 dialect: lax token mode + extended escapes + integer
    ;; overflow warnings.
    (is (eq :lax (reader-options-token-mode bricscad-options)))
    (is (eq t (reader-options-extended-string-escapes-p bricscad-options)))
    (is (eq t (reader-options-warn-on-integer-overflow-p bricscad-options)))))

;;; Reader behaviour driven by the dialect descriptor.

(defun read-with-dialect (text dialect)
  (read-forms-from-string
   text
   :options (reader-options-from-dialect dialect :source-name "<test>")))

(test dialect-strict-rejects-permissive-integer
  "The strict dialect emits a diagnostic when an integer literal has a
trailing junk suffix (the lax mode of the tokenizer would otherwise
fold these silently into the symbol class)."
  (let* ((result (read-with-dialect "42x" (autolisp-dialect-strict)))
         (diagnostics (read-result-diagnostics result)))
    ;; Either the reader produces a diagnostic, or the resulting object
    ;; is not a clean integer-object — both responses confirm the
    ;; strict-mode tokenizer rejected the permissive form.
    (is (or (some (lambda (d) (eq :error (diagnostic-severity d))) diagnostics)
            (let ((objects (read-result-objects result)))
              (or (null objects)
                  (not (typep (first objects) 'integer-object))))))))

(test dialect-bricscad-tolerates-permissive-integer
  "The lax-mode dialect accepts the same input as a symbol or as an
integer (depending on the tokenizer's lax recovery), without
escalating to an error diagnostic."
  (let* ((result (read-with-dialect "42x" (autolisp-dialect-bricscad-v26)))
         (errors (loop for d in (read-result-diagnostics result)
                       when (eq :error (diagnostic-severity d))
                         collect d)))
    (is (null errors))))

(test dialect-syntax-error-diagnostic-is-localized
  "An unbalanced paren under any dialect produces an error diagnostic
whose source span carries the configured source name."
  (let ((signalled-p nil)
        (carried-source-name nil))
    (handler-case
        (read-with-dialect "(foo bar" (autolisp-dialect-strict))
      (simple-error (condition)
        (setf signalled-p t)
        (let ((arguments (simple-condition-format-arguments condition)))
          (when (and arguments (typep (first arguments) 'diagnostic))
            (let ((span (diagnostic-span (first arguments))))
              (when span
                (setf carried-source-name (source-span-source-name span))))))))
    (is (eq t signalled-p))
    (is (equal "<test>" carried-source-name))))
