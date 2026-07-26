;;;; autolisp-front-end/source/conformance.lisp
;;;;
;;;; alfe.conformance — the scenario corpus runner. Phase 4 of the
;;;; alfe rollout. Specified by ../issues/open/alfe-conformance.issue.
;;;;
;;;; The runner is the backbone behind `make -C autolisp-front-end
;;;; test`'s scenario lane. Every other alfe ticket lands at least
;;;; one scenario here so the CI lane catches regressions even when
;;;; the per-ticket unit tests pass.
;;;;
;;;; The scenario format is a property list in a single .sexp file
;;;; (mirrors clautolisp/autolisp-file-compat/scenarios/*.sexp):
;;;;
;;;;   (:name "scenario-id"
;;;;    :description "What this checks."
;;;;    :classification :portable         ; :portable / :clautolisp-only /
;;;;                                       ;  :bricscad-only / :autocad-only /
;;;;                                       ;  :parity
;;;;    :argv ("--clautolisp" "-x" "(+ 1 2)")
;;;;    :expected-exit 0
;;;;    :expected-stdout-includes ("3")
;;;;    :expected-stdout-excludes ()
;;;;    :expected-stderr-includes ()
;;;;    :expected-stderr-excludes ()
;;;;    :stdin nil                        ; optional string fed to *standard-input*
;;;;    :setup-files ()                   ; ((BASENAME CONTENT) …) created in CWD
;;;;    :covers-options ("--clautolisp" "-x")
;;;;    :tolerated-divergence nil)        ; :parity-only documentation
;;;;
;;;; The runner returns one of three statuses per scenario:
;;;;
;;;;   :pass      every expectation held.
;;;;   :fail      at least one expectation failed; details in the
;;;;              `failures` slot.
;;;;   :skipped   classification requires a backend (or env var) that
;;;;              isn't available on the host; the scenario is
;;;;              counted but not asserted.

(defpackage #:alfe.conformance
  (:use #:cl)
  (:import-from #:alfe.cli
                #:run)
  (:export ;; scenario plist accessors
           #:scenario-name
           #:scenario-classification
           #:scenario-argv
           ;; runner
           #:read-scenario
           #:read-scenarios-from
           #:run-scenario
           #:run-scenarios
           ;; result struct
           #:scenario-result
           #:scenario-result-scenario
           #:scenario-result-status
           #:scenario-result-failures
           #:scenario-result-exit-code
           #:scenario-result-stdout
           #:scenario-result-stderr
           #:scenario-result-observations
           ;; probe-model observations (autolisp-spec ch.25)
           #:scenario-expected-observations
           #:parse-observations
           #:classify-observations
           ;; helpers
           #:summarise-results
           #:any-failed-p
           #:scenarios-directory))

(in-package #:alfe.conformance)

;;; --- scenario accessors --------------------------------------------

(defun scenario-name (scenario)           (getf scenario :name))
(defun scenario-description (scenario)    (getf scenario :description))
(defun scenario-classification (scenario) (getf scenario :classification :portable))
(defun scenario-argv (scenario)           (getf scenario :argv))
(defun scenario-expected-exit (scenario)  (getf scenario :expected-exit 0))
(defun scenario-stdout-includes (scenario)
  (getf scenario :expected-stdout-includes))
(defun scenario-stdout-excludes (scenario)
  (getf scenario :expected-stdout-excludes))
(defun scenario-stderr-includes (scenario)
  (getf scenario :expected-stderr-includes))
(defun scenario-stderr-excludes (scenario)
  (getf scenario :expected-stderr-excludes))
(defun scenario-stdin (scenario)          (getf scenario :stdin))
(defun scenario-setup-files (scenario)    (getf scenario :setup-files))
(defun scenario-covers-options (scenario) (getf scenario :covers-options))
(defun scenario-expected-observations (scenario)
  "The per-target observation expectations (autolisp-spec ch.25 probe
model). Each entry is (NAME EXPECTED-TOKEN &optional NORMATIVE-TOKEN):
EXPECTED-TOKEN is what THIS target should exhibit; NORMATIVE-TOKEN, when
present and different, is the autolisp-spec normative behaviour — so a
matching exhibition is a recognised KNOWN-DIVERGENCE rather than a plain
CONFORMS. NIL when the scenario still uses the older pass-line model."
  (getf scenario :expected-observations))
(defun scenario-version-arg (scenario)
  "Version string the CLI's RUN sees as :VERSION. Defaults so scenarios
that don't care can omit it."
  (or (getf scenario :version) "0.0.0"))

;;; --- result struct -------------------------------------------------

(defstruct scenario-result
  "Per-scenario outcome. SCENARIO is the original plist for context;
STATUS is :pass / :fail / :skipped; FAILURES is a list of one-line
diagnostics when STATUS = :fail. EXIT-CODE / STDOUT / STDERR mirror
what alfe.cli:run produced so the caller can render rich failure
output."
  (scenario      nil)
  (status        :pending :type (member :pending :pass :fail :skipped))
  (failures      nil :type list)
  (observations  nil :type list)   ; (NAME VERDICT EXHIBITED EXPECTED NORMATIVE) per obs
  (exit-code     nil)
  (stdout        "" :type string)
  (stderr        "" :type string))

;;; --- scenario discovery + loading ---------------------------------

(defun scenarios-directory ()
  "Return the absolute pathname of the bundled tests/scenarios/
directory. Uses #. so the resolved path survives save-lisp-and-die
in the alfe-tool image; the value lands in the FASL as a literal."
  #.(let ((self (or *compile-file-truename* *load-truename*)))
      (and self
           (namestring
            (merge-pathnames
             #P"../tests/scenarios/"
             (make-pathname :name nil :type nil :version nil
                            :defaults self))))))

(defun read-scenario (path)
  "Read a single .sexp scenario file and return the property list it
contains. Adds :path to the plist so failure messages can reference
the source."
  (with-open-file (in path :direction :input :external-format :utf-8)
    (let ((form (read in nil :eof)))
      (when (eq form :eof)
        (error "Scenario file ~A is empty." path))
      (unless (listp form)
        (error "Scenario file ~A does not contain a property list." path))
      (append (list :path (namestring path)) form))))

(defun read-scenarios-from (directory)
  "Walk DIRECTORY recursively and return the parsed scenarios. Order
follows the directory traversal — typically alphabetical per category,
which gives a stable runner sequence."
  (let ((scenarios nil))
    (uiop:collect-sub*directories
     (uiop:ensure-directory-pathname directory)
     t t
     (lambda (subdir)
       (dolist (file (uiop:directory-files subdir "*.sexp"))
         (handler-case
             (push (read-scenario file) scenarios)
           (error (probe)
             (format *error-output* "~&conformance: skipping ~A: ~A~%"
                     file probe))))))
    (nreverse scenarios)))

;;; --- backend availability gating ----------------------------------

(defun backend-available-p (classification)
  "True iff the scenario's classification can run on the current host.
:portable always runs; backend-bound ones check if the matching
backend is registered AND (for CAD backends) detects successfully."
  (case classification
    (:portable         t)
    (:clautolisp-only  (not (null (alfe.backend:find-backend :clautolisp))))
    (:bricscad-only
     (let ((backend (alfe.backend:find-backend :bricscad)))
       (and backend
            (handler-case
                (progn (alfe.backend:detect backend) t)
              (alfe.error:backend-not-available () nil)))))
    (:autocad-only
     (let ((backend (alfe.backend:find-backend :autocad)))
       (and backend
            (handler-case
                (progn (alfe.backend:detect backend) t)
              (alfe.error:backend-not-available () nil)))))
    (:parity
     ;; Parity scenarios run only when AUTOLISP_LEGACY is set to a
     ;; path the runner can spawn.
     (let ((legacy (uiop:getenv "AUTOLISP_LEGACY")))
       (and legacy (plusp (length legacy)) (probe-file legacy))))
    (otherwise nil)))

;;; --- per-scenario execution --------------------------------------

(defun call-with-sandboxed-init-env (workdir env-var-names thunk)
  "Run THUNK with $HOME = WORKDIR and every name in ENV-VAR-NAMES
temporarily unset, restoring the prior values on return. Used by
RUN-SCENARIO to keep the test host's real init files and env-var
state from leaking into a scenario's run."
  (let ((saved (loop for name in env-var-names
                     collect (cons name (uiop:getenv name)))))
    (unwind-protect
        (progn
          ;; Force $HOME to point at the scenario's workdir so the
          ;; init-file lookup only sees fixtures the scenario
          ;; declared. Anything not bound to a fixture is absent.
          (setf (uiop:getenv "HOME") (namestring workdir))
          (dolist (name env-var-names)
            (unless (string= name "HOME")
              (handler-case
                  #+sbcl (sb-posix:unsetenv name)
                  #+ccl  (ccl::unsetenv name)
                  #-(or sbcl ccl) (setf (uiop:getenv name) "")
                (error () nil))))
          (funcall thunk))
      (dolist (entry saved)
        (cond
          ((cdr entry)
           (setf (uiop:getenv (car entry)) (cdr entry)))
          (t
           (handler-case
               #+sbcl (sb-posix:unsetenv (car entry))
               #+ccl  (ccl::unsetenv (car entry))
               #-(or sbcl ccl) (setf (uiop:getenv (car entry)) "")
             (error () nil))))))))

(defmacro with-sandboxed-init-env ((workdir &rest env-var-names) &body body)
  "Macro wrapper around CALL-WITH-SANDBOXED-INIT-ENV. The
ENV-VAR-NAMES are evaluated once at expansion time as a literal
list of strings, matching the way the caller in RUN-SCENARIO
spells the names inline."
  `(call-with-sandboxed-init-env
    ,workdir (list ,@env-var-names)
    (lambda () ,@body)))

(defun run-scenario (scenario)
  "Execute SCENARIO against alfe.cli:run with captured streams. Returns
a SCENARIO-RESULT; the caller is responsible for surfacing failures.

We honor :setup-files by laying them down in a fresh per-scenario
working directory under $TMPDIR, then UIOP:WITH-CURRENT-DIRECTORY
into it so relative paths in :argv resolve. The directory is torn
down afterwards regardless of outcome.

Backend registries are rebound per-scenario so a scenario that
needs a different backend mix doesn't pollute its neighbours. We
re-register the standard four (echo / clautolisp / bricscad /
autocad) at the start of every scenario."
  (let ((result (make-scenario-result :scenario scenario)))
    (unless (backend-available-p (scenario-classification scenario))
      (setf (scenario-result-status result) :skipped)
      (return-from run-scenario result))
    (let* ((workdir (uiop:ensure-directory-pathname
                     (merge-pathnames
                      (format nil "alfe-conf-~A-~D/"
                              (scenario-name scenario) (random 999999))
                      (uiop:temporary-directory)))))
      (ensure-directories-exist workdir)
      (unwind-protect
           (let ((alfe.backend:*backends* (make-hash-table :test #'eql)))
             (setup-default-backends)
             (lay-down-fixtures workdir (scenario-setup-files scenario))
             (let* ((stdout-stream (make-string-output-stream))
                    (stderr-stream (make-string-output-stream))
                    (stdin-stream (or (when (scenario-stdin scenario)
                                        (make-string-input-stream
                                         (scenario-stdin scenario)))
                                      (make-string-input-stream "")))
                    ;; Sandbox $HOME + the env vars that gate init
                    ;; files so a scenario sees only the fixtures it
                    ;; declared via :setup-files. Without this, the
                    ;; test host's real ~/.autolisp file (or a
                    ;; contaminated CI env's $AUTOLISP_NO_INIT) would
                    ;; leak into every run.
                    (exit-code
                      (with-sandboxed-init-env
                          (workdir
                           "HOME" "AUTOLISP_NO_INIT"
                           "ALFE_NO_INIT" "CLAUTOLISP_NO_INIT"
                           "AUTOLISP_KEEP_WORKDIR")
                        (uiop:with-current-directory (workdir)
                          (let ((*standard-output* stdout-stream)
                                (*error-output*    stderr-stream)
                                (*standard-input*  stdin-stream))
                            (run (scenario-argv scenario)
                                 :version (scenario-version-arg scenario)))))))
               (setf (scenario-result-exit-code result) exit-code
                     (scenario-result-stdout result)
                       (get-output-stream-string stdout-stream)
                     (scenario-result-stderr result)
                       (get-output-stream-string stderr-stream))
               (compare-against-expectations result scenario)))
        (ignore-errors
         (uiop:delete-directory-tree workdir
                                     :validate t
                                     :if-does-not-exist :ignore))))
    result))

(defun setup-default-backends ()
  "Re-populate the rebound *backends* registry with the standard
four. Each per-backend module exports a MAKE-… constructor; we call
the ones whose package is loaded (echo + clautolisp are always
available in the test image; the CAD backends register themselves
on package-load too)."
  (when (find-package '#:alfe.backend.echo)
    (alfe.backend:register-backend
     :echo
     (funcall (find-symbol "MAKE-ECHO-BACKEND" '#:alfe.backend.echo))))
  (when (find-package '#:alfe.backend.clautolisp)
    (alfe.backend:register-backend
     :clautolisp
     (funcall (find-symbol "MAKE-CLAUTOLISP-BACKEND"
                           '#:alfe.backend.clautolisp))))
  (when (find-package '#:alfe.backend.bricscad)
    (alfe.backend:register-backend
     :bricscad
     (funcall (find-symbol "MAKE-BRICSCAD-BACKEND" '#:alfe.backend.bricscad))))
  (when (find-package '#:alfe.backend.autocad)
    (alfe.backend:register-backend
     :autocad
     (funcall (find-symbol "MAKE-AUTOCAD-BACKEND" '#:alfe.backend.autocad)))))

(defun lay-down-fixtures (workdir setup-files)
  "Materialise the (BASENAME CONTENT) pairs declared in SCENARIO's
:setup-files inside WORKDIR. The basename is taken literally — no
path traversal sanity-check beyond what the OS enforces."
  (dolist (entry setup-files)
    (destructuring-bind (basename content) entry
      (with-open-file (out (merge-pathnames basename workdir)
                           :direction :output
                           :if-exists :supersede
                           :if-does-not-exist :create
                           :external-format :utf-8)
        (write-string content out)))))

(defun parse-observations (stdout)
  "Parse the probe's `OBSERVE <name> <token>' lines from STDOUT into an
alist (NAME . TOKEN), last write winning. A probe is an INSTRUMENT that
emits one such line per exhibited behaviour (autolisp-spec ch.25 probe
model); everything else on stdout is human context and ignored."
  (let ((table nil))
    (with-input-from-string (in stdout)
      (loop for line = (read-line in nil :eof)
            until (eq line :eof)
            do (let* ((trimmed (string-left-trim '(#\Space #\Tab #\Return) line)))
                 (when (and (>= (length trimmed) 8)
                            (string= "OBSERVE " (subseq trimmed 0 8)))
                   (let* ((body (string-trim '(#\Space #\Tab #\Return)
                                             (subseq trimmed 8)))
                          (sp (position #\Space body)))
                     (when sp
                       (let ((name (subseq body 0 sp))
                             (token (string-trim '(#\Space #\Tab #\Return)
                                                 (subseq body sp))))
                         (setf table (acons name token
                                            (remove name table
                                                    :key #'car :test #'string=))))))))))
    (nreverse table)))

(defun classify-observations (stdout expected-observations)
  "Compare the exhibited OBSERVE tokens in STDOUT against
EXPECTED-OBSERVATIONS (each (NAME EXPECTED &optional NORMATIVE)). Return
two values: the verdict list ((NAME VERDICT EXHIBITED EXPECTED NORMATIVE)
…) and the failure diagnostics. Verdicts:
  :conforms          exhibited = expected, and expected = normative;
  :known-divergence  exhibited = expected, but expected differs from the
                     autolisp-spec NORMATIVE token (a documented,
                     recognised divergence for this target) — NOT a
                     failure;
  :unexpected        exhibited ≠ expected (the target deviates from what
                     it should do) — a failure;
  :missing           the probe emitted no observation of that NAME — a
                     failure."
  (let ((exhibited-table (parse-observations stdout))
        (verdicts nil)
        (failures nil))
    (dolist (entry expected-observations)
      (destructuring-bind (name expected &optional normative) entry
        (let* ((cell (assoc name exhibited-table :test #'string=))
               (exhibited (and cell (cdr cell)))
               (verdict
                 (cond
                   ((null cell) :missing)
                   ((string= exhibited expected)
                    (if (and normative (not (string= normative expected)))
                        :known-divergence
                        :conforms))
                   (t :unexpected))))
          (push (list name verdict exhibited expected normative) verdicts)
          (case verdict
            (:missing
             (push (format nil "observation ~S missing (expected ~S)"
                           name expected)
                   failures))
            (:unexpected
             (push (format nil "observation ~S = ~S, expected ~S~@[ (normative ~S)~]"
                           name exhibited expected
                           (and normative (not (string= normative expected))
                                normative))
                   failures))))))
    (values (nreverse verdicts) (nreverse failures))))

(defun compare-against-expectations (result scenario)
  "Walk every :expected-* declaration in SCENARIO and append a
diagnostic to RESULT's FAILURES for each mismatch. STATUS is set to
:pass when FAILURES stays empty."
  (let ((failures nil)
        (exit (scenario-result-exit-code result))
        (stdout (scenario-result-stdout result))
        (stderr (scenario-result-stderr result)))
    (let ((expected-exit (scenario-expected-exit scenario)))
      (unless (eql exit expected-exit)
        (push (format nil "exit code ~A (expected ~A)" exit expected-exit)
              failures)))
    (dolist (needle (scenario-stdout-includes scenario))
      (unless (search needle stdout)
        (push (format nil "stdout missing substring ~S" needle) failures)))
    (dolist (needle (scenario-stdout-excludes scenario))
      (when (search needle stdout)
        (push (format nil "stdout contains forbidden substring ~S" needle)
              failures)))
    (dolist (needle (scenario-stderr-includes scenario))
      (unless (search needle stderr)
        (push (format nil "stderr missing substring ~S" needle) failures)))
    (dolist (needle (scenario-stderr-excludes scenario))
      (when (search needle stderr)
        (push (format nil "stderr contains forbidden substring ~S" needle)
              failures)))
    ;; Probe-model observations (autolisp-spec ch.25): compare exhibited
    ;; behaviour against the per-target expectation. :unexpected / :missing
    ;; gate; :known-divergence is informational.
    (let ((expected-obs (scenario-expected-observations scenario)))
      (when expected-obs
        (multiple-value-bind (verdicts obs-failures)
            (classify-observations stdout expected-obs)
          (setf (scenario-result-observations result) verdicts)
          (dolist (msg obs-failures) (push msg failures)))))
    (setf (scenario-result-failures result) (nreverse failures)
          (scenario-result-status result)
          (if failures :fail :pass))
    result))

;;; --- batch run + summarisation -----------------------------------

(defun run-scenarios (&key directory filter)
  "Run every scenario found under DIRECTORY (defaults to the bundled
tests/scenarios/). FILTER, when provided, is a predicate on the
scenario plist; only scenarios for which it returns T are run.
Returns the list of SCENARIO-RESULT objects."
  (let* ((dir (or directory (scenarios-directory)))
         (scenarios (read-scenarios-from dir))
         (filtered (if filter (remove-if-not filter scenarios) scenarios)))
    (mapcar #'run-scenario filtered)))

(defun count-by-status (results)
  "Return a plist (:pass N :fail N :skipped N) summarising RESULTS."
  (let ((counts (list :pass 0 :fail 0 :skipped 0)))
    (dolist (result results)
      (incf (getf counts (scenario-result-status result))))
    counts))

(defun any-failed-p (results)
  "True iff at least one result has :fail status."
  (some (lambda (r) (eq (scenario-result-status r) :fail)) results))

(defun summarise-results (results &key (stream *standard-output*))
  "Print a human-readable summary line plus per-failure detail to
STREAM. Returns 0 when every scenario passed (or was skipped); 1
otherwise — the runner's exit code maps from this."
  (let* ((counts (count-by-status results))
         (pass (getf counts :pass))
         (fail (getf counts :fail))
         (skip (getf counts :skipped))
         (all-obs (loop for r in results append (scenario-result-observations r)))
         (n-conforms (count :conforms all-obs :key #'second))
         (n-known    (count :known-divergence all-obs :key #'second)))
    (format stream "~&alfe conformance: ~D pass, ~D fail, ~D skipped~%"
            pass fail skip)
    (when (plusp (length all-obs))
      (format stream "observations: ~D conforms, ~D known-divergence, ~D unexpected~%"
              n-conforms n-known
              (count :unexpected all-obs :key #'second)))
    ;; Known divergences are diagnostic, not failures: surface them so the
    ;; probe run documents where each target departs from the normative
    ;; spec (autolisp-spec ch.25).
    (when (plusp n-known)
      (format stream "~%Known divergences (target departs from the normative spec):~%")
      (dolist (r results)
        (dolist (obs (scenario-result-observations r))
          (destructuring-bind (name verdict exhibited expected normative) obs
            (declare (ignore expected))
            (when (eq verdict :known-divergence)
              (format stream "  ~A / ~A: exhibited ~S; normative ~S~%"
                      (scenario-name (scenario-result-scenario r))
                      name exhibited normative))))))
    (when (plusp fail)
      (format stream "~%Failures:~%")
      (dolist (r results)
        (when (eq (scenario-result-status r) :fail)
          (format stream "  ~A:~%" (scenario-name (scenario-result-scenario r)))
          (dolist (msg (scenario-result-failures r))
            (format stream "    - ~A~%" msg)))))
    (if (plusp fail) 1 0)))
