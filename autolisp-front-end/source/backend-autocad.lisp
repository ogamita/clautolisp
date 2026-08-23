;;;; autolisp-front-end/source/backend-autocad.lisp
;;;;
;;;; The AutoCAD backend — Phase 3 of the alfe rollout. Specified
;;;; by ../issues/open/alfe-backend-autocad.issue and the spec's
;;;; "Backend autocad" section.
;;;;
;;;; AutoCAD is Windows-only; on macOS / Linux this backend's DETECT
;;;; signals a structured BACKEND-NOT-AVAILABLE with code
;;;; :unsupported-os so the CLI maps that to exit code 3 and a clean
;;;; "AutoCAD is not distributed for this OS" message.
;;;;
;;;; On Windows, two execution paths:
;;;;
;;;;   Automation mode (default):
;;;;     cscript //nologo WORKDIR/bridge-autocad.vbs
;;;;     The VBScript creates AutoCAD.Application via COM, calls
;;;;     SendCommand with the run-common.lsp load, and polls
;;;;     GetAcadState via WaitQuiescent.
;;;;
;;;;   Batch mode (`--mode batch` or `AUTOCAD_COM_MODE=off`):
;;;;     accoreconsole.exe /i <dwg> /s <SCRFILE>
;;;;     Headless, faster, but no vlisp-compile or DCL.

