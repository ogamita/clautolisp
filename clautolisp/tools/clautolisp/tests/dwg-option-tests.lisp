;;;; clautolisp/tools/clautolisp/tests/dwg-option-tests.lisp
;;;;
;;;; --dwg FILE, the drawing argument (deferred-document-lifecycle-command-
;;;; semantics): the CLI parse and its usage errors. What the host makes of
;;;; the drawing is tested with the multi-document tests (builtins suite).

(in-package #:clautolisp.tools.clautolisp.tests)

(in-suite clautolisp-tool-suite)

(test dwg-option-sets-the-drawing-argument
  (is (equal "a.dxf"
             (clautolisp.autolisp-cli:cli-options-dwg
              (clautolisp.tools.clautolisp::parse-arguments '("--dwg" "a.dxf" "-x" "1")))))
  (is (null (clautolisp.autolisp-cli:cli-options-dwg
             (clautolisp.tools.clautolisp::parse-arguments '("-x" "1"))))))

(test dwg-option-missing-drawing-is-a-cli-error-with-noinput
  ;; Not a usage error any more: the option is fine, the file it names is
  ;; not there -- EX_NOINPUT (sysexits-exit-statuses.issue).
  (let ((condition (handler-case
                       (clautolisp.tools.clautolisp::open-drawing-argument
                        (clautolisp.cador:make-cador) "/nonexistent/none.dxf")
                     (clautolisp.autolisp-cli:cli-error (c) c))))
    (is (typep condition 'clautolisp.autolisp-cli:cli-error))
    (is (= clautolisp.sysexits:+ex-noinput+
           (clautolisp.autolisp-cli:cli-error-status condition)))))

(test dwg-option-on-a-host-without-drawings-is-a-usage-error
  (is (typep (handler-case
                 (clautolisp.tools.clautolisp::open-drawing-argument
                  (make-instance 'clautolisp.autolisp-host:nihil) "a.dxf")
               (clautolisp.autolisp-cli:cli-error (c)
                 (and (= clautolisp.sysexits:+ex-usage+
                         (clautolisp.autolisp-cli:cli-error-status c))
                      c)))
             'clautolisp.autolisp-cli:cli-error)))
