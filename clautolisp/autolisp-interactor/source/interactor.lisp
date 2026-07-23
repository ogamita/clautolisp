;;;; Interactors and the single interaction loop.
;;;;
;;;; An interactor bundles what distinguishes one command loop from another:
;;;; a name, a status display, a prompt, a reader (how the input line is
;;;; parsed), an evaluator (what a bare Lisp form means there), and its two
;;;; command dictionaries. Interactors are SINGLETONS — pure program, never
;;;; copied (interactor-design-revision.issue D1): what varies per entry is
;;;; the ACTIVATION, the stack entry pairing the interactor with the state of
;;;; one activation of it — like a call frame pairing a function with its
;;;; locals. INTERACTOR-LOOP drives whichever activation is on top of
;;;; *INTERACTOR-STACK*; commands may push an interactor (entering a mode
;;;; within the same loop), pop one (leaving it), call INTERACTOR-LOOP
;;;; recursively (e.g. invoke-debugger, which is specified as a recursive
;;;; REPL), or INTERACTOR-RETURN a value out of the innermost loop.

(in-package #:clautolisp.interactor)

(deftype function-designator () `(or symbol function))

(defstruct (interactor (:constructor %make-interactor) (:copier nil))
  (name          "interactor" :type string)
  ;; ALIAS: one optional alternate name for `NAME CMD …' routing — the ALDO
  ;; debugger answers to `aldo' and `debug'. One alias, not a list: keep the
  ;; invocation namespace small.
  (alias         nil          :type (or null string))
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
  ;; ON-RESULT: (function (result)) applied to each command's return value —
  ;; on the interactor whose dictionary OWNED the command, wherever it was
  ;; typed. The debugger's calls (INTERACTOR-RETURN result) on non-NIL: a
  ;; debugger command's non-NIL value is a resume directive and ends the
  ;; loop, even when issued from an inner navigator. NIL ignores results.
  (on-result     nil          :type (or null function-designator))
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

(defstruct (activation (:constructor make-activation (interactor &optional state)))
  "One entry of *INTERACTOR-STACK*: the (singleton) INTERACTOR paired with the
STATE of this activation of it — like a call frame pairing a function with
its locals (interactor-design-revision.issue T1). The state is whatever the
mode needs per entry: the navigator's location and redraw flag, the
debugger's UI/session/stop. Recursive entries (a nested invoke-debugger
suspending one navigator under another) each carry their own state over the
same interactor."
  (interactor nil :type (or null interactor))
  (state      nil))

(defvar *interactor-stack* '()
  "The stack of live ACTIVATIONs, innermost first. Commands are searched down
this stack — user dictionaries before system dictionaries at each level — so
user commands shadow system commands and inner loops shadow outer loops.")

(defun push-interactor (interactor &optional state)
  "Enter INTERACTOR with this activation's STATE: subsequent turns of the
running INTERACTOR-LOOP read its prompt and dictionaries. Returns the
ACTIVATION."
  (let ((activation (make-activation interactor state)))
    (push activation *interactor-stack*)
    activation))

(defun pop-interactor ()
  "Leave the top activation. A loop whose stack shrinks below its entry depth
returns."
  (pop *interactor-stack*))

(defun find-activation (name &optional (stack *interactor-stack*))
  "The activation whose interactor is called (or aliased) NAME,
case-insensitively, on STACK; NIL when none."
  (let ((name (string name)))
    (find-if (lambda (activation)
               (let ((interactor (activation-interactor activation)))
                 (or (equalp name (interactor-name interactor))
                     (and (interactor-alias interactor)
                          (equalp name (interactor-alias interactor))))))
             stack)))

(defun find-interactor (name &optional (stack *interactor-stack*))
  "The interactor called (or aliased) NAME, case-insensitively, active on
STACK; NIL when none."
  (let ((activation (find-activation name stack)))
    (and activation (activation-interactor activation))))

;;; --- the interactor registry ---------------------------------------------
;;;
;;; For registration and listing, NOT routing (design-revision D7/D8):
;;; (CLAL-DEFINE-COMMAND "NAME" …) registers a user command into the named
;;; interactor's user dictionary whether or not it is active — commands are
;;; installed before their interactor is stacked — and
;;; (CLAL-LIST-INTERACTOR-NAMES) lists every registered interactor. `NAME
;;; CMD …' routing, by contrast, reaches only interactors ON the stack.

(defvar *interactors* '()
  "The registered interactors, registration order (oldest first).
DEFINE-INTERACTOR populates this.")

(defun register-interactor (interactor)
  "Register INTERACTOR (replacing any same-name entry — a reload).
Returns INTERACTOR."
  (setf *interactors*
        (append (remove (interactor-name interactor) *interactors*
                        :key #'interactor-name :test #'equalp)
                (list interactor)))
  interactor)

(defun find-registered-interactor (name)
  "The registered interactor called (or aliased) NAME, case-insensitively;
NIL when none."
  (let ((name (string name)))
    (find-if (lambda (interactor)
               (or (equalp name (interactor-name interactor))
                   (and (interactor-alias interactor)
                        (equalp name (interactor-alias interactor)))))
             *interactors*)))

(defun list-interactor-names ()
  "The names of every registered interactor, registration order — stacked or
not: commands are installed before their interactor is activated."
  (mapcar #'interactor-name *interactors*))

(defun make-prompt-function (who)
  "A prompt function printing `[DEPTH]WHO> ', DEPTH the interactor stack depth."
  (lambda (stream)
    (format stream "~&[~D]~A> " (length *interactor-stack*) who)))

;;; --- finding a command invocation on the interactor stack ---------------

(defparameter +system-command-word+ "command"
  "The system-table escape word (like bash's `command', which bypasses shell
functions): `command CMD …' resolves CMD in the system dictionaries only,
skipping the user dictionaries — reaching a system command a user command
shadows (a shadowing user command calls the system one this way). After an
interactor name it scopes to that interactor: `aldo command CMD …'. The word
is reserved: a command named `command' would be unreachable.")

(defun %system-word-p (ident)
  (string-equal ident +system-command-word+))

(defun find-invocation-in-interactor (invocation interactor &optional system-only)
  "The command INVOCATION (a token string) names in INTERACTOR — its user
dictionary first, so user commands shadow system commands; with SYSTEM-ONLY,
the system dictionary alone (the `command' escape)."
  (or (and (not system-only)
           (interactor-user-commands interactor)
           (find-command (interactor-user-commands interactor) invocation))
      (and (interactor-commands interactor)
           (find-command (interactor-commands interactor) invocation))))

