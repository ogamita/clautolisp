;;;; clautolisp/tools/clautolisp/tests/lisp-template-tests.lisp
;;;;
;;;; The lisp REPL as a window interactor template (windows-and-interactor-
;;;; templates.issue): a multi-instance REPL UI over the one shared evaluator.

(in-package #:clautolisp.tools.clautolisp.tests)

(in-suite clautolisp-tool-suite)

(test lisp-template-is-registered
  (let ((tpl (clautolisp.interactor:find-interactor-template "lisp")))
    (is (not (null tpl)))
    (is (eq clautolisp.tools.clautolisp::*autolisp*
            (clautolisp.interactor:interactor-template-interactor tpl)))
    (is (string= "lisp" (clautolisp.interactor:interactor-template-config-name tpl)))))

(test lisp-template-instantiates-over-a-shared-context
  ;; a fresh REPL instance multiplexes the ONE evaluator: the constructor wires
  ;; the given (else current) evaluation context into a repl-state.
  (let* ((tctx (clautolisp.interactor:make-template-context :target :the-eval-context))
         (act (clautolisp.interactor:instantiate-interactor-template "lisp" tctx))
         (state (clautolisp.interactor:activation-state act)))
    (is (eq clautolisp.tools.clautolisp::*autolisp*
            (clautolisp.interactor:activation-interactor act)))
    (is (eq :the-eval-context (clautolisp.tools.clautolisp::repl-state-context state)))
    ;; a fresh instance is named after the template's display-name
    (is (string= "Lisp REPL" (clautolisp.interactor:activation-name act)))))
