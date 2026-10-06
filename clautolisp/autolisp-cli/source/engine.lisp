;;;; -*- mode:lisp; coding:utf-8 -*-
;;;;
;;;; The engine contract shared by the clautolisp program and alfe's
;;;; in-process clautolisp engine (alfe-clautolisp-backend-semantic-
;;;; parity.issue).
;;;;
;;;; `alfe --clautolisp' runs the same engine two ways: embedded in alfe
;;;; (--backend direct, the default) or as the clautolisp program in a child
;;;; process (--backend subprocess). The two are transports, not products, so
;;;; what a program observes must not depend on which one was chosen. This
;;;; file holds the pieces of the run that both must perform IDENTICALLY and
;;;; that used to exist only in the clautolisp program:
;;;;
;;;;  - how the engine REPORTS a runtime error, a termination and an
;;;;    unexpected error (the program's wording, backtrace included);
;;;;  - the wording of an unreadable --dwg drawing;
;;;;  - the transport of the *AUTOLISP-...* bindings a front end resolved
;;;;    into a child engine, so the child installs the front end's view of
;;;;    the run (*AUTOLISP-FRONTEND* ALFE, alfe's version, the user's actions)
;;;;    rather than the one its own argv would give.

(in-package #:clautolisp.autolisp-cli)

;;; --- reporting -------------------------------------------------------

(defun %render-value-safely (object)
  "Render OBJECT through the AutoLISP value printer, falling back to ~S if
that printer signals (e.g. when the structure is malformed in mid-error)."
  (handler-case
      (clautolisp.autolisp-builtins-core:autolisp-value->string object nil)
    (error () (prin1-to-string object))))

(defun %render-frame-arguments (arguments)
  "Render a list of AutoLISP argument values as a space-separated
parenthesised list, as the source would have written them at the call site."
  (with-output-to-string (out)
    (write-char #\( out)
    (loop for cell on arguments
          for first-p = t then nil
          do (unless first-p (write-char #\Space out))
             (write-string (%render-value-safely (car cell)) out))
    (write-char #\) out)))

(defun %format-call-stack-frame (frame)
  "Render one (KIND . PAYLOAD) backtrace frame as a single line."
  (let ((kind (car frame))
        (payload (cdr frame)))
    (case kind
      (:eval        (format nil "  in EVAL: ~A" (%render-value-safely payload)))
      (:special-op  (format nil "  in SPECIAL: ~A" (%render-value-safely payload)))
      (:subr        (format nil "  in SUBR ~A: ~A"
                            (car payload) (%render-frame-arguments (cdr payload))))
      (:usubr       (format nil "  in USUBR ~A: ~A"
                            (car payload) (%render-frame-arguments (cdr payload))))
      (otherwise    (format nil "  ~A: ~S" kind payload)))))

(defun %frame-is-noise-p (frame)
  "True for backtrace frames that add no information: :eval frames whose form
is a self-evaluating atom or a bare symbol."
  (and (eq :eval (car frame))
       (not (consp (cdr frame)))))

(defun report-autolisp-runtime-error (condition &key (stream *error-output*)
                                                     (program "clautolisp")
                                                     debug-p)
  "Report the AutoLISP runtime error CONDITION on STREAM the way the
clautolisp engine does: one `PROGRAM: runtime error: CODE: MESSAGE' line,
then the AutoLISP backtrace (atom frames hidden). DEBUG-P adds the host-Lisp
backtrace."
  (format stream "~&~A: runtime error: ~A: ~A~%"
          program
          (clautolisp.autolisp-runtime:autolisp-runtime-error-code condition)
          (clautolisp.autolisp-runtime:autolisp-runtime-error-message condition))
  (let ((stack (clautolisp.autolisp-runtime:autolisp-runtime-error-call-stack
                condition)))
    (cond
      ((null stack)
       (format stream
               "AutoLISP backtrace: <no frames captured — signal raised outside an active evaluation context>~%"))
      (t
       (let ((interesting (remove-if #'%frame-is-noise-p stack)))
         (format stream
                 "AutoLISP backtrace (most recent call first, ~D frame~:P~@[, ~D atom frame~:P hidden~]):~%"
                 (length interesting)
                 (let ((hidden (- (length stack) (length interesting))))
                   (when (plusp hidden) hidden)))
         (dolist (frame interesting)
           (format stream "~A~%" (%format-call-stack-frame frame))))))
    (when debug-p
      (format stream "~&CL backtrace (host Lisp):~%")
      (handler-case
          (uiop:print-backtrace :stream stream :condition condition)
        (error (probe)
          (format stream "  <unable to render host backtrace: ~A>~%" probe))))))

(defun report-autolisp-termination (condition &key (stream *error-output*)
                                                   (program "clautolisp"))
  "Report a (quit) / (exit) termination CONDITION the way the engine does."
  (format stream "~&~A: terminated by ~A~%"
          program
          (clautolisp.autolisp-runtime:autolisp-termination-kind condition)))

(defun report-engine-error (condition &key (stream *error-output*)
                                           (program "clautolisp"))
  "Report an error that is not an AutoLISP runtime error (a file error, a
usage error) the way the engine does: `PROGRAM: CONDITION'."
  (format stream "~&~A: ~A~%" program condition))

(defun engine-drawing-error-message (path condition)
  "The message for a --dwg drawing PATH the host could not open (CONDITION).
One wording for both clautolisp variants."
  (format nil "cannot open the drawing ~A: ~A" path condition))

;;; --- front-end bindings: from a front end to a child engine -----------
;;;
;;; The bindings are AutoLISP values: strings, symbols, integers, reals, NIL
;;; and conses of those. They are written as a CL-readable tree of keyword-
;;; tagged nodes, read back with *READ-EVAL* off -- no AutoLISP reader is
;;; involved, so nothing depends on the dialect's string escapes.

(defparameter *transmit-bindings-format* 1
  "Version of the --front-end-bindings file format.")

(defun %encode-transmit-value (value)
  (cond
    ((null value) :nil)
    ((typep value 'clautolisp.autolisp-runtime:autolisp-string)
     (list :string (clautolisp.autolisp-runtime:autolisp-string-value value)))
    ((typep value 'clautolisp.autolisp-runtime:autolisp-symbol)
     (list :symbol (clautolisp.autolisp-runtime:autolisp-symbol-name value)))
    ((integerp value) (list :integer value))
    ((realp value) (list :real (float value 1d0)))
    ((consp value)
     (list :cons (%encode-transmit-value (car value))
           (%encode-transmit-value (cdr value))))
    (t (error "cannot transmit the value ~S" value))))

(defun %decode-transmit-value (node)
  (cond
    ((eq node :nil) nil)
    ((and (consp node) (keywordp (first node)))
     (ecase (first node)
       (:string  (make-autolisp-string (the string (second node))))
       (:symbol  (intern-autolisp-symbol (the string (second node))))
       (:integer (the integer (second node)))
       (:real    (the real (second node)))
       (:cons    (cons (%decode-transmit-value (second node))
                       (%decode-transmit-value (third node))))))
    (t (error "malformed transmitted value ~S" node))))

(defun write-transmit-bindings-file (path bindings)
  "Write BINDINGS -- the ((NAME VALUE) ...) list CLI-OPTIONS->TRANSMIT-
BINDINGS returns -- to PATH, in UTF-8. Returns PATH."
  (with-open-file (out path :direction :output :if-exists :supersede
                            :if-does-not-exist :create :external-format :utf-8)
    (with-standard-io-syntax
      (let ((*package* (find-package "KEYWORD")))
        (write-line ";; clautolisp front-end bindings (--front-end-bindings)" out)
        (prin1 (list :clautolisp-front-end-bindings *transmit-bindings-format*
                     (mapcar (lambda (binding)
                               (list (the string (first binding))
                                     (%encode-transmit-value (second binding))))
                             bindings))
               out)
        (terpri out))))
  path)

(defun read-transmit-bindings-file (path)
  "Read back the bindings WRITE-TRANSMIT-BINDINGS-FILE wrote to PATH.
Signals CLI-USAGE-ERROR (option --front-end-bindings) when the file is
missing or malformed."
  (handler-case
      (with-open-file (in path :direction :input :external-format :utf-8)
        (let ((form (with-standard-io-syntax
                      (let ((*read-eval* nil)
                            (*package* (find-package "KEYWORD")))
                        (read in)))))
          (unless (and (consp form)
                       (eq (first form) :clautolisp-front-end-bindings)
                       (eql (second form) *transmit-bindings-format*))
            (error "not a format-~D front-end bindings file"
                   *transmit-bindings-format*))
          (mapcar (lambda (entry)
                    (list (the string (first entry))
                          (%decode-transmit-value (second entry))))
                  (third form))))
    (error (condition)
      (error 'cli-usage-error
             :option "--front-end-bindings"
             :message (format nil "cannot read ~A: ~A" path condition)))))
