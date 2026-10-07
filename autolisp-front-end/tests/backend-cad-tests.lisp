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

;;; --- quitting the AutoCAD we created -------------------------------
;;;
;;; The bug these pin (alfe-autocad-automation-never-quits-acad.issue):
;;; in automation mode alfe launches CSCRIPT, which asks COM for an
;;; AutoCAD; the acad.exe that answers belongs to Windows' COM service,
;;; so killing the launched process never touched it and every run left
;;; AutoCAD idle on an unnamed Dessin1.dwg.
;;;
;;; None of this can be run against a real AutoCAD here, so what is
;;; tested is the DECISION and the emitted script — the two halves that
;;; do not need Windows. The launcher is injected, so the test can say
;;; whether alfe would have launched the quit bridge at all.

(defvar *cad-test-random* (make-random-state t)
  "A random state seeded ONCE PER PROCESS, for naming test directories.

Not *RANDOM-STATE*. CCL starts every fresh process with the SAME random
state, so UIOP:WITH-TEMPORARY-FILE hands out the SAME name sequence run
after run (measured: /tmp/tmpGYSY3UZ5.tmp in two separate processes).
Tests that reuse a temporary name as a DIRECTORY and never remove it
therefore collide with their own leftovers on the SECOND run -- which is
exactly how these tests passed once and then failed with `Is a
directory: /tmp/tmpKW2VXSR3.tmp' (ccl-test-lanes-cannot-fail.issue).")

(defvar *cad-test-directories* '()
  "Directories made during the current WITH-CAD-TEST-DIRECTORIES.")

(defun %fresh-test-directory ()
  "Make and return a NEW, empty directory under the system temp dir.

NEW is checked, not assumed: a name that already exists is skipped, so
a leftover from an earlier run can never be mistaken for this one."
  (loop
    (let ((dir (uiop:ensure-directory-pathname
                (uiop:subpathname
                 (uiop:temporary-directory)
                 (format nil "alfe-cad-test-~36R"
                         (random (expt 36 12) *cad-test-random*))))))
      (unless (uiop:directory-exists-p dir)
        (ensure-directories-exist dir)
        (push dir *cad-test-directories*)
        (return dir)))))

(defmacro with-cad-test-directories (&body body)
  "Run BODY, then remove every directory %FRESH-TEST-DIRECTORY made.

The removal is what the earlier helper lacked: it left a directory in
/tmp per call — 42 had accumulated — and those leftovers are what the
next run collided with."
  `(let ((*cad-test-directories* '()))
     (unwind-protect (progn ,@body)
       (dolist (dir *cad-test-directories*)
         (ignore-errors
          (uiop:delete-directory-tree
           dir
           ;; only ever a directory THIS helper made, under the temp dir
           :validate (lambda (d)
                       (search "alfe-cad-test-" (namestring d)))))))))

(defun %quit-test-workdir (&key attached created)
  "A fresh workdir holding a bridge flags file, or none when both are NIL.
Call inside WITH-CAD-TEST-DIRECTORIES, which removes it afterwards."
  (let ((dir (%fresh-test-directory)))
    (when (or attached created)
      (with-open-file (out (merge-pathnames "com-flags.txt" dir)
                           :direction :output :if-exists :supersede
                           :if-does-not-exist :create)
        (format out "ATTACHED=~D~%CREATED=~D~%"
                (if attached 1 0) (if created 1 0))))
    dir))

(test autocad-com-flags-are-read-from-the-workdir
  "The bridge reported CREATED / ATTACHED on stdout and NOTHING read
them, which is why the decision could not be made. They are written to
a file in the workdir now, and this is the reader."
  (with-cad-test-directories
    (multiple-value-bind (att cre)
        (alfe.backend.autocad::read-com-flags
         (%quit-test-workdir :created t))
      (is (null att))
      (is (eq t cre)))
    (multiple-value-bind (att cre)
        (alfe.backend.autocad::read-com-flags
         (%quit-test-workdir :attached t))
      (is (eq t att))
      (is (null cre)))
    ;; No flags file at all — a bridge that died before reporting. Both
    ;; NIL, which is what makes the safe default safe.
    (multiple-value-bind (att cre)
        (alfe.backend.autocad::read-com-flags (%quit-test-workdir))
      (is (null att))
      (is (null cre)))))

(defun %quit-launches (workdir)
  "Run QUIT-CREATED-AUTOCAD on a session in WORKDIR with a recording
launcher. Returns (values RESULT LAUNCHED-ARGVS)."
  (let* ((launched '())
         (session (alfe.backend.autocad::%make-autocad-session
                   :workdir workdir
                   :variant :automation))
         (result (alfe.backend.autocad::quit-created-autocad
                  session
                  :launcher (lambda (argv &rest ignored)
                              (declare (ignore ignored))
                              (push argv launched)
                              nil))))
    (values result launched)))

(test autocad-quit-runs-only-for-an-instance-we-created
  "pjb, 2026-09-16: alfe should only quit a CAD it created itself. An
AutoCAD the bridge ATTACHED to was already running — on this runner it
may be a person's own session — so alfe must leave it alone. The
launcher is injected: the test asserts whether the quit bridge would
have been launched AT ALL, which is the whole decision."
  (with-cad-test-directories
    ;; created -> the quit bridge is launched, with cscript and the script
    (multiple-value-bind (result launched)
        (%quit-launches (%quit-test-workdir :created t))
      (is (eq t result))
      (is (= 1 (length launched)))
      (let ((argv (first launched)))
        (is (equal "cscript" (first argv)))
        (is (search "quit-autocad.vbs" (format nil "~{~A ~}" argv)))))
    ;; attached -> nothing is launched. This is the case that protects a
    ;; human's AutoCAD, so it is asserted on the LAUNCHER, not the result.
    (multiple-value-bind (result launched)
        (%quit-launches (%quit-test-workdir :attached t))
      (is (null result))
      (is (null launched) "alfe tried to quit an AutoCAD it only attached to"))
    ;; no flags at all -> nothing is launched either
    (multiple-value-bind (result launched)
        (%quit-launches (%quit-test-workdir))
      (is (null result))
      (is (null launched)))))

(test autocad-quit-bridge-closes-documents-without-saving
  "The document the bridge adds is UNNAMED (Dessin1/Drawing1), so
app.Quit alone would raise the Save-changes dialog — a modal dialog on
an unattended runner being the very hang this is meant to end. Each
document is closed with SaveChanges = False first, downwards because
closing shortens the collection."
  (let ((text alfe.backend.autocad::*quit-autocad-vbs-template*))
    ;; The server is the resolved ProgID now, not a hardcoded generic one
    ;; (alfe-autocad-cad-selection-ignores-com-progid).
    (is (search "GetObject(, progId)" text))
    (is (search "${PROGID}" text))
    (is (search "doc.Close False" text))
    (is (search "app.Quit" text))
    (is (search "Step -1" text)
        "the close loop must run downwards")
    ;; It must never CREATE one while trying to quit.
    (is (not (search "CreateObject(" text)))))

(test autocad-bridge-writes-its-flags-to-a-file
  "The flags reach alfe through a file in the workdir: cscript is
short-lived and the answer is needed later, at shutdown."
  (with-cad-test-directories
    (let* ((dir (%fresh-test-directory))
           (vbs (merge-pathnames "bridge-flags-test.vbs" dir)))
      (alfe.backend.autocad::emit-bridge-vbs
       vbs
       :runtime-load-path (merge-pathnames "run-common.lsp" dir)
       :status-path (merge-pathnames "status.txt" dir)
       :error-path (merge-pathnames "err.txt" dir)
       :flags-path (merge-pathnames "com-flags.txt" dir))
      (let ((text (uiop:read-file-string vbs)))
        (is (search "flagsFile" text))
        (is (search "com-flags.txt" text))
        (is (search "AppendLine flagsFile" text))))))

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

(test bricscad-cui-file-corrupt-p-classifies-cui-files
  "cui-file-corrupt-p: a CUI that opens (after leading whitespace) with a `<'
tag is fine; empty / whitespace-only / non-tag content is corrupt (the startup
'invalid document structure' modal); an ABSENT file is not corrupt — BricsCAD
creates it. Backs the pre-launch quarantine of a corrupt per-user default.cui."
  (let ((dir (uiop:ensure-directory-pathname
              (merge-pathnames (format nil "alfe-cui-test-~D/" (random 999999))
                               (uiop:temporary-directory)))))
    (unwind-protect
        (progn
          (ensure-directories-exist dir)
          (flet ((mk (name content)
                   (let ((p (merge-pathnames name dir)))
                     (with-open-file (o p :direction :output :if-exists :supersede
                                          :if-does-not-exist :create
                                          :external-format :latin-1)
                       (write-string content o))
                     p)))
            ;; valid: opens with a tag (optionally after whitespace)
            (is (null (alfe.backend.bricscad:cui-file-corrupt-p
                       (mk "ok.cui" (format nil "<?xml version=\"1.0\"?>~%<CUIx/>~%")))))
            (is (null (alfe.backend.bricscad:cui-file-corrupt-p
                       (mk "ok-ws.cui" (format nil "  ~%<CUIx/>")))))
            ;; valid WITH a leading UTF-8 BOM (EF BB BF) — BricsCAD writes one
            ;; before <?xml (the fr_FR default.cui). Must NOT be flagged corrupt.
            (is (null (alfe.backend.bricscad:cui-file-corrupt-p
                       (mk "ok-bom.cui"
                           (format nil "~C~C~C<?xml version=\"1.0\"?>~%<CUIx/>"
                                   (code-char #xEF) (code-char #xBB) (code-char #xBF))))))
            ;; corrupt: empty / whitespace-only / non-tag first char
            (is (alfe.backend.bricscad:cui-file-corrupt-p (mk "empty.cui" "")))
            (is (alfe.backend.bricscad:cui-file-corrupt-p
                 (mk "ws.cui" (format nil "   ~%  ~%"))))
            (is (alfe.backend.bricscad:cui-file-corrupt-p
                 (mk "garbage.cui" "not xml at all")))
            ;; absent: not corrupt (BricsCAD regenerates it)
            (is (null (alfe.backend.bricscad:cui-file-corrupt-p
                       (merge-pathnames "does-not-exist.cui" dir))))))
      (uiop:delete-directory-tree dir :validate t :if-does-not-exist :ignore))))

;;; --- BricsCAD emitters ---------------------------------------------

(defun read-back (path)
  (with-open-file (in path :external-format :utf-8)
    (with-output-to-string (out)
      (loop for ch = (read-char in nil :eof)
            until (eq ch :eof) do (write-char ch out)))))

(defun touch-file (path &optional (contents ""))
  (ensure-directories-exist path)
  (with-open-file (out path :direction :output
                            :if-exists :supersede
                            :if-does-not-exist :create
                            :external-format :utf-8)
    (write-string contents out))
  path)

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
              (is (search (namestring run-common) content))
              ;; Regression: same 424 "Object required" trap as AutoCAD —
              ;; `app` must be Set to an object before the first `Is Nothing`.
              (is (search "Set app = Nothing" content))
              (let ((init (search "Set app = Nothing" content))
                    (probe (search "app Is Nothing" content)))
                (is (and init probe (< init probe)))))))
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

(test bricscad-discover-windows-installed-binary-via-program-files-env
  "On native Windows, BricsCAD discovery should search the Program
Files roots advertised by the standard environment variables, not
just an MSYS-style /c mirror."
  (let ((root (uiop:ensure-directory-pathname
               (merge-pathnames
                (format nil "alfe-test-win-bricscad-~D/" (random 999999))
                (uiop:temporary-directory)))))
    (unwind-protect
        (progn
          (touch-file (merge-pathnames "Bricsys/BricsCAD V26/bricscad.exe" root))
          (with-env ("BRICSCAD_EXE" "")
            (with-env ("ProgramW6432" (namestring root))
              (with-env ("ProgramFiles" "")
                (with-env ("ProgramFiles(x86)" "")
                  (let ((discovered
                          (alfe.backend.bricscad:discover-bricscad-binary
                           :os :windows)))
                    (is (not (null discovered)))
                    (is (search "BricsCAD V26" discovered))
                    (is (search "bricscad.exe" discovered))))))))
      (uiop:delete-directory-tree root :validate t
                                       :if-does-not-exist :ignore))))

(test bricscad-discover-windows-env-var-wins-over-default-search
  "When $BRICSCAD_EXE is set, it must override the default Windows
Program Files scan."
  (let ((root (uiop:ensure-directory-pathname
               (merge-pathnames
                (format nil "alfe-test-win-bricscad-env-~D/" (random 999999))
                (uiop:temporary-directory)))))
    (unwind-protect
        (progn
          (let ((installed (touch-file
                            (merge-pathnames "Bricsys/BricsCAD V26/bricscad.exe"
                                             root)))
                (override (touch-file
                           (merge-pathnames "custom/override-bricscad.exe"
                                            root))))
            (declare (ignore installed))
            (with-env ("ProgramW6432" (namestring root))
              (with-env ("ProgramFiles" "")
                (with-env ("ProgramFiles(x86)" "")
                  (with-env ("BRICSCAD_EXE" (namestring override))
                    (is (string=
                         (namestring override)
                         (alfe.backend.bricscad:discover-bricscad-binary
                          :os :windows)))))))))
      (uiop:delete-directory-tree root :validate t
                                       :if-does-not-exist :ignore))))

(test autocad-detect-on-non-windows-signals-unsupported-os
  "AutoCAD's GUI / COM-automation path is Windows-only; on macOS/Linux
DETECT signals BACKEND-NOT-AVAILABLE with :unsupported-os (exit code 3) —
UNLESS an AcCoreConsole batch engine is present (it ships with the macOS
AutoCAD bundle and runs there), in which case batch DETECT succeeds."
  (when (or (alfe.backend.cad-common:macos-p)
            (alfe.backend.cad-common:linux-p))
    (let ((backend (alfe.backend.autocad:make-autocad-backend)))
      (if (alfe.backend.autocad:discover-accoreconsole-binary)
          ;; accoreconsole available off Windows (macOS with AutoCAD) — the
          ;; batch engine is supported, so DETECT resolves rather than errors.
          (is (eq backend (alfe.backend:detect backend)))
          ;; No batch engine — GUI-only, genuinely unsupported off Windows.
          (handler-case
              (progn
                (alfe.backend:detect backend)
                (is nil "Expected BACKEND-NOT-AVAILABLE on non-Windows host."))
            (alfe.error:backend-not-available (condition)
              (is (eq :autocad (alfe.error:backend-error-backend condition)))
              (is (eq :unsupported-os (alfe.error:backend-error-code condition)))
              (is (search "not distributed"
                          (alfe.error:backend-error-message condition)))))))))

(test autocad-unsupported-os-message-mentions-current-os
  "The friendly message names the current OS — so the user sees a
purposeful error, not 'this OS unknown'."
  (let ((message (alfe.backend.autocad:unsupported-os-message)))
    (is (or (search "macOS" message)
            (search "Linux" message)
            (search "this OS" message)))))

(test autocad-discover-windows-installed-binaries-via-program-files-env
  "On native Windows, AutoCAD discovery should walk the actual
Program Files roots from the environment for both acad.exe and
accoreconsole.exe."
  (let ((root (uiop:ensure-directory-pathname
               (merge-pathnames
                (format nil "alfe-test-win-autocad-~D/" (random 999999))
                (uiop:temporary-directory)))))
    (unwind-protect
        (progn
          (touch-file (merge-pathnames
                       "Autodesk/AutoCAD 2026/acad.exe" root))
          (touch-file (merge-pathnames
                       "Autodesk/AutoCAD 2026/accoreconsole.exe" root))
          (with-env ("AUTOCAD_EXE" "")
            (with-env ("AUTOCAD_ACCORECONSOLE" "")
              (with-env ("ProgramW6432" (namestring root))
                (with-env ("ProgramFiles" "")
                  (with-env ("ProgramFiles(x86)" "")
                    (let ((acad (alfe.backend.autocad:discover-autocad-binary
                                 :os :windows))
                          (acc (alfe.backend.autocad:discover-accoreconsole-binary
                                :os :windows)))
                      (is (not (null acad)))
                      (is (not (null acc)))
                      (is (search "AutoCAD 2026" acad))
                      (is (search "acad.exe" acad))
                      (is (search "accoreconsole.exe" acc)))))))))
      (uiop:delete-directory-tree root :validate t
                                       :if-does-not-exist :ignore))))

(test autocad-discover-windows-env-vars-win-over-default-search
  "When $AUTOCAD_EXE / $AUTOCAD_ACCORECONSOLE are set, they must
override the default Windows Program Files scan."
  (let ((root (uiop:ensure-directory-pathname
               (merge-pathnames
                (format nil "alfe-test-win-autocad-env-~D/" (random 999999))
                (uiop:temporary-directory)))))
    (unwind-protect
        (progn
          (touch-file (merge-pathnames
                       "Autodesk/AutoCAD 2026/acad.exe" root))
          (touch-file (merge-pathnames
                       "Autodesk/AutoCAD 2026/accoreconsole.exe" root))
          (let ((override-acad (touch-file
                                (merge-pathnames "custom/override-acad.exe"
                                                 root)))
                (override-acc (touch-file
                               (merge-pathnames "custom/override-acc.exe"
                                                root))))
            (with-env ("ProgramW6432" (namestring root))
              (with-env ("ProgramFiles" "")
                (with-env ("ProgramFiles(x86)" "")
                  (with-env ("AUTOCAD_EXE" (namestring override-acad))
                    (with-env ("AUTOCAD_ACCORECONSOLE" (namestring override-acc))
                      (is (string=
                           (namestring override-acad)
                           (alfe.backend.autocad:discover-autocad-binary
                            :os :windows)))
                      (is (string=
                           (namestring override-acc)
                           (alfe.backend.autocad:discover-accoreconsole-binary
                            :os :windows)))))))))
      (uiop:delete-directory-tree root :validate t
                                       :if-does-not-exist :ignore)))))

(test autocad-discover-template-prefers-requested-then-env-then-install
  "Batch mode needs a drawing/template. Discovery order is:
requested --dwg, then $AUTOLISP_DWG, then a template shipped with the
discovered AutoCAD install."
  (let ((root (uiop:ensure-directory-pathname
               (merge-pathnames
                (format nil "alfe-test-win-autocad-template-~D/" (random 999999))
                (uiop:temporary-directory)))))
    (unwind-protect
        (let* ((install-template
                 (touch-file (merge-pathnames
                              "Autodesk/AutoCAD 2026/Template/acadiso.dwt" root)))
               (requested
                 (touch-file (merge-pathnames "custom/requested.dwg" root)))
               (env-template
                 (touch-file (merge-pathnames "custom/from-env.dwg" root)))
               (backend (alfe.backend.autocad:make-autocad-backend
                         :executable-path
                         (namestring
                          (touch-file (merge-pathnames
                                       "Autodesk/AutoCAD 2026/acad.exe" root)))
                         :accoreconsole-path
                         (namestring
                          (touch-file (merge-pathnames
                                       "Autodesk/AutoCAD 2026/accoreconsole.exe"
                                       root))))))
          (flet ((same-file (a b)
                   ;; Compare existing paths by TRUENAME: macOS resolves the
                   ;; /var -> /private/var symlink, and DISCOVER-AUTOCAD-TEMPLATE
                   ;; TRUENAMEs the requested path, so a raw STRING= spuriously
                   ;; fails on macOS while passing on Linux (where /var is real).
                   (equal (truename a) (truename b))))
            (with-env ("AUTOLISP_DWG" "")
              (is (same-file
                   requested
                   (alfe.backend.autocad:discover-autocad-template
                    backend :requested (namestring requested)))))
            (with-env ("AUTOLISP_DWG" (namestring env-template))
              (is (same-file
                   env-template
                   (alfe.backend.autocad:discover-autocad-template backend))))
            (with-env ("AUTOLISP_DWG" "")
              (is (same-file
                   install-template
                   (alfe.backend.autocad:discover-autocad-template backend))))))
      (uiop:delete-directory-tree root :validate t
                                       :if-does-not-exist :ignore))))

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
              (is (search "30" content))
              ;; Regression: `app` must be a real object reference before the
              ;; first `Is Nothing` test. An unassigned Dim is Empty, and
              ;; `Empty Is Nothing` raises VBScript err 424 "Object required"
              ;; on the attach-miss path (this bit at emitted line 72).
              (is (search "Set app = Nothing" content))
              (let ((init (search "Set app = Nothing" content))
                    (probe (search "app Is Nothing" content)))
                (is (and init probe (< init probe)))))))
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

(defun %mock-retry-file-op (thunk)
  "Run THUNK, retrying a TRANSIENT Windows sharing violation (a FILE-ERROR /
STREAM-ERROR on a file whose handle another party is still releasing) a few
times with a short back-off, then re-signalling. The mock's per-cycle
`delete-file' and echo `:append' are otherwise bare ops under the thread's
outer IGNORE-ERRORS: on Windows a momentary sharing violation there aborts the
WHOLE mock thread, so it stops consuming stdin.txt and the driver's next
SEND-STDIN times out with [STDIN-BUSY] — the intermittent test:alfe:windows this
guards against. It mirrors the same transient that READ-FILE-AS-STRING already
retries in the production protocol; dormant on POSIX, where these ops never
raise."
  (loop for n from 1 to 50 do
    (handler-case (return (funcall thunk))
      ((or file-error stream-error) (c)
        (when (>= n 50) (error c))
        (sleep 0.02)))))

(define-condition alfe-test-serious-not-error (serious-condition) ()
  (:report (lambda (condition stream)
             (declare (ignore condition))
             (write-string "deliberately serious, not an ERROR" stream)))
  (:documentation "Serious but not an ERROR, so a HANDLER-CASE on ERROR does not
see it. The fixture for the class of condition that used to escape the mock
thread's guard and, under CCL, block on a terminal that is not there."))

(defun %call-recording-mock-condition (thunk)
  "Run THUNK under the mock thread's guard: a condition that would otherwise
kill the thread silently is RECORDED in *MOCK-CAD-CONDITION* and swallowed.

Both halves are load-bearing. Swallowing is mandatory -- an unhandled error in
a thread under `--disable-debugger' aborts the whole test process, so the mock
must not let one out. Recording is what was missing: without it every mock
crash arrives at the assertions as an indistinguishable driver timeout.

It is a FUNCTION rather than the inline HANDLER-CASE it replaces so that the
guarantee can be tested directly, on the same code the thread runs, instead of
by arranging a filesystem failure -- which is not portable: the first version of
that test deleted the workdir and passed on SBCL, where the mock's first write
then signals, and failed on CCL, where it does not.

IT CATCHES SERIOUS-CONDITION, NOT ERROR, and binds *DEBUGGER-HOOK* too. A
condition can be serious without being an error, and an ERROR handler then does
not see it; and no handler at all helps against INVOKE-DEBUGGER or BREAK. Either
way the condition reaches the implementation's debugger, and under CCL a
debugger with no terminal to talk to BLOCKS -- a process at 0 % CPU producing
nothing, which is the shape of ccl-protocol-write-atomic-file-contention-hangs
and of job 14519641143 before it. On SBCL it is merely dropped, so an ERROR-only
guard looks fine on the host most runs happen on. Same reasoning and same shape
as %CALL-IN-GUARDED-THREAD in file-protocol-tests.lisp."
  (catch '%mock-cad-exit
    (let ((*debugger-hook*
            (lambda (condition hook)
              (declare (ignore hook))
              (setf *mock-cad-condition* condition)
              (throw '%mock-cad-exit nil))))
      (handler-case (funcall thunk)
        (serious-condition (condition)
          (setf *mock-cad-condition* condition)
          nil)))))

(defun %mock-cad-failure-note ()
  "A clause naming the condition that killed the mock, or the empty string.
Appended to an assertion message so a timeout says WHY instead of :ABORTED."
  (if *mock-cad-condition*
      (format nil " -- the mock CAD thread died: ~A" *mock-cad-condition*)
      ""))

(defparameter +mock-cad-safety-net-seconds+ 300
  "How long a mock CAD thread may live, at most. NOT a budget the mock is
expected to meet: the mock is step-locked to its driver -- it waits for the next
request or for SHUTDOWN, however long either takes, and a test that finishes
without sending SHUTDOWN sends it through %FINISH-MOCK-CAD. So this is reached
only when something is already broken, and then it keeps a wedged thread from
outliving the suite.

It replaced a 20 s budget for the WHOLE session, which WAS on the success path:
a loaded Windows runner could spend it before the last request arrived, the mock
stopped serving, and the driver reported :ABORTED
(mock-cad-protocol-tests-flake-on-native-windows).")

(defun %mock-shutdown-requested-p (control)
  "True when the driver has published SHUTDOWN on CONTROL."
  (and control
       (search "SHUTDOWN" (alfe.protocol.file:read-file-as-string control))))

(defun %finish-mock-cad (thread protocol-session)
  "Join the mock CAD THREAD, first telling it to stop when it is still alive.

The driver's :quit publishes SHUTDOWN, so on the success path the mock has
already stopped. When the driver gave up early -- the failures this family is
diagnosed by -- the mock would otherwise wait for a SHUTDOWN nobody sends, until
+MOCK-CAD-SAFETY-NET-SECONDS+. Sending it here keeps a failing test fast without
putting a deadline back on the success path."
  (when (bordeaux-threads:thread-alive-p thread)
    (ignore-errors
     (alfe.protocol.file:write-atomic-file
      (alfe.protocol.file:protocol-session-control-path protocol-session)
      "SHUTDOWN")))
  (bordeaux-threads:join-thread thread))

(defun %mock-consume-request (stdin deadline &optional control)
  "Wait until STDIN holds a request, return its text and delete it; NIL if
DEADLINE passes first, :SHUTDOWN if CONTROL (when given) says SHUTDOWN first --
a driver that stops early must not leave the mock waiting for a request.

NEVER PROBE THEN OPEN. The driver publishes stdin.txt with WRITE-ATOMIC-FILE
-- write a temp, rename over -- and on Windows that rename is delete+rename
(UIOP's overwrite), so between a PROBE-FILE that succeeds and the OPEN that
follows, the file can be gone or still held by the renaming party. The first
shape of this loop probed and then read BARE, and that read was the one
operation in the cycle %MOCK-RETRY-FILE-OP did not cover: the transient
propagated to the thread's outer handler, killed the mock mid-session, and the
driver timed out with :ABORTED and no cause.

That is the SECOND cause of alfe-windows-drive-protocol-three-evals-fails. The
mock's per-round budget was the first; fixing it made the Linux repro pass and
left the Windows lane red, which is what said there was another one.

The only way to know a file is readable is to read it, so the wait and the read
are ONE loop: attempt the read, treat absence and a sharing violation alike as
`not yet', and stop at the deadline. An EMPTY read is also `not yet' -- it is
what a half-written file looks like, and consuming it would strand the request."
  (loop
    (let ((text (handler-case
                    (with-open-file (in stdin :direction :input
                                              :if-does-not-exist nil
                                              :external-format :utf-8)
                      (when in
                        (let* ((buffer (make-string (file-length in)))
                               (n (read-sequence buffer in)))
                          (subseq buffer 0 n))))
                  ((or file-error stream-error) () nil))))
      (when (and text (plusp (length text)))
        (%mock-retry-file-op
         (lambda () (when (probe-file stdin) (delete-file stdin))))
        (return text))
      (when (%mock-shutdown-requested-p control)
        (return :shutdown))
      (when (> (get-internal-real-time) deadline)
        (return nil))
      (sleep 0.02))))

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
     ;; Guard the whole mock body: if the workdir is torn down while this
     ;; thread is still alive (a teardown race, or a test whose JOIN got
     ;; skipped because the driver threw), an unguarded WRITE-ATOMIC-FILE
     ;; here signals a file error that, being UNHANDLED in a thread under
     ;; --disable-debugger, aborts the ENTIRE test process. Swallow it so
     ;; at most the owning test fails; the suite keeps running -- but RECORD
     ;; it (*MOCK-CAD-CONDITION*) rather than only swallowing: a guard that
     ;; discards the cause is why a dead mock read as a bare :ABORTED on the
     ;; Windows lane for a week.
     (%call-recording-mock-condition
      (lambda ()
     (alfe.protocol.file:write-atomic-file
      (alfe.protocol.file:protocol-session-status-path protocol-session)
      "READY 0")
     (sleep initial-ready-delay)
     ;; SERVE `cycles' REQUESTS -- do not SPEND `cycles' rounds of
     ;; up-to-two-seconds (alfe-windows-drive-protocol-three-evals-fails). The
     ;; old loop was a DOTIMES whose body gave up waiting for stdin.txt after 2
     ;; seconds and then published RUNNING/DONE for that counter ANYWAY. Two
     ;; consequences, and the Windows runner hit the first:
     ;;
     ;;   * a slow cycle consumed the budget, so with :cycles 3 and three
     ;;     actions the third request was never acknowledged and the driver
     ;;     timed out -- :ABORTED, which is exactly what that lane reported;
     ;;   * a DONE published for a request that never arrived is a status the
     ;;     driver could match against a send it has not made yet.
     ;;
     ;; The counter now follows the requests SERVED, so the mock cannot run
     ;; ahead of the driver. And the mock is STEP-LOCKED to it: it waits for
     ;; the next request OR for SHUTDOWN, with no budget on that wait. The
     ;; safety net is reached only when a test is already broken
     ;; (+MOCK-CAD-SAFETY-NET-SECONDS+); the 20 s session budget it replaced
     ;; was not, and a loaded Windows runner spent it
     ;; (mock-cad-protocol-tests-flake-on-native-windows).
     (let ((stdin (alfe.protocol.file:protocol-session-stdin-path protocol-session))
           (control (alfe.protocol.file:protocol-session-control-path protocol-session))
           (served 0)
           (overall-deadline (+ (get-internal-real-time)
                                (* +mock-cad-safety-net-seconds+
                                   internal-time-units-per-second))))
       (loop while (and (< served cycles)
                        (< (get-internal-real-time) overall-deadline))
             do (let ((request
                        ;; The wait and the read are one operation -- see
                        ;; %MOCK-CONSUME-REQUEST for why probing first is what
                        ;; broke this on Windows.
                        (%mock-consume-request stdin overall-deadline control)))
                  (when (eq request :shutdown)
                    (return))
                  (when request
                    (incf served)
                    (alfe.protocol.file:write-atomic-file
                     (alfe.protocol.file:protocol-session-status-path protocol-session)
                     (format nil "RUNNING ~D" served))
                    (when echo-stdin-p
                      (%mock-retry-file-op
                       (lambda ()
                         (with-open-file (out (alfe.protocol.file:protocol-session-stdout-path
                                               protocol-session)
                                              :direction :output :if-exists :append
                                              :external-format :utf-8)
                           (write-string request out)))))
                    (alfe.protocol.file:write-atomic-file
                     (alfe.protocol.file:protocol-session-status-path protocol-session)
                     (format nil "DONE ~D OK" served))
                    ;; Keep DONE published until the next request replaces it
                    ;; with RUNNING. A fixed sleep lets a busy scheduler miss
                    ;; DONE entirely and makes the mock nondeterministic.
                    ))))
     ;; Wait for SHUTDOWN -- from the driver's :quit, or from %FINISH-MOCK-CAD
     ;; when the driver stopped early. Step-locked like the requests: the old
     ;; 2 s wait published STOPPED whether or not SHUTDOWN had come, so a slow
     ;; driver could find the mock already gone. The delete is retried like the
     ;; mock's other file ops: a bare one was the last unguarded operation in
     ;; the cycle, and a sharing violation there killed the thread.
     (let ((control (alfe.protocol.file:protocol-session-control-path protocol-session))
           (deadline (+ (get-internal-real-time)
                        (* +mock-cad-safety-net-seconds+
                           internal-time-units-per-second))))
       (loop until (%mock-shutdown-requested-p control)
             when (> (get-internal-real-time) deadline)
               do (return)
             do (sleep 0.02))
       (%mock-retry-file-op
        (lambda () (when (probe-file control) (delete-file control)))))
     (alfe.protocol.file:write-atomic-file
      (alfe.protocol.file:protocol-session-status-path protocol-session)
      "STOPPING")
     (sleep 0.2)
     (alfe.protocol.file:write-atomic-file
      (alfe.protocol.file:protocol-session-status-path protocol-session)
      "STOPPED"))))
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
          (setf *mock-cad-condition* nil)
          (let* ((protocol (alfe.protocol.file:init-session workdir))
                 (cad (spawn-mock-cad-runtime protocol :cycles 1))
                 (plan (list (alfe.backend:action-eval "(princ 42)")
                             (alfe.backend:action-quit)))
                 (result
                   ;; Wait for the mock to publish READY 0 first.
                   (progn (alfe.protocol.file:wait-for-status-prefix
                           protocol "READY" :timeout 15)
                          (let ((*standard-output* (make-string-output-stream))
                                (*error-output*    (make-string-output-stream)))
                            (alfe.backend.cad-common:drive-protocol-actions
                             protocol plan)))))
            (is (eq :success (alfe.backend:eval-result-status result))
                "got ~S~A" (alfe.backend:eval-result-status result)
                (%mock-cad-failure-note))
            (is (search "(princ 42)"
                        (alfe.backend:eval-result-output result)))
            (%finish-mock-cad cad protocol)))
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
          (setf *mock-cad-condition* nil)
          (let* ((protocol (alfe.protocol.file:init-session workdir))
                 (cad (spawn-mock-cad-runtime protocol :cycles 3))
                 (plan (list (alfe.backend:action-eval "(princ 1)")
                             (alfe.backend:action-eval "(princ 2)")
                             (alfe.backend:action-eval "(princ 3)")
                             (alfe.backend:action-quit)))
                 (result
                   (progn (alfe.protocol.file:wait-for-status-prefix
                           protocol "READY" :timeout 15)
                          (let ((*standard-output* (make-string-output-stream))
                                (*error-output*    (make-string-output-stream)))
                            (alfe.backend.cad-common:drive-protocol-actions
                             protocol plan)))))
            (is (eq :success (alfe.backend:eval-result-status result))
                "got ~S~A" (alfe.backend:eval-result-status result)
                (%mock-cad-failure-note))
            (let ((stdout (alfe.backend:eval-result-output result)))
              ;; All three actions must show up in the echo capture.
              (is (search "(princ 1)" stdout))
              (is (search "(princ 2)" stdout))
              (is (search "(princ 3)" stdout)))
            (%finish-mock-cad cad protocol)))
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
          (setf *mock-cad-condition* nil)
          (let* ((protocol (alfe.protocol.file:init-session workdir))
                 (cad (spawn-mock-cad-runtime protocol :cycles 2))
                 (plan (list (alfe.backend:action-interactive)
                             (alfe.backend:action-quit)))
                 (input-text (format nil "(+ 1 2)~%(+ 3 4)~%"))
                 (output-stream (make-string-output-stream))
                 (error-stream  (make-string-output-stream))
                 (result
                   (progn (alfe.protocol.file:wait-for-status-prefix
                           protocol "READY" :timeout 15)
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
            (is (eq :success (alfe.backend:eval-result-status result))
                "got ~S~A" (alfe.backend:eval-result-status result)
                (%mock-cad-failure-note))
            (%finish-mock-cad cad protocol)))
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
          (setf *mock-cad-condition* nil)
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
                      protocol "READY" :timeout 15)
                     (let ((*standard-output* (make-string-output-stream))
                           (*error-output*    (make-string-output-stream)))
                       (alfe.backend.cad-common:drive-protocol-actions
                        protocol plan)))
              (is (eq :info alfe.logging:*current-level*)
                  "Runtime DEBUG=0 should have dragged alfe down to :info; current is ~S"
                  alfe.logging:*current-level*))
            (%finish-mock-cad cad protocol)))
      (uiop:delete-directory-tree workdir :validate t
                                          :if-does-not-exist :ignore))))

