;;;; aldo command table: the debugger-specific layer over the generic
;;;; command/dictionary machinery (clautolisp.interactor, re-exported here).
;;;;
;;;; A debugger command is a mapping from a short/long name to a function
;;;; (command reference §8 "Defining commands"). Commands live in
;;;; *dictionaries* — the global debugger dictionary and the mode dictionaries
;;;; (navigator, inspector) layered over it; lookup walks a stack
;;;; innermost-first, first match wins (§8 "Command dictionaries (stacked
;;;; dispatch)"). This file keeps what is the debugger's own: the global
;;;; dictionary, the escape word, the dispatch dynamic variables, and the
;;;; AutoLISP-side command registration hook.

(in-package #:clautolisp.debug.ui)

(defvar *global-dictionary* (make-command-dictionary "global")
  "The global debugger command dictionary; mode dictionaries layer over it.")

(defparameter +debugger-escape-word+ "debugger"
  "The historical escape prefix: `debugger TOKEN' routes TOKEN to the built-in
dictionary, reaching a command a user / mode command shadows (command
reference §8). The systematic form is the interactor framework's
CLAUTOLISP.INTERACTOR:+SYSTEM-COMMAND-WORD+ — `command TOKEN', like bash's
`command' — which the dispatcher accepts equally.")

(defvar *active-command-dictionaries* nil
  "The dictionary stack the UI dispatcher consults, innermost-first; NIL means
just *GLOBAL-DICTIONARY*. A mode (navigator, inspector) pushes its dictionary
here while active (command reference §8 stacked dispatch).")

(defun active-command-dictionaries ()
  "The current dictionary stack: the active mode dictionaries over the global."
  (or *active-command-dictionaries* (list *global-dictionary*)))

;;; The debugger dynamic vars a command body reads to reach the live session
;;; (the chosen calling convention): the dispatcher binds them, and a command
;;; function receives only its parsed positional arguments.
(defvar *debugger-ui* nil "The UI dispatching the current command.")
(defvar *debugger-session* nil "The debugger-session of the current command.")
(defvar *debugger-hit* nil "The HIT at the current stop, or NIL.")

;;; --- registration -----------------------------------------------------

(defun bind-debugger-command (names lambda-list docstring function
                              &optional (dictionary *global-dictionary*))
  "Register a command. NAMES is (KEY WORD [WORD2 …]): the WORDs are the
ordered sequence of the command's single long name — one phrase, derived by
joining them, not alternative names — and the key must be their initials
(§0). Signals an error on a clash *in the same dictionary* (clashes across
dictionaries are fine — resolved by the stack). Returns the COMMAND."
  (bind-command dictionary names lambda-list docstring function))

(defun unbind-debugger-command (names-or-key &optional (dictionary *global-dictionary*))
  "Remove a command (by its key, word phrase, or a NAMES list) from DICTIONARY.
Returns T if something was removed."
  (unbind-command dictionary names-or-key))

(defmacro define-debugger-command ((key &rest words) lambda-list docstring &body body)
  "CL sugar over BIND-DEBUGGER-COMMAND: register a global command whose body is
captured directly. (The AutoLISP-side define-debugger-command is the function
form — an alias of bind-debugger-command.)"
  `(bind-debugger-command (list ',key ,@(mapcar (lambda (w) `',w) words))
                          ',lambda-list ,docstring
                          (lambda ,lambda-list ,@body)))

;;; --- AutoLISP-defined commands (command reference §8) -----------------
;;;
;;; The AutoLISP-side define-debugger-command: a user .lsp registers a command
;;; whose body is an AutoLISP function. CLAL-DEFINE-DEBUGGER-COMMAND (builtins-
;;; core) reaches here through *debug-define-command-hook*, so builtins-core
;;; needs no dependency on this UI layer.

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

(defun register-autolisp-command (names function doc)
  "Register an AutoLISP-defined debugger command (command reference §8). NAMES is
(KEY WORD…) of CL strings; FUNCTION is an AutoLISP function applied — with
debugging suppressed, in the stop's evaluation context — to the command's parsed
string arguments (as AutoLISP strings). The command keeps the loop reading
(returns NIL). Returns the COMMAND."
  (bind-debugger-command
   names (%autolisp-command-lambda-list function) (or doc "")
   (lambda (&rest args)
     (let ((clautolisp.autolisp-runtime:*debugging* nil))
       (apply #'clautolisp.autolisp-runtime:call-autolisp-function function
              (mapcar (lambda (a)
                        (clautolisp.autolisp-runtime:make-autolisp-string (or a "")))
                      args)))
     nil)))

;; Install the registration hook so CLAL-DEFINE-DEBUGGER-COMMAND reaches here.
(setf clautolisp.autolisp-runtime:*debug-define-command-hook* #'register-autolisp-command)
