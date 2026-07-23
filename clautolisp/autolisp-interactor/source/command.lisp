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
  ;; LAMBDA-LIST: arity for the reader; (&whole VAR) = raw; a parameter may
  ;; be a (NAME TYPE) sublist declaring a converted argument (typed command
  ;; arguments — see +COMMAND-ARGUMENT-TYPES+).
  (lambda-list '() :type list)
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

;;; --- typed parameters (interactor-unification: typed command arguments) --

(defparameter +command-argument-types+ '(string integer float ident sexp)
  "The declarable command parameter types. A lambda-list entry may be a
(NAME TYPE) sublist instead of a bare symbol; the argument marshaling
\(CALL-COMMAND, and the dumb UI's legacy dispatch) then CONVERTS the token's
text before the call:
  STRING  — the token's text, unchanged (what a bare NAME means too);
  INTEGER — the text parsed as an integer (the whole token must parse);
  FLOAT   — a Lisp real read from the text;
  IDENT   — the text, which must be an identifier token;
  SEXP    — the text read as one Lisp form, *READ-EVAL* disabled.
Types are matched by name, so a client package need not import IDENT / SEXP.")

(defun command-parameter-name (parameter)
  "The name of the declared lambda-list PARAMETER: a bare symbol names a
plain STRING parameter, a (NAME TYPE) sublist a converted one."
  (if (consp parameter) (first parameter) parameter))

(defun command-parameter-type (parameter)
  "The declared type of the lambda-list PARAMETER — one of
+COMMAND-ARGUMENT-TYPES+ (canonicalized, matched by name); STRING for a
bare symbol."
  (if (consp parameter)
      (or (find (second parameter) +command-argument-types+ :test #'string-equal)
          (error "unknown command parameter type ~S in ~S (one of ~{~A~^/~} expected)"
                 (second parameter) parameter +command-argument-types+))
      'string))

(defun check-command-lambda-list (lambda-list)
  "Validate a command's declared LAMBDA-LIST at registration: either exactly
\(&WHOLE VAR) — the raw convention, exclusive of everything else, typed
entries included — or positional entries that are bare symbols (lambda-list
keywords included) or (NAME TYPE) sublists, TYPE one of
+COMMAND-ARGUMENT-TYPES+. Returns LAMBDA-LIST; signals an error otherwise."
  (if (member '&whole lambda-list)
      (unless (and (= 2 (length lambda-list))
                   (eq '&whole (first lambda-list))
                   (symbolp (second lambda-list)))
        (error "&whole in a command lambda-list must be exactly (&whole VAR), got ~S"
               lambda-list))
      (dolist (parameter lambda-list)
        (unless (or (symbolp parameter)
                    (and (consp parameter)
                         (= 2 (length parameter))
                         (symbolp (first parameter))
                         (find (second parameter) +command-argument-types+
                               :test #'string-equal)))
          (error "invalid command lambda-list entry ~S in ~S: NAME or (NAME TYPE) ~
                  expected, TYPE one of ~{~A~^/~}"
                 parameter lambda-list +command-argument-types+))))
  lambda-list)

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
      (check-command-lambda-list lambda-list)
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
missing. The declared specs: a typed parameter stays a (NAME TYPE) sublist
\(COMMAND-PARAMETER-NAME / COMMAND-PARAMETER-TYPE take them apart). Empty
for a raw-argument (&WHOLE) command."
  (let ((ll (command-lambda-list command)))
    (if (command-raw-argument-p command)
        '()
        (loop :for item :in ll
              :until (member item lambda-list-keywords)
              :collect item))))

(defun command-arity (command)
  "How many arguments the reader should read after COMMAND (ignoring &optional
/ &rest markers, which simply allow fewer / more). A (NAME TYPE) sublist
counts like a bare NAME."
  (count-if-not (lambda (s) (and (symbolp s) (char= #\& (char (symbol-name s) 0))))
                (command-lambda-list command)))

;;; --- argument conversion (typed command arguments) ----------------------

(defun ident-text-p (text)
  "True when TEXT matches the command parser's ident token:
/[A-Za-z][-A-Za-z0-9]*/ (parse-command's classification)."
  (flet ((letterp (ch) (or (char<= #\A ch #\Z) (char<= #\a ch #\z)))
         (digitp (ch) (char<= #\0 ch #\9)))
    (and (plusp (length text))
         (letterp (char text 0))
         (every (lambda (ch) (or (letterp ch) (digitp ch) (char= ch #\-)))
                text))))

(define-condition command-argument-error (error)
  ((command   :initarg :command   :reader command-argument-error-command)
   (parameter :initarg :parameter :reader command-argument-error-parameter)
   (text      :initarg :text      :reader command-argument-error-text))
  (:documentation
   "An argument token's text does not convert to its parameter's declared
type. The marshalers (CALL-COMMAND, the dumb UI dispatch) report it and skip
the call, keeping the command loop alive.")
  (:report (lambda (condition stream)
             (let ((command (command-argument-error-command condition))
                   (parameter (command-argument-error-parameter condition)))
               (format stream "the ~A command needs a ~(~A~) for ~(~A~), got ~S"
                       (if (plusp (length (command-phrase command)))
                           (command-phrase command)
                           (command-key command))
                       (command-parameter-type parameter)
                       (command-parameter-name parameter)
                       (command-argument-error-text condition))))))

(defun %read-argument-form (text)
  "TEXT read as one Lisp form, *READ-EVAL* disabled, the whole text consumed.
Returns (values FORM T), or (values NIL NIL) when it does not read."
  (handler-case
      (let ((*read-eval* nil))
        (multiple-value-bind (form position) (read-from-string text)
          (if (>= position (length text))
              (values form t)
              (values nil nil))))
    (error () (values nil nil))))

(defun convert-command-argument (command parameter text)
  "Convert TEXT — one argument token's text, a string, or NIL for a missing
argument — to PARAMETER's declared type (COMMAND-PARAMETER-TYPE; a bare
symbol declares STRING, the text unchanged). NIL stays NIL. Signals
COMMAND-ARGUMENT-ERROR when TEXT does not convert."
  (let ((type (command-parameter-type parameter)))
    (flet ((fail ()
             (error 'command-argument-error
                    :command command :parameter parameter :text text)))
      (cond
        ((null text) nil)
        ((eq type 'string) text)
        ((eq type 'integer)
         (multiple-value-bind (value position)
             (parse-integer text :junk-allowed t)
           (if (and value (= position (length text))) value (fail))))
        ((eq type 'float)
         (multiple-value-bind (form okp) (%read-argument-form text)
           (if (and okp (realp form)) form (fail))))
        ((eq type 'ident)
         (if (ident-text-p text) text (fail)))
        ((eq type 'sexp)
         (multiple-value-bind (form okp) (%read-argument-form text)
           (if okp form (fail))))))))

(defun %positional-and-rest-parameters (lambda-list)
  "The positional parameter specs of LAMBDA-LIST and its &rest spec (NIL when
none) as two values — (NAME TYPE) sublists kept whole, lambda-list keywords
dropped."
  (let ((positional '()) (rest nil) (items lambda-list))
    (loop :while items
          :do (let ((item (pop items)))
                (cond ((eq item '&rest) (setf rest (pop items)))
                      ((and (symbolp item) (member item lambda-list-keywords)))
                      (t (push item positional)))))
    (values (nreverse positional) rest)))

(defun convert-command-arguments (command texts)
  "TEXTS (the argument tokens' texts) converted per COMMAND's declared
lambda-list, positionally; the texts beyond the positional parameters
convert per the &rest spec — (&rest (VAR TYPE)) converts each collected
element, an untyped &rest leaves them strings. Signals
COMMAND-ARGUMENT-ERROR on a text that does not convert."
  (multiple-value-bind (positional rest)
      (%positional-and-rest-parameters (command-lambda-list command))
    (loop :for text :in texts
          :collect (convert-command-argument
                    command (if positional (pop positional) rest) text))))
