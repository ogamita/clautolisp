(setq *autolisp-spec-result-file*
      (or *autolisp-spec-result-file* "autolisp-spec-results.sexp"))
(setq *autolisp-spec-platform*
      (or *autolisp-spec-platform* "unknown"))
(setq *autolisp-spec-product*
      (or *autolisp-spec-product* "unknown"))
(setq *autolisp-spec-run-directory*
      (or *autolisp-spec-run-directory* "."))

(defun autolisp-spec--record (fields / stream)
  (setq stream (open *autolisp-spec-result-file* "a"))
  (if stream
    (progn
      (prin1 fields stream)
      (terpri stream)
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
