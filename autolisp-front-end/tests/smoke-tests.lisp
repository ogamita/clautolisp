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
  "Every condition class maps to its sysexits status
(sysexits-exit-statuses.issue)."
  (is (= 64 (exit-code-for-condition
            (make-condition 'cli-usage-error
                            :option "--foo"
                            :message "test"))))
  (is (= 69 (exit-code-for-condition
            (make-condition 'backend-not-available
                            :backend :bricscad
                            :message "no bricscad"))))
  (is (= 1 (exit-code-for-condition
            (make-condition 'alfe.error:backend-eval-error
                            :backend :clautolisp
                            :message "boom"))))
  ;; A file or drawing an option names carries its own status.
  (is (= 66 (exit-code-for-condition
             (make-condition 'clautolisp.autolisp-cli:cli-error
                             :option "--dwg" :message "gone"
                             :status clautolisp.sysexits:+ex-noinput+))))
  (is (= 75 (exit-code-for-condition
             (make-condition 'alfe.error:backend-bootstrap-error
                             :backend :bricscad :code :ready-timeout
                             :message "late"))))
  (is (= 69 (exit-code-for-condition
             (make-condition 'alfe.error:backend-bootstrap-error
                             :backend :clautolisp :code :no-subprocess-binary
                             :message "absent"))))
  (is (= 64 (exit-code-for-condition
             (make-condition 'alfe.error:backend-bootstrap-error
                             :backend :clautolisp :code :unknown-host
                             :message "bad host"))))
  (is (= 73 (exit-code-for-condition
             (make-condition 'alfe.error:backend-bootstrap-error
                             :backend :clautolisp :code :cannot-create-workdir
                             :message "read-only"))))
  (is (= 76 (exit-code-for-condition
             (make-condition 'alfe.error:backend-protocol-error
                             :backend :bricscad :code :unknown-control
                             :message "garbled"))))
  (is (= 75 (exit-code-for-condition
             (make-condition 'alfe.error:backend-protocol-error
                             :backend :bricscad :code :stdin-busy
                             :message "busy"))))
  (is (= 70 (exit-code-for-condition
             (make-condition 'alfe.error:plugin-error
                             :plugin "p" :hook :plan :message "boom"))))
  ;; Conditions that are not alfe's: the engine's table.
  (is (= 66 (exit-code-for-condition
             (make-condition 'file-error :pathname #p"/nonexistent"))))
  (is (= 70 (exit-code-for-condition
             (make-condition 'simple-error :format-control "internal")))))

(test sysexits-table-matches-sysexits-h
  "The named statuses are the <sysexits.h> values (checked against the C
header on Linux, 2026-10-06), and nothing in 64..78 is unnamed."
  (is (= 0  clautolisp.sysexits:+ex-ok+))
  (is (= 64 clautolisp.sysexits:+ex-usage+))
  (is (= 65 clautolisp.sysexits:+ex-dataerr+))
  (is (= 66 clautolisp.sysexits:+ex-noinput+))
  (is (= 67 clautolisp.sysexits:+ex-nouser+))
  (is (= 68 clautolisp.sysexits:+ex-nohost+))
  (is (= 69 clautolisp.sysexits:+ex-unavailable+))
  (is (= 70 clautolisp.sysexits:+ex-software+))
  (is (= 71 clautolisp.sysexits:+ex-oserr+))
  (is (= 72 clautolisp.sysexits:+ex-osfile+))
  (is (= 73 clautolisp.sysexits:+ex-cantcreat+))
  (is (= 74 clautolisp.sysexits:+ex-ioerr+))
  (is (= 75 clautolisp.sysexits:+ex-tempfail+))
  (is (= 76 clautolisp.sysexits:+ex-protocol+))
  (is (= 77 clautolisp.sysexits:+ex-noperm+))
  (is (= 78 clautolisp.sysexits:+ex-config+))
  (is (= 1 clautolisp.sysexits:+exit-autolisp-error+))
  (is (= 130 clautolisp.sysexits:+exit-interrupted+))
  (is (equal "EX_NOINPUT" (clautolisp.sysexits:exit-status-name 66)))
  (is (null (clautolisp.sysexits:exit-status-name 1)))
  (is (loop for status from 64 to 78
            always (clautolisp.sysexits:exit-status-name status))))
