(in-package #:clautolisp.autolisp-runtime.tests)

(in-suite autolisp-runtime-suite)

;;; Phase 6: end-to-end smoke tests for the standalone evaluator entry
;;; points (run-autolisp-string / run-autolisp-file). The legacy
;;; autolisp-load-file path is tested elsewhere; here we only exercise
;;; the dialect-aware wrappers that the `clautolisp` CLI consumes.

(test run-autolisp-string-evaluates-strict-forms
  "run-autolisp-string evaluates a sequence of forms in a fresh session
and returns the value of the last form."
  (reset-autolisp-symbol-table)
  (let ((result (run-autolisp-string "(setq x 7) (setq y 5) (if 1 x y)")))
    (is (eql 7 result))))

(test run-autolisp-string-defaults-to-strict-dialect
  "When no dialect is given, run-autolisp-string installs the strict
profile in the active session."
  (reset-autolisp-symbol-table)
  (run-autolisp-string "(setq x 1)")
  (let* ((session (evaluation-context-session (default-evaluation-context)))
         (dialect (runtime-session-dialect session)))
    (is (eq :strict
            (clautolisp.autolisp-reader:autolisp-dialect-name dialect)))))

(test run-autolisp-string-honours-bricscad-dialect
  "Passing :dialect propagates the descriptor to the new session."
  (reset-autolisp-symbol-table)
  (let ((result (run-autolisp-string
                 "(setq x 1)"
                 :dialect (clautolisp.autolisp-reader:autolisp-dialect-bricscad-v26))))
    (is (eql 1 result))
    (let* ((session (evaluation-context-session (default-evaluation-context)))
           (dialect (runtime-session-dialect session)))
      (is (eq :bricscad-v26
              (clautolisp.autolisp-reader:autolisp-dialect-name dialect))))))

(test current-evaluation-dialect-falls-back-to-strict
  "current-evaluation-dialect returns the strict descriptor when no
session has been installed."
  (reset-autolisp-symbol-table)
  (let ((dialect (current-evaluation-dialect)))
    (is (eq :strict
            (clautolisp.autolisp-reader:autolisp-dialect-name dialect)))))

(test run-autolisp-file-loads-and-evaluates-from-disk
  "run-autolisp-file reads a file, evaluates each form, and returns the
value of the last expression."
  (reset-autolisp-symbol-table)
  (uiop:with-temporary-file (:stream stream :pathname path :type "lsp"
                             :direction :output)
    (write-string "(setq a 11) (setq b 4) (if 1 (setq c 3) nil)" stream)
    :close-stream
    (let ((result (run-autolisp-file path)))
      (is (eql 3 result)))))