(defun find-invocation-in-stack (invocation &optional (stack *interactor-stack*)
                                              system-only)
  "Search STACK (of activations) innermost-first for INVOCATION (a token
string). Returns (values COMMAND ACTIVATION) or NIL."
  (dolist (activation stack nil)
    (let ((command (find-invocation-in-interactor
                    invocation (activation-interactor activation)
                    system-only)))
      (when command
        (return (values command activation))))))

(defun %find-longest-prefix (idents stack &optional system-only)
  "Resolve the longest prefix of IDENTS to a command, innermost activation
first: at each level `list breakpoints' is found before `list'.
Returns (values COMMAND PREFIX-LENGTH ACTIVATION) or NIL."
  (dolist (activation stack nil)
    (loop :for k :from (length idents) :downto 1
          :do (let* ((phrase (format nil "~{~A~^ ~}" (subseq idents 0 k)))
                     (command (find-invocation-in-interactor
                               phrase (activation-interactor activation)
                               system-only)))
                (when command
                  (return-from %find-longest-prefix
                    (values command k activation)))))))

(defun find-interactor-command (input &optional (stack *interactor-stack*))
  "Resolve INPUT (an INPUT-COMMAND) against STACK. When the first ident names
(or aliases) an interactor on the stack and a command follows, the command is
looked up in that interactor only (`aldo break 42' runs the debugger's
`break' from any inner loop); otherwise the longest ident prefix is resolved
down the stack. The system word `command' — bare or after the interactor
name — skips the user dictionaries: `command CMD …' / `aldo command CMD …'
reach a system command a user command shadows. Returns (values COMMAND
ARGUMENT-TOKENS WORDS-CONSUMED ACTIVATION), or NIL when nothing matches."
  (let ((invocation (input-command-invocation input))
        (tokens (input-command-tokens input)))
    (when invocation
      ;; explicit routing: INTERACTOR-NAME [command] CMD …
      (when (rest invocation)
        (let ((activation (find-activation (first invocation) stack)))
          (when activation
            (let* ((system-only (and (%system-word-p (second invocation))
                                     (not (null (cddr invocation)))))
                   (idents (if system-only (cddr invocation) (rest invocation)))
                   (offset (if system-only 2 1)))
              (multiple-value-bind (command k)
                  (%find-longest-prefix idents (list activation) system-only)
                (when command
                  (return-from find-interactor-command
                    (values command (nthcdr (+ offset k) tokens) (+ offset k)
                            activation))))))))
      ;; the system word alone: skip the user dictionaries down the stack
      (when (and (%system-word-p (first invocation)) (rest invocation))
        (multiple-value-bind (command k activation)
            (%find-longest-prefix (rest invocation) stack t)
          (when command
            (return-from find-interactor-command
              (values command (nthcdr (1+ k) tokens) (1+ k) activation)))))
      (multiple-value-bind (command k activation)
          (%find-longest-prefix invocation stack)
        (when command
          (values command (nthcdr k tokens) k activation))))))

;;; --- executing a command with parameters ---------------------------------

(defun %prompt-for-argument (parameter output input-context)
  "Prompt for a missing required PARAMETER (its declared spec — a symbol or
a (NAME TYPE) sublist) and read one token; NIL at EOF."
  (format output "~A? " (string-downcase (string (command-parameter-name parameter))))
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
function receives the token texts (strings), each CONVERTED first when its
parameter is declared as a (NAME TYPE) sublist (CONVERT-COMMAND-ARGUMENT —
typed command arguments; (&rest (VAR TYPE)) converts each collected
element). A raw (&WHOLE) command receives RAW — the untokenized argument
string — instead. Missing required arguments are prompted for, the answer
converted the same way; a text that does not convert reports on
ERROR-OUTPUT and cancels the call, keeping the loop alive. Extra arguments
warn and are dropped unless &rest collects them. An error during execution
is reported on ERROR-OUTPUT; returns the command's value (commands that
resume an outer loop use INTERACTOR-RETURN)."
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
            (apply (command-function command)
                   (convert-command-arguments command texts))))
    (command-argument-error (err)
      ;; a token that does not convert to its declared type: report, skip
      ;; the call — the loop stays alive (same choke-point as below).
      (format error-output "~&~A~%" err)
      (values))
    (error (err)
      (format error-output "~&Error while executing the command: ~A~%" err)
      (values))))

