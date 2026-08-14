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

(test read-current-source-honours-the-live-dialect-variable
  "READ-CURRENT-SOURCE (the one interactive reader entry,
interactor-design-revision.issue D2) consults the dialect in force at each
call: after (setq *AUTOLISP-DIALECT* 'bricscad-v26) in a STRICT session, the
BricsCAD =\\U+XXXX= string escape reads as the code point."
  (reset-autolisp-symbol-table)
  (run-autolisp-string "(setq x 1)")          ; installs a strict session
  (let ((context (default-evaluation-context)))
    (flet ((first-string (text)
             (clautolisp.autolisp-runtime:autolisp-string-value
              (first (clautolisp.autolisp-runtime:read-current-source
                      text :context context))))
           (eval-in-context (text)
             (clautolisp.autolisp-runtime:autolisp-eval-progn
              (clautolisp.autolisp-runtime:read-runtime-from-string text)
              context)))
      ;; strict: \U+0041 is no escape — the backslash sequence stays verbatim
      (is (not (string= "A" (first-string "\"\\U+0041\""))))
      ;; switch the dialect LIVE, through the runtime variable
      (eval-in-context "(setq *AUTOLISP-DIALECT* 'bricscad-v26)")
      (is (string= "A" (first-string "\"\\U+0041\"")))
      ;; and back
      (eval-in-context "(setq *AUTOLISP-DIALECT* 'strict)")
      (is (not (string= "A" (first-string "\"\\U+0041\"")))))))

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

;;; --- Variadic functions via `&' (issues/open/variadic-functions.issue) ---

(test defun-ampersand-rest-binds-list-of-extra-args
  "(defun foo (a & rest) ...) binds REST to the list of arguments
beyond the required formals. The test uses bare references (no
CONS / LIST builtins — autolisp-runtime tests run without
builtins-core loaded) and checks the value REST takes on at the
call site."
  (reset-autolisp-symbol-table)
  ;; REST captures (2 3 4) when there is one required formal.
  (is (equal '(2 3 4)
             (run-autolisp-string
              "(defun foo (a & rest) rest) (foo 1 2 3 4)")))
  (reset-autolisp-symbol-table)
  ;; Zero-required case: REST collects everything.
  (is (equal '(10 20 30 40)
             (run-autolisp-string
              "(defun zero (& args) args) (zero 10 20 30 40)"))))

(test defun-ampersand-rest-exact-arity-rest-is-nil
  "When the caller supplies EXACTLY the number of required arguments,
REST binds to NIL (the empty list) — mirrors the (princ) /
(princ x) shape the extension was designed to support."
  (reset-autolisp-symbol-table)
  (is (null (run-autolisp-string
             "(defun bar (a & rest) rest) (bar 1)"))))

(test defun-ampersand-rest-combined-with-slash-locals
  "(/ locals*) still apply after the `&'-rest slot; locals are
initialised to NIL just like in a plain defun. The body sets the
local then returns REST so we can verify both slots survived
binding."
  (reset-autolisp-symbol-table)
  (is (equal '(3 4 5)
             (run-autolisp-string
              "(defun bar (a b & rest / x) (setq x rest) x) (bar 1 2 3 4 5)"))))

(test defun-ampersand-arity-shortfall-signals
  "Fewer arguments than REQUIRED still signals :wrong-number-of-arguments
when `&' is present. The diagnostic detail (the `at least N' phrasing)
isn't inspected here — only the error code is part of the contract."
  (reset-autolisp-symbol-table)
  (let (signalled-code)
    (handler-case
        (run-autolisp-string "(defun foo (a b & rest) a) (foo 1)")
      (autolisp-runtime-error (condition)
        (setf signalled-code (autolisp-runtime-error-code condition))))
    (is (eq :wrong-number-of-arguments signalled-code))))

(test defun-ampersand-zero-rest-symbols-signals
  "(defun foo (a & ) …) is malformed: nothing names the rest-parameter.
The diagnostic surfaces the first time FOO is called."
  (reset-autolisp-symbol-table)
  (let (signalled-code)
    (handler-case
        (run-autolisp-string "(defun foo (a & ) a) (foo 1)")
      (autolisp-runtime-error (condition)
        (setf signalled-code (autolisp-runtime-error-code condition))))
    (is (eq :invalid-rest-parameter signalled-code))))

