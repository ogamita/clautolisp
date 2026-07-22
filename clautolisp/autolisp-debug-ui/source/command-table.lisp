;;;; aldo command table: the debugger-specific layer over the generic
;;;; command/dictionary machinery (clautolisp.interactor, re-exported here).
;;;;
;;;; A debugger command is a mapping from a short/long name to a function
;;;; (command reference §8 "Defining commands"). Commands live in
;;;; *dictionaries* — each interactor carries a system dictionary and a user
;;;; dictionary layered over it; lookup walks the interactor stack
;;;; innermost-first, user before system at each level, first match wins (§8
;;;; "Command dictionaries (stacked dispatch)"). There is NO global user
;;;; table (interactor-design-revision.issue D6): a "global" user command is
;;;; one defined on the AUTOLISP interactor, which is always at the bottom
;;;; of the stack. This file keeps what is the debugger's own: the escape
;;;; word, the dispatch dynamic variables, and the AutoLISP-side command
;;;; registration hooks (CLAL-DEFINE-COMMAND and the deprecated
;;;; CLAL-DEFINE-DEBUGGER-COMMAND).

(in-package #:clautolisp.debug.ui)

(defparameter +debugger-escape-word+ "debugger"
  "The historical escape prefix: `debugger TOKEN' routes TOKEN to the built-in
dictionary, reaching a command a user / mode command shadows (command
reference §8). The systematic form is the interactor framework's
CLAUTOLISP.INTERACTOR:+SYSTEM-COMMAND-WORD+ — `command TOKEN', like bash's
`command' — which the dispatcher accepts equally.")

;;; The debugger dynamic vars a command body reads to reach the live session
;;; (the chosen calling convention): the dispatcher binds them, and a command
;;; function receives only its parsed positional arguments.
(defvar *debugger-ui* nil "The UI dispatching the current command.")
(defvar *debugger-session* nil "The debugger-session of the current command.")
(defvar *debugger-hit* nil "The HIT at the current stop, or NIL.")

;;; --- registration -----------------------------------------------------

(defun interactor-user-dictionary (interactor-name)
  "The USER dictionary of the registered interactor named INTERACTOR-NAME —
where AutoLISP- and user-defined commands land, shadowing the interactor's
system commands. Signals an error when no such interactor is registered
(CLAL-LIST-INTERACTOR-NAMES lists them)."
  (let ((interactor (clautolisp.interactor:find-registered-interactor
                     interactor-name)))
    (unless interactor
      (error "No interactor is named ~S — one of ~{~A~^, ~} expected."
             interactor-name (clautolisp.interactor:list-interactor-names)))
    (clautolisp.interactor:interactor-user-commands interactor)))

(defun bind-debugger-command (names lambda-list docstring function
                              &optional dictionary)
  "Register a command into DICTIONARY — the ALDO user dictionary when NIL.
NAMES is (KEY WORD [WORD2 …]): the WORDs are the ordered sequence of the
command's single long name — one phrase, derived by joining them, not
alternative names — and the key must be their initials (§0). Signals an
error on a clash *in the same dictionary* (clashes across dictionaries are
fine — resolved by the stack). Returns the COMMAND."
  (bind-command (or dictionary (interactor-user-dictionary "ALDO"))
                names lambda-list docstring function))

(defun unbind-debugger-command (names-or-key &optional dictionary)
  "Remove a command (by its key, word phrase, or a NAMES list) from
DICTIONARY — the ALDO user dictionary when NIL. Returns T if something was
removed."
  (unbind-command (or dictionary (interactor-user-dictionary "ALDO"))
                  names-or-key))

(defmacro define-debugger-command ((key &rest words) lambda-list docstring &body body)
  "CL sugar over BIND-DEBUGGER-COMMAND: register an ALDO user command whose
body is captured directly. (The AutoLISP-side registration is
CLAL-DEFINE-COMMAND \"ALDO\" — or its deprecated equivalent
clal-define-debugger-command.)"
  `(bind-debugger-command (list ',key ,@(mapcar (lambda (w) `',w) words))
                          ',lambda-list ,docstring
                          (lambda ,lambda-list ,@body)))

;;; --- AutoLISP-defined commands (command reference §8) -----------------
;;;
;;; The AutoLISP-side registration: a user .lsp registers a command whose
;;; body is an AutoLISP function, into the user dictionary of a NAMED
;;; interactor (design-revision D7) — CLAL-DEFINE-COMMAND (builtins-core)
;;; reaches here through *define-interactor-command-hook*, and the
;;; deprecated CLAL-DEFINE-DEBUGGER-COMMAND through
;;; *debug-define-command-hook*, so builtins-core needs no dependency on
;;; this UI layer.

(defun %autolisp-command-lambda-list (function)
  "A reader lambda-list (dummy symbols) matching FUNCTION's required arity, with
&rest when it is variadic; (&rest r) when the arity cannot be determined."
  (let ((parts (ignore-errors
                 (multiple-value-list
                  (clautolisp.autolisp-runtime:split-usubr-lambda-list
                   (clautolisp.autolisp-runtime:autolisp-usubr-lambda-list function))))))
    (if parts
        (destructuring-bind (required &optional rest-param locals) parts
          (declare (ignore locals))
          (append (loop repeat (length required) collect (gensym "ARG"))
                  (when rest-param (list '&rest (gensym "REST")))))
        (list '&rest (gensym "REST")))))

(defun %autolisp-command-function (function)
  "Wrap the AutoLISP FUNCTION as a command function: applied — with
debugging suppressed, in the stop's evaluation context — to the command's
parsed string arguments (as AutoLISP strings); keeps the loop reading
(returns NIL)."
  (lambda (&rest args)
    (let ((clautolisp.autolisp-runtime:*debugging* nil))
      (apply #'clautolisp.autolisp-runtime:call-autolisp-function function
             (mapcar (lambda (a)
                       (clautolisp.autolisp-runtime:make-autolisp-string (or a "")))
                     args)))
    nil))

(defun register-interactor-command (interactor-name names function doc)
  "Register an AutoLISP-defined user command of the interactor named
INTERACTOR-NAME (CLAL-DEFINE-COMMAND, design-revision D7). NAMES is
(KEY WORD…) of CL strings; FUNCTION is an AutoLISP function (see
%AUTOLISP-COMMAND-FUNCTION). Returns the COMMAND."
  (bind-command (interactor-user-dictionary interactor-name)
                names (%autolisp-command-lambda-list function) (or doc "")
                (%autolisp-command-function function)))

(defun register-autolisp-command (names function doc)
  "The deprecated CLAL-DEFINE-DEBUGGER-COMMAND registration: the equivalent
of (CLAL-DEFINE-COMMAND \"ALDO\" …). Returns the COMMAND."
  (register-interactor-command "ALDO" names function doc))

;; Install the registration hooks so CLAL-DEFINE-COMMAND /
;; CLAL-LIST-INTERACTOR-NAMES / CLAL-DEFINE-DEBUGGER-COMMAND reach here.
(setf clautolisp.autolisp-runtime:*debug-define-command-hook*
      #'register-autolisp-command
      clautolisp.autolisp-runtime:*define-interactor-command-hook*
      #'register-interactor-command
      clautolisp.autolisp-runtime:*list-interactor-names-hook*
      #'clautolisp.interactor:list-interactor-names)
