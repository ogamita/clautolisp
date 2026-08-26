(in-package #:clautolisp.autolisp-compiler)

;;;; The AutoLISP -> Common Lisp transpiler (compiler.issue, Tier 2).
;;;;
;;;; THE ONE DESIGN DECISION THAT MAKES THIS SAFE TO GROW.
;;;;
;;;; Anything this file does not know how to translate compiles to a call
;;;; back into the interpreter on the SAME form:
;;;;
;;;;     (autolisp-eval '<form> context)
;;;;
;;;; So the compiler is correct from its first line and gets faster as its
;;;; coverage grows, instead of being wrong until it is complete. A form
;;;; that falls back costs an interpreter dispatch — exactly what it cost
;;;; before there was a compiler — and nothing else changes: the fallback
;;;; runs in the same context, on the same symbol table, with the same
;;;; dynamic bindings, because it IS the interpreter.
;;;;
;;;; That is also what makes the thing testable: every AutoLISP program is
;;;; a legitimate input from day one, and the test asserts that compiled
;;;; and interpreted evaluation agree — not that some subset compiles.
;;;;
;;;; WHAT THIS SLICE DELIBERATELY DOES NOT DO.
;;;;
;;;; The probe recorded in compiler.issue (2026-07-23) measured the ceiling
;;;; and warned where the margin goes: a codegen that FULL-CALLS the closed
;;;; runtime builtins — argument-list consing and checks per operation —
;;;; erodes the conservative variant's 4-6x lead over LispEx down to bare
;;;; parity. Hot core operators have to be open-coded as inline CL carrying
;;;; AutoLISP semantics.
;;;;
;;;; This slice full-calls them anyway, on purpose. Open-coding + - * / car
;;;; cdr … means REIMPLEMENTING their AutoLISP semantics (type coercion,
;;;; error signalling, the string/symbol wrappers) in a second place, and a
;;;; second implementation that disagrees with the first is a worse defect
;;;; than a slow one. The order is: agree with the interpreter, measure,
;;;; then open-code operator by operator with the equivalence test as the
;;;; guard. Anything else is optimising before there is anything to
;;;; protect.
;;;;
;;;; VALUES. AutoLISP values are mostly CL values here — nil is nil, truth
;;;; is anything else, numbers are CL numbers, lists are CL lists — while
;;;; strings and symbols are wrapper objects. The transpiler emits code
;;;; over the SAME representation the interpreter uses, so compiled and
;;;; interpreted code call each other with no marshalling.
;;;;
;;;; VARIABLES. Every variable reference goes through LOOKUP-VARIABLE and
;;;; SET-VARIABLE, i.e. the interpreter's own dynamic-frame + namespace
;;;; machinery. That is the faithful choice and the only one that lets
;;;; compiled and interpreted code share state. The probe's "locals as CL
;;;; specials" variant is a later optimisation, and its own measurement
;;;; says dynamic scoping is NOT the bottleneck — SBCL special access is
;;;; cheap — so there is no hurry.

(defvar *transpiler-fallbacks* nil
  "Names of the operators the last TRANSPILE-FORM fell back on, newest
first. Not a diagnostic for users: it is how the coverage test reports
what is still interpreted, so growth in coverage is measurable rather
than asserted.")

(defun %symbol-name-of (object)
  (and (typep object 'autolisp-symbol) (autolisp-symbol-name object)))

(defun %operator-name (form)
  "The operator name of FORM as an upper-case string, or NIL when FORM is
not a call with a symbol in operator position.

Upper-cased because that is what SPECIAL-OPERATOR-NAME does. The reader
interns names upper-case, so this changes nothing for source that was
read; but a symbol interned directly need not be, and dispatching on the
raw name would then disagree with the interpreter about what is a special
operator. Harmless while everything fell back; not harmless now that
calls compile."
  (and (consp form)
       (let ((name (%symbol-name-of (first form))))
         (and name (string-upcase name)))))

(defun %note-fallback (name)
  (push (or name "<not-a-symbol-call>") *transpiler-fallbacks*)
  nil)

(defun %fallback (form context-var)
  "Compile FORM by handing it back to the interpreter."
  (%note-fallback (%operator-name form))
  `(autolisp-eval ',form ,context-var))

(defun transpile-body (forms context-var)
  "Translate FORMS as an implicit PROGN, yielding the last value — nil
for an empty body, which is what AUTOLISP-EVAL-PROGN yields."
  (if (null forms)
      nil
      `(progn ,@(mapcar (lambda (form) (transpile-form form context-var)) forms))))

(defun transpile-form (form context-var)
  "Translate the AutoLISP FORM into a Common Lisp form evaluating it in
the evaluation context held by the variable CONTEXT-VAR.

Never fails: an unhandled form becomes an interpreter call on itself."
  (cond
    ;; SELF-EVALUATING-RUNTIME-VALUE-P is the interpreter's own answer,
    ;; asked rather than restated here: the compiler must not carry a
    ;; second opinion about which values evaluate to themselves. The
    ;; local predicate this replaces was a SUPERSET -- it called every
    ;; non-cons non-symbol object self-evaluating, where the interpreter
    ;; signals :invalid-form -- so compiled code returned a value where
    ;; interpreted code raised an error.
    ((self-evaluating-runtime-value-p form) `',form)

    ;; T evaluates to ITSELF, whatever it is bound to. Not a special case
    ;; worth arguing with: without it (cond (T ...)) falls through to nil
    ;; in every dialect whose unbound-variable mode is :silent-nil, which
    ;; is every product profile, and silently -- the failure this branch
    ;; exists to prevent (transpiler-t-is-not-self-evaluating.issue).
    ((and (typep form 'autolisp-symbol)
          (string= "T" (autolisp-symbol-name form)))
     `',form)

    ;; A bare symbol is a variable reference. LOOKUP-VARIABLE returns the
    ;; value as its primary value; the interpreter's own unbound-variable
    ;; diagnostic lives behind it, so referencing an unbound name behaves
    ;; identically compiled or interpreted.
    ((typep form 'autolisp-symbol)
     `(lookup-variable ',form ,context-var))

    ;; Neither self-evaluating, nor a symbol, nor a call: the interpreter
    ;; signals :invalid-form here. Hand the form to it rather than invent
    ;; a second diagnostic -- or, worse, quietly return the object.
    ((not (consp form)) (%fallback form context-var))

    (t
     (let ((name (%operator-name form))
           (arguments (rest form)))
       (cond
         ((null name) (%fallback form context-var))

         ((string= name "QUOTE") `',(first arguments))

         ((string= name "PROGN") (transpile-body arguments context-var))

         ((string= name "IF")
          ;; AutoLISP IF: no else branch yields nil.
          `(if (autolisp-true-p ,(transpile-form (first arguments) context-var))
               ,(transpile-form (second arguments) context-var)
               ,(if (third arguments)
                    (transpile-form (third arguments) context-var)
                    nil)))

         ((string= name "SETQ")
          ;; Pairs, left to right, yielding the LAST value assigned.
          ;; An odd argument count is the interpreter's error to signal,
          ;; not ours -- fall back rather than invent a second diagnostic.
          (if (oddp (length arguments))
              (%fallback form context-var)
              `(let ((%value nil))
                 (declare (ignorable %value))
                 ,@(loop for (symbol value-form) on arguments by #'cddr
                         collect `(setf %value
                                        (set-variable ',symbol
                                                      ,(transpile-form value-form context-var)
                                                      ,context-var)))
                 %value)))

         ;; AND / OR yield the T SYMBOL or nil -- not the last value, which
         ;; is what a Lisp reflex would write. Matching EVAL-AND-FORM /
         ;; EVAL-OR-FORM exactly.
         ;; The no-argument cases are emitted directly rather than as an
         ;; `if' over a constant: (and) is always true and (or) always
         ;; false, so the general shape would leave a dead branch -- which
         ;; SBCL duly notes, filling the test log with "deleting
         ;; unreachable code". Better codegen is a better answer than
         ;; muffling the note.
         ((string= name "AND")
          (if (null arguments)
              `(intern-autolisp-symbol "T")
              `(if (and ,@(mapcar (lambda (a)
                                    `(autolisp-true-p ,(transpile-form a context-var)))
                                  arguments))
                   (intern-autolisp-symbol "T")
                   nil)))

         ((string= name "OR")
          (if (null arguments)
              nil
              `(if (or ,@(mapcar (lambda (a)
                                   `(autolisp-true-p ,(transpile-form a context-var)))
                                 arguments))
                   (intern-autolisp-symbol "T")
                   nil)))

         ;; WHILE yields nil in this engine (EVAL-WHILE-FORM), not the last
         ;; body value. Copied rather than reasoned about: the compiler's
         ;; job is to agree with the interpreter, including where the
         ;; interpreter is surprising.
         ((string= name "WHILE")
          (if (null arguments)
              (%fallback form context-var)
              `(progn
                 (loop while (autolisp-true-p
                              ,(transpile-form (first arguments) context-var))
                       do ,(transpile-body (rest arguments) context-var))
                 nil)))

         ((string= name "COND")
          ;; A clause with only a test yields the test's value; otherwise
          ;; the clause body's last value. No clause taken yields nil.
          `(block %cond
             ,@(mapcar
                (lambda (clause)
                  (if (consp clause)
                      `(let ((%test ,(transpile-form (first clause) context-var)))
                         (when (autolisp-true-p %test)
                           (return-from %cond
                             ,(if (rest clause)
                                  (transpile-body (rest clause) context-var)
                                  '%test))))
                      `(progn ,(%fallback clause context-var))))
                arguments)
             nil))

         ;; A form whose operator names a special operator has UNEVALUATED
         ;; operands -- (defun f (x) ...) -- so it must never reach the
         ;; call branch below, where those operands would be evaluated as
         ;; arguments. KNOWN-SPECIAL-OPERATOR-P is the runtime's own
         ;; answer, and it is the same question the debugger's
         ;; instrumenter asks (spec 5.3); asking it beats keeping a list
         ;; here that would drift the first time an operator is added.
         ;;
         ;; The table IS extensible at run time -- REGISTER-SPECIAL-OPERATOR
         ;; is how the debugger installs its poll point -- so this reads
         ;; the table as it stands at transpile time. Registration happens
         ;; when a system loads, long before user code is compiled, so
         ;; that is sound; an operator registered AFTER a form was
         ;; compiled would not be seen by that form.
         ((known-special-operator-p name) (%fallback form context-var))

         (t
          ;; THE CALL.
          ;;
          ;; Order: the interpreter resolves the function FIRST and
          ;; evaluates the arguments AFTER (LOOKUP-FUNCTION, then a MAPCAR
          ;; over the arguments), so an undefined function is signalled
          ;; before any argument's side effects happen. Common Lisp's
          ;; left-to-right argument evaluation reproduces that order
          ;; exactly -- provided the resolution stays in the first
          ;; argument position, which is why it is written inline here
          ;; rather than hoisted into a LET.
          ;;
          ;; Entry point: CALL-AUTOLISP-FUNCTION-IN-CONTEXT, not FUNCALL.
          ;; It is the interpreter's own, so TRACE, the :subr/:usubr call
          ;; stack frames, the debugger's two-bodies dispatch and the
          ;; host-error wrapping all keep working through compiled code
          ;; with no second implementation of any of them. What compiled
          ;; code drops is the per-form (:eval . form) frame AUTOLISP-EVAL
          ;; pushes -- that cons per evaluated form is precisely the cost
          ;; being removed -- so backtraces through compiled code show
          ;; function frames but not intermediate form frames. Restoring
          ;; them is the instrumented variant's job, not this one's.
          `(call-autolisp-function-in-context
            (resolve-autolisp-function-designator ',(first form) ,context-var)
            ,context-var
            ,@(mapcar (lambda (argument) (transpile-form argument context-var))
                      arguments))))))))

(defun compile-autolisp-form (form)
  "Compile FORM into a function of one argument (the evaluation context)
that evaluates it. The counterpart of (autolisp-eval FORM context), and
the thing the equivalence test compares against."
  (let ((*transpiler-fallbacks* nil))
    (values (compile nil `(lambda (%context)
                            (declare (ignorable %context))
                            ,(transpile-form form '%context)))
            *transpiler-fallbacks*)))

(defun transpiler-coverage (form)
  "The operator names FORM would fall back on, newest first. For the
coverage test and for deciding what the next slice should handle."
  (let ((*transpiler-fallbacks* nil))
    (transpile-form form '%context)
    *transpiler-fallbacks*))
