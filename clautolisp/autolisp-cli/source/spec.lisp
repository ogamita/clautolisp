(in-package #:clautolisp.autolisp-cli)

;;;; Option-spec datum + common option set shared by clautolisp and alfe.
;;;;
;;;; An option-spec describes one CLI option:
;;;;   LONGS         — list of long-option strings ("--load", "--ld"). May be ().
;;;;   SHORTS        — list of short-option strings ("-l", "-L"). May be ().
;;;;   TAKES-ARG-P   — true iff the option consumes a following value.
;;;;   HANDLER       — (lambda (cli-options value option-name) …) mutates
;;;;                   cli-options. VALUE is the consumed argument when
;;;;                   TAKES-ARG-P, nil otherwise. OPTION-NAME is the long
;;;;                   or short form actually seen (for error messages).
;;;;
;;;; The parser walks argv, dispatches by exact string match to the
;;;; first spec whose LONGS or SHORTS list contains the argument, and
;;;; invokes its HANDLER.
;;;;
;;;; *COMMON-OPTION-SPECS* is the intersection: everything both
;;;; clautolisp and alfe accept. Each tool prepends or appends its own
;;;; tool-specific specs.

(defstruct option-spec
  (longs nil :type list)
  (shorts nil :type list)
  (takes-arg-p nil :type boolean)
  ;; When TAKES-ARG-P and OPTIONAL-ARG-P are both true the option's
  ;; value comes ONLY from the `--opt=VALUE` embedded form; a bare
  ;; `--opt` does not consume the following argv element and the
  ;; handler receives VALUE = nil (e.g. `--dribble` / `--dribble=FILE`).
  (optional-arg-p nil :type boolean)
  (handler nil :type (or null function))
  ;; The option GROUP this spec belongs to for environment defaults
  ;; (*OPTION-ENVIRONMENT-GROUPS*, environment.lisp), or NIL: an option with
  ;; no environment variable. Every spec of a group marks the group as given
  ;; on the command line (--strict as much as --dialect suppresses
  ;; AUTOLISP_DIALECT).
  (environment nil :type symbol)
  ;; How the group's environment value is applied, when the default rule
  ;; (the spec's own HANDLER) will not do: (lambda (opts value variable)).
  (environment-handler nil :type (or null function))
  ;; True when that handler writes a layer BELOW the command line (the
  ;; encodings, -O): it then applies even when the command line set the
  ;; group, the command line still winning.
  (environment-layer-p nil :type boolean))

(defparameter *verbosity-rank*
  '((:debug   . 0)
    (:verbose . 1)
    (:info    . 2)
    (:warn    . 3))
  "Rank table used by RAISE-VERBOSITY: lower rank = more verbose. The
order mirrors alfe.logging's *level-order* (most-verbose-first) so a
:debug request always wins over a :warn (--quiet) request regardless
of CLI argument order. :error is intentionally absent — there is no
flag that requests \"error-only\" output.")

(defun %verbosity-rank (level)
  (or (cdr (assoc level *verbosity-rank*))
      (error "Unknown verbosity level ~S (expected one of ~S)."
             level (mapcar #'car *verbosity-rank*))))

(defun raise-verbosity (opts requested)
  "Update OPTS's verbosity for a freshly-seen --quiet / --verbose /
--debug flag.

Rules, designed to be commutative across flag order:
  1. The default :INFO (no verbosity flag yet seen) gets overridden by
     the first flag, whatever it is — so `--quiet` alone yields :WARN
     and `--verbose` alone yields :VERBOSE, matching the documented
     single-flag semantics.
  2. Once a non-default level is in place, subsequent flags can only
     RAISE verbosity (move toward :DEBUG). So `--quiet --debug` and
     `--debug --quiet` both land on :DEBUG; `--quiet --verbose` and
     `--verbose --quiet` both land on :VERBOSE.

The rationale is that across multiple flags the user's combined intent
is \"show me at least this much detail\" — order-of-appearance must not
suppress output a user explicitly asked for."
  (let ((current (cli-options-verbosity opts)))
    (cond
      ;; First flag overrides the :INFO default outright.
      ((eq current :info)
       (setf (cli-options-verbosity opts) requested))
      ;; Subsequent flags only raise verbosity (lower rank = more
      ;; verbose). Never downgrade away from what an earlier flag
      ;; requested.
      ((< (%verbosity-rank requested)
          (%verbosity-rank current))
       (setf (cli-options-verbosity opts) requested)))))

;;; --- encoding SITUATIONS + the -E<situation> option family -----------
;;;
;;; See issues/closed/encoding-situations-cli-options.issue. The old generic
;;; -e (load) / -E (io) are DROPPED in favour of one option per situation,
;;; generated from this registry. `source' and `terminal' mirror the two
;;; legacy slots (load-encoding / io-encoding) so downstream consumers are
;;; unchanged; the other situations land in the situation-encodings alist
;;; for the plumbing phases to consume.

(defparameter *encoding-situations*
  '(("source"   . ())               ; .lsp/.dcl loaded (all load impls)
    ("file"     . ("read" "write")) ; files the AutoLISP program opens
    ("console"  . ("in" "out"))     ; the CAD's own GUI console device
    ("cadstdio" . ("in" "out"))     ; the CAD subprocess OS stdin/stdout/stderr
    ("log"      . ())               ; the CAD log file
    ("terminal" . ("in" "out")))    ; alfe/clautolisp's own REPL device
  "The character-encoding SITUATIONS. Each is (NAME . DIRECTIONS); empty
DIRECTIONS = single-directional. The CLI has one -E<name>[-<dir>] /
--<name>[-<longdir>]-encoding option per (situation, direction), plus a
bare -E/--encoding that sets them all.")

(defparameter *encoding-situation-notes*
  '(("source"   . "how a .lsp is decoded on load (incl. the CAD's native load)")
    ("file"     . "default encoding of files the program opens")
    ("console"  . "the CAD's own GUI console device (may be product-fixed)")
    ("cadstdio" . "the CAD subprocess stdin/stdout/stderr pipes")
    ("log"      . "the CAD log file")
    ("terminal" . "alfe / clautolisp's own REPL I/O (always settable)"))
  "One-line description per encoding situation, for --list-situations.")

(defparameter *situation-backend-table*
  '((:clautolisp
     ("source"   "settable"        "-Esource / *AUTOLISP-FILE-ENCODING* / LC_*; default UTF-8")
     ("file"     "settable"        "-Efile[-read|-write] -> *AUTOLISP-FILE-READ/WRITE-ENCODING*, OPEN's default")
     ("console"  "= terminal"      "in-process — same stream as terminal: -Econsole[-in|-out] folds into it; -Eterminal wins")
     ("cadstdio" "n/a"             "no CAD subprocess")
     ("log"      "settable"        "-Elog -> the LOGFILEMODE log; default windows-1252 (AutoCAD dialects), else UTF-8")
     ("terminal" "settable"        "-Eterminal — applied to the REPL's own streams"))
    (:bricscad
     ("source"   "locale/BOM"      "UTF-8 with a BOM / locale; -Esource forwarded to the native load")
     ("file"     "default+ccs"     "Windows cp1252, macOS UTF-8; -Efile-write UTF-8/UTF-16LE -> OPEN ,ccs= on Windows (BOM); read never decodes; else warned")
     ("console"  "product-fixed"   "GUI device: macOS full-Unicode, Windows cp1252; -Econsole[-out] = drain codec, -Econsole-in warned and ignored")
     ("cadstdio" "auto / -Ecadstdio" "drain auto-detects; -Ecadstdio overrides")
     ("log"      "product-fixed"   "LOGFILEMODE: windows-1252 or UTF-8+BOM (unsettled); --cad-log decodes a BOM, else windows-1252 on Windows; -Elog overrides")
     ("terminal" "settable"        "-Eterminal — alfe's own stream"))
    (:autocad
     ("source"   "LISPSYS"         "LISPSYS 0=cp1252, 1/2=UTF-8 (restart); -Esource forwarded at 1/2")
     ("file"     "LISPSYS / MBCS"  "writes cp1252 at every LISPSYS; reads cp1252 at 0, UTF-8 else cp1252 at 1/2; OPEN takes no encoding at 0; -Efile-write UTF-8 -> OPEN \"utf8\" at LISPSYS 1/2 (warned at 0, and for \"a\"); -Efile-read warned, not forwarded")
     ("console"  "product-fixed"   "accoreconsole UTF-16LE; -Econsole warned and ignored")
     ("cadstdio" "-Ecadstdio"      "drain: the CAD's file bytes (cp1252, E3), auto-detected; -Ecadstdio forces")
     ("log"      "product-fixed"   "LOGFILEMODE: windows-1252 (measured, AutoCAD 2022); --cad-log decodes it so; -Elog overrides")
     ("terminal" "settable"        "-Eterminal — alfe's own stream")))
  "Per-backend encoding-situation provenance for --list-situations, distilled
from the measured (os × tool × version) findings. Approximate at the CLI
backend level (accoreconsole vs GUI acad, macOS vs Windows differ within a
backend); the full table with byte evidence is the alfe user manual + the
encoding issues.")

(defun print-situations (&key backend (stream *standard-output*))
  "Print the encoding situations — the companion to --list-encodings. With a
BACKEND (:clautolisp / :bricscad / :autocad) print that backend's resolved
default provenance per situation; otherwise print the generic situation list
with directions."
  (let ((rows (cdr (assoc backend *situation-backend-table*))))
    (cond
      (rows
       (format stream "Encoding situations for the ~(~A~) backend ~
(set with -E<situation>[-<dir>] ENC):~%~%" backend)
       (dolist (row rows)
         (destructuring-bind (name provenance note) row
           (format stream "  -E~11A~18A ~A~%" name provenance note)))
       (format stream "~%A product-fixed situation (AutoCAD's console, BricsCAD's console ~
input) still accepts -E<situation> but warns that it is ignored and keeps the product value; a bare ~
-E does not reach it. Full (os × version) defaults with byte evidence: the alfe ~
user-manual Encoding section.~%"))
      (t
       (format stream "Encoding situations — set with -E<situation>[-<dir>] ENC ~
or --<situation>[-<dir>]-encoding ENC~%(a bare -E / --encoding sets them ~
all; --list-situations under a backend flag shows that backend's defaults):~%~%")
       (dolist (row *encoding-situations*)
         (let ((name (car row))
               (dirs (cdr row)))
           (format stream "  -E~11A~13A ~A~%"
                   name
                   (if dirs (format nil "[~{~A~^|~}]" dirs) "")
                   (or (cdr (assoc name *encoding-situation-notes* :test #'string=)) ""))))))
    (values)))

(defun %encoding-dir-long (dir)
  (cond ((string= dir "in") "input") ((string= dir "out") "output") (t dir)))

(defun %encoding-store (opts key canon)
  "Record encoding CANON under KEY (\"all\" | \"<name>\" | \"<name>/<dir>\")
in OPTS's situation table, and recompute the two legacy slots the downstream
reads -- load-encoding (source) and io-encoding (terminal) -- through
CLI-SITUATION-ENCODING, so the bare -E reaches them too, a specific option
winning over it whatever the order (it used to set neither: -E UTF-8 left the
source encoding alone)."
  (push (cons key canon) (cli-options-situation-encodings opts))
  (%refresh-legacy-encoding-slots opts))

(defun %situation-table-lookup (tbl situation direction all-p)
  "SITUATION's encoding in one table: <name>/<dir>, then <name>, then (when
ALL-P) the bare \"all\"."
  (or (and direction
           (cdr (assoc (format nil "~A/~A" situation direction) tbl :test #'string=)))
      (cdr (assoc situation tbl :test #'string=))
      (and all-p (cdr (assoc "all" tbl :test #'string=)))))

(defun cli-situation-encoding (opts situation &optional direction)
  "The user-requested encoding for SITUATION (and optional DIRECTION), by
precedence: the specific <name>/<dir> override, then <name> (both
directions), then the bare \"all\" -- first among the command-line options,
then the same three among the environment variables (AUTOLISP_..._ENCODING,
a layer below the whole command line); NIL when nothing was set (the caller
then falls through to the variable/fixed default for that boundary)."
  (or (%situation-table-lookup (cli-options-situation-encodings opts)
                               situation direction t)
      (%situation-table-lookup (cli-options-environment-situation-encodings opts)
                               situation direction t)))

(defun cli-situation-encoding-explicit (opts situation &optional direction)
  "Like CLI-SITUATION-ENCODING without the bare -E fallback (nor the bare
AUTOLISP_ENCODING): only an option or variable that names SITUATION. For the
boundaries a bare -E must not reach -- a product-fixed device, where a
blanket choice would silently override it."
  (or (%situation-table-lookup (cli-options-situation-encodings opts)
                               situation direction nil)
      (%situation-table-lookup (cli-options-environment-situation-encodings opts)
                               situation direction nil)))

;;; --- environment groups of the encoding options ----------------------
;;;
;;; The -E family is generated, so its environment groups are too: the
;;; group of key "all" is :ENCODING, of "source" :SOURCE-ENCODING, of
;;; "file/write" :FILE-WRITE-ENCODING. *OPTION-ENVIRONMENT-GROUPS*
;;; (environment.lisp) lists each one literally with its variable name, and
;;; a test checks the two agree.

(defun encoding-environment-group (key)
  "The environment group of the encoding option for KEY (\"all\",
\"<situation>\" or \"<situation>/<dir>\")."
  (if (string= key "all")
      :encoding
      (intern (format nil "~:@(~A~)-ENCODING" (substitute #\- #\/ key)) :keyword)))

(defun encoding-replacement-environment-group (key)
  "The environment group of the replacement option for KEY (\"all\",
\"file/write\", \"terminal/out\")."
  (if (string= key "all")
      :encoding-replacement
      (intern (format nil "~:@(~A~)-ENCODING-REPLACEMENT" (substitute #\- #\/ key))
              :keyword)))

(defun %refresh-legacy-encoding-slots (opts)
  "Recompute the two legacy slots the downstream reads -- load-encoding
(source) and io-encoding (terminal) -- from both layers."
  (setf (cli-options-load-encoding opts) (cli-situation-encoding opts "source")
        (cli-options-io-encoding opts) (cli-situation-encoding opts "terminal")))

(defun %encoding-environment-handler (key)
  "The environment handler of the encoding option for KEY: records the
variable's encoding in the environment layer, under KEY."
  (lambda (opts value variable)
    (push (cons key (canonical-encoding-name value variable))
          (cli-options-environment-situation-encodings opts))
    (%refresh-legacy-encoding-slots opts)))

(defun %encoding-option-specs ()
  "Generate the -E<situation>[-<dir>] / --<situation>[-<longdir>]-encoding
family + the bare -E/--encoding (sets every situation)."
  (let ((specs (list
                (make-option-spec
                 :longs '("--encoding") :shorts '("-E") :takes-arg-p t
                 :handler (lambda (opts value name)
                            (%encoding-store
                             opts "all"
                             (canonical-encoding-name value (or name "-E"))))
                 :environment (encoding-environment-group "all")
                 :environment-handler (%encoding-environment-handler "all")
                 :environment-layer-p t))))
    (dolist (sit *encoding-situations* (nreverse specs))
      (destructuring-bind (name . dirs) sit
        (push (make-option-spec
               :longs (list (format nil "--~A-encoding" name))
               :shorts (list (format nil "-E~A" name)) :takes-arg-p t
               :handler (let ((k name))
                          (lambda (opts value nm)
                            (%encoding-store
                             opts k (canonical-encoding-name
                                     value (or nm (format nil "-E~A" k))))))
               :environment (encoding-environment-group name)
               :environment-handler (%encoding-environment-handler name)
               :environment-layer-p t)
              specs)
        (dolist (dir dirs)
          (push (make-option-spec
                 :longs (list (format nil "--~A-~A-encoding" name (%encoding-dir-long dir)))
                 :shorts (list (format nil "-E~A-~A" name dir)) :takes-arg-p t
                 :handler (let ((k (format nil "~A/~A" name dir)))
                            (lambda (opts value nm)
                              (%encoding-store
                               opts k (canonical-encoding-name value (or nm k)))))
                 :environment (encoding-environment-group
                               (format nil "~A/~A" name dir))
                 :environment-handler (%encoding-environment-handler
                                       (format nil "~A/~A" name dir))
                 :environment-layer-p t)
                specs))))))

(defparameter *encoding-replacement-options*
  '(("all"          "--encoding-replacement"                "-Ereplacement")
    ("file/write"   "--file-write-encoding-replacement"     "-Efile-write-replacement")
    ("terminal/out" "--terminal-output-encoding-replacement" "-Eterminal-out-replacement"))
  "The encoding-replacement options (encoding-replacement-character-option):
KEY in the cli-options table, long name, short name. The bare one reaches
every output situation, a specific one wins over it whatever the order.")

(defun %encoding-replacement-store (opts key value option &key environment)
  "Record the replacement policy VALUE (validated, canonical spelling) under
KEY, or signal a usage error naming OPTION. ENVIRONMENT true records it in the
environment layer (an AUTOLISP_..._ENCODING_REPLACEMENT variable), below the
command line."
  (let ((policy (clautolisp.autolisp-runtime:parse-encoding-replacement (or value ""))))
    (when (or (null policy) (eq policy :invalid))
      (error 'cli-usage-error
             :option option
             :message (format nil "~A expects one character, or error, low-byte, ~
best-fit or escape; got ~S" option value)))
    (let ((entry (cons key (clautolisp.autolisp-runtime:encoding-replacement-policy-name
                            policy))))
      (if environment
          (push entry (cli-options-environment-encoding-replacements opts))
          (push entry (cli-options-encoding-replacements opts))))))

(defun %replacement-table-lookup (tbl situation all-p)
  (or (and situation (cdr (assoc situation tbl :test #'string=)))
      (and all-p (cdr (assoc "all" tbl :test #'string=)))))

(defun cli-encoding-replacement (opts &optional situation)
  "The replacement policy name requested for SITUATION (\"file/write\" or
\"terminal/out\"), or for every situation when SITUATION is NIL: the specific
option, else the bare -Ereplacement, then the same two among the environment
variables; NIL when none was given (the dialect default then applies)."
  (or (%replacement-table-lookup (cli-options-encoding-replacements opts) situation t)
      (%replacement-table-lookup (cli-options-environment-encoding-replacements opts)
                                 situation t)))

(defun cli-encoding-replacement-explicit (opts situation)
  "Only the option naming SITUATION (\"all\" for the bare one), or NIL --
then the variable naming it, unless the command line gave the bare
-Ereplacement: the consumer falls back from a specific policy to the bare
one, and the bare option must keep beating a specific variable."
  (let ((command-line (cli-options-encoding-replacements opts)))
    (cond ((assoc situation command-line :test #'string=)
           (cdr (assoc situation command-line :test #'string=)))
          ((and (string/= situation "all")
                (assoc "all" command-line :test #'string=))
           nil)
          (t
           (cdr (assoc situation (cli-options-environment-encoding-replacements opts)
                       :test #'string=))))))

(defun encoding-replacement-option-arguments (opts)
  "The argv fragment that gives a child clautolisp the replacement options of
OPTS, short spellings, in the table's order: (\"-Ereplacement\" \"?\" ...).
It carries the RESOLVED policies -- command line over environment -- since a
driven child ignores the environment: the bare one, then each specific one
that differs from what the child would infer from the bare one."
  (let ((all (cli-encoding-replacement opts nil)))
    (loop for (key nil short) in *encoding-replacement-options*
          for value = (if (string= key "all")
                          all
                          (let ((resolved (cli-encoding-replacement opts key)))
                            (and resolved (not (equal resolved all)) resolved)))
          when value append (list short value))))

(defun %encoding-replacement-option-specs ()
  (loop for (key long short) in *encoding-replacement-options*
        collect (make-option-spec
                 :longs (list long) :shorts (list short) :takes-arg-p t
                 :handler (let ((k key) (default-name short))
                            (lambda (opts value name)
                              (%encoding-replacement-store
                               opts k value (or name default-name))))
                 :environment (encoding-replacement-environment-group key)
                 :environment-handler (let ((k key))
                                        (lambda (opts value variable)
                                          (%encoding-replacement-store
                                           opts k value variable :environment t)))
                 :environment-layer-p t)))

(defun %make-common-option-specs ()
  "Build the common-option-specs list once at load time. Returned as
a fresh list so callers can DESTRUCTIVELY extend it with tool-specific
specs without mutating the shared template."
  (list
   ;; --- informational ---------------------------------------------
   (make-option-spec
    :longs '("--help") :shorts '("-h") :takes-arg-p nil
    :handler (lambda (opts value name)
               (declare (ignore value name))
               (setf (cli-options-help-p opts) t)))
   (make-option-spec
    :longs '("--version") :shorts '("-V") :takes-arg-p nil
    :handler (lambda (opts value name)
               (declare (ignore value name))
               (setf (cli-options-version-p opts) t)))
   ;; --list-encodings dumps the encoding catalogue (mandatory four
   ;; + every encoding the running CL impl exposes) and exits. The
   ;; flag is the same shape as --help / --version: the slot is set
   ;; here, and each tool's main() short-circuits before running
   ;; any user action.
   (make-option-spec
    :longs '("--list-encodings") :takes-arg-p nil
    :handler (lambda (opts value name)
               (declare (ignore value name))
               (setf (cli-options-list-encodings-p opts) t)))
   ;; --list-dialects prints every --dialect name (strict first, lax
   ;; last), one per line, then exits — same short-circuit shape as
   ;; --help / --version / --list-encodings.
   (make-option-spec
    :longs '("--list-dialects") :takes-arg-p nil
    :handler (lambda (opts value name)
               (declare (ignore value name))
               (setf (cli-options-list-dialects-p opts) t)))
   ;; --list-situations prints the encoding situations (and directions),
   ;; then exits — companion to --list-encodings.
   (make-option-spec
    :longs '("--list-situations") :takes-arg-p nil
    :handler (lambda (opts value name)
               (declare (ignore value name))
               (setf (cli-options-list-situations-p opts) t)))
   ;; --list-hosts prints the --host backends with a one-line summary, then
   ;; exits — companion to --host.
   (make-option-spec
    :longs '("--list-hosts") :takes-arg-p nil
    :handler (lambda (opts value name)
               (declare (ignore value name))
               (setf (cli-options-list-hosts-p opts) t)))

   ;; --- verbosity -------------------------------------------------
   ;; The three verbosity flags compose ADDITIVELY: each handler raises
   ;; the level toward the most verbose of (current, requested) and
   ;; never downgrades. So `--debug --verbose`, `--verbose --debug`,
   ;; and even `--quiet --debug` all land on :DEBUG; `--quiet` alone
   ;; (or with no other verbosity flag) yields :WARN. Rationale: the
   ;; user's intent across multiple flags is "show me at least this
   ;; much detail" — order-of-appearance shouldn't suppress output a
   ;; user explicitly asked for.
   (make-option-spec
    :longs '("--quiet") :shorts '("-q") :takes-arg-p nil
    :environment :verbosity
    ;; AUTOLISP_VERBOSITY names a level and SETS it: the additive rule
    ;; below is for flags on one command line, and an environment default
    ;; must not outrank a -q the user typed (it applies only when no
    ;; verbosity flag was given at all).
    :environment-handler (lambda (opts value variable)
                           (setf (cli-options-verbosity opts)
                                 (parse-verbosity value variable)))
    :handler (lambda (opts value name)
               (declare (ignore value name))
               (raise-verbosity opts :warn)))
   (make-option-spec
    :longs '("--verbose") :shorts '("-v") :takes-arg-p nil
    :environment :verbosity
    :handler (lambda (opts value name)
               (declare (ignore value name))
               (raise-verbosity opts :verbose)))
   (make-option-spec
    :longs '("--debug") :shorts '("-d") :takes-arg-p nil
    :environment :verbosity
    :handler (lambda (opts value name)
               (declare (ignore value name))
               (raise-verbosity opts :debug)))

   ;; --- dialect ---------------------------------------------------
   (make-option-spec
    :longs '("--dialect") :shorts nil :takes-arg-p t
    :environment :dialect
    :handler (lambda (opts value name)
               (setf (cli-options-dialect opts)
                     (parse-dialect value name))))
   (make-option-spec
    :longs '("--strict") :shorts nil :takes-arg-p nil
    :environment :dialect
    :handler (lambda (opts value name)
               (declare (ignore value name))
               (setf (cli-options-dialect opts) :strict)))
   (make-option-spec
    :longs '("--autocad") :shorts nil :takes-arg-p nil
    :environment :dialect
    :handler (lambda (opts value name)
               (declare (ignore value name))
               (setf (cli-options-dialect opts) :autocad-2026
                     (cli-options-backend opts) :autocad)))
   (make-option-spec
    :longs '("--bricscad") :shorts nil :takes-arg-p nil
    :environment :dialect
    :handler (lambda (opts value name)
               (declare (ignore value name))
               (setf (cli-options-dialect opts) :bricscad-v26
                     (cli-options-backend opts) :bricscad)))
   (make-option-spec
    :longs '("--clautolisp") :shorts nil :takes-arg-p nil
    :environment :dialect
    :handler (lambda (opts value name)
               (declare (ignore value name))
               (setf (cli-options-dialect opts) :clautolisp
                     (cli-options-backend opts) :clautolisp)))
   (make-option-spec
    :longs '("--lax") :shorts nil :takes-arg-p nil
    :environment :dialect
    :handler (lambda (opts value name)
               (declare (ignore value name))
               (setf (cli-options-dialect opts) :lax)))

   ;; --- host ------------------------------------------------------
   (make-option-spec
    :longs '("--host") :shorts nil :takes-arg-p t
    :environment :host
    :handler (lambda (opts value name)
               (setf (cli-options-host opts) (parse-host value name))))

   ;; --- DCL renderer selection (clautolisp; alfe ignores the slot) --
   ;; --dcl tui|gui|auto picks how a DCL dialog is presented: tui forces
   ;; the terminal / command-line form (clautolisp's spelling of AutoCAD's
   ;; `-command' convention), gui uses the subprocess GUI driver, auto
   ;; (the default) uses the GUI only when a driver is configured AND
   ;; stdout is a TTY, otherwise the TUI.
   (make-option-spec
    :longs '("--dcl") :shorts nil :takes-arg-p t
    :environment :dcl
    :handler (lambda (opts value name)
               (setf (cli-options-dcl opts) (parse-dcl-mode value name))))

   ;; --- drawing -----------------------------------------------------
   ;; The drawing argument: the session's first drawing (clautolisp: in
   ;; place of the untitled Drawing1.dwg; alfe: the drawing the CAD opens).
   ;; alfe has its own --dwg spec ahead of this one.
   (make-option-spec
    :longs '("--dwg") :shorts nil :takes-arg-p t
    :environment :dwg
    :handler (lambda (opts value name)
               (declare (ignore name))
               (setf (cli-options-dwg opts) value)))

   ;; --- actions ---------------------------------------------------
   (make-option-spec
    :longs '("--load") :shorts '("-l") :takes-arg-p t
    :handler (lambda (opts value name)
               (declare (ignore name))
               (setf (cli-options-actions opts)
                     (append (cli-options-actions opts)
                             (list (cons :file value))))))
   (make-option-spec
    :longs '("--eval") :shorts '("-x") :takes-arg-p t
    :handler (lambda (opts value name)
               (declare (ignore name))
               (setf (cli-options-actions opts)
                     (append (cli-options-actions opts)
                             (list (cons :expression value))))))
   (make-option-spec
    :longs '("--interactive") :shorts '("-i") :takes-arg-p nil
    :handler (lambda (opts value name)
               (declare (ignore value name))
               (setf (cli-options-interactive-p opts) t)
               (setf (cli-options-actions opts)
                     (append (cli-options-actions opts)
                             (list (cons :interactive t))))))

   ;; --- encoding --------------------------------------------------
   ;; The encoding options are the generated -E<situation>[-<dir>] /
   ;; --<situation>-encoding family (%ENCODING-OPTION-SPECS, appended to
   ;; *COMMON-OPTION-SPECS* below). The old generic -e/-E were dropped
   ;; (encoding-situations-cli-options.issue). A typo (e.g. `uft-8')
   ;; still surfaces via CANONICAL-ENCODING-NAME as a cli-usage-error.

   ;; --- init files / colour --------------------------------------
   (make-option-spec
    :longs '("--no-init") :shorts '("-norc") :takes-arg-p nil
    :handler (lambda (opts value name)
               (declare (ignore value name))
               (setf (cli-options-no-init-p opts) t)))
   (make-option-spec
    :longs '("--no-color") :shorts nil :takes-arg-p nil
    :handler (lambda (opts value name)
               (declare (ignore value name))
               (setf (cli-options-no-color-p opts) t)))

   ;; --- debugger (aldo) options ---------------------------------
   ;; debugger command reference §10, debugger-public-interface-and-
   ;; on-error.issue Parts B-D. SHARED since the alfe decision of
   ;; 2026-10-06 (pjb): alfe accepts them with the same spelling,
   ;; parsing and semantics -- its clautolisp engine applies them in
   ;; both variants, and alfe refuses the ones a CAD backend cannot honour
   ;; (see DEBUGGER-OPTIONS-FOR-CAD-BACKEND). The slots stay NIL unless
   ;; given: each program applies the context-dependent defaults itself.
   (make-option-spec
    :longs '("--on-error") :shorts nil :takes-arg-p t
    :environment :on-error
    :handler (lambda (opts value name)
               (setf (cli-options-on-error opts) (parse-on-error value name))))
   (make-option-spec
    :longs '("--on-interrupt") :shorts nil :takes-arg-p t
    :environment :on-interrupt
    :handler (lambda (opts value name)
               (setf (cli-options-on-interrupt opts) (parse-on-interrupt value name))))
   (make-option-spec
    :longs '("--on-quit") :shorts nil :takes-arg-p t
    :environment :on-quit
    :handler (lambda (opts value name)
               (setf (cli-options-on-quit opts) (parse-on-quit value name))))
   (make-option-spec
    :longs '("--debugger-ui") :shorts nil :takes-arg-p t
    :environment :debugger-ui
    :handler (lambda (opts value name)
               (setf (cli-options-user-interface opts)
                     (parse-user-interface value name))))
   (make-option-spec
    :longs '("--aldb-listen") :shorts nil :takes-arg-p t
    :environment :aldb-listen
    :handler (lambda (opts value name)
               (multiple-value-bind (host port) (parse-aldb-listen value name)
                 (setf (cli-options-aldb-address opts) host
                       (cli-options-aldb-port opts) port))))
   (make-option-spec
    :longs '("--aldb-stdio") :shorts nil :takes-arg-p nil
    :handler (lambda (opts value name)
               (declare (ignore value name))
               (setf (cli-options-aldb-stdio-p opts) t)))))

(defparameter *common-option-specs*
  (append (%make-common-option-specs) (%encoding-option-specs)
          (%encoding-replacement-option-specs))
  "The intersection of CLI options accepted by both clautolisp and
alfe. Each tool builds its full spec list by appending its
tool-specific specs (alfe's --mode/--backend/--dwg/etc.;
clautolisp's --mock-input/--gui/--trace). The debugger options
(--on-error, --on-interrupt, --on-quit, --debugger-ui, --aldb-listen,
--aldb-stdio) are here too: both programs accept them. Tools may also append
duplicate handlers — the first match wins, so prepending a custom
handler replaces the common one without removing it.")
