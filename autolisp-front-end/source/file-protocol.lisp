;;;; autolisp-front-end/source/file-protocol.lisp
;;;;
;;;; alfe.protocol.file — the file-IPC driver shared by the BricsCAD
;;;; and AutoCAD backends. Phase 2 of the alfe rollout.
;;;;
;;;; Specified by ../issues/open/alfe-file-protocol.issue and by
;;;; documentation/alfe--specifications.org sections "Protocole REPL
;;;; distant" and "Contrat AutoLISP côté runtime".
;;;;
;;;; The rationale lives in the spec: the AutoLISP REPL inside a CAD
;;;; engine has no IPC mechanism other than files (no sockets, no
;;;; pipes, no shared memory; the engine lives behind a GUI). So
;;;; alfe drops a small set of well-known files under
;;;; WORKDIR/protocol/ and the CAD-side runtime
;;;; (autolisp-remote-io.lsp, kept verbatim) reads/writes them on its
;;;; end. This file implements the *alfe-side* of that protocol — the
;;;; "shell" half of the legacy bash design.
;;;;
;;;; The contract is:
;;;;
;;;;   alfe atomically writes  stdin.txt / control.txt
;;;;   alfe reads incrementally stdout.txt / stderr.txt
;;;;   alfe polls               status.txt for state transitions
;;;;
;;;; "Atomically" means write to a temp file with a per-process suffix
;;;; (PATH.tmp.<pid>.<random>) and then RENAME-FILE onto the target.
;;;; The CAD-side runtime never sees a partial write.

