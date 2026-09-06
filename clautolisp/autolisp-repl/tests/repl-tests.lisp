;;;; clautolisp/autolisp-repl/tests/repl-tests.lisp

(in-package #:clautolisp.repl.tests)

(in-suite repl-suite)

(test lisp-template-is-registered
  (let ((tpl (clautolisp.interactor:find-interactor-template "lisp")))
    (is (not (null tpl)))
    (is (eq clautolisp.repl:*autolisp*
            (clautolisp.interactor:interactor-template-interactor tpl)))
    (is (string= "lisp" (clautolisp.interactor:interactor-template-config-name tpl)))))

(test lisp-template-instantiates-over-a-shared-context
  ;; a fresh REPL instance multiplexes the ONE evaluator: the constructor wires
  ;; the given (else current) evaluation context into a repl-state.
  (let* ((tctx (clautolisp.interactor:make-template-context :target :the-eval-context))
         (act (clautolisp.interactor:instantiate-interactor-template "lisp" tctx))
         (state (clautolisp.interactor:activation-state act)))
    (is (eq clautolisp.repl:*autolisp* (clautolisp.interactor:activation-interactor act)))
    (is (eq :the-eval-context (clautolisp.repl:repl-state-context state)))
    (is (string= "Lisp REPL" (clautolisp.interactor:activation-name act)))))

(test autolisp-interactor-drives-a-turn-with-the-default-hooks
  ;; End-to-end: the relocated *AUTOLISP* interactor, driven by the framework
  ;; loop over its own activation with the LIBRARY default hooks (one line = one
  ;; turn, minimal read-eval-print), evaluates a self-evaluating form.
  (let* ((ctx (clautolisp.autolisp-runtime:current-evaluation-context))
         (act (clautolisp.interactor:make-activation
               clautolisp.repl:*autolisp*
               (clautolisp.repl:make-repl-state :context ctx :session nil)))
         (clautolisp.interactor:*interactor-stack* (list act))
         (out (make-string-output-stream)))
    (with-input-from-string (in (format nil "42~%"))
      (clautolisp.interactor:interactor-loop
       :input in :output out :error-output out))
    (is (not (null (search "42" (get-output-stream-string out)))))))
