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
;;;;     bricscad.exe /Automation <template> [/p <profile>] /b WORKDIR/run.scr
;;;;     Same GUI-exe + script mechanism as macOS/Linux — no COM. NB the
;;;;     Windows CLI takes /p and /b (AutoCAD-lineage), not the Unix -P/-B.
;;;;     /Automation is a BricsCAD executable switch that starts it with the
;;;;     main frame window HIDDEN (Bricsys Startup options doc); it combines
;;;;     with /B and does NOT mean ALFE's COM `--mode automation' backend —
;;;;     the direct /b file-protocol still drives the run. Windows only.
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
                #:drive-protocol-actions
                ;; READY-wait launcher liveness. This package :USEs only CL,
                ;; so exporting these from cad-common is not enough — an
                ;; un-imported name reads as an internal
                ;; ALFE.BACKEND.BRICSCAD:: symbol and every launch dies with
                ;; an undefined-function error at RUNTIME (compile-time it is
                ;; a mere style warning).
                #:launcher-alive-or-clean-p
                #:launcher-failure-details
                #:launcher-state-description
                #:kill-engine-process
                #:launcher-exit-code)
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
           #:macos-app-bundle-for
           #:build-launch-argv
           #:discover-bricscad-binary
           #:discover-bricscad-template
           #:bundle-template-candidates
           #:cui-file-corrupt-p
           #:quarantine-corrupt-bricscad-cui))

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

(defun bundle-template-candidates (executable-path)
  "The templates shipped INSIDE a macOS BricsCAD bundle, best first.

BricsCAD keeps them at
  <bundle>/Contents/Resources/UserDataCache/Templates/<locale>/Default-m*.dwt
which the user-Library paths below do not cover: those name one locale
 (en_US) and one location, so a French install — where the templates are
=…/Templates/fr_FR/Default-m.dwt= — was invisible to discovery even
though the product ships a perfectly good blank drawing. The AutoCAD
backend has looked inside its own install (=UserDataCache/Template/…=)
all along; this is the same idea for the other vendor.

Ordering is deliberate rather than alphabetical:

- en_US first. A localised template carries localised layer and linetype
  names, and this drawing is the BASELINE of a vendor-divergence harness:
  anything the file contributes is noise in the measurement. Prefer the
  neutral one when the install has it, take what exists otherwise.
- =Default-mm.dwt= before =Default-m.dwt=, matching the existing
  preference below."
  (let ((bundle (and executable-path (macos-app-bundle-for executable-path))))
    (when bundle
      (let ((found (mapcar #'namestring
                           (directory
                            (merge-pathnames
                             "Contents/Resources/UserDataCache/Templates/*/Default-m*.dwt"
                             (uiop:ensure-directory-pathname bundle))))))
        (flet ((neutral-p (path) (and (search "/en_US/" path) t)))
          (sort found
                (lambda (a b)
                  (let ((na (neutral-p a))
                        (nb (neutral-p b)))
                    (cond ((and na (not nb)) t)
                          ((and nb (not na)) nil)
                          ;; "Default-mm.dwt" > "Default-m.dwt" under
                          ;; STRING>, which is the preference we want.
                          (t (string> a b)))))))))))

