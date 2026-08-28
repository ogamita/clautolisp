;;;; Input contexts and the two command readers.
;;;;
;;;; An interactor's READER interferes at read-time to change the parser:
;;;; COMMA-COMMAND-READ (the Lisp REPL) reads a sexp unless the line starts
;;;; with a comma introducing a command (`,date', `,quit'); COMMAND-READ (the
;;;; debugger, the navigators, the editor) treats every line as a command
;;;; unless it starts with `(' — a Lisp form to evaluate. (Note: these are
;;;; toplevel reads, so the comma is not ambiguous with backquote-comma.)
;;;;
;;;; A reader returns an INPUT-COMMAND (the raw line + its parsed tokens), a
;;;; sexp to evaluate, :BLANK for an empty line, or :EOF.

(in-package #:clautolisp.interactor)

(defstruct input-context
  (stream nil :type (or null stream)))

(defun read-line-from-input-context (input-context)
  (read-line (input-context-stream input-context) nil :eof))

(defun unread-line-from-input-context (line input-context)
  "Push LINE (plus a newline) back in front of INPUT-CONTEXT's stream."
  (let ((newline-string (load-time-value (format nil "~%") t)))
    (setf (input-context-stream input-context)
          (make-concatenated-stream (make-string-input-stream line)
                                    (make-string-input-stream newline-string)
                                    (input-context-stream input-context)))))

(defparameter *whitespaces* '(#\space #\tab))

(defun read-sexp-from-input-context (input-context)
  "Read one Lisp form, consuming further lines while the form is
incomplete. Returns the form, or :EOF at end of input.

READS FROM A STRING, NOT FROM THE STREAM, and that is the whole point.
What CL:READ leaves behind is not portable. CLHS says it `throws away the
delimiting character ... if it is a whitespace character\', but the
delimiter of (+ 1 2) is the closing PAREN, which is not whitespace and is
therefore not thrown away -- so the newline after it is still in the
stream. Whether it then survives a CONCATENATED-STREAM boundary differs
by implementation: CCL leaves it, SBCL does not. The line reader saw one
extra empty line on CCL and none on SBCL, which is
interactor-trailing-blank-on-ccl: three tests green on one host and red
on the other, over a difference neither implementation is wrong about.

