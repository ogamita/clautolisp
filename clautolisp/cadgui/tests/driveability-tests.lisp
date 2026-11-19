;;;; Tests for the cadgui driveability guard (driveability.lisp) -- slice D of
;;;; cadgui-action-layer. The guard itself is the fixture: a clean registry is
;;;; GREEN, and each kind of back-door (undocumented, mistyped, a GUI binding to
;;;; an unregistered action, an action no headless test drives) turns it RED.

(in-package #:clautolisp.cadgui.tests)

(in-suite cadgui-suite)

(test cadgui-driveability-guard-is-green-for-the-builtins
  ;; The CHECKED invariant: with only the built-in actions the guard finds NO
  ;; violation -- each is documented, typed, reachable only via invoke-action,
  ;; and driven headless by its sample args. Rebind the registry to a clean copy
  ;; so throwaway actions other tests registered globally do not perturb it.
  (let ((*cadgui-actions* (make-hash-table :test 'eq)))
    (cadgui-register-builtin-actions)
    (is (null (cadgui-run-driveability-check)))))

(test cadgui-driveability-flags-an-undocumented-action
  ;; (a) an action with no docstring -> :no-doc.
  (cadgui-register-action :clal-guard-no-doc :doc "" :params '() :fn (lambda () nil))
  (unwind-protect
       (let ((v (cadgui-driveability-violations)))
         (is (find-if (lambda (x) (and (eq :no-doc (getf x :kind))
                                       (eq :clal-guard-no-doc (getf x :id))))
                      v)))
    (remhash :clal-guard-no-doc *cadgui-actions*)))

(test cadgui-driveability-flags-mistyped-params
  ;; (a) a param that is not a (NAME TYPE DOC) triple -> :bad-params.
  (cadgui-register-action :clal-guard-bad-params :doc "demo"
                          :params '((x))      ; missing TYPE and DOC
                          :fn (lambda (&rest _) (declare (ignore _)) nil))
  (unwind-protect
       (let ((v (cadgui-driveability-violations)))
         (is (find-if (lambda (x) (and (eq :bad-params (getf x :kind))
                                       (eq :clal-guard-bad-params (getf x :id))))
                      v)))
    (remhash :clal-guard-bad-params *cadgui-actions*)))

(test cadgui-driveability-flags-a-gui-back-door
  ;; (b) a GUI binding that dispatches an UNREGISTERED action -> the guard's
  ;; model of a widget that mutates state by a route no action covers.
  (cadgui-register-gui-binding "rogue-widget" :clal-guard-nonexistent)
  (unwind-protect
       (let ((v (cadgui-driveability-violations)))
         (is (find-if (lambda (x) (and (eq :binding-unknown-action (getf x :kind))
                                       (eq :clal-guard-nonexistent (getf x :id))))
                      v)))
    (remhash "rogue-widget" *cadgui-gui-bindings*)))

(test cadgui-driveability-flags-an-untested-action
  ;; (c) a well-formed action that NO headless test drives (no sample args, not
  ;; dispatched) -> :untested. Register one, run the full check (with coverage).
  (cadgui-register-action :clal-guard-untested :doc "demo"
                          :params '((n integer "a number"))
                          :fn (lambda (n) n))
  (unwind-protect
       (let ((v (cadgui-run-driveability-check)))
         (is (find-if (lambda (x) (and (eq :untested (getf x :kind))
                                       (eq :clal-guard-untested (getf x :id))))
                      v)))
    (remhash :clal-guard-untested *cadgui-actions*)))

(test cadgui-driveability-report-counts-and-returns-zero-when-green
  ;; The CI runner's entry point: the report prints the count and returns it;
  ;; 0 is the green exit status.
  (let ((*cadgui-actions* (make-hash-table :test 'eq))
        count)
    (cadgui-register-builtin-actions)
    (let ((text (with-output-to-string (s) (setf count (cadgui-driveability-report s)))))
      (is (search "DRIVEABILITY-VIOLATIONS 0" text))
      (is (= 0 count)))))
