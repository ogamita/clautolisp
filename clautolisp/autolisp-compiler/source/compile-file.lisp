(in-package #:clautolisp.autolisp-compiler)

;;;; Writing a .lap — a compiled AutoLISP application.
;;;;
;;;; WHAT A .lap IS (pjb, 2026-08-28). A native host FASL, renamed. Not a
;;;; Lisp image: AutoCAD and BricsCAD load "applications" into a document
;;;; that already has other applications loaded, so an artefact has to be
;;;; loadable INTO a running image, several of them, in any order. Partial
;;;; images would be the other way to do that and no current Common Lisp
;;;; produces them.
;;;;
;;;; So a .lap built by an SBCL clautolisp is NOT loadable by a CCL one,
;;;; and a .lap is not promised to survive a clautolisp version change.
;;;; Both are accepted deliberately rather than worked around: a portable
;;;; format means a custom FASL format, and bocl's experience with one was
;;;; not good on speed. (CLISP could have done it — its .fas is byte code
;;;; for a VM independent of the host, so a Windows-compiled .fas loads on
;;;; macOS. That is a property of a byte-code implementation, not
;;;; something SBCL or CCL can be talked into.) Builds for different hosts
;;;; and versions are kept apart the way the binary releases already are:
;;;; in different directories, not by encoding the host in the name.
;;;;
;;;; WHY THE ARTEFACT IS GENERATED AS SOURCE AND COMPILE-FILE'd, rather
;;;; than COMPILE'd in memory and dumped. There is no portable way to dump
;;;; a function object; COMPILE-FILE is the only door to a FASL. It is
;;;; also the door we wanted anyway: one COMPILE-FILE of one generated
;;;; file IS the compilation unit that makes file-wide optimizations
;;;; possible, so CLAL-COMPILE-SYSTEM emitting all its sources into a
;;;; single generated file is what makes it a system rather than a loop.

;;;; --- externalizing AutoLISP data ------------------------------------
;;;;
;;;; The generated file is SOURCE: every datum in it has to be printed and
;;;; read back. AutoLISP values cannot simply be printed, for two separate
;;;; reasons, and it is worth naming both because either alone would be
;;;; enough to make the obvious approach fail silently.
;;;;
;;;; PRINTING: AUTOLISP-SYMBOL has a PRINT-OBJECT method that writes its
;;;; bare name, so printing one into a source file yields a token that
;;;; reads back as a COMMON LISP symbol. Nothing signals; the artefact is
;;;; simply wrong.
;;;;
;;;; READING: even printed as #S(AUTOLISP-SYMBOL :NAME "FOO"), reading it
;;;; back would construct a NEW symbol object that is not the one in the
;;;; symbol table. The runtime compares symbols with EQ through interning,
;;;; so every such comparison would quietly stop matching — a whole
;;;; artefact whose functions are invisible to the engine that loaded it.
;;;;
;;;; Hence: emit CONSTRUCTOR forms, not literals. A symbol becomes
;;;; (INTERN-AUTOLISP-SYMBOL "FOO"), which lands in the LOADING image's
;;;; table, which is the only table it could usefully be in.

(defun runtime-datum-needs-constructing-p (object)
  "True when OBJECT cannot be written to a source file as a literal."
  (typecase object
    (autolisp-symbol t)
    (autolisp-string t)
    (cons (or (runtime-datum-needs-constructing-p (car object))
              (runtime-datum-needs-constructing-p (cdr object))))
    (t nil)))

(defun externalize-datum (object)
  "A form that, evaluated in the loading image, yields a datum equal to
OBJECT — with symbols interned in THAT image's table."
  (typecase object
    (autolisp-symbol `(intern-autolisp-symbol ,(autolisp-symbol-name object)))
    (autolisp-string `(make-autolisp-string ,(autolisp-string-value object)))
    ;; CONS rather than LIST: an AutoLISP dotted pair is a normal value
    ;; (a point, an entity association) and rebuilding it with LIST would
    ;; turn (1 . 2) into (1 2) — a change of type, not of representation.
    (cons `(cons ,(externalize-datum (car object))
                 ,(externalize-datum (cdr object))))
    (t `',object)))

(defun externalize-code (form)
  "Rewrite FORM — Common Lisp code produced by the transpiler — so that it
can be written to a source file.

Only quoted data are touched, and only those containing runtime objects;
a quoted list of numbers is already writable and is left as it is.

The constructor goes inside LOAD-TIME-VALUE rather than being evaluated
where it stands. Without that, a fallback inside a loop — which is a
plain (AUTOLISP-EVAL '<form> context) — would rebuild its form on every
iteration, so the interpreter would be handed a freshly consed tree each
time. That is not merely slower: source positions are recorded against
body conses, so a form rebuilt per call is a form the debugger can no
longer locate."
  (cond
    ((not (consp form)) form)
    ((eq 'quote (car form))
     (let ((datum (second form)))
       (if (runtime-datum-needs-constructing-p datum)
           `(load-time-value ,(externalize-datum datum) t)
           form)))
    (t
     ;; Proper and dotted code alike: the transpiler emits proper lists,
     ;; but walking the CDR keeps this honest if that ever changes.
     (cons (externalize-code (car form))
           (externalize-code (cdr form))))))

;;;; --- what a loaded .lap does ----------------------------------------

(defun load-compiled-defun (name lambda-list body compiled-body)
  "Install, in the loading image, the function a .lap carries.

Reproduces what EVAL-DEFUN-FORM does — make a usubr, bind it to NAME —
with one addition: its compiled fork is already woven, so the function
never pays the threshold or the host compiler again.

BODY is kept even though COMPILED-BODY is what runs. It is not dead
weight: it is what the debugger instruments when a session starts, what
CLAL-COMPILATION-level changes fall back to, and what an error report
prints. An artefact that dropped it would be faster to load and
undebuggable."
  (let* ((context (current-evaluation-context))
         (usubr (make-autolisp-usubr (autolisp-symbol-name name)
                                     lambda-list body context)))
    (setf (autolisp-usubr-compiled-body usubr) compiled-body)
    (set-function name usubr context)
    name))

(defun load-compiled-toplevel (thunk)
  "Run one non-DEFUN top-level form of a .lap, compiled."
  (funcall thunk (current-evaluation-context)))

;;;; --- generating the artefact source ---------------------------------

(defun %defun-form-p (form)
  (and (consp form)
       (typep (first form) 'autolisp-symbol)
       (string-equal "DEFUN" (autolisp-symbol-name (first form)))
       (>= (length form) 3)
       (typep (second form) 'autolisp-symbol)))

(defun lap-form-for-toplevel (form)
  "The Common Lisp top-level form a .lap carries for one AutoLISP form."
  (if (%defun-form-p form)
      (destructuring-bind (defun-symbol name lambda-list &rest body) form
        (declare (ignore defun-symbol))
        `(load-compiled-defun
          ,(externalize-datum name)
          ,(externalize-datum lambda-list)
          ,(externalize-datum body)
          (lambda (%context)
            (declare (ignorable %context))
            ,(externalize-code (transpile-body body '%context)))))
      ;; Everything else — SETQ at top level, a call, a nested DEFUN
      ;; inside a PROGN — is transpiled as an ordinary form. Operators the
      ;; transpiler does not handle fall back to the interpreter exactly
      ;; as they do in memory, so an artefact is never LESS capable than
      ;; the source it was built from.
      `(load-compiled-toplevel
        (lambda (%context)
          (declare (ignorable %context))
          ,(externalize-code (transpile-form form '%context))))))

(defun write-lap-source (autolisp-forms stream)
  "Write the Common Lisp source of a .lap for AUTOLISP-FORMS."
  (let ((*package* (find-package '#:clautolisp.autolisp-compiler))
        (*print-readably* nil)
        (*print-circle* nil)
        (*print-pretty* nil))
    (format stream ";;;; Generated by clautolisp. Do not edit.~%")
    (format stream "(in-package #:clautolisp.autolisp-compiler)~%~%")
    (dolist (form autolisp-forms)
      (prin1 (lap-form-for-toplevel form) stream)
      (terpri stream))))

(defun compile-autolisp-files-to-lap (source-pathnames output-pathname)
  "Compile SOURCE-PATHNAMES into the single artefact OUTPUT-PATHNAME.

All the sources go into ONE generated file and therefore through ONE
COMPILE-FILE. That is the whole difference between this and compiling
each file separately: a single compilation unit is what lets the host
coalesce literals across the sources and resolve forward references
between them without a warning at each one.

Returns the artefact's truename, or NIL if the host compiler failed."
  (let ((forms (loop for source in source-pathnames
                     append (read-runtime-from-file source))))
    (uiop:with-temporary-file (:stream stream :pathname generated
                               :type "lisp" :keep nil)
        (write-lap-source forms stream)
        :close-stream
      (multiple-value-bind (fasl warningsp failurep)
          ;; NO :OUTPUT-FILE. The host names its own output, and only
          ;; afterwards is it moved to the .lap.
          ;;
          ;; That is not fastidiousness: CCL REFUSES to compile to a
          ;; destination whose type is not its own -- "Compile destination
          ;; ... is not a lx64fsl file!" -- so asking COMPILE-FILE for a
          ;; .lap directly works on SBCL and fails on CCL. Which is the
          ;; same fact that decided the naming question: a host FASL type
          ;; is the host's business (.lx64fsl, .dx64fsl, .fasl ...), and a
          ;; .lap is that file, moved.
          ;;
          ;; Quiet by default: compiling an artefact is something the USER
          ;; asked for, not something to narrate, and the host's chatter
          ;; would name a generated temporary the user cannot act on.
          (compile-file generated :verbose nil :print nil)
        (declare (ignore warningsp))
        (cond
          ((or failurep (null fasl)) nil)
          (t
           ;; Copy-then-rename rather than RENAME-FILE straight to the
           ;; target: the host writes its FASL beside the generated source
           ;; in the temporary directory, which is very often a different
           ;; filesystem from where the user asked for the artefact, and
           ;; RENAME-FILE across filesystems fails. The final rename is
           ;; within one directory, so a reader never sees a half-written
           ;; .lap.
           (let ((staged (uiop:tmpize-pathname output-pathname)))
             (uiop:copy-file fasl staged)
             (delete-file fasl)
             ;; UIOP's form, not CL:RENAME-FILE: CCL refuses to rename
             ;; onto an existing file ("File exists") where SBCL replaces
             ;; it, so recompiling an application would fail on one host
             ;; and succeed on the other.
             (uiop:rename-file-overwriting-target staged output-pathname))
           (truename output-pathname)))))))

;;; Installing the hook is the whole of this file's effect on a running
;;; image: with the compiler loaded, CLAL-COMPILE-FILE can write an
;;; artefact; without it, the builtin says so rather than half-working.
(setf *compile-files-to-artefact-hook* #'compile-autolisp-files-to-lap)
