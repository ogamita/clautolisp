(in-package #:autolisp-front-end.tests)

(in-suite autolisp-front-end-suite)

;;;; FiveAM tests for the abstract backend protocol and the echo
;;;; backend. The acceptance criterion in
;;;; ../../issues/open/alfe-backend-interface.issue calls for an
;;;; end-to-end plan exercise:
;;;;
;;;;     (:eval "(+ 1 2)") → output "3"
;;;;
;;;; so that's the headline test here. We also assert that the
;;;; conditions hierarchy carries the documented plist and that the
;;;; echo backend implements every generic.

(test echo-backend-is-registered
  "The echo backend self-registers on load; the CLI can find it
without an explicit init step."
  (let ((backend (find-backend :echo)))
    (is (not (null backend)))
    (is (member :echo (list-backends)))))

(test echo-backend-detect-always-succeeds
  "DETECT on the echo backend returns the backend instance (never
signals BACKEND-NOT-AVAILABLE)."
  (let ((backend (find-backend :echo)))
    (is (eq backend (detect backend)))))

(test echo-backend-evaluates-plus-one-two
  "Headline acceptance test: an action plan with (:eval \"(+ 1 2)\")
yields the value \"3\" and prints \"3\\n\" on the captured stdout."
  (let* ((backend (find-backend :echo))
         (session (start-engine backend nil
                                :dialect :strict
                                :host :mock
                                :mock-input nil
                                :bootstrap-phase :full
                                :interactive-p nil))
         (plan    (list (action-eval "(+ 1 2)") (action-quit)))
         (result  (eval-plan session plan)))
    (is (eq :success (eval-result-status result)))
    (is (string= "3" (eval-result-value result)))
    ;; The captured stdout is exactly "3\n" — no banner, no extra text.
    (is (string= (format nil "3~%") (eval-result-output result)))
    (shutdown session :reason :test-end)
    (is (eq :stopped (session-state session)))))

(test echo-backend-handles-load-and-main
  "LOAD and MAIN actions echo a deterministic line each and report
SUCCESS at the end of the queue."
  (let* ((backend (find-backend :echo))
         (session (start-engine backend nil
                                :dialect :strict
                                :host :mock
                                :mock-input nil
                                :bootstrap-phase :full
                                :interactive-p nil))
         (plan    (list (action-load "/tmp/foo.lsp")
                        (action-main "MY-MAIN")
                        (action-quit)))
         (result  (eval-plan session plan)))
    (is (eq :success (eval-result-status result)))
    (let ((output (eval-result-output result)))
      (is (search "loaded /tmp/foo.lsp" output))
      (is (search "main MY-MAIN" output)))
    (shutdown session)))

(test backend-error-carries-structured-payload
  "The condition hierarchy preserves :backend / :phase / :code /
:message / :details — the CLI relies on them for exit-code mapping
and structured logging."
  (let ((condition (make-condition 'backend-error
                                   :backend :clautolisp
                                   :phase :eval
                                   :code :runtime-error
                                   :message "boom"
                                   :details '(:span "<expr>:1:1-1:5"))))
    (is (eq :clautolisp (alfe.error:backend-error-backend condition)))
    (is (eq :eval (alfe.error:backend-error-phase condition)))
    (is (eq :runtime-error (alfe.error:backend-error-code condition)))
    (is (string= "boom" (alfe.error:backend-error-message condition)))
    (is (equal '(:span "<expr>:1:1-1:5")
               (alfe.error:backend-error-details condition)))))