(defun discover-bricscad-template (&key requested executable-path)
  "Resolve the template DWG/DWT to launch BricsCAD with. REQUESTED,
when non-NIL, comes from --dwg / $AUTOLISP_DWG and takes priority.
Falls back to $AUTOLISP_BRICSCAD_TEMPLATE, then the macOS-default
~/Library/Application Support/Bricsys/.../Default-mm.dwt path, then a
template shipped inside the application bundle (EXECUTABLE-PATH is what
locates it), and finally NIL (the backend will launch without an
explicit template).

$AUTOLISP_BRICSCAD_TEMPLATE is the zero-code answer when a machine wants
a specific blank drawing: point it at any .dwt/.dwg and nothing here
needs to change. That is preferable to copying a vendor template to a
fixed name, and far preferable to committing one — a .dwg is a vendor
binary bound to a format version (see libredwg-empty-dwg-write-invalid)."
  (or (and requested
           (probe-file requested)
           (namestring (truename requested)))
      (env-binary "AUTOLISP_BRICSCAD_TEMPLATE")
      (env-binary "AUTOLISP_DWG")
      (first-existing
       (mapcar (lambda (p) (uiop:native-namestring p))
               (list "~/Library/Application Support/Bricsys/BricsCAD/V26x64/en_US/Templates/Default-mm.dwt"
                     "~/Library/Application Support/Bricsys/BricsCAD/V26x64/en_US/Templates/Default-m.dwt"
                     "/Library/Application Support/Bricsys/BricsCAD/V26x64/Templates/Default-mm.dwt")))
      (first-existing (bundle-template-candidates executable-path))))

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
          (discover-bricscad-template :executable-path binary)
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
  ;; A VBScript comment is an apostrophe (or REM), NEVER `;;' — see the
  ;; note on the AutoCAD template. Same defect, same file position: it is
  ;; a syntax error at line 1. Kept ASCII because cscript reads a .vbs as
  ;; ANSI unless it carries a BOM, and this one is written UTF-8 without.
  "' BricsCAD COM bridge - emitted by alfe.backend.bricscad
' The placeholders ${RUNLSPFILE}, ${STATUSFILE}, ${ERRFILE},
' ${COMMODE}, ${DEBUGFILE} are substituted by EMIT-BRIDGE-VBS.

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
' app/doc MUST be object references before any `Is Nothing` test: an
' unassigned Dim variable is Empty, and `Empty Is Nothing` raises the
' runtime error 424 \"Object required\". A failed GetObject leaves app
' unassigned, so without this the attach-miss path dies at `If app Is
' Nothing` instead of falling through to CreateObject.
Set app = Nothing
Set doc = Nothing

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

