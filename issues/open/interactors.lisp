

;;; We use only one loop. At any time, there is one command intepreter,
;;; which prints and flush a prompt, read a lisp expression or a command,
;;; send the lisp expression to the lisp evaluator, and print its result,
;;; or interprets the command
;;; 
;;; For each command interpreter (interactor), we define two dictionaries:
;;; - a dictionary of commands provided by clautolisp specific to this command loop,
;;; - a dictionary of commands provided by the user for this command loop.
;;; 
;;; A command may push on the *interactor-stack* a new interactor (command loop),
;;; with it's pair of dictionaries.
;;; 
;;; Commands are searched on the interactor stack in order;  user
;;; defined commands first, so they may shadow system commands, and command
;;; loops may shadow commands from underneath command loops.
;;;
;;; note: invoke-debugger and other commands and functions may call
;;; recursively (interactor-loop) too, or may only push a new top-interactor
;;; onto the *interactor-stack* to be processed by the same interactor-loop.
;;; Some operators are specified for a recursive REPL
;;; (eg. invoke-debugger, implicitely is).

#||

** Principle of operation

The principle is to have a single REPL, ie. a lisp Read Eval Print ;
Loop, but augmented with commands.
 
Command interpreters interfer at read-time to change the parser:

- Lisp REPL: usual read of sexp (symbols are variables). We use comma
  to introduce commands:

    ,date    prints date and time (iso-8601)
    ,uptime  prints how long this clautolisp process has been running.
    ,help    prints lisp REPL help.
    ,quit    exit the Lisp REPL (sometimes (quit) is not available).

- Debugger REPL, with two navigation variants:

    - file:line source printing and navigation

    - form navigation (it's a restriction of the SEDIT editor used only
      for navigation),

  These variants change how the current position (poll-point), source,
  and how breakpoints are displayed, and have different commands, but a
  common trunk of debugging (aldo) commands.

  With the TUI (line discipline), these navigation/debugger command
  interpreters take symbols as command name, and don't interpret them
  as lisp variables. (We can always use (print variable), and there is
  no reader macro to deal with in autolisp).

- SEDIT REPL: a structural sexp editor (with directory tree navigation
  extension). This command interpreter too takes symbols as command
  names instead of lisp variables.

Each command interpreter has a command dictionary, where its commands
are registered, and stacks a user command dictionary.

||#

;;;
;;; Commands
;;;

;; (make-command key words phrase lambda-list docstring function) --> command

