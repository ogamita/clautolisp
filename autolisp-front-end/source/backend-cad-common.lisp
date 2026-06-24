;;;; autolisp-front-end/source/backend-cad-common.lisp
;;;;
;;;; Shared helpers used by both CAD backends (BricsCAD + AutoCAD).
;;;; Specified implicitly by alfe-backend-bricscad.issue and
;;;; alfe-backend-autocad.issue — both tickets share the same
;;;; protocol-driven shape, so the common bits live here to keep
;;;; the per-backend files focused on platform specifics.

(defpackage #:alfe.backend.cad-common
  (:use #:cl)
  (:import-from #:alfe.error
                #:backend-not-available
                #:backend-bootstrap-error
                #:backend-protocol-error
                #:backend-eval-error)
  (:import-from #:alfe.backend
                #:make-eval-result)
  (:import-from #:alfe.logging
                #:log-debug
                #:log-verbose)
  (:export ;; OS detection
           #:host-os
           #:macos-p
           #:linux-p
           #:windows-p
           ;; binary discovery
           #:env-binary
           #:first-existing
           #:windows-program-files-roots
           #:windows-glob-existing-files
           #:vbs-escape
           #:applescript-escape
           ;; runtime LSP discovery
           #:discover-runtime-lsp
           #:discover-bootstrap-lsp
           ;; protocol-driven eval-plan
           #:drive-protocol-actions))

(in-package #:alfe.backend.cad-common)

;;; --- OS detection -------------------------------------------------

(defun host-os ()
  "Return one of :macos :linux :windows :unknown. The detection only
looks at compile-time *features*; UIOP exposes a similar helper but
its name differs across versions, and we don't need uiop's full
matrix here."
  (cond
    #+darwin                   ((or :macos))
    #+(and unix (not darwin))  ((or :linux))
    #+(or win32 windows mswindows)
                               ((or :windows))
    (t                          :unknown)))

(defun macos-p ()   (eq (host-os) :macos))
(defun linux-p ()   (eq (host-os) :linux))
(defun windows-p () (eq (host-os) :windows))

;;; --- binary discovery helpers ------------------------------------

(defun env-binary (name)
  "Return the env-var value as a string if it's set, exists on disk,
and is executable. Returns NIL otherwise. Used by every backend's
DETECT for its primary `$<BACKEND>_EXE` override."
  (let ((value (uiop:getenv name)))
    (when (and value
               (plusp (length value))
               (probe-file value))
      value)))

(defun first-existing (candidates)
  "Return the first candidate path that exists on disk, or NIL when
none do. CANDIDATES may contain NIL entries (the caller often
splices optional env-var values); those are skipped silently."
  (dolist (candidate candidates)
    (when (and candidate
               (probe-file candidate))
      (return-from first-existing (namestring (truename candidate)))))
  nil)

(defparameter *windows-program-files-env-vars*
  '("ProgramW6432" "ProgramFiles" "ProgramFiles(x86)")
  "Environment variables that typically point at Windows program-
installation roots. The order prefers the native 64-bit tree, then
the generic tree, then the 32-bit compatibility tree.")

(defun windows-program-files-roots ()
  "Return the distinct existing Program Files roots advertised by the
current environment. The result is a list of directory pathnames in
search order, suitable for MERGE-PATHNAMES-based globbing on native
Windows Lisp images."
  (let ((seen (make-hash-table :test #'equal))
        (roots '()))
    (dolist (name *windows-program-files-env-vars* (nreverse roots))
      (let ((value (uiop:getenv name)))
        (when (and value (plusp (length value)))
          (let* ((root (ignore-errors
                         (uiop:ensure-directory-pathname
                          (uiop:parse-native-namestring value))))
                 (namestring (and root (probe-file root)
                                  (namestring (truename root)))))
            (when (and namestring
                       (not (gethash namestring seen)))
              (setf (gethash namestring seen) t)
              (push (uiop:ensure-directory-pathname namestring) roots))))))))

(defun windows-glob-existing-files (relative-globs &key
                                                    (roots
                                                      (windows-program-files-roots)))
  "Expand each RELATIVE-GLOBS pattern under every directory in ROOTS
and return the existing matches as absolute namestrings. RELATIVE-GLOBS
uses forward-slash separators and may contain `*' wildcards in any
path segment, which keeps the callers readable on both native Windows
and MSYS/MinGW-hosted Lisp images."
  (loop for root in roots
        append (loop for relative-glob in relative-globs
                     append (mapcar #'namestring
                                    (directory
                                     (merge-pathnames relative-glob root))))))

;;; --- string escapers for emitted bridge scripts ------------------

(defun vbs-escape (string)
  "Escape STRING for inclusion in a VBScript double-quoted literal.
Per the spec's escape_vbs_string helper: double internal quotes,
leave backslashes alone (Windows paths embed them verbatim)."
  (with-output-to-string (out)
    (loop for ch across string
          do (case ch
               (#\" (write-string "\"\"" out))
               (t   (write-char ch out))))))

(defun applescript-escape (string)
  "Escape STRING for inclusion in an AppleScript double-quoted
literal. AppleScript uses backslash escapes — backslash and double
quote both have to be escaped."
  (with-output-to-string (out)
    (loop for ch across string
          do (case ch
               (#\\ (write-string "\\\\" out))
               (#\" (write-string "\\\"" out))
               (t   (write-char ch out))))))

;;; --- runtime LSP discovery ---------------------------------------
;;;
;;; The CAD-side bootstrap involves two .lsp files, loaded in order:
;;;
;;;   1. autolisp-bootstrap.lsp  — the ~67 autolisp-* helper defuns
;;;                                 (autolisp-eval-request-form,
;;;                                  autolisp-log-err, autolisp-set-
;;;                                  status, …) ported verbatim from
;;;                                 the legacy bash wrapper.
;;;   2. autolisp-remote-io.lsp  — the file-IPC server loop, which
;;;                                 calls into the helpers from (1).
;;;
;;; Both files are shared by every CAD backend, both ship vendored
;;; under source/runtime/, and users can override their location via
;;; $ALFE_BOOTSTRAP_LSP / $ALFE_RUNTIME_LSP for advanced setups (e.g.
;;; a system-wide /opt/local/share/alfe/runtime/ install).

(defun %vendored-asset-pathname (basename)
  "Resolve a vendored runtime asset by BASENAME (e.g.
\"autolisp-remote-io.lsp\", \"autolisp-bootstrap.lsp\") under
source/runtime/ next to this code. Returns NIL if the asset isn't on
disk. ASDF's system registry is the source of truth so the answer
survives fasl caching and frozen executable builds — *load-pathname*
alone would point at the cached .fasl, not the source tree."
  (let ((candidate
          (ignore-errors
           (asdf:system-relative-pathname
            "autolisp-front-end/backend-cad-common"
            (concatenate 'string "source/runtime/" basename)))))
    (when (and candidate (probe-file candidate))
      (namestring (truename candidate)))))

(defparameter *runtime-lsp-fallback-paths*
  '("/opt/local/share/alfe/runtime/autolisp-remote-io.lsp"
    "/usr/local/share/alfe/runtime/autolisp-remote-io.lsp"
    "/usr/share/alfe/runtime/autolisp-remote-io.lsp"
    "~/works/sncf-reseau/src/outils-autolisp/autolisp-script/runtime/autolisp-remote-io.lsp")
  "Fallback locations consulted when $ALFE_RUNTIME_LSP is unset and
the vendored copy is missing. The last entry points at the legacy
SNCF tree so developers with that checkout keep working without
configuration.")

(defparameter *bootstrap-lsp-fallback-paths*
  '("/opt/local/share/alfe/runtime/autolisp-bootstrap.lsp"
    "/usr/local/share/alfe/runtime/autolisp-bootstrap.lsp"
    "/usr/share/alfe/runtime/autolisp-bootstrap.lsp")
  "Fallback locations for autolisp-bootstrap.lsp when $ALFE_BOOTSTRAP_LSP
is unset and the vendored copy is missing. The legacy SNCF tree does
NOT ship this file standalone — the bash wrapper inlines its content
into the generated run-common.lsp at run time — so there is no
SNCF-tree fallback here (only the vendored copy + install prefixes).")

(defun %resolve-asset (env-name vendored-fn fallback-paths)
  "Return the first asset path found by: env var ENV-NAME, the
vendored copy via VENDORED-FN, then the FALLBACK-PATHS list. Each
candidate is PROBE-FILE-checked; the empty-string env value is
treated as unset. Returns NIL when no candidate exists."
  (let ((env (uiop:getenv env-name))
        (vendored (funcall vendored-fn)))
    (cond
      ((and env (plusp (length env)) (probe-file env))
       (namestring (truename env)))
      (vendored vendored)
      (t
       (first-existing
        (mapcar (lambda (p) (uiop:native-namestring p))
                fallback-paths))))))

(defun discover-runtime-lsp ()
  "Resolve the CAD-side runtime LSP path. Order of precedence:

  1. $ALFE_RUNTIME_LSP (when the file exists)
  2. The vendored copy under source/runtime/ next to this code
  3. Built-in fallback search list (/opt/local/share/alfe/runtime/, …)

Returns an absolute namestring, or NIL when no copy is found — in
which case the caller leaves the runtime unstaged and run-common.lsp
will not LOAD it (the historical broken behavior)."
  (%resolve-asset "ALFE_RUNTIME_LSP"
                  (lambda () (%vendored-asset-pathname
                              "autolisp-remote-io.lsp"))
                  *runtime-lsp-fallback-paths*))

(defun discover-bootstrap-lsp ()
  "Resolve the CAD-side bootstrap LSP path (autolisp-bootstrap.lsp),
which defines the autolisp-* helpers that the runtime's server loop
calls. Order of precedence matches DISCOVER-RUNTIME-LSP:

  1. $ALFE_BOOTSTRAP_LSP (when the file exists)
  2. The vendored copy under source/runtime/ next to this code
  3. Built-in fallback search list (/opt/local/share/alfe/runtime/, …)

Returns an absolute namestring, or NIL when no copy is found. When NIL
the caller leaves the bootstrap unstaged and the runtime's server loop
will fail at the first eval (autolisp-eval-request-form undefined) —
the deferred-autolisp-runtime-helpers symptom this asset closes."
  (%resolve-asset "ALFE_BOOTSTRAP_LSP"
                  (lambda () (%vendored-asset-pathname
                              "autolisp-bootstrap.lsp"))
                  *bootstrap-lsp-fallback-paths*))

;;; --- protocol-driven eval-plan ------------------------------------

(defparameter *interactive-prompt-primary*    "alfe> "
  "Prompt issued before reading a fresh top-level form in the
CAD-backed interactive REPL.")

(defparameter *interactive-prompt-continuation* "    > "
  "Continuation prompt issued when the form on the wire is not yet
balanced and the user must keep typing.")

(defparameter *interactive-quit-tokens*
  '(":quit" ":q" ":exit" "(quit)" "(exit)")
  "Lines (after trimming) that terminate the CAD-backed interactive
REPL on the alfe side without bothering to send another request.
Anything else is forwarded to the runtime verbatim. Note that the
runtime *itself* still honours (quit)/(exit) — sending those forms
through stdin.txt drives the same code path as :quit control; this
list is just a UX convenience so users can type the familiar tokens
and have the loop terminate cleanly without waiting for the runtime
round-trip.")

(defun drive-protocol-actions (protocol-session plan
                               &key
                                 (request-timeout 30)
                                 (shutdown-timeout 10)
                                 (input-stream  *standard-input*)
                                 (output-stream *standard-output*)
                                 (error-stream  *error-output*))
  "Drive a PLAN of actions through a connected PROTOCOL-SESSION,
waiting for each transition to land. The CAD-side runtime is
expected to walk READY N → RUNNING N → DONE N {OK,FAIL,QUIT} per
the spec's main loop.

Returns an EVAL-RESULT with:
  - status: :success when every action saw `DONE N OK`,
            :failed on any `DONE N FAIL`,
            :aborted on a timeout.
  - output / error-output: the drained stdout.txt / stderr.txt
    captures (the full per-plan transcript — alfe writes them live
    to OUTPUT-STREAM / ERROR-STREAM as each action completes, and
    keeps a copy for the EVAL-RESULT).

Each round-trip waits for a *counter-specific* `DONE N` — generic
`DONE` would match the previous action's stale status the very tick
after send-stdin returns, dropping the new eval's output and any
error message before they could be drained. The counter is seeded
from the runtime's `READY N` (whatever the CAD published when it
became ready) and incremented locally on each send.

INPUT-STREAM/OUTPUT-STREAM/ERROR-STREAM are wired through to the
:interactive REPL loop; the CLI passes the live terminal streams,
tests can pass string streams to drive the REPL in-process."
  (let* ((status :success)
         (captured-stdout (make-string-output-stream))
         (captured-stderr (make-string-output-stream))
         ;; The runtime publishes "READY N" at startup and then walks
         ;; N+1 on each request. We initialise from the currently-
         ;; observed status (typically "READY 0") so the first
         ;; send-action waits for "DONE 1".
         (request-counter (or (parse-trailing-positive-integer
                               (alfe.protocol.file:read-current-status
                                protocol-session))
                              0)))
    (labels
        ((apply-alfe-control (key value)
           "Apply one parsed `[ALFE-CONTROL] KEY=VALUE' sentinel."
           (cond
             ((string-equal key "DEBUG")
              (let ((on (or (string= value "1")
                            (string-equal value "T"))))
                (alfe.logging:set-level (if on :debug :info))))
             ((string-equal key "VERBOSE")
              (let ((on (or (string= value "1")
                            (string-equal value "T"))))
                ;; Don't downgrade from :debug -- VERBOSE=0 means
                ;; "stop verbose chatter", but if debug is also on
                ;; we want to stay at :debug.
                (cond
                  (on
                   (unless (eq alfe.logging:*current-level* :debug)
                     (alfe.logging:set-level :verbose)))
                  (t
                   (when (eq alfe.logging:*current-level* :verbose)
                     (alfe.logging:set-level :info))))))
             (t
              ;; Unknown control key. Log under :debug so the user can
              ;; diagnose typos, but don't fail the drain.
              (alfe.logging:log-debug
               "cad-common: unknown ALFE-CONTROL key ~S (value ~S)"
               key value))))
         (filter-alfe-control-lines (raw)
           "Walk RAW, identify any `[ALFE-CONTROL] KEY=VALUE' lines,
apply them as side effects, and return the chunk with those lines
stripped out. Non-sentinel lines pass through verbatim so the
terminal sees only what the user printed.

The sentinel format is one line per command:
  `[ALFE-CONTROL] KEY=VALUE'
Trailing newlines are preserved on non-sentinel lines so the caller
can write the result straight to OUTPUT-STREAM."
           (let ((accum (make-string-output-stream))
                 (start 0)
                 (sentinel "[ALFE-CONTROL] ")
                 (len (length raw)))
             (loop
               (let ((eol (position #\Newline raw :start start)))
                 (let* ((line-end (or eol len))
                        (line (subseq raw start line-end))
                        (trimmed (string-left-trim '(#\Space #\Tab) line)))
                   (cond
                     ((and (>= (length trimmed) (length sentinel))
                           (string= sentinel trimmed
                                    :end2 (length sentinel)))
                      ;; Sentinel hit -- parse + apply, don't echo.
                      (let* ((rest (subseq trimmed (length sentinel)))
                             (eq-pos (position #\= rest)))
                        (when eq-pos
                          (apply-alfe-control
                           (string-trim '(#\Space #\Tab)
                                        (subseq rest 0 eq-pos))
                           (string-trim '(#\Space #\Tab #\Return)
                                        (subseq rest (1+ eq-pos)))))))
                     (t
                      ;; Non-sentinel: copy through, preserving the
                      ;; newline if there was one.
                      (write-string line accum)
                      (when eol
                        (write-char #\Newline accum))))
                   (if eol
                       (setf start (1+ eol))
                       (return)))))
             (get-output-stream-string accum)))
         (drain-live ()
           "Drain stdout.txt + stderr.txt, append to the capture
streams, and echo to the live OUTPUT-STREAM / ERROR-STREAM so the
user sees CAD output AS each action completes (not deferred to
end-of-plan).

`[ALFE-CONTROL] KEY=VALUE' lines in stdout are intercepted here
(see filter-alfe-control-lines): they apply control side effects
inline -- chiefly toggling alfe.logging:*current-level* -- and are
stripped before the chunk reaches the terminal. Stderr is passed
through verbatim."
           (let ((out (alfe.protocol.file:drain-stdout protocol-session))
                 (err (alfe.protocol.file:drain-stderr protocol-session)))
             (when (plusp (length out))
               (let ((visible (filter-alfe-control-lines out)))
                 ;; Capture the full text (including sentinels) for
                 ;; the eval-result -- tests + diagnostics may want
                 ;; the unfiltered trace. The live stream only sees
                 ;; the filtered text.
                 (write-string out captured-stdout)
                 (when (plusp (length visible))
                   (write-string visible output-stream)
                   (finish-output output-stream))))
             (when (plusp (length err))
               (write-string err captured-stderr)
               (write-string err error-stream)
               (finish-output error-stream))))
         (sync-verbosity-from-runtime ()
           "Re-read protocol/runtime-flags.txt and, if the CAD-side
runtime has toggled *AUTOLISP-DEBUG* / *AUTOLISP-VERBOSE*, mirror
the change into alfe.logging's *current-level* so the alfe-side
trace lines respect the runtime-side switch regardless of what the
--debug / --verbose CLI flag was at startup.

The mapping is `most-specific-wins': DEBUG=1 -> :DEBUG;
VERBOSE=1 -> :VERBOSE; both NIL -> :INFO. We never drop below
:INFO from here -- the CLI's --quiet (which sets :WARN) still
wins because runtime-flags only carries DEBUG/VERBOSE."
           (let ((flags (alfe.protocol.file:read-runtime-flags
                         protocol-session)))
             (when flags
               (let ((desired
                       (cond
                         ((getf flags :debug)   :debug)
                         ((getf flags :verbose) :verbose)
                         (t                     :info))))
                 (unless (eq desired alfe.logging:*current-level*)
                   ;; Only ever transition between debug/verbose/info
                   ;; based on the runtime flags; if the CLI elected
                   ;; :warn (--quiet alone) we leave that alone, the
                   ;; user opted out of debug/verbose chatter at the
                   ;; process level.
                   (unless (eq alfe.logging:*current-level* :warn)
                     (alfe.logging:set-level desired)))))))
         (wait-done ()
           "Wait for the runtime to publish `DONE <request-counter>'.
Sets STATUS based on the OK / FAIL / QUIT suffix. Drains stdout +
stderr right after the match so output reaches alfe before the
next round-trip starts. After draining we also mirror the current
runtime-side verbosity flags into alfe.logging so toggles a REPL
user makes via (setq *autolisp-debug* …) take effect on the next
trace line."
           (incf request-counter)
           (let ((target (format nil "~A ~D"
                                 alfe.protocol.file:+status-done-prefix+
                                 request-counter)))
             (multiple-value-bind (matched elapsed last)
                 (alfe.protocol.file:wait-for-status-prefix
                  protocol-session target
                  :timeout request-timeout)
               (declare (ignore elapsed))
               (drain-live)
               (sync-verbosity-from-runtime)
               (cond
                 ((not matched)
                  (setf status :aborted)
                  nil)
                 ((search " FAIL" last) (setf status :failed))
                 ((search " QUIT" last) nil)
                 (t nil)))))
         (send-action (form-text)
           "Atomically publish FORM-TEXT into stdin.txt, then wait
for the runtime to acknowledge `DONE <next-counter>'."
           (alfe.protocol.file:send-stdin protocol-session form-text)
           (wait-done))
         (interactive-loop ()
           "Read balanced forms from INPUT-STREAM, forward each to
the runtime via send-action, drain output, repeat until EOF or the
user types a quit token. Survives runtime errors: a `DONE N FAIL'
shows the error on stderr and the prompt comes back."
           (loop
             (drain-live)
             (write-string *interactive-prompt-primary* output-stream)
             (finish-output output-stream)
             (multiple-value-bind (text eof-p)
                 (alfe.protocol.file:read-balanced-form-from-lines
                  (lambda () (read-line input-stream nil nil))
                  :source-name "<alfe-repl>")
               (cond
                 (eof-p
                  (terpri output-stream)
                  (return))
                 ((or (null text) (zerop (length text)))
                  ;; Blank input — just re-prompt.
                  nil)
                 ((member (string-trim '(#\Space #\Tab #\Newline #\Return)
                                       text)
                          *interactive-quit-tokens* :test #'string-equal)
                  (return))
                 (t
                  ;; In a REPL we want to *see* the value the user just
                  ;; typed -- (+ 1 2) should echo 3 on the next line.
                  ;; The protocol only relays printer output (see the
                  ;; alfe spec's "Action output semantics" section),
                  ;; so wrap each form with (print …) on its way to the
                  ;; runtime. The bootstrap's `print' shadow routes the
                  ;; emitted text through *AUTOLISP_PROTOCOL_STDOUTFILE*,
                  ;; which the next drain-live picks up and writes to
                  ;; OUTPUT-STREAM. -x and -l, which are batch and do
                  ;; NOT auto-print, are unaffected -- they take the
                  ;; :load / :eval branches above and bypass this wrap.
                  (send-action (format nil "(print ~A)" text))
                  ;; A FAILED action in the REPL is recoverable: the
                  ;; runtime stays in the read loop, we surfaced the
                  ;; stderr via drain-live, just reset our local
                  ;; status so the next form gets a clean wait-done.
                  (when (eq status :failed)
                    (setf status :success))))))))
      (log-verbose "cad-common: driving ~D action~:P (request-timeout ~A s)"
                   (length plan) request-timeout)
      (log-debug "cad-common: starting from request-counter ~D"
                 request-counter)
      (dolist (action plan)
        (unless (eq status :success) (return))
        (log-debug "cad-common: action ~A payload ~S"
                   (alfe.backend:action-kind action)
                   (alfe.backend:action-payload action))
        (case (alfe.backend:action-kind action)
          (:load
           (let ((path (getf (alfe.backend:action-payload action) :path)))
             (send-action (format nil "(load ~S)" path))))
          (:eval
           (send-action (alfe.backend:action-payload action)))
          (:main
           (send-action (format nil "(~A)" (alfe.backend:action-payload action))))
          (:interactive
           ;; The CAD-side runtime is already a read-eval loop on
           ;; stdin.txt; alfe just forwards the terminal. We surface
           ;; a one-line banner so the user knows they've crossed
           ;; into the live REPL, then turn the file-IPC loop into
           ;; an interactive one. Exiting the loop falls through to
           ;; the next action in the plan (typically :quit).
           (format output-stream
                   "alfe REPL on CAD backend. Type ~A or end-of-file (Ctrl-D) to exit.~%"
                   (car *interactive-quit-tokens*))
           (finish-output output-stream)
           (interactive-loop))
          (:quit
           (alfe.protocol.file:send-control protocol-session :shutdown)
           (multiple-value-bind (matched elapsed last)
               (alfe.protocol.file:wait-for-status
                protocol-session
                alfe.protocol.file:+status-stopped+
                :timeout shutdown-timeout)
             (declare (ignore elapsed last))
             (drain-live)
             (unless matched
               (setf status :aborted)))))))
    ;; Final drain — catches anything published between the last
    ;; wait-done's drain-live and now (e.g. a buffered newline).
    (let ((out (alfe.protocol.file:drain-stdout protocol-session))
          (err (alfe.protocol.file:drain-stderr protocol-session)))
      (when (plusp (length out))
        (write-string out captured-stdout)
        (write-string out output-stream))
      (when (plusp (length err))
        (write-string err captured-stderr)
        (write-string err error-stream)))
    (finish-output output-stream)
    (finish-output error-stream)
    (make-eval-result
     :status status
     :value nil       ; CAD backends don't surface a typed value
     :output (get-output-stream-string captured-stdout)
     :error-output (get-output-stream-string captured-stderr))))

(defun parse-trailing-positive-integer (string)
  "If STRING looks like `<word> <integer> ...' (e.g. \"READY 0\",
\"DONE 7 OK\"), return the integer. NIL when STRING is NIL or has no
integer in the second token slot. Used to seed the request-counter
in drive-protocol-actions from whatever READY N the runtime has
already published when we begin driving."
  (when (and string (plusp (length string)))
    (let* ((parts (uiop:split-string string :separator '(#\Space #\Tab))))
      (when (>= (length parts) 2)
        (ignore-errors (parse-integer (second parts)))))))
