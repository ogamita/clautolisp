(in-package #:autolisp-front-end.tests)

(in-suite autolisp-front-end-suite)

;;;; FiveAM tests for the BricsCAD + AutoCAD backends (Phase 3).
;;;;
;;;; What we test without a real CAD install:
;;;;   - emitter byte-shape (run.scr / bridge-*.vbs / launcher.applescript)
;;;;   - VBS / AppleScript escapers
;;;;   - platform-gated DETECT (AutoCAD on macOS/Linux signals
;;;;     :unsupported-os; BricsCAD without a binary signals :no-binary)
;;;;   - the protocol-driven eval-plan against a mock CAD thread
;;;;     (reuses the Phase 2 pattern: a bordeaux-threads worker walks
;;;;     READY/RUNNING/DONE/STOPPED on the file slots while the
;;;;     backend issues actions)
;;;;
;;;; Real-CAD end-to-end tests are gated behind BRICSCAD_SMOKE=1 and
;;;; AUTOCAD_SMOKE=1 env vars per the issue; not run in CI.

;;; --- VBS / AppleScript escape helpers ------------------------------

(test cad-common-vbs-escape-doubles-internal-quotes
  "The VBScript double-quoted literal escape rule: every \" becomes
\"\" while backslashes stay verbatim (Windows paths embed them)."
  (is (string= "hello \"\"world\"\""
               (alfe.backend.cad-common:vbs-escape "hello \"world\"")))
  (is (string= "C:\\foo\\bar"
               (alfe.backend.cad-common:vbs-escape "C:\\foo\\bar"))))

(test cad-common-applescript-escape-backslashes-and-quotes
  "AppleScript escapes both \\ and \"."
  (is (string= "a \\\"quoted\\\" path"
               (alfe.backend.cad-common:applescript-escape "a \"quoted\" path")))
  (is (string= "back\\\\slash"
               (alfe.backend.cad-common:applescript-escape "back\\slash"))))

;;; --- BricsCAD detect ----------------------------------------------

(test bricscad-backend-is-registered
  (let ((backend (alfe.backend:find-backend :bricscad)))
    (is (not (null backend)))
    (is (eq :bricscad (alfe.backend:backend-name backend)))))

(defmacro with-env ((var value) &body body)
  "Run BODY with the env var named VAR temporarily set to VALUE,
then restore (or unset) it. Portable wrapper so the tests don't
hard-code SB-POSIX."
  (let ((saved (gensym "SAVED")) (had (gensym "HAD")))
    `(let* ((,saved (uiop:getenv ,var))
            (,had (and ,saved (plusp (length ,saved)))))
       (unwind-protect
           (progn (setf (uiop:getenv ,var) ,value)
                  ,@body)
         ;; Restore the previous value, or remove the binding when
         ;; there was no value to start with.
         (if ,had
             (setf (uiop:getenv ,var) ,saved)
             #+sbcl (sb-posix:unsetenv ,var)
             #+ccl  (ccl::unsetenv ,var)
             #-(or sbcl ccl) (setf (uiop:getenv ,var) ""))))))

(test bricscad-detect-via-env-var
  "When $BRICSCAD_EXE points at a real existing file, DETECT picks
it up and the backend's executable-path is set. We use /usr/bin/true
as a stand-in — the contract under test is 'honour the env var',
not 'recognise the binary'."
  (let ((fake-binary (or (probe-file "/usr/bin/true")
                         (probe-file "/bin/true"))))
    (when fake-binary
      (with-env ("BRICSCAD_EXE" (namestring fake-binary))
        (let* ((backend (alfe.backend.bricscad:make-bricscad-backend))
               (resolved (alfe.backend:detect backend)))
          (is (eq backend resolved))
          (is (string= (namestring fake-binary)
                       (alfe.backend.bricscad:bricscad-backend-executable-path
                        backend))))))))

(test bricscad-detect-without-binary-signals-not-available
  "With no binary on disk and no env var, DETECT signals
BACKEND-NOT-AVAILABLE. Skipped if a real BricsCAD install happens
to live on the test host."
  (with-env ("BRICSCAD_EXE" "")
    (when (or (alfe.backend.cad-common:macos-p)
              (alfe.backend.cad-common:linux-p))
      (let ((discovered (alfe.backend.bricscad:discover-bricscad-binary)))
        (if discovered
            (is (stringp discovered)
                "BricsCAD detected at ~A — test skipped." discovered)
            (let ((backend (alfe.backend.bricscad:make-bricscad-backend)))
              (signals alfe.error:backend-not-available
                (alfe.backend:detect backend))))))))

;;; --- BricsCAD emitters ---------------------------------------------

(defun read-back (path)
  (with-open-file (in path :external-format :utf-8)
    (with-output-to-string (out)
      (loop for ch = (read-char in nil :eof)
            until (eq ch :eof) do (write-char ch out)))))

(test bricscad-emit-run-scr-loads-runtime-and-quits
  "EMIT-RUN-SCR writes a SCR that:
   - loads run-common.lsp,
   - disables FILEDIA,
   - issues _QUIT _N when QUIT-ON-FINISH-P is on."
  (let* ((workdir (uiop:ensure-directory-pathname
                   (merge-pathnames
                    (format nil "alfe-test-bcad-scr-~D/" (random 999999))
                    (uiop:temporary-directory)))))
    (unwind-protect
        (progn
          (ensure-directories-exist workdir)
          (let* ((run-common (merge-pathnames "run-common.lsp" workdir))
                 (_ (with-open-file (out run-common
                                         :direction :output :if-exists :supersede
                                         :if-does-not-exist :create)
                      (write-string "(setq *AUTOLISP-DEBUG* nil)" out)))
                 (scr (alfe.backend.bricscad:emit-run-scr workdir run-common))
                 (content (read-back scr)))
            (declare (ignore _))
            (is (probe-file scr))
            (is (search "(load" content))
            (is (search "run-common.lsp" content))
            (is (search "_FILEDIA 0" content))
            (is (search "_QUIT _N" content))))
      (uiop:delete-directory-tree workdir :validate t
                                          :if-does-not-exist :ignore))))

(test bricscad-emit-bridge-vbs-substitutes-placeholders
  "EMIT-BRIDGE-VBS substitutes every documented placeholder. The
emitted text retains the WaitQuiescent / SendCommand /
ATTACHED=/CREATED= protocol that the legacy bash bridge defines."
  (let ((workdir (uiop:ensure-directory-pathname
                  (merge-pathnames
                   (format nil "alfe-test-bcad-vbs-~D/" (random 999999))
                   (uiop:temporary-directory)))))
    (unwind-protect
        (progn
          (ensure-directories-exist workdir)
          (let* ((vbs (merge-pathnames "bridge-bricscad.vbs" workdir))
                 (run-common (merge-pathnames "run-common.lsp" workdir))
                 (status (merge-pathnames "protocol/status.txt" workdir))
                 (err    (merge-pathnames "protocol/stderr.txt" workdir)))
            (alfe.backend.bricscad:emit-bridge-vbs
             vbs
             :runtime-load-path run-common
             :status-path status
             :error-path err
             :com-mode "auto")
            (let ((content (read-back vbs)))
              (is (search "BricscadApp.AcadApplication" content))
              (is (search "SendCommand" content))
              (is (search "ATTACHED=" content))
              (is (search "CREATED=" content))
              (is (search (namestring run-common) content)))))
      (uiop:delete-directory-tree workdir :validate t
                                          :if-does-not-exist :ignore))))

(test bricscad-emit-launcher-applescript-injects-load
  "EMIT-LAUNCHER-APPLESCRIPT writes an .applescript that uses
System Events to keystroke the (load …) form into BricsCAD."
  (let ((workdir (uiop:ensure-directory-pathname
                  (merge-pathnames
                   (format nil "alfe-test-bcad-as-~D/" (random 999999))
                   (uiop:temporary-directory)))))
    (unwind-protect
        (progn
          (ensure-directories-exist workdir)
          (let* ((as (merge-pathnames "launcher.applescript" workdir))
                 (run-common (merge-pathnames "run-common.lsp" workdir)))
            (alfe.backend.bricscad:emit-launcher-applescript
             as :runtime-load-path run-common)
            (let ((content (read-back as)))
              (is (search "System Events" content))
              (is (search "BricsCAD" content))
              (is (search "(load" content))
              (is (search (namestring run-common) content)))))
      (uiop:delete-directory-tree workdir :validate t
                                          :if-does-not-exist :ignore))))

;;; --- AutoCAD platform gating + detect -----------------------------

(test autocad-backend-is-registered
  (let ((backend (alfe.backend:find-backend :autocad)))
    (is (not (null backend)))
    (is (eq :autocad (alfe.backend:backend-name backend)))))

(test autocad-detect-on-non-windows-signals-unsupported-os
  "AutoCAD is Windows-only; on macOS/Linux DETECT signals
BACKEND-NOT-AVAILABLE with :unsupported-os and a structured message
the CLI translates to exit code 3."
  (when (or (alfe.backend.cad-common:macos-p)
            (alfe.backend.cad-common:linux-p))
    (let ((backend (alfe.backend.autocad:make-autocad-backend)))
      (handler-case
          (progn
            (alfe.backend:detect backend)
            (is nil "Expected BACKEND-NOT-AVAILABLE on non-Windows host."))
        (alfe.error:backend-not-available (condition)
          (is (eq :autocad (alfe.error:backend-error-backend condition)))
          (is (eq :unsupported-os (alfe.error:backend-error-code condition)))
          (is (search "not distributed"
                      (alfe.error:backend-error-message condition))))))))

(test autocad-unsupported-os-message-mentions-current-os
  "The friendly message names the current OS — so the user sees a
purposeful error, not 'this OS unknown'."
  (let ((message (alfe.backend.autocad:unsupported-os-message)))
    (is (or (search "macOS" message)
            (search "Linux" message)
            (search "this OS" message)))))

;;; --- AutoCAD emitter ----------------------------------------------

(test autocad-emit-bridge-vbs-substitutes-and-keeps-waitquiescent
  "EMIT-BRIDGE-VBS for AutoCAD substitutes placeholders and keeps
the WaitQuiescent / SendCommand / GetAcadState handshake the spec
calls 'the hard-won piece'."
  (let ((workdir (uiop:ensure-directory-pathname
                  (merge-pathnames
                   (format nil "alfe-test-acad-vbs-~D/" (random 999999))
                   (uiop:temporary-directory)))))
    (unwind-protect
        (progn
          (ensure-directories-exist workdir)
          (let* ((vbs (merge-pathnames "bridge-autocad.vbs" workdir))
                 (run-common (merge-pathnames "run-common.lsp" workdir))
                 (status (merge-pathnames "protocol/status.txt" workdir))
                 (err    (merge-pathnames "protocol/stderr.txt" workdir)))
            (alfe.backend.autocad:emit-bridge-vbs
             vbs
             :runtime-load-path run-common
             :status-path status
             :error-path err
             :com-mode "attach"
             :wait-secs 30)
            (let ((content (read-back vbs)))
              (is (search "AutoCAD.Application" content))
              (is (search "WaitQuiescent" content))
              (is (search "GetAcadState" content))
              (is (search "SendCommand" content))
              (is (search "ATTACHED=" content))
              (is (search "CREATED="  content))
              (is (search (namestring run-common) content))
              ;; com-mode + wait-secs are wired through.
              (is (search "\"attach\"" content))
              (is (search "30" content)))))
      (uiop:delete-directory-tree workdir :validate t
                                          :if-does-not-exist :ignore))))

(test autocad-emit-batch-scr-loads-runtime-and-quits
  "The accoreconsole SCR loads run-common.lsp, saves, and quits."
  (let ((workdir (uiop:ensure-directory-pathname
                  (merge-pathnames
                   (format nil "alfe-test-acad-scr-~D/" (random 999999))
                   (uiop:temporary-directory)))))
    (unwind-protect
        (progn
          (ensure-directories-exist workdir)
          (let* ((run-common (merge-pathnames "run-common.lsp" workdir)))
            (with-open-file (out run-common :direction :output
                                            :if-exists :supersede
                                            :if-does-not-exist :create)
              (write-string "()" out))
            (let* ((scr (alfe.backend.autocad:emit-batch-scr
                         (merge-pathnames "run.scr" workdir)
                         run-common))
                   (content (read-back scr)))
              (is (probe-file scr))
              (is (search "(load" content))
              (is (search "_QSAVE" content))
              (is (search "_QUIT _Y" content)))))
      (uiop:delete-directory-tree workdir :validate t
                                          :if-does-not-exist :ignore))))

;;; --- mock CAD end-to-end via file-protocol ------------------------

(defun spawn-mock-cad-runtime (protocol-session
                               &key (cycles 1)
                                    (echo-stdin-p t)
                                    (initial-ready-delay 0.05))
  "Launch a background bordeaux-threads thread that emulates the
CAD-side runtime: walks BOOTING → READY 0 → (RUNNING N → DONE N OK
→ READY N) for each request → STOPPING → STOPPED on SHUTDOWN.
Returns the thread so the test can JOIN it.

ECHO-STDIN-P, when true, echoes each consumed stdin.txt payload to
stdout.txt so the test driver can verify the round-trip."
  (bordeaux-threads:make-thread
   (lambda ()
     (alfe.protocol.file:write-atomic-file
      (alfe.protocol.file:protocol-session-status-path protocol-session)
      "READY 0")
     (sleep initial-ready-delay)
     (dotimes (i cycles)
       (let ((stdin (alfe.protocol.file:protocol-session-stdin-path protocol-session))
             (deadline (+ (get-internal-real-time)
                          (* 2 internal-time-units-per-second)))
             (request nil))
         (loop until (probe-file stdin)
               when (> (get-internal-real-time) deadline)
                 do (return)
               do (sleep 0.02))
         (when (probe-file stdin)
           (setf request (alfe.protocol.file:read-file-as-string stdin))
           (delete-file stdin))
         (alfe.protocol.file:write-atomic-file
          (alfe.protocol.file:protocol-session-status-path protocol-session)
          (format nil "RUNNING ~D" (1+ i)))
         (when (and echo-stdin-p request)
           (with-open-file (out (alfe.protocol.file:protocol-session-stdout-path
                                 protocol-session)
                                :direction :output :if-exists :append
                                :external-format :utf-8)
             (write-string request out)))
         (alfe.protocol.file:write-atomic-file
          (alfe.protocol.file:protocol-session-status-path protocol-session)
          (format nil "DONE ~D OK" (1+ i)))
         (sleep 0.05)
         (alfe.protocol.file:write-atomic-file
          (alfe.protocol.file:protocol-session-status-path protocol-session)
          (format nil "READY ~D" (1+ i)))))
     ;; Wait for SHUTDOWN.
     (let ((control (alfe.protocol.file:protocol-session-control-path protocol-session))
           (deadline (+ (get-internal-real-time)
                        (* 2 internal-time-units-per-second))))
       (loop until (let ((text (alfe.protocol.file:read-file-as-string control)))
                     (search "SHUTDOWN" text))
             when (> (get-internal-real-time) deadline)
               do (return)
             do (sleep 0.02))
       (when (probe-file control) (delete-file control)))
     (alfe.protocol.file:write-atomic-file
      (alfe.protocol.file:protocol-session-status-path protocol-session)
      "STOPPING")
     (sleep 0.2)
     (alfe.protocol.file:write-atomic-file
      (alfe.protocol.file:protocol-session-status-path protocol-session)
      "STOPPED"))
   :name "mock-cad-runtime"))

(test cad-drive-protocol-actions-end-to-end
  "DRIVE-PROTOCOL-ACTIONS issues each action through stdin.txt, sees
the mock CAD's DONE transition, drains the echoed payload, and
reports :success at the end. Mirrors the eval-plan a real BricsCAD
session would walk."
  (let ((workdir (uiop:ensure-directory-pathname
                  (merge-pathnames
                   (format nil "alfe-test-cad-drive-~D/" (random 999999))
                   (uiop:temporary-directory)))))
    (unwind-protect
        (progn
          (ensure-directories-exist workdir)
          (let* ((protocol (alfe.protocol.file:init-session workdir))
                 (cad (spawn-mock-cad-runtime protocol :cycles 1))
                 (plan (list (alfe.backend:action-eval "(princ 42)")
                             (alfe.backend:action-quit)))
                 (result
                   ;; Wait for the mock to publish READY 0 first.
                   (progn (alfe.protocol.file:wait-for-status-prefix
                           protocol "READY" :timeout 2)
                          (let ((*standard-output* (make-string-output-stream))
                                (*error-output*    (make-string-output-stream)))
                            (alfe.backend.cad-common:drive-protocol-actions
                             protocol plan)))))
            (is (eq :success (alfe.backend:eval-result-status result)))
            (is (search "(princ 42)"
                        (alfe.backend:eval-result-output result)))
            (bordeaux-threads:join-thread cad)))
      (uiop:delete-directory-tree workdir :validate t
                                          :if-does-not-exist :ignore))))

(test cad-drive-protocol-actions-three-evals-counter-aware
  "Regression: DRIVE-PROTOCOL-ACTIONS must wait for `DONE N' where N
is the *next* request counter, not the generic `DONE' prefix. The
old code matched the previous action's stale `DONE N-1 OK' the very
tick after send-stdin returned, dropping every action past the
first one and silently skipping their output + errors.

This test fires three :eval actions; without the counter fix, the
mock's echo of actions 2 and 3 never reaches eval-result-output
because alfe believes them finished before the mock has even read
stdin.txt for them."
  (let ((workdir (uiop:ensure-directory-pathname
                  (merge-pathnames
                   (format nil "alfe-test-cad-three-~D/" (random 999999))
                   (uiop:temporary-directory)))))
    (unwind-protect
        (progn
          (ensure-directories-exist workdir)
          (let* ((protocol (alfe.protocol.file:init-session workdir))
                 (cad (spawn-mock-cad-runtime protocol :cycles 3))
                 (plan (list (alfe.backend:action-eval "(princ 1)")
                             (alfe.backend:action-eval "(princ 2)")
                             (alfe.backend:action-eval "(princ 3)")
                             (alfe.backend:action-quit)))
                 (result
                   (progn (alfe.protocol.file:wait-for-status-prefix
                           protocol "READY" :timeout 2)
                          (let ((*standard-output* (make-string-output-stream))
                                (*error-output*    (make-string-output-stream)))
                            (alfe.backend.cad-common:drive-protocol-actions
                             protocol plan)))))
            (is (eq :success (alfe.backend:eval-result-status result)))
            (let ((stdout (alfe.backend:eval-result-output result)))
              ;; All three actions must show up in the echo capture.
              (is (search "(princ 1)" stdout))
              (is (search "(princ 2)" stdout))
              (is (search "(princ 3)" stdout)))
            (bordeaux-threads:join-thread cad)))
      (uiop:delete-directory-tree workdir :validate t
                                          :if-does-not-exist :ignore))))

(test cad-drive-protocol-actions-interactive-loop-roundtrips
  "DRIVE-PROTOCOL-ACTIONS on an :interactive action reads lines from
INPUT-STREAM, sends each balanced form through the protocol, drains
output live to OUTPUT-STREAM, and exits cleanly on EOF. We drive
both the input and the live streams via string streams so the test
runs in-process against the mock CAD; the :interactive action is
followed by an explicit :quit so the loop unwinds and STOP-PED is
published."
  (let ((workdir (uiop:ensure-directory-pathname
                  (merge-pathnames
                   (format nil "alfe-test-cad-repl-~D/" (random 999999))
                   (uiop:temporary-directory)))))
    (unwind-protect
        (progn
          (ensure-directories-exist workdir)
          (let* ((protocol (alfe.protocol.file:init-session workdir))
                 (cad (spawn-mock-cad-runtime protocol :cycles 2))
                 (plan (list (alfe.backend:action-interactive)
                             (alfe.backend:action-quit)))
                 (input-text (format nil "(+ 1 2)~%(+ 3 4)~%"))
                 (output-stream (make-string-output-stream))
                 (error-stream  (make-string-output-stream))
                 (result
                   (progn (alfe.protocol.file:wait-for-status-prefix
                           protocol "READY" :timeout 2)
                          (alfe.backend.cad-common:drive-protocol-actions
                           protocol plan
                           :input-stream (make-string-input-stream input-text)
                           :output-stream output-stream
                           :error-stream  error-stream))))
            ;; Both lines we typed should have been echoed by the
            ;; mock through stdout.txt -> alfe drain -> output-stream.
            ;; alfe wraps each interactive form in (print …) so the
            ;; runtime emits the value back to stdout.txt; the mock
            ;; echoes the wrapped text so the assertion is on the
            ;; wrapped form ("(print (+ 1 2))" rather than the bare
            ;; "(+ 1 2)").
            (let ((live (get-output-stream-string output-stream)))
              (is (search "(print (+ 1 2))" live))
              (is (search "(print (+ 3 4))" live))
              ;; A primary prompt was issued before the first form.
              (is (search "alfe>" live)))
            (is (eq :success (alfe.backend:eval-result-status result)))
            (bordeaux-threads:join-thread cad)))
      (uiop:delete-directory-tree workdir :validate t
                                          :if-does-not-exist :ignore))))

(test cad-drive-protocol-actions-mirrors-runtime-debug-flag
  "After each wait-done, drive-protocol-actions reads
protocol/runtime-flags.txt and updates alfe.logging:*current-level*
so a (setq *autolisp-debug* nil) the user types at the REPL takes
effect on alfe's own trace output too -- not just on the [CAD]
debug.log channel."
  (let ((workdir (uiop:ensure-directory-pathname
                  (merge-pathnames
                   (format nil "alfe-test-cad-flags-~D/" (random 999999))
                   (uiop:temporary-directory)))))
    (unwind-protect
        (progn
          (ensure-directories-exist workdir)
          (let* ((protocol (alfe.protocol.file:init-session workdir))
                 (cad (spawn-mock-cad-runtime protocol :cycles 1))
                 (plan (list (alfe.backend:action-eval "(princ 1)")
                             (alfe.backend:action-quit)))
                 ;; Pre-populate runtime-flags.txt with DEBUG=0 so the
                 ;; sync-from-runtime call after wait-done sees a
                 ;; concrete value. (In a live run the CAD-side
                 ;; alfe-publish-runtime-flags writes this; the mock
                 ;; CAD doesn't, so we install the file by hand.)
                 (flags-path (alfe.protocol.file:protocol-session-runtime-flags-path
                              protocol)))
            (with-open-file (out flags-path :direction :output
                                            :if-does-not-exist :create
                                            :if-exists :supersede
                                            :external-format :utf-8)
              (format out "DEBUG=0~%VERBOSE=0~%"))
            ;; Start alfe in :debug, then drive the plan; the runtime
            ;; flag says debug should be off, so the level must come
            ;; back to :info.
            (let ((alfe.logging:*current-level* :debug))
              (progn (alfe.protocol.file:wait-for-status-prefix
                      protocol "READY" :timeout 2)
                     (let ((*standard-output* (make-string-output-stream))
                           (*error-output*    (make-string-output-stream)))
                       (alfe.backend.cad-common:drive-protocol-actions
                        protocol plan)))
              (is (eq :info alfe.logging:*current-level*)
                  "Runtime DEBUG=0 should have dragged alfe down to :info; current is ~S"
                  alfe.logging:*current-level*))
            (bordeaux-threads:join-thread cad)))
      (uiop:delete-directory-tree workdir :validate t
                                          :if-does-not-exist :ignore))))

(test bricscad-start-engine-with-mock-launcher
  "START-ENGINE composes the launch artefacts and waits for READY 0;
we substitute a thread-based mock for the real bricscad binary via
the :launcher keyword. The session ends up in :ready state."
  (let ((workdir (uiop:ensure-directory-pathname
                  (merge-pathnames
                   (format nil "alfe-test-bcad-start-~D/" (random 999999))
                   (uiop:temporary-directory)))))
    (unwind-protect
        (let* ((backend (alfe.backend.bricscad:make-bricscad-backend
                         :executable-path "/usr/bin/true"
                         :variant :batch))
               (mock-thread nil)
               (launcher
                 (lambda (argv &rest ignored)
                   (declare (ignore argv ignored))
                   ;; Once the launch "happens", spin up the mock
                   ;; runtime against the workdir's protocol session.
                   ;; We grab the session via the well-known
                   ;; status.txt path under the workdir we passed in.
                   (let ((proto-session
                           (find-protocol-session-in-workdir workdir)))
                     (setf mock-thread
                           (spawn-mock-cad-runtime proto-session :cycles 1))
                     nil)))
               (session (alfe.backend:start-engine
                         backend workdir
                         :dialect :strict
                         :host :mock
                         :mock-input nil
                         :bootstrap-phase :full
                         :interactive-p nil
                         :mode :batch
                         :launcher launcher
                         :wait-for-ready t
                         :ready-timeout 2)))
          (is (eq :ready (alfe.backend:session-state session)))
          ;; Now run a tiny plan.
          (let ((*standard-output* (make-string-output-stream))
                (*error-output*    (make-string-output-stream)))
            (let ((result (alfe.backend:eval-plan
                           session
                           (list (alfe.backend:action-eval "(princ 7)")
                                 (alfe.backend:action-quit)))))
              (is (eq :success (alfe.backend:eval-result-status result)))))
          (alfe.backend:shutdown session)
          (when mock-thread
            (handler-case (bordeaux-threads:join-thread mock-thread)
              (error () nil))))
      (uiop:delete-directory-tree workdir :validate t
                                          :if-does-not-exist :ignore))))

(defun find-protocol-session-in-workdir (workdir)
  "After START-ENGINE has run, the protocol session's filesystem
artefacts live under WORKDIR/protocol/. The launcher closure
doesn't have direct access to the session struct, so we
reconstruct a thin one pointing at the same files."
  (alfe.protocol.file::%make-protocol-session
   :workdir workdir
   :protocol-dir (merge-pathnames "protocol/" workdir)
   :status-path (merge-pathnames "protocol/status.txt" workdir)
   :stdin-path  (merge-pathnames "protocol/stdin.txt" workdir)
   :stdout-path (merge-pathnames "protocol/stdout.txt" workdir)
   :stderr-path (merge-pathnames "protocol/stderr.txt" workdir)
   :control-path (merge-pathnames "protocol/control.txt" workdir)
   :heartbeat-path (merge-pathnames "protocol/heartbeat.txt" workdir)
   :read-buffer-path (merge-pathnames "protocol/read-buffer.lsp" workdir)
   :runtime-info-path (merge-pathnames "protocol/runtime-info.txt" workdir)))

;;; --- BUILD-LAUNCH-ARGV ---------------------------------------------

(test bricscad-build-launch-argv-batch-shape
  "In batch mode the argv is [<bricscad> [<template>] [-P prof] -B
<run.scr>]. We verify the -B suffix is present, the binary is in
CAR, and the SCR points into the workdir."
  (let ((workdir (uiop:ensure-directory-pathname
                  (merge-pathnames
                   (format nil "alfe-test-bcad-argv-~D/" (random 999999))
                   (uiop:temporary-directory)))))
    (unwind-protect
        (progn
          (ensure-directories-exist workdir)
          (let* ((backend (alfe.backend.bricscad:make-bricscad-backend
                           :executable-path "/usr/bin/true"
                           :variant :batch))
                 (protocol (alfe.protocol.file:init-session workdir))
                 (argv (alfe.backend.bricscad:build-launch-argv
                        backend protocol :mode :batch)))
            (is (string= "/usr/bin/true" (first argv)))
            (is (member "-B" argv :test #'string=))
            (is (find "run.scr" argv :test (lambda (needle s)
                                              (search needle s))))))
      (uiop:delete-directory-tree workdir :validate t
                                          :if-does-not-exist :ignore))))

(test autocad-build-launch-argv-batch-requires-dwg-and-accoreconsole
  "Batch mode without --dwg signals :no-dwg; without accoreconsole
binary signals :no-accoreconsole. Both surface as
BACKEND-BOOTSTRAP-ERROR (exit code 4)."
  (let ((workdir (uiop:ensure-directory-pathname
                  (merge-pathnames
                   (format nil "alfe-test-acad-argv-~D/" (random 999999))
                   (uiop:temporary-directory)))))
    (unwind-protect
        (progn
          (ensure-directories-exist workdir)
          (let* ((protocol (alfe.protocol.file:init-session workdir))
                 (no-acc (alfe.backend.autocad:make-autocad-backend))
                 (with-acc (alfe.backend.autocad:make-autocad-backend
                            :accoreconsole-path "/usr/bin/true")))
            (signals alfe.error:backend-bootstrap-error
              (alfe.backend.autocad:build-launch-argv
               no-acc protocol :mode :batch :dwg "/tmp/x.dwg"))
            (signals alfe.error:backend-bootstrap-error
              (alfe.backend.autocad:build-launch-argv
               with-acc protocol :mode :batch))
            (let ((argv (alfe.backend.autocad:build-launch-argv
                         with-acc protocol :mode :batch :dwg "/tmp/x.dwg")))
              (is (string= "/usr/bin/true" (first argv)))
              (is (member "/i" argv :test #'string=))
              (is (member "/s" argv :test #'string=)))))
      (uiop:delete-directory-tree workdir :validate t
                                          :if-does-not-exist :ignore))))