(test defun-ampersand-multiple-rest-symbols-signals
  "(defun foo (a & x y) …) — more than one symbol after `&' is
malformed (CL's `&body' / `&optional' are NOT mimicked here; the
extension is deliberately a single-symbol slot)."
  (reset-autolisp-symbol-table)
  (let (signalled-code)
    (handler-case
        (run-autolisp-string "(defun foo (a & x y) a) (foo 1 2 3)")
      (autolisp-runtime-error (condition)
        (setf signalled-code (autolisp-runtime-error-code condition))))
    (is (eq :invalid-rest-parameter signalled-code))))

(test defun-ampersand-after-slash-signals
  "(defun foo (a / locals & x) …) — `&' must precede `/' (otherwise
it would be naming a local). The check fires when FOO is called."
  (reset-autolisp-symbol-table)
  (let (signalled-code)
    (handler-case
        (run-autolisp-string "(defun foo (a / locals & x) a) (foo 1)")
      (autolisp-runtime-error (condition)
        (setf signalled-code (autolisp-runtime-error-code condition))))
    (is (eq :invalid-rest-parameter signalled-code))))

(test lambda-ampersand-rest-binds-list-of-extra-args
  "The same `&'-rest extension fires in anonymous LAMBDAs, mirroring
the defun path through the shared usubr machinery."
  (reset-autolisp-symbol-table)
  (is (equal '(2 3 4)
             (let ((*error-output* (make-string-output-stream)))
               (run-autolisp-string
                "((lambda (a & rest) rest) 1 2 3 4)")))))

(test defun-and-rest-spelling-is-accepted-as-alias-for-ampersand
  "Per the 2026-06-07 user clarification (issues/open/
bricscad-undocumented-clisms.issue): BricsCAD V26 uses `&REST'
(the Common Lisp spelling), not the bare `&'. clautolisp accepts
BOTH spellings as synonyms; the recogniser is case-insensitive."
  (reset-autolisp-symbol-table)
  (is (equal '(2 3 4)
             (let ((*error-output* (make-string-output-stream)))
               (run-autolisp-string
                "(defun foo (a &rest args) args) (foo 1 2 3 4)"))))
  (reset-autolisp-symbol-table)
  ;; Case-insensitive: `&REST', `&Rest', `&rest' all match. We use
  ;; integers in the trailing args because EQUAL of AutoLISP-symbol
  ;; objects against CL-symbol literals returns NIL even when the
  ;; printed names line up — integers compare numerically and let
  ;; this test stay focused on the lambda-list-parser behavior.
  (is (equal '(10 20 30)
             (let ((*error-output* (make-string-output-stream)))
               (run-autolisp-string
                "(defun foo (a &Rest tail) tail) (foo 7 10 20 30)")))))

;;; --- Dialect-aware warning for the variadic separator ---

(defun %run-under-dialect (dialect-name source)
  "Run SOURCE under the dialect named DIALECT-NAME, capturing
*error-output*. Returns (values RESULT DIAGNOSTIC-STRING).
RUN-AUTOLISP-STRING ignores the default context and builds a
fresh session from its `:dialect' keyword, so we pass the
descriptor through that path rather than mutating an existing
session."
  (let ((*error-output* (make-string-output-stream))
        (dialect (clautolisp.autolisp-reader:find-autolisp-dialect
                  dialect-name)))
    (values (run-autolisp-string source :dialect dialect)
            (get-output-stream-string *error-output*))))

(test variadic-warning-silent-under-clautolisp-dialect
  "Under --dialect clautolisp, both `&' and `&REST' are accepted
silently — both are blessed by the spec extension and using either
is portable across clautolisp installs."
  (reset-autolisp-symbol-table)
  (multiple-value-bind (result diag)
      (%run-under-dialect :clautolisp
                          "(defun f (a & r) r)
                           (defun g (a &rest r) r)
                           (g 1 2 3)")
    (declare (ignore result))
    (is (null (search "lambda-list-extension" diag))
        "Expected no warning under :clautolisp; got: ~S" diag)))

(test variadic-warning-bricscad-silent-for-rest-warns-for-ampersand
  "Under --dialect bricscad-v26: `&REST' is silent (BricsCAD's
native undocumented spelling), `&' warns (BricsCAD does not
accept the bare ampersand)."
  (reset-autolisp-symbol-table)
  (multiple-value-bind (result diag)
      (%run-under-dialect :bricscad-v26
                          "(defun g (a &rest r) r) (g 1 2 3)")
    (declare (ignore result))
    (is (null (search "lambda-list-extension" diag))
        "&REST should be silent under :bricscad-v26; got: ~S" diag))
  (reset-autolisp-symbol-table)
  (multiple-value-bind (result diag)
      (%run-under-dialect :bricscad-v26
                          "(defun f (a & r) r) (f 1 2 3)")
    (declare (ignore result))
    (is (search "[lambda-list-extension]" diag)
        "& should warn under :bricscad-v26; got: ~S" diag)
    (is (search "`&'" diag)
        "warning should mention `&' specifically; got: ~S" diag)))

(test variadic-warning-strict-warns-for-both-spellings
  "Under --dialect strict (and any non-clautolisp / non-bricscad
dialect), BOTH spellings warn — they are non-portable across
vendors and the strict dialect surfaces every such departure."
  (reset-autolisp-symbol-table)
  (multiple-value-bind (result diag)
      (%run-under-dialect :strict
                          "(defun f (a & r) r)
                           (defun g (a &rest r) r)")
    (declare (ignore result))
    (is (search "`&'" diag) "Expected `&' warning; got: ~S" diag)
    (is (search "`&REST'" diag) "Expected `&REST' warning; got: ~S" diag)))

(test variadic-warning-silent-under-lax-dialect
  "Under --dialect lax, NOTHING warns — `--lax' is the catch-all
`accept every vendor's extensions without complaining' mode, by
spec parallel with how the encoding-diagnostic gate already
silences itself under :lax (`%enc-dialect-is-lax-p'). Both `&'
and `&REST' are accepted silently."
  (reset-autolisp-symbol-table)
  (multiple-value-bind (result diag)
      (%run-under-dialect :lax
                          "(defun f (a & r) r)
                           (defun g (a &rest r) r)
                           (g 1 2 3)")
    (declare (ignore result))
    (is (null (search "lambda-list-extension" diag))
        "Expected no warning under :lax; got: ~S" diag)))

(test variadic-warning-autocad-warns-for-both-spellings
  "Under --dialect autocad-2026, same behavior as strict: both
spellings warn, because neither is part of the Autodesk public
AutoLISP reference."
  (reset-autolisp-symbol-table)
  (multiple-value-bind (result diag)
      (%run-under-dialect :autocad-2026
                          "(defun g (a &rest r) r)")
    (declare (ignore result))
    (is (search "`&REST'" diag)
        "&REST should warn under :autocad-2026; got: ~S" diag)))

