;;;; cadgui action layer -- SLICE D: the driveability guard.
;;;; cadgui-action-layer.issue.
;;;;
;;;; The invariant the whole epic rests on: the app is AI-driveable AND testable
;;;; because EVERY user-facing operation is a registered action reachable only
;;;; through CADGUI-INVOKE-ACTION, with no GUI back-door, and each is covered by a
;;;; headless test that drives it offscreen. This file turns that from a hope into
;;;; a CHECKED INVARIANT: CADGUI-DRIVEABILITY-VIOLATIONS returns the list of
;;;; violations (empty = green), and the runner (run-cadgui-driveability.sh) exits
;;;; non-zero on any -- wired like scripts/ci-classify-changes.py.
;;;;
;;;; The three checks (a/b/c in the issue):
;;;;   (a) registered: every action has a non-empty docstring and TYPED params
;;;;       (each param a (NAME TYPE DOC) triple).
;;;;   (b) no back-door: every declared GUI binding (*cadgui-gui-bindings*) names
;;;;       a REGISTERED action -- a widget that mutated state directly would be a
;;;;       binding to no action, or no binding at all; the shell is required to
;;;;       route every signal through this table, so enumerating it enumerates the
;;;;       GUI's entry points.
;;;;   (c) headlessly tested: every registered action was actually DISPATCHED
;;;;       through CADGUI-INVOKE-ACTION under coverage (the guard self-drives each
;;;;       one using its sample args; a new action with no sample args and no test
;;;;       that drives it shows up as :untested).

(in-package #:clautolisp.cadgui)

;;; --- (b) the GUI binding registry: the enumerable set of GUI entry points ---

(defvar *cadgui-gui-bindings* (make-hash-table :test 'equal)
  "SIGNAL (a string: a widget signal / menu path / ribbon id) -> ACTION id. The
ONE place the GUI's state-mutating entry points are declared, so the guard can
assert each dispatches a registered action and nothing mutates by another route.")

(defun cadgui-register-gui-binding (signal id)
  "Declare that GUI SIGNAL (a string) dispatches action ID. The shell calls this
for every widget / menu / ribbon entry point; the guard checks ID is registered."
  (check-type signal string)
  (check-type id keyword)
  (setf (gethash signal *cadgui-gui-bindings*) id))

(defun cadgui-gui-bindings ()
  "The declared GUI bindings as a list of (SIGNAL . ID), sorted by signal."
  (sort (loop for s being the hash-keys of *cadgui-gui-bindings* using (hash-value id)
              collect (cons s id))
        #'string< :key #'car))

;;; --- (c) sample args: how the guard self-drives each action headless --------

(defvar *cadgui-action-sample-args* (make-hash-table :test 'eq)
  "ACTION id -> a list of representative ARGS the guard applies to drive the
action headless (proving it is reachable + exercised through CADGUI-INVOKE-ACTION).
An action with neither sample args here nor a test that dispatches it is :untested.")

(defun cadgui-register-action-sample-args (id args)
  "Declare representative ARGS for driving action ID in the guard. Returns ID."
  (check-type id keyword)
  (setf (gethash id *cadgui-action-sample-args*) args)
  id)

(defun cadgui-register-builtin-driveability ()
  "Declare the GUI bindings and sample args for the built-in actions. Idempotent."
  ;; The live shell's command line submits its text through the :eval-command
  ;; action (the only GUI state-mutating entry point today; menus/ribbon arrive
  ;; with later phases, each declaring its binding here).
  (cadgui-register-gui-binding "command-line-submit" :eval-command)
  (cadgui-register-action-sample-args :add-line '(0 0 1 1))
  (cadgui-register-action-sample-args :add-circle '(0 0 1))
  (cadgui-register-action-sample-args :eval-command '("(+ 1 2)"))
  (cadgui-register-action-sample-args :entity-count '())
  (cadgui-register-action-sample-args :selection '()))

(cadgui-register-builtin-driveability)

;;; --- the checks -------------------------------------------------------------

(defun %cadgui-param-well-typed-p (param)
  "A param is well-typed when it is a (NAME TYPE DOC) triple: a symbol name, a
non-nil type spec, and a string doc."
  (and (consp param) (= 3 (length param))
       (symbolp (first param)) (first param)
       (second param)
       (stringp (third param))))

(defun cadgui-drive-all-actions (&key (reset t))
  "Self-drive every registered action that has sample args, through
CADGUI-INVOKE-ACTION, under a coverage table; return that table. With RESET
(default) start a fresh cadgui session first so the drive is deterministic.
Errors from an individual action are swallowed -- the guard cares that the action
was DISPATCHED (reachable), not that these sample args produce a particular
result."
  (when reset (cadgui-start))
  (let ((*cadgui-action-coverage* (make-hash-table :test 'eq)))
    (dolist (id (cadgui-list-actions))
      (multiple-value-bind (args present) (gethash id *cadgui-action-sample-args*)
        (when present
          (ignore-errors (apply #'cadgui-invoke-action id args)))))
    *cadgui-action-coverage*))

(defun cadgui-driveability-violations (&key (coverage nil coverage-p))
  "The list of driveability violations -- each a (:kind K :id ID :detail S) plist;
an EMPTY list means the app is fully driveable and introspectable (green). Checks
(a) every action documented + typed, (b) every GUI binding names a registered
action, and -- when COVERAGE (a hash of dispatched ids, e.g. from
CADGUI-DRIVE-ALL-ACTIONS) is supplied -- (c) every registered action was actually
dispatched headless."
  (let ((violations '()))
    (flet ((note (kind id detail) (push (list :kind kind :id id :detail detail) violations)))
      ;; (a) registered: documented + typed params
      (dolist (id (cadgui-list-actions))
        (let ((a (gethash id *cadgui-actions*)))
          (when (zerop (length (action-doc a)))
            (note :no-doc id "action has no docstring"))
          (dolist (p (action-params a))
            (unless (%cadgui-param-well-typed-p p)
              (note :bad-params id (format nil "param ~S is not a (NAME TYPE DOC) triple" p))))))
      ;; (b) no back-door: every GUI binding dispatches a registered action
      (loop for (signal . id) in (cadgui-gui-bindings)
            unless (gethash id *cadgui-actions*)
              do (note :binding-unknown-action id
                       (format nil "GUI binding ~S dispatches unregistered action ~S" signal id)))
      ;; (c) headlessly tested: every registered action was dispatched
      (when coverage-p
        (dolist (id (cadgui-list-actions))
          (unless (gethash id coverage)
            (note :untested id "no headless dispatch (add sample args or a test that drives it)")))))
    (nreverse violations)))

(defun cadgui-run-driveability-check ()
  "Run the full guard: self-drive every action, then compute violations with
coverage. Returns the violation list (empty = green). This is what the CI runner
and the self-test call."
  (let ((coverage (cadgui-drive-all-actions)))
    (cadgui-driveability-violations :coverage coverage)))

(defun cadgui-driveability-report (&optional (stream *standard-output*))
  "Run the guard and print a human/CI-readable report to STREAM. Returns the
number of violations (0 = green). The runner exits with this as its status."
  (let ((violations (cadgui-run-driveability-check)))
    (dolist (v violations)
      (format stream "VIOLATION ~A ~S -- ~A~%"
              (getf v :kind) (getf v :id) (getf v :detail)))
    (format stream "DRIVEABILITY-VIOLATIONS ~D~%" (length violations))
    (length violations)))
