(in-package #:clautolisp.tools.clautolisp)

;;;; The dribble feature (dribble.issue): record the REPL interactions
;;;; — input lines, standard output, error output, and condition
;;;; reports — into an append-mode log file.
;;;;
;;;; File format (dribble.issue):
;;;;   ;; H: clautolisp VERSION          — header, written at start
;;;;   input line                        — raw, unprefixed
;;;;   ;; O: standard output line
;;;;   ;; E: error output line
;;;;   ;; C: condition/error message line
;;;;
;;;; The REPL's *standard-input* / *standard-output* / *error-output*
;;;; are wrapped UNCONDITIONALLY (repl-loop) in three Gray streams that
;;;; pass every character through to the real stream; when a dribble is
;;;; active AND the current top interactor is in the captured interactor
;;;; set, they additionally tee complete lines into the dribble file.
;;;;
;;;; Interactor filtering (dribble.issue §Interactors): the set is
;;;; captured at DRIBBLE-START (changing *CLAL-DRIBBLE-INTERACTORS*
;;;; while active does not change the active set); the check happens
;;;; dynamically at write time against the top of
;;;; clautolisp.interactor:*interactor-stack* — an empty stack counts as
;;;; the "AUTOLISP" interactor (the REPL outside the interactor loop).

;;; --- state ------------------------------------------------------------

(defvar *dribble-stream* nil
  "The open dribble file stream, or NIL when dribbling is off.")

(defvar *dribble-names* nil
  "The interactor set captured at DRIBBLE-START: :ALL, or a list of
interactor name strings (canonical names; aliases are resolved at
start). Matched case-insensitively against the current top interactor's
name AND alias at write time.")

(defvar *dribble-path* nil
  "The absolute namestring of the active dribble file, or NIL.")

(defvar *dribble-open-tee* nil
  "The output tee currently owning an unterminated dribble line (its
buffer holds a partial line), or NIL. The interleaving rule
(dribble.issue): when the other tag or a condition line must write
while a line is open, the open line is terminated first — its partial
content is emitted as a complete prefixed line.")

;;; --- filtering ---------------------------------------------------------

(defun %dribble-current-interactor-names ()
  "The name (and alias, when present) of the current top interactor on
CLAUTOLISP.INTERACTOR:*INTERACTOR-STACK*; (\"AUTOLISP\") when the stack
is empty — the REPL outside the interactor loop belongs to AUTOLISP."
  (let ((activation (first *interactor-stack*)))
    (if activation
        (let ((interactor (clautolisp.interactor:activation-interactor activation)))
          (remove nil (list (clautolisp.interactor:interactor-name interactor)
                            (clautolisp.interactor:interactor-alias interactor))))
        (list "AUTOLISP"))))

(defun %dribble-filter-passes-p ()
  "True when a dribble is active AND the current top interactor is in
the captured set. Checked dynamically at write time, so stacking an
unlisted interactor (a debugger stop, sedit, …) pauses recording and
popping back resumes it."
  (and *dribble-stream*
       (or (eq *dribble-names* :all)
           (loop for name in (%dribble-current-interactor-names)
                   thereis (member name *dribble-names*
                                   :test #'string-equal)))))

;;; --- dribble-file writers ----------------------------------------------

(defun %dribble-write-raw-line (line)
  "Write LINE raw (no prefix — an input line) to the dribble file."
  (when *dribble-stream*
    (write-string line *dribble-stream*)
    (terpri *dribble-stream*)
    (finish-output *dribble-stream*)))

(defun %dribble-write-tagged-line (tag line)
  "Write LINE prefixed by `;; TAG: ' to the dribble file."
  (when *dribble-stream*
    (format *dribble-stream* ";; ~A: ~A~%" tag line)
    (finish-output *dribble-stream*)))

;;; --- the output tees ----------------------------------------------------

(defclass dribble-output-tee (trivial-gray-streams:fundamental-character-output-stream)
  ((understream :initarg :understream :reader tee-understream)
   (tag         :initarg :tag         :reader tee-tag)
   (buffer      :initform (make-array 80 :element-type 'character
                                         :adjustable t :fill-pointer 0)
                :reader tee-buffer)
   (column      :initform 0 :accessor tee-column))
  (:documentation "A pass-through character output stream that, while a
dribble is active and the interactor filter passes, buffers what it
writes and emits each complete line to the dribble file prefixed by its
TAG (`O' for standard output, `E' for error output)."))

(defun make-dribble-output-tee (understream tag)
  (make-instance 'dribble-output-tee :understream understream :tag tag))

(defun %tee-emit-buffered-line (tee)
  "Emit TEE's buffered (partial or complete) line as one prefixed
dribble line and reset the buffer."
  (%dribble-write-tagged-line (tee-tag tee) (tee-buffer tee))
  (setf (fill-pointer (tee-buffer tee)) 0)
  (when (eq *dribble-open-tee* tee)
    (setf *dribble-open-tee* nil)))

(defun %dribble-terminate-open-line (&key discard)
  "Terminate the open dribble line, if any: emit the owning tee's
buffered partial content as a complete prefixed line — or drop it when
DISCARD is true (used by the input echo: partial output pending when an
input line completes is prompt text, which the dribble format omits)."
  (let ((tee *dribble-open-tee*))
    (when tee
      (if (or discard (zerop (fill-pointer (tee-buffer tee))))
          (progn (setf (fill-pointer (tee-buffer tee)) 0)
                 (setf *dribble-open-tee* nil))
          (%tee-emit-buffered-line tee)))))

(defmethod trivial-gray-streams:stream-write-char ((tee dribble-output-tee) character)
  (write-char character (tee-understream tee))
  (setf (tee-column tee)
        (if (char= character #\Newline) 0 (1+ (tee-column tee))))
  (when (%dribble-filter-passes-p)
    (if (char= character #\Newline)
        ;; A newline arriving when this tee neither buffered anything
        ;; nor owns the open line terminates nothing we recorded — it
        ;; is a `~&' closing a discarded prompt (or a leading blank) —
        ;; so it emits no (empty) dribble line.
        (when (or (eq *dribble-open-tee* tee)
                  (plusp (fill-pointer (tee-buffer tee))))
          (%tee-emit-buffered-line tee))
        (progn
          ;; Interleaving rule: writing while the OTHER tee owns the
          ;; open line terminates that line first.
          (unless (eq *dribble-open-tee* tee)
            (%dribble-terminate-open-line))
          (setf *dribble-open-tee* tee)
          (vector-push-extend character (tee-buffer tee)))))
  character)

(defmethod trivial-gray-streams:stream-line-column ((tee dribble-output-tee))
  (tee-column tee))

(defmethod trivial-gray-streams:stream-start-line-p ((tee dribble-output-tee))
  (zerop (tee-column tee)))

(defmethod trivial-gray-streams:stream-force-output ((tee dribble-output-tee))
  (force-output (tee-understream tee)))

(defmethod trivial-gray-streams:stream-finish-output ((tee dribble-output-tee))
  (finish-output (tee-understream tee)))

(defmethod trivial-gray-streams:stream-clear-output ((tee dribble-output-tee))
  (clear-output (tee-understream tee)))

;;; --- the input echo -------------------------------------------------------

(defclass dribble-input-echo (trivial-gray-streams:fundamental-character-input-stream)
  ((understream :initarg :understream :reader echo-understream)
   (buffer      :initform (make-array 80 :element-type 'character
                                         :adjustable t :fill-pointer 0)
                :reader echo-buffer))
  (:documentation "A pass-through character input stream that
accumulates the line being read and, when a full line has been consumed
while the dribble filter passes, writes it RAW (no prefix) to the
dribble file."))

(defun make-dribble-input-echo (understream)
  (make-instance 'dribble-input-echo :understream understream))

(defun %echo-complete-line (echo)
  "A full input line has been consumed: dribble it raw when the filter
passes. Any pending partial output line is DISCARDED, not emitted — the
only output that can be left unterminated when the user finishes typing
a line is the prompt, which the dribble format omits."
  (when (%dribble-filter-passes-p)
    (%dribble-terminate-open-line :discard t)
    (%dribble-write-raw-line (echo-buffer echo)))
  (setf (fill-pointer (echo-buffer echo)) 0))

(defmethod trivial-gray-streams:stream-read-char ((echo dribble-input-echo))
  (let ((character (read-char (echo-understream echo) nil :eof)))
    (cond
      ((eq character :eof)
       ;; A last line not terminated by a newline still gets dribbled.
       (when (plusp (fill-pointer (echo-buffer echo)))
         (%echo-complete-line echo))
       :eof)
      ((char= character #\Newline)
       (%echo-complete-line echo)
       character)
      (t
       (vector-push-extend character (echo-buffer echo))
       character))))

(defmethod trivial-gray-streams:stream-unread-char ((echo dribble-input-echo) character)
  (unread-char character (echo-understream echo))
  (let ((buffer (echo-buffer echo)))
    (when (and (plusp (fill-pointer buffer))
               (char= character (aref buffer (1- (fill-pointer buffer)))))
      (decf (fill-pointer buffer))))
  nil)

(defmethod trivial-gray-streams:stream-read-char-no-hang ((echo dribble-input-echo))
  (when (listen (echo-understream echo))
    (trivial-gray-streams:stream-read-char echo)))

(defmethod trivial-gray-streams:stream-listen ((echo dribble-input-echo))
  (listen (echo-understream echo)))

(defmethod trivial-gray-streams:stream-clear-input ((echo dribble-input-echo))
  (setf (fill-pointer (echo-buffer echo)) 0)
  (clear-input (echo-understream echo)))

;;; --- conditions -------------------------------------------------------------

(defun dribble-condition (condition)
  "Write CONDITION's report to the dribble as `;; C: ' lines, when a
dribble is active and the filter passes. Called by the REPL's handler
clauses BEFORE the normal report goes to *error-output* (whose lines
appear as `;; E: '/`;; O: ' naturally; the redundancy is fine per
dribble.issue)."
  (when (%dribble-filter-passes-p)
    (%dribble-terminate-open-line)
    (let ((text (if (typep condition 'autolisp-runtime-error)
                    ;; `CODE: message' — the code names the error kind
                    ;; (dribble.issue example: `;; C: DIVISION-BY-ZERO:
                    ;; Division by zero in /.'), which a bare
                    ;; PRINC-TO-STRING of the condition omits.
                    (format nil "~A: ~A"
                            (autolisp-runtime-error-code condition)
                            (autolisp-runtime-error-message condition))
                    (princ-to-string condition))))
      (with-input-from-string (input text)
        (loop for line = (read-line input nil nil)
              while line
              do (%dribble-write-tagged-line "C" line))))))

;;; --- start / stop / toggle ---------------------------------------------------

(defun dribble-default-path ()
  "The default dribble file:
${XDG_STATE_HOME:-~/.local/state}/clautolisp/dribbles/YYYYMMDDTHHMMSS.log
(the timestamp is the start of the dribble, ISO-8601 basic format)."
  (multiple-value-bind (second minute hour day month year)
      (decode-universal-time (get-universal-time))
    (let* ((state-home (let ((env (uiop:getenv "XDG_STATE_HOME")))
                         (if (and env (plusp (length env)))
                             (uiop:ensure-directory-pathname env)
                             (merge-pathnames ".local/state/"
                                              (user-homedir-pathname)))))
           (directory (merge-pathnames "clautolisp/dribbles/" state-home)))
      (merge-pathnames
       (format nil "~4,'0D~2,'0D~2,'0DT~2,'0D~2,'0D~2,'0D.log"
               year month day hour minute second)
       directory))))

(defun %resolve-dribble-names (names)
  "Resolve NAMES to the captured interactor set: NIL -> (\"AUTOLISP\");
T / :ALL -> :ALL (every interactor); a list -> the given names, each
resolved through the interactor registry so an alias (\"LISP\",
\"debug\") captures its interactor's canonical name. Unregistered names
are kept as given (upcased), so a dribble can target an interactor
registered later."
  (cond
    ((or (eq names t) (eq names :all)) :all)
    ((null names) (list "AUTOLISP"))
    (t (mapcar (lambda (name)
                 (let ((interactor (clautolisp.interactor:find-registered-interactor
                                    (string name))))
                   (if interactor
                       (clautolisp.interactor:interactor-name interactor)
                       (string-upcase (string name)))))
               names))))

(defun dribble-start (path names &optional (version *version*))
  "Open PATH (the default dribble path when NIL) in append mode, write
the `;; H: clautolisp VERSION' header, and capture NAMES as the
interactor set (see %RESOLVE-DRIBBLE-NAMES). Returns the ABSOLUTE
namestring of the opened file."
  (let ((pathname (merge-pathnames (or path (dribble-default-path)))))
    (ensure-directories-exist pathname)
    (let ((stream (open pathname :direction :output
                                 :if-exists :append
                                 :if-does-not-exist :create
                                 :external-format :utf-8)))
      (setf *dribble-stream* stream
            *dribble-names*  (%resolve-dribble-names names)
            *dribble-open-tee* nil
            *dribble-path*   (namestring (or (ignore-errors (truename stream))
                                             pathname)))
      (format stream ";; H: clautolisp ~A~%" version)
      (finish-output stream)
      *dribble-path*)))

(defun dribble-stop ()
  "Flush any pending partial output line, close the dribble file, and
reset the dribble state. Returns NIL."
  (when *dribble-stream*
    (%dribble-terminate-open-line)
    (close *dribble-stream*)
    (setf *dribble-stream* nil
          *dribble-names*  nil
          *dribble-open-tee* nil
          *dribble-path*   nil))
  nil)

(defun %dribble-interactors-from-variable ()
  "Read the AutoLISP variable *CLAL-DRIBBLE-INTERACTORS* from the
current evaluation context: the T symbol -> :ALL, a list of AutoLISP
strings/symbols -> the list of name strings, NIL / unbound / no
context -> NIL. Heavily guarded: any failure yields NIL so the caller
falls back to the default (\"AUTOLISP\") set."
  (ignore-errors
   (let ((context (current-evaluation-context)))
     (when context
       (let ((symbol (clautolisp.autolisp-runtime:find-autolisp-symbol
                      "*CLAL-DRIBBLE-INTERACTORS*")))
         (when symbol
           (multiple-value-bind (value boundp) (lookup-variable symbol context)
             (when (and boundp value)
               (cond
                 ((and (typep value 'clautolisp.autolisp-runtime:autolisp-symbol)
                       (string-equal
                        "T" (clautolisp.autolisp-runtime:autolisp-symbol-name value)))
                  :all)
                 ((consp value)
                  (mapcar (lambda (element)
                            (typecase element
                              (clautolisp.autolisp-runtime:autolisp-symbol
                               (clautolisp.autolisp-runtime:autolisp-symbol-name element))
                              (clautolisp.autolisp-runtime:autolisp-string
                               (clautolisp.autolisp-runtime:autolisp-string-value element))
                              (string element)
                              (t (princ-to-string element))))
                          value))
                 (t nil))))))))))

(defun clal-dribble (&optional path interactors)
  "The dribble entry point (the CLAL-DRIBBLE builtin's hook and the
--dribble CLI implementation). Semantics (dribble.issue):
  (clal-dribble)            — toggle: start on the default path when
                              off; stop when on.
  (clal-dribble PATH [IS])  — close any active dribble, start appending
                              to PATH.
INTERACTORS is :ALL, a list of interactor names, or NIL — NIL consults
the AutoLISP variable *CLAL-DRIBBLE-INTERACTORS* (NIL/unbound meaning
the default (\"AUTOLISP\") set). Returns the absolute namestring of the
file just opened, or NIL when it just stopped dribbling."
  (let ((names (or interactors (%dribble-interactors-from-variable))))
    (cond
      (path
       (when *dribble-stream* (dribble-stop))
       (dribble-start path names))
      (*dribble-stream*
       (dribble-stop))
      (t
       (dribble-start nil names)))))
