(in-package #:clautolisp.autolisp-mock-host)

;;;; Command-dispatch HAL methods on MockHost
;;;; (deferred-command-special-form issue).
;;;;
;;;; MockHost has no CAD command engine: there is nothing to parse
;;;; "._LINE" or to draw. The mock semantics of an AutoLISP
;;;; (command ...) call is therefore purely observational:
;;;;
;;;;   * the normalized token-string list the runtime routed here is
;;;;     recorded on the host's COMMAND-LOG (newest first, matching
;;;;     the DISPLAY-LOG convention), and
;;;;   * a human-readable one-line echo is written to PROMPT-OUTPUT,
;;;;     so an interactive REPL shows that the command was "typed".
;;;;
;;;; The call returns nil — the documented COMMAND return-value rule.
;;;; Tests and the CLAL-COMMAND-LOG extension read the log back
;;;; oldest-first through HOST-COMMAND-LOG.

(defun render-command-token (token)
  "Echo spelling for TOKEN: the RETURN token \"\" prints as <RETURN>,
the PAUSE token \"\\\\\" as <PAUSE>, anything else verbatim."
  (cond
    ((string= token "")   "<RETURN>")
    ((string= token "\\") "<PAUSE>")
    (t token)))

(defmethod host-command ((host mock-host) arguments)
  (push arguments (mock-host-command-log host))
  (let ((sink (mock-host-prompt-output host)))
    (when sink
      (if arguments
          (format sink "~&Command:~{ ~A~}~%"
                  (mapcar #'render-command-token arguments))
          ;; (command) with no arguments — the vendor-documented
          ;; "cancel the current command" call.
          (format sink "~&Command: *Cancel*~%"))
      (finish-output sink)))
  nil)

(defmethod host-command-log ((host mock-host))
  (reverse (mock-host-command-log host)))
