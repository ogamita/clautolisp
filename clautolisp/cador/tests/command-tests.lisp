(in-package #:clautolisp.cador.tests)

(in-suite cador-suite)

;;; --- Command dispatch (deferred-command-special-form issue) -------
;;;
;;; MockHost has no command engine: HOST-COMMAND records the routed
;;; token sequence on the per-session command log, echoes one line to
;;; PROMPT-OUTPUT, and returns nil. HOST-COMMAND-LOG reads the log
;;; back oldest-first.

(test host-command-records-tokens-and-returns-nil
  (let ((mock (make-cador)))
    (is (null (clautolisp.autolisp-host:host-command
               mock '("._LINE" "0.0,0.0,0.0" "10.0,10.0,0.0" ""))))
    (is (equal '(("._LINE" "0.0,0.0,0.0" "10.0,10.0,0.0" ""))
               (clautolisp.autolisp-host:host-command-log mock)))))

(test host-command-log-is-oldest-first
  (let ((mock (make-cador)))
    (clautolisp.autolisp-host:host-command mock '("._LINE"))
    (clautolisp.autolisp-host:host-command mock '("._CIRCLE" "1,2" "5.5"))
    (is (equal '(("._LINE") ("._CIRCLE" "1,2" "5.5"))
               (clautolisp.autolisp-host:host-command-log mock)))))

(test host-command-echoes-to-prompt-output
  (let ((mock (make-cador)))
    (clautolisp.autolisp-host:host-command mock '("._LINE" "" "\\"))
    (let ((echo (get-output-stream-string (cador-prompt-output mock))))
      (is (search "Command: ._LINE <RETURN> <PAUSE>" echo)))))

(test host-command-empty-sequence-is-a-cancel
  (let ((mock (make-cador)))
    (is (null (clautolisp.autolisp-host:host-command mock '())))
    (is (equal '(()) (clautolisp.autolisp-host:host-command-log mock)))
    (is (search "Command: *Cancel*"
                (get-output-stream-string (cador-prompt-output mock))))))