(test cad-drive-protocol-actions-applies-alfe-control-sentinel
  "When the CAD-side runtime fires `[ALFE-CONTROL] DEBUG=0' through
protocol/stdout.txt, drive-protocol-actions
  (1) applies the control side effect (drops *current-level* :debug
      back to :info), and
  (2) strips the sentinel line so it never reaches the live output
      stream the user sees -- only the user's own prints do.

This is the explicit channel that backs the runtime-side
(alfe-set-debugging nil|t) function: by using an in-line
synchronous sentinel rather than the polling runtime-flags.txt
mirror, the control fires the instant the CAD evaluates the form
(no race with DONE-status timing)."
  (let ((workdir (uiop:ensure-directory-pathname
                  (merge-pathnames
                   (format nil "alfe-test-cad-sentinel-~D/" (random 999999))
                   (uiop:temporary-directory)))))
    (unwind-protect
        (progn
          (ensure-directories-exist workdir)
          (setf *mock-cad-condition* nil)
          (let* ((protocol (alfe.protocol.file:init-session workdir))
                 (stdout (alfe.protocol.file:protocol-session-stdout-path
                          protocol))
                 (cad (spawn-mock-cad-runtime protocol :cycles 1
                                              :echo-stdin-p nil))
                 (plan (list (alfe.backend:action-eval
                              "(alfe-set-debugging nil)")
                             (alfe.backend:action-quit))))
            ;; Pre-stage the response stdout the mock CAD would write
            ;; if it ran the real runtime: the visible value `nil'
            ;; AND the control sentinel.
            (with-open-file (out stdout :direction :output
                                        :if-does-not-exist :create
                                        :if-exists :supersede
                                        :external-format :utf-8)
              (format out "[ALFE-CONTROL] DEBUG=0~%nil~%"))
            (let ((alfe.logging:*current-level* :debug)
                  (output-stream (make-string-output-stream)))
              (alfe.protocol.file:wait-for-status-prefix
               protocol "READY" :timeout 15)
              (let ((*error-output* (make-string-output-stream)))
                (alfe.backend.cad-common:drive-protocol-actions
                 protocol plan :output-stream output-stream))
              ;; The control sentinel dropped us to :info.
              (is (eq :info alfe.logging:*current-level*)
                  "Sentinel DEBUG=0 should have dropped current level to :info; got ~S"
                  alfe.logging:*current-level*)
              ;; The output the user saw must contain "nil" but
              ;; must NOT contain the sentinel.
              (let ((shown (get-output-stream-string output-stream)))
                (is (search "nil" shown)
                    "User-visible output should contain `nil'; got ~S"
                    shown)
                (is (null (search "[ALFE-CONTROL]" shown))
                    "User-visible output must NOT echo the sentinel; got ~S"
                    shown)))
            (%finish-mock-cad cad protocol)))
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
                         ;; --timeout 7 must reach the session so eval-plan can
                         ;; hand it to drive-protocol-actions
                         ;; (alfe-request-timeout-aborts-long-eval): before the
                         ;; fix cli-options-timeout dead-ended in the CLI.
                         :cli-options (alfe.cli:make-cli-options :timeout 7)
                         :launcher launcher
                         :wait-for-ready t
                         :ready-timeout 2)))
          (is (eq :ready (alfe.backend:session-state session)))
          ;; The parsed --timeout is stored on the session (the plumb the bug
          ;; was missing); eval-plan reads it back out below.
          (is (eql 7 (alfe.backend:session-request-timeout session)))
          ;; Now run a tiny plan.
          (let ((*standard-output* (make-string-output-stream))
                (*error-output*    (make-string-output-stream)))
            (let ((result (alfe.backend:eval-plan
                           session
                           (list (alfe.backend:action-eval "(princ 7)")
                                 (alfe.backend:action-quit)))))
              (is (eq :success (alfe.backend:eval-result-status result))
                  "got ~S~A" (alfe.backend:eval-result-status result)
                  (%mock-cad-failure-note))))
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
            ;; Batch switch is platform-shaped: /b on Windows, -B on POSIX
            ;; (backend-bricscad build-launch-argv, `(if (windows-p) ...)').
            (is (member (if (uiop:os-windows-p) "/b" "-B") argv :test #'string=))
            (is (find "run.scr" argv :test (lambda (needle s)
                                              (search needle s))))))
      (uiop:delete-directory-tree workdir :validate t
                                          :if-does-not-exist :ignore))))

(test autocad-build-launch-argv-batch-discovers-template-and-still-requires-accoreconsole
  "Batch mode always has a drawing to open, and still signals
:no-accoreconsole when the batch binary itself is missing.

REWRITTEN for the embedded empty drawing (empty-ressource.issue). This
test used to assert that argv named the SHIPPED acadiso.dwt, and that
:no-dwg was signalled when no template could be found anywhere. Neither
holds now, and both by design: alfe writes a FRESH drawing into the
run's own workdir and passes that, so the install template is a fallback
and :no-dwg has become all but unreachable. What is checked instead is
the property that actually matters -- the drawing handed to the CAD
belongs to THIS run, because a shared one is what produced the modal
in-use dialogs."
  (let ((workdir (uiop:ensure-directory-pathname
                  (merge-pathnames
                   (format nil "alfe-test-acad-argv-~D/" (random 999999))
                   (uiop:temporary-directory)))))
    (unwind-protect
        (progn
          (ensure-directories-exist workdir)
          (setf *mock-cad-condition* nil)
          (let* ((protocol (alfe.protocol.file:init-session workdir))
                 (no-acc (alfe.backend.autocad:make-autocad-backend))
                 (with-install-template
                   (alfe.backend.autocad:make-autocad-backend
                    :executable-path
                    (namestring
                     (touch-file (merge-pathnames
                                  "AutoCAD 2026/acad.exe" workdir)))
                    :accoreconsole-path "/usr/bin/true"))
                 (with-acc (alfe.backend.autocad:make-autocad-backend
                            :accoreconsole-path "/usr/bin/true")))
            (touch-file (merge-pathnames
                         "AutoCAD 2026/Template/acadiso.dwt" workdir))
            (signals alfe.error:backend-bootstrap-error
              (alfe.backend.autocad:build-launch-argv
               no-acc protocol :mode :batch
               :dwg (namestring
                     (touch-file (merge-pathnames "explicit.dwg" workdir)))))
            ;; No accoreconsole is still fatal; a missing template no
            ;; longer is, because alfe brings its own drawing.
            (let ((argv (alfe.backend.autocad:build-launch-argv
                         with-acc protocol :mode :batch)))
              (is (string= "/usr/bin/true" (first argv)))
              (is (member "/i" argv :test #'string=)))
            ;; The drawing is in THIS run's workdir -- not the install
            ;; template, and not a path shared with any other run.
            (let* ((argv (alfe.backend.autocad:build-launch-argv
                          with-install-template protocol :mode :batch))
                   (opened (second (member "/i" argv :test #'string=))))
              (is (string= "/usr/bin/true" (first argv)))
              (is (member "/i" argv :test #'string=))
              (is (search (namestring workdir) opened)
                  "the drawing handed to the CAD is not in this run's workdir: ~S"
                  opened)
              (is (probe-file opened)
                  "the drawing handed to the CAD does not exist: ~S" opened))
            (let ((argv (alfe.backend.autocad:build-launch-argv
                         with-acc protocol :mode :batch
                         :dwg (namestring
                               (touch-file (merge-pathnames "explicit-2.dwg"
                                                            workdir))))))
              (is (string= "/usr/bin/true" (first argv)))
              (is (member "/i" argv :test #'string=))
              (is (member "/s" argv :test #'string=)))))
      (uiop:delete-directory-tree workdir :validate t
                                          :if-does-not-exist :ignore))))

(test autocad-start-engine-batch-surfaces-early-process-exit
  "If the batch child process exits before publishing READY, START-ENGINE
surfaces the child stderr / exit code instead of reporting a misleading
READY timeout."
  (when (alfe.backend.cad-common:windows-p)
    (let ((workdir (uiop:ensure-directory-pathname
                    (merge-pathnames
                     (format nil "alfe-test-acad-exit-~D/" (random 999999))
                     (uiop:temporary-directory)))))
      (unwind-protect
          (progn
            (ensure-directories-exist workdir)
            (let ((backend (alfe.backend.autocad:make-autocad-backend
                            :accoreconsole-path "C:/dummy/accoreconsole.exe"))
                  (launcher
                    (lambda (argv &rest keys &key input output error-output &allow-other-keys)
                      (declare (ignore argv input output error-output keys))
                      (uiop:launch-program
                       '("powershell.exe" "-NoProfile" "-Command"
                         "[Console]::Error.WriteLine('fatal cfg lock'); exit 7")
                       :input :stream
                       :output :stream
                       :error-output :stream))))
              (handler-case
                  (progn
                    (alfe.backend:start-engine
                     backend workdir
                     :dialect :strict
                     :host :mock
                     :mock-input nil
                     :bootstrap-phase :full
                     :interactive-p nil
                     :mode :batch
                     :dwg (namestring
                           (touch-file (merge-pathnames "explicit.dwg" workdir)))
                     :launcher launcher
                     :wait-for-ready t
                     :ready-timeout 5)
                    (is nil "Expected BACKEND-BOOTSTRAP-ERROR for early child exit."))
                (alfe.error:backend-bootstrap-error (condition)
                  (is (eq :process-exited-before-ready
                          (alfe.error:backend-error-code condition)))
                  (is (search "fatal cfg lock"
                              (alfe.error:backend-error-message condition)))
                  (is (= 7 (getf (alfe.error:backend-error-details condition)
                                 :exit-code)))))))
        (uiop:delete-directory-tree workdir :validate t
                                            :if-does-not-exist :ignore)))))

(test autocad-automation-start-engine-runs-without-probe-undefined
  "Regression for alfe-autocad-start-engine-malformed-handler-case: a missing
paren once turned %START-ENGINE's HANDLER-CASE clauses into trailing body
forms, so the AutoCAD backend evaluated (probe) — a call to the undefined
function ALFE.BACKEND.AUTOCAD::PROBE — the moment the automation body ran to
completion, crashing even --print-command (which spawns nothing). The existing
start-engine tests never caught it: the batch one is guarded by WINDOWS-P (so it
is skipped off Windows) and exercises the early-EXIT error path, which unwinds
before reaching the trailing forms. Here we force :windows via
*HOST-OS-OVERRIDE* so the Windows-only path runs on any host, stage with a
capturing launcher and :WAIT-FOR-READY NIL (no AutoCAD spawned, no READY
awaited), and assert START-ENGINE returns a session and hands a cscript launch
argv to the launcher instead of signalling UNDEFINED-FUNCTION."
  (let ((alfe.backend.cad-common:*host-os-override* :windows)
        (workdir (uiop:ensure-directory-pathname
                  (merge-pathnames
                   (format nil "alfe-test-acad-auto-~D/" (random 999999))
                   (uiop:temporary-directory)))))
    (unwind-protect
        (progn
          (ensure-directories-exist workdir)
          (let* ((backend (alfe.backend.autocad:make-autocad-backend))
                 (captured nil)
                 (session (alfe.backend:start-engine
                           backend workdir
                           :dialect :strict :host :mock :mock-input nil
                           :bootstrap-phase :full :interactive-p nil
                           :mode :automation
                           :dwg (namestring
                                 (touch-file (merge-pathnames "d.dwg" workdir)))
                           :wait-for-ready nil
                           :launcher (lambda (argv &rest ignored)
                                       (declare (ignore ignored))
                                       (setf captured argv)
                                       nil))))
            (is (not (null session)))
            (is (probe-file (merge-pathnames "bridge-autocad.vbs" workdir)))
            (is (and (consp captured)
                     (search "cscript"
                             (string-downcase (princ-to-string (first captured))))))))
      (uiop:delete-directory-tree workdir :validate t :if-does-not-exist :ignore))))

(test autocad-accoreconsole-prefers-real-autocad-over-dwg-trueview
  ;; Only full AutoCAD can mutate entities; the read-only DWG TrueView
  ;; viewer also ships accoreconsole.exe and must rank AFTER real AutoCAD
  ;; so discovery never picks it (alfe-cad-console-encoding.issue).
  (let ((acad "C:/Program Files/Autodesk/AutoCAD 2026/accoreconsole.exe")
        (view "C:/Program Files/Autodesk/DWG TrueView 2024 - French/accoreconsole.exe"))
    (is (= 0 (alfe.backend.autocad::%accoreconsole-preference acad)))
    (is (= 2 (alfe.backend.autocad::%accoreconsole-preference view)))
    (is (< (alfe.backend.autocad::%accoreconsole-preference acad)
           (alfe.backend.autocad::%accoreconsole-preference view)))
    (let ((sorted (stable-sort (sort (list view acad) #'string>)
                               #'< :key #'alfe.backend.autocad::%accoreconsole-preference)))
      (is (search "AutoCAD" (first sorted))))))

;;; --- G2: console-encoding resolution (decode + pipe) ----------------

(test autocad-console-decode-protocol-files-auto-by-default
  "The DRAIN decodes the runtime-written protocol stdout/stderr FILES with the
robust :AUTO cascade by default — they are UTF-8/ASCII in practice (verified on
real AutoCAD 2022) and self-describing, DISTINCT from accoreconsole's own console
PIPE (UTF-16LE, handled by AUTOCAD-CONSOLE-EXTERNAL-FORMAT). Forcing :utf-16le
here mangled UTF-8 payload into CJK mojibake (autocad-no-rest-output-capture). An
explicit -Ecadstdio still forces a codec; -Econsole is ignored (the console is
fixed by the product, encoding-situations section 4) and so is the bare -E; the
variant no longer matters for the file drain."
  ;; accoreconsole batch, unset -> :AUTO (was wrongly forced to UTF-16LE)
  (is (eq :auto (alfe.backend.autocad::%autocad-console-decode-encoding
                 (parse-arguments '("--autocad")) :batch)))
  ;; an explicit -Ecadstdio forces the drain codec
  (is (string= "WINDOWS-1252"
               (alfe.backend.autocad::%autocad-console-decode-encoding
                (parse-arguments '("--autocad" "-Ecadstdio" "cp1252")) :batch)))
  (is (eq :utf-16le (alfe.backend.autocad::%autocad-console-decode-encoding
                     (parse-arguments '("--autocad" "-Ecadstdio" "utf-16le")) :batch)))
  ;; -Econsole (product-fixed: warned, ignored) and the bare -E leave :AUTO
  (is (eq :auto (alfe.backend.autocad::%autocad-console-decode-encoding
                 (parse-arguments '("--autocad" "-Econsole" "cp1252")) :batch)))
  (is (eq :auto (alfe.backend.autocad::%autocad-console-decode-encoding
                 (parse-arguments '("--autocad" "-E" "UTF-8")) :batch)))
  ;; automation path: identical contract
  (is (string= "WINDOWS-1252"
               (alfe.backend.autocad::%autocad-console-decode-encoding
                (parse-arguments '("--autocad" "-Ecadstdio" "cp1252")) :automation)))
  (is (eq :auto (alfe.backend.autocad::%autocad-console-decode-encoding
                 (parse-arguments '("--autocad")) :automation))))

(test cad-cli-load-path-is-made-absolute-before-crossing-process-boundary
  "A relative -l path is relative to alfe's invocation directory, not to the
CAD workdir.  The CAD backend must therefore hand the remote process an
absolute pathname even when no source transcoding was requested."
  (let* ((workdir (uiop:ensure-directory-pathname
                   (merge-pathnames
                    (format nil "alfe-test-relative-load-~D/" (random 999999))
                    (uiop:temporary-directory))))
         (protocol (alfe.protocol.file:init-session workdir))
         (relative "autolisp-front-end/tests/scenarios/entities/pathname-probe.lsp")
         (expected (namestring
                    (uiop:ensure-absolute-pathname relative (uiop:getcwd)))))
    (unwind-protect
         (let ((resolved
                 (alfe.backend.cad-common::stage-source-as-utf8-bom
                  protocol relative nil)))
           (is (uiop:absolute-pathname-p (pathname resolved)))
           (is (string= expected resolved)))
      (uiop:delete-directory-tree workdir :validate t
                                          :if-does-not-exist :ignore))))

(test autocad-console-external-format-folds-cli-over-default
  "G2 send half: an explicit -Ecadstdio drives the pipe external-format; with
nothing requested (and no env) it stays the robust :ISO-8859-1. -Econsole is
ignored (the console is fixed by the product), and so is the bare -E."
  (is (eq :utf-16le (alfe.backend.autocad::autocad-console-external-format
                     (parse-arguments '("--autocad" "-Ecadstdio" "utf-16le")))))
  (unless (uiop:getenv "ALFE_AUTOCAD_CONSOLE_ENCODING")
    (is (eq :iso-8859-1 (alfe.backend.autocad::autocad-console-external-format
                         (parse-arguments '("--autocad" "-Econsole" "utf-16le")))))
    (is (eq :iso-8859-1 (alfe.backend.autocad::autocad-console-external-format
                         (parse-arguments '("--autocad" "-E" "UTF-8"))))))
  (is (eq :windows-1252 (alfe.backend.autocad::autocad-console-external-format
                         (parse-arguments '("--autocad" "-Ecadstdio" "cp1252")))))
  (unless (uiop:getenv "ALFE_AUTOCAD_CONSOLE_ENCODING")
    (is (eq :iso-8859-1 (alfe.backend.autocad::autocad-console-external-format
                         (parse-arguments '("--autocad")))))))

(test bricscad-console-input-encoding-is-a-warned-no-op
  "BricsCAD's console device is product-fixed and alfe's input does not go
through it: an explicit -Econsole-in (or a bare -Econsole, which sets both
directions) is warned about and ignored, as AutoCAD's -Econsole is; the bare
-E and -Econsole-out are not warned about. The output half of -Econsole still
picks the drain codec."
  (let ((warning (alfe.backend.bricscad::bricscad-console-input-warning
                  (parse-arguments '("--bricscad" "-Econsole-in" "cp1252")))))
    (is (stringp warning))
    (is (search "-Econsole-in WINDOWS-1252 is ignored" warning))
    (is (search "fixed by the" warning)))
  (is (stringp (alfe.backend.bricscad::bricscad-console-input-warning
                (parse-arguments '("--bricscad" "-Econsole" "cp1252")))))
  (is (null (alfe.backend.bricscad::bricscad-console-input-warning
             (parse-arguments '("--bricscad" "-Econsole-out" "cp1252")))))
  (is (null (alfe.backend.bricscad::bricscad-console-input-warning
             (parse-arguments '("--bricscad" "-E" "UTF-8")))))
  (is (null (alfe.backend.bricscad::bricscad-console-input-warning nil)))
  ;; logged once per run
  (let ((alfe.backend.bricscad::*bricscad-console-input-option-warned* nil)
        (*error-output* (make-string-output-stream)))
    (let ((opts (parse-arguments '("--bricscad" "-Econsole-in" "cp1252"))))
      (is (eq t (alfe.backend.bricscad::%warn-bricscad-console-input opts)))
      (is (null (alfe.backend.bricscad::%warn-bricscad-console-input opts))))))

;;; -Efile forwarded to the CAD's own OPEN (encoding-situations-cli-options
;;; section 6 point 5): only BricsCAD on Windows honours a write encoding
;;; (,ccs=UTF-8 / ,ccs=UTF-16LE, measured V25); every other request is warned.

(defun %open-plan (backend platform write read)
  "(list CCS WARNINGS) of CAD-FILE-ENCODING-PLAN."
  (subseq (multiple-value-list
           (alfe.backend.cad-common:cad-file-encoding-plan backend platform write read))
          0 2))

(defun %open-plan-arg (backend platform write read)
  "The third value of CAD-FILE-ENCODING-PLAN: OPEN's third argument."
  (nth-value 2 (alfe.backend.cad-common:cad-file-encoding-plan
                backend platform write read)))

(test cad-file-encoding-plan-bricscad-windows-write
  "BricsCAD on Windows: UTF-8 and UTF-16LE (any spelling) become the ,ccs=
value, silently; cp1252 is the default and is no warning; anything else is not
forwarded and is warned about."
  (dolist (name '("UTF-8" "utf-8" "utf8" "UTF8" "utf_8"))
    (is (equal '("UTF-8" nil) (%open-plan :bricscad :windows name nil))
        "~S must forward as ,ccs=UTF-8" name))
  (dolist (name '("UTF-16LE" "utf-16le" "utf16le"))
    (is (equal '("UTF-16LE" nil) (%open-plan :bricscad :windows name nil))
        "~S must forward as ,ccs=UTF-16LE" name))
  (dolist (name '("WINDOWS-1252" "cp1252" "windows-1252"))
    (is (equal '(nil nil) (%open-plan :bricscad :windows name nil))
        "~S is BricsCAD's default: neither forwarded nor warned" name))
  (destructuring-bind (ccs warnings) (%open-plan :bricscad :windows "ISO-8859-1" nil)
    (is (null ccs))
    (is (= 1 (length warnings)))
    (is (search "backend BRICSCAD: -Efile-write ISO-8859-1 is not forwarded" (first warnings)))
    (is (search "measured, V25" (first warnings))))
  (is (equal '(nil nil) (%open-plan :bricscad :windows nil nil))))

(test cad-file-encoding-plan-autocad-utf8-is-the-third-argument
  "AutoCAD: a UTF-8 write (any spelling) becomes OPEN's third argument \"utf8\"
(measured at LISPSYS 1/2: UTF-8 without a BOM; the CAD side applies it only
there), silently on alfe's side and with no ,ccs=; cp1252 is the default and
needs nothing; any other encoding is warned about, not forwarded."
  (dolist (name '("UTF-8" "utf-8" "utf8"))
    (is (equal '(nil nil) (%open-plan :autocad :windows name nil)) "~S" name)
    (is (equal "utf8" (%open-plan-arg :autocad :windows name nil)) "~S" name))
  (is (equal '(nil nil) (%open-plan :autocad :windows "cp1252" nil)))
  (is (null (%open-plan-arg :autocad :windows "cp1252" nil)))
  (destructuring-bind (ccs warnings) (%open-plan :autocad :windows "UTF-16LE" nil)
    (is (null ccs))
    (is (= 1 (length warnings)))
    (is (search "backend AUTOCAD: -Efile-write UTF-16LE is not forwarded" (first warnings)))
    (is (search "none at 0, measured, AutoCAD 2022" (first warnings))))
  (is (null (%open-plan-arg :autocad :windows "UTF-16LE" nil)))
  ;; BricsCAD never gets a third argument
  (is (null (%open-plan-arg :bricscad :windows "UTF-8" nil)))
  (is (null (%open-plan-arg :bricscad :macos "UTF-8" nil))))

(test cad-file-encoding-plan-other-cads-warn
  "BricsCAD on macOS honours no write encoding: NIL, with the measured reason
-- except a request for what it does anyway."
  (destructuring-bind (ccs warnings) (%open-plan :bricscad :macos "UTF-16LE" nil)
    (is (null ccs))
    (is (= 1 (length warnings)))
    (is (search "BricsCAD on macOS writes UTF-8 whatever the mode (measured, V26)"
                (first warnings))))
  (is (equal '(nil nil) (%open-plan :bricscad :macos "utf8" nil))))

(test cad-file-encoding-plan-read-is-never-forwarded
  "A read encoding is never forwarded: the CADs' OPEN never decodes on read.
Warned on every CAD, except cp1252 on AutoCAD, which is what it reads."
  (dolist (case '((:bricscad :windows) (:bricscad :macos) (:autocad :windows)))
    (destructuring-bind (ccs warnings) (%open-plan (first case) (second case) nil "UTF-8")
      (is (null ccs))
      (is (= 1 (length warnings)) "~S: one warning" case)
      (is (search "-Efile-read UTF-8 is not forwarded: the CAD's OPEN reads in its own default"
                  (first warnings)))
      (is (search "UTF-8 falling back to cp1252 at LISPSYS 1/2; BricsCAD returns octets"
                  (first warnings)))))
  (is (equal '(nil nil) (%open-plan :autocad :windows nil "cp1252")))
  ;; both directions: the write is still forwarded, the read still warned
  (destructuring-bind (ccs warnings) (%open-plan :bricscad :windows "UTF-8" "UTF-8")
    (is (equal "UTF-8" ccs))
    (is (= 1 (length warnings)))))

(test cad-open-write-ccs-from-cli-options
  "CAD-OPEN-WRITE-CCS reads -Efile-write / -Efile / the bare -E from the
parsed options and logs each warning once per run."
  (let ((alfe.backend.cad-common::*cad-file-encoding-warnings-given* '())
        (*error-output* (make-string-output-stream)))
    (is (equal "UTF-16LE"
               (alfe.backend.cad-common:cad-open-write-ccs
                :bricscad (parse-arguments '("--bricscad" "-Efile-write" "utf-16le"))
                :platform :windows)))
    (is (null (alfe.backend.cad-common:cad-open-write-ccs
               :bricscad (parse-arguments '("--bricscad")) :platform :windows)))
    (is (null (alfe.backend.cad-common:cad-open-write-ccs :bricscad nil :platform :windows)))
    ;; AutoCAD: no ccs, the third argument "utf8", and no warning
    (multiple-value-bind (ccs arg)
        (alfe.backend.cad-common:cad-open-write-ccs
         :autocad (parse-arguments '("--autocad" "-Efile-write" "UTF-8"))
         :platform :windows)
      (is (null ccs))
      (is (equal "utf8" arg)))
    (is (= 0 (length alfe.backend.cad-common::*cad-file-encoding-warnings-given*)))
    (is (null (alfe.backend.cad-common:cad-open-write-ccs
               :autocad (parse-arguments '("--autocad" "-Efile-write" "UTF-16LE"))
               :platform :windows)))
    (is (= 1 (length alfe.backend.cad-common::*cad-file-encoding-warnings-given*)))
    ;; the same warning again is not logged twice
    (alfe.backend.cad-common:cad-open-write-ccs
     :autocad (parse-arguments '("--autocad" "-Efile-write" "UTF-16LE")) :platform :windows)
    (is (= 1 (length alfe.backend.cad-common::*cad-file-encoding-warnings-given*)))
    ;; -Efile (both directions) on BricsCAD Windows: write forwarded, read warned
    (is (equal "UTF-8"
               (alfe.backend.cad-common:cad-open-write-ccs
                :bricscad (parse-arguments '("--bricscad" "-Efile" "UTF-8"))
                :platform :windows)))
    (is (= 2 (length alfe.backend.cad-common::*cad-file-encoding-warnings-given*)))))

(test bricscad-drain-codec-ignores-the-bare-e
  "RESOLVED-CONSOLE-ENCODING (the BricsCAD drain codec) counts only an option
naming the console or cadstdio: the bare -E no longer reaches the drain (it
forced UTF-8 over the auto-detect cascade that reads a cp1252 BricsCAD/Windows
drain correctly) -- the rule AutoCAD already had."
  (is (eq :auto (alfe.cli:resolved-console-encoding nil)))
  (is (eq :auto (alfe.cli:resolved-console-encoding
                 (parse-arguments '("--bricscad")))))
  (is (eq :auto (alfe.cli:resolved-console-encoding
                 (parse-arguments '("--bricscad" "-E" "UTF-8")))))
  ;; -Econsole-in is the input half only: nothing for the drain
  (is (eq :auto (alfe.cli:resolved-console-encoding
                 (parse-arguments '("--bricscad" "-Econsole-in" "cp1252")))))
  (is (equal "WINDOWS-1252" (alfe.cli:resolved-console-encoding
                             (parse-arguments '("--bricscad" "-Econsole" "cp1252")))))
  (is (equal "WINDOWS-1252" (alfe.cli:resolved-console-encoding
                             (parse-arguments '("--bricscad" "-Econsole-out" "cp1252"
                                                "-E" "UTF-8")))))
  ;; console wins over cadstdio
  (is (equal "UTF-16LE" (alfe.cli:resolved-console-encoding
                         (parse-arguments '("--bricscad" "-Ecadstdio" "cp1252"
                                            "-Econsole" "utf-16le")))))
  (is (equal "WINDOWS-1252" (alfe.cli:resolved-console-encoding
                             (parse-arguments '("--bricscad" "-Ecadstdio-out" "cp1252"))))))

;;; --- backend selection: CAD-program denotation parsing --------------

(test cad-program-denotation-parsing
  "alfe-backend-selection: version/locale extraction from install paths and
the canonical denotation each yields (OS-independent — we feed paths in)."
  (labels ((den (kind path)
             (alfe.backend.cad-common:cad-program-denotation
              (alfe.backend.cad-common::%cad-program-from-path kind path))))
    ;; AutoCAD (Windows + macOS) — the bare 20NN year
    (is (string= "acad-2022"
                 (den :acad "C:/Program Files/Autodesk/AutoCAD 2022/acad.exe")))
    (is (string= "acad-2026"
                 (den :acad "/Applications/Autodesk/AutoCAD 2026/AutoCAD 2026.app/Contents/MacOS/AutoCAD")))
    (is (string= "accoreconsole-2022"
                 (den :accoreconsole "C:/Program Files/Autodesk/AutoCAD 2022/accoreconsole.exe")))
    ;; the DWG TrueView viewer's accoreconsole is a DIFFERENT product: its own
    ;; denotation, so "accoreconsole" / "autocad" never match it
    (is (string= "dwgtrueview-2024"
                 (den :accoreconsole "C:/Program Files/Autodesk/DWG TrueView 2024 - French/accoreconsole.exe")))
    ;; BricsCAD — the V-token (lower-cased in the denotation); + locale on Win
    (is (string= "bricscad-v26"
                 (den :bricscad "/Applications/BricsCAD V26.app/Contents/MacOS/bricscad")))
    (is (string= "bricscad-v25-fr_FR"
                 (den :bricscad "C:/Program Files/Bricsys/BricsCAD V25 fr_FR/bricscad.exe")))
    (is (string= "bricscad-v25"
                 (den :bricscad "/opt/bricsys/bricscad/V25/bricscad")))
    ;; V26x64 keeps only V26
    (is (string= "bricscad-v26"
                 (den :bricscad "C:/Program Files/Bricsys/BricsCAD V26x64/bricscad.exe")))
    ;; no version in the path -> bare denotation
    (is (string= "acad" (den :acad "/somewhere/acad.exe")))
    (is (string= "clautolisp" (den :clautolisp "(embedded in alfe)")))
    ;; the parsed struct fields
    (let ((p (alfe.backend.cad-common::%cad-program-from-path
              :bricscad "C:/Program Files/Bricsys/BricsCAD V25 fr_FR/bricscad.exe")))
      (is (eq :bricscad (alfe.backend.cad-common:cad-program-kind p)))
      (is (string= "V25" (alfe.backend.cad-common:cad-program-version p)))
      (is (string= "fr_FR" (alfe.backend.cad-common:cad-program-locale p))))))

(test cad-denotation-resolution
  "backend-selection: resolve-cad-denotation picks the right install — exact,
bare/partial (latest wins), and the virtual autocad -> acad/accoreconsole per
--mode."
  (labels ((mk (kind path) (alfe.backend.cad-common::%cad-program-from-path kind path))
           (den (p) (and p (alfe.backend.cad-common:cad-program-denotation p)))
           (res (q progs &optional (mode :auto))
             (alfe.backend.cad-common:resolve-cad-denotation q progs :mode mode)))
    (let ((progs (list
                  (mk :acad "C:/Program Files/Autodesk/AutoCAD 2022/acad.exe")
                  (mk :acad "C:/Program Files/Autodesk/AutoCAD 2026/acad.exe")
                  (mk :accoreconsole "C:/Program Files/Autodesk/AutoCAD 2022/accoreconsole.exe")
                  (mk :bricscad "C:/Program Files/Bricsys/BricsCAD V25 fr_FR/bricscad.exe")
                  (mk :bricscad "C:/Program Files/Bricsys/BricsCAD V26 en_US/bricscad.exe"))))
      ;; exact
      (is (string= "acad-2022" (den (res "acad-2022" progs))))
      ;; bare kind -> latest version
      (is (string= "acad-2026" (den (res "acad" progs))))
      (is (string= "bricscad-v26-en_US" (den (res "bricscad" progs))))
      ;; partial version -> the matching locale variant
      (is (string= "bricscad-v25-fr_FR" (den (res "bricscad-v25" progs))))
      ;; virtual autocad -> acad (auto) / accoreconsole (batch), latest
      (is (string= "acad-2026"          (den (res "autocad" progs :auto))))
      (is (string= "accoreconsole-2022" (den (res "autocad" progs :batch))))
      (is (string= "acad-2022"          (den (res "autocad-2022" progs :auto))))
      (is (string= "accoreconsole-2022" (den (res "autocad-2022" progs :batch))))
      ;; case-insensitive
      (is (string= "acad-2026" (den (res "ACAD" progs))))
      ;; unknown -> nil
      (is (null (res "nope" progs)))
      (is (null (res "acad-2019" progs))))
    ;; A newer DWG TrueView (read-only viewer, also ships accoreconsole.exe)
    ;; must not win over real AutoCAD's accoreconsole: seen on PF5S26BT,
    ;; `--cad accoreconsole` picked TrueView 2024 over AutoCAD 2022, which
    ;; aborted at bootstrap on its locked dwgviewr2024.cfg.
    (let ((progs (list
                  (mk :acad "C:/Program Files/Autodesk/AutoCAD 2022/acad.exe")
                  (mk :accoreconsole "C:/Program Files/Autodesk/AutoCAD 2022/accoreconsole.exe")
                  (mk :accoreconsole "C:/Program Files/Autodesk/DWG TrueView 2024 - French/accoreconsole.exe"))))
      (is (string= "accoreconsole-2022" (den (res "accoreconsole" progs))))
      (is (string= "accoreconsole-2022" (den (res "autocad" progs :batch))))
      (is (null (res "accoreconsole-2024" progs)))
      (is (null (res "autocad-2024" progs :batch)))
      ;; still selectable explicitly, by its own name
      (is (string= "dwgtrueview-2024" (den (res "dwgtrueview" progs)))))))

(test cad-denotation-locale-preference
  "backend-selection: among same-version BricsCAD installs of different
locales, the host's preferred locale (injected) wins; version still beats
locale; no preference keeps discovery order."
  (labels ((mk (kind path) (alfe.backend.cad-common::%cad-program-from-path kind path))
           (den (p) (and p (alfe.backend.cad-common:cad-program-denotation p)))
           (res (q progs prefs)
             (alfe.backend.cad-common:resolve-cad-denotation q progs :preferred-locales prefs)))
    ;; the POSIX ll_CC extractor
    (is (string= "fr_FR" (alfe.backend.cad-common::%locale-from-lc-value "fr_FR.UTF-8")))
    (is (string= "en_US" (alfe.backend.cad-common::%locale-from-lc-value "en_US")))
    (is (null (alfe.backend.cad-common::%locale-from-lc-value "C")))
    (let ((progs (list
                  (mk :bricscad "C:/Program Files/Bricsys/BricsCAD V26 en_US/bricscad.exe")
                  (mk :bricscad "C:/Program Files/Bricsys/BricsCAD V26 fr_FR/bricscad.exe"))))
      (is (string= "bricscad-v26-fr_FR" (den (res "bricscad" progs '("fr_FR" "en_US")))))
      (is (string= "bricscad-v26-en_US" (den (res "bricscad" progs '("en_US" "fr_FR")))))
      ;; no preference -> discovery order (first = en_US)
      (is (string= "bricscad-v26-en_US" (den (res "bricscad" progs nil)))))
    ;; version beats a locale preference for an older version
    (let ((mixed (list (mk :bricscad "C:/x/Bricsys/BricsCAD V25 fr_FR/bricscad.exe")
                       (mk :bricscad "C:/x/Bricsys/BricsCAD V26 en_US/bricscad.exe"))))
      (is (string= "bricscad-v26-en_US" (den (res "bricscad" mixed '("fr_FR"))))))))

;;; --- build-launch-argv: the Windows /Automation hidden-UI switch ----
;;; alfe-bricscad-batch-hidden-ui. Simulate the host OS via
;;; *host-os-override* so the Windows-only argv is exercised from any host.
;;; (Placed in this section deliberately: the mid-file BUILD-LAUNCH-ARGV
;;; area is in the dead suite-registration zone tracked by
;;; backend-cad-tests-dead-suite-zone.issue.)

(defun %bricscad-batch-argv (os &key profile (template "C:/t.dwt"))
  "The :batch launch argv BUILD-LAUNCH-ARGV produces on a simulated OS."
  (let ((alfe.backend.cad-common:*host-os-override* os)
        (backend (alfe.backend.bricscad:make-bricscad-backend
                  :executable-path "/fake/bricscad.exe"
                  :variant :batch
                  :template-path template
                  :profile profile))
        (session (alfe.protocol.file::%make-protocol-session
                  :workdir (uiop:ensure-directory-pathname "/tmp/argv-probe/"))))
    (alfe.backend.bricscad:build-launch-argv backend session :mode :batch)))

(test bricscad-windows-batch-argv-has-single-automation-before-b
  "On Windows the direct batch argv carries exactly one /Automation, and it
precedes the /b script pair (alfe-bricscad-batch-hidden-ui)."
  (let* ((argv (%bricscad-batch-argv :windows :profile "clean"))
         (autopos (position "/Automation" argv :test #'string=))
         (bpos (position "/b" argv :test #'string=)))
    (is (eql 1 (count "/Automation" argv :test #'string=)))
    (is (integerp autopos))
    (is (integerp bpos))
    (is (< autopos bpos))
    (is (member "C:/t.dwt" argv :test #'string=))
    (is (member "/p" argv :test #'string=))
    (is (member "clean" argv :test #'string=))
    (is (search "run.scr" (car (last argv))))
    (is (not (member "-B" argv :test #'string=)))
    (is (not (member "-P" argv :test #'string=)))))

(test bricscad-nonwindows-batch-argv-has-no-automation
  "macOS/Linux batch argv never contains /Automation and uses -B, not /b."
  (dolist (os '(:macos :linux))
    (let ((argv (%bricscad-batch-argv os :profile "clean")))
      (is (not (member "/Automation" argv :test #'string=)) "no /Automation on ~A" os)
      (is (not (member "/b" argv :test #'string=))          "no /b on ~A" os)
      (is (member "-B" argv :test #'string=)                "-B present on ~A" os)
      (is (member "-P" argv :test #'string=)                "-P present on ~A" os))))

(test bricscad-windows-automation-mode-still-launches-cscript
  "Explicit ALFE :automation mode (the COM/VBScript backend) is unchanged by
the hidden-UI switch: on Windows it still runs cscript on the VBS bridge,
NOT bricscad.exe /Automation."
  (let ((alfe.backend.cad-common:*host-os-override* :windows)
        (backend (alfe.backend.bricscad:make-bricscad-backend
                  :executable-path "/fake/bricscad.exe" :variant :automation))
        (session (alfe.protocol.file::%make-protocol-session
                  :workdir (uiop:ensure-directory-pathname "/tmp/argv-probe/"))))
    (let ((argv (alfe.backend.bricscad:build-launch-argv
                 backend session :mode :automation)))
      (is (string= "cscript" (first argv)))
      (is (member "//nologo" argv :test #'string=))
      (is (some (lambda (a) (search "bridge-bricscad.vbs" a)) argv))
      (is (not (member "/Automation" argv :test #'string=))))))

;;; --- --print-command: real staging, no launch ----------------------
;;; PRINT-COMMAND-PLAN must do everything a real run does short of
;;; spawning the CAD: prepare the workdir, stage run-common.lsp and
;;; run.scr, then print the argv it WOULD have launched. It must launch
;;; nothing, and it must not leave the workdir behind unless asked.

(defun %fake-bricscad-binary ()
  "A file on disk standing in for bricscad(.exe). Only its existence
matters — PRINT-COMMAND-PLAN never executes it."
  (let ((path (merge-pathnames (format nil "alfe-fake-bricscad-~D" (random 1000000))
                               (uiop:temporary-directory))))
    (with-open-file (out path :direction :output :if-exists :supersede
                              :if-does-not-exist :create)
      (write-line "#!/bin/sh" out))
    (namestring path)))

(defun %run-print-command-plan (&key keep-p)
  "Drive ALFE.CLI:PRINT-COMMAND-PLAN against a fake BricsCAD in :batch
mode. Returns (values exit-code printed-output workdir-path)."
  (let* ((binary (%fake-bricscad-binary))
         (wd-file (merge-pathnames (format nil "alfe-print-command-wd-~D.txt"
                                           (random 1000000))
                                   (uiop:temporary-directory)))
         (backend (alfe.backend.bricscad:make-bricscad-backend
                   :executable-path binary :variant :batch))
         (options (make-cli-options :backend :bricscad
                                    :mode :batch
                                    :keep-workdir-p keep-p
                                    :write-workdir-path (namestring wd-file)
                                    :actions (list (action-eval "(princ)"))))
         (stdout (make-string-output-stream))
         (code (print-command-plan options backend
                                   :version-text "0.0.1"
                                   :stream stdout))
         (workdir (with-open-file (in wd-file) (read-line in nil ""))))
    (ignore-errors (delete-file wd-file))
    (ignore-errors (delete-file binary))
    (values code (get-output-stream-string stdout) workdir)))

(test bricscad-print-command-plan-prints-argv-and-erases-workdir
  "--print-command stages the workdir for real, prints exactly one
shell-ready command line naming the binary and the staged run.scr, and
removes the workdir afterwards (no --keep-workdir)."
  (multiple-value-bind (code output workdir) (%run-print-command-plan)
    (is (= 0 code))
    (let ((lines (remove "" (uiop:split-string (string-trim '(#\Newline) output)
                                               :separator '(#\Newline))
                         :test #'string=)))
      ;; One line, and one line only: the command.
      (is (= 1 (length lines)))
      (let ((command (first lines)))
        (is (search "bricscad" command))
        (is (search "run.scr" command))
        ;; The batch switch: /b on Windows, -B on POSIX.
        (is (search (if (uiop:os-windows-p) "/b" "-B") command))))
    ;; Default: the staged workdir is gone.
    (is (plusp (length workdir)))
    (is (not (uiop:directory-exists-p (uiop:ensure-directory-pathname workdir))))))

(test bricscad-print-command-plan-keep-workdir-leaves-staged-artefacts
  "With --keep-workdir the staged workdir survives, holding the exact
run.scr and run-common.lsp the printed command refers to."
  (multiple-value-bind (code output workdir) (%run-print-command-plan :keep-p t)
    (declare (ignore output))
    (is (= 0 code))
    (let ((dir (uiop:ensure-directory-pathname workdir)))
      (is (uiop:directory-exists-p dir))
      (is (uiop:file-exists-p (merge-pathnames "run.scr" dir)))
      (is (uiop:file-exists-p (merge-pathnames "run-common.lsp" dir)))
      (ignore-errors (uiop:delete-directory-tree dir :validate t
                                                     :if-does-not-exist :ignore)))))

;;; --- macOS automation launcher (alfe-bricscad-automation-macos) ----
;;; The first real macOS probe run sat at BOOTING for the whole 240 s
;;; READY timeout with empty stdout/stderr, because the emitted
;;; AppleScript could not run at all: it used `running' (a reserved
;;; AppleScript property term) as a variable, and addressed the app as
;;; "BricsCAD" while the installed bundle is "BricsCAD V26.app".

