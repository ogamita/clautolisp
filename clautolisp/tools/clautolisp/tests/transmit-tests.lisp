;;;; clautolisp/tools/clautolisp/tests/transmit-tests.lisp
;;;;
;;;; Regression tests for clautolisp.autolisp-cli:cli-options->transmit-bindings.
;;;; (The dedicated autolisp-cli test system is still missing — see
;;;; issues/open/autolisp-cli-tests-missing.issue — so this interim home is
;;;; the clautolisp-tool suite, which already depends on the shared CLI.)

(in-package #:clautolisp.tools.clautolisp.tests)

(in-suite clautolisp-tool-suite)

(test transmit-bindings-tolerates-explicit-nil-backend-frontend
  "Regression for transmit-bindings-interns-nil-bare-call: the builder
must be safely callable in isolation with an explicit NIL :backend /
:frontend (alfe's wrapper leaves :backend unset when it is exercised
outside the full run path). Previously (intern-autolisp-symbol NIL)
signalled a TYPE-ERROR; now both fall back to the documented CLAUTOLISP
default, so *AUTOLISP-BACKEND* / *AUTOLISP-FRONTEND* are present and
non-NIL."
  (let* ((options (clautolisp.tools.clautolisp::parse-arguments
                   (list "-x" "(+ 1 2)")))
         (bindings (clautolisp.autolisp-cli:cli-options->transmit-bindings
                    options :backend nil :frontend nil :version-text "0")))
    (is (listp bindings))
    (dolist (name '("*AUTOLISP-BACKEND*" "*AUTOLISP-FRONTEND*"))
      (let ((entry (assoc name bindings :test #'string=)))
        (is (not (null entry))
            "~A binding missing from the transmit list" name)
        (is (not (null (second entry)))
            "~A value is NIL (intern-autolisp-symbol would have signalled)"
            name)))))

(test transmit-bindings-honours-explicit-backend-frontend
  "The fallback only applies to NIL: an explicit backend/frontend is
still published verbatim."
  (let* ((options (clautolisp.tools.clautolisp::parse-arguments
                   (list "-x" "(+ 1 2)")))
         (bindings (clautolisp.autolisp-cli:cli-options->transmit-bindings
                    options :backend "BRICSCAD" :frontend "ALFE"
                    :version-text "0")))
    (flet ((sym-name (name)
             (let ((v (second (assoc name bindings :test #'string=))))
               (and v (clautolisp.autolisp-runtime:autolisp-symbol-name v)))))
      (is (string= "BRICSCAD" (sym-name "*AUTOLISP-BACKEND*")))
      (is (string= "ALFE" (sym-name "*AUTOLISP-FRONTEND*"))))))