(defun substitute-placeholders (template alist &key (escape #'vbs-escape))
  "Substitute every ${KEY} occurrence in TEMPLATE with the matching
value from ALIST. Cheap one-pass replacement; placeholders that
don't appear in ALIST are left as-is so the caller can spot
unfilled slots in tests.

ESCAPE is applied to each value on the way in. It defaults to
VBS-ESCAPE because the first template here was the VBScript bridge,
where a literal quote must be doubled. Callers whose template is NOT
VBScript must pass their own (or #'IDENTITY and escape at the call
site): the AppleScript launcher injects a code fragment as well as
string literals, and doubling the quotes in
`do shell script \"open -a \" & quoted form of appPath'
turned it into the un-runnable `do shell script \"\"open -a \"\" & ...'."
  (let ((out template))
    (loop for (key . value) in alist
          do (setf out (uiop:frob-substrings
                        out (list (format nil "${~A}" key))
                        (funcall escape value))))
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
--
-- Types `(load \"<run-common.lsp>\")' into BricsCAD's command line with
-- synthetic keystrokes. That needs BOTH an interactive GUI session AND
-- Accessibility (TCC) permission for whatever process runs osascript; without
-- either, System Events raises an error and osascript exits non-zero. alfe
-- surfaces that exit code and stderr now instead of waiting out the READY
-- timeout (alfe-bricscad-automation-macos).

set runLspFile to \"${RUNLSPFILE}\"
set appPath to \"${APPPATH}\"
set docPath to \"${DOCPATH}\"

-- Launch-or-activate in one step. `open -a' is idempotent: it activates an
-- already-running copy rather than starting a second one, so no process-name
-- probing is needed.
--
-- The previous template did probe, and was wrong twice over: it wrote
-- `set running to exists (processes whose name is \"bricscad\")', but
-- `running' is a RESERVED AppleScript property term, and it then addressed
-- the app as `application \"BricsCAD\"' while the installed bundle is named
-- e.g. \"BricsCAD V26.app\". Either fault aborts the script before a single
-- keystroke is sent — which is exactly what the first macOS probe run saw:
-- status.txt stuck at BOOTING with empty stdout/stderr.
${LAUNCHCOMMAND}

-- Wait for BricsCAD to actually OWN THE KEYBOARD before typing, instead of
-- guessing with a fixed delay. `keystroke' has no target: it goes to whatever
-- is frontmost at that instant. If BricsCAD is still starting, the text lands
-- in the terminal that ran osascript and is silently lost — the script still
-- exits 0, so from alfe's side it looks exactly like success while status.txt
-- stays at BOOTING forever. That is what the 2026-08-01 macOS probe hit: a
-- clean run (Accessibility granted, `UI elements enabled' -> true, exit 0)
-- whose keystrokes never reached the CAD.
--
-- AppleScript's `contains' is case-insensitive, so this matches the process
-- whatever the bundle calls itself (\"BricsCAD\", \"bricscad\", \"BricsCAD V26\").
set frontApp to \"\"
set focused to false
repeat ${STARTUPWAIT} times
  try
    tell application \"System Events\"
      set frontApp to name of first application process whose frontmost is true
    end tell
    if frontApp contains \"bricscad\" then
      set focused to true
      exit repeat
    end if
  end try
  delay 1
end repeat

-- Record what actually had focus, so a failure says where the keystrokes went
-- rather than leaving us to guess.
try
  do shell script \"printf '%s\\\\n' \" & quoted form of (\"frontmost=\" & frontApp & \" focused=\" & (focused as text)) & \" > \" & quoted form of \"${FOCUSLOG}\"
end try

if not focused then
  -- Do NOT type into someone else's window. Exiting non-zero makes alfe abort
  -- the READY wait at once (LAUNCHER-FAILED) and report this message, instead
  -- of spending the whole timeout on a run that cannot succeed.
  error \"BricsCAD never became frontmost within ${STARTUPWAIT}s (frontmost was \\\"\" & frontApp & \"\\\"); refusing to send keystrokes to another application.\" number 1
end if

tell application \"System Events\"
  keystroke \"(load \\\"\" & runLspFile & \"\\\")\"
  key code 36 -- Return
end tell
"
  "AppleScript template for macOS automation. Injects (load
runLspFile) into BricsCAD's command line via System Events keystrokes —
requires an interactive session and Accessibility permission for the
process running osascript.")

(defun macos-app-bundle-for (executable-path)
  "The .app bundle enclosing EXECUTABLE-PATH — e.g.
/Applications/BricsCAD V26.app/Contents/MacOS/bricscad
-> /Applications/BricsCAD V26.app — or NIL when the path is not inside
a bundle. Needed because AppleScript must address the app by its real
bundle name, not by the unix binary's name."
  (when executable-path
    (let* ((path (uiop:ensure-directory-pathname
                  (make-pathname :name nil :type nil :version nil
                                 :defaults (pathname executable-path))))
           (components (pathname-directory path)))
      (let ((tail (member-if (lambda (component)
                               (and (stringp component)
                                    (let ((n (length component)))
                                      (and (> n 4)
                                           (string-equal ".app" component
                                                         :start2 (- n 4))))))
                             (reverse components))))
        (when tail
          ;; TAIL is the reversed list from the .app component down to :absolute;
          ;; re-reverse to rebuild the bundle's own directory pathname.
          (namestring
           (make-pathname :directory (reverse tail)
                          :name nil :type nil :version nil
                          :defaults path)))))))

(defun %applescript-launch-command (executable-path &optional template-path)
  "The `do shell script' line the launcher uses to bring BricsCAD up.
Prefers the enclosing .app bundle with `open -a' (the supported way to
launch a macOS GUI app); falls back to running the binary directly in
the background when the executable is not inside a bundle. AppleScript's
`quoted form of' does the shell quoting, so a path with spaces — the
normal case, \"BricsCAD V26.app\" — is safe.

When TEMPLATE-PATH is given it is opened WITH the app. That is not a
nicety: `keystroke' types into the frontmost window, and a BricsCAD with
no drawing open shows its Start page, which has no command line to
receive the text. The 2026-08-01 macOS probe proved the keystrokes were
reaching a focused BricsCAD (launcher-focus.txt said
`frontmost=bricscad focused=true', osascript exit 0) and still executing
nothing. The batch path never had this problem because it always passes
a template on the command line."
  (let ((bundle (macos-app-bundle-for executable-path)))
    (cond
      ((and bundle template-path)
       "do shell script \"open -a \" & quoted form of appPath & \" \" & quoted form of docPath")
      (bundle
       "do shell script \"open -a \" & quoted form of appPath")
      (t
       "do shell script quoted form of appPath & \" > /dev/null 2>&1 &\""))))

(defparameter +bricscad-applescript-startup-wait+ "60"
  "How many seconds the launcher waits for BricsCAD to become the
frontmost application before typing into it. This is a BOUND on a poll,
not a fixed sleep: the script types as soon as the CAD has focus, and
gives up (non-zero, so alfe aborts at once) if it never does. A fixed
delay is unusable here — too short and the keystrokes go to the
terminal, too long and every run pays for it. Override with
$ALFE_BRICSCAD_STARTUP_DELAY.")

(defun emit-launcher-applescript (path &key runtime-load-path executable-path
                                            template-path)
  "Write the macOS AppleScript launcher to PATH. EXECUTABLE-PATH is the
discovered bricscad binary; the launcher addresses its enclosing .app
bundle (see MACOS-APP-BUNDLE-FOR) rather than guessing an app name.
TEMPLATE-PATH, when given, is opened with it so the CAD has a drawing —
and therefore a command line — to type into."
  (let* ((bundle (or (macos-app-bundle-for executable-path) executable-path ""))
         ;; :escape #'identity — this template is AppleScript, not VBScript.
         ;; The two path values are escaped here (they land inside AppleScript
         ;; string literals); LAUNCHCOMMAND is a code fragment and must go in
         ;; verbatim.
         (text (substitute-placeholders
                *bricscad-applescript-template*
                `(("RUNLSPFILE"    . ,(applescript-escape (namestring runtime-load-path)))
                  ("APPPATH"       . ,(applescript-escape (namestring bundle)))
                  ("DOCPATH"       . ,(applescript-escape
                                       (if template-path (namestring template-path) "")))
                  ("LAUNCHCOMMAND" . ,(%applescript-launch-command
                                       executable-path template-path))
                  ("STARTUPWAIT"   . ,(or (uiop:getenv "ALFE_BRICSCAD_STARTUP_DELAY")
                                          +bricscad-applescript-startup-wait+))
                  ("FOCUSLOG"      . ,(applescript-escape
                                       (namestring
                                        (merge-pathnames
                                         "launcher-focus.txt"
                                         (uiop:ensure-directory-pathname
                                          (make-pathname
                                           :name nil :type nil :version nil
                                           :defaults (pathname runtime-load-path))))))))
                :escape #'identity)))
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
remains available via an explicit --mode automation.

AUTOMATION IS WINDOWS-ONLY. pjb, 2026-08-14, taking option A of
alfe-bricscad-automation-macos: \"sur macos, les scripts ne marchent pas
en combinaison avec --automation\". The macOS route drove BricsCAD through
an AppleScript that types into the app; five rounds of CI eliminated five
hypotheses and found no working path, and the remaining ones cannot be
tested from a headless job. Rather than leave a mode that launches a CAD
and times out 240 s later, it now fails HERE — before anything is emitted
or spawned — with the same BACKEND-NOT-AVAILABLE :NO-AUTOMATION that
Linux has always given.

The refusal is in this function rather than in BUILD-LAUNCH-ARGV because
this is where the variant is decided, and both the emitter and the argv
builder come through here: putting it here is what makes the failure
immediate instead of arriving after launcher.applescript has been
written.

The AppleScript emitter, the Accessibility preflight and the launcher
state reporting are DELIBERATELY KEPT. They are what made the five
investigation rounds interpretable, and option B of the ticket — driving
the emitted launcher by hand at the machine — is still open."
  (let ((variant (case cli-mode
                   (:auto
                    (if (bricscad-backend-executable-path backend)
                        :batch
                        :automation))
                   ((:batch :automation) cli-mode))))
    (when (and (eq variant :automation) (not (windows-p)))
      (error 'backend-not-available
             :backend :bricscad
             :code :no-automation
             :message
             (if (eq cli-mode :automation)
                 "BricsCAD --mode automation is not supported on this OS (Windows only). Use --mode batch, which is the default when the BricsCAD CLI is found."
                 "BricsCAD CLI executable not found, and --mode automation is not supported on this OS (Windows only), so there is no fallback. Install BricsCAD or point alfe at it.")))
    variant))

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
                 ;; Windows-only: /Automation starts BricsCAD WITHOUT its main
                 ;; frame window. It is a BricsCAD executable startup switch
                 ;; (Bricsys "Startup options" doc), NOT ALFE's COM `--mode
                 ;; automation' backend — the direct /b file-protocol still
                 ;; drives the run. Bricsys documents it as combinable with /B
                 ;; and useful for non-COM batch; the loaded script must close
                 ;; BricsCAD on completion (run.scr already does). Not passed on
                 ;; macOS/Linux, where the switch does not exist. It precedes
                 ;; the template + /b pair, matching the documented example
                 ;; `bricscad.exe /automation /B <script.scr>'.
                 ;; See alfe-bricscad-batch-hidden-ui.issue.
                 (when (windows-p) (list "/Automation"))
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

;;; --- corrupt-CUI guard --------------------------------------------
;;;
;;; A corrupt per-user default.cui pops a modal at STARTUP -- "CUI File Error:
;;; ... invalid document structure" with a No/Yes "restore from a backup?"
;;; prompt -- BEFORE any command runs, so the `-'/`_'/`.' command prefixes
;;; can't help. On a headless/batch run that modal stalls the launch until it
;;; times out. The file is the WRITABLE user copy (a pristine template lives
;;; read-only in the app bundle), so if it is unreadable we quarantine it and
;;; BricsCAD regenerates a fresh one on the next launch.

(defun bricscad-user-cui-candidates ()
  "The writable per-user default.cui files BricsCAD loads at startup. Version-
and locale-specific (e.g. .../BricsCAD/V26x64/en_US/Support/default.cui), so
glob both levels."
  (let ((roots
          (cond
            ((macos-p)
             (let ((home (uiop:getenv "HOME")))
               (when home
                 (list (format nil "~A/Library/Application Support/Bricsys/BricsCAD/" home)))))
            ((windows-p)
             (let ((appdata (uiop:getenv "APPDATA")))
               (when appdata (list (format nil "~A/Bricsys/BricsCAD/" appdata)))))
            (t
             (let ((home (uiop:getenv "HOME")))
               (when home
                 (list (format nil "~A/.local/share/Bricsys/BricsCAD/" home))))))))
    (loop for root in (remove nil roots)
          append (ignore-errors
                  (directory (merge-pathnames "*/*/Support/default.cui"
                                              (uiop:ensure-directory-pathname root)))))))

(defun cui-file-corrupt-p (path)
  "True iff PATH exists but is empty or does not begin — after an optional
Unicode BOM and leading whitespace — with a `<' (0x3C) tag. The CUI is XML;
\"invalid document structure at line 1, char 1\" is exactly a file that does not
open with a tag. Read as OCTETS so a valid BOM-prefixed CUI (BricsCAD writes a
UTF-8 BOM `EF BB BF' before `<?xml' — the fr_FR default.cui does) is NOT
mistaken for garbage. An ABSENT file is not corrupt (BricsCAD creates it); an
unreadable file is left alone (NIL). Conservative on purpose — a false positive
renames the user's real customization aside."
  (ignore-errors
   (with-open-file (in path :direction :input
                            :element-type '(unsigned-byte 8)
                            :if-does-not-exist nil)
     (when in
       (let* ((buf (make-array 64 :element-type '(unsigned-byte 8)))
              (n (read-sequence buf in)))
         (if (zerop n)
             t                                     ; empty -> corrupt
             (let ((i 0))
               ;; Skip a leading BOM: UTF-8 (EF BB BF) or UTF-16 (FF FE / FE FF).
               (cond
                 ((and (>= n 3) (= (aref buf 0) #xEF) (= (aref buf 1) #xBB) (= (aref buf 2) #xBF))
                  (setf i 3))
                 ((and (>= n 2) (member (aref buf 0) '(#xFF #xFE)) (member (aref buf 1) '(#xFF #xFE)))
                  (setf i 2)))
               ;; Skip whitespace, incl. the UTF-16 zero bytes between chars.
               (loop while (and (< i n) (member (aref buf i) '(32 9 10 13 12 0)))
                     do (incf i))
               (cond
                 ((>= i n) t)                      ; BOM/whitespace only -> corrupt
                 ((= (aref buf i) #x3C) nil)       ; opens with `<' -> OK
                 (t t)))))))))                     ; some other byte -> corrupt

(defun quarantine-corrupt-bricscad-cui ()
  "Rename any corrupt per-user default.cui aside so BricsCAD regenerates a fresh
one from its bundled template instead of popping a startup modal that stalls a
batch launch. Renames (never deletes) and logs. Opt out with
$ALFE_NO_CUI_REPAIR. Returns the list of quarantined paths."
  (unless (let ((v (uiop:getenv "ALFE_NO_CUI_REPAIR"))) (and v (plusp (length v))))
    (loop for cui in (bricscad-user-cui-candidates)
          when (cui-file-corrupt-p cui)
            append (let ((aside (format nil "~A.corrupt-~D"
                                        (namestring cui) (get-universal-time))))
                     (handler-case
                         (progn
                           (rename-file cui (pathname aside))
                           (log-warn "backend BRICSCAD: quarantined corrupt CUI ~A -> ~A; BricsCAD will regenerate it"
                                     (namestring cui) (file-namestring aside))
                           (list cui))
                       (error (e)
                         (log-warn "backend BRICSCAD: corrupt CUI ~A could not be quarantined (~A); a startup modal may stall this run"
                                   (namestring cui) e)
                         nil))))))

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
  ;; A corrupt per-user default.cui pops a startup modal that stalls a batch
  ;; launch; quarantine it first so BricsCAD regenerates a clean one.
  (quarantine-corrupt-bricscad-cui)
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
                  (emit-launcher-applescript
                   apl :runtime-load-path run-common
                       :executable-path (bricscad-backend-executable-path backend)
                       ;; Open a drawing with the app: no document, no command
                       ;; line, nowhere for the keystrokes to land.
                       :template-path
                       (or (bricscad-backend-template-path backend)
                           (discover-bricscad-template
                            :executable-path
                            (bricscad-backend-executable-path backend))))
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
                           protocol "READY" :timeout ready-timeout
                           ;; A launcher that exits NON-ZERO before READY
                           ;; aborts the wait at once; one that exits 0 is a
                           ;; driver that finished its job (osascript after
                           ;; typing, cscript after SendCommand) and the wait
                           ;; continues. Without this the failure was silent:
                           ;; the whole timeout elapsed and the launcher's exit
                           ;; code and stderr — the actual diagnosis — were
                           ;; thrown away. See alfe-bricscad-automation-macos.
                           :alive-p
                           (let ((info (bricscad-session-process-info session)))
                             (when info
                               (lambda () (launcher-alive-or-clean-p info)))))
                        (cond
                          (ok
                           (log-verbose "backend BRICSCAD: READY after ~,2F s (status ~S)"
                                        elapsed last))
                          (t
                           (let ((failure (launcher-failure-details
                                           (bricscad-session-process-info session))))
                             (log-warn "backend BRICSCAD: READY ~:[timeout~;abort~] after ~,2F s; last status = ~S~@[ (~A)~]"
                                       failure elapsed last failure)
                             (error 'backend-bootstrap-error
                                    :backend :bricscad
                                    :code (if failure :launcher-failed :ready-timeout)
                                    :message
                                    (if failure
                                        (format nil
                                                "BricsCAD launch failed before READY: ~A (last status: ~S)."
                                                failure last)
                                        (format nil
                                                "BricsCAD did not reach READY within ~A s (last status: ~S~@[; ~A~])."
                                                ready-timeout last
                                                (launcher-state-description
                                                 (bricscad-session-process-info session))))
                                    :details (list :workdir workdir
                                                   :last-status last
                                                   :launcher-failure failure)))))))
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

;;; %KILL-ENGINE-PROCESS moved to backend-cad-common as KILL-ENGINE-PROCESS:
;;; the hazard it guards against (an unbounded wait-process on a GUI CAD
;;; that will not die) is not BricsCAD-specific, and AutoCAD had kept the
;;; unbounded `wait-process' this very code exists to avoid.
(defun %kill-engine-process (info &key (timeout 6))
  "Deprecated local name; see ALFE.BACKEND.CAD-COMMON:KILL-ENGINE-PROCESS."
  (kill-engine-process info :timeout timeout))

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
