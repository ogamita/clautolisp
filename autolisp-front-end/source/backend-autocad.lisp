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
                #:expand-plugin-slots
                #:launcher-lines
                #:call-launcher
                #:discover-runtime-lsp
                #:discover-bootstrap-lsp
                #:require-runtime-assets
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
           #:resolve-autocad-progid
           #:created-cad-registry-path
           #:*created-cad-registry-name*
           #:release-named-by-denotation
           #:*generic-autocad-progid*
           #:*autocad-release-com-versions*
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

(defun discover-autocad-template (backend &key requested workdir)
  "Resolve the drawing/template to feed accoreconsole batch mode.
Order of precedence:
  1. REQUESTED (from --dwg) when it exists;
  2. $AUTOLISP_DWG when it exists;
  3. a FRESH empty.dwg written into WORKDIR from the copy carried in the
     image (alfe.drawing);
  4. a shipped acadiso.dwt/acad.dwt next to the discovered AutoCAD
     install;
  5. NIL, in which case the caller raises :no-dwg.

Step 3 is new (issues/open/empty-ressource.issue, pjb 2026-08-30). Every
run gets its OWN drawing because sharing one produces modal dialogs --
\"in use by another instance\", \"open read-only?\" -- when a previous CAD
still holds the lock or has modified the file, and a modal dialog in a
batch launch is a hung run rather than a slow one. accoreconsole OPENS
the drawing it is given (/i), so it is exactly the file that gets locked.

It also all but retires the :NO-DWG error below: that error meant \"this
machine has no template I can find\", and now alfe brings one."
  (or (and requested
           (probe-file requested)
           (namestring (truename requested)))
      (env-binary "AUTOLISP_DWG")
      (and workdir
           (let ((fresh (alfe.drawing:fresh-empty-dwg workdir)))
             (and fresh (namestring fresh))))
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

;;; --- which COM server an AutoCAD release means ---------------------
;;;
;;; Choosing acad.exe does NOT choose the COM server
;;; (alfe-autocad-cad-selection-ignores-com-progid). Automation runs
;;; cscript, and the ProgID it asks for is what Windows resolves --
;;; through the registry, to whatever release that registration names.
;;; `--cad autocad-2022' therefore has to ask for AutoCAD 2022's OWN
;;; ProgID, AutoCAD.Application.24.1, and not for the generic
;;; AutoCAD.Application: on the SCHMS runner the generic one resolves to
;;; a CLSID whose LocalServer32 cannot be read, so CreateObject fails
;;; 429 while the versioned one starts AutoCAD 2022 in 41 s.

(defparameter *generic-autocad-progid* "AutoCAD.Application"
  "The unversioned ProgID. Whichever release Windows last registered
answers to it -- which is why an explicitly requested release never
settles for it.")

(defparameter *autocad-release-com-versions*
  '(("2019" . "23.0") ("2020" . "23.1") ("2021" . "24.0") ("2022" . "24.1")
    ("2023" . "24.2") ("2024" . "24.3") ("2025" . "25.0") ("2026" . "25.1"))
  "Product year -> AutoCAD COM interface version, the ProgID suffix.
A LOOKUP TABLE, NOT A FORMULA: the year/version relation has changed
shape before (2020 is 23.1, 2021 is 24.0, 2025 is 25.0) and Autodesk
owes us no arithmetic. It only proposes a candidate -- the registry
decides, and a release missing from the table is resolved by asking the
registry what is installed.")

(defvar *registry-value-function* '%registry-default-value
  "Function (KEY) -> the key's default value as a string, or NIL.
The tests bind it to describe a registry without a Windows host.")

(defvar *registry-progids-function* '%registered-autocad-progids
  "Function () -> the AutoCAD.Application* ProgIDs registered on this
host. Bound by the tests, as *REGISTRY-VALUE-FUNCTION* is.")

(defparameter *reg-command-names* '("reg" "reg.exe")
  "How to spell reg.exe, tried in order. A PATH where `reg' does not
resolve (an MSYS2 shell environment is one) must not look like an empty
registry.")

(defun %run-capturing-text (command arguments)
  "COMMAND's output as text, or NIL if it cannot be run.

:EXTERNAL-FORMAT :LATIN-1 is the point of this function. A console
program writes in the console codepage, not UTF-8, and the default
decoder SIGNALS on a byte it cannot make sense of -- which is how a
French Windows' `(Par defaut)' turned a readable registry into an empty
one. Latin-1 decodes every byte and never signals."
  (ignore-errors
   (uiop:run-program (cons command arguments)
                     :output :string :error-output nil
                     :external-format :latin-1
                     :ignore-error-status t)))

(defun %reg-query (&rest arguments)
  "Run reg.exe with ARGUMENTS and return its output, or NIL. Windows
only; any failure (missing reg.exe, absent key) is NIL, not an error.

DECODED AS LATIN-1, ALWAYS. reg.exe writes in the console codepage, and
on a French Windows `reg query ... /ve' prints `(Par defaut)' with an
accent that is not valid UTF-8 -- so the default decoder SIGNALLED, the
error was swallowed here, and a registry that reads perfectly well
looked empty: every ProgID came back `not-registered'
(alfe-autocad-progid-registry-probe-fails.issue). Latin-1 is a total
decoder; the part we parse (REG_SZ, a CLSID, a path) is ASCII anyway."
  (when (windows-p)
    (dolist (command *reg-command-names*)
      (let ((output (%run-capturing-text command arguments)))
        (when (and output (plusp (length output)))
          (log-debug "backend AUTOCAD: ~A ~{~A ~}-> ~D character~:P"
                     command arguments (length output))
          (return output))))))

(defun %parse-reg-default-value (output)
  "The default value in `reg query KEY /ve' OUTPUT, or NIL."
  (with-input-from-string (in output)
    (loop for line = (read-line in nil nil)
          while line
          for type = (search "REG_" line)
          when type
            do (let* ((rest (subseq line type))
                      (space (position #\Space rest)))
                 (when space
                   (let ((value (string-trim '(#\Space #\Tab #\Return)
                                             (subseq rest space))))
                     (when (plusp (length value))
                       (return value))))))))

(defun %registry-default-value (key)
  (let ((output (%reg-query "query" key "/ve")))
    (when output (%parse-reg-default-value output))))

(defvar *registry-probe-usable-function* '%registry-probe-usable-p
  "Function () -> true when this host's registry can actually be read.")

(defun %registry-probe-usable-p ()
  "True when a value that exists on EVERY Windows can be read.
Distinguishes `this ProgID is not registered' from `alfe cannot read the
registry at all' -- opposite conclusions that were the same answer (NIL)
until the probe failed for real on the Windows runner. The control is a
NAMED value: a key like HKCR\\CLSID has thousands of subkeys and no
default value, so it answers neither quickly nor usefully."
  (and (windows-p)
       (let ((output (%reg-query "query"
                                 "HKLM\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion"
                                 "/v" "ProductName")))
         (and output (not (null (%parse-reg-default-value output)))))))

(defun %registered-autocad-progids ()
  "The AutoCAD.Application ProgIDs registered under HKEY_CLASSES_ROOT."
  (let ((output (%reg-query "query" "HKCR" "/f" "AutoCAD.Application" "/k")))
    (when output
      (with-input-from-string (in output)
        (loop for line = (read-line in nil nil)
              while line
              for trimmed = (string-trim '(#\Space #\Tab #\Return) line)
              for backslash = (position #\\ trimmed :from-end t)
              when (and backslash
                        (let ((name (subseq trimmed (1+ backslash))))
                          (and (>= (length name) (length *generic-autocad-progid*))
                               (string= *generic-autocad-progid* name
                                        :end2 (length *generic-autocad-progid*)))))
                collect (subseq trimmed (1+ backslash)))))))

(defun autocad-progid-registration (progid)
  "(values CLSID LOCAL-SERVER32) for PROGID. A usable registration has
both: the failing generic ProgID in the ticket HAS a CLSID and no
readable LocalServer32, and that is exactly the case to reject."
  (let* ((clsid (funcall *registry-value-function*
                         (format nil "HKCR\\~A\\CLSID" progid)))
         (server (when clsid
                   (funcall *registry-value-function*
                            (format nil "HKCR\\CLSID\\~A\\LocalServer32" clsid)))))
    (values clsid server)))

(defun %progid-for-com-version (version)
  (format nil "~A.~A" *generic-autocad-progid* version))

(defun %release-progid-candidates (release)
  "The ProgIDs that could be RELEASE's, table entry first, then whatever
is registered (which covers a release the table does not know)."
  (let* ((from-table (cdr (assoc release *autocad-release-com-versions*
                                 :test #'string=)))
         (registered (remove *generic-autocad-progid*
                             (ignore-errors (funcall *registry-progids-function*))
                             :test #'string=)))
    (remove-duplicates (if from-table
                           (cons (%progid-for-com-version from-table) registered)
                           registered)
                       :test #'string= :from-end t)))

(defun %registered-progid-for-release (release)
  "(values PROGID TRIED), PROGID being RELEASE's usable COM server or
NIL. TRIED lists (PROGID REASON DETAIL) for the diagnostic."
  (let ((tried '())
        (fallback nil))
    (dolist (progid (%release-progid-candidates release))
      (multiple-value-bind (clsid server) (autocad-progid-registration progid)
        (cond
          ((null clsid)
           (push (list progid :not-registered nil) tried))
          ((null server)
           (push (list progid :no-local-server clsid) tried))
          ((search release server)
           ;; The registration itself names the release: strongest evidence.
           (return-from %registered-progid-for-release
             (values progid (nreverse (cons (list progid :ok server) tried)))))
          (t
           ;; Usable, but its LocalServer32 does not name the release. Good
           ;; enough only if nothing better turns up -- and only for the
           ;; table's own candidate, whose version IS the release evidence.
           (push (list progid :version-not-confirmed server) tried)
           (unless fallback
             (let ((from-table (cdr (assoc release *autocad-release-com-versions*
                                           :test #'string=))))
               (when (and from-table
                          (string= progid (%progid-for-com-version from-table)))
                 (setf fallback progid))))))))
    (values fallback (nreverse tried))))

(defun %release-table-progid (release)
  "RELEASE's ProgID according to the table, or NIL when it is not in it."
  (let ((version (cdr (assoc release *autocad-release-com-versions*
                             :test #'string=))))
    (when version (%progid-for-com-version version))))

(defun %progid-diagnostic (release tried &key unreadable-p)
  (when unreadable-p
    (return-from %progid-diagnostic
      (format nil "AutoCAD ~A was requested, and alfe cannot read this host's~
~%  registry to find its COM server -- reg.exe did not answer. AutoCAD ~:*~A~
~%  is not in alfe's release table either, so there is no ProgID to try.~
~%  Name the server with $AUTOCAD_PROGID (e.g. AutoCAD.Application.24.1)."
              release)))
  (format nil "AutoCAD ~A was requested, but no COM server for it is registered.~
~:[~;~:*~%  Tried:~{~%    ~{~A: ~(~A~)~@[ (~A)~]~}~}~]~
~%  Not falling back to ~A: it is registered to whichever release Windows~
~%  last claimed it, so it may start a different AutoCAD.~
~%  Repair the AutoCAD ~A installation's COM registration, or name the~
~%  server outright with $AUTOCAD_PROGID (e.g. AutoCAD.Application.24.1)."
          release tried *generic-autocad-progid* release))

(defun release-named-by-denotation (denotation)
  "The release a --cad DENOTATION names (\"acad-2022\" -> \"2022\"), or
NIL when it names none: \"autocad\" and \"acad\" mean `the latest one',
which is alfe's choice to make and never a failure."
  (when denotation
    (alfe.backend.cad-common:autocad-release-in-path (string denotation))))

(defun resolve-autocad-progid (&key release executable-path explicit-p)
  "The COM ProgID the automation bridges ask for. Precedence:

  1. $AUTOCAD_PROGID, verbatim -- the escape hatch for a release this
     alfe has never heard of; no registry check, none is possible.
  2. RELEASE (from --cad autocad-YYYY) or the release of
     EXECUTABLE-PATH: that release's OWN ProgID, confirmed against the
     registry.
  3. The generic ProgID.

EXPLICIT-P says the user named the release. Then step 2 must succeed:
an unregistered release is an error (BACKEND-NOT-AVAILABLE, code
:AUTOCAD-PROGID-UNAVAILABLE) naming what was tried, never a quiet step
3 that could drive another release. Without EXPLICIT-P the release is
only alfe's own discovery, so step 3 is a legitimate answer."
  (let ((override (uiop:getenv "AUTOCAD_PROGID")))
    (cond
      ((and override (plusp (length override)))
       (log-debug "backend AUTOCAD: $AUTOCAD_PROGID = ~A" override)
       override)
      (t
       (let ((release (or release
                          (and executable-path
                               (alfe.backend.cad-common:autocad-release-in-path
                                executable-path)))))
         (cond
           ((null release) *generic-autocad-progid*)
           (t
            (multiple-value-bind (progid tried) (%registered-progid-for-release release)
              (cond
                (progid
                 (log-debug "backend AUTOCAD: release ~A -> ProgID ~A" release progid)
                 ;; Accepted on the table's authority, with a registration
                 ;; that names something else. Measured on the Windows
                 ;; runner: AutoCAD.Application.24.2 and .24.3 there are
                 ;; DWG TrueView 2024, not AutoCAD 2023/2024. Using it is
                 ;; still the best available answer -- it IS what Windows
                 ;; would start -- but saying nothing would hide that.
                 (let ((unconfirmed (find-if (lambda (entry)
                                               (and (string= (first entry) progid)
                                                    (eq (second entry)
                                                        :version-not-confirmed)))
                                             tried)))
                   (when unconfirmed
                     (log-warn "backend AUTOCAD: ~A is registered to ~A, which ~
does not name AutoCAD ~A; using it anyway (set $AUTOCAD_PROGID to pin another)"
                               progid (third unconfirmed) release)))
                 progid)
                ;; Nothing found -- but WHY? An unreadable registry is not
                ;; an absent registration, and answering as if it were is
                ;; how a working AutoCAD 2022 was refused on the Windows
                ;; runner (alfe-autocad-progid-registry-probe-fails).
                ((not (funcall *registry-probe-usable-function*))
                 (let ((unverified (%release-table-progid release)))
                   (cond
                     (unverified
                      (log-warn "backend AUTOCAD: cannot read the registry; ~
using ~A for AutoCAD ~A unverified (set $AUTOCAD_PROGID to pin one)"
                                unverified release)
                      unverified)
                     (explicit-p
                      (error 'backend-not-available
                             :backend :autocad
                             :code :autocad-progid-unavailable
                             :message (%progid-diagnostic release tried :unreadable-p t)
                             :details (list :release release :tried tried
                                            :registry :unreadable)))
                     (t *generic-autocad-progid*))))
                (explicit-p
                 (error 'backend-not-available
                        :backend :autocad
                        :code :autocad-progid-unavailable
                        :message (%progid-diagnostic release tried)
                        :details (list :release release :tried tried)))
                (t
                 (log-warn "backend AUTOCAD: no COM registration for AutoCAD ~A; ~
using ~A (set $AUTOCAD_PROGID to pin one)"
                           release *generic-autocad-progid*)
                 *generic-autocad-progid*))))))))))

;;; --- the AutoCAD instances this host created ----------------------

(defparameter *created-cad-registry-name* "alfe-created-cad.txt"
  "File, in the system temp directory, where each run writes down the
AutoCAD it created: PID and creation time, one per line.")

(defun created-cad-registry-path ()
  "Where to record the AutoCAD instances alfe creates on this host.

NOT in the workdir: the workdir dies with the run, and the case this
serves is the run that never gets to clean anything up -- killed, or its
CI job cancelled (autocad-orphaned-by-killed-or-cancelled-jobs.issue).
The next job reads this file and can end what the last one left."
  (merge-pathnames *created-cad-registry-name* (uiop:temporary-directory)))

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
' ${COMMODE}, ${DEBUGFILE}, ${WAIT_SECS}, ${PROGID}.
' Mirrors the legacy bash wrapper's bridge-autocad.vbs; preserve
' the WaitQuiescent + GetAcadState handshake - it's the hard-won
' piece that keeps the bridge from racing AutoCAD's UI init.

Option Explicit
Dim fso, app, doc, runFile, statusFile, errFile, commode, debugFile, waitSecs
Dim attached, created, rc, statusReadyFlag, flagsFile, progId, createdFile
Dim errNumber, errDescription

Set fso = CreateObject(\"Scripting.FileSystemObject\")
runFile     = \"${RUNLSPFILE}\"
statusFile  = \"${STATUSFILE}\"
errFile     = \"${ERRFILE}\"
commode     = \"${COMMODE}\"
debugFile   = \"${DEBUGFILE}\"
flagsFile   = \"${FLAGSFILE}\"
' Where this run writes down the AutoCAD it creates, so a later job can
' clean up after a run that never reached shutdown.
createdFile = \"${CREATEDFILE}\"
' The COM server to ask for. A VERSIONED ProgID when a release was
' selected: the generic one is registered to whichever AutoCAD claimed
' it last (alfe-autocad-cad-selection-ignores-com-progid).
progId      = \"${PROGID}\"
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

' What a failed activation actually was. Err.Number and Err.Description
' are cleared by the next statement, so the caller captures them into
' errNumber/errDescription FIRST and passes them in here. Without these
' lines the run reported only cscript's \"ATTACHED=0 CREATED=0\" and the
' COM error -- 429, the whole diagnosis -- was lost.
' Write down the AutoCAD this run CREATED, so a later job can clean it
' up if this one never reaches shutdown -- killed, or its CI job
' cancelled (autocad-orphaned-by-killed-or-cancelled-jobs.issue).
'
' A PID ALONE IS NOT AN IDENTITY: Windows reuses them. The creation time
' is recorded with it, and the sweep kills only a process whose PID AND
' creation time both still match -- so it can never kill an AutoCAD this
' run did not start, which is the whole worry about sweeping someone's
' own machine.
'
' The acad.exe that COM starts is a child of the COM service, not of
' cscript, so there is no process tree to walk: WMI is how it is found.
Sub RecordCreatedProcesses(path)
  Dim wmi, processes, proc
  If path = \"\" Then Exit Sub
  On Error Resume Next
  Set wmi = GetObject(\"winmgmts:\\\\.\\root\\cimv2\")
  If Err.Number <> 0 Then
    VBSDebug \"WMI unavailable; created AutoCAD not recorded: \" & Err.Description
    Err.Clear
    Exit Sub
  End If
  Set processes = wmi.ExecQuery( _
    \"SELECT ProcessId, CreationDate, CommandLine FROM Win32_Process WHERE Name = 'acad.exe'\")
  For Each proc In processes
    If InStr(1, proc.CommandLine & \"\", \"/Automation\", 1) > 0 Then
      AppendLine path, \"PID=\" & proc.ProcessId & \" CREATED=\" & proc.CreationDate
      VBSDebug \"recorded created acad.exe pid \" & proc.ProcessId
    End If
  Next
  Err.Clear
  On Error GoTo 0
End Sub

Sub RecordComError(stage, num, desc)
  AppendLine errFile, \"COM.PROGID=\" & progId
  AppendLine errFile, \"COM.STAGE=\" & stage
  AppendLine errFile, \"COM.ERROR.DECIMAL=\" & num
  AppendLine errFile, \"COM.ERROR.HEX=0x\" & Hex(num)
  AppendLine errFile, \"COM.ERROR.DESCRIPTION=\" & desc
End Sub

Sub EmitFlags(att, cre)
  Dim a, c
  If att Then a = \"1\" Else a = \"0\"
  If cre Then c = \"1\" Else c = \"0\"
  WScript.StdOut.WriteLine \"ATTACHED=\" & a
  WScript.StdOut.WriteLine \"CREATED=\"  & c
  ' ... and to a FILE, because stdout is not where alfe can read them.
  ' cscript is short-lived and its pipe is drained on exit, but the
  ' answer is needed LATER, at shutdown, to decide whether this run
  ' owns the AutoCAD it is about to quit. A file in the workdir
  ' outlives the process and needs no stream timing.
  If flagsFile <> \"\" Then
    AppendLine flagsFile, \"ATTACHED=\" & a
    AppendLine flagsFile, \"CREATED=\" & c
  End If
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

errNumber = 0
errDescription = \"\"
lastTouchError = \"\"

' RPC_E_CALL_REJECTED (&H80010001, \"L'appel a ete rejete par l'appele\")
' and RPC_E_SERVERCALL_RETRYLATER (&H8001010A) do not mean the server is
' broken: they mean it is BUSY -- a modal dialog, a load in progress, a
' command mid-flight. A native client installs an IMessageFilter and the
' COM runtime retries for it; a script must retry by hand. Failing on the
' first rejection made a transiently busy AutoCAD indistinguishable from
' a wedged one, and said neither. See
' alfe-autocad-hung-instance-blocks-com-bootstrap.
Function TouchApp(theApp, tries)
  Dim i
  TouchApp = False
  For i = 1 To tries
    On Error Resume Next
    theApp.Visible = True
    If Err.Number = 0 Then
      On Error GoTo 0
      TouchApp = True
      Exit Function
    End If
    lastTouchError = Err.Number & \" \" & Err.Description
    VBSDebug \"app busy on attempt \" & i & \" of \" & tries & \": \" & lastTouchError
    Err.Clear
    On Error GoTo 0
    WScript.Sleep 1000
  Next
End Function

If commode = \"attach\" Or commode = \"auto\" Then
  On Error Resume Next
  Set app = GetObject(, progId)
  errNumber = Err.Number
  errDescription = Err.Description
  If errNumber = 0 And Not (app Is Nothing) Then attached = True
  Err.Clear
  On Error GoTo 0
  ' Under \"auto\" a miss is ordinary -- no AutoCAD is running yet -- so it
  ' goes to the debug trace, not to the error file the user reads.
  If Not attached Then
    VBSDebug \"GetObject(\" & progId & \") failed: \" & errNumber & \" \" & errDescription
  End If
End If

If app Is Nothing Then
  If commode = \"attach\" Then
    AppendLine errFile, \"ERROR COM bridge: no running \" & progId & \" to attach to.\"
    RecordComError \"getobject\", errNumber, errDescription
    EmitFlags False, False
    WScript.Quit 4
  End If
  On Error Resume Next
  Set app = CreateObject(progId)
  errNumber = Err.Number
  errDescription = Err.Description
  If errNumber <> 0 Then
    AppendLine errFile, \"ERROR COM bridge: could not launch \" & progId & \": \" & errDescription
    RecordComError \"createobject\", errNumber, errDescription
    EmitFlags False, False
    WScript.Quit 4
  End If
  Err.Clear
  On Error GoTo 0
  created = True
  RecordCreatedProcesses createdFile
End If

If Not TouchApp(app, 10) Then
  AppendLine errFile, \"ERROR COM bridge: \" & progId & \" rejected the first call \" & _
    \"on 10 attempts, one second apart (\" & lastTouchError & \"). Another instance \" & _
    \"is probably wedged and holding the registration: end it on the machine.\"
  RecordComError \"touch\", 0, lastTouchError
  EmitFlags attached, created
  WScript.Quit 4
End If
EmitFlags attached, created

${PLUGIN_AFTER_APP}
WaitQuiescent app, waitSecs

If app.Documents.Count = 0 Then
  Call app.Documents.Add(\"\")
End If
Set doc = app.ActiveDocument

${PLUGIN_BEFORE_LOAD}
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

(defparameter *quit-autocad-vbs-template*
  "' Quit the AutoCAD this alfe run CREATED. Never called for an
' instance the bridge merely ATTACHED to: that one was already running
' — it may be a person's session on the same laptop — and closing it
' would be alfe reaching outside its own work.
' ${PROGID} is the SAME server the start bridge asked for: quitting
' \"AutoCAD.Application\" could close a different release than the one
' this run created (alfe-autocad-cad-selection-ignores-com-progid).
Option Explicit
Dim app, doc, i, progId
progId = \"${PROGID}\"
On Error Resume Next
Set app = GetObject(, progId)
If Err.Number <> 0 Then WScript.Quit 0
If app Is Nothing Then WScript.Quit 0
Err.Clear

' Close every document WITHOUT saving, downwards because closing
' shortens the collection. Not app.Quit on its own: the document this
' bridge added is UNNAMED (Dessin1/Drawing1), so a quit with unsaved
' changes raises the Save-changes dialog — and a modal dialog on an
' unattended runner is the very hang this is meant to end.
For i = app.Documents.Count - 1 To 0 Step -1
  Set doc = app.Documents.Item(i)
  If Err.Number = 0 Then
    doc.Close False
  End If
  Err.Clear
Next

app.Quit
Err.Clear
WScript.Quit 0
"
  "VBScript that attaches to the running AutoCAD and quits it.")

(defun emit-quit-vbs (path &key progid)
  "Write the quit bridge to PATH and return it. PROGID is the server the
start bridge used, so the instance quit is the instance created."
  (with-open-file (out path :direction :output
                            :if-exists :supersede
                            :if-does-not-exist :create
                            :external-format :utf-8)
    (write-string (substitute-placeholders
                   *quit-autocad-vbs-template*
                   `(("PROGID" . ,(or progid *generic-autocad-progid*))))
                  out))
  path)

(defun read-com-flags (workdir)
  "Return (values ATTACHED-P CREATED-P) from the bridge's flags file.

Both NIL when the file is missing or unreadable — which is the SAFE
default: alfe quits only what it can SHOW it created, so a bridge that
died before reporting leaves AutoCAD alone."
  (let ((path (merge-pathnames "com-flags.txt" workdir))
        (attached nil)
        (created nil))
    (when (probe-file path)
      (ignore-errors
       (with-open-file (in path :direction :input :external-format :utf-8)
         (loop for line = (read-line in nil nil)
               while line
               do (let ((trimmed (string-trim '(#\Space #\Tab #\Return) line)))
                    (cond ((string= trimmed "ATTACHED=1") (setf attached t))
                          ((string= trimmed "CREATED=1")  (setf created t))))))))
    (values attached created)))

(defun emit-bridge-vbs (path
                        &key runtime-load-path
                             status-path
                             error-path
                             debug-path
                             flags-path
                             progid
                             (created-registry (created-cad-registry-path))
                             (com-mode "auto")
                             (wait-secs 60))
  (let ((text (alfe.plugin:run-hook
               :launcher-script
               ;; The plug-in slots are filled AFTER the placeholders: their
               ;; lines are VBScript already and must not be quote-doubled.
               (expand-plugin-slots
                (substitute-placeholders
                 *bridge-autocad-vbs-template*
                 `(("RUNLSPFILE"  . ,(namestring runtime-load-path))
                   ("STATUSFILE"  . ,(namestring status-path))
                   ("ERRFILE"     . ,(namestring error-path))
                   ("COMMODE"     . ,com-mode)
                   ("DEBUGFILE"   . ,(if debug-path (namestring debug-path) ""))
                   ("FLAGSFILE"   . ,(if flags-path (namestring flags-path) ""))
                   ("PROGID"      . ,(or progid *generic-autocad-progid*))
                   ("CREATEDFILE" . ,(if created-registry
                                         (uiop:native-namestring created-registry)
                                         ""))
                   ("WAIT_SECS"   . ,(format nil "~D" wait-secs))))
                :automation)
               :kind :vbs :variant :automation :path path)))
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
  (let ((text (alfe.plugin:run-hook
               :launcher-script
               (with-output-to-string (out)
                 ;; Plug-in lines (hook :launcher-lines), as in the BricsCAD
                 ;; run.scr: before the load, and after it (the load only
                 ;; returns when the session ends).
                 (dolist (line (launcher-lines :before-load :scr :batch))
                   (write-line line out))
                 (format out "(load ~S)~%"
                         (namestring (truename runtime-load-path)))
                 (dolist (line (launcher-lines :after-load :scr :batch))
                   (write-line line out))
                 (format out "._QSAVE~%")
                 (format out "._QUIT _Y~%"))
               :kind :scr :variant :batch :path path)))
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
                            (discover-autocad-template backend
                                                       :requested dwg
                                                       :workdir workdir))))
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

(defun %com-field (text name)
  "The value of a NAME=… line in TEXT (the bridge's error file), or NIL."
  (when text
    (with-input-from-string (in text)
      (loop with prefix = (concatenate 'string name "=")
            for line = (read-line in nil nil)
            while line
            for trimmed = (string-trim '(#\Return #\Space #\Tab) line)
            when (and (>= (length trimmed) (length prefix))
                      (string= prefix trimmed :end2 (length prefix)))
              do (let ((value (subseq trimmed (length prefix))))
                   (when (plusp (length value))
                     (return value)))))))

(defun summarize-process-exit (details)
  "The bootstrap message for a launch that ended before READY.

In automation mode the process that exits is CSCRIPT, the COM bridge --
not acad.exe, which COM starts on its own. Saying `AutoCAD process
exited' there claimed something unobserved, and the message carried only
cscript's `ATTACHED=0 CREATED=0' stdout while the COM error that
explains it went unread (alfe-autocad-cad-selection-ignores-com-progid).
The ProgID, the stage and Err.Number/Description are reported when the
bridge recorded them."
  (let* ((exit-code (getf details :exit-code))
         (automation-p (eq (getf details :variant) :automation))
         (bridge (getf details :bridge-errors))
         (progid (%com-field bridge "COM.PROGID"))
         (stage (%com-field bridge "COM.STAGE"))
         (number (%com-field bridge "COM.ERROR.DECIMAL"))
         (hex (%com-field bridge "COM.ERROR.HEX"))
         (description (%com-field bridge "COM.ERROR.DESCRIPTION"))
         (stderr (string-trim '(#\Return #\Newline #\Space #\Tab)
                              (or (getf details :stderr) "")))
         (stdout (string-trim '(#\Return #\Newline #\Space #\Tab)
                              (or (getf details :stdout) "")))
         (snippet (cond ((plusp (length stderr)) stderr)
                        ((plusp (length stdout)) stdout)
                        (t ""))))
    (with-output-to-string (out)
      (format out "~A exited before READY (exit ~A)"
              (if automation-p "AutoCAD COM bridge (cscript)" "AutoCAD process")
              exit-code)
      (when stage
        (format out " at ~A(~@[~A~])" stage progid))
      (cond
        ((or number description)
         (format out ": COM error~@[ ~A~]~@[ (~A)~]~@[ ~A~]"
                 number hex description))
        ((plusp (length snippet))
         (format out ": ~A" snippet))
        (t (write-char #\. out)))
      (when (and automation-p (or number description))
        (format out "~%  The COM bridge is what exited; whether acad.exe ~
started is what ATTACHED/CREATED say.")
        (when progid
          (format out "~%  Server asked for: ~A (override with $AUTOCAD_PROGID)."
                  progid))))))

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
  (variant          nil)
  ;; The COM server this run asked for, kept so SHUTDOWN quits the same
  ;; one (alfe-autocad-cad-selection-ignores-com-progid).
  (progid           nil))

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
      (let* (;; Both assets, or a BACKEND-BOOTSTRAP-ERROR naming what is
             ;; missing and where it was looked for -- before the engine
             ;; is launched (alfe-installed-runtime-prefix-discovery).
             (assets (multiple-value-list (require-runtime-assets :autocad)))
             (runtime-source (first assets))
             (bootstrap-source (second assets))
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
             (variant (choose-effective-mode backend mode))
             ;; Filled by the :AUTOMATION branch below; the session keeps
             ;; it so SHUTDOWN quits the server this run started.
             (progid nil)
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
                :backend-name "AUTOCAD"
                :variant variant)))
        ;; G2: how the drain decodes AutoCAD's console output. accoreconsole
        ;; (batch) is UTF-16LE, product-fixed (conflicting -Econsole warned +
        ;; ignored); the GUI path honours the user's request, else :AUTO.
        (setf (alfe.protocol.file:protocol-session-console-encoding protocol)
              (%autocad-console-decode-encoding cli-options variant))
        (log-debug "backend AUTOCAD: bootstrap LSP source = ~A" bootstrap-source)
        (log-debug "backend AUTOCAD: runtime LSP source = ~A" runtime-source)
        (cond
          (staged-bootstrap
           (log-debug "backend AUTOCAD: staged bootstrap -> ~A" staged-bootstrap))
          (bootstrap-source
           (log-warn "backend AUTOCAD: bootstrap source ~A resolved but staging returned NIL"
                     bootstrap-source))
          (t
           (log-warn "backend AUTOCAD: bootstrap LSP not staged")))
        (cond
          (staged-runtime
           (log-debug "backend AUTOCAD: staged runtime -> ~A" staged-runtime))
          (runtime-source
           (log-warn "backend AUTOCAD: runtime source ~A resolved but staging returned NIL"
                     runtime-source))
          (t
           (log-warn "backend AUTOCAD: runtime LSP not staged")))
        (log-debug "backend AUTOCAD: emitted run-common.lsp -> ~A" run-common)
        (log-verbose "backend AUTOCAD: effective mode = ~A" variant)
        (case variant
          (:automation
           (let ((vbs (merge-pathnames "bridge-autocad.vbs" workdir)))
             (let ((named (release-named-by-denotation
                           (and cli-options (alfe.cli:cli-options-cad cli-options)))))
               (setf progid
                     (resolve-autocad-progid
                      :release named
                      :executable-path (autocad-backend-executable-path backend)
                      ;; Only `--cad autocad-2022' is a claim about WHICH
                      ;; AutoCAD, and only such a claim may fail rather
                      ;; than be met by another release. `--cad autocad'
                      ;; asks for the latest one and must still run
                      ;; (alfe-autocad-progid-registry-probe-fails).
                      :explicit-p (and named t))))
             (log-verbose "backend AUTOCAD: COM server = ~A" progid)
             (emit-bridge-vbs
              vbs
              :runtime-load-path run-common
              :status-path (alfe.protocol.file:protocol-session-status-path protocol)
              :error-path  (alfe.protocol.file:protocol-session-stderr-path protocol)
              :flags-path  (merge-pathnames "com-flags.txt" workdir)
              :progid      progid
              :com-mode    (or (uiop:getenv "AUTOCAD_COM_MODE") "auto"))
             (log-debug "backend AUTOCAD: wrote bridge-autocad.vbs -> ~A" vbs)))
          (:batch
           (let ((scr (merge-pathnames "run.scr" workdir)))
             (emit-batch-scr scr run-common)
             (log-debug "backend AUTOCAD: wrote run.scr -> ~A" scr))))
        (let* ((argv (alfe.plugin:run-hook
                      :launch-argv
                      (build-launch-argv backend protocol :mode mode :dwg dwg)
                      :variant variant :workdir workdir))
               (launch-options (alfe.plugin:run-hook
                                :launch-options
                                (list :directory nil :environment nil)
                                :variant variant :argv argv :workdir workdir))
               (session (%make-autocad-session
                         :backend backend
                         :workdir workdir
                         :request-timeout (and cli-options
                                               (alfe.cli:cli-options-timeout
                                                cli-options))
                         :protocol-session protocol
                         :variant variant
                         :progid progid))
               (_ (log-verbose "backend AUTOCAD: launching: ~{~A~^ ~}" argv))
               (process-info
                 (when launcher
                   (call-launcher launcher argv launch-options
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
                 ;; The COM failure is in the bridge's error FILE, not in
                 ;; cscript's pipes: read it before reporting, or the
                 ;; diagnosis is lost (see SUMMARIZE-PROCESS-EXIT).
                 (let ((details (append
                                 (list :variant (and session
                                                     (autocad-session-variant session))
                                       :bridge-errors
                                       (ignore-errors
                                        (uiop:read-file-string
                                         (alfe.protocol.file:protocol-session-stderr-path
                                          protocol))))
                                 details)))
                   (error 'backend-bootstrap-error
                          :backend :autocad
                          :code :process-exited-before-ready
                          :message (summarize-process-exit details)
                          :details (append
                                    (list :workdir workdir
                                          :last-status last)
                                    details))))
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

(defun quit-created-autocad (session &key (timeout 20)
                                          (launcher #'uiop:launch-program))
  "Quit the AutoCAD this session CREATED, if it created one.

WHY THIS EXISTS. In automation mode alfe does not run AutoCAD: it runs
CSCRIPT, which asks Windows' COM service for an AutoCAD.Application.
The acad.exe that answers is a child of that service, not of cscript,
alfe, or the CI job — so KILL-ENGINE-PROCESS, which kills the process
alfe launched, has never been able to reach it, and neither can a
process-tree kill from the job. The bridge ends with `Don't call
app.Quit here - ... the alfe-side poller decides on the lifecycle';
this is the alfe side finally deciding. Until now nothing did, and
every automation run left AutoCAD idle on an unnamed Dessin1.dwg
(issues/open/alfe-autocad-automation-never-quits-acad.issue).

ONLY WHAT WE CREATED (pjb, 2026-09-16). The bridge attaches to a
running AutoCAD when there is one, and on this runner that may be a
person's own session. Quitting it would be alfe reaching outside its
own work, so the CREATED flag — which the bridge already reported, and
which nothing read — is what licenses the quit.

BOUNDED, like every other shutdown step here: the quit is itself a
cscript, so it gets the same treatment as the engine — poll, then
KILL-ENGINE-PROCESS. A CAD that hangs on a dialog while being asked to
quit must not hang alfe, or the cure becomes the disease."
  (let ((workdir (session-workdir session)))
    (when workdir
      (multiple-value-bind (attached created) (read-com-flags workdir)
        (declare (ignore attached))
        (cond
          ((not created)
           (log-debug "backend AUTOCAD: not quitting AutoCAD (this run did ~
not create it)")
           nil)
          (t
           (log-verbose "backend AUTOCAD: quitting the AutoCAD this run created")
           (ignore-errors
            (let* ((vbs (emit-quit-vbs (merge-pathnames "quit-autocad.vbs"
                                                        workdir)
                                       :progid (autocad-session-progid session)))
                   (info (funcall launcher
                                  (list "cscript" "//nologo" (namestring vbs))
                                  :output :stream :error-output :stream))
                   (start (get-internal-real-time)))
              (loop while (and (uiop:process-alive-p info)
                               (< (/ (float (- (get-internal-real-time) start))
                                     internal-time-units-per-second)
                                  timeout))
                    do (sleep 0.2))
              (kill-engine-process info)
              (log-debug "backend AUTOCAD: quit bridge finished")))
           t))))))

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
      ;;
      ;; The AutoCAD itself is quit FIRST, and only when this run created
      ;; it: in automation mode the process killed below is cscript, and
      ;; acad.exe is a child of Windows' COM service that no kill here can
      ;; reach. Order matters only in that the quit needs COM alive; the
      ;; kill below is unaffected either way.
      (when (eq (autocad-session-variant session) :automation)
        (ignore-errors (quit-created-autocad session)))
      (kill-engine-process info))
    (session-state-set session :stopped))
  session)

(defmethod cleanup-workdir ((backend autocad-backend) workdir &key keep-p)
  (when workdir
    (remove-workdir workdir :keep-p keep-p))
  nil)

;;; --- registration -------------------------------------------------

(register-backend :autocad (make-autocad-backend))
