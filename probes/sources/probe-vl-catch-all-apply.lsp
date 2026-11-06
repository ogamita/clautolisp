;;;; probes/sources/probe-vl-catch-all-apply.lsp
;;;;
;;;; Does this engine accept (vl-catch-all-apply f) with NO argument
;;;; list?
;;;;
;;;; BricsCAD does, and depends on it: the vle-extension.lsp shipped
;;;; inside BricsCAD V26 and loaded by the engine at startup calls
;;;; (vl-catch-all-apply 'vl-load-com).  The autolisp-spec, following
;;;; AutoCAD's documentation, gives both arguments as required.
;;;;
;;;; AutoCAD's ACTUAL behaviour is the open question
;;;; (vl-catch-all-apply-optional-arglist.issue): documentation saying an
;;;; argument is required is not evidence that the engine rejects its
;;;; absence -- this project has already been wrong that way, e.g. the
;;;; "Sunday=1" example in vl-file-systime that no vendor document
;;;; actually supported.  So this asks the engine instead of reasoning
;;;; about it, and clautolisp's dialect scope follows the answer.
;;;;
;;;; Reading the result:
;;;;   status "ok"    -> the engine ACCEPTS one argument; the value is
;;;;                     what the called function returned.
;;;;   status "error" -> the engine REJECTS it; the message is its own
;;;;                     arity complaint, worth recording verbatim
;;;;                     because the wording identifies the engine's
;;;;                     check.
;;;;
;;;; The one-argument call cannot be made directly here: on an engine
;;;; that rejects it, the error would abort the probe run.  It is made
;;;; inside the thunk that cad-probe-capture wraps in the TWO-argument
;;;; form, which every engine accepts -- so a rejection is captured as a
;;;; result rather than ending the suite.

(defun cad-probe--vl-catch-all-apply-one-arg ()
  (cad-probe-capture "vl-catch-all-apply-arity"
    "(vl-catch-all-apply (lambda () 42)) -- argument list omitted"
    (function
      (lambda ()
        (vl-catch-all-apply (function (lambda () 42)))))))

(defun cad-probe--vl-catch-all-apply-two-args ()
  ;; The control. If THIS ever comes back "error", the probe itself is
  ;; broken (or the engine has no vl-catch-all-apply at all) and the
  ;; one-argument result above means nothing.
  (cad-probe-capture "vl-catch-all-apply-arity"
    "(vl-catch-all-apply (lambda () 42) nil) -- control, spec form"
    (function
      (lambda ()
        (vl-catch-all-apply (function (lambda () 42)) nil)))))

(defun cad-probe--vl-catch-all-apply-one-arg-with-args ()
  ;; A function that NEEDS arguments, called with the list omitted: does
  ;; the engine treat the missing list as empty (so this fails inside the
  ;; called function) or as something else? Distinguishes "accepts and
  ;; means nil" from "accepts and does something surprising".
  (cad-probe-capture "vl-catch-all-apply-arity"
    "(vl-catch-all-apply '+ ) -- omitted list, function takes arguments"
    (function
      (lambda ()
        (vl-catch-all-apply (function (lambda (a) a)))))))

(defun cad-probe-run-vl-catch-all-apply-probes ()
  (cad-probe--vl-catch-all-apply-two-args)
  (cad-probe--vl-catch-all-apply-one-arg)
  (cad-probe--vl-catch-all-apply-one-arg-with-args)
  (princ))
