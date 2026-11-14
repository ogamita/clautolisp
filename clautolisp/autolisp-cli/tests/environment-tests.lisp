(in-package #:clautolisp.autolisp-cli.tests)

(in-suite autolisp-cli-suite)

;;;; Option defaults from the environment (cli-option-environment-defaults).
;;;;
;;;; Every test reads a TABLE, never the process environment: the variables
;;;; are read through *ENVIRONMENT-GETENV*, bound here.

(defun %env-reader (alist)
  (lambda (name)
    (let ((value (cdr (assoc name alist :test #'string=))))
      (and value (plusp (length value)) value))))

(defun %parse-with-environment (argv environment
                                &key (program :clautolisp)
                                     (specs clautolisp.autolisp-cli:*common-option-specs*))
  (let ((clautolisp.autolisp-cli:*environment-getenv* (%env-reader environment)))
    (clautolisp.autolisp-cli:apply-environment-defaults
     (clautolisp.autolisp-cli:parse-arguments-with-spec specs argv)
     specs program)))

(defun %canonical (name)
  (clautolisp.autolisp-cli::canonical-encoding-name name "test"))

;;; --- the table and the specs agree -------------------------------

(test every-environment-group-of-a-spec-is-in-the-table
  (dolist (spec clautolisp.autolisp-cli:*common-option-specs*)
    (let ((group (clautolisp.autolisp-cli:option-spec-environment spec)))
      (when group
        (is (assoc group clautolisp.autolisp-cli:*option-environment-groups*)
            "~S (~A) is not in *OPTION-ENVIRONMENT-GROUPS*"
            group (first (clautolisp.autolisp-cli:option-spec-longs spec)))))))

(test every-shared-group-has-a-common-spec
  ;; --dribble / --dribble-interactors are per-program specs (each program
  ;; records something else); every other shared group is a common option.
  (dolist (entry clautolisp.autolisp-cli:*option-environment-groups*)
    (destructuring-bind (group suffix scope) entry
      (declare (ignore suffix))
      (when (and (eq scope :shared)
                 (not (member group '(:dribble :dribble-interactors))))
        (is (find group clautolisp.autolisp-cli:*common-option-specs*
                  :key #'clautolisp.autolisp-cli:option-spec-environment)
            "no common option spec is in group ~S" group)))))

(test variable-names-per-program
  (is (equal '("CLAUTOLISP_HOST" "AUTOLISP_HOST")
             (clautolisp.autolisp-cli:option-environment-variables :host :clautolisp)))
  (is (equal '("ALFE_HOST" "AUTOLISP_HOST")
             (clautolisp.autolisp-cli:option-environment-variables :host :alfe)))
  (is (equal '("CLAUTOLISP_TRACE")
             (clautolisp.autolisp-cli:option-environment-variables :trace :clautolisp)))
  (is (null (clautolisp.autolisp-cli:option-environment-variables :trace :alfe)))
  (is (equal '("ALFE_CAD")
             (clautolisp.autolisp-cli:option-environment-variables :cad :alfe)))
  (let ((all (clautolisp.autolisp-cli:option-environment-variable-names)))
    (is (member "AUTOLISP_SOURCE_ENCODING" all :test #'string=))
    (is (member "ALFE_TERMINAL_OUT_ENCODING_REPLACEMENT" all :test #'string=))
    (is (= (length all) (length (remove-duplicates all :test #'string=))))))

;;; --- precedence: command line > program variable > AUTOLISP_ > default

(test host-from-environment
  (let ((opts (%parse-with-environment '() '(("AUTOLISP_HOST" . "nihil")))))
    (is (eq :nihil (clautolisp.autolisp-cli:cli-options-host opts)))
    (is (equal "AUTOLISP_HOST"
               (clautolisp.autolisp-cli:option-environment-source opts :host)))))

(test command-line-beats-environment
  (let ((opts (%parse-with-environment '("--host" "cadtui")
                                       '(("AUTOLISP_HOST" . "nihil")
                                         ("CLAUTOLISP_HOST" . "nihil")))))
    (is (eq :cadtui (clautolisp.autolisp-cli:cli-options-host opts)))
    (is (null (clautolisp.autolisp-cli:option-environment-source opts :host)))))

(test program-variable-beats-autolisp-variable
  (let ((env '(("AUTOLISP_HOST" . "nihil") ("CLAUTOLISP_HOST" . "cadtui")
               ("ALFE_HOST" . "cador"))))
    (is (eq :cadtui (clautolisp.autolisp-cli:cli-options-host
                     (%parse-with-environment '() env :program :clautolisp))))
    (is (eq :cador (clautolisp.autolisp-cli:cli-options-host
                    (%parse-with-environment '() env :program :alfe))))))

(test another-programs-variable-is-ignored
  (is (eq :cador (clautolisp.autolisp-cli:cli-options-host
                  (%parse-with-environment '() '(("ALFE_HOST" . "nihil"))
                                           :program :clautolisp)))))

(test empty-variable-is-unset
  (is (eq :nihil (clautolisp.autolisp-cli:cli-options-host
                  (%parse-with-environment '() '(("CLAUTOLISP_HOST" . "")
                                                 ("AUTOLISP_HOST" . "nihil")))))))

(test invalid-value-is-a-usage-error-naming-the-variable
  (handler-case
      (progn (%parse-with-environment '() '(("AUTOLISP_HOST" . "bogus")))
             (fiveam:fail "AUTOLISP_HOST=bogus was accepted"))
    (cli-usage-error (e)
      (is (equal "AUTOLISP_HOST" (clautolisp.autolisp-cli:cli-usage-error-option e))))))

;;; --- groups: any option of the group keeps the variable out ---------

(test dialect-from-environment
  (is (eq :lax (clautolisp.autolisp-cli:cli-options-dialect
                (%parse-with-environment '() '(("AUTOLISP_DIALECT" . "lax")))))))

(test a-dialect-shortcut-keeps-autolisp-dialect-out
  (dolist (argv '(("--strict") ("--lax") ("--dialect" "clautolisp")))
    (is (not (eq :autocad-2026
                 (clautolisp.autolisp-cli:cli-options-dialect
                  (%parse-with-environment argv '(("AUTOLISP_DIALECT" . "autocad-2026"))))))
        "~S" argv))
  (is (eq :strict (clautolisp.autolisp-cli:cli-options-dialect
                   (%parse-with-environment '("--strict")
                                            '(("AUTOLISP_DIALECT" . "lax")))))))

;;; --- verbosity: the variable sets a level, a flag still wins ---------

(test verbosity-from-environment
  (dolist (case '(("quiet" . :warn) ("info" . :info) ("verbose" . :verbose)
                  ("debug" . :debug)))
    (is (eq (cdr case)
            (clautolisp.autolisp-cli:cli-options-verbosity
             (%parse-with-environment '() `(("AUTOLISP_VERBOSITY" . ,(car case))))))
        "AUTOLISP_VERBOSITY=~A" (car case))))

(test a-verbosity-flag-beats-autolisp-verbosity
  ;; The flags compose additively among themselves (the most verbose wins),
  ;; but an environment level is not a flag: -q must not lose to it.
  (is (eq :warn (clautolisp.autolisp-cli:cli-options-verbosity
                 (%parse-with-environment '("-q") '(("AUTOLISP_VERBOSITY" . "debug")))))))

;;; --- encodings: a layer below the whole command line -----------------

(test encoding-variables-set-the-situations
  (let ((opts (%parse-with-environment '() '(("AUTOLISP_SOURCE_ENCODING" . "cp1252")
                                             ("AUTOLISP_ENCODING" . "iso-8859-1")))))
    (is (equal (%canonical "cp1252")
               (clautolisp.autolisp-cli:cli-situation-encoding opts "source")))
    (is (equal (%canonical "cp1252") (clautolisp.autolisp-cli:cli-options-load-encoding opts)))
    (is (equal (%canonical "iso-8859-1")
               (clautolisp.autolisp-cli:cli-situation-encoding opts "file" "read")))))

(test a-bare-e-on-the-command-line-beats-a-specific-variable
  (let ((opts (%parse-with-environment '("-E" "utf-8")
                                       '(("AUTOLISP_SOURCE_ENCODING" . "cp1252")))))
    (is (equal (%canonical "utf-8")
               (clautolisp.autolisp-cli:cli-situation-encoding opts "source")))
    (is (equal (%canonical "utf-8") (clautolisp.autolisp-cli:cli-options-load-encoding opts)))))

(test a-specific-option-beats-the-same-variable
  (let ((opts (%parse-with-environment '("-Efile-read" "utf-8")
                                       '(("AUTOLISP_FILE_READ_ENCODING" . "cp1252")
                                         ("AUTOLISP_FILE_WRITE_ENCODING" . "cp1252")))))
    (is (equal (%canonical "utf-8")
               (clautolisp.autolisp-cli:cli-situation-encoding opts "file" "read")))
    (is (equal (%canonical "cp1252")
               (clautolisp.autolisp-cli:cli-situation-encoding opts "file" "write")))))

(test a-bare-e-does-not-reach-a-named-situation-variable-boundary
  ;; The product-fixed boundaries take only an option or variable that names
  ;; them; AUTOLISP_CONSOLE_ENCODING names the console.
  (let ((opts (%parse-with-environment '("-E" "utf-8")
                                       '(("AUTOLISP_CONSOLE_ENCODING" . "cp1252")))))
    (is (equal (%canonical "cp1252")
               (clautolisp.autolisp-cli:cli-situation-encoding-explicit opts "console" "out")))))

(test replacement-variables-sit-below-the-command-line
  (let ((opts (%parse-with-environment
               '("-Ereplacement" "escape")
               '(("AUTOLISP_FILE_WRITE_ENCODING_REPLACEMENT" . "?")))))
    (is (equal "escape"
               (clautolisp.autolisp-cli:cli-encoding-replacement opts "file/write")))
    ;; The consumer falls back from file/write to the bare policy: the
    ;; specific variable must not shadow the bare option.
    (is (null (clautolisp.autolisp-cli:cli-encoding-replacement-explicit opts "file/write")))
    ;; A driven child is handed the resolved policies.
    (is (equal '("-Ereplacement" "escape")
               (clautolisp.autolisp-cli:encoding-replacement-option-arguments opts))))
  (let ((opts (%parse-with-environment
               '() '(("AUTOLISP_FILE_WRITE_ENCODING_REPLACEMENT" . "?")))))
    (is (equal "?" (clautolisp.autolisp-cli:cli-encoding-replacement opts "file/write")))
    (is (equal '("-Efile-write-replacement" "?")
               (clautolisp.autolisp-cli:encoding-replacement-option-arguments opts)))))

(test invalid-encoding-variable-names-the-variable
  (handler-case
      (progn (%parse-with-environment '() '(("AUTOLISP_SOURCE_ENCODING" . "uft-8")))
             (fiveam:fail "AUTOLISP_SOURCE_ENCODING=uft-8 was accepted"))
    (clautolisp.autolisp-cli:cli-error (e)
      (is (equal "AUTOLISP_SOURCE_ENCODING" (clautolisp.autolisp-cli:cli-error-option e))))))

;;; --- the debugger options and --dcl ---------------------------------

(test debugger-and-dcl-from-environment
  (let ((opts (%parse-with-environment '() '(("AUTOLISP_ON_ERROR" . "quit")
                                             ("AUTOLISP_DEBUGGER_UI" . "dumb")
                                             ("AUTOLISP_DCL" . "tui")
                                             ("AUTOLISP_ALDB_LISTEN" . "4005")))))
    (is (eq :quit (clautolisp.autolisp-cli:cli-options-on-error opts)))
    (is (eq :dumb (clautolisp.autolisp-cli:cli-options-user-interface opts)))
    (is (eq :tui (clautolisp.autolisp-cli:cli-options-dcl opts)))
    (is (not (null (clautolisp.autolisp-cli:cli-options-aldb-port opts))))))

;;; --- boolean and optional-value options ------------------------------

(defun %flag-specs ()
  "A boolean flag and an optional-value option in groups the table knows, as
the programs define them (--trace, --dribble)."
  (list (clautolisp.autolisp-cli:make-option-spec
         :longs '("--trace") :takes-arg-p nil :environment :trace
         :handler (lambda (opts value name)
                    (declare (ignore value name))
                    (setf (clautolisp.autolisp-cli:cli-options-trace-p opts) t)))
        (clautolisp.autolisp-cli:make-option-spec
         :longs '("--dribble") :takes-arg-p t :optional-arg-p t :environment :dribble
         :handler (lambda (opts value name)
                    (declare (ignore name))
                    (setf (clautolisp.autolisp-cli:cli-options-dribble opts) (or value t))))))

(test boolean-variables
  (flet ((trace-p (value)
           (clautolisp.autolisp-cli:cli-options-trace-p
            (%parse-with-environment '() `(("CLAUTOLISP_TRACE" . ,value))
                                     :specs (%flag-specs)))))
    (is (eq t (trace-p "1")))
    (is (eq t (trace-p "yes")))
    (is (null (trace-p "0")))
    (is (null (trace-p "off")))
    (signals cli-usage-error (trace-p "maybe"))))

(test optional-value-variables
  (flet ((dribble-value (value)
           (clautolisp.autolisp-cli:cli-options-dribble
            (%parse-with-environment '() `(("AUTOLISP_DRIBBLE" . ,value))
                                     :specs (%flag-specs)))))
    (is (eq t (dribble-value "1")))
    (is (null (dribble-value "no")))
    (is (equal "session.dribble" (dribble-value "session.dribble")))))
