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
           #:*host-os-override*
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
           #:drive-protocol-actions
           ;; CAD program discovery + denotation (backend selection)
           #:cad-program
           #:cad-program-kind
           #:cad-program-version
           #:cad-program-locale
           #:cad-program-path
           #:cad-program-denotation
           #:discover-cad-programs
           #:print-cad-programs
           #:resolve-cad-denotation))

(in-package #:alfe.backend.cad-common)

;;; --- OS detection -------------------------------------------------

(defvar *host-os-override* nil
  "When non-NIL, forces HOST-OS to return this keyword (:macos / :linux /
:windows) instead of the compile-time detection. Its only purpose is to
let tests exercise a platform-specific launch path — e.g. the Windows
`/Automation' batch argv (alfe-bricscad-batch-hidden-ui) — from a host of
a different OS. NIL in production; never bound outside the test suite.")

(defun host-os ()
  "Return one of :macos :linux :windows :unknown. The detection only
looks at compile-time *features*; UIOP exposes a similar helper but
its name differs across versions, and we don't need uiop's full
matrix here. *HOST-OS-OVERRIDE*, when set, wins (tests only)."
  (or *host-os-override*
      (cond
        #+darwin                   ((or :macos))
        #+(and unix (not darwin))  ((or :linux))
        #+(or win32 windows mswindows)
                                   ((or :windows))
        (t                          :unknown))))

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

;;; --- G3b: transcode a codepage -l source to UTF-8+BOM for the CAD --------
;;;
;;; A CAD host cannot load a raw single-byte-codepage source portably: (load)
;;; has NO encoding argument -- it detects a UTF-8/UTF-16 BOM, else decodes with
;;; the READ-ONLY SYSCODEPAGE (macOS = MAC_ROMAN, Windows = its ANSI cp). So a
;;; cp1252 é (0xE9) native-loaded on macOS BricsCAD becomes È, and (chr 233) is
;;; no longer = the file char (cad-chr-vs-loaded-encoding). When -Esource names
;;; a codepage, alfe decodes the file with it and stages a UTF-8-WITH-BOM copy,
;;; which every platform's (load) detects (via the BOM) and decodes correctly.
;;; Unicode / unset encodings pass through unchanged. (A refinement, not needed
;;; for correctness: skip the copy when -Esource already equals the host
;;; SYSCODEPAGE -- the raw file would then load right too.)

(defun %source-encoding->babel (encoding)
  "Map a -Esource ENCODING designator to a BABEL encoding keyword, or NIL when it
is nil / :auto / a Unicode codec the CAD reads via its own BOM (no transcode
needed). babel gives the SAME codec set on SBCL and CCL, so every named codepage
is handled, not just the built-in cp1252 cascade."
  (let ((kw (ignore-errors (clautolisp.autolisp-cli:encoding-keyword encoding))))
    (case kw
      ((nil :auto :utf-8 :utf8 :utf-16 :utf-16le :utf-16be :utf16le :utf16be) nil)
      ;; babel spells the Windows codepages :cp125X, not :windows-125X.
      (:windows-1250 :cp1250) (:windows-1251 :cp1251) (:windows-1252 :cp1252)
      (:windows-1253 :cp1253) (:windows-1254 :cp1254) (:windows-1255 :cp1255)
      (:windows-1256 :cp1256) (:windows-1257 :cp1257) (:windows-1258 :cp1258)
      (t kw))))                          ; :iso-8859-*, :koi8-*, :cp125X, … pass through

(defun %read-file-octets (path)
  (with-open-file (in path :direction :input :element-type '(unsigned-byte 8))
    (let ((v (make-array (file-length in) :element-type '(unsigned-byte 8))))
      (read-sequence v in)
      v)))

(defun stage-source-as-utf8-bom (protocol-session path encoding)
  "If ENCODING is a non-Unicode codepage, decode PATH with babel and write a
UTF-8-with-BOM copy into the workdir, returning that copy's path for the CAD to
(load); otherwise return PATH unchanged."
  (let ((babel-enc (%source-encoding->babel encoding)))
    (if (null babel-enc)
      path
      (let* ((text (babel:octets-to-string (%read-file-octets path)
                                           :encoding babel-enc :errorp nil))
             (staged (merge-pathnames
                      (format nil "esrc-~A" (file-namestring (pathname path)))
                      (uiop:ensure-directory-pathname
                       (alfe.protocol.file:protocol-session-workdir
                        protocol-session)))))
        (with-open-file (out staged :direction :output :external-format :utf-8
                                    :if-exists :supersede :if-does-not-exist :create)
          (write-char (code-char #xFEFF) out)   ; UTF-8 BOM -> EF BB BF
          (write-string text out))
        (log-debug "cad-common: staged UTF-8+BOM ~A -> ~A (from ~A source)"
                   (file-namestring (pathname path))
                   (file-namestring staged) encoding)
        (namestring (truename staged))))))

(defun drive-protocol-actions (protocol-session plan
                               &key
                                 (request-timeout 30)
                                 (keep-alive-while-running t)
                                 (process-info nil)
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
tests can pass string streams to drive the REPL in-process.

REQUEST-TIMEOUT bounds how long each round-trip waits for its `DONE N'.
When KEEP-ALIVE-WHILE-RUNNING (the default) and PROCESS-INFO are given,
that budget only guards the READY->RUNNING handshake: once the runtime
publishes `RUNNING N' and the spawned process is alive, the wait is
extended so a legitimately long (eval ...) is not aborted on wall-clock
(alfe-request-timeout-aborts-long-eval). An explicit user `--timeout'
passes KEEP-ALIVE-WHILE-RUNNING NIL to restore a hard cap. PROCESS-INFO
(a UIOP process object) also lets a dead engine abort promptly."
  (let* ((status :success)
         (captured-stdout (make-string-output-stream))
         (captured-stderr (make-string-output-stream))
         ;; Liveness probe over the spawned CAD process, or NIL in tests /
         ;; when the caller has no handle. Consulted by wait-for-status-prefix
         ;; to distinguish "engine still computing" from "engine died".
         (alive-p (when process-info
                    (lambda () (uiop:process-alive-p process-info))))
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
                                 request-counter))
                 ;; RUNNING acknowledgement for this request. Supplied only
                 ;; when the caller opted into keep-alive; an explicit
                 ;; --timeout keeps this NIL so the wait is a hard cap.
                 (running-target
                   (when keep-alive-while-running
                     (format nil "~A ~D"
                             alfe.protocol.file:+status-running-prefix+
                             request-counter))))
             (multiple-value-bind (matched elapsed last)
                 (alfe.protocol.file:wait-for-status-prefix
                  protocol-session target
                  :timeout request-timeout
                  :running-prefix running-target
                  :alive-p alive-p)
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
           (let* ((payload (alfe.backend:action-payload action))
                  (path (getf payload :path))
                  (load-path (stage-source-as-utf8-bom
                              protocol-session path (getf payload :encoding))))
             (send-action (format nil "(load ~S)" load-path))))
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

