(in-package #:clautolisp.autolisp-cli)

;;;; The debugger (aldo) options as data: what they request, and how a
;;;; front end forwards them to an engine it runs as a child.
;;;;
;;;; The option SPECS are in *COMMON-OPTION-SPECS* (spec.lisp): the
;;;; clautolisp program and alfe both accept --on-error, --on-interrupt,
;;;; --on-quit, --debugger-ui, --aldb-listen and --aldb-stdio
;;;; (debugger-public-interface-and-on-error.issue; shared with alfe by
;;;; pjb's decision of 2026-10-06). These functions are pure -- no I/O, no
;;;; debugger -- so both programs, and their tests, reach the same answers.

(defparameter *debugger-option-names*
  '("--on-error" "--on-interrupt" "--on-quit"
    "--debugger-ui" "--aldb-listen" "--aldb-stdio")
  "The long names of the debugger options, in their usage-text order.")

(defun validate-debugger-options (options)
  "Cross-option validation for the aldb channel options
(debugger-public-interface-and-on-error.issue C.2): --aldb-stdio turns the
process's stdin/stdout into the aldb RPC channel, so it is mutually exclusive
with --interactive (the REPL would fight the RPC for stdio) and with
--aldb-listen (one transport at a time). Signals a CLI-USAGE-ERROR; returns
OPTIONS otherwise."
  (when (cli-options-aldb-stdio-p options)
    (when (cli-options-interactive-p options)
      (error 'cli-usage-error
             :option "--aldb-stdio"
             :message "--aldb-stdio and --interactive are mutually exclusive (stdio becomes the aldb RPC channel)"))
    (when (or (cli-options-aldb-address options)
              (cli-options-aldb-port options))
      (error 'cli-usage-error
             :option "--aldb-stdio"
             :message "--aldb-stdio and --aldb-listen are mutually exclusive (pick one aldb transport)")))
  options)

(defun effective-user-interface (options)
  "The --debugger-ui selection from OPTIONS, with the aldb-channel
implication (debugger-public-interface-and-on-error.issue C.3): an aldb
transport option (--aldb-listen / --aldb-stdio) implies the aldb UI unless
an explicit --debugger-ui says otherwise. NIL when no UI was requested."
  (or (cli-options-user-interface options)
      (and (or (cli-options-aldb-address options)
               (cli-options-aldb-port options)
               (cli-options-aldb-stdio-p options))
           :aldb)))

(defun debugger-session-requested-p (options)
  "True when OPTIONS EXPLICITLY arm a debug session: --on-error debug, a
debugger UI (--debugger-ui, or an aldb transport, which implies one), or an
explicit --on-quit debug / --on-interrupt debug. The defaults never do -- the
interrupt default is debug, and it must not arm a session for every run; an
interactive REPL arms one through its own on-error default, which the engine
applies.

A front end running the engine as a child uses this to know that the child
will talk to the user (a DBG> prompt, an aldb connection), so it must be given
the terminal instead of captured pipes."
  (and (or (eq (cli-options-on-error options) :debug)
           (effective-user-interface options)
           (eq (cli-options-on-quit options) :debug)
           (eq (cli-options-on-interrupt options) :debug))
       t))

(defun aldb-listen-argument (host port)
  "The --aldb-listen value that names HOST and PORT, as PARSE-ALDB-LISTEN
reads it back: PORT alone when HOST is NIL, HOST:PORT otherwise, an IPv6
literal (a HOST with a colon) in brackets."
  (cond ((null host) (format nil "~A" port))
        ((find #\: host) (format nil "[~A]:~A" host port))
        (t (format nil "~A:~A" host port))))

(defun debugger-option-arguments (options)
  "The argv fragment that gives an engine the debugger options OPTIONS
carry -- only the ones the user GAVE, spelled as the engine's own parser reads
them, so the engine applies its own context-dependent defaults to the rest.
Used by alfe to forward them to a clautolisp child (--backend subprocess)."
  (flet ((policy (option value)
           (when value (list option (string-downcase (symbol-name value))))))
    (append
     (policy "--on-error" (cli-options-on-error options))
     (policy "--on-interrupt" (cli-options-on-interrupt options))
     (policy "--on-quit" (cli-options-on-quit options))
     (policy "--debugger-ui" (cli-options-user-interface options))
     (when (or (cli-options-aldb-address options)
               (cli-options-aldb-port options))
       (list "--aldb-listen"
             (aldb-listen-argument (cli-options-aldb-address options)
                                   (cli-options-aldb-port options))))
     (when (cli-options-aldb-stdio-p options)
       (list "--aldb-stdio")))))

(defun given-debugger-options (options)
  "The long names of the debugger options OPTIONS carry (the user gave them),
in *DEBUGGER-OPTION-NAMES* order."
  (remove-if-not
   (lambda (name)
     (cond ((string= name "--on-error")     (cli-options-on-error options))
           ((string= name "--on-interrupt") (cli-options-on-interrupt options))
           ((string= name "--on-quit")      (cli-options-on-quit options))
           ((string= name "--debugger-ui")  (cli-options-user-interface options))
           ((string= name "--aldb-listen")  (or (cli-options-aldb-address options)
                                                (cli-options-aldb-port options)))
           ((string= name "--aldb-stdio")   (cli-options-aldb-stdio-p options))))
   *debugger-option-names*))
