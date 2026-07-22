;;;; FiveAM tests for the aldo command table + stacked dictionaries
;;;; (clautolisp.debug.ui command-table, command reference §8).

(in-package #:clautolisp.ui.dumb.tests)

(in-suite dumb-ui-suite)

(defun fresh-dict (name) (clautolisp.debug.ui:make-command-dictionary name))

(test cmdtab-register-and-lookup
  (let ((d (fresh-dict "g")))
    (clautolisp.debug.ui:bind-debugger-command '(c continue) '() "Continue."
                                               (constantly :continue) d)
    (clautolisp.debug.ui:bind-debugger-command '(lb list breakpoints) '() "List bkpts."
                                               (constantly :list) d)
    ;; by key and by word phrase
    (is (clautolisp.debug.ui:find-command d "c"))
    (is (clautolisp.debug.ui:find-command d "continue"))
    (is (clautolisp.debug.ui:find-command d "lb"))
    (is (clautolisp.debug.ui:find-command d "list breakpoints"))
    ;; case-insensitive
    (is (clautolisp.debug.ui:find-command d "LB"))
    ;; the function is callable
    (is (eq :continue (funcall (clautolisp.debug.ui:command-function
                                (clautolisp.debug.ui:find-command d "c")))))
    ;; absent
    (is (null (clautolisp.debug.ui:find-command d "zzz")))))

(test cmdtab-arity
  (let ((d (fresh-dict "g")))
    (clautolisp.debug.ui:bind-debugger-command '(z zar) '(count name) "Zar."
                                               (lambda (a b) (list a b)) d)
    (is (= 2 (clautolisp.debug.ui:command-arity (clautolisp.debug.ui:find-command d "z"))))
    (clautolisp.debug.ui:bind-debugger-command '(c continue) '() "C." (constantly t) d)
    (is (= 0 (clautolisp.debug.ui:command-arity (clautolisp.debug.ui:find-command d "c"))))))

(test cmdtab-naming-rule
  (let ((d (fresh-dict "g")))
    ;; key must be the initials of the words
    (fiveam:signals error
      (clautolisp.debug.ui:bind-debugger-command '(x continue) '() "bad" (constantly t) d))
    ;; punctuation / mnemonic keys are exempt (e.g. . = definition, > = forward)
    (fiveam:finishes
      (clautolisp.debug.ui:bind-debugger-command '(|.| definition) '() "ok" (constantly t) d))
    (fiveam:finishes
      (clautolisp.debug.ui:bind-debugger-command '(|>| forward) '() "ok" (constantly t) d))))

(test cmdtab-collision
  (let ((d (fresh-dict "g")))
    (clautolisp.debug.ui:bind-debugger-command '(b break) '() "Break." (constantly t) d)
    ;; same key in the same dictionary => error
    (fiveam:signals error
      (clautolisp.debug.ui:bind-debugger-command '(b back) '() "dup" (constantly t) d))))

(test cmdtab-stacked-lookup
  (let ((global (fresh-dict "global"))
        (mode (fresh-dict "inspector")))
    (clautolisp.debug.ui:bind-debugger-command '(b break) '() "global break."
                                               (constantly :break) global)
    (clautolisp.debug.ui:bind-debugger-command '(c continue) '() "global continue."
                                               (constantly :continue) global)
    ;; the inspector shadows b with its own `bind'
    (clautolisp.debug.ui:bind-debugger-command '(b bind) '() "inspector bind."
                                               (constantly :bind) mode)
    (let ((stack (list mode global)))
      ;; innermost wins for the shadowed key
      (is (eq :bind (funcall (clautolisp.debug.ui:command-function
                              (clautolisp.debug.ui:lookup-command "b" stack)))))
      ;; a global-only command resolves through from any mode
      (is (eq :continue (funcall (clautolisp.debug.ui:command-function
                                  (clautolisp.debug.ui:lookup-command "c" stack)))))
      ;; the escape word reaches the shadowed global command (global dict only)
      (is (eq :break (funcall (clautolisp.debug.ui:command-function
                               (clautolisp.debug.ui:lookup-command
                                "b" (list global)))))))))

(test cmdtab-unbind-and-macro
  (with-fresh-user-dictionary
    ;; the CL macro registers into the default dictionary — the ALDO
    ;; singleton's user dictionary (D6: no global user table)
    (let ((aldo-user (clautolisp.debug.ui:interactor-user-dictionary "ALDO")))
      (clautolisp.debug.ui:define-debugger-command (t throw-test) () "t."
        :thrown)
      (is (eq :thrown (funcall (clautolisp.debug.ui:command-function
                                (clautolisp.debug.ui:find-command aldo-user "t")))))
      (is (clautolisp.debug.ui:unbind-debugger-command "t"))
      (is (null (clautolisp.debug.ui:find-command aldo-user "t")))
      (is (null (clautolisp.debug.ui:find-command aldo-user "throw-test"))))))

(test cmdtab-interactor-registry-and-named-registration
  ;; interactor-design-revision.issue D6/D7: no global user table — the
  ;; registry lists every DEFINE-INTERACTOR-defined interactor, and the
  ;; CLAL-DEFINE-COMMAND hook registers an AutoLISP-style command into any
  ;; NAMED interactor's user dictionary, active or not.
  (let ((names (clautolisp.interactor:list-interactor-names)))
    (dolist (expected '("ALDO" "NAVI" "LAVI" "INSPECT"))
      (is (member expected names :test #'string-equal))))
  ;; alias resolution: "debug" names ALDO's dictionary too
  (is (eq (clautolisp.debug.ui:interactor-user-dictionary "ALDO")
          (clautolisp.debug.ui:interactor-user-dictionary "debug")))
  ;; an unknown interactor name is an error
  (fiveam:signals error (clautolisp.debug.ui:interactor-user-dictionary "NOSUCH"))
  ;; named registration into an INACTIVE interactor's user dictionary
  (let ((dict (clautolisp.debug.ui:interactor-user-dictionary "NAVI")))
    (clautolisp.debug.ui:bind-debugger-command
     '(z zap) '() "zap." (constantly :zap) dict)
    (unwind-protect
         (is (eq :zap (funcall (clautolisp.debug.ui:command-function
                                (clautolisp.debug.ui:find-command dict "z")))))
      (clautolisp.debug.ui:unbind-debugger-command "z" dict))))
