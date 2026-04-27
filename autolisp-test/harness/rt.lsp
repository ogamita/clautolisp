;;;; autolisp-test/harness/rt.lsp
;;;;
;;;; Registration core for the AutoLISP / Visual LISP conformance test
;;;; suite. Pure AutoLISP. Does not depend on Common Lisp, on any
;;;; particular host (AutoCAD, BricsCAD, clautolisp), or on Express
;;;; Tools, DOSLib, or any other extension library.
;;;;
;;;; The runtime model:
;;;;
;;;;   - Tests are appended to a single registry list `*autolisp-tests*'.
;;;;   - Each entry is a property-list-like alist with the metadata
;;;;     required to: filter by profile and tags, evaluate the test
;;;;     form, classify the result, and report it.
;;;;
;;;; Five user-facing registration helpers, all regular AutoLISP
;;;; functions (no defmacro is required by the spec):
;;;;
;;;;   (deftest        name meta form expected-value)
;;;;     The test is PASS iff (equal expected-value evaluated-value).
;;;;
;;;;   (deftest-eq     name meta form expected-value)
;;;;     The test is PASS iff (eq expected-value evaluated-value).
;;;;
;;;;   (deftest-pred   name meta form predicate-form)
;;;;     The test is PASS iff predicate-form evaluates to a non-nil
;;;;     value when *result* is bound to the value of form.
;;;;
;;;;   (deftest-error  name meta form expected-error-code)
;;;;     The test is PASS iff form signals an AutoLISP-visible error
;;;;     and the catch-all message contains the expected indication.
;;;;     Implementations without `vl-catch-all-apply' SKIP this case.
;;;;
;;;;   (deftest-skip   name meta form reason)
;;;;     The test is registered but is reported as SKIP / DEFERRED.
;;;;     Used for entries that depend on prerequisites the harness
;;;;     does not yet install (mock host, fixtures, vendor probes).
;;;;
;;;; META is an alist of `(KEY . VALUE)' pairs. The recognised keys are:
;;;;
;;;;   OPERATOR        - string, the spec entry name under test
;;;;   AREA            - string, the language area (e.g. "string")
;;;;   PROFILE         - one of STRICT AUTOCAD BRICSCAD
;;;;   PLATFORM-TAGS   - list of symbols, subset of (WINDOWS LINUX MACOS)
;;;;   RUNTIME-TAGS    - list of symbols (COM VLA VLAX VLAX-CURVE VLR
;;;;                     ARX BRX OBJECTDBX DCL GRAPHICS USER-INPUT
;;;;                     EXPRESS-TOOLS DOSLIB)
;;;;   AUTHORITY       - DOCUMENTED TESTED-AUTOCAD TESTED-BRICSCAD
;;;;                     TESTED-BOTH INFERRED
;;;;   TAGS            - free-form list of symbols for grouping
;;;;
;;;; The test FORM is left unevaluated by quoting at the call site.

;;; --- registry ------------------------------------------------------

(setq *autolisp-tests* nil)

(defun autolisp-test-registry-clear ()
  (setq *autolisp-tests* nil)
  T)

(defun autolisp-test-registry-count ()
  (length *autolisp-tests*))

(defun autolisp-test-registry-list ()
  (reverse *autolisp-tests*))

;;; --- registration helpers ------------------------------------------

(defun autolisp-test--make-entry (name meta form assertion-kind payload)
  (list (cons 'name name)
        (cons 'meta meta)
        (cons 'form form)
        (cons 'assertion-kind assertion-kind)
        (cons 'assertion-payload payload)))

(defun autolisp-test-register (entry)
  (setq *autolisp-tests* (cons entry *autolisp-tests*))
  (cdr (assoc 'name entry)))

(defun deftest (name meta form expected-value)
  (autolisp-test-register
   (autolisp-test--make-entry name meta form 'value expected-value)))

(defun deftest-eq (name meta form expected-value)
  (autolisp-test-register
   (autolisp-test--make-entry name meta form 'value-eq expected-value)))

(defun deftest-pred (name meta form predicate-form)
  (autolisp-test-register
   (autolisp-test--make-entry name meta form 'predicate predicate-form)))

(defun deftest-error (name meta form expected-error-code)
  (autolisp-test-register
   (autolisp-test--make-entry name meta form 'error expected-error-code)))

(defun deftest-skip (name meta form reason)
  (autolisp-test-register
   (autolisp-test--make-entry name meta form 'skip reason)))

;;; --- metadata accessors --------------------------------------------

(defun autolisp-test-entry-name (entry)            (cdr (assoc 'name entry)))
(defun autolisp-test-entry-meta (entry)            (cdr (assoc 'meta entry)))
(defun autolisp-test-entry-form (entry)            (cdr (assoc 'form entry)))
(defun autolisp-test-entry-assertion-kind (entry)  (cdr (assoc 'assertion-kind entry)))
(defun autolisp-test-entry-assertion-payload (entry) (cdr (assoc 'assertion-payload entry)))

(defun autolisp-test-meta-get (meta key default)
  (cond ((null meta) default)
        ((assoc key meta) (cdr (assoc key meta)))
        (T default)))

(defun autolisp-test-entry-operator (entry)
  (autolisp-test-meta-get (autolisp-test-entry-meta entry) 'operator "?"))

(defun autolisp-test-entry-area (entry)
  (autolisp-test-meta-get (autolisp-test-entry-meta entry) 'area "?"))

(defun autolisp-test-entry-profile (entry)
  (autolisp-test-meta-get (autolisp-test-entry-meta entry) 'profile 'strict))

(defun autolisp-test-entry-platform-tags (entry)
  (autolisp-test-meta-get (autolisp-test-entry-meta entry) 'platform-tags nil))

(defun autolisp-test-entry-runtime-tags (entry)
  (autolisp-test-meta-get (autolisp-test-entry-meta entry) 'runtime-tags nil))

(defun autolisp-test-entry-authority (entry)
  (autolisp-test-meta-get (autolisp-test-entry-meta entry) 'authority 'documented))

(defun autolisp-test-entry-tags (entry)
  (autolisp-test-meta-get (autolisp-test-entry-meta entry) 'tags nil))

;;; --- error capture -------------------------------------------------
;;;
;;; `vl-catch-all-apply' is part of every supported target (AutoCAD,
;;; BricsCAD, clautolisp). If it is missing, error tests are reported
;;; SKIP rather than failing the harness.
;;;
;;; *autolisp-test-debug-p* (defaults to nil) is a verbosity flag,
;;; not an error-propagation switch. When non-nil:
;;;
;;;   - the harness prints `[autolisp-test] >>> NAME  form: FORM'
;;;     before every test so the most recent line identifies the
;;;     test in flight,
;;;   - on every test that raises an error (whether expected or not),
;;;     the harness prints the captured AutoLISP backtrace inline.
;;;
;;; Errors are still caught and reported as test FAILs. The run
;;; continues to completion and produces a report directory.

(if (not (boundp '*autolisp-test-debug-p*))
    (setq *autolisp-test-debug-p* nil))

(defun autolisp-test--symbol-bound-to-subr-p (name / fn-type)
  "True iff NAME is bound to a builtin / user / external subr in
the current environment. Avoids evaluating NAME when it is unbound."
  (cond ((not (boundp name)) nil)
        (T (setq fn-type (type (eval name)))
           (or (eq fn-type 'subr)
               (eq fn-type 'usubr)
               (eq fn-type 'exsubr)
               (eq fn-type 'subrf)))))

(defun autolisp-test--catch-all-available-p ()
  (autolisp-test--symbol-bound-to-subr-p 'vl-catch-all-apply))

(defun autolisp-test--coerce-to-string (value)
  "Return a printable string representation of VALUE. Defensive
against nil and unexpected types so the harness never crashes when
formatting a detail message about a faulty test result."
  (cond ((null value) "NIL")
        ((eq (type value) 'str) value)
        ((eq (type value) 'sym) (vl-symbol-name value))
        ((eq (type value) 'int) (itoa value))
        ((eq (type value) 'real) (rtos value 2 6))
        ((autolisp-test--symbol-bound-to-subr-p 'vl-prin1-to-string)
         (vl-prin1-to-string value))
        (T "<unprintable>")))

(defun autolisp-test--safe-strcat (parts / acc)
  "Concatenate every element of PARTS, coercing each through
autolisp-test--coerce-to-string. Never raises."
  (setq acc "")
  (foreach part parts
    (setq acc (strcat acc (autolisp-test--coerce-to-string part))))
  acc)

(defun autolisp-test--catch-all-error-stack (catcher / fn-bound stack-catch)
  "Return the AutoLISP call stack stored inside the catch-all error
CATCHER, or NIL if the host implementation does not expose one.
Calls vl-catch-all-error-stack only when it is bound, since this is
a clautolisp extension and AutoCAD / BricsCAD do not provide it."
  (cond
    ((not (autolisp-test--symbol-bound-to-subr-p 'vl-catch-all-error-stack))
     nil)
    (T
     (setq stack-catch
           (vl-catch-all-apply
            '(lambda (c) (vl-catch-all-error-stack c))
            (list catcher)))
     (cond ((vl-catch-all-error-p stack-catch) nil)
           (T stack-catch)))))

(defun autolisp-test--render-stack (stack / out frame kind payload)
  "Format STACK (a list of (KIND . PAYLOAD) frames, most recent
first) as a multi-line string. Returns the empty string when STACK
is NIL so the harness can always concatenate the result."
  (cond ((null stack) "")
        (T (setq out "")
           (foreach frame stack
             (setq kind (car frame))
             (setq payload (cdr frame))
             (cond ((eq kind 'subr)
                    (setq out (autolisp-test--safe-strcat
                               (list out
                                     "    in SUBR "
                                     (car payload)
                                     ": "
                                     (cdr payload)
                                     "\n"))))
                   ((eq kind 'usubr)
                    (setq out (autolisp-test--safe-strcat
                               (list out
                                     "    in USUBR "
                                     (car payload)
                                     ": "
                                     (cdr payload)
                                     "\n"))))
                   ((eq kind 'eval)
                    (setq out (autolisp-test--safe-strcat
                               (list out
                                     "    eval: "
                                     payload
                                     "\n"))))
                   (T
                    (setq out (autolisp-test--safe-strcat
                               (list out
                                     "    "
                                     kind
                                     ": "
                                     payload
                                     "\n"))))))
           out)))

(defun autolisp-test--evaluate-form (form / catcher message stack)
  "Evaluate FORM. Return (KIND PAYLOAD STACK) where KIND is one of
'value or 'error. On 'value, PAYLOAD is the evaluated value and
STACK is nil. On 'error, PAYLOAD is a printable message string and
STACK is the call stack snapshot captured at error time, or nil if
the host does not expose one.

The catch-all guard is always engaged when vl-catch-all-apply is
available, irrespective of *autolisp-test-debug-p*. Debug mode is a
verbosity flag, not an error-propagation switch: it affects what the
harness prints around each test, not whether errors are caught.
This lets the run complete in every mode and produces a report
directory even when many tests raise."
  (cond
    ((autolisp-test--catch-all-available-p)
     (setq catcher
           (vl-catch-all-apply
            '(lambda (f) (eval f))
            (list form)))
     (cond ((vl-catch-all-error-p catcher)
            (setq message (autolisp-test--coerce-to-string
                           (vl-catch-all-error-message catcher)))
            (setq stack (autolisp-test--catch-all-error-stack catcher))
            (list 'error message stack))
           (T (list 'value catcher nil))))
    (T
     ;; vl-catch-all-apply absent -- evaluate without protection.
     ;; This branch only runs on the most minimal AutoLISP profiles
     ;; that we already mark out via deftest-error skips.
     (list 'value (eval form) nil))))

(defun autolisp-test--evaluate-predicate (predicate-form / catcher)
  "Evaluate PREDICATE-FORM (which may reference *result*). Return
(KIND VALUE) with the same conventions as autolisp-test--evaluate-form."
  (autolisp-test--evaluate-form predicate-form))

;;; --- result classification -----------------------------------------

(defun autolisp-test--equal-p (a b) (equal a b))

(defun autolisp-test--eq-p (a b) (eq a b))

(defun autolisp-test--message-mentions-p (message indicator / needle)
  "True iff INDICATOR (string or symbol) appears in MESSAGE (string).
Conservative: when INDICATOR is a symbol we accept its symbol-name
substring. When INDICATOR is the symbol ANY we accept any error."
  (cond ((eq indicator 'any) T)
        ((or (null message) (not (eq (type message) 'str))) nil)
        (T (setq needle
                 (cond ((eq (type indicator) 'str) indicator)
                       ((eq (type indicator) 'sym) (vl-symbol-name indicator))
                       (T (autolisp-test--coerce-to-string indicator))))
           (if (vl-string-search (strcase needle) (strcase message))
               T
               nil))))

(defun autolisp-test--classify-pred-result (pred-result status-on-truthy)
  "Helper: PRED-RESULT is the (KIND VALUE) shape returned by
autolisp-test--evaluate-predicate. STATUS-ON-TRUTHY is the symbol
to assign when the predicate evaluates to a non-nil value (typically
'pass)."
  (cond ((eq (car pred-result) 'error)
         (list 'fail
               (autolisp-test--safe-strcat
                (list "predicate raised error: " (cadr pred-result)))))
        ((null (cadr pred-result))
         (list 'fail "predicate returned nil"))
        (T (list status-on-truthy "predicate"))))

(defun autolisp-test--error-detail (raw stack prefix)
  "Build a human-readable detail string for a test that raised an
unexpected error. Includes the rendered call stack when STACK is
non-nil."
  (autolisp-test--safe-strcat
   (list prefix raw "\n" (autolisp-test--render-stack stack))))

(defun autolisp-test--classify-body (entry / kind eval-result raw stack status
                                              detail payload assertion
                                              pred-result)
  "Worker for autolisp-test-classify. Always returns the result alist;
never raises."
  (setq assertion (autolisp-test-entry-assertion-kind entry))
  (setq payload (autolisp-test-entry-assertion-payload entry))
  (cond
    ((eq assertion 'skip)
     (list (cons 'name (autolisp-test-entry-name entry))
           (cons 'status 'skip)
           (cons 'detail (autolisp-test--coerce-to-string payload))
           (cons 'evaluated nil)
           (cons 'expected nil)
           (cons 'stack nil)
           (cons 'assertion 'skip)))
    ((and (eq assertion 'error)
          (not (autolisp-test--catch-all-available-p)))
     (list (cons 'name (autolisp-test-entry-name entry))
           (cons 'status 'skip)
           (cons 'detail "vl-catch-all-apply not available")
           (cons 'evaluated nil)
           (cons 'expected payload)
           (cons 'stack nil)
           (cons 'assertion 'error)))
    (T
     (setq eval-result (autolisp-test--evaluate-form
                        (autolisp-test-entry-form entry)))
     (setq kind (car eval-result))
     (setq raw  (cadr eval-result))
     (setq stack (caddr eval-result))
     (setq status 'fail)
     (setq detail "unclassified")
     (cond
       ((eq assertion 'value)
        (cond ((eq kind 'error)
               (setq detail
                     (autolisp-test--error-detail
                      raw stack "unexpected error: ")))
              ((autolisp-test--equal-p raw payload)
               (setq status 'pass) (setq detail "equal"))
              (T (setq detail "value mismatch (equal)"))))
       ((eq assertion 'value-eq)
        (cond ((eq kind 'error)
               (setq detail
                     (autolisp-test--error-detail
                      raw stack "unexpected error: ")))
              ((autolisp-test--eq-p raw payload)
               (setq status 'pass) (setq detail "eq"))
              (T (setq detail "value mismatch (eq)"))))
       ((eq assertion 'predicate)
        (cond ((eq kind 'error)
               (setq detail
                     (autolisp-test--error-detail
                      raw stack "unexpected error: ")))
              (T (setq *result* raw)
                 (setq pred-result
                       (autolisp-test--evaluate-predicate payload))
                 (setq pred-result
                       (autolisp-test--classify-pred-result
                        pred-result 'pass))
                 (setq status (car pred-result))
                 (setq detail (cadr pred-result)))))
       ((eq assertion 'error)
        (cond ((eq kind 'error)
               (cond ((autolisp-test--message-mentions-p raw payload)
                      (setq status 'pass)
                      (setq detail (autolisp-test--safe-strcat
                                    (list "error: " raw))))
                     (T (setq detail
                              (autolisp-test--error-detail
                               raw stack
                               (autolisp-test--safe-strcat
                                (list "error message did not mention "
                                      payload ": ")))))))
              (T (setq detail "expected error but got value"))))
       (T (setq detail (autolisp-test--safe-strcat
                        (list "unknown assertion kind: " assertion)))))
     (list (cons 'name (autolisp-test-entry-name entry))
           (cons 'status status)
           (cons 'detail detail)
           (cons 'evaluated raw)
           (cons 'expected payload)
           (cons 'stack stack)
           (cons 'assertion assertion)))))

(defun autolisp-test-classify (entry / catcher classified)
  "Evaluate ENTRY's form and classify the outcome.

A bug inside the worker (a malformed test entry, a defensive
mismatch, or any other unexpected harness behaviour) is converted
into an internal-harness FAIL rather than escaping to the caller.
The whole run therefore continues even when one test entry exposes
a harness flaw, and CI captures the harness flaw in the report.

The catch-all guard is always engaged: debug mode is a verbosity
flag, not an error-propagation switch."
  (cond
    ((autolisp-test--catch-all-available-p)
     (setq catcher
           (vl-catch-all-apply
            'autolisp-test--classify-body
            (list entry)))
     (cond ((vl-catch-all-error-p catcher)
            (list (cons 'name (autolisp-test-entry-name entry))
                  (cons 'status 'fail)
                  (cons 'detail
                        (autolisp-test--error-detail
                         (vl-catch-all-error-message catcher)
                         (autolisp-test--catch-all-error-stack catcher)
                         "internal-harness-error: "))
                  (cons 'evaluated nil)
                  (cons 'expected nil)
                  (cons 'stack
                        (autolisp-test--catch-all-error-stack catcher))
                  (cons 'assertion
                        (autolisp-test-entry-assertion-kind entry))))
           (T catcher)))
    (T
     (autolisp-test--classify-body entry))))

;;; --- selection helpers ---------------------------------------------

(defun autolisp-test--every-in (subset superset)
  "True iff every element of SUBSET (list of symbols) is also in
SUPERSET (list of symbols). Returns T on empty SUBSET."
  (cond ((null subset) T)
        ((member (car subset) superset)
         (autolisp-test--every-in (cdr subset) superset))
        (T nil)))

(defun autolisp-test-applicable-p (entry descriptor / req-platform req-runtime
                                                       det-platform det-runtime)
  "True iff ENTRY's required platform tags are satisfied by DESCRIPTOR's
detected platform list AND its required runtime tags by the detected
runtime list."
  (setq req-platform (autolisp-test-entry-platform-tags entry))
  (setq req-runtime  (autolisp-test-entry-runtime-tags entry))
  (setq det-platform (cdr (assoc 'platforms descriptor)))
  (setq det-runtime  (cdr (assoc 'runtimes descriptor)))
  (and (autolisp-test--every-in req-platform det-platform)
       (autolisp-test--every-in req-runtime  det-runtime)))

(defun autolisp-test-select-by-profile (profile entries / acc)
  (setq acc nil)
  (foreach entry entries
    (if (eq profile (autolisp-test-entry-profile entry))
        (setq acc (cons entry acc))))
  (reverse acc))

(defun autolisp-test-select-by-area (area entries / acc)
  (setq acc nil)
  (foreach entry entries
    (if (equal area (autolisp-test-entry-area entry))
        (setq acc (cons entry acc))))
  (reverse acc))

(defun autolisp-test-select-by-tag (tag entries / acc)
  (setq acc nil)
  (foreach entry entries
    (if (or (member tag (autolisp-test-entry-platform-tags entry))
            (member tag (autolisp-test-entry-runtime-tags entry))
            (member tag (autolisp-test-entry-tags entry)))
        (setq acc (cons entry acc))))
  (reverse acc))

(defun autolisp-test-select-by-name (name entries / acc)
  (setq acc nil)
  (foreach entry entries
    (if (equal name (autolisp-test-entry-name entry))
        (setq acc (cons entry acc))))
  (reverse acc))

(princ "[autolisp-test] rt.lsp loaded.\n")
(princ)
