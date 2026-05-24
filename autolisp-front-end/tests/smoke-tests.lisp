(in-package #:autolisp-front-end.tests)

(in-suite autolisp-front-end-suite)

;;;; Smoke tests for the alfe skeleton.
;;;;
;;;; These exist to satisfy alfe-skeleton.issue's "FiveAM scaffold so
;;;; make test exits 0" acceptance criterion. They are intentionally
;;;; thin: real coverage of the parser, action plan, and echo backend
;;;; lives in cli-tests.lisp and backend-tests.lisp.

(test alfe-skeleton-smoke
  "Trivial smoke test that the FiveAM suite is wired up at all."
  (is (string= "alfe" "alfe")))

(test alfe-error-exit-code-mapping
  "Every defined exit code in alfe-cli.issue maps cleanly."
  (is (= 2 (exit-code-for-condition
            (make-condition 'cli-usage-error
                            :option "--foo"
                            :message "test"))))
  (is (= 3 (exit-code-for-condition
            (make-condition 'backend-not-available
                            :backend :bricscad
                            :message "no bricscad"))))
  (is (= 1 (exit-code-for-condition
            (make-condition 'alfe.error:backend-eval-error
                            :backend :clautolisp
                            :message "boom")))))
