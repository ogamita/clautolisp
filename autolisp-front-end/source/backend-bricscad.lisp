;;;; autolisp-front-end/source/backend-bricscad.lisp
;;;;
;;;; The BricsCAD backend — Phase 3 of the alfe rollout. Specified
;;;; by ../issues/open/alfe-backend-bricscad.issue and the spec's
;;;; "Backend bricscad" section.
;;;;
;;;; BricsCAD's AutoLISP REPL lives behind a GUI, so alfe drives it
;;;; through the file-IPC protocol (alfe-file-protocol.issue): the
;;;; CAD-side runtime (autolisp-remote-io.lsp, reused verbatim)
;;;; consumes stdin.txt / control.txt and publishes status.txt /
;;;; stdout.txt / stderr.txt; the alfe side publishes the request
;;;; lines, polls status, and drains output.
;;;;
;;;; Per-platform launch:
;;;;
;;;;   macOS, batch mode (default):
;;;;     bricscad <template.dwt> [-P <profile>] -B WORKDIR/run.scr
;;;;
;;;;   macOS, automation mode (--mode automation):
;;;;     osascript <emitted .applescript> — injects (load run-common.lsp)
;;;;     into a running or freshly-launched BricsCAD via System Events.
;;;;
;;;;   Linux, batch mode:
;;;;     bricscad <template> -B WORKDIR/run.scr
;;;;     (Linux automation is deferred per the issue.)
;;;;
;;;;   Windows, batch mode (default, when bricscad.exe is found):
;;;;     bricscad.exe <template> [/p <profile>] /b WORKDIR/run.scr
;;;;     Same GUI-exe + script mechanism as macOS/Linux — no COM. NB the
;;;;     Windows CLI takes /p and /b (AutoCAD-lineage), not the Unix -P/-B.
;;;;     $AUTOLISP_BRICSCAD_PROFILE names the profile; a CLEAN profile is
;;;;     required for pure-CAD runs, else the runner's default profile
;;;;     auto-loads a vertical app whose startup blocks the /b script.
;;;;
;;;;   Windows, automation mode (--mode automation, or :auto with no exe):
;;;;     cscript //nologo WORKDIR/bridge-bricscad.vbs
;;;;     The VBScript instantiates BricsCAD via COM, calls SendCommand
;;;;     with the run-common.lsp load. Kept as a fallback; the batch path
;;;;     avoids its SendCommand-timing and modal-dialog fragility.

