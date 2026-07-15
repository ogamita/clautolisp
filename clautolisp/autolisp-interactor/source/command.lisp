;;;; Commands and command dictionaries.
;;;;
;;;; A command is a mapping from a short/long name to a function (aldo command
;;;; reference §8 "Defining commands"). Commands live in *dictionaries*; each
;;;; interactor carries a system dictionary and a user dictionary layered over
;;;; it, and lookup walks a stack innermost-first, first match wins (§8
;;;; "Command dictionaries (stacked dispatch)"). The §0 naming-consistency
;;;; rule and the collision check are enforced per dictionary at registration.
;;;;
;;;; This is the generic machinery, moved here from the debugger UI's
;;;; command-table (clautolisp.debug.ui re-exports it); the debugger-specific
;;;; parts — the global dictionary, the escape word, the AutoLISP registration
;;;; hook — stay there.

(in-package #:clautolisp.interactor)

(defstruct (command (:constructor %make-command))
  ;; A command has two invocations: its KEY (short) and its PHRASE (long).
  ;; WORDS is the *ordered* sequence of words making up the ONE phrase that
  ;; is the command's long name — ("list" "breakpoints") names `list
  ;; breakpoints' — NOT a set of alternative names. PHRASE is derived, never
  ;; supplied: BIND-COMMAND computes it by joining the words with spaces.
  ;; (Alternative spellings are separate BIND-COMMAND-ALIAS entries.)
  (key "" :type string)               ; the 1- or 2-letter (or punctuation) key
  (words '() :type list)              ; ordered words of the long name, lower-cased
  (phrase "" :type string)            ; derived: the words joined with spaces
  (lambda-list '() :type list)        ; arity for the reader; (&whole VAR) = raw
  (docstring "" :type string)
  (function nil))

(defstruct (dictionary (:constructor %make-dictionary (name)))
  (name "" :type string)
  (table (make-hash-table :test 'equal) :type hash-table)) ; token-string -> command

(defun make-command-dictionary (name)
  (%make-dictionary (string name)))

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

(defun bind-command (dictionary names lambda-list docstring function)
  "Register a command in DICTIONARY. NAMES is (KEY WORD [WORD2 …]): KEY is
the short name, and the WORDs are the *ordered* sequence making up the
command's single long name — one phrase (=list breakpoints=), not a set of
alternatives. The phrase is derived here (the words joined with spaces) and
is never supplied; the key must be the words' initials (§0). The command is
invocable by its key and by its full phrase (use BIND-COMMAND-ALIAS for
alternative spellings). Signals an error on a clash *in the same dictionary*
\(clashes across dictionaries are fine — resolved by the stack). Returns the
COMMAND."
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

(defun unbind-command (dictionary names-or-key)
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

(defun bind-command-alias (dictionary token command-or-token)
  "Bind an extra invocation TOKEN for an already-registered command (e.g. a
legacy `,jump' alias for `jump'). COMMAND-OR-TOKEN is the COMMAND itself or a
token already bound in DICTIONARY. Aliases are exempt from the naming rule.
Returns the COMMAND."
  (let ((cmd (if (command-p command-or-token)
                 command-or-token
                 (or (find-command dictionary command-or-token)
                     (error "no command ~S in dictionary ~A to alias"
                            command-or-token (dictionary-name dictionary)))))
        (token (string-downcase (string token))))
    (when (gethash token (dictionary-table dictionary))
      (error "command token ~S already bound in dictionary ~A"
             token (dictionary-name dictionary)))
    (setf (gethash token (dictionary-table dictionary)) cmd)))

;;; --- lookup -----------------------------------------------------------

(defun find-command (dictionary token)
  "The command bound to TOKEN (its key or word phrase) in DICTIONARY, or NIL."
  (gethash (string-downcase (string token)) (dictionary-table dictionary)))

(defun lookup-command (token stack)
  "Find TOKEN's command by walking STACK of dictionaries innermost-first
\(first match wins). Returns (values COMMAND DICTIONARY) or NIL."
  (loop :for dict :in stack
        :for cmd := (find-command dict token)
        :when cmd :do (return (values cmd dict))))

(defun dictionary-commands (dictionary)
  "The distinct commands registered in DICTIONARY, sorted by key."
  (let ((commands '()))
    (maphash (lambda (token cmd)
               (declare (ignore token))
               (pushnew cmd commands))
             (dictionary-table dictionary))
    (sort commands #'string< :key #'command-key)))

;;; --- arity ------------------------------------------------------------

(defun command-raw-argument-p (command)
  "True when COMMAND declared the (&WHOLE VAR) lambda-list: its function
receives the raw, untokenized argument string (or NIL) — for commands that
parse their own argument, e.g. one embedding a Lisp form."
  (let ((ll (command-lambda-list command)))
    (and (= 2 (length ll)) (eq (first ll) '&whole))))

(defun command-required-parameters (command)
  "The required parameters of COMMAND — those the reader prompts for when
missing. Empty for a raw-argument (&WHOLE) command."
  (let ((ll (command-lambda-list command)))
    (if (command-raw-argument-p command)
        '()
        (loop :for item :in ll
              :until (member item lambda-list-keywords)
              :collect item))))

(defun command-arity (command)
  "How many arguments the reader should read after COMMAND (ignoring &optional
/ &rest markers, which simply allow fewer / more)."
  (count-if-not (lambda (s) (and (symbolp s) (char= #\& (char (symbol-name s) 0))))
                (command-lambda-list command)))
