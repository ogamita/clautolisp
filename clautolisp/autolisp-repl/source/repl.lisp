;;;; clautolisp/autolisp-repl/source/repl.lisp
;;;;
;;;; The AutoLISP REPL interactor (*AUTOLISP*) and the "lisp" window template,
;;;; relocated here from the clautolisp tool so a Lisp window is instantiable
;;;; over the shared evaluator anywhere below the tool (the ncurses debugger
;;;; panes, in particular). The rich per-turn behaviour stays in the tool and
;;;; is injected through *REPL-EVAL-HOOK* / *REPL-SOURCE-READER-HOOK*.

(in-package #:clautolisp.repl)

(defstruct repl-state
  "The AUTOLISP activation's per-INSTANCE state (windows-and-interactor-
templates.issue, the singleton split): the evaluation CONTEXT is the shared,
singleton evaluator; everything else belongs to this one REPL instance:
 - SESSION: the attached debug session (if any);
 - BREAK-ON-ERROR: the policy of this instance's turns;
 - VARIABLES: this instance's own values of the REPL variables named by
   *REPL-INSTANCE-VARIABLES* (the =:-= =:+= =:*= ... history), an alist
   (NAME . VALUE). Each instance sees its own history, as each slime-mrepl
   has its own =*=, while every other variable of the image is shared;
 - TRANSCRIPT: the instance's output lines, oldest first, for a UI that shows
   the instance in a window of its own.
The dialect is NOT here — it is consulted live at each read
(CURRENT-EVALUATION-DIALECT, design-revision D2), so a mid-session
=(setq *AUTOLISP-DIALECT* 'lax)= takes effect immediately."
  context session break-on-error
  (variables '())
  (transcript '()))

(defun repl-transcript-append (state lines)
  "Append LINES (a list of strings) to STATE's transcript. Returns the
transcript."
  (setf (repl-state-transcript state)
        (append (repl-state-transcript state) (copy-list lines))))

;;; --- per-instance REPL variables ----------------------------------------

(defvar *repl-instance-variables* '()
  "The names (strings) of the AutoLISP variables whose values belong to ONE REPL
instance rather than to the shared image: the clautolisp tool installs its
=:-= / =:+= / =:*= / =:/= history family here. Around each turn of an instance
CALL-WITH-REPL-INSTANCE-VARIABLES installs that instance's values and puts the
enclosing ones back afterwards. Empty = nothing is per instance.")

(defun %instance-context-p (context)
  (typep context 'clautolisp.autolisp-runtime:evaluation-context))

(defun call-with-repl-instance-variables (state thunk)
  "Call THUNK with the REPL instance STATE's own values of
*REPL-INSTANCE-VARIABLES* installed in its evaluation context (an unset one
reads NIL); record their values when THUNK exits (normally or not) as STATE's
own, and restore the values that were there before. This is a dynamic binding
done by hand, so two instances over one evaluator keep independent histories,
and a turn of one instance nested in another's (a debugger stop) leaves the
outer one's history intact."
  (let ((context (repl-state-context state))
        (names *repl-instance-variables*))
    (if (or (null names) (not (%instance-context-p context)))
        (funcall thunk)
        (let* ((symbols (mapcar #'intern-autolisp-symbol names))
               (outer (mapcar (lambda (symbol)
                                (nth-value 0 (lookup-variable symbol context)))
                              symbols)))
          (loop for name in names
                for symbol in symbols
                do (set-variable symbol
                                 (cdr (assoc name (repl-state-variables state)
                                             :test #'string=))
                                 context))
          (unwind-protect (funcall thunk)
            (setf (repl-state-variables state)
                  (loop for name in names
                        for symbol in symbols
                        collect (cons name (nth-value 0 (lookup-variable symbol context)))))
            (loop for symbol in symbols
                  for value in outer
                  do (set-variable symbol value context)))))))

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
    (call-with-repl-instance-variables
     state
     (lambda ()
       (funcall *repl-eval-hook*
                (second input)
                (repl-state-context state)
                (repl-state-session state)
                (repl-state-break-on-error state)
                (lambda () (interactor-return :terminated)))))))

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
otherwise the current one is shared. The new instance starts with an empty
history and transcript of its own (REPL-STATE)."
  (let ((eval-context (or (template-context-target context)
                          (current-evaluation-context))))
    (make-activation *autolisp* (make-repl-state :context eval-context :session nil))))

(define-interactor-template "lisp"
  :display-name "Lisp REPL"
  :description "An AutoLISP read-eval-print instance over the running evaluator"
  :interactor *autolisp*
  :constructor '%lisp-template-constructor
  :config-name "lisp")
