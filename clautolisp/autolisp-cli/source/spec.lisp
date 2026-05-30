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
  (handler nil :type (or null function)))

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
    :handler (lambda (opts value name)
               (declare (ignore value name))
               (raise-verbosity opts :warn)))
   (make-option-spec
    :longs '("--verbose") :shorts '("-v") :takes-arg-p nil
    :handler (lambda (opts value name)
               (declare (ignore value name))
               (raise-verbosity opts :verbose)))
   (make-option-spec
    :longs '("--debug") :shorts '("-d") :takes-arg-p nil
    :handler (lambda (opts value name)
               (declare (ignore value name))
               (raise-verbosity opts :debug)))

   ;; --- dialect ---------------------------------------------------
   (make-option-spec
    :longs '("--dialect") :shorts nil :takes-arg-p t
    :handler (lambda (opts value name)
               (setf (cli-options-dialect opts)
                     (parse-dialect value name))))
   (make-option-spec
    :longs '("--strict") :shorts nil :takes-arg-p nil
    :handler (lambda (opts value name)
               (declare (ignore value name))
               (setf (cli-options-dialect opts) :strict)))
   (make-option-spec
    :longs '("--autocad") :shorts nil :takes-arg-p nil
    :handler (lambda (opts value name)
               (declare (ignore value name))
               (setf (cli-options-dialect opts) :autocad-2026
                     (cli-options-backend opts) :autocad)))
   (make-option-spec
    :longs '("--bricscad") :shorts nil :takes-arg-p nil
    :handler (lambda (opts value name)
               (declare (ignore value name))
               (setf (cli-options-dialect opts) :bricscad-v26
                     (cli-options-backend opts) :bricscad)))
   (make-option-spec
    :longs '("--clautolisp") :shorts nil :takes-arg-p nil
    :handler (lambda (opts value name)
               (declare (ignore value name))
               (setf (cli-options-dialect opts) :clautolisp
                     (cli-options-backend opts) :clautolisp)))
   (make-option-spec
    :longs '("--lax") :shorts nil :takes-arg-p nil
    :handler (lambda (opts value name)
               (declare (ignore value name))
               (setf (cli-options-dialect opts) :lax)))

   ;; --- host ------------------------------------------------------
   (make-option-spec
    :longs '("--host") :shorts nil :takes-arg-p t
    :handler (lambda (opts value name)
               (setf (cli-options-host opts) (parse-host value name))))

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
   ;; -e ENC and -E ENC validate the value at parse time via the
   ;; shared encoding alias registry (encoding.issue). A typo
   ;; (e.g. `-e uft-8') surfaces here as a cli-usage-error rather
   ;; than later as a cryptic "Undefined external-format" from
   ;; CL OPEN. The canonical spelling is stored on the slot so
   ;; *AUTOLISP-FILE-ENCODING* / *AUTOLISP-TERMINAL-ENCODING* show
   ;; the registered name regardless of which alias the user typed.
   (make-option-spec
    :longs nil :shorts '("-e") :takes-arg-p t
    :handler (lambda (opts value name)
               (setf (cli-options-load-encoding opts)
                     (canonical-encoding-name value (or name "-e")))))
   (make-option-spec
    :longs nil :shorts '("-E") :takes-arg-p t
    :handler (lambda (opts value name)
               (setf (cli-options-io-encoding opts)
                     (canonical-encoding-name value (or name "-E")))))

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
               (setf (cli-options-no-color-p opts) t)))))

(defparameter *common-option-specs* (%make-common-option-specs)
  "The intersection of CLI options accepted by both clautolisp and
alfe. Each tool builds its full spec list by appending its
tool-specific specs (alfe's --mode/--backend/--dwg/--epure/etc.;
clautolisp's --mock-input/--gui/--trace). Tools may also append
duplicate handlers — the first match wins, so prepending a custom
handler replaces the common one without removing it.")
