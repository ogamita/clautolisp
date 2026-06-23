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
                #:null-host
                #:*null-host*)
  (:import-from #:clautolisp.autolisp-mock-host
                #:make-mock-host)
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
  "Map an alfe dialect keyword (:strict / :autocad-2026 / :bricscad-v26
/ :clautolisp) to a clautolisp.autolisp-reader dialect descriptor.
:clautolisp is an alias for :strict — see the comment in
tools/clautolisp/source/main.lisp's argument parser."
  (case dialect-keyword
    (:strict        (autolisp-dialect-strict))
    (:clautolisp    (autolisp-dialect-strict))
    (:autocad-2026  (autolisp-dialect-autocad-2026))
    (:bricscad-v26  (autolisp-dialect-bricscad-v26))
    (otherwise
     (or (find-autolisp-dialect dialect-keyword)
         (error 'backend-bootstrap-error
                :backend :clautolisp
                :code :unknown-dialect
                :message (format nil "Unknown clautolisp dialect ~S"
                                 dialect-keyword)
                :details (list :dialect dialect-keyword))))))

(defun resolve-clautolisp-host (host-keyword)
  "Map an alfe host keyword (:mock / :null) to the HAL backend
instance the clautolisp runtime expects. Defaults to a fresh
MockHost when unspecified — same default as the standalone
clautolisp executable."
  (case host-keyword
    ((nil :mock) (make-mock-host))
    (:null       *null-host*)
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
DETECT fills it in by probing $PATH and the well-known relative
location next to this checkout (tools/clautolisp/bin/clautolisp-sbcl)."))
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

(defun walk-path-for (binary-name)
  "Walk $PATH for BINARY-NAME and return the first absolute path that
exists, or NIL. uiop's portable helpers don't expose a PATH walker on
every supported Lisp; doing it inline keeps the dependency surface
narrow."
  (let ((path (uiop:getenv "PATH")))
    (when path
      (dolist (dir (uiop:split-string path :separator '(#\:)))
        (let ((candidate (merge-pathnames binary-name
                                          (uiop:ensure-directory-pathname dir))))
          (when (probe-file candidate)
            (return-from walk-path-for (namestring candidate))))))))

(defun candidate-clautolisp-binaries ()
  "Where to look for clautolisp-sbcl, in priority order. The first
existing file wins. Used by DETECT for the :subprocess variant."
  (let ((from-env (uiop:getenv "ALFE_CLAUTOLISP_BIN")))
    (remove nil
            (list
             (when (and from-env (plusp (length from-env))) from-env)
             *checkout-sibling-clautolisp*
             (walk-path-for "clautolisp-sbcl")
             "/usr/local/bin/clautolisp-sbcl"))))

(defmethod detect ((backend clautolisp-backend) &key)
  ;; The :direct variant is always available — alfe is itself a
  ;; clautolisp host. For the :subprocess variant we probe for the
  ;; executable and remember its absolute path for START-ENGINE.
  (ecase (clautolisp-backend-variant backend)
    (:direct backend)
    (:subprocess
     (let ((found nil))
       (dolist (candidate (candidate-clautolisp-binaries))
         (when (and candidate
                    (probe-file candidate))
           (setf found (namestring (truename candidate)))
           (return)))
       (unless found
         (error 'backend-not-available
                :backend :clautolisp
                :code :no-subprocess-binary
                :message
                (format nil "clautolisp-sbcl not found (looked in ~{~A~^, ~})"
                        (candidate-clautolisp-binaries))
                :details
                (list :candidates (candidate-clautolisp-binaries))))
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
to NIL on completion. HOST is the alfe host keyword (:mock/:null)
resolved at START-ENGINE time."
  (process-info nil)
  (host         nil)
  (output-file  nil)
  (errors-file  nil)
  ;; User-supplied `-e ENC' string, forwarded as the subprocess
  ;; argv's `-e ENC' so the spawned engine reads source files in
  ;; the same encoding. NIL when the user did not pass `-e'.
  (load-encoding nil))

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
                              bootstrap-phase interactive-p
                              load-encoding io-encoding
                              cli-options version-text)
  ;; INTERACTIVE-P is forwarded to start-subprocess-engine below; the
  ;; direct branch doesn't use it (the REPL is opened by EVAL-PLAN
  ;; when the action plan carries an :interactive action). MOCK-INPUT
  ;; and BOOTSTRAP-PHASE are reserved for future tickets.
  ;;
  ;; LOAD-ENCODING is the user's `-e ENC' string (utf-8 / iso-8859-1
  ;; / latin-1 / windows-1252 / cp1252). The direct variant installs
  ;; it on the runtime session so every load — including nested
  ;; (load …) from a user init file — uses it instead of the dialect
  ;; default. The subprocess variant forwards it as `-e ENC' to the
  ;; spawned clautolisp-sbcl binary's CLI.
  ;;
  ;; CLI-OPTIONS is the alfe-side cli-options struct; the direct
  ;; variant uses it to install the *AUTOLISP-…* globals in the
  ;; freshly created runtime context (transmit-options.issue). The
  ;; subprocess variant ignores it — the spawned clautolisp-sbcl
  ;; installs its own from argv.
  (declare (ignore mock-input bootstrap-phase io-encoding))
  (ecase (clautolisp-backend-variant backend)
    (:direct
     (handler-case
         (let* ((dialect-struct (resolve-clautolisp-dialect dialect))
                (host-instance  (resolve-clautolisp-host host))
                (context        (make-default-runtime-context
                                 :dialect dialect-struct))
                (session-handle (evaluation-context-session context)))
           (set-runtime-session-host session-handle host-instance)
           (install-core-builtins)
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
           ;;   `-e ENC' (LOAD-ENCODING) > LC_ALL/LC_CTYPE/LANG > NIL.
           ;; NIL falls through to the dialect default at load time.
           (let ((effective
                   (or (and load-encoding (encoding-keyword load-encoding))
                       (clautolisp.autolisp-runtime:locale-default-source-encoding))))
             (when effective
               (clautolisp.autolisp-runtime:set-default-source-encoding
                context effective)))
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
                              :interactive-p interactive-p
                              :load-encoding load-encoding))))

;;; --- START-ENGINE: subprocess variant ------------------------------

(defun dialect-cli-name (dialect-keyword)
  "Render the alfe dialect keyword in the form clautolisp-sbcl's CLI
parser accepts. Mirrors the option names in
tools/clautolisp/source/main.lisp."
  (case dialect-keyword
    (:strict        "strict")
    (:clautolisp    "strict")
    (:autocad-2026  "autocad-2026")
    (:bricscad-v26  "bricscad-v26")
    (otherwise      "strict")))

(defun start-subprocess-engine (backend workdir &key dialect host interactive-p
                                load-encoding)
  ;; The Phase 1 subprocess variant defers the actual fork to
  ;; EVAL-PLAN so we can map every action to a clautolisp-sbcl CLI
  ;; flag and run the engine *once* with the right argv (rather than
  ;; piping forms through stdin and framing each value's output with
  ;; sentinels — that's the harder design the issue describes as
  ;; the v2 path). START-ENGINE just stashes the binary path and
  ;; the engine flags it has resolved so far.
  ;;
  ;; LOAD-ENCODING is stashed in the session so EVAL-PLAN below can
  ;; forward it as `-e ENC' to the spawned clautolisp-sbcl invocation.
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
                    :load-encoding load-encoding)))
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
  (clautolisp.autolisp-cli:encoding-keyword encoding-string "-e"))

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

(defun build-subprocess-argv (session plan)
  "Compose the clautolisp-sbcl argv from SESSION's per-engine flags
plus one flag pair per action in PLAN. Used by EVAL-PLAN on the
subprocess variant."
  (let* ((backend (session-backend session))
         (binary  (clautolisp-backend-executable-path backend))
         (dialect (session-dialect session))
         (host    (clautolisp-subprocess-session-host session))
         (host-name (case host
                      (:null "null")
                      ((nil :mock) "mock")
                      (otherwise (string-downcase (symbol-name host))))))
    (append (list binary
                  "--quiet"
                  "--dialect" (dialect-cli-name dialect)
                  "--host"    host-name)
            ;; Forward the user's `-e ENC' so the spawned
            ;; clautolisp-sbcl reads source files in the same
            ;; encoding the user asked alfe for. Placed BEFORE the
            ;; action flags so it's in effect from the very first
            ;; -l/-x in the queue.
            (let ((enc (clautolisp-subprocess-session-load-encoding session)))
              (when enc (list "-e" enc)))
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
            (uiop:run-program argv
                              :output :string
                              :error-output :string
                              :ignore-error-status t)
          (log-verbose "backend CLAUTOLISP (subprocess): exit ~A" exit-code)
          (write-string stdout captured-stdout)
          (write-string stderr captured-stderr)
          ;; Echo live, same contract as the direct variant.
          (write-string stdout *standard-output*)
          (write-string stderr *error-output*)
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
