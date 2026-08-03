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

;;; --- workdir cleanup safety (alfe-workdir-env-deletes-caller-directory) ---

(test workdir-cleanup-spares-caller-supplied-directory
  "remove-workdir deletes a workdir ALFE generated (make-fresh-workdir name)
entirely, but NEVER a caller-supplied one (--workdir / $AUTOLISP_WORKDIR): it
removes only alfe's own protocol/ scratch and leaves the caller's files."
  ;; the name predicate — only the exact alfe-<backend>-<pid>-<6alnum> shape
  (is (alfe.workdir:alfe-generated-workdir-name-p "/tmp/alfe-bricscad-1234-ab12cd/"))
  (is (alfe.workdir:alfe-generated-workdir-name-p "/x/alfe-clautolisp-9-z9y8x7/"))
  (is (not (alfe.workdir:alfe-generated-workdir-name-p "/tmp/wdtest/")))
  (is (not (alfe.workdir:alfe-generated-workdir-name-p "/tmp/alfe-foo/")))         ; wrong arity
  (is (not (alfe.workdir:alfe-generated-workdir-name-p "/tmp/alfe-b-x-ab12cd/")))  ; pid not digits
  ;; a CALLER-supplied dir survives; only protocol/ is removed
  (let* ((base (uiop:ensure-directory-pathname
                (merge-pathnames (format nil "wdtest-caller-~D/" (random 999999))
                                 (uiop:temporary-directory))))
         (precious (merge-pathnames "my-result.txt" base))
         (protocol (uiop:ensure-directory-pathname (merge-pathnames "protocol/" base))))
    (unwind-protect
         (progn
           (ensure-directories-exist protocol)
           (with-open-file (s precious :direction :output :if-exists :supersede) (write-line "keep" s))
           (with-open-file (s (merge-pathnames "status.txt" protocol)
                              :direction :output :if-exists :supersede) (write-line "x" s))
           (alfe.workdir:remove-workdir base)
           (is (probe-file precious))                        ; caller's file survives
           (is (not (uiop:directory-exists-p protocol)))     ; alfe's protocol/ gone
           (is (uiop:directory-exists-p base)))              ; caller's dir survives
      (ignore-errors (uiop:delete-directory-tree base :validate t :if-does-not-exist :ignore))))
  ;; an ALFE-generated dir is removed entirely
  (let ((base (uiop:ensure-directory-pathname
               (merge-pathnames (format nil "alfe-clautolisp-~D-abc123/" (random 999999))
                                (uiop:temporary-directory)))))
    (ensure-directories-exist base)
    (alfe.workdir:remove-workdir base)
    (is (not (uiop:directory-exists-p base)))))

;;; --- workdir random tag is seeded (workdir-random-tag-unseeded) ---

(test workdir-random-tag-is-seeded-and-varies
  "random-tag must draw from a high-entropy per-process state, not the
implementation's fixed default sequence: before the seed fix every
process produced the SAME 6-char tag (workdir-random-tag-unseeded.issue)."
  ;; well-formed: 6 lowercase alphanumerics
  (let ((tag (alfe.workdir::random-tag)))
    (is (= 6 (length tag)))
    (is (every (lambda (c) (or (digit-char-p c) (char<= #\a c #\z))) tag)))
  ;; Simulate fresh-process starts: clear the memoised state so the next
  ;; call re-seeds via (make-random-state t), and take the first tag each
  ;; time. A properly seeded generator yields differing first tags; an
  ;; unseeded / fixed-seed one repeats the same tag every time.
  (let ((first-tags
          (loop repeat 8
                collect (progn (setf alfe.workdir::*tag-random-state* nil)
                               (alfe.workdir::random-tag)))))
    (is (> (length (remove-duplicates first-tags :test #'string=)) 1)))
  ;; Reset so later callers get a fresh seed rather than our torn-down one.
  (setf alfe.workdir::*tag-random-state* nil))
