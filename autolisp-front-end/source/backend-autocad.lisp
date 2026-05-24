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
                #:vbs-escape
                #:drive-protocol-actions)
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
  (sort (mapcar #'namestring
                (append
                 (directory "/c/Program Files/Autodesk/AutoCAD */acad.exe")
                 (directory "/c/Program Files/Autodesk/AutoCAD LT */acadlt.exe")))
        #'string>))

(defun windows-accoreconsole-candidates ()
  (sort (mapcar #'namestring
                (directory "/c/Program Files/Autodesk/*/accoreconsole.exe"))
        #'string>))

(defun discover-autocad-binary ()
  (or (env-binary "AUTOCAD_EXE")
      (when (windows-p)
        (first-existing (windows-acad-candidates)))))

(defun discover-accoreconsole-binary ()
  (or (env-binary "AUTOCAD_ACCORECONSOLE")
      (when (windows-p)
        (first-existing (windows-accoreconsole-candidates)))))

;;; --- DETECT --------------------------------------------------------

(defmethod detect ((backend autocad-backend) &key)
  (unless (windows-p)
    (error 'backend-not-available
           :backend :autocad
           :code :unsupported-os
           :message (unsupported-os-message)
           :details (list :os (host-os))))
  (let ((acad (discover-autocad-binary))
        (acc  (discover-accoreconsole-binary)))
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
  ";; AutoCAD COM bridge — emitted by alfe.backend.autocad
;; Placeholders: ${RUNLSPFILE}, ${STATUSFILE}, ${ERRFILE},
;; ${COMMODE}, ${DEBUGFILE}, ${WAIT_SECS}.
;; Mirrors the legacy bash wrapper's bridge-autocad.vbs; preserve
;; the WaitQuiescent + GetAcadState handshake — it's the hard-won
;; piece that keeps the bridge from racing AutoCAD's UI init.

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

' Don't call app.Quit here — the runtime publishes its own status
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
         (workdir (alfe.protocol.file:protocol-session-workdir protocol-session)))
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
         (unless dwg
           (error 'backend-bootstrap-error
                  :backend :autocad
                  :code :no-dwg
                  :message "Batch mode requires --dwg FILE (accoreconsole has no template default)."))
         (list acc "/i" (namestring dwg) "/s" (namestring scr)))))))

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
                              (mode :auto)
                              (dwg nil)
                              (launcher #'uiop:launch-program)
                              (wait-for-ready t)
                              (ready-timeout 60))
  ;; LOAD-ENCODING accepted but ignored: the AutoCAD-resident
  ;; AutoLISP runtime owns the source-file encoding policy.
  (declare (ignore dialect host mock-input load-encoding))
  (handler-case
      (let* ((protocol (alfe.protocol.file:init-session workdir))
             (run-common
               (alfe.protocol.file:emit-run-common-lsp
                protocol
                :bootstrap-phase bootstrap-phase
                :use-remote-protocol-p t
                :quit-on-finish-p (not interactive-p)))
             (variant (choose-effective-mode backend mode)))
        (case variant
          (:automation
           (emit-bridge-vbs
            (merge-pathnames "bridge-autocad.vbs" workdir)
            :runtime-load-path run-common
            :status-path (alfe.protocol.file:protocol-session-status-path protocol)
            :error-path  (alfe.protocol.file:protocol-session-stderr-path protocol)
            :com-mode    (or (uiop:getenv "AUTOCAD_COM_MODE") "auto")))
          (:batch
           (emit-batch-scr
            (merge-pathnames "run.scr" workdir) run-common)))
        (let* ((argv (build-launch-argv backend protocol :mode mode :dwg dwg))
               (session (%make-autocad-session
                         :backend backend
                         :workdir workdir
                         :protocol-session protocol
                         :variant variant))
               (process-info
                 (when launcher
                   (funcall launcher argv
                            :input :stream
                            :output :stream
                            :error-output :stream))))
          (setf (autocad-session-process-info session) process-info)
          (when wait-for-ready
            (multiple-value-bind (ok elapsed last)
                (alfe.protocol.file:wait-for-status-prefix
                 protocol "READY" :timeout ready-timeout)
              (declare (ignore elapsed))
              (unless ok
                (error 'backend-bootstrap-error
                       :backend :autocad
                       :code :ready-timeout
                       :message
                       (format nil "AutoCAD did not reach READY within ~A s (last: ~S)."
                               ready-timeout last)
                       :details (list :workdir workdir :last-status last)))))
          (session-state-set session :ready)
          session))
    (alfe.error:backend-error (probe)
      (error probe))
    (error (probe)
      (error 'backend-bootstrap-error
             :backend :autocad
             :code :bootstrap-failed
             :message (format nil "AutoCAD start-engine failed: ~A" probe)
             :details (list :origin probe)))))

;;; --- EVAL-PLAN ----------------------------------------------------

(defmethod eval-plan ((session autocad-session) plan)
  (session-state-set session :running)
  (let ((result (drive-protocol-actions
                 (autocad-session-protocol-session session) plan)))
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
      (when info
        (handler-case
            (when (uiop:process-alive-p info)
              (uiop:terminate-process info)
              (uiop:wait-process info))
          (error () nil))))
    (session-state-set session :stopped))
  session)

(defmethod cleanup-workdir ((backend autocad-backend) workdir &key keep-p)
  (when workdir
    (remove-workdir workdir :keep-p keep-p))
  nil)

;;; --- registration -------------------------------------------------

(register-backend :autocad (make-autocad-backend))
