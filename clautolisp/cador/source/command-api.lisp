(in-package #:clautolisp.cador)

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

(defun %cador-cmdecho-on-p (host)
  "True unless CMDECHO is 0. CMDECHO governs whether (command ...) echoes
the command line to the prompt output — its documented coupling (spec
§CMDECHO, whose Read/Written-By list names the command engine). An
absent or non-integer cell is treated as ON (the vendor default of 1),
so a host that never sets CMDECHO keeps echoing. system-variables.issue
'Coupling'."
  (let ((cell (ignore-errors (cador-sysvar host "CMDECHO"))))
    (or (null cell)
        (not (eql (sysvar-cell-value cell) 0)))))

(defmethod host-command ((host cador) arguments)
  (push arguments (cador-command-log host))
  ;; The command log is always recorded (so CLAL-COMMAND-LOG and tests
  ;; can see what was "typed"); only the human-readable echo obeys
  ;; CMDECHO, matching AutoCAD where CMDECHO=0 silences the prompt echo
  ;; without disabling the command itself.
  (let ((sink (cador-prompt-output host)))
    (when (and sink (%cador-cmdecho-on-p host))
      (if arguments
          (format sink "~&Command:~{ ~A~}~%"
                  (mapcar #'render-command-token arguments))
          ;; (command) with no arguments — the vendor-documented
          ;; "cancel the current command" call.
          (format sink "~&Command: *Cancel*~%"))
      (finish-output sink)))
  nil)

(defmethod host-command-log ((host cador))
  (reverse (cador-command-log host)))
