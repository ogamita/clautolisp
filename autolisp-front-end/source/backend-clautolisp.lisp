;;;; autolisp-front-end/source/backend-clautolisp.lisp
;;;;
;;;; The clautolisp backend — Phase 1 of the alfe rollout. Specified
;;;; by ../issues/open/alfe-backend-clautolisp.issue (section
;;;; "Backend clautolisp" in the alfe specification).
;;;;
;;;; clautolisp is itself a Common Lisp process, so alfe can either:
;;;;
;;;;   - *be* that process — bind the evaluator in-process via the
;;;;     clautolisp.autolisp-runtime APIs (the :direct variant; the
;;;;     default for --clautolisp);
;;;;   - *spawn* it — fork `clautolisp-sbcl` via uiop:launch-program
;;;;     and pipe action lines down its stdin (the :subprocess
;;;;     variant, opted into with `--backend subprocess`).
;;;;
;;;; Both paths skip the file-IPC protocol; that protocol exists only
;;;; because BricsCAD/AutoCAD have no alternative.
;;;;
;;;; Output mirroring:
;;;;   The direct variant tees *standard-output* / *error-output* into
;;;;   the live terminal streams AND into `WORKDIR/output.txt` and
;;;;   `WORKDIR/errors.txt`. The subprocess variant captures its
;;;;   child's stdout/stderr into the same files. This preserves
;;;;   diagnostic symmetry with the CAD backends documented in the
;;;;   spec.

