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

;;;; --- the singleton split: per-instance REPL state ------------------------

(defun %hist (context)
  (nth-value 0 (clautolisp.autolisp-runtime:lookup-variable
                (clautolisp.autolisp-runtime:intern-autolisp-symbol "ITPL-HIST")
                context)))

(defun %set (name value context)
  (clautolisp.autolisp-runtime:set-variable
   (clautolisp.autolisp-runtime:intern-autolisp-symbol name) value context))

(test two-lisp-instances-keep-independent-histories
  ;; two "lisp" instances over the ONE evaluator: a variable named in
  ;; *REPL-INSTANCE-VARIABLES* (the tool's :* history family) is per instance,
  ;; every other variable is the shared image's.
  (let* ((ctx (clautolisp.autolisp-runtime:current-evaluation-context))
         (clautolisp.repl:*repl-instance-variables* (list "ITPL-HIST"))
         (a1 (clautolisp.interactor:instantiate-interactor-template
              "lisp" (clautolisp.interactor:make-template-context :target ctx)))
         (a2 (clautolisp.interactor:instantiate-interactor-template
              "lisp" (clautolisp.interactor:make-template-context :target ctx)
              :existing-names (list (clautolisp.interactor:activation-label a1))))
         (s1 (clautolisp.interactor:activation-state a1))
         (s2 (clautolisp.interactor:activation-state a2)))
    (is (string= "Lisp REPL<2>" (clautolisp.interactor:activation-label a2)))
    (is (eq (clautolisp.repl:repl-state-context s1) (clautolisp.repl:repl-state-context s2)))
    (%set "ITPL-HIST" :outer ctx)
    (clautolisp.repl:call-with-repl-instance-variables
     s1 (lambda ()
          (is (null (%hist ctx)))           ; a fresh instance: empty history
          (%set "ITPL-HIST" 1 ctx)
          (%set "ITPL-SHARED" 1 ctx)))
    (is (eq :outer (%hist ctx)))           ; the enclosing value is restored
    (clautolisp.repl:call-with-repl-instance-variables
     s2 (lambda ()
          (is (null (%hist ctx)))           ; instance 2 does not see 1's history
          (is (eql 1 (nth-value 0 (clautolisp.autolisp-runtime:lookup-variable
                                   (clautolisp.autolisp-runtime:intern-autolisp-symbol
                                    "ITPL-SHARED")
                                   ctx))))  ; ... but does see the shared image
          (%set "ITPL-HIST" 2 ctx)
          ;; a turn of instance 1 nested in 2's (a debugger stop) keeps both
          (clautolisp.repl:call-with-repl-instance-variables
           s1 (lambda () (is (eql 1 (%hist ctx)))))
          (is (eql 2 (%hist ctx)))))
    (clautolisp.repl:call-with-repl-instance-variables
     s1 (lambda () (is (eql 1 (%hist ctx)))))
    (is (equal '(("ITPL-HIST" . 2)) (clautolisp.repl:repl-state-variables s2)))
    (is (eq :outer (%hist ctx)))))

(test lisp-instance-evaluator-swaps-its-history-and-keeps-a-transcript
  ;; the *AUTOLISP* evaluator runs each turn inside its instance's variables;
  ;; the transcript is the instance's own.
  (let* ((ctx (clautolisp.autolisp-runtime:current-evaluation-context))
         (clautolisp.repl:*repl-instance-variables* (list "ITPL-HIST"))
         (clautolisp.repl:*repl-eval-hook*
           (lambda (source context session break-on-error exit)
             (declare (ignore session break-on-error exit))
             (%set "ITPL-HIST" source context)))
         (a1 (clautolisp.interactor:instantiate-interactor-template
              "lisp" (clautolisp.interactor:make-template-context :target ctx)))
         (a2 (clautolisp.interactor:instantiate-interactor-template
              "lisp" (clautolisp.interactor:make-template-context :target ctx))))
    (flet ((turn (activation text)
             (let ((clautolisp.interactor:*command-activation* activation))
               (funcall (clautolisp.interactor:interactor-evaluator clautolisp.repl:*autolisp*)
                        (list :source text)))))
      (turn a1 "one")
      (turn a2 "two")
      (is (equal '(("ITPL-HIST" . "one"))
                 (clautolisp.repl:repl-state-variables (clautolisp.interactor:activation-state a1))))
      (is (equal '(("ITPL-HIST" . "two"))
                 (clautolisp.repl:repl-state-variables (clautolisp.interactor:activation-state a2)))))
    (clautolisp.repl:repl-transcript-append (clautolisp.interactor:activation-state a1) (list "x"))
    (is (equal '("x") (clautolisp.repl:repl-state-transcript (clautolisp.interactor:activation-state a1))))
    (is (null (clautolisp.repl:repl-state-transcript (clautolisp.interactor:activation-state a2))))))
