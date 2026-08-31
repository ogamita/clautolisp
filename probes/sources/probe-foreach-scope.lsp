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

(defun cad-probe-foreach--own-local ( / e)
  ;; The loop variable is a /-local OF THE SAME FUNCTION.
  ;; binding semantics => BEFORE ; assignment semantics => 3
  (setq e 'before)
  (foreach e (list 1 2 3) nil)
  e)

(defun cad-probe-foreach--callee (l)
  (foreach e l nil))

(defun cad-probe-foreach--callers-local ( / e)
  ;; The loop variable is a /-local OF THE CALLER, reachable only because
  ;; AutoLISP is dynamically scoped. binding => BEFORE ; assignment => 3
  (setq e 'before)
  (cad-probe-foreach--callee (list 1 2 3))
  e)

(defun cad-probe-foreach--global ()
  ;; The name is a GLOBAL. binding => OUTER ; assignment => 2
  (setq cad-probe-foreach-g 'outer)
  (cad-probe-foreach--global-loop)
  cad-probe-foreach-g)

(defun cad-probe-foreach--global-loop ()
  (foreach cad-probe-foreach-g (list 1 2) nil))

(defun cad-probe-foreach--unbound ()
  ;; The name is bound NOWHERE before the loop. Both semantics agree the
  ;; loop variable should not survive; a non-nil answer would mean FOREACH
  ;; leaks a global, which is a third possibility worth ruling out.
  (cad-probe-foreach--unbound-loop)
  cad-probe-foreach-fresh)

(defun cad-probe-foreach--unbound-loop ()
  (foreach cad-probe-foreach-fresh (list 1 2) nil))

(defun cad-probe-foreach--empty-list ( / e)
  ;; An empty list runs no iteration. Under binding semantics e is still
  ;; BEFORE; under assignment it is also BEFORE, so this case separates
  ;; "assigns per iteration" from "assigns once up front".
  (setq e 'before)
  (foreach e nil nil)
  e)

(defun cad-probe-foreach--return-value ()
  ;; The documented return: the last body value, and nil for an empty
  ;; LIST. The empty BODY case is probed separately, below, and not from
  ;; here -- see why.
  (list (foreach e (list 1 2 3) (* e 10))
        (foreach e nil 99)))

;;; SYNTAX A HOST MIGHT REJECT GOES IN A STRING, not in this file's forms.
;;;
;;; `(foreach e lst)' with NO BODY used to sit in the function above, and
;;; it cost two days: BricsCAD would not LOAD this file because of it --
;;; on both platforms, before a single probe ran, taking the other five
;;; cases down with it and looking for all the world like a crash in the
;;; harness. AutoCAD and clautolisp both accept the form, so nothing local
;;; showed it.
;;;
;;; A probe asks whether an engine accepts something. Writing the
;;; questionable form directly means the engine answers by refusing to
;;; read the file, which is not an answer, it is a silence. Held as text
;;; and READ at run time, a refusal becomes a recorded `error' status for
;;; that one case -- which is the answer -- and the rest of the suite
;;; still runs.
;;;
;;; (An empty loop body is not an exotic case: `(while (setq i (cdr i)))'
;;; is how AutoLISP drains a list, and the same shape broke clautolisp's
;;; own compiler -- issues/closed/compiled-loop-with-empty-body.issue.)

(setq cad-probe-foreach--empty-body-source "(foreach e (list 1 2 3))")

(defun cad-probe-foreach--empty-body ()
  (eval (read cad-probe-foreach--empty-body-source)))

(defun cad-probe-run-foreach-scope-probes ()
  (cad-probe--foreach
   "loop variable is a /-local of the same function"
   "(defun f ( / e) (setq e 'before) (foreach e '(1 2 3) nil) e)"
   (function cad-probe-foreach--own-local))
  (cad-probe--foreach
   "loop variable is a /-local of the CALLER"
   "caller binds e; callee runs (foreach e ...); caller reads e"
   (function cad-probe-foreach--callers-local))
  (cad-probe--foreach
   "loop variable is a global"
   "(setq g 'outer) then (foreach g '(1 2) nil) in a function; read g"
   (function cad-probe-foreach--global))
  (cad-probe--foreach
   "loop variable bound nowhere before the loop"
   "(foreach fresh '(1 2) nil) in a function; read fresh afterwards"
   (function cad-probe-foreach--unbound))
  (cad-probe--foreach
   "empty list -- no iteration runs"
   "(setq e 'before) (foreach e nil nil) e"
   (function cad-probe-foreach--empty-list))
  (cad-probe--foreach
   "return value: last body value, and an empty list"
   "(list (foreach e '(1 2 3) (* e 10)) (foreach e nil 99))"
   (function cad-probe-foreach--return-value))
  (cad-probe--foreach
   "return value: a foreach with NO BODY (read at run time)"
   "(foreach e '(1 2 3))"
   (function cad-probe-foreach--empty-body)))
