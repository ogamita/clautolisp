(in-package #:autolisp-front-end.tests)

(in-suite autolisp-front-end-suite)

;;;; FiveAM tests for alfe.cli. We test PARSE-ARGUMENTS directly
;;;; (it's deliberately pure) and RUN end-to-end against the echo
;;;; backend for the --dry-run, --help, --version, and exit-code
;;;; paths.

;;; --- PARSE-ARGUMENTS: positive cases --------------------------------

(test cli-parses-version-and-help
  "Bare --version / --help flags set the corresponding option slot."
  (is (cli-options-version-p (parse-arguments '("--version"))))
  (is (cli-options-version-p (parse-arguments '("-V"))))
  (is (cli-options-help-p (parse-arguments '("--help"))))
  (is (cli-options-help-p (parse-arguments '("-h")))))

(test cli-parses-backend-selectors
  "Each --bricscad / --autocad / --clautolisp flag pins the backend."
  (is (eq :clautolisp (cli-options-backend (parse-arguments '("--clautolisp")))))
  (is (eq :bricscad   (cli-options-backend (parse-arguments '("--bricscad")))))
  (is (eq :autocad    (cli-options-backend (parse-arguments '("--autocad"))))))

(test cli-conflicting-backends-error
  "Two different backend selectors on the same line trip a usage error."
  (signals cli-usage-error
    (parse-arguments '("--bricscad" "--autocad"))))

(test cli-parses-mode-and-variant
  "--mode and --backend accept both space-separated and =-separated values."
  (is (eq :automation (cli-options-mode (parse-arguments '("--mode" "automation")))))
  (is (eq :automation (cli-options-mode (parse-arguments '("--mode=automation")))))
  ;; The slot accessor is named CLI-OPTIONS-BACKEND-VARIANT to mirror
  ;; the rest of the struct; we have to reach for it via the internal
  ;; symbol since it's not exported.
  (is (eq :attach (alfe.cli::cli-options-backend-variant
                   (parse-arguments '("--backend" "attach"))))))

(test cli-builds-action-plan-in-order
  "Actions appear in the plan in the order they're seen on the CLI."
  (let* ((opts (parse-arguments '("-x" "(+ 1 2)" "-l" "/tmp/foo.lsp" "-x" "(bar)")))
         (actions (cli-options-actions opts)))
    (is (= 3 (length actions)))
    (is (eq :eval (action-kind (first actions))))
    (is (string= "(+ 1 2)" (action-payload (first actions))))
    (is (eq :load (action-kind (second actions))))
    (is (string= "/tmp/foo.lsp" (getf (action-payload (second actions)) :path)))
    (is (eq :eval (action-kind (third actions))))))

(test cli-positional-becomes-load
  "A bare positional argument is treated as an implicit -l for that file."
  (let* ((opts (parse-arguments '("/tmp/script.lsp")))
         (actions (cli-options-actions opts)))
    (is (equal '("/tmp/script.lsp") (cli-options-positional opts)))
    (is (= 1 (length actions)))
    (is (eq :load (action-kind (first actions))))))

(test cli-interactive-and-quit-flags
  "--interactive flips the flag and queues an :interactive action;
--quit does the same with :quit."
  (let ((opts-i (parse-arguments '("-i"))))
    (is (cli-options-interactive-p opts-i))
    (is (find :interactive (cli-options-actions opts-i) :key #'action-kind)))
  (let ((opts-q (parse-arguments '("--quit"))))
    (is (cli-options-quit-p opts-q))
    (is (find :quit (cli-options-actions opts-q) :key #'action-kind))))

(test cli-encoding-flags-stick
  "-e and -E set their respective encoding slots; -l after -e inherits
the load encoding. Per encoding.issue the parser canonicalises the
user's spelling against the shared alias registry, so `-e cp1252'
lands as \"WINDOWS-1252\" (and `-E utf-8' as \"UTF-8\")."
  (let ((opts (parse-arguments '("-e" "cp1252" "-l" "/tmp/x.lsp" "-E" "utf-8"))))
    (is (string= "WINDOWS-1252" (cli-options-load-encoding opts)))
    (is (string= "UTF-8"        (cli-options-io-encoding opts)))
    (let ((action (first (cli-options-actions opts))))
      (is (eq :load (action-kind action)))
      (is (string= "WINDOWS-1252" (getf (action-payload action) :encoding))))))

(test cli-encoding-typo-rejected
  "A typo'd -e value (e.g. `-e uft-8') signals cli-usage-error at
parse time, not later as a cryptic external-format error from
OPEN. Encoding.issue's headline rule. The validator probes the
running CL implementation's external-format registry, so a value
that looks alphanumerically plausible but isn't actually a
recognised encoding still gets caught here."
  (signals cli-usage-error
    (parse-arguments '("-e" "uft-8")))      ; user's exact typo
  (signals cli-usage-error
    (parse-arguments '("-e" "1234not-an-encoding")))
  (signals cli-usage-error
    (parse-arguments '("-E" "/etc/passwd"))))

(test cli-encoding-line-terminator-suffix
  "Line-termination.issue: `-e UTF-8-mac' / `-dos' / `-unix' / -lf /
-cr / -crlf are accepted on top of any base encoding. The slot
keeps the suffix (so *AUTOLISP-FILE-ENCODING* surfaces it
unchanged); the canonical spelling preserves it as documented."
  (dolist (suffix '("-mac" "-dos" "-unix" "-lf" "-cr" "-crlf" "-MAC" "-Dos"))
    (let ((opts (parse-arguments (list "-e" (format nil "UTF-8~A" suffix)))))
      (is (search (string-downcase suffix)
                  (cli-options-load-encoding opts))
          "Suffix ~A preserved in load-encoding slot" suffix)
      (is (search "UTF-8" (cli-options-load-encoding opts))
          "Base UTF-8 preserved alongside ~A" suffix)))
  ;; Same on -E.
  (let ((opts (parse-arguments '("-E" "ISO-8859-1-crlf"))))
    (is (string= "ISO-8859-1-crlf" (cli-options-io-encoding opts))))
  ;; A suffix on a typo still fails — the base is validated.
  (signals cli-usage-error
    (parse-arguments '("-e" "UTF-8-banana")))
  (signals cli-usage-error
    (parse-arguments '("-e" "ftu-8-mac"))))

(test cli-bootstrap-and-host-and-dialect
  "Phase truncation, host, and dialect are routed onto the right slots."
  (let ((opts (parse-arguments '("--bootstrap-phase" "core"
                                 "--host" "null"
                                 "--dialect" "autocad-2026"))))
    (is (eq :core (cli-options-bootstrap-phase opts)))
    (is (eq :null (cli-options-host opts)))
    (is (eq :autocad-2026 (cli-options-dialect opts)))))

(test cli-verbosity-flags-single
  "Each verbosity flag in isolation yields its documented level."
  (is (eq :verbose (cli-options-verbosity (parse-arguments '("-v")))))
  (is (eq :warn    (cli-options-verbosity (parse-arguments '("-q")))))
  (is (eq :debug   (cli-options-verbosity (parse-arguments '("-d"))))))

(test cli-verbosity-flags-additive-and-commutative
  "When more than one verbosity flag is given the most verbose wins,
regardless of CLI argument order — so `--quiet --debug` and
`--debug --quiet` both land on :DEBUG, and `--quiet --verbose` /
`--verbose --quiet` both land on :VERBOSE. This is the new semantics
introduced to replace the original \"last-wins\" behaviour."
  ;; --quiet + --debug, both orders.
  (is (eq :debug   (cli-options-verbosity (parse-arguments '("-q" "-d")))))
  (is (eq :debug   (cli-options-verbosity (parse-arguments '("-d" "-q")))))
  ;; --quiet + --verbose, both orders.
  (is (eq :verbose (cli-options-verbosity (parse-arguments '("-q" "-v")))))
  (is (eq :verbose (cli-options-verbosity (parse-arguments '("-v" "-q")))))
  ;; --verbose + --debug, both orders.
  (is (eq :debug   (cli-options-verbosity (parse-arguments '("-v" "-d")))))
  (is (eq :debug   (cli-options-verbosity (parse-arguments '("-d" "-v")))))
  ;; All three flags — debug still wins regardless of order.
  (is (eq :debug   (cli-options-verbosity (parse-arguments '("-q" "-v" "-d")))))
  (is (eq :debug   (cli-options-verbosity (parse-arguments '("-d" "-v" "-q")))))
  (is (eq :debug   (cli-options-verbosity (parse-arguments '("-v" "-d" "-q"))))))

(test cli-workdir-and-timeout
  "--workdir is verbatim; --timeout parses an integer and rejects junk."
  (let ((opts (parse-arguments '("--workdir" "/tmp/foo" "--timeout" "30"))))
    (is (string= "/tmp/foo" (cli-options-workdir opts)))
    (is (= 30 (cli-options-timeout opts))))
  (signals cli-usage-error
    (parse-arguments '("--timeout" "soon"))))

(test cli-dwg-and-epure-and-noinit
  "Flag-shaped options flip their slots."
  (let ((opts (parse-arguments '("--dwg" "/tmp/foo.dwg" "--epure" "--no-init"))))
    (is (string= "/tmp/foo.dwg" (cli-options-dwg opts)))
    (is (cli-options-epure-p opts))
    (is (cli-options-no-init-p opts))))

;;; --- PARSE-ARGUMENTS: negative cases --------------------------------

(test cli-unknown-long-option-errors
  "An unknown --foo signals CLI-USAGE-ERROR with the offending option."
  (handler-case
      (progn (parse-arguments '("--no-such-option"))
             (is nil "expected CLI-USAGE-ERROR"))
    (cli-usage-error (condition)
      (is (string= "--no-such-option"
                   (alfe.error:cli-usage-error-option condition))))))

(test cli-unknown-short-option-errors
  "An unknown -Z signals CLI-USAGE-ERROR too."
  (signals cli-usage-error
    (parse-arguments '("-Z"))))

(test cli-missing-argument-errors
  "Options that require a value but get none signal CLI-USAGE-ERROR."
  (signals cli-usage-error (parse-arguments '("-l")))
  (signals cli-usage-error (parse-arguments '("-x")))
  (signals cli-usage-error (parse-arguments '("--mode"))))

(test cli-bad-enum-rejected
  "Enum-valued options reject anything outside their vocabulary."
  (signals cli-usage-error (parse-arguments '("--mode" "fast")))
  (signals cli-usage-error (parse-arguments '("--host" "remote")))
  (signals cli-usage-error (parse-arguments '("--dialect" "lisp"))))

;;; --- PLAN-FROM-OPTIONS appends an implicit quit ----------------------

(test cli-plan-appends-quit-when-no-interactive
  "When neither -i nor --quit was given, PLAN-FROM-OPTIONS appends an
implicit :quit so backends see a uniform queue terminator."
  (let* ((opts (parse-arguments '("-x" "(princ 1)")))
         (plan (plan-from-options opts)))
    (is (= 2 (length plan)))
    (is (eq :quit (action-kind (second plan))))))

(test cli-plan-does-not-append-quit-when-interactive
  "Interactive mode opts out of the implicit :quit."
  (let* ((opts (parse-arguments '("-x" "(princ 1)" "-i")))
         (plan (plan-from-options opts)))
    (is (null (find :quit plan :key #'action-kind)))))

;;; --- implicit -i: bare `alfe' drops into the REPL -------------------
;;;
;;; Per command-line-option-ammendment.issue, invoking alfe with no
;;; -l / -x / --main / positional action enters the REPL by default,
;;; matching clautolisp. The init-file loads added by EFFECTIVE-PLAN
;;; do not count — they're machinery, not user intent — so the
;;; pure transformation under test (PLAN-FROM-OPTIONS) sees an empty
;;; CLI-OPTIONS-ACTIONS list and is expected to append :interactive.

(test cli-plan-appends-interactive-when-no-user-action
  "PLAN-FROM-OPTIONS with no user-supplied action appends :interactive
so the backend drops the user into the REPL once any init-file loads
have run."
  (let* ((opts (parse-arguments '()))
         (plan (plan-from-options opts)))
    (is (= 1 (length plan)))
    (is (eq :interactive (action-kind (first plan))))
    (is (null (find :quit plan :key #'action-kind)))))

(test cli-plan-quit-suppresses-implicit-interactive
  "--quit on its own (no content action either) wins over the implicit
-i: the plan ends with :quit so the backend shuts down cleanly."
  (let* ((opts (parse-arguments '("--quit")))
         (plan (plan-from-options opts)))
    (is (= 1 (length plan)))
    (is (eq :quit (action-kind (first plan))))
    (is (null (find :interactive plan :key #'action-kind)))))

(test cli-plan-content-action-still-quits
  "When the user supplies a content action (-l / -x / --main) and
neither -i nor --quit, PLAN-FROM-OPTIONS appends :quit so the backend
runs in batch mode and exits — same as before the implicit-REPL
change."
  (let* ((opts (parse-arguments '("-l" "/dev/null")))
         (plan (plan-from-options opts)))
    (is (= 2 (length plan)))
    (is (eq :load (action-kind (first plan))))
    (is (eq :quit (action-kind (second plan))))))

;;; --- env-var mapping is exhaustive ----------------------------------

(test cli-env-default-table-is-complete
  "Every documented env-var key resolves through ENV-DEFAULT without
error (the actual value may be NIL if the env-var is unset)."
  (dolist (key '(:workdir :timeout :mode :backend :os :bootstrap-phase
                 :remote-io-mode :dwg :epure
                 :autocad-install :autocad-version
                 :bricscad-install :bricscad-version
                 :keep-workdir :override))
    ;; Just checking ENV-DEFAULT does not signal.
    (is (or (null (env-default key))
            (stringp (env-default key)))
        "Env-default for ~S should be NIL or a string" key)))

(test cli-unknown-env-default-key-errors
  "ENV-DEFAULT on a typoed key signals a regular error (it's a bug,
not a usage failure)."
  (signals error (env-default :no-such-key)))

;;; --- RUN end-to-end -------------------------------------------------

(test cli-run-version-prints-and-exits-zero
  "RUN with --version writes 'alfe <ver>' to stdout and returns 0."
  (let* ((stdout (make-string-output-stream))
         (exit-code
           (let ((*standard-output* stdout))
             (run '("--version") :version "0.0.1"))))
    (is (= 0 exit-code))
    (is (search "alfe 0.0.1" (get-output-stream-string stdout)))))

(test cli-run-help-prints-and-exits-zero
  "RUN with --help writes the usage banner and returns 0."
  (let* ((stdout (make-string-output-stream))
         (exit-code
           (let ((*standard-output* stdout))
             (run '("--help") :version "0.0.1"))))
    (is (= 0 exit-code))
    (is (search "Usage: alfe" (get-output-stream-string stdout)))))

(test cli-run-dry-run-against-echo-backend
  "--dry-run resolves to the echo backend (the only one registered in
the test image), prints the resolved plan, and exits 0."
  (let* ((stdout (make-string-output-stream))
         (exit-code
           (let ((*standard-output* stdout)
                 ;; Rebind *backends* to an echo-only registry so the
                 ;; auto-resolver picks our mock and not whatever
                 ;; load-order accident left in place. `let` performs
                 ;; the dynamic save-and-restore for us.
                 (alfe.backend:*backends* (make-hash-table :test #'eql)))
             (alfe.backend:register-backend
              :echo (alfe.backend.echo:make-echo-backend))
             (run '("--dry-run" "-x" "(+ 1 2)") :version "0.0.1"))))
    (is (= 0 exit-code))
    (let ((output (get-output-stream-string stdout)))
      (is (search "alfe --dry-run" output))
      (is (search "eval" output)))))

(test cli-run-unknown-option-exits-two
  "An unknown CLI option produces exit code 2 (CLI-USAGE-ERROR)."
  (let* ((stderr (make-string-output-stream))
         (exit-code
           (let ((*error-output* stderr))
             (run '("--no-such-option") :version "0.0.1"))))
    (is (= 2 exit-code))
    (is (search "Unknown option" (get-output-stream-string stderr)))))

(test cli-run-no-backend-exits-three
  "When the requested backend isn't registered, RUN returns exit code 3."
  (let* ((stderr (make-string-output-stream))
         (alfe.backend:*backends* (make-hash-table :test #'eql))
         (exit-code
           (let ((*error-output* stderr))
             (run '("--clautolisp" "-x" "(+ 1 2)") :version "0.0.1"))))
    (is (= 3 exit-code))))

(test cli-run-eval-plus-1-2-against-echo-prints-three
  "End-to-end: -x \"(+ 1 2)\" against the echo backend prints \"3\\n\"
on stdout and exits 0. Mirrors the headline acceptance criterion
from alfe-backend-interface.issue."
  (let* ((stdout (make-string-output-stream))
         (exit-code
           (let ((*standard-output* stdout)
                 ;; Make echo the only registered backend so the
                 ;; default-resolver picks it up.
                 (alfe.backend:*backends* (make-hash-table :test #'eql)))
             (alfe.backend:register-backend :echo (alfe.backend.echo:make-echo-backend))
             (run '("-x" "(+ 1 2)") :version "0.0.1"))))
    (is (= 0 exit-code))
    (is (search (format nil "3~%") (get-output-stream-string stdout)))))