(defvar *command-interactor* nil
  "The interactor whose dictionary held the command being executed — bound by
FIND-AND-RUN-COMMAND around the call. Note this is the command's OWNER, not
necessarily the top of the stack: `aldo break' typed in the navigator runs
with the debugger interactor here.")

(defvar *command-activation* nil
  "The activation on whose behalf interactor code is currently running: bound
by FIND-AND-RUN-COMMAND to the OWNING activation around a command's
execution, and by INTERACTOR-LOOP to the TOP activation around the status /
prompt / reader / evaluator calls. Interactor functions and command bodies
reach their mode's per-entry state as (ACTIVATION-STATE *COMMAND-ACTIVATION*).")

(defvar *command-line* nil
  "The whole input line (a string) of the command being executed — bound by
FIND-AND-RUN-COMMAND around the call. Part of the fixed calling convention
(design-revision T3) shared command functions rely on.")

(defvar *command-arguments-text* nil
  "The raw, untokenized argument text of the command being executed — the
same string a (&WHOLE VAR) command receives as VAR; NIL when there is none.
Bound by FIND-AND-RUN-COMMAND around the call, so a positional command
function can still reach the verbatim text (design-revision T3).")

(defun find-and-run-command (input
                             &key (stack *interactor-stack*)
                                  (output *standard-output*)
                                  (error-output *error-output*) input-context)
  "Resolve INPUT (an INPUT-COMMAND) on STACK and run it — *COMMAND-INTERACTOR*
/ *COMMAND-ACTIVATION* bound to the owning interactor and activation — then
apply that interactor's ON-RESULT to the command's value (which may
INTERACTOR-RETURN out of the running loop). An unknown command is reported
on OUTPUT. Returns the command's value, or NIL."
  (multiple-value-bind (command arguments skip activation)
      (find-interactor-command input stack)
    (if command
        (let* ((interactor (and activation (activation-interactor activation)))
               (raw-arguments (input-command-raw-arguments input skip))
               (*command-interactor* interactor)
               (*command-activation* activation)
               (*command-line* (input-command-raw input))
               (*command-arguments-text* raw-arguments)
               (result (call-command command arguments
                                     :raw raw-arguments
                                     :output output :error-output error-output
                                     :input-context input-context)))
          (let ((on-result (and interactor (interactor-on-result interactor))))
            (when on-result (funcall on-result result)))
          result)
        (format output "~&? unknown command ~S~%"
                (first (input-command-invocation input))))))

(defun run-command-line (line &key (stack *interactor-stack*)
                                   (output *standard-output*)
                                   (error-output *error-output*) input-context)
  "Parse LINE as one command invocation and FIND-AND-RUN-COMMAND it on STACK —
how a command body delegates to another interactor's command with full
routing and ON-RESULT semantics (e.g. NAVI's confirmed quit running `aldo
quit', whose abort directive then cascades out of the loop)."
  (find-and-run-command (make-input-command :raw line
                                            :tokens (parse-command line :lenient t))
                        :stack stack :output output :error-output error-output
                        :input-context input-context))

