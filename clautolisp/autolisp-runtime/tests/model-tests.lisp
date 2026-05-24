(in-package #:clautolisp.autolisp-runtime.tests)

(in-suite autolisp-runtime-suite)

(test interned-symbols-are-distinct-from-cl-symbols
  (reset-autolisp-symbol-table)
  (let ((symbol (intern-autolisp-symbol "FOO")))
    (is (typep symbol 'autolisp-symbol))
    (is (string= "FOO" (autolisp-symbol-name symbol)))
    (is (not (symbolp symbol)))))

(test reader-string-maps-to-runtime-string-wrapper
  (let* ((reader-object (first (read-result-objects
                                (read-forms-from-string "\"abc\""))))
         (runtime-value (reader-object->runtime-value reader-object)))
    (is (typep runtime-value 'autolisp-string))
    (is (string= "abc" (autolisp-string-value runtime-value)))))

(test reader-list-maps-to-runtime-values
  (reset-autolisp-symbol-table)
  (let ((values (read-runtime-from-string "(foo 17 3.5 \"x\")")))
    (is (= 1 (length values)))
    (is (runtime-value-p (first values)))
    (is (typep (first (first values)) 'autolisp-symbol))
    (is (= 17 (second (first values))))
    (is (typep (third (first values)) 'double-float))
    (is (typep (fourth (first values)) 'autolisp-string))))

(test reader-quote-maps-to-runtime-quote-list
  (reset-autolisp-symbol-table)
  (let* ((values (read-runtime-from-string "'x"))
         (form (first values)))
    (is (consp form))
    (is (typep (first form) 'autolisp-symbol))
    (is (string= "QUOTE" (autolisp-symbol-name (first form))))
    (is (typep (second form) 'autolisp-symbol))
    (is (string= "X" (autolisp-symbol-name (second form))))))

(test type-and-basic-predicates
  (reset-autolisp-symbol-table)
  (let* ((symbol (intern-autolisp-symbol "FOO"))
         (string (first (read-runtime-from-string "\"x\"")))
         (list (first (read-runtime-from-string "(1 2)"))))
    (is (null (autolisp-type nil)))
    (is (string= "INT" (autolisp-symbol-name (autolisp-type 1))))
    (is (string= "REAL" (autolisp-symbol-name (autolisp-type 1.5d0))))
    (is (string= "STR" (autolisp-symbol-name (autolisp-type string))))
    (is (string= "SYM" (autolisp-symbol-name (autolisp-type symbol))))
    (is (string= "LIST" (autolisp-symbol-name (autolisp-type list))))
    (is (string= "T" (autolisp-symbol-name (autolisp-null nil))))
    (is (null (autolisp-null 1)))
    (is (string= "T" (autolisp-symbol-name (autolisp-not nil))))
    (is (string= "T" (autolisp-symbol-name (autolisp-listp nil))))
    (is (string= "T" (autolisp-symbol-name (autolisp-listp list))))
    (is (null (autolisp-listp 42)))
    (is (string= "T" (autolisp-symbol-name (autolisp-atom nil))))
    (is (string= "T" (autolisp-symbol-name (autolisp-atom 42))))
    (is (null (autolisp-atom list)))))

(test visual-lisp-symbol-helpers
  (reset-autolisp-symbol-table)
  (let ((symbol (intern-autolisp-symbol "FOO")))
    (is (string= "T" (autolisp-symbol-name (autolisp-vl-symbolp symbol))))
    (is (null (autolisp-vl-symbolp nil)))
    (is (string= "FOO"
                 (autolisp-string-value (autolisp-vl-symbol-name symbol))))
    (is (null (autolisp-vl-symbol-value symbol)))
    (is (not (autolisp-symbol-value-bound-p symbol)))
    (is (not (autolisp-symbol-function-bound-p symbol)))))

(test autolisp-boundp-semantics
  (reset-autolisp-symbol-table)
  (let ((fresh (intern-autolisp-symbol "FRESH"))
        (nil-bound (intern-autolisp-symbol "NIL-BOUND"))
        (value-bound (intern-autolisp-symbol "VALUE-BOUND")))
    (set-variable nil-bound nil)
    (set-variable value-bound 99)
    (is (null (autolisp-boundp fresh)))
    (is (autolisp-symbol-value-bound-p fresh))
    (is (null (autolisp-symbol-value fresh)))
    (is (null (autolisp-boundp nil-bound)))
    (is (autolisp-symbol-value-bound-p nil-bound))
    (is (null (autolisp-symbol-value nil-bound)))
    (is (string= "T" (autolisp-symbol-name (autolisp-boundp value-bound))))))

(test symbol-bindings-live-in-namespaces-not-symbols
  (reset-autolisp-symbol-table)
  (let* ((symbol (intern-autolisp-symbol "FOO"))
         (first-namespace (make-document-namespace :name "DOC-1"))
         (second-namespace (make-document-namespace :name "DOC-2"))
         (first-context (make-evaluation-context
                         :session (make-runtime-session :current-document first-namespace)
                         :current-document first-namespace
                         :current-namespace first-namespace))
         (second-context (make-evaluation-context
                          :session (make-runtime-session :current-document second-namespace)
                          :current-document second-namespace
                          :current-namespace second-namespace)))
    (set-variable symbol 11 first-context)
    (set-variable symbol 22 second-context)
    (multiple-value-bind (value boundp origin) (lookup-variable symbol first-context)
      (declare (ignore origin))
      (is (not (null boundp)))
      (is (= 11 value)))
    (multiple-value-bind (value boundp origin) (lookup-variable symbol second-context)
      (declare (ignore origin))
      (is (not (null boundp)))
      (is (= 22 value)))
    (is (= 11 (value-cell-value (namespace-value-cell first-namespace symbol :createp nil))))
    (is (= 22 (value-cell-value (namespace-value-cell second-namespace symbol :createp nil))))))

(test dynamic-bindings-shadow-namespace-values
  (reset-autolisp-symbol-table)
  (let* ((symbol (intern-autolisp-symbol "FOO"))
         (context (default-evaluation-context)))
    (set-variable symbol 10 context)
    (is (= 10 (autolisp-symbol-value symbol)))
    (push-dynamic-frame context)
    (bind-dynamic-variable symbol 99 context)
    (multiple-value-bind (value boundp origin) (lookup-variable symbol context)
      (is (not (null boundp)))
      (is (= 99 value))
      (is (eq :dynamic origin)))
    (set-variable symbol 100 context)
    (is (= 100 (autolisp-symbol-value symbol)))
    (pop-dynamic-frame context)
    (multiple-value-bind (value boundp origin) (lookup-variable symbol context)
      (is (not (null boundp)))
      (is (= 10 value))
      (is (eq :namespace origin)))))

(test function-bindings-live-in-current-namespace
  (reset-autolisp-symbol-table)
  (let* ((symbol (intern-autolisp-symbol "FN"))
         (document (make-document-namespace :name "FUNCTION-DOC"))
         (context (make-evaluation-context
                   :session (make-runtime-session :current-document document)
                   :current-document document
                   :current-namespace document))
         ;; Lisp-1: lookup-function only surfaces the binding when its
         ;; value is a callable (subr / usubr). Wrap the raw CL lambda
         ;; in a SUBR so the test exercises the call-position path.
         (function (make-autolisp-subr "FN" (lambda (x) x))))
    (set-function symbol function context)
    (multiple-value-bind (binding boundp origin) (lookup-function symbol context)
      (is (not (null boundp)))
      (is (eq function binding))
      (is (eq :namespace origin)))
    (is (eq function
            (function-cell-function
             (namespace-function-cell document symbol :createp nil))))))

(test current-evaluation-context-follows-active-call-context
  (reset-autolisp-symbol-table)
  (let* ((document (make-document-namespace :name "CTX-DOC"))
         (context (make-evaluation-context
                   :session (make-runtime-session :current-document document)
                   :current-document document
                   :current-namespace document))
         (function (make-autolisp-subr
                    "WHOAMI"
                    (lambda ()
                      (current-evaluation-context))))
         (symbol (intern-autolisp-symbol "WHOAMI")))
    (set-function symbol function context)
    (is (eq context (autolisp-eval (list symbol) context)))))

(test evaluation-context-carries-current-document-and-namespace
  (let* ((document (make-document-namespace :name "DRAWING-A"))
         (context (make-evaluation-context
                   :session (make-runtime-session :current-document document)
                   :current-document document
                   :current-namespace document)))
    (is (string= "DRAWING-A"
                 (document-namespace-name
                  (evaluation-context-current-document context))))
    (is (eq (evaluation-context-current-document context)
            (evaluation-context-current-namespace context)))
    (is (eq document
            (runtime-session-current-document
             (evaluation-context-session context))))))

(test evaluation-context-defaults-follow-host-entry-semantics
  (let* ((document (make-document-namespace :name "DRAWING-B"))
         (session (make-runtime-session :current-document document))
         (context (make-evaluation-context :session session)))
    (is (eq document (evaluation-context-current-document context)))
    (is (eq document (evaluation-context-current-namespace context)))
    (is (eq document (runtime-session-current-document session)))))

(test enter-document-context-can-select-document-and-namespace
  (let* ((document (make-document-namespace :name "DRAWING-C"))
         (namespace (make-separate-vlx-namespace :name "APP-C"))
         (session (make-runtime-session))
         (context (enter-document-context session document :namespace namespace)))
    (is (eq document (runtime-session-current-document session)))
    (is (eq document (evaluation-context-current-document context)))
    (is (eq namespace (evaluation-context-current-namespace context)))
    (is (string= "APP-C"
                 (separate-vlx-namespace-name
                 (evaluation-context-current-namespace context))))
    (is (null (evaluation-context-dynamic-frame context)))))

(test runtime-session-registers-and-finds-documents
  (let* ((document-a (make-document-namespace :name "DRAWING-A"))
         (document-b (make-document-namespace :name "DRAWING-B"))
         (session (make-runtime-session :current-document document-a)))
    (is (eq document-a
            (find-runtime-session-document session "DRAWING-A")))
    (is (null (find-runtime-session-document session "MISSING")))
    (is (eq document-b
            (register-runtime-session-document session document-b)))
    (is (eq document-b
            (find-runtime-session-document session "DRAWING-B")))))

(test blackboard-namespace-is-session-shared
  (reset-autolisp-symbol-table)
  (let* ((document-a (make-document-namespace :name "DRAWING-A"))
         (document-b (make-document-namespace :name "DRAWING-B"))
         (session (make-runtime-session :current-document document-a))
         (context-a (make-evaluation-context
                     :session session
                     :current-document document-a
                     :current-namespace document-a))
         (context-b (make-evaluation-context
                     :session session
                     :current-document document-b
                     :current-namespace document-b))
         (symbol (intern-autolisp-symbol "SHARED")))
    (register-runtime-session-document session document-b)
    (is (runtime-session-blackboard-namespace session))
    (blackboard-set symbol 17 context-a)
    (multiple-value-bind (value boundp) (blackboard-ref symbol context-b)
      (is (not (null boundp)))
      (is (= 17 value)))))

(test propagated-variable-copies-to-existing-and-future-documents
  (reset-autolisp-symbol-table)
  (let* ((document-a (make-document-namespace :name "DRAWING-A"))
         (document-b (make-document-namespace :name "DRAWING-B"))
         (session (make-runtime-session :current-document document-a))
         (context-a (make-evaluation-context
                     :session session
                     :current-document document-a
                     :current-namespace document-a))
         (symbol (intern-autolisp-symbol "GLOBAL-VAR")))
    (register-runtime-session-document session document-b)
    (document-namespace-set document-a symbol 42)
    (propagate-variable symbol context-a)
    (multiple-value-bind (value boundp) (document-namespace-ref document-b symbol)
      (is (not (null boundp)))
      (is (= 42 value)))
    (let ((document-c (make-document-namespace :name "DRAWING-C")))
      (register-runtime-session-document session document-c)
      (multiple-value-bind (value boundp) (document-namespace-ref document-c symbol)
        (is (not (null boundp)))
        (is (= 42 value)))))) 

(test separate-vlx-function-export-and-import-via-document
  (reset-autolisp-symbol-table)
  (let* ((document (make-document-namespace :name "DRAWING-DOC"))
         (producer (make-separate-vlx-namespace :name "PRODUCER"))
         (consumer (make-separate-vlx-namespace :name "CONSUMER"))
         (session (make-runtime-session :current-document document))
         (producer-context (make-evaluation-context
                            :session session
                            :current-document document
                            :current-namespace producer))
         (consumer-context (make-evaluation-context
                            :session session
                            :current-document document
                            :current-namespace consumer))
         (symbol (intern-autolisp-symbol "EXPORTED-FN"))
         (function (make-autolisp-subr "EXPORTED-FN" (lambda (x) (+ x 5)))))
    (set-function symbol function producer-context)
    (is (eq symbol
            (export-function-to-current-document symbol producer-context)))
    (multiple-value-bind (binding boundp origin)
        (document-namespace-function-ref document symbol)
      (is (not (null boundp)))
      (is (eq function binding))
      (is (eq :document origin)))
    (is (eq symbol
            (import-function-from-current-document symbol consumer-context)))
    (multiple-value-bind (binding boundp origin)
        (lookup-function symbol consumer-context)
      (is (not (null boundp)))
      (is (eq function binding))
      (is (eq :namespace origin)))))

(test separate-vlx-application-import-uses-export-registry
  (reset-autolisp-symbol-table)
  (let* ((document (make-document-namespace :name "DRAWING-DOC"))
         (producer (make-separate-vlx-namespace :name "PRODUCER"))
         (consumer (make-separate-vlx-namespace :name "CONSUMER"))
         (session (make-runtime-session :current-document document))
         (producer-context (make-evaluation-context
                            :session session
                            :current-document document
                            :current-namespace producer))
         (consumer-context (make-evaluation-context
                            :session session
                            :current-document document
                            :current-namespace consumer))
         (symbol-a (intern-autolisp-symbol "APP-FN-A"))
         (symbol-b (intern-autolisp-symbol "APP-FN-B"))
         (function-a (make-autolisp-subr "APP-FN-A" (lambda (x) (+ x 1))))
         (function-b (make-autolisp-subr "APP-FN-B" (lambda (x) (+ x 2)))))
    (register-runtime-session-vlx-namespace session producer)
    (register-runtime-session-vlx-namespace session consumer)
    (set-function symbol-a function-a producer-context)
    (set-function symbol-b function-b producer-context)
    (export-function-to-current-document symbol-a producer-context)
    (export-function-to-current-document symbol-b producer-context)
    (is (equal '("app-fn-a" "app-fn-b")
               (mapcar (lambda (symbol)
                         (string-downcase (autolisp-symbol-name symbol)))
                       (import-functions-from-application
                        "PRODUCER"
                        consumer-context))))
    (multiple-value-bind (binding-a boundp-a)
        (lookup-function symbol-a consumer-context)
      (is (not (null boundp-a)))
      (is (eq function-a binding-a)))
    (multiple-value-bind (binding-b boundp-b)
        (lookup-function symbol-b consumer-context)
      (is (not (null boundp-b)))
      (is (eq function-b binding-b)))))

(test autolisp-eval-self-evaluating-and-symbol-lookup
  (reset-autolisp-symbol-table)
  (let ((symbol (intern-autolisp-symbol "FOO")))
    (set-variable symbol 42)
    (is (= 7 (autolisp-eval 7)))
    (is (string= "x" (autolisp-string-value
                      (autolisp-eval (make-autolisp-string "x")))))
    (is (= 42 (autolisp-eval symbol)))))

(test autolisp-eval-quote-progn-and-setq
  (reset-autolisp-symbol-table)
  (let* ((foo (intern-autolisp-symbol "FOO"))
         (bar (intern-autolisp-symbol "BAR"))
         (quoted (autolisp-eval (list (intern-autolisp-symbol "QUOTE") foo))))
    (is (eq foo quoted))
    (is (= 17
           (autolisp-eval
            (list (intern-autolisp-symbol "SETQ") foo 17))))
    (is (= 17 (autolisp-symbol-value foo)))
    (is (= 33
           (autolisp-eval
            (list (intern-autolisp-symbol "PROGN")
                  (list (intern-autolisp-symbol "SETQ") foo 10)
                  (list (intern-autolisp-symbol "SETQ") bar 33)
                  bar))))
    (is (= 10 (autolisp-symbol-value foo)))
    (is (= 33 (autolisp-symbol-value bar)))))

(test autolisp-eval-calls-subr-bindings
  (reset-autolisp-symbol-table)
  (let* ((plus2 (intern-autolisp-symbol "PLUS2"))
         (arg (intern-autolisp-symbol "ARG"))
         (function (make-autolisp-subr "PLUS2" (lambda (value) (+ value 2)))))
    (set-function plus2 function)
    (set-variable arg 5)
    (is (= 7 (autolisp-eval (list plus2 arg))))))

(test autolisp-eval-progn-helper
  (reset-autolisp-symbol-table)
  (let ((foo (intern-autolisp-symbol "FOO")))
    (is (= 9
           (autolisp-eval-progn
            (list (list (intern-autolisp-symbol "SETQ") foo 9)
                  foo))))))

(test autolisp-eval-if-and-cond
  (reset-autolisp-symbol-table)
  (let ((foo (intern-autolisp-symbol "FOO"))
        (if-symbol (intern-autolisp-symbol "IF"))
        (cond-symbol (intern-autolisp-symbol "COND"))
        (setq-symbol (intern-autolisp-symbol "SETQ"))
        (t-symbol (intern-autolisp-symbol "T")))
    (set-variable foo 0)
    (set-variable t-symbol t-symbol)
    (is (= 1 (autolisp-eval (list if-symbol t-symbol 1 2))))
    (is (= 2 (autolisp-eval (list if-symbol nil 1 2))))
    (is (= 7
           (autolisp-eval
            (list cond-symbol
                  (list nil 1)
                  (list t-symbol 7)))))
    (is (= 11
           (autolisp-eval
            (list cond-symbol
                  (list nil 1)
                  (list t-symbol
                        (list setq-symbol foo 11)
                        foo)))))
    (is (= 11 (autolisp-symbol-value foo)))))

(test autolisp-eval-defun-and-usubr-call
  (reset-autolisp-symbol-table)
  (let* ((defun-symbol (intern-autolisp-symbol "DEFUN"))
         (progn-symbol (intern-autolisp-symbol "PROGN"))
         (setq-symbol (intern-autolisp-symbol "SETQ"))
         (plus-symbol (intern-autolisp-symbol "+"))
         (name (intern-autolisp-symbol "ADD2"))
         (arg (intern-autolisp-symbol "X"))
         (local (intern-autolisp-symbol "TMP"))
         (slash (intern-autolisp-symbol "/")))
    (set-function plus-symbol
                  (make-autolisp-subr "+" (lambda (left right) (+ left right))))
    (is (eq name
            (autolisp-eval
             (list defun-symbol
                   name
                   (list arg slash local)
                   (list setq-symbol local arg)
                   (list plus-symbol local 2)))))
    (is (autolisp-symbol-function-bound-p name))
    (is (= 9
           (autolisp-eval (list name 7))))
    (is (= 5
           (autolisp-eval
            (list progn-symbol
                  (list setq-symbol arg 100)
                  (list name 3)
                  5))))
    (is (= 100 (autolisp-symbol-value arg)))))

(test autolisp-eval-defun-q
  (reset-autolisp-symbol-table)
  (let* ((defun-q-symbol (intern-autolisp-symbol "DEFUN-Q"))
         (plus-symbol (intern-autolisp-symbol "+"))
         (name (intern-autolisp-symbol "ADDQ"))
         (arg (intern-autolisp-symbol "X")))
    (set-function plus-symbol
                  (make-autolisp-subr "+" (lambda (left right) (+ left right))))
    (is (eq name
            (autolisp-eval
             (list defun-q-symbol
                   name
                   (list arg)
                   (list plus-symbol arg 2)))))
    (is (equal (list (list arg)
                     (list plus-symbol arg 2))
               (autolisp-function-list-definition name)))
    (is (= 9
           (autolisp-eval (list name 7))))))

(test autolisp-eval-and-or
  ;; AutoLISP `and` / `or` return *T or nil only*, not the first
  ;; non-nil expression value (Common Lisp). Confirmed against
  ;; BricsCAD V26 by Phase-5 product test on 2026-04-26 and against
  ;; Bricsys's per-symbol pages for both AND and OR. Short-circuit
  ;; evaluation is preserved; only the return shape changes.
  (reset-autolisp-symbol-table)
  (let* ((and-symbol (intern-autolisp-symbol "AND"))
         (or-symbol (intern-autolisp-symbol "OR"))
         (setq-symbol (intern-autolisp-symbol "SETQ"))
         (t-symbol (intern-autolisp-symbol "T"))
         (foo (intern-autolisp-symbol "FOO")))
    (set-variable foo 0)
    ;; Empty `and` returns T per Bricsys's documented "T if all
    ;; arguments are non-NIL" rule (vacuous truth).
    (is (eq t-symbol (autolisp-eval (list and-symbol))))
    ;; Empty `or` returns nil.
    (is (null (autolisp-eval (list or-symbol))))
    ;; Non-empty `and` of all-true arguments returns T (NOT 3).
    (is (eq t-symbol (autolisp-eval (list and-symbol 1 2 3))))
    ;; Non-empty `or` with a non-nil somewhere returns T (NOT 7).
    (is (eq t-symbol (autolisp-eval (list or-symbol nil nil 7 9))))
    ;; Short-circuit: `and` stops at first nil; setq side effect not run.
    (is (null
         (autolisp-eval
          (list and-symbol
                nil
                (list setq-symbol foo 99)))))
    (is (= 0 (autolisp-symbol-value foo)))
    ;; Short-circuit: `or` stops at first non-nil; setq side effect IS run
    ;; (because the (setq foo 12) form is the first non-nil clause).
    (is (eq t-symbol
            (autolisp-eval
             (list or-symbol
                   nil
                   (list setq-symbol foo 12)
                   99))))
    (is (= 12 (autolisp-symbol-value foo)))))

(test autolisp-eval-while-and-repeat
  (reset-autolisp-symbol-table)
  (let* ((while-symbol (intern-autolisp-symbol "WHILE"))
         (repeat-symbol (intern-autolisp-symbol "REPEAT"))
         (setq-symbol (intern-autolisp-symbol "SETQ"))
         (plus-symbol (intern-autolisp-symbol "+"))
         (less-symbol (intern-autolisp-symbol "<"))
         (count (intern-autolisp-symbol "COUNT")))
    (set-function plus-symbol
                  (make-autolisp-subr "+" (lambda (left right) (+ left right))))
    (set-function less-symbol
                  (make-autolisp-subr "<" (lambda (left right)
                                            (if (< left right)
                                                (intern-autolisp-symbol "T")
                                                nil))))
    (set-variable count 0)
    (is (null
         (autolisp-eval
          (list while-symbol
                (list less-symbol count 3)
                (list setq-symbol count (list plus-symbol count 1))))))
    (is (= 3 (autolisp-symbol-value count)))
    (set-variable count 0)
    (is (null
         (autolisp-eval
          (list repeat-symbol
                4
                (list setq-symbol count (list plus-symbol count 2))))))
    (is (= 8 (autolisp-symbol-value count)))))

(test autolisp-eval-lambda
  (reset-autolisp-symbol-table)
  (let* ((lambda-symbol (intern-autolisp-symbol "LAMBDA"))
         (setq-symbol (intern-autolisp-symbol "SETQ"))
         (plus-symbol (intern-autolisp-symbol "+"))
         (arg (intern-autolisp-symbol "X"))
         (local (intern-autolisp-symbol "TMP"))
         (outer (intern-autolisp-symbol "X-OUTER"))
         (slash (intern-autolisp-symbol "/")))
    (set-function plus-symbol
                  (make-autolisp-subr "+" (lambda (left right) (+ left right))))
    (set-variable outer 100)
    (let ((fn (autolisp-eval
               (list lambda-symbol
                     (list arg slash local)
                     (list setq-symbol local arg)
                    (list plus-symbol local 1)))))
      (is (typep fn 'clautolisp.autolisp-runtime:autolisp-usubr))
      (is (= 8
             (autolisp-eval
              (list (list lambda-symbol
                          (list arg slash local)
                          (list setq-symbol local arg)
                          (list plus-symbol local 1))
                    7))))
      (is (= 100 (autolisp-symbol-value outer))))))

(test autolisp-eval-function
  ;; `function` is identical to `quote` except for a compiler hint
  ;; (autolisp-spec ch.3, "Special Form Entry: FUNCTION"; Autodesk
  ;; AutoLISP Reference, function): evaluating it returns the symbol
  ;; or lambda form *unevaluated*, so that downstream call sites
  ;; (APPLY, MAPCAR, direct call dispatch) resolve the function
  ;; against the dynamic scope chain at the point of call. That late
  ;; resolution is what makes the portable HOF idiom
  ;; `(apply (function fn) (list arg))` work when `fn` shadows or is
  ;; redefined further down the call stack.
  (reset-autolisp-symbol-table)
  (let* ((function-symbol (intern-autolisp-symbol "FUNCTION"))
         (lambda-symbol (intern-autolisp-symbol "LAMBDA"))
         (plus-symbol (intern-autolisp-symbol "+"))
         (arg (intern-autolisp-symbol "X")))
    (set-function plus-symbol
                  (make-autolisp-subr "+" (lambda (left right) (+ left right))))
    (let* ((lambda-form (list lambda-symbol
                              (list arg)
                              (list plus-symbol arg 1)))
           (named     (autolisp-eval (list function-symbol plus-symbol)))
           (anonymous (autolisp-eval (list function-symbol lambda-form))))
      (is (eq plus-symbol named))
      (is (eq lambda-form anonymous))
      ;; Late resolution via APPLY: the symbol resolves to the
      ;; namespace-cell binding, the lambda form is reified to a usubr.
      (is (= 3
             (call-autolisp-function
              (resolve-autolisp-function-designator named)
              1 2)))
      (is (= 8
             (call-autolisp-function
              (resolve-autolisp-function-designator anonymous)
              7))))))

(test autolisp-eval-foreach
  (reset-autolisp-symbol-table)
  (let* ((foreach-symbol (intern-autolisp-symbol "FOREACH"))
         (setq-symbol (intern-autolisp-symbol "SETQ"))
         (plus-symbol (intern-autolisp-symbol "+"))
         (item (intern-autolisp-symbol "ITEM"))
         (sum (intern-autolisp-symbol "SUM")))
    (set-function plus-symbol
                  (make-autolisp-subr "+" (lambda (left right) (+ left right))))
    (set-variable sum 0)
    (is (= 6
           (autolisp-eval
            (list foreach-symbol
                  item
                  (list (intern-autolisp-symbol "QUOTE") '(1 2 3))
                  (list setq-symbol sum (list plus-symbol sum item))
                  sum))))
    (is (= 6 (autolisp-symbol-value sum)))
    (is (not (autolisp-symbol-value-bound-p item)))))

(test autolisp-eval-signals-runtime-errors
  (reset-autolisp-symbol-table)
  (let ((missing-variable (intern-autolisp-symbol "MISSING-VARIABLE"))
        (missing-function (intern-autolisp-symbol "MISSING-FUNCTION"))
        (foreach-symbol (intern-autolisp-symbol "FOREACH"))
        (plus-symbol (intern-autolisp-symbol "PLUS")))
    (flet ((expect-runtime-error (thunk expected-code)
             (handler-case
                 (progn
                   (funcall thunk)
                   (is nil))
               (autolisp-runtime-error (condition)
                 (is (eq expected-code
                         (autolisp-runtime-error-code condition)))
                 condition))))
      ;; Bare reference to an unset symbol must NOT signal in any
;; conforming dialect — silent-NIL is the strict rule across all
;; AutoLISP hosts (autolisp-spec ch. 3, "Unbound-Variable
;; Reference"). The diagnostic-only :strict-error mode is exercised
;; by `unbound-variable-diagnostic-mode-signals` in evaluator-tests.
      (is (null (autolisp-eval missing-variable)))
      (expect-runtime-error (lambda ()
                              (autolisp-eval (list missing-function 1 2)))
                            :undefined-function)
      (expect-runtime-error (lambda ()
                              (autolisp-eval (list 42 1 2)))
                            :invalid-call-operator)
    (set-function plus-symbol
                  (make-autolisp-subr "PLUS"
                                      (lambda (left right)
                                        (+ left right))))
      (expect-runtime-error (lambda ()
                              (autolisp-eval (list foreach-symbol 42 '(1 2 3) 1)))
                            :invalid-foreach-binding)
    (set-function plus-symbol
                  (make-autolisp-subr "PLUS"
                                      (lambda (left)
                                        left)))
      (let ((condition
              (expect-runtime-error (lambda ()
                                      (autolisp-eval (list plus-symbol 1 2)))
                                    :subr-call-host-error)))
        (is (typep (getf (autolisp-runtime-error-details condition) :condition)
                   'error)))
      (let ((condition
              (expect-runtime-error (lambda ()
                                      (clautolisp.autolisp-runtime::call-autolisp-function-in-context
                                       42
                                       (default-evaluation-context)))
                                    :invalid-function-object)))
        (is (typep condition 'autolisp-runtime-error)))
      (expect-runtime-error (lambda ()
                              (autolisp-eval
                               (list (intern-autolisp-symbol "FUNCTION") 42)))
                            :invalid-function-designator)
      ;; `(function missing-function)` does NOT eagerly resolve — per
      ;; the spec (and Autodesk doc) `function` is identical to `quote`
      ;; except for a compiler hint. Missing-function error surfaces
      ;; only when the returned designator is actually applied.
      (let ((missing (intern-autolisp-symbol "MISSING-FUNCTION")))
        (is (eq missing
                (autolisp-eval (list (intern-autolisp-symbol "FUNCTION")
                                     missing))))
        (expect-runtime-error
         (lambda () (resolve-autolisp-function-designator missing))
         :undefined-function)))))

(test autolisp-read-from-string-returns-first-form
  (reset-autolisp-symbol-table)
  (let ((value (autolisp-read-from-string "(a) (b)")))
    (is (consp value))
    (is (string= "A"
                 (autolisp-symbol-name (first value))))))

(test autolisp-load-file-in-context-evaluates-forms-sequentially
  (reset-autolisp-symbol-table)
  (let* ((plus-symbol (intern-autolisp-symbol "+"))
         (foo (intern-autolisp-symbol "FOO"))
         (path (merge-pathnames
                (format nil "autolisp-load-~36R.lsp" (random (expt 36 6)))
                (uiop:temporary-directory))))
    (set-function plus-symbol
                  (make-autolisp-subr "+" (lambda (left right) (+ left right))))
    (unwind-protect
         (progn
           (with-open-file (stream path
                                   :direction :output
                                   :if-exists :supersede
                                   :if-does-not-exist :create)
             (write-line "(setq foo 1)" stream)
             (write-line "(setq foo (+ foo 2))" stream)
             (write-line "foo" stream))
           (is (= 3
                  (autolisp-load-file-in-context path
                                                 (default-evaluation-context))))
           (is (= 3 (autolisp-symbol-value foo))))
      (when (probe-file path)
        (delete-file path)))))

(test call-with-autolisp-error-handler-updates-errno
  (reset-autolisp-symbol-table)
  (let ((error-symbol (intern-autolisp-symbol "*ERROR*")))
    (set-autolisp-errno 7)
    (set-function error-symbol
                  (make-autolisp-subr
                   "*ERROR*"
                   (lambda (message)
                     message)))
    (let ((result (call-with-autolisp-error-handler
                   (lambda ()
                     (clautolisp.autolisp-runtime::signal-autolisp-runtime-error
                      :test-error
                      "Synthetic runtime failure.")))))
      (is (typep result 'autolisp-string))
      (is (string= "Synthetic runtime failure."
                   (autolisp-string-value result)))
      (is (= 1 (autolisp-errno))))
    (let ((result (call-with-autolisp-error-handler
                   (lambda ()
                     (clautolisp.autolisp-runtime::signal-autolisp-runtime-error
                      :undefined-function
                      "Missing function.")))))
      (is (typep result 'autolisp-string))
      (is (string= "Missing function."
                   (autolisp-string-value result)))
      (is (= 3 (autolisp-errno))))
    (let ((result (call-with-autolisp-error-handler
                   (lambda ()
                     (clautolisp.autolisp-runtime::signal-autolisp-runtime-error
                      :invalid-open-mode
                      "Bad file mode.")))))
      (is (typep result 'autolisp-string))
      (is (string= "Bad file mode."
                   (autolisp-string-value result)))
      (is (= 5 (autolisp-errno))))
    (let ((result (call-with-autolisp-error-handler
                   (lambda ()
                     (clautolisp.autolisp-runtime::signal-autolisp-runtime-error
                      :subr-call-host-error
                      "Wrapped host failure.")))))
      (is (typep result 'autolisp-string))
      (is (string= "Wrapped host failure."
                   (autolisp-string-value result)))
      (is (= 6 (autolisp-errno))))
    (is (= 3
           (call-with-autolisp-error-handler
            (lambda ()
              3))))
    (is (= 0 (autolisp-errno)))))

;;; --- POSIX locale probe (LC_ALL / LC_CTYPE / LANG) ------------------

(test parse-locale-encoding-string-maps-common-encodings
  "PARSE-LOCALE-ENCODING-STRING recognises every encoding family the
CLI's `-e ENC' helper handles, returning a keyword usable as a Lisp
external-format."
  (is (eq :utf-8        (clautolisp.autolisp-runtime:parse-locale-encoding-string "UTF-8")))
  (is (eq :utf-8        (clautolisp.autolisp-runtime:parse-locale-encoding-string "utf8")))
  (is (eq :iso-8859-1   (clautolisp.autolisp-runtime:parse-locale-encoding-string "ISO-8859-1")))
  (is (eq :iso-8859-1   (clautolisp.autolisp-runtime:parse-locale-encoding-string "latin1")))
  (is (eq :windows-1252 (clautolisp.autolisp-runtime:parse-locale-encoding-string "windows-1252")))
  (is (eq :windows-1252 (clautolisp.autolisp-runtime:parse-locale-encoding-string "cp1252")))
  (is (eq :ascii        (clautolisp.autolisp-runtime:parse-locale-encoding-string "us-ascii")))
  (is (null             (clautolisp.autolisp-runtime:parse-locale-encoding-string nil)))
  (is (null             (clautolisp.autolisp-runtime:parse-locale-encoding-string ""))))

(test parse-posix-locale-extracts-encoding-suffix
  "PARSE-POSIX-LOCALE pulls the .ENCODING suffix out of a full
POSIX locale string, ignores @modifier tails, and returns NIL when
no encoding is present (e.g. plain 'C' / 'POSIX')."
  (is (eq :utf-8        (clautolisp.autolisp-runtime:parse-posix-locale "en_US.UTF-8")))
  (is (eq :utf-8        (clautolisp.autolisp-runtime:parse-posix-locale "fr_FR.UTF-8@euro")))
  (is (eq :iso-8859-1   (clautolisp.autolisp-runtime:parse-posix-locale "fr_FR.ISO-8859-1")))
  (is (eq :windows-1252 (clautolisp.autolisp-runtime:parse-posix-locale "ja_JP.windows-1252")))
  (is (null             (clautolisp.autolisp-runtime:parse-posix-locale "C")))
  (is (null             (clautolisp.autolisp-runtime:parse-posix-locale "POSIX")))
  (is (null             (clautolisp.autolisp-runtime:parse-posix-locale "en_US")))
  (is (null             (clautolisp.autolisp-runtime:parse-posix-locale "")))
  (is (null             (clautolisp.autolisp-runtime:parse-posix-locale nil))))

;;; --- PRINT-OBJECT routes AutoLISP values to their surface syntax ----
;;;
;;; Regression for debug-messages-autolisp-symbols.issue: error
;;; messages containing AutoLISP values used to dump the underlying
;;; defstruct form (#S(... :NAME "T" :ORIGINAL-NAME "T" :PLIST NIL))
;;; — useless to an AutoLISP developer. PRINT-OBJECT methods on every
;;; runtime value struct now render the AutoLISP surface syntax.

(test print-object-renders-autolisp-symbol-by-name
  "An autolisp-symbol prints as its name in princ and prin1 alike —
no #S(...) structure dump in error messages."
  (let ((sym (clautolisp.autolisp-runtime:intern-autolisp-symbol "T")))
    (is (string= "T" (princ-to-string sym)))
    (is (string= "T" (prin1-to-string sym))))
  (let ((sym (clautolisp.autolisp-runtime:intern-autolisp-symbol "MY-FN")))
    (is (string= "MY-FN" (princ-to-string sym)))))

(test print-object-renders-autolisp-string-with-escape
  "An autolisp-string prints quoted under prin1 (~S), unquoted under
princ (~A), matching the (princ \"abc\") / (prin1 \"abc\") semantics
AutoLISP itself uses."
  (let* ((s "hello"))
    (let ((al-str (clautolisp.autolisp-runtime.internal::make-autolisp-string :value s)))
      (is (string= "hello"   (princ-to-string al-str)))
      (is (string= "\"hello\"" (prin1-to-string al-str)))))
  ;; Embedded quote / backslash get escape-doubled under prin1.
  (let ((al-str (clautolisp.autolisp-runtime.internal::make-autolisp-string
                 :value "a\"b\\c")))
    (is (string= "\"a\\\"b\\\\c\"" (prin1-to-string al-str)))))

(test print-object-conses-recurse-into-autolisp-values
  "PRINT-OBJECT methods compose: a cons of AutoLISP values is printed
by CL's list printer using our methods element-by-element, so error
backtraces like `in SUBR CAR: (A-SYMBOL)' come out cleanly without
nested #S(...) noise."
  (let* ((sym (clautolisp.autolisp-runtime:intern-autolisp-symbol "A-SYMBOL"))
         (lst (list sym))
         (rendered (princ-to-string lst)))
    (is (string= "(A-SYMBOL)" rendered)))
  ;; Mixed list of an autolisp-symbol and a CL integer.
  (let* ((sym (clautolisp.autolisp-runtime:intern-autolisp-symbol "X"))
         (rendered (princ-to-string (list sym 42))))
    (is (string= "(X 42)" rendered))))

;;; --- Terminal colour policy and ANSI symbol rendering ---------------
;;;
;;; The follow-up portion of debug-messages-autolisp-symbols.issue:
;;; PRINT-OBJECT on AUTOLISP-SYMBOL wraps its output in an ANSI SGR
;;; sequence when *COLOR-OUTPUT* names a colour, and emits the bare
;;; name otherwise. RESOLVE-COLOR-POLICY does the env / tty / probe
;;; cascade that decides what the CLI binds.

(test ansi-colorize-no-ops-when-colour-is-nil
  "ANSI-COLORIZE on NIL passes the string through unchanged — the
cheap path the PRINT-OBJECT method takes when colour is off."
  (is (string= "FOO" (clautolisp.autolisp-runtime:ansi-colorize "FOO" nil))))

(test ansi-colorize-wraps-string-in-sgr-sequence
  "Yellow and blue produce the expected SGR 33 / 34 sequences with a
trailing reset (SGR 0) so downstream output isn't tinted."
  (let ((yellow (clautolisp.autolisp-runtime:ansi-colorize "FOO" :yellow))
        (blue   (clautolisp.autolisp-runtime:ansi-colorize "FOO" :blue)))
    (is (string= (format nil "~C[33mFOO~C[0m" #\Esc #\Esc) yellow))
    (is (string= (format nil "~C[34mFOO~C[0m" #\Esc #\Esc) blue))))

(test print-object-symbol-uses-colour-when-policy-armed
  "An AUTOLISP-SYMBOL rendered through PRINC honours a non-NIL
*COLOR-OUTPUT* binding: the rendered string carries an SGR-33 prefix
and an SGR-0 reset around the bare symbol name."
  (let ((sym (clautolisp.autolisp-runtime:intern-autolisp-symbol "MY-FN")))
    (is (string= "MY-FN" (princ-to-string sym)))
    (let ((clautolisp.autolisp-runtime:*color-output* :yellow))
      (is (string= (format nil "~C[33mMY-FN~C[0m" #\Esc #\Esc)
                   (princ-to-string sym))))
    (let ((clautolisp.autolisp-runtime:*color-output* :blue))
      (is (string= (format nil "~C[34mMY-FN~C[0m" #\Esc #\Esc)
                   (princ-to-string sym))))))

(test parse-colorfgbg-classifies-background-index
  "$COLORFGBG's second field is the ANSI palette index for the
background. Indices 0..6 and 8 (bright black) are dark; everything
else is light. Unparseable / missing values yield NIL."
  ;; Empty string stands in for "unset" — UIOP exposes GETENV but no
  ;; portable UNSETENV, and our parser treats "" and NIL identically
  ;; (both fail (PLUSP (LENGTH …))).
  (labels ((with-env (val thunk)
             (let ((before (or (uiop:getenv "COLORFGBG") "")))
               (unwind-protect
                    (progn
                      (setf (uiop:getenv "COLORFGBG") (or val ""))
                      (funcall thunk))
                 (setf (uiop:getenv "COLORFGBG") before)))))
    (with-env "15;0"    (lambda () (is (eq :dark  (clautolisp.autolisp-runtime:parse-colorfgbg)))))
    (with-env "15;8"    (lambda () (is (eq :dark  (clautolisp.autolisp-runtime:parse-colorfgbg)))))
    (with-env "0;15"    (lambda () (is (eq :light (clautolisp.autolisp-runtime:parse-colorfgbg)))))
    (with-env "0;7"     (lambda () (is (eq :light (clautolisp.autolisp-runtime:parse-colorfgbg)))))
    (with-env "garbage" (lambda () (is (null (clautolisp.autolisp-runtime:parse-colorfgbg)))))
    (with-env nil       (lambda () (is (null (clautolisp.autolisp-runtime:parse-colorfgbg)))))))

(test parse-osc11-response-extracts-rgb-triple
  "PARSE-OSC11-RESPONSE handles the standard ESC-ST terminated reply,
the BEL-terminated variant, and rejects malformed input."
  (is (equal (list #x2e2e #x3434 #x3a3a)
             (clautolisp.autolisp-runtime:parse-osc11-response
              (format nil "~C]11;rgb:2e2e/3434/3a3a~C\\" #\Esc #\Esc))))
  (is (equal (list #xffff #xffff #xffff)
             (clautolisp.autolisp-runtime:parse-osc11-response
              (format nil "~C]11;rgb:ffff/ffff/ffff~C" #\Esc #\Bel))))
  (is (null (clautolisp.autolisp-runtime:parse-osc11-response "not a response")))
  (is (null (clautolisp.autolisp-runtime:parse-osc11-response ""))))

(test luminance-of-rgb-matches-rec-601
  "Rec-601 weights: 0.299*R + 0.587*G + 0.114*B. Pure white saturates
near 1.0, pure black is 0.0, and the conventional 0.5 cut falls
between common dark and light terminal backgrounds."
  (let ((white (clautolisp.autolisp-runtime:luminance-of-rgb '(65535 65535 65535)))
        (black (clautolisp.autolisp-runtime:luminance-of-rgb '(0 0 0)))
        (dark  (clautolisp.autolisp-runtime:luminance-of-rgb '(#x2e2e #x3434 #x3a3a)))
        (light (clautolisp.autolisp-runtime:luminance-of-rgb '(#xeeee #xeeee #xeeee))))
    (is (> white 0.99))
    (is (= black 0.0))
    (is (< dark 0.5))
    (is (> light 0.5))
    (is (null (clautolisp.autolisp-runtime:luminance-of-rgb '(1 2))))
    (is (null (clautolisp.autolisp-runtime:luminance-of-rgb nil)))))

(test resolve-color-policy-honours-no-color-flag
  "The --no-color CLI flag short-circuits the entire cascade. Even on
a tty with a freshly probed luminance, the policy is NIL.
Defensively, a broken stream also yields NIL (the function never
signals)."
  (is (null (clautolisp.autolisp-runtime:resolve-color-policy
             :no-color-flag t
             :probe-luminance-p nil)))
  (let ((sink (make-broadcast-stream)))
    (is (null (clautolisp.autolisp-runtime:resolve-color-policy
               :stream sink
               :probe-luminance-p nil)))))

(test resolve-color-policy-honours-no-color-env
  "$NO_COLOR (https://no-color.org) disables colour regardless of the
--no-color flag's state. Unset means the env doesn't gate."
  (labels ((with-env (val thunk)
             (let ((before (or (uiop:getenv "NO_COLOR") "")))
               (unwind-protect
                    (progn
                      (setf (uiop:getenv "NO_COLOR") (or val ""))
                      (funcall thunk))
                 (setf (uiop:getenv "NO_COLOR") before)))))
    (with-env "1" (lambda ()
                    (is (clautolisp.autolisp-runtime:env-no-color-set-p))
                    (is (null (clautolisp.autolisp-runtime:resolve-color-policy
                               :probe-luminance-p nil)))))
    (with-env nil (lambda ()
                    (is (not (clautolisp.autolisp-runtime:env-no-color-set-p)))))))

(test ansi-colorize-renders-foreground-and-background-pair
  "(FG BG) shape produces a two-parameter SGR sequence (\"33;40\"
for yellow on black). Either axis may be NIL — the SGR keeps only
the recognised parameter. Bright variants honour the 90+ / 100+
ranges. Unknown keywords on both axes mean the result is the bare
string with no SGR at all."
  (let ((expected-yellow-on-black
          (format nil "~C[33;40mFOO~C[0m" #\Esc #\Esc)))
    (is (string= expected-yellow-on-black
                 (clautolisp.autolisp-runtime:ansi-colorize
                  "FOO" '(:yellow :black)))))
  (is (string= (format nil "~C[96mFOO~C[0m" #\Esc #\Esc)
               (clautolisp.autolisp-runtime:ansi-colorize
                "FOO" '(:bright-cyan nil))))
  (is (string= (format nil "~C[44mFOO~C[0m" #\Esc #\Esc)
               (clautolisp.autolisp-runtime:ansi-colorize
                "FOO" '(nil :blue))))
  (is (string= "FOO"
               (clautolisp.autolisp-runtime:ansi-colorize
                "FOO" '(:not-a-colour :nor-this))))
  ;; Backwards compat: the keyword shorthand is still foreground-only.
  (is (string= (format nil "~C[33mFOO~C[0m" #\Esc #\Esc)
               (clautolisp.autolisp-runtime:ansi-colorize
                "FOO" :yellow))))

(test parse-colour-name-handles-case-whitespace-sentinels
  "Names are case-insensitive and tolerate leading / trailing
whitespace. The 'clear this axis' sentinels return NIL so a user
can spell `none' / `default' / `off' to leave one axis bare."
  (is (eq :yellow
          (clautolisp.autolisp-runtime:parse-colour-name "yellow")))
  (is (eq :yellow
          (clautolisp.autolisp-runtime:parse-colour-name "Yellow")))
  (is (eq :bright-blue
          (clautolisp.autolisp-runtime:parse-colour-name "Bright-Blue")))
  (is (eq :bright-yellow
          (clautolisp.autolisp-runtime:parse-colour-name "  BRIGHT-YELLOW  ")))
  (is (null (clautolisp.autolisp-runtime:parse-colour-name nil)))
  (is (null (clautolisp.autolisp-runtime:parse-colour-name "")))
  (is (null (clautolisp.autolisp-runtime:parse-colour-name "   ")))
  (is (null (clautolisp.autolisp-runtime:parse-colour-name "default")))
  (is (null (clautolisp.autolisp-runtime:parse-colour-name "none")))
  (is (null (clautolisp.autolisp-runtime:parse-colour-name "off"))))

(test env-symbol-colour-spec-pairs-the-two-env-vars
  "ENV-SYMBOL-COLOUR-SPEC returns (FG BG) when either env var is set,
NIL when neither is. An unrecognised name still 'counts' as set
because the user clearly tried to specify something — the SGR
emission step is what decides to drop unrecognised codes."
  (labels ((with-env (fg bg thunk)
             (let ((fg-before (or (uiop:getenv "CLAUTOLISP_SYMBOL_FOREGROUND") ""))
                   (bg-before (or (uiop:getenv "CLAUTOLISP_SYMBOL_BACKGROUND") "")))
               (unwind-protect
                    (progn
                      (setf (uiop:getenv "CLAUTOLISP_SYMBOL_FOREGROUND") (or fg ""))
                      (setf (uiop:getenv "CLAUTOLISP_SYMBOL_BACKGROUND") (or bg ""))
                      (funcall thunk))
                 (setf (uiop:getenv "CLAUTOLISP_SYMBOL_FOREGROUND") fg-before)
                 (setf (uiop:getenv "CLAUTOLISP_SYMBOL_BACKGROUND") bg-before)))))
    (with-env "yellow" "black"
              (lambda () (is (equal '(:yellow :black)
                                    (clautolisp.autolisp-runtime:env-symbol-colour-spec)))))
    (with-env "bright-cyan" nil
              (lambda () (is (equal '(:bright-cyan nil)
                                    (clautolisp.autolisp-runtime:env-symbol-colour-spec)))))
    (with-env nil "blue"
              (lambda () (is (equal '(nil :blue)
                                    (clautolisp.autolisp-runtime:env-symbol-colour-spec)))))
    (with-env "default" "none"
              (lambda () (is (null (clautolisp.autolisp-runtime:env-symbol-colour-spec)))))
    (with-env nil nil
              (lambda () (is (null (clautolisp.autolisp-runtime:env-symbol-colour-spec)))))))

(test resolve-color-policy-honours-symbol-colour-env-vars
  "The CLAUTOLISP_SYMBOL_* env vars win over the luminance probe.
Even on a 'light' background (where the default would otherwise pick
:blue), the user's foreground / background choice takes effect and
RESOLVE-COLOR-POLICY returns the (FG BG) pair the user asked for."
  (labels ((with-env (key val thunk)
             (let ((before (or (uiop:getenv key) "")))
               (unwind-protect
                    (progn (setf (uiop:getenv key) (or val ""))
                           (funcall thunk))
                 (setf (uiop:getenv key) before)))))
    (with-env "CLAUTOLISP_BACKGROUND" "light"
      (lambda ()
        (with-env "CLAUTOLISP_SYMBOL_FOREGROUND" "bright-cyan"
          (lambda ()
            (with-env "CLAUTOLISP_SYMBOL_BACKGROUND" "black"
              (lambda ()
                ;; Use a synonym stream pointed at *terminal-io* so the
                ;; tty gate fires; if it doesn't we get NIL and the
                ;; subsequent EQUAL fails informatively.
                (let* ((s *terminal-io*)
                       (policy (clautolisp.autolisp-runtime:resolve-color-policy
                                :stream s :probe-luminance-p nil)))
                  (when policy
                    (is (equal '(:bright-cyan :black) policy))))))))))))

(test print-object-symbol-renders-with-foreground-and-background
  "When *COLOR-OUTPUT* is a (FG BG) pair, the symbol's printed name
carries both SGR parameters — yellow foreground on black background
renders as `\\e[33;40mNAME\\e[0m'."
  (let ((sym (clautolisp.autolisp-runtime:intern-autolisp-symbol "MY-FN"))
        (clautolisp.autolisp-runtime:*color-output* '(:yellow :black)))
    (is (string= (format nil "~C[33;40mMY-FN~C[0m" #\Esc #\Esc)
                 (princ-to-string sym))))
  ;; Background-only also works: the SGR carries just the 4x code.
  (let ((sym (clautolisp.autolisp-runtime:intern-autolisp-symbol "OTHER"))
        (clautolisp.autolisp-runtime:*color-output* '(nil :blue)))
    (is (string= (format nil "~C[44mOTHER~C[0m" #\Esc #\Esc)
                 (princ-to-string sym)))))

(test resolve-color-policy-does-not-spawn-osc11-probe-by-default
  "Regression for the macOS arm64 SIGTTOU hang: by default
RESOLVE-COLOR-POLICY must NOT call PROBE-TERMINAL-BACKGROUND-VIA-OSC11
(it spawns /bin/sh + stty + dd, and the child can get suspended
with no clean exit path). Users opt in via $CLAUTOLISP_PROBE_OSC11;
without that, only the cheap env-var rungs run.

We monkey-patch the probe to raise; if it gets called the test
fails loudly instead of hanging the suite. The cleanup also
explicitly unsets $CLAUTOLISP_PROBE_OSC11 so a stray env in the
test runner can't re-enable the probe."
  (let ((called-p nil)
        (probe-fn #'clautolisp.autolisp-runtime::probe-terminal-background-via-osc11)
        (env-before (or (uiop:getenv "CLAUTOLISP_PROBE_OSC11") "")))
    (unwind-protect
         (progn
           (setf (uiop:getenv "CLAUTOLISP_PROBE_OSC11") "")
           (setf (symbol-function
                  'clautolisp.autolisp-runtime::probe-terminal-background-via-osc11)
                 (lambda (&rest args)
                   (declare (ignore args))
                   (setf called-p t)
                   (error "OSC 11 probe must not run by default")))
           ;; Pass a TTY-looking stream (interactive-stream-p returns
           ;; T on *terminal-io* in tests run under FiveAM); even if
           ;; it doesn't, the tty branch returns NIL and we never
           ;; reach the probe. Either way, called-p stays NIL.
           (clautolisp.autolisp-runtime:resolve-color-policy)
           (is (null called-p))
           ;; Likewise when probe-luminance-p is explicitly T but
           ;; the OSC 11 opt-in env is empty — still no probe.
           (clautolisp.autolisp-runtime:resolve-color-policy
            :probe-luminance-p t)
           (is (null called-p)))
      (setf (symbol-function
             'clautolisp.autolisp-runtime::probe-terminal-background-via-osc11)
            probe-fn)
      (setf (uiop:getenv "CLAUTOLISP_PROBE_OSC11") env-before))))