(defpackage #:alfe.backend.bricscad
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
                #:macos-p
                #:linux-p
                #:windows-p
                #:host-os
                #:env-binary
                #:first-existing
                #:windows-glob-existing-files
                #:vbs-escape
                #:applescript-escape
                #:discover-runtime-lsp
                #:discover-bootstrap-lsp
                #:drive-protocol-actions)
  (:import-from #:alfe.logging
                #:log-debug
                #:log-verbose
                #:log-info
                #:log-warn)
  (:export #:bricscad-backend
           #:make-bricscad-backend
           #:bricscad-backend-variant
           #:bricscad-backend-executable-path
           #:bricscad-backend-template-path
           #:bricscad-session
           #:emit-run-scr
           #:emit-bridge-vbs
           #:emit-launcher-applescript
           #:build-launch-argv
           #:discover-bricscad-binary
           #:discover-bricscad-template))

(in-package #:alfe.backend.bricscad)

;;; --- backend class -------------------------------------------------

(defclass bricscad-backend (backend)
  ((variant
    :initarg :variant
    :reader bricscad-backend-variant
    :initform :auto
    :type (member :auto :batch :automation)
    :documentation
    "Launch mode. :auto picks :batch on macOS/Linux when a CLI binary
is found, otherwise :automation. The CLI's --mode flag is the
public switch.")
   (executable-path
    :initarg :executable-path
    :accessor bricscad-backend-executable-path
    :initform nil
    :documentation
    "Absolute path of the bricscad binary that DETECT discovered.")
   (template-path
    :initarg :template-path
    :accessor bricscad-backend-template-path
    :initform nil
    :documentation
    "Absolute path of the template .dwt/.dwg DETECT discovered (or
the user-overridden one via --dwg / $AUTOLISP_DWG).")
   (profile
    :initarg :profile
    :accessor bricscad-backend-profile
    :initform nil
    :documentation
    "Optional user-profile name, passed via /p (Windows) or -P (Unix).
Resolved from $AUTOLISP_BRICSCAD_PROFILE. A clean profile keeps a
pure-CAD run from auto-loading a vertical application."))
  (:default-initargs
   :name :bricscad
   :display-name "BricsCAD"))

(defun make-bricscad-backend (&key (variant :auto)
                                   executable-path
                                   template-path
                                   profile)
  (make-instance 'bricscad-backend
                 :variant variant
                 :executable-path executable-path
                 :template-path template-path
                 :profile profile))

;;; --- binary discovery -----------------------------------------------

(defun macos-bricscad-app-binary ()
  "On macOS, walk /Applications/BricsCAD* and return the first
.../Contents/MacOS/bricscad executable. Returns NIL if no
installation is found."
  (let ((apps (sort (directory "/Applications/BricsCAD*.app/")
                    #'string>
                    :key #'namestring)))
    (loop for app in apps
          for exe = (merge-pathnames "Contents/MacOS/bricscad" app)
          when (probe-file exe)
            do (return (namestring (truename exe))))))

(defun linux-bricscad-candidates ()
  "Linux candidates in priority order."
  (append
   (when (probe-file "/opt/bricsys/")
     (sort (mapcar #'namestring
                   (directory "/opt/bricsys/bricscad/V*/bricscad"))
           #'string>))
   (list "/opt/bricsys/bricscad/bricscad")))

(defun windows-bricscad-candidates ()
  "Windows candidates in priority order (descending version)."
  (sort (append
         (windows-glob-existing-files '("Bricsys/*/bricscad.exe"))
         ;; Keep the MSYS/MinGW-style /c fallback for compatibility
         ;; with Unix-like Windows runtimes that do expose that view.
         (mapcar #'namestring
                 (directory "/c/Program Files*/Bricsys/*/bricscad.exe")))
        #'string>))

(defun discover-bricscad-binary (&key
                                   (os (host-os)))
  "Run the platform-aware binary search documented in the issue.
Returns the absolute path of a usable bricscad executable, or NIL."
  (or (env-binary "BRICSCAD_EXE")
      (cond
        ((eq os :macos)   (macos-bricscad-app-binary))
        ((eq os :linux)   (first-existing (linux-bricscad-candidates)))
        ((eq os :windows) (first-existing (windows-bricscad-candidates)))
        (t nil))))

(defun discover-bricscad-template (&key requested)
  "Resolve the template DWG/DWT to launch BricsCAD with. REQUESTED,
when non-NIL, comes from --dwg / $AUTOLISP_DWG and takes priority.
Falls back to $AUTOLISP_BRICSCAD_TEMPLATE, then the macOS-default
~/Library/Application Support/Bricsys/.../Default-mm.dwt path, and
finally NIL (the backend will launch without an explicit template)."
  (or (and requested
           (probe-file requested)
           (namestring (truename requested)))
      (env-binary "AUTOLISP_BRICSCAD_TEMPLATE")
      (env-binary "AUTOLISP_DWG")
      (first-existing
       (mapcar (lambda (p) (uiop:native-namestring p))
               (list "~/Library/Application Support/Bricsys/BricsCAD/V26x64/en_US/Templates/Default-mm.dwt"
                     "~/Library/Application Support/Bricsys/BricsCAD/V26x64/en_US/Templates/Default-m.dwt"
                     "/Library/Application Support/Bricsys/BricsCAD/V26x64/Templates/Default-mm.dwt")))))

(defun discover-bricscad-profile ()
  "Resolve the BricsCAD user profile to launch with (the /p or -P switch).
Named by $AUTOLISP_BRICSCAD_PROFILE (or $BRICSCAD_PROFILE); NIL means
launch with the default/last-used profile.

This matters because on this runner the DEFAULT profile has the EPURE /
SCHMS+ vertical application loaded (its ribbon shows even for a bare
bricscad.exe), and that on-startup app-load blocks the /b script. A
pure-CAD run must therefore name a CLEAN profile explicitly (e.g. the
unnamed \"<<Profil sans nom>>\") rather than trust the default."
  (let ((p (or (uiop:getenv "AUTOLISP_BRICSCAD_PROFILE")
               (uiop:getenv "BRICSCAD_PROFILE"))))
    (if (and p (plusp (length p))) p nil)))

;;; --- DETECT --------------------------------------------------------

(defmethod detect ((backend bricscad-backend) &key)
  (let ((binary (discover-bricscad-binary)))
    ;; Automation mode on macOS/Windows can sometimes proceed without
    ;; a CLI binary (the OS bridge handles launching), but for V1 we
    ;; require the binary so DETECT has a concrete artefact to surface.
    (unless binary
      (error 'backend-not-available
             :backend :bricscad
             :code :no-binary
             :message
             "BricsCAD binary not found. Set $BRICSCAD_EXE or install BricsCAD."
             :details
             (list :probed
                   (list (uiop:getenv "BRICSCAD_EXE")
                         (cond ((macos-p)   "/Applications/BricsCAD*.app")
                               ((linux-p)   "/opt/bricsys/bricscad/V*/bricscad")
                               ((windows-p) "/c/Program Files*/Bricsys/*/bricscad.exe"))))))
    (setf (bricscad-backend-executable-path backend) binary
          (bricscad-backend-template-path backend)
          (discover-bricscad-template)
          (bricscad-backend-profile backend)
          (discover-bricscad-profile))
    backend))

;;; --- emitter: run.scr (batch mode) --------------------------------

(defun emit-run-scr (workdir runtime-load-path
                     &key (quit-on-finish-p t))
  "Write WORKDIR/run.scr — the SCR script BricsCAD runs in batch
(-B) mode. The script loads run-common.lsp (which itself loads the
autolisp-remote-io runtime) and, when QUIT-ON-FINISH-P is true,
disables FILEDIA and issues _QUIT _N so the engine doesn't hang
on a save-changes dialog.

Returns the path of the emitted file."
  (let* ((path (merge-pathnames "run.scr" workdir))
         (marker (namestring (merge-pathnames "run-scr-started.txt" workdir)))
         (text (with-output-to-string (out)
                 ;; Prove the script actually ran: drop a marker file as the
                 ;; very first action. If run-scr-started.txt exists in a kept
                 ;; workdir but debug.log is empty, the (load) is the problem;
                 ;; if the marker is ALSO absent, the -B/​/b script switch never
                 ;; fired the script at all.
                 (format out "(setq alfe-scr-mark (open ~S \"w\"))~%" marker)
                 (format out "(if alfe-scr-mark (progn (write-line \"run.scr executing\" alfe-scr-mark) (close alfe-scr-mark)))~%")
                 ;; Disable the LISP load-security prompt before the load:
                 ;; the runtime lives in a temp workdir, which SECURELOAD>0
                 ;; would otherwise block with a modal "load unsigned file?"
                 ;; dialog. SECURELOAD is a system variable (not a LISP atom),
                 ;; so probe it via getvar; vl-catch-all-apply keeps a host
                 ;; that rejects the sysvar from aborting the script.
                 (format out "(if (getvar \"SECURELOAD\") (vl-catch-all-apply 'setvar '(\"SECURELOAD\" 0)))~%")
                 (format out "(load ~S)~%"
                         (namestring (truename runtime-load-path)))
                 (when quit-on-finish-p
                   ;; The trailing space-then-newline on FILEDIA is
                   ;; intentional — BricsCAD's SCR parser treats the
                   ;; newline as the command terminator.
                   (format out "._FILEDIA 0~%")
                   (format out "._QUIT _N~%")))))
    (with-open-file (out path :direction :output
                              :if-exists :supersede
                              :if-does-not-exist :create
                              :external-format :utf-8)
      (write-string text out))
    path))

;;; --- emitter: bridge-bricscad.vbs (Windows automation) ------------

(defparameter *bridge-bricscad-vbs-template*
  ";; BricsCAD COM bridge — emitted by alfe.backend.bricscad
;; The placeholders ${RUNLSPFILE}, ${STATUSFILE}, ${ERRFILE},
;; ${COMMODE}, ${DEBUGFILE} are substituted by EMIT-BRIDGE-VBS.

Option Explicit
Dim fso, app, doc, runFile, statusFile, errFile, commode, debugFile
Dim attached, created, rc

Set fso = CreateObject(\"Scripting.FileSystemObject\")
runFile     = \"${RUNLSPFILE}\"
statusFile  = \"${STATUSFILE}\"
errFile     = \"${ERRFILE}\"
commode     = \"${COMMODE}\"
debugFile   = \"${DEBUGFILE}\"

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

attached = False
created  = False

VBSDebug \"bridge start; commode=\" & commode

If commode = \"attach\" Or commode = \"auto\" Then
  On Error Resume Next
  Set app = GetObject(, \"BricscadApp.AcadApplication\")
  If Err.Number = 0 And Not (app Is Nothing) Then attached = True
  VBSDebug \"GetObject attach: Err=\" & Err.Number & \" attached=\" & attached
  Err.Clear
  On Error GoTo 0
End If

If app Is Nothing Then
  If commode = \"attach\" Then
    AppendLine errFile, \"ERROR COM bridge: no running BricsCAD to attach to.\"
    EmitFlags False, False
    WScript.Quit 4
  End If
  VBSDebug \"CreateObject BricscadApp.AcadApplication ...\"
  On Error Resume Next
  Set app = CreateObject(\"BricscadApp.AcadApplication\")
  If Err.Number <> 0 Then
    AppendLine errFile, \"ERROR COM bridge: could not launch BricsCAD: \" & Err.Description
    VBSDebug \"CreateObject FAILED: \" & Err.Description & \"; quit 4\"
    EmitFlags False, False
    WScript.Quit 4
  End If
  Err.Clear
  On Error GoTo 0
  created = True
  VBSDebug \"CreateObject ok\"
End If

app.Visible = True
EmitFlags attached, created

On Error Resume Next
VBSDebug \"app.Name=\" & app.Name & \" ver=\" & app.Version & \" docs=\" & app.Documents.Count
Err.Clear
On Error GoTo 0

If app.Documents.Count = 0 Then
  VBSDebug \"no document; Documents.Add\"
  Call app.Documents.Add(\"\")
End If
Set doc = app.ActiveDocument

' Give a freshly-created BricsCAD a moment to finish initialising its
' document/command context before pushing a command at it; a SendCommand
' issued too early can be silently dropped.
If created Then WScript.Sleep 3000

' Disable the LISP load-security prompt for this session: the runtime
' lives in a temp workdir, which SECURELOAD>0 would block with a modal
' \"load unsigned file?\" dialog -- and a modal dialog leaves the (load)
' never running, exactly the observed \"stuck at BOOTING\" symptom.
On Error Resume Next
Call doc.SendCommand(\"(setvar \"\"SECURELOAD\"\" 0) \")
VBSDebug \"SECURELOAD 0 dispatched: Err=\" & Err.Number
Err.Clear
On Error GoTo 0

Dim cmd
cmd = \"(load \"\"\" & Replace(runFile, \"\\\", \"/\") & \"\"\") \"
VBSDebug \"SendCommand load: \" & cmd
On Error Resume Next
Call doc.SendCommand(cmd)
If Err.Number <> 0 Then
  AppendLine errFile, \"ERROR COM bridge: SendCommand failed: \" & Err.Description
  VBSDebug \"SendCommand load FAILED: \" & Err.Description & \"; quit 4\"
  WScript.Quit 4
End If
On Error GoTo 0
VBSDebug \"load dispatched; handing off to alfe poller; quit 0\"

' The runtime publishes its own status; the VBS exits as soon as it
' has dispatched the load. The alfe-side poller takes over.
WScript.Quit 0
"
  "VBScript template for the Windows COM bridge. Placeholders are
substituted by EMIT-BRIDGE-VBS at emit time.")

(defun substitute-placeholders (template alist)
  "Substitute every ${KEY} occurrence in TEMPLATE with the matching
value from ALIST. Cheap one-pass replacement; placeholders that
don't appear in ALIST are left as-is so the caller can spot
unfilled slots in tests."
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
                             (com-mode "auto"))
  "Write the BricsCAD VBScript bridge to PATH, with placeholders
substituted from the provided session paths."
  (let ((text (substitute-placeholders
               *bridge-bricscad-vbs-template*
               `(("RUNLSPFILE"  . ,(namestring runtime-load-path))
                 ("STATUSFILE"  . ,(namestring status-path))
                 ("ERRFILE"     . ,(namestring error-path))
                 ("COMMODE"     . ,com-mode)
                 ("DEBUGFILE"   . ,(if debug-path (namestring debug-path) ""))))))
    (with-open-file (out path :direction :output
                              :if-exists :supersede
                              :if-does-not-exist :create
                              :external-format :utf-8)
      (write-string text out))
    path))

;;; --- emitter: launcher.applescript (macOS automation) ------------

(defparameter *bricscad-applescript-template*
  "-- BricsCAD macOS automation launcher — emitted by alfe.backend.bricscad

set runLspFile to \"${RUNLSPFILE}\"

tell application \"System Events\"
  set running to exists (processes whose name is \"bricscad\")
end tell

if not running then
  tell application \"BricsCAD\" to activate
  delay 2.0
end if

tell application \"System Events\"
  tell process \"bricscad\"
    set frontmost to true
  end tell
end tell

tell application \"System Events\"
  keystroke \"(load \\\"\" & runLspFile & \"\\\")\"
  key code 36 -- Return
end tell
"
  "AppleScript template for macOS automation. Injects (load
runLspFile) into BricsCAD's command-line via System Events
keystrokes — requires Accessibility permission for the running
shell process.")

(defun emit-launcher-applescript (path &key runtime-load-path)
  "Write the macOS AppleScript launcher to PATH."
  (let ((text (substitute-placeholders
               *bricscad-applescript-template*
               `(("RUNLSPFILE" . ,(namestring runtime-load-path))))))
    (with-open-file (out path :direction :output
                              :if-exists :supersede
                              :if-does-not-exist :create
                              :external-format :utf-8)
      (write-string text out))
    path))

;;; --- launch argv ---------------------------------------------------

(defun choose-effective-mode (backend cli-mode)
  "Translate the CLI's :auto / :batch / :automation into the
backend's variant slot. :auto picks :batch on every platform when the
CLI binary is found, else :automation.

Windows batch is `bricscad.exe -B run.scr` — the same GUI-exe + script
mechanism macOS/Linux use, which is simpler and far more robust than the
COM/VBScript bridge (no SendCommand timing, no modal security/startup
dialogs silently swallowing the (load)). The VBScript automation path
remains available via an explicit --mode automation."
  (case cli-mode
    (:auto
     (if (bricscad-backend-executable-path backend) :batch :automation))
    ((:batch :automation) cli-mode)))

(defun build-launch-argv (backend protocol-session
                          &key (mode :auto))
  "Return the argv list to launch the BricsCAD engine for SESSION
under MODE. The returned list has the binary in CAR; the caller
typically hands it to UIOP:LAUNCH-PROGRAM."
  (let ((variant (choose-effective-mode backend mode))
        (binary  (bricscad-backend-executable-path backend))
        (workdir (alfe.protocol.file:protocol-session-workdir protocol-session)))
    (case variant
      (:batch
       (let ((scr (merge-pathnames "run.scr" workdir))
             (template (bricscad-backend-template-path backend))
             (profile (bricscad-backend-profile backend)))
         (append (list binary)
                 (when template (list (namestring template)))
                 ;; User profile: the /p (Windows) or -P (Unix) switch. This
                 ;; is how a pure-CAD run avoids the runner's default profile
                 ;; auto-loading a heavy vertical application (EPURE/SCHMS+),
                 ;; whose on-startup load runs on the single LISP/UI thread
                 ;; and blocks the /b script from ever running (the "stuck at
                 ;; BOOTING, run.scr never executes" symptom). Point it at a
                 ;; clean profile with an empty Startup Suite.
                 (when profile (list (if (windows-p) "/p" "-P") profile))
                 ;; Script switch is platform-specific: Unix builds take
                 ;; -B, the Windows (AutoCAD-lineage) CLI takes /b. Passing
                 ;; -B on Windows opens the GUI but silently ignores the
                 ;; script -- the "drawing shows but run.scr never runs,
                 ;; stuck at BOOTING" symptom.
                 (list (if (windows-p) "/b" "-B") (namestring scr)))))
      (:automation
       (cond
         ((windows-p)
          (list "cscript" "//nologo"
                (namestring (merge-pathnames "bridge-bricscad.vbs" workdir))))
         ((macos-p)
          (list "osascript"
                (namestring (merge-pathnames "launcher.applescript" workdir))))
         (t
          (error 'backend-not-available
                 :backend :bricscad
                 :code :no-automation
                 :message "BricsCAD automation mode is not supported on this OS.")))))))

;;; --- session subclass + START-ENGINE ------------------------------

(defstruct (bricscad-session
            (:include session)
            (:constructor %make-bricscad-session)
            (:copier nil))
  "Live state of a BricsCAD-driven session. Carries the underlying
file-protocol session plus the launched engine's PROCESS-INFO so
SHUTDOWN can terminate it."
  (protocol-session nil)
  (process-info     nil)
  (variant          nil))

(defmethod prepare-workdir ((backend bricscad-backend) workdir-root &key)
  (let ((workdir (if workdir-root
                     (uiop:ensure-directory-pathname workdir-root)
                     (make-fresh-workdir :bricscad))))
    (ensure-directories-exist workdir)
    workdir))

(defmethod start-engine ((backend bricscad-backend) workdir
                         &key dialect host mock-input bootstrap-phase
                              interactive-p
                              dwg
                              load-encoding
                              io-encoding
                              cli-options version-text
                              (mode :auto)
                              (launcher #'uiop:launch-program)
                              (wait-for-ready t)
                              (ready-timeout 30))
  "Build the file-protocol session, emit the launch artefacts
(run.scr / bridge-bricscad.vbs / launcher.applescript), spawn the
engine via LAUNCHER, and wait for the runtime to publish READY 0.

The :launcher knob lets the test suite substitute a thread-based
mock CAD for the real engine; the production code path passes
UIOP:LAUNCH-PROGRAM. WAIT-FOR-READY can be turned off when the
test driver is responsible for the state walk.

LOAD-ENCODING is accepted for protocol compatibility but ignored:
the BricsCAD-resident AutoLISP runtime owns the source-file
encoding policy; user `-e ENC' over the file-IPC protocol is a
future ticket."
  ;; DIALECT is currently irrelevant on the CAD side: the AutoLISP
  ;; dialect lives inside the CAD engine and is not swappable from
  ;; outside. HOST is meaningful only to clautolisp.
  (declare (ignore host mock-input dialect dwg load-encoding io-encoding))
  (log-verbose "backend BRICSCAD: starting engine (mode ~A)" mode)
  (log-debug "backend BRICSCAD: workdir = ~A" workdir)
  ;; Let --timeout / $AUTOLISP_WAIT_SECS raise the READY timeout: a cold
  ;; BricsCAD launch (COM start + license + first document) can take well
  ;; over the 30 s default, which otherwise reports a spurious
  ;; READY-TIMEOUT while the engine is still booting.
  (when (and cli-options (alfe.cli:cli-options-timeout cli-options))
    (setf ready-timeout (alfe.cli:cli-options-timeout cli-options)))
  (log-debug "backend BRICSCAD: ready-timeout = ~A s; wait-for-ready = ~A"
             ready-timeout wait-for-ready)
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
                :backend-name "BRICSCAD")))
        ;; G2: how the drain decodes BricsCAD's console output. :AUTO
        ;; (default) keeps the robust cascade — behaviour-preserving.
        (setf (alfe.protocol.file:protocol-session-console-encoding protocol)
              (alfe.cli:resolved-console-encoding cli-options))
        (cond
          (staged-bootstrap
           (log-debug "backend BRICSCAD: staged bootstrap -> ~A" staged-bootstrap))
          (bootstrap-source
           (log-warn "backend BRICSCAD: bootstrap source ~A resolved but staging returned NIL"
                     bootstrap-source))
          (t
           (log-warn "backend BRICSCAD: no bootstrap LSP found; set $ALFE_BOOTSTRAP_LSP or install autolisp-bootstrap.lsp")))
        (cond
          (staged-runtime
           (log-debug "backend BRICSCAD: staged runtime -> ~A" staged-runtime))
          (runtime-source
           (log-warn "backend BRICSCAD: runtime source ~A resolved but staging returned NIL"
                     runtime-source))
          (t
           (log-warn "backend BRICSCAD: no runtime LSP found; set $ALFE_RUNTIME_LSP or install autolisp-remote-io.lsp")))
        (log-debug "backend BRICSCAD: emitted run-common.lsp -> ~A" run-common)
        (log-debug "backend BRICSCAD: protocol status file -> ~A"
                   (alfe.protocol.file:protocol-session-status-path protocol))
        ;; Emit the engine-side launcher in the right shape.
        (let ((variant (choose-effective-mode backend mode)))
          (log-verbose "backend BRICSCAD: effective mode = ~A" variant)
          (case variant
            (:batch
             (let ((scr (emit-run-scr workdir run-common
                                      :quit-on-finish-p (not interactive-p))))
               (log-debug "backend BRICSCAD: wrote run.scr (quit-on-finish-p ~A) -> ~A"
                          (not interactive-p) scr)))
            (:automation
             (cond
               ((windows-p)
                (let ((vbs (merge-pathnames "bridge-bricscad.vbs" workdir)))
                  (emit-bridge-vbs
                   vbs
                   :runtime-load-path run-common
                   :status-path (alfe.protocol.file:protocol-session-status-path protocol)
                   :error-path  (alfe.protocol.file:protocol-session-stderr-path protocol)
                   ;; Always trace the COM bridge into the workdir. Under
                   ;; --keep-workdir this file survives and shows exactly
                   ;; how far the bridge got (attach vs create, doc count,
                   ;; whether SendCommand was dispatched) -- the missing
                   ;; piece when BricsCAD sits at BOOTING and never runs
                   ;; run-common.lsp.
                   :debug-path  (merge-pathnames "bridge-vbs.log" workdir)
                   :com-mode    (or (uiop:getenv "BRICSCAD_COM_MODE") "auto"))
                  (log-debug "backend BRICSCAD: wrote bridge-bricscad.vbs -> ~A" vbs)))
               ((macos-p)
                (let ((apl (merge-pathnames "launcher.applescript" workdir)))
                  (emit-launcher-applescript apl :runtime-load-path run-common)
                  (log-debug "backend BRICSCAD: wrote launcher.applescript -> ~A" apl))))))
          (let ((argv (build-launch-argv backend protocol :mode mode))
                (session (%make-bricscad-session
                          :backend backend
                          :workdir workdir
                          :request-timeout (and cli-options
                                                (alfe.cli:cli-options-timeout
                                                 cli-options))
                          :protocol-session protocol
                          :variant variant)))
            (log-verbose "backend BRICSCAD: launching: ~{~A~^ ~}" argv)
            (let ((process-info
                    (when launcher
                      (funcall launcher argv
                               :input :stream
                               :output :stream
                               :error-output :stream))))
              (when process-info
                (log-debug "backend BRICSCAD: spawned, process-info-pid = ~A"
                           (ignore-errors (uiop:process-info-pid process-info))))
              (setf (bricscad-session-process-info session) process-info))
            ;; From here on the engine is spawned. If we exit abnormally
            ;; (e.g. READY-timeout signals below), the error unwinds past the
            ;; caller's SESSION binding, so its SHUTDOWN never runs and the
            ;; launched engine is orphaned -- the "BricsCAD left spinning
            ;; after the job" symptom. In batch mode process-info IS the
            ;; bricscad.exe, so terminate it ourselves on any abnormal exit;
            ;; on success it is left running and handed to the session for
            ;; the normal QUIT/shutdown path.
            (let ((started-ok nil))
              (unwind-protect
                  (progn
                    (when wait-for-ready
                      (log-verbose "backend BRICSCAD: waiting for READY (timeout ~A s)"
                                   ready-timeout)
                      (multiple-value-bind (ok elapsed last)
                          (alfe.protocol.file:wait-for-status-prefix
                           protocol "READY" :timeout ready-timeout)
                        (cond
                          (ok
                           (log-verbose "backend BRICSCAD: READY after ~,2F s (status ~S)"
                                        elapsed last))
                          (t
                           (log-warn "backend BRICSCAD: READY timeout after ~,2F s; last status = ~S"
                                     elapsed last)
                           (error 'backend-bootstrap-error
                                  :backend :bricscad
                                  :code :ready-timeout
                                  :message
                                  (format nil
                                          "BricsCAD did not reach READY within ~A s (last status: ~S)."
                                          ready-timeout last)
                                  :details (list :workdir workdir
                                                 :last-status last))))))
                    (session-state-set session :ready)
                    (setq started-ok t)
                    session)
                (unless started-ok
                  (let ((info (bricscad-session-process-info session)))
                    (when info
                      (ignore-errors
                        (log-warn "backend BRICSCAD: start aborted; terminating spawned engine (pid ~A)"
                                  (ignore-errors (uiop:process-info-pid info))))
                      (%kill-engine-process info)))))))))
    (alfe.error:backend-error (probe)
      (error probe))
    (error (probe)
      (error 'backend-bootstrap-error
             :backend :bricscad
             :code :bootstrap-failed
             :message (format nil "BricsCAD start-engine failed: ~A" probe)
             :details (list :origin probe)))))

;;; --- EVAL-PLAN ----------------------------------------------------

(defmethod eval-plan ((session bricscad-session) plan)
  (session-state-set session :running)
  (let* ((explicit-timeout (session-request-timeout session))
         (result (drive-protocol-actions
                  (bricscad-session-protocol-session session)
                  plan
                  ;; --timeout / $AUTOLISP_WAIT_SECS reaches the DONE wait.
                  ;; An explicit value is a hard cap (keep-alive off); the
                  ;; default keeps a RUNNING eval alive while BricsCAD lives
                  ;; (alfe-request-timeout-aborts-long-eval).
                  :request-timeout (or explicit-timeout 30)
                  :keep-alive-while-running (null explicit-timeout)
                  :process-info (bricscad-session-process-info session))))
    (session-state-set session
                       (ecase (alfe.backend:eval-result-status result)
                         (:success :done)
                         (:failed  :done)
                         (:aborted :failed)))
    result))

;;; --- READ-OUTPUT / SEND-INPUT / REQUEST-CONTROL -------------------

(defmethod read-output ((session bricscad-session) &key timeout)
  (declare (ignore timeout))
  (let ((protocol (bricscad-session-protocol-session session)))
    (values (alfe.protocol.file:drain-stdout protocol)
            (alfe.protocol.file:drain-stderr protocol))))

(defmethod send-input ((session bricscad-session) text)
  (alfe.protocol.file:send-stdin
   (bricscad-session-protocol-session session) text))

(defmethod request-control ((session bricscad-session) command)
  (alfe.protocol.file:send-control
   (bricscad-session-protocol-session session) command)
  (case command
    (:ping       :pong)
    (:shutdown   :stopped)
    (:interrupt  :interrupted)))

(defun %kill-engine-process (info &key (timeout 6))
  "Best-effort terminate the launched engine within TIMEOUT seconds, NEVER
blocking indefinitely. uiop:wait-process can hang on Windows when the engine
(a GUI BricsCAD) is slow to die or a child shares its handles -- that would
freeze alfe in shutdown and hang the whole job. So we terminate, then POLL
process-alive-p up to TIMEOUT, force-killing (:urgent) if it outlives that,
and never issue an unbounded wait. On exit the OS reaps it."
  (when info
    (ignore-errors
     (when (uiop:process-alive-p info) (uiop:terminate-process info)))
    (let ((start (get-internal-real-time)))
      (loop while (and (ignore-errors (uiop:process-alive-p info))
                       (< (/ (float (- (get-internal-real-time) start))
                             internal-time-units-per-second)
                          timeout))
            do (sleep 0.2)))
    (ignore-errors
     (when (uiop:process-alive-p info)
       (uiop:terminate-process info :urgent t))))
  nil)

(defmethod shutdown ((session bricscad-session) &key reason)
  (declare (ignore reason))
  (unless (eq (session-state session) :stopped)
    (let ((protocol (bricscad-session-protocol-session session))
          (info (bricscad-session-process-info session)))
      (ignore-errors (alfe.protocol.file:send-control protocol :shutdown))
      (ignore-errors
       (alfe.protocol.file:wait-for-status
        protocol alfe.protocol.file:+status-stopped+ :timeout 5))
      (%kill-engine-process info))
    (session-state-set session :stopped))
  session)

(defmethod cleanup-workdir ((backend bricscad-backend) workdir &key keep-p)
  (when workdir
    (remove-workdir workdir :keep-p keep-p))
  nil)

;;; --- registration -------------------------------------------------

(register-backend :bricscad (make-bricscad-backend :variant :auto))
