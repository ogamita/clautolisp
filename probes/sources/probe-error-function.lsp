;;;; probes/sources/probe-error-function.lsp
;;;;
;;;; Is there an ERROR function in this engine, and what does it do?
;;;;
;;;; Neither vendor documents one. clautolisp provides ERROR (signal a
;;;; runtime error whose message is the argument), and treats it as a
;;;; clautolisp extension until this probe has run
;;;; (clautolisp-error-silent-under-autocad). AutoCAD 2022 is reported to
;;;; have none (alfe-autocad-error-primitive-masks-load-failure).
;;;;
;;;; The encoding probe's error-primitive.bound / .call said "yes" /
;;;; "raised: error" on BricsCAD V25 and V26, but that is not conclusive:
;;;; it tested ATOMS-FAMILY, which may list a symbol that is merely
;;;; interned (the probe source itself reads `error'), and BricsCAD is
;;;; known to report the bare word "error" for an UNDEFINED function too
;;;; (alfe-cad-load-error-message-says-only-error). So this suite records
;;;; TYPE, which reads the function cell, and compares the message of a
;;;; call of ERROR with that of a call of a function that surely does not
;;;; exist.
;;;;
;;;; Reading the result:
;;;;   error-function / type        "SUBR" (or "USUBR"...) -> a function
;;;;                                 exists; "nil" -> none.
;;;;   error-function / call ...     only made when TYPE is a function:
;;;;                                 the catch-all message of (error "x").
;;;;                                 "x" -> the argument is the message;
;;;;                                 anything else, compare it with:
;;;;   error-function / undefined    the message of an undefined function
;;;;                                 called the same way. The SAME text
;;;;                                 as the call above means the probe
;;;;                                 cannot tell ERROR from no function.
;;;;
;;;; Not measurable here, so to do by hand (deferred-spec-research,
;;;; ERROR): what a *error* handler receives for (error "x") at top level,
;;;; and what the command line prints.

(defun cad-probe--error-function-type ()
  (cad-probe-capture "error-function"
    "(type error)"
    (function
      (lambda ()
        (if (type error) (vl-symbol-name (type error)) "nil")))))

(defun cad-probe--error-function-atoms-family ()
  ;; What the encoding probe tested, to see whether it agrees with TYPE.
  (cad-probe-capture "error-function"
    "(atoms-family 1 '(\"ERROR\"))"
    (function
      (lambda ()
        (if (car (atoms-family 1 (list "ERROR"))) "listed" "not-listed")))))

(defun cad-probe--error-function-calls ()
  ;; Only where ERROR is a function: an undefined-function error is
  ;; signalled while RESOLVING the operator on AutoCAD, and can escape
  ;; vl-catch-all-apply and end the run.
  (if (member (type error) '(SUBR EXRXSUBR USUBR))
    (progn
      (cad-probe-capture "error-function"
        "(error \"clal-error-probe-marker\") -- message of the catch-all object"
        (function
          (lambda ()
            (vl-catch-all-error-message
              (vl-catch-all-apply 'error (list "clal-error-probe-marker"))))))
      (cad-probe-capture "error-function"
        "(error 'clal-error-probe-symbol) -- a symbol argument"
        (function
          (lambda ()
            (vl-catch-all-error-message
              (vl-catch-all-apply 'error (list 'clal-error-probe-symbol))))))
      (cad-probe-capture "error-function"
        "(error) -- no argument"
        (function
          (lambda ()
            (vl-catch-all-error-message
              (vl-catch-all-apply 'error '())))))
      (cad-probe-capture "error-function"
        "(clal-error-probe-undefined \"x\") -- undefined function, for comparison"
        (function
          (lambda ()
            (vl-catch-all-error-message
              (vl-catch-all-apply 'clal-error-probe-undefined (list "x")))))))
    (cad-probe-note "error-function" "calls"
                    "skipped: (type error) is not a function here")))

(defun cad-probe-run-error-function-probes ()
  (cad-probe--error-function-type)
  (cad-probe--error-function-atoms-family)
  (cad-probe--error-function-calls)
  (princ))
