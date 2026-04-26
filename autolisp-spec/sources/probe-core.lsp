;; Cross-vendor note: BricsCAD V26 `or` returns T / nil, not the first
;; non-nil expression value (see vendor-inventory-2026.org §10). The
;; idiom `(setq x (or x default))` therefore *clobbers* x with T in
;; BricsCAD when x is already non-nil. We use an `if`-based guard instead.
(if (not *autolisp-spec-result-file*)
  (setq *autolisp-spec-result-file* "autolisp-spec-results.sexp"))
(if (not *autolisp-spec-platform*)
  (setq *autolisp-spec-platform* "unknown"))
(if (not *autolisp-spec-product*)
  (setq *autolisp-spec-product* "unknown"))
(if (not *autolisp-spec-run-directory*)
  (setq *autolisp-spec-run-directory* "."))

;; Cross-vendor / wrapper-aware record writer.
;; Several environments either redefine `prin1` / `princ` / `print`
;; to a 1-argument helper (the autolisp-script wrapper does so to
;; mirror command-line output) or provide a 2-argument form whose
;; stream argument is silently ignored. To work everywhere, we
;; serialise the record via vl-prin1-to-string (1-argument; always
;; vendor-defined as round-trippable) and emit via write-line —
;; `write-line` is left untouched by every wrapper we have seen and
;; is documented as 2-argument with a stream sink in both AutoCAD
;; and BricsCAD V26.
(defun autolisp-spec--record (fields / stream serialised)
  (setq serialised (vl-prin1-to-string fields))
  (setq stream (open *autolisp-spec-result-file* "a"))
  (if stream
    (progn
      (write-line serialised stream)
      (close stream)
      fields)
    nil))

(defun autolisp-spec-begin-run ()
  (autolisp-spec--record
    (list
      (cons 'kind "run-start")
      (cons 'product *autolisp-spec-product*)
      (cons 'platform *autolisp-spec-platform*)
      (cons 'result-file *autolisp-spec-result-file*)
      (cons 'run-directory *autolisp-spec-run-directory*))))

(defun autolisp-spec-end-run ()
  (autolisp-spec--record
    (list
      (cons 'kind "run-end")
      (cons 'product *autolisp-spec-product*)
      (cons 'platform *autolisp-spec-platform*))))

(defun autolisp-spec-note (suite case text)
  (autolisp-spec--record
    (list
      (cons 'kind "note")
      (cons 'suite suite)
      (cons 'case case)
      (cons 'text text))))

(defun autolisp-spec-capture (suite case thunk / value)
  (setq value (vl-catch-all-apply thunk '()))
  (if (vl-catch-all-error-p value)
    (autolisp-spec--record
      (list
        (cons 'kind "probe-result")
        (cons 'suite suite)
        (cons 'case case)
        (cons 'status "error")
        (cons 'message (vl-catch-all-error-message value))))
    (autolisp-spec--record
      (list
        (cons 'kind "probe-result")
        (cons 'suite suite)
        (cons 'case case)
        (cons 'status "ok")
        (cons 'value value)))))

(defun autolisp-spec--slurp-file (path / stream line text)
  (setq text "")
  (setq stream (open path "r"))
  (if stream
    (progn
      (setq line (read-line stream))
      (while line
        (setq text (strcat text line "\n"))
        (setq line (read-line stream)))
      (close stream)
      text)
    ""))

(defun autolisp-spec--truncate-file (path / stream)
  (setq stream (open path "w"))
  (if stream
    (close stream))
  path)

(defun autolisp-spec--write-probe-file (path writer / stream value)
  (setq stream (open path "w"))
  (if stream
    (progn
      ;; The probe writer thunk receives a stream argument and uses
      ;; whatever output function it wishes (prin1/princ/print/terpri).
      ;; The 2-argument forms of those functions may be no-ops in some
      ;; wrappers, in which case the per-file probe will record an
      ;; empty `file-output` value — that's still useful evidence.
      (setq value (vl-catch-all-apply writer (list stream)))
      (close stream)
      value)
    "open-failed"))

(defun autolisp-spec-probe-file-output (suite case path writer / value)
  (autolisp-spec--truncate-file path)
  (setq value (autolisp-spec--write-probe-file path writer))
  (if (vl-catch-all-error-p value)
    (autolisp-spec--record
      (list
        (cons 'kind "probe-result")
        (cons 'suite suite)
        (cons 'case case)
        (cons 'status "error")
        (cons 'message (vl-catch-all-error-message value))))
    (autolisp-spec--record
      (list
        (cons 'kind "probe-result")
        (cons 'suite suite)
        (cons 'case case)
        (cons 'status "ok")
        (cons 'value value)
        (cons 'file-output (autolisp-spec--slurp-file path))))))
