(in-package #:clautolisp.autolisp-builtins-core.tests)

(in-suite autolisp-builtins-core-suite)

(test builtin-registry-returns-subrs
  (let ((builtin (find-core-builtin "TYPE")))
    (is (typep builtin 'autolisp-subr))
    (is (string= "TYPE" (autolisp-subr-name builtin)))))

(test installed-builtins-bind-functions-on-symbols
  (reset-autolisp-symbol-table)
  (install-core-builtins)
  (let ((symbol (find-autolisp-symbol "TYPE")))
    (is (typep symbol 'autolisp-symbol))
    (is (typep (autolisp-symbol-function symbol) 'autolisp-subr))))

(test builtin-type-call
  (reset-autolisp-symbol-table)
  (install-core-builtins)
  (let* ((symbol (find-autolisp-symbol "TYPE"))
         (result (call-autolisp-function (autolisp-symbol-function symbol) 42)))
    (is (typep result 'autolisp-symbol))
    (is (string= "INT" (autolisp-symbol-name result)))))

(test builtin-basic-arithmetic
  (reset-autolisp-symbol-table)
  (install-core-builtins)
  (let* ((+-fn (autolisp-symbol-function (find-autolisp-symbol "+")))
         (--fn (autolisp-symbol-function (find-autolisp-symbol "-")))
         (*-fn (autolisp-symbol-function (find-autolisp-symbol "*")))
         (/-fn (autolisp-symbol-function (find-autolisp-symbol "/")))
         (1+-fn (autolisp-symbol-function (find-autolisp-symbol "1+")))
         (1--fn (autolisp-symbol-function (find-autolisp-symbol "1-")))
         (max-fn (autolisp-symbol-function (find-autolisp-symbol "MAX")))
         (min-fn (autolisp-symbol-function (find-autolisp-symbol "MIN")))
         (rem-fn (autolisp-symbol-function (find-autolisp-symbol "REM")))
         (gcd-fn (autolisp-symbol-function (find-autolisp-symbol "GCD")))
         (lcm-fn (autolisp-symbol-function (find-autolisp-symbol "LCM")))
         (~-fn (autolisp-symbol-function (find-autolisp-symbol "~")))
         (logand-fn (autolisp-symbol-function (find-autolisp-symbol "LOGAND")))
         (logior-fn (autolisp-symbol-function (find-autolisp-symbol "LOGIOR")))
         (lsh-fn (autolisp-symbol-function (find-autolisp-symbol "LSH"))))
    (is (= 0 (call-autolisp-function +-fn)))
    (is (= 6 (call-autolisp-function +-fn 1 2 3)))
    (is (= 1 (call-autolisp-function *-fn)))
    (is (= 24 (call-autolisp-function *-fn 2 3 4)))
    (is (= -7 (call-autolisp-function --fn 7)))
    (is (= 5 (call-autolisp-function --fn 10 2 3)))
    (is (= 0.5d0 (call-autolisp-function /-fn 2)))
    (is (= 5 (call-autolisp-function /-fn 20 2 2)))
    (is (typep (call-autolisp-function /-fn 2) 'double-float))
    (is (typep (call-autolisp-function /-fn 20 2 2) '(signed-byte 32)))
    (is (= 8 (call-autolisp-function 1+-fn 7)))
    (is (= 6 (call-autolisp-function 1--fn 7)))
    (is (= 9 (call-autolisp-function max-fn 1 9 3 7)))
    (is (= 1 (call-autolisp-function min-fn 1 9 3 7)))
    (is (= 2.5d0 (call-autolisp-function max-fn 1 2.5d0 2)))
    (is (= 1.5d0 (call-autolisp-function min-fn 3 1.5d0 2)))
    (is (= 2 (call-autolisp-function rem-fn 17 5)))
    (is (= 4 (call-autolisp-function gcd-fn 20 12)))
    (is (= 6 (call-autolisp-function gcd-fn 54 24 18)))
    (is (= 0 (call-autolisp-function gcd-fn)))
    (is (= 12 (call-autolisp-function lcm-fn 3 4)))
    (is (= 0 (call-autolisp-function lcm-fn 0 5)))
    (is (= 1 (call-autolisp-function lcm-fn)))
    (is (= -1 (call-autolisp-function ~-fn 0)))
    (is (= 2 (call-autolisp-function logand-fn 6 3)))
    (is (= 7 (call-autolisp-function logior-fn 6 3 5)))
    (is (= 20 (call-autolisp-function lsh-fn 5 2)))
    (is (= 1 (call-autolisp-function lsh-fn 4 -2)))))

(test builtin-null-and-not
  (reset-autolisp-symbol-table)
  (install-core-builtins)
  (let* ((null-fn (autolisp-symbol-function (find-autolisp-symbol "NULL")))
         (not-fn (autolisp-symbol-function (find-autolisp-symbol "NOT"))))
    (is (string= "T" (autolisp-symbol-name (call-autolisp-function null-fn nil))))
    (is (string= "T" (autolisp-symbol-name (call-autolisp-function not-fn nil))))
    (is (null (call-autolisp-function null-fn 1)))))

(test builtin-vl-symbol-name
  (reset-autolisp-symbol-table)
  (install-core-builtins)
  (let* ((foo (intern-autolisp-symbol "FOO"))
         (fn (autolisp-symbol-function (find-autolisp-symbol "VL-SYMBOL-NAME")))
         (result (call-autolisp-function fn foo)))
    (is (typep result 'autolisp-string))
    (is (string= "FOO" (autolisp-string-value result)))))

(test builtin-errors-are-normalized
  (reset-autolisp-symbol-table)
  (install-core-builtins)
  (let ((car-fn (autolisp-symbol-function (find-autolisp-symbol "CAR")))
        (open-fn (autolisp-symbol-function (find-autolisp-symbol "OPEN")))
        (strlen-fn (autolisp-symbol-function (find-autolisp-symbol "STRLEN")))
        (abs-fn (autolisp-symbol-function (find-autolisp-symbol "ABS")))
        (=-fn (autolisp-symbol-function (find-autolisp-symbol "=")))
        (/=-fn (autolisp-symbol-function (find-autolisp-symbol "/=")))
        (/-fn (autolisp-symbol-function (find-autolisp-symbol "/")))
        (rem-fn (autolisp-symbol-function (find-autolisp-symbol "REM")))
        (read-fn (autolisp-symbol-function (find-autolisp-symbol "READ"))))
    (flet ((expect-builtin-error (thunk expected-code expected-builtin)
             (handler-case
                 (progn
                   (funcall thunk)
                   (is nil))
               (autolisp-runtime-error (condition)
                 (is (eq expected-code
                         (autolisp-runtime-error-code condition)))
                 (is (string= expected-builtin
                              (getf (autolisp-runtime-error-details condition)
                                    :builtin)))))))
      (expect-builtin-error (lambda ()
                              (call-autolisp-function car-fn 42))
                            :invalid-list-argument
                            "CAR")
      (expect-builtin-error (lambda ()
                              (call-autolisp-function strlen-fn 42))
                            :invalid-string-argument
                            "STRLEN")
      (expect-builtin-error (lambda ()
                              (call-autolisp-function abs-fn
                                                      (make-autolisp-string "x")))
                            :invalid-number-argument
                            "ABS")
      (expect-builtin-error (lambda ()
                              (call-autolisp-function =-fn
                                                      (intern-autolisp-symbol "FOO")))
                            :invalid-comparison-argument
                            "=")
      (expect-builtin-error (lambda ()
                              (call-autolisp-function /=-fn))
                            :wrong-number-of-arguments
                            "/=")
      (expect-builtin-error (lambda ()
                              (call-autolisp-function open-fn
                                                      (make-autolisp-string "/tmp/unused")
                                                      (make-autolisp-string "bad-mode")))
                            :invalid-open-mode
                            "OPEN")
      (expect-builtin-error (lambda ()
                              (call-autolisp-function open-fn
                                                      (make-autolisp-string "/tmp/unused")
                                                      (make-autolisp-string "r")
                                                      (make-autolisp-string "")))
                            :invalid-external-format
                            "OPEN")
      (expect-builtin-error (lambda ()
                              (call-autolisp-function open-fn
                                                      (make-autolisp-string "/tmp/unused")
                                                      (make-autolisp-string "r")
                                                      (make-autolisp-string "(")))
                            :invalid-external-format
                            "OPEN")
      (expect-builtin-error (lambda ()
                              (call-autolisp-function /-fn 1 0))
                            :division-by-zero
                            "/")
      (expect-builtin-error (lambda ()
                              (call-autolisp-function rem-fn 1 0))
                            :division-by-zero
                            "REM")
      (expect-builtin-error (lambda ()
                              (call-autolisp-function read-fn
                                                      (make-autolisp-string "(")))
                            :invalid-read-syntax
                            "READ"))))

(test builtin-boundp
  (reset-autolisp-symbol-table)
  (install-core-builtins)
  (let* ((foo (intern-autolisp-symbol "FOO"))
         (bar (intern-autolisp-symbol "BAR"))
         (baz (intern-autolisp-symbol "BAZ"))
         (fn (autolisp-symbol-function (find-autolisp-symbol "BOUNDP"))))
    (set-autolisp-symbol-value foo 17)
    (set-autolisp-symbol-value bar nil)
    (is (string= "T" (autolisp-symbol-name (call-autolisp-function fn foo))))
    (is (null (call-autolisp-function fn bar)))
    (is (null (call-autolisp-function fn baz)))
    (is (autolisp-symbol-value-bound-p baz))))

(test builtin-blackboard-and-propagation
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
                     :current-namespace document-b)))
    (clautolisp.autolisp-runtime:register-runtime-session-document session document-b)
    (set-default-evaluation-context context-a)
    (install-core-builtins)
    (let* ((symbol (intern-autolisp-symbol "SHARED-VAR"))
           (bb-set-fn (find-core-builtin "VL-BB-SET"))
           (bb-ref-fn (find-core-builtin "VL-BB-REF"))
           (propagate-fn (find-core-builtin "VL-PROPAGATE")))
      (is (= 17 (call-autolisp-function bb-set-fn symbol 17)))
      (set-default-evaluation-context context-b)
      (is (= 17 (call-autolisp-function bb-ref-fn symbol)))
      (set-default-evaluation-context context-a)
      (set-autolisp-symbol-value symbol 42)
      (is (= 42 (call-autolisp-function propagate-fn symbol)))
      (set-default-evaluation-context context-b)
      (is (= 42 (autolisp-symbol-value symbol))))))

(test builtin-document-namespace-access
  (reset-autolisp-symbol-table)
  (let* ((document (make-document-namespace :name "DRAWING-DOC"))
         (vlx (clautolisp.autolisp-runtime:make-separate-vlx-namespace :name "APP"))
         (session (make-runtime-session :current-document document))
         (context (make-evaluation-context
                   :session session
                   :current-document document
                   :current-namespace vlx)))
    (set-default-evaluation-context context)
    (install-core-builtins)
    (let* ((symbol (intern-autolisp-symbol "DOC-VAR"))
           (doc-set-fn (find-core-builtin "VL-DOC-SET"))
           (doc-ref-fn (find-core-builtin "VL-DOC-REF")))
      (is (= 23 (call-autolisp-function doc-set-fn symbol 23)))
      (is (= 23 (call-autolisp-function doc-ref-fn symbol)))
      (is (= 23
             (nth-value 0
                        (clautolisp.autolisp-runtime:document-namespace-ref
                         document
                         symbol))))
      (is (null (autolisp-symbol-value symbol))))))

(test builtin-document-export-and-import
  (reset-autolisp-symbol-table)
  (let* ((document (make-document-namespace :name "DRAWING-DOC"))
         (producer (clautolisp.autolisp-runtime:make-separate-vlx-namespace
                    :name "PRODUCER"))
         (consumer (clautolisp.autolisp-runtime:make-separate-vlx-namespace
                    :name "CONSUMER"))
         (session (make-runtime-session :current-document document))
         (producer-context (make-evaluation-context
                            :session session
                            :current-document document
                            :current-namespace producer))
         (consumer-context (make-evaluation-context
                            :session session
                            :current-document document
                            :current-namespace consumer)))
    (set-default-evaluation-context producer-context)
    (install-core-builtins)
    (let* ((symbol (intern-autolisp-symbol "EXPORTED-FN"))
           (export-fn (find-core-builtin "VL-DOC-EXPORT"))
           (import-fn (find-core-builtin "VL-DOC-IMPORT"))
           (function (make-autolisp-subr "EXPORTED-FN" (lambda (x) (+ x 9)))))
      (set-autolisp-symbol-function symbol function)
      (is (eq symbol
              (call-autolisp-function export-fn symbol)))
      (set-default-evaluation-context consumer-context)
      (is (eq symbol
              (call-autolisp-function import-fn symbol)))
      (is (= 12
             (call-autolisp-function
              (autolisp-symbol-function symbol)
              3))))))

(test builtin-document-import-by-application
  (reset-autolisp-symbol-table)
  (let* ((document (make-document-namespace :name "DRAWING-DOC"))
         (producer (clautolisp.autolisp-runtime:make-separate-vlx-namespace
                    :name "PRODUCER"))
         (consumer (clautolisp.autolisp-runtime:make-separate-vlx-namespace
                    :name "CONSUMER"))
         (session (make-runtime-session :current-document document))
         (producer-context (make-evaluation-context
                            :session session
                            :current-document document
                            :current-namespace producer))
         (consumer-context (make-evaluation-context
                            :session session
                            :current-document document
                            :current-namespace consumer)))
    (register-runtime-session-vlx-namespace session producer)
    (register-runtime-session-vlx-namespace session consumer)
    (set-default-evaluation-context producer-context)
    (install-core-builtins)
    (let* ((symbol-a (intern-autolisp-symbol "APP-FN-A"))
           (symbol-b (intern-autolisp-symbol "APP-FN-B"))
           (export-fn (find-core-builtin "VL-DOC-EXPORT"))
           (import-fn (find-core-builtin "VL-DOC-IMPORT"))
           (function-a (make-autolisp-subr "APP-FN-A" (lambda (x) (+ x 1))))
           (function-b (make-autolisp-subr "APP-FN-B" (lambda (x) (+ x 2)))))
      (set-autolisp-symbol-function symbol-a function-a)
      (set-autolisp-symbol-function symbol-b function-b)
      (call-autolisp-function export-fn symbol-a)
      (call-autolisp-function export-fn symbol-b)
      (set-default-evaluation-context consumer-context)
      (is (equal '("APP-FN-A" "APP-FN-B")
                 (sort (mapcar #'autolisp-symbol-name
                               (call-autolisp-function import-fn
                                                       (make-autolisp-string "PRODUCER")))
                       #'string<)))
      (is (= 8
             (call-autolisp-function
              (autolisp-symbol-function symbol-a)
              7)))
      (is (= 9
             (call-autolisp-function
              (autolisp-symbol-function symbol-b)
              7))))))

(test builtin-defun-q-list-ref-and-set
  (reset-autolisp-symbol-table)
  (install-core-builtins)
  (let* ((defun-q-symbol (intern-autolisp-symbol "DEFUN-Q"))
         (plus-symbol (intern-autolisp-symbol "+"))
         (name (intern-autolisp-symbol "ADDQ"))
         (arg (intern-autolisp-symbol "X"))
         (list-ref-fn (autolisp-symbol-function
                       (find-autolisp-symbol "DEFUN-Q-LIST-REF")))
         (list-set-fn (autolisp-symbol-function
                       (find-autolisp-symbol "DEFUN-Q-LIST-SET"))))
    (set-autolisp-symbol-function plus-symbol
                                  (find-core-builtin "+"))
    (autolisp-eval
     (list defun-q-symbol
           name
           (list arg)
           (list plus-symbol arg 2)))
    (is (equal (list (list arg)
                     (list plus-symbol arg 2))
               (call-autolisp-function list-ref-fn name)))
    (is (eq name
            (call-autolisp-function list-set-fn
                                    name
                                    (list (list arg)
                                          (list plus-symbol arg 5)))))
    (is (= 12 (autolisp-eval (list name 7))))
    (is (equal (list (list arg)
                     (list plus-symbol arg 5))
               (call-autolisp-function list-ref-fn name)))))

(test builtin-car-cdr-cons-list
  (reset-autolisp-symbol-table)
  (install-core-builtins)
  (let* ((car-fn (autolisp-symbol-function (find-autolisp-symbol "CAR")))
         (cdr-fn (autolisp-symbol-function (find-autolisp-symbol "CDR")))
         (cons-fn (autolisp-symbol-function (find-autolisp-symbol "CONS")))
         (list-fn (autolisp-symbol-function (find-autolisp-symbol "LIST"))))
    (is (eql 1 (call-autolisp-function car-fn '(1 2 3))))
    (is (equal '(2 3) (call-autolisp-function cdr-fn '(1 2 3))))
    (is (equal '(1 2 3) (call-autolisp-function cons-fn 1 '(2 3))))
    (is (equal '(1 . 2) (call-autolisp-function cons-fn 1 2)))
    (is (equal '(1 2 3) (call-autolisp-function list-fn 1 2 3)))
    (is (null (call-autolisp-function list-fn)))))

(test builtin-append-length-nth-reverse
  (reset-autolisp-symbol-table)
  (install-core-builtins)
  (let* ((append-fn (autolisp-symbol-function (find-autolisp-symbol "APPEND")))
         (length-fn (autolisp-symbol-function (find-autolisp-symbol "LENGTH")))
         (nth-fn (autolisp-symbol-function (find-autolisp-symbol "NTH")))
         (reverse-fn (autolisp-symbol-function (find-autolisp-symbol "REVERSE"))))
    (is (null (call-autolisp-function append-fn)))
    (is (equal '(1 2 3 4) (call-autolisp-function append-fn '(1 2) '(3 4))))
    (is (equal '(1 2 . 3) (call-autolisp-function append-fn '(1 2) 3)))
    (is (= 3 (call-autolisp-function length-fn '(1 2 3))))
    (is (eql 30 (call-autolisp-function nth-fn 2 '(10 20 30 40))))
    (is (null (call-autolisp-function nth-fn 9 '(10 20 30 40))))
    (is (equal '(3 2 1) (call-autolisp-function reverse-fn '(1 2 3))))))

(test builtin-assoc
  (reset-autolisp-symbol-table)
  (install-core-builtins)
  (let* ((assoc-fn (autolisp-symbol-function (find-autolisp-symbol "ASSOC")))
         (foo (intern-autolisp-symbol "FOO"))
         (bar (intern-autolisp-symbol "BAR")))
    (is (equal '(1 . 2)
               (call-autolisp-function assoc-fn 1 '((0 . 1) (1 . 2) (2 . 3)))))
    (let* ((alist (list (cons bar 1) (cons foo 2)))
           (result (call-autolisp-function assoc-fn foo alist)))
      (is (eq result (second alist))
          "Symbol lookup is name-based and returns the matching alist entry."))
    (let* ((string-key-1 (clautolisp.autolisp-runtime:autolisp-read-from-string "\"foo\""))
           (string-key-2 (clautolisp.autolisp-runtime:autolisp-read-from-string "\"foo\""))
           (result (call-autolisp-function assoc-fn string-key-2
                                           (list (cons string-key-1 1)))))
      (is (consp result))
      (is (typep (car result) 'autolisp-string))
      (is (string= "foo" (autolisp-string-value (car result))))
      (is (= 1 (cdr result))))))

(test builtin-last-and-member
  (reset-autolisp-symbol-table)
  (install-core-builtins)
  (let* ((last-fn (autolisp-symbol-function (find-autolisp-symbol "LAST")))
         (member-fn (autolisp-symbol-function (find-autolisp-symbol "MEMBER")))
         (foo (intern-autolisp-symbol "FOO"))
         (bar (intern-autolisp-symbol "BAR")))
    (is (null (call-autolisp-function last-fn nil)))
    (is (eql 'e (call-autolisp-function last-fn '(a b c d e))))
    (is (equal '(d e) (call-autolisp-function last-fn '(a b c (d e)))))
    (is (equal '(c d e) (call-autolisp-function member-fn 'c '(a b c d e))))
    (is (null (call-autolisp-function member-fn 'q '(a b c d e))))
    (is (equal (list foo bar)
               (call-autolisp-function member-fn foo (list foo bar))))))

(test builtin-subst
  (reset-autolisp-symbol-table)
  (install-core-builtins)
  (let* ((subst-fn (autolisp-symbol-function (find-autolisp-symbol "SUBST")))
         (foo-1 (intern-autolisp-symbol "FOO"))
         (bar (intern-autolisp-symbol "BAR"))
         (string-old-1 (clautolisp.autolisp-runtime:autolisp-read-from-string "\"old\""))
         (string-old-2 (clautolisp.autolisp-runtime:autolisp-read-from-string "\"old\""))
         (string-new (clautolisp.autolisp-runtime:autolisp-read-from-string "\"new\"")))
    (is (equal '(a qq (c d) qq)
               (call-autolisp-function subst-fn 'qq 'b '(a b (c d) b))))
    (is (equal '(a b (qq rr) b)
               (call-autolisp-function subst-fn '(qq rr) '(c d) '(a b (c d) b))))
    (is (eq bar (call-autolisp-function subst-fn bar foo-1 foo-1)))
    (let ((result (call-autolisp-function subst-fn string-new string-old-2
                                          (list string-old-1 1))))
      (is (typep (first result) 'autolisp-string))
      (is (string= "new" (autolisp-string-value (first result)))))))

(test builtin-listp-and-vl-consp
  (reset-autolisp-symbol-table)
  (install-core-builtins)
  (let* ((listp-fn (autolisp-symbol-function (find-autolisp-symbol "LISTP")))
         (vl-consp-fn (autolisp-symbol-function (find-autolisp-symbol "VL-CONSP"))))
    (is (string= "T" (autolisp-symbol-name (call-autolisp-function listp-fn '(a b c)))))
    (is (string= "T" (autolisp-symbol-name (call-autolisp-function listp-fn nil))))
    (is (null (call-autolisp-function listp-fn 'a)))
    (is (string= "T" (autolisp-symbol-name (call-autolisp-function vl-consp-fn '(a b c)))))
    (is (string= "T" (autolisp-symbol-name (call-autolisp-function vl-consp-fn '(a . b)))))
    (is (null (call-autolisp-function vl-consp-fn nil)))
    (is (null (call-autolisp-function vl-consp-fn 'a)))))

(test builtin-vl-list*
  (reset-autolisp-symbol-table)
  (install-core-builtins)
  (let ((fn (autolisp-symbol-function (find-autolisp-symbol "VL-LIST*"))))
    (is (eql 1 (call-autolisp-function fn 1)))
    (is (equal '(1 . 2) (call-autolisp-function fn 1 2)))
    (is (equal '(1 2 . 3) (call-autolisp-function fn 1 2 3)))
    (is (equal '(1 2 3 4) (call-autolisp-function fn 1 2 '(3 4))))
    (is (equal '((a) b c) (call-autolisp-function fn '(a) 'b '(c))))))

(test builtin-number-and-comparison-predicates
  (reset-autolisp-symbol-table)
  (install-core-builtins)
  (let* ((numberp-fn (autolisp-symbol-function (find-autolisp-symbol "NUMBERP")))
         (=-fn (autolisp-symbol-function (find-autolisp-symbol "=")))
         (/=-fn (autolisp-symbol-function (find-autolisp-symbol "/=")))
         (zerop-fn (autolisp-symbol-function (find-autolisp-symbol "ZEROP")))
         (minusp-fn (autolisp-symbol-function (find-autolisp-symbol "MINUSP")))
         (foo-string-1 (clautolisp.autolisp-runtime:autolisp-read-from-string "\"foo\""))
         (foo-string-2 (clautolisp.autolisp-runtime:autolisp-read-from-string "\"foo\""))
         (bar-string (clautolisp.autolisp-runtime:autolisp-read-from-string "\"bar\"")))
    (is (string= "T" (autolisp-symbol-name (call-autolisp-function numberp-fn 1))))
    (is (string= "T" (autolisp-symbol-name (call-autolisp-function numberp-fn 1.0d0))))
    (is (null (call-autolisp-function numberp-fn foo-string-1)))
    (is (string= "T" (autolisp-symbol-name (call-autolisp-function =-fn 1 1 1))))
    (is (null (call-autolisp-function =-fn 1 2)))
    (is (string= "T" (autolisp-symbol-name (call-autolisp-function =-fn foo-string-1 foo-string-2))))
    (is (null (call-autolisp-function =-fn foo-string-1 bar-string)))
    (is (string= "T" (autolisp-symbol-name (call-autolisp-function /=-fn 1 2 3))))
    (is (null (call-autolisp-function /=-fn 1 2 1)))
    (is (string= "T" (autolisp-symbol-name (call-autolisp-function /=-fn foo-string-1 bar-string))))
    (is (string= "T" (autolisp-symbol-name (call-autolisp-function zerop-fn 0))))
    (is (null (call-autolisp-function zerop-fn 7)))
    (is (string= "T" (autolisp-symbol-name (call-autolisp-function minusp-fn -3))))
    (is (null (call-autolisp-function minusp-fn 0)))))

(test builtin-ordered-comparisons-and-numeric-conversions
  (reset-autolisp-symbol-table)
  (install-core-builtins)
  (let* ((<-fn (autolisp-symbol-function (find-autolisp-symbol "<")))
         (<=-fn (autolisp-symbol-function (find-autolisp-symbol "<=")))
         (>-fn (autolisp-symbol-function (find-autolisp-symbol ">")))
         (>=-fn (autolisp-symbol-function (find-autolisp-symbol ">=")))
         (abs-fn (autolisp-symbol-function (find-autolisp-symbol "ABS")))
         (fix-fn (autolisp-symbol-function (find-autolisp-symbol "FIX")))
         (float-fn (autolisp-symbol-function (find-autolisp-symbol "FLOAT"))))
    (is (string= "T" (autolisp-symbol-name (call-autolisp-function <-fn 1 2 3))))
    (is (null (call-autolisp-function <-fn 1 3 2)))
    (is (string= "T" (autolisp-symbol-name (call-autolisp-function <=-fn 1 1 2))))
    (is (string= "T" (autolisp-symbol-name (call-autolisp-function >-fn 3 2 1))))
    (is (null (call-autolisp-function >-fn 3 3 1)))
    (is (string= "T" (autolisp-symbol-name (call-autolisp-function >=-fn 3 3 1))))
    (is (= 7 (call-autolisp-function abs-fn -7)))
    (is (= 2.5d0 (call-autolisp-function abs-fn -2.5d0)))
    (is (= 12 (call-autolisp-function fix-fn 12.75d0)))
    (is (= -12 (call-autolisp-function fix-fn -12.75d0)))
    (is (typep (call-autolisp-function float-fn 7) 'double-float))
    (is (= 7.0d0 (call-autolisp-function float-fn 7)))
    (is (= 3.5d0 (call-autolisp-function float-fn 3.5d0)))))

(test builtin-string-primitives
  (reset-autolisp-symbol-table)
  (install-core-builtins)
  (let* ((strcat-fn (autolisp-symbol-function (find-autolisp-symbol "STRCAT")))
         (strlen-fn (autolisp-symbol-function (find-autolisp-symbol "STRLEN")))
         (substr-fn (autolisp-symbol-function (find-autolisp-symbol "SUBSTR")))
         (ascii-fn (autolisp-symbol-function (find-autolisp-symbol "ASCII")))
         (chr-fn (autolisp-symbol-function (find-autolisp-symbol "CHR")))
         (hello (clautolisp.autolisp-runtime:make-autolisp-string "Hello"))
         (space (clautolisp.autolisp-runtime:make-autolisp-string " "))
         (world (clautolisp.autolisp-runtime:make-autolisp-string "World"))
         (empty (clautolisp.autolisp-runtime:make-autolisp-string "")))
    (is (string= "" (autolisp-string-value (call-autolisp-function strcat-fn))))
    (is (string= "Hello World"
                 (autolisp-string-value
                  (call-autolisp-function strcat-fn hello space world))))
    (is (= 0 (call-autolisp-function strlen-fn)))
    (is (= 0 (call-autolisp-function strlen-fn empty)))
    (is (= 10 (call-autolisp-function strlen-fn hello world)))
    (is (string= "Hello"
                 (autolisp-string-value
                  (call-autolisp-function substr-fn hello 1))))
    (is (string= "ell"
                 (autolisp-string-value
                  (call-autolisp-function substr-fn hello 2 3))))
    (is (string= ""
                 (autolisp-string-value
                  (call-autolisp-function substr-fn hello 10))))
    (is (= 72 (call-autolisp-function ascii-fn hello)))
    (is (string= "A"
                 (autolisp-string-value
                  (call-autolisp-function chr-fn 65))))))

(test builtin-read
  (reset-autolisp-symbol-table)
  (install-core-builtins)
  (let ((read-fn (autolisp-symbol-function (find-autolisp-symbol "READ"))))
    (is (= 42
           (call-autolisp-function read-fn
                                   (make-autolisp-string "42"))))
    (let ((result (call-autolisp-function read-fn
                                          (make-autolisp-string "\"hello\""))))
      (is (typep result 'autolisp-string))
      (is (string= "hello" (autolisp-string-value result))))
    (let ((result (call-autolisp-function read-fn
                                          (make-autolisp-string "(a 1 \"x\")"))))
      (is (consp result))
      (is (typep (first result) 'autolisp-symbol))
      (is (string= "A" (autolisp-symbol-name (first result))))
      (is (= 1 (second result)))
      (is (typep (third result) 'autolisp-string))
      (is (string= "x" (autolisp-string-value (third result)))))
    (let ((result (call-autolisp-function read-fn
                                          (make-autolisp-string "'foo"))))
      (is (equal 2 (length result)))
      (is (typep (first result) 'autolisp-symbol))
      (is (string= "QUOTE" (autolisp-symbol-name (first result))))
      (is (typep (second result) 'autolisp-symbol))
      (is (string= "FOO" (autolisp-symbol-name (second result)))))))

(test builtin-load-and-error-hooks
  (reset-autolisp-symbol-table)
  (install-core-builtins)
  (let* ((load-fn (autolisp-symbol-function (find-autolisp-symbol "LOAD")))
         (loaded (intern-autolisp-symbol "LOADED"))
         (fallback-symbol (intern-autolisp-symbol "LOAD-FALLBACK"))
         (error-symbol (intern-autolisp-symbol "*ERROR*"))
         (path (merge-pathnames
                (format nil "autoload-~36R.lsp" (random (expt 36 6)))
                (uiop:temporary-directory)))
         (missing (make-autolisp-string
                   (namestring
                    (merge-pathnames "missing-load-file.lsp"
                                     (uiop:temporary-directory))))))
    (unwind-protect
         (progn
           (with-open-file (stream path
                                   :direction :output
                                   :if-exists :supersede
                                   :if-does-not-exist :create)
             (write-line "(setq loaded 5)" stream)
             (write-line "loaded" stream))
           (is (= 5
                  (call-autolisp-function load-fn
                                          (make-autolisp-string (namestring path)))))
           (is (= 5 (autolisp-symbol-value loaded)))
           (is (= 42
                  (call-autolisp-function load-fn
                                          missing
                                          42)))
           (set-autolisp-symbol-function
            fallback-symbol
            (make-autolisp-subr
             "LOAD-FALLBACK"
             (lambda ()
               99)))
           (is (= 99
                  (call-autolisp-function load-fn
                                          missing
                                          fallback-symbol)))
           (set-autolisp-symbol-function
            error-symbol
            (make-autolisp-subr
             "*ERROR*"
             (lambda (message)
               message)))
           (let ((result (call-autolisp-function load-fn missing)))
             (is (typep result 'autolisp-string))
             (is (search "LOAD could not locate"
                         (autolisp-string-value result)))))
      (when (probe-file path)
        (delete-file path)))))

(test builtin-autoload
  (reset-autolisp-symbol-table)
  (install-core-builtins)
  (let* ((autoload-fn (autolisp-symbol-function (find-autolisp-symbol "AUTOLOAD")))
         (target (intern-autolisp-symbol "AUTOLOAD-TARGET"))
         (path (merge-pathnames
                (format nil "autoload-target-~36R.lsp" (random (expt 36 6)))
                (uiop:temporary-directory))))
    (unwind-protect
         (progn
           (with-open-file (stream path
                                   :direction :output
                                   :if-exists :supersede
                                   :if-does-not-exist :create)
             (write-line "(defun autoload-target (x) (+ x 1))" stream))
           (is (null
                (call-autolisp-function autoload-fn
                                        (make-autolisp-string (namestring path))
                                        (list (make-autolisp-string "AUTOLOAD-TARGET")))))
           (is (= 5 (autolisp-eval (list target 4)))))
      (when (probe-file path)
        (delete-file path)))))

(test builtin-vl-catch-all-family
  (reset-autolisp-symbol-table)
  (install-core-builtins)
  (let* ((apply-fn (autolisp-symbol-function
                    (find-autolisp-symbol "VL-CATCH-ALL-APPLY")))
         (error-p-fn (autolisp-symbol-function
                      (find-autolisp-symbol "VL-CATCH-ALL-ERROR-P")))
         (message-fn (autolisp-symbol-function
                      (find-autolisp-symbol "VL-CATCH-ALL-ERROR-MESSAGE")))
         (car-symbol (intern-autolisp-symbol "CAR"))
         (list-symbol (intern-autolisp-symbol "LIST"))
         (open-symbol (intern-autolisp-symbol "OPEN")))
    (let ((success (call-autolisp-function apply-fn list-symbol '(1 2 3))))
      (is (equal '(1 2 3) success))
      (is (= 0 (autolisp-errno)))
      (is (null (call-autolisp-function error-p-fn success))))
    (let ((failure (call-autolisp-function apply-fn car-symbol '(42))))
      (is (= 4 (autolisp-errno)))
      (is (string= "T"
                   (autolisp-symbol-name
                    (call-autolisp-function error-p-fn failure))))
      (let ((message (call-autolisp-function message-fn failure)))
        (is (typep message 'autolisp-string))
        (is (> (length (autolisp-string-value message)) 0))))
    (let ((failure (call-autolisp-function
                    apply-fn
                    open-symbol
                    (list (make-autolisp-string "/tmp/unused")
                          (make-autolisp-string "bad-mode")))))
      (is (= 5 (autolisp-errno)))
      (is (string= "T"
                   (autolisp-symbol-name
                    (call-autolisp-function error-p-fn failure)))))
    (let ((failure (call-autolisp-function
                    apply-fn
                    (make-autolisp-subr "BROKEN"
                                        (lambda ()
                                          (error "Broken host subr.")))
                    nil)))
      (is (= 6 (autolisp-errno)))
      (is (string= "T"
                   (autolisp-symbol-name
                    (call-autolisp-function error-p-fn failure)))))
    (set-autolisp-errno 7)
    (handler-case
        (progn
          (call-autolisp-function apply-fn
                                  (intern-autolisp-symbol "EXIT")
                                  nil)
          (is nil))
      (autolisp-termination (condition)
        (is (eq :exit (autolisp-termination-kind condition)))
        (is (= 7 (autolisp-errno)))))
    (handler-case
        (progn
          (call-autolisp-function apply-fn
                                  (intern-autolisp-symbol "VL-EXIT-WITH-VALUE")
                                  (list 42))
          (is nil))
      (autolisp-namespace-exit (condition)
        (is (eq :value (autolisp-namespace-exit-kind condition)))
        (is (= 42 (autolisp-namespace-exit-value condition)))
        (is (= 7 (autolisp-errno)))))))

(test builtin-mapcar
  (reset-autolisp-symbol-table)
  (install-core-builtins)
  (let* ((mapcar-fn (autolisp-symbol-function (find-autolisp-symbol "MAPCAR")))
         (one-plus (intern-autolisp-symbol "1+"))
         (plus (intern-autolisp-symbol "+"))
         (lambda-symbol (intern-autolisp-symbol "LAMBDA"))
         (arg (intern-autolisp-symbol "X")))
    (is (equal '(11 21 31)
               (call-autolisp-function mapcar-fn one-plus '(10 20 30))))
    (is (equal '(13 23 33)
               (call-autolisp-function
                mapcar-fn
                (list lambda-symbol
                      (list arg)
                      (list plus arg 3))
                '(10 20 30))))
    (is (equal '(11 22)
               (call-autolisp-function
                mapcar-fn
                plus
                '(1 2)
                '(10 20 30))))))

(test builtin-visual-lisp-functional-list-operators
  (reset-autolisp-symbol-table)
  (install-core-builtins)
  (let* ((vl-every-fn (autolisp-symbol-function (find-autolisp-symbol "VL-EVERY")))
         (vl-some-fn (autolisp-symbol-function (find-autolisp-symbol "VL-SOME")))
         (vl-member-if-fn (autolisp-symbol-function (find-autolisp-symbol "VL-MEMBER-IF")))
         (vl-member-if-not-fn (autolisp-symbol-function (find-autolisp-symbol "VL-MEMBER-IF-NOT")))
         (vl-remove-if-fn (autolisp-symbol-function (find-autolisp-symbol "VL-REMOVE-IF")))
         (vl-remove-if-not-fn (autolisp-symbol-function (find-autolisp-symbol "VL-REMOVE-IF-NOT")))
         (zerop-symbol (intern-autolisp-symbol "ZEROP"))
         (minusp-symbol (intern-autolisp-symbol "MINUSP"))
         (lambda-symbol (intern-autolisp-symbol "LAMBDA"))
         (function-symbol (intern-autolisp-symbol "FUNCTION"))
         (plus-symbol (intern-autolisp-symbol "+"))
         (greater-than-symbol (intern-autolisp-symbol ">"))
         (x (intern-autolisp-symbol "X"))
         (y (intern-autolisp-symbol "Y"))
         (quoted-lambda (list (intern-autolisp-symbol "QUOTE")
                              (list lambda-symbol
                                    (list x)
                                    (list greater-than-symbol x 0))))
         (if-symbol (intern-autolisp-symbol "IF"))
         (function-lambda (list function-symbol
                                (list lambda-symbol
                                      (list x y)
                                      (list if-symbol
                                            (list greater-than-symbol x 2)
                                            (list plus-symbol x y)
                                            nil)))))
    (is (string= "T"
                 (autolisp-symbol-name
                  (call-autolisp-function vl-every-fn
                                          quoted-lambda
                                          '(1 2 3)))))
    (is (null (call-autolisp-function vl-every-fn
                                      minusp-symbol
                                      '(1 -2 -3))))
    (is (= 33
           (call-autolisp-function vl-some-fn
                                   function-lambda
                                   '(0 0 3)
                                   '(10 20 30))))
    (is (null (call-autolisp-function vl-some-fn
                                      zerop-symbol
                                      '(1 2 3))))
    (is (equal '(0 1 2)
               (call-autolisp-function vl-member-if-fn
                                       zerop-symbol
                                       '(3 2 0 1 2))))
    (is (equal '(1 2 3)
               (call-autolisp-function vl-member-if-not-fn
                                       minusp-symbol
                                       '(1 2 3))))
    (is (equal '(1 2 3)
               (call-autolisp-function vl-remove-if-fn
                                       zerop-symbol
                                       '(0 1 0 2 3 0))))
    (is (equal '(0 0 0)
               (call-autolisp-function vl-remove-if-not-fn
                                       zerop-symbol
                                       '(0 1 0 2 3 0))))))

(test builtin-mapcar-uses-active-evaluation-context
  (reset-autolisp-symbol-table)
  (install-core-builtins)
  (let* ((default-document (make-document-namespace :name "DEFAULT-DOC"))
         (default-context (make-evaluation-context
                           :session (make-runtime-session :current-document default-document)
                           :current-document default-document
                           :current-namespace default-document))
         (runtime-document (make-document-namespace :name "RUNTIME-DOC"))
         (runtime-context (make-evaluation-context
                           :session (make-runtime-session :current-document runtime-document)
                           :current-document runtime-document
                           :current-namespace runtime-document))
         (mapcar-symbol (intern-autolisp-symbol "MAPCAR"))
         (inc-symbol (intern-autolisp-symbol "INC")))
    (set-default-evaluation-context default-context)
    (dolist (builtin (core-builtins))
      (set-function (intern-autolisp-symbol (autolisp-subr-name builtin))
                    builtin
                    runtime-context))
    (set-function inc-symbol
                  (make-autolisp-subr "INC" (lambda (value) (+ value 1)))
                  runtime-context)
    (is (equal '(2 3 4)
               (autolisp-eval
                (list mapcar-symbol
                      (list (intern-autolisp-symbol "QUOTE") inc-symbol)
                      (list (intern-autolisp-symbol "QUOTE") '(1 2 3)))
                runtime-context)))))

(test builtin-exit-quit-and-namespace-bridge
  (reset-autolisp-symbol-table)
  (install-core-builtins)
  (let ((exit-fn (autolisp-symbol-function (find-autolisp-symbol "EXIT")))
        (quit-fn (autolisp-symbol-function (find-autolisp-symbol "QUIT")))
        (exit-error-fn (autolisp-symbol-function (find-autolisp-symbol "VL-EXIT-WITH-ERROR")))
        (exit-value-fn (autolisp-symbol-function (find-autolisp-symbol "VL-EXIT-WITH-VALUE"))))
    (handler-case
        (progn
          (call-autolisp-function exit-fn)
          (is nil))
      (autolisp-termination (condition)
        (is (eq :exit (autolisp-termination-kind condition)))))
    (handler-case
        (progn
          (call-autolisp-function quit-fn)
          (is nil))
      (autolisp-termination (condition)
        (is (eq :quit (autolisp-termination-kind condition)))))
    (handler-case
        (progn
          (call-autolisp-function exit-error-fn (make-autolisp-string "bridge-error"))
          (is nil))
      (autolisp-namespace-exit (condition)
        (is (eq :error (autolisp-namespace-exit-kind condition)))
        (is (string= "bridge-error" (autolisp-namespace-exit-value condition)))))
    (handler-case
        (progn
          (call-autolisp-function exit-value-fn 42)
          (is nil))
      (autolisp-namespace-exit (condition)
        (is (eq :value (autolisp-namespace-exit-kind condition)))
        (is (= 42 (autolisp-namespace-exit-value condition)))))))

(test builtin-load-error-hook-can-transfer-control
  (reset-autolisp-symbol-table)
  (install-core-builtins)
  (let* ((load-fn (autolisp-symbol-function (find-autolisp-symbol "LOAD")))
         (error-symbol (intern-autolisp-symbol "*ERROR*"))
         (missing (make-autolisp-string
                   (namestring
                    (merge-pathnames "missing-load-file.lsp"
                                     (uiop:temporary-directory))))))
    (set-autolisp-symbol-function
     error-symbol
     (make-autolisp-subr
      "*ERROR*"
      (lambda (message)
        (declare (ignore message))
        (error 'autolisp-termination :kind :quit))))
    (handler-case
        (progn
          (call-autolisp-function load-fn missing)
          (is nil))
      (autolisp-termination (condition)
        (is (eq :quit (autolisp-termination-kind condition)))))))

(test builtin-file-primitives
  (reset-autolisp-symbol-table)
  (install-core-builtins)
  (let* ((open-fn (autolisp-symbol-function (find-autolisp-symbol "OPEN")))
         (close-fn (autolisp-symbol-function (find-autolisp-symbol "CLOSE")))
         (read-line-fn (autolisp-symbol-function (find-autolisp-symbol "READ-LINE")))
         (read-char-fn (autolisp-symbol-function (find-autolisp-symbol "READ-CHAR")))
         (write-line-fn (autolisp-symbol-function (find-autolisp-symbol "WRITE-LINE")))
         (write-char-fn (autolisp-symbol-function (find-autolisp-symbol "WRITE-CHAR")))
         (findfile-fn (autolisp-symbol-function (find-autolisp-symbol "FINDFILE")))
         (findtrustedfile-fn (autolisp-symbol-function (find-autolisp-symbol "FINDTRUSTEDFILE")))
         (directory (format nil "/tmp/clautolisp-builtins-core-~D/" (random 1000000000)))
         (relative-name "sample.txt")
         (encoded-name "encoded.txt")
         (trusted-name "trusted.txt")
         (path (concatenate 'string directory relative-name))
         (trusted-path (concatenate 'string directory trusted-name))
         (resolved-path nil)
         (resolved-trusted-path nil)
         (path-string (clautolisp.autolisp-runtime:make-autolisp-string relative-name))
         (encoded-path-string (clautolisp.autolisp-runtime:make-autolisp-string encoded-name))
         (write-mode (clautolisp.autolisp-runtime:make-autolisp-string "w"))
         (read-mode (clautolisp.autolisp-runtime:make-autolisp-string "r"))
         (utf-8-format (clautolisp.autolisp-runtime:make-autolisp-string "utf-8")))
    (flet ((expect-file-error (thunk expected-code expected-builtin)
             (handler-case
                 (progn
                   (funcall thunk)
                   (is nil))
               (autolisp-runtime-error (condition)
                 (is (eq expected-code
                         (autolisp-runtime-error-code condition)))
                 (is (string= expected-builtin
                              (getf (autolisp-runtime-error-details condition)
                                    :builtin)))))))
    (ignore-errors (uiop:delete-directory-tree directory :validate t))
    (ensure-directories-exist directory)
    (set-autolisp-current-directory directory)
    (set-autolisp-support-paths (list directory))
    (set-autolisp-trusted-paths (list directory))
    (let ((file (call-autolisp-function open-fn path-string write-mode)))
      (is (typep file 'autolisp-file))
      (is (typep (call-autolisp-function write-line-fn
                                         (clautolisp.autolisp-runtime:make-autolisp-string "alpha")
                                         file)
                 'autolisp-string))
      (is (= 66 (call-autolisp-function write-char-fn 66 file)))
      (is (null (call-autolisp-function close-fn file))))
    (let ((file (call-autolisp-function open-fn path-string read-mode)))
      (is (typep file 'autolisp-file))
      (is (string= "alpha"
                   (autolisp-string-value
                    (call-autolisp-function read-line-fn file))))
      (is (= 66 (call-autolisp-function read-char-fn file)))
      (is (null (call-autolisp-function read-line-fn file)))
      (is (null (call-autolisp-function close-fn file))))
    (let ((file (call-autolisp-function open-fn path-string read-mode)))
      (is (typep file 'autolisp-file))
      (is (null (call-autolisp-function close-fn file)))
      (expect-file-error (lambda ()
                           (call-autolisp-function read-line-fn file))
                         :closed-file-descriptor
                         "READ-LINE")
      (expect-file-error (lambda ()
                           (call-autolisp-function read-char-fn file))
                         :closed-file-descriptor
                         "READ-CHAR"))
    (let ((file (call-autolisp-function open-fn path-string write-mode)))
      (is (typep file 'autolisp-file))
      (is (null (call-autolisp-function close-fn file)))
      (expect-file-error (lambda ()
                           (call-autolisp-function write-line-fn
                                                   (clautolisp.autolisp-runtime:make-autolisp-string "beta")
                                                   file))
                         :closed-file-descriptor
                         "WRITE-LINE")
      (expect-file-error (lambda ()
                           (call-autolisp-function write-char-fn 67 file))
                         :closed-file-descriptor
                         "WRITE-CHAR"))
    (expect-file-error (lambda ()
                         (call-autolisp-function write-char-fn -1))
                       :invalid-character-code
                       "WRITE-CHAR")
    (let* ((encoded-text
             (clautolisp.autolisp-runtime:make-autolisp-string
              (coerce (list #\H (code-char 233) #\!) 'string)))
           (file (call-autolisp-function open-fn encoded-path-string write-mode utf-8-format)))
      (is (typep file 'autolisp-file))
      (call-autolisp-function write-line-fn encoded-text file)
      (is (null (call-autolisp-function close-fn file))))
    (let ((file (call-autolisp-function open-fn encoded-path-string read-mode utf-8-format)))
      (is (typep file 'autolisp-file))
      (let ((line (call-autolisp-function read-line-fn file)))
        (is (typep line 'autolisp-string))
        (is (string= (coerce (list #\H (code-char 233) #\!) 'string)
                     (autolisp-string-value line))))
      (is (null (call-autolisp-function close-fn file))))
    (with-open-file (stream trusted-path
                            :direction :output
                            :if-exists :supersede
                            :if-does-not-exist :create)
      (write-line "trusted" stream))
    (setf resolved-path (namestring (probe-file path))
          resolved-trusted-path (namestring (probe-file trusted-path)))
    (is (string= resolved-path
                 (autolisp-string-value
                  (call-autolisp-function findfile-fn
                                          (clautolisp.autolisp-runtime:make-autolisp-string relative-name)))))
    (is (string= resolved-trusted-path
                 (autolisp-string-value
                  (call-autolisp-function findtrustedfile-fn
                                          (clautolisp.autolisp-runtime:make-autolisp-string trusted-name)))))
    (is (null (call-autolisp-function findfile-fn
                                      (clautolisp.autolisp-runtime:make-autolisp-string "missing.txt"))))
    (ignore-errors (uiop:delete-directory-tree directory :validate t)))))

(test builtin-vl-directory-and-filename-helpers
  (reset-autolisp-symbol-table)
  (install-core-builtins)
  (let* ((directory-files-fn
           (autolisp-symbol-function (find-autolisp-symbol "VL-DIRECTORY-FILES")))
         (file-directory-p-fn
           (autolisp-symbol-function (find-autolisp-symbol "VL-FILE-DIRECTORY-P")))
         (filename-base-fn
           (autolisp-symbol-function (find-autolisp-symbol "VL-FILENAME-BASE")))
         (filename-directory-fn
           (autolisp-symbol-function (find-autolisp-symbol "VL-FILENAME-DIRECTORY")))
         (filename-extension-fn
           (autolisp-symbol-function (find-autolisp-symbol "VL-FILENAME-EXTENSION")))
         (directory (format nil "/tmp/clautolisp-builtins-core-dir-~D/" (random 1000000000)))
         (subdirectory (concatenate 'string directory "subdir/"))
         (file-path (concatenate 'string directory "alpha.lsp"))
         (other-file-path (concatenate 'string directory "README"))
         (pattern-string (clautolisp.autolisp-runtime:make-autolisp-string "*.lsp")))
    (ignore-errors (uiop:delete-directory-tree directory :validate t))
    (ensure-directories-exist subdirectory)
    (with-open-file (stream file-path
                            :direction :output
                            :if-exists :supersede
                            :if-does-not-exist :create)
      (write-line "alpha" stream))
    (with-open-file (stream other-file-path
                            :direction :output
                            :if-exists :supersede
                            :if-does-not-exist :create)
      (write-line "readme" stream))
    (set-autolisp-current-directory directory)
    (let ((all-results (call-autolisp-function directory-files-fn))
          (file-results (call-autolisp-function directory-files-fn nil pattern-string 1))
          (directory-results (call-autolisp-function directory-files-fn nil nil -1)))
      (is (equal '("README" "alpha.lsp")
                 (sort (mapcar #'autolisp-string-value all-results) #'string<)))
      (is (equal '("alpha.lsp")
                 (mapcar #'autolisp-string-value file-results)))
      (is (equal '("subdir")
                 (mapcar #'autolisp-string-value directory-results))))
    (is (string= "T"
                 (autolisp-symbol-name
                  (call-autolisp-function file-directory-p-fn
                                          (clautolisp.autolisp-runtime:make-autolisp-string subdirectory)))))
    (is (null
         (call-autolisp-function file-directory-p-fn
                                 (clautolisp.autolisp-runtime:make-autolisp-string file-path))))
    (is (string= "alpha"
                 (autolisp-string-value
                  (call-autolisp-function filename-base-fn
                                          (clautolisp.autolisp-runtime:make-autolisp-string
                                           "dir\\alpha.lsp")))))
    (is (string= "dir"
                 (autolisp-string-value
                  (call-autolisp-function filename-directory-fn
                                          (clautolisp.autolisp-runtime:make-autolisp-string
                                           "dir\\alpha.lsp")))))
    (let ((extension
            (call-autolisp-function filename-extension-fn
                                    (clautolisp.autolisp-runtime:make-autolisp-string
                                     "dir/alpha.lsp"))))
      (is (typep extension 'autolisp-string))
      (is (string= ".lsp" (autolisp-string-value extension))))
    (is (null
         (call-autolisp-function filename-extension-fn
                                 (clautolisp.autolisp-runtime:make-autolisp-string
                                  "dir/README"))))
    (is (string= ""
                 (autolisp-string-value
                  (call-autolisp-function filename-directory-fn
                                          (clautolisp.autolisp-runtime:make-autolisp-string
                                           "alpha.lsp")))))
    (handler-case
        (progn
          (call-autolisp-function directory-files-fn nil nil 2)
          (is nil))
      (autolisp-runtime-error (condition)
        (is (eq :invalid-directory-selector
                (autolisp-runtime-error-code condition)))
        (is (string= "VL-DIRECTORY-FILES"
                     (getf (autolisp-runtime-error-details condition)
                           :builtin)))))
    (ignore-errors (uiop:delete-directory-tree directory :validate t))))

(test builtin-vl-file-mutation-and-size-helpers
  (reset-autolisp-symbol-table)
  (install-core-builtins)
  (let* ((file-delete-fn
           (autolisp-symbol-function (find-autolisp-symbol "VL-FILE-DELETE")))
         (file-rename-fn
           (autolisp-symbol-function (find-autolisp-symbol "VL-FILE-RENAME")))
         (file-size-fn
           (autolisp-symbol-function (find-autolisp-symbol "VL-FILE-SIZE")))
         (mkdir-fn
           (autolisp-symbol-function (find-autolisp-symbol "VL-MKDIR")))
         (directory (format nil "/tmp/clautolisp-builtins-core-file-~D/" (random 1000000000)))
         (subdirectory (concatenate 'string directory "created/"))
         (old-path (concatenate 'string directory "before.txt"))
         (new-path (concatenate 'string directory "after.txt")))
    (ignore-errors (uiop:delete-directory-tree directory :validate t))
    (ensure-directories-exist directory)
    (with-open-file (stream old-path
                            :direction :output
                            :if-exists :supersede
                            :if-does-not-exist :create)
      (write-string "ABCD" stream))
    (is (= 4
           (call-autolisp-function file-size-fn
                                   (clautolisp.autolisp-runtime:make-autolisp-string old-path))))
    (is (= 0
           (call-autolisp-function file-size-fn
                                   (clautolisp.autolisp-runtime:make-autolisp-string directory))))
    (is (null
         (call-autolisp-function file-size-fn
                                 (clautolisp.autolisp-runtime:make-autolisp-string
                                  (concatenate 'string directory "missing.txt")))))
    (let ((mkdir-result
            (call-autolisp-function mkdir-fn
                                    (clautolisp.autolisp-runtime:make-autolisp-string
                                     subdirectory))))
      (when mkdir-result
        (is (string= "T" (autolisp-symbol-name mkdir-result))))
      (is (probe-file subdirectory)))
    (is (null
         (call-autolisp-function mkdir-fn
                                 (clautolisp.autolisp-runtime:make-autolisp-string
                                  subdirectory))))
    (let ((rename-result
            (call-autolisp-function file-rename-fn
                                    (clautolisp.autolisp-runtime:make-autolisp-string old-path)
                                    (clautolisp.autolisp-runtime:make-autolisp-string new-path))))
      (when rename-result
        (is (string= "T" (autolisp-symbol-name rename-result)))))
    (is (null (probe-file old-path)))
    (is (probe-file new-path))
    (let ((delete-result
            (call-autolisp-function file-delete-fn
                                    (clautolisp.autolisp-runtime:make-autolisp-string new-path))))
      (when delete-result
        (is (string= "T" (autolisp-symbol-name delete-result)))))
    (is (null (probe-file new-path)))
    (is (null
         (call-autolisp-function file-delete-fn
                                 (clautolisp.autolisp-runtime:make-autolisp-string new-path))))
    (ignore-errors (uiop:delete-directory-tree directory :validate t))))

(test builtin-vl-file-copy-systime-and-mktemp
  (reset-autolisp-symbol-table)
  (install-core-builtins)
  (let* ((file-copy-fn
           (autolisp-symbol-function (find-autolisp-symbol "VL-FILE-COPY")))
         (file-systime-fn
           (autolisp-symbol-function (find-autolisp-symbol "VL-FILE-SYSTIME")))
         (mktemp-fn
           (autolisp-symbol-function (find-autolisp-symbol "VL-FILENAME-MKTEMP")))
         (directory (format nil "/tmp/clautolisp-builtins-core-copy-~D/" (random 1000000000)))
         (source-path (concatenate 'string directory "source.bin"))
         (destination-path (concatenate 'string directory "destination.bin"))
         (append-path (concatenate 'string directory "append.bin")))
    (ignore-errors (uiop:delete-directory-tree directory :validate t))
    (ensure-directories-exist directory)
    (with-open-file (stream source-path
                            :direction :output
                            :if-exists :supersede
                            :if-does-not-exist :create
                            :element-type '(unsigned-byte 8))
      (write-sequence #(1 2 3 4 5) stream))
    (with-open-file (stream append-path
                            :direction :output
                            :if-exists :supersede
                            :if-does-not-exist :create
                            :element-type '(unsigned-byte 8))
      (write-sequence #(7 8) stream))
    (let ((copy-result
            (call-autolisp-function file-copy-fn
                                    (clautolisp.autolisp-runtime:make-autolisp-string source-path)
                                    (clautolisp.autolisp-runtime:make-autolisp-string destination-path))))
      (when copy-result
        (is (= 5 copy-result))))
    (is (probe-file destination-path))
    (is (= 5
           (with-open-file (stream destination-path
                                   :direction :input
                                   :element-type '(unsigned-byte 8))
             (file-length stream))))
    (is (null
         (call-autolisp-function file-copy-fn
                                 (clautolisp.autolisp-runtime:make-autolisp-string source-path)
                                 (clautolisp.autolisp-runtime:make-autolisp-string destination-path))))
    (is (null
         (call-autolisp-function file-copy-fn
                                 (clautolisp.autolisp-runtime:make-autolisp-string source-path)
                                 (clautolisp.autolisp-runtime:make-autolisp-string directory))))
    (let ((append-result
            (call-autolisp-function file-copy-fn
                                    (clautolisp.autolisp-runtime:make-autolisp-string source-path)
                                    (clautolisp.autolisp-runtime:make-autolisp-string append-path)
                                    (intern-autolisp-symbol "T"))))
      (when append-result
        (is (= 5 append-result))))
    (is (= 7
           (with-open-file (stream append-path
                                   :direction :input
                                   :element-type '(unsigned-byte 8))
             (file-length stream))))
    (let ((systime
            (call-autolisp-function file-systime-fn
                                    (clautolisp.autolisp-runtime:make-autolisp-string
                                     source-path))))
      (is (listp systime))
      (is (= 7 (length systime)))
      (is (every #'integerp systime))
      (let ((write-date (file-write-date source-path)))
        (multiple-value-bind (second minute hour day month year common-lisp-day-of-week)
            (decode-universal-time write-date)
          (declare (ignore second minute hour day month year))
          (is (= (mod (1+ common-lisp-day-of-week) 7)
                 (third systime))))))
    (let* ((temp-name
             (call-autolisp-function mktemp-fn
                                     (clautolisp.autolisp-runtime:make-autolisp-string "foo-")
                                     (clautolisp.autolisp-runtime:make-autolisp-string directory)
                                     (clautolisp.autolisp-runtime:make-autolisp-string "tmp")))
           (temp-path (autolisp-string-value temp-name)))
      (is (typep temp-name 'autolisp-string))
      (is (search directory temp-path))
      (is (search "foo-" temp-path))
      (is (search ".tmp" temp-path))
      (is (null (probe-file temp-path))))
    (let* ((default-temp-name (call-autolisp-function mktemp-fn))
           (default-temp-path (autolisp-string-value default-temp-name)))
      (is (typep default-temp-name 'autolisp-string))
      (is (uiop:absolute-pathname-p (pathname default-temp-path)))
      (is (null (probe-file default-temp-path))))
    (ignore-errors (uiop:delete-directory-tree directory :validate t))))

(test builtin-printer-functions
  (reset-autolisp-symbol-table)
  (install-core-builtins)
  (let* ((prin1-fn (autolisp-symbol-function (find-autolisp-symbol "PRIN1")))
         (princ-fn (autolisp-symbol-function (find-autolisp-symbol "PRINC")))
         (print-fn (autolisp-symbol-function (find-autolisp-symbol "PRINT")))
         (terpri-fn (autolisp-symbol-function (find-autolisp-symbol "TERPRI")))
         (prompt-fn (autolisp-symbol-function (find-autolisp-symbol "PROMPT")))
         (vl-prin1-fn
           (autolisp-symbol-function (find-autolisp-symbol "VL-PRIN1-TO-STRING")))
         (vl-princ-fn
           (autolisp-symbol-function (find-autolisp-symbol "VL-PRINC-TO-STRING")))
         (read-char-fn (autolisp-symbol-function (find-autolisp-symbol "READ-CHAR")))
         (hello (make-autolisp-string "Hello"))
         (quoted (make-autolisp-string "a\\\"b"))
         (list-value (list 1 hello (intern-autolisp-symbol "T")))
         (directory (format nil "/tmp/clautolisp-builtins-core-print-~D/" (random 1000000000)))
         (path (concatenate 'string directory "output.txt"))
         (printed nil))
    (ignore-errors (uiop:delete-directory-tree directory :validate t))
    (ensure-directories-exist directory)
    (let ((result (call-autolisp-function vl-prin1-fn quoted)))
      (is (typep result 'autolisp-string))
      (is (string= "\"a\\\\\\\"b\"" (autolisp-string-value result))))
    (let ((result (call-autolisp-function vl-princ-fn quoted)))
      (is (typep result 'autolisp-string))
      (is (string= "a\\\"b" (autolisp-string-value result))))
    (let ((file (call-autolisp-function
                 (autolisp-symbol-function (find-autolisp-symbol "OPEN"))
                 (make-autolisp-string path)
                 (make-autolisp-string "w"))))
      (call-autolisp-function prin1-fn quoted file)
      ;; Use `(princ "\n" file)` instead of `(terpri file)`: AutoLISP
      ;; `terpri` is zero-arity (BricsCAD V26 product test, 2026-04-26;
      ;; spec entry for TERPRI).
      (call-autolisp-function princ-fn (make-autolisp-string (string #\Newline)) file)
      (call-autolisp-function princ-fn hello file)
      (call-autolisp-function print-fn list-value file)
      (call-autolisp-function (autolisp-symbol-function (find-autolisp-symbol "CLOSE")) file))
    (with-open-file (stream path :direction :input)
      (setf printed
            (with-output-to-string (out)
              (loop for line = (read-line stream nil nil)
                    while line
                    do (write-line line out)))))
    (is (search "\"a\\\\\\\"b\"" printed))
    (is (search "Hello" printed))
    (is (search "(1 \"Hello\" T)" printed))
    (let ((*standard-output* (make-string-output-stream)))
      (is (eq hello (call-autolisp-function princ-fn hello)))
      (is (null (call-autolisp-function prompt-fn hello)))
      (is (search "Hello"
                  (get-output-stream-string *standard-output*))))
    (let ((*standard-output* (make-string-output-stream)))
      (is (eq list-value (call-autolisp-function print-fn list-value)))
      (is (search "(1 \"Hello\" T)"
                  (get-output-stream-string *standard-output*))))
    (let ((*standard-input* (make-string-input-stream "Z")))
      (is (= 90 (call-autolisp-function read-char-fn))))
    (let ((file (call-autolisp-function
                 (autolisp-symbol-function (find-autolisp-symbol "OPEN"))
                 (make-autolisp-string path)
                 (make-autolisp-string "w"))))
      (call-autolisp-function
       (autolisp-symbol-function (find-autolisp-symbol "CLOSE")) file)
      (handler-case
          (progn
            (call-autolisp-function prin1-fn quoted file)
            (is nil))
        (autolisp-runtime-error (condition)
          (is (eq :closed-file-descriptor
                  (autolisp-runtime-error-code condition)))
          (is (string= "PRIN1"
                       (getf (autolisp-runtime-error-details condition)
                             :builtin))))))
    (ignore-errors (uiop:delete-directory-tree directory :validate t))))

(test builtin-terpri-is-zero-arity
  ;; AutoLISP `terpri` does not accept a file-handle argument. The
  ;; 2-argument form `(terpri stream)` raises "too few / too many
  ;; arguments at [TERPRI]" in BricsCAD V26 (Phase-5 product test,
  ;; 2026-04-26; spec entry TERPRI). The Common Lisp implementation
  ;; surface enforces this via the function arity itself.
  (reset-autolisp-symbol-table)
  (install-core-builtins)
  (let ((terpri-fn (autolisp-symbol-function (find-autolisp-symbol "TERPRI")))
        (*standard-output* (make-string-output-stream)))
    (is (null (call-autolisp-function terpri-fn)))
    ;; Calling with an extra argument must NOT silently succeed.
    ;; The exact host condition class (program-error /
    ;; autolisp-runtime-error / simple-error) depends on whether the
    ;; SUBR wrapper traps the host arity error, so we just assert that
    ;; *some* condition was signalled.
    (let ((signalled nil))
      (handler-case
          (call-autolisp-function terpri-fn (make-autolisp-string "stream"))
        (condition () (setf signalled t)))
      (is (eq t signalled)))))

(test builtin-print-trailing-space
  ;; AutoLISP `print` writes leading newline + prin1 form + trailing
  ;; SPACE (not a trailing newline). Confirmed by the BricsCAD V26
  ;; product test on 2026-04-26: print-string.txt was the literal
  ;; nine characters `\n"hello" `.
  (reset-autolisp-symbol-table)
  (install-core-builtins)
  (let* ((print-fn (autolisp-symbol-function (find-autolisp-symbol "PRINT")))
         (open-fn (autolisp-symbol-function (find-autolisp-symbol "OPEN")))
         (close-fn (autolisp-symbol-function (find-autolisp-symbol "CLOSE")))
         (directory (format nil "/tmp/clautolisp-print-frame-~D/" (random 1000000000)))
         (path (concatenate 'string directory "print.txt"))
         (hello (make-autolisp-string "hello"))
         contents)
    (ignore-errors (uiop:delete-directory-tree directory :validate t))
    (ensure-directories-exist directory)
    (let ((file (call-autolisp-function open-fn
                                        (make-autolisp-string path)
                                        (make-autolisp-string "w"))))
      (call-autolisp-function print-fn hello file)
      (call-autolisp-function close-fn file))
    (with-open-file (stream path :direction :input
                                 :element-type '(unsigned-byte 8))
      (let ((bytes (make-array 32 :element-type '(unsigned-byte 8) :fill-pointer 0)))
        (loop for byte = (read-byte stream nil nil)
              while byte
              do (vector-push-extend byte bytes))
        (setf contents
              (map 'string #'code-char (coerce bytes 'simple-vector)))))
    (is (string= (concatenate 'string (string #\Newline) "\"hello\" ") contents))
    (ignore-errors (uiop:delete-directory-tree directory :validate t))))

(test builtin-atoi-strtol-style
  ;; AutoLISP `atoi` follows a strtol(..., 10) C-style lex model.
  ;; Confirmed against BricsCAD V26 by the Phase-5 product test on
  ;; 2026-04-26 (results.sexp, suite "atoi"). Lex edges: skip leading
  ;; whitespace, accept optional sign, longest decimal-digit prefix,
  ;; trailing junk truncates, decimal-fraction truncates toward zero,
  ;; `0x`-prefix returns 0 (no hex auto-detect), leading-zero forms
  ;; are decimal (NOT octal).
  (reset-autolisp-symbol-table)
  (install-core-builtins)
  (let ((atoi-fn (autolisp-symbol-function (find-autolisp-symbol "ATOI"))))
    (is (= 17  (call-autolisp-function atoi-fn (make-autolisp-string "17"))))
    (is (= 17  (call-autolisp-function atoi-fn (make-autolisp-string "017"))))
    (is (= 0   (call-autolisp-function atoi-fn (make-autolisp-string "0xbabe"))))
    (is (= 17  (call-autolisp-function atoi-fn (make-autolisp-string "+17"))))
    (is (= -17 (call-autolisp-function atoi-fn (make-autolisp-string "-17"))))
    (is (= 17  (call-autolisp-function atoi-fn (make-autolisp-string "17x"))))
    (is (= 17  (call-autolisp-function atoi-fn (make-autolisp-string " 17"))))
    (is (= 3   (call-autolisp-function atoi-fn (make-autolisp-string "3.9"))))
    (is (= 0   (call-autolisp-function atoi-fn (make-autolisp-string "xyz"))))))

(test builtin-atof-strtod-style
  ;; AutoLISP `atof` follows a strtod-style lex model. Confirmed
  ;; against BricsCAD V26 by the Phase-5 product test on 2026-04-26.
  ;; This implementation deliberately omits C99 hex-float syntax
  ;; (BricsCAD V26 accepts `(atof "0x1p4") -> 16.0`, but the
  ;; clautolisp model is conservative). Decimal-comma is rejected
  ;; (no locale sensitivity).
  (reset-autolisp-symbol-table)
  (install-core-builtins)
  (let ((atof-fn (autolisp-symbol-function (find-autolisp-symbol "ATOF"))))
    (is (= 3.5d0    (call-autolisp-function atof-fn (make-autolisp-string "3.5"))))
    (is (= 0.5d0    (call-autolisp-function atof-fn (make-autolisp-string ".5"))))
    (is (= 1.0d0    (call-autolisp-function atof-fn (make-autolisp-string "1."))))
    (is (= 1000.0d0 (call-autolisp-function atof-fn (make-autolisp-string "1e3"))))
    (is (= 17.0d0   (call-autolisp-function atof-fn (make-autolisp-string "017"))))
    (is (= 3.0d0    (call-autolisp-function atof-fn (make-autolisp-string "3,5"))))
    (is (= 3.5d0    (call-autolisp-function atof-fn (make-autolisp-string " 3.5"))))
    (is (= 0.0d0    (call-autolisp-function atof-fn (make-autolisp-string "xyz"))))
    ;; Conservative-clautolisp choice: hex-float is NOT accepted.
    (is (= 0.0d0    (call-autolisp-function atof-fn (make-autolisp-string "0x1p4"))))))
