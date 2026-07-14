;;;; Interactors and the single interaction loop.
;;;;
;;;; An interactor bundles what distinguishes one command loop from another:
;;;; a name, a status display, a prompt, a reader (how the input line is
;;;; parsed), an evaluator (what a bare Lisp form means there), and its two
;;;; command dictionaries. INTERACTOR-LOOP drives whichever interactor is on
;;;; top of *INTERACTOR-STACK*; commands may push a new interactor (entering
;;;; a mode within the same loop), pop one (leaving it), call INTERACTOR-LOOP
;;;; recursively (e.g. invoke-debugger, which is specified as a recursive
;;;; REPL), or INTERACTOR-RETURN a value out of the innermost loop.

(in-package #:clautolisp.interactor)

(deftype function-designator () `(or symbol function))

(defstruct (interactor (:constructor %make-interactor))
  (name          "interactor" :type string)
  ;; STATUS: (function (output-stream)) rendering the mode's view before each
  ;; prompt (the navigator's marked form, the editor's selection); NIL = none.
  (status        nil          :type (or null function-designator))
  ;; PROMPT: a string, or (function (output-stream)); NIL prompts "NAME> ".
  (prompt        nil          :type (or null string function-designator))
  ;; READER: (function (input-context)) returning an INPUT-COMMAND, a sexp,
  ;; :BLANK or :EOF (COMMA-COMMAND-READ, COMMAND-READ, or a custom one).
  (reader        #'command-read :type function-designator)
  ;; EVALUATOR: (function (sexp)) evaluating-and-printing a bare Lisp form —
  ;; the REPL evaluates globally, the debugger in the selected frame; NIL
  ;; reports that there is no evaluator here.
  (evaluator     nil          :type (or null function-designator))
  (commands      nil          :type (or null dictionary))
  (user-commands nil          :type (or null dictionary))
  (documentation nil          :type (or null string)))

(defun make-interactor (&rest initargs &key (name "interactor") commands user-commands
                        &allow-other-keys)
  "Make an interactor; the system and user command dictionaries default to
fresh ones named after it."
  (apply #'%make-interactor
         (append initargs
                 (list :name name
                       :commands (or commands (make-command-dictionary name))
                       :user-commands
                       (or user-commands
                           (make-command-dictionary
                            (concatenate 'string (string name) "-user")))))))

(defvar *interactor-stack* '()
  "The stack of live interactors, innermost first. Commands are searched down
this stack — user dictionaries before system dictionaries at each level — so
user commands shadow system commands and inner loops shadow outer loops.")

(defun push-interactor (interactor)
  "Enter INTERACTOR: subsequent turns of the running INTERACTOR-LOOP read its
prompt and dictionaries. Returns INTERACTOR."
  (push interactor *interactor-stack*)
  interactor)

(defun pop-interactor ()
  "Leave the top interactor. A loop whose stack shrinks below its entry depth
returns."
  (pop *interactor-stack*))

(defun find-interactor (name &optional (stack *interactor-stack*))
  "The interactor called NAME (case-insensitively) on STACK, or NIL."
  (find (string name) stack :key #'interactor-name :test #'equalp))

(defun make-prompt-function (who)
  "A prompt function printing `[DEPTH]WHO> ', DEPTH the interactor stack depth."
  (lambda (stream)
    (format stream "~&[~D]~A> " (length *interactor-stack*) who)))

;;; --- finding a command invocation on the interactor stack ---------------

(defun find-invocation-in-interactor (invocation interactor)
  "The command INVOCATION (a token string) names in INTERACTOR — its user
dictionary first, so user commands shadow system commands."
  (or (and (interactor-user-commands interactor)
           (find-command (interactor-user-commands interactor) invocation))
      (and (interactor-commands interactor)
           (find-command (interactor-commands interactor) invocation))))

(defun find-invocation-in-stack (invocation &optional (stack *interactor-stack*))
  "Search STACK innermost-first for INVOCATION (a token string).
Returns (values COMMAND INTERACTOR) or NIL."
  (dolist (interactor stack nil)
    (let ((command (find-invocation-in-interactor invocation interactor)))
      (when command
        (return (values command interactor))))))

(defun %find-longest-prefix (idents stack)
  "Resolve the longest prefix of IDENTS to a command, innermost interactor
first: at each level `list breakpoints' is found before `list'.
Returns (values COMMAND PREFIX-LENGTH INTERACTOR) or NIL."
  (dolist (interactor stack nil)
    (loop :for k :from (length idents) :downto 1
          :do (let* ((phrase (format nil "~{~A~^ ~}" (subseq idents 0 k)))
                     (command (find-invocation-in-interactor phrase interactor)))
                (when command
                  (return-from %find-longest-prefix
                    (values command k interactor)))))))

(defun find-interactor-command (input &optional (stack *interactor-stack*))
  "Resolve INPUT (an INPUT-COMMAND) against STACK. When the first ident names
an interactor on the stack and a command follows, the command is looked up in
that interactor only (`aldo break 42' runs the debugger's `break' from any
inner loop); otherwise the longest ident prefix is resolved down the stack.
Returns (values COMMAND ARGUMENT-TOKENS WORDS-CONSUMED INTERACTOR), or NIL
when nothing matches."
  (let ((invocation (input-command-invocation input))
        (tokens (input-command-tokens input)))
    (when invocation
      ;; explicit routing: INTERACTOR-NAME COMMAND …
      (when (rest invocation)
        (let ((interactor (find-interactor (first invocation) stack)))
          (when interactor
            (multiple-value-bind (command k)
                (%find-longest-prefix (rest invocation) (list interactor))
              (when command
                (return-from find-interactor-command
                  (values command (nthcdr (1+ k) tokens) (1+ k) interactor)))))))
      (multiple-value-bind (command k interactor)
          (%find-longest-prefix invocation stack)
        (when command
          (values command (nthcdr k tokens) k interactor))))))

;;; --- executing a command with parameters ---------------------------------

(defun %prompt-for-argument (parameter output input-context)
  "Prompt for a missing required PARAMETER and read one token; NIL at EOF."
  (format output "~A? " (string-downcase (string parameter)))
  (finish-output output)
  (let ((line (if input-context
                  (read-line-from-input-context input-context)
                  (read-line *standard-input* nil :eof))))
    (unless (eq line :eof)
      (let ((tokens (handler-case (parse-command line)
                      (command-syntax-error () nil))))
        (when (cdr tokens)
          (warn "Ignored tokens: ~{~A~^ ~}" (mapcar #'cdr (cdr tokens))))
        (cdr (first tokens))))))

(defun call-command (command arguments
                     &key raw (output *standard-output*)
                          (error-output *error-output*) input-context)
  "Apply COMMAND to ARGUMENTS ((TYPE . TEXT) conses from PARSE-COMMAND); the
function receives the token texts (strings). A raw (&WHOLE) command receives
RAW — the untokenized argument string — instead. Missing required arguments
are prompted for; extra arguments warn and are dropped unless &rest collects
them. An error during execution is reported on ERROR-OUTPUT; returns the
command's value (commands that resume an outer loop use INTERACTOR-RETURN)."
  (handler-case
      (if (command-raw-argument-p command)
          (funcall (command-function command) raw)
          (let ((texts (mapcar #'cdr arguments))
                (required (command-required-parameters command))
                (maximum (command-arity command))
                (restp (member '&rest (command-lambda-list command))))
            (loop
              (when (>= (length texts) (length required)) (return))
              (let ((text (%prompt-for-argument (elt required (length texts))
                                                output input-context)))
                (unless text (return))          ; EOF while prompting
                (setf texts (append texts (list text)))))
            (when (and (not restp) (> (length texts) maximum))
              (warn "Too many arguments given, ~{~A~^ ~} are ignored"
                    (subseq texts maximum))
              (setf texts (subseq texts 0 maximum)))
            (apply (command-function command) texts)))
    (error (err)
      (format error-output "~&Error while executing the command: ~A~%" err)
      (values))))

(defun find-and-run-command (input
                             &key (stack *interactor-stack*)
                                  (output *standard-output*)
                                  (error-output *error-output*) input-context)
  "Resolve INPUT (an INPUT-COMMAND) on STACK and run it; an unknown command is
reported on OUTPUT. Returns the command's value, or NIL."
  (multiple-value-bind (command arguments skip)
      (find-interactor-command input stack)
    (if command
        (call-command command arguments
                      :raw (input-command-raw-arguments input skip)
                      :output output :error-output error-output
                      :input-context input-context)
        (format output "~&? unknown command ~S~%"
                (first (input-command-invocation input))))))

;;; --- the INTERACTOR-LOOP --------------------------------------------------

(defun interactor-return (&optional value)
  "Return VALUE from the innermost INTERACTOR-LOOP: how a command resumes the
computation that entered the loop (continue/step in the debugger)."
  (throw '%interactor-loop value))

(defun interactor-loop (&key (input *standard-input*)
                             (output *standard-output*)
                             (error-output *error-output*))
  "The single interaction loop: each turn takes the top of *INTERACTOR-STACK*,
prints its status and prompt, reads with its reader, and either runs the
command (searched down the stack, with `NAME CMD …' routing to the named
interactor) or hands the sexp to its evaluator. Returns at EOF, when the
stack shrinks below its depth at entry (the interactors present at entry were
popped), or with INTERACTOR-RETURN's value."
  (assert *interactor-stack* (*interactor-stack*)
          "The interactor stack must not be empty.")
  (let ((input-context (make-input-context :stream input))
        (entry-depth (length *interactor-stack*)))
    (catch '%interactor-loop
      (loop
        (when (< (length *interactor-stack*) entry-depth)
          (return))
        (let ((top (first *interactor-stack*)))
          ;; status
          (let ((status (interactor-status top)))
            (when status
              (handler-case (funcall status output)
                (error (err)
                  (format error-output "~&~A while printing ~A status~%"
                          err (interactor-name top))))))
          ;; prompt
          (let ((prompt (interactor-prompt top)))
            (etypecase prompt
              (null   (format output "~&~A> " (interactor-name top)))
              (string (format output "~&~A" prompt))
              (function-designator (funcall prompt output))))
          (finish-output output)
          ;; read
          (let ((input* (handler-case (funcall (interactor-reader top) input-context)
                          (error (err)
                            (format error-output
                                    "~&Cannot read a sexp or command: ~A~%" err)
                            :blank))))
            (cond
              ((eq input* :eof) (return))
              ((eq input* :blank))
              (t
               (let ((*standard-input*  (input-context-stream input-context))
                     (*standard-output* output)
                     (*error-output*    error-output))
                 (if (input-command-p input*)
                     (find-and-run-command input*
                                           :output output
                                           :error-output error-output
                                           :input-context input-context)
                     (let ((evaluator (interactor-evaluator top)))
                       (if evaluator
                           (handler-case (funcall evaluator input*)
                             (error (err)
                               (format error-output "~&~A~%" err)))
                           (format output "~&; no evaluator in ~A~%"
                                   (interactor-name top))))))))))))))

;;; --- definition sugar -------------------------------------------------

(defmacro define-interactor (varname &key name status prompt reader evaluator
                                          commands user-commands documentation)
  "Define VARNAME as an interactor. NAME defaults to VARNAME without its
earmuffs."
  `(defparameter ,varname
     (make-interactor
      :name ,(or name (string-trim "*" (string varname)))
      ,@(when status        `(:status ,status))
      ,@(when prompt        `(:prompt ,prompt))
      ,@(when reader        `(:reader ,reader))
      ,@(when evaluator     `(:evaluator ,evaluator))
      ,@(when commands      `(:commands ,commands))
      ,@(when user-commands `(:user-commands ,user-commands))
      ,@(when documentation `(:documentation ,documentation)))
     ,@(when documentation (list documentation))))

(defun %function-lambda-list (lambda-list)
  "The lambda-list of the command's function: (&WHOLE VAR) declares the raw
calling convention, whose function takes just (VAR)."
  (if (and (= 2 (length lambda-list)) (eq (first lambda-list) '&whole))
      (rest lambda-list)
      lambda-list))

(defmacro define-command ((interactor key &rest words) (&rest lambda-list)
                          docstring &body body)
  "Register a system command of INTERACTOR: KEY its short name, WORDS its long
name (§0: the key is the words' initials). The BODY receives the parsed
argument strings bound to LAMBDA-LIST — or the raw argument string when
LAMBDA-LIST is (&WHOLE VAR)."
  `(bind-command (interactor-commands ,interactor)
                 (list ',key ,@(mapcar (lambda (w) `',w) words))
                 ',lambda-list ,docstring
                 (lambda ,(%function-lambda-list lambda-list) ,@body)))

(defmacro define-user-command ((interactor key &rest words) (&rest lambda-list)
                               docstring &body body)
  "Like DEFINE-COMMAND, into INTERACTOR's user dictionary (shadowing its
system commands)."
  `(bind-command (interactor-user-commands ,interactor)
                 (list ',key ,@(mapcar (lambda (w) `',w) words))
                 ',lambda-list ,docstring
                 (lambda ,(%function-lambda-list lambda-list) ,@body)))
