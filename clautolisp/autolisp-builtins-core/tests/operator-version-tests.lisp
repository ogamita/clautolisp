(in-package #:clautolisp.autolisp-builtins-core.tests)

(in-suite autolisp-builtins-core-suite)

;;;; Version-gated operators (dialect-platform-version-axis): an operator the
;;;; vendor documentation says a release added or removed warns when called
;;;; under a dialect of that product whose version lacks it.

(defun %with-session-dialect (spelling thunk)
  (let ((session (clautolisp.autolisp-runtime:evaluation-context-session
                  (clautolisp.autolisp-runtime:current-evaluation-context))))
    (unwind-protect
         (progn
           (clautolisp.autolisp-runtime:set-runtime-session-dialect
            session (clautolisp.autolisp-reader:find-autolisp-dialect spelling))
           (funcall thunk))
      (clautolisp.autolisp-runtime:set-runtime-session-dialect
       session (clautolisp.autolisp-reader:autolisp-dialect-strict)))))

(defun %version-notice (spelling text)
  "What evaluating TEXT under dialect SPELLING writes to *ERROR-OUTPUT*."
  (%lisp-command-setup)
  (let ((*error-output* (make-string-output-stream)))
    (%with-session-dialect spelling
      (lambda () (ignore-errors (%eval-here text))))
    (get-output-stream-string *error-output*)))

(test version-gated-operators-warn-only-where-the-version-lacks-them
  ;; AutoCAD 2025 added ACET-LOAD-EXPRESSTOOLS.
  (is (search "[version-operator]"
              (%version-notice :autocad-2022 "(acet-load-expresstools)")))
  (is (search "added in AutoCAD 2025"
              (%version-notice :autocad-2022 "(acet-load-expresstools)")))
  (is (not (search "[version-operator]"
                   (%version-notice :autocad-2026 "(acet-load-expresstools)"))))
  ;; BricsCAD V26.1.07 removed MOD.
  (is (search "removed in BricsCAD V26"
              (%version-notice :bricscad-v26 "(mod 7 3)")))
  (is (not (search "[version-operator]" (%version-notice :bricscad-v25 "(mod 7 3)"))))
  ;; BricsCAD V21 added VL-INFP.
  (is (not (search "[version-operator]" (%version-notice :bricscad-v26 "(vl-infp 1.0)"))))
  ;; A dialect without a version is never gated.
  (is (not (search "[version-operator]"
                   (%version-notice :strict "(acet-load-expresstools)")))))

(test vl-infp-and-vl-nanp-are-not-bricscad-only
  ;; Measured on AutoCAD 2022 (probe-versions, job 16921684058): both exist,
  ;; so the spec lists them for both vendors and --autocad does not warn.
  (is (not (search "[vendor-operator]" (%version-notice :autocad-2022 "(vl-infp 1.0)"))))
  (is (not (search "[vendor-operator]" (%version-notice :autocad-2022 "(vl-nanp 1.0)")))))

(test setvar-lispsys-persists-in-the-registry-per-product
  ;; LISPSYS is saved in the registry (spec: clautolisp: LISPSYS, persisted
  ;; and read at launch) -- here the CLAUTOLISP_REGISTRY_FILE sandbox.
  (%lisp-command-setup)
  (%with-session-dialect :autocad-2022
    (lambda ()
      (%eval-here "(setvar \"LISPSYS\" 0)")
      (is (equal "0" (clautolisp.autolisp-host:host-registry-read
                      (clautolisp.autolisp-runtime:current-evaluation-host)
                      "HKEY_CURRENT_USER\\Software\\clautolisp\\Variables\\AutoCAD" "LISPSYS")))
      (%eval-here "(setvar \"LISPSYS\" 1)")
      (is (equal "1" (clautolisp.autolisp-host:host-registry-read
                      (clautolisp.autolisp-runtime:current-evaluation-host)
                      "HKEY_CURRENT_USER\\Software\\clautolisp\\Variables\\AutoCAD" "LISPSYS"))))))
