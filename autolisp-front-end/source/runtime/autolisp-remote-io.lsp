(if (not (boundp '*autolisp-protocol-yield-mode*))
  (setq *autolisp-protocol-yield-mode* "VLAX-SLEEP"))

(if (not (boundp '*autolisp-protocol-yield-ms*))
  (setq *autolisp-protocol-yield-ms* 100))

(defun autolisp-protocol-write-line (alfe--path alfe--text / alfe--f)
  (setq alfe--f (open alfe--path "a"))
  (if alfe--f
    (progn
      (write-line alfe--text alfe--f)
      (close alfe--f))))

(defun autolisp-protocol-reset-file (alfe--path / alfe--f)
  (setq alfe--f (open alfe--path "w"))
  (if alfe--f
    (close alfe--f)))

(defun autolisp-protocol-slurp-lines (alfe--path / alfe--f alfe--line alfe--acc)
  (setq alfe--f (open alfe--path "r"))
  (if (not alfe--f)
    nil
    (progn
      (setq alfe--acc '())
      (while (setq alfe--line (read-line alfe--f))
        (setq alfe--acc (cons alfe--line alfe--acc)))
      (close alfe--f)
      (reverse alfe--acc))))

(defun autolisp-protocol-lines->text (alfe--lines / alfe--acc)
  (setq alfe--acc "")
  (while alfe--lines
    (if (= alfe--acc "")
      (setq alfe--acc (car alfe--lines))
      (setq alfe--acc (strcat alfe--acc "\n" (car alfe--lines))))
    (setq alfe--lines (cdr alfe--lines)))
  alfe--acc)

(defun autolisp-protocol-set-status (alfe--text / alfe--f)
  (setq alfe--f (open *AUTOLISP_PROTOCOL_STATUSFILE* "w"))
  (if alfe--f
    (progn
      (write-line alfe--text alfe--f)
      (close alfe--f)))
  alfe--text)

(defun autolisp-protocol-write-stdout (alfe--text)
  (autolisp-protocol-write-line *AUTOLISP_PROTOCOL_STDOUTFILE* alfe--text))

(defun autolisp-protocol-write-stderr (alfe--text)
  (autolisp-protocol-write-line *AUTOLISP_PROTOCOL_STDERRFILE* alfe--text))

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

(defun autolisp-protocol-pulse-heartbeat (/ alfe--stamp alfe--f)
  (setq alfe--stamp (rtos (getvar "DATE") 2 8))
  (setq alfe--f (open *AUTOLISP_PROTOCOL_HEARTBEATFILE* "w"))
  (if alfe--f
    (progn
      (write-line alfe--stamp alfe--f)
      (close alfe--f))))

(defun autolisp-protocol-form-complete-p (alfe--text / alfe--idx alfe--len alfe--depth alfe--in-string alfe--escape alfe--in-comment alfe--started alfe--ch)
  (setq alfe--idx 1)
  (setq alfe--len (strlen alfe--text))
  (setq alfe--depth 0)
  (setq alfe--in-string nil)
  (setq alfe--escape nil)
  (setq alfe--in-comment nil)
  (setq alfe--started nil)
  (while (<= alfe--idx alfe--len)
    (setq alfe--ch (substr alfe--text alfe--idx 1))
    (cond
      (alfe--in-comment
        (if (= alfe--ch "\n")
          (setq alfe--in-comment nil)))
      (alfe--in-string
        (setq alfe--started T)
        (cond
          (alfe--escape
            (setq alfe--escape nil))
          ((= alfe--ch "\\")
            (setq alfe--escape T))
          ((= alfe--ch "\"")
            (setq alfe--in-string nil))))
      ((= alfe--ch ";")
        (setq alfe--in-comment T))
      ((member alfe--ch '(" " "\t" "\r" "\n")))
      (T
        (setq alfe--started T)
        (cond
          ((= alfe--ch "\"")
            (setq alfe--in-string T))
          ((= alfe--ch "(")
            (setq alfe--depth (+ alfe--depth 1)))
          ((= alfe--ch ")")
            (if (> alfe--depth 0)
              (setq alfe--depth (- alfe--depth 1)))))))
    (setq alfe--idx (+ alfe--idx 1)))
  (and alfe--started (not alfe--in-string) (not alfe--in-comment) (= alfe--depth 0)))

(defun autolisp-protocol-pop-file-lines (alfe--path / alfe--lines)
  (setq alfe--lines (autolisp-protocol-slurp-lines alfe--path))
  (if alfe--lines
    (vl-file-delete alfe--path))
  alfe--lines)

(defun autolisp-protocol-pop-control ()
  (autolisp-protocol-lines->text
    (autolisp-protocol-pop-file-lines *AUTOLISP_PROTOCOL_CONTROLFILE*)))

(defun autolisp-protocol-handle-control (/ alfe--control)
  (setq alfe--control (autolisp-protocol-pop-control))
  (cond
    ((= alfe--control "PING")
      (autolisp-protocol-pulse-heartbeat)
      nil)
    ((= alfe--control "SHUTDOWN")
      (autolisp-protocol-set-status "STOPPING")
      (setq *AUTOLISP_PROTOCOL_STOP* T)
      T)
    (T nil)))

(defun autolisp-protocol-queue-input-lines (alfe--lines)
  (while alfe--lines
    (setq *AUTOLISP_PROTOCOL_INPUT_QUEUE*
          (append *AUTOLISP_PROTOCOL_INPUT_QUEUE* (list (car alfe--lines))))
    (setq alfe--lines (cdr alfe--lines))))

(defun autolisp-protocol-remote-read-line (/ alfe--lines alfe--line)
  (while (null *AUTOLISP_PROTOCOL_INPUT_QUEUE*)
    (autolisp-protocol-handle-control)
    (if *AUTOLISP_PROTOCOL_STOP*
      (setq *AUTOLISP_PROTOCOL_INPUT_QUEUE* '("__AUTOLISP_PROTOCOL_STOP__")))
    (autolisp-protocol-pulse-heartbeat)
    (setq alfe--lines (autolisp-protocol-pop-file-lines *AUTOLISP_PROTOCOL_STDINFILE*))
    (if alfe--lines
      (autolisp-protocol-queue-input-lines alfe--lines)
      (progn
        (if *AUTOLISP_PROTOCOL_EMIT_WAITING_INPUT*
          (autolisp-protocol-set-status "WAITING-INPUT"))
        (autolisp-protocol-yield))))
  (setq alfe--line (car *AUTOLISP_PROTOCOL_INPUT_QUEUE*))
  (setq *AUTOLISP_PROTOCOL_INPUT_QUEUE* (cdr *AUTOLISP_PROTOCOL_INPUT_QUEUE*))
  alfe--line)

(defun autolisp-read-line (/ alfe--old-flag alfe--line)
  (setq alfe--old-flag *AUTOLISP_PROTOCOL_EMIT_WAITING_INPUT*)
  (setq *AUTOLISP_PROTOCOL_EMIT_WAITING_INPUT* T)
  (setq alfe--line (autolisp-protocol-remote-read-line))
  (setq *AUTOLISP_PROTOCOL_EMIT_WAITING_INPUT* alfe--old-flag)
  alfe--line)

(defun autolisp-protocol-read-from-text (alfe--text / alfe--f alfe--value)
  (read alfe--text))

(defun autolisp-protocol-remote-read (/ alfe--acc alfe--line)
  (setq alfe--acc "")
  (while (not (autolisp-protocol-form-complete-p alfe--acc))
    (setq alfe--line (autolisp-protocol-remote-read-line))
    (if (= alfe--acc "")
      (setq alfe--acc alfe--line)
      (setq alfe--acc (strcat alfe--acc "\n" alfe--line))))
  ;; Keep the request's TEXT: the server loop hands it to
  ;; autolisp-eval-request-source with the form, so the CAD reads the
  ;; request as it was written instead of a re-print of it, which kept
  ;; only 6 (AutoCAD) or 14 (BricsCAD) digits of a real literal
  ;; (alfe-cad-transport-rounds-reals).
  (setq *AUTOLISP_PROTOCOL_REQUEST_TEXT* alfe--acc)
  (autolisp-protocol-read-from-text alfe--acc))

;; See autolisp-host-has-fn / autolisp-delay-ms in the bootstrap (loaded
;; first): probe vlax-sleep's existence rather than trusting
;; vl-catch-all-apply to trap an undefined-symbol error, which it cannot.
;; On AutoCAD (no vlax-sleep) this degrades to the DELAY command.
(defun autolisp-protocol-sleep-ms (alfe--ms / alfe--r)
  (if (autolisp-host-has-fn "VLAX-SLEEP")
    (progn
      (setq alfe--r (vl-catch-all-apply 'vlax-sleep (list alfe--ms)))
      (if (vl-catch-all-error-p alfe--r)
        (autolisp-delay-ms alfe--ms)))
    (autolisp-delay-ms alfe--ms))
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

(defun autolisp-protocol-yield (/ alfe--mode alfe--ms alfe--r)
  (setq alfe--mode (autolisp-protocol-yield-mode))
  (setq alfe--ms (autolisp-protocol-yield-ms))
  (cond
    ((= alfe--mode "SLEEP")
      (setq alfe--r (vl-catch-all-apply 'sleep (list alfe--ms)))
      (if (vl-catch-all-error-p alfe--r)
        (autolisp-protocol-sleep-ms alfe--ms)))
    ((= alfe--mode "GRREAD")
      ;; Experimental: grread may let BricsCAD process UI messages,
      ;; but host behavior can differ and it may still block.
      (setq alfe--r (vl-catch-all-apply 'grread (list nil 8 0)))
      (if (vl-catch-all-error-p alfe--r)
        (autolisp-protocol-sleep-ms alfe--ms)))
    ((= alfe--mode "DELAY")
      (setq alfe--r (vl-catch-all-apply 'command (list "_DELAY" alfe--ms)))
      (if (vl-catch-all-error-p alfe--r)
        (autolisp-protocol-sleep-ms alfe--ms)))
    (T
      (autolisp-protocol-sleep-ms alfe--ms)))
  nil)

(defun autolisp-protocol-result-code (alfe--result)
  (cond
    ((= (type alfe--result) 'INT)
      alfe--result)
    ((= (type alfe--result) 'REAL)
      (fix alfe--result))
    (T 0)))

(defun autolisp-vague-error-message-p (alfe--msg)
  "True when MSG tells the user nothing: absent, empty, or one of the
bare words a host offers when it has no text of its own. BricsCAD
answers exactly \"error\" for some conditions, which is what
alfe-cad-load-error-message-says-only-error was about -- the report was
correct and useless."
  (or (null alfe--msg)
      (/= (type alfe--msg) 'STR)
      (= alfe--msg "")
      (member (strcase alfe--msg)
              (list "ERROR" "ERREUR" "FUNCTION CANCELLED"
                    ;; What autolisp-raise puts in the context when the
                    ;; host gave nothing: still vague, so the form is
                    ;; still worth adding.
                    (strcase "the engine supplied no message")))))

(defun autolisp-request-failure-text (alfe--req-id alfe--msg alfe--form / alfe--text alfe--shown)
  "The stderr line for a failed request: the engine's message, plus the
FORM when that message says nothing. A host that supplies no text leaves
the user with a position and no cause, and the form is the one piece of
context this side always has."
  (setq alfe--text (strcat "ERROR protocol request " (itoa alfe--req-id) ": "
                     (if (autolisp-vague-error-message-p alfe--msg)
                         (if (or (null alfe--msg) (/= (type alfe--msg) 'STR) (= alfe--msg "")
                                 (= (strcase alfe--msg)
                                    (strcase "the engine supplied no message")))
                             "the engine supplied no message"
                             (strcat alfe--msg " -- the engine said no more"))
                         alfe--msg)))
  (if (autolisp-vague-error-message-p alfe--msg)
    (progn
      (setq alfe--shown (autolisp-readable-text alfe--form))
      (if (> (strlen alfe--shown) 200)
        (setq alfe--shown (strcat (substr alfe--shown 1 200) "...")))
      (setq alfe--text (strcat alfe--text " [form: " alfe--shown "]"))))
  alfe--text)

(defun autolisp-protocol-server-loop (/ alfe--keep alfe--form alfe--req-id alfe--result alfe--rc)
  (setq *AUTOLISP_PROTOCOL_INPUT_QUEUE* nil)
  (setq *AUTOLISP_PROTOCOL_STOP* nil)
  (setq *AUTOLISP_PROTOCOL_EMIT_WAITING_INPUT* nil)
  (autolisp-protocol-clear-stdout)
  (autolisp-protocol-clear-stderr)
  (setq alfe--req-id 0)
  (autolisp-protocol-set-status "READY 0")
  (while (not *AUTOLISP_PROTOCOL_STOP*)
    (setq *AUTOLISP_PROTOCOL_REQUEST_TEXT* nil)
    (setq alfe--form (vl-catch-all-apply 'autolisp-protocol-remote-read nil))
    (if (vl-catch-all-error-p alfe--form)
      (progn
        ;; ONE report, not two. This loop used to write the message to the
        ;; session log (autolisp-log-err) AND to the wire
        ;; (autolisp-protocol-write-stderr) -- two different files by
        ;; design. But run-common's bridge REDIRECTS autolisp-log-err onto
        ;; the protocol stderr so CAD-side warnings reach the user at all,
        ;; and the loop always runs with that bridge, so both calls landed
        ;; in the same file and the user saw every failure twice. Keep the
        ;; wire; the bridge keeps carrying everything else log-err is used
        ;; for. See alfe-cad-error-reported-twice-on-stderr.
        (autolisp-protocol-write-stderr
          (strcat "ERROR protocol read: "
                  (vl-catch-all-error-message alfe--form)))
        (autolisp-protocol-set-status "FAILED READ")
        (setq *AUTOLISP_PROTOCOL_STOP* T))
      (if (or *AUTOLISP_PROTOCOL_STOP*
              (eq alfe--form '__AUTOLISP_PROTOCOL_STOP__))
        nil
        (progn
          (setq alfe--req-id (+ alfe--req-id 1))
          (autolisp-protocol-set-status (strcat "RUNNING " (itoa alfe--req-id)))
          (setq alfe--result (vl-catch-all-apply
                         'autolisp-eval-request-source
                         (list alfe--form
                               (autolisp-first-form-text
                                 *AUTOLISP_PROTOCOL_REQUEST_TEXT*))))
          (if (vl-catch-all-error-p alfe--result)
            (if (or (and (boundp '*AUTOLISP_QUIT_REQUESTED*)
                         *AUTOLISP_QUIT_REQUESTED*)
                    (and (boundp '*AUTOLISP_QUIT_SIGNAL*)
                     (autolisp-quit-signal-p
                       (vl-catch-all-error-message alfe--result))))
              (progn
                (setq alfe--rc 0)
                (autolisp-set-status alfe--rc)
                (autolisp-protocol-set-status
                  (strcat "DONE " (itoa alfe--req-id) " QUIT"))
                (setq *AUTOLISP_PROTOCOL_STOP* T))
              (progn
                ;; One report, as above, and it names a cause: when the
                ;; engine's own message says nothing the form goes with it
                ;; (alfe-cad-load-error-message-says-only-error).
                (autolisp-protocol-write-stderr
                  (autolisp-request-failure-text
                    alfe--req-id
                    (autolisp-effective-error-message
                      (vl-catch-all-error-message alfe--result))
                    alfe--form))
                (autolisp-clear-last-error-context)
                (setq alfe--rc 1)
                (autolisp-set-status alfe--rc)
                (autolisp-protocol-set-status
                  (strcat "DONE " (itoa alfe--req-id) " FAIL"))))
            (progn
              ;; *AUTOLISP_STATUSFILE* still records the form value as
              ;; the legacy numeric exit code (batch scripts on the
              ;; SNCF tree consume that channel). The protocol DONE
              ;; status however is OK/FAIL/QUIT based on EVAL outcome,
              ;; NOT on the form's return value: every successful
              ;; evaluation -- including (+ 1 2) returning 3 -- must
              ;; land on `DONE N OK', otherwise the alfe-side REPL
              ;; sees every scalar value as a failure.
              (setq alfe--rc (autolisp-protocol-result-code alfe--result))
              (autolisp-set-status alfe--rc)
              (autolisp-protocol-set-status
                (strcat "DONE " (itoa alfe--req-id) " OK"))))))))
  (autolisp-protocol-set-status "STOPPED")
  ;; Return nil, NOT (princ "") -- under AutoCAD the host lacks &rest so the
  ;; bootstrap keeps the fixed 2-arg `princ' shadow (obj file); a 1-arg
  ;; (princ "") then raises "nombre d'arguments insuffisants" and aborts the
  ;; loop after it had already set STOPPED (giving the mystery status 99).
  ;; The loop's return value is discarded by the run-common outer catch.
  nil)

(defun autolisp-protocol-selftest-loop (/ alfe--keep alfe--control alfe--line alfe--form)
  (setq *AUTOLISP_PROTOCOL_INPUT_QUEUE* nil)
  (setq *AUTOLISP_PROTOCOL_STOP* nil)
  (setq *AUTOLISP_PROTOCOL_EMIT_WAITING_INPUT* T)
  (autolisp-protocol-clear-stdout)
  (autolisp-protocol-clear-stderr)
  (autolisp-protocol-set-status "READY")
  (setq alfe--keep T)
  (while alfe--keep
    (autolisp-protocol-handle-control)
    (if *AUTOLISP_PROTOCOL_STOP*
      (setq alfe--keep nil))
    (if alfe--keep
      (progn
        (setq alfe--line (autolisp-protocol-remote-read-line))
        (if (and alfe--line (/= alfe--line "__AUTOLISP_PROTOCOL_STOP__"))
          (progn
            (autolisp-protocol-set-status "RUNNING")
            (autolisp-protocol-write-stdout (strcat "LINE " alfe--line))
            (setq alfe--form (autolisp-protocol-remote-read))
            (autolisp-protocol-write-stdout
              (strcat "FORM " (vl-princ-to-string alfe--form)))
            (autolisp-protocol-write-stderr "STDERR done")
            (autolisp-protocol-set-status "READY"))
          (setq alfe--keep nil)))))
  (autolisp-protocol-set-status "STOPPED")
  ;; Return nil, NOT (princ "") -- under AutoCAD the host lacks &rest so the
  ;; bootstrap keeps the fixed 2-arg `princ' shadow (obj file); a 1-arg
  ;; (princ "") then raises "nombre d'arguments insuffisants" and aborts the
  ;; loop after it had already set STOPPED (giving the mystery status 99).
  ;; The loop's return value is discarded by the run-common outer catch.
  nil)

(defun C:AUTOLISP-PROTOCOL-SELFTEST ()
  (autolisp-protocol-selftest-loop))