(defpackage #:alfe.backend.clautolisp
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
                #:action-kind
                #:action-payload
                #:make-eval-result
                #:register-backend)
  (:import-from #:alfe.error
                #:backend-not-available
                #:backend-bootstrap-error
                #:backend-protocol-error
                #:backend-eval-error)
  (:import-from #:alfe.workdir
                #:make-fresh-workdir
                #:ensure-subdir
                #:remove-workdir)
  (:import-from #:clautolisp.autolisp-reader
                #:autolisp-dialect-strict
                #:autolisp-dialect-autocad-2026
                #:autolisp-dialect-bricscad-v26
                #:find-autolisp-dialect
                #:diagnostic
                #:diagnostic-code)
  (:import-from #:clautolisp.autolisp-runtime
                #:make-default-runtime-context
                #:autolisp-load-file-in-context
                #:autolisp-eval-progn
                #:autolisp-runtime-error
                #:autolisp-runtime-error-code
                #:autolisp-runtime-error-message
                #:autolisp-termination
                #:autolisp-termination-kind
                #:call-with-autolisp-error-handler
                #:derive-reader-options-for-dialect
                #:read-runtime-from-string
                #:set-runtime-session-host
                #:evaluation-context-session
                #:lookup-function
                #:intern-autolisp-symbol)
  (:import-from #:clautolisp.autolisp-builtins-core
                #:install-core-builtins
                #:autolisp-value->string)
  (:import-from #:clautolisp.autolisp-host
                #:nihil
                #:*nihil*)
  (:import-from #:clautolisp.cador
                #:make-cador)
  (:import-from #:alfe.logging
                #:log-debug
                #:log-verbose)
  (:export #:clautolisp-backend
           #:make-clautolisp-backend
           #:clautolisp-backend-variant
           #:clautolisp-direct-session
           #:clautolisp-subprocess-session
           #:resolve-clautolisp-dialect
           #:resolve-clautolisp-host))

(in-package #:alfe.backend.clautolisp)

;;; --- dialect / host resolution --------------------------------------

(defun resolve-clautolisp-dialect (dialect-keyword)
  "Map an alfe dialect keyword (any --dialect name; see --list-dialects)
to a clautolisp.autolisp-reader dialect descriptor, delegating to the
reader's single-source-of-truth registry. NIL means the strict default.
Unlike before, :clautolisp resolves to the real clautolisp dialect (not
strict) so `--clautolisp --dialect clautolisp` enables clautolisp
extensions; the strict DEFAULT for the --clautolisp backend is supplied
upstream by EFFECTIVE-DIALECT, not by collapsing the keyword here."
  (or (find-autolisp-dialect (or dialect-keyword :strict))
      (error 'backend-bootstrap-error
             :backend :clautolisp
             :code :unknown-dialect
             :message (format nil "Unknown clautolisp dialect ~S"
                              dialect-keyword)
             :details (list :dialect dialect-keyword))))

(defun resolve-clautolisp-host (host-keyword)
  "Map an alfe host keyword (:cador or :nihil) to the HAL backend instance
the embedded clautolisp runtime expects. Defaults to a fresh cador (the
headless CAD core) when unspecified — same default as the standalone
clautolisp executable. :cadtui is not served here: its UI-tree layer is
installed by the clautolisp executable, so alfe runs it as the subprocess
variant (ALFE.CLI:RESOLVE-BACKEND arranges that). Honoured for the
--clautolisp backend only; under --autocad / --bricscad the real CAD is the
host and --host is ignored."
  (case host-keyword
    ((nil :cador) (make-cador))
    (:nihil       *nihil*)
    (:cadtui
     (error 'backend-bootstrap-error
            :backend :clautolisp
            :code :host-needs-subprocess
            :message "The in-process engine has no cadtui host; cadtui runs in the clautolisp executable (--backend subprocess)."
            :details (list :host host-keyword)))
    (otherwise
     (error 'backend-bootstrap-error
            :backend :clautolisp
            :code :unknown-host
            :message (format nil "Unknown clautolisp HAL backend ~S"
                             host-keyword)
            :details (list :host host-keyword)))))

;;; --- the backend class ---------------------------------------------

(defclass clautolisp-backend (backend)
  ((variant
    :initarg :variant
    :reader clautolisp-backend-variant
    :initform :direct
    :type (member :direct :subprocess)
    :documentation
    "Which engine variant START-ENGINE materialises. Default :direct
binds the evaluator in-process; :subprocess spawns clautolisp-sbcl
under uiop:launch-program. The CLI flips this via --backend
{subprocess,direct,in-process}.")
   (executable-path
    :initarg :executable-path
    :accessor clautolisp-backend-executable-path
    :initform nil
    :documentation
    "Absolute path to the clautolisp-sbcl binary used by the
:subprocess variant. NIL means 'discover at start-engine time' —
DETECT fills it in from CANDIDATE-CLAUTOLISP-BINARIES:
$ALFE_CLAUTOLISP_BIN, the engine installed beside the running alfe,
the build checkout (when it still exists), $PATH, /usr/local/bin."))
  (:default-initargs
   :name :clautolisp
   :display-name "clautolisp (in-process)"))

(defun make-clautolisp-backend (&key (variant :direct) executable-path)
  (make-instance 'clautolisp-backend
                 :variant variant
                 :executable-path executable-path
                 :display-name (ecase variant
                                 (:direct "clautolisp (in-process)")
                                 (:subprocess "clautolisp (subprocess)"))))

;;; --- DETECT ---------------------------------------------------------

;;; Stamp the source-tree-relative path at *read* time so the saved
;;; image still knows where clautolisp's sibling binary lives.
;;;
;;; Why #. and not a plain DEFPARAMETER expression? DEFPARAMETER
;;; re-evaluates its init-form at load-time; under ASDF the load
;;; happens against the cached fasl, where *load-truename* is the
;;; fasl path — so the relative walk lands in $XDG_CACHE_HOME and
;;; never finds the binary. #. (read-time eval) runs the form once,
;;; during COMPILE-FILE, when *compile-file-truename* IS the source,
;;; and embeds the resulting string as a literal in the fasl. The
;;; saved image then sees that literal regardless of load-time state.

(defparameter *checkout-sibling-clautolisp*
  #.(let ((self (or *compile-file-truename* *load-truename*)))
      (and self
           (let* ((source-dir (make-pathname
                               :name nil :type nil :version nil
                               :defaults self))
                  (sibling (merge-pathnames
                            #P"../../clautolisp/tools/clautolisp/bin/clautolisp-sbcl"
                            source-dir)))
             (namestring sibling))))
  "Best-guess absolute path of the clautolisp-sbcl binary inside this
checkout, captured at compile-read time so it survives
save-lisp-and-die. Falls back to NIL when the source isn't co-located
with the clautolisp subproject (e.g. an installed binary).")

(defun %path-separator (os)
  "The $PATH list separator on OS: `;' on MS-Windows, where `:' is part
of every drive-letter directory, `:' everywhere else."
  (if (eq os :windows) #\; #\:))

(defun walk-path-for (binary-name &key (path (uiop:getenv "PATH"))
                                       (os (alfe.backend.cad-common:host-os)))
  "Walk PATH (default $PATH) for BINARY-NAME and return the first
absolute path that exists, or NIL. uiop's portable helpers don't expose
a PATH walker on every supported Lisp; doing it inline keeps the
dependency surface narrow."
  (when (and path (plusp (length path)))
    (dolist (dir (uiop:split-string path :separator (list (%path-separator os))))
      (when (plusp (length dir))
        (let ((candidate (merge-pathnames binary-name
                                          (uiop:ensure-directory-pathname dir))))
          (when (probe-file candidate)
            (return-from walk-path-for (namestring candidate))))))))

;;; --- the installed engine ------------------------------------------
;;;
;;; alfe-installed-subprocess-binary-not-discovered: a release installs
;;;
;;;   PREFIX/bin/alfe, PREFIX/bin/clautolisp          (dispatchers)
;;;   PREFIX/libexec/clautolisp/binaries/OS/CPU/alfe-sbcl[.exe]
;;;   PREFIX/libexec/clautolisp/binaries/OS/CPU/clautolisp-sbcl[.exe]
;;;
;;; and the dispatcher EXECs the image, which therefore runs from that
;;; libexec directory. The engine shipped with this alfe is found from
;;; where the running executable itself lives -- never from the current
;;; directory, and never from the build tree the image was dumped in.

(defun distribution-os-name (os)
  "The OS directory name of the release layout for the HOST-OS keyword
OS. The SAME mapping as clautolisp/tools/packaging/dispatch.sh and
dispatch.cmd, the top Makefile's REL_OS and drawing-dwg's %OS: linux,
darwin, windows. NIL for an unknown OS."
  (case os
    (:linux   "linux")
    (:macos   "darwin")
    (:windows "windows")
    (otherwise nil)))

(defun distribution-arch-name (&optional (machine (machine-type)))
  "The CPU directory name of the release layout for MACHINE (default:
this Lisp's MACHINE-TYPE). The SAME mapping as dispatch.sh (uname -m:
x86_64/amd64 -> x86-64, aarch64 -> arm64, lower case otherwise),
dispatch.cmd (AMD64 -> x86-64, ARM64 -> arm64), the top Makefile's
REL_ARCH and drawing-dwg's %ARCH."
  (let ((m (string-downcase (string machine))))
    (cond ((member m '("x86-64" "x86_64" "amd64" "x8664") :test #'string=) "x86-64")
          ((member m '("arm64" "aarch64") :test #'string=) "arm64")
          (t m))))

(defun clautolisp-binary-name (os)
  "The file name of the standalone engine on OS: clautolisp-sbcl, with
the .exe suffix only on MS-Windows, as dispatch.sh and dispatch.cmd
name it."
  (if (eq os :windows) "clautolisp-sbcl.exe" "clautolisp-sbcl"))

(defun %file-in (directory file-name)
  "Namestring of FILE-NAME (a string, possibly with a type) in the
directory pathname DIRECTORY."
  (namestring
   (merge-pathnames (make-pathname :name (pathname-name file-name)
                                   :type (pathname-type file-name)
                                   :defaults directory)
                    directory)))

(defun installed-clautolisp-binaries
    (&key (exe (funcall alfe.backend.cad-common:*executable-pathname-function*))
          (os (alfe.backend.cad-common:host-os))
          (machine (machine-type)))
  "The clautolisp-sbcl[.exe] the installation of the running alfe EXE
ships, most specific first, as namestrings (whether they exist or not):

  1. the sibling of EXE: the release puts alfe-sbcl and clautolisp-sbcl
     in the same libexec/clautolisp/binaries/OS/CPU/ directory (and the
     autolisp-front-end `make install' layout in the same bin/), so the
     OS and CPU are the ones the dispatcher already chose;
  2. PREFIX/libexec/clautolisp/binaries/OS/CPU/clautolisp-sbcl[.exe] for
     every PREFIX of INSTALLATION-PREFIXES, OS and CPU named as the
     dispatchers name them.

NIL when EXE is not an alfe executable (a development image running as
sbcl or ccl has no installation to speak of)."
  (when (alfe.backend.cad-common:alfe-executable-p exe)
    (let ((name (clautolisp-binary-name os))
          (os-name (distribution-os-name os))
          (arch-name (distribution-arch-name machine))
          (result '()))
      (push (%file-in (make-pathname :name nil :type nil :version nil
                                     :defaults exe)
                      name)
            result)
      (when os-name
        (dolist (prefix (alfe.backend.cad-common:installation-prefixes exe))
          (push (%file-in (merge-pathnames
                           (make-pathname
                            :directory (list :relative "libexec" "clautolisp"
                                             "binaries" os-name arch-name)
                            :name nil :type nil :version nil)
                           prefix)
                          name)
                result)))
      (remove-duplicates (nreverse result) :test #'equal :from-end t))))

(defun candidate-clautolisp-binaries
    (&key (env (uiop:getenv "ALFE_CLAUTOLISP_BIN"))
          (exe (funcall alfe.backend.cad-common:*executable-pathname-function*))
          (os (alfe.backend.cad-common:host-os))
          (machine (machine-type))
          (checkout *checkout-sibling-clautolisp*)
          (path (uiop:getenv "PATH")))
  "Where to look for clautolisp-sbcl, in priority order, as namestrings.
The first existing file wins. Used by DETECT for the :subprocess
variant, and listed by its NO-SUBPROCESS-BINARY diagnostic.

  1. $ALFE_CLAUTOLISP_BIN (ENV), when set and non-empty: an explicit
     instruction always wins;
  2. the engine installed with the running alfe (EXE), see
     INSTALLED-CLAUTOLISP-BINARIES;
  3. the checkout path captured when alfe was compiled (CHECKOUT), ONLY
     when that file exists: after packaging it names a build tree that
     is usually gone, and must neither shadow the installed engine nor
     clutter the diagnostic;
  4. clautolisp-sbcl[.exe] found on PATH (default $PATH);
  5. /usr/local/bin/clautolisp-sbcl (not on MS-Windows).

Every argument defaults to the live process's value; the tests inject
pretend ones."
  (let ((name (clautolisp-binary-name os)))
    (remove-duplicates
     (remove nil
             (append
              (list (when (and env (plusp (length env))) env))
              (installed-clautolisp-binaries :exe exe :os os :machine machine)
              (list (when (and checkout (probe-file checkout))
                      (namestring checkout))
                    (walk-path-for name :path path :os os)
                    (unless (eq os :windows)
                      "/usr/local/bin/clautolisp-sbcl"))))
     :test #'equal :from-end t)))

(defun no-subprocess-binary-message (candidates)
  "The NO-SUBPROCESS-BINARY diagnostic text: every candidate tried, in
order, and the remedy."
  (format nil "clautolisp-sbcl not found (looked in ~{~A~^, ~}, and on $PATH); ~
set $ALFE_CLAUTOLISP_BIN to the engine's pathname"
          candidates))

(defmethod detect ((backend clautolisp-backend) &key)
  ;; The :direct variant is always available — alfe is itself a
  ;; clautolisp host. For the :subprocess variant we probe for the
  ;; executable and remember its absolute path for START-ENGINE.
  (ecase (clautolisp-backend-variant backend)
    (:direct backend)
    (:subprocess
     (let* ((candidates (candidate-clautolisp-binaries))
            (found (dolist (candidate candidates nil)
                     (when (probe-file candidate)
                       (return (namestring (truename candidate)))))))
       (unless found
         (error 'backend-not-available
                :backend :clautolisp
                :code :no-subprocess-binary
                :message (no-subprocess-binary-message candidates)
                :details (list :candidates candidates)))
       (setf (clautolisp-backend-executable-path backend) found)
       backend))))

;;; --- PREPARE-WORKDIR ------------------------------------------------

(defmethod prepare-workdir ((backend clautolisp-backend) workdir-root &key)
  ;; If the CLI passed --workdir DIR we use DIR verbatim (the user
  ;; opted in); otherwise we mint a fresh alfe-clautolisp-<pid>-<rand>
  ;; under $TMPDIR. The clautolisp backend doesn't need any
  ;; subdirs beyond the root; the file-protocol backends create
  ;; protocol/ themselves.
  (let ((workdir (if workdir-root
                     (uiop:ensure-directory-pathname workdir-root)
                     (make-fresh-workdir :clautolisp))))
    (ensure-directories-exist workdir)
    workdir))

;;; --- TEE helper (direct variant) -----------------------------------
;;;
;;; A teeing stream mirrors writes to two destinations. The direct
;;; variant uses one to fan *standard-output* into both the live
;;; terminal and WORKDIR/output.txt — matching the spec's promise
;;; that every backend leaves the same set of artefacts behind.

(defclass tee-stream
    (trivial-gray-streams:fundamental-character-output-stream)
  ((destinations
    :initarg :destinations
    :reader tee-stream-destinations
    :documentation
    "List of underlying streams every write is fanned to. The order
is not observable from the outside."))
  (:documentation
   "Character output stream that writes to every member of
DESTINATIONS in order. Used in PHASE 1 to mirror the live stdout
into WORKDIR/output.txt and the live stderr into WORKDIR/errors.txt."))

(defmethod trivial-gray-streams:stream-write-char ((stream tee-stream) ch)
  (dolist (dest (tee-stream-destinations stream))
    (write-char ch dest))
  ch)

(defmethod trivial-gray-streams:stream-write-string
    ((stream tee-stream) string &optional (start 0) (end nil))
  (dolist (dest (tee-stream-destinations stream))
    (write-string string dest :start start :end (or end (length string))))
  string)

(defmethod trivial-gray-streams:stream-line-column ((stream tee-stream))
  ;; trivial-gray-streams requires this; we don't track columns.
  nil)

(defmethod trivial-gray-streams:stream-finish-output ((stream tee-stream))
  (dolist (dest (tee-stream-destinations stream))
    (finish-output dest)))

(defmethod trivial-gray-streams:stream-force-output ((stream tee-stream))
  (dolist (dest (tee-stream-destinations stream))
    (force-output dest)))

(defmethod close ((stream tee-stream) &key abort)
  ;; Close every owned destination. The caller is responsible for
  ;; deciding whether the live terminal streams belong to that set —
  ;; we just close what we were handed.
  (dolist (dest (tee-stream-destinations stream))
    (close dest :abort abort))
  t)

(defun make-tee-stream (&rest destinations)
  (make-instance 'tee-stream :destinations destinations))

;;; --- session subclasses --------------------------------------------

(defstruct (clautolisp-direct-session
            (:include session)
            (:constructor %make-direct-session)
            (:copier nil))
  "Direct-variant session: holds the live runtime context plus the
underlying files we mirror live stdout/stderr into."
  (context        nil)
  (host           nil)
  (output-file    nil)
  (errors-file    nil)
  ;; Captured output/error text when EVAL-PLAN is asked to operate
  ;; *without* a live terminal (e.g. from FiveAM tests). NIL when
  ;; the session writes straight to the inherited streams.
  (captured-stdout-stream nil)
  (captured-stderr-stream nil)
  (interrupt-requested-p nil))

(defstruct (clautolisp-subprocess-session
            (:include session)
            (:constructor %make-subprocess-session)
            (:copier nil))
  "Subprocess-variant session. The Phase 1 implementation fork-execs
clautolisp-sbcl once per EVAL-PLAN with the resolved CLI flags (one
flag per action); PROCESS-INFO is bound during that call and reset
to NIL on completion. HOST is the alfe host keyword (:cador/:cadtui/:nihil)
resolved at START-ENGINE time."
  (process-info nil)
  (host         nil)
  (output-file  nil)
  (errors-file  nil)
  ;; The `source' encoding (-Esource, or the bare -E), forwarded as the
  ;; subprocess argv's -Esource so the spawned engine reads source files in
  ;; the same encoding. NIL when none was requested.
  (load-encoding nil)
  ;; The other situations the spawned clautolisp honours itself, forwarded
  ;; as -Efile-read / -Efile-write / -Eterminal-in / -Eterminal-out / -Elog
  ;; (encoding-situations-cli-options, section 6 point 1). The console of a
  ;; clautolisp engine IS its terminal: an explicit -Econsole arrives here
  ;; already folded into the terminal pair (alfe.cli:situation-engine-keywords).
  (file-read-encoding nil)
  (file-write-encoding nil)
  (terminal-in-encoding nil)
  (terminal-out-encoding nil)
  (log-encoding nil)
  ;; The user's --dribble / --dribble-interactors request, forwarded to
  ;; the spawned engine, which records its OWN REPL (alfe-dribble.issue).
  ;; T = the engine's default timestamped file, a string = that file.
  (dribble nil)
  (dribble-interactors nil)
  ;; The drawing argument (--dwg / $AUTOLISP_DWG), forwarded as --dwg.
  (dwg nil))

;;; --- START-ENGINE: direct variant ----------------------------------

(defun open-output-file (workdir basename)
  "Open WORKDIR/BASENAME for append-from-empty writes, in UTF-8.
Returns the open stream. Callers are responsible for closing it on
SHUTDOWN."
  (open (merge-pathnames basename workdir)
        :direction :output
        :if-exists :supersede
        :if-does-not-exist :create
        :external-format :utf-8))

(defmethod start-engine ((backend clautolisp-backend) workdir
                         &key dialect host mock-input
                              bootstrap-phase interactive-p mode dwg
                              load-encoding io-encoding
                              source-encoding
                              file-read-encoding file-write-encoding
                              console-in-encoding console-out-encoding
                              cadstdio-in-encoding cadstdio-out-encoding
                              log-encoding
                              terminal-in-encoding terminal-out-encoding
                              cli-options version-text)
  ;; INTERACTIVE-P is forwarded to start-subprocess-engine below; the
  ;; direct branch doesn't use it (the REPL is opened by EVAL-PLAN
  ;; when the action plan carries an :interactive action). MOCK-INPUT
  ;; and BOOTSTRAP-PHASE are reserved for future tickets.
  ;;
  ;; SOURCE-ENCODING (else the legacy LOAD-ENCODING mirror) is the
  ;; `source' situation, -Esource or the bare -E (utf-8 / iso-8859-1 /
  ;; latin-1 / windows-1252 / cp1252). The direct variant installs it on
  ;; the runtime session so every load — including nested (load …) from a
  ;; user init file — uses it instead of the dialect default. The
  ;; subprocess variant forwards it as -Esource to the spawned
  ;; clautolisp-sbcl binary's CLI, together with the file / terminal / log
  ;; situations (-Efile-read, -Efile-write, -Eterminal-in, -Eterminal-out,
  ;; -Elog) so the child applies them itself. In the direct variant those
  ;; are applied elsewhere: file through the *AUTOLISP-FILE-READ/WRITE-
  ;; ENCODING* transmit variables (CLI-OPTIONS), terminal to alfe's own
  ;; streams (APPLY-TERMINAL-ENCODING, which folds -Econsole in for this
  ;; backend). CONSOLE-* is already folded into TERMINAL-* by the caller
  ;; (the engine's console is its terminal); CADSTDIO-* has no meaning
  ;; without a CAD subprocess.
  ;;
  ;; CLI-OPTIONS is the alfe-side cli-options struct; the direct
  ;; variant uses it to install the *AUTOLISP-…* globals in the
  ;; freshly created runtime context (transmit-options.issue). The
  ;; subprocess variant ignores it — the spawned clautolisp-sbcl
  ;; installs its own from argv.
  (declare (ignore mock-input bootstrap-phase mode
                   console-in-encoding console-out-encoding
                   cadstdio-in-encoding cadstdio-out-encoding))
  (setf load-encoding (or source-encoding load-encoding))
  (ecase (clautolisp-backend-variant backend)
    (:direct
     (handler-case
         (let* ((dialect-struct (resolve-clautolisp-dialect dialect))
                (host-instance  (resolve-clautolisp-host host))
                (context        (make-default-runtime-context
                                 :dialect dialect-struct))
                (session-handle (evaluation-context-session context)))
           ;; The drawing argument (--dwg / $AUTOLISP_DWG): the first drawing.
           (when dwg
             (clautolisp.autolisp-host:host-open-startup-drawing host-instance dwg))
           (set-runtime-session-host session-handle host-instance)
           (install-core-builtins)
           ;; Anchor the engine to the live process: cwd AND run frame.
           ;;
           ;; This used to be a COPY of the cwd half of the clautolisp
           ;; tool's startup — and only that half. The run-frame half was
           ;; left behind, so on a mingw-SBCL-under-MSYS2 host
           ;; *RUN-ENVIRONMENT* stayed the BUILD frame (native drive
           ;; style) and an MSYS2 path mapped to nothing: `clautolisp'
           ;; loaded /c/Users/... and `alfe --clautolisp' answered
           ;; LOAD-FILE-NOT-FOUND for the same path
           ;; (windows-msys-paths-in-autolisp-load-alfe.issue).
           ;;
           ;; Both halves now live in ONE runtime function that every
           ;; entry point calls, because the semantics of the embedded
           ;; engine must not depend on which front end started it.
           (clautolisp.autolisp-runtime:synchronize-process-environment)
           ;; Install the *AUTOLISP-…* globals derived from alfe's
           ;; CLI options. The in-process engine IS the clautolisp
           ;; runtime, so *AUTOLISP-BACKEND* = CLAUTOLISP. alfe is
           ;; the driving front-end, so *AUTOLISP-FRONTEND* = ALFE
           ;; (set by the wrapper's default). *AUTOLISP-HELP* gets
           ;; alfe's --help banner so user code can redisplay it.
           ;; Variables visible to user code as if clautolisp had
           ;; been invoked directly, plus alfe-specific slots like
           ;; *AUTOLISP-MODE* / *AUTOLISP-DRAWING* / etc.
           (when cli-options
             (clautolisp.autolisp-cli:install-transmit-variables
              context
              (alfe.cli:cli-options-transmit-bindings-for-alfe
               cli-options
               :backend "CLAUTOLISP"
               :usage-text (alfe.cli:usage-string)
               :version-text (or version-text "0.0.0"))))
           ;; Effective default source-file encoding precedence:
           ;;   -Esource or the bare -E (SOURCE-ENCODING / LOAD-ENCODING) > LC_ALL/LC_CTYPE/LANG > NIL.
           ;; NIL falls through to the dialect default at load time.
           (let ((effective
                   (or (and load-encoding (encoding-keyword load-encoding))
                       (clautolisp.autolisp-runtime:locale-default-source-encoding))))
             (when effective
               (clautolisp.autolisp-runtime:set-default-source-encoding
                context effective)))
           ;; --dribble under the IN-PROCESS engine (alfe-dribble.issue).
           (when cli-options
             (%warn-direct-dribble-unavailable cli-options))
           (let ((session (%make-direct-session
                           :backend backend
                           :workdir workdir
                           :dialect dialect-struct
                           :context context
                           :host host-instance
                           :output-file (when workdir
                                          (open-output-file workdir "output.txt"))
                           :errors-file (when workdir
                                          (open-output-file workdir "errors.txt")))))
             (session-state-set session :ready)
             session))
       (error (probe)
         (error 'backend-bootstrap-error
                :backend :clautolisp
                :code :runtime-init-failed
                :message (format nil "Failed to initialise the clautolisp runtime: ~A"
                                 probe)
                :details (list :origin probe)))))
    (:subprocess
     (start-subprocess-engine backend workdir
                              :dialect dialect
                              :host host
                              :dwg dwg
                              :interactive-p interactive-p
                              :load-encoding load-encoding
                              :file-read-encoding file-read-encoding
                              :file-write-encoding file-write-encoding
                              ;; the legacy IO-ENCODING mirror stands in for
                              ;; a caller that passes only it
                              :terminal-in-encoding (or terminal-in-encoding
                                                        io-encoding)
                              :terminal-out-encoding (or terminal-out-encoding
                                                         io-encoding)
                              :log-encoding log-encoding
                              ;; Forwarded, not recorded here: the engine's own
                              ;; REPL transcript is the one worth having
                              ;; (alfe-dribble.issue).
                              :dribble (when cli-options
                                         (clautolisp.autolisp-cli:cli-options-dribble
                                          cli-options))
                              :dribble-interactors
                              (when cli-options
                                (clautolisp.autolisp-cli:cli-options-dribble-interactors
                                 cli-options))))))

;;; --- START-ENGINE: subprocess variant ------------------------------

(defun dialect-cli-name (dialect-keyword)
  "Render the alfe dialect keyword as the string clautolisp-sbcl's CLI
--dialect accepts (any name listed by --list-dialects). The downcased
keyword name matches the reader's dialect registry, so :clautolisp ->
\"clautolisp\", :autocad-2022 -> \"autocad-2022\", etc.; NIL -> strict."
  (if dialect-keyword
      (string-downcase (symbol-name dialect-keyword))
      "strict"))

(defun %warn-direct-dribble-unavailable (cli-options)
  "Say why --dribble records nothing under the IN-PROCESS clautolisp engine, and
what to do instead. Returns T when it warned.

The recording clautolisp's --dribble performs is a REPL one: three Gray streams
tee the REPL's own input/output character by character, and that implementation
belongs to CLAUTOLISP.TOOLS.CLAUTOLISP -- the program, not the engine. It
attaches itself through *DRIBBLE-HOOK*, and in alfe's :direct mode nothing
attaches it, so (clal-dribble …) is a documented no-op there. alfe could not
substitute its own recorder without producing something visibly poorer than what
the same flag gives elsewhere.

So the two honest answers are named, and the third -- recording nothing and
saying nothing -- is the one avoided: a user who asked for a transcript must not
discover its absence by looking for the file."
  (let ((dribble (clautolisp.autolisp-cli:cli-options-dribble cli-options)))
    (when dribble
      (format *error-output*
              "~&alfe: --dribble records nothing with the IN-PROCESS clautolisp ~
engine: the recording is clautolisp's own REPL tee, which only the clautolisp ~
program attaches.~%~
alfe: for a transcript, either run the engine as a child -- `alfe --clautolisp ~
--backend subprocess --dribble …', which forwards the flag so the engine records ~
itself -- or use clautolisp directly. Under --autocad / --bricscad, alfe records ~
the session itself.~%")
      t)))

(defun %dribble-interactors-cli-value (interactors)
  "The --dribble-interactors value to forward for INTERACTORS (the parsed
cli-options slot: :ALL, or a list of names), or NIL when there is nothing to
forward. The spelling is the engine's own: `t' for all, else a comma-separated
list -- so the value the user typed is what the engine receives."
  (cond ((null interactors) nil)
        ((eq interactors :all) "t")
        ((listp interactors) (format nil "~{~A~^,~}" interactors))
        (t nil)))

(defun %dribble-cli-flags (session)
  "The argv fragment forwarding SESSION's dribble request to the spawned
engine: NIL when none was asked for, `--dribble' for the engine's default file,
`--dribble=FILE' for an explicit one, plus --dribble-interactors when given."
  (let ((dribble (clautolisp-subprocess-session-dribble session))
        (interactors (clautolisp-subprocess-session-dribble-interactors session)))
    (append
     (cond ((null dribble) nil)
           ((eq dribble t) (list "--dribble"))
           ((stringp dribble) (list (format nil "--dribble=~A" dribble)))
           (t nil))
     ;; Only with a dribble: the option alone would configure a recording
     ;; that is not happening, and the engine would rightly ignore it.
     (when dribble
       (let ((value (%dribble-interactors-cli-value interactors)))
         (when value (list (format nil "--dribble-interactors=~A" value))))))))

(defun start-subprocess-engine (backend workdir &key dialect host interactive-p
                                load-encoding
                                file-read-encoding file-write-encoding
                                terminal-in-encoding terminal-out-encoding
                                log-encoding
                                dribble dribble-interactors dwg)
  ;; The Phase 1 subprocess variant defers the actual fork to
  ;; EVAL-PLAN so we can map every action to a clautolisp-sbcl CLI
  ;; flag and run the engine *once* with the right argv (rather than
  ;; piping forms through stdin and framing each value's output with
  ;; sentinels — that's the harder design the issue describes as
  ;; the v2 path). START-ENGINE just stashes the binary path and
  ;; the engine flags it has resolved so far.
  ;;
  ;; LOAD-ENCODING and the file / terminal / log encodings are stashed in
  ;; the session so EVAL-PLAN below can forward them as -Esource,
  ;; -Efile-read, -Efile-write, -Eterminal-in, -Eterminal-out and -Elog to
  ;; the spawned clautolisp-sbcl invocation.
  (declare (ignore interactive-p))
  (let ((binary (clautolisp-backend-executable-path backend)))
    (unless (and binary (probe-file binary))
      (error 'backend-bootstrap-error
             :backend :clautolisp
             :code :no-subprocess-binary
             :message "clautolisp-sbcl executable path is not set; call DETECT first."))
    (let ((session (%make-subprocess-session
                    :backend backend
                    :workdir workdir
                    :dialect dialect
                    :host host
                    :process-info nil
                    :output-file (when workdir
                                   (open-output-file workdir "output.txt"))
                    :errors-file (when workdir
                                   (open-output-file workdir "errors.txt"))
                    :load-encoding load-encoding
                    :file-read-encoding file-read-encoding
                    :file-write-encoding file-write-encoding
                    :terminal-in-encoding terminal-in-encoding
                    :terminal-out-encoding terminal-out-encoding
                    :log-encoding log-encoding
                    :dribble dribble
                    :dribble-interactors dribble-interactors
                    :dwg dwg)))
      (session-state-set session :ready)
      session)))

;;; --- EVAL-PLAN: direct variant -------------------------------------

(defun render-runtime-value-safely (value)
  "Render an AutoLISP runtime value via the core printer, falling
back to ~S on a failure (e.g. when the value is in a partially-
constructed state on an error path)."
  (handler-case (autolisp-value->string value nil)
    (error () (prin1-to-string value))))

(defun direct-load (session action)
  "Run a (:LOAD …) action in the direct variant. Honours the
optional :encoding plist entry by passing :external-format through
to AUTOLISP-LOAD-FILE-IN-CONTEXT.

Binds *AUTOLISP-LOAD-PATHNAME* around the load, exactly as the
standalone clautolisp executable does for its -l action (see
tools/clautolisp/source/main.lisp EVAL-ACTION-IN-CONTEXT). Without
this, `alfe --clautolisp -l FILE` left the variable UNBOUND while
`alfe --bricscad` and bare `clautolisp` bound it, so a loaded file
could not self-locate under the clautolisp backend. See
issues/open/autolisp-load-pathname-always-bound.issue."
  (let* ((payload  (action-payload action))
         (path     (getf payload :path))
         (encoding (getf payload :encoding))
         (context  (clautolisp-direct-session-context session))
         (dialect  (clautolisp-direct-session-dialect session))
         (options  (derive-reader-options-for-dialect
                    dialect :source-name (namestring path)))
         (external-format
           (cond
             ((null encoding) nil)
             ((stringp encoding) (encoding-keyword encoding))
             (t encoding))))
    (clautolisp.autolisp-cli:call-with-dynamic-transmit-binding
     context "*AUTOLISP-LOAD-PATHNAME*"
     (clautolisp.autolisp-runtime:make-autolisp-string (namestring path))
     (lambda ()
       (if external-format
           (autolisp-load-file-in-context path context
                                          :options options
                                          :external-format external-format)
           (autolisp-load-file-in-context path context :options options))))))

(defun encoding-keyword (encoding-string)
  "Map a CLI encoding string to the Lisp keyword external-format.
Delegates to the shared CLI alias registry
(clautolisp.autolisp-cli:encoding-keyword). The shared resolver
signals a cli-usage-error on a typo at CLI parse time, so by the
time the backend reaches this helper the value is either a
canonical alias or already-validated alphanumeric."
  (clautolisp.autolisp-cli:encoding-keyword encoding-string "-Esource"))

(defun direct-eval (session action)
  (let* ((text    (action-payload action))
         (context (clautolisp-direct-session-context session))
         (dialect (clautolisp-direct-session-dialect session))
         (options (derive-reader-options-for-dialect
                   dialect :source-name "<-x>"))
         (forms   (read-runtime-from-string text :options options)))
    (call-with-autolisp-error-handler
     (lambda () (autolisp-eval-progn forms context))
     context)))

(defun direct-main (session action)
  "Call the AutoLISP function named in ACTION's payload. Looks up
the symbol via INTERN-AUTOLISP-SYMBOL (so the canonical case lookup
is used) and invokes it with no arguments. Errors propagate through
the standard autolisp-error-handler."
  (let* ((name    (action-payload action))
         (context (clautolisp-direct-session-context session))
         (symbol  (intern-autolisp-symbol name))
         (cell    (lookup-function symbol context)))
    (unless cell
      (error 'backend-eval-error
             :backend :clautolisp
             :code :main-undefined
             :message (format nil "--main: function ~A is unbound" name)
             :details (list :symbol name)))
    (call-with-autolisp-error-handler
     (lambda ()
       (autolisp-eval-progn
        (read-runtime-from-string
         (format nil "(~A)" name)
         :options (derive-reader-options-for-dialect
                   (clautolisp-direct-session-dialect session)
                   :source-name "<--main>"))
        context))
     context)))

(defun direct-interactive (session)
  "Open an interactive REPL on SESSION's evaluation context. Multi-
line forms are joined until the reader reports the source is
parser-balanced (cf. clautolisp.tools.clautolisp's REPL). The loop
exits on EOF or on a :quit control request."
  (let* ((dialect (clautolisp-direct-session-dialect session))
         (context (clautolisp-direct-session-context session))
         (prompt        "alfe> ")
         (continuation  "    > "))
    (loop until (clautolisp-direct-session-interrupt-requested-p session)
          do (write-string prompt) (finish-output)
             (multiple-value-bind (source eof-p)
                 (read-balanced-source dialect prompt continuation)
               (cond
                 (eof-p (terpri) (return))
                 ((or (null source) (zerop (length source))) nil)
                 (t
                  (handler-case
                      (let* ((options (derive-reader-options-for-dialect
                                       dialect :source-name "<repl>"))
                             (forms (read-runtime-from-string source
                                                              :options options))
                             (value (call-with-autolisp-error-handler
                                     (lambda () (autolisp-eval-progn forms context))
                                     context)))
                        (format t "~A~%" (render-runtime-value-safely value)))
                    (autolisp-runtime-error (condition)
                      (format *error-output*
                              "~&; runtime error: ~A: ~A~%"
                              (autolisp-runtime-error-code condition)
                              (autolisp-runtime-error-message condition)))
                    (autolisp-termination ()
                      (return)))))))))

(defun read-balanced-source (dialect prompt continuation)
  "Read whole, parser-balanced AutoLISP source from *STANDARD-INPUT*,
prompting between continuation lines. Returns (VALUES TEXT EOF-P).
The parser is consulted via READ-RUNTIME-FROM-STRING; an unexpected
EOF tells us the form isn't complete yet, so we ask for one more
line and try again."
  (declare (ignore prompt))
  (let ((accumulated nil))
    (loop
      (when accumulated
        (write-string continuation)
        (finish-output))
      (let ((line (read-line *standard-input* nil :eof)))
        (cond
          ((and (eq line :eof) (null accumulated))
           (return (values nil t)))
          ((eq line :eof)
           (return (values accumulated nil)))
          (t
           (setf accumulated
                 (if accumulated
                     (concatenate 'string accumulated (string #\Newline) line)
                     line))
           (handler-case
               (progn
                 (read-runtime-from-string
                  accumulated
                  :options (derive-reader-options-for-dialect
                            dialect :source-name "<repl>"))
                 (return (values accumulated nil)))
             (simple-error (condition)
               (unless (incomplete-form-error-p condition)
                 (return (values accumulated nil)))))))))))

(defun incomplete-form-error-p (condition)
  "True iff CONDITION carries a reader diagnostic flagging an
unexpected end of input. We use this to know whether to prompt for
another line or give up and surface the error."
  (let* ((args (simple-condition-format-arguments condition))
         (first (and args (first args))))
    (and (typep first 'diagnostic)
         (eq :unexpected-eof (diagnostic-code first)))))

(defmethod eval-plan ((session clautolisp-direct-session) plan)
  ;; Tee live stdout/stderr into the workdir mirror files when a
  ;; workdir is present (i.e. when the CLI passed one). With no
  ;; workdir we leave the streams untouched, which is the case
  ;; FiveAM exercises.
  (session-state-set session :running)
  (let ((effective-stdout *standard-output*)
        (effective-stderr *error-output*)
        (final-value nil)
        (status :success)
        (captured-stdout-stream
          (or (clautolisp-direct-session-captured-stdout-stream session)
              (make-string-output-stream)))
        (captured-stderr-stream
          (or (clautolisp-direct-session-captured-stderr-stream session)
              (make-string-output-stream)))
        (output-file (clautolisp-direct-session-output-file session))
        (errors-file (clautolisp-direct-session-errors-file session)))
    (setf effective-stdout
          (apply #'make-tee-stream
                 (remove nil (list *standard-output*
                                   captured-stdout-stream
                                   output-file)))
          effective-stderr
          (apply #'make-tee-stream
                 (remove nil (list *error-output*
                                   captured-stderr-stream
                                   errors-file))))
    (let ((*standard-output* effective-stdout)
          (*error-output*    effective-stderr))
      (handler-case
          (dolist (action plan)
            (when (clautolisp-direct-session-interrupt-requested-p session)
              (setf status :aborted)
              (return))
            (case (action-kind action)
              (:load        (setf final-value (direct-load session action)))
              (:eval        (setf final-value (direct-eval session action)))
              (:main        (setf final-value (direct-main session action)))
              (:interactive (direct-interactive session)
                            (setf final-value nil))
              (:quit        (return))))
        (autolisp-runtime-error (condition)
          (setf status :failed
                final-value nil)
          (format *error-output*
                  "~&; clautolisp runtime error: ~A: ~A~%"
                  (autolisp-runtime-error-code condition)
                  (autolisp-runtime-error-message condition)))
        (autolisp-termination (condition)
          (declare (ignore condition))
          (setf status :success))
        (backend-eval-error (condition)
          (setf status :failed)
          (format *error-output* "~&alfe: ~A~%" condition))
        (error (condition)
          (setf status :failed)
          (format *error-output* "~&; unexpected error: ~A~%" condition))))
    (session-state-set session :done)
    (make-eval-result
     :status status
     :value  (and final-value (render-runtime-value-safely final-value))
     :output (get-output-stream-string captured-stdout-stream)
     :error-output (get-output-stream-string captured-stderr-stream))))

;;; --- EVAL-PLAN: subprocess variant --------------------------------

(defun action-to-cli-flags (action)
  "Translate an alfe action into the flag pair clautolisp-sbcl's CLI
expects. Returns a list of arguments — empty for actions the
subprocess can't service via flags (notably :quit, which is implicit
when the engine drains its argv-driven action queue)."
  (case (action-kind action)
    (:load
     (let ((payload (action-payload action)))
       (list "-l" (getf payload :path))))
    (:eval
     (list "-x" (action-payload action)))
    (:main
     ;; clautolisp-sbcl has no --main; emulate via -x "(NAME)".
     (list "-x" (format nil "(~A)" (action-payload action))))
    (:interactive
     (list "-i"))
    (:quit
     nil)))

(defun %situation-cli-flags (session)
  "The argv fragment forwarding SESSION's file / terminal / log encodings to
the spawned clautolisp: -Efile-read, -Efile-write, -Eterminal-in,
-Eterminal-out, -Elog, each with its value, only for those requested. The
child resolves them exactly as alfe did (same option table, autolisp-cli)."
  (loop for (option value)
          in (list (list "-Efile-read"
                         (clautolisp-subprocess-session-file-read-encoding session))
                   (list "-Efile-write"
                         (clautolisp-subprocess-session-file-write-encoding session))
                   (list "-Eterminal-in"
                         (clautolisp-subprocess-session-terminal-in-encoding session))
                   (list "-Eterminal-out"
                         (clautolisp-subprocess-session-terminal-out-encoding session))
                   (list "-Elog"
                         (clautolisp-subprocess-session-log-encoding session)))
        when value append (list option value)))

(defun %subprocess-capture-external-format (session)
  "The external format alfe decodes the child's CAPTURED stdout / stderr with:
the forwarded terminal-out encoding (the child writes its streams in it), or
NIL for the default. Without this, -Eterminal-out cp1252 would have the child
write cp1252 into a pipe alfe read as UTF-8."
  (let ((enc (clautolisp-subprocess-session-terminal-out-encoding session)))
    (and enc (clautolisp.autolisp-cli:encoding-keyword enc "-Eterminal-out"))))

(defun build-subprocess-argv (session plan)
  "Compose the clautolisp-sbcl argv from SESSION's per-engine flags
plus one flag pair per action in PLAN. Used by EVAL-PLAN on the
subprocess variant."
  (let* ((backend (session-backend session))
         (binary  (clautolisp-backend-executable-path backend))
         (dialect (session-dialect session))
         (host    (clautolisp-subprocess-session-host session))
         ;; The three hosts clautolisp has, by their own names: cador,
         ;; cadtui, nihil. alfe hands the choice over unchanged.
         (host-name (if host (string-downcase (symbol-name host)) "cador")))
    (append (list binary
                  "--quiet"
                  ;; The front-end owns bootstrap/init policy.  Loading the
                  ;; spawned CLI's user rc files here makes subprocess runs
                  ;; differ from the direct backend and contaminates tests.
                  "--no-init"
                  "--dialect" (dialect-cli-name dialect)
                  "--host"    host-name)
            ;; Forward the user's `source' encoding so the spawned
            ;; clautolisp-sbcl reads source files in the same encoding
            ;; the user asked alfe for. Placed BEFORE the action flags so
            ;; it's in effect from the very first -l/-x in the queue.
            (let ((enc (clautolisp-subprocess-session-load-encoding session)))
              (when enc (list "-Esource" enc)))
            ;; ... and the other situations the child applies itself
            ;; (section 6 point 1), each only when one was requested.
            (%situation-cli-flags session)
            (let ((dwg (clautolisp-subprocess-session-dwg session)))
              (when dwg (list "--dwg" dwg)))
            ;; Forward the dribble request, the same way as -Esource above
            ;; (alfe-dribble.issue; pjb: "alfe --clautolisp surement
            ;; l'implemente deja dans clautolisp"). The ENGINE records its own
            ;; REPL, which is the transcript worth having -- alfe records
            ;; nothing for this backend, so there is no second, poorer copy of
            ;; the same session. --dribble-interactors only means anything
            ;; where interactors exist, which is exactly here, so it is
            ;; forwarded too.
            (%dribble-cli-flags session)
            (loop for action in plan
                  for flags = (action-to-cli-flags action)
                  when flags append flags))))

(defmethod eval-plan ((session clautolisp-subprocess-session) plan)
  (session-state-set session :running)
  (let* ((argv (build-subprocess-argv session plan))
         (captured-stdout (make-string-output-stream))
         (captured-stderr (make-string-output-stream))
         (status :success))
    (log-debug "backend CLAUTOLISP (subprocess): launching: ~{~A~^ ~}" argv)
    (handler-case
        (multiple-value-bind (stdout stderr exit-code)
            (if (some (lambda (action) (eq (action-kind action) :interactive))
                      plan)
                ;; A REPL — or the cadtui console — reads the keyboard and
                ;; writes the screen, which captured pipes cannot serve: the
                ;; child gets alfe's own terminal. Nothing is captured then,
                ;; so OUTPUT / ERROR-OUTPUT of the result stay empty.
                (progn
                  (finish-output *standard-output*)
                  (finish-output *error-output*)
                  (uiop:run-program argv
                                    :input :interactive
                                    :output :interactive
                                    :error-output :interactive
                                    :ignore-error-status t))
                (let ((external-format (%subprocess-capture-external-format session)))
                  (apply #'uiop:run-program argv
                         :output :string
                         :error-output :string
                         :ignore-error-status t
                         (when external-format
                           (list :external-format external-format)))))
          (log-verbose "backend CLAUTOLISP (subprocess): exit ~A" exit-code)
          (let ((stdout (or stdout ""))
                (stderr (or stderr "")))
            (write-string stdout captured-stdout)
            (write-string stderr captured-stderr)
            ;; Echo live, same contract as the direct variant.
            (write-string stdout *standard-output*)
            (write-string stderr *error-output*))
          (unless (zerop exit-code)
            (setf status :failed)))
      (error (probe)
        (setf status :failed)
        (format captured-stderr "subprocess launch failed: ~A~%" probe)
        (format *error-output* "alfe: subprocess launch failed: ~A~%" probe)))
    (session-state-set session :done)
    (let ((stdout-text (get-output-stream-string captured-stdout))
          (stderr-text (get-output-stream-string captured-stderr)))
      ;; Mirror into workdir/output.txt and errors.txt if requested.
      (let ((out-file (clautolisp-subprocess-session-output-file session))
            (err-file (clautolisp-subprocess-session-errors-file session)))
        (when out-file (write-string stdout-text out-file))
        (when err-file (write-string stderr-text err-file)))
      ;; VALUE is intentionally NIL here. The subprocess engine has
      ;; already passed user-script output through to *standard-output*
      ;; verbatim; if the CLI also printed a "final value", we'd
      ;; double-print every (princ …) in the user's source. The direct
      ;; variant can return a real value because it owns the
      ;; AutoLISP-side runtime and prints nothing on the user's
      ;; behalf — the CLI's value-print step is what makes -x emit a
      ;; visible result there.
      (make-eval-result
       :status status
       :value nil
       :output stdout-text
       :error-output stderr-text))))

(defun last-non-empty-line (text)
  "Return the last non-blank line of TEXT, or NIL if there is none.
Used to pluck the subprocess's final printed value out of its stdout
capture."
  (let ((lines (remove ""
                       (uiop:split-string text :separator '(#\Newline))
                       :test #'string=)))
    (and lines (car (last lines)))))

;;; --- READ-OUTPUT / SEND-INPUT / REQUEST-CONTROL --------------------

(defmethod read-output ((session clautolisp-direct-session) &key timeout)
  ;; The direct variant's output went straight to *STANDARD-OUTPUT*
  ;; (and the workdir mirror) at EVAL-PLAN time. We return the
  ;; captured buffers as a convenience for tests that want to
  ;; introspect — but they may be empty when output was already
  ;; consumed.
  (declare (ignore timeout))
  (values
   (let ((stream (clautolisp-direct-session-captured-stdout-stream session)))
     (if stream (get-output-stream-string stream) ""))
   (let ((stream (clautolisp-direct-session-captured-stderr-stream session)))
     (if stream (get-output-stream-string stream) ""))))

(defmethod read-output ((session clautolisp-subprocess-session) &key timeout)
  (declare (ignore timeout))
  (values "" ""))

(defmethod send-input ((session clautolisp-direct-session) text)
  ;; The direct REPL reads from *STANDARD-INPUT*, which alfe.cli has
  ;; already wired up. SEND-INPUT is meaningless for the synchronous
  ;; in-process variant in V1; we record the text for inspection.
  (declare (ignore session))
  text)

(defmethod send-input ((session clautolisp-subprocess-session) text)
  (let ((in (uiop:process-info-input
             (clautolisp-subprocess-session-process-info session))))
    (write-line text in)
    (finish-output in)
    text))

(defmethod request-control ((session clautolisp-direct-session) command)
  (case command
    (:ping       :pong)
    (:interrupt  (setf (clautolisp-direct-session-interrupt-requested-p session) t)
                 :interrupted)
    (:shutdown   (shutdown session) :stopped)
    (otherwise
     (error 'backend-protocol-error
            :backend :clautolisp
            :code :unknown-control
            :message (format nil "Unknown control command ~S" command)))))

(defmethod request-control ((session clautolisp-subprocess-session) command)
  (case command
    (:ping     :pong)
    (:shutdown (shutdown session) :stopped)
    (:interrupt
     (uiop:terminate-process
      (clautolisp-subprocess-session-process-info session))
     :interrupted)
    (otherwise
     (error 'backend-protocol-error
            :backend :clautolisp
            :code :unknown-control
            :message (format nil "Unknown control command ~S" command)))))

;;; --- SHUTDOWN ------------------------------------------------------

(defmethod shutdown ((session clautolisp-direct-session) &key reason)
  (declare (ignore reason))
  (unless (eq (session-state session) :stopped)
    (when (clautolisp-direct-session-output-file session)
      (ignore-errors
       (close (clautolisp-direct-session-output-file session))))
    (when (clautolisp-direct-session-errors-file session)
      (ignore-errors
       (close (clautolisp-direct-session-errors-file session))))
    (session-state-set session :stopped))
  session)

(defmethod shutdown ((session clautolisp-subprocess-session) &key reason)
  (declare (ignore reason))
  (let ((info (clautolisp-subprocess-session-process-info session)))
    (when info
      (handler-case
          (when (uiop:process-alive-p info)
            (uiop:terminate-process info)
            (uiop:wait-process info))
        (error () nil)))
    (when (clautolisp-subprocess-session-output-file session)
      (ignore-errors
       (close (clautolisp-subprocess-session-output-file session))))
    (when (clautolisp-subprocess-session-errors-file session)
      (ignore-errors
       (close (clautolisp-subprocess-session-errors-file session))))
    (unless (eq (session-state session) :stopped)
      (session-state-set session :stopped)))
  session)

;;; --- CLEANUP-WORKDIR ----------------------------------------------

(defmethod cleanup-workdir ((backend clautolisp-backend) workdir &key keep-p)
  (when workdir
    (remove-workdir workdir :keep-p keep-p))
  nil)

;;; --- registration -------------------------------------------------

;; Register the :direct variant under :clautolisp by default. The CLI
;; can swap in the :subprocess variant by constructing a fresh
;; backend at resolve-time when --backend subprocess is requested.
(register-backend :clautolisp (make-clautolisp-backend :variant :direct))
