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

;;; --- open-coded operators -------------------------------------------
;;;
;;; Calling `+' through the full protocol costs an argument list, a
;;; call-stack entry, two HANDLER-CASEs and two APPLYs -- to add two
;;; integers. Measured on this engine: the protocol is about 43 ns a call,
;;; while everything the arithmetic builtins actually DO is about a tenth
;;; of a call-heavy profile. So the win from open-coding is mostly the
;;; CALL, not the operation.
;;;
;;; WHAT MAKES THIS SAFE, and it is the whole design:
;;;
;;;  1. The inline code is a FAST PATH, not a second implementation. It
;;;     covers one narrow case, stated exactly against the builtin it
;;;     shortcuts, and EVERY other case -- other types, out-of-range
;;;     results, wrong arity, and therefore every error and every message
;;;     -- falls through to a normal call of that same builtin. There is
;;;     one implementation of `+'; there is also a shortcut for adding two
;;;     small integers.
;;;
;;;  2. The call site checks, at run time, that the name still resolves to
;;;     the exact builtin whose semantics were open-coded. `+' can be
;;;     redefined with DEFUN, assigned with SETQ, or shadowed by a
;;;     `/'-local; all three work in AutoLISP and all three were checked
;;;     against the engine. In each case the resolved object carries no
;;;     tag, the guard fails, and the ordinary call happens.
;;;
;;;  3. The function is resolved ONCE, exactly as the ordinary call branch
;;;     resolves it, and before the arguments are evaluated -- so an
;;;     undefined function is still signalled before any argument side
;;;     effect, which is the interpreter's order.
;;;
;;; The narrowness is deliberate. AutoLISP `+' is not CL `+': it signals
;;; INTEGER-OVERFLOW outside the 32-bit range, and the relational
;;; operators fold a NON-NUMERIC argument to nil instead of signalling,
;;; which loop idioms depend on. An inline path that quietly got either
;;; wrong would be worse than a slow one, so the guard tests the ARGUMENTS
;;; and, for arithmetic, the RESULT.

(defparameter *open-coded-operators*
  '(;; (NAME TAG . ARITIES-THE-FAST-PATH-IS-WRITTEN-FOR)
    ("+"    :add          2)
    ("-"    :subtract     1 2)
    ("*"    :multiply     2)
    ("1+"   :add1         1)
    ("1-"   :sub1         1)
    ("<"    :less         2)
    (">"    :greater      2)
    ("<="   :not-greater  2)
    (">="   :not-less     2)
    ("CAR"  :car          1)
    ("CDR"  :cdr          1)
    ("NULL" :null         1)
    ("NOT"  :not          1)
    ("ATOM" :atom         1)
    ("LISTP" :listp       1)
    ("ZEROP" :zerop       1)
    ("EQ"   :eq           2))
  "Operator name -> the tag its open-codable builtin carries, and the
arities an inline fast path exists for. Any other arity of the same
operator is an ordinary call: the fast paths are written per arity because
the SEMANTICS are per arity -- (- 5) negates and (- 9 4) subtracts.

The other half of this table is *OPEN-CODED-CORE-BUILTINS* in the
builtins, which is what actually stamps the tag onto a subr; the two are
joined by the tag, so neither side can open-code something the other did
not agree to.")

