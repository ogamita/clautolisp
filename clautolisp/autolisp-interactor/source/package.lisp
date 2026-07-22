(defpackage #:clautolisp.interactor
  (:use #:cl)
  (:documentation
   "The interactor framework: one command loop for every clautolisp
interaction mode (issues/open/interactors.lisp).

At any time one command interpreter — an INTERACTOR — is in charge: it
prints a status and a prompt, reads a Lisp expression or a command,
sends the expression to its evaluator, or runs the command. Each
interactor carries two command dictionaries — the system commands
clautolisp provides for that loop, and the user commands layered over
them. A command may push a new interactor on *INTERACTOR-STACK* (a new
command loop) or pop one; commands are searched down the stack, user
dictionaries first, so user commands shadow system commands and inner
loops shadow outer loops. A command may also be routed explicitly to a
named interactor anywhere on the stack: `aldo break 42' runs the ALDO
debugger's `break' from any inner loop.

INTERACTOR-LOOP is the single loop driving all of this; the concrete
interactors (the Lisp REPL, the ALDO debugger, the LAVI line / NAVI
sexp navigators, the SEDIT editor) are defined next to their
implementations, not here.")
  (:export
   ;; commands
   #:command #:command-p
   #:command-key #:command-words #:command-phrase
   #:command-lambda-list #:command-docstring #:command-function
   #:command-arity #:command-raw-argument-p #:command-required-parameters
   ;; dictionaries
   #:dictionary #:dictionary-p #:dictionary-name
   #:make-command-dictionary
   #:bind-command #:unbind-command #:bind-command-alias
   #:find-command #:lookup-command #:dictionary-commands
   #:check-naming-rule
   ;; command-line parser (IDENT and TOKEN name token types, with the
   ;; CL symbols INTEGER, FLOAT and STRING)
   #:parse-command #:ident #:token
   #:command-syntax-error
   #:command-syntax-error-command #:command-syntax-error-position
   #:simple-command-syntax-error
   ;; input contexts and readers
   #:input-context #:make-input-context #:input-context-p
   #:input-context-stream
   #:read-line-from-input-context #:read-sexp-from-input-context
   #:unread-line-from-input-context
   #:comma-command-read #:command-read
   #:input-command #:make-input-command #:input-command-p
   #:input-command-raw #:input-command-tokens
   #:input-command-invocation #:input-command-arguments
   #:input-command-raw-arguments
   ;; interactors (singletons) and their activations on the stack
   #:interactor #:make-interactor #:interactor-p
   #:interactor-name #:interactor-alias
   #:interactor-status #:interactor-prompt
   #:interactor-reader #:interactor-evaluator
   #:interactor-commands #:interactor-user-commands
   #:interactor-on-result
   #:interactor-documentation
   #:activation #:make-activation #:activation-p
   #:activation-interactor #:activation-state
   #:*command-interactor* #:*command-activation*
   #:*interactor-stack*
   #:push-interactor #:pop-interactor
   #:find-interactor #:find-activation
   ;; the registry: registration + listing, never routing (D7/D8)
   #:*interactors* #:register-interactor
   #:find-registered-interactor #:list-interactor-names
   #:make-prompt-function
   #:find-invocation-in-interactor #:find-invocation-in-stack
   #:find-interactor-command #:+system-command-word+
   #:call-command #:find-and-run-command
   #:interactor-loop #:interactor-return
   #:define-interactor #:define-command #:define-user-command))