(defstruct (command (:constructor make-command))
  (key "" :type string)               ; the 1- or 2-letter (or punctuation) key
  (words '() :type list)              ; the word(s), lower-cased strings
  (phrase "" :type string)            ; the words joined with spaces
  (lambda-list '() :type list)        ; arity for the reader
  (docstring "" :type string)
  (function nil))

(defun all-invocations (command)
  "Return all the possible way to invoke a command."
  (append (when (command-key command)
            (list (command-key command)))
          (command-words command)
          (when (command-phrase command)
            (list (command-phrase command)))))

;;;
;;; Command parser
;;;

(define-condition command-syntax-error (error)
  ((command :initarg :command :reader command-syntax-error-command)
   (position :initarg :position :reader command-syntax-error-position)))

(define-command simple-command-syntax-error (command-syntax-error simple-error)
  ())

(defun parse-command (command &key (start 0) (end nil))
  (check-type command string)
  (check-type start (integer 0))
  (check-type end (or null (integer 0)))
  ;; A command line is a list of whitespace separated tokens, the first
  ;; one must be an ident.
  ;;
  ;; command ::= ident { ident | float | integer | string | token } .
  ;;
  ;; ident   ::= /[A-Za-z][-A-Za-z0-9]*/ .
  ;; float   ::= /[-+]?[0-9]+\(\.[0-9]*\)?\(e[-+]?[0-9]+\)?/ .
  ;; integer ::= /[-+]?[0-9]+/ .
  ;; string  ::= /"\([^\\"]\|\\[\\"]\)*"/ .
  ;; token   ::= /[^ ]+/ .
  ;;
  ;; case is preserved.
  ;; string let us include spaces in a token.
  ;; any non-whitespace sequence of character not matching ident, float or integer is a token.
  ;; Note: a double-quote starts a string, and a string should end in
  ;; a non-escaped double-quote, or it's end-of-command in a string error.
  ;;
  ;;
  ;; Signal: COMMAND-SYNTAX-ERROR in case of syntax error.
  ;;
  ;; Return: a list of CONS cell, car of which is IDENT, FLOAT, INTEGER, STRING or TOKEN,
  ;;         and cdr is a string containing the characters of the token or string
  ;;
  ;; Examples:
  ;;
  ;;     break 42
  ;;        --> ((ident . "break") (integer . "42"))
  ;;
  ;;     list source
  ;;        --> ((ident . "list") (ident . "source"))
  ;;
  ;;     b source.lsp:33
  ;;        --> ((ident . "b") (token . "source.lsp:33"))
  ;;
  ;;     b "/A vilainous/path with spaces/or \\ backslashes/in/it.lsp:143"
  ;;        --> ((ident . "b") (string . "/A vilainous/path with spaces/or \\ backslashes/in/it.lsp:143"))
  (let ((end (or end (length command)))
        (index start)
        (tokens '()))
    (labels ((whitespacep (ch)
               (or (char= ch #\space) (char= ch #\tab)))
             (ascii-letter-p (ch)
               (or (char<= #\A ch #\Z) (char<= #\a ch #\z)))
             (ascii-digit-p (ch)
               (char<= #\0 ch #\9))
             (syntax-error (position)
               (error 'command-syntax-error
                      :command command
                      :position position))
             (identp (text)
               ;; /[A-Za-z][-A-Za-z0-9]*/
               (and (plusp (length text))
                    (ascii-letter-p (char text 0))
                    (every (lambda (ch)
                             (or (ascii-letter-p ch)
                                 (ascii-digit-p ch)
                                 (char= ch #\-)))
                           text)))
             (integerp* (text)
               ;; /[-+]?[0-9]+/
               (let ((n (length text)) (i 0))
                 (when (and (< i n) (member (char text i) '(#\+ #\-)))
                   (incf i))
                 (let ((start-digits i))
                   (loop while (and (< i n) (ascii-digit-p (char text i)))
                         do (incf i))
                   ;; at least one digit, and the whole text consumed.
                   (and (> i start-digits) (= i n)))))
             (floatp* (text)
               ;; /[-+]?[0-9]+(\.[0-9]*)?(e[-+]?[0-9]+)?/
               (let ((n (length text)) (i 0))
                 (when (and (< i n) (member (char text i) '(#\+ #\-)))
                   (incf i))
                 ;; mantissa: at least one digit is required
                 (let ((start-digits i))
                   (loop while (and (< i n) (ascii-digit-p (char text i)))
                         do (incf i))
                   (when (= i start-digits)
                     (return-from floatp* nil)))
                 ;; optional fractional part
                 (when (and (< i n) (char= (char text i) #\.))
                   (incf i)
                   (loop while (and (< i n) (ascii-digit-p (char text i)))
                         do (incf i)))
                 ;; optional exponent
                 (when (and (< i n) (char-equal (char text i) #\e))
                   (incf i)
                   (when (and (< i n) (member (char text i) '(#\+ #\-)))
                     (incf i))
                   (let ((start-exp i))
                     (loop while (and (< i n) (ascii-digit-p (char text i)))
                           do (incf i))
                     (when (= i start-exp)
                       (return-from floatp* nil))))
                 (= i n)))
             (classify (text)
               ;; The order matters: integer before float, because "42"
               ;; matches both the integer and the (looser) float regexp.
               (cond ((identp text)    'ident)
                     ((integerp* text) 'integer)
                     ((floatp* text)   'float)
                     (t                'token)))
             (parse-string ()
               ;; INDEX points at the opening double-quote.  Consume up to
               ;; and including the closing (unescaped) double-quote, and
               ;; return the decoded content (quotes stripped, \\ and \"
               ;; unescaped).
               (let ((open index)
                     (out (make-string-output-stream)))
                 (incf index)           ; skip opening quote
                 (loop
                   (when (>= index end)
                     ;; end-of-command while still inside a string.
                     (syntax-error open))
                   (let ((ch (char command index)))
                     (cond
                       ((char= ch #\")
                        (incf index)    ; skip closing quote
                        (return))
                       ((char= ch #\\)
                        (incf index)
                        (when (>= index end)
                          (syntax-error open))
                        (let ((escaped (char command index)))
                          (unless (or (char= escaped #\\) (char= escaped #\"))
                            ;; only \\ and \" are valid escapes.
                            (syntax-error (1- index)))
                          (write-char escaped out)
                          (incf index)))
                       (t
                        (write-char ch out)
                        (incf index)))))
                 ;; A string is a whole token: it must be followed by
                 ;; whitespace or end-of-command.
                 (when (and (< index end) (not (whitespacep (char command index))))
                   (syntax-error index))
                 (get-output-stream-string out)))
             (parse-token ()
               ;; A maximal run of non-whitespace characters.
               (let ((first index))
                 (loop while (and (< index end)
                                  (not (whitespacep (char command index))))
                       do (incf index))
                 (subseq command first index))))
      ;; skip leading whitespace
      (loop while (and (< index end) (whitespacep (char command index)))
            do (incf index))
      (loop
        (when (>= index end)
          (return))
        (if (char= (char command index) #\")
            (let ((position index))
              (push (cons 'string (parse-string)) tokens)
              ;; a string is never an ident, so it cannot be the first
              ;; (command-name) token.
              (when (null (rest tokens))
                (syntax-error position)))
            (let ((position index)
                  (text (parse-token)))
              (let ((type (classify text)))
                ;; The first token (the command name) must be an ident.
                (when (and (null tokens) (not (eq type 'ident)))
                  (syntax-error position))
                (push (cons type text) tokens))))
        ;; skip whitespace separating tokens
        (loop while (and (< index end) (whitespacep (char command index)))
              do (incf index)))
      (nreverse tokens))))


(assert (equal (parse-command ",abort" :start 1)
               '((ident . "abort"))))

(assert (equal (parse-command ",b foo.lisp:42" :start 1)
               '((ident . "b") (token . "foo.lisp:42"))))


(defstruct input-context
  (stream nil :type input-stream))

(defun read-sexp-from-input-context (input-context)
  (read (input-context-stream input-context)))

(defun read-line-from-input-context (input-context)
  (read-line (input-context-stream input-context)))


(defun unread-line-from-input-context (line input-context)
  (let ((newline-string (load-time-value (format nil "~%") t)))
    (setf (input-context-stream input-context)
          (make-concatenated-stream (make-string-input-stream line)
                                    (make-string-input-stream newline-string)
                                    (input-context-stream input-context)))))

(defparameter *whitespaces* #(#\space #\tab))

(defun comma-command-read (input-context)
  ;; Note: this is a toplevel read, so the comma is not ambiguous with backquote-comma.
  (let ((line (string-left-trim *whitespaces*
                                (read-line-from-input-context input-context))))
    (if (and (plusp (length line))
             (char= #\, (aref line 0)))
        `(%command ,@(parse-command line :start 1))
        (progn
          (unread-line-from-input-context line input-context)
          (read-sexp-from-input-context input-context)))))

(defun command-read (input-context)
  (let ((line (string-left-trim *whitespaces* 
                                (read-line-from-input-context input-context))))
    (if (alphabeticp (aref line 0))
        `(%command ,@(parse-command line))
        (progn
          (unread-line-from-input-context line input-context)
          (read-sexp-from-input-context input-context)))))



;;;
;;; Command Dictionaries
;;;

(defun make-command-dictionary ()
  (make-hash-table :test (function equal) #|case sensitive|#))

(defun register-command (command-dictionary command)
  (dolist (invocation (all-invocations command)
                      command)
    (setf (gethash invocation) command-dictionary)))

(defun unregister-command (command-dictionary command)
  (dolist (invocation (all-invocations command)
                      command)
    (remhash invocation command-dictionary)))

(defun get-invocation-in-dictionary (command-dictionary invocation)
  (gethash invocation command-dictionary))

;;;
;;; Interactor
;;;

(deftype function-designator () `(or symbol function))

(defstruct interactor
  (name          "interactor"              :type string)
  (status        (function identity)       :type function-designator)
  (prompt        "interactor>"             :type (or string function-designator))
  (reader        (function read)           :type function-designator)
  (commands      (make-command-dictionary) :type command-dictionary)
  (user-commands (make-command-dictionary) :type command-dictionary)
  (documentation nil                       :type (or null string)))

(defvar *interactor-stack* '())

(defun make-prompt-function (who)
  (lambda (stream)
    (format stream "[~D~]~A> "
            (length *interactor-stack*)
            who)))

;;;
;;; input command
;;;


(defun input-command-p (input)
  (and (listp input)
       (eql '%command (first input)))) 

(defun input-command-invocation (input)
  (assert (input-command-p input))
  (loop
    :for item :in (rest input)
    :while (eq 'ident (car item))
    :collect (cdr item)))

(defun input-command-arguments (input)
  (assert (input-command-p input))
  (pop input)
  (loop
    :while (and input (eq 'ident (car (first input))))
    :do (pop input)
    :finally (return input)))


;;;
;;; Finding command invocation in the interactor stack
;;;

(defun find-invocation-in-interactor (invocation interactor)
  (or (get-invocation-in-dictionary invocation (interactor-user-commands interactor))
      (get-invocation-in-dictionary invocation (interactor-commands interactor))))

(defun find-invocation-in-stack (invocation *interactor-stack*)
 (dolist (interactor *interactor-stack* nil)
   (let ((command (find-invocation-in-interactor invocation interactor)))
     (when command
       (return-from find-invocation-in-stack command)))))

(defun find-command (invocation *interactor-stack*)
  "
INVOCATION: a list of ident strings.
"
  (cond
    ((null invocation)
     (error "null invocation? invalid command syntax"))
    ((null (cdr invocation))
     ;; 1 ident       
     (let ((command (find-invocation-in-stack (car invocation) *interactor-stack*)))
       (if command
           (return find-command command)
           (error "no such command"))))
    (t
     ;; multiple ident: try interactor name
     (destructuring-bind (name &rest invocation) invocation
       (let ((interactor (find name *interactor-stack*
                               :key (function interactor-name)
                               #| case insensitive: |#
                               :test (function equalp))))
         (when interactor
           (cond
             ((null invocation)
              ;; we only got the name of the interactor
              ;; let's read the commmand:
              ;; (format interactor-prompt)
              ;; read-line
              ;; parse-command
              ;; find-command
              )
             ((null (cdr invocation))
              (let ((command (find-invocation-in-interactor
                              (car invocation)
                              interactor)))
                (when command
                  (return-from find-command command))))
             (t ;; several idents
              (let ((command (find-invocation-in-interactor
                              (format "~{~A~^ ~}" invocation)
                              interactor)))
                (when command
                  (return-from find-command command))))))))
     ;; no interactor name (in first position)
     (let ((command (find-invocation-in-stack (format "~{~A~^ ~}" invocation)
                                              *interactor-stack*)))
       (when command
         (return-from find-command command))))))


;;;
;;; Executing a command with parameters
;;;

(defun run-command (command arguments)
  (let ((mandatory-count (length (command-lambda-list command))))
    (loop
      :while (< (length arguments) mandatory-count) ; missing arguments
      :do (setf arguments (append arguments
                                  (list
                                   (progn
                                     (format t "~A? "  (elt (command-lambda-list command) (length arguments)))
                                     (finish-output)
                                     (let ((tokens (parse-command (read-line))))
                                       (when (cdr tokens)
                                         (warn "Ignored tokens: ~{~A~^ ~}"
                                               (mapcar (function cdr) (cdr tokens))))
                                       (car tokens)))))))
    (handler-case
        (if (= (length arguments) mandatory-count)
            (apply (command-function command) arguments)
            (progn
              (warn "Too many arguments given, ~{~A~^ ~} are ignored" (subseq arguments mandatory-count))
              (apply (command-function command)  (subseq arguments 0 mandatory-count))))
      (error (err)
        (format *error-output* "Error while executing the command: ~A" err)))))

(defun find-and-run-command (input *interactor-stack*)
  (assert (input-command-p input))
  ;; Finds the command to run in the *interactor-stack* and run it:
  (let ((command (find-command (input-command-invocation input) *interactor-stack*)))
    (if command
        (run-command command (input-command-arguments input))
        (error "unknown command ~S" input))))

;;;
;;; Evaluating and printing a lisp expression:
;;;

(defun lisp-eval-print (sexp)
  ;; Perform the * ** *** etc juggling, and
  ;; eval the input sexp and print its
  ;; results; handle errors as specified by
  ;; *autolisp-on-error*, or invoke-debugger,
  ;; TODO
  (not-implemented-yet lisp-eval-print))

;;;
;;; The INTERACTOR-LOOP
;;;

(defun interactor-loop (input-stream output-stream error-stream)
  (assert *interactor-stack* (*interactor-stack*)
          "The interactor stack must not be empty.")
  (let ((input-context (make-input-context :stream input-stream)))
   (loop
    (tagbody
     continue

       (let ((top-interactor (first *interactor-stack*)))

         ;; print status
         (let ((status (interactor-status top-interactor)))
           (handler-case (funcall status output-stream)
             (error (err)
               (format error-stream "&~A while printing ~A status~%"
                       err (interactor-name top-interactor)))))
        
         ;; print prompt:
         (let ((prompt (interactor-prompt top-interactor)))
           (typecase prompt
             (string   (write-string prompt output-stream))
             (function (funcall prompt output-stream))
             (otherwise
              (warn "Invalid prompt in iterator ~A" (iteractor-name top-interactor))
              (write-string "> " output-stream))))
        
         (finish-output output-stream)
        
         (let ((input (handler-case
                          (funcall (interactor-reader top-interactor) input-context)
                        (error (err)
                          ;; handle reader errors
                          (format error-stream "~&Cannot read a sexp or command: ~A~%" err)
                          ;; Note: too many consecutive errors with the same interactor
                          ;; we should pop it. (if not the bottom of stack).
                          (go continue))))
               (*standard-input*  (input-context-stream input-context))
               (*standard-output* output-stream)
               (*error-output*    error-stream))

           (if (input-command-p input)

               ;; Finds the command to run in the *interactor-stack* and run it:
               (find-and-run-command input *interactor-stack*)

               ;; Perform the * ** *** etc juggling, and
               ;; eval the input expression and print its
               ;; results; handle errors as specified by
               ;; *autolisp-on-error*, or invoke-debugger
               (lisp-eval-print input))))))))


;;;
;;; Definition of interactors and their commands
;;;

(defmacro define-interactor (varname &rest parameters
                             &key name status prompt reader commands user-commands
                             documentation)
  `(defparameter ,varname (make-interactor ,@parameters)
     ,@(when documentation `(,documentation))))

(defmacro define-command ((interactor-varname short (&rest words) phrase) (&rest lambda-list)
                          docstring
                          &body body)
  `(register-command (interactor-commands ,interactor-varname)
                     (make-command ,short ,words ,phrase ,lambda-list ,docstring
                                   (lambda ,lambda-list ,@body))))

(defmacro define-user-command ((interactor-varname short (&rest words) phrase) (&rest lambda-list)
                               docstring
                               &body body)
  `(register-command (interactor-user-commands ,interactor-varname)
                     (make-command ,short ,words ,phrase ,lambda-list ,docstring
                                   (lambda ,lambda-list ,@body))))



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; LISP-INTERACTOR (REPL)
;;;

(define-interactor *autolisp*
  :name "AUTOLISP"
  :prompt (make-prompt-function "LISP")
  :reader (function comma-command-read)
  :documentation "The normal lisp REPL.")

(define-command (*autolisp* nil ("date") nil) ()
  "Prints the date"
  (multiple-value-bind (se mi ho da mo ye)
      (decode-universal-time (get-universal-time))
    (format t "~&~4,'0D~2,'0D~2,'0DT~2,'0D~2,'0D~2,'0D~%"
            ye mo da ho mi se)))

(defvar *boot-time* (get-universal-time))

(define-command (*autolisp* nil ("uptime") ()) ()
  "Prints the uptime"
  (let* ((uptime (- (get-universal-time) *boot-time*))
         (sec (mod uptime 60))
         (min (mod (truncate uptime 60) 60))
         (hou (mod (truncate uptime 3600) 24))
         (day  (truncate uptime 86400)))
    (format t "~&~:[~*~;~D day~:*~P, ~]~2,'0D:~2,'0D:~2,'0D~%"
            (plusp day) day hou min sec)))

(define-command (*autolisp* nil ("help") nil) ()
  "Prints Help"
  (format t "~&Help~%"))

(define-command (*autolisp* "q" ("quit") ("get me out")) ()
  "Exits the Lisp REPL"
  (%autolisp-quit))

(define-user-command ("M" ("mix") "color mix") (color1 color2)
  "Mix two colors"
  (let ((color1 (intern (cdr color1) (load-time-value *package*)))
        (color2 (intern (cdr color2) (load-time-value *package*))))
    (format t "~&~A + ~A -> ~A~%"
            color1 color2
            (case color2
              (black (case color1
                       (black   black)
                       (blue    blue)
                       (red     red)
                       (green   green)
                       (magenta magenta)
                       (yellow  yellow)
                       (cyan    cyan)
                       (white   white)))
              (blue (case color1
                      (black   blue)
                      (blue    blue)
                      (red     magenta)
                      (green   cyan)
                      (magenta magenta)
                      (yellow  white)
                      (cyan    cyan)
                      (white   white)))
              (red (case color1
                     (black   red)
                     (blue    magenta)
                     (red     red)
                     (green   yellow)
                     (magenta magenta)
                     (yellow  yellow)
                     (cyan    white)
                     (white   white)))
              (green (case color1
                       (black   green)
                       (blue    cyan)
                       (red     yellow)
                       (green   green)
                       (magenta white)
                       (yellow  yellow)
                       (cyan    cyan)
                       (white   white)))
              (magenta (case color1
                         (black   magenta)
                         (blue    magenta)
                         (red     magenta)
                         (green   white)
                         (magenta magenta)
                         (yellow  white)
                         (cyan    white)
                         (white   white)))
              (yellow (case color1
                        (black   yellow)
                        (blue    white)
                        (red     yellow)
                        (green   yellow)
                        (magenta white)
                        (yellow  yellow)
                        (cyan    white)
                        (white   white)))
              (cyan (case color1
                      (black   cyan)
                      (blue    cyan)
                      (red     white)
                      (green   cyan)
                      (magenta white)
                      (yellow  white)
                      (cyan    cyan)
                      (white   white)))
              (white (case color1
                       (black   white)
                       (blue    white)
                       (red     white)
                       (green   white)
                       (magenta white)
                       (yellow  white)
                       (cyan    white)
                       (white   white)))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; ALDO-INTERACTOR
;;;

(define-interactor *aldo*
  :name "ALDO"
  :prompt (make-prompt-function "ALDO")
  :status (function aldo-status)
  :reader (function command-read)
  :documentation "The ALDO debugger.")

(define-command (*aldo* "b" ("break") "set breakpoint") (point)
  "Set a breakpoint at the indicated poll point."
  ;; NOTE: the command arguments are cons cells (type . value)
  ;; as returned by parse-command. They may need to be parsed
  ;; and converted by the command.
  (not-implemented-yet "break"))

(define-command (*aldo* "n" ("next") nil) ()
  "step to next poll-point."
  (not-implemented-yet "next"))

;; TODO; and so on define all aldo commands.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; LAVI-INTERACTOR
;;;

(define-interactor *lavi*
  :name "LAVI"
  :status (function lavi-status)
  :prompt (make-prompt-function "LAVI")
  :reader (function command-read)
  :documentation "The file:line navigator.")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; NAVI-INTERACTOR
;;;

(define-interactor *navi*
  :name "NAVI"
  :status (function navi-status)
  :prompt (make-prompt-function "NAVI")
  :reader (function command-read)
  :documentation "The sexp navigator.")

(define-command (*navi* "f" ("forward") nil) ()
  "Move the selection forward"
  (not-implemented-yet "forward"))

(define-command (*navi* "b" ("backward") nil) ()
  "Move the selection backward"
  (not-implemented-yet "backward"))

;; TODO: and so on implement all navi commands

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; SEDIT-INTERACTOR
;;;

(define-interactor *sedit*
  :name "SEDIT"
  :status (function sedit-status)
  :prompt (make-prompt-function "SEDI")
  :reader (function command-read)
  :documentation "The Sexp Editor".)


(define-command (*sedit* "f" ("forward") nil) ()
  "Move the selection forward"
  (not-implemented-yet "forward"))

(define-command (*sedit* "b" ("backward") nil) ()
  "Move the selection backward"
  (not-implemented-yet "backward"))

;; TODO: and so on implement all sedit commands


(defparameter *interactor-stack* (list *autolisp*)) ; the initial stack.