(defun %open-coded-operator (name arity)
  "The open-coding tag for NAME called with ARITY arguments, or NIL."
  (let ((entry (assoc name *open-coded-operators* :test #'string=)))
    (and entry
         (member arity (cddr entry))
         (second entry))))

(defun %open-coded-fast-path (tag arguments block-name)
  "The inline form for TAG over the argument VARIABLES, returning from
BLOCK-NAME when the narrow case it covers applies and falling off its own
end otherwise -- which is how it says `not mine' without having to encode
that in a value. A bare value could not say it: nil and 0 are both
perfectly good AutoLISP results, so no return value is free to mean `no
answer'. Returning from the block also means the fast path allocates
nothing at all, which is most of the point.

Each clause states, against the builtin it shortcuts, exactly which case
it is taking."
  (let ((first-argument (first arguments))
        (second-argument (second arguments)))
    (ecase tag
      ;; ARITHMETIC. BUILTIN-+ is (require-number each) then
      ;; ARITHMETIC-RESULT, and ARITHMETIC-RESULT signals INTEGER-OVERFLOW
      ;; for an integer outside (SIGNED-BYTE 32). So the fast path needs
      ;; both arguments in range AND the result in range; anything else --
      ;; a float, a string, an overflow -- is the builtin's business, and
      ;; goes to the builtin.
      ((:add :multiply)
       (%integer-arithmetic-path (ecase tag (:add '+) (:multiply '*))
                                 (list first-argument second-argument)
                                 block-name))
      (:subtract
       ;; (- x) NEGATES; (- x y) subtracts. Same builtin, two meanings,
       ;; so two fast paths -- and (- -2147483648) overflows, which the
       ;; result check catches like any other.
       (%integer-arithmetic-path '- (if second-argument
                                       (list first-argument second-argument)
                                       (list first-argument))
                                 block-name))
      (:add1 (%integer-arithmetic-path '1+ (list first-argument) block-name))
      (:sub1 (%integer-arithmetic-path '1- (list first-argument) block-name))
      ;; RELATIONAL. NUMERIC-ORDER-P folds a NON-NUMERIC argument to nil
      ;; rather than signalling -- deliberately: loop guards like
      ;; (while (<= 48 (car chars) 57) ...) depend on it -- and yields the
      ;; interned T symbol, not CL T. Two integers is the narrow case;
      ;; anything else goes to the builtin, which is the only thing that
      ;; knows the rest of that rule.
      ((:less :greater :not-greater :not-less)
       (let ((operator (ecase tag
                         (:less '<) (:greater '>)
                         (:not-greater '<=) (:not-less '>=))))
         `(when (and (typep ,first-argument '(signed-byte 32))
                     (typep ,second-argument '(signed-byte 32)))
            (return-from ,block-name
              (if (,operator ,first-argument ,second-argument)
                  (autolisp-true-symbol)
                  nil)))))
      ;; CAR / CDR. The builtin is nil -> nil, cons -> the part, anything
      ;; else -> an error. LISTP is exactly `nil or cons', and CL's CAR
      ;; of NIL is NIL, so the whole non-error domain is one line. A
      ;; string or a number still reaches the builtin and still signals.
      ((:car :cdr)
       (let ((operator (ecase tag (:car 'car) (:cdr 'cdr))))
         `(when (listp ,first-argument)
            (return-from ,block-name (,operator ,first-argument)))))
      ;; TOTAL PREDICATES. AUTOLISP-NULL / -NOT / -ATOM / -LISTP accept
      ;; ANY object and cannot signal, so there is no narrow case to
      ;; guard: the fast path is the whole function.
      ((:null :not)
       `(return-from ,block-name
          (if (null ,first-argument) (autolisp-true-symbol) nil)))
      (:atom
       `(return-from ,block-name
          (if (atom ,first-argument) (autolisp-true-symbol) nil)))
      (:listp
       `(return-from ,block-name
          (if (listp ,first-argument) (autolisp-true-symbol) nil)))
      ;; ZEROP requires a number and signals otherwise, so unlike the
      ;; predicates above it needs its guard.
      (:zerop
       `(when (typep ,first-argument '(signed-byte 32))
          (return-from ,block-name
            (if (zerop ,first-argument) (autolisp-true-symbol) nil))))
      ;; EQ is EQL, plus the rule that two STRINGS with equal contents
      ;; are EQ (the host interns literals). When neither argument is a
      ;; string that second clause cannot fire, so EQL is the whole
      ;; answer. Two strings go to the builtin, which owns that rule.
      (:eq
       `(when (not (or (typep ,first-argument 'autolisp-string)
                       (typep ,second-argument 'autolisp-string)))
          (return-from ,block-name
            (if (eql ,first-argument ,second-argument)
                (autolisp-true-symbol)
                nil)))))))

(defun %integer-arithmetic-path (operator arguments block-name)
  "The shared shape of the arithmetic fast paths: every argument a 32-bit
integer, the result checked to be one too, and the builtin left to signal
INTEGER-OVERFLOW when it is not."
  `(when (and ,@(mapcar (lambda (argument)
                          `(typep ,argument '(signed-byte 32)))
                        arguments))
     (let ((%open-coded-result (,operator ,@arguments)))
       (when (typep %open-coded-result '(signed-byte 32))
         (return-from ,block-name %open-coded-result)))))

(defun transpile-open-coded-call (form tag arguments context-var)
  "A call to an open-codable operator at an arity it has a fast path for:
the guarded fast path, falling through to an ordinary call of the very
same function.

Note the order. The function is resolved FIRST and the arguments after,
which is what the ordinary call branch does and what the interpreter does
-- an undefined function is signalled before any argument's side effect.
And it is resolved ONCE: the fast path and the fallback both use that one
resolution, so there is no window in which the guard inspects one
definition and the call reaches another.

INTERNED names, not GENSYMs, and this is a hard constraint on everything
this file emits rather than a style choice: a .lap is produced by PRINTING
the transpiled code as source and COMPILE-FILEing it, and the writer
prints with *PRINT-CIRCLE* NIL. An uninterned symbol printed that way
comes out as `#:FN364' at every occurrence, and each of those READS BACK
AS A DIFFERENT SYMBOL -- so the binding and its references come apart and
the artefact does not compile. The existing %VALUE / %TEST / %COND are
interned for the same reason.

Capture is not a risk even so: transpiled user code appears only in the
INIT FORMS, which are outside the scope of these bindings and outside the
block, so a nested open-coded call binds and returns from its own."
  (let* ((function-var '%open-coded-function)
         (block-name '%open-coded)
         (variables (subseq '(%open-coded-arg-1 %open-coded-arg-2)
                            0 (length arguments))))
    `(let ((,function-var (resolve-autolisp-function-designator
                           ',(first form) ,context-var))
           ,@(mapcar (lambda (variable argument)
                       (list variable (transpile-form argument context-var)))
                     variables arguments))
       (block ,block-name
         (when (eq (autolisp-open-code-tag ,function-var) ,tag)
           ,(%open-coded-fast-path tag variables block-name))
         (call-autolisp-function-in-context
          ,function-var ,context-var ,@variables)))))

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
         ;; %CLAL-POLL -- the node the debugger weaves around every
         ;; instrumentable form. THE seam between the two transpiler
         ;; variants pjb asked for, and the reason there can be two.
         ;;
         ;; It is a registered special operator, so without this branch
         ;; it falls to the one below and hands the interpreter the whole
         ;; form -- and since the OUTERMOST node of an instrumented body
         ;; wraps the entire body, compiling an instrumented function
         ;; would produce a single call to AUTOLISP-EVAL and gain
         ;; precisely nothing. Compiling instrumented code means
         ;; open-coding this node; there is no other way in.
         ;;
         ;; What is emitted is NOT a reimplementation of the poll
         ;; protocol. The shadow stack, the :BEFORE/:AFTER poll points,
         ;; form-level jumps and the CLAL-POLL-RETURN restart stay in the
         ;; debugger, in the one function EVAL-POLL-FORM also calls; all
         ;; that changes is how the value inside it is produced --
         ;; interpreted there, compiled here. A second copy of that
         ;; protocol would be a debugger that steps differently depending
         ;; on whether a function happened to be hot.
         ;;
         ;; The shape is checked rather than assumed: FID and FORM-ID are
         ;; host integers written by WRAP-POLL, so anything else is not a
         ;; woven node and belongs to the interpreter.
         ((and (string= name +poll-operator-name+)
               (= 3 (length arguments))
               (integerp (first arguments))
               (integerp (second arguments)))
          `(call-with-compiled-poll-point
            ,(first arguments) ,(second arguments) ,context-var
            (lambda () ,(transpile-form (third arguments) context-var))))

         ((known-special-operator-p name) (%fallback form context-var))

         ;; An operator with an inline fast path, called with the arity
         ;; that path is written for. Anything else about it -- a
         ;; different arity, a shadowed name, a redefinition -- goes
         ;; through the ordinary call below or through the guard.
         ((%open-coded-operator name (length arguments))
          (transpile-open-coded-call form
                                     (%open-coded-operator name (length arguments))
                                     arguments context-var))

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
