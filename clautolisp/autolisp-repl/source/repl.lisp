;;;; clautolisp/autolisp-repl/source/repl.lisp
;;;;
;;;; The AutoLISP REPL interactor (*AUTOLISP*) and the "lisp" window template,
;;;; relocated here from the clautolisp tool so a Lisp window is instantiable
;;;; over the shared evaluator anywhere below the tool (the ncurses debugger
;;;; panes, in particular). The rich per-turn behaviour stays in the tool and
;;;; is injected through *REPL-EVAL-HOOK* / *REPL-SOURCE-READER-HOOK*.

(in-package #:clautolisp.repl)

(defstruct repl-state
  "The AUTOLISP activation's per-run state: the evaluation CONTEXT (the shared
evaluator), the attached debug SESSION (if any), and the BREAK-ON-ERROR policy.
The dialect is NOT here — it is consulted live at each read
(CURRENT-EVALUATION-DIALECT, design-revision D2), so a mid-session
=(setq *AUTOLISP-DIALECT* 'lax)= takes effect immediately."
  context session break-on-error)

;;; --- the injectable rich-behaviour hooks -------------------------------

(defun %default-repl-source-reader (dialect)
  "The library's minimal source reader (used until the tool installs its
balanced/dribble-aware one): one input line is the turn's source. Returns a
closure over an input-context yielding (:SOURCE TEXT) or :EOF."
  (declare (ignore dialect))
  (lambda (input-context)
    (let ((line (read-line-from-input-context input-context)))
      (if (eq line :eof) :eof (list :source line)))))

(defun %default-repl-eval (source context session break-on-error exit)
  "The library's minimal per-turn evaluator (a bare read-eval-print) used until
the tool installs its rich *REPL-EVAL-HOOK*. Reads SOURCE under CONTEXT,
evaluates, and prints the result."
  (declare (ignore session break-on-error exit))
  (handler-case
      (let* ((forms  (read-current-source source :source-name "<repl>" :context context))
             (result (autolisp-eval-toplevel-progn forms context)))
        (format t "~&~A~%" (princ-to-string result))
        result)
    (error (condition)
      (format *error-output* "~&; error: ~A~%" condition))))

(defvar *repl-source-reader-hook* '%default-repl-source-reader
  "(function (dialect)) -> a source-reader closure over an input-context. The
clautolisp tool installs its balanced/dribble-aware reader; the default reads
one line.")

(defvar *repl-eval-hook* '%default-repl-eval
  "The per-turn REPL evaluator:
(function (source context session break-on-error exit)). The clautolisp tool
installs its rich version (history / dribble / navigation / debug-session eval
path); the default is a minimal read-eval-print.")

;;; --- the interactor ----------------------------------------------------

(defun %autolisp-reader (input-context)
  "The *AUTOLISP* reader: a `,command' line dispatches; anything else reads one
turn via *REPL-SOURCE-READER-HOOK* under the dialect in force NOW."
  (let ((state (activation-state *command-activation*)))
    (comma-command-read input-context
                        (funcall *repl-source-reader-hook*
                                 (current-evaluation-dialect (repl-state-context state))))))

(defun %autolisp-evaluate (input)
  "The *AUTOLISP* evaluator: one REPL turn via *REPL-EVAL-HOOK* over this
activation's context and session."
  (let ((state (activation-state *command-activation*)))
    (funcall *repl-eval-hook*
             (second input)
             (repl-state-context state)
             (repl-state-session state)
             (repl-state-break-on-error state)
             (lambda () (interactor-return :terminated)))))

(define-interactor *autolisp*
  :name "AUTOLISP" :alias "LISP"
  :prompt "_$ "
  :reader '%autolisp-reader
  :evaluator '%autolisp-evaluate
  :documentation "The clautolisp Lisp REPL — the bottom interactor, always
under every stacked mode (design-revision D3): reads AutoLISP forms; a
`,command' line runs a REPL command. Routable as `autolisp CMD' or `lisp
CMD' from any inner mode; a user command registered here
((clal-define-command \"AUTOLISP\" …)) is reachable everywhere — the
\"global\" user command (D6). The prompt is late-bound (an indication of
the current dialect can come later).")

;;; --- the "lisp" window template ----------------------------------------

(defun %lisp-template-constructor (context)
  "Build an AUTOLISP (lisp REPL) activation over the shared evaluation context —
a new REPL UI instance multiplexing the one evaluator (windows-and-interactor-
templates.issue). CONTEXT's TARGET may name an explicit evaluation context;
otherwise the current one is shared."
  (let ((eval-context (or (template-context-target context)
                          (current-evaluation-context))))
    (make-activation *autolisp* (make-repl-state :context eval-context :session nil))))

(define-interactor-template "lisp"
  :display-name "Lisp REPL"
  :description "An AutoLISP read-eval-print instance over the running evaluator"
  :interactor *autolisp*
  :constructor '%lisp-template-constructor
  :config-name "lisp")
