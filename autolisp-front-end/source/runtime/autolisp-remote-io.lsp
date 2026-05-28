(if (not (boundp '*autolisp-protocol-yield-mode*))
  (setq *autolisp-protocol-yield-mode* "VLAX-SLEEP"))

(if (not (boundp '*autolisp-protocol-yield-ms*))
  (setq *autolisp-protocol-yield-ms* 100))

(defun autolisp-protocol-write-line (path text / f)
  (setq f (open path "a"))
  (if f
    (progn
      (write-line text f)
      (close f))))

(defun autolisp-protocol-reset-file (path / f)
  (setq f (open path "w"))
  (if f
    (close f)))

(defun autolisp-protocol-slurp-lines (path / f line acc)
  (setq f (open path "r"))
  (if (not f)
    nil
    (progn
      (setq acc '())
      (while (setq line (read-line f))
        (setq acc (cons line acc)))
      (close f)
      (reverse acc))))

(defun autolisp-protocol-lines->text (lines / acc)
  (setq acc "")
  (while lines
    (if (= acc "")
      (setq acc (car lines))
      (setq acc (strcat acc "\n" (car lines))))
    (setq lines (cdr lines)))
  acc)

(defun autolisp-protocol-set-status (text / f)
  (setq f (open *AUTOLISP_PROTOCOL_STATUSFILE* "w"))
  (if f
    (progn
      (write-line text f)
      (close f)))
  text)

(defun autolisp-protocol-write-stdout (text)
  (autolisp-protocol-write-line *AUTOLISP_PROTOCOL_STDOUTFILE* text))

(defun autolisp-protocol-write-stderr (text)
  (autolisp-protocol-write-line *AUTOLISP_PROTOCOL_STDERRFILE* text))

(defun autolisp-protocol-clear-stdout ()
  (autolisp-protocol-reset-file *AUTOLISP_PROTOCOL_STDOUTFILE*))

(defun autolisp-protocol-clear-stderr ()
  (autolisp-protocol-reset-file *AUTOLISP_PROTOCOL_STDERRFILE*))

(defun autolisp-protocol-clear-input ()
  (setq *AUTOLISP_PROTOCOL_INPUT_QUEUE* nil)
  (if (findfile *AUTOLISP_PROTOCOL_STDINFILE*)
    (vl-file-delete *AUTOLISP_PROTOCOL_STDINFILE*))
  nil)

(defun clear-input ()
  (autolisp-protocol-clear-input))

(defun clear-output ()
  (autolisp-protocol-clear-stdout)
  (autolisp-protocol-clear-stderr)
  nil)

(defun autolisp-protocol-pulse-heartbeat (/ stamp)
  (setq stamp (rtos (getvar "DATE") 2 8))
  (setq f (open *AUTOLISP_PROTOCOL_HEARTBEATFILE* "w"))
  (if f
    (progn
      (write-line stamp f)
      (close f))))

(defun autolisp-protocol-form-complete-p (text / idx len depth in-string escape in-comment started ch)
  (setq idx 1)
  (setq len (strlen text))
  (setq depth 0)
  (setq in-string nil)
  (setq escape nil)
  (setq in-comment nil)
  (setq started nil)
  (while (<= idx len)
    (setq ch (substr text idx 1))
    (cond
      (in-comment
        (if (= ch "\n")
          (setq in-comment nil)))
      (in-string
        (setq started T)
        (cond
          (escape
            (setq escape nil))
          ((= ch "\\")
            (setq escape T))
          ((= ch "\"")
            (setq in-string nil))))
      ((= ch ";")
        (setq in-comment T))
      ((member ch '(" " "\t" "\r" "\n")))
      (T
        (setq started T)
        (cond
          ((= ch "\"")
            (setq in-string T))
          ((= ch "(")
            (setq depth (+ depth 1)))
          ((= ch ")")
            (if (> depth 0)
              (setq depth (- depth 1)))))))
    (setq idx (+ idx 1)))
  (and started (not in-string) (not in-comment) (= depth 0)))

(defun autolisp-protocol-pop-file-lines (path / lines)
  (setq lines (autolisp-protocol-slurp-lines path))
  (if lines
    (vl-file-delete path))
  lines)

(defun autolisp-protocol-pop-control ()
  (autolisp-protocol-lines->text
    (autolisp-protocol-pop-file-lines *AUTOLISP_PROTOCOL_CONTROLFILE*)))

(defun autolisp-protocol-handle-control (/ control)
  (setq control (autolisp-protocol-pop-control))
  (cond
    ((= control "PING")
      (autolisp-protocol-pulse-heartbeat)
      nil)
    ((= control "SHUTDOWN")
      (autolisp-protocol-set-status "STOPPING")
      (setq *AUTOLISP_PROTOCOL_STOP* T)
      T)
    (T nil)))

(defun autolisp-protocol-queue-input-lines (lines)
  (while lines
    (setq *AUTOLISP_PROTOCOL_INPUT_QUEUE*
          (append *AUTOLISP_PROTOCOL_INPUT_QUEUE* (list (car lines))))
    (setq lines (cdr lines))))

(defun autolisp-protocol-remote-read-line (/ lines line)
  (while (null *AUTOLISP_PROTOCOL_INPUT_QUEUE*)
    (autolisp-protocol-handle-control)
    (if *AUTOLISP_PROTOCOL_STOP*
      (setq *AUTOLISP_PROTOCOL_INPUT_QUEUE* '("__AUTOLISP_PROTOCOL_STOP__")))
    (autolisp-protocol-pulse-heartbeat)
    (setq lines (autolisp-protocol-pop-file-lines *AUTOLISP_PROTOCOL_STDINFILE*))
    (if lines
      (autolisp-protocol-queue-input-lines lines)
      (progn
        (if *AUTOLISP_PROTOCOL_EMIT_WAITING_INPUT*
          (autolisp-protocol-set-status "WAITING-INPUT"))
        (autolisp-protocol-yield))))
  (setq line (car *AUTOLISP_PROTOCOL_INPUT_QUEUE*))
  (setq *AUTOLISP_PROTOCOL_INPUT_QUEUE* (cdr *AUTOLISP_PROTOCOL_INPUT_QUEUE*))
  line)

(defun autolisp-read-line (/ old-flag line)
  (setq old-flag *AUTOLISP_PROTOCOL_EMIT_WAITING_INPUT*)
  (setq *AUTOLISP_PROTOCOL_EMIT_WAITING_INPUT* T)
  (setq line (autolisp-protocol-remote-read-line))
  (setq *AUTOLISP_PROTOCOL_EMIT_WAITING_INPUT* old-flag)
  line)

(defun autolisp-protocol-read-from-text (text / f value)
  (read text))

(defun autolisp-protocol-remote-read (/ acc line)
  (setq acc "")
  (while (not (autolisp-protocol-form-complete-p acc))
    (setq line (autolisp-protocol-remote-read-line))
    (if (= acc "")
      (setq acc line)
      (setq acc (strcat acc "\n" line))))
  (autolisp-protocol-read-from-text acc))

(defun autolisp-protocol-sleep-ms (ms / r)
  (setq r (vl-catch-all-apply 'vlax-sleep (list ms)))
  (if (vl-catch-all-error-p r)
    (vl-catch-all-apply 'command (list "_DELAY" ms)))
  nil)

(defun autolisp-protocol-yield-ms ()
  (if (and (boundp '*autolisp-protocol-yield-ms*)
           *autolisp-protocol-yield-ms*)
    *autolisp-protocol-yield-ms*
    100))

(defun autolisp-protocol-yield-mode ()
  (if (and (boundp '*autolisp-protocol-yield-mode*)
           *autolisp-protocol-yield-mode*)
    (strcase *autolisp-protocol-yield-mode*)
    "VLAX-SLEEP"))

(defun autolisp-protocol-yield (/ mode ms r)
  (setq mode (autolisp-protocol-yield-mode))
  (setq ms (autolisp-protocol-yield-ms))
  (cond
    ((= mode "SLEEP")
      (setq r (vl-catch-all-apply 'sleep (list ms)))
      (if (vl-catch-all-error-p r)
        (autolisp-protocol-sleep-ms ms)))
    ((= mode "GRREAD")
      ;; Experimental: grread may let BricsCAD process UI messages,
      ;; but host behavior can differ and it may still block.
      (setq r (vl-catch-all-apply 'grread (list nil 8 0)))
      (if (vl-catch-all-error-p r)
        (autolisp-protocol-sleep-ms ms)))
    ((= mode "DELAY")
      (setq r (vl-catch-all-apply 'command (list "_DELAY" ms)))
      (if (vl-catch-all-error-p r)
        (autolisp-protocol-sleep-ms ms)))
    (T
      (autolisp-protocol-sleep-ms ms)))
  nil)

(defun autolisp-protocol-result-code (result)
  (cond
    ((= (type result) 'INT)
      result)
    ((= (type result) 'REAL)
      (fix result))
    (T 0)))

(defun autolisp-protocol-server-loop (/ keep form req-id result rc)
  (setq *AUTOLISP_PROTOCOL_INPUT_QUEUE* nil)
  (setq *AUTOLISP_PROTOCOL_STOP* nil)
  (setq *AUTOLISP_PROTOCOL_EMIT_WAITING_INPUT* nil)
  (autolisp-protocol-clear-stdout)
  (autolisp-protocol-clear-stderr)
  (setq req-id 0)
  (autolisp-protocol-set-status "READY 0")
  (while (not *AUTOLISP_PROTOCOL_STOP*)
    (setq form (vl-catch-all-apply 'autolisp-protocol-remote-read nil))
    (if (vl-catch-all-error-p form)
      (progn
        (autolisp-log-err
          (strcat "ERROR protocol read: "
                  (vl-catch-all-error-message form)))
        (autolisp-protocol-write-stderr
          (strcat "ERROR protocol read: "
                  (vl-catch-all-error-message form)))
        (autolisp-protocol-set-status "FAILED READ")
        (setq *AUTOLISP_PROTOCOL_STOP* T))
      (if (or *AUTOLISP_PROTOCOL_STOP*
              (eq form '__AUTOLISP_PROTOCOL_STOP__))
        nil
        (progn
          (setq req-id (+ req-id 1))
          (autolisp-protocol-set-status (strcat "RUNNING " (itoa req-id)))
          (setq result (vl-catch-all-apply 'autolisp-eval-request-form (list form)))
          (if (vl-catch-all-error-p result)
            (if (or (and (boundp '*AUTOLISP_QUIT_REQUESTED*)
                         *AUTOLISP_QUIT_REQUESTED*)
                    (and (boundp '*AUTOLISP_QUIT_SIGNAL*)
                     (autolisp-quit-signal-p
                       (vl-catch-all-error-message result))))
              (progn
                (setq rc 0)
                (autolisp-set-status rc)
                (autolisp-protocol-set-status
                  (strcat "DONE " (itoa req-id) " QUIT"))
                (setq *AUTOLISP_PROTOCOL_STOP* T))
              (progn
                (autolisp-log-err
                  (strcat "ERROR protocol request " (itoa req-id) ": "
                          (autolisp-effective-error-message
                            (vl-catch-all-error-message result))))
                (autolisp-protocol-write-stderr
                  (strcat "ERROR protocol request " (itoa req-id) ": "
                          (autolisp-effective-error-message
                            (vl-catch-all-error-message result))))
                (autolisp-clear-last-error-context)
                (setq rc 1)
                (autolisp-set-status rc)
                (autolisp-protocol-set-status
                  (strcat "DONE " (itoa req-id) " FAIL"))))
            (progn
              (setq rc (autolisp-protocol-result-code result))
              (autolisp-set-status rc)
              (autolisp-protocol-set-status
                (strcat "DONE " (itoa req-id)
                        (if (= rc 0) " OK" " FAIL")))))))))
  (autolisp-protocol-set-status "STOPPED")
  (princ ""))

(defun autolisp-protocol-selftest-loop (/ keep control line form)
  (setq *AUTOLISP_PROTOCOL_INPUT_QUEUE* nil)
  (setq *AUTOLISP_PROTOCOL_STOP* nil)
  (setq *AUTOLISP_PROTOCOL_EMIT_WAITING_INPUT* T)
  (autolisp-protocol-clear-stdout)
  (autolisp-protocol-clear-stderr)
  (autolisp-protocol-set-status "READY")
  (setq keep T)
  (while keep
    (autolisp-protocol-handle-control)
    (if *AUTOLISP_PROTOCOL_STOP*
      (setq keep nil))
    (if keep
      (progn
        (setq line (autolisp-protocol-remote-read-line))
        (if (and line (/= line "__AUTOLISP_PROTOCOL_STOP__"))
          (progn
            (autolisp-protocol-set-status "RUNNING")
            (autolisp-protocol-write-stdout (strcat "LINE " line))
            (setq form (autolisp-protocol-remote-read))
            (autolisp-protocol-write-stdout
              (strcat "FORM " (vl-princ-to-string form)))
            (autolisp-protocol-write-stderr "STDERR done")
            (autolisp-protocol-set-status "READY"))
          (setq keep nil)))))
  (autolisp-protocol-set-status "STOPPED")
  (princ ""))

(defun C:AUTOLISP-PROTOCOL-SELFTEST ()
  (autolisp-protocol-selftest-loop))
