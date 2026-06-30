;;;; tests/printer/terpri.lsp -- TERPRI
;;;; Strict: zero-arity. Confirmed by the BricsCAD V26 / macOS Phase-5
;;;; probe run (terpri with a file-desc argument errored).

(deftest "terpri-no-arg-returns-nil"
  '((operator . "TERPRI") (area . "printer") (profile . strict))
  '(terpri) nil)

;; Real AutoCAD 2026 / BricsCAD V26 reject `(terpri <file>)` with an
;; arity error (terpri is command-line-only). clautolisp INTENTIONALLY
;; diverges: `(terpri <file>)` is a clautolisp extension that, under a
;; non-clautolisp dialect, emits a non-fatal out-of-dialect WARNING and
;; still writes the newline rather than erroring
;; (alfe-clautolisp-dialect.issue point 4: dialect problems are
;; warnings, never errors). So the vendor arity-error is not asserted
;; here; the warn-and-proceed behaviour is covered by the builtins-core
;; unit test `builtin-terpri-dialect-gated-file-extension`.
(deftest-skip "terpri-with-file-desc-argument-errors"
  '((operator . "TERPRI") (area . "printer") (profile . strict))
  '(terpri 42)
  "clautolisp warns (does not error) on (terpri <file>) — intentional divergence from the vendor zero-arity contract; see builtin-terpri-dialect-gated-file-extension")
