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
                #:eval-plan-with-action-hooks
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
           #:resolve-clautolisp-host
           #:*clautolisp-option-contract*
           #:clautolisp-option-disposition))

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
                            (if (uiop:os-windows-p)
                                #P"../../clautolisp/tools/clautolisp/bin/clautolisp-sbcl.exe"
                                #P"../../clautolisp/tools/clautolisp/bin/clautolisp-sbcl")
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
is not observable from the outside.")
   (column
    :initform 0
    :accessor tee-stream-column
    :documentation
    "Column of the next character, so FRESH-LINE (the ~& of the engine's
diagnostics) behaves as on the real stream instead of always breaking the
line: the in-process engine must print what the clautolisp program prints
(alfe-clautolisp-backend-semantic-parity.issue)."))
  (:documentation
   "Character output stream that writes to every member of
DESTINATIONS in order. Used in PHASE 1 to mirror the live stdout
into WORKDIR/output.txt and the live stderr into WORKDIR/errors.txt."))

(defmethod trivial-gray-streams:stream-write-char ((stream tee-stream) ch)
  (dolist (dest (tee-stream-destinations stream))
    (write-char ch dest))
  (setf (tee-stream-column stream)
        (if (char= ch #\Newline) 0 (1+ (tee-stream-column stream))))
  ch)

(defmethod trivial-gray-streams:stream-write-string
    ((stream tee-stream) string &optional (start 0) (end nil))
  (let ((end (or end (length string))))
    (dolist (dest (tee-stream-destinations stream))
      (write-string string dest :start start :end end))
    (let ((newline (position #\Newline string :start start :end end
                                               :from-end t)))
      (setf (tee-stream-column stream)
            (if newline
                (- end newline 1)
                (+ (tee-stream-column stream) (- end start))))))
  string)

(defmethod trivial-gray-streams:stream-line-column ((stream tee-stream))
  (tee-stream-column stream))

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
  (interrupt-requested-p nil)
  ;; alfe's CLI-OPTIONS, for what EVAL-PLAN resolves per run: the debugger
  ;; settings (--on-error, --on-interrupt, --on-quit, --debugger-ui,
  ;; --aldb-listen, --aldb-stdio), whose defaults depend on whether the plan
  ;; is interactive. NIL when START-ENGINE had none (then the engine runs
  ;; with the runtime's defaults and no debugger, as before).
  (cli-options nil)
  ;; The --dwg drawing the host could not open, as the CLI-USAGE-ERROR the
  ;; clautolisp program reports for it. EVAL-PLAN reports it and fails
  ;; before the first action, exactly as the program does before its first
  ;; one, so both variants print the same line and exit with the same status
  ;; (alfe-clautolisp-backend-semantic-parity.issue).
  (startup-error nil))

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
  ;; The --dcl renderer selection (:tui / :ncurses / :gui / :auto), forwarded
  ;; as --dcl when it is not the engine's own default (:auto).
  (dcl nil)
  ;; The drawing argument (--dwg / $AUTOLISP_DWG), forwarded as --dwg.
  (dwg nil)
  ;; The debugger options the user gave, as the child's argv fragment
  ;; (--on-error debug, --aldb-listen 127.0.0.1:0, ...): forwarded verbatim so
  ;; the engine applies them -- and its own defaults to the others -- exactly
  ;; as the in-process engine does.
  (debugger-arguments nil)
  ;; True when those options arm a debug session in the child: it will talk
  ;; to the user (a DBG> prompt, the aldb connect prompt, stdio RPC), so it is
  ;; given alfe's terminal instead of captured pipes, as for -i.
  (debugger-session-p nil)
  ;; The *AUTOLISP-...* bindings alfe resolved -- the very list the direct
  ;; variant installs -- forwarded through --front-end-bindings so the child
  ;; engine shows user code the same values. NIL when START-ENGINE had no
  ;; CLI-OPTIONS (then the child derives its own, as the direct variant
  ;; installs none).
  (front-end-bindings nil))

;;; --- START-ENGINE: direct variant ----------------------------------

(defun direct-transmit-bindings (cli-options version-text)
  "The *AUTOLISP-...* bindings of alfe's clautolisp engine for CLI-OPTIONS:
installed in-process by the direct variant, handed to the child through
--front-end-bindings by the subprocess variant -- ONE list, so user code sees
the same values whichever variant runs it
(alfe-clautolisp-backend-semantic-parity.issue)."
  (alfe.cli:cli-options-transmit-bindings-for-alfe
   cli-options
   :backend "CLAUTOLISP"
   :usage-text (alfe.cli:usage-string)
   :version-text (or version-text "0.0.0")))

(defun open-output-file (workdir basename)
  "Open WORKDIR/BASENAME for append-from-empty writes, in UTF-8.
Returns the open stream. Callers are responsible for closing it on
SHUTDOWN."
  (open (merge-pathnames basename workdir)
        :direction :output
        :if-exists :supersede
        :if-does-not-exist :create
        :external-format :utf-8
        ;; CCL makes a file stream PRIVATE to the thread that opened it by
        ;; default; the aldo companion thread writes the debugger dialogue
        ;; through the same tee (--on-error debug in the in-process engine),
        ;; and got "Stream ... is private to ..." instead.
        #+ccl :sharing #+ccl :lock))

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
  ;; direct branch doesn't use it (it has no REPL: an interactive run is
  ;; the clautolisp program's, routed to the subprocess variant). MOCK-INPUT
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
                (session-handle (evaluation-context-session context))
                ;; The drawing argument (--dwg / $AUTOLISP_DWG): the first
                ;; drawing. A drawing the host cannot open is reported by
                ;; EVAL-PLAN, in the clautolisp program's words.
                (startup-error
                  (when (and dwg host-instance)
                    (handler-case
                        (progn
                          (clautolisp.autolisp-host:host-open-startup-drawing
                           host-instance dwg)
                          nil)
                      (error (condition)
                        (clautolisp.autolisp-cli:engine-drawing-error
                         dwg condition))))))
           ;; The host set-up of the clautolisp program (SETUP-CONTEXT): the
           ;; session's host, then the startup drawing's LISP namespace --
           ;; the context's (multi-document slice 1) -- then the builtins.
           (set-runtime-session-host session-handle host-instance)
           (when host-instance
             (clautolisp.autolisp-host:link-runtime-session-to-host
              session-handle host-instance))
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
              context (direct-transmit-bindings cli-options version-text)))
           ;; Effective default source-file encoding precedence:
           ;;   -Esource or the bare -E (SOURCE-ENCODING / LOAD-ENCODING) > LC_ALL/LC_CTYPE/LANG > NIL.
           ;; NIL falls through to the dialect default at load time.
           (let ((effective
                   (or (and load-encoding (encoding-keyword load-encoding))
                       (clautolisp.autolisp-runtime:locale-default-source-encoding))))
             (when effective
               (clautolisp.autolisp-runtime:set-default-source-encoding
                context effective)))
           ;; No --dribble here: a run that asks for one is the clautolisp
           ;; program's, so alfe.cli routed it to the subprocess variant.
           (let ((session (%make-direct-session
                           :backend backend
                           :workdir workdir
                           :dialect dialect-struct
                           :context context
                           :host host-instance
                           :cli-options cli-options
                           :startup-error startup-error
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
                                 cli-options))
                              :dcl (when cli-options
                                     (clautolisp.autolisp-cli:cli-options-dcl
                                      cli-options))
                              :front-end-bindings
                              (when cli-options
                                (direct-transmit-bindings cli-options version-text))
                              :debugger-arguments
                              (when cli-options
                                (clautolisp.autolisp-cli:debugger-option-arguments
                                 cli-options))
                              :debugger-session-p
                              (and cli-options
                                   (clautolisp.autolisp-cli:debugger-session-requested-p
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
                                dribble dribble-interactors dwg dcl
                                front-end-bindings
                                debugger-arguments debugger-session-p)
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
                    :dwg dwg
                    :dcl dcl
                    :front-end-bindings front-end-bindings
                    :debugger-arguments debugger-arguments
                    :debugger-session-p debugger-session-p)))
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

(defun direct-eval-text (session text)
  "Evaluate the AutoLISP source TEXT as one -x action, as the clautolisp
program does: *AUTOLISP-EXPRESSION* is bound to TEXT for the duration."
  (let* ((context (clautolisp-direct-session-context session))
         (dialect (clautolisp-direct-session-dialect session))
         (options (derive-reader-options-for-dialect
                   dialect :source-name "<-x>"))
         (forms   (read-runtime-from-string text :options options)))
    (clautolisp.autolisp-cli:call-with-dynamic-transmit-binding
     context "*AUTOLISP-EXPRESSION*"
     (clautolisp.autolisp-runtime:make-autolisp-string text)
     (lambda ()
       (call-with-autolisp-error-handler
        (lambda () (autolisp-eval-progn forms context))
        context)))))

(defun direct-eval (session action)
  (direct-eval-text session (action-payload action)))

(defun direct-main (session action)
  "Call the AutoLISP function named in ACTION's payload, with no arguments.
The clautolisp program has no --main, so the subprocess variant runs it as
-x \"(NAME)\"; this variant does exactly the same, so an unbound NAME is
the same UNDEFINED-FUNCTION runtime error in both
(alfe-clautolisp-backend-semantic-parity.issue)."
  (direct-eval-text session (format nil "(~A)" (action-payload action))))

;; There is no REPL here. An interactive session is the clautolisp PROGRAM's
;; (its interactors, comma commands, aldo debugger, Control-C policy, dribble),
;; so alfe runs it as the subprocess variant (alfe.cli:clautolisp-program-
;; requirement) and the two variants cannot differ. alfe's own minimal
;; `alfe> ' loop, which used to stand in for it here, is gone
;; (alfe-clautolisp-backend-semantic-parity.issue).

(defun direct-interactive-refused ()
  "The error an :INTERACTIVE action meets in the direct variant: only a caller
bypassing alfe.cli (which routes interactive runs to the subprocess variant)
can get here."
  (error 'backend-eval-error
         :backend :clautolisp
         :code :interactive-needs-subprocess
         :message "An interactive session runs in the clautolisp executable, not in alfe's embedded engine (--backend subprocess)."))

(defun call-with-direct-debugger (session plan run-actions)
  "Run the PLAN of the direct SESSION through RUN-ACTIONS (a function of the
debug session and the break-on-error flag) under the debugger options alfe was
given -- resolved, bound and acted on by the clautolisp program's own functions,
so the in-process engine behaves as the program (and as the subprocess variant,
which IS the program): the event policies and their defaults (--on-error
debug for an interactive plan, quit for a batch one), the AutoLISP mirrors
(*CLAL-ON-ERROR*, ...), the --on-interrupt Control-C handler (restored
afterwards: Control-C is alfe's again), and, for a debugged run, ONE aldo
session with its UI on the aldo companion thread -- the batch actions as one
debugging extent, or each turn of the REPL when the plan is interactive.

A session started without CLI options (a test driving the backend directly)
runs RUN-ACTIONS plain, with no debugger, as before."
  (let ((options (clautolisp-direct-session-cli-options session)))
    (if (null options)
        (funcall run-actions nil nil)
        (let* ((context (clautolisp-direct-session-context session))
               (interactive-p (some (lambda (action)
                                      (eq (action-kind action) :interactive))
                                    plan))
               (settings (clautolisp.tools.clautolisp:resolve-debugger-settings
                          options :interactive-p interactive-p)))
          (clautolisp.tools.clautolisp:with-debugger-settings (settings)
            (clautolisp.tools.clautolisp:sync-debugger-policy-mirrors)
            (clautolisp.tools.clautolisp:call-with-interrupt-handler
             (lambda ()
               (clautolisp.tools.clautolisp:call-with-debug-session
                (clautolisp.tools.clautolisp:debugger-settings-debug-ui settings)
                (clautolisp.tools.clautolisp:debugger-settings-on-error settings)
                context
                (lambda (debug-session break)
                  (if (and debug-session (not interactive-p))
                      (clautolisp.tools.clautolisp:run-under-session-debugging
                       debug-session
                       (lambda () (funcall run-actions nil nil))
                       break)
                      (funcall run-actions debug-session break)))))))))))

;;; --- per-action hooks, both variants --------------------------------
;;;
;;; alfe's :pre-action / :post-action plug-in hooks run at the action
;;; boundaries of the ONE run EVAL-PLAN makes -- in-process here, in the child
;;; through --front-end-action-boundaries below -- so a plug-in changes nothing
;;; about the run itself: AutoLISP state carries from one action to the next,
;;; the run stops where it would stop anyway (an error, (exit N)), and its
;;; output and status are the same (alfe-clautolisp-backend-semantic-
;;; parity.issue). Before, alfe made one EVAL-PLAN per action, and the
;;; subprocess variant one child per action.

(defun %action-result (exit-code value output error-output &key (status :success))
  "The EVAL-RESULT a :post-action hook receives for one action, built the same
way by both variants: EXIT-CODE is the status the engine had recorded when the
action ended (its (exit N), its error's status), VALUE the action's value as
CLAUTOLISP.AUTOLISP-CLI:RENDER-ACTION-VALUE renders it, OUTPUT and ERROR-OUTPUT
what the action wrote. A non-zero EXIT-CODE fails the action, as it fails the
whole run."
  (make-eval-result
   :status (if (and (integerp exit-code) (/= 0 exit-code)) :failed status)
   :exit-code exit-code
   :value value
   :output (or output "")
   :error-output (or error-output "")))

(defun %call-action-hook (function &rest arguments)
  "Call the action hook FUNCTION. An error in it is not the ENGINE's: it must
neither be reported as a runtime error, nor break into aldo, nor be taken for
a failure of the child; it leaves the run through the catch tag
%ACTION-HOOK-FAILED, and the variant re-signals it once the engine is stopped,
so it reaches alfe's own error handling as it did when the hooks were called
from alfe.cli."
  (handler-case (apply function arguments)
    (error (condition)
      (throw '%action-hook-failed condition))))

(defmacro %with-action-hook-failures ((failure) &body body)
  "Run BODY; if an action hook failed in it, set FAILURE to its condition."
  (let ((condition (gensym "CONDITION")))
    `(let ((,condition (catch '%action-hook-failed
                         ,@body
                         nil)))
       (when ,condition (setf ,failure ,condition)))))

(defmethod eval-plan ((session clautolisp-direct-session) plan)
  (%direct-eval-plan session plan nil nil))

(defmethod eval-plan-with-action-hooks ((session clautolisp-direct-session) plan
                                        before-action after-action)
  (%direct-eval-plan session plan before-action after-action))

(defun %direct-eval-plan (session plan before-action after-action)
  "EVAL-PLAN of the direct variant; with BEFORE-ACTION / AFTER-ACTION (see
EVAL-PLAN-WITH-ACTION-HOOKS), called around each action of the same run. The
hooks run with alfe's own streams, not the engine's: what they print is not
the engine's output, as in the subprocess variant."
  ;; Tee live stdout/stderr into the workdir mirror files when a
  ;; workdir is present (i.e. when the CLI passed one). With no
  ;; workdir we leave the streams untouched, which is the case
  ;; FiveAM exercises.
  (session-state-set session :running)
  (let* ((hooks-p (or before-action after-action))
         (alfe-stdout *standard-output*)
         (alfe-stderr *error-output*)
         (final-value nil)
         (status :success)
         (exit-code nil)
         (hook-failure nil)
         ;; The action in progress, for the :post-action of one that does not
         ;; return (an error, (exit N)): (ACTION . INDEX).
         (current nil)
         (captured-stdout-stream
           (or (clautolisp-direct-session-captured-stdout-stream session)
               (make-string-output-stream)))
         (captured-stderr-stream
           (or (clautolisp-direct-session-captured-stderr-stream session)
               (make-string-output-stream)))
         ;; What the current action wrote, for its :post-action result.
         (action-stdout (and hooks-p (make-string-output-stream)))
         (action-stderr (and hooks-p (make-string-output-stream)))
         (output-file (clautolisp-direct-session-output-file session))
         (errors-file (clautolisp-direct-session-errors-file session))
         (context (clautolisp-direct-session-context session))
         (effective-stdout
           (apply #'make-tee-stream
                  (remove nil (list *standard-output*
                                    captured-stdout-stream
                                    action-stdout
                                    output-file))))
         (effective-stderr
           (apply #'make-tee-stream
                  (remove nil (list *error-output*
                                    captured-stderr-stream
                                    action-stderr
                                    errors-file)))))
    (labels ((action-output ()
               (values (if action-stdout (get-output-stream-string action-stdout) "")
                       (if action-stderr (get-output-stream-string action-stderr) "")))
             (call-hook (function &rest arguments)
               (when function
                 (let ((*standard-output* alfe-stdout)
                       (*error-output* alfe-stderr))
                   (apply #'%call-action-hook function arguments)))))
      (let ((*standard-output* effective-stdout)
            (*error-output*    effective-stderr))
        ;; The outcome is reported, and the exit status chosen, exactly as the
        ;; clautolisp program does in RUN-WITH-INPUT / MAIN -- the subprocess
        ;; variant IS that program, and the two variants must not differ in
        ;; diagnostics or status (alfe-clautolisp-backend-semantic-parity.issue).
        (handler-case
            (%with-action-hook-failures (hook-failure)
              (let ((startup-error (clautolisp-direct-session-startup-error session)))
                (when startup-error
                  (error startup-error)))
              (flet ((run-actions (debug-session break)
                       (declare (ignore debug-session break))
                       (loop for action in plan
                             for index from 1
                             for kind = (action-kind action)
                             do (when (clautolisp-direct-session-interrupt-requested-p session)
                                  ;; Interrupted: the status of a Control-C under the quit
                                  ;; policy, as the clautolisp program gives it.
                                  (setf status :aborted
                                        exit-code clautolisp.sysexits:+exit-interrupted+)
                                  (return))
                                (action-output) ; drop what came before the action
                                (call-hook before-action action index)
                                (setf current (cons action index))
                                ;; Each action is a top-level read: a document switch the
                                ;; previous one requested (NEW / OPEN ...) takes effect here.
                                (when (member kind '(:load :eval :main))
                                  (clautolisp.autolisp-runtime:apply-pending-document-switch context))
                                (let ((value (case kind
                                               (:load        (direct-load session action))
                                               (:eval        (direct-eval session action))
                                               (:main        (direct-main session action))
                                               (:interactive (direct-interactive-refused))
                                               (:quit        nil))))
                                  (when (member kind '(:load :eval :main))
                                    (setf final-value value))
                                  (setf current nil)
                                  (when after-action
                                    (multiple-value-bind (out err) (action-output)
                                      (call-hook after-action action index
                                                 (%action-result
                                                  (clautolisp.autolisp-runtime:autolisp-exit-status
                                                   context)
                                                  (clautolisp.autolisp-cli:render-action-value value)
                                                  out err)))))
                                (when (eq kind :quit)
                                  (return)))))
                ;; The run's dribble streams, as the clautolisp program installs
                ;; them around its run: (clal-dribble FILE) from an action
                ;; records the same file in both variants. Not for a session
                ;; started without CLI options (a test driving the backend),
                ;; which never had a recorder.
                (if (clautolisp-direct-session-cli-options session)
                    (clautolisp.tools.clautolisp:call-with-engine-dribble
                     (lambda ()
                       (call-with-direct-debugger session plan #'run-actions)))
                    (call-with-direct-debugger session plan #'run-actions)))
              ;; Normal completion: the status a script recorded with
              ;; (autolisp-set-status N), 0 when it never did.
              (unless (eq status :aborted)
                (setf exit-code (clautolisp.autolisp-runtime:autolisp-exit-status
                                 context))))
          ;; Every status comes from the table the clautolisp program uses
          ;; (CLAUTOLISP.AUTOLISP-CLI:ENGINE-EXIT-STATUS;
          ;; sysexits-exit-statuses.issue).
          (autolisp-runtime-error (condition)
            (setf status :failed
                  final-value nil
                  exit-code (clautolisp.autolisp-cli:engine-exit-status condition))
            ;; No host-Lisp backtrace: the child engine never prints one
            ;; either (alfe spawns it --quiet, never --debug).
            (clautolisp.autolisp-cli:report-autolisp-runtime-error condition))
          (autolisp-termination (condition)
            ;; (quit [N]) / (exit [N]): reported, and N is the status.
            (clautolisp.autolisp-cli:report-autolisp-termination condition)
            (setf exit-code (clautolisp.autolisp-runtime:autolisp-termination-status
                             condition)))
          (backend-eval-error (condition)
            (setf status :failed)
            (format *error-output* "~&alfe: ~A~%" condition))
          ;; A file that cannot be opened (EX_NOINPUT), a source the reader
          ;; refuses (EX_DATAERR), a --dwg drawing (its CLI-ERROR status), an
          ;; internal error (EX_SOFTWARE).
          (error (condition)
            (setf status :failed
                  exit-code (clautolisp.autolisp-cli:engine-exit-status condition))
            (clautolisp.autolisp-cli:report-engine-error condition))))
      (when (and (integerp exit-code) (/= 0 exit-code))
        (setf status :failed))
      (session-state-set session :done)
      ;; An action that did not return -- the run ended in it -- still has its
      ;; :post-action, with the run's outcome, as in the subprocess variant
      ;; (whose child exits in it).
      (when (and current after-action (not hook-failure))
        (multiple-value-bind (out err) (action-output)
          (%with-action-hook-failures (hook-failure)
            (call-hook after-action (car current) (cdr current)
                       (%action-result exit-code nil out err
                                       :status (if (eq status :failed)
                                                   :failed
                                                   :success))))))
      (when hook-failure
        (error hook-failure))
      (make-eval-result
       :status status
       :exit-code exit-code
       :value  (and final-value (render-runtime-value-safely final-value))
       :output (get-output-stream-string captured-stdout-stream)
       :error-output (get-output-stream-string captured-stderr-stream)))))

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

(defun %forward-dialect (session)
  "--dialect NAME for the child (--dialect / --strict / --lax)."
  (list "--dialect" (dialect-cli-name (session-dialect session))))

(defun %forward-host (session)
  "--host NAME for the child: clautolisp's three hosts by their own names
(cador, cadtui, nihil); alfe hands the choice over unchanged."
  (let ((host (clautolisp-subprocess-session-host session)))
    (list "--host" (if host (string-downcase (symbol-name host)) "cador"))))

(defun %forward-dwg (session)
  "--dwg FILE for the child, when a drawing was asked for."
  (let ((dwg (clautolisp-subprocess-session-dwg session)))
    (when dwg (list "--dwg" dwg))))

(defun %forward-source-encoding (session)
  "-Esource ENC for the child: the user's `source' encoding, so the spawned
engine reads source files in the encoding the user asked alfe for."
  (let ((enc (clautolisp-subprocess-session-load-encoding session)))
    (when enc (list "-Esource" enc))))

(defun %forward-dcl (session)
  "--dcl MODE for the child, when it is not the engine's own default (auto)."
  (let ((dcl (clautolisp-subprocess-session-dcl session)))
    (when (and dcl (not (eq dcl :auto)))
      (list "--dcl" (string-downcase (symbol-name dcl))))))

(defun %debugger-cli-flags (session)
  "The debugger options the user gave (--on-error POLICY, ..., --aldb-stdio),
spelled as the child's parser reads them back
(CLAUTOLISP.AUTOLISP-CLI:DEBUGGER-OPTION-ARGUMENTS, computed at START-ENGINE).
The child applies its own defaults to the others, as the direct variant does."
  (clautolisp-subprocess-session-debugger-arguments session))

(defun %child-plan (plan)
  "The part of PLAN the child runs: the actions before the first :QUIT. The
in-process engine stops at a :QUIT (alfe ... -x A --quit -x B never runs B),
and the clautolisp program has no --quit, so the actions after it are simply
not handed over."
  (ldiff plan (member :quit plan :key #'action-kind)))

(defun build-subprocess-argv (session plan &key front-end-bindings-file
                                                action-boundaries)
  "Compose the clautolisp-sbcl argv for SESSION and PLAN. Used by EVAL-PLAN on
the subprocess variant. FRONT-END-BINDINGS-FILE, when given, is passed as
--front-end-bindings so the child installs alfe's *AUTOLISP-...* values;
ACTION-BOUNDARIES, when given, as --front-end-action-boundaries, so the child
stops at each action boundary for alfe's per-action hooks.

The options come from the option contract, not from a list kept here: every
argv-fragment function an :ENGINE / :PROGRAM entry of
*CLAUTOLISP-OPTION-CONTRACT* names under :FORWARD, once each, in table order
(dialect, host, drawing, encodings, dribble, DCL) -- so an option is forwarded
exactly when the contract says so (alfe-clautolisp-backend-semantic-parity.issue).
Then the front-end bindings and the boundaries, then one flag pair per action
of the plan up to its first :QUIT (%CHILD-PLAN), last, so every option is in
effect from the first -l / -x. A plan with no action for the child (alfe
--quit) is the no-op -x \"\": the clautolisp program would take an empty
command line for a REPL, which the in-process engine never starts."
  (let ((binary (clautolisp-backend-executable-path (session-backend session)))
        (action-flags (loop for action in (%child-plan plan)
                            for flags = (action-to-cli-flags action)
                            when flags append flags)))
    (append (list binary
                  "--quiet"
                  ;; The front-end owns bootstrap/init policy.  Loading the
                  ;; spawned CLI's user rc files here makes subprocess runs
                  ;; differ from the direct backend and contaminates tests.
                  "--no-init")
            (loop for forwarder in (contract-subprocess-forwarders)
                  append (funcall forwarder session))
            (when front-end-bindings-file
              (list "--front-end-bindings"
                    (namestring front-end-bindings-file)))
            (when action-boundaries
              (list "--front-end-action-boundaries"
                    (namestring action-boundaries)))
            (or action-flags (list "-x" "")))))

(defun %front-end-bindings-pathname (session)
  "Where EVAL-PLAN writes SESSION's front-end bindings for the child: in the
workdir when there is one (kept with it under --keep-workdir), else a fresh
temporary file. Second value: T when the file is temporary (deleted after
the run)."
  (let ((workdir (session-workdir session)))
    (if workdir
        (values (merge-pathnames "front-end-bindings.sexp"
                                 (uiop:ensure-directory-pathname workdir))
                nil)
        (values (uiop:tmpize-pathname
                 (merge-pathnames "alfe-front-end-bindings.sexp"
                                  (uiop:temporary-directory)))
                t))))

(defun %call-with-front-end-bindings (session function)
  "Call FUNCTION with the pathname of the file holding SESSION's front-end
bindings (NIL when it has none), written for the duration of the call."
  (let ((bindings (clautolisp-subprocess-session-front-end-bindings session)))
    (if (null bindings)
        (funcall function nil)
        (multiple-value-bind (file temporary-p) (%front-end-bindings-pathname session)
          (unwind-protect
               (progn
                 (clautolisp.autolisp-cli:write-transmit-bindings-file file bindings)
                 (funcall function file))
            (when temporary-p
              (ignore-errors (delete-file file))))))))

(defmethod eval-plan ((session clautolisp-subprocess-session) plan)
  (%call-with-front-end-bindings
   session
   (lambda (file) (%subprocess-eval-plan session plan file nil nil))))

(defmethod eval-plan-with-action-hooks ((session clautolisp-subprocess-session) plan
                                        before-action after-action)
  (%call-with-front-end-bindings
   session
   (lambda (file)
     (%subprocess-eval-plan session plan file before-action after-action))))

(defun %process-stream-p (stream)
  "True when STREAM (synonym streams followed) is one of this process's own
file-descriptor streams -- the child can then simply inherit the descriptor."
  (loop while (typep stream 'synonym-stream)
        do (setf stream (symbol-value (synonym-stream-symbol stream))))
  (or #+sbcl (typep stream 'sb-sys:fd-stream)
      ;; CCL's standard streams are "basic" streams, not FD-STREAMs; they
      ;; know their descriptor (a string stream answers -1).
      #+ccl (let ((fd (ignore-errors
                       (ccl::stream-device stream (if (output-stream-p stream)
                                                      :output
                                                      :input)))))
              (and (integerp fd) (>= fd 0)))
      #-(or sbcl ccl) t))

(defun %child-stream (stream)
  "The uiop:run-program designator giving the clautolisp child STREAM: the
inherited descriptor (:INTERACTIVE) for a process stream, else STREAM itself
(uiop copies it)."
  (if (%process-stream-p stream) :interactive stream))

(defun %subprocess-needs-terminal-p (session plan)
  "True when the child must have alfe's terminal rather than captured pipes:
an interactive session in PLAN, a debugger the options start, or a --dcl renderer that draws on the
terminal (ncurses) or talks to a GUI driver (gui)."
  (or (some (lambda (action) (eq (action-kind action) :interactive)) plan)
      (member (clautolisp-subprocess-session-dcl session) '(:gui :ncurses))
      ;; The debugger options start a debugger in the child (a DBG> prompt,
      ;; the aldb connect prompt, stdio RPC): it talks to the user.
      (clautolisp-subprocess-session-debugger-session-p session)))

(defun %wait-for-engine-child (session process &optional (wait #'uiop:wait-process))
  "Wait for the engine child PROCESS of SESSION to exit -- by calling WAIT on
it, UIOP:WAIT-PROCESS by default -- and return its status. While it runs,
Control-C belongs to the CHILD, which applies its own --on-interrupt policy
(the subprocess variant forwards that option): alfe's handler does not die of
it, and passes the signal on only when the terminal did not deliver it -- the
child is in another process group (its input is not alfe's terminal); a child
sharing alfe's group got it already, and a second one would read as a second
Control-C. PROCESS is the session's PROCESS-INFO meanwhile, so a :INTERRUPT
control request reaches it. A child still running when the wait is left
non-locally (a plug-in hook failed at an action boundary) is terminated."
  (let ((pid (ignore-errors (uiop:process-info-pid process))))
    (setf (clautolisp-subprocess-session-process-info session) process)
    (unwind-protect
         (clautolisp.autolisp-cli:call-with-sigint-handler
          (lambda ()
            (when pid
              (ignore-errors (clautolisp.autolisp-cli:forward-sigint pid))))
          (lambda () (funcall wait process)))
      (when (ignore-errors (uiop:process-alive-p process))
        (ignore-errors (uiop:terminate-process process :urgent t))
        (ignore-errors (uiop:wait-process process)))
      (setf (clautolisp-subprocess-session-process-info session) nil))))

(defun %wait-at-action-boundaries (process directory on-boundary)
  "Wait for the child PROCESS, run with --front-end-action-boundaries
DIRECTORY, to exit; return its status. Each boundary marker it publishes, in
order -- action 1 :pre, action 1 :post, action 2 :pre, ... -- is read and
handed to ON-BOUNDARY (its plist), then acknowledged, which lets the child go
on (CLAUTOLISP.AUTOLISP-CLI:REPORT-ACTION-BOUNDARY is the other side)."
  (let ((index 1)
        (phase :pre))
    (loop
      (let ((marker (clautolisp.autolisp-cli:action-boundary-pathname
                     directory index phase)))
        (cond ((probe-file marker)
               (funcall on-boundary
                        (clautolisp.autolisp-cli:read-action-boundary marker))
               (clautolisp.autolisp-cli:acknowledge-action-boundary
                directory index phase)
               (if (eq phase :pre)
                   (setf phase :post)
                   (setf phase :pre
                         index (1+ index))))
              ;; A child waits at each marker for its reply, so one that has
              ;; exited left none unanswered.
              ((not (uiop:process-alive-p process))
               (return (uiop:wait-process process)))
              (t
               (sleep clautolisp.autolisp-cli:*action-boundary-poll-interval*)))))))

(defun %temporary-file (name)
  (uiop:tmpize-pathname (merge-pathnames name (uiop:temporary-directory))))

(defun %copy-stream-to-file (stream path)
  (with-open-file (out path :direction :output :if-exists :supersede
                            :external-format uiop:*utf-8-external-format*)
    (loop for line = (read-line stream nil nil)
          while line do (write-line line out))))

(defun %file-text-from (path start external-format)
  "The text of the file at PATH from character START on (\"\" when there is no
such file)."
  (let ((text (if (probe-file path)
                  (uiop:read-file-string path :external-format external-format)
                  "")))
    (if (< start (length text)) (subseq text start) "")))

(defun %run-engine-child (session argv &key terminal external-format
                                            action-boundaries on-boundary)
  "Run the engine ARGV to completion, the way uiop:run-program would, but
through LAUNCH-PROGRAM, so alfe knows the child while it runs (Control-C, see
%WAIT-FOR-ENGINE-CHILD). The child reads alfe's standard input -- the
descriptor itself when it is a process stream, else a copy of what the stream
holds. TERMINAL: the child writes to alfe's own output and error streams
(inherited when they are process streams) and nothing is captured. Otherwise
its output and error output are captured in EXTERNAL-FORMAT (the default when
NIL). What the child writes to a stream it does not inherit is echoed to
alfe's: at each action boundary and when it exits.

ACTION-BOUNDARIES is the directory ARGV passes as --front-end-action-
boundaries, or NIL. ON-BOUNDARY is then called at each boundary, before the
child goes on, with the marker's plist and what the child wrote to its output
and error output since the previous boundary.

Returns (VALUES STDOUT STDERR EXIT-CODE STDOUT-TAIL STDERR-TAIL): STDOUT /
STDERR the whole text (NIL under TERMINAL), the tails what came after the last
boundary."
  (finish-output *standard-output*)
  (finish-output *error-output*)
  (let* ((format (or external-format uiop:*utf-8-external-format*))
         (in-file (unless (%process-stream-p *standard-input*)
                    (let ((path (%temporary-file "alfe-engine-stdin.txt")))
                      (%copy-stream-to-file *standard-input* path)
                      path)))
         (input (or in-file :interactive))
         (out-file (%temporary-file "alfe-engine-stdout.txt"))
         (err-file (%temporary-file "alfe-engine-stderr.txt"))
         (out-inherit (and terminal (%process-stream-p *standard-output*)))
         (err-inherit (and terminal (%process-stream-p *error-output*)))
         (out-seen 0)
         (err-seen 0))
    (flet ((take-new-output ()
             ;; What the child wrote since the last call, echoed to alfe's
             ;; streams.
             (let ((out (if out-inherit "" (%file-text-from out-file out-seen format)))
                   (err (if err-inherit "" (%file-text-from err-file err-seen format))))
               (incf out-seen (length out))
               (incf err-seen (length err))
               (write-string out *standard-output*)
               (write-string err *error-output*)
               (finish-output *standard-output*)
               (finish-output *error-output*)
               (values out err))))
      (unwind-protect
           (let ((code (%wait-for-engine-child
                        session
                        (uiop:launch-program
                         argv
                         :input input
                         :output (if out-inherit :interactive out-file)
                         :if-output-exists :supersede
                         :error-output (if err-inherit :interactive err-file)
                         :if-error-output-exists :supersede
                         :external-format format)
                        (if action-boundaries
                            (lambda (process)
                              (%wait-at-action-boundaries
                               process action-boundaries
                               (lambda (marker)
                                 (multiple-value-bind (out err) (take-new-output)
                                   (funcall on-boundary marker out err)))))
                            #'uiop:wait-process))))
             (multiple-value-bind (out-tail err-tail) (take-new-output)
               (values (unless (or terminal out-inherit)
                         (uiop:read-file-string out-file :external-format format))
                       (unless (or terminal err-inherit)
                         (uiop:read-file-string err-file :external-format format))
                       code
                       out-tail
                       err-tail)))
        (dolist (file (list in-file out-file err-file))
          (when file (ignore-errors (delete-file file))))))))

(defun %make-action-boundaries-directory (session)
  "A fresh, empty directory for the action boundaries of one run of SESSION:
in its workdir when it has one, else a temporary one."
  (let* ((workdir (session-workdir session))
         (directory
           (uiop:ensure-directory-pathname
            (if workdir
                (merge-pathnames "action-boundaries/"
                                 (uiop:ensure-directory-pathname workdir))
                (merge-pathnames
                 (format nil "alfe-action-boundaries-~36R/"
                         (random (expt 36 10) (make-random-state t)))
                 (uiop:temporary-directory))))))
    (uiop:delete-directory-tree directory :validate t :if-does-not-exist :ignore)
    (ensure-directories-exist directory)
    directory))

(defun %subprocess-eval-plan (session plan front-end-bindings-file
                              before-action after-action)
  "EVAL-PLAN of the subprocess variant; with BEFORE-ACTION / AFTER-ACTION (see
EVAL-PLAN-WITH-ACTION-HOOKS), called at the action boundaries the child
reports (--front-end-action-boundaries), while it waits: one child for the
whole plan, so the run is the one EVAL-PLAN makes without them.

The child's boundaries are its own actions, in the order it runs them: the
-l / -x of %CHILD-PLAN, then its REPL. They are mapped back onto the plan's
actions (a -l / -x / --main in plan order, the :INTERACTIVE), the no-op -x \"\"
of an action-less plan onto none. A :QUIT has no counterpart in the child: its
hooks are called when the child has run every action it was given, as the
in-process engine reaches the :QUIT after the last one."
  (session-state-set session :running)
  (let* ((hooks-p (or before-action after-action))
         (boundaries (and hooks-p (%make-action-boundaries-directory session)))
         (argv (build-subprocess-argv session plan
                                      :front-end-bindings-file
                                      front-end-bindings-file
                                      :action-boundaries boundaries))
         (child-plan (%child-plan plan))
         ;; (ACTION . INDEX) of the plan's actions the child runs as -l / -x.
         (queue (loop for action in child-plan
                      for index from 1
                      when (member (action-kind action) '(:load :eval :main))
                        collect (cons action index)))
         (repl (loop for action in child-plan
                     for index from 1
                     when (eq (action-kind action) :interactive)
                       return (cons action index)))
         ;; How many actions the child runs: its -l / -x (or the no-op -x
         ;; ""), then the REPL.
         (child-action-count (+ (max 1 (length queue)) (if repl 1 0)))
         (quit (let ((position (position :quit plan :key #'action-kind)))
                 (and position (cons (nth position plan) (1+ position)))))
         (posts 0)
         (current nil)
         (hook-failure nil)
         (captured-stdout (make-string-output-stream))
         (captured-stderr (make-string-output-stream))
         (status :success)
         (exit-status nil))
    (when (and repl (null queue))
      ;; -i alone: no no-op -x "" was added.
      (setf child-action-count 1))
    (labels ((call-hook (function &rest arguments)
               (when function
                 (apply #'%call-action-hook function arguments)))
             (on-boundary (marker out err)
               (ecase (getf marker :phase)
                 (:pre
                  ;; What came before the action is not the action's.
                  (setf current (case (getf marker :kind)
                                  ((:file :expression) (pop queue))
                                  (:interactive repl)
                                  (t nil)))
                  (when current
                    (call-hook before-action (car current) (cdr current))))
                 (:post
                  (incf posts)
                  (when current
                    (call-hook after-action (car current) (cdr current)
                               (%action-result (getf marker :status)
                                               (getf marker :value)
                                               out err)))
                  (setf current nil)))))
      (log-debug "backend CLAUTOLISP (subprocess): launching: ~{~A~^ ~}" argv)
      (unwind-protect
           (handler-case
               (%with-action-hook-failures (hook-failure)
                 (multiple-value-bind (stdout stderr exit-code out-tail err-tail)
                     (%run-engine-child
                      session argv
                      :terminal (%subprocess-needs-terminal-p session plan)
                      :external-format (%subprocess-capture-external-format session)
                      :action-boundaries boundaries
                      :on-boundary #'on-boundary)
                   (log-verbose "backend CLAUTOLISP (subprocess): exit ~A" exit-code)
                   ;; Already echoed live by %RUN-ENGINE-CHILD.
                   (write-string (or stdout "") captured-stdout)
                   (write-string (or stderr "") captured-stderr)
                   ;; The child's status is the engine's: (exit N), a file error's
                   ;; EX_NOINPUT -- passed on, as the direct variant does.
                   (setf exit-status exit-code)
                   (unless (zerop exit-code)
                     (setf status :failed))
                   (cond
                     ;; The child ended inside an action (an error, (exit N)).
                     (current
                      (call-hook after-action (car current) (cdr current)
                                 (%action-result exit-code nil out-tail err-tail)))
                     ;; It ran every action it was given: the plan's :QUIT.
                     ((and hooks-p quit (= posts child-action-count))
                      (call-hook before-action (car quit) (cdr quit))
                      (call-hook after-action (car quit) (cdr quit)
                                 (%action-result exit-code nil out-tail err-tail))))))
             ;; The child could not be started: an operating-system failure
             ;; (cannot fork / exec), EX_OSERR.
             (error (probe)
               (setf status :failed
                     exit-status clautolisp.sysexits:+ex-oserr+)
               (format captured-stderr "subprocess launch failed: ~A~%" probe)
               (format *error-output* "alfe: subprocess launch failed: ~A~%" probe)))
        (when boundaries
          (ignore-errors
           (uiop:delete-directory-tree boundaries :validate t
                                                  :if-does-not-exist :ignore)))))
    (session-state-set session :done)
    (when hook-failure
      (error hook-failure))
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
       :exit-code exit-status
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
