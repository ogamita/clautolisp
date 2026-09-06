;;;; clautolisp/autolisp-repl/source/package.lisp

(defpackage #:clautolisp.repl
  (:use #:cl)
  (:documentation
   "The AutoLISP REPL interactor, as a library (windows-and-interactor-
templates.issue). *AUTOLISP* is the singleton bottom REPL interactor and the
\"lisp\" window template; both live here — below the ncurses UI — so a Lisp
window can be instantiated over the shared evaluator anywhere, not only from
the clautolisp tool.

The reader and evaluator delegate the RICH per-turn behaviour (input history,
the dribble, navigation requests, the debug-session eval path, the
balanced/dribble-aware source reader) to installable hooks: the clautolisp
tool fills them at load; a bare library user (or a debugger lisp pane) gets a
minimal read-eval-print default. This is the *default-on-quit-policy* pattern:
the tool sits above this system, so it injects its behaviour rather than this
system reaching up.")
  (:import-from #:clautolisp.interactor
                #:define-interactor #:define-interactor-template
                #:make-activation #:activation-state #:*command-activation*
                #:comma-command-read #:interactor-return
                #:read-line-from-input-context #:template-context-target)
  (:import-from #:clautolisp.autolisp-runtime
                #:current-evaluation-dialect #:current-evaluation-context
                #:read-current-source #:autolisp-eval-toplevel-progn)
  (:export
   #:*autolisp*
   #:repl-state #:make-repl-state #:repl-state-p
   #:repl-state-context #:repl-state-session #:repl-state-break-on-error
   ;; the injectable rich-behaviour hooks (installed by the clautolisp tool)
   #:*repl-eval-hook* #:*repl-source-reader-hook*))
