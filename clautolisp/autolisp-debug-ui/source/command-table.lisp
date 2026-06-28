;;;; aldo command table + stacked command dictionaries.
;;;;
;;;; A debugger command is a mapping from a short/long name to a function
;;;; (command reference §8 "Defining commands"). Commands live in *dictionaries*
;;;; — the global debugger dictionary and the mode dictionaries (navigator,
;;;; inspector) layered over it; lookup walks a stack innermost-first, first
;;;; match wins (§8 "Command dictionaries (stacked dispatch)"). The §0
;;;; naming-consistency rule and the collision check are enforced per dictionary
;;;; at registration.

(in-package #:clautolisp.debug.ui)

(defstruct (command (:constructor %make-command))
  (key "" :type string)               ; the 1- or 2-letter (or punctuation) key
  (words '() :type list)              ; the word(s), lower-cased strings
  (phrase "" :type string)            ; the words joined with spaces
  (lambda-list '() :type list)        ; arity for the reader
  (docstring "" :type string)
  (function nil))

(defstruct (dictionary (:constructor %make-dictionary (name)))
  (name "" :type string)
  (table (make-hash-table :test 'equal) :type hash-table)) ; token-string -> command

(defun make-command-dictionary (name)
  (%make-dictionary (string name)))

(defvar *global-dictionary* (make-command-dictionary "global")
  "The global debugger command dictionary; mode dictionaries layer over it.")

(defparameter +debugger-escape-word+ "debugger"
  "The escape prefix: in a mode, `debugger TOKEN' routes TOKEN to the global
dictionary, reaching a command the mode shadows (command reference §8).")

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

;;; --- the §0 naming-consistency rule -----------------------------------

(defun words-initials (words)
  (coerce (mapcar (lambda (w) (char (string w) 0)) words) 'string))

(defun check-naming-rule (key words)
  "Enforce the §0 rule: a *word-named* command's key is the initial(s) of its
word(s). Punctuation / mnemonic keys (e.g. =.= , =>= , =?=) are exempt — the
rule is checked only when both the key and the word initials are alphabetic."
  (when (and words
             (every #'alpha-char-p key)
             (every (lambda (w) (alpha-char-p (char (string w) 0))) words))
    (unless (string-equal key (words-initials words))
      (error "command key ~S is not the initials of ~{~A~^ ~} (§0 naming rule)"
             key (mapcar #'string words)))))

;;; --- registration -----------------------------------------------------

(defun bind-debugger-command (names lambda-list docstring function
                              &optional (dictionary *global-dictionary*))
  "Register a command. NAMES is (KEY WORD [WORD2 …]); the key must be the
initial(s) of the word(s) (§0). Signals an error on a clash *in the same
dictionary* (clashes across dictionaries are fine — resolved by the stack).
Returns the COMMAND."
  (destructuring-bind (key &rest words) names
    (let* ((key (string-downcase (string key)))
           (words (mapcar (lambda (w) (string-downcase (string w))) words))
           (phrase (format nil "~{~A~^ ~}" words))
           (table (dictionary-table dictionary)))
      (check-naming-rule key words)
      (dolist (tok (list key phrase))
        (when (and (plusp (length tok)) (gethash tok table))
          (error "command token ~S already bound in dictionary ~A"
                 tok (dictionary-name dictionary))))
      (let ((cmd (%make-command :key key :words words :phrase phrase
                                :lambda-list lambda-list
                                :docstring (or docstring "") :function function)))
        (setf (gethash key table) cmd)
        (when (plusp (length phrase)) (setf (gethash phrase table) cmd))
        cmd))))

(defun unbind-debugger-command (names-or-key &optional (dictionary *global-dictionary*))
  "Remove a command (by its key, word phrase, or a NAMES list) from DICTIONARY.
Returns T if something was removed."
  (let* ((token (string-downcase
                 (string (if (consp names-or-key) (first names-or-key) names-or-key))))
         (cmd (find-command dictionary token)))
    (when cmd
      (remhash (command-key cmd) (dictionary-table dictionary))
      (when (plusp (length (command-phrase cmd)))
        (remhash (command-phrase cmd) (dictionary-table dictionary)))
      t)))

(defmacro define-debugger-command ((key &rest words) lambda-list docstring &body body)
  "CL sugar over BIND-DEBUGGER-COMMAND: register a global command whose body is
captured directly. (The AutoLISP-side define-debugger-command is the function
form — an alias of bind-debugger-command.)"
  `(bind-debugger-command (list ',key ,@(mapcar (lambda (w) `',w) words))
                          ',lambda-list ,docstring
                          (lambda ,lambda-list ,@body)))

;;; --- lookup -----------------------------------------------------------

(defun find-command (dictionary token)
  "The command bound to TOKEN (its key or word phrase) in DICTIONARY, or NIL."
  (gethash (string-downcase (string token)) (dictionary-table dictionary)))

(defun lookup-command (token &optional (stack (list *global-dictionary*)))
  "Find TOKEN's command by walking STACK innermost-first (first match wins).
Returns (values COMMAND DICTIONARY) or NIL."
  (loop :for dict :in stack
        :for cmd := (find-command dict token)
        :when cmd :do (return (values cmd dict))))

(defun command-arity (command)
  "How many arguments the reader should read after COMMAND (ignoring &optional
/ &rest markers, which simply allow fewer / more)."
  (count-if-not (lambda (s) (and (symbolp s) (char= #\& (char (symbol-name s) 0))))
                (command-lambda-list command)))

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