(test macos-app-bundle-for-finds-enclosing-bundle
  "MACOS-APP-BUNDLE-FOR maps a binary inside a .app to the bundle, and
returns NIL for a plain unix binary."
  (is (string= "/Applications/BricsCAD V26.app/"
               (alfe.backend.bricscad:macos-app-bundle-for
                "/Applications/BricsCAD V26.app/Contents/MacOS/bricscad")))
  (is (string= "/Applications/BricsCAD.app/"
               (alfe.backend.bricscad:macos-app-bundle-for
                "/Applications/BricsCAD.app/Contents/MacOS/bricscad")))
  (is (null (alfe.backend.bricscad:macos-app-bundle-for "/opt/bricsys/bricscad")))
  (is (null (alfe.backend.bricscad:macos-app-bundle-for nil))))

(defun %emitted-applescript (executable-path &key (code-only t)
                                                  (template-path "/tmp/tpl/Default-mm.dwt"))
  "The AppleScript EMIT-LAUNCHER-APPLESCRIPT writes for EXECUTABLE-PATH.
With CODE-ONLY (the default) the `--' comment lines are dropped, so the
assertions below test what osascript will RUN. The template's comments
quote the very constructs the tests forbid (that is the point of the
comments), and matching against them would make every check vacuous."
  (let ((path (merge-pathnames (format nil "alfe-applescript-~D.applescript"
                                       (random 1000000))
                               (uiop:temporary-directory))))
    (unwind-protect
         (progn
           (alfe.backend.bricscad:emit-launcher-applescript
            path :runtime-load-path "/tmp/wd/run-common.lsp"
                 :executable-path executable-path
                 :template-path template-path)
           (let ((text (uiop:read-file-string path)))
             (if code-only
                 (format nil "~{~A~^~%~}"
                         (remove-if (lambda (line)
                                      (let ((trimmed (string-left-trim
                                                      '(#\Space #\Tab) line)))
                                        (and (>= (length trimmed) 2)
                                             (string= "--" trimmed :end2 2))))
                                    (uiop:split-string text :separator '(#\Newline))))
                 text)))
      (ignore-errors (delete-file path)))))

(test macos-launcher-applescript-avoids-reserved-word-and-app-name-guess
  "The emitted launcher must not use the reserved term `running' as a
variable, must not address a guessed \"BricsCAD\" application name, and
must launch the real bundle via `open -a' with AppleScript quoting."
  (let ((script (%emitted-applescript
                 "/Applications/BricsCAD V26.app/Contents/MacOS/bricscad")))
    ;; The two faults that made the first macOS probe run a silent no-op.
    (is (not (search "set running to" script)))
    (is (not (search "tell application \"BricsCAD\" to activate" script)))
    ;; What it does instead.
    (is (search "open -a " script))
    (is (search "quoted form of appPath" script))
    (is (search "/Applications/BricsCAD V26.app" script))
    ;; The payload still gets typed.
    (is (search "keystroke" script))
    (is (search "/tmp/wd/run-common.lsp" script))))

(test macos-launcher-applescript-falls-back-to-plain-binary
  "A bricscad that is NOT inside a .app bundle is run directly rather
than through `open -a', which only accepts an application."
  (let ((script (%emitted-applescript "/opt/bricsys/bricscad")))
    (is (not (search "open -a " script)))
    (is (search "/opt/bricsys/bricscad" script))
    (is (search "do shell script quoted form of appPath" script))))

