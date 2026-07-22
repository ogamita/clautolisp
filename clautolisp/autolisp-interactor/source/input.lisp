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

(defun read-sexp-from-input-context (input-context)
  (read (input-context-stream input-context) nil :eof))

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

(defun comma-command-read (input-context
                           &optional (sexp-reader #'read-sexp-from-input-context))
  "The Lisp REPL reader: a line starting with a comma is a command
\(`,date'); anything else is unread and handed to SEXP-READER."
  (let ((line (%read-command-line input-context)))
    (case line
      ((:eof :blank) line)
      (otherwise
       (if (char= #\, (char line 0))
           (%parse-command-line line :start 1)
           (progn
             (unread-line-from-input-context line input-context)
             (funcall sexp-reader input-context)))))))

(defun command-read (input-context
                     &optional (sexp-reader #'read-sexp-from-input-context))
  "The command-mode reader (debugger, navigators, editor): every line is a
command — symbols are command names, not Lisp variables — except a line
starting with `(', a Lisp form to evaluate (we can always use (print var),
and there is no reader macro to deal with in AutoLISP)."
  (let ((line (%read-command-line input-context)))
    (case line
      ((:eof :blank) line)
      (otherwise
       (if (char= #\( (char line 0))
           (progn
             (unread-line-from-input-context line input-context)
             (funcall sexp-reader input-context))
           (%parse-command-line line))))))