;;; --- the INTERACTOR-LOOP --------------------------------------------------

(defun interactor-return (&optional value)
  "Return VALUE from the innermost INTERACTOR-LOOP: how a command resumes the
computation that entered the loop (continue/step in the debugger)."
  (throw '%interactor-loop value))

(defun interactor-loop (&key (input *standard-input*)
                             (output *standard-output*)
                             (error-output *error-output*)
                             (floor (length *interactor-stack*)))
  "The single interaction loop: each turn takes the top activation of
*INTERACTOR-STACK*, prints its interactor's status and prompt, reads with its
reader, and either runs the command (searched down the stack, with `NAME CMD
…' routing to the named interactor) or hands the sexp to its evaluator —
*COMMAND-ACTIVATION* bound to the top activation around those calls, so the
interactor's functions reach this activation's state. Returns at EOF, when
the stack shrinks below FLOOR activations (default: its depth at entry — the
caller may pass a smaller FLOOR to let inner interactors pop back to an
outer one within the same loop), or with INTERACTOR-RETURN's value."
  (assert *interactor-stack* (*interactor-stack*)
          "The interactor stack must not be empty.")
  (let ((input-context (make-input-context :stream input)))
    (catch '%interactor-loop
      (loop
        (when (< (length *interactor-stack*) floor)
          (return))
        (let* ((*command-activation* (first *interactor-stack*))
               (top (activation-interactor *command-activation*)))
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

(defmacro define-interactor (varname &key name alias status prompt reader
                                          evaluator commands user-commands
                                          on-result documentation)
  "Define VARNAME as an interactor — a singleton: per-entry state belongs to
the ACTIVATION pushed on the stack, not to the interactor. NAME defaults to
VARNAME without its earmuffs; ALIAS is the optional alternate routing name.
The interactor is added to the registry (REGISTER-INTERACTOR), so
LIST-INTERACTOR-NAMES and named user-command registration see it."
  `(defparameter ,varname
     (register-interactor
      (make-interactor
      :name ,(or name (string-trim "*" (string varname)))
      ,@(when alias         `(:alias ,alias))
      ,@(when status        `(:status ,status))
      ,@(when prompt        `(:prompt ,prompt))
      ,@(when reader        `(:reader ,reader))
      ,@(when evaluator     `(:evaluator ,evaluator))
      ,@(when commands      `(:commands ,commands))
      ,@(when user-commands `(:user-commands ,user-commands))
      ,@(when on-result     `(:on-result ,on-result))
      ,@(when documentation `(:documentation ,documentation))))
     ,@(when documentation (list documentation))))

(defun %function-lambda-list (lambda-list)
  "The lambda-list of the command's function: (&WHOLE VAR) declares the raw
calling convention, whose function takes just (VAR) — function lambda-lists
have no &WHOLE, only the declaration does (design-revision T3) — and a typed
\(NAME TYPE) sublist contributes just NAME: the types too belong to the
declaration only."
  (if (and (= 2 (length lambda-list)) (eq (first lambda-list) '&whole))
      (rest lambda-list)
      (mapcar #'command-parameter-name lambda-list)))

(defun %command-function-form (lambda-list body)
  "The function form DEFINE-COMMAND registers: a body of exactly
(:FUNCTION FORM) yields FORM — a function (designator) shared across
commands and interactors (design-revision D5) — otherwise an inline lambda
over BODY."
  (if (and (= 2 (length body)) (eq (first body) :function))
      (second body)
      `(lambda ,(%function-lambda-list lambda-list) ,@body)))

(defmacro define-command ((interactor key &rest words) (&rest lambda-list)
                          docstring &body body)
  "Register a system command of INTERACTOR: KEY its short name, WORDS the
ordered words of its single long name — one phrase, whose derived join is
the long invocation (§0: the key is the words' initials).

The calling convention (design-revision T3): LAMBDA-LIST is either
(&WHOLE VAR) — the function receives the raw, untokenized argument string
as its single parameter VAR (its actual lambda-list is (VAR): &WHOLE
belongs to the declaration only) — or positional,
(REQUIRED… [&REST REST]), receiving the parsed argument strings. A
positional parameter may be a (NAME TYPE) sublist — TYPE one of STRING /
INTEGER / FLOAT / IDENT / SEXP (+COMMAND-ARGUMENT-TYPES+) — receiving the
CONVERTED value instead of the text; (&REST (VAR TYPE)) converts each
collected element. Like &WHOLE, the types belong to the declaration only:
the function's lambda-list uses just the names. A token that does not
convert cancels the command with a report and the loop continues
\(mutually exclusive with (&WHOLE VAR), which stays all-raw). BODY is
the function's body; a body of exactly =:function FORM= registers FORM's
value (a function designator) instead, so several interactors' commands
can share one named function (D5). Every command function reaches its
context through dynamic variables: *COMMAND-INTERACTOR* /
*COMMAND-ACTIVATION* (owner and its per-entry state), *COMMAND-LINE* /
*COMMAND-ARGUMENTS-TEXT* (the verbatim input), plus the client's own
(e.g. the debugger's UI / session / hit variables)."
  `(bind-command (interactor-commands ,interactor)
                 (list ',key ,@(mapcar (lambda (w) `',w) words))
                 ',lambda-list ,docstring
                 ,(%command-function-form lambda-list body)))

(defmacro define-user-command ((interactor key &rest words) (&rest lambda-list)
                               docstring &body body)
  "Like DEFINE-COMMAND, into INTERACTOR's user dictionary (shadowing its
system commands)."
  `(bind-command (interactor-user-commands ,interactor)
                 (list ',key ,@(mapcar (lambda (w) `',w) words))
                 ',lambda-list ,docstring
                 ,(%command-function-form lambda-list body)))
