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

(defun drive-protocol-actions (protocol-session plan
                               &key
                                 (request-timeout 30)
                                 (shutdown-timeout 10))
  "Drive a PLAN of actions through a connected PROTOCOL-SESSION,
waiting for each transition to land. The CAD-side runtime is
expected to walk READY N → RUNNING N → DONE N {OK,FAIL,QUIT} per
the spec's main loop.

Returns an EVAL-RESULT with:
  - status: :success when every action saw `DONE N OK`,
            :failed on any `DONE N FAIL`,
            :aborted on a timeout.
  - output / error-output: the drained stdout.txt / stderr.txt
    captures (incremental — only the bytes published while the plan
    ran).

The CAD's REPL prints its values via the shadowed print/princ/prin1
helpers that route into stdout.txt; alfe's CLI re-emits the captured
text live in run-plan."
  (let ((status :success)
        (captured-stdout (make-string-output-stream))
        (captured-stderr (make-string-output-stream)))
    (labels
        ((wait-done ()
           "Wait for the next DONE N status; sets STATUS based on
the OK/FAIL/QUIT suffix."
           (multiple-value-bind (matched elapsed last)
               (alfe.protocol.file:wait-for-status-prefix
                protocol-session
                alfe.protocol.file:+status-done-prefix+
                :timeout request-timeout)
             (declare (ignore elapsed))
             (cond
               ((not matched)
                (setf status :aborted)
                nil)
               ((search " FAIL" last) (setf status :failed))
               ((search " QUIT" last) nil)
               (t nil))))
         (send-action (form-text)
           "Atomically publish FORM-TEXT into stdin.txt and wait for
the runtime to acknowledge DONE."
           (alfe.protocol.file:send-stdin protocol-session form-text)
           (wait-done)))
      (log-verbose "cad-common: driving ~D action~:P (request-timeout ~A s)"
                   (length plan) request-timeout)
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
           ;; The CAD-side runtime already presents an interactive
           ;; REPL by reading lines from stdin.txt; alfe just needs
           ;; to forward terminal input. For Phase 3 we surface a
           ;; clear "interactive mode requires terminal forwarding"
           ;; message and stop — the legacy bash wrapper has a
           ;; line-pump that Phase 3.1 can port later.
           (error 'backend-eval-error
                  :backend :cad
                  :code :interactive-not-implemented
                  :message "Interactive mode against a CAD backend is not implemented in V1; use --clautolisp -i for an interactive REPL."))
          (:quit
           (alfe.protocol.file:send-control protocol-session :shutdown)
           (multiple-value-bind (matched elapsed last)
               (alfe.protocol.file:wait-for-status
                protocol-session
                alfe.protocol.file:+status-stopped+
                :timeout shutdown-timeout)
             (declare (ignore elapsed last))
             (unless matched
               (setf status :aborted)))))))
    ;; Drain whatever the runtime published during the run.
    (write-string
     (alfe.protocol.file:drain-stdout protocol-session) captured-stdout)
    (write-string
     (alfe.protocol.file:drain-stderr protocol-session) captured-stderr)
    (let ((stdout-text (get-output-stream-string captured-stdout))
          (stderr-text (get-output-stream-string captured-stderr)))
      ;; Echo live to the CLI streams so the user sees what the CAD
      ;; printed. Mirrors the contract the in-process clautolisp
      ;; backend follows.
      (when (plusp (length stdout-text))
        (write-string stdout-text *standard-output*))
      (when (plusp (length stderr-text))
        (write-string stderr-text *error-output*))
      (make-eval-result
       :status status
       :value nil       ; CAD backends don't surface a typed value
       :output stdout-text
       :error-output stderr-text))))
