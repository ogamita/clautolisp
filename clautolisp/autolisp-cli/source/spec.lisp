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

;;; --- encoding SITUATIONS + the -E<situation> option family -----------
;;;
;;; See issues/open/encoding-situations-cli-options.issue. The old generic
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

(defun %encoding-dir-long (dir)
  (cond ((string= dir "in") "input") ((string= dir "out") "output") (t dir)))

(defun %encoding-store (opts key canon)
  "Record encoding CANON under KEY (\"all\" | \"<name>\" | \"<name>/<dir>\")
in OPTS's situation table, and mirror the two legacy slots so existing
downstream keeps working: source -> load-encoding, terminal -> io-encoding."
  (push (cons key canon) (cli-options-situation-encodings opts))
  (cond ((string= key "source")   (setf (cli-options-load-encoding opts) canon))
        ((string= key "terminal") (setf (cli-options-io-encoding opts) canon))))

(defun cli-situation-encoding (opts situation &optional direction)
  "The user-requested encoding for SITUATION (and optional DIRECTION), by
precedence: the specific <name>/<dir> override, then <name> (both
directions), then the bare \"all\"; NIL when nothing was set (the caller
then falls through to the variable/fixed default for that boundary)."
  (let ((tbl (cli-options-situation-encodings opts)))
    (or (and direction
             (cdr (assoc (format nil "~A/~A" situation direction) tbl :test #'string=)))
        (cdr (assoc situation tbl :test #'string=))
        (cdr (assoc "all" tbl :test #'string=)))))

(defun %encoding-option-specs ()
  "Generate the -E<situation>[-<dir>] / --<situation>[-<longdir>]-encoding
family + the bare -E/--encoding (sets every situation)."
  (let ((specs (list
                (make-option-spec
                 :longs '("--encoding") :shorts '("-E") :takes-arg-p t
                 :handler (lambda (opts value name)
                            (%encoding-store
                             opts "all"
                             (canonical-encoding-name value (or name "-E"))))))))
    (dolist (sit *encoding-situations* (nreverse specs))
      (destructuring-bind (name . dirs) sit
        (push (make-option-spec
               :longs (list (format nil "--~A-encoding" name))
               :shorts (list (format nil "-E~A" name)) :takes-arg-p t
               :handler (let ((k name))
                          (lambda (opts value nm)
                            (%encoding-store
                             opts k (canonical-encoding-name
                                     value (or nm (format nil "-E~A" k)))))))
              specs)
        (dolist (dir dirs)
          (push (make-option-spec
                 :longs (list (format nil "--~A-~A-encoding" name (%encoding-dir-long dir)))
                 :shorts (list (format nil "-E~A-~A" name dir)) :takes-arg-p t
                 :handler (let ((k (format nil "~A/~A" name dir)))
                            (lambda (opts value nm)
                              (%encoding-store
                               opts k (canonical-encoding-name value (or nm k))))))
                specs))))))

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
               (setf (cli-options-no-color-p opts) t)))))

(defparameter *common-option-specs*
  (append (%make-common-option-specs) (%encoding-option-specs))
  "The intersection of CLI options accepted by both clautolisp and
alfe. Each tool builds its full spec list by appending its
tool-specific specs (alfe's --mode/--backend/--dwg/--epure/etc.;
clautolisp's --mock-input/--gui/--trace). Tools may also append
duplicate handlers — the first match wins, so prepending a custom
handler replaces the common one without removing it.")
