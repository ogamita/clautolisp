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
                    (exit-code
                      (uiop:with-current-directory (workdir)
                        (let ((*standard-output* stdout-stream)
                              (*error-output*    stderr-stream)
                              (*standard-input*  stdin-stream))
                          (run (scenario-argv scenario)
                               :version (scenario-version-arg scenario))))))
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
         (skip (getf counts :skipped)))
    (format stream "~&alfe conformance: ~D pass, ~D fail, ~D skipped~%"
            pass fail skip)
    (when (plusp fail)
      (format stream "~%Failures:~%")
      (dolist (r results)
        (when (eq (scenario-result-status r) :fail)
          (format stream "  ~A:~%" (scenario-name (scenario-result-scenario r)))
          (dolist (msg (scenario-result-failures r))
            (format stream "    - ~A~%" msg)))))
    (if (plusp fail) 1 0)))
