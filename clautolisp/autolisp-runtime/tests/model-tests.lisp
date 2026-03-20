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
         (function (lambda (x) x)))
    (set-function symbol function context)
    (multiple-value-bind (binding boundp origin) (lookup-function symbol context)
      (is (not (null boundp)))
      (is (eq function binding))
      (is (eq :namespace origin)))
    (is (eq function
            (function-cell-function
             (namespace-function-cell document symbol :createp nil))))))

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

(test autolisp-eval-and-or
  (reset-autolisp-symbol-table)
  (let* ((and-symbol (intern-autolisp-symbol "AND"))
         (or-symbol (intern-autolisp-symbol "OR"))
         (setq-symbol (intern-autolisp-symbol "SETQ"))
         (foo (intern-autolisp-symbol "FOO")))
    (set-variable foo 0)
    (is (eq (intern-autolisp-symbol "T")
            (autolisp-eval (list and-symbol))))
    (is (null (autolisp-eval (list or-symbol))))
    (is (= 3 (autolisp-eval (list and-symbol 1 2 3))))
    (is (= 7 (autolisp-eval (list or-symbol nil nil 7 9))))
    (is (null
         (autolisp-eval
          (list and-symbol
                nil
                (list setq-symbol foo 99)))))
    (is (= 0 (autolisp-symbol-value foo)))
    (is (= 12
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

(test autolisp-read-from-string-returns-first-form
  (reset-autolisp-symbol-table)
  (let ((value (autolisp-read-from-string "(a) (b)")))
    (is (consp value))
    (is (string= "A"
                 (autolisp-symbol-name (first value))))))