;;; --- Dialect portability warnings: dedup + escalation (ch.25) ---
;;;
;;; The &rest lambda-list extension is the first concrete consumer of
;;; the autolisp-spec ch.25 "Dialect Portability Warnings" mechanism.
;;; These tests pin the three properties that the ch.25 model adds on
;;; top of the plain dialect-gated emit: once-per-occurrence dedup,
;;; evaluation-tied firing (guarded code stays silent), and the
;;; optional warning->error escalation knob.

(defun %count-substrings (needle haystack)
  "Number of non-overlapping occurrences of NEEDLE in HAYSTACK."
  (loop with n = 0 with start = 0
        for pos = (search needle haystack :start2 start)
        while pos
        do (incf n) (setf start (+ pos (length needle)))
        finally (return n)))

(test portability-warning-loop-warns-once-per-occurrence
  "autolisp-spec ch.25 once-per-occurrence: the SAME defun re-evaluated
in a loop warns exactly once, not once per iteration — the dedup key is
the source occurrence (the lambda-list cons identity)."
  (reset-autolisp-symbol-table)
  (multiple-value-bind (result diag)
      (%run-under-dialect :strict
                          "(repeat 3 (defun loopf (a &rest r) r))")
    (declare (ignore result))
    (is (= 1 (%count-substrings "[lambda-list-extension]" diag))
        "Expected exactly one warning across 3 iterations; got: ~S" diag)))