;;; --- CAD program discovery + denotation (alfe-backend-selection) ---
;;;
;;; A user may have several CAD versions/locales installed and want to pick
;;; one explicitly. DISCOVER-CAD-PROGRAMS enumerates them ALL (unlike the
;;; per-backend DISCOVER-*-BINARY which return only the best one), each with a
;;; canonical DENOTATION (acad-2026, bricscad-v26, bricscad-v25-fr_FR,
;;; accoreconsole-2022, clautolisp) the CLI can select by. This is the model
;;; behind --list-cad-programs; the selection wiring builds on it.

(defstruct (cad-program (:constructor %make-cad-program) (:copier nil))
  (kind       nil)   ; :acad :accoreconsole :bricscad :clautolisp
  (version    nil)   ; "2026" / "V26" / an alfe version / NIL
  (locale     nil)   ; "fr_FR" (BricsCAD/Windows) or NIL
  (path       nil)   ; executable namestring, or "(embedded)" for clautolisp
  (denotation nil))  ; canonical selector, e.g. "acad-2026"

;; -- version / locale extraction from an install path -----------------

(defun %find-autocad-year (path)
  "The first bare 20NN run in PATH (a namestring), or NIL. Bare = not a
digit on either side, so \"AutoCAD 2026\" yields \"2026\"."
  (loop for i from 0 to (max -1 (- (length path) 4))
        when (and (char= (char path i) #\2) (char= (char path (1+ i)) #\0)
                  (digit-char-p (char path (+ i 2))) (digit-char-p (char path (+ i 3)))
                  (or (zerop i) (not (digit-char-p (char path (1- i)))))
                  (or (>= (+ i 4) (length path)) (not (digit-char-p (char path (+ i 4))))))
          return (subseq path i (+ i 4))))

(defun %find-bricscad-version (path)
  "The BricsCAD version token in PATH — \"V\" then digits (e.g. \"V26\"),
upper-cased; \"V26x64\" keeps only \"V26\". NIL when absent."
  (let ((u (string-upcase path)))
    (loop for i from 0 below (length u)
          when (and (char= (char u i) #\V)
                    (< (1+ i) (length u))
                    (digit-char-p (char u (1+ i)))
                    (or (zerop i) (not (alpha-char-p (char u (1- i))))))
            return (let ((j (1+ i)))
                     (loop while (and (< j (length u)) (digit-char-p (char u j))) do (incf j))
                     (concatenate 'string "V" (subseq u (1+ i) j))))))

(defun %find-locale (path)
  "A POSIX-ish locale token in PATH — ll_CC (two lower, '_', two upper, e.g.
\"fr_FR\") — or NIL."
  (loop for i from 0 to (max -1 (- (length path) 5))
        when (and (lower-case-p (char path i)) (lower-case-p (char path (1+ i)))
                  (char= (char path (+ i 2)) #\_)
                  (upper-case-p (char path (+ i 3))) (upper-case-p (char path (+ i 4)))
                  (or (zerop i) (not (alphanumericp (char path (1- i)))))
                  (or (>= (+ i 5) (length path)) (not (alphanumericp (char path (+ i 5))))))
          return (subseq path i (+ i 5))))

(defun %cad-denotation (kind version locale)
  "Build the canonical denotation string from KIND + VERSION + LOCALE."
  (let ((base (ecase kind
                (:acad          (format nil "acad~@[-~A~]" version))
                (:accoreconsole (format nil "accoreconsole~@[-~A~]" version))
                (:bricscad      (format nil "bricscad~@[-~(~A~)~]" version))
                (:clautolisp    "clautolisp"))))
    (if (and (eq kind :bricscad) locale)
        (format nil "~A-~A" base locale)
        base)))

(defun %cad-program-from-path (kind path)
  "Parse a discovered executable PATH into a CAD-PROGRAM of KIND."
  (let* ((ns (namestring path))
         (version (case kind
                    ((:acad :accoreconsole) (%find-autocad-year ns))
                    (:bricscad              (%find-bricscad-version ns))))
         (locale (when (eq kind :bricscad) (%find-locale ns))))
    (%make-cad-program :kind kind :version version :locale locale :path ns
                       :denotation (%cad-denotation kind version locale))))

;; -- per-kind, per-OS enumeration -------------------------------------

(defun %glob (pattern) (mapcar #'namestring (directory pattern)))

(defun discover-acad-programs ()
  (cond
    ((windows-p)
     (append (windows-glob-existing-files '("Autodesk/AutoCAD */acad.exe"))
             (%glob "/c/Program Files/Autodesk/AutoCAD */acad.exe")))
    ((macos-p)
     (%glob "/Applications/Autodesk/AutoCAD */AutoCAD *.app/Contents/MacOS/AutoCAD"))))

(defun discover-accoreconsole-programs ()
  (cond
    ((windows-p)
     (append (windows-glob-existing-files '("Autodesk/*/accoreconsole.exe"))
             (%glob "/c/Program Files/Autodesk/*/accoreconsole.exe")))
    ((macos-p)
     (%glob "/Applications/Autodesk/AutoCAD */AutoCAD *.app/Contents/Helpers/AcCoreConsole.app/Contents/MacOS/AcCoreConsole"))))

(defun discover-bricscad-paths ()
  (cond
    ((windows-p)
     (append (windows-glob-existing-files '("Bricsys/*/bricscad.exe"))
             (%glob "/c/Program Files*/Bricsys/*/bricscad.exe")))
    ((macos-p) (%glob "/Applications/BricsCAD*.app/Contents/MacOS/bricscad"))
    ((linux-p) (%glob "/opt/bricsys/bricscad/V*/bricscad"))))

(defun %dedup-programs (programs)
  "Drop programs whose PATH we have already seen (the Windows globs overlap)."
  (let ((seen (make-hash-table :test #'equal)) (out '()))
    (dolist (p programs (nreverse out))
      (unless (gethash (cad-program-path p) seen)
        (setf (gethash (cad-program-path p) seen) t)
        (push p out)))))

(defun clautolisp-program ()
  "clautolisp is embedded in alfe (not forked), so it is always available."
  (%make-cad-program :kind :clautolisp :path "(embedded in alfe)"
                     :denotation "clautolisp"))

(defun discover-cad-programs ()
  "All CAD programs installed on this host, each as a CAD-PROGRAM with a
canonical denotation. clautolisp is always present (embedded)."
  (%dedup-programs
   (append (mapcar (lambda (p) (%cad-program-from-path :acad p))
                   (discover-acad-programs))
           (mapcar (lambda (p) (%cad-program-from-path :accoreconsole p))
                   (discover-accoreconsole-programs))
           (mapcar (lambda (p) (%cad-program-from-path :bricscad p))
                   (discover-bricscad-paths))
           (list (clautolisp-program)))))

(defun print-cad-programs (&optional (stream *standard-output*))
  "The --list-cad-programs output: DENOTATION then PATH, one per line."
  (let ((programs (discover-cad-programs)))
    (if programs
        (dolist (p programs)
          (format stream "~24A ~A~%" (cad-program-denotation p) (cad-program-path p)))
        (format stream "no CAD programs found (clautolisp is always available)~%"))
    (values)))

;;; --- denotation resolution (backend selection, increment 2) --------

(defun %prefix-p (prefix string)
  (and (<= (length prefix) (length string))
       (string= prefix string :end2 (length prefix))))

(defun %denotation-matches-p (query pd)
  "QUERY matches program-denotation PD when it is PD exactly, or a
segment-boundary prefix of it (so \"bricscad\" matches \"bricscad-v26\" and
\"bricscad-v25\" matches \"bricscad-v25-fr_FR\")."
  (or (string= query pd)
      (%prefix-p (concatenate 'string query "-") pd)))

(defun %cad-version-key (program)
  "A sortable integer for 'latest' selection: the AutoCAD year, or the
BricsCAD V-number; 0 when there is no version."
  (let ((v (cad-program-version program)))
    (cond
      ((null v) 0)
      ((and (plusp (length v)) (char-equal (char v 0) #\V))
       (or (parse-integer v :start 1 :junk-allowed t) 0))
      (t (or (parse-integer v :junk-allowed t) 0)))))

;; -- host locale preference (disambiguates same-version installs) -----

(defun %locale-from-lc-value (value)
  "The ll_CC core of a POSIX locale string, or NIL. \"fr_FR.UTF-8\" → \"fr_FR\";
\"C\" / \"POSIX\" / \"en\" → NIL."
  (when (and value (plusp (length value)))
    (let* ((end (or (position #\. value) (position #\@ value) (length value)))
           (base (subseq value 0 end)))
      (when (and (= (length base) 5) (char= (char base 2) #\_)) base))))

(defun %macos-apple-languages ()
  "The macOS AppleLanguages preference as ll_CC codes (\"en-FR\" → \"en_FR\"),
most-preferred first; NIL off macOS or on any failure (best-effort)."
  (when (macos-p)
    (let ((out (ignore-errors
                 (uiop:run-program '("defaults" "read" "-g" "AppleLanguages")
                                   :output :string :ignore-error-status t))))
      (when out
        (let ((result '()) (start 0))
          (loop
            (let ((open (position #\" out :start start)))
              (unless open (return))
              (let ((close (position #\" out :start (1+ open))))
                (unless close (return))
                (let ((tok (substitute #\_ #\- (subseq out (1+ open) close))))
                  (when (and (= (length tok) 5) (char= (char tok 2) #\_))
                    (push tok result)))
                (setf start (1+ close)))))
          (nreverse result))))))

(defun %host-preferred-locales ()
  "Ordered, de-duplicated ll_CC locales the host prefers — macOS
AppleLanguages first, then LC_ALL / LC_CTYPE / LANG — used to pick among
same-version BricsCAD installs of different localisations."
  (let ((acc '()))
    (dolist (loc (append (%macos-apple-languages)
                         (remove nil (mapcar (lambda (v) (%locale-from-lc-value (uiop:getenv v)))
                                             '("LC_ALL" "LC_CTYPE" "LANG")))))
      (pushnew loc acc :test #'string-equal))
    (nreverse acc)))

(defun %locale-rank (program preferred-locales)
  "PROGRAM's position in PREFERRED-LOCALES (earlier = better), or a large
number when it has no locale or none is preferred — so locale-less programs
keep their discovery order."
  (let ((loc (cad-program-locale program)))
    (or (and loc (position loc preferred-locales :test #'string-equal))
        most-positive-fixnum)))

(defun resolve-cad-denotation (denotation programs &key (mode :auto)
                                                        (preferred-locales
                                                         (%host-preferred-locales)))
  "Resolve DENOTATION (a string) against PROGRAMS to a single CAD-PROGRAM, or
NIL when nothing matches. Exact and segment-prefix matches are accepted; among
matches the LATEST version wins, and ties are broken by PREFERRED-LOCALES (the
host's locale preference) so several localised BricsCAD installs of the same
version pick the right one. The virtual =autocad[-VER]= maps to =acad= or
=accoreconsole= per MODE (=:batch= → accoreconsole, else acad), so
=--cad autocad-2022 --mode batch= selects accoreconsole-2022."
  (let* ((q0 (string-downcase (string-trim '(#\Space #\Tab) denotation)))
         (q (if (or (string= q0 "autocad") (%prefix-p "autocad-" q0))
                (concatenate 'string
                             (if (eq mode :batch) "accoreconsole" "acad")
                             (subseq q0 (length "autocad")))
                q0))
         (matches (remove-if-not
                   (lambda (p)
                     (%denotation-matches-p q (string-downcase (cad-program-denotation p))))
                   programs)))
    (when matches
      (let* ((top-version (reduce #'max matches :key #'%cad-version-key :initial-value -1))
             (top (remove-if-not (lambda (p) (= (%cad-version-key p) top-version)) matches)))
        (first (stable-sort (copy-list top) #'<
                            :key (lambda (p) (%locale-rank p preferred-locales))))))))
