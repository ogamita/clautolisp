(in-package #:clautolisp.autolisp-runtime.tests)

(in-suite autolisp-runtime-suite)

;;; Phase 6: end-to-end smoke tests for the standalone evaluator entry
;;; points (run-autolisp-string / run-autolisp-file). The legacy
;;; autolisp-load-file path is tested elsewhere; here we only exercise
;;; the dialect-aware wrappers that the `clautolisp` CLI consumes.

(test run-autolisp-string-evaluates-strict-forms
  "run-autolisp-string evaluates a sequence of forms in a fresh session
and returns the value of the last form."
  (reset-autolisp-symbol-table)
  (let ((result (run-autolisp-string "(setq x 7) (setq y 5) (if 1 x y)")))
    (is (eql 7 result))))

(test run-autolisp-string-defaults-to-strict-dialect
  "When no dialect is given, run-autolisp-string installs the strict
profile in the active session."
  (reset-autolisp-symbol-table)
  (run-autolisp-string "(setq x 1)")
  (let* ((session (evaluation-context-session (default-evaluation-context)))
         (dialect (runtime-session-dialect session)))
    (is (eq :strict
            (clautolisp.autolisp-reader:autolisp-dialect-name dialect)))))

(test run-autolisp-string-honours-bricscad-dialect
  "Passing :dialect propagates the descriptor to the new session."
  (reset-autolisp-symbol-table)
  (let ((result (run-autolisp-string
                 "(setq x 1)"
                 :dialect (clautolisp.autolisp-reader:autolisp-dialect-bricscad-v26))))
    (is (eql 1 result))
    (let* ((session (evaluation-context-session (default-evaluation-context)))
           (dialect (runtime-session-dialect session)))
      (is (eq :bricscad-v26
              (clautolisp.autolisp-reader:autolisp-dialect-name dialect))))))

(test current-evaluation-dialect-falls-back-to-strict
  "current-evaluation-dialect returns the strict descriptor when no
session has been installed."
  (reset-autolisp-symbol-table)
  (let ((dialect (current-evaluation-dialect)))
    (is (eq :strict
            (clautolisp.autolisp-reader:autolisp-dialect-name dialect)))))

(test run-autolisp-file-loads-and-evaluates-from-disk
  "run-autolisp-file reads a file, evaluates each form, and returns the
value of the last expression."
  (reset-autolisp-symbol-table)
  (uiop:with-temporary-file (:stream stream :pathname path :type "lsp"
                             :direction :output)
    (write-string "(setq a 11) (setq b 4) (if 1 (setq c 3) nil)" stream)
    :close-stream
    (let ((result (run-autolisp-file path)))
      (is (eql 3 result)))))

;;; --- Lisp-1 / single-cell binding semantics ------------------------
;;;
;;; AutoLISP is Lisp-1 (autolisp-spec, chapter 7): SETQ and DEFUN
;;; share one per-symbol binding cell; the most recent assignment
;;; wins. These tests pin the contract so a future Lisp-2 regression
;;; would fail loudly.

(test lisp1-defun-overwrites-prior-setq-value
  "After (setq foo 42) (defun foo (x) ...), evaluating the bare symbol
foo returns the function object, not 42."
  (reset-autolisp-symbol-table)
  (run-autolisp-string "(setq foo 42) (defun foo (x) (+ 1 x))")
  (let* ((symbol (intern-autolisp-symbol "FOO"))
         (value (autolisp-symbol-value symbol)))
    (is (typep value 'clautolisp.autolisp-runtime:autolisp-usubr))))

(test lisp1-defun-then-call-after-setq-overwrite
  "After (defun bar ...) (setq bar 42), calling (bar 5) signals
:undefined-function — the function value was overwritten."
  (reset-autolisp-symbol-table)
  (let ((signalled-code nil))
    (handler-case
        (run-autolisp-string
         "(defun bar (x) (+ 1 x)) (setq bar 42) (bar 5)")
      (autolisp-runtime-error (condition)
        (setf signalled-code (autolisp-runtime-error-code condition))))
    (is (eq :undefined-function signalled-code))))

;;; --- Unbound-variable dialect contract ----------------------------
;;;
;;; Silent-NIL on bare reference to an unset symbol is strict across
;;; every named dialect (autolisp-spec ch. 3, "Unbound-Variable
;;; Reference"). The host language has no portable way to distinguish
;;; bound-to-nil from never-bound — `boundp` itself binds the tested
;;; symbol to nil — so any compliant dialect must silently NIL.
;;; clautolisp's :strict-error mode is a non-conforming diagnostic
;;; extension intended for static-analysis / unit-test harnesses; we
;;; pin both behaviours below.

(test unbound-variable-strict-dialect-returns-nil
  "Strict dialect: bare reference to an unset symbol returns nil."
  (reset-autolisp-symbol-table)
  (let ((result (run-autolisp-string "totally-unset-symbol-strict")))
    (is (null result))))

(test unbound-variable-bricscad-returns-nil
  "BricsCAD V26 dialect: bare reference to an unset symbol returns nil."
  (reset-autolisp-symbol-table)
  (let ((result
         (run-autolisp-string
          "totally-unset-symbol-lax"
          :dialect (clautolisp.autolisp-reader:autolisp-dialect-bricscad-v26))))
    (is (null result))))

(test unbound-variable-autocad-returns-nil
  "AutoCAD 2026 dialect: bare reference to an unset symbol returns nil."
  (reset-autolisp-symbol-table)
  (let ((result
         (run-autolisp-string
          "totally-unset-symbol-acad"
          :dialect (clautolisp.autolisp-reader:autolisp-dialect-autocad-2026))))
    (is (null result))))

(test unbound-variable-diagnostic-mode-signals
  "Custom dialect with :unbound-variable-mode :strict-error signals
:unbound-variable. Diagnostic-only mode; non-conforming."
  (reset-autolisp-symbol-table)
  (let* ((diagnostic-dialect
          (clautolisp.autolisp-reader:make-autolisp-dialect
           :name :strict
           :unbound-variable-mode :strict-error))
         (signalled-code nil))
    (handler-case
        (run-autolisp-string
         "totally-unset-symbol-diag"
         :dialect diagnostic-dialect)
      (autolisp-runtime-error (condition)
        (setf signalled-code (autolisp-runtime-error-code condition))))
    (is (eq :unbound-variable signalled-code))))

(test lisp1-variable-holding-subr-is-callable
  "(setq myfunc <some-subr>) followed by (myfunc ...) calls the stored
subroutine — single-cell rule (BricsCAD defect SR44723)."
  (reset-autolisp-symbol-table)
  (let ((result
         (run-autolisp-string
          "(setq myfunc add2) (myfunc 3 4)"
          :setup-fn
          (lambda (context)
            (declare (ignore context))
            (let ((adder (clautolisp.autolisp-runtime:make-autolisp-subr
                          "ADD2"
                          (lambda (a b) (+ a b)))))
              (clautolisp.autolisp-runtime:set-autolisp-symbol-function
               (intern-autolisp-symbol "ADD2") adder))))))
    (is (eql 7 result))))

(test t-symbol-self-evaluates
  "Bare T at the top level self-evaluates to T regardless of dialect.
Without this, (cond (... ) (T fallback)) would silently fall
through in any dialect whose unbound-variable mode is :silent-nil.
Discovered via greet.lsp's GUI flow on 2026-04-26."
  (reset-autolisp-symbol-table)
  (let ((result (run-autolisp-string "T")))
    (is (typep result 'clautolisp.autolisp-runtime:autolisp-symbol))
    (is (string= "T" (clautolisp.autolisp-runtime:autolisp-symbol-name result)))))

(defun install-list-subr-for-test (context)
  "Test helper: register a LIST subr in the bare runtime (which
doesn't load autolisp-builtins-core) so test snippets can use
`(list 'a 'b)' without hitting :undefined-function."
  (declare (ignore context))
  (let ((list-subr (clautolisp.autolisp-runtime:make-autolisp-subr
                    "LIST"
                    (lambda (&rest args) args))))
    (clautolisp.autolisp-runtime:set-autolisp-symbol-function
     (intern-autolisp-symbol "LIST") list-subr)))

(test function-of-lambda-via-parameter-resolves-to-lambda
  "Regression for issues/open/function-value.issue. A parameter
bound to `(function (lambda …))' — i.e. an unevaluated lambda-form
list, per the spec's FUNCTION ≡ QUOTE equivalence — must be
callable in operator position. Before the fix, lookup-function
rejected any value that wasn't a SUBR or USUBR; the parameter's
binding was therefore invisible to call dispatch and a same-named
global function was invoked instead. (funny-fun 42 (function
(lambda (x) (list 'expected x)))) returned (GOOD-NAME 42) instead
of (EXPECTED 42)."
  (reset-autolisp-symbol-table)
  (let ((result
          (run-autolisp-string
           "(defun good-name (object) (list 'good-name object))
            (defun funny-fun (object good-name) (good-name object))
            (funny-fun 42 (function (lambda (object) (list 'expected object))))"
           :setup-fn #'install-list-subr-for-test)))
    (is (consp result))
    (is (eq (intern-autolisp-symbol "EXPECTED") (first result)))
    (is (= 42 (second result)))))

(test function-of-lambda-via-parameter-respects-inner-defun-shadow
  "Same regression, second half: when an inner DEFUN inside
`(/ object good-name)' locals shadows the global GOOD-NAME and a
parameter then carries a `(function (lambda …))', the lambda must
still win in operator position. Before the fix, the inner DEFUN's
GOOD-NAME was invoked instead, returning (IN-OBJECT …) rather
than (EXPECTED …)."
  (reset-autolisp-symbol-table)
  (let ((result
          (run-autolisp-string
           "(defun good-name (object) (list 'good-name object))
            (defun funny-fun (object good-name) (good-name object))
            (defun doit-in-object (/ object good-name)
              (setq object 33)
              (defun good-name (object) (list 'in-object object))
              (funny-fun object
                         (function (lambda (object) (list 'expected object)))))
            (doit-in-object)"
           :setup-fn #'install-list-subr-for-test)))
    (is (consp result))
    (is (eq (intern-autolisp-symbol "EXPECTED") (first result)))
    (is (= 33 (second result)))))

;;;; ----- M1 special operators: SET, TRACE, UNTRACE -----

(test eval-set-form-with-quoted-symbol
  "(set 'foo 99) binds FOO to 99 and returns 99 — the canonical
SET shape (Autodesk reference)."
  (reset-autolisp-symbol-table)
  (let ((result (run-autolisp-string "(set 'foo 99) foo")))
    (is (eql 99 result))))

(test eval-set-form-evaluates-place
  "(setq name 'target) (set name 42) binds the runtime symbol
named by NAME's value — the distinguishing feature vs SETQ,
which never evaluates its place."
  (reset-autolisp-symbol-table)
  (let ((result (run-autolisp-string "(setq name 'target) (set name 42) target")))
    (is (eql 42 result))))

(test eval-set-form-wrong-arg-count-signals
  "(set 'foo) with one argument raises :wrong-number-of-arguments."
  (reset-autolisp-symbol-table)
  (let (signalled-code)
    (handler-case
        (run-autolisp-string "(set 'foo)")
      (autolisp-runtime-error (condition)
        (setf signalled-code (autolisp-runtime-error-code condition))))
    (is (eq :wrong-number-of-arguments signalled-code))))

(test eval-set-form-place-must-evaluate-to-symbol
  "(set 5 99) — place evaluates to an integer, not a symbol —
raises :invalid-set-place."
  (reset-autolisp-symbol-table)
  (let (signalled-code)
    (handler-case
        (run-autolisp-string "(set 5 99)")
      (autolisp-runtime-error (condition)
        (setf signalled-code (autolisp-runtime-error-code condition))))
    (is (eq :invalid-set-place signalled-code))))

(test eval-trace-form-adds-name-to-set
  "(trace foo) inserts FOO into *autolisp-traced-symbols* and
returns the FOO symbol (the SETQ current-value idiom)."
  (reset-autolisp-symbol-table)
  (let ((clautolisp.autolisp-runtime:*autolisp-traced-symbols*
          (make-hash-table :test 'equal)))
    (let ((result (run-autolisp-string "(defun foo () 1) (trace foo)")))
      (is (typep result 'clautolisp.autolisp-runtime:autolisp-symbol))
      (is (string= "FOO" (autolisp-symbol-name result)))
      (is (gethash "FOO"
                   clautolisp.autolisp-runtime:*autolisp-traced-symbols*)))))

(test eval-untrace-form-removes-one-name
  "(untrace foo) removes FOO from *autolisp-traced-symbols* and
leaves other entries alone."
  (reset-autolisp-symbol-table)
  (let ((clautolisp.autolisp-runtime:*autolisp-traced-symbols*
          (make-hash-table :test 'equal)))
    (setf (gethash "FOO" clautolisp.autolisp-runtime:*autolisp-traced-symbols*) t)
    (setf (gethash "BAR" clautolisp.autolisp-runtime:*autolisp-traced-symbols*) t)
    (run-autolisp-string "(defun foo () 1) (defun bar () 2) (untrace foo)")
    (is (not (gethash "FOO" clautolisp.autolisp-runtime:*autolisp-traced-symbols*)))
    (is (gethash "BAR" clautolisp.autolisp-runtime:*autolisp-traced-symbols*))))

(test eval-untrace-no-args-clears-all
  "(untrace) with no arguments is the clautolisp clear-all
extension — empties the entire trace set."
  (reset-autolisp-symbol-table)
  (let ((clautolisp.autolisp-runtime:*autolisp-traced-symbols*
          (make-hash-table :test 'equal)))
    (setf (gethash "FOO" clautolisp.autolisp-runtime:*autolisp-traced-symbols*) t)
    (setf (gethash "BAR" clautolisp.autolisp-runtime:*autolisp-traced-symbols*) t)
    (run-autolisp-string "(untrace)")
    (is (zerop (hash-table-count
                clautolisp.autolisp-runtime:*autolisp-traced-symbols*)))))

(test trace-emits-enter-exit-lines-on-traced-call
  "After (trace id), calling (id 5) emits two trace lines on the
trace stream — `-> (ID 5)` and `<- ID => 5` — driven by the
per-symbol filter without touching *autolisp-trace-p*. Uses the
identity function so no core builtins are required (the
autolisp-runtime test image doesn't load autolisp-builtins-core)."
  (reset-autolisp-symbol-table)
  (let* ((captured (make-string-output-stream))
         (clautolisp.autolisp-runtime:*autolisp-trace-p* nil)
         (clautolisp.autolisp-runtime:*autolisp-trace-stream* captured)
         (clautolisp.autolisp-runtime:*autolisp-traced-symbols*
           (make-hash-table :test 'equal)))
    (run-autolisp-string "(defun id (x) x) (trace id) (id 5)")
    (let ((text (get-output-stream-string captured)))
      (is (search "-> (ID 5)" text))
      (is (search "<- ID => 5" text)))))

(test untrace-stops-emitting-trace-lines
  "After (trace id) then (untrace id), a subsequent (id 7) must
NOT add new lines to the trace stream. Single run-autolisp-string
call so the defun + the post-untrace use share one session (each
run-autolisp-string spins up a fresh session by design). Marker
text after the second call lets us split before/after the untrace
without two separate captures."
  (reset-autolisp-symbol-table)
  (let* ((captured (make-string-output-stream))
         (clautolisp.autolisp-runtime:*autolisp-trace-p* nil)
         (clautolisp.autolisp-runtime:*autolisp-trace-stream* captured)
         (clautolisp.autolisp-runtime:*autolisp-traced-symbols*
           (make-hash-table :test 'equal)))
    (run-autolisp-string
     "(defun id (x) x) (trace id) (id 5) (untrace id) (id 7)")
    (let* ((text (get-output-stream-string captured)))
      (is (search "(ID 5)" text))
      (is (not (search "(ID 7)" text))))))

