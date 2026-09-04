;;;; clautolisp/tools/clautolisp/tests/aldb-socket-tests.lisp
;;;;
;;;; A live-socket integration test for the aldb TCP listener (debugger §10). It
;;;; opens a REAL ALDB-LISTENER-UI on an OS-chosen free port, runs a real debug
;;;; session that stops on an uncaught error, and drives it from a client socket
;;;; in a second thread — exercising the accept, the emacs-ui over the socket,
;;;; and the command round-trip end to end, with no external Emacs. Unit tests
;;;; cover the pieces (address parsing, the RPC over string streams, the gating);
;;;; this proves they compose over an actual TCP connection.

(in-package #:clautolisp.tools.clautolisp.tests)

(in-suite clautolisp-tool-suite)

(defun %aldb-listener-port (ui)
  "The port the listener UI actually bound (its address is \"HOST:PORT\")."
  (let ((address (clautolisp.tools.clautolisp::aldb-address ui)))
    (parse-integer address :start (1+ (position #\: address :from-end t)))))

(defun %aldb-drive-connected (sock)
  "Read the debugger's wire from the already-connected client SOCK until EOF,
sending (:abort) once it is awaiting a command. Return the lines as one string.
Bounded by a per-read timeout so a hang can never wedge the suite."
  (let ((stream (usocket:socket-stream sock))
        (lines '()))
    (unwind-protect
         ;; A benign teardown race (the server closing right after (:detached))
         ;; can surface as a stream error rather than a clean EOF; treat it as
         ;; end-of-session and keep whatever lines were already read.
         (handler-case
             (loop
               (unless (usocket:wait-for-input sock :timeout 15 :ready-only t)
                 (return))                               ; safety: no data for 15s
               (let ((line (read-line stream nil nil)))
                 (unless line (return))                  ; EOF: the session detached
                 (push line lines)
                 (when (search ":await-command" line)
                   (write-line "(:abort)" stream)
                   (finish-output stream))))
           (stream-error () nil))
      (ignore-errors (usocket:socket-close sock)))
    (format nil "~{~A~^~%~}" (nreverse lines))))

(test aldb-listener-drives-a-live-socket-session
  (let* (;; MAKE-DEFAULT-RUNTIME-CONTEXT does NOT install the builtins (its
         ;; caller does), so install them into this fresh context — otherwise
         ;; `/' is unbound and (/ 1 0) signals an undefined-function error (via
         ;; the vla-accessor hook, mangling the name to `/.') that escapes the
         ;; session, instead of the intended division-by-zero. The context is the
         ;; default now, so INSTALL-CORE-BUILTINS binds `/' &c. into it.
         (context (let ((c (clautolisp.autolisp-runtime:make-default-runtime-context)))
                    (clautolisp.autolisp-builtins-core:install-core-builtins)
                    c))
         (ui (clautolisp.tools.clautolisp::make-aldb-listener-ui "127.0.0.1:0" context))
         (port (%aldb-listener-port ui))
         ;; Connect BEFORE the session runs: the listener socket is already
         ;; bound, so this queues us in the backlog and the stop's ACCEPT returns
         ;; at once — the session never blocks waiting for a client that raced.
         (client-sock (usocket:socket-connect "127.0.0.1" port :element-type 'character))
         (wire nil)
         (client (bordeaux-threads:make-thread
                  (lambda () (setf wire (%aldb-drive-connected client-sock)))
                  :name "aldb-test-client")))
    (let ((outcome
            ;; Suppress the connect prompt (→ a string sink) and starve the 1/2
            ;; terminal-fallback poll (→ empty stdin), so the listener commits to
            ;; the socket, not a stray keypress.
            (let ((*standard-output* (make-string-output-stream))
                  (*standard-input* (make-string-input-stream "")))
              (clautolisp.debug.ui:call-with-session
               ui
               (lambda ()
                 (clautolisp.autolisp-runtime:autolisp-eval
                  (first (clautolisp.autolisp-runtime:read-runtime-from-string "(/ 1 0)"))
                  context))
               :context context))))
      (bordeaux-threads:join-thread client)
      ;; the erroring form aborted from the debugger (the client's (:abort))
      (is (eq :aborted outcome))
      ;; and the client saw the full Elisp-readable exchange over the socket
      (is (search "(:attached" wire))
      (is (search ":unhandled-error" wire))
      (is (search "(:await-command)" wire))
      (is (search "(:detached)" wire))
      (is (not (search "COMMON-LISP" (string-upcase wire)))))))