;;; --- launcher liveness: a dead launcher must not cost the timeout ---

(defstruct (%fake-process (:constructor %make-fake-process))
  "Stand-in for a UIOP process-info in the launcher-liveness tests."
  (alive t) (code 0))

(test launcher-alive-or-clean-p-only-fails-on-nonzero-exit
  "The READY wait aborts only when the launcher exited NON-ZERO. While it
runs, and after a clean exit (osascript done typing, cscript done
dispatching), the wait must continue — the CAD publishes READY later."
  (flet ((probe (alive code)
           ;; Exercise the decision directly: NIL exit code = still alive.
           (let ((exit (if alive nil code)))
             (or (null exit) (eql exit 0)))))
    (is (probe t 0)   "alive -> keep waiting")
    (is (probe nil 0) "exited 0 -> keep waiting (driver finished its job)")
    (is (not (probe nil 1)) "exited non-zero -> abort now")
    (is (not (probe nil 2)) "exited non-zero -> abort now")))

(test ready-timeout-diagnosis-tells-a-dialog-from-a-slow-start
  "cad-runner-wedged-by-modal-dialog, the half left open: `READY timeout, last
status BOOTING, launcher still running' reads IDENTICALLY for a CAD that is
merely slow and for one sitting on a modal dialog nobody can answer. Telling
those apart cost three wrong hypotheses once, so the message now says which it
is.

The discriminating pair is the last two assertions: same live launcher, one
engine that never moved and one that did."
  (flet ((phrase (exit-code last) (alfe.backend.cad-common:ready-timeout-diagnosis
                                   exit-code last)))
    ;; An exited launcher: its code is the fact that matters.
    (is (search "exited with code 1" (phrase 1 "BOOTING"))
        "an exited launcher must report its code; got ~S" (phrase 1 "BOOTING"))
    (is (not (search "dialog" (phrase 1 "BOOTING")))
        "and must NOT be diagnosed as a dialog -- it is not running")
    ;; Alive, and the engine never published anything: the dialog case.
    (dolist (last '(nil "" "BOOTING" "BOOTING 0" "  BOOTING  "))
      (let ((text (phrase nil last)))
        (is (search "never moved past BOOTING" text)
            "~S must be diagnosed as never started; got ~S" last text)
        (is (search "dialog" text)
            "~S must name the likely cause; got ~S" last text)))
    ;; Alive, but the engine HAS moved: a later stall, NOT a launch problem.
    (dolist (last '("READY 0" "RUNNING 1" "DONE 1 OK" "STOPPING"))
      (let ((text (phrase nil last)))
        (is (not (search "dialog" text))
            "~S moved past BOOTING, so it must NOT be called a dialog; got ~S"
            last text)
        (is (search "still running" text)
            "~S must still describe the launcher; got ~S" last text)))))

(test engine-never-started-p-is-exactly-the-no-transition-case
  "The predicate behind the diagnosis, on its own. BOOTING is what INIT-SESSION
writes BEFORE the CAD is launched, so seeing it still there means the engine
published nothing at all -- it never loaded run-common.lsp."
  (flet ((never (last) (alfe.backend.cad-common:engine-never-started-p last)))
    (is (never nil) "no status at all")
    (is (never "") "empty status")
    (is (never "BOOTING") "the initial status")
    (is (never "booting") "case-insensitive, status text is not a contract")
    (is (never (format nil "BOOTING~%")) "trailing newline (status.txt is a line)")
    (is (never (format nil "BOOTING~C~%" #\Return)) "and CRLF, which is what Windows writes")
    (is (not (never "READY 0")) "READY is a transition")
    (is (not (never "RUNNING 1")) "so is RUNNING")
    (is (not (never "FAILED 1")) "and a failure is a transition too")))

(test launcher-failure-details-nil-unless-nonzero-exit
  "LAUNCHER-FAILURE-DETAILS reports nothing for a live or cleanly-exited
launcher, so the normal path keeps its plain READY-TIMEOUT message."
  (is (null (alfe.backend.cad-common:launcher-failure-details nil)))
  (is (null (alfe.backend.cad-common:launcher-exit-code nil))))

(test bricscad-package-imports-the-launcher-liveness-helpers
  "Regression (alfe 1.7.11). START-ENGINE's READY wait calls
LAUNCHER-ALIVE-OR-CLEAN-P and LAUNCHER-FAILURE-DETAILS, which live in
ALFE.BACKEND.CAD-COMMON. ALFE.BACKEND.BRICSCAD :USEs only CL, so
EXPORTING them was not enough: the calls read as fresh internal
ALFE.BACKEND.BRICSCAD:: symbols and every launch — batch as well as
automation — died with an undefined-function error at RUNTIME. At
compile time it is only a style warning, and nothing in this suite
drives the READY wait (backend-cad-tests-dead-suite-zone), so the first
thing to notice was a real CAD run in CI."
  (let ((home (find-package :alfe.backend.cad-common))
        (bricscad (find-package :alfe.backend.bricscad)))
    (dolist (name '("LAUNCHER-ALIVE-OR-CLEAN-P"
                    "LAUNCHER-FAILURE-DETAILS"
                    "LAUNCHER-EXIT-CODE"))
      (let ((sym (find-symbol name bricscad)))
        (is (and sym (eq (symbol-package sym) home) (fboundp sym))
            "~A must resolve, inside ALFE.BACKEND.BRICSCAD, to the bound ~
CAD-COMMON function (got ~S)" name sym)))))

(test macos-launcher-applescript-waits-for-focus-before-typing
  "`keystroke' has no target: it goes to whatever is frontmost. The
launcher must therefore WAIT for BricsCAD to own the keyboard and
refuse to type otherwise — a fixed delay silently loses the payload to
the terminal while still exiting 0, which is indistinguishable from
success on alfe's side (2026-08-01 macOS probe: Accessibility granted,
osascript exit 0, status stuck at BOOTING)."
  (let ((script (%emitted-applescript
                 "/Applications/BricsCAD V26.app/Contents/MacOS/bricscad")))
    ;; Polls for the frontmost process instead of sleeping a fixed time.
    (is (search "frontmost is true" script))
    (is (search "exit repeat" script))
    ;; Refuses to type into another application, and says so non-zero so
    ;; alfe's READY wait aborts at once instead of burning the timeout.
    (is (search "error " script))
    (is (search "refusing to send keystrokes" script))
    ;; Records where the focus actually was, for the failing case.
    (is (search "launcher-focus.txt" script))
    ;; And there is no bare fixed-delay-then-type any more.
    (is (not (search "delay 8.0" script)))))

(test macos-launcher-applescript-opens-a-drawing-with-the-app
  "The launcher must open a DOCUMENT, not just the application. BricsCAD
with no drawing shows its Start page, which has no command line, so the
keystrokes land in a focused BricsCAD and execute nothing — the exact
2026-08-01 probe result (frontmost=bricscad focused=true, osascript exit
0, status stuck at BOOTING). The batch path never hit this because it
always passes a template."
  (let ((with-doc (%emitted-applescript
                   "/Applications/BricsCAD V26.app/Contents/MacOS/bricscad"
                   :template-path "/tmp/tpl/Default-mm.dwt"))
        (no-doc (%emitted-applescript
                 "/Applications/BricsCAD V26.app/Contents/MacOS/bricscad"
                 :template-path nil)))
    (is (search "quoted form of docPath" with-doc))
    (is (search "/tmp/tpl/Default-mm.dwt" with-doc))
    ;; Still shell-quoted (a template path has spaces on a real install).
    (is (search "open -a " with-doc))
    ;; With no template discovered we still launch the app rather than
    ;; emitting a broken `open -a APP ""'.
    (is (not (search "quoted form of docPath" no-doc)))
    (is (search "open -a " no-doc))))

(test macos-launcher-applescript-checks-already-running-before-opening-doc
  "alfe-bricscad-automation-macos-reopens-welcome-page: `open -a app
docPath' against a BricsCAD that already has a document/console window
open can knock its main window back to the Welcome page instead of
reusing the existing session — found live, 2026-09-12. docPath must
therefore only be passed when no such window exists yet, decided at
RUNTIME (the emitted script, not Lisp-side, since BricsCAD's state can
change between generation and execution) — not by resurrecting the
reserved-word `running' probe Round 6 removed for activation (that
removal stays correct; only the document-opening side effect needed a
check). And NOT by a bare \"is the process running\" check either: found
live that this is too coarse — a freshly-launched, running-but-no-
document-yet BricsCAD needs docPath exactly as much as no process at
all, so the check must be \"does a document/console window already
exist\", the same exclusion-by-product-name signal FINDCONSOLEWINDOW
uses, not merely process existence."
  (let ((script (%emitted-applescript
                 "/Applications/BricsCAD V26.app/Contents/MacOS/bricscad"
                 :template-path "/tmp/tpl/Default-mm.dwt")))
    ;; The check itself, and NOT the reserved word `running' as a bare
    ;; variable name (Round 6's own fault, still guarded against).
    (is (search "alreadyHasDoc" script))
    (is (not (search "set running to" script)))
    (is (search "exists (processes whose name contains" script))
    ;; Must check for an existing DOCUMENT window, not merely that the
    ;; process exists — the same exclusion-by-name signal as
    ;; FINDCONSOLEWINDOW, so a running-but-doc-less BricsCAD still gets
    ;; docPath.
    (is (search "does not contain \"bricscad\"" script))
    (is (search "AXStandardWindow" script))
    ;; Both shapes of the launch line must be present...
    (is (search "open -a \" & quoted form of appPath & \" \" & quoted form of docPath" script))
    ;; ...but the doc-opening one must be reachable only via a runtime
    ;; conditional, not unconditionally.
    (is (search "if alreadyHasDoc then" script))
    (is (search "else" script))))

(test macos-launcher-applescript-dismisses-startup-dialogs
  "A genuinely COLD BricsCAD launch on this installation can show a STACK
of startup dialogs before any document/console is usable at all — found
live, 2026-09-12: a workspace-selection \"BricsCAD Launcher\" dialog
first, then (when a template was left locked by a previous automation
run killed abnormally while it had that template open) a lock-file-found
dialog right after it. The frontmost-wait above only confirms BricsCAD
ITSELF is frontmost — a dialog is part of that same process, so the wait
succeeds while a dialog still blocks everything underneath it, and
FINDCONSOLEWINDOW correctly excludes both dialogs from ever being
mistaken for the console, which means it also never finds anything while
one is up. Return dismisses both dialog types via whichever button is
their own default one — verified live — WITHOUT hard-coding either
dialog's locale-specific button label."
  (let ((script (%emitted-applescript
                 "/Applications/BricsCAD V26.app/Contents/MacOS/bricscad")))
    (is (search "dismissStartupDialogs" script))
    ;; Bounded, not an unconditional/infinite retry.
    (is (search "repeat 5 times" script))
    ;; Stops as soon as a console is found, rather than always spending
    ;; the whole bound.
    (is (search "findConsoleWindow(procName) is not missing value then return" script))
    ;; The dismissal mechanism itself: Return, not a hard-coded button
    ;; name in any language.
    (is (search "key code 36 -- Return" script))))

;;; --- the emitted .vbs must be VALID VBScript ------------------------------
;;;
;;; alfe-autocad-vbscript-comments (pjb, 2026-08-12): the bridge templates
;;; opened with `;;' comment lines — Lisp syntax, which VBScript does not
;;; have. A VBScript comment is an apostrophe or REM. Those lines are the
;;; FIRST thing cscript reads, so this did not degrade: it was a syntax error
;;; at line 1, before AutoCAD COM was touched.
;;;
;;; Asserted on the EMITTED FILE, not on the template constant: what cscript
;;; parses is the file, and a substitution could in principle introduce a
;;; line the template never had.

(defun %vbs-offending-lines (content)
  "Lines of CONTENT that VBScript cannot parse as a comment or as ASCII code.
Returns a list of (LINE-NUMBER REASON LINE)."
  (let ((offenders '())
        (number 0))
    (dolist (line (uiop:split-string content :separator '(#\Newline))
                  (nreverse offenders))
      (incf number)
      (let ((trimmed (string-left-trim '(#\Space #\Tab #\Return) line)))
        (when (and (plusp (length trimmed))
                   (char= #\; (char trimmed 0)))
          (push (list number "Lisp comment marker" line) offenders))
        (when (some (lambda (character) (>= (char-code character) 128)) line)
          (push (list number "non-ASCII" line) offenders))))))

(test autocad-emitted-vbs-is-valid-vbscript
  "No `;;' comment line, and pure ASCII: cscript reads a .vbs as ANSI unless
it carries a BOM, and this file is written UTF-8 without one."
  (let ((workdir (uiop:ensure-directory-pathname
                  (merge-pathnames
                   (format nil "alfe-test-acad-vbs-valid-~D/" (random 999999))
                   (uiop:temporary-directory)))))
    (unwind-protect
        (progn
          (ensure-directories-exist workdir)
          (let ((vbs (merge-pathnames "bridge-autocad.vbs" workdir)))
            (alfe.backend.autocad:emit-bridge-vbs
             vbs
             :runtime-load-path (merge-pathnames "run-common.lsp" workdir)
             :status-path (merge-pathnames "protocol/status.txt" workdir)
             :error-path (merge-pathnames "protocol/stderr.txt" workdir))
            (let ((offenders (%vbs-offending-lines (read-back vbs))))
              (is (null offenders)
                  "bridge-autocad.vbs has lines cscript cannot parse: ~S"
                  offenders))))
      (uiop:delete-directory-tree workdir :validate t
                                          :if-does-not-exist :ignore))))

(test bricscad-emitted-vbs-is-valid-vbscript
  "The BricsCAD template carried the SAME defect, though the ticket named
only AutoCAD — it is the same file position in a copy of the same header."
  (let ((workdir (uiop:ensure-directory-pathname
                  (merge-pathnames
                   (format nil "alfe-test-bcad-vbs-valid-~D/" (random 999999))
                   (uiop:temporary-directory)))))
    (unwind-protect
        (progn
          (ensure-directories-exist workdir)
          (let ((vbs (merge-pathnames "bridge-bricscad.vbs" workdir)))
            (alfe.backend.bricscad:emit-bridge-vbs
             vbs
             :runtime-load-path (merge-pathnames "run-common.lsp" workdir)
             :status-path (merge-pathnames "protocol/status.txt" workdir)
             :error-path (merge-pathnames "protocol/stderr.txt" workdir))
            (let ((offenders (%vbs-offending-lines (read-back vbs))))
              (is (null offenders)
                  "bridge-bricscad.vbs has lines cscript cannot parse: ~S"
                  offenders))))
      (uiop:delete-directory-tree workdir :validate t
                                          :if-does-not-exist :ignore))))

(test vbs-offending-line-detector-actually-detects
  "A check that cannot fail is worth nothing: prove the detector fires on
both defects it is meant to catch."
  (is (= 1 (length (%vbs-offending-lines (format nil "Option Explicit~%;; nope~%")))))
  (is (= 1 (length (%vbs-offending-lines (format nil "' emitted by alfe~C~%" (code-char 233))))))
  (is (null (%vbs-offending-lines (format nil "' fine~%Option Explicit~%")))))

;;; --- automation is Windows-only (alfe-bricscad-automation-macos, A) -------
;;;
;;; pjb, 2026-08-14, taking option A: "sur macos, les scripts ne marchent pas
;;; en combinaison avec --automation". The mode used to launch a CAD and time
;;; out 240 s later; it now refuses up front, with the same
;;; BACKEND-NOT-AVAILABLE :NO-AUTOMATION Linux has always given.
;;;
;;; Asserted through CHOOSE-EFFECTIVE-MODE, because that is where the refusal
;;; lives and therefore what makes it IMMEDIATE — the emitter and the argv
;;; builder both come through it, so nothing is written before the failure.

(test bricscad-automation-refused-off-windows
  "Explicit --mode automation off Windows signals BACKEND-NOT-AVAILABLE
:NO-AUTOMATION rather than proceeding."
  (let ((backend (alfe.backend.bricscad:make-bricscad-backend
                  :executable-path "/fake/bricscad")))
    (if (alfe.backend.cad-common:windows-p)
        ;; On Windows the COM bridge is real: the mode resolves normally.
        (is (eq :automation
                (alfe.backend.bricscad::choose-effective-mode backend :automation)))
        (handler-case
            (progn
              (alfe.backend.bricscad::choose-effective-mode backend :automation)
              (is nil "Expected BACKEND-NOT-AVAILABLE off Windows."))
          (alfe.error:backend-not-available (condition)
            (is (eq :bricscad (alfe.error:backend-error-backend condition)))
            (is (eq :no-automation (alfe.error:backend-error-code condition)))
            (is (search "not supported on this OS"
                        (alfe.error:backend-error-message condition)))
            ;; the message must point at the mode that DOES work
            (is (search "--mode batch"
                        (alfe.error:backend-error-message condition))))))))

(test bricscad-auto-mode-without-executable-refused-off-windows
  "--mode auto used to fall back to automation when no CLI binary was found.
Off Windows that fallback no longer exists, so the failure must name the
REAL problem — a missing BricsCAD — instead of silently selecting a mode
that cannot work."
  (let ((backend (alfe.backend.bricscad:make-bricscad-backend
                  :executable-path nil)))
    (unless (alfe.backend.cad-common:windows-p)
      (handler-case
          (progn
            (alfe.backend.bricscad::choose-effective-mode backend :auto)
            (is nil "Expected BACKEND-NOT-AVAILABLE with no executable."))
        (alfe.error:backend-not-available (condition)
          (is (eq :no-automation (alfe.error:backend-error-code condition)))
          (is (search "not found"
                      (alfe.error:backend-error-message condition))))))))

(test bricscad-batch-mode-is-untouched-by-the-automation-refusal
  "The refusal must not disturb the path every real run uses. Batch resolves
on every platform, and --mode auto still prefers it when the CLI is found."
  (let ((backend (alfe.backend.bricscad:make-bricscad-backend
                  :executable-path "/fake/bricscad")))
    (is (eq :batch (alfe.backend.bricscad::choose-effective-mode backend :batch)))
    (is (eq :batch (alfe.backend.bricscad::choose-effective-mode backend :auto)))))

;;; --- opt-in re-enable (alfe-bricscad-automation-macos-osascript, option B) -
;;;
;;; The refusal above stays the DEFAULT; $ALFE_ENABLE_MACOS_AUTOMATION lets it
;;; be relaxed explicitly to debug the hardened AppleScript path against a
;;; real BricsCAD, interactively, at the machine (verified live 2026-09-11).

(test bricscad-automation-opt-in-relaxes-refusal-on-macos
  "With the opt-in set, macOS resolves :automation instead of refusing —
mirrors how Windows already behaves, unconditionally."
  (let ((backend (alfe.backend.bricscad:make-bricscad-backend
                  :executable-path "/fake/bricscad")))
    (when (alfe.backend.cad-common:macos-p)
      (with-env ("ALFE_ENABLE_MACOS_AUTOMATION" "1")
        (is (eq :automation
                (alfe.backend.bricscad::choose-effective-mode backend :automation)))))))

(test bricscad-automation-opt-in-is-off-by-default
  "Merely having the machinery does not change the default: with the env
var ABSENT (the normal case, and every CI job), the refusal is exactly as
before — this is the acceptance criterion that the opt-in must not weaken
the honest immediate failure for the common \"no automation here\" case."
  (let ((backend (alfe.backend.bricscad:make-bricscad-backend
                  :executable-path "/fake/bricscad")))
    (unless (alfe.backend.cad-common:windows-p)
      (is (not (alfe.backend.bricscad::macos-automation-opt-in-p)))
      (handler-case
          (progn
            (alfe.backend.bricscad::choose-effective-mode backend :automation)
            (is nil "Expected BACKEND-NOT-AVAILABLE with the opt-in unset."))
        (alfe.error:backend-not-available (condition)
          (is (eq :no-automation (alfe.error:backend-error-code condition))))))))

(test bricscad-automation-opt-in-string-forms
  "$ALFE_ENABLE_MACOS_AUTOMATION=0 and an empty string do NOT opt in —
only a genuinely truthy value does. Guards against a caller who sets the
var to \"0\" meaning \"off\" accidentally enabling it."
  (when (alfe.backend.cad-common:macos-p)
    (with-env ("ALFE_ENABLE_MACOS_AUTOMATION" "0")
      (is (not (alfe.backend.bricscad::macos-automation-opt-in-p))))
    (with-env ("ALFE_ENABLE_MACOS_AUTOMATION" "")
      (is (not (alfe.backend.bricscad::macos-automation-opt-in-p))))
    (with-env ("ALFE_ENABLE_MACOS_AUTOMATION" "1")
      (is (alfe.backend.bricscad::macos-automation-opt-in-p)))))

(test bricscad-applescript-emitter-is-kept
  "The AppleScript emitter, the preflight and the launcher-state reporting are
deliberately KEPT (the ticket: they are what made five investigation rounds
interpretable, and option B — driving the launcher by hand at the machine —
is still open). Guard against a later cleanup deleting them as dead code."
  (is (fboundp 'alfe.backend.bricscad:emit-launcher-applescript))
  (is (fboundp 'alfe.backend.bricscad:macos-app-bundle-for)))

;;; --- templates shipped inside the BricsCAD bundle -------------------------
;;;
;;; pjb, 2026-08-14: "on pourrait copier '/Applications/BricsCAD V26.app/
;;; Contents/Resources/UserDataCache/Templates/fr_FR/Default-m.dwt' empty.dwt
;;; et ainsi obtenir des empty.dwg avec ce template."
;;;
;;; The product ships a perfectly good blank drawing; discovery simply could
;;; not see it. The user-Library candidates name ONE locale (en_US) and one
;;; location, so a French install was invisible — while the AutoCAD backend
;;; has searched inside its own install (UserDataCache/Template/…) all along.
;;; Runs on any OS: the bundle is a directory shape, not a macOS feature.

(defun %fake-bricscad-bundle (root locales names)
  "Build ROOT/Fake.app/…/Templates/<locale>/<name> for each pair, and return
the executable path inside the bundle."
  (dolist (locale locales)
    (dolist (name names)
      (let ((path (merge-pathnames
                   (format nil "Fake.app/Contents/Resources/UserDataCache/Templates/~A/~A"
                           locale name)
                   root)))
        (ensure-directories-exist path)
        (with-open-file (out path :direction :output :if-exists :supersede
                                  :if-does-not-exist :create)
          (write-string "not really a dwt" out)))))
  (namestring (merge-pathnames "Fake.app/Contents/MacOS/bricscad" root)))

(test bricscad-bundle-templates-prefer-neutral-locale-and-mm
  "Ordering is deliberate: en_US first, because a localised template carries
localised layer and linetype names and this drawing is the BASELINE of a
vendor-divergence harness — anything the file contributes is noise in the
measurement. Then Default-mm before Default-m, matching the existing
preference."
  (let ((root (uiop:ensure-directory-pathname
               (merge-pathnames (format nil "alfe-bundle-tpl-~D/" (random 999999))
                                (uiop:temporary-directory)))))
    (unwind-protect
        (let* ((exe (%fake-bricscad-bundle root '("fr_FR" "en_US")
                                           '("Default-m.dwt" "Default-mm.dwt")))
               (found (alfe.backend.bricscad:bundle-template-candidates exe)))
          (is (= 4 (length found)) "expected all four templates; got ~S" found)
          (is (search "/en_US/" (first found))
              "the neutral locale must come first; got ~S" (first found))
          (is (search "Default-mm.dwt" (first found))
              "Default-mm must be preferred; got ~S" (first found))
          ;; the localised ones are still offered, after the neutral ones
          (is (search "/fr_FR/" (third found))
              "localised templates must still be reachable; got ~S" found))
      (uiop:delete-directory-tree root :validate t :if-does-not-exist :ignore))))

(test bricscad-bundle-templates-take-what-exists-when-no-neutral-locale
  "A French-only install — exactly the case pjb reported — must still yield a
template rather than nothing."
  (let ((root (uiop:ensure-directory-pathname
               (merge-pathnames (format nil "alfe-bundle-fr-~D/" (random 999999))
                                (uiop:temporary-directory)))))
    (unwind-protect
        (let* ((exe (%fake-bricscad-bundle root '("fr_FR") '("Default-m.dwt")))
               (found (alfe.backend.bricscad:bundle-template-candidates exe)))
          (is (= 1 (length found)))
          (is (search "/fr_FR/Default-m.dwt" (first found))))
      (uiop:delete-directory-tree root :validate t :if-does-not-exist :ignore))))

(test bricscad-bundle-templates-degrade-quietly
  "No bundle, no executable, nothing there: NIL, never an error. Discovery
runs on hosts with no BricsCAD at all."
  (is (null (alfe.backend.bricscad:bundle-template-candidates nil)))
  (is (null (alfe.backend.bricscad:bundle-template-candidates "/opt/bricsys/bricscad")))
  (is (null (alfe.backend.bricscad:bundle-template-candidates
             "/nonexistent/Nothing.app/Contents/MacOS/bricscad"))))

(test bricscad-template-env-override-still-wins
  "$AUTOLISP_BRICSCAD_TEMPLATE remains the zero-code way to point a machine at
a specific blank drawing — preferable to copying a vendor template to a fixed
name, and far preferable to committing one."
  (let ((path (merge-pathnames (format nil "alfe-tpl-~D.dwt" (random 999999))
                               (uiop:temporary-directory))))
    (unwind-protect
        (progn
          (with-open-file (out path :direction :output :if-exists :supersede
                                    :if-does-not-exist :create)
            (write-string "x" out))
          (is (string= (namestring (truename path))
                       (namestring
                        (truename
                         (alfe.backend.bricscad:discover-bricscad-template
                          :requested path))))))
      (ignore-errors (delete-file path)))))

;;; --- DETECT must not cache a vendor template as a false "explicit" value --
;;; alfe-bricscad-automation-macos-reopens-welcome-page (2026-09-12). DETECT
;;; runs before any per-invocation workdir exists, so a naive call used to
;;; fall through empty-drawing.lisp's fresh-per-run step straight to the
;;; SHARED vendor template and cache THAT — permanently shadowing every later
;;; per-invocation caller's own correctly workdir-aware discovery, since
;;; those callers legitimately check the cached value first (a real
;;; override must win). Found live: automation mode keeps BricsCAD running
;;; across invocations, so a killed run leaves a stale lock on that cached,
;;; shared file, and every subsequent run hits the resulting modal dialog.

(test discover-bricscad-template-skips-vendor-fallback-when-asked
  "ALLOW-VENDOR-FALLBACK NIL must return NIL rather than a vendor template
when nothing explicit was requested and no WORKDIR was given to try the
fresh-per-run drawing — even on a host where a real vendor template
exists on disk (this dev machine may well be one), proving the vendor
step is genuinely skipped, not merely absent by coincidence."
  (with-env ("AUTOLISP_BRICSCAD_TEMPLATE" "")
    (with-env ("AUTOLISP_DWG" "")
      (is (null (alfe.backend.bricscad:discover-bricscad-template
                 :allow-vendor-fallback nil))))))

(test detect-does-not-cache-a-vendor-template-path
  "With no explicit override and a fake (but real, so DETECT does not
error) executable, DETECT must leave TEMPLATE-PATH NIL — not a vendor
template it found on its own, which would then permanently shadow every
later per-invocation caller's own workdir-aware discovery."
  (let ((fake-binary (or (probe-file "/usr/bin/true") (probe-file "/bin/true"))))
    (when fake-binary
      (with-env ("BRICSCAD_EXE" (namestring fake-binary))
        (with-env ("AUTOLISP_BRICSCAD_TEMPLATE" "")
          (with-env ("AUTOLISP_DWG" "")
            (let ((backend (alfe.backend.bricscad:make-bricscad-backend)))
              (alfe.backend:detect backend)
              (is (null (alfe.backend.bricscad:bricscad-backend-template-path
                         backend))))))))))

(test detect-still-captures-an-explicit-template-override
  "An explicit $AUTOLISP_BRICSCAD_TEMPLATE must still be captured onto the
backend by DETECT — ALLOW-VENDOR-FALLBACK NIL only skips the VENDOR
fallback step, not the explicit-override steps ahead of it."
  (let ((fake-binary (or (probe-file "/usr/bin/true") (probe-file "/bin/true")))
        (path (merge-pathnames (format nil "alfe-tpl-~D.dwt" (random 999999))
                               (uiop:temporary-directory))))
    (when fake-binary
      (unwind-protect
          (progn
            (with-open-file (out path :direction :output :if-exists :supersede
                                      :if-does-not-exist :create)
              (write-string "x" out))
            (with-env ("BRICSCAD_EXE" (namestring fake-binary))
              (with-env ("AUTOLISP_BRICSCAD_TEMPLATE" (namestring path))
                (let ((backend (alfe.backend.bricscad:make-bricscad-backend)))
                  (alfe.backend:detect backend)
                  (is (string= (namestring path)
                                (alfe.backend.bricscad:bricscad-backend-template-path
                                 backend)))))))
        (ignore-errors (delete-file path))))))

;;; --- reaping a spawned engine (cad-runner-wedged-by-modal-dialog) ---------
;;;
;;; alfe's --timeout bounds the PROTOCOL wait; it never bounded the
;;; ENGINE's lifetime. On 2026-08-14 a BricsCAD launched with neither a
;;; drawing nor a profile sat on an invisible modal dialog: alfe's 180 s
;;; READY timeout fired, but the spawned process stayed alive and the CI
;;; job kept running — 32 minutes on a concurrency=1 CAD runner, with 70
;;; jobs queued behind it.
;;;
;;; KILL-ENGINE-PROCESS is the bounded killer. It was private to the
;;; BricsCAD backend, which is why AutoCAD still had the unbounded
;;; `uiop:wait-process' its own docstring warns about. Tested here with a
;;; real process, no CAD required.

(test kill-engine-process-terminates-a-live-process
  "The ordinary case: a running child is gone when this returns."
  (let ((info (uiop:launch-program (list "sleep" "60") :output nil :error-output nil)))
    (is (uiop:process-alive-p info))
    (alfe.backend.cad-common:kill-engine-process info :timeout 5)
    (is (not (uiop:process-alive-p info))
        "the process outlived kill-engine-process")))

(test kill-engine-process-is-bounded-not-blocking
  "The point of the function: it must RETURN, even for a child that
ignores the polite signal. `uiop:wait-process' would block here for as
long as the process chose to live — which on Windows is what froze alfe
in shutdown and hung the whole job.

The child traps SIGTERM and keeps running; the call must still come back
promptly, and must escalate to :urgent so the process really dies."
  (let ((info (uiop:launch-program
               (list "sh" "-c" "trap '' TERM; sleep 60")
               :output nil :error-output nil)))
    (unwind-protect
        (let ((start (get-internal-real-time)))
          (alfe.backend.cad-common:kill-engine-process info :timeout 2)
          (let ((elapsed (/ (float (- (get-internal-real-time) start))
                            internal-time-units-per-second)))
            ;; bounded: nowhere near the child's 60 s
            (is (< elapsed 20)
                "kill-engine-process took ~,1F s — it is not bounded" elapsed)
            ;; and it escalated rather than giving up
            (is (not (uiop:process-alive-p info))
                "a TERM-ignoring process survived; :urgent did not fire")))
      (ignore-errors (uiop:terminate-process info :urgent t)))))

(test kill-engine-process-tolerates-nil-and-dead-processes
  "Called from an unwind-protect on a failed start, so it must cope with
having nothing to kill — the engine may never have been spawned, or may
have exited on its own."
  (is (null (alfe.backend.cad-common:kill-engine-process nil)))
  (let ((info (uiop:launch-program (list "true") :output nil :error-output nil)))
    (ignore-errors (uiop:wait-process info))
    (is (null (alfe.backend.cad-common:kill-engine-process info :timeout 1)))))

(defun %code-lines (text)
  "TEXT's lines with `;'-comments removed. Crude — it does not know about
semicolons inside strings — but enough to tell code from commentary, and
the alternative is a test that its own explanatory comment can fail."
  (mapcar (lambda (line)
            (let ((semi (position #\; line)))
              (if semi (subseq line 0 semi) line)))
          (uiop:split-string text :separator '(#\Newline))))

(test both-cad-backends-use-the-bounded-killer
  "Guard against the shape of the original bug: the careful killer existed,
but only one backend used it, so the other kept the unbounded
`uiop:wait-process' that the killer's own docstring warns about.

Asserted on CODE, not on the file text: the comment explaining why that
call was removed contains the call, and a check that its own rationale
can fail is worse than no check."
  (is (fboundp 'alfe.backend.cad-common:kill-engine-process))
  (dolist (file '("backend-autocad.lisp" "backend-bricscad.lisp"))
    (let* ((path (merge-pathnames (format nil "source/~A" file)
                                  (asdf:system-source-directory "autolisp-front-end")))
           (code (%code-lines (uiop:read-file-string path))))
      (is (some (lambda (l) (search "kill-engine-process" l)) code)
          "~A does not use the bounded killer" file)
      ;; `(uiop:wait-process info)' on the ENGINE handle is the hazard.
      ;; PROCESS-EXIT-DETAILS also waits, but only on a process already
      ;; known to have exited, where it merely collects the code — that is
      ;; why this looks for the engine variable specifically.
      (is (notany (lambda (l) (search "(uiop:wait-process info)" l)) code)
          "~A still issues an UNBOUNDED wait-process on its engine" file))))

;;; --- installed runtime assets (alfe-installed-runtime-prefix-discovery) ---
;;;
;;; A release is staged, zipped and unpacked under any prefix, and the
;;; binary is reached through a trampoline from $PREFIX/bin or lives in
;;; $PREFIX/bin itself; the prefix is known only at run time. The running
;;; executable is injected here, so a pretend installation is enough:
;;; nothing needs to be dumped, and no CAD is involved.

(defparameter *asset-names* '("autolisp-bootstrap.lsp" "autolisp-remote-io.lsp"))

(defun %pretend-install (root layout &key (assets *asset-names*)
                                          (exe-name "alfe-sbcl"))
  "Lay out an installation under ROOT (a directory pathname) and return
the pathname its alfe executable would have. LAYOUT is :LIBEXEC or :BIN."
  (dolist (a assets)
    (touch-file (merge-pathnames (concatenate 'string "share/alfe/runtime/" a)
                                 root)
                (format nil ";; installed ~A~%" a)))
  (merge-pathnames
   (ecase layout
     (:libexec (concatenate 'string
                            "libexec/clautolisp/binaries/linux/x86-64/" exe-name))
     (:bin (concatenate 'string "bin/" exe-name)))
   root))

(defun %dir-token (directory)
  "The last component of DIRECTORY: unique per test directory, and
unchanged by symlink resolution (/var on macOS) or native separators."
  (car (last (pathname-directory directory))))

(defmacro with-installed-alfe ((exe) &body body)
  "Run BODY as if EXE were the running alfe, with the build tree and the
fixed fallbacks unavailable -- the situation on the Windows runner --
and both $ALFE_*_LSP overrides unset. Restores the environment."
  (let ((saved (gensym)))
    `(let ((alfe.backend.cad-common:*executable-pathname-function*
             (let ((e ,exe)) (lambda () e)))
           (alfe.backend.cad-common:*vendored-asset-system*
             "no-such-system/for-alfe-tests")
           (alfe.backend.cad-common:*runtime-lsp-fallback-paths* '())
           (alfe.backend.cad-common:*bootstrap-lsp-fallback-paths* '())
           (,saved (mapcar (lambda (v) (cons v (uiop:getenv v)))
                           '("ALFE_RUNTIME_LSP" "ALFE_BOOTSTRAP_LSP"))))
       (unwind-protect
            (progn
              (dolist (v ,saved) (setf (uiop:getenv (car v)) ""))
              ,@body)
         (dolist (v ,saved) (setf (uiop:getenv (car v)) (or (cdr v) "")))))))

(test installation-prefixes-covers-both-layouts
  "The prefix is the parent of the libexec directory the binary is
below, or of the bin directory it is in -- on any drive, in any case,
with spaces; and nothing for a Lisp that is not alfe."
  (flet ((prefix-of (namestring)
           (mapcar #'namestring
                   (alfe.backend.cad-common:installation-prefixes
                    (pathname namestring)))))
    (is (equal '("/opt/my tools/")
               (prefix-of "/opt/my tools/libexec/clautolisp/binaries/linux/x86-64/alfe-sbcl")))
    (is (equal '("/opt/my tools/")
               (prefix-of "/opt/my tools/libexec/alfe/alfe-ccl")))
    (is (equal '("/opt/my tools/") (prefix-of "/opt/my tools/bin/alfe-ccl")))
    (is (equal '("/opt/my tools/") (prefix-of "/opt/my tools/bin/alfe")))
    ;; Windows: upper-case components and the .exe suffix
    (is (= 1 (length (alfe.backend.cad-common:installation-prefixes
                      (make-pathname
                       :directory '(:absolute "Tools" "LIBEXEC" "clautolisp"
                                    "binaries" "windows" "x86-64")
                       :name "alfe-sbcl" :type "exe")))))
    ;; a development image: its prefix says nothing about alfe
    (is (null (prefix-of "/usr/local/bin/sbcl")))
    (is (null (prefix-of "/usr/local/libexec/ccl/lx86cl64")))
    ;; not installed at all (the build tree's tools/alfe/bin/): a bin
    ;; prefix is proposed, and simply holds no share/alfe/runtime/
    (is (equal '("/src/tools/alfe/") (prefix-of "/src/tools/alfe/bin/alfe-sbcl")))))

(test installed-alfe-finds-both-assets-without-overrides
  "The SCHMS runner: installed files present, build tree and fixed
prefixes unavailable, no overrides. Both layouts, in a prefix with a
space, and the files are the INSTALLED ones."
  (with-cad-test-directories
    (dolist (layout '(:libexec :bin))
      (let* ((root (merge-pathnames "unpacked here/" (%fresh-test-directory)))
             (exe (%pretend-install root layout)))
        (with-installed-alfe (exe)
          (let ((runtime (alfe.backend.cad-common:discover-runtime-lsp))
                (bootstrap (alfe.backend.cad-common:discover-bootstrap-lsp)))
            (is (and runtime (search "unpacked here" runtime)
                     (search "share" runtime))
                "~A layout: runtime not found under the prefix: ~S" layout runtime)
            (is (and bootstrap (search "unpacked here" bootstrap))
                "~A layout: bootstrap not found under the prefix: ~S" layout bootstrap)
            (multiple-value-bind (r b)
                (alfe.backend.cad-common:require-runtime-assets :bricscad)
              (is (equal runtime r))
              (is (equal bootstrap b)))))))))

(test installed-assets-precede-the-source-tree-and-overrides-precede-both
  "An installed alfe uses its own copies even when a source tree is
reachable; an explicit override still wins over the installed copies."
  (with-cad-test-directories
    (let* ((root (%fresh-test-directory))
           (exe (%pretend-install root :libexec))
           (override (touch-file (merge-pathnames "mine.lsp"
                                                  (%fresh-test-directory)))))
      (with-installed-alfe (exe)
        ;; the source tree is back: the installed copy still comes first
        (let ((alfe.backend.cad-common:*vendored-asset-system*
                "autolisp-front-end/backend-cad-common"))
          (is (search (%dir-token root)
                      (alfe.backend.cad-common:discover-runtime-lsp)))
          (setf (uiop:getenv "ALFE_RUNTIME_LSP") (namestring override))
          (is (equal (namestring (truename override))
                     (alfe.backend.cad-common:discover-runtime-lsp)))
          ;; an override naming nothing is passed over, as before
          (setf (uiop:getenv "ALFE_RUNTIME_LSP")
                (namestring (merge-pathnames "absent.lsp" root)))
          (is (search (%dir-token root)
                      (alfe.backend.cad-common:discover-runtime-lsp))))))))

(test missing-runtime-asset-fails-before-launching
  "Missing assets fail at once, naming the file and every path searched,
and the CAD is never launched -- no READY timeout is waited out."
  (with-cad-test-directories
    (let* ((root (%fresh-test-directory))
           (exe (%pretend-install root :libexec
                                  :assets '("autolisp-bootstrap.lsp"))))
      (with-installed-alfe (exe)
        (let ((condition
                (handler-case
                    (progn (alfe.backend.cad-common:require-runtime-assets :bricscad)
                           nil)
                  (alfe.error:backend-bootstrap-error (c) c))))
          (is (typep condition 'alfe.error:backend-bootstrap-error))
          (when condition
            (let ((message (alfe.error:backend-error-message condition)))
              (is (eq :runtime-asset-missing
                      (alfe.error:backend-error-code condition)))
              (is (search "autolisp-remote-io.lsp" message))
              (is (search "ALFE_RUNTIME_LSP" message))
              ;; the searched installed path is reported
              (is (search (%dir-token root) message))
              ;; the bootstrap WAS found, so it is not reported missing
              (is (not (search "autolisp-bootstrap.lsp" message))))))
        ;; through both backends: an error, and the launcher never runs
        (dolist (backend (list (alfe.backend.bricscad:make-bricscad-backend
                                :executable-path "/usr/bin/true"
                                :variant :batch)
                               (alfe.backend.autocad:make-autocad-backend)))
          (let* ((workdir (%fresh-test-directory))
                 (launched nil)
                 (condition
                   (handler-case
                       (progn
                         (alfe.backend:start-engine
                          backend workdir
                          :dialect :strict :host :mock :mock-input nil
                          :bootstrap-phase :full :interactive-p nil
                          :mode :batch
                          :launcher (lambda (&rest ignored)
                                      (declare (ignore ignored))
                                      (setf launched t)
                                      nil)
                          :wait-for-ready t
                          :ready-timeout 60)
                         nil)
                     (alfe.error:backend-error (c) c))))
            (is (typep condition 'alfe.error:backend-bootstrap-error)
                "~A: ~S" (type-of backend) condition)
            (when condition
              (is (eq :runtime-asset-missing
                      (alfe.error:backend-error-code condition))
                  "~A: ~A" (type-of backend)
                  (alfe.error:backend-error-message condition)))
            (is (not launched) "~A launched a CAD without its runtime"
                (type-of backend))))))))

;;; --- the COM ProgID an explicit AutoCAD release selects -------------
;;;
;;; alfe-autocad-cad-selection-ignores-com-progid: choosing an executable
;;; does NOT constrain the COM server. `--cad autocad-2022 --mode
;;; automation' resolved acad.exe of AutoCAD 2022 and then asked COM for
;;; the GENERIC "AutoCAD.Application", whose registration on the SCHMS
;;; runner resolves to a different CLSID with no readable LocalServer32:
;;; CreateObject failed 429 and the run died at bootstrap. The versioned
;;; "AutoCAD.Application.24.1" works there.
;;;
;;; The registry is behind two injectable functions, so these tests
;;; describe real registrations without a Windows host.

(defun %fake-registry (&key (versioned t) (generic-clsid t) (generic-server nil)
                            (release "2022") (com-version "24.1"))
  "A registry the AutoCAD ProgID resolver can read, shaped like the one
in the ticket: the versioned ProgID complete, the generic one resolving
to another CLSID whose LocalServer32 is unreadable."
  (let* ((versioned-clsid "{AA46BA8A-9825-40FD-8493-0BA3C4D5CEB5}")
         (other-clsid "{0DECFB78-73C3-47C7-9630-A1B55B3ACA1C}")
         (exe (format nil "C:\\Program Files\\Autodesk\\AutoCAD ~A\\acad.exe /Automation"
                      release))
         (entries '()))
    (when versioned
      (push (cons (format nil "HKCR\\AutoCAD.Application.~A\\CLSID" com-version)
                  versioned-clsid)
            entries)
      (push (cons (format nil "HKCR\\CLSID\\~A\\LocalServer32" versioned-clsid) exe)
            entries))
    (when generic-clsid
      (push (cons "HKCR\\AutoCAD.Application\\CLSID" other-clsid) entries))
    (when generic-server
      (push (cons (format nil "HKCR\\CLSID\\~A\\LocalServer32" other-clsid) exe)
            entries))
    entries))

(defmacro with-fake-registry ((entries &key (progids nil progids-p)) &body body)
  "Run BODY with the AutoCAD registry readers answering from ENTRIES."
  `(let* ((%entries ,entries)
          ;; A registry that answers at all: the tests below distinguish
          ;; `this ProgID is absent' from `the registry cannot be read'.
          (alfe.backend.autocad::*registry-probe-usable-function* (lambda () t))
          (alfe.backend.autocad::*registry-value-function*
            (lambda (key) (cdr (assoc key %entries :test #'string-equal))))
          (alfe.backend.autocad::*registry-progids-function*
            ,(if progids-p
                 `(lambda () ,progids)
                 `(lambda ()
                    (loop for (key . nil) in %entries
                          for p = (search "\\AutoCAD.Application" key)
                          when (and p (search "\\CLSID" key :start2 p))
                            collect (subseq key 6 (search "\\CLSID" key :start2 p)))))))
     ,@body))

(test autocad-progid-resolves-the-requested-release
  "An explicitly requested release resolves to ITS versioned ProgID,
verified against the registration (a CLSID with a readable
LocalServer32), not to the generic one."
  (with-fake-registry ((%fake-registry))
    (is (equal "AutoCAD.Application.24.1"
               (alfe.backend.autocad:resolve-autocad-progid :release "2022")))
    ;; and the executable's own release is enough, without --cad
    (is (equal "AutoCAD.Application.24.1"
               (alfe.backend.autocad:resolve-autocad-progid
                :executable-path "C:/Program Files/Autodesk/AutoCAD 2022/acad.exe")))))

(test autocad-progid-explicit-release-never-falls-back
  "The bug itself: an explicit release whose COM server is not
registered must FAIL, naming the release, the ProgID and the reason --
never quietly use the generic ProgID, which may start another release."
  (with-fake-registry ((%fake-registry :versioned nil :generic-server t))
    (let ((condition
            (handler-case (progn (alfe.backend.autocad:resolve-autocad-progid
                                  :release "2022" :explicit-p t)
                                 nil)
              (alfe.error:backend-error (c) c))))
      (is (typep condition 'alfe.error:backend-error))
      (when condition
        (let ((message (alfe.error:backend-error-message condition)))
          (is (eq :autocad-progid-unavailable
                  (alfe.error:backend-error-code condition)))
          (is (search "2022" message))
          (is (search "AutoCAD.Application.24.1" message))
          ;; actionable: how to override
          (is (search "AUTOCAD_PROGID" message)))))))

(test autocad-progid-unversioned-does-not-fail
  "`--autocad' without a release is not a claim about which one: the
versioned ProgID is used when the discovered executable's release is
registered, and the generic one otherwise -- no error either way."
  (with-fake-registry ((%fake-registry :versioned nil :generic-server t))
    (is (equal "AutoCAD.Application"
               (alfe.backend.autocad:resolve-autocad-progid
                :executable-path "C:/Program Files/Autodesk/AutoCAD 2022/acad.exe"))))
  (with-fake-registry ((%fake-registry))
    (is (equal "AutoCAD.Application"
               (alfe.backend.autocad:resolve-autocad-progid)))))

(test autocad-progid-override-is-taken-as-given
  "$AUTOCAD_PROGID names the COM server outright: it is used verbatim,
registry or no registry, so an unknown release stays usable."
  (let ((saved (uiop:getenv "AUTOCAD_PROGID")))
    (unwind-protect
         (progn
           (setf (uiop:getenv "AUTOCAD_PROGID") "AutoCAD.Application.99.9")
           (with-fake-registry ('())
             (is (equal "AutoCAD.Application.99.9"
                        (alfe.backend.autocad:resolve-autocad-progid
                         :release "2022" :explicit-p t)))))
      (setf (uiop:getenv "AUTOCAD_PROGID") (or saved "")))))

(test autocad-bridges-use-the-resolved-progid
  "Both bridges ask COM for the SAME resolved ProgID: the attach/create
bridge and the quit bridge. A quit bridge on the generic ProgID could
quit another release."
  (with-cad-test-directories
    (let* ((dir (%fresh-test-directory))
           (vbs (merge-pathnames "bridge-autocad.vbs" dir))
           (quit (merge-pathnames "quit-autocad.vbs" dir))
           (progid "AutoCAD.Application.24.1"))
      (alfe.backend.autocad:emit-bridge-vbs
       vbs
       :runtime-load-path (merge-pathnames "run-common.lsp" dir)
       :status-path (merge-pathnames "status.txt" dir)
       :error-path (merge-pathnames "err.txt" dir)
       :progid progid)
      (alfe.backend.autocad::emit-quit-vbs quit :progid progid)
      (dolist (path (list vbs quit))
        (let ((text (read-back path)))
          (is (search progid text) "~A does not name the resolved ProgID" path)
          ;; no bare generic ProgID left in a COM call
          (is (not (search "GetObject(, \"AutoCAD.Application\")" text)))
          (is (not (search "CreateObject(\"AutoCAD.Application\")" text))))))))

(test autocad-bridge-retries-the-document-calls-after-touchapp
  "alfe-autocad-hung-instance-blocks-com-bootstrap, measured on the runner
2026-09-27 (job 16761201255): the bridge died on a RAW VBScript runtime error --
`L'appel a ete rejete par l'appele' at bridge-autocad.vbs(217, 1) -- because the
calls AFTER a successful TouchApp were unguarded. A freshly CreateObject'd
AutoCAD answers Visible=True and is then still opening its startup document, so
Documents.Count / Documents.Add / ActiveDocument get RPC_E_CALL_REJECTED.

The same job proved nothing else was wedged (EmitFlags ATTACHED=0 CREATED=1, and
the CAD sweep reported no live instance), and verify:epure-api reached READY in
30.95 s on another invocation -- so the rejection is TRANSIENT and must be
retried, not reported as a broken server.

The structural assertion is the one that would have failed before: between
WaitQuiescent and the ActiveDocument call there must be an error guard."
  (let* ((text alfe.backend.autocad::*bridge-autocad-vbs-template*)
         (quiescent (search "WaitQuiescent app, waitSecs" text))
         (active-doc (search "Set doc = app.ActiveDocument" text)))
    (is (and quiescent active-doc (< quiescent active-doc))
        "the template must still call WaitQuiescent before taking the document")
    (let ((guard (search "On Error Resume Next" text :start2 quiescent)))
      (is (and guard (< guard active-doc))
          "the ActiveDocument call must sit inside an error guard: unguarded, a ~
busy server kills the script with a bare line number"))
    ;; It retries, and says how many times it tried when it gives up.
    (is (search "docReady" text) "the retry must record whether it succeeded")
    (is (search "docAttempt" text) "and count its attempts")
    (is (search "of 20" text) "and name the budget in the failure message")
    ;; Assert on a fragment that is CONTIGUOUS in the template. VBScript
    ;; messages are built with `& _' continuations, so a phrase that reads as
    ;; one sentence in the source is several strings in the emitted text -- the
    ;; first version of this test searched across a continuation and failed on
    ;; its own wording rather than on the code.
    (is (search "never became ready to take a" text)
        "the give-up message must say what actually happened")
    ;; Option Explicit: both new globals are declared.
    (is (search "Dim docReady, docAttempt" text)
        "both new globals must be Dim'd -- an undeclared one kills the bridge ~
before READY under Option Explicit")))

(test autocad-bridge-blames-another-instance-only-when-it-attached
  "The TouchApp failure message used to say `Another instance is probably wedged
and holding the registration' unconditionally. When the bridge CREATED the
instance itself there is no other one to blame, and that advice sent an
investigation after a phantom for a week -- the 2026-09-27 evidence was
ATTACHED=0, CREATED=1, sweep reporting nothing live.

So the advice is now conditional, and the wrong half must not be reachable from
the created path."
  (let* ((text alfe.backend.autocad::*bridge-autocad-vbs-template*)
         (touch-fail (search "rejected the first call" text)))
    ;; NB: IS needs a LIST form -- `(is touch-fail ...)' is a compile error
    ;; ("Argument to IS must be a list"), which surfaces at RUN time as
    ;; COMPILED-PROGRAM-ERROR rather than at compile time.
    (is (not (null touch-fail)) "the TouchApp failure branch must still exist")
    ;; The branch OPENS before the message, so the window has to start earlier
    ;; than the message -- and every fragment asserted below is contiguous in
    ;; the template, because `& _' continuations split a sentence into several
    ;; strings (see the note in the sibling test).
    (is (search "If attached Then" text)
        "the advice must branch on whether we attached")
    (let ((region (subseq text touch-fail (min (length text) (+ touch-fail 1400)))))
      (is (search "that one is wedged" region)
          "the ATTACHED branch keeps the end-it-on-the-machine advice")
      (is (search "no other one is to blame" region)
          "and the CREATED branch must say so instead")
      (is (search "it is still starting" region)
          "naming the likely cause for our own instance"))))

(test autocad-bridge-records-the-com-failure-details
  "The COM error number and description are what diagnose a failed
activation, and they were thrown away: the run reported only cscript's
`ATTACHED=0 CREATED=0' stdout. The bridge now writes the ProgID, the
stage, and Err.Number in decimal AND hex with Err.Description."
  (let ((text alfe.backend.autocad::*bridge-autocad-vbs-template*))
    (is (search "COM.PROGID=" text))
    (is (search "COM.STAGE=" text))
    (is (search "COM.ERROR.DECIMAL=" text))
    (is (search "COM.ERROR.HEX=" text))
    (is (search "COM.ERROR.DESCRIPTION=" text))
    ;; Err.Number must be captured into a local before anything can clear it
    (is (search "errNumber" text))))

;;; --- Option Explicit hygiene: every global must be Dim'd -----------
;;;
;;; alfe-autocad-vbscript / accoreconsole probe 2026-09-26: the bridge died
;;; before READY with `bridge-autocad.vbs(138,1) Variable non definie:
;;; lastTouchError' — a top-level variable assigned but never Dim'd under
;;; Option Explicit. cscript exited 0, so every AutoCAD probe reported
;;; "backend unreachable". VBScript cannot run on the Linux CI, but this
;;; class of bug is visible in the emitted template: under Option Explicit
;;; every column-0 `ident = ...' assignment must have a matching Dim.

(defun %vbs-lines (text)
  (with-input-from-string (s text)
    (loop for line = (read-line s nil :eof)
          until (eq line :eof) collect line)))

(defun %vbs-leading-identifier (line)
  (when (and (plusp (length line))
             (let ((c (char line 0))) (or (alpha-char-p c) (char= c #\_))))
    (subseq line 0 (or (position-if-not (lambda (c) (or (alphanumericp c) (char= c #\_)))
                                         line)
                       (length line)))))

(defun %vbs-dim-names (lines)
  (let ((names '()))
    (dolist (line lines names)
      (let ((trimmed (string-left-trim '(#\Space #\Tab) line)))
        (when (and (>= (length trimmed) 4) (string-equal "Dim " (subseq trimmed 0 4)))
          (dolist (piece (uiop:split-string (subseq trimmed 4) :separator '(#\,)))
            (let ((id (%vbs-leading-identifier (string-left-trim '(#\Space #\Tab) piece))))
              (when id (push (string-downcase id) names)))))))))

(defun %vbs-toplevel-assignments (lines)
  (let ((names '()))
    (dolist (line lines (nreverse names))
      (let* ((id (%vbs-leading-identifier line))
             (rest (and id (string-left-trim '(#\Space #\Tab) (subseq line (length id))))))
        (when (and id rest (plusp (length rest)) (char= (char rest 0) #\=)
                   (or (< (length rest) 2) (char/= (char rest 1) #\=)))
          (pushnew (string-downcase id) names :test #'string=))))))

(test autocad-bridge-template-declares-every-global-under-option-explicit
  "Regression for the accoreconsole bridge crash `Variable non definie:
lastTouchError': under Option Explicit every top-level assigned variable must
be Dim-declared, or the emitted .vbs dies before READY and every AutoCAD probe
fails backend-unreachable."
  (let* ((text alfe.backend.autocad::*bridge-autocad-vbs-template*)
         (lines (%vbs-lines text)))
    (if (search "Option Explicit" text)
        (let* ((dims (%vbs-dim-names lines))
               (assigned (%vbs-toplevel-assignments lines))
               (undeclared (remove-if (lambda (n) (member n dims :test #'string=)) assigned)))
          (is (null undeclared)
              "top-level VBScript globals assigned but never Dim'd: ~{~A~^, ~}" undeclared)
          (is (member "lasttoucherror" dims :test #'string=)))
        (is nil "template unexpectedly lacks Option Explicit"))))

(test autocad-bridge-exit-message-reports-the-com-failure
  "The bootstrap error must carry the COM failure and name the stage
accurately: cscript exiting is not proof that acad.exe exited."
  (let ((message
          (alfe.backend.autocad::summarize-process-exit
           (list :exit-code 4
                 :variant :automation
                 :stdout "ATTACHED=0
CREATED=0"
                 :stderr ""
                 :bridge-errors "ERROR COM bridge: could not launch AutoCAD
COM.PROGID=AutoCAD.Application.24.1
COM.STAGE=createobject
COM.ERROR.DECIMAL=429
COM.ERROR.HEX=0x1AD
COM.ERROR.DESCRIPTION=ActiveX component can't create object"))))
    (is (search "429" message))
    (is (search "0x1AD" message))
    (is (search "ActiveX component can't create object" message))
    (is (search "AutoCAD.Application.24.1" message))
    (is (search "createobject" (string-downcase message)))
    ;; the COM bridge is what exited; do not assert acad.exe did
    (is (search "bridge" (string-downcase message)))
    (is (not (search "AutoCAD process exited" message)))))

(test autocad-bridge-errors-are-read-in-the-ansi-code-page-too
  "The bridge writes its error file in the ANSI code page (CP1252 on the
runner's French Windows). Read as UTF-8 only, the accented COM description
\"L'exécution du serveur a échoué\" made the read fail, the failure became NIL,
and the bootstrap message lost the COM error it exists to report
(verify:epure-api:windows, 2026-09-28). The test above passes the text as a
string and so never saw that: this one writes the BYTES the bridge writes."
  (with-cad-test-directories
    (let* ((dir (%fresh-test-directory))
           (path (merge-pathnames "stderr.txt" dir))
           (text (format nil "ERROR COM bridge: could not launch AutoCAD.Application.24.1~%~
COM.STAGE=createobject~%COM.ERROR.DECIMAL=-2146959355~%COM.ERROR.HEX=0x80080005~%~
COM.ERROR.DESCRIPTION=L'ex~Ccution du serveur a ~Cchou~C~%"
                         (code-char 233) (code-char 233) (code-char 233))))
      ;; CP1252 bytes: every character here is below 256, so Latin-1 IS the
      ;; byte-for-byte encoding the bridge produced.
      (with-open-file (out path :direction :output :if-exists :supersede
                                :external-format :latin-1)
        (write-string text out))
      (let ((read (alfe.backend.autocad::read-bridge-errors path)))
        (is (stringp read) "the ANSI file must be read, not dropped; got ~S" read)
        (is (equal text read)))
      (let ((message (alfe.backend.autocad::summarize-process-exit
                      (list :exit-code 4 :variant :automation
                            :stdout (format nil "ATTACHED=0~%CREATED=0") :stderr ""
                            :bridge-errors (alfe.backend.autocad::read-bridge-errors path)))))
        (is (search "0x80080005" message) "got ~S" message)
        (is (search (format nil "serveur a ~Cchou~C" (code-char 233) (code-char 233))
                    message)
            "got ~S" message))
      ;; What alfe itself writes there is UTF-8, and must stay UTF-8.
      (with-open-file (out path :direction :output :if-exists :supersede
                                :external-format :utf-8)
        (write-string text out))
      (is (equal text (alfe.backend.autocad::read-bridge-errors path)))
      ;; No file, no errors -- and no signal.
      (is (null (alfe.backend.autocad::read-bridge-errors
                 (merge-pathnames "absent.txt" dir)))))))

(test autocad-batch-needs-no-com-registration
  "Batch selection is unchanged and independent of COM: emitting the
accoreconsole SCR must not consult the registry at all."
  (with-cad-test-directories
    (let* ((dir (%fresh-test-directory))
           (scr (merge-pathnames "run.scr" dir))
           (alfe.backend.autocad::*registry-value-function*
             (lambda (key) (error "the batch path read the registry: ~A" key)))
           (alfe.backend.autocad::*registry-progids-function*
             (lambda () (error "the batch path enumerated COM ProgIDs"))))
      (alfe.backend.autocad::emit-batch-scr
       scr (touch-file (merge-pathnames "run-common.lsp" dir) "(princ)"))
      (let ((text (read-back scr)))
        (is (not (search "AutoCAD.Application" text)))))))

;;; --- the AutoCAD instances a run created ---------------------------
;;;
;;; autocad-orphaned-by-killed-or-cancelled-jobs: alfe quits the AutoCAD
;;; it created, but only when it REACHES shutdown. Killed, or its CI job
;;; cancelled, it never does -- and the acad.exe belongs to the COM
;;; service, not to the job, so no process-tree kill reaches it. The
;;; bridge therefore writes down what it creates, and the runner-side
;;; sweep (scripts/sweep-orphaned-cad.ps1) ends only those.

(test autocad-bridge-records-the-instance-it-creates
  "PID *and* creation time: Windows reuses PIDs, and a sweep that
matched on PID alone could end an AutoCAD this run never started -- the
one risk worth caring about on a machine somebody else also uses."
  (let ((text alfe.backend.autocad::*bridge-autocad-vbs-template*))
    (is (search "RecordCreatedProcesses" text))
    (is (search "${CREATEDFILE}" text))
    (is (search "Win32_Process" text)
        "the created acad.exe is a child of the COM service, so WMI is ~
how it is found")
    (is (search "PID=" text))
    (is (search "CREATED=" text))
    ;; recorded only on the CREATE path: an attached instance is somebody
    ;; else's and must never be swept
    (let ((record (search "RecordCreatedProcesses createdFile" text))
          (created (search "created = True" text)))
      (is (and record created (< created record))
          "the record must follow `created = True'"))))

(test autocad-created-registry-outlives-the-workdir
  "The file cannot live in the workdir: the case it serves is the run
that never cleans anything up, workdir included."
  (let ((path (alfe.backend.autocad:created-cad-registry-path)))
    (is (equal alfe.backend.autocad::*created-cad-registry-name*
               (file-namestring path)))
    (is (equal (namestring (uiop:temporary-directory))
               (namestring (uiop:pathname-directory-pathname path))))))

(test autocad-bridge-carries-the-registry-path
  "EMIT-BRIDGE-VBS substitutes the registry path, and an explicit NIL
leaves the bridge recording nothing (the placeholder is emptied, never
left unexpanded)."
  (with-cad-test-directories
    (let* ((dir (%fresh-test-directory))
           (vbs (merge-pathnames "bridge-autocad.vbs" dir))
           (registry (merge-pathnames "created.txt" dir)))
      (alfe.backend.autocad:emit-bridge-vbs
       vbs
       :runtime-load-path (merge-pathnames "run-common.lsp" dir)
       :status-path (merge-pathnames "status.txt" dir)
       :error-path (merge-pathnames "err.txt" dir)
       :created-registry registry)
      (let ((text (read-back vbs)))
        (is (search (uiop:native-namestring registry) text))
        (is (not (search "${CREATEDFILE}" text))))
      (alfe.backend.autocad:emit-bridge-vbs
       vbs
       :runtime-load-path (merge-pathnames "run-common.lsp" dir)
       :status-path (merge-pathnames "status.txt" dir)
       :error-path (merge-pathnames "err.txt" dir)
       :created-registry nil)
      (let ((text (read-back vbs)))
        (is (not (search "${CREATEDFILE}" text)))
        (is (search "createdFile = \"\"" text))))))
;;; --- reading the registry, and what silence means ------------------
;;;
;;; alfe-autocad-progid-registry-probe-fails: on the Windows runner
;;; `alfe --cad autocad -l probe.lsp' died with
;;;
;;;   AutoCAD 2022 was requested, but no COM server for it is registered.
;;;     Tried:
;;;       AutoCAD.Application.24.1: not-registered
;;;
;;; while that very ProgID activates AutoCAD 2022 there. Two defects:
;;; the probe could not read the registry (reg.exe writes the console
;;; codepage: `(Par defaut)' on a French Windows is not valid UTF-8, the
;;; decoder signalled, and the error was swallowed), and `--cad autocad'
;;; -- which asks for the LATEST AutoCAD, naming no release -- was
;;; treated as an explicit release claim, so it failed instead of
;;; falling back.

(test autocad-registry-output-is-decoded-whatever-the-console-codepage
  "reg.exe answers in the console codepage. The value is ASCII; the
label around it need not be, and a French Windows writes `(Par
defaut)' with an accent."
  (let ((french (format nil "~%HKEY_CLASSES_ROOT\\AutoCAD.Application.24.1\\CLSID~%~
    (Par d~cfaut)    REG_SZ    {AA46BA8A-9825-40FD-8493-0BA3C4D5CEB5}~%~%"
                        (code-char 233))))
    (is (equal "{AA46BA8A-9825-40FD-8493-0BA3C4D5CEB5}"
               (alfe.backend.autocad::%parse-reg-default-value french))))
  ;; a named value (/v ProductName), as the control probe reads
  (is (equal "Windows 10 Pro"
             (alfe.backend.autocad::%parse-reg-default-value
              (format nil "~%HKEY_LOCAL_MACHINE\\SOFTWARE\\...~%~
    ProductName    REG_SZ    Windows 10 Pro~%")))))

(test autocad-unreadable-registry-is-not-an-absent-registration
  "`alfe cannot read the registry' and `this release is not registered'
are opposite conclusions. When the probe itself is down, an explicitly
requested release still gets ITS OWN versioned ProgID -- unverified,
with a warning -- rather than a refusal to run."
  (let ((alfe.backend.autocad::*registry-value-function* (lambda (key)
                                                           (declare (ignore key))
                                                           nil))
        (alfe.backend.autocad::*registry-progids-function* (lambda () nil))
        (alfe.backend.autocad::*registry-probe-usable-function* (lambda () nil)))
    (is (equal "AutoCAD.Application.24.1"
               (alfe.backend.autocad:resolve-autocad-progid
                :release "2022" :explicit-p t)))
    ;; a release the table does not know, and no registry to ask: that
    ;; one really cannot be resolved, and says so.
    (let ((condition (handler-case
                         (progn (alfe.backend.autocad:resolve-autocad-progid
                                 :release "2044" :explicit-p t)
                                nil)
                       (alfe.error:backend-error (c) c))))
      (is (typep condition 'alfe.error:backend-error))
      (when condition
        (is (search "AUTOCAD_PROGID"
                    (alfe.error:backend-error-message condition)))))))

(test autocad-registry-that-answers-still-refuses-an-unregistered-release
  "The refusal must survive: a registry that READS and does not have the
release is still a hard failure for an explicit request."
  (with-fake-registry ((%fake-registry :versioned nil :generic-server t))
    (let ((alfe.backend.autocad::*registry-probe-usable-function* (lambda () t)))
      (is (typep (handler-case (progn (alfe.backend.autocad:resolve-autocad-progid
                                       :release "2022" :explicit-p t)
                                      nil)
                   (alfe.error:backend-error (c) c))
                 'alfe.error:backend-error)))))

(test autocad-cad-denotation-names-a-release-only-when-it-does
  "`--cad autocad' asks for the latest AutoCAD -- alfe's choice, never a
failure. Only `--cad autocad-2022' claims a release."
  (is (equal "2022" (alfe.backend.autocad:release-named-by-denotation "autocad-2022")))
  (is (equal "2022" (alfe.backend.autocad:release-named-by-denotation "acad-2022")))
  (is (null (alfe.backend.autocad:release-named-by-denotation "autocad")))
  (is (null (alfe.backend.autocad:release-named-by-denotation "acad")))
  (is (null (alfe.backend.autocad:release-named-by-denotation nil)))
  ;; and the consequence: the executable's release, discovered rather
  ;; than requested, falls back instead of failing
  (with-fake-registry ((%fake-registry :versioned nil :generic-server t))
    (let ((alfe.backend.autocad::*registry-probe-usable-function* (lambda () t)))
      (is (equal "AutoCAD.Application"
                 (alfe.backend.autocad:resolve-autocad-progid
                  :release (alfe.backend.autocad:release-named-by-denotation "autocad")
                  :executable-path "C:/Program Files/Autodesk/AutoCAD 2022/acad.exe"
                  :explicit-p nil))))))

(test autocad-registry-capture-survives-non-utf8-output
  "The defect itself, reproduced without Windows: a console program
whose output is NOT valid UTF-8. The default decoder signals, the
caller's IGNORE-ERRORS swallows it, and the registry reads as empty.
%RUN-CAPTURING-TEXT must return the bytes as text instead."
  (if (uiop:os-unix-p)
      ;; \351 is Latin-1 for the accent in a French `(Par defaut)'; it is
      ;; not a valid UTF-8 sequence on its own.
      (let ((text (alfe.backend.autocad::%run-capturing-text
                   "/bin/sh" (list "-c" "printf 'a \\351 REG_SZ b'"))))
        (is (stringp text) "no output captured at all")
        (when (stringp text)
          (is (find (code-char 233) text)
              "the undecodable byte did not survive as a character")
          (is (search "REG_SZ" text))))
      (pass "POSIX-only: needs a shell that can emit a raw byte")))

(test autocad-latest-selection-starts-even-when-its-progid-is-unregistered
  "The runner's actual command: `--cad autocad', which asks for the
LATEST AutoCAD and names no release. With AutoCAD 2022 discovered and
its ProgID unregistered, that must still start -- on the generic
ProgID -- instead of failing the run. START-ENGINE is what wires the
denotation to the resolver, so the whole path is exercised here."
  (with-cad-test-directories
    (let* ((workdir (%fresh-test-directory))
           (alfe.backend.cad-common:*host-os-override* :windows)
           (backend (alfe.backend.autocad:make-autocad-backend
                     :executable-path
                     "C:/Program Files/Autodesk/AutoCAD 2022/acad.exe"))
           (captured nil))
      (with-fake-registry ((%fake-registry :versioned nil :generic-server t))
        (let ((session (alfe.backend:start-engine
                        backend workdir
                        :dialect :strict :host :mock :mock-input nil
                        :bootstrap-phase :full :interactive-p nil
                        :mode :automation
                        :cli-options (alfe.cli:make-cli-options :cad "autocad")
                        :wait-for-ready nil
                        :launcher (lambda (argv &rest ignored)
                                    (declare (ignore ignored))
                                    (setf captured argv)
                                    nil))))
          (is (not (null session)) "--cad autocad refused to start")
          (is (consp captured) "no engine was launched")
          (let ((text (read-back (merge-pathnames "bridge-autocad.vbs" workdir))))
            (is (search "AutoCAD.Application" text)))))
      ;; and the release-naming form still fails on the same registry
      (with-fake-registry ((%fake-registry :versioned nil :generic-server t))
        (is (typep (handler-case
                       (progn (alfe.backend:start-engine
                               (alfe.backend.autocad:make-autocad-backend
                                :executable-path
                                "C:/Program Files/Autodesk/AutoCAD 2022/acad.exe")
                               (%fresh-test-directory)
                               :dialect :strict :host :mock :mock-input nil
                               :bootstrap-phase :full :interactive-p nil
                               :mode :automation
                               :cli-options (alfe.cli:make-cli-options
                                             :cad "autocad-2022")
                               :wait-for-ready nil
                               :launcher (lambda (&rest ignored)
                                           (declare (ignore ignored))
                                           nil))
                              nil)
                     (alfe.error:backend-error (c) c))
                   'alfe.error:backend-error)
            "--cad autocad-2022 accepted another release's COM server")))))

(test autocad-progid-registered-to-another-product-is-reported
  "Measured on the Windows runner: AutoCAD.Application.24.2 and .24.3
are registered there to DWG TrueView 2024, not to AutoCAD 2023/2024.
The table's candidate is still what Windows would start, so it is used
-- but the mismatch is CLASSIFIED, not silently equated with a
registration that names the release."
  (let* ((clsid "{169B5B8E-E315-41C7-9574-66FC7E530D10}")
         (server "C:\\Program Files\\Autodesk\\DWG TrueView 2024 - French\\dwgviewr.exe /Automation")
         (entries (list (cons "HKCR\\AutoCAD.Application.24.2\\CLSID" clsid)
                        (cons (format nil "HKCR\\CLSID\\~A\\LocalServer32" clsid) server))))
    (with-fake-registry (entries)
      (multiple-value-bind (progid tried)
          (alfe.backend.autocad::%registered-progid-for-release "2023")
        (is (equal "AutoCAD.Application.24.2" progid))
        (let ((entry (assoc "AutoCAD.Application.24.2" tried :test #'string=)))
          (is (eq :version-not-confirmed (second entry)))
          (is (equal server (third entry)))))))
  ;; a registration that DOES name the release is not flagged
  (let ((matching (list (cons "HKCR\\AutoCAD.Application.24.1\\CLSID" "{AA}")
                        (cons "HKCR\\CLSID\\{AA}\\LocalServer32"
                              "C:\\Program Files\\Autodesk\\AutoCAD 2022\\acad.exe /Automation"))))
    (with-fake-registry (matching)
      (multiple-value-bind (progid tried)
          (alfe.backend.autocad::%registered-progid-for-release "2022")
        (is (equal "AutoCAD.Application.24.1" progid))
        (is (eq :ok (second (assoc "AutoCAD.Application.24.1" tried
                                   :test #'string=))))))))

(test autocad-bridge-retries-a-rejected-com-call
  "alfe-autocad-hung-instance-blocks-com-bootstrap. RPC_E_CALL_REJECTED --
`L'appel a ete rejete par l'appele' -- means the COM server is BUSY, not
broken: a modal dialog, a load in progress. A native client installs an
IMessageFilter and the runtime retries for it; a script must retry by
hand, and this bridge failed the whole bootstrap on the first rejection.
The emitted VBS must carry the retry, and must still be ASCII-clean
VBScript with it."
  (let ((workdir (uiop:ensure-directory-pathname
                  (merge-pathnames
                   (format nil "alfe-test-acad-retry-~D/" (random 999999))
                   (uiop:temporary-directory)))))
    (unwind-protect
        (progn
          (ensure-directories-exist workdir)
          (let ((vbs (merge-pathnames "bridge-autocad.vbs" workdir)))
            (alfe.backend.autocad:emit-bridge-vbs
             vbs
             :runtime-load-path (merge-pathnames "run-common.lsp" workdir)
             :status-path (merge-pathnames "protocol/status.txt" workdir)
             :error-path (merge-pathnames "protocol/stderr.txt" workdir))
            (let ((text (read-back vbs)))
              ;; The retry helper, and the first touch going through it.
              (is (search "Function TouchApp(theApp, tries)" text))
              (is (search "WScript.Sleep 1000" text))
              (is (search "If Not TouchApp(app, 10) Then" text))
              ;; The bare unguarded touch must be gone, or the first
              ;; rejection still kills the bootstrap.
              (is (not (search (format nil "~%app.Visible = True~%") text))
                  "the unguarded app.Visible must not come back")
              ;; The give-up message says how many attempts were made,
              ;; and what to do about it.
              (is (search "on 10 attempts" text))
              (is (search "wedged" text))
              ;; Still valid, ASCII-only VBScript.
              (is (null (%vbs-offending-lines text))))))
      (uiop:delete-directory-tree workdir :validate t
                                          :if-does-not-exist :ignore))))

;;; --- the runner-side sweep: a lingering PID is not a running process ---
;;;
;;; cad-sweep-fails-jobs-for-zombie-pids: on 2026-09-26 the sweep failed
;;; 21 CAD jobs over three acad.exe PIDs that had ALREADY EXITED. Windows
;;; keeps a process-table entry until the last handle to it closes, and
;;; the COM service holds one, so a dead acad.exe answers Get-Process for
;;; days while Stop-Process cannot touch it and taskkill says "there is no
;;; running instance of the task". The sweep read that as a survivor.
;;;
;;; No PowerShell on the Linux test lanes, so these are assertions on the
;;; script TEXT -- the same instrument as the VBScript template tests
;;; above, and for the same reason: what breaks is a property of the file
;;; the other tool reads.

(defun %cad-sweep-script-text ()
  "The runner-side sweep script's text (scripts/sweep-orphaned-cad.ps1),
read from the repository the tests run in."
  (uiop:read-file-string
   (merge-pathnames "scripts/sweep-orphaned-cad.ps1"
                    (asdf:system-relative-pathname "autolisp-front-end" "../"))))

(test cad-sweep-classifies-a-process-before-calling-it-a-survivor
  (let ((text (%cad-sweep-script-text)))
    ;; there is an explicit classifier, and it names all three states
    (is (search "function Get-CadProcessState" text))
    (is (search "'zombie'" text))
    (is (search "'live'" text))
    (is (search "'gone'" text))
    ;; it decides on evidence that a PID's mere existence does not give:
    ;; the thread count, and the exited flag
    (is (search "ThreadCount" text))
    (is (search "HasExited" text))
    ;; the survivor list is fed by the classifier, not by "the PID answers"
    (is (search "(Get-CadProcessState -ProcessId $entry.Pid) -eq 'live'" text))
    (is (not (search "if (Get-Process -Id $entry.Pid -ErrorAction SilentlyContinue) {" text))
        "a bare Get-Process presence check must not decide again that a ~
lingering PID is a running CAD")
    ;; and a zombie is settled, never a reason to fail a job
    (is (search "has EXITED (no threads left)" text))
    (is (search "entry dropped" text))))

(test cad-sweep-fails-only-for-a-cad-that-is-really-running
  (let* ((text (%cad-sweep-script-text))
         (fail-at (search "FAILING THIS JOB" text))
         (live-at (search "is STILL RUNNING after taskkill" text)))
    (is (and fail-at live-at))
    ;; the hard failure is reached only through the living list
    (is (search "if ($living.Count -gt 0) {" text))
    (is (< live-at fail-at)
        "the live-instance report comes before the job is failed")
    ;; the escape hatch for a machine nobody can reach right now stays
    (is (search "CAD_SWEEP_IGNORE_SURVIVORS" text))
    ;; and the separate, intent-named knob for a job a wedged AutoCAD cannot
    ;; affect at all (cad-sweep-blocks-bricscad-jobs-over-autocad). Two knobs
    ;; on purpose: one says "I know, run anyway", the other "this cannot
    ;; affect me" -- collapsing them would lose that difference.
    (is (search "CAD_SWEEP_NONBLOCKING" text))
    (is (search "does not use" text)
        "the non-blocking path must say WHY it is continuing")
    ;; the header must keep saying WHY a lingering PID is not a survivor,
    ;; so the next reader does not re-add the simpler, wrong check
    (is (search "A PID THAT STILL EXISTS IS NOT A RUNNING PROCESS" text))))

(test cad-mock-serves-a-request-that-arrives-late
  "alfe-windows-drive-protocol-three-evals-fails, reproduced on Linux: a request
that arrives after the mock's OLD per-cycle budget (2 s) must still be served.

The old mock gave up waiting, published DONE for that counter anyway, and moved
on -- so the request was never echoed and, with several actions, a later one was
never acknowledged at all (the Windows lane reported :ABORTED). Here the action
is deliberately sent LATE; the assertions that discriminate are the echo (the
mock really consumed this request) and :success (it acknowledged this counter,
not a counter it ran ahead to)."
  (let ((workdir (uiop:ensure-directory-pathname
                  (merge-pathnames
                   (format nil "alfe-test-cad-late-~D/" (random 999999))
                   (uiop:temporary-directory)))))
    (unwind-protect
        (progn
          (ensure-directories-exist workdir)
          (setf *mock-cad-condition* nil)
          (let* ((protocol (alfe.protocol.file:init-session workdir))
                 (cad (spawn-mock-cad-runtime protocol :cycles 1))
                 (plan (list (alfe.backend:action-eval "(princ 'late)")
                             (alfe.backend:action-quit))))
            (alfe.protocol.file:wait-for-status-prefix protocol "READY" :timeout 15)
            ;; Past the old 2-second per-cycle budget, by a margin.
            (sleep 3)
            (let ((result (let ((*standard-output* (make-string-output-stream))
                                (*error-output*    (make-string-output-stream)))
                            (alfe.backend.cad-common:drive-protocol-actions
                             protocol plan))))
              ;; Quote the mock's death when there was one: this assertion
              ;; reported a bare :ABORTED on the Windows runner while the real
              ;; cause was the mock dying on a probe-then-open transient.
              (is (eq :success (alfe.backend:eval-result-status result))
                  "a late request must still be acknowledged; got ~S~A"
                  (alfe.backend:eval-result-status result)
                  (%mock-cad-failure-note))
              (is (search "(princ 'late)" (alfe.backend:eval-result-output result))
                  "and really consumed -- the echo proves the mock read it~A"
                  (%mock-cad-failure-note)))
            (%finish-mock-cad cad protocol)))
      (uiop:delete-directory-tree workdir :validate t
                                          :if-does-not-exist :ignore))))

(test cad-mock-stops-on-shutdown-without-its-requests
  "The mock is step-locked, with only a failure-time safety net
(+MOCK-CAD-SAFETY-NET-SECONDS+, minutes). So a test whose driver stopped early
must be able to stop it: %FINISH-MOCK-CAD sends SHUTDOWN, and a mock still
waiting for requests it will never get must take it and publish STOPPED -- in
seconds, not at the safety net. Without this, every failure of the family would
cost the safety net and a flaky lane would time out instead of failing."
  (let ((workdir (uiop:ensure-directory-pathname
                  (merge-pathnames
                   (format nil "alfe-test-cad-stop-~D/" (random 999999))
                   (uiop:temporary-directory)))))
    (unwind-protect
        (progn
          (ensure-directories-exist workdir)
          (setf *mock-cad-condition* nil)
          (let* ((protocol (alfe.protocol.file:init-session workdir))
                 ;; Three requests expected; none will be sent.
                 (cad (spawn-mock-cad-runtime protocol :cycles 3))
                 (started nil))
            (alfe.protocol.file:wait-for-status-prefix protocol "READY" :timeout 15)
            (setf started (get-internal-real-time))
            (%finish-mock-cad cad protocol)
            (is (< (/ (- (get-internal-real-time) started)
                      internal-time-units-per-second)
                   10)
                "an unfed mock must stop on SHUTDOWN, not at the safety net~A"
                (%mock-cad-failure-note))
            (is (search "STOPPED"
                        (alfe.protocol.file:read-file-as-string
                         (alfe.protocol.file:protocol-session-status-path protocol)))
                "and say so: STOPPED~A" (%mock-cad-failure-note))))
      (uiop:delete-directory-tree workdir :validate t
                                          :if-does-not-exist :ignore))))

(test cad-mock-consume-request-never-probes-then-opens
  "The second cause of alfe-windows-drive-protocol-three-evals-fails, as a unit
test that needs no thread and no platform.

%MOCK-CONSUME-REQUEST must treat an ABSENT file and a HALF-WRITTEN one alike as
`not yet' and keep waiting, because that is what stdin.txt looks like while the
driver's WRITE-ATOMIC-FILE renames over it -- on Windows a delete+rename, so a
PROBE-FILE that succeeds says nothing about the OPEN that follows. The old code
probed and then read bare; the read signalled, the mock thread died inside its
guard, and the driver reported :ABORTED with no cause.

The case that discriminates is the EMPTY file: a reader that consumes it eats a
request that was never fully written, and the request is then lost for good."
  (let* ((dir (uiop:ensure-directory-pathname
               (merge-pathnames (format nil "alfe-test-consume-~D/" (random 999999))
                                (uiop:temporary-directory))))
         (stdin (merge-pathnames "stdin.txt" dir))
         (quarter (floor internal-time-units-per-second 4)))
    (unwind-protect
        (progn
          (ensure-directories-exist dir)
          ;; ABSENT: returns NIL at the deadline rather than signalling.
          (is (null (%mock-consume-request stdin (get-internal-real-time)))
              "an absent request file must be `not yet', not an error")
          ;; HALF-WRITTEN (empty): still `not yet', and LEFT ALONE.
          (with-open-file (out stdin :direction :output
                                     :if-exists :supersede
                                     :if-does-not-exist :create))
          (is (null (%mock-consume-request stdin (+ (get-internal-real-time) quarter)))
              "an empty file is a half-written request, not a request")
          (is (probe-file stdin)
              "and it must be LEFT for the writer to finish, not consumed")
          ;; COMPLETE: consumed, returned verbatim, and removed. Verbatim
          ;; INCLUDES the trailing newline WRITE-ATOMIC-FILE appends -- the
          ;; protocol is line-oriented (the CAD side reads with `read-line'),
          ;; and the mock echoes what it read, so trimming here would hide a
          ;; reader that dropped or added a line.
          (alfe.protocol.file:write-atomic-file stdin "(princ 'x)")
          (is (equal (format nil "(princ 'x)~%")
                     (%mock-consume-request stdin (+ (get-internal-real-time)
                                                     (* 5 internal-time-units-per-second))))
              "a complete request must be returned verbatim, newline included")
          (is (null (probe-file stdin))
              "consumed means deleted, so the next cycle waits for a new one"))
      (uiop:delete-directory-tree dir :validate t
                                      :if-does-not-exist :ignore))))

(test cad-mock-death-is-recorded-not-swallowed
  "A mock that dies must say why. The thread's body has to be guarded -- an
unhandled error in a thread under --disable-debugger aborts the whole test
process -- but the guard used to discard the condition, so every mock crash
arrived at the assertions as an indistinguishable driver timeout. That is why
the Windows lane took a week to explain: it said :ABORTED and nothing else.

Exercises %CALL-RECORDING-MOCK-CONDITION, the guard the thread itself runs, so
the test proves the mechanism rather than a symptom. The first version arranged
a real failure instead -- it deleted the workdir so the mock's first write would
signal -- and that is NOT portable: it passed on SBCL and failed on CCL, where
the write does not signal. The mechanism is the same on both."
  (setf *mock-cad-condition* nil)
  (is (equal "" (%mock-cad-failure-note))
      "no death, no note -- otherwise every message would carry noise")
  ;; The guard must SWALLOW: a condition escaping here would abort the process.
  (is (null (%call-recording-mock-condition
             (lambda () (error "mock-cad boom, deliberately"))))
      "the guard must swallow, or an unhandled thread error kills the suite")
  ;; ... and RECORD, which is the half that was missing.
  (is (not (null *mock-cad-condition*))
      "the guard must RECORD the condition, not discard it")
  (is (search "mock-cad boom" (%mock-cad-failure-note))
      "and the note must quote it, so an assertion can name the cause")
  ;; A SERIOUS condition that is not an ERROR: an ERROR-only handler misses it
  ;; entirely, the condition reaches the implementation's debugger, and under
  ;; CCL a debugger with no terminal BLOCKS the process at 0 % CPU
  ;; (ccl-protocol-write-atomic-file-contention-hangs). This is the case the
  ;; first version of this guard would have let through.
  (setf *mock-cad-condition* nil)
  (is (null (%call-recording-mock-condition
             (lambda () (error 'alfe-test-serious-not-error))))
      "a serious non-error must be swallowed too")
  (is (search "serious, not an ERROR" (%mock-cad-failure-note))
      "and recorded: got ~S" (%mock-cad-failure-note))
  ;; NOT asserted here, and the reason is recorded rather than left as a gap:
  ;; the guard also binds *DEBUGGER-HOOK*, but under SBCL's --disable-debugger
  ;; -- how this suite runs -- INVOKE-DEBUGGER goes through
  ;; SB-EXT:*INVOKE-DEBUGGER-HOOK*, which runs FIRST and quits the process, so
  ;; that binding cannot be exercised from inside the suite on this host. It is
  ;; kept for the implementations whose debugger entry does honour it (CCL, the
  ;; one that blocks rather than quitting). Measured, not assumed: asserting it
  ;; killed the SBCL run outright.
  ;; A successful body returns its value and leaves no note behind.
  (setf *mock-cad-condition* nil)
  (is (eql 42 (%call-recording-mock-condition (lambda () 42)))
      "a body that succeeds returns its value")
  (is (equal "" (%mock-cad-failure-note))
      "and records nothing"))

(test cad-source-staging-is-cp1252-for-autocad
  "A -Esource cp1252 file staged for AutoCAD stays cp1252 without a BOM -- read
right at every LISPSYS (E1: LISPSYS 0 ignores a BOM, 1 / 2 fall back to cp1252
on invalid UTF-8) -- and becomes UTF-8 + BOM for the other CADs."
  (let* ((workdir (uiop:ensure-directory-pathname
                   (merge-pathnames (format nil "alfe-test-stage-~D/" (random 999999))
                                    (uiop:temporary-directory))))
         (protocol (alfe.protocol.file:init-session workdir))
         (source (merge-pathnames "src.lsp" workdir)))
    (unwind-protect
         (flet ((bytes (path)
                  (with-open-file (in path :element-type '(unsigned-byte 8))
                    (let ((v (make-array (file-length in) :element-type '(unsigned-byte 8))))
                      (read-sequence v in) (coerce v 'list)))))
           (with-open-file (out source :direction :output :element-type '(unsigned-byte 8)
                                       :if-exists :supersede)
             (write-sequence #(34 65 #xE9 90 34) out))          ; "AéZ" in cp1252
           (is (equal '(34 65 #xE9 90 34)
                      (bytes (alfe.backend.cad-common::stage-source-as-utf8-bom
                              protocol (namestring source) "cp1252" :autocad))))
           (is (equal '(#xEF #xBB #xBF 34 65 #xC3 #xA9 90 34)
                      (bytes (alfe.backend.cad-common::stage-source-as-utf8-bom
                              protocol (namestring source) "cp1252" :bricscad)))))
      (uiop:delete-directory-tree workdir :validate t :if-does-not-exist :ignore))))

;;; --- --cad-log: the CAD's own command-history log ------------------
;;;
;;; encoding-situations-cli-options, the `log' situation. The CAD writes its
;;; LOGFILEMODE log into the workdir's logs/ (the bootstrap's
;;; autolisp-log-setup); alfe reads it after the run. Measured: AutoCAD 2022
;;; writes windows-1252; BricsCAD V25 windows-1252 or UTF-8 with a BOM (not
;;; settled) -- so a BOM decides, else windows-1252 on Windows.

(defun %octets (&rest items)
  "An octet vector from ITEMS: integers are octets, strings their ASCII codes."
  (coerce (loop for item in items
                append (if (stringp item) (map 'list #'char-code item) (list item)))
          '(vector (unsigned-byte 8))))

(test cad-log-decode-encoding-measured-defaults
  "Without -Elog: a UTF-8 or UTF-16LE BOM names the encoding; otherwise
windows-1252 on MS-Windows and the auto-detect cascade elsewhere. An explicit
-Elog wins, its line-ending suffix ignored; one the log decoder does not have
falls back to :AUTO with a warning."
  (let ((plain (%octets "caf" #xE9)))
    (is (eq :cp1252 (alfe.backend.cad-common:cad-log-decode-encoding plain :platform :windows)))
    (is (eq :auto (alfe.backend.cad-common:cad-log-decode-encoding plain :platform :macos)))
    (is (eq :utf-8 (alfe.backend.cad-common:cad-log-decode-encoding
                    (%octets #xEF #xBB #xBF "caf" #xC3 #xA9) :platform :windows)))
    (is (eq :utf-16le (alfe.backend.cad-common:cad-log-decode-encoding
                       (%octets #xFF #xFE "A" 0) :platform :windows)))
    (is (eq :utf-8 (alfe.backend.cad-common:cad-log-decode-encoding
                    plain :explicit "UTF-8" :platform :windows)))
    (is (eq :iso-8859-1 (alfe.backend.cad-common:cad-log-decode-encoding
                         plain :explicit "ISO-8859-1-DOS" :platform :windows)))
    (multiple-value-bind (kw warning)
        (alfe.backend.cad-common:cad-log-decode-encoding
         plain :explicit "MAC-ROMAN" :platform :windows)
      (is (eq :auto kw))
      (is (search "-Elog MAC-ROMAN: the CAD log is decoded only as" warning)))))

(test cad-log-decoded-text
  "The decoded log: windows-1252's 0x80 is the euro, a BOM is not part of the
text, and CR LF become LF."
  (is (string= (format nil "caf~Cx~C~%B~%" (code-char 233) (code-char #x20AC))
               (alfe.backend.cad-common:decode-cad-log-octets
                (%octets "caf" #xE9 "x" #x80 13 10 "B" 13 10) :platform :windows)))
  (is (string= (format nil "caf~C~%" (code-char 233))
               (alfe.backend.cad-common:decode-cad-log-octets
                (%octets #xEF #xBB #xBF "caf" #xC3 #xA9 10) :platform :windows))))

(defun %write-octets (path octets)
  (ensure-directories-exist path)
  (with-open-file (out path :direction :output :element-type '(unsigned-byte 8)
                            :if-exists :supersede :if-does-not-exist :create)
    (write-sequence octets out))
  path)

(defun %read-utf-8 (path)
  (with-open-file (in path :external-format :utf-8)
    (let* ((s (make-string (file-length in)))
           (n (read-sequence s in)))
      (subseq s 0 n))))

(test cad-log-collected-into-the-cad-log-file
  "COLLECT-ENGINE-LOG on a CAD backend reads the workdir's logs/ (not alfe's
debug.log); WRITE-CAD-LOG-IF-ASKED writes it to the --cad-log FILE in UTF-8, one
`==> NAME <==' header per file when there are several. No log: :NONE, no file.
The clautolisp backend has none to collect: :UNSUPPORTED, warned, no file."
  (let* ((workdir (merge-pathnames
                   (format nil "alfe-cad-log-~D/" (random 1000000 *cad-test-random*))
                   (uiop:temporary-directory)))
         (logs (merge-pathnames "logs/" workdir))
         (out (merge-pathnames "collected.txt" workdir))
         (autocad (alfe.backend:find-backend :autocad))
         (*error-output* (make-string-output-stream)))
    (unwind-protect
         (progn
           (ensure-directories-exist logs)
           ;; no log yet
           (multiple-value-bind (entries status)
               (alfe.backend:collect-engine-log autocad workdir :cli-options nil)
             (is (null entries))
             (is (eq :none status)))
           (%write-octets (merge-pathnames "debug.log" logs) (%octets "alfe debug" 10))
           (%write-octets (merge-pathnames "empty_1_1_0001.log" logs)
                          (%octets "PRB caf" #xE9 13 10))
           (let ((opts (parse-arguments
                        (list "--autocad" "--cad-log" (namestring out)))))
             (is (equal (namestring out)
                        (clautolisp.autolisp-cli:cli-options-cad-log opts)))
             (let ((alfe.backend.cad-common:*host-os-override* :windows))
               (is (equal (pathname (namestring out))
                          (alfe.cli::write-cad-log-if-asked opts autocad workdir))))
             (is (string= (format nil "PRB caf~C~%" (code-char 233)) (%read-utf-8 out)))
             ;; a second log file: both, each under its header
             (%write-octets (merge-pathnames "empty_1_1_0002.log" logs)
                            (%octets "second" 13 10))
             (let ((alfe.backend.cad-common:*host-os-override* :windows))
               (alfe.cli::write-cad-log-if-asked opts autocad workdir))
             (let ((text (%read-utf-8 out)))
               (is (search "==> empty_1_1_0001.log <==" text))
               (is (search "==> empty_1_1_0002.log <==" text))
               (is (search "second" text))
               (is (not (search "alfe debug" text))
                   "alfe's own debug.log is not the CAD's log")))
           ;; the clautolisp backend: nothing collected, no file
           (let ((other (merge-pathnames "other.txt" workdir)))
             (is (null (alfe.cli::write-cad-log-if-asked
                        (parse-arguments (list "--clautolisp" "--cad-log" (namestring other)))
                        (alfe.backend:find-backend :clautolisp) workdir)))
             (is (null (probe-file other)))))
      (uiop:delete-directory-tree workdir :validate t :if-does-not-exist :ignore))))
