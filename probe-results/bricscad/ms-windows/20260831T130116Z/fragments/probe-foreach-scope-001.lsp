;;;; probes/sources/probe-foreach-scope.lsp
;;;;
;;;; Ground-truth for what FOREACH does to its loop variable.
;;;;
;;;; THE QUESTION. Does `(foreach e list ...)' BIND e for the duration of
;;;; the loop -- so that whatever e held before is restored afterwards --
;;;; or does it ASSIGN to an existing binding, leaving the last element
;;;; behind?
;;;;
;;;; The specification says BIND: "for each element of the resulting list,
;;;; bind it to name", and lists "rebinding name for each iteration" among
;;;; the side effects. But it also records FOREACH's availability as
;;;; "AutoCAD 2026: documented; BricsCAD V26: presumed compatible (no
;;;; contradicting page found)" -- i.e. nobody has asked either engine.
;;;;
;;;; clautolisp meanwhile ASSIGNS when the name already has a dynamic
;;;; binding anywhere in the chain, and only binds afresh otherwise. That
;;;; is observable, inconsistent between cases, and unverified against
;;;; either vendor -- which is what these probes are for. See
;;;; issues/open/foreach-binding-vs-assignment.issue.
;;;;
;;;; Each case is written so the ANSWER ITSELF says which semantics the
;;;; engine has, without needing to know the engine: case 1 yields BEFORE
;;;; under binding semantics and the last element under assignment.

(defun cad-probe--foreach (case expression thunk)
  (cad-probe-capture "foreach-scope" case thunk))

;;; The four cases differ only in WHERE the name is bound before the loop,
;;; which is the axis clautolisp turns out to be inconsistent along.

