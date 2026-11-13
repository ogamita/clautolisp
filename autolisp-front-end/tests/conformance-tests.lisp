(in-package #:autolisp-front-end.tests)

(in-suite autolisp-front-end-suite)

;;;; FiveAM integration for the alfe.conformance runner.
;;;;
;;;; This file is what binds `make -C autolisp-front-end test` to
;;;; the scenario corpus under tests/scenarios/. The runner itself
;;;; (source/conformance.lisp) is responsible for the I/O and
;;;; assertions; FiveAM here just calls RUN-SCENARIOS and asserts
;;;; that nothing failed.
;;;;
;;;; Skipped scenarios — typically BricsCAD/AutoCAD ones on a host
;;;; without the CAD installed — do NOT count as failures. Their
;;;; coverage shows up in the runner's summary output.

(test conformance-corpus-passes
  "Run the scenario corpus end-to-end. Every scenario must either
:pass or :skip; a :fail anywhere fails this FiveAM test with a
trail of the scenario names that failed."
  (let* ((results (alfe.conformance:run-scenarios))
         (failures (remove-if-not
                    (lambda (r) (eq (alfe.conformance:scenario-result-status r)
                                    :fail))
                    results))
         (passes  (count-if (lambda (r) (eq (alfe.conformance:scenario-result-status r)
                                            :pass))
                            results))
         (skipped (count-if (lambda (r) (eq (alfe.conformance:scenario-result-status r)
                                            :skipped))
                            results)))
    (is (not (null results))
        "Conformance corpus is empty — did the scenarios/ directory go missing?")
    (is (null failures)
        "Conformance failures (~D pass, ~D fail, ~D skipped): ~%~{  ~A: ~A~%~}"
        passes (length failures) skipped
        (mapcan (lambda (r)
                  (list (alfe.conformance:scenario-name
                         (alfe.conformance:scenario-result-scenario r))
                        (or (first (alfe.conformance:scenario-result-failures r))
                            "(no failure detail)")))
                failures))))

(test conformance-corpus-not-empty
  "Lightweight protection against accidentally landing a Makefile
change that hides the scenarios — the corpus must contain at least
one of each major action class (-x, -l, --main)."
  (let* ((scenarios (alfe.conformance:read-scenarios-from
                     (alfe.conformance:scenarios-directory)))
         (argvs (mapcar (lambda (s) (alfe.conformance:scenario-argv s))
                        scenarios)))
    (is (some (lambda (a) (find "-x" a :test #'string=)) argvs)
        "No scenario exercises -x")
    (is (some (lambda (a) (find "-l" a :test #'string=)) argvs)
        "No scenario exercises -l")
    (is (some (lambda (a) (find "--main" a :test #'string=)) argvs)
        "No scenario exercises --main")
    (is (some (lambda (a) (find "--dry-run" a :test #'string=)) argvs)
        "No scenario exercises --dry-run")))

;;; --- probe observation model (autolisp-spec ch.25) ----------------

(test conformance-parse-observations
  "PARSE-OBSERVATIONS extracts (NAME . TOKEN) from OBSERVE lines, last
write winning, ignoring human context."
  (let ((table (alfe.conformance:parse-observations
                (format nil "=== probe ===~%OBSERVE a.b yes~%noise~%  OBSERVE c.d payload~%OBSERVE a.b no~%OBSERVATIONS 3~%"))))
    (is (string= "no" (cdr (assoc "a.b" table :test #'string=))))   ; last write wins
    (is (string= "payload" (cdr (assoc "c.d" table :test #'string=))))
    (is (= 2 (length table)))))

(test conformance-classify-observations-verdicts
  "CLASSIFY-OBSERVATIONS yields :conforms / :known-divergence /
:unexpected / :missing and gates only on the last two."
  (let ((normative "OBSERVE keep.same payload
OBSERVE entmod.xrecord payload")
        (deviant "OBSERVE keep.same payload
OBSERVE entmod.xrecord payload2"))
    ;; normative target: exhibited = expected = normative -> conforms, no failures
    (multiple-value-bind (v f)
        (alfe.conformance:classify-observations
         normative '(("keep.same" "payload") ("entmod.xrecord" "payload")))
      (is (= 2 (count :conforms v :key #'second)))
      (is (null f)))
    ;; bricscad target: exhibited = expected (payload2) but normative differs
    ;; -> known-divergence, still green
    (multiple-value-bind (v f)
        (alfe.conformance:classify-observations
         deviant '(("keep.same" "payload") ("entmod.xrecord" "payload2" "payload")))
      (is (= 1 (count :known-divergence v :key #'second)))
      (is (null f)))
    ;; a target that should no-op but mutated -> unexpected (a real bug), gates
    (multiple-value-bind (v f)
        (alfe.conformance:classify-observations
         deviant '(("keep.same" "payload") ("entmod.xrecord" "payload")))
      (is (= 1 (count :unexpected v :key #'second)))
      (is (= 1 (length f))))
    ;; probe never emitted an expected observation -> missing, gates
    (multiple-value-bind (v f)
        (alfe.conformance:classify-observations
         normative '(("keep.same" "payload") ("never.emitted" "x")))
      (is (= 1 (count :missing v :key #'second)))
      (is (= 1 (length f))))))

(test conformance-classify-observations-default
  "A DEFAULT token covers every EMITTED observation not explicitly named:
matching ones conform silently; a NEW non-default value surfaces as
:unexpected so undeclared divergences cannot slip through."
  (let ((out "OBSERVE a.b yes
OBSERVE c.d yes
OBSERVE e.f rejected"))
    ;; e.f is declared divergent; a.b/c.d ride the default -> all green
    (multiple-value-bind (v f)
        (alfe.conformance:classify-observations
         out '(("e.f" "rejected")) "yes")
      (is (= 3 (count :conforms v :key #'second)))   ; e.f explicit + a.b + c.d via default
      (is (null f)))
    ;; an undeclared observation that is NOT the default -> unexpected, gates
    (multiple-value-bind (v f)
        (alfe.conformance:classify-observations
         "OBSERVE a.b yes
OBSERVE surprise.x created" nil "yes")
      (is (= 1 (count :unexpected v :key #'second)))
      (is (= 1 (length f))))))

(test conformance-summarise-results-exit-code
  "SUMMARISE-RESULTS returns 0 when every result is :pass / :skipped
and 1 when any is :fail. Drives the CLI runner's exit-code logic."
  (let* ((make (find-symbol "MAKE-SCENARIO-RESULT" '#:alfe.conformance))
         (passing (list (funcall make :scenario '(:name "ok") :status :pass)))
         (mixed (list (funcall make :scenario '(:name "ok") :status :pass)
                      (funcall make :scenario '(:name "boom") :status :fail
                                    :failures (list "exit-code mismatch")))))
    (let ((*standard-output* (make-string-output-stream)))
      (is (= 0 (alfe.conformance:summarise-results passing))))
    (let ((*standard-output* (make-string-output-stream)))
      (is (= 1 (alfe.conformance:summarise-results mixed))))))

(test accoreconsole-macos-discovered-only-when-runnable
  "Regression guard for the corpus break caused by the macOS --cad fix, as
the rule stands since alfe 2.3.118: an AcCoreConsole in a macOS AutoCAD bundle
is discovered only once it has been seen to run AutoLISP. An install that
cannot (no licence, accoreconsole-macos-headless-qt-blocker) is NOT
discovered, so plain --autocad -- and CONFORMANCE-CORPUS-PASSES via
BACKEND-AVAILABLE-P -> DETECT -- skips the AutoCAD scenarios instead of running
and failing them. $AUTOCAD_ACCORECONSOLE, which --cad accoreconsole sets, is
taken as given, unprobed. (Until 2.3.118 this test asserted no bundle
discovery at all; on a Mac with a licensed AutoCAD that stale assertion read
the real /Applications and failed.) Never looks at the real install: the
bundles are a fake /Applications (WITH-FAKE-MACOS-AUTOCAD)."
  (with-cad-test-directories
    (let ((dir (%fresh-test-directory)))
      (with-fake-macos-autocad (dir)
        (is (null (alfe.backend.autocad:discover-accoreconsole-binary :os :macos))
            "no AutoCAD bundle: nothing discovered")
        (unless (uiop:os-windows-p)     ; fake AcCoreConsoles are POSIX shell scripts
          (%fake-accoreconsole dir :fails)
          (is (null (alfe.backend.autocad:discover-accoreconsole-binary :os :macos))
              "an AcCoreConsole that cannot run AutoLISP is not discovered"))
        ;; A stub that could never pass the probe: returned only if unprobed.
        (let ((named (namestring (merge-pathnames "named-accoreconsole.txt" dir))))
          (with-open-file (s named :direction :output :if-exists :supersede)
            (write-line "stub, not runnable" s))
          (setf (uiop:getenv "AUTOCAD_ACCORECONSOLE") named)
          (is (equal named (alfe.backend.autocad:discover-accoreconsole-binary :os :macos))
              "$AUTOCAD_ACCORECONSOLE is taken as given, unprobed"))))))

(test conformance-runs-against-an-autocad-absent-baseline
  "The corpus's AutoCAD-absent baseline holds on a Mac with a runnable AutoCAD
installed: autocad-unsupported-os passes, because RUN-SCENARIO hides the macOS
bundles (CALL-WITHOUT-INSTALLED-AUTOCAD) as it unsets $AUTOCAD_ACCORECONSOLE.
Release 2.4.0 failed it on a Mac with AutoCAD 2027. Simulated with a fake,
runnable install, so it guards on every POSIX host."
  (if (uiop:os-windows-p)
      (fiveam:skip "the scenario is :skip-on-os (:windows); fake AcCoreConsoles are POSIX shell scripts")
      (with-cad-test-directories
        (let ((dir (%fresh-test-directory)))
          (with-fake-macos-autocad (dir)
            (%fake-accoreconsole dir :runs)
            (is (alfe.backend.autocad:discover-accoreconsole-binary :os :macos)
                "precondition: the fake install is discovered outside the corpus")
            (let ((result (alfe.conformance:run-scenario
                           (alfe.conformance:read-scenario
                            (merge-pathnames "autocad/unsupported-os.sexp"
                                             (alfe.conformance:scenarios-directory))))))
              (is (eq :pass (alfe.conformance:scenario-result-status result))
                  "autocad-unsupported-os: ~S~%stderr: ~A"
                  (alfe.conformance:scenario-result-failures result)
                  (alfe.conformance:scenario-result-stderr result))))))))