(test portability-warning-distinct-occurrences-warn-separately
  "autolisp-spec ch.25: two DIFFERENT defuns each using &rest warn
independently — the dedup key is the occurrence, not the construct class."
  (reset-autolisp-symbol-table)
  (multiple-value-bind (result diag)
      (%run-under-dialect :strict
                          "(defun occa (a &rest r) r)
                           (defun occb (a &rest r) r)")
    (declare (ignore result))
    (is (= 2 (%count-substrings "[lambda-list-extension]" diag))
        "Expected two independent warnings; got: ~S" diag)))

(test portability-warning-guarded-occurrence-is-silent
  "autolisp-spec ch.25 evaluation-tied: a defun guarded behind a false
branch is never evaluated and therefore never warns."
  (reset-autolisp-symbol-table)
  (multiple-value-bind (result diag)
      (%run-under-dialect :strict
                          "(if nil (defun guardedf (a &rest r) r))")
    (declare (ignore result))
    (is (null (search "lambda-list-extension" diag))
        "A never-evaluated defun must not warn; got: ~S" diag)))

(test portability-warning-escalation-signals-error
  "autolisp-spec ch.25 escalation knob: with :portability-warning-mode
:error the advisory becomes an AutoLISP runtime error
(:non-portable-construct), changing program outcome. Off by default."
  (reset-autolisp-symbol-table)
  (let* ((escalating
          (clautolisp.autolisp-reader:make-autolisp-dialect
           :name :strict
           :portability-warning-mode :error))
         (signalled-code nil)
         (*error-output* (make-string-output-stream)))
    (handler-case
        (run-autolisp-string "(defun escf (a &rest r) r)"
                             :dialect escalating)
      (autolisp-runtime-error (condition)
        (setf signalled-code (autolisp-runtime-error-code condition))))
    (is (eq :non-portable-construct signalled-code)
        "Expected :non-portable-construct under escalation; got: ~S"
        signalled-code)))

(test portability-warning-default-mode-does-not-error
  "The default :warn mode keeps &rest advisory — the defun still defines
and the program runs (no error signalled), only a warning is printed."
  (reset-autolisp-symbol-table)
  (let ((*error-output* (make-string-output-stream)))
    (is (equal '(2 3)
               (run-autolisp-string
                "(defun okf (a &rest r) r) (okf 1 2 3)"
                :dialect (clautolisp.autolisp-reader:find-autolisp-dialect
                          :strict))))))

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

;;; --- source-aware-defun-documentation: doc-update rules -----------

(defun %doc (name)
  "Helper for the doc-rule tests: look up the doc tag attached to
the innermost binding of NAME (uppercased string). Returns nil,
(:function \"S\"), or (:variable \"S\")."
  (lookup-documentation (intern-autolisp-symbol name)))

(test doc-rule-defun-with-block-installs-function-doc
  (reset-autolisp-symbol-table)
  (run-autolisp-string ";| hello |;
(defun foo () 1)")
  (is (equal '(:function " hello ") (%doc "FOO"))))

(test doc-rule-defun-without-block-clears-existing-doc
  ;; DEFUN is an authoritative redeclaration: absent block → nil.
  (reset-autolisp-symbol-table)
  (run-autolisp-string ";| first |;
(defun foo () 1)
(defun foo () 2)")
  (is (null (%doc "FOO"))))

(test doc-rule-setq-with-block-installs-variable-doc
  (reset-autolisp-symbol-table)
  (run-autolisp-string ";| counter |;
(setq counter 0)")
  (is (equal '(:variable " counter ") (%doc "COUNTER"))))

(test doc-rule-bare-setq-preserves-variable-doc
  ;; A bare (setq x ...) after a documented (setq x ...) leaves the
  ;; doc alone — plain mutation does not erase a variable's doc.
  (reset-autolisp-symbol-table)
  (run-autolisp-string ";| counter |;
(setq counter 0)
(setq counter 1)
(setq counter 2)")
  (is (equal '(:variable " counter ") (%doc "COUNTER"))))

(test doc-rule-bare-setq-clears-function-doc
  ;; A bare (setq x ...) after a documented (defun x ...) clears
  ;; the function-doc — it no longer describes what is bound.
  (reset-autolisp-symbol-table)
  (run-autolisp-string ";| handler |;
(defun handler () nil)
(setq handler 42)")
  (is (null (%doc "HANDLER"))))

(test doc-rule-multi-pair-setq-only-first-pair-sees-block
  ;; The parse-tree's preceding-doc belongs to the form, not to
  ;; each pair: only the first name receives the doc; subsequent
  ;; pairs apply the no-block rule independently.
  (reset-autolisp-symbol-table)
  (run-autolisp-string ";| pair |;
(setq a 1 b 2 c 3)")
  (is (equal '(:variable " pair ") (%doc "A")))
  (is (null (%doc "B")))
  (is (null (%doc "C"))))

(test doc-rule-locally-rebound-name-shadows-outer-doc
  ;; The shadowing example from the issue: an inner (defun foo …)
  ;; inside (defun foo (/ foo) …) writes its doc to the LOCAL
  ;; binding cell, not the global one; the global doc survives
  ;; the call. The "inner doc visible inside the body" half of
  ;; the contract is exercised end-to-end via the
  ;; CLAUTOLISP-DOCUMENTATION builtin in autolisp-test; here at
  ;; the runtime layer the meaningful invariant is the after-call
  ;; state — the global cell is untouched.
  (reset-autolisp-symbol-table)
  (run-autolisp-string ";| global doc |;
(defun foo (/ foo)
  ;| inner doc |;
  (defun foo () 1)
  (foo))
(foo)")
  (is (equal '(:function " global doc ") (%doc "FOO"))))

(test doc-rule-second-block-clobbers-first-at-read-time
  ;; Two ;|…|; blocks before one defun: the second wins (the
  ;; parser's pending-doc slot is overwritten by each block).
  (reset-autolisp-symbol-table)
  (run-autolisp-string ";| first |;
;| second |;
(defun foo () 1)")
  (is (equal '(:function " second ") (%doc "FOO"))))

;;;; ----- COMMAND / COMMAND-S special forms -------------------------
;;;; (deferred-command-special-form issue). The runtime evaluates the
;;;; arguments, normalizes each value to a command-line token string,
;;;; and routes the sequence through *HOST-COMMAND-FUNCTION*. These
;;;; tests replace that hook with a recorder — no host system needed.

(defun call-with-command-recorder (thunk)
  "Run THUNK with the COMMAND routing hook replaced by a recorder and
a non-nil dummy default host. Returns (values result routed-calls)
where ROUTED-CALLS is the list of token lists, oldest first."
  (let ((calls '()))
    (let ((clautolisp.autolisp-runtime:*host-command-function*
            (lambda (host tokens)
              (declare (ignore host))
              (push tokens calls)
              nil))
          (clautolisp.autolisp-runtime:*default-runtime-host*
            :fake-command-host))
      (values (funcall thunk) (reverse calls)))))

(test command-routes-normalized-tokens-and-returns-nil
  "(command \"._LINE\" pt1 pt2 \"\") evaluates its arguments, formats
points as comma-separated coordinates, keeps strings verbatim
(including the \"\" RETURN token), and returns nil."
  (reset-autolisp-symbol-table)
  (multiple-value-bind (result calls)
      (call-with-command-recorder
       (lambda ()
         (run-autolisp-string
          "(setq p1 '(0.0 0.0 0.0))
           (command \"._LINE\" p1 '(10.0 10.0 0.0) \"\")")))
    (is (null result))
    (is (equal '(("._LINE" "0.0,0.0,0.0" "10.0,10.0,0.0" ""))
               calls))))

(test command-formats-integers-reals-2d-points-and-pause
  "Integer tokens print in decimal, reals in AutoLISP princ spelling,
2D points as X,Y; the one-backslash PAUSE string passes through."
  (reset-autolisp-symbol-table)
  (multiple-value-bind (result calls)
      (call-with-command-recorder
       (lambda ()
         (run-autolisp-string
          "(command \"._CIRCLE\" '(1 2) 5.5 42 \"\\\\\")")))
    (is (null result))
    (is (equal '(("._CIRCLE" "1,2" "5.5" "42" "\\"))
               calls))))

(test command-with-no-arguments-routes-empty-sequence
  "(command) — the vendor-documented cancel — routes an empty token
sequence to the host."
  (reset-autolisp-symbol-table)
  (multiple-value-bind (result calls)
      (call-with-command-recorder
       (lambda () (run-autolisp-string "(command)")))
    (is (null result))
    (is (equal '(()) calls))))

(test command-s-shares-routing-and-returns-nil
  "(command-s ...) shares COMMAND's token routing (the in-process
engine is already synchronous) and returns nil."
  (reset-autolisp-symbol-table)
  (multiple-value-bind (result calls)
      (call-with-command-recorder
       (lambda () (run-autolisp-string "(command-s \"._REGEN\")")))
    (is (null result))
    (is (equal '(("._REGEN")) calls))))

(test command-rejects-values-without-command-input-reading
  "nil and non-point lists have no command-line spelling —
:invalid-command-argument."
  (reset-autolisp-symbol-table)
  (dolist (source '("(command \"._LINE\" nil)"
                    "(command '(\"a\" \"b\"))"))
    (let ((signalled-code nil))
      (handler-case
          (call-with-command-recorder
           (lambda () (run-autolisp-string source)))
        (autolisp-runtime-error (condition)
          (setf signalled-code (autolisp-runtime-error-code condition))))
      (is (eq :invalid-command-argument signalled-code)
          "~A should signal :invalid-command-argument, got ~S"
          source signalled-code))))

(test command-without-host-signals-host-not-supported
  "With no HAL backend attached (and no routing hook installed),
COMMAND fails loudly with :host-not-supported."
  (reset-autolisp-symbol-table)
  (let ((clautolisp.autolisp-runtime:*host-command-function* nil)
        (clautolisp.autolisp-runtime:*default-runtime-host* nil)
        (signalled-code nil))
    (handler-case
        (run-autolisp-string "(command \"._LINE\")")
      (autolisp-runtime-error (condition)
        (setf signalled-code (autolisp-runtime-error-code condition))))
    (is (eq :host-not-supported signalled-code))))

;;; --- LET: the BricsCAD V26 undocumented extension ------------------
;;;
;;; issues/open/bricscad-undocumented-clisms.issue, "Harvest RESULTS
;;; (2026-08-07, real BricsCAD V26 / macOS runner)". LET is the one
;;; genuine, implementable BricsCAD extension the harvest confirmed:
;;; CL-style PARALLEL binding, with an implicit-progn body. LET* was
;;; refuted ("no function definition <LET*>") and is intentionally NOT
;;; provided. These tests pin the semantics + the
;;; [ext-bricscad-undocumented] dialect-warning gate.

(defun install-list-and-plus-subrs-for-test (context)
  "Test helper: register LIST and `+' subrs in the bare runtime (which
does not load autolisp-builtins-core) so LET snippets can mirror the
harvest transcript — (list x y) and (+ x y) — without hitting
:undefined-function."
  (declare (ignore context))
  (flet ((reg (name fn)
           (clautolisp.autolisp-runtime:set-autolisp-symbol-function
            (intern-autolisp-symbol name)
            (clautolisp.autolisp-runtime:make-autolisp-subr name fn))))
    (reg "LIST" (lambda (&rest args) args))
    (reg "+" (lambda (&rest args) (apply #'+ args)))))

(defun %run-let-silently (source)
  "Run SOURCE under the :clautolisp dialect (LET silent there) with the
LIST/`+' subrs installed, swallowing *error-output*. Returns the value
of the last form."
  (let ((*error-output* (make-string-output-stream)))
    (run-autolisp-string
     source
     :dialect (clautolisp.autolisp-reader:find-autolisp-dialect :clautolisp)
     :setup-fn #'install-list-and-plus-subrs-for-test)))

(test let-parallel-binding-matches-bricscad-harvest
  "The exact 2026-08-07 harvest case: (setq x 10)(let ((x 1)(y x))
(list x y)) => (1 10). PARALLEL binding — the y init-form sees the
OUTER x (=10), NOT the let's x (=1); had binding been sequential (a
let*) y would be 1 and the result (1 1)."
  (reset-autolisp-symbol-table)
  (is (equal '(1 10)
             (%run-let-silently
              "(setq x 10) (let ((x 1) (y x)) (list x y))"))))

(test let-sum-matches-bricscad-harvest
  "The harvest LET-SUM=3: (let ((x 1)(y 2)) (+ x y)) => 3."
  (reset-autolisp-symbol-table)
  (is (eql 3 (%run-let-silently "(let ((x 1) (y 2)) (+ x y))"))))

(test let-body-is-implicit-progn-returning-last
  "The LET body is an implicit progn: every form runs in order and the
value of the LAST is returned. No builtins needed — SETQ is a special
form and the bare variable reference returns the binding."
  (reset-autolisp-symbol-table)
  (is (eql 3 (%run-let-silently "(let ((x 1)) (setq x 2) (setq x 3) x)"))))

(test let-empty-body-returns-nil
  "A LET with no body forms returns nil (the implicit-progn of nothing)."
  (reset-autolisp-symbol-table)
  (is (null (%run-let-silently "(let ((x 1)))"))))

(test let-bare-symbol-binding-defaults-to-nil
  "A bare-symbol binding (no init-form) binds the variable to nil, like
Common Lisp's (let (x) ...)."
  (reset-autolisp-symbol-table)
  (is (null (%run-let-silently "(let (x) x)")))
  (reset-autolisp-symbol-table)
  (is (eql 5 (%run-let-silently "(let ((x 5)) x)"))))

(test let-shadow-is-torn-down-after-body
  "A LET binding shadows the surrounding binding only for the extent of
the body: mutating the LET-bound X inside does not leak out. After the
LET, X resolves to its outer value 99."
  (reset-autolisp-symbol-table)
  (is (eql 99 (%run-let-silently "(setq x 99) (let ((x 1)) (setq x 2)) x"))))

(test let-shadow-interacts-with-slash-locals
  "LET nested inside a defun's `/'-locals: the LET shadows the local Y
for its body, and the shadow is torn down on exit so the enclosing
local's value (5) is what the function returns."
  (reset-autolisp-symbol-table)
  (is (eql 5 (%run-let-silently
              "(defun f (/ y) (setq y 5) (let ((y 1)) (setq y 2)) y) (f)"))))

(test let-malformed-binding-signals
  "A binding that is neither a symbol nor a (symbol init-form) list is
rejected with :invalid-let-binding."
  (reset-autolisp-symbol-table)
  (let ((signalled-code nil)
        (*error-output* (make-string-output-stream)))
    (handler-case
        (run-autolisp-string
         "(let ((5 1)) 5)"
         :dialect (clautolisp.autolisp-reader:find-autolisp-dialect :clautolisp))
      (autolisp-runtime-error (condition)
        (setf signalled-code (autolisp-runtime-error-code condition))))
    (is (eq :invalid-let-binding signalled-code))))

;;; --- LET dialect-warning gate [ext-bricscad-undocumented] ----------

(test let-warning-silent-under-bricscad-dialect
  "Under --dialect bricscad-v26, LET is native — no warning."
  (reset-autolisp-symbol-table)
  (multiple-value-bind (result diag)
      (%run-under-dialect :bricscad-v26 "(let ((x 1)) x)")
    (declare (ignore result))
    (is (null (search "ext-bricscad-undocumented" diag))
        "LET must be silent under :bricscad-v26; got: ~S" diag)))

(test let-warning-silent-under-clautolisp-dialect
  "Under --dialect clautolisp, LET is a blessed extension — no warning."
  (reset-autolisp-symbol-table)
  (multiple-value-bind (result diag)
      (%run-under-dialect :clautolisp "(let ((x 1)) x)")
    (declare (ignore result))
    (is (null (search "ext-bricscad-undocumented" diag))
        "LET must be silent under :clautolisp; got: ~S" diag)))

(test let-warning-silent-under-lax-dialect
  "Under --dialect lax (accept every vendor extension quietly), LET is
silent."
  (reset-autolisp-symbol-table)
  (multiple-value-bind (result diag)
      (%run-under-dialect :lax "(let ((x 1)) x)")
    (declare (ignore result))
    (is (null (search "ext-bricscad-undocumented" diag))
        "LET must be silent under :lax; got: ~S" diag)))

(test let-warning-fires-under-strict-dialect
  "Under --dialect strict, LET emits the [ext-bricscad-undocumented]
warning — portable AutoLISP has no LET — yet still evaluates."
  (reset-autolisp-symbol-table)
  (multiple-value-bind (result diag)
      (%run-under-dialect :strict "(let ((x 1)) x)")
    (is (eql 1 result) "LET still evaluates under :strict; got: ~S" result)
    (is (search "[ext-bricscad-undocumented]" diag)
        "LET should warn under :strict; got: ~S" diag)))

(test let-warning-fires-under-autocad-dialect
  "Under --dialect autocad-2026, LET warns the same way — AutoCAD has
no LET."
  (reset-autolisp-symbol-table)
  (multiple-value-bind (result diag)
      (%run-under-dialect :autocad-2026 "(let ((x 1)) x)")
    (declare (ignore result))
    (is (search "[ext-bricscad-undocumented]" diag)
        "LET should warn under :autocad-2026; got: ~S" diag)))

(test let-warning-silent-under-bricscad-v25
  "Under --dialect bricscad-v25, LET is native too, so it is silent.

Regression guard: the gate used to be an inline `case' naming only
:bricscad-v26, so v25 warned about a construct its own host provides.
Routing the decision through the catalogue fixed that."
  (reset-autolisp-symbol-table)
  (multiple-value-bind (result diag)
      (%run-under-dialect :bricscad-v25 "(let ((x 1)) x)")
    (is (eql 1 result) "LET still evaluates under :bricscad-v25; got: ~S" result)
    (is (null (search "ext-bricscad-undocumented" diag))
        "LET must be silent under :bricscad-v25; got: ~S" diag)))

;;; --- The portability knowledge base (autolisp-spec ch.25) ----------
;;;
;;; The catalogue is the single source the emitters consult. These
;;; tests pin the query surface itself, so a future static linter can
;;; rely on it without starting a runtime.

(test portability-catalogue-lookup-is-case-insensitive
  "Constructs are looked up by label, case-insensitively — AutoLISP
symbols are case-insensitive, so `let' and `LET' must find one entry."
  (let ((upper (find-portability-construct "LET"))
        (lower (find-portability-construct "let")))
    (is (not (null upper)) "LET must be catalogued")
    (is (eq upper lower) "LET and let must resolve to the same entry")))

(test portability-catalogue-unknown-construct-is-not-silent-business
  "An uncatalogued name has no entry, and is therefore never reported
as silent — the catalogue only speaks about what it knows."
  (is (null (find-portability-construct "CAR")))
  (is (null (portability-construct-silent-p nil :strict))))

(test portability-catalogue-native-and-silent-sets
  "The support decision is data: LET is native to both BricsCAD
versions, silent in the two permissive dialects, and reportable under
strict and AutoCAD."
  (let ((let-entry (find-portability-construct "LET")))
    (is (portability-construct-supported-p let-entry :bricscad-v25))
    (is (portability-construct-supported-p let-entry :bricscad-v26))
    (is (not (portability-construct-supported-p let-entry :autocad-2026)))
    (is (portability-construct-silent-p let-entry :clautolisp))
    (is (portability-construct-silent-p let-entry :lax))
    (is (not (portability-construct-silent-p let-entry :strict)))
    (is (not (portability-construct-silent-p let-entry :autocad-2026)))))

(test portability-catalogue-bare-ampersand-is-native-nowhere
  "The bare `&' rest-separator is native to NO vendor — the harvest
showed BricsCAD rejects it — yet clautolisp accepts it, which is
exactly why it stays silent only under clautolisp and lax."
  (let ((amp (find-portability-construct "&")))
    (is (not (null amp)))
    (is (null (portability-construct-native-in amp)))
    (is (portability-construct-silent-p amp :clautolisp))
    (is (not (portability-construct-silent-p amp :bricscad-v26)))))

(test portability-catalogue-is-enumerable
  "MAP-PORTABILITY-CONSTRUCTS visits every entry — the enumeration a
linter or a report consumes."
  (let ((labels '()))
    (map-portability-constructs
     (lambda (entry) (push (portability-construct-label entry) labels)))
    (dolist (expected '("LET" "SETF" "LET*" "&REST" "&"))
      (is (member expected labels :test #'string=)
          "~A must be enumerated; got ~S" expected labels))))

;;; --- Declined constructs: recognise, explain, still don't define ---

(test declined-setf-explains-itself-and-stays-undefined
  "SETF is catalogued as declined: calling it still raises
:undefined-function, but a note first explains that the omission is
deliberate — BricsCAD's SETF returns a sentinel and does not assign."
  (reset-autolisp-symbol-table)
  (let ((signalled-code nil)
        (captured nil)
        (*error-output* (make-string-output-stream)))
    (handler-case
        (run-autolisp-string
         "(setf foo 42)"
         :dialect (clautolisp.autolisp-reader:find-autolisp-dialect :clautolisp))
      (autolisp-runtime-error (condition)
        (setf signalled-code (autolisp-runtime-error-code condition))))
    (setf captured (get-output-stream-string *error-output*))
    (is (eq :undefined-function signalled-code)
        "SETF must remain undefined; got ~S" signalled-code)
    (is (search "[ext-bricscad-undocumented]" captured)
        "SETF should explain itself; got: ~S" captured)
    (is (search "does NOT assign" captured)
        "the note should say why clautolisp declines it; got: ~S" captured)))

(test declined-let-star-explains-itself-and-stays-undefined
  "LET* likewise — and the note records that BricsCAD has no LET*
either, so it is not a vendor extension anyone is missing."
  (reset-autolisp-symbol-table)
  (let ((signalled-code nil)
        (captured nil)
        (*error-output* (make-string-output-stream)))
    (handler-case
        (run-autolisp-string
         "(let* ((x 1)) x)"
         :dialect (clautolisp.autolisp-reader:find-autolisp-dialect :clautolisp))
      (autolisp-runtime-error (condition)
        (setf signalled-code (autolisp-runtime-error-code condition))))
    (setf captured (get-output-stream-string *error-output*))
    (is (eq :undefined-function signalled-code))
    (is (search "[ext-bricscad-undocumented]" captured)
        "LET* should explain itself; got: ~S" captured)
    (is (search "does not exist on BricsCAD" captured)
        "the note should cite the harvest refutation; got: ~S" captured)))

(test declined-note-is-emitted-under-every-dialect
  "Unlike the advisory warnings, the declined-construct note is NOT
dialect-gated: the error fires everywhere, so the explanation is
useful everywhere. A --dialect bricscad user is the most likely to be
surprised, because on the real engine SETF does exist."
  (dolist (dialect-name '(:strict :autocad-2026 :bricscad-v26 :clautolisp :lax))
    (reset-autolisp-symbol-table)
    (let ((captured nil)
          (*error-output* (make-string-output-stream)))
      (ignore-errors
       (run-autolisp-string
        "(setf foo 42)"
        :dialect (clautolisp.autolisp-reader:find-autolisp-dialect dialect-name)))
      (setf captured (get-output-stream-string *error-output*))
      (is (search "[ext-bricscad-undocumented]" captured)
          "SETF note must appear under ~S; got: ~S" dialect-name captured))))

(test ordinary-undefined-function-gets-no-declined-note
  "The hook must stay off the path of ordinary undefined-function
errors: a name the catalogue does not know produces the error alone."
  (reset-autolisp-symbol-table)
  (let ((signalled-code nil)
        (captured nil)
        (*error-output* (make-string-output-stream)))
    (handler-case
        (run-autolisp-string
         "(no-such-function-anywhere 1)"
         :dialect (clautolisp.autolisp-reader:find-autolisp-dialect :clautolisp))
      (autolisp-runtime-error (condition)
        (setf signalled-code (autolisp-runtime-error-code condition))))
    (setf captured (get-output-stream-string *error-output*))
    (is (eq :undefined-function signalled-code))
    (is (null (search "ext-bricscad-undocumented" captured))
        "an unknown name must not get a portability note; got: ~S" captured)))

(test let-warning-once-per-occurrence
  "autolisp-spec ch.25 once-per-occurrence: the SAME LET re-evaluated in
a loop warns exactly once (dedup key is the binding-list cons identity)."
  (reset-autolisp-symbol-table)
  (multiple-value-bind (result diag)
      (%run-under-dialect :strict "(repeat 3 (let ((x 1)) x))")
    (declare (ignore result))
    (is (= 1 (%count-substrings "[ext-bricscad-undocumented]" diag))
        "Expected exactly one LET warning across 3 iterations; got: ~S" diag)))

(test let-warning-escalation-signals-error
  "autolisp-spec ch.25 escalation knob: with :portability-warning-mode
:error a strict-dialect LET becomes a :non-portable-construct runtime
error instead of an advisory."
  (reset-autolisp-symbol-table)
  (let ((escalating
          (clautolisp.autolisp-reader:make-autolisp-dialect
           :name :strict
           :portability-warning-mode :error))
        (signalled-code nil)
        (*error-output* (make-string-output-stream)))
    (handler-case
        (run-autolisp-string "(let ((x 1)) x)" :dialect escalating)
      (autolisp-runtime-error (condition)
        (setf signalled-code (autolisp-runtime-error-code condition))))
    (is (eq :non-portable-construct signalled-code)
        "Expected :non-portable-construct under escalation; got: ~S"
        signalled-code)))

(test let-star-is-not-a-bricscad-extension
  "The harvest refuted LET* on BricsCAD V26 (\"no function definition
<LET*>\"). clautolisp must NOT provide LET* as a special operator: a
(let* ...) call falls through to ordinary function dispatch and, with
no such function defined, is an undefined-function error — never a
silently-accepted sequential-binding form."
  (reset-autolisp-symbol-table)
  (let ((signalled-code nil)
        (*error-output* (make-string-output-stream)))
    (handler-case
        (run-autolisp-string
         "(let* ((x 1) (y (+ x 1))) y)"
         :dialect (clautolisp.autolisp-reader:find-autolisp-dialect :bricscad-v26))
      (autolisp-runtime-error (condition)
        (setf signalled-code (autolisp-runtime-error-code condition))))
    (is (eq :undefined-function signalled-code)
        "LET* must be undefined, not a special operator; got: ~S"
        signalled-code)))

;;; --- the register of dialect warnings, keyed by [tag] --------------
;;;
;;; pjb's 2026-08-14 ruling: the tag is the stable identifier, the
;;; message is free prose, and a register keyed by tag carries the
;;; detail and the references. These tests guard the two properties
;;; that make the register worth having: it is COMPLETE (every tag a
;;; user can meet is in it) and it is REACHABLE (the emitters format
;;; from it, so the annex cannot drift from what is printed).

(test dialect-warning-register-covers-every-catalogued-construct
  "Every construct in the portability catalogue names a tag that the
register documents. Otherwise a user meets a bracketed identifier that
leads nowhere."
  (is (null (unregistered-construct-tags))
      "Catalogued constructs whose tag is undocumented: ~S"
      (unregistered-construct-tags)))

(test dialect-warning-register-covers-every-closed-code-set
  "The encoding and secureload diagnostics build their bracket from a
code keyword at emission time, so their tags appear NOWHERE as literals
in the sources — grepping cannot enumerate them, and a grep of `[...]'
also picks up struct names and UI decorations that are not tags at all.
This is the exact check instead: add a code without documenting it and
this fails."
  (is (null (unregistered-diagnostic-codes *enc-diagnostic-codes*))
      "Encoding codes with no register entry: ~S"
      (unregistered-diagnostic-codes *enc-diagnostic-codes*))
  (is (null (unregistered-diagnostic-codes *secureload-diagnostic-codes*))
      "Secureload codes with no register entry: ~S"
      (unregistered-diagnostic-codes *secureload-diagnostic-codes*)))

(test dialect-warning-entries-are-complete
  "Every register entry carries what the annex needs. An entry with an
empty explanation is worse than no entry: it looks documented."
  (map-dialect-warnings
   (lambda (entry)
     (let ((tag (dialect-warning-tag entry)))
       (is (plusp (length (dialect-warning-title entry)))
           "~A has no title" tag)
       (is (plusp (length (dialect-warning-example entry)))
           "~A has no example line" tag)
       (is (plusp (length (dialect-warning-dialects entry)))
           "~A does not say how the dialects diverge" tag)
       (is (plusp (length (dialect-warning-rationale entry)))
           "~A does not say why it matters" tag)
       (is (consp (dialect-warning-references entry))
           "~A has no references" tag)
       ;; The example must actually show the tag it documents — an
       ;; example copied from a neighbouring entry is a real mistake
       ;; and an easy one.
       (is (search (format nil "[~A]" tag) (dialect-warning-example entry))
           "~A's example line does not show its own tag: ~S"
           tag (dialect-warning-example entry))))))

(test dialect-warning-message-comes-from-the-register
  "The emitted line is formatted from the register entry, so improving
the wording in one place changes both the diagnostic and the annex.
Checked on the real emission path rather than on the formatter."
  (reset-autolisp-symbol-table)
  (multiple-value-bind (result diag)
      (%run-under-dialect :strict "(defun compute-area (a &rest r) r)")
    (declare (ignore result))
    ;; the tag, the function concerned, and the register's own wording
    (is (search "[lambda-list-extension]" diag)
        "Expected the tag; got: ~S" diag)
    (is (search "in COMPUTE-AREA" diag)
        "Expected the function name (pjb's point 2); got: ~S" diag)
    (is (search "rest parameter not portable to strict" diag)
        "Expected the register's wording; got: ~S" diag)
    ;; one line, per pjb's point 3
    (is (zerop (count #\Newline (string-trim '(#\Newline #\Space) diag)))
        "The diagnostic must stand on a single line; got: ~S" diag)))

(test dialect-warning-reports-the-defined-function-not-the-caller
  "DEFUN's warning names the function being DEFINED. It cannot come off
the call stack — the body is not running yet — so the definer passes it
explicitly. Guard against a refactor that drops the argument and
silently falls back to the enclosing frame."
  (reset-autolisp-symbol-table)
  ;; A nested DEFUN, so there IS an enclosing frame to be confused with:
  ;; OUTER is on the call stack when INNER's lambda list is checked.
  ;; DEFUN is a special operator, so this needs no builtins.
  (multiple-value-bind (result diag)
      (%run-under-dialect :strict
                          "(defun outer () (defun inner (a &rest r) r))
                           (outer)")
    (declare (ignore result))
    (is (search "in INNER" diag)
        "Expected the defined function INNER, not the caller OUTER; got: ~S"
        diag)
    (is (null (search "in OUTER" diag))
        "The enclosing frame must not win over the defined name; got: ~S"
        diag)))

(test dialect-warning-annex-renders-every-entry
  "The manual annex is GENERATED from the register, so the generator
must survive every entry — including the code families, whose MESSAGE
is deliberately empty because their text varies by call site."
  (let ((annex (with-output-to-string (out)
                 (render-dialect-warnings-annex out))))
    (is (plusp (length annex)) "The annex came out empty")
    (dolist (tag (dialect-warning-tags))
      (is (search (format nil "=[~A]=" tag) annex)
          "~A is missing from the generated annex" tag))))
