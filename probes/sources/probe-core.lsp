;;;; probes/sources/probe-core.lsp
;;;;
;;;; Project-wide CAD-probe runtime: a tiny, vendor-neutral AutoLISP
;;;; framework that runs the same probe programs inside AutoCAD,
;;;; BricsCAD and clautolisp and writes one machine-readable record per
;;;; line to a results .sexp file. The captured records are the
;;;; ground-truth clautolisp is diffed against. See probes/README.org.
;;;;
;;;; Portability notes (the reasons this file looks defensive):
;;;;
;;;;  * BricsCAD V26 `or' returns T / nil, not the first non-nil value,
;;;;    so `(setq x (or x default))' clobbers x with T when x is already
;;;;    non-nil. We guard defaults with `if' instead.
;;;;
;;;;  * Some hosts / wrappers redefine prin1 / princ / print to a
;;;;    one-argument helper, or accept a stream argument they silently
;;;;    ignore. We serialise each record with vl-prin1-to-string (always
;;;;    vendor-defined, one argument, round-trippable) and emit it with
;;;;    write-line, which every host we have seen leaves untouched.
;;;;
;;;;  * Every probe body runs under vl-catch-all-apply so a missing
;;;;    function or a host error becomes a recorded `error' status
;;;;    rather than aborting the whole run.

;; --- run context (seeded by the generated wrapper) -------------------

(if (not cad-probe-result-file)  (setq cad-probe-result-file  "cad-probe-results.sexp"))
(if (not cad-probe-platform)     (setq cad-probe-platform     "unknown"))
(if (not cad-probe-product)      (setq cad-probe-product      "unknown"))
(if (not cad-probe-run-directory)(setq cad-probe-run-directory "."))

;; --- record writer ---------------------------------------------------

(defun cad-probe--record (fields / stream serialised)
  (setq serialised (vl-prin1-to-string fields))
  (setq stream (open cad-probe-result-file "a"))
  (if stream
    (progn
      (write-line serialised stream)
      (close stream)
      fields)
    nil))

(defun cad-probe-begin-run ()
  (cad-probe--record
    (list
      (cons 'kind "run-start")
      (cons 'product cad-probe-product)
      (cons 'platform cad-probe-platform)
      (cons 'result-file cad-probe-result-file)
      (cons 'run-directory cad-probe-run-directory))))

(defun cad-probe-end-run ()
  (cad-probe--record
    (list
      (cons 'kind "run-end")
      (cons 'product cad-probe-product)
      (cons 'platform cad-probe-platform))))

(defun cad-probe-note (suite key text)
  (cad-probe--record
    (list
      (cons 'kind "note")
      (cons 'suite suite)
      (cons 'case key)
      (cons 'text text))))

;; --- the workhorse: run a thunk, record its value or its error -------
;;
;; SUITE groups related probes; CASE is the human-readable source of the
;; expression being probed (kept verbatim so a reader can re-evaluate
;; it). THUNK is a zero-argument function returning the value to capture.

(defun cad-probe-capture (suite case thunk / value)
  (setq value (vl-catch-all-apply thunk '()))
  (if (vl-catch-all-error-p value)
    (cad-probe--record
      (list
        (cons 'kind "probe-result")
        (cons 'suite suite)
        (cons 'case case)
        (cons 'status "error")
        (cons 'message (vl-catch-all-error-message value))))
    (cad-probe--record
      (list
        (cons 'kind "probe-result")
        (cons 'suite suite)
        (cons 'case case)
        (cons 'status "ok")
        (cons 'value value)))))

;; --- sysvar helpers --------------------------------------------------
;;
;; cad-probe-sysvar records both the value of a system variable and
;; whether it is read-only. Read-only is detected by attempting to set
;; the variable back to the value it already holds (a semantic no-op):
;; a host that rejects the write signals read-only. The original value
;; is restored on the off chance the no-op write is observable.

(defun cad-probe-sysvar (suite name / value setres readonly restore)
  (setq value (vl-catch-all-apply (function (lambda () (getvar name))) '()))
  (if (vl-catch-all-error-p value)
    (cad-probe--record
      (list
        (cons 'kind "sysvar")
        (cons 'suite suite)
        (cons 'name name)
        (cons 'status "error")
        (cons 'message (vl-catch-all-error-message value))))
    (progn
      (setq setres
        (vl-catch-all-apply (function (lambda () (setvar name value))) '()))
      (if (vl-catch-all-error-p setres)
        (setq readonly 'T)
        (setq readonly nil))
      ;; Restore (best effort); ignore any failure.
      (vl-catch-all-apply (function (lambda () (setvar name value))) '())
      (cad-probe--record
        (list
          (cons 'kind "sysvar")
          (cons 'suite suite)
          (cons 'name name)
          (cons 'status "ok")
          (cons 'value value)
          (cons 'read-only readonly))))))

(princ)
