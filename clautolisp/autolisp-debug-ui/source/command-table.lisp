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
