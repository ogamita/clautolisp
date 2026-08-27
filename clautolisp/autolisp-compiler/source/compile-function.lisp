(in-package #:clautolisp.autolisp-compiler)

;;;; Compiling the BODY of an AutoLISP function (compiler.issue, Tier 2).
;;;;
;;;; The previous slice compiled a top-level form, which measured 3.4-4.2x
;;;; against the interpreter -- but only 2.3x once that form called a
;;;; user-defined function, because the callee's BODY still ran
;;;; interpreted. A compiled call into an interpreted body removes half
;;;; the work. This is the other half.
;;;;
;;;; The mechanism is the runtime's, not the compiler's: an AUTOLISP-USUBR
;;;; now carries a COMPILED-BODY beside its plain and instrumented ones,
;;;; and CALL-AUTOLISP-FUNCTION-IN-CONTEXT runs it inside the frame it
;;;; already pushes. What lives here is only the weaving, installed
;;;; through *COMPILE-USUBR-HOOK* -- the same dependency inversion the
;;;; debugger's instrumenter uses, and for the same reason: the runtime
;;;; must be able to run compiled bodies without depending on the layer
;;;; that produces them, so an image built without this system behaves
;;;; exactly as it did before the system existed.
;;;;
;;;; WHY LAZILY, AT A THRESHOLD. Weaving a fork runs the host Common Lisp
;;;; compiler, which costs far more than interpreting a short body once.
;;;; Most functions in a freshly loaded file are called once or never;
;;;; compiling those would make loading slower for nothing. So the fork is
;;;; woven on the call that crosses *AUTOLISP-COMPILATION-THRESHOLD*.
;;;;
;;;; WHY THIS IS SAFE. The body is transpiled by the same TRANSPILE-BODY
;;;; as everything else, so an operator the transpiler does not know still
;;;; becomes an AUTOLISP-EVAL call on itself. A body made entirely of
;;;; unknown operators compiles to a chain of interpreter calls: slower
;;;; than plain interpretation by one indirection, never wrong. That is
;;;; what makes it defensible to have this on by default.

(defun compile-usubr (usubr)
  "Transpile USUBR's body and store the result in its COMPILED-BODY slot.

The stored value is a function of one argument, the evaluation context,
which the evaluator calls in place of evaluating the body form by form.
Returns that function.

Installed as *COMPILE-USUBR-HOOK*; the runtime handles the failure case
by storing :FAILED, so this is free to signal."
  (let ((compiled
          (let ((*transpiler-fallbacks* nil))
            (compile nil `(lambda (%context)
                            (declare (ignorable %context))
                            ,(transpile-body (autolisp-usubr-body usubr)
                                             '%context))))))
    (setf (autolisp-usubr-compiled-body usubr) compiled)))

(defun compile-instrumented-usubr (usubr)
  "Transpile USUBR's INSTRUMENTED body and store the result in its
COMPILED-INSTRUMENTED-BODY slot. The instrumented variant pjb asked for.

Same transpiler, same contract, different input: the body woven by the
debugger, whose %CLAL-POLL nodes TRANSPILE-FORM open-codes into calls to
the debugger's own poll protocol. Nothing else about it is special, which
is the point -- an instrumented body is ordinary AutoLISP with poll nodes
in it, so the compiler needed one new form to handle, not a second
compiler.

Before this, a debug session switched the compiler off entirely: the
runtime asked for a compiled fork only when *DEBUGGING* was NIL, because
the alternative was choosing between a debuggable body and a fast one.
Compiling the instrumented body removes the choice. It matters most where
debugging is slowest and least interactive -- running to a breakpoint
inside a loop, where every poll point of every iteration was interpreted.

Installed as *COMPILE-INSTRUMENTED-USUBR-HOOK*; as with COMPILE-USUBR the
runtime handles failure by storing :FAILED, so this is free to signal."
  (let ((compiled
          (let ((*transpiler-fallbacks* nil))
            (compile nil `(lambda (%context)
                            (declare (ignorable %context))
                            ,(transpile-body
                              (autolisp-usubr-instrumented-body usubr)
                              '%context))))))
    (setf (autolisp-usubr-compiled-instrumented-body usubr) compiled)))

(defun autolisp-function-instrumented-compiled-p (usubr)
  "True when USUBR is running a COMPILED INSTRUMENTED body -- debuggable
and compiled at once."
  (functionp (autolisp-usubr-compiled-instrumented-body usubr)))

(defun compile-autolisp-function (usubr)
  "Compile USUBR's body now, whatever its call count. The explicit form of
what the threshold does automatically -- for a caller that knows a
function is worth compiling, and for tests."
  (compile-usubr usubr))

(defun autolisp-function-compiled-p (usubr)
  "True when USUBR is running a compiled body. Distinguishes the three
states the slot can be in -- not tried, compiled, and :FAILED -- so that
`is it compiled?' is answered by asking rather than by inferring it from
a call count."
  (functionp (autolisp-usubr-compiled-body usubr)))

;;; Installing the hook is the whole of this system's effect on a running
;;; image: loading the compiler makes AutoLISP functions compile
;;; themselves once they are hot, and loading nothing else changes.
(setf *compile-usubr-hook* #'compile-usubr)
(setf *compile-instrumented-usubr-hook* #'compile-instrumented-usubr)
