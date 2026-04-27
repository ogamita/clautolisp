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

(defun autolisp-test--catch-all-available-p ()
  (and (= 'subr (type 'vl-catch-all-apply))
       T))

(defun autolisp-test--evaluate-form (form / catcher result)
  "Evaluate FORM. Return (KIND VALUE) where KIND is one of
'value or 'error. On error, VALUE is a printable message."
  (if (autolisp-test--catch-all-available-p)
      (progn
        (setq catcher
              (vl-catch-all-apply
               '(lambda (f) (eval f))
               (list form)))
        (if (vl-catch-all-error-p catcher)
            (list 'error (vl-catch-all-error-message catcher))
            (list 'value catcher)))
    ;; Without catch-all: evaluate directly. Errors will abort.
    (progn
      (setq result (eval form))
      (list 'value result))))

;;; --- result classification -----------------------------------------

(defun autolisp-test--equal-p (a b) (equal a b))

(defun autolisp-test--eq-p (a b) (eq a b))

(defun autolisp-test--message-mentions-p (message indicator)
  "True iff INDICATOR (string or symbol) appears in MESSAGE (string).
Conservative: when INDICATOR is a symbol we accept its symbol-name
substring. When INDICATOR is the symbol ANY we accept any error."
  (cond ((eq indicator 'any) T)
        ((null message) nil)
        (T (let ((needle
                  (cond ((eq (type indicator) 'str) indicator)
                        (T (vl-symbol-name indicator)))))
             (if (vl-string-search (strcase needle) (strcase message))
                 T
                 nil)))))

(defun autolisp-test-classify (entry / kind eval-result raw status detail
                                       payload assertion)
  "Evaluate ENTRY's form and classify the outcome.
Return an alist with keys NAME, STATUS, DETAIL, EVALUATED, EXPECTED,
ASSERTION."
  (setq assertion (autolisp-test-entry-assertion-kind entry))
  (setq payload (autolisp-test-entry-assertion-payload entry))
  (cond
    ((eq assertion 'skip)
     (list (cons 'name (autolisp-test-entry-name entry))
           (cons 'status 'skip)
           (cons 'detail payload)
           (cons 'evaluated nil)
           (cons 'expected nil)
           (cons 'assertion 'skip)))
    ((and (eq assertion 'error)
          (not (autolisp-test--catch-all-available-p)))
     (list (cons 'name (autolisp-test-entry-name entry))
           (cons 'status 'skip)
           (cons 'detail "vl-catch-all-apply not available")
           (cons 'evaluated nil)
           (cons 'expected payload)
           (cons 'assertion 'error)))
    (T
     (setq eval-result (autolisp-test--evaluate-form
                        (autolisp-test-entry-form entry)))
     (setq kind (car eval-result))
     (setq raw  (cadr eval-result))
     (cond
       ((eq assertion 'value)
        (cond ((eq kind 'error)
               (setq status 'fail) (setq detail (strcat "unexpected error: " raw)))
              ((autolisp-test--equal-p raw payload)
               (setq status 'pass) (setq detail "equal"))
              (T
               (setq status 'fail) (setq detail "value mismatch (equal)"))))
       ((eq assertion 'value-eq)
        (cond ((eq kind 'error)
               (setq status 'fail) (setq detail (strcat "unexpected error: " raw)))
              ((autolisp-test--eq-p raw payload)
               (setq status 'pass) (setq detail "eq"))
              (T
               (setq status 'fail) (setq detail "value mismatch (eq)"))))
       ((eq assertion 'predicate)
        (cond ((eq kind 'error)
               (setq status 'fail) (setq detail (strcat "unexpected error: " raw)))
              (T
               (setq *result* raw)
               (setq detail "predicate")
               (if (eval payload)
                   (setq status 'pass)
                   (setq status 'fail)))))
       ((eq assertion 'error)
        (cond ((eq kind 'error)
               (if (autolisp-test--message-mentions-p raw payload)
                   (progn (setq status 'pass)
                          (setq detail (strcat "error: " raw)))
                   (progn (setq status 'fail)
                          (setq detail (strcat "error message did not mention "
                                               (if (eq (type payload) 'str)
                                                   payload
                                                 (vl-symbol-name payload))
                                               ": " raw)))))
              (T
               (setq status 'fail)
               (setq detail "expected error but got value"))))
       (T
        (setq status 'fail)
        (setq detail (strcat "unknown assertion kind"))))
     (list (cons 'name (autolisp-test-entry-name entry))
           (cons 'status status)
           (cons 'detail detail)
           (cons 'evaluated raw)
           (cons 'expected payload)
           (cons 'assertion assertion)))))

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
