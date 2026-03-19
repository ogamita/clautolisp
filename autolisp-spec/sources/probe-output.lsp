(defun autolisp-spec-run-output-probes (/ base)
  (setq base (strcat *autolisp-spec-run-directory* "/"))

  (autolisp-spec-probe-file-output
    "output"
    "(prin1 \"hello\" file-desc)"
    (strcat base "prin1-string.txt")
    (function (lambda (stream) (prin1 "hello" stream))))

  (autolisp-spec-probe-file-output
    "output"
    "(princ \"hello\" file-desc)"
    (strcat base "princ-string.txt")
    (function (lambda (stream) (princ "hello" stream))))

  (autolisp-spec-probe-file-output
    "output"
    "(print \"hello\" file-desc)"
    (strcat base "print-string.txt")
    (function (lambda (stream) (print "hello" stream))))

  (autolisp-spec-probe-file-output
    "output"
    "(terpri file-desc)"
    (strcat base "terpri-only.txt")
    (function (lambda (stream) (terpri stream))))

  (autolisp-spec-probe-file-output
    "output"
    "(princ \"A\" file-desc) + (terpri file-desc)"
    (strcat base "princ-terpri.txt")
    (function
      (lambda (stream)
        (princ "A" stream)
        (terpri stream))))

  (autolisp-spec-capture
    "output"
    "(prompt \"AUTOLISP-SPEC-PROMPT>\")"
    (function (lambda () (prompt "AUTOLISP-SPEC-PROMPT>"))))

  (autolisp-spec-note
    "output"
    "(prompt ...)"
    "Prompt output is not captured through file descriptors; this probe records the return value only."))