(defpackage #:alfe.protocol.file
  (:use #:cl)
  (:import-from #:alfe.error
                #:backend-protocol-error)
  (:import-from #:alfe.workdir
                #:ensure-subdir
                #:current-pid)
  (:import-from #:clautolisp.autolisp-reader
                #:diagnostic
                #:diagnostic-code
                #:autolisp-dialect-strict)
  (:import-from #:clautolisp.autolisp-runtime
                #:derive-reader-options-for-dialect
                #:read-runtime-from-string)
  (:import-from #:alfe.logging
                #:log-debug
                #:log-verbose)
  (:export ;; session struct + accessors
           #:protocol-session
           #:make-protocol-session
           #:protocol-session-p
           #:protocol-session-workdir
           #:protocol-session-protocol-dir
           #:protocol-session-status-path
           #:protocol-session-stdin-path
           #:protocol-session-stdout-path
           #:protocol-session-stderr-path
           #:protocol-session-control-path
           #:protocol-session-heartbeat-path
           #:protocol-session-read-buffer-path
           #:protocol-session-runtime-info-path
           #:protocol-session-runtime-lsp-source
           #:protocol-session-runtime-lsp-staged
           #:protocol-session-stdout-offset
           #:protocol-session-stderr-offset
           ;; lifecycle
           #:init-session
           #:reset-session
           #:stage-runtime-lsp
           #:emit-run-common-lsp
           ;; atomic writes
           #:write-atomic-file
           ;; reads
           #:read-file-as-string
           #:last-non-empty-line
           #:read-current-status
           ;; status polling
           #:+status-booting+
           #:+status-ready-prefix+
           #:+status-running-prefix+
           #:+status-done-prefix+
           #:+status-stopping+
           #:+status-stopped+
           #:+status-failed-prefix+
           #:wait-for-status
           #:wait-for-status-prefix
           ;; output draining
           #:drain-stdout
           #:drain-stderr
           ;; line-to-form reader
           #:read-balanced-form-from-lines
           ;; control commands
           #:send-stdin
           #:send-control
           ;; heartbeat
           #:read-heartbeat))

(in-package #:alfe.protocol.file)

;;; --- protocol slot inventory ---------------------------------------
;;;
;;; The file layout below matches the spec's *AUTOLISP-PROTOCOL-*FILE*
;;; table byte-for-byte. The accessors return absolute pathnames so
;;; callers can hand them to OPEN, PROBE-FILE, or RENAME-FILE without
;;; re-merging.

;;; --- status vocabulary --------------------------------------------
;;;
;;; The constants below are defined here, *before* INIT-SESSION /
;;; RESET-SESSION reference them — SBCL otherwise warns about
;;; reading a not-yet-bound variable at compile time.

(defparameter +status-booting+         "BOOTING")
(defparameter +status-ready-prefix+    "READY")
(defparameter +status-running-prefix+  "RUNNING")
(defparameter +status-done-prefix+     "DONE")
(defparameter +status-stopping+        "STOPPING")
(defparameter +status-stopped+         "STOPPED")
(defparameter +status-failed-prefix+   "FAILED")

(defparameter +protocol-files+
  '((:status         . "status.txt")
    (:stdin          . "stdin.txt")
    (:stdout         . "stdout.txt")
    (:stderr         . "stderr.txt")
    (:control        . "control.txt")
    (:heartbeat      . "heartbeat.txt")
    (:read-buffer    . "read-buffer.lsp")
    (:runtime-info   . "runtime-info.txt"))
  "Alist mapping logical slot keyword to relative basename under the
session's protocol/ directory. Used by INIT-SESSION when building a
fresh session struct and by tests that want to assert the layout
matches the spec.")

;;; --- session struct ------------------------------------------------

(defstruct (protocol-session (:constructor %make-protocol-session))
  "Per-run state for the file-IPC driver. Every CAD backend that
needs file-IPC builds one of these via INIT-SESSION and threads it
through the EVAL-PLAN generic.

The STDOUT-OFFSET / STDERR-OFFSET slots are advanced by DRAIN-STDOUT
and DRAIN-STDERR so successive reads see only the new bytes."
  (workdir                nil :type (or null pathname))
  (protocol-dir           nil :type (or null pathname))
  (status-path            nil :type (or null pathname))
  (stdin-path             nil :type (or null pathname))
  (stdout-path            nil :type (or null pathname))
  (stderr-path            nil :type (or null pathname))
  (control-path           nil :type (or null pathname))
  (heartbeat-path         nil :type (or null pathname))
  (read-buffer-path       nil :type (or null pathname))
  (runtime-info-path      nil :type (or null pathname))
  ;; The path to the source autolisp-remote-io.lsp the caller wants
  ;; us to stage into WORKDIR/runtime/. NIL means "the CAD backend
  ;; provides it later" (Phase 3 wires this up; tests pass NIL).
  (runtime-lsp-source     nil :type (or null pathname string))
  (runtime-lsp-staged     nil :type (or null pathname))
  (stdout-offset            0 :type unsigned-byte)
  (stderr-offset            0 :type unsigned-byte))

;;; --- INIT-SESSION --------------------------------------------------

(defun init-session (workdir &key runtime-lsp-source)
  "Build a fresh PROTOCOL-SESSION under WORKDIR. Creates
WORKDIR/protocol/ with the spec's slot inventory, publishes the
initial `BOOTING` line to status.txt via the atomic-publish
primitive, leaves the other slots empty (or absent, depending on
the slot's contract). Returns the session.

RUNTIME-LSP-SOURCE, when provided, is the absolute path of the
upstream autolisp-remote-io.lsp the caller wants staged under
WORKDIR/runtime/; pass NIL when staging is the caller's job
(tests do this)."
  (let* ((workdir (uiop:ensure-directory-pathname workdir))
         (protocol-dir (ensure-subdir workdir "protocol"))
         (session (%make-protocol-session
                   :workdir workdir
                   :protocol-dir protocol-dir
                   :status-path (merge-pathnames "status.txt" protocol-dir)
                   :stdin-path (merge-pathnames "stdin.txt" protocol-dir)
                   :stdout-path (merge-pathnames "stdout.txt" protocol-dir)
                   :stderr-path (merge-pathnames "stderr.txt" protocol-dir)
                   :control-path (merge-pathnames "control.txt" protocol-dir)
                   :heartbeat-path (merge-pathnames "heartbeat.txt" protocol-dir)
                   :read-buffer-path (merge-pathnames "read-buffer.lsp"
                                                      protocol-dir)
                   :runtime-info-path (merge-pathnames "runtime-info.txt"
                                                       protocol-dir)
                   :runtime-lsp-source runtime-lsp-source)))
    (ensure-directories-exist protocol-dir)
    ;; Pre-create the empty output streams so the CAD-side runtime's
    ;; first append doesn't have to race a missing file. The
    ;; non-output slots (stdin, control) are intentionally absent
    ;; until something is published into them — the runtime side
    ;; detects pending input by PROBE-FILE.
    (touch-file (protocol-session-stdout-path session))
    (touch-file (protocol-session-stderr-path session))
    ;; Publish BOOTING. Use the atomic publisher so the runtime
    ;; never reads a partial banner if it happens to be polling
    ;; this exact moment.
    (write-atomic-file (protocol-session-status-path session)
                       +status-booting+)
    session))

(defun reset-session (session)
  "Truncate the published-by-runtime output channels, clear pending
input, and re-publish `BOOTING` on status.txt. Used between
back-to-back runs against the same WORKDIR (rare; useful for
soak-tests)."
  (touch-file (protocol-session-stdout-path session) :truncate t)
  (touch-file (protocol-session-stderr-path session) :truncate t)
  (when (probe-file (protocol-session-stdin-path session))
    (ignore-errors (delete-file (protocol-session-stdin-path session))))
  (when (probe-file (protocol-session-control-path session))
    (ignore-errors (delete-file (protocol-session-control-path session))))
  (setf (protocol-session-stdout-offset session) 0
        (protocol-session-stderr-offset session) 0)
  (write-atomic-file (protocol-session-status-path session)
                     +status-booting+)
  session)

(defun touch-file (path &key truncate)
  "Ensure PATH exists as an empty (or freshly truncated) file. Used
to pre-create the runtime's output channels so a polling reader has
something to OPEN."
  (with-open-file (out path
                       :direction :output
                       :if-exists (if truncate :supersede :append)
                       :if-does-not-exist :create
                       :external-format :utf-8)
    ;; Mention OUT in a no-op so SBCL stops warning that we both
    ;; declare it ignored AND read it (via the implicit close).
    (force-output out))
  path)

;;; --- atomic-write primitive ---------------------------------------

(defparameter *atomic-write-counter* 0
  "Monotonically-incrementing counter used as the unique component of
each atomic-write temp suffix. Under threaded contention the shared
*RANDOM-STATE* doesn't guarantee distinct draws across threads (its
internal mutation isn't atomic on every implementation), so we lean
on a counter plus a per-process random seed instead.")

(defparameter *atomic-write-counter-lock*
  #+(or sbcl ccl) (bordeaux-threads:make-lock "atomic-write-counter")
  #-(or sbcl ccl) nil
  "Lock protecting *ATOMIC-WRITE-COUNTER*. Pure CL-with-no-threading
implementations leave this NIL — the lock-guarded path falls back
to direct INCF.")

(defun next-atomic-counter ()
  (cond
    (*atomic-write-counter-lock*
     (bordeaux-threads:with-lock-held (*atomic-write-counter-lock*)
       (incf *atomic-write-counter*)))
    (t (incf *atomic-write-counter*))))

(defun atomic-temp-path (target)
  "Return a sibling pathname of TARGET safe for use as the
write-then-rename staging file. The caller owns the lifetime.

The temp name is built by NAMESTRING-concatenation rather than via
MAKE-PATHNAME with a multi-dot :type, because SBCL escapes the dots
in pathname components (a :type of \"txt.tmp.123.abc\" round-trips
as `txt\\.tmp\\.123\\.abc` and RENAME-FILE then fails).

The uniqueness component is a (pid, monotonic counter) pair —
guaranteed distinct across every call within one process, regardless
of how many threads are racing. The legacy bash wrapper used
`$$.$RANDOM` which works for the same reason."
  (let* ((counter (next-atomic-counter))
         (suffix  (format nil ".tmp.~D.~D" (current-pid) counter))
         (base    (namestring target)))
    (pathname (concatenate 'string base suffix))))

(defun write-atomic-file (target content &key (external-format :utf-8)
                                              (newline-p t))
  "Atomically publish CONTENT (a string) at TARGET. The implementation
writes CONTENT to a uniquely-named sibling of TARGET, then
RENAME-FILE's it onto TARGET. RENAME-FILE is atomic per POSIX on
the same filesystem, so the reader either sees the previous version
or the new one, never a torn write.

NEWLINE-P appends a trailing newline when CONTENT does not already
end in one — the runtime's `read-line` expects line-oriented
inputs. Pass :newline-p nil for binary-ish writes (rare)."
  (let* ((temp (atomic-temp-path target))
         (text (if (and newline-p
                        (plusp (length content))
                        (not (char= (char content (1- (length content)))
                                    #\Newline)))
                   (concatenate 'string content (string #\Newline))
                   content)))
    (with-open-file (out temp
                         :direction :output
                         :if-exists :supersede
                         :if-does-not-exist :create
                         :external-format external-format)
      (write-string text out)
      (finish-output out))
    ;; Use UIOP's overwriting-rename helper rather than CL's
    ;; RENAME-FILE: the standard's RENAME-FILE doesn't promise to
    ;; replace an existing target — SBCL happens to inherit POSIX
    ;; rename(2)'s replace-on-success semantic and works, but CCL
    ;; raises "File exists" instead. UIOP:RENAME-FILE-OVERWRITING-
    ;; TARGET dispatches to the right primitive per implementation
    ;; (POSIX rename on Unix, MoveFileEx with
    ;; MOVEFILE_REPLACE_EXISTING on Windows) so the contract holds
    ;; cross-Lisp + cross-OS without us probing *features*.
    (uiop:rename-file-overwriting-target temp target)
    target))

;;; --- reads ---------------------------------------------------------

(defun read-file-as-string (path &key (external-format :utf-8))
  "Slurp the entire contents of PATH as a UTF-8 string. Returns the
empty string when PATH does not exist; this is what the protocol
expects when the runtime hasn't published anything yet."
  (cond
    ((not (probe-file path)) "")
    (t
     (with-open-file (in path :direction :input
                              :external-format external-format)
       (with-output-to-string (out)
         (loop for ch = (read-char in nil :eof)
               until (eq ch :eof)
               do (write-char ch out)))))))

(defun last-non-empty-line (text)
  "Return the last non-blank line of TEXT, or NIL if TEXT has none.
The status channel records the entire transition history (the
runtime appends to it); the *current* state is the last line."
  (let ((lines (remove "" (uiop:split-string text :separator '(#\Newline))
                       :test #'string=)))
    (and lines (car (last lines)))))

(defun read-current-status (session)
  "Return the last non-empty line of SESSION's status.txt, or NIL
when the status file is missing or empty. The spec defines the
status channel as a *sequence* of transitions; this helper plucks
the live state for callers that only need a snapshot."
  (last-non-empty-line
   (read-file-as-string (protocol-session-status-path session))))

;;; --- status polling -----------------------------------------------

(defparameter *poll-initial-ms* 50
  "Initial back-off interval (milliseconds) used by the polling
helpers. The interval doubles each iteration up to *poll-max-ms*.")

(defparameter *poll-max-ms* 500
  "Upper bound on the back-off interval (milliseconds).")

(defun sleep-ms (ms)
  (sleep (/ ms 1000.0)))

(defun universal-time-now ()
  (get-internal-real-time))

(defun seconds-elapsed-since (start)
  (/ (float (- (universal-time-now) start))
     internal-time-units-per-second))

(defun wait-for-status (session expected &key (timeout 10))
  "Poll status.txt until its current line is STRING= to EXPECTED, or
TIMEOUT seconds have passed. Returns (values matched-p elapsed
last-status). Used for terminal transitions whose target is known
exactly (`BOOTING` → `STOPPED`, etc.)."
  (let ((start (universal-time-now))
        (interval-ms *poll-initial-ms*)
        (last-seen nil))
    (loop
      (setf last-seen (read-current-status session))
      (when (and last-seen (string= last-seen expected))
        (return (values t (seconds-elapsed-since start) last-seen)))
      (when (>= (seconds-elapsed-since start) timeout)
        (return (values nil (seconds-elapsed-since start) last-seen)))
      (sleep-ms interval-ms)
      (setf interval-ms (min *poll-max-ms* (* 2 interval-ms))))))

(defun starts-with-p (string prefix)
  "True iff STRING begins with PREFIX. Used by wait-for-status-prefix
to match `READY 0`, `RUNNING 7`, `DONE 7 OK`, etc., where the
suffix carries a request-counter we don't pin a priori."
  (and (>= (length string) (length prefix))
       (string= prefix string :end2 (length prefix))))

(defun wait-for-status-prefix (session prefix &key (timeout 10))
  "Like WAIT-FOR-STATUS but matches by prefix — the spec's status
table has parameterised states (`READY N`, `RUNNING N`, `DONE N OK`)
whose counter is set by the runtime."
  (log-debug "protocol: wait-for-status-prefix ~S (timeout ~A s)"
             prefix timeout)
  (let ((start (universal-time-now))
        (interval-ms *poll-initial-ms*)
        (last-seen nil)
        (prev-status nil))
    (loop
      (setf last-seen (read-current-status session))
      ;; Log on CHANGE only — the polling loop runs many times,
      ;; we don't want to flood the debug stream with identical
      ;; status reads. Matches the bash-script
      ;; `wait_for_status` pattern.
      (when (and last-seen (not (equal last-seen prev-status)))
        (log-debug "protocol: status now ~S (elapsed ~,2F s)"
                   last-seen (seconds-elapsed-since start))
        (setf prev-status last-seen))
      (when (and last-seen (starts-with-p last-seen prefix))
        (log-debug "protocol: matched ~S after ~,2F s"
                   prefix (seconds-elapsed-since start))
        (return (values t (seconds-elapsed-since start) last-seen)))
      (when (>= (seconds-elapsed-since start) timeout)
        (log-debug "protocol: timeout after ~,2F s (last status ~S)"
                   (seconds-elapsed-since start) last-seen)
        (return (values nil (seconds-elapsed-since start) last-seen)))
      (sleep-ms interval-ms)
      (setf interval-ms (min *poll-max-ms* (* 2 interval-ms))))))

;;; --- output draining -----------------------------------------------

(defun drain-channel (path offset-place)
  "Generic incremental reader. Opens PATH for input, skips to the
saved OFFSET-PLACE byte position, reads the rest as UTF-8, and
advances OFFSET-PLACE to the new file length. Returns the new text.

When PATH does not exist (the runtime hasn't published anything
yet), returns the empty string and leaves OFFSET-PLACE unchanged.

Note we read by *character*, not by raw byte: the spec says the
runtime never tears a multi-byte UTF-8 sequence (appends are
line-buffered), so a character-mode reader is safe."
  (cond
    ((not (probe-file path)) "")
    (t
     (with-open-file (in path :direction :input
                              :element-type 'character
                              :external-format :utf-8)
       (let ((current-offset (funcall offset-place)))
         ;; FILE-POSITION on a character stream is in characters
         ;; under SBCL/CCL for UTF-8 inputs — we therefore track our
         ;; offset in characters too, consistent with what the spec
         ;; calls "the offset". The runtime appends a fixed number of
         ;; characters per write, never partial code points, so this
         ;; lines up.
         (file-position in current-offset)
         (let ((collected (with-output-to-string (out)
                            (loop for ch = (read-char in nil :eof)
                                  until (eq ch :eof)
                                  do (write-char ch out)
                                     (incf current-offset)))))
           (funcall offset-place current-offset)
           collected))))))

(defun drain-stdout (session)
  "Return the bytes published to stdout.txt since the previous
DRAIN-STDOUT call. Advances SESSION's offset."
  (drain-channel
   (protocol-session-stdout-path session)
   (lambda (&optional new-value)
     (if new-value
         (setf (protocol-session-stdout-offset session) new-value)
         (protocol-session-stdout-offset session)))))

(defun drain-stderr (session)
  "Mirror of DRAIN-STDOUT for the stderr channel."
  (drain-channel
   (protocol-session-stderr-path session)
   (lambda (&optional new-value)
     (if new-value
         (setf (protocol-session-stderr-offset session) new-value)
         (protocol-session-stderr-offset session)))))

;;; --- line-to-form reader ------------------------------------------

(defun incomplete-form-error-p (condition)
  "True iff CONDITION carries the reader's :unexpected-eof
diagnostic. Used by READ-BALANCED-FORM-FROM-LINES to know whether
to ask the line-source for another continuation."
  (let* ((arguments (simple-condition-format-arguments condition))
         (first (and arguments (first arguments))))
    (and (typep first 'diagnostic)
         (eq :unexpected-eof (diagnostic-code first)))))

(defun read-balanced-form-from-lines (line-source
                                      &key (dialect (autolisp-dialect-strict))
                                           (source-name "<protocol-stdin>"))
  "Pull lines from LINE-SOURCE (a thunk returning the next line as a
string, or NIL on EOF) until the accumulated text is parser-
balanced under DIALECT. Returns (values text eof-p), where TEXT is
the concatenated lines suitable for hand-off to
READ-RUNTIME-FROM-STRING, or NIL on EOF without any line.

This is the alfe-side counterpart of the CAD runtime's
`autolisp-protocol-remote-read` — both sides agree on the same
parser, so a multi-line form composed line-by-line on the wire
reassembles identically on both sides."
  (let ((accumulated nil))
    (loop
      (let ((line (funcall line-source)))
        (cond
          ((and (null line) (null accumulated))
           (return (values nil t)))
          ((null line)
           (return (values accumulated nil)))
          (t
           (setf accumulated
                 (if accumulated
                     (concatenate 'string accumulated (string #\Newline) line)
                     line))
           (handler-case
               (progn
                 (read-runtime-from-string
                  accumulated
                  :options (derive-reader-options-for-dialect
                            dialect :source-name source-name))
                 (return (values accumulated nil)))
             (simple-error (condition)
               (unless (incomplete-form-error-p condition)
                 ;; Genuine reader error — surface the text so the
                 ;; caller can decide whether to error or retry.
                 (return (values accumulated nil)))))))))))

;;; --- control sender ------------------------------------------------

(defparameter +control-commands+ '("PING" "SHUTDOWN" "INTERRUPT")
  "The full set of out-of-band commands the spec defines for
control.txt. Listed here so SEND-CONTROL can refuse anything
unrecognised before it reaches the wire.")

(defun wait-for-slot-free (path &key (timeout 5))
  "Poll until PATH does not exist (the runtime has consumed any
previously-published value), or TIMEOUT expires. Returns T iff the
slot was found free within the budget."
  (let ((start (universal-time-now))
        (interval-ms *poll-initial-ms*))
    (loop
      (unless (probe-file path)
        (return t))
      (when (>= (seconds-elapsed-since start) timeout)
        (return nil))
      (sleep-ms interval-ms)
      (setf interval-ms (min *poll-max-ms* (* 2 interval-ms))))))

(defun send-stdin (session text &key (wait-timeout 5))
  "Atomically publish TEXT into stdin.txt. Waits up to WAIT-TIMEOUT
seconds for any prior publication to be consumed (the runtime's
consumption is destructive: it deletes the file after reading), so
back-to-back sends don't lose lines. Signals BACKEND-PROTOCOL-ERROR
when the slot stays occupied past the timeout."
  (let ((path (protocol-session-stdin-path session)))
    (unless (wait-for-slot-free path :timeout wait-timeout)
      (error 'backend-protocol-error
             :backend :file-protocol
             :code :stdin-busy
             :message (format nil "stdin.txt did not become free within ~D s"
                              wait-timeout)
             :details (list :path path)))
    (write-atomic-file path text)))

(defun send-control (session command &key (wait-timeout 5))
  "Atomically publish COMMAND into control.txt. COMMAND is one of
:ping :shutdown :interrupt; SEND-CONTROL refuses anything else with
BACKEND-PROTOCOL-ERROR."
  (let ((path (protocol-session-control-path session))
        (text (case command
                (:ping      "PING")
                (:shutdown  "SHUTDOWN")
                (:interrupt "INTERRUPT")
                (otherwise
                 (error 'backend-protocol-error
                        :backend :file-protocol
                        :code :unknown-control
                        :message (format nil "Unknown control command ~S"
                                         command)
                        :details (list :command command
                                       :allowed +control-commands+))))))
    (unless (wait-for-slot-free path :timeout wait-timeout)
      (error 'backend-protocol-error
             :backend :file-protocol
             :code :control-busy
             :message (format nil "control.txt did not become free within ~D s"
                              wait-timeout)
             :details (list :path path)))
    (write-atomic-file path text)))

;;; --- heartbeat -----------------------------------------------------

(defun read-heartbeat (session)
  "Return the last line of heartbeat.txt (the timestamp the runtime
last published), or NIL when no heartbeat has been published yet.
Absence is NOT an error: the spec calls heartbeat publication
optional."
  (let ((text (read-file-as-string
               (protocol-session-heartbeat-path session))))
    (and (plusp (length text))
         (last-non-empty-line text))))

;;; --- run-common.lsp emitter ---------------------------------------
;;;
;;; This emitter materialises the run-common.lsp template documented
;;; in the spec (section "Emitted run-common.lsp template"), with
;;; placeholders bound to session-resolved absolute paths. The
;;; AutoLISP runtime (autolisp-remote-io.lsp) consumes
;;; *AUTOLISP_PROTOCOL_*FILE* globals (underscore-separated) while
;;; the spec template uses *AUTOLISP-PROTOCOL-*FILE* (hyphen-
;;; separated). To keep both consumers happy without forking the
;;; runtime we emit *both* spellings; AutoLISP's case-insensitive
;;; reader treats them as distinct identifiers because of the
;;; underscore-vs-hyphen difference.

(defun stringify-path (path)
  "Render PATH as an absolute namestring suitable for embedding in
AutoLISP source. Returns the empty string when PATH is NIL so the
emitted source still parses."
  (if path
      (namestring (truename* path))
      ""))

(defun truename* (path)
  "TRUENAME that doesn't signal when PATH refers to a not-yet-created
file. The protocol slots may not exist at emit time; the runtime
will create them. We prefer TRUENAME for the parent directory to
canonicalise but accept the merged path otherwise."
  (or (probe-file path)
      (handler-case
          (merge-pathnames (file-namestring path)
                           (truename (make-pathname
                                      :defaults path
                                      :name nil :type nil :version nil)))
        (error () path))))

(defun bool->autolisp (boolean)
  (if boolean "T" "nil"))

(defun %render-autolisp-literal-element (value)
  "Render VALUE as its element-position spelling inside an already
quoted list context — symbols are bare, strings are quoted, lists
are parenthesised without a leading apostrophe. Inverse helper to
%RENDER-AUTOLISP-LITERAL, which prepends the apostrophe at top
level only."
  (cond
    ((null value) "nil")
    ((eq value t) "t")
    ((typep value 'clautolisp.autolisp-runtime:autolisp-symbol)
     (clautolisp.autolisp-runtime:autolisp-symbol-name value))
    ((typep value 'clautolisp.autolisp-runtime:autolisp-string)
     (format nil "~S"
             (clautolisp.autolisp-runtime.internal::autolisp-string-value value)))
    ((integerp value) (format nil "~D" value))
    ((consp value)
     ;; Nested list inside an already-quoted context: bare parens,
     ;; no extra apostrophe.
     (format nil "(~{~A~^ ~})"
             (mapcar #'%render-autolisp-literal-element value)))
    (t (format nil "~S" value))))

(defun %render-autolisp-literal (value)
  "Render VALUE as the AutoLISP literal source the remote engine
will read via LOAD. Used by EMIT-CLI-TRANSMIT-BINDINGS to format
the CLI-derived globals into setq forms. A list value is rendered
with a single leading apostrophe (`'(…)`); nested lists inside
are rendered bare (`(…)`) to avoid double-quoting."
  (cond
    ((null value) "nil")
    ((eq value t) "t")
    ((typep value 'clautolisp.autolisp-runtime:autolisp-symbol)
     (format nil "'~A"
             (clautolisp.autolisp-runtime:autolisp-symbol-name value)))
    ((typep value 'clautolisp.autolisp-runtime:autolisp-string)
     (format nil "~S"
             (clautolisp.autolisp-runtime.internal::autolisp-string-value value)))
    ((integerp value) (format nil "~D" value))
    ((consp value)
     (format nil "'(~{~A~^ ~})"
             (mapcar #'%render-autolisp-literal-element value)))
    (t (format nil "~S" value))))

(defun emit-cli-transmit-bindings (stream cli-options version-text emit-var)
  "Walk ALFE.CLI:CLI-OPTIONS-TRANSMIT-BINDINGS-FOR-ALFE on
CLI-OPTIONS (the alfe-side action-object → cons translation
wrapper) and emit a setq form per binding via EMIT-VAR (which
already knows the hyphen + underscore pairing convention). Skip
the dynamically-scoped *AUTOLISP-INTERACTIVE* / *AUTOLISP-LOAD-
PATHNAME* / *AUTOLISP-EXPRESSION* — those are set per-action by
the runtime, not statically at run-common emission. The HELP
string is omitted by default to keep run-common.lsp small; user
code that needs it can re-derive it from --help on demand."
  (declare (ignore stream))
  (let* ((bindings (alfe.cli:cli-options-transmit-bindings-for-alfe
                    cli-options
                    :backend "ALFE"
                    :version-text version-text))
         (skip '("*AUTOLISP-INTERACTIVE*"
                 "*AUTOLISP-LOAD-PATHNAME*"
                 "*AUTOLISP-EXPRESSION*"
                 "*AUTOLISP-HELP*")))
    (dolist (binding bindings)
      (let ((name (first binding))
            (value (second binding)))
        (unless (member name skip :test #'string=)
          (funcall emit-var
                   name
                   ;; Underscore-variant for the AutoCAD reader: the
                   ;; transmit globals are part of the same ;-_-
                   ;; double-emission scheme as the protocol slots.
                   (substitute #\_ #\- name)
                   (%render-autolisp-literal value)))))))

(defun emit-run-common-lsp (session
                            &key (path
                                   (merge-pathnames
                                    "run-common.lsp"
                                    (protocol-session-workdir session)))
                                 (version '(0 0 3))
                                 (bootstrap-phase :full)
                                 (use-remote-protocol-p t)
                                 (quit-on-finish-p t)
                                 (debug-p nil)
                                 (invocation-dir (uiop:getcwd))
                                 (log-name "autolisp-session.log")
                                 cli-options
                                 version-text)
  "Write the run-common.lsp init script the CAD-side runtime sources
at startup. Substitutes the spec's placeholders with absolute paths
drawn from SESSION; the remaining knobs (BOOTSTRAP-PHASE, DEBUG-P,
…) come from the alfe CLI options.

When CLI-OPTIONS is non-NIL, the CLI-derived *AUTOLISP-…* globals
from transmit-options.issue are emitted at the *top* of the file
(*AUTOLISP-VERSION* in first position, per the issue's remote
table). They precede the protocol-related globals so the CAD-side
init code can branch on them while it's still wiring up the
protocol scaffolding. VERSION-TEXT is the alfe build version
string published as *AUTOLISP-VERSION* (e.g. \"1.0.9\"); the
run-common protocol generation (e.g. (0 0 3)) moves to
*AUTOLISP-RUNCOMMON-VERSION* to avoid collision.

Returns the path of the emitted file."
  (let* ((workdir (protocol-session-workdir session))
         (logs-dir (ensure-subdir workdir "logs"))
         (debug-file (merge-pathnames "debug.log" logs-dir))
         (outfile (merge-pathnames "output.txt" workdir))
         (errfile (merge-pathnames "errors.txt" workdir))
         (statusfile (merge-pathnames "status.txt" workdir))
         (inpfile (merge-pathnames "input.txt" workdir))
         (renderfile (merge-pathnames "render.txt" workdir))
         (lines
          (with-output-to-string (out)
            (format out ";;; alfe — generated run-common.lsp~%")
            (format out ";;; This file is regenerated on every alfe invocation.~%")
            (format out ";;; Do not edit by hand.~%~%")
            ;; --- Injected globals (hyphen + underscore variants) ---
            (flet ((emit-var (hyphen underscore value-form)
                     (format out "(setq ~A ~A)~%" hyphen value-form)
                     (format out "(setq ~A ~A)~%" underscore value-form)))
              ;; --- CLI-derived globals (transmit-options.issue) ---
              ;; Emitted *first* so the CAD-side init code sees the
              ;; alfe-invocation metadata before any protocol wiring.
              ;; *AUTOLISP-VERSION* is the first entry per the issue's
              ;; remote table.
              (when cli-options
                (emit-cli-transmit-bindings out cli-options
                                            (or version-text "0.0.0")
                                            #'emit-var))
              (flet ((emit-path (hyphen underscore path)
                       (emit-var hyphen underscore
                                 (format nil "~S" (stringify-path path)))))
                (emit-path "*AUTOLISP-OUTFILE*"                "*AUTOLISP_OUTFILE*"                outfile)
                (emit-path "*AUTOLISP-ERRFILE*"                "*AUTOLISP_ERRFILE*"                errfile)
                (emit-path "*AUTOLISP-STATUSFILE*"             "*AUTOLISP_STATUSFILE*"             statusfile)
                (emit-path "*AUTOLISP-INPFILE*"                "*AUTOLISP_INPFILE*"                inpfile)
                (emit-path "*AUTOLISP-LOGDIR*"                 "*AUTOLISP_LOGDIR*"                 logs-dir)
                (emit-path "*AUTOLISP-RENDERFILE*"             "*AUTOLISP_RENDERFILE*"             renderfile)
                (emit-path "*AUTOLISP-PROTOCOL-DIR*"           "*AUTOLISP_PROTOCOL_DIR*"
                           (protocol-session-protocol-dir session))
                (emit-path "*AUTOLISP-PROTOCOL-STATUSFILE*"    "*AUTOLISP_PROTOCOL_STATUSFILE*"
                           (protocol-session-status-path session))
                (emit-path "*AUTOLISP-PROTOCOL-STDINFILE*"     "*AUTOLISP_PROTOCOL_STDINFILE*"
                           (protocol-session-stdin-path session))
                (emit-path "*AUTOLISP-PROTOCOL-STDOUTFILE*"    "*AUTOLISP_PROTOCOL_STDOUTFILE*"
                           (protocol-session-stdout-path session))
                (emit-path "*AUTOLISP-PROTOCOL-STDERRFILE*"    "*AUTOLISP_PROTOCOL_STDERRFILE*"
                           (protocol-session-stderr-path session))
                (emit-path "*AUTOLISP-PROTOCOL-CONTROLFILE*"   "*AUTOLISP_PROTOCOL_CONTROLFILE*"
                           (protocol-session-control-path session))
                (emit-path "*AUTOLISP-PROTOCOL-HEARTBEATFILE*" "*AUTOLISP_PROTOCOL_HEARTBEATFILE*"
                           (protocol-session-heartbeat-path session))
                (emit-path "*AUTOLISP-PROTOCOL-READFILE*"      "*AUTOLISP_PROTOCOL_READFILE*"
                           (protocol-session-read-buffer-path session))
                (emit-path "*AUTOLISP-PROTOCOL-INFOFILE*"      "*AUTOLISP_PROTOCOL_INFOFILE*"
                           (protocol-session-runtime-info-path session))
                (emit-path "*AUTOLISP-PROTOCOL-RUNTIMEFILE*"   "*AUTOLISP_PROTOCOL_RUNTIMEFILE*"
                           (protocol-session-runtime-lsp-staged session))
                (emit-path "*AUTOLISP-DEBUGFILE*"              "*AUTOLISP_DEBUGFILE*"            debug-file))
              (emit-var "*AUTOLISP-USE-REMOTE-PROTOCOL*"
                        "*AUTOLISP_USE_REMOTE_PROTOCOL*"
                        (if use-remote-protocol-p "1" "0"))
              (emit-var "*AUTOLISP-LOGNAME*"
                        "*AUTOLISP_LOGNAME*"
                        (format nil "~S" log-name))
              (emit-var "*AUTOLISP-QUIT-ON-FINISH*"
                        "*AUTOLISP_QUIT_ON_FINISH*"
                        (bool->autolisp quit-on-finish-p))
              (emit-var "*AUTOLISP-BOOTSTRAP-PHASE*"
                        "*AUTOLISP_BOOTSTRAP_PHASE*"
                        (format nil "~S" (string-downcase
                                          (symbol-name bootstrap-phase))))
              (emit-var "*AUTOLISP-INVOCATION-DIR*"
                        "*AUTOLISP_INVOCATION_DIR*"
                        (format nil "~S" (namestring invocation-dir)))
              (emit-var "*AUTOLISP-DEBUG*"
                        "*AUTOLISP_DEBUG*"
                        (bool->autolisp debug-p))
              ;; The run-common.lsp protocol generation (a list like
              ;; (0 0 3)) used to be emitted as *AUTOLISP-VERSION*.
              ;; Renamed here to avoid colliding with the CLI-derived
              ;; *AUTOLISP-VERSION* (the alfe build version, a string)
              ;; published above when CLI-OPTIONS is supplied.
              (emit-var "*AUTOLISP-RUNCOMMON-VERSION*"
                        "*AUTOLISP_RUNCOMMON_VERSION*"
                        (format nil "'(~D ~D ~D)"
                                (first version)
                                (second version)
                                (third version))))
            ;; --- Source the CAD-side runtime ---
            ;; When the runtime has been staged, instruct the CAD to
            ;; LOAD it so the *AUTOLISP_PROTOCOL_* helpers exist before
            ;; user code runs, then enter the server loop at top level
            ;; so BricsCAD's SCR / accoreconsole doesn't fall through
            ;; to EOF and exit. The CAD backend is responsible for
            ;; sourcing run-common.lsp itself (usually via a one-line
            ;; SCR script).
            (when (protocol-session-runtime-lsp-staged session)
              (format out "~%(load ~S)~%"
                      (stringify-path
                       (protocol-session-runtime-lsp-staged session)))
              ;; Drive the loop. The runtime defines the function but
              ;; does not call it at top level; the legacy bash wrapper
              ;; emitted an autolisp-main-entry tail that we replicate
              ;; here in a leaner form. vl-catch-all-apply contains any
              ;; bootstrap error so a misconfigured runtime publishes a
              ;; FAILED status rather than crashing BricsCAD silently.
              (format out
                      "(setq *AUTOLISP-PROTOCOL-LOOP-RESULT*~%~
                              (vl-catch-all-apply 'autolisp-protocol-server-loop nil))~%")))))
    (with-open-file (out path :direction :output
                              :if-exists :supersede
                              :if-does-not-exist :create
                              :external-format :utf-8)
      (write-string lines out))
    path))

;;; --- runtime LSP staging -------------------------------------------

(defun stage-runtime-lsp (session)
  "Copy the upstream autolisp-remote-io.lsp file (whose source path
SESSION's RUNTIME-LSP-SOURCE slot holds) into WORKDIR/runtime/ so
the CAD can LOAD it. Returns the staged absolute pathname, or NIL
when no source was provided (the caller is expected to wire one
up in Phase 3).

The staging is a verbatim file copy: the issue is emphatic that the
runtime is reused as-is, never patched."
  (let ((source (protocol-session-runtime-lsp-source session)))
    (when source
      (let* ((runtime-dir (ensure-subdir (protocol-session-workdir session)
                                         "runtime"))
             (target (merge-pathnames "autolisp-remote-io.lsp" runtime-dir)))
        (uiop:copy-file source target)
        (setf (protocol-session-runtime-lsp-staged session) target)
        target))))