READ-FROM-STRING has no such ambiguity -- it RETURNS the position where
it stopped, so what remains is a fact rather than an inference. Lines are
accumulated until the form parses, and whatever follows the form on the
last line is pushed back, which is what keeps `(print x) (print y)\' on
one line reading as two forms."
  (let ((text nil))
    (loop
      (let ((line (read-line-from-input-context input-context)))
        (when (eq line :eof)
          ;; EOF with a partial form is not an error to raise here: the
          ;; caller\'s loop ends on :EOF, exactly as it did when READ met
          ;; the end of the stream mid-form.
          (return :eof))
        (setf text (if text
                       (concatenate 'string text (string #\Newline) line)
                       line))
        (multiple-value-bind (form position)
            (handler-case (read-from-string text nil :eof)
              ;; Not an error -- a form that needs more lines.
              (end-of-file () (values :incomplete nil)))
          (unless (eq form :incomplete)
            (let ((rest (subseq text position)))
              ;; Push back only real content. Pushing back trailing
              ;; whitespace would manufacture an empty line the user never
              ;; typed -- which is the bug this function exists to remove.
              (unless (zerop (length (string-trim (list* #\Newline *whitespaces*)
                                                  rest)))
                (unread-line-from-input-context rest input-context)))
            (return form)))))))

;;; --- command input ----------------------------------------------------

(defstruct input-command
  ;; A struct rather than a (%command …) list, so a command input can never
  ;; be mistaken for a sexp the user typed.
  (raw "" :type string)                 ; the line (sans comma), verbatim
  (tokens '() :type list))              ; its PARSE-COMMAND (TYPE . TEXT) conses

(defun input-command-invocation (input)
  "The invocation of INPUT: the list of leading ident texts (a multi-ident
prefix can name a `list breakpoints'-style phrase), or the single leading
token's text when the command is named by punctuation or a signed number
\(`.', `>>', `+3')."
  (let ((tokens (input-command-tokens input)))
    (cond ((null tokens) '())
          ((eq (car (first tokens)) 'ident)
           (loop :for item :in tokens
                 :while (eq (car item) 'ident)
                 :collect (cdr item)))
          (t (list (cdr (first tokens)))))))

(defun input-command-arguments (input)
  "The (TYPE . TEXT) tokens of INPUT following its invocation."
  (nthcdr (length (input-command-invocation input))
          (input-command-tokens input)))

(defun input-command-raw-arguments (input skip)
  "The raw text of INPUT after its first SKIP whitespace-separated words —
the untokenized argument string a raw (&WHOLE) command receives — or NIL
when nothing follows. Exact because an invocation never contains a string
token (only a string can embed whitespace)."
  (let* ((raw (input-command-raw input))
         (end (length raw))
         (index 0))
    (flet ((skip-whitespace ()
             (loop :while (and (< index end)
                               (member (char raw index) *whitespaces*))
                   :do (incf index)))
           (skip-word ()
             (loop :while (and (< index end)
                               (not (member (char raw index) *whitespaces*)))
                   :do (incf index))))
      (dotimes (i skip)
        (skip-whitespace)
        (skip-word))
      (skip-whitespace)
      (when (< index end)
        (subseq raw index)))))

;;; --- the readers ------------------------------------------------------

(defun %read-command-line (input-context)
  "Read and left-trim one line; :EOF at end of input, :BLANK when empty."
  (let ((line (read-line-from-input-context input-context)))
    (if (eq line :eof)
        line
        (let ((line (string-left-trim *whitespaces* line)))
          (if (zerop (length line)) :blank line)))))

(defun %parse-command-line (line &key (start 0))
  ;; lenient: a raw argument embedding a Lisp form must still read
  (make-input-command :raw (subseq line start)
                      :tokens (parse-command line :start start :lenient t)))

;;; --- shell escape (bang.issue) ----------------------------------------
;;;
;;; A line whose FIRST character is the shell-escape character sends its
;;; remainder to $SHELL with stdin/stdout/stderr inherited — which is what
;;; `startapp' cannot do.
;;;
;;; Both halves are hooks rather than code, because this system is
;;; deliberately dependency-free ("reusable outside the debugger"): running
;;; a subprocess would drag in uiop, and reading the setting would drag in
;;; the configuration layer, which sits ABOVE this one. The tool installs
;;; both at start-up, exactly as it installs SEDIT's on-quit policy.
;;;
;;; The character is fetched through a function, not stored in a variable,
;;; so that `,set shell-escape-character …' takes effect immediately
;;; instead of at the next launch.

(defparameter *shell-escape-character-hook* (constantly nil)
  "Called with no arguments; returns the shell-escape CHARACTER, or NIL to
disable the escape entirely. NIL by default: an embedder that installs
nothing gets no shell escape, and no surprise.")

(defparameter *shell-escape-runner* nil
  "Called with the command STRING when a shell escape fires. NIL disables
the escape as surely as a NIL character does.")

(defun shell-escape-character ()
  "The active shell-escape character, or NIL when the escape is off."
  (let ((character (ignore-errors (funcall *shell-escape-character-hook*))))
    (and (characterp character) *shell-escape-runner* character)))

(defun %shell-escape-command (line input-context)
  "The command text of a shell-escape LINE, continuation lines included.

A trailing backslash continues onto the next line (the ticket's
`!echo hello \\' / `world.'), so the backslash is dropped and the next
line appended verbatim. Reads RAW lines: leading whitespace on a
continuation belongs to the command."
  (let ((command (subseq line 1)))
    (loop :while (and (plusp (length command))
                      (char= #\\ (char command (1- (length command)))))
          :for next := (read-line-from-input-context input-context)
          :do (setf command (concatenate 'string
                                         (subseq command 0 (1- (length command)))
                                         (if (eq next :eof) "" next)))
          :until (eq next :eof))
    command))

(defun %shell-escape-command-to-run (command)
  "COMMAND as it should be handed to the shell.

A command ending in `&' is backgrounded, and a NON-INTERACTIVE bash prints
neither the PID nor any job-control notice — so ` echo $!' is appended to
print it, per the ticket. The test is made on the TRIMMED text because the
ticket allows spaces on either side; note that `a && b' does not end in
`&' and is therefore left alone, which is the intent."
  (let ((trimmed (string-trim '(#\Space #\Tab #\Return) command)))
    (if (and (plusp (length trimmed))
             (char= #\& (char trimmed (1- (length trimmed)))))
        (concatenate 'string trimmed " echo $!")
        trimmed)))

(defun %maybe-shell-escape (raw-line input-context)
  "When RAW-LINE begins with the shell-escape character, run its remainder
and return T; otherwise NIL.

RAW-LINE is deliberately untrimmed: the ticket requires that nothing —
not even a space — precede the escape character, and trimming first would
silently accept ` !pwd'."
  (let ((escape (shell-escape-character)))
    (when (and escape
               (stringp raw-line)
               (plusp (length raw-line))
               (char= escape (char raw-line 0)))
      (let ((command (%shell-escape-command-to-run
                      (%shell-escape-command raw-line input-context))))
        (when (plusp (length command))
          (funcall *shell-escape-runner* command))
        t))))

(defun comma-command-read (input-context
                           &optional (sexp-reader #'read-sexp-from-input-context))
  "The Lisp REPL reader: a line starting with a comma is a command
\(`,date'); a line starting with the shell-escape character goes to the
shell (bang.issue); anything else is unread and handed to SEXP-READER."
  (let ((raw (read-line-from-input-context input-context)))
    (if (eq raw :eof)
        :eof
        (if (%maybe-shell-escape raw input-context)
            :blank                      ; handled; ask the loop for another line
            (let ((line (string-left-trim *whitespaces* raw)))
              (cond
                ((zerop (length line)) :blank)
                ((char= #\, (char line 0)) (%parse-command-line line :start 1))
                (t (unread-line-from-input-context line input-context)
                   (funcall sexp-reader input-context))))))))

(defun command-read (input-context
                     &optional (sexp-reader #'read-sexp-from-input-context))
  "The command-mode reader (debugger, navigators, editor): every line is a
command — symbols are command names, not Lisp variables — except a line
starting with `(', a Lisp form to evaluate (we can always use (print var),
and there is no reader macro to deal with in AutoLISP)."
  (let ((raw (read-line-from-input-context input-context)))
    (if (eq raw :eof)
        :eof
        (if (%maybe-shell-escape raw input-context)
            :blank
            (let ((line (string-left-trim *whitespaces* raw)))
              (cond
                ((zerop (length line)) :blank)
                ((char= #\( (char line 0))
                 (unread-line-from-input-context line input-context)
                 (funcall sexp-reader input-context))
                (t (%parse-command-line line))))))))