(defpackage #:alfe.backend.autocad
  (:use #:cl)
  (:import-from #:alfe.backend
                #:backend
                #:backend-name
                #:detect
                #:prepare-workdir
                #:start-engine
                #:eval-plan
                #:read-output
                #:send-input
                #:request-control
                #:shutdown
                #:cleanup-workdir
                #:session
                #:session-backend
                #:session-workdir
                #:session-dialect
                #:session-state
                #:session-request-timeout
                #:session-state-set
                #:register-backend)
  (:import-from #:alfe.error
                #:backend-not-available
                #:backend-bootstrap-error
                #:backend-eval-error)
  (:import-from #:alfe.workdir
                #:make-fresh-workdir
                #:remove-workdir)
  (:import-from #:alfe.backend.cad-common
                #:host-os
                #:macos-p
                #:linux-p
                #:windows-p
                #:env-binary
                #:first-existing
                #:windows-glob-existing-files
                #:vbs-escape
                #:discover-runtime-lsp
                #:discover-bootstrap-lsp
                #:drive-protocol-actions
                #:kill-engine-process)
  (:import-from #:alfe.logging
                #:log-debug
                #:log-verbose
                #:log-warn)
  (:export #:autocad-backend
           #:make-autocad-backend
           #:autocad-backend-executable-path
           #:autocad-backend-accoreconsole-path
           #:autocad-session
           #:emit-bridge-vbs
           #:emit-batch-scr
           #:build-launch-argv
           #:discover-autocad-binary
           #:discover-accoreconsole-binary
           #:discover-autocad-template
           #:unsupported-os-message))

(in-package #:alfe.backend.autocad)

;;; --- backend class -------------------------------------------------

(defclass autocad-backend (backend)
  ((variant
    :initarg :variant
    :reader autocad-backend-variant
    :initform :auto
    :type (member :auto :automation :batch))
   (executable-path
    :initarg :executable-path
    :accessor autocad-backend-executable-path
    :initform nil
    :documentation
    "Absolute path of acad.exe (full GUI) when DETECT found one.")
   (accoreconsole-path
    :initarg :accoreconsole-path
    :accessor autocad-backend-accoreconsole-path
    :initform nil
    :documentation
    "Absolute path of accoreconsole.exe when DETECT found one. Used
by --mode batch."))
  (:default-initargs
   :name :autocad
   :display-name "AutoCAD"
   :supports-vlisp-compile-p t))

(defun make-autocad-backend (&rest initargs)
  (apply #'make-instance 'autocad-backend initargs))

;;; --- platform gating helper ---------------------------------------

(defun unsupported-os-message ()
  (format nil
          "AutoCAD is not distributed for ~A. Use --bricscad on macOS/Linux."
          (case (host-os)
            (:macos   "macOS")
            (:linux   "Linux")
            (:unknown "this OS")
            (t        (string-downcase (symbol-name (host-os)))))))

;;; --- binary discovery ---------------------------------------------

(defun windows-acad-candidates ()
  (sort (append
         (windows-glob-existing-files
          '("Autodesk/AutoCAD */acad.exe"
            "Autodesk/AutoCAD LT */acadlt.exe"))
         ;; Keep the MSYS/MinGW-style /c fallback for compatibility
         ;; with Unix-like Windows runtimes that do expose that view.
         (mapcar #'namestring
                 (append
                  (directory "/c/Program Files/Autodesk/AutoCAD */acad.exe")
                  (directory "/c/Program Files/Autodesk/AutoCAD LT */acadlt.exe"))))
        #'string>))

(defun %accoreconsole-preference (path)
  "Ranking key (lower = preferred) for accoreconsole candidates. Several
Autodesk products ship accoreconsole.exe; only full AutoCAD can create
and modify entities. The free DWG TrueView VIEWER also ships one but is
read-only (and, seen on a CI runner, its config in Program Files is
read-only/locked and aborts on launch), so it must never win over real
AutoCAD (alfe-cad-console-encoding.issue / DWG-TrueView discovery)."
  (let ((p (string-downcase (namestring path))))
    (cond ((search "trueview" p) 2)         ; read-only viewer — last resort
          ((search "autocad" p) 0)          ; real AutoCAD — preferred
          (t 1))))

(defun windows-accoreconsole-candidates ()
  ;; Version-descending within a preference tier, then AutoCAD before
  ;; generic before DWG TrueView (STABLE-SORT keeps the version order).
  (stable-sort
   (sort (append
          (windows-glob-existing-files '("Autodesk/*/accoreconsole.exe"))
          ;; Keep the MSYS/MinGW-style /c fallback for compatibility
          ;; with Unix-like Windows runtimes that do expose that view.
          (mapcar #'namestring
                  (directory "/c/Program Files/Autodesk/*/accoreconsole.exe")))
         #'string>)
   #'< :key #'%accoreconsole-preference))

(defun discover-autocad-binary (&key
                                  (os (host-os)))
  (or (env-binary "AUTOCAD_EXE")
      (when (eq os :windows)
        (first-existing (windows-acad-candidates)))))

(defun discover-accoreconsole-binary (&key
                                        (os (host-os)))
  "Locate the AcCoreConsole batch engine.

On Windows it is auto-discovered from the install. AcCoreConsole ALSO ships
inside the macOS AutoCAD bundle and can be driven by alfe — but it is NOT
auto-discovered here: on macOS it is opt-in via $AUTOCAD_ACCORECONSOLE, which
`--cad accoreconsole' sets to the bundle path (cli.lisp). Auto-globbing the
bundle would make plain `--autocad' — and thus the conformance corpus, through
BACKEND-AVAILABLE-P -> DETECT — treat macOS as a working AutoCAD host and RUN the
AutoCAD scenarios, but the macOS batch engine still aborts at bootstrap
(accoreconsole-macos-headless-qt-blocker), so they fail with exit 4 instead of
skipping. Env-gating keeps the corpus deterministic (Windows-only for real
AutoCAD) while letting `--cad accoreconsole' drive it on macOS for debugging."
  (or (env-binary "AUTOCAD_ACCORECONSOLE")
      (when (eq os :windows)
        (first-existing (windows-accoreconsole-candidates)))))

(defun candidate-autocad-template-paths (backend)
  "Return likely DWG/DWT templates that ship alongside the discovered
AutoCAD install. The list is ordered by the ISO template first, then
the imperial one. This is an implementation-default for batch mode
when the user did not pass --dwg / $AUTOLISP_DWG."
  (let ((roots
          (remove nil
                  (mapcar (lambda (path)
                            (when path
                              (uiop:ensure-directory-pathname
                               (make-pathname :name nil :type nil :version nil
                                              :defaults path))))
                          (list (autocad-backend-executable-path backend)
                                (autocad-backend-accoreconsole-path backend))))))
    (loop for root in roots
          append (list (merge-pathnames "Template/acadiso.dwt" root)
                       (merge-pathnames "Template/acad.dwt" root)
                       (merge-pathnames "UserDataCache/Template/acadiso.dwt" root)
                       (merge-pathnames "UserDataCache/Template/acad.dwt" root)))))

(defun discover-autocad-template (backend &key requested)
  "Resolve the drawing/template to feed accoreconsole batch mode.
Order of precedence:
  1. REQUESTED (from --dwg) when it exists;
  2. $AUTOLISP_DWG when it exists;
  3. a shipped acadiso.dwt/acad.dwt next to the discovered AutoCAD
     install;
  4. NIL, in which case the caller raises :no-dwg."
  (or (and requested
           (probe-file requested)
           (namestring (truename requested)))
      (env-binary "AUTOLISP_DWG")
      (first-existing (candidate-autocad-template-paths backend))))

;;; --- DETECT --------------------------------------------------------

(defmethod detect ((backend autocad-backend) &key)
  (let ((acad (discover-autocad-binary))
        (acc  (discover-accoreconsole-binary)))
    ;; The AutoCAD GUI / COM-automation path is Windows-only, but the
    ;; AcCoreConsole BATCH engine ships with the macOS AutoCAD bundle and runs
    ;; there. Allow a non-Windows host only when an accoreconsole binary is
    ;; available (batch mode); GUI acad / --mode automation still needs Windows.
    (when (and (not (windows-p)) (not acc))
      (error 'backend-not-available
             :backend :autocad
             :code :unsupported-os
             :message (unsupported-os-message)
             :details (list :os (host-os))))
    (unless (or acad acc)
      (error 'backend-not-available
             :backend :autocad
             :code :no-binary
             :message
             "AutoCAD binary not found. Set $AUTOCAD_EXE or $AUTOCAD_ACCORECONSOLE."
             :details (list :env-acad (uiop:getenv "AUTOCAD_EXE")
                            :env-acc  (uiop:getenv "AUTOCAD_ACCORECONSOLE"))))
    (setf (autocad-backend-executable-path backend) acad
          (autocad-backend-accoreconsole-path backend) acc)
    backend))

;;; --- emitter: bridge-autocad.vbs (Windows automation) -------------

(defparameter *bridge-autocad-vbs-template*
  ;; A VBScript comment is an apostrophe (or REM), NEVER `;;'. These lines
  ;; are the FIRST thing cscript reads, so a Lisp comment marker here does
  ;; not degrade — it is a syntax error at line 1, before AutoCAD COM is
  ;; even touched. Kept ASCII for the same reason the marker matters:
  ;; cscript reads a .vbs as ANSI unless it carries a BOM, and this file is
  ;; written UTF-8 without one, so any non-ASCII character would arrive
  ;; mangled. Inside a comment that is only ugly; it is not worth the risk
  ;; of ever moving one of these characters into code.
  "' AutoCAD COM bridge - emitted by alfe.backend.autocad
' Placeholders: ${RUNLSPFILE}, ${STATUSFILE}, ${ERRFILE},
' ${COMMODE}, ${DEBUGFILE}, ${WAIT_SECS}.
' Mirrors the legacy bash wrapper's bridge-autocad.vbs; preserve
' the WaitQuiescent + GetAcadState handshake - it's the hard-won
' piece that keeps the bridge from racing AutoCAD's UI init.

Option Explicit
Dim fso, app, doc, runFile, statusFile, errFile, commode, debugFile, waitSecs
Dim attached, created, rc, statusReadyFlag

Set fso = CreateObject(\"Scripting.FileSystemObject\")
runFile     = \"${RUNLSPFILE}\"
statusFile  = \"${STATUSFILE}\"
errFile     = \"${ERRFILE}\"
commode     = \"${COMMODE}\"
debugFile   = \"${DEBUGFILE}\"
waitSecs    = ${WAIT_SECS}
attached    = False
created     = False
statusReadyFlag = False
' app/doc MUST be object references before any `Is Nothing` test: an
' unassigned Dim variable is Empty, and `Empty Is Nothing` raises the
' runtime error 424 \"Object required\". A failed GetObject leaves app
' unassigned, so without this the attach-miss path dies at `If app Is
' Nothing` instead of falling through to CreateObject.
Set app = Nothing
Set doc = Nothing

Sub AppendLine(path, text)
  Dim f
  Set f = fso.OpenTextFile(path, 8, True)
  f.WriteLine text
  f.Close
End Sub

Sub VBSDebug(msg)
  If debugFile <> \"\" Then AppendLine debugFile, \"[VBS] \" & msg
End Sub

Sub EmitFlags(att, cre)
  Dim a, c
  If att Then a = \"1\" Else a = \"0\"
  If cre Then c = \"1\" Else c = \"0\"
  WScript.StdOut.WriteLine \"ATTACHED=\" & a
  WScript.StdOut.WriteLine \"CREATED=\"  & c
End Sub

Sub WaitQuiescent(a, secs)
  Dim deadline, state, quiescent, supported
  deadline = DateAdd(\"s\", secs, Now)
  Do While Now < deadline
    On Error Resume Next
    state = a.GetAcadState
    supported = (Err.Number = 0)
    Err.Clear
    On Error GoTo 0
    If supported Then
      quiescent = state.IsQuiescent
      If quiescent Then Exit Do
    Else
      ' Older AutoCAD versions don't expose GetAcadState; fall back
      ' to a short sleep + best-effort exit.
      WScript.Sleep 200
      Exit Do
    End If
    WScript.Sleep 200
  Loop
End Sub

If commode = \"attach\" Or commode = \"auto\" Then
  On Error Resume Next
  Set app = GetObject(, \"AutoCAD.Application\")
  If Err.Number = 0 And Not (app Is Nothing) Then attached = True
  Err.Clear
  On Error GoTo 0
End If

If app Is Nothing Then
  If commode = \"attach\" Then
    AppendLine errFile, \"ERROR COM bridge: no running AutoCAD to attach to.\"
    EmitFlags False, False
    WScript.Quit 4
  End If
  On Error Resume Next
  Set app = CreateObject(\"AutoCAD.Application\")
  If Err.Number <> 0 Then
    AppendLine errFile, \"ERROR COM bridge: could not launch AutoCAD: \" & Err.Description
    EmitFlags False, False
    WScript.Quit 4
  End If
  Err.Clear
  On Error GoTo 0
  created = True
End If

app.Visible = True
EmitFlags attached, created

WaitQuiescent app, waitSecs

If app.Documents.Count = 0 Then
  Call app.Documents.Add(\"\")
End If
Set doc = app.ActiveDocument

VBSDebug \"SendCommand (load ...)\"
Dim cmd
cmd = \"(load \"\"\" & Replace(runFile, \"\\\", \"/\") & \"\"\") \"
On Error Resume Next
Call doc.SendCommand(cmd)
If Err.Number <> 0 Then
  AppendLine errFile, \"ERROR COM bridge: SendCommand failed: \" & Err.Description
  WScript.Quit 4
End If
On Error GoTo 0

' Don't call app.Quit here - the runtime publishes its own status
' and the alfe-side poller decides on the lifecycle.
WScript.Quit 0
"
  "VBScript template for the Windows AutoCAD COM bridge. Mirrors
the legacy bash bridge-autocad.vbs; placeholders are substituted by
EMIT-BRIDGE-VBS.")

(defun substitute-placeholders (template alist)
  (let ((out template))
    (loop for (key . value) in alist
          do (setf out (uiop:frob-substrings
                        out (list (format nil "${~A}" key))
                        (vbs-escape value))))
    out))

(defun emit-bridge-vbs (path
                        &key runtime-load-path
                             status-path
                             error-path
                             debug-path
                             (com-mode "auto")
                             (wait-secs 60))
  (let ((text (substitute-placeholders
               *bridge-autocad-vbs-template*
               `(("RUNLSPFILE"  . ,(namestring runtime-load-path))
                 ("STATUSFILE"  . ,(namestring status-path))
                 ("ERRFILE"     . ,(namestring error-path))
                 ("COMMODE"     . ,com-mode)
                 ("DEBUGFILE"   . ,(if debug-path (namestring debug-path) ""))
                 ("WAIT_SECS"   . ,(format nil "~D" wait-secs))))))
    (with-open-file (out path :direction :output
                              :if-exists :supersede
                              :if-does-not-exist :create
                              :external-format :utf-8)
      (write-string text out))
    path))

;;; --- emitter: batch SCR (accoreconsole) ---------------------------

(defun emit-batch-scr (path runtime-load-path)
  "Write the accoreconsole SCR. Loads run-common.lsp; the runtime
publishes its own DONE/STOPPED transitions, so the SCR itself
doesn't need a _QUIT — accoreconsole exits when the script finishes."
  (let ((text (with-output-to-string (out)
                (format out "(load ~S)~%"
                        (namestring (truename runtime-load-path)))
                (format out "._QSAVE~%")
                (format out "._QUIT _Y~%"))))
    (with-open-file (out path :direction :output
                              :if-exists :supersede
                              :if-does-not-exist :create
                              :external-format :utf-8)
      (write-string text out))
    path))

;;; --- launch argv --------------------------------------------------

(defun choose-effective-mode (backend cli-mode)
  (case cli-mode
    (:auto
     (cond ((autocad-backend-executable-path backend)    :automation)
           ((autocad-backend-accoreconsole-path backend) :batch)
           (t :automation)))
    ((:batch :automation) cli-mode)))

(defun build-launch-argv (backend protocol-session
                          &key (mode :auto) dwg)
  (let* ((variant (choose-effective-mode backend mode))
         (workdir (alfe.protocol.file:protocol-session-workdir protocol-session))
         (resolved-dwg (and (eq variant :batch)
                            (discover-autocad-template backend :requested dwg))))
    (case variant
      (:automation
       (list "cscript" "//nologo"
             (namestring (merge-pathnames "bridge-autocad.vbs" workdir))))
      (:batch
       (let ((acc (autocad-backend-accoreconsole-path backend))
             (scr (merge-pathnames "run.scr" workdir)))
         (unless acc
           (error 'backend-bootstrap-error
                  :backend :autocad
                  :code :no-accoreconsole
                  :message "Batch mode requires $AUTOCAD_ACCORECONSOLE or accoreconsole.exe on disk."))
         (unless resolved-dwg
           (error 'backend-bootstrap-error
                  :backend :autocad
                  :code :no-dwg
                  :message
                  "Batch mode requires --dwg FILE, $AUTOLISP_DWG, or a discoverable AutoCAD template."))
         (list acc "/i" resolved-dwg "/s" (namestring scr)))))))

(defun string-prefix-p (prefix string)
  (and string
       (>= (length string) (length prefix))
       (string= prefix string :end2 (length prefix))))

(defparameter *accoreconsole-console-encoding* :utf-16le
  "accoreconsole's console / stdout is UTF-16LE, FIXED by the product
(verified 2026-07-29 on French Windows; no /l language flag or chcp code
page changes it). Named so the value lives in ONE place. The drain decodes
the channel with it; the robust auto-detect cascade (:AUTO) stays as the
safety net for any target that turns out NOT to be UTF-16LE.")

(defun %autocad-console-decode-encoding (cli-options variant)
  "How the DRAIN decodes the protocol stdout/stderr FILES. These are written by
the AutoLISP runtime (open + write-line), NOT by accoreconsole itself, so they
carry the CAD's FILE encoding -- UTF-8/ASCII in practice (verified on real
AutoCAD 2022), possibly UTF-16LE on some locales -- which is DISTINCT from
accoreconsole's own console PIPE (that is UTF-16LE and is handled by
AUTOCAD-CONSOLE-EXTERNAL-FORMAT). The files are self-describing, so decode with
the robust :AUTO cascade (it detects UTF-16LE via the interleaved NULs, else
UTF-8/Latin-1, and never signals). Forcing :UTF-16LE here decoded the UTF-8
payload as UTF-16 and turned every line into CJK mojibake -- the real cause of
autocad-no-rest-output-capture. An explicit -Econsole / -Ecadstdio still forces
a codec for a target that genuinely needs one."
  (declare (ignore variant))
  (let ((requested (alfe.cli:resolved-console-encoding cli-options)))
    (if (eq requested :auto)
        :auto
        (clautolisp.autolisp-cli:encoding-keyword requested))))

(defun autocad-console-external-format (&optional cli-options)
  "The external-format for reading accoreconsole's own stdout/stderr PIPE
(diagnostics). Precedence: an explicit -Econsole / -Ecadstdio in CLI-OPTIONS,
then $ALFE_AUTOCAD_CONSOLE_ENCODING, then the robust default :ISO-8859-1 — a
total decoder that never signals, so a non-UTF-8 Windows console cannot crash
bootstrap; SLURP-PROCESS-STREAM strips UTF-16LE's interleaved NULs. The
protocol PAYLOAD is decoded separately by the drain (DECODE-CONSOLE-OCTETS,
never signals) with %AUTOCAD-CONSOLE-DECODE-ENCODING — this is only the raw
pipe read, so the default stays the robust total decoder (G2)."
  (let ((requested (and cli-options
                        (let ((e (alfe.cli:resolved-console-encoding cli-options)))
                          (unless (eq e :auto) e))))
        (env (uiop:getenv "ALFE_AUTOCAD_CONSOLE_ENCODING")))
    (cond
      (requested (clautolisp.autolisp-cli:encoding-keyword requested))
      ((and env (plusp (length env))) (intern (string-upcase env) :keyword))
      (t :iso-8859-1))))

(defun slurp-process-stream (stream)
  (if (null stream)
      ""
      (with-output-to-string (out)
        (loop for ch = (read-char stream nil nil)
              while ch
              unless (char= ch #\Null)
                do (write-char ch out)))))

(defun process-exit-details (process-info)
  (let ((exit-code (ignore-errors (uiop:wait-process process-info)))
        (stdout (slurp-process-stream
                 (ignore-errors (uiop:process-info-output process-info))))
        (stderr (slurp-process-stream
                 (ignore-errors (uiop:process-info-error-output process-info)))))
    (list :exit-code exit-code
          :stdout stdout
          :stderr stderr)))

(defun summarize-process-exit (details)
  (let* ((exit-code (getf details :exit-code))
         (stderr (string-trim '(#\Return #\Newline #\Space #\Tab)
                              (or (getf details :stderr) "")))
         (stdout (string-trim '(#\Return #\Newline #\Space #\Tab)
                              (or (getf details :stdout) "")))
         (snippet (cond ((plusp (length stderr)) stderr)
                        ((plusp (length stdout)) stdout)
                        (t ""))))
    (if (plusp (length snippet))
        (format nil "AutoCAD process exited before READY (exit ~A): ~A"
                exit-code snippet)
        (format nil "AutoCAD process exited before READY (exit ~A)."
                exit-code))))

(defun wait-for-ready-or-process-exit (protocol process-info timeout)
  (let ((start (get-internal-real-time))
        (interval-ms 50)
        (last-seen nil)
        (prev-status nil))
    (labels ((elapsed ()
               (/ (float (- (get-internal-real-time) start))
                  internal-time-units-per-second)))
      (loop
        (alfe.protocol.file:stream-debug-log-to-logger protocol)
        (setf last-seen (alfe.protocol.file:read-current-status protocol))
        (when (and last-seen (not (equal last-seen prev-status)))
          (log-debug "protocol: status now ~S (elapsed ~,2F s)"
                     last-seen (elapsed))
          (setf prev-status last-seen))
        (when (string-prefix-p "READY" last-seen)
          (log-debug "protocol: matched ~S after ~,2F s"
                     "READY" (elapsed))
          (alfe.protocol.file:stream-debug-log-to-logger protocol)
          (return (values :ready (elapsed) last-seen nil)))
        (when (and process-info
                   (not (uiop:process-alive-p process-info)))
          (let ((details (process-exit-details process-info)))
            (alfe.protocol.file:stream-debug-log-to-logger protocol)
            (return (values :exited (elapsed) last-seen details))))
        (when (>= (elapsed) timeout)
          (log-debug "protocol: timeout after ~,2F s (last status ~S)"
                     (elapsed) last-seen)
          (alfe.protocol.file:stream-debug-log-to-logger protocol)
          (return (values :timeout (elapsed) last-seen nil)))
        (sleep (/ interval-ms 1000.0))
        (setf interval-ms (min 500 (* 2 interval-ms)))))))

;;; --- session subclass + START-ENGINE -----------------------------

(defstruct (autocad-session
            (:include session)
            (:constructor %make-autocad-session)
            (:copier nil))
  (protocol-session nil)
  (process-info     nil)
  (variant          nil))

(defmethod prepare-workdir ((backend autocad-backend) workdir-root &key)
  (let ((workdir (if workdir-root
                     (uiop:ensure-directory-pathname workdir-root)
                     (make-fresh-workdir :autocad))))
    (ensure-directories-exist workdir)
    workdir))

(defmethod start-engine ((backend autocad-backend) workdir
                         &key dialect host mock-input bootstrap-phase
                              interactive-p
                              load-encoding
                              io-encoding
                              cli-options version-text
                              (mode :auto)
                              (dwg nil)
                              (launcher #'uiop:launch-program)
                              (wait-for-ready t)
                              (ready-timeout 60))
  ;; LOAD-ENCODING accepted but ignored: the AutoCAD-resident
  ;; AutoLISP runtime owns the source-file encoding policy.
  (declare (ignore dialect host mock-input load-encoding io-encoding))
  (log-verbose "backend AUTOCAD: starting engine (mode ~A)" mode)
  (log-debug "backend AUTOCAD: workdir = ~A" workdir)
  ;; Parity with the BricsCAD backend: let --timeout / $AUTOLISP_WAIT_SECS
  ;; raise the READY timeout too, so a cold accoreconsole launch is not
  ;; reported as a spurious READY-TIMEOUT while it is still booting.
  (when (and cli-options (alfe.cli:cli-options-timeout cli-options))
    (setf ready-timeout (alfe.cli:cli-options-timeout cli-options)))
  (log-debug "backend AUTOCAD: dwg = ~A; ready-timeout = ~A s; wait-for-ready = ~A"
             dwg ready-timeout wait-for-ready)
  (handler-case
      (let* ((runtime-source (discover-runtime-lsp))
             (bootstrap-source (discover-bootstrap-lsp))
             (protocol (alfe.protocol.file:init-session
                        workdir
                        :runtime-lsp-source runtime-source
                        :bootstrap-lsp-source bootstrap-source))
             (staged-runtime
               (when runtime-source
                 (alfe.protocol.file:stage-runtime-lsp protocol)))
             (staged-bootstrap
               (when bootstrap-source
                 (alfe.protocol.file:stage-bootstrap-lsp protocol)))
             (run-common
               (alfe.protocol.file:emit-run-common-lsp
                protocol
                :bootstrap-phase bootstrap-phase
                :use-remote-protocol-p t
                :quit-on-finish-p (not interactive-p)
                :debug-p (and cli-options
                              (eq :debug
                                  (alfe.cli:cli-options-verbosity cli-options)))
                :cli-options cli-options
                :version-text version-text
                :backend-name "AUTOCAD"))
             (variant (choose-effective-mode backend mode)))
        ;; G2: how the drain decodes AutoCAD's console output. accoreconsole
        ;; (batch) is UTF-16LE, product-fixed (conflicting -Econsole warned +
        ;; ignored); the GUI path honours the user's request, else :AUTO.
        (setf (alfe.protocol.file:protocol-session-console-encoding protocol)
              (%autocad-console-decode-encoding cli-options variant))
        (cond
          (staged-bootstrap
           (log-debug "backend AUTOCAD: staged bootstrap -> ~A" staged-bootstrap))
          (bootstrap-source
           (log-warn "backend AUTOCAD: bootstrap source ~A resolved but staging returned NIL"
                     bootstrap-source))
          (t
           (log-warn "backend AUTOCAD: no bootstrap LSP found; set $ALFE_BOOTSTRAP_LSP or install autolisp-bootstrap.lsp")))
        (cond
          (staged-runtime
           (log-debug "backend AUTOCAD: staged runtime -> ~A" staged-runtime))
          (runtime-source
           (log-warn "backend AUTOCAD: runtime source ~A resolved but staging returned NIL"
                     runtime-source))
          (t
           (log-warn "backend AUTOCAD: no runtime LSP found; set $ALFE_RUNTIME_LSP or install autolisp-remote-io.lsp")))
        (log-debug "backend AUTOCAD: emitted run-common.lsp -> ~A" run-common)
        (log-verbose "backend AUTOCAD: effective mode = ~A" variant)
        (case variant
          (:automation
           (let ((vbs (merge-pathnames "bridge-autocad.vbs" workdir)))
             (emit-bridge-vbs
              vbs
              :runtime-load-path run-common
              :status-path (alfe.protocol.file:protocol-session-status-path protocol)
              :error-path  (alfe.protocol.file:protocol-session-stderr-path protocol)
              :com-mode    (or (uiop:getenv "AUTOCAD_COM_MODE") "auto"))
             (log-debug "backend AUTOCAD: wrote bridge-autocad.vbs -> ~A" vbs)))
          (:batch
           (let ((scr (merge-pathnames "run.scr" workdir)))
             (emit-batch-scr scr run-common)
             (log-debug "backend AUTOCAD: wrote run.scr -> ~A" scr))))
        (let* ((argv (build-launch-argv backend protocol :mode mode :dwg dwg))
               (session (%make-autocad-session
                         :backend backend
                         :workdir workdir
                         :request-timeout (and cli-options
                                               (alfe.cli:cli-options-timeout
                                                cli-options))
                         :protocol-session protocol
                         :variant variant))
               (_ (log-verbose "backend AUTOCAD: launching: ~{~A~^ ~}" argv))
               (process-info
                 (when launcher
                   (funcall launcher argv
                            :input :stream
                            :output :stream
                            :error-output :stream
                            ;; accoreconsole's console is not UTF-8 on a
                            ;; non-UTF-8 Windows; a robust external-format
                            ;; keeps reading its pipe from crashing bootstrap
                            ;; (alfe-accoreconsole-encoding.issue). -Econsole /
                            ;; -Ecadstdio (or $ALFE_AUTOCAD_CONSOLE_ENCODING)
                            ;; override it (G2 send half).
                            :external-format (autocad-console-external-format
                                              cli-options)))))
          (declare (ignore _))
          (when process-info
            (log-debug "backend AUTOCAD: spawned, process-info-pid = ~A"
                       (ignore-errors (uiop:process-info-pid process-info))))
          (setf (autocad-session-process-info session) process-info)
          ;; Reap the engine when the start does NOT complete. Without this,
          ;; a READY timeout signalled below left the spawned AutoCAD alive:
          ;; alfe reported the timeout and returned, but the CI job kept
          ;; running because the surviving process still held the console
          ;; handles — 32 minutes on the shared concurrency=1 CAD runner,
          ;; 2026-08-14. alfe's --timeout bounds the PROTOCOL wait; it never
          ;; bounded the engine's lifetime. The BricsCAD backend has had
          ;; this guard; AutoCAD had not.
          (let ((started-ok nil))
            (unwind-protect
                (progn
                  (%autocad-await-ready session protocol process-info workdir
                                        ready-timeout wait-for-ready)
                  (session-state-set session :ready)
                  (setq started-ok t)
                  session)
              (unless started-ok
                (when process-info
                  (ignore-errors
                   (log-warn "backend AUTOCAD: start aborted; terminating spawned engine (pid ~A)"
                             (ignore-errors (uiop:process-info-pid process-info))))
                  (kill-engine-process process-info)))))))
    (alfe.error:backend-error (probe)
      (error probe))
    (error (probe)
      (error 'backend-bootstrap-error
             :backend :autocad
             :code :bootstrap-failed
             :message (format nil "AutoCAD start-engine failed: ~A" probe)
             :details (list :origin probe)))))

(defun %autocad-await-ready (session protocol process-info workdir
                             ready-timeout wait-for-ready)
  "Wait for the engine to reach READY, signalling on exit-before-ready or
timeout. Split out of START-ENGINE so the caller can wrap it in the
unwind-protect that reaps the engine when it does not get there."
  (declare (ignorable session))
  (block nil
          (when wait-for-ready
            (log-verbose "backend AUTOCAD: waiting for READY (timeout ~A s)"
                         ready-timeout)
            (multiple-value-bind (state elapsed last details)
                (wait-for-ready-or-process-exit
                 protocol process-info ready-timeout)
              (cond
                ((eq state :ready)
                 (log-verbose "backend AUTOCAD: READY after ~,2F s (status ~S)"
                              elapsed last))
                ((eq state :exited)
                 (log-warn "backend AUTOCAD: process exited after ~,2F s; last status = ~S"
                           elapsed last)
                 (error 'backend-bootstrap-error
                        :backend :autocad
                        :code :process-exited-before-ready
                        :message (summarize-process-exit details)
                        :details (append
                                  (list :workdir workdir
                                        :last-status last)
                                  details)))
                (t
                 (log-warn "backend AUTOCAD: READY timeout after ~,2F s; last status = ~S"
                           elapsed last)
                 (error 'backend-bootstrap-error
                        :backend :autocad
                        :code :ready-timeout
                        :message
                        (format nil "AutoCAD did not reach READY within ~A s (last: ~S)."
                                ready-timeout last)
                        :details (list :workdir workdir :last-status last))))))
    nil))

;;; --- EVAL-PLAN ----------------------------------------------------

(defmethod eval-plan ((session autocad-session) plan)
  (session-state-set session :running)
  (let* ((explicit-timeout (session-request-timeout session))
         (result (drive-protocol-actions
                  (autocad-session-protocol-session session) plan
                  ;; See the BricsCAD eval-plan: --timeout bounds the DONE
                  ;; wait (hard cap when explicit), else a RUNNING eval is
                  ;; kept alive while accoreconsole lives
                  ;; (alfe-request-timeout-aborts-long-eval).
                  :request-timeout (or explicit-timeout 30)
                  :keep-alive-while-running (null explicit-timeout)
                  :process-info (autocad-session-process-info session))))
    (session-state-set session
                       (ecase (alfe.backend:eval-result-status result)
                         (:success :done)
                         (:failed  :done)
                         (:aborted :failed)))
    result))

;;; --- READ-OUTPUT / SEND-INPUT / REQUEST-CONTROL ------------------

(defmethod read-output ((session autocad-session) &key timeout)
  (declare (ignore timeout))
  (let ((protocol (autocad-session-protocol-session session)))
    (values (alfe.protocol.file:drain-stdout protocol)
            (alfe.protocol.file:drain-stderr protocol))))

(defmethod send-input ((session autocad-session) text)
  (alfe.protocol.file:send-stdin
   (autocad-session-protocol-session session) text))

(defmethod request-control ((session autocad-session) command)
  (alfe.protocol.file:send-control
   (autocad-session-protocol-session session) command)
  (case command
    (:ping      :pong)
    (:shutdown  :stopped)
    (:interrupt :interrupted)))

(defmethod shutdown ((session autocad-session) &key reason)
  (declare (ignore reason))
  (unless (eq (session-state session) :stopped)
    (let ((protocol (autocad-session-protocol-session session))
          (info (autocad-session-process-info session)))
      (ignore-errors (alfe.protocol.file:send-control protocol :shutdown))
      (ignore-errors
       (alfe.protocol.file:wait-for-status
        protocol alfe.protocol.file:+status-stopped+ :timeout 5))
      ;; NOT terminate + (uiop:wait-process info): that wait is UNBOUNDED,
      ;; and on Windows a GUI CAD that is slow to die — or a child of it
      ;; still holding the handles — hangs it, freezing alfe in shutdown
      ;; and with it the whole CI job. The BricsCAD backend learned this
      ;; and grew a bounded killer; AutoCAD had kept the unbounded call.
      ;; KILL-ENGINE-PROCESS is now shared by both.
      (kill-engine-process info))
    (session-state-set session :stopped))
  session)

(defmethod cleanup-workdir ((backend autocad-backend) workdir &key keep-p)
  (when workdir
    (remove-workdir workdir :keep-p keep-p))
  nil)

;;; --- registration -------------------------------------------------

(register-backend :autocad (make-autocad-backend))
