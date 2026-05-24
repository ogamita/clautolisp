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
