;;;; clautolisp/tools/clautolisp/tests/aldb-socket-tests.lisp
;;;;
;;;; End-to-end tests for the aldb (Emacs) RPC transports (debugger §10): the
;;;; TCP listener and the stdio channel. Each drives a real debug session that
;;;; stops on an uncaught error and, at the stop, aborts it from the aldb side —
;;;; exercising the emacs-ui over the wire and the command round-trip, with no
;;;; external Emacs. Unit tests cover the pieces (address parsing, the RPC over
;;;; string streams in the emacs suite, the transport gating); these prove they
;;;; compose over each transport.
;;;;
;;;; Both tests are DETERMINISTIC and SINGLE-THREADED: the resume command
;;;; (:abort) is queued on the channel BEFORE the session runs, so the debugger
;;;; reads it the moment it reaches (:await-command). There is no second thread
;;;; and no reactive send, hence no read/write interleaving, accept, or teardown
;;;; race. The earlier live-socket version drove the socket from a client thread
;;;; and flaked on the SECOND in-process suite run (the whole suite runs twice,
;;;; sharing state) — the debugger reached the await, read EOF from a
;;;; raced/torn-down client, took the EOF=>:continue branch, and let the error
;;;; escape uncaught. Patched three times on macOS (4043f8ee / bc0e147a /
;;;; 3526bc2d) and resurfaced on Windows; pre-queuing the command removes the
;;;; race at its source instead of chasing the timing.

(in-package #:clautolisp.tools.clautolisp.tests)

(in-suite clautolisp-tool-suite)

(defun %aldb-listener-port (ui)
  "The port the listener UI actually bound (its address is \"HOST:PORT\")."
  (let ((address (clautolisp.tools.clautolisp::aldb-address ui)))
    (parse-integer address :start (1+ (position #\: address :from-end t)))))

(defun %aldb-erroring-thunk (context)
  "A thunk that raises a deterministic unhandled AUTOLISP-RUNTIME-ERROR: a call
to an UNDEFINED function, in a bare context that installs no builtins. (Never
install builtins here — that resets *COM-LOADED-P* and breaks the later cador
SAFEARRAY tests — and the `/' path's pathname-normalised name `/.' once escaped
on macOS.)"
  (lambda ()
    (clautolisp.autolisp-runtime:autolisp-eval
     (first (clautolisp.autolisp-runtime:read-runtime-from-string
             "(aldb-no-such-function)"))
     context)))

(defun %aldb-slurp (stream)
  "Read STREAM to EOF and return its text. Used after the session has closed its
end, so EOF is reached without blocking."
  (with-output-to-string (out)
    (handler-case
        (loop for line = (read-line stream nil nil)
              while line do (write-line line out))
      (stream-error () nil))))          ; a benign teardown RST → keep what we read

(defun %aldb-check-wire (wire)
  "Assert WIRE carries the full Elisp-readable exchange and leaks no CL package."
  (is (search "(:attached" wire))
  (is (search ":unhandled-error" wire))
  (is (search "(:await-command)" wire))
  (is (search "(:detached)" wire))
  (is (not (search "COMMON-LISP" (string-upcase wire)))))

(test aldb-listener-drives-a-live-socket-session
  ;; TCP transport: a real loopback listener, driven deterministically. Connect
  ;; first (the listener socket is already bound, so this queues in the backlog
  ;; and the stop's ACCEPT returns at once), pre-send (:abort), then run the
  ;; erroring session. The emacs delegate writes its notifications and, at
  ;; (:await-command), reads the already-buffered (:abort) → the session aborts.
  (let* ((context (clautolisp.autolisp-runtime:make-default-runtime-context))
         (ui (clautolisp.tools.clautolisp::make-aldb-listener-ui "127.0.0.1:0" context))
         (port (%aldb-listener-port ui))
         (client (usocket:socket-connect "127.0.0.1" port :element-type 'character)))
    (unwind-protect
         (let ((cstream (usocket:socket-stream client)))
           ;; queue the resume command before the server ever reads it
           (write-line "(:abort)" cstream)
           (finish-output cstream)
           (let ((outcome
                   ;; suppress the connect prompt (→ a string sink) and starve the
                   ;; 1/2 terminal-fallback poll (→ empty stdin), so the listener
                   ;; commits to the socket, not a stray keypress.
                   (let ((*standard-output* (make-string-output-stream))
                         (*standard-input* (make-string-input-stream "")))
                     (clautolisp.debug.ui:call-with-session
                      ui (%aldb-erroring-thunk context) :context context))))
             (is (eq :aborted outcome))
             (%aldb-check-wire (%aldb-slurp cstream))))
      (ignore-errors (usocket:socket-close client)))))

(test aldb-stdio-drives-the-session
  ;; STDIO transport (--aldb-stdio): the emacs UI over string streams, no socket
  ;; and no thread. Same exchange as the listener test — the resume command is
  ;; pre-seeded on the input stream, and the wire is read from the output stream
  ;; after the session ends.
  (let* ((context (clautolisp.autolisp-runtime:make-default-runtime-context))
         (input (make-string-input-stream "(:abort)"))
         (output (make-string-output-stream))
         (outcome (clautolisp.debug.ui:call-with-session
                   :aldb (%aldb-erroring-thunk context)
                   :context context
                   :ui-initargs (list :input input :output output))))
    (is (eq :aborted outcome))
    (%aldb-check-wire (get-output-stream-string output))))
