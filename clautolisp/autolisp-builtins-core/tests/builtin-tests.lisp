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

(test builtin-integer-division-truncates-toward-zero
  ;; AutoLISP `/` over integers truncates toward zero (autolisp-spec
  ;; ch. 3, "Number Tower and Division"; BricsCAD V26 probe section
  ;; F: (/ 7 2) = 3, not 3.5). Mixed-type promotes to real.
  (reset-autolisp-symbol-table)
  (install-core-builtins)
  (let ((/-fn (autolisp-symbol-function (find-autolisp-symbol "/"))))
    (is (eql 3 (call-autolisp-function /-fn 7 2)))
    (is (typep (call-autolisp-function /-fn 7 2) '(signed-byte 32)))
    (is (eql 0 (call-autolisp-function /-fn 1 5)))
    (is (= 3.5d0 (call-autolisp-function /-fn 7.0d0 2)))
    (is (= 3.5d0 (call-autolisp-function /-fn 7 2.0d0)))
    (is (typep (call-autolisp-function /-fn 7.0d0 2) 'double-float))
    (is (typep (call-autolisp-function /-fn 7 2.0d0) 'double-float))
    ;; Multi-step int chain still truncates each step.
    (is (eql 1 (call-autolisp-function /-fn 13 4 2)))))

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
      ;; `=` is permissive: it accepts arguments of any type and falls
      ;; back to host-identity comparison for non-numeric / non-string
      ;; values (autolisp-spec ch. 5). The old strict-error behaviour
      ;; was wrong; production AutoLISP code uses (= sym1 sym2) freely.
      (is (string= "T"
                   (autolisp-symbol-name
                    (call-autolisp-function =-fn
                                            (intern-autolisp-symbol "FOO")))))
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
    (let ((value (call-autolisp-function
                  apply-fn
                  (intern-autolisp-symbol "VL-EXIT-WITH-VALUE")
                  (list 42))))
      (is (= 42 value))
      (is (= 0 (autolisp-errno)))
      (is (null (call-autolisp-function error-p-fn value))))
    (let ((failure (call-autolisp-function
                    apply-fn
                    (intern-autolisp-symbol "VL-EXIT-WITH-ERROR")
                    (list (make-autolisp-string "boom")))))
      (is (= 1 (autolisp-errno)))
      (is (string= "T"
                   (autolisp-symbol-name
                    (call-autolisp-function error-p-fn failure))))
      (let ((message (call-autolisp-function message-fn failure)))
        (is (typep message 'autolisp-string))
        (is (search "boom" (autolisp-string-value message)))))))

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

(test builtin-apply-eval-eq-equal
  ;; Core ch.5 functions: APPLY spreads a list, EVAL re-enters the
  ;; evaluator, EQ matches eql plus interned-string identity, and
  ;; EQUAL is structural with cross-type numeric equality.
  (reset-autolisp-symbol-table)
  (install-core-builtins)
  (let ((apply-fn (autolisp-symbol-function (find-autolisp-symbol "APPLY")))
        (eval-fn (autolisp-symbol-function (find-autolisp-symbol "EVAL")))
        (eq-fn (autolisp-symbol-function (find-autolisp-symbol "EQ")))
        (equal-fn (autolisp-symbol-function (find-autolisp-symbol "EQUAL")))
        (plus (intern-autolisp-symbol "+"))
        (foo-1 (intern-autolisp-symbol "FOO"))
        (foo-2 (intern-autolisp-symbol "FOO"))
        (t-symbol (intern-autolisp-symbol "T")))
    (is (eql 6 (call-autolisp-function apply-fn plus '(1 2 3))))
    (is (eql 0 (call-autolisp-function apply-fn plus nil)))
    (is (eql 6 (call-autolisp-function eval-fn (list plus 1 2 3))))
    (is (eq t-symbol (call-autolisp-function eq-fn foo-1 foo-2)))
    (is (eq t-symbol
            (call-autolisp-function eq-fn
                                    (make-autolisp-string "abc")
                                    (make-autolisp-string "abc"))))
    (is (eq t-symbol (call-autolisp-function equal-fn 1 1.0d0)))
    (is (eq t-symbol
            (call-autolisp-function equal-fn '(1 2) (list 1 2))))
    ;; equal with fuzz tolerance.
    (is (eq t-symbol
            (call-autolisp-function equal-fn 1.0d0 1.0001d0 0.01d0)))
    (is (null (call-autolisp-function equal-fn 1.0d0 1.05d0 0.01d0)))))

(test builtin-caxr-family
  ;; All depth-2 and depth-3 CAxR / CDxR walkers and a representative
  ;; depth-4 sample. Argument layout: ((a (b c)) (d (e f))).
  (reset-autolisp-symbol-table)
  (install-core-builtins)
  (let* ((cadr-fn (autolisp-symbol-function (find-autolisp-symbol "CADR")))
         (caar-fn (autolisp-symbol-function (find-autolisp-symbol "CAAR")))
         (cddr-fn (autolisp-symbol-function (find-autolisp-symbol "CDDR")))
         (caddr-fn (autolisp-symbol-function (find-autolisp-symbol "CADDR")))
         (cadddr-fn (autolisp-symbol-function (find-autolisp-symbol "CADDDR")))
         (lst '(1 2 3 4 5)))
    (is (eql 2 (call-autolisp-function cadr-fn lst)))
    (is (eql 3 (call-autolisp-function caddr-fn lst)))
    (is (eql 4 (call-autolisp-function cadddr-fn lst)))
    (is (equal '(3 4 5) (call-autolisp-function cddr-fn lst)))
    (is (eql 1 (call-autolisp-function caar-fn '((1 2) 3))))))

(test builtin-string-trim-search-translate
  ;; vl-string-* family used by real-world AutoLISP (e.g. project-file
  ;; loaders and path normalisers).
  (reset-autolisp-symbol-table)
  (install-core-builtins)
  (let ((trim-fn (autolisp-symbol-function (find-autolisp-symbol "VL-STRING-TRIM")))
        (search-fn (autolisp-symbol-function (find-autolisp-symbol "VL-STRING-SEARCH")))
        (translate-fn (autolisp-symbol-function (find-autolisp-symbol "VL-STRING-TRANSLATE")))
        (subst-fn (autolisp-symbol-function (find-autolisp-symbol "VL-STRING-SUBST")))
        (strcase-fn (autolisp-symbol-function (find-autolisp-symbol "STRCASE"))))
    (is (string= "abc"
                 (autolisp-string-value
                  (call-autolisp-function trim-fn
                                          (make-autolisp-string " \t\r\n")
                                          (make-autolisp-string "  abc \r\n")))))
    (is (eql 3
             (call-autolisp-function search-fn
                                     (make-autolisp-string "qux")
                                     (make-autolisp-string "fooqux"))))
    (is (null
         (call-autolisp-function search-fn
                                 (make-autolisp-string "zz")
                                 (make-autolisp-string "fooqux"))))
    (is (string= "C/path/to/file"
                 (autolisp-string-value
                  (call-autolisp-function translate-fn
                                          (make-autolisp-string "\\")
                                          (make-autolisp-string "/")
                                          (make-autolisp-string "C\\path\\to\\file")))))
    (is (string= "fooBARbaz"
                 (autolisp-string-value
                  (call-autolisp-function subst-fn
                                          (make-autolisp-string "BAR")
                                          (make-autolisp-string "qux")
                                          (make-autolisp-string "fooquxbaz")))))
    (is (string= "ABC"
                 (autolisp-string-value
                  (call-autolisp-function strcase-fn (make-autolisp-string "abc")))))
    (is (string= "abc"
                 (autolisp-string-value
                  (call-autolisp-function strcase-fn
                                          (make-autolisp-string "ABC")
                                          (intern-autolisp-symbol "T")))))))

(test builtin-error-signals-user-error
  ;; (error MSG) signals an autolisp-runtime-error with code
  ;; :user-error so user *error* hooks can match on it.
  (reset-autolisp-symbol-table)
  (install-core-builtins)
  (let ((error-fn (autolisp-symbol-function (find-autolisp-symbol "ERROR")))
        (signalled-code nil)
        (signalled-message nil))
    (handler-case
        (call-autolisp-function error-fn (make-autolisp-string "boom"))
      (autolisp-runtime-error (condition)
        (setf signalled-code (autolisp-runtime-error-code condition)
              signalled-message (autolisp-runtime-error-message condition))))
    (is (eq :user-error signalled-code))
    (is (string= "boom" signalled-message))))

(test phase7-math-builtins
  (reset-autolisp-symbol-table)
  (install-core-builtins)
  (let ((sqrt-fn (autolisp-symbol-function (find-autolisp-symbol "SQRT")))
        (exp-fn (autolisp-symbol-function (find-autolisp-symbol "EXP")))
        (log-fn (autolisp-symbol-function (find-autolisp-symbol "LOG")))
        (sin-fn (autolisp-symbol-function (find-autolisp-symbol "SIN")))
        (cos-fn (autolisp-symbol-function (find-autolisp-symbol "COS")))
        (atan-fn (autolisp-symbol-function (find-autolisp-symbol "ATAN")))
        (expt-fn (autolisp-symbol-function (find-autolisp-symbol "EXPT")))
        (mod-fn (autolisp-symbol-function (find-autolisp-symbol "MOD")))
        (floor-fn (autolisp-symbol-function (find-autolisp-symbol "FLOOR")))
        (ceiling-fn (autolisp-symbol-function (find-autolisp-symbol "CEILING")))
        (round-fn (autolisp-symbol-function (find-autolisp-symbol "ROUND")))
        (random-fn (autolisp-symbol-function (find-autolisp-symbol "RANDOM"))))
    (is (= 2.0d0 (call-autolisp-function sqrt-fn 4)))
    (is (= 1.0d0 (call-autolisp-function exp-fn 0)))
    (is (= 0.0d0 (call-autolisp-function log-fn 1)))
    (is (= 0.0d0 (call-autolisp-function sin-fn 0)))
    (is (= 1.0d0 (call-autolisp-function cos-fn 0)))
    (is (= (atan 1.0d0) (call-autolisp-function atan-fn 1)))
    (is (eql 8 (call-autolisp-function expt-fn 2 3)))
    (is (eql 2 (call-autolisp-function mod-fn 17 5)))
    (is (eql 3 (call-autolisp-function floor-fn 7 2)))
    (is (eql 4 (call-autolisp-function ceiling-fn 7 2)))
    (is (eql 4 (call-autolisp-function round-fn 3.6d0)))
    (is (eql -4 (call-autolisp-function round-fn -3.6d0)))
    (let ((r (call-autolisp-function random-fn 100)))
      (is (and (integerp r) (<= 0 r) (< r 100))))))

(test phase7-list-and-conversion
  (reset-autolisp-symbol-table)
  (install-core-builtins)
  (let ((vl-list-length-fn (autolisp-symbol-function (find-autolisp-symbol "VL-LIST-LENGTH")))
        (vl-position-fn (autolisp-symbol-function (find-autolisp-symbol "VL-POSITION")))
        (remove-fn (autolisp-symbol-function (find-autolisp-symbol "REMOVE")))
        (vl-sort-fn (autolisp-symbol-function (find-autolisp-symbol "VL-SORT")))
        (itoa-fn (autolisp-symbol-function (find-autolisp-symbol "ITOA")))
        (rtos-fn (autolisp-symbol-function (find-autolisp-symbol "RTOS"))))
    (is (eql 4 (call-autolisp-function vl-list-length-fn '(1 2 3 4))))
    (is (null (call-autolisp-function vl-list-length-fn '(1 2 . 3))))
    (is (eql 2 (call-autolisp-function vl-position-fn 30 '(10 20 30 40))))
    (is (null (call-autolisp-function vl-position-fn 99 '(10 20 30 40))))
    (is (equal '(1 3) (call-autolisp-function remove-fn 2 '(1 2 3 2))))
    (let ((sorted (call-autolisp-function
                   vl-sort-fn '(3 1 4 1 5 9 2 6)
                   (clautolisp.autolisp-runtime:make-autolisp-subr
                    "<" (lambda (a b) (if (< a b) (intern-autolisp-symbol "T") nil))))))
      (is (equal '(1 1 2 3 4 5 6 9) sorted)))
    (is (string= "42" (autolisp-string-value (call-autolisp-function itoa-fn 42))))
    (is (string= "3.14"
                 (autolisp-string-value (call-autolisp-function rtos-fn 3.14159d0 2 2))))))

(test phase7-geometry
  (reset-autolisp-symbol-table)
  (install-core-builtins)
  (let ((distance-fn (autolisp-symbol-function (find-autolisp-symbol "DISTANCE")))
        (angle-fn (autolisp-symbol-function (find-autolisp-symbol "ANGLE")))
        (polar-fn (autolisp-symbol-function (find-autolisp-symbol "POLAR")))
        (inters-fn (autolisp-symbol-function (find-autolisp-symbol "INTERS"))))
    (is (= 5.0d0 (call-autolisp-function distance-fn '(0 0) '(3 4))))
    (is (= 0.0d0 (call-autolisp-function angle-fn '(0 0) '(1 0))))
    (let ((p (call-autolisp-function polar-fn '(0 0) 0 5)))
      (is (= 5.0d0 (first p)))
      (is (< (abs (second p)) 1d-9)))
    ;; Crossing at (1,1) within both segments.
    (let ((hit (call-autolisp-function inters-fn '(0 0) '(2 2) '(0 2) '(2 0))))
      (is (and hit (= 1.0d0 (first hit)) (= 1.0d0 (second hit)))))
    ;; Non-intersecting segments.
    (is (null (call-autolisp-function inters-fn '(0 0) '(1 0) '(2 1) '(3 2))))))

(test phase7-string-helpers-wcmatch-snvalid
  (reset-autolisp-symbol-table)
  (install-core-builtins)
  (let ((wcmatch-fn (autolisp-symbol-function (find-autolisp-symbol "WCMATCH")))
        (snvalid-fn (autolisp-symbol-function (find-autolisp-symbol "SNVALID")))
        (xstrcase-fn (autolisp-symbol-function (find-autolisp-symbol "XSTRCASE")))
        (t-symbol (intern-autolisp-symbol "T")))
    (is (eq t-symbol
            (call-autolisp-function wcmatch-fn
                                    (make-autolisp-string "Layer-1")
                                    (make-autolisp-string "Layer*"))))
    (is (null (call-autolisp-function wcmatch-fn
                                      (make-autolisp-string "Other")
                                      (make-autolisp-string "Layer*"))))
    (is (eq t-symbol
            (call-autolisp-function wcmatch-fn
                                    (make-autolisp-string "abc")
                                    (make-autolisp-string "[abc]bc"))))
    (is (eq t-symbol (call-autolisp-function snvalid-fn (make-autolisp-string "Layer_01"))))
    (is (null (call-autolisp-function snvalid-fn (make-autolisp-string "with space"))))
    (is (string= "ABC"
                 (autolisp-string-value
                  (call-autolisp-function xstrcase-fn (make-autolisp-string "abc")))))))

(test phase7-findfile-handles-absolute-paths
  ;; findfile must return the absolute namestring when given an
  ;; existing absolute path, not nil. Real-world AutoLISP uses
  ;; (findfile path) right after writing a file to confirm it
  ;; landed where expected.
  (reset-autolisp-symbol-table)
  (install-core-builtins)
  (let* ((findfile-fn (autolisp-symbol-function (find-autolisp-symbol "FINDFILE")))
         (path (uiop:with-temporary-file (:pathname p :stream s :type "txt"
                                          :keep t)
                  (write-string "hello" s)
                  (namestring p))))
    (let ((result (call-autolisp-function findfile-fn (make-autolisp-string path))))
      (is (typep result 'autolisp-string))
      (is (probe-file (autolisp-string-value result))))
    (is (null (call-autolisp-function findfile-fn
                                      (make-autolisp-string "/no/such/file.lsp"))))))

(test phase-encoding-strict-loads-iso-8859-1-source
  ;; Strict dialect default external-format is :iso-8859-1, so a
  ;; file whose bytes are valid Latin-1 but invalid UTF-8 (e.g. byte
  ;; 233 = e-acute) loads cleanly.
  (reset-autolisp-symbol-table)
  (install-core-builtins)
  (uiop:with-temporary-file (:pathname p :stream s :type "lsp"
                             :keep nil :direction :output
                             :element-type '(unsigned-byte 8))
    (write-sequence #(40 ;; "(setq foo \"<é>\")"
                      83 69 84 81 32 70 79 79 32 34 60 233 62 34 41
                      10)
                    s)
    :close-stream
    (let ((load-fn (autolisp-symbol-function (find-autolisp-symbol "LOAD"))))
      ;; Should not signal — strict default encoding is iso-8859-1.
      (call-autolisp-function load-fn (make-autolisp-string (namestring p))))))

(test phase-encoding-autocad-default-is-utf-8
  ;; Under autocad-2026, the default source encoding is :utf-8 — a
  ;; UTF-8 file with non-ASCII bytes loads, and an iso-8859-1-only
  ;; file does NOT (the user opted into Unicode).
  (clautolisp.autolisp-runtime:reset-default-evaluation-context)
  (let* ((session (clautolisp.autolisp-runtime:evaluation-context-session
                   (clautolisp.autolisp-runtime:default-evaluation-context)))
         (autocad (clautolisp.autolisp-reader:autolisp-dialect-autocad-2026)))
    (clautolisp.autolisp-runtime:set-runtime-session-dialect session autocad)
    (is (eq :utf-8
            (clautolisp.autolisp-reader:autolisp-dialect-default-source-encoding
             autocad)))
    (is (eq :utf-8
            (clautolisp.autolisp-reader:autolisp-dialect-default-file-encoding
             autocad)))))

(test phase-encoding-parse-open-external-format-aliases
  ;; Autodesk short names + ANSI / latin1 / cp1252 + BricsCAD ccs=
  ;; mode-string fragment.
  (let ((parse 'clautolisp.autolisp-builtins-core::parse-open-external-format))
    (is (eq :utf-8     (funcall parse "utf8")))
    (is (eq :utf-8     (funcall parse "utf8-bom")))
    (is (eq :utf-8     (funcall parse "UTF-8")))
    (is (eq :iso-8859-1 (funcall parse "ANSI")))
    (is (eq :iso-8859-1 (funcall parse "latin1")))
    (is (eq :iso-8859-1 (funcall parse "iso-8859-1")))
    (is (eq :cp1252    (funcall parse "cp1252")))
    (is (eq :cp1252    (funcall parse "windows-1252")))
    ;; Bricscad-style "MODE,ccs=NAME" — the parser sees the trailing
    ;; "ccs=NAME" fragment.
    (is (eq :utf-8     (funcall parse "ccs=UTF-8")))
    (is (eq :iso-8859-1 (funcall parse "r,ccs=ANSI")))
    ;; Common-Lisp keyword literal still works.
    (is (eq :utf-8     (funcall parse ":utf-8")))))

(test phase10-entity-builtins-on-mock-host
  ;; The Phase-10 builtins (ENTGET/ENTMAKE/ENTLAST/ENTNEXT/HANDENT)
  ;; route through the active session's HAL backend. Under the
  ;; default NullHost they signal :host-not-supported; under a
  ;; freshly-allocated MockHost they round-trip a DXF group-code
  ;; list. We exercise both halves here.
  (reset-autolisp-symbol-table)
  (install-core-builtins)
  ;; Default NullHost: the builtins surface :host-not-supported.
  (let ((entlast-fn (autolisp-symbol-function (find-autolisp-symbol "ENTLAST"))))
    (handler-case (call-autolisp-function entlast-fn)
      (autolisp-runtime-error (condition)
        (is (eq :host-not-supported (autolisp-runtime-error-code condition))))))
  ;; Swap the default context onto a MockHost-bearing session.
  (let* ((mock (clautolisp.autolisp-mock-host:make-mock-host))
         (session (clautolisp.autolisp-runtime:evaluation-context-session
                   (clautolisp.autolisp-runtime:default-evaluation-context))))
    (clautolisp.autolisp-runtime:set-runtime-session-host session mock)
    (let* ((entmake-fn (autolisp-symbol-function (find-autolisp-symbol "ENTMAKE")))
           (entget-fn  (autolisp-symbol-function (find-autolisp-symbol "ENTGET")))
           (entlast-fn (autolisp-symbol-function (find-autolisp-symbol "ENTLAST")))
           (handent-fn (autolisp-symbol-function (find-autolisp-symbol "HANDENT")))
           (data (call-autolisp-function entmake-fn
                                         (list (cons 0 "LINE")
                                               (cons 8 "0")
                                               (cons 10 '(0.0d0 0.0d0 0.0d0))
                                               (cons 11 '(1.0d0 1.0d0 0.0d0))))))
      (is (consp data))
      ;; (-1 . ENAME) head injected by entmake.
      (is (eql -1 (car (first data))))
      (is (typep (cdr (first data))
                 'clautolisp.autolisp-runtime:autolisp-ename))
      ;; entlast returns the same ename's hex handle.
      (let ((last-ename (call-autolisp-function entlast-fn)))
        (is (string=
             (clautolisp.autolisp-runtime:autolisp-ename-value (cdr (first data)))
             (clautolisp.autolisp-runtime:autolisp-ename-value last-ename)))
        ;; entget against that ename round-trips the data list.
        (is (consp (call-autolisp-function entget-fn last-ename))))
      ;; handent on the recorded handle string returns an ename.
      (let* ((handle-cell (second data))
             (handle (cdr handle-cell)))
        (is (typep (call-autolisp-function handent-fn
                                            (make-autolisp-string handle))
                   'clautolisp.autolisp-runtime:autolisp-ename))
        (is (null (call-autolisp-function handent-fn
                                          (make-autolisp-string "DEADBEEF"))))))))

(test phase13-vlax-builtins-on-mock-host
  ;; Round-trip a VLA-object create -> get-property -> put-property
  ;; -> invoke-method, plus a SAFEARRAY round-trip and a VARIANT
  ;; type-tagged round-trip.
  (reset-autolisp-symbol-table)
  (install-core-builtins)
  (let* ((mock (clautolisp.autolisp-mock-host:make-mock-host))
         (session (clautolisp.autolisp-runtime:evaluation-context-session
                   (clautolisp.autolisp-runtime:default-evaluation-context))))
    (clautolisp.autolisp-runtime:set-runtime-session-host session mock)
    (let* ((create-fn  (autolisp-symbol-function (find-autolisp-symbol "VLAX-CREATE-OBJECT")))
           (get-prop   (autolisp-symbol-function (find-autolisp-symbol "VLAX-GET-PROPERTY")))
           (put-prop   (autolisp-symbol-function (find-autolisp-symbol "VLAX-PUT-PROPERTY")))
           (invoke     (autolisp-symbol-function (find-autolisp-symbol "VLAX-INVOKE-METHOD")))
           (release    (autolisp-symbol-function (find-autolisp-symbol "VLAX-RELEASE-OBJECT")))
           (released-p (autolisp-symbol-function (find-autolisp-symbol "VLAX-OBJECT-RELEASED-P")))
           (vla        (call-autolisp-function create-fn
                                                (make-autolisp-string "AutoCAD.Document"))))
      (is (typep vla 'clautolisp.autolisp-runtime:autolisp-vla-object))
      (flet ((prop-as-string (vla name)
               (let ((v (call-autolisp-function get-prop vla
                                                 (make-autolisp-string name))))
                 (cond ((stringp v) v)
                       ((typep v 'clautolisp.autolisp-runtime:autolisp-string)
                        (autolisp-string-value v))
                       (t v)))))
        (is (string= "Drawing.dwg" (prop-as-string vla "Name")))
        (call-autolisp-function put-prop vla
                                (make-autolisp-string "Name")
                                (make-autolisp-string "Renamed.dwg"))
        (is (string= "Renamed.dwg" (prop-as-string vla "Name")))
        (call-autolisp-function invoke vla
                                (make-autolisp-string "SaveAs")
                                (make-autolisp-string "Other.dwg"))
        (is (string= "Other.dwg" (prop-as-string vla "Name"))))
      (call-autolisp-function release vla)
      (is (string= "T"
                   (autolisp-symbol-name
                    (call-autolisp-function released-p vla))))))
  ;; SAFEARRAY round-trip.
  (let ((make-fn (autolisp-symbol-function (find-autolisp-symbol "VLAX-MAKE-SAFEARRAY")))
        (fill-fn (autolisp-symbol-function (find-autolisp-symbol "VLAX-SAFEARRAY-FILL")))
        (get-fn  (autolisp-symbol-function (find-autolisp-symbol "VLAX-SAFEARRAY-GET-ELEMENT")))
        (list-fn (autolisp-symbol-function (find-autolisp-symbol "VLAX-SAFEARRAY->LIST"))))
    (let ((sa (call-autolisp-function make-fn
                                       (intern-autolisp-symbol "VARIANT")
                                       (cons 0 2))))
      (call-autolisp-function fill-fn sa '(10 20 30))
      (is (eql 10 (call-autolisp-function get-fn sa 0)))
      (is (eql 30 (call-autolisp-function get-fn sa 2)))
      (is (equal '(10 20 30) (call-autolisp-function list-fn sa)))))
  ;; VARIANT round-trip.
  (let ((make-fn (autolisp-symbol-function (find-autolisp-symbol "VLAX-MAKE-VARIANT")))
        (type-fn (autolisp-symbol-function (find-autolisp-symbol "VLAX-VARIANT-TYPE")))
        (val-fn  (autolisp-symbol-function (find-autolisp-symbol "VLAX-VARIANT-VALUE"))))
    (let ((v (call-autolisp-function make-fn 42)))
      (is (eql 42 (call-autolisp-function val-fn v)))
      (is (string= "INTEGER"
                   (autolisp-symbol-name
                    (call-autolisp-function type-fn v)))))))

(test reader-handles-newline-and-tab-string-escapes
  ;; "\n" / "\t" / "\r" in source code must produce real control
  ;; characters in every dialect, not literal backslash-letter pairs
  ;; (real-world AutoLISP relies on this).
  (reset-autolisp-symbol-table)
  (install-core-builtins)
  (let ((forms (clautolisp.autolisp-runtime:read-runtime-from-string
                "\"a\\nb\\tc\\rd\"")))
    (is (= 1 (length forms)))
    (let ((s (autolisp-string-value (first forms))))
      (is (string= s (format nil "a~Cb~Cc~Cd"
                             #\Newline #\Tab #\Return))))))

;;; --- COND clause-selection regressions --------------------------
;;;
;;; Real AutoLISP treats T as a self-evaluating constant, so the
;;; idiom (cond ((test) ...) (T fallback)) must reach the fallback
;;; whenever no earlier clause matches. The strict / autocad-2026 /
;;; bricscad-v26 dialects all return :silent-nil for unbound
;;; variables, which previously made the T clause silently skip —
;;; found via greet.lsp's GUI flow on 2026-04-26.

(defun install-core-into (context)
  (declare (ignore context))
  (install-core-builtins))

(test cond-t-fallback-is-selected
  "(cond ((false) ...) (T x)) returns x. T self-evaluates."
  (reset-autolisp-symbol-table)
  (is (eql 99 (run-autolisp-string "(cond ((= 1 2) 11) (T 99))"
                                   :setup-fn #'install-core-into))))

(test cond-first-true-clause-wins
  "When two branches would match, COND picks the first."
  (reset-autolisp-symbol-table)
  (is (eql 1 (run-autolisp-string
              "(cond ((= 1 1) 1) ((= 2 2) 2) (T 99))"
              :setup-fn #'install-core-into))))

(test cond-middle-branch-selected-when-others-fail
  "A middle clause runs only when earlier ones are nil."
  (reset-autolisp-symbol-table)
  (is (eql 22 (run-autolisp-string
               "(cond ((= 1 0) 11) ((= 2 2) 22) ((= 3 3) 33) (T 99))"
               :setup-fn #'install-core-into))))

(test cond-no-match-returns-nil-without-t
  "If no clause matches and there is no T fallback, COND yields nil."
  (reset-autolisp-symbol-table)
  (is (null (run-autolisp-string
             "(cond ((= 0 1) 11) ((= 0 2) 22))"
             :setup-fn #'install-core-into))))

(test cond-clause-body-is-progn
  "All forms of a selected clause are evaluated in order; the last
value is returned."
  (reset-autolisp-symbol-table)
  (is (eql 7 (run-autolisp-string
              "(cond ((= 1 1) (setq z 3) (setq z (+ z 4)) z))"
              :setup-fn #'install-core-into))))

(test cond-test-only-clause-returns-test-value
  "(cond ((expr))) returns expr's value when no consequent forms."
  (reset-autolisp-symbol-table)
  (is (eql 42 (run-autolisp-string "(cond ((* 6 7)))"
                                   :setup-fn #'install-core-into))))

(test cond-each-branch-independently-selectable
  "For x in 0..3, each branch fires the matching clause's body."
  (reset-autolisp-symbol-table)
  (let ((labels (loop for x from 0 to 3
                      collect (autolisp-string-value
                               (run-autolisp-string
                                (format nil
                                        "(setq x ~D)
                                         (cond ((= x 0) \"a\")
                                               ((= x 1) \"b\")
                                               ((= x 2) \"c\")
                                               (T       \"d\"))" x)
                                :setup-fn #'install-core-into)))))
    (is (equal '("a" "b" "c" "d") labels))))

;;; --- Phase 7 round-out: hyperbolics, predicates, list/string ----

(test phase7-hyperbolic-math
  "sinh / cosh / tanh / atanh return the IEEE-correct values for
the canonical inputs."
  (reset-autolisp-symbol-table)
  (is (< (abs (- 1.1752011936438014d0
                 (run-autolisp-string "(sinh 1.0)"
                                       :setup-fn #'install-core-into)))
         1d-12))
  (is (< (abs (- 1.5430806348152437d0
                 (run-autolisp-string "(cosh 1.0)"
                                       :setup-fn #'install-core-into)))
         1d-12))
  (is (< (abs (- 0.7615941559557649d0
                 (run-autolisp-string "(tanh 1.0)"
                                       :setup-fn #'install-core-into)))
         1d-12))
  (is (< (abs (- 0.5493061443340549d0
                 (run-autolisp-string "(atanh 0.5)"
                                       :setup-fn #'install-core-into)))
         1d-12)))

(test phase7-power-is-expt
  (reset-autolisp-symbol-table)
  (is (eql 8 (run-autolisp-string "(power 2 3)"
                                  :setup-fn #'install-core-into))))

(test phase7-position-and-vl-position-agree
  (reset-autolisp-symbol-table)
  (is (eql 2 (run-autolisp-string "(position 'c '(a b c d))"
                                  :setup-fn #'install-core-into)))
  (is (eql 2 (run-autolisp-string "(vl-position 'c '(a b c d))"
                                  :setup-fn #'install-core-into))))

(test phase7-vl-remove-and-remove-agree
  (reset-autolisp-symbol-table)
  ;; remove returns a list; vl-remove is a synonym in V26.
  (let ((via-remove (run-autolisp-string "(remove 2 '(1 2 3 2 4))"
                                          :setup-fn #'install-core-into))
        (via-vl     (run-autolisp-string "(vl-remove 2 '(1 2 3 2 4))"
                                          :setup-fn #'install-core-into)))
    (is (equal '(1 3 4) via-remove))
    (is (equal '(1 3 4) via-vl))))

(test phase7-vl-string-split-on-comma
  (reset-autolisp-symbol-table)
  (let ((parts (run-autolisp-string
                "(vl-string-split \",\" \"a,bb,,c\")"
                :setup-fn #'install-core-into)))
    (is (equal '("a" "bb" "" "c")
               (mapcar #'autolisp-string-value parts)))))

(test phase7-vl-nanp-and-vl-infp
  "Ordinary doubles are neither NaN nor infinite; integers and
strings yield nil (not an error)."
  (reset-autolisp-symbol-table)
  (is (null (run-autolisp-string "(vl-nanp 1.0)"
                                  :setup-fn #'install-core-into)))
  (is (null (run-autolisp-string "(vl-infp 1.0)"
                                  :setup-fn #'install-core-into)))
  (is (null (run-autolisp-string "(vl-nanp 42)"
                                  :setup-fn #'install-core-into)))
  (is (null (run-autolisp-string "(vl-infp \"hello\")"
                                  :setup-fn #'install-core-into))))

;;;; ----- M2 missing-functions: core/misc native -----

(test m2-getenv-existing-var
  "(getenv \"PATH\") returns a non-nil autolisp-string when the env
var is set in the running process — PATH is essentially always set."
  (reset-autolisp-symbol-table)
  (let ((result (run-autolisp-string "(getenv \"PATH\")"
                                     :setup-fn #'install-core-into)))
    (is (typep result 'autolisp-string))
    (is (plusp (length (autolisp-string-value result))))))

(test m2-getenv-missing-returns-nil
  "(getenv \"DEFINITELY_NOT_SET\") returns nil for an unset var."
  (reset-autolisp-symbol-table)
  (is (null
       (run-autolisp-string "(getenv \"DEFINITELY_NOT_SET_X\")"
                            :setup-fn #'install-core-into))))

(test m2-setenv-getenv-roundtrip
  "(setenv \"X\" \"v\") followed by (getenv \"X\") returns \"v\"."
  (reset-autolisp-symbol-table)
  (let ((result (run-autolisp-string
                 "(setenv \"CLAUTOLISP_TEST_M2\" \"hello\") (getenv \"CLAUTOLISP_TEST_M2\")"
                 :setup-fn #'install-core-into)))
    (is (typep result 'autolisp-string))
    (is (string= "hello" (autolisp-string-value result)))))

(test m2-getenv-distinguishes-empty-from-unset
  "Per AutoLISP Spec § GETENV: nil is returned ONLY when the
variable is undefined. A defined-but-empty variable returns the
empty string \"\" — useful for flag-style env vars (NO_COLOR
etc.) where presence with any value, including empty, is the
signal."
  (reset-autolisp-symbol-table)
  ;; Set the var to the empty string, then read it back.
  (setf (uiop:getenv "CLAUTOLISP_TEST_M2_EMPTY") "")
  (unwind-protect
       (let ((result (run-autolisp-string
                      "(getenv \"CLAUTOLISP_TEST_M2_EMPTY\")"
                      :setup-fn #'install-core-into)))
         (is (typep result 'autolisp-string))
         (is (string= "" (autolisp-string-value result))))
    ;; Cleanup — unsetting is impl-specific; setting to nil works
    ;; on both SBCL/UIOP and CCL/UIOP for our purposes.
    (ignore-errors (setf (uiop:getenv "CLAUTOLISP_TEST_M2_EMPTY") nil))))

(test m2-getpid-returns-positive-integer
  "(getpid) returns the running process's PID as a positive integer."
  (reset-autolisp-symbol-table)
  (let ((result (run-autolisp-string "(getpid)"
                                     :setup-fn #'install-core-into)))
    (is (integerp result))
    (is (plusp result))))

(test m2-sleep-returns-nil
  "(sleep 1) returns nil — Autodesk's documented return."
  (reset-autolisp-symbol-table)
  (is (null (run-autolisp-string "(sleep 1)"
                                 :setup-fn #'install-core-into))))

(test m2-gc-returns-nil
  "(gc) returns nil and doesn't crash."
  (reset-autolisp-symbol-table)
  (is (null (run-autolisp-string "(gc)" :setup-fn #'install-core-into))))

(test m2-ver-returns-version-string
  "(ver) returns a non-empty autolisp-string starting with the
lower-case project name \"clautolisp\" (matching the binary,
package, and doc styling)."
  (reset-autolisp-symbol-table)
  (let ((result (run-autolisp-string "(ver)" :setup-fn #'install-core-into)))
    (is (typep result 'autolisp-string))
    (is (search "clautolisp" (autolisp-string-value result)))))

(test m2-lisp$version-alias
  "(lisp$version) returns the same string as (ver)."
  (reset-autolisp-symbol-table)
  (let ((ver (run-autolisp-string "(ver)" :setup-fn #'install-core-into))
        (lv  (run-autolisp-string "(lisp$version)" :setup-fn #'install-core-into)))
    (is (string= (autolisp-string-value ver)
                 (autolisp-string-value lv)))))

(test m2-mem-returns-three-integers
  "(mem) returns a list of three integers (the documented triple).
On CCL we parse (room) output and expect non-zero used+free heap
counts; on SBCL we only require the slot shape (the SBCL impl
returns dynamic-space-size as USED + zero placeholders)."
  (reset-autolisp-symbol-table)
  (let ((result (run-autolisp-string "(mem)" :setup-fn #'install-core-into)))
    (is (consp result))
    (is (= 3 (length result)))
    (is (every #'integerp result))
    #+ccl
    (let ((used (first result))
          (free (second result)))
      (is (plusp used) "(mem) USED slot under CCL should reflect real heap use, got ~D" used)
      (is (plusp free) "(mem) FREE slot under CCL should reflect real heap free, got ~D" free))))

(test m2-alloc-returns-argument
  "(alloc N) returns N (Autodesk: doesn't apply)."
  (reset-autolisp-symbol-table)
  (is (eql 1234 (run-autolisp-string "(alloc 1234)"
                                     :setup-fn #'install-core-into))))

(test m2-vl-getcurrentdir-returns-string
  "(vl-getcurrentdir) returns the current working directory."
  (reset-autolisp-symbol-table)
  (let ((result (run-autolisp-string "(vl-getcurrentdir)"
                                     :setup-fn #'install-core-into)))
    (is (typep result 'autolisp-string))
    (is (plusp (length (autolisp-string-value result))))))

(test m2-vl-getstartupdir-returns-string
  "(vl-getstartupdir) returns the directory captured at startup."
  (reset-autolisp-symbol-table)
  (let ((result (run-autolisp-string "(vl-getstartupdir)"
                                     :setup-fn #'install-core-into)))
    (is (typep result 'autolisp-string))))

(test m2-fnsplitl-three-parts
  "(fnsplitl \"/tmp/file.lsp\") -> (\"/tmp/\" \"file\" \".lsp\")."
  (reset-autolisp-symbol-table)
  (let ((result (run-autolisp-string "(fnsplitl \"/tmp/file.lsp\")"
                                     :setup-fn #'install-core-into)))
    (is (consp result))
    (is (= 3 (length result)))
    (is (string= "/tmp/" (autolisp-string-value (first  result))))
    (is (string= "file"  (autolisp-string-value (second result))))
    (is (string= ".lsp"  (autolisp-string-value (third  result))))))

(test m2-fnsplitl-no-extension
  "(fnsplitl \"noext\") -> (\"\" \"noext\" \"\")."
  (reset-autolisp-symbol-table)
  (let ((result (run-autolisp-string "(fnsplitl \"noext\")"
                                     :setup-fn #'install-core-into)))
    (is (string= ""      (autolisp-string-value (first  result))))
    (is (string= "noext" (autolisp-string-value (second result))))
    (is (string= ""      (autolisp-string-value (third  result))))))

(test m2-trans-identity-preserves-coordinates
  "(trans '(1 2 3) 0 1) returns (1.0 2.0 3.0) — identity transform
in a headless engine where every coordinate space collapses to WCS."
  (reset-autolisp-symbol-table)
  (let ((result (run-autolisp-string "(trans '(1 2 3) 0 1)"
                                     :setup-fn #'install-core-into)))
    (is (consp result))
    (is (= 3 (length result)))
    (is (= 1.0d0 (first  result)))
    (is (= 2.0d0 (second result)))
    (is (= 3.0d0 (third  result)))))

(test m2-trans-2d-fills-z-zero
  "(trans '(1 2) 0 1) -> (1.0 2.0 0.0) — missing Z defaults to 0."
  (reset-autolisp-symbol-table)
  (let ((result (run-autolisp-string "(trans '(1 2) 0 1)"
                                     :setup-fn #'install-core-into)))
    (is (= 3 (length result)))
    (is (= 0.0d0 (third result)))))

(test m2-textbox-stub-shape
  "(textbox '((1 . \"hello\") (40 . 1.0))) returns a 2-corner box."
  (reset-autolisp-symbol-table)
  (let ((result (run-autolisp-string
                 "(textbox (list (cons 1 \"hello\") (cons 40 1.0)))"
                 :setup-fn #'install-core-into)))
    (is (consp result))
    (is (= 2 (length result)))
    (is (= 3 (length (first  result))))    ; (x1 y1 z1)
    (is (= 3 (length (second result))))    ; (x2 y2 z2)
    ;; Lower-left corner at origin in our stub.
    (is (= 0.0d0 (first  (first result))))
    (is (= 0.0d0 (second (first result))))))

(test m2-vle-g-vectol-returns-tolerance
  "(vle_g_vectol) returns the configured vector tolerance."
  (reset-autolisp-symbol-table)
  (let ((result (run-autolisp-string "(vle_g_vectol)"
                                     :setup-fn #'install-core-into)))
    (is (numberp result))
    (is (plusp result))))

(test m2-cli-noops-all-return-nil
  "GRAPHSCR, TEXTSCR, TEXTPAGE, REDRAW, SETVIEW, TABLET return nil."
  (reset-autolisp-symbol-table)
  (dolist (form '("(graphscr)" "(textscr)" "(textpage)"
                  "(redraw)" "(setview)" "(tablet)"))
    (is (null (run-autolisp-string form :setup-fn #'install-core-into)))))

(test m2-cli-noops-string-return
  "MENUCMD returns \"\"; MENUGROUP and SHOWHTMLMODALWINDOW return nil."
  (reset-autolisp-symbol-table)
  (let ((mcmd (run-autolisp-string "(menucmd)" :setup-fn #'install-core-into)))
    (is (typep mcmd 'autolisp-string))
    (is (string= "" (autolisp-string-value mcmd))))
  (is (null (run-autolisp-string "(menugroup)" :setup-fn #'install-core-into)))
  (is (null (run-autolisp-string "(showhtmlmodalwindow)"
                                 :setup-fn #'install-core-into))))

(test m2-error-mode-push-pop-lifo
  "*push-error-using-command* / *push-error-using-stack* / *pop-error-mode*
form a LIFO stack returning the keyword names of pushed modes."
  (reset-autolisp-symbol-table)
  ;; Drain any state from earlier tests.
  (setf clautolisp.autolisp-builtins-core::*autolisp-error-mode-stack* nil)
  (let ((first-pop
          (run-autolisp-string
           "(*push-error-using-command*)
            (*push-error-using-stack*)
            (*pop-error-mode*)"
           :setup-fn #'install-core-into)))
    (is (typep first-pop 'autolisp-symbol))
    (is (string= "STACK" (autolisp-symbol-name first-pop))))
  (let ((second-pop
          (run-autolisp-string "(*pop-error-mode*)"
                               :setup-fn #'install-core-into)))
    (is (typep second-pop 'autolisp-symbol))
    (is (string= "COMMAND" (autolisp-symbol-name second-pop))))
  (let ((third-pop
          (run-autolisp-string "(*pop-error-mode*)"
                               :setup-fn #'install-core-into)))
    (is (null third-pop))))

(test m2-help-returns-nil
  "(help) prints a one-liner and returns nil."
  (reset-autolisp-symbol-table)
  (is (null (run-autolisp-string "(help)"
                                 :setup-fn #'install-core-into))))

;;;; ----- M3a missing-functions: VLE-* list/predicate/number helpers -----

(test m3a-vle-nth-shortcuts
  "VLE-NTH0..VLE-NTH9 return the element at their fixed index, or
NIL past the end."
  (reset-autolisp-symbol-table)
  (is (eq (intern-autolisp-symbol "A")
          (run-autolisp-string "(vle-nth0 '(a b c d))"
                               :setup-fn #'install-core-into)))
  (is (eq (intern-autolisp-symbol "D")
          (run-autolisp-string "(vle-nth3 '(a b c d))"
                               :setup-fn #'install-core-into)))
  (is (null
       (run-autolisp-string "(vle-nth9 '(a b c d))"
                            :setup-fn #'install-core-into))))

(test m3a-vle-put-nth-pads-and-replaces
  "(vle-put-nth lst idx val) replaces at IDX, or pads with NIL
if IDX > length; returns lst unchanged for negative IDX."
  (reset-autolisp-symbol-table)
  (let ((replaced (run-autolisp-string
                   "(vle-put-nth '(10 20 30) 1 99)"
                   :setup-fn #'install-core-into)))
    (is (equal '(10 99 30) replaced)))
  (let ((padded (run-autolisp-string
                 "(vle-put-nth '(10 20) 4 99)"
                 :setup-fn #'install-core-into)))
    (is (equal '(10 20 nil nil 99) padded))))

(test m3a-vle-subst-nth-leaves-out-of-range-unchanged
  "VLE-SUBST-NTH keeps lst untouched on out-of-range IDX (the
conservative interpretation chosen until vendor-validation)."
  (reset-autolisp-symbol-table)
  (let ((unchanged (run-autolisp-string
                    "(vle-subst-nth '(10 20) 4 99)"
                    :setup-fn #'install-core-into)))
    (is (equal '(10 20) unchanged))))

(test m3a-vle-remove-family
  "REMOVE-NTH / REMOVE-ALL / REMOVE-FIRST / REMOVE-LAST behave per
their respective spec descriptions."
  (reset-autolisp-symbol-table)
  (is (equal '(10 30)
             (run-autolisp-string "(vle-remove-nth 1 '(10 20 30))"
                                  :setup-fn #'install-core-into)))
  (is (equal '(10 30)
             (run-autolisp-string "(vle-remove-all 20 '(10 20 30 20))"
                                  :setup-fn #'install-core-into)))
  (is (equal '(10 30 20)
             (run-autolisp-string "(vle-remove-first 20 '(10 20 30 20))"
                                  :setup-fn #'install-core-into)))
  (is (equal '(10 20)
             (run-autolisp-string "(vle-remove-last '(10 20 30))"
                                  :setup-fn #'install-core-into))))

(test m3a-vle-list-split-returns-head-tail
  "(vle-list-split lst item) returns (head tail) with the
splitter dropped at the split point."
  (reset-autolisp-symbol-table)
  (let ((split (run-autolisp-string "(vle-list-split '(a b 0 c d) 0)"
                                    :setup-fn #'install-core-into)))
    (is (equal (list (list (intern-autolisp-symbol "A")
                           (intern-autolisp-symbol "B"))
                     (list (intern-autolisp-symbol "C")
                           (intern-autolisp-symbol "D")))
               split))))

(test m3a-vle-sublist-extracts-n-items
  "(vle-sublist lst start n) returns N items starting at START
(0-based), clamped to the list end."
  (reset-autolisp-symbol-table)
  (is (equal '(30 40 50)
             (run-autolisp-string "(vle-sublist '(10 20 30 40 50 60) 2 3)"
                                  :setup-fn #'install-core-into)))
  ;; clamp to end
  (is (equal '(50 60)
             (run-autolisp-string "(vle-sublist '(10 20 30 40 50 60) 4 10)"
                                  :setup-fn #'install-core-into))))

(test m3a-vle-set-ops
  "LIST-DIFF is symmetric difference; INTERSECT / SUBTRACT / UNION
follow the standard set semantics."
  (reset-autolisp-symbol-table)
  (is (equal '(1 4)
             (run-autolisp-string "(vle-list-diff '(1 2 3) '(2 3 4))"
                                  :setup-fn #'install-core-into)))
  (is (equal '(2 3)
             (run-autolisp-string "(vle-list-intersect '(1 2 3) '(2 3 4))"
                                  :setup-fn #'install-core-into)))
  (is (equal '(1 4)
             (run-autolisp-string "(vle-list-subtract '(1 2 3 4) '(2 3))"
                                  :setup-fn #'install-core-into)))
  (is (equal '(1 2 3 4)
             (run-autolisp-string "(vle-list-union '(1 2 3) '(2 3 4))"
                                  :setup-fn #'install-core-into))))

(test m3a-vle-cdrassoc-and-cadrassoc
  "VLE-CDRASSOC == (cdr (assoc k l)); VLE-CADRASSOC == (cadr (assoc k l))."
  (reset-autolisp-symbol-table)
  (is (equal '(2) (run-autolisp-string "(vle-cdrassoc 'b '((a 1) (b 2) (c 3)))"
                                       :setup-fn #'install-core-into)))
  (is (eql 2 (run-autolisp-string "(vle-cadrassoc 'b '((a 1) (b 2) (c 3)))"
                                  :setup-fn #'install-core-into))))

(test m3a-vle-list-massoc-collects-all
  "(vle-list-massoc key alist) returns the cdr of every pair whose car matches KEY."
  (reset-autolisp-symbol-table)
  (let ((result (run-autolisp-string
                 "(vle-list-massoc 'b '((a 1) (b 2) (b 22) (c 3)))"
                 :setup-fn #'install-core-into)))
    (is (equal '((2) (22)) result))))

(test m3a-vle-search-tail-and-index
  "(vle-search item lst nil) returns the tail starting at ITEM
(MEMBER semantics); (vle-search item lst t) returns the 0-based
index. NIL when not found."
  (reset-autolisp-symbol-table)
  (let ((tail (run-autolisp-string "(vle-search 'c '(a b c d) nil)"
                                   :setup-fn #'install-core-into)))
    (is (equal (list (intern-autolisp-symbol "C")
                     (intern-autolisp-symbol "D"))
               tail)))
  (is (eql 2 (run-autolisp-string "(vle-search 'c '(a b c d) t)"
                                  :setup-fn #'install-core-into)))
  (is (null (run-autolisp-string "(vle-search 'z '(a b c d) t)"
                                 :setup-fn #'install-core-into))))

(test m3a-vle-type-predicates-native
  "Native predicates return T for matches, NIL for non-matches."
  (reset-autolisp-symbol-table)
  (let ((tests '(("(vle-integerp 5)"      t)
                 ("(vle-integerp 1.5)"    nil)
                 ("(vle-realp 1.5)"       t)
                 ("(vle-realp 5)"         nil)
                 ("(vle-numberp 5)"       t)
                 ("(vle-numberp 1.5)"     t)
                 ("(vle-numberp \"a\")"   nil)
                 ("(vle-stringp \"x\")"   t)
                 ("(vle-stringp 5)"       nil)
                 ("(vle-pointp '(1 2))"   t)
                 ("(vle-pointp '(1 2 3))" t)
                 ("(vle-pointp '(1))"     nil)
                 ("(vle-pointp '(1 2 \"a\"))" nil))))
    (dolist (pair tests)
      (let* ((form     (first pair))
             (expected (second pair))
             (result   (run-autolisp-string form
                                            :setup-fn #'install-core-into)))
        (cond
          (expected
           (is (typep result 'autolisp-symbol) "~A returned ~S, not a symbol" form result)
           (is (string= "T" (autolisp-symbol-name result))
               "~A returned ~S, not T" form result))
          (t
           (is (null result) "~A returned ~S, not nil" form result)))))))

(test m3a-vle-com-predicates-are-stubs
  "VARIANTP / SAFEARRAYP / VLAOBJECTP return nil — clautolisp
doesn't carry the COM types these predicate over."
  (reset-autolisp-symbol-table)
  (dolist (form '("(vle-variantp 5)"
                  "(vle-safearrayp 5)"
                  "(vle-vlaobjectp 5)"))
    (is (null (run-autolisp-string form :setup-fn #'install-core-into))
        "~A should be nil under the stub impl" form)))

(test m3a-vle-rounding
  "CEILING / FLOOR / ROUND / ROUNDTO match their spec descriptions."
  (reset-autolisp-symbol-table)
  (is (eql 2 (run-autolisp-string "(vle-ceiling 1.3)" :setup-fn #'install-core-into)))
  (is (eql 1 (run-autolisp-string "(vle-floor 1.7)"   :setup-fn #'install-core-into)))
  (is (eql 2 (run-autolisp-string "(vle-round 1.5)"   :setup-fn #'install-core-into)))
  (let ((rounded (run-autolisp-string "(vle-roundto 3.14159 2)"
                                      :setup-fn #'install-core-into)))
    (is (and (numberp rounded)
             (< (abs (- rounded 3.14d0)) 1.0d-9))
        "vle-roundto 3.14159 2 -> ~S, expected ~~3.14" rounded)))

(test m3a-vle-int32-conversions
  "ATOI32 / ITOA32 / INT64TO32 wrap large values to 32-bit signed."
  (reset-autolisp-symbol-table)
  (is (eql 42 (run-autolisp-string "(vle-atoi32 \"42\")"
                                   :setup-fn #'install-core-into)))
  (let ((s (run-autolisp-string "(vle-itoa32 -7)"
                                :setup-fn #'install-core-into)))
    (is (typep s 'autolisp-string))
    (is (string= "-7" (autolisp-string-value s)))))

(test m3a-vle-tan
  "(vle-tan 0) returns 0.0."
  (reset-autolisp-symbol-table)
  (is (< (abs (run-autolisp-string "(vle-tan 0)" :setup-fn #'install-core-into))
         1.0d-12)))

;;;; ----- M3b missing-functions: VLE-VECTOR-* math -----

(defun close-vec3-p (vec expected &key (tol 1.0d-9))
  "Helper: compare a returned VEC against EXPECTED triple within TOL."
  (and (consp vec)
       (= 3 (length vec))
       (every (lambda (a b) (< (abs (- a b)) tol)) vec expected)))

(test m3b-vle-vector-arithmetic
  "ADD / SUB / NEGATE / SCALE / MIDPOINT / GET produce the
expected component-wise results."
  (reset-autolisp-symbol-table)
  (is (close-vec3-p
       (run-autolisp-string "(vle-vector-add '(1 2 3) '(10 20 30))"
                            :setup-fn #'install-core-into)
       '(11d0 22d0 33d0)))
  (is (close-vec3-p
       (run-autolisp-string "(vle-vector-sub '(10 20 30) '(1 2 3))"
                            :setup-fn #'install-core-into)
       '(9d0 18d0 27d0)))
  (is (close-vec3-p
       (run-autolisp-string "(vle-vector-negate '(1 2 3))"
                            :setup-fn #'install-core-into)
       '(-1d0 -2d0 -3d0)))
  (is (close-vec3-p
       (run-autolisp-string "(vle-vector-scale '(1 2 3) 2)"
                            :setup-fn #'install-core-into)
       '(2d0 4d0 6d0)))
  (is (close-vec3-p
       (run-autolisp-string "(vle-vector-midpoint '(0 0 0) '(4 4 4))"
                            :setup-fn #'install-core-into)
       '(2d0 2d0 2d0)))
  (is (close-vec3-p
       (run-autolisp-string "(vle-vector-get '(1 1 1) '(4 5 6))"
                            :setup-fn #'install-core-into)
       '(3d0 4d0 5d0))))

(test m3b-vle-vector-products
  "Dot of perpendicular vectors is 0; cross of X×Y is Z."
  (reset-autolisp-symbol-table)
  (let ((dot (run-autolisp-string
              "(vle-vector-dotproduct '(1 0 0) '(0 1 0))"
              :setup-fn #'install-core-into)))
    (is (< (abs dot) 1.0d-12)))
  (is (close-vec3-p
       (run-autolisp-string "(vle-vector-crossproduct '(1 0 0) '(0 1 0))"
                            :setup-fn #'install-core-into)
       '(0d0 0d0 1d0))))

(test m3b-vle-vector-lengths
  "LENGTH = sqrt(x²+y²+z²); LENGTH2D drops Z; LENGTH2DXZ drops Y;
LENGTH2DYZ drops X."
  (reset-autolisp-symbol-table)
  (is (< (abs (- 5d0 (run-autolisp-string
                       "(vle-vector-length '(3 4 0))"
                       :setup-fn #'install-core-into)))
         1.0d-9))
  (is (< (abs (- 5d0 (run-autolisp-string
                       "(vle-vector-length2d '(3 4 999))"
                       :setup-fn #'install-core-into)))
         1.0d-9))
  (is (< (abs (- 5d0 (run-autolisp-string
                       "(vle-vector-length2dxz '(3 999 4))"
                       :setup-fn #'install-core-into)))
         1.0d-9))
  (is (< (abs (- 5d0 (run-autolisp-string
                       "(vle-vector-length2dyz '(999 3 4))"
                       :setup-fn #'install-core-into)))
         1.0d-9)))

(test m3b-vle-vector-normalise
  "NORMALISE produces a unit vector; zero-length input returns NIL."
  (reset-autolisp-symbol-table)
  (is (close-vec3-p
       (run-autolisp-string "(vle-vector-normalise '(0 3 0))"
                            :setup-fn #'install-core-into)
       '(0d0 1d0 0d0)))
  (is (null (run-autolisp-string "(vle-vector-normalise '(0 0 0))"
                                 :setup-fn #'install-core-into))))

(test m3b-vle-vector-angles
  "ANGLETO unsigned π/2 between X and Y axes; ANGLETOREF sign
flips when the normal flips."
  (reset-autolisp-symbol-table)
  (let* ((half-pi (/ (acos -1d0) 2d0))
         (raw (run-autolisp-string "(vle-vector-angleto '(1 0 0) '(0 1 0))"
                                   :setup-fn #'install-core-into))
         (pos (run-autolisp-string
               "(vle-vector-angletoref '(1 0 0) '(0 1 0) '(0 0 1))"
               :setup-fn #'install-core-into))
         (neg (run-autolisp-string
               "(vle-vector-angletoref '(1 0 0) '(0 1 0) '(0 0 -1))"
               :setup-fn #'install-core-into)))
    (is (< (abs (- raw half-pi)) 1.0d-9))
    (is (< (abs (- pos half-pi)) 1.0d-9))
    (is (< (abs (- neg (- half-pi))) 1.0d-9))))

(test m3b-vle-vector-predicates
  "Equality, unit-length, zero-length, parallelism,
codirectionality, perpendicularity, axis-tests."
  (reset-autolisp-symbol-table)
  (flet ((bool (form)
           (let ((r (run-autolisp-string form :setup-fn #'install-core-into)))
             (and (typep r 'autolisp-symbol)
                  (string= "T" (autolisp-symbol-name r))))))
    (is      (bool "(vle-vector-isequal '(1 2 3) '(1 2 3))"))
    (is (not (bool "(vle-vector-isequal '(1 2 3) '(1 2 4))")))
    (is      (bool "(vle-vector-isunitlength '(1 0 0))"))
    (is (not (bool "(vle-vector-isunitlength '(2 0 0))")))
    (is      (bool "(vle-vector-iszerolength '(0 0 0))"))
    (is (not (bool "(vle-vector-iszerolength '(0 0 1))")))
    (is      (bool "(vle-vector-isparallel '(1 2 3) '(2 4 6))"))
    (is      (bool "(vle-vector-isparallel '(1 2 3) '(-2 -4 -6))"))
    (is      (bool "(vle-vector-iscodirectional '(1 0 0) '(5 0 0))"))
    (is (not (bool "(vle-vector-iscodirectional '(1 0 0) '(-2 0 0))")))
    (is      (bool "(vle-vector-isperpendicular '(1 0 0) '(0 1 0))"))
    (is (not (bool "(vle-vector-isperpendicular '(1 0 0) '(1 1 0))")))
    (is      (bool "(vle-vector-isxaxis '(1 0 0))"))
    (is      (bool "(vle-vector-isyaxis '(0 1 0))"))
    (is      (bool "(vle-vector-iszaxis '(0 0 1))"))
    (is (not (bool "(vle-vector-isxaxis '(0 1 0))")))))

(test m3b-vle-vector-getperpvector-orthogonal
  "GETPERPVECTOR's result is orthogonal to its input."
  (reset-autolisp-symbol-table)
  (let* ((v   (run-autolisp-string "'(1 2 3)" :setup-fn #'install-core-into))
         (p   (run-autolisp-string
               "(vle-vector-getperpvector '(1 2 3))"
               :setup-fn #'install-core-into))
         (dot (run-autolisp-string
               "(vle-vector-dotproduct '(1 2 3) (vle-vector-getperpvector '(1 2 3)))"
               :setup-fn #'install-core-into)))
    (declare (ignore v p))
    (is (< (abs dot) 1.0d-9))))

(test m3b-vle-vector-getucs-orthonormal-basis
  "GETUCS of world-Z returns the standard X/Y axes; both axes are
unit-length and mutually orthogonal."
  (reset-autolisp-symbol-table)
  (let ((basis (run-autolisp-string "(vle-vector-getucs '(0 0 1))"
                                    :setup-fn #'install-core-into)))
    (is (consp basis))
    (is (= 2 (length basis)))
    (is (close-vec3-p (first  basis) '(1d0 0d0 0d0)))
    (is (close-vec3-p (second basis) '(0d0 1d0 0d0)))))

(test m3b-vle-vector-to2d-to3d
  "TO2D drops Z; TO3D pads Z=0 on a 2-list input."
  (reset-autolisp-symbol-table)
  (let ((two (run-autolisp-string "(vle-vector-to2d '(1 2 3))"
                                  :setup-fn #'install-core-into))
        (three (run-autolisp-string "(vle-vector-to3d '(1 2))"
                                    :setup-fn #'install-core-into)))
    (is (= 2 (length two)))
    (is (< (abs (- 1d0 (first  two))) 1.0d-9))
    (is (< (abs (- 2d0 (second two))) 1.0d-9))
    (is (close-vec3-p three '(1d0 2d0 0d0)))))

(test m3b-vle-vector-tolerance-get-set
  "GETTOLERANCE returns the current value; SETTOLERANCE replaces
and returns the new value; subsequent predicates use it."
  (reset-autolisp-symbol-table)
  ;; Reset the shared parameter so independent test runs are
  ;; deterministic.
  (setf clautolisp.autolisp-builtins-core::*vle-vector-tolerance* 1.0d-10)
  (let ((before (run-autolisp-string "(vle-vector-gettolerance)"
                                     :setup-fn #'install-core-into)))
    (is (< (abs (- 1.0d-10 before)) 1.0d-20)))
  (let ((set-result (run-autolisp-string
                     "(vle-vector-settolerance 0.01)"
                     :setup-fn #'install-core-into)))
    (is (< (abs (- 0.01d0 set-result)) 1.0d-9)))
  ;; Restore.
  (setf clautolisp.autolisp-builtins-core::*vle-vector-tolerance* 1.0d-10))

;;;; ----- M3c missing-functions: VLE-* string / file / color / misc -----

(test m3c-vle-string-replace-replaces-all
  "(vle-string-replace new old in) replaces every occurrence."
  (reset-autolisp-symbol-table)
  (let ((result (run-autolisp-string
                 "(vle-string-replace \"X\" \"BAR\" \"FOO BAR BAZ BAR\")"
                 :setup-fn #'install-core-into)))
    (is (typep result 'autolisp-string))
    (is (string= "FOO X BAZ X" (autolisp-string-value result)))))

(test m3c-vle-string-split-keeps-empty-tokens
  "(vle-string-split keys s) splits on any char in KEYS; empty
tokens between adjacent delimiters are kept."
  (reset-autolisp-symbol-table)
  (let ((tokens (run-autolisp-string
                 "(vle-string-split \",\" \"a,b,,c\")"
                 :setup-fn #'install-core-into)))
    (is (consp tokens))
    (is (= 4 (length tokens)))
    (is (string= "a" (autolisp-string-value (first  tokens))))
    (is (string= "b" (autolisp-string-value (second tokens))))
    (is (string= ""  (autolisp-string-value (third  tokens))))
    (is (string= "c" (autolisp-string-value (fourth tokens))))))

(test m3c-vle-file->list-reads-and-skips-comments
  "(vle-file->list path commentchar) returns one line per
non-comment line; lines whose first non-whitespace char matches
commentchar are dropped."
  (reset-autolisp-symbol-table)
  (let ((path (uiop:tmpize-pathname
               (uiop:with-temporary-file (:pathname p :keep t) p))))
    (unwind-protect
         (progn
           (with-open-file (out path :direction :output
                                     :if-exists :supersede)
             (format out "line 1~%# comment~%   # indented comment~%line 4~%"))
           (let ((lines (run-autolisp-string
                         (format nil "(vle-file->list ~S \"#\")"
                                 (namestring path))
                         :setup-fn #'install-core-into)))
             (is (consp lines))
             (is (= 2 (length lines)))
             (is (string= "line 1" (autolisp-string-value (first  lines))))
             (is (string= "line 4" (autolisp-string-value (second lines))))))
      (ignore-errors (delete-file path)))))

(test m3c-vle-filep-recognises-open-handles
  "(vle-filep H) is T for an OPEN'd file handle, nil for anything else."
  (reset-autolisp-symbol-table)
  ;; A non-file value returns nil.
  (is (null (run-autolisp-string "(vle-filep 'foo)"
                                 :setup-fn #'install-core-into))))

(test m3c-vle-file-encoding-stub-returns-string
  "(vle-file-encoding handle) returns an autolisp-string with the
session's encoding; the per-handle reset is the stub."
  (reset-autolisp-symbol-table)
  (let ((result (run-autolisp-string "(vle-file-encoding nil)"
                                     :setup-fn #'install-core-into)))
    (is (typep result 'autolisp-string))
    (is (plusp (length (autolisp-string-value result))))))

(test m3c-vle-aci2rgb-known-indices
  "ACI 1 -> red, 7 -> white, 100 -> nil (in the un-tabulated 10-249 range)."
  (reset-autolisp-symbol-table)
  (is (equal '(255 0 0)
             (run-autolisp-string "(vle-aci2rgb 1)" :setup-fn #'install-core-into)))
  (is (equal '(255 255 255)
             (run-autolisp-string "(vle-aci2rgb 7)" :setup-fn #'install-core-into)))
  (is (null (run-autolisp-string "(vle-aci2rgb 100)"
                                 :setup-fn #'install-core-into))))

(test m3c-vle-rgb2aci-nearest-known
  "(vle-rgb2aci '(R G B)) returns the index of the nearest known
palette entry."
  (reset-autolisp-symbol-table)
  (is (eql 1 (run-autolisp-string "(vle-rgb2aci '(255 0 0))"
                                  :setup-fn #'install-core-into)))
  (is (eql 5 (run-autolisp-string "(vle-rgb2aci '(0 0 255))"
                                  :setup-fn #'install-core-into))))

(test m3c-vle-ping-alive-always-true
  "(vle-ping-alive) returns T."
  (reset-autolisp-symbol-table)
  (let ((r (run-autolisp-string "(vle-ping-alive)"
                                :setup-fn #'install-core-into)))
    (is (typep r 'autolisp-symbol))
    (is (string= "T" (autolisp-symbol-name r)))))

(test m3c-vle-optimiser-and-fastcom-stubs-return-nil
  "VLE-OPTIMISER / VLE-OPTIMIZER / VLE-FASTCOM stubs return nil."
  (reset-autolisp-symbol-table)
  (dolist (form '("(vle-optimiser t)" "(vle-optimizer nil)" "(vle-fastcom t)"))
    (is (null (run-autolisp-string form :setup-fn #'install-core-into))
        "~A should return nil under the stub impl" form)))

;;;; ----- M3d missing-functions: VLE-* CAD / COM / UI stubs -----

(test m3d-vle-all-stubs-registered
  "Every M3d stub binds a callable subr on its AutoLISP symbol."
  (reset-autolisp-symbol-table)
  (install-core-builtins)
  (dolist (name '("VLE-ALERT" "VLE-COLLECTION->LIST" "VLE-COMPILE-SHAPE"
                  "VLE-CURVE-GETPERIMETER" "VLE-DICTIONARY-LIST"
                  "VLE-DICTOBJNAME" "VLE-DICTSEARCH"
                  "VLE-DISPLAYPAUSE" "VLE-DISPLAYUPDATE"
                  "VLE-EDITTEXTINPLACE" "VLE-ENABLESERVERBUSY"
                  "VLE-ENAME-VALID" "VLE-END-TRANSACTION"
                  "VLE-START-TRANSACTION" "VLE-ENTGET" "VLE-ENTGET-M"
                  "VLE-ENTGET-MASSOC" "VLE-ENTMOD" "VLE-ENTMOD-M"
                  "VLE-EXTENSIONS-ACTIVE" "VLE-GETGEOMEXTENTS"
                  "VLE-HIDEPROMPTMENU" "VLE-SHOWPROMPTMENU"
                  "VLE-IS-CURVE" "VLE-LICENSELEVEL"
                  "VLE-LISPINSTALL" "VLE-LISPVERSION" "VLE-NTH<X>"
                  "VLE-SAFEARRAY->LIST" "VLE-SELECTIONSET->LIST"
                  "VLE-SUNID" "VLE-TABLE-LIST" "VLE-TABLE-LIST-ALL"
                  "VLE-TBLSEARCH"))
    (let* ((sym (find-autolisp-symbol name))
           (subr (and sym (autolisp-symbol-function sym))))
      (is (typep subr 'autolisp-subr) "~A should bind to a SUBR, got ~S" name subr))))

(test m3d-vle-entity-stubs-return-nil
  "Entity DB / dictionary / table family stubs return nil so user
code that wraps them in IF / WHEN keeps the falsy branch."
  (reset-autolisp-symbol-table)
  (dolist (form '("(vle-entget 'foo)"
                  "(vle-entmod nil)"
                  "(vle-dictionary-list)"
                  "(vle-tblsearch \"LAYER\" \"X\")"
                  "(vle-table-list \"LAYER\")"
                  "(vle-is-curve 'foo)"
                  "(vle-ename-valid 'foo)"
                  "(vle-curve-getperimeter 'foo)"
                  "(vle-collection->list 'foo)"
                  "(vle-selectionset->list 'foo)"))
    (is (null (run-autolisp-string form :setup-fn #'install-core-into))
        "~A should return nil under the stub impl" form)))

(test m3d-vle-info-stubs-return-strings
  "LICENSELEVEL / LISPINSTALL / LISPVERSION return string
placeholders so user code can format them without nil-checking."
  (reset-autolisp-symbol-table)
  (dolist (form '("(vle-licenselevel)" "(vle-lispinstall)" "(vle-lispversion)"))
    (let ((result (run-autolisp-string form :setup-fn #'install-core-into)))
      (is (typep result 'autolisp-string)
          "~A should return a string, got ~S" form result))))

(test m3d-vle-extensions-active-is-true
  "(vle-extensions-active) returns T — the VLE-* names ARE
registered, even if many are stubs."
  (reset-autolisp-symbol-table)
  (let ((result (run-autolisp-string "(vle-extensions-active)"
                                     :setup-fn #'install-core-into)))
    (is (typep result 'autolisp-symbol))
    (is (string= "T" (autolisp-symbol-name result)))))

;;;; ----- Coverage backfill: tests for the genuinely-untested 130 -----
;;;;
;;;; Each test here exists because the function it covers was, per the
;;;; coverage sweep, registered but never called from any test snippet.
;;;; Grouped by family so the per-test bodies are compact (one batched
;;;; check per family beats writing 14 separate one-liners for the Cxxr
;;;; accessors). Skipped: DOC_CLIPBOARD (mutates the user's system
;;;; clipboard), STARTAPP (spawns a real process; flaky in CI), DCL
;;;; tile/dialog builtins (covered by autolisp-dcl suite via a
;;;; different machinery), entity/sysvar/prompt builtins (covered by
;;;; autolisp-mock-host suite), VLAX-* (need ActiveX bridge), VLR-*
;;;; reactors (need reactor dispatcher).

(test coverage-cxxr-accessor-family
  "Deeper Cxxxxr accessors (depth 4) return the expected nested
element. Construction: a 16-leaf binary cons tree where every
leaf is labelled with its path from the root, read left-to-right
in A/D notation. Convenient property: for any C{w}R accessor,
the leaf it returns has label = reverse(w). Covers the 14
depth-4 accessors not exercised by the existing
builtin-caxr-family test (which only covers depth-2 / depth-3
plus one depth-4 sample)."
  (reset-autolisp-symbol-table)
  (let ((tree
         ;; ((((aaaa . aaad) . (aada . aadd)) . ((adaa . adad) . (adda . addd)))
         ;;  . (((daaa . daad) . (dada . dadd)) . ((ddaa . ddad) . (ddda . dddd))))
         (concatenate 'string
                      "((((aaaa . aaad) . (aada . aadd))"
                      " . ((adaa . adad) . (adda . addd)))"
                      " . (((daaa . daad) . (dada . dadd))"
                      " . ((ddaa . ddad) . (ddda . dddd))))")))
    (dolist (pair '(("caaadr" "DAAA")
                    ("caadar" "ADAA")
                    ("caaddr" "DDAA")
                    ("cadaar" "AADA")
                    ("cadadr" "DADA")
                    ("caddar" "ADDA")
                    ("cdaaar" "AAAD")
                    ("cdaadr" "DAAD")
                    ("cdadar" "ADAD")
                    ("cdaddr" "DDAD")
                    ("cddaar" "AADD")
                    ("cddadr" "DADD")
                    ("cdddar" "ADDD")
                    ("cddddr" "DDDD")))
      (let* ((accessor (first pair))
             (expected (second pair))
             (form (format nil "(~A '~A)" accessor tree))
             (r (run-autolisp-string form :setup-fn #'install-core-into)))
        (is (typep r 'autolisp-symbol)
            "~A returned ~S, not a symbol" form r)
        (is (string= expected (autolisp-symbol-name r))
            "~A returned ~S, expected ~A" form r expected)))))

(test coverage-numeric-primitives
  "(1+ N), (1- N), (~ N) return the expected integers."
  (reset-autolisp-symbol-table)
  (is (eql 6  (run-autolisp-string "(1+ 5)" :setup-fn #'install-core-into)))
  (is (eql 4  (run-autolisp-string "(1- 5)" :setup-fn #'install-core-into)))
  ;; ~ is bitwise NOT: ~0 = all 1-bits = -1 in two's complement.
  (is (eql -1 (run-autolisp-string "(~ 0)"  :setup-fn #'install-core-into)))
  (is (eql -6 (run-autolisp-string "(~ 5)"  :setup-fn #'install-core-into))))

(test coverage-boole-bitwise-reducer
  "(boole OP I1 I2 ...) routes the bitwise op selected by OP.
OP=1 is logical-AND per the documented truth-table layout."
  (reset-autolisp-symbol-table)
  ;; BOOLE op=1 (AND) over 5 (101b) and 3 (011b) -> 1 (001b).
  (is (eql 1 (run-autolisp-string "(boole 1 5 3)" :setup-fn #'install-core-into))))

(test coverage-angtos-radians-default
  "(angtos 1.5708) returns a non-empty string for the radians input."
  (reset-autolisp-symbol-table)
  (let ((result (run-autolisp-string "(angtos 1.5708)"
                                     :setup-fn #'install-core-into)))
    (is (typep result 'autolisp-string))
    (is (plusp (length (autolisp-string-value result))))))

(test coverage-angtof-parses-string
  "(angtof \"1.5708\") parses to a real."
  (reset-autolisp-symbol-table)
  (let ((result (run-autolisp-string "(angtof \"1.5708\")"
                                     :setup-fn #'install-core-into)))
    (is (numberp result))
    (is (< (abs (- 1.5708d0 result)) 1.0d-6))))

(test coverage-distof-parses-string
  "(distof \"1.5\") parses to 1.5 as a real."
  (reset-autolisp-symbol-table)
  (let ((result (run-autolisp-string "(distof \"1.5\")"
                                     :setup-fn #'install-core-into)))
    (is (numberp result))
    (is (< (abs (- 1.5d0 result)) 1.0d-9))))

(test coverage-string-split-alias-of-vl-string-split
  "STRING-SPLIT is the documented alias of VL-STRING-SPLIT.
Signature is (SEPARATOR SOURCE)."
  (reset-autolisp-symbol-table)
  (let ((result (run-autolisp-string "(string-split \":\" \"a:b:c\")"
                                     :setup-fn #'install-core-into)))
    (is (consp result))
    (is (= 3 (length result)))
    (is (string= "a" (autolisp-string-value (first result))))
    (is (string= "b" (autolisp-string-value (second result))))
    (is (string= "c" (autolisp-string-value (third result))))))

(test coverage-push-error-using-pair
  "Both *PUSH-* variants push onto *autolisp-error-mode-stack*, with
*POP-* draining in LIFO order."
  (reset-autolisp-symbol-table)
  (setf clautolisp.autolisp-builtins-core::*autolisp-error-mode-stack* nil)
  (run-autolisp-string "(*push-error-using-command*)"
                       :setup-fn #'install-core-into)
  (is (equal '(:command)
             clautolisp.autolisp-builtins-core::*autolisp-error-mode-stack*))
  (run-autolisp-string "(*push-error-using-stack*)"
                       :setup-fn #'install-core-into)
  (is (equal '(:stack :command)
             clautolisp.autolisp-builtins-core::*autolisp-error-mode-stack*)))

(test coverage-vl-enable-user-cancel-returns-true
  "(vl-enable-user-cancel T|nil) returns T (we accept the flag
silently — the CL impls deliver SIGINT to the REPL natively)."
  (reset-autolisp-symbol-table)
  (let ((r (run-autolisp-string "(vl-enable-user-cancel t)"
                                :setup-fn #'install-core-into)))
    (is (typep r 'autolisp-symbol))
    (is (string= "T" (autolisp-symbol-name r)))))

(test coverage-vl-rmdir-removes-empty-directory
  "(vl-rmdir path) deletes an empty directory and returns T;
returns nil if the path is missing."
  (reset-autolisp-symbol-table)
  (let* ((unique (format nil "/tmp/clautolisp-vl-rmdir-~A-~A/"
                         (get-universal-time) (random 100000000)))
         (tmp    (uiop:ensure-directory-pathname unique)))
    (ensure-directories-exist tmp)
    (unwind-protect
         (let ((result (run-autolisp-string
                        (format nil "(vl-rmdir ~S)" unique)
                        :setup-fn #'install-core-into)))
           (is (typep result 'autolisp-symbol)
               "vl-rmdir on existing empty dir should return T, got ~S" result)
           (is (string= "T" (autolisp-symbol-name result)))
           (is (not (uiop:directory-exists-p tmp))
               "directory should be gone after vl-rmdir"))
      (ignore-errors (uiop:delete-directory-tree tmp :validate t))))
  (is (null (run-autolisp-string
             "(vl-rmdir \"/tmp/clautolisp-definitely-not-there-XYZ-99999\")"
             :setup-fn #'install-core-into))))

(test coverage-vl-setcurrentdir-changes-cwd
  "(vl-setcurrentdir path) changes the working directory and returns
the new cwd string."
  (reset-autolisp-symbol-table)
  (let ((original (uiop:getcwd))
        (target (uiop:temporary-directory)))
    (unwind-protect
         (let ((result (run-autolisp-string
                        (format nil "(vl-setcurrentdir ~S)" (namestring target))
                        :setup-fn #'install-core-into)))
           (is (typep result 'autolisp-string)
               "vl-setcurrentdir should return the new cwd string, got ~S"
               result)
           (is (plusp (length (autolisp-string-value result)))))
      (uiop:chdir original)))
  (is (null (run-autolisp-string "(vl-setcurrentdir \"/no/such/dir/at/all\")"
                                 :setup-fn #'install-core-into))))

(test coverage-vl-bt-family
  "VL-BT prints a backtrace and returns nil; VL-BT-ON enables it
and returns T; VL-BT-OFF disables and returns nil."
  (reset-autolisp-symbol-table)
  ;; VL-BT is allowed to print to *error-output*; we only check the
  ;; return values to keep the test output clean.
  (let ((on  (run-autolisp-string "(vl-bt-on)"  :setup-fn #'install-core-into))
        (off (run-autolisp-string "(vl-bt-off)" :setup-fn #'install-core-into)))
    (is (typep on 'autolisp-symbol))
    (is (string= "T" (autolisp-symbol-name on)))
    (is (null off))))

(test coverage-vl-catch-all-error-stack
  "After a (vl-catch-all-apply) returns an error object, the
matching (vl-catch-all-error-stack OBJ) returns a non-nil
diagnostic (the recorded call-stack list)."
  (reset-autolisp-symbol-table)
  (let ((stk (run-autolisp-string
              "(vl-catch-all-error-stack
                  (vl-catch-all-apply
                    (function (lambda () (car 1)))
                    (quote ())))"
              :setup-fn #'install-core-into)))
    ;; Stack representation is non-nil — either a list of frames or a
    ;; printed string, depending on what VL-CATCH-ALL-ERROR-STACK
    ;; chooses to surface. The contract is "non-nil after a real error".
    (is (not (null stk))
        "(vl-catch-all-error-stack ERROR-OBJ) should be non-nil after a real error, got ~S" stk)))

(test coverage-vle-nth-shortcuts-rest-of-family
  "VLE-NTH1..NTH8 — the indices skipped by the M3a sample
(M3A-VLE-NTH-SHORTCUTS covered 0, 3, 9 only). Walks the whole
family in one shot."
  (reset-autolisp-symbol-table)
  (dolist (pair '((1 . B) (2 . C) (4 . E) (5 . F) (6 . G) (7 . H) (8 . I)))
    (let* ((idx (car pair))
           (expected (string (cdr pair)))
           (form (format nil "(vle-nth~D '(a b c d e f g h i j))" idx))
           (r (run-autolisp-string form :setup-fn #'install-core-into)))
      (is (typep r 'autolisp-symbol) "~A returned ~S" form r)
      (is (string= expected (autolisp-symbol-name r))
          "~A returned ~S, expected ~A" form r expected))))

(test coverage-vle-append-int64to32-startapp
  "Three M3 gap-fills: VLE-APPEND is the AutoLISP APPEND;
VLE-INT64TO32 wraps to 32-bit signed; VLE-STARTAPP returns nil
when given a non-existent command (we don't actually spawn /bin/true
to keep the test deterministic across hosts)."
  (reset-autolisp-symbol-table)
  (is (equal '(1 2 3 4)
             (run-autolisp-string "(vle-append '(1 2) '(3 4))"
                                  :setup-fn #'install-core-into)))
  (is (eql 42
           (run-autolisp-string "(vle-int64to32 42)"
                                :setup-fn #'install-core-into)))
  ;; VLE-STARTAPP on a guaranteed-missing binary: nil.
  (is (null (run-autolisp-string
             "(vle-startapp \"/no/such/binary/at/all-XYZ\" nil nil)"
             :setup-fn #'install-core-into))))

(test coverage-vle-member-and-enamep-and-picksetp
  "Three predicate-style gap-fills."
  (reset-autolisp-symbol-table)
  ;; VLE-MEMBER: returns the tail starting at the match (CL MEMBER).
  (let ((tail (run-autolisp-string "(vle-member 'b '(a b c))"
                                   :setup-fn #'install-core-into)))
    (is (consp tail))
    (is (= 2 (length tail))))
  ;; VLE-ENAMEP / VLE-PICKSETP: both nil for a bare integer.
  (is (null (run-autolisp-string "(vle-enamep 5)"
                                 :setup-fn #'install-core-into)))
  (is (null (run-autolisp-string "(vle-picksetp 5)"
                                 :setup-fn #'install-core-into))))

(test coverage-vle-set-cdrassoc-mutates
  "(vle-set-cdrassoc KEY ALIST VAL) replaces the cdr of every pair
whose car matches KEY; returns the (potentially-mutated) list.
Verified by re-querying with VLE-CDRASSOC after the mutation."
  (reset-autolisp-symbol-table)
  (let ((after-query
         (run-autolisp-string
          "(setq al (list (cons 'a 1) (cons 'b 2) (cons 'c 3)))
           (vle-set-cdrassoc 'b al 99)
           (vle-cdrassoc 'b al)"
          :setup-fn #'install-core-into)))
    (is (eql 99 after-query)
        "(b . 2) should have become (b . 99); cdrassoc returned ~S"
        after-query)))

;;;; ----- M4 missing-functions: VLISP-* IDE stubs -----

(test m4-vlisp-all-stubs-registered
  "All five VLISP-* names bind to a SUBR after install."
  (reset-autolisp-symbol-table)
  (install-core-builtins)
  (dolist (name '("VLISP-COMPILE" "VLISP-EXPORT-SYMBOL"
                  "VLISP-IMPORT-SYMBOL" "VLISP-IMPORT-EXSUBRS"
                  "VLISP-OPTIMIZER"))
    (let* ((sym (find-autolisp-symbol name))
           (subr (and sym (autolisp-symbol-function sym))))
      (is (typep subr 'autolisp-subr) "~A should bind to a SUBR" name))))

(test m4-vlisp-compile-returns-nil
  "(vlisp-compile mode src) is a no-op returning nil."
  (reset-autolisp-symbol-table)
  (is (null (run-autolisp-string "(vlisp-compile 'sym \"foo.lsp\")"
                                 :setup-fn #'install-core-into)))
  (is (null (run-autolisp-string "(vlisp-compile 'sym \"foo.lsp\" \"foo.fas\")"
                                 :setup-fn #'install-core-into))))

(test m4-vlisp-export-symbol-records-and-returns-t
  "VLISP-EXPORT-SYMBOL pushes names into *vlisp-exported-symbols*
and returns T. Accepts both a single symbol and a list."
  (reset-autolisp-symbol-table)
  (setf clautolisp.autolisp-builtins-core::*vlisp-exported-symbols* nil)
  (let ((r1 (run-autolisp-string "(vlisp-export-symbol 'foo)"
                                 :setup-fn #'install-core-into))
        (r2 (run-autolisp-string "(vlisp-export-symbol '(bar baz))"
                                 :setup-fn #'install-core-into)))
    (is (typep r1 'autolisp-symbol))
    (is (string= "T" (autolisp-symbol-name r1)))
    (is (typep r2 'autolisp-symbol))
    (is (string= "T" (autolisp-symbol-name r2))))
  ;; All three names recorded (order not guaranteed).
  (let ((recorded clautolisp.autolisp-builtins-core::*vlisp-exported-symbols*))
    (is (member "FOO" recorded :test #'string=))
    (is (member "BAR" recorded :test #'string=))
    (is (member "BAZ" recorded :test #'string=)))
  ;; Cleanup
  (setf clautolisp.autolisp-builtins-core::*vlisp-exported-symbols* nil))

(test m4-vlisp-import-symbol-returns-t
  "VLISP-IMPORT-SYMBOL is a no-op returning T."
  (reset-autolisp-symbol-table)
  (let ((r (run-autolisp-string "(vlisp-import-symbol '(a b c))"
                                :setup-fn #'install-core-into)))
    (is (typep r 'autolisp-symbol))
    (is (string= "T" (autolisp-symbol-name r)))))

(test m4-vlisp-import-exsubrs-returns-t
  "VLISP-IMPORT-EXSUBRS — no-op, returns T."
  (reset-autolisp-symbol-table)
  (let ((r (run-autolisp-string "(vlisp-import-exsubrs)"
                                :setup-fn #'install-core-into)))
    (is (typep r 'autolisp-symbol))
    (is (string= "T" (autolisp-symbol-name r)))))

(test m4-vlisp-optimizer-returns-nil
  "VLISP-OPTIMIZER returns nil (no optimiser to toggle/query)."
  (reset-autolisp-symbol-table)
  (is (null (run-autolisp-string "(vlisp-optimizer)"
                                 :setup-fn #'install-core-into)))
  (is (null (run-autolisp-string "(vlisp-optimizer t)"
                                 :setup-fn #'install-core-into))))

;;;; ----- M5 missing-functions: core/misc rest -----

(test m5-native-vl-load-family-returns-t
  "VL-INIT / VL-LOAD-COM / VL-LOAD-REACTORS / VL-LOAD-ALL all
return T — no-op success on a system without VLX / COM /
reactors."
  (reset-autolisp-symbol-table)
  (flet ((true-p (form)
           (let ((r (run-autolisp-string form :setup-fn #'install-core-into)))
             (and (typep r 'autolisp-symbol)
                  (string= "T" (autolisp-symbol-name r))))))
    (is (true-p "(vl-init)"))
    (is (true-p "(vl-load-com)"))
    (is (true-p "(vl-load-reactors)"))
    (is (true-p "(vl-load-all)"))))

(test m5-layoutlist-returns-model-only
  "(layoutlist) returns a single-element list with the autolisp-string \"Model\"."
  (reset-autolisp-symbol-table)
  (let ((result (run-autolisp-string "(layoutlist)"
                                     :setup-fn #'install-core-into)))
    (is (consp result))
    (is (= 1 (length result)))
    (is (typep (first result) 'autolisp-string))
    (is (string= "Model" (autolisp-string-value (first result))))))

(test m5-vports-returns-single-default
  "(vports) returns a list with one entry: id=1, full-screen corners."
  (reset-autolisp-symbol-table)
  (let* ((result (run-autolisp-string "(vports)"
                                      :setup-fn #'install-core-into))
         (first-entry (first result)))
    (is (consp result))
    (is (= 1 (length result)))
    (is (eql 1 (first first-entry)))
    (is (equal '(0.0d0 0.0d0) (second first-entry)))
    (is (equal '(1.0d0 1.0d0) (third first-entry)))))

(test m5-acdimenableupdate-returns-t
  "(acdimenableupdate) and (acdimenableupdate <flag>) both return T."
  (reset-autolisp-symbol-table)
  (flet ((true-p (form)
           (let ((r (run-autolisp-string form :setup-fn #'install-core-into)))
             (and (typep r 'autolisp-symbol)
                  (string= "T" (autolisp-symbol-name r))))))
    (is (true-p "(acdimenableupdate)"))
    (is (true-p "(acdimenableupdate t)"))
    (is (true-p "(acdimenableupdate nil)"))))

(test m5-vl-registry-roundtrip
  "VL-REGISTRY-WRITE / READ / DELETE round-trip through the
session table; DESCENDENTS lists value-names."
  (reset-autolisp-symbol-table)
  (clrhash clautolisp.autolisp-builtins-core::*vl-registry*)
  ;; Write + read
  (let ((written (run-autolisp-string
                  "(vl-registry-write \"HKLM/test\" \"k1\" \"v1\")"
                  :setup-fn #'install-core-into)))
    (is (typep written 'autolisp-string))
    (is (string= "v1" (autolisp-string-value written))))
  (let ((read-back (run-autolisp-string
                    "(vl-registry-read \"HKLM/test\" \"k1\")"
                    :setup-fn #'install-core-into)))
    (is (typep read-back 'autolisp-string))
    (is (string= "v1" (autolisp-string-value read-back))))
  ;; Descendents
  (run-autolisp-string "(vl-registry-write \"HKLM/test\" \"k2\" \"v2\")"
                       :setup-fn #'install-core-into)
  (let ((children (run-autolisp-string
                   "(vl-registry-descendents \"HKLM/test\" t)"
                   :setup-fn #'install-core-into)))
    (is (consp children))
    (is (= 2 (length children)))
    (is (string= "k1" (autolisp-string-value (first  children))))
    (is (string= "k2" (autolisp-string-value (second children)))))
  ;; Delete + miss-on-read
  (let ((deleted (run-autolisp-string
                  "(vl-registry-delete \"HKLM/test\" \"k1\")"
                  :setup-fn #'install-core-into)))
    (is (typep deleted 'autolisp-symbol))
    (is (string= "T" (autolisp-symbol-name deleted))))
  (is (null (run-autolisp-string "(vl-registry-read \"HKLM/test\" \"k1\")"
                                 :setup-fn #'install-core-into)))
  ;; Cleanup
  (clrhash clautolisp.autolisp-builtins-core::*vl-registry*))

(test m5-getcfg-setcfg-roundtrip
  "SETCFG / GETCFG round-trip through the session table."
  (reset-autolisp-symbol-table)
  (clrhash clautolisp.autolisp-builtins-core::*acad-cfg*)
  (let ((written (run-autolisp-string
                  "(setcfg \"AppData/test\" \"hello\")"
                  :setup-fn #'install-core-into)))
    (is (typep written 'autolisp-string))
    (is (string= "hello" (autolisp-string-value written))))
  (let ((read-back (run-autolisp-string "(getcfg \"AppData/test\")"
                                        :setup-fn #'install-core-into)))
    (is (typep read-back 'autolisp-string))
    (is (string= "hello" (autolisp-string-value read-back))))
  (is (null (run-autolisp-string "(getcfg \"AppData/missing\")"
                                 :setup-fn #'install-core-into)))
  (clrhash clautolisp.autolisp-builtins-core::*acad-cfg*))

(test m5-all-stubs-registered
  "Every M5 stub binds a callable SUBR on its AutoLISP symbol."
  (reset-autolisp-symbol-table)
  (install-core-builtins)
  (dolist (name '("ADS" "INITDIA" "INSPECTOR" "DLG-SYSVARS" "EXPAND"
                  "LISP$INSTALL" "LISP$ENABLEFASTCOM" "BPOLY"
                  "BCAD$DISABLE-EXTENDED-ERROR" "BCAD$LICENSELEVELS"
                  "VMON" "_VLAX-SAFEARRAY-MODE"
                  "LISTALLPROPERTIES" "DUMPALLPROPERTIES"
                  "ISPROPERTYREADONLY" "ISPROPERTYVALID"
                  "GETPROPERTYVALUE" "SETPROPERTYVALUE"
                  "VL-LIST-LOADED-LISP" "VL-LIST-LOADED-VLX"
                  "VL-VLX-LOADED-P" "VL-UNLOAD-VLX"
                  "VL-LIST-EXPORTED-FUNCTIONS"
                  "VL-VBALOAD" "VL-VBARUN" "VL-CMDF"
                  "VL-ACAD-DEFUN" "VL-ACAD-UNDEFUN"
                  "VL-GET-RESOURCE" "VL-GETGEOMEXTENTS"
                  "VL-HIDEPROMPTMENU" "VL-SHOWPROMPTMENU"
                  "VL-LOCAL-UNDO-CLEAR" "VL-LOCAL-UNDO-POP"
                  "VL-LOCAL-UNDO-PUSH" "VL-LOCAL-UNDO-RESET"
                  "VL-LOCAL-UNDO-STEPS"
                  "VL-ANNOTATIVE-ADDSCALE" "VL-ANNOTATIVE-GET"
                  "VL-ANNOTATIVE-GETSCALES" "VL-ANNOTATIVE-REMOVE"
                  "VL-ANNOTATIVE-REMOVESCALE" "VL-ANNOTATIVE-RESET"
                  "VL-ANNOTATIVE-SCALELIST" "VL-ANNOTATIVE-SET"
                  "VL-ANNOTATIVE-SETSCALES" "VL-ANNOTATIVE-SUPPORTED"
                  "VL-SUBENT-ATPOINT" "VL-SUBENT-SELECT"
                  "VL-SUBENT-SSADD" "VL-SUBENT-SSDEL"
                  "VL-SUBENT-SSMEMB"
                  "VL-VPLAYER-GET-COLOR" "VL-VPLAYER-GET-LINETYPE"
                  "VL-VPLAYER-GET-LINEWEIGHT" "VL-VPLAYER-GET-TRANSPARENCY"
                  "VL-VPLAYER-SET-COLOR" "VL-VPLAYER-SET-LINETYPE"
                  "VL-VPLAYER-SET-LINEWEIGHT" "VL-VPLAYER-SET-TRANSPARENCY"
                  "VL-VPLAYER-SET-TRUECOLOR"
                  "VL-VECTOR-PROJECT-POINTTOENTITY"))
    (let* ((sym (find-autolisp-symbol name))
           (subr (and sym (autolisp-symbol-function sym))))
      (is (typep subr 'autolisp-subr) "~A should bind to a SUBR, got ~S" name subr))))

(test m5-stubs-return-nil
  "Spot-check that the M5 stubs return nil under representative calls."
  (reset-autolisp-symbol-table)
  (dolist (form '("(ads)"
                  "(initdia)"
                  "(inspector 'foo)"
                  "(vl-list-loaded-lisp)"
                  "(vl-list-loaded-vlx)"
                  "(vl-vlx-loaded-p \"foo.vlx\")"
                  "(vl-cmdf \"FOO\")"
                  "(vl-vbaload \"x.vba\")"
                  "(vl-get-resource \"foo\")"
                  "(vl-annotative-supported 'foo)"
                  "(vl-annotative-get 'foo)"
                  "(vl-subent-atpoint nil)"
                  "(vl-vplayer-get-color \"Layer\" 1)"
                  "(vl-local-undo-clear)"
                  "(vl-vector-project-pointtoentity '(0 0 0) 'foo nil)"
                  "(bpoly '(0 0))"
                  "(vmon)"
                  "(listallproperties 'foo)"))
    (is (null (run-autolisp-string form :setup-fn #'install-core-into))
        "~A should return nil under the stub impl" form)))

;;;; ----- LOAD honours the AutoLISP-level *AUTOLISP-FILE-ENCODING* -----

(test load-honours-autolisp-file-encoding-override
  "A user's (setq *autolisp-file-encoding* \"ISO-8859-1\") at the
REPL must affect the next LOAD. Without the override, the
CL-level session-default-source-encoding silently wins — a
long-standing bug that produced 'octet sequence cannot be
decoded' errors when a UTF-8 session loaded a Latin-1 source.

Fixture: a file with a non-ASCII Latin-1 byte (#xE9 = é).
Under UTF-8 the file is invalid (#xE9 starts a 2-byte sequence
expecting a continuation byte that isn't there). Under
ISO-8859-1 it's valid and the read-in string is one char long.

We assert the positive case: ISO-8859-1 override lets the load
succeed and the string carries one character. The negative case
(UTF-8 fails) isn't portably checkable here — SBCL and CCL
recover from invalid UTF-8 differently."
  (reset-autolisp-symbol-table)
  (uiop:with-temporary-file (:pathname path :type "lsp" :keep nil)
    (with-open-file (out path :direction :output
                              :if-exists :supersede
                              :element-type '(unsigned-byte 8))
      ;; "(setq msg \"\xE9\")\n" — Latin-1 e-acute inside a string.
      (write-sequence #(40 115 101 116 113 32 109 115 103 32 34
                        #xE9 34 41 10)
                      out))
    (let ((result (run-autolisp-string
                   (format nil "(setq *autolisp-file-encoding* \"ISO-8859-1\")
                                (load ~S)
                                msg"
                           (namestring path))
                   :setup-fn #'install-core-into)))
      (is (typep result 'autolisp-string))
      (is (= 1 (length (autolisp-string-value result)))
          "Latin-1 byte 0xE9 should decode to a single character; got ~S"
          (and (typep result 'autolisp-string) (autolisp-string-value result))))))

;;;; ----- LOAD positional [encoding] argument (Phase 3) ---------------
;;;;
;;;; (load filename [onfailure [encoding]]) — the third positional
;;;; argument is the clautolisp-only per-call encoding override
;;;; specified in issues/open/encoding-dispatch.issue. String
;;;; designator (string or symbol) per the spec.
;;;;
;;;; These tests use the same Latin-1 fixture as the override test
;;;; above, but supply the encoding through LOAD's third argument
;;;; rather than via *AUTOLISP-FILE-ENCODING*. The per-call form must
;;;; override even when the global is bound to a different encoding.

(defun %write-latin1-msg-fixture (path)
  "Write the test fixture: a 16-byte file whose only non-ASCII byte
is 0xE9 (Latin-1 e-acute) inside a string literal. Decoding under
UTF-8 errors at the 0xE9; under ISO-8859-1 the byte decodes to a
single character. Used by the Phase-3 LOAD-encoding tests."
  (with-open-file (out path :direction :output
                            :if-exists :supersede
                            :element-type '(unsigned-byte 8))
    (write-sequence #(40 115 101 116 113 32 109 115 103 32 34
                      #xE9 34 41 10)
                    out)))

(test load-positional-encoding-string-overrides-global
  ;; The third positional argument wins over *AUTOLISP-FILE-ENCODING*.
  (reset-autolisp-symbol-table)
  (uiop:with-temporary-file (:pathname path :type "lsp" :keep nil)
    (%write-latin1-msg-fixture path)
    (let ((result (run-autolisp-string
                   (format nil "(setq *autolisp-file-encoding* \"WINDOWS-1252\")
                                (load ~S nil \"ISO-8859-1\")
                                msg"
                           (namestring path))
                   :setup-fn #'install-core-into)))
      (is (typep result 'autolisp-string))
      (is (= 1 (length (autolisp-string-value result)))
          "Per-call ISO-8859-1 should decode the 0xE9 byte as one char; got ~S"
          (and (typep result 'autolisp-string) (autolisp-string-value result))))))

(test load-positional-encoding-symbol-accepted
  ;; The string-designator contract — passing the encoding as a symbol
  ;; ('UTF-8 / 'ISO-8859-1 / …) — uses the symbol-name.
  (reset-autolisp-symbol-table)
  (uiop:with-temporary-file (:pathname path :type "lsp" :keep nil)
    (%write-latin1-msg-fixture path)
    (let ((result (run-autolisp-string
                   (format nil "(load ~S nil 'ISO-8859-1) msg"
                           (namestring path))
                   :setup-fn #'install-core-into)))
      (is (typep result 'autolisp-string))
      (is (= 1 (length (autolisp-string-value result)))))))

(test load-positional-encoding-rejects-non-designator
  ;; Integer 42 is not a string designator — must signal at the LOAD
  ;; call site, not crash silently later.
  (reset-autolisp-symbol-table)
  (uiop:with-temporary-file (:pathname path :type "lsp" :keep nil)
    (%write-latin1-msg-fixture path)
    (let ((signalled-p nil))
      (handler-case
          (run-autolisp-string
           (format nil "(load ~S nil 42)" (namestring path))
           :setup-fn #'install-core-into)
        (autolisp-runtime-error (c)
          (declare (ignore c))
          (setf signalled-p t)))
      (is (eq signalled-p t)))))

(test load-positional-encoding-rejects-unknown-name
  ;; Encoding names that PARSE-LOCALE-ENCODING-STRING doesn't
  ;; recognise (typos, made-up names) get a clean argument-error
  ;; before the LOAD's stream-decoding stage.
  (reset-autolisp-symbol-table)
  (uiop:with-temporary-file (:pathname path :type "lsp" :keep nil)
    (%write-latin1-msg-fixture path)
    (let ((signalled-p nil))
      (handler-case
          (run-autolisp-string
           (format nil "(load ~S nil \"\")" (namestring path))
           :setup-fn #'install-core-into)
        (autolisp-runtime-error (c)
          (declare (ignore c))
          (setf signalled-p t)))
      (is (eq signalled-p t)))))

(test load-without-encoding-still-uses-global
  ;; Backward-compatibility: omitting the third arg falls back to
  ;; the precedence chain — *AUTOLISP-FILE-ENCODING* wins when set.
  (reset-autolisp-symbol-table)
  (uiop:with-temporary-file (:pathname path :type "lsp" :keep nil)
    (%write-latin1-msg-fixture path)
    (let ((result (run-autolisp-string
                   (format nil "(setq *autolisp-file-encoding* \"ISO-8859-1\")
                                (load ~S)
                                msg"
                           (namestring path))
                   :setup-fn #'install-core-into)))
      (is (typep result 'autolisp-string))
      (is (= 1 (length (autolisp-string-value result)))))))

;;;; ----- enc-* diagnostics: per-dialect dispatch (Phase 4) -----------
;;;;
;;;; The runtime always honours LOAD's third positional [encoding]
;;;; argument; the diagnostic varies by dialect.
;;;;
;;;; --clautolisp        silent (native form)
;;;; --strict            enc-extension-used
;;;; --autocad-2026      enc-foreign-dialect
;;;; --bricscad-v26      enc-foreign-dialect
;;;;
;;;; The fixture captures *enc-diagnostic-stream* output, so the
;;;; tests don't have to read real *error-output*.

(defun %install-mock-host-and-core (context)
  "Wire a fresh MockHost into CONTEXT and install the core builtins.
Used by tests that exercise sysvar paths through GETVAR / SETVAR —
the bare RUN-AUTOLISP-STRING uses null-host which signals
:host-not-supported."
  (install-core-into context)
  (let ((session (clautolisp.autolisp-runtime:evaluation-context-session
                  context))
        (mock (clautolisp.autolisp-mock-host:make-mock-host)))
    (setf (clautolisp.autolisp-runtime.internal::runtime-session-host session)
          mock)))

(defun %capture-enc-diagnostics (form-source &key dialect)
  "Evaluate FORM-SOURCE through RUN-AUTOLISP-STRING under DIALECT,
returning (values RESULT DIAGNOSTIC-OUTPUT) where DIAGNOSTIC-OUTPUT
is the string written by SIGNAL-ENCODING-DIAGNOSTIC. DIALECT is a
keyword (:strict / :clautolisp / :autocad-2026 / :bricscad-v26)
which we resolve to the named-dialect descriptor.

The setup-fn wires a mock-host so GETVAR / SETVAR work — needed by
the LISPSYS tests; harmless for the LOAD tests that don't touch
sysvars."
  (let* ((sink (make-string-output-stream))
         (dialect-struct
          (or (clautolisp.autolisp-reader:find-autolisp-dialect dialect)
              (error "Unknown dialect keyword ~S" dialect))))
    (let* ((clautolisp.autolisp-runtime:*enc-diagnostic-stream* sink)
           (result (run-autolisp-string
                    form-source
                    :dialect dialect-struct
                    :setup-fn #'%install-mock-host-and-core)))
      (values result (get-output-stream-string sink)))))

(test load-encoding-diagnostic-silent-under-clautolisp
  (reset-autolisp-symbol-table)
  (uiop:with-temporary-file (:pathname path :type "lsp" :keep nil)
    (%write-latin1-msg-fixture path)
    (multiple-value-bind (result diagnostics)
        (%capture-enc-diagnostics
         (format nil "(load ~S nil \"ISO-8859-1\") msg" (namestring path))
         :dialect :clautolisp)
      (is (typep result 'autolisp-string))
      (is (string= "" diagnostics)
          "Expected no diagnostic under --clautolisp; got: ~S" diagnostics))))

(test load-encoding-diagnostic-enc-extension-used-under-strict
  (reset-autolisp-symbol-table)
  (uiop:with-temporary-file (:pathname path :type "lsp" :keep nil)
    (%write-latin1-msg-fixture path)
    (multiple-value-bind (result diagnostics)
        (%capture-enc-diagnostics
         (format nil "(load ~S nil \"ISO-8859-1\") msg" (namestring path))
         :dialect :strict)
      (is (typep result 'autolisp-string))
      (is (search "[enc-extension-used]" diagnostics)
          "Expected [enc-extension-used] diagnostic under --strict; got: ~S"
          diagnostics))))

(test load-encoding-diagnostic-enc-foreign-dialect-under-autocad
  (reset-autolisp-symbol-table)
  (uiop:with-temporary-file (:pathname path :type "lsp" :keep nil)
    (%write-latin1-msg-fixture path)
    (multiple-value-bind (result diagnostics)
        (%capture-enc-diagnostics
         (format nil "(load ~S nil \"ISO-8859-1\") msg" (namestring path))
         :dialect :autocad-2026)
      (is (typep result 'autolisp-string))
      (is (search "[enc-foreign-dialect]" diagnostics))
      (is (search "--autocad" diagnostics)
          "Expected --autocad sub-tag in foreign-dialect diagnostic; got: ~S"
          diagnostics))))

(test load-encoding-diagnostic-enc-foreign-dialect-under-bricscad
  (reset-autolisp-symbol-table)
  (uiop:with-temporary-file (:pathname path :type "lsp" :keep nil)
    (%write-latin1-msg-fixture path)
    (multiple-value-bind (result diagnostics)
        (%capture-enc-diagnostics
         (format nil "(load ~S nil \"ISO-8859-1\") msg" (namestring path))
         :dialect :bricscad-v26)
      (is (typep result 'autolisp-string))
      (is (search "[enc-foreign-dialect]" diagnostics))
      (is (search "--bricscad" diagnostics)))))

(test load-encoding-diagnostic-suppressed-when-encoding-omitted
  ;; LOAD without the third arg must NOT emit any encoding diagnostic
  ;; regardless of dialect.
  (reset-autolisp-symbol-table)
  (uiop:with-temporary-file (:pathname path :type "lsp" :keep nil)
    (%write-latin1-msg-fixture path)
    (dolist (d '(:strict :clautolisp :autocad-2026 :bricscad-v26))
      (multiple-value-bind (result diagnostics)
          (%capture-enc-diagnostics
           (format nil "(setq *autolisp-file-encoding* \"ISO-8859-1\")
                       (load ~S) msg"
                   (namestring path))
           :dialect d)
        (declare (ignore result))
        (is (string= "" diagnostics)
            "Bare LOAD must not emit enc-* under ~A; got: ~S" d diagnostics)))))

(test signal-encoding-diagnostic-rejects-unknown-code
  ;; Closed-set check: passing a non-listed code is a programmer error,
  ;; not a user-visible diagnostic.
  (let ((signalled-p nil))
    (handler-case
        (clautolisp.autolisp-runtime:signal-encoding-diagnostic
         :enc-typo-not-in-the-list "oops")
      (error (c)
        (declare (ignore c))
        (setf signalled-p t)))
    (is (eq signalled-p t))))

(test signal-encoding-diagnostic-suppress-flag-silences-output
  (let ((sink (make-string-output-stream)))
    (let ((clautolisp.autolisp-runtime:*enc-diagnostic-stream* sink)
          (clautolisp.autolisp-runtime:*enc-diagnostic-suppress-p* t))
      (clautolisp.autolisp-runtime:signal-encoding-diagnostic
       :enc-extension-used "should not appear"))
    (is (string= "" (get-output-stream-string sink)))))

;;;; ----- LISPSYS dispatch (Phase 6) ----------------------------------
;;;;
;;;; LISPSYS is an AutoCAD-only sysvar (introduced 2021) that gates
;;;; source-file encoding globally. BricsCAD does not expose it. The
;;;; encoding-dispatch.issue answer to the open question is: warn
;;;; loudly under all non-autocad dialects, do not forbid.
;;;;
;;;; Setvar with a value outside {0,1,2} additionally emits
;;;; enc-lispsys-out-of-range — the spec mandates the {0,1,2} domain.

(test lispsys-getvar-silent-under-autocad
  (multiple-value-bind (result diagnostics)
      (%capture-enc-diagnostics
       "(getvar \"LISPSYS\")"
       :dialect :autocad-2026)
    (declare (ignore result))
    (is (string= "" diagnostics))))

(test lispsys-getvar-foreign-dialect-under-clautolisp
  (multiple-value-bind (result diagnostics)
      (%capture-enc-diagnostics
       "(getvar \"LISPSYS\")"
       :dialect :clautolisp)
    (declare (ignore result))
    (is (search "[enc-foreign-dialect]" diagnostics))
    (is (search "--clautolisp" diagnostics))))

(test lispsys-getvar-foreign-dialect-under-bricscad
  (multiple-value-bind (result diagnostics)
      (%capture-enc-diagnostics
       "(getvar \"LISPSYS\")"
       :dialect :bricscad-v26)
    (declare (ignore result))
    (is (search "[enc-foreign-dialect]" diagnostics))
    (is (search "--bricscad" diagnostics))))

(test lispsys-getvar-extension-used-under-strict
  (multiple-value-bind (result diagnostics)
      (%capture-enc-diagnostics
       "(getvar \"LISPSYS\")"
       :dialect :strict)
    (declare (ignore result))
    (is (search "[enc-extension-used]" diagnostics))))

(test lispsys-setvar-in-range-silent-under-autocad
  (multiple-value-bind (result diagnostics)
      (%capture-enc-diagnostics
       "(setvar \"LISPSYS\" 1)"
       :dialect :autocad-2026)
    (declare (ignore result))
    (is (string= "" diagnostics))))

(test lispsys-setvar-out-of-range-emits-enc-lispsys-out-of-range
  ;; The out-of-range diagnostic fires even under --autocad (native
  ;; dialect): the {0,1,2} domain is documented universally, not a
  ;; dialect-portability concern.
  (multiple-value-bind (result diagnostics)
      (%capture-enc-diagnostics
       "(setvar \"LISPSYS\" 99)"
       :dialect :autocad-2026)
    (declare (ignore result))
    (is (search "[enc-lispsys-out-of-range]" diagnostics))))

(test lispsys-setvar-out-of-range-still-stores-value
  ;; The write proceeds even when the value is out-of-range — matches
  ;; the vendor 'permissive but warn' behaviour the spec calls out.
  (multiple-value-bind (result diagnostics)
      (%capture-enc-diagnostics
       "(progn (setvar \"LISPSYS\" 99) (getvar \"LISPSYS\"))"
       :dialect :autocad-2026)
    (declare (ignore diagnostics))
    (is (eql 99 result))))

(test lispsys-setvar-clautolisp-stacks-both-diagnostics
  ;; Under --clautolisp, an out-of-range setvar surfaces BOTH the
  ;; foreign-dialect diagnostic and the out-of-range one.
  (multiple-value-bind (result diagnostics)
      (%capture-enc-diagnostics
       "(setvar \"LISPSYS\" 7)"
       :dialect :clautolisp)
    (declare (ignore result))
    (is (search "[enc-foreign-dialect]" diagnostics))
    (is (search "[enc-lispsys-out-of-range]" diagnostics))))

(test non-lispsys-getvar-silent-under-clautolisp
  ;; The dispatch must be name-specific. Other sysvars should not
  ;; trigger LISPSYS-related diagnostics.
  (multiple-value-bind (result diagnostics)
      (%capture-enc-diagnostics
       "(getvar \"CMDECHO\")"
       :dialect :clautolisp)
    (declare (ignore result))
    (is (string= "" diagnostics))))

;;;; ----- OPEN [encoding] dispatch (Phase 7) -------------------------
;;;;
;;;; Three forms share OPEN's encoding slot:
;;;;
;;;;   1. Positional autocad — third arg is "utf8" / "utf8-bom"
;;;;      (case-insensitive). Native under --autocad.
;;;;   2. Positional clautolisp — third arg uses the broader
;;;;      clautolisp vocabulary (UTF-8, UTF-8-BOM, ISO-8859-1,
;;;;      CP-NNNN, …). Native under --clautolisp.
;;;;   3. CCS mode-suffix — ,ccs=ENC in the mode-string. Native
;;;;      under --bricscad.
;;;;
;;;; The dispatcher routes each form per dialect; native cases are
;;;; silent, foreign cases emit enc-foreign-dialect with a sub-tag
;;;; identifying the offending form, and --strict emits
;;;; enc-extension-used for every form.

(defun %open-fixture-form (mode-or-encoding-clause)
  "Build a small OPEN-then-conditionally-close form that opens
/tmp/openenc.txt under the given mode-and-encoding-clause text.
Used to drive the diagnostic-capture harness; the file is
created/overwritten on disk, which we don't care about for the
diagnostic check. OPEN may return nil when the requested encoding
isn't supported by the running CL impl (e.g. MBCS on SBCL); the
guarded close keeps the harness from crashing on that path —
the diagnostic of interest has already been emitted before OPEN
attempts the I/O."
  (format nil "(progn (setq f (open \"/tmp/openenc.txt\" ~A)) (if f (close f)) 0)"
          mode-or-encoding-clause))

(test open-positional-autocad-silent-under-autocad
  (multiple-value-bind (result diagnostics)
      (%capture-enc-diagnostics
       (%open-fixture-form "\"w\" \"utf8\"")
       :dialect :autocad-2026)
    (declare (ignore result))
    (is (string= "" diagnostics))))

(test open-positional-autocad-utf8-bom-silent-under-autocad
  (multiple-value-bind (result diagnostics)
      (%capture-enc-diagnostics
       (%open-fixture-form "\"w\" \"utf8-bom\"")
       :dialect :autocad-2026)
    (declare (ignore result))
    (is (string= "" diagnostics))))

(test open-positional-clautolisp-silent-under-clautolisp
  (multiple-value-bind (result diagnostics)
      (%capture-enc-diagnostics
       (%open-fixture-form "\"w\" \"UTF-8\"")
       :dialect :clautolisp)
    (declare (ignore result))
    (is (string= "" diagnostics))))

(test open-positional-clautolisp-foreign-under-autocad
  ;; "UTF-8" with the dash is the clautolisp vocabulary — foreign to
  ;; AutoCAD's "utf8" / "utf8-bom" set.
  (multiple-value-bind (result diagnostics)
      (%capture-enc-diagnostics
       (%open-fixture-form "\"w\" \"UTF-8\"")
       :dialect :autocad-2026)
    (declare (ignore result))
    (is (search "[enc-foreign-dialect]" diagnostics))
    (is (search "clautolisp-positional" diagnostics))))

(test open-positional-autocad-foreign-under-clautolisp
  ;; The AutoCAD lower-case literal is foreign to --clautolisp.
  (multiple-value-bind (result diagnostics)
      (%capture-enc-diagnostics
       (%open-fixture-form "\"w\" \"utf8\"")
       :dialect :clautolisp)
    (declare (ignore result))
    (is (search "[enc-foreign-dialect]" diagnostics))
    (is (search "autocad-positional" diagnostics))))

(test open-positional-extension-used-under-strict
  (multiple-value-bind (result diagnostics)
      (%capture-enc-diagnostics
       (%open-fixture-form "\"w\" \"UTF-8\"")
       :dialect :strict)
    (declare (ignore result))
    (is (search "[enc-extension-used]" diagnostics))))

(test open-ccs-suffix-silent-under-bricscad
  (multiple-value-bind (result diagnostics)
      (%capture-enc-diagnostics
       (%open-fixture-form "\"w,ccs=UTF-8\"")
       :dialect :bricscad-v26)
    (declare (ignore result))
    (is (string= "" diagnostics))))

(test open-ccs-suffix-foreign-under-autocad
  (multiple-value-bind (result diagnostics)
      (%capture-enc-diagnostics
       (%open-fixture-form "\"w,ccs=UTF-8\"")
       :dialect :autocad-2026)
    (declare (ignore result))
    (is (search "[enc-foreign-dialect]" diagnostics))
    (is (search "bricscad-ccs" diagnostics))))

(test open-ccs-suffix-foreign-under-clautolisp
  (multiple-value-bind (result diagnostics)
      (%capture-enc-diagnostics
       (%open-fixture-form "\"w,ccs=UTF-8\"")
       :dialect :clautolisp)
    (declare (ignore result))
    (is (search "[enc-foreign-dialect]" diagnostics))
    (is (search "bricscad-ccs" diagnostics))))

(test open-ccs-suffix-extension-used-under-strict
  (multiple-value-bind (result diagnostics)
      (%capture-enc-diagnostics
       (%open-fixture-form "\"w,ccs=UTF-8\"")
       :dialect :strict)
    (declare (ignore result))
    (is (search "[enc-extension-used]" diagnostics))))

(test open-both-forms-emits-two-diagnostics-under-strict
  ;; Providing both forms simultaneously is unusual but documented;
  ;; under --strict each form should surface its own diagnostic.
  (multiple-value-bind (result diagnostics)
      (%capture-enc-diagnostics
       (%open-fixture-form "\"w,ccs=UTF-8\" \"UTF-8\"")
       :dialect :strict)
    (declare (ignore result))
    (is (search "bricscad-ccs" diagnostics))
    (is (search "clautolisp-positional" diagnostics))))

(test open-no-encoding-arg-silent-under-every-dialect
  ;; Bare OPEN should not emit any encoding diagnostic regardless
  ;; of dialect.
  (dolist (d '(:strict :clautolisp :autocad-2026 :bricscad-v26))
    (multiple-value-bind (result diagnostics)
        (%capture-enc-diagnostics
         (%open-fixture-form "\"w\"")
         :dialect d)
      (declare (ignore result))
      (is (string= "" diagnostics)
          "Bare OPEN must not emit enc-* under ~A; got: ~S" d diagnostics))))

;;; --- BricsCAD ,ccs= mode-suffix actually drives the encoding ------
;;;
;;; The dispatcher diagnostic is one half; the other is that the
;;; encoding extracted from the mode-suffix actually flows into the
;;; CL OPEN call. Write a single Latin-1 byte via the ccs= mode and
;;; read it back; the byte should round-trip when both sides
;;; agree on the encoding. The mode-suffix splitter is what makes
;;; this work — without it the CL OPEN sees "w,ccs=ISO-8859-1"
;;; as the literal direction and chokes.

(test open-ccs-suffix-actually-honoured-as-encoding
  (reset-autolisp-symbol-table)
  (uiop:with-temporary-file (:pathname path :type "txt" :keep nil)
    (let ((result (run-autolisp-string
                   (format nil "(progn
                                  (setq f (open ~S \"w,ccs=ISO-8859-1\"))
                                  (princ (chr 233) f)
                                  (close f)
                                  (setq g (open ~S \"r,ccs=ISO-8859-1\"))
                                  (setq c (read-char g))
                                  (close g)
                                  c)"
                           (namestring path) (namestring path))
                   :dialect (clautolisp.autolisp-reader:find-autolisp-dialect
                             :bricscad-v26)
                   :setup-fn #'%install-mock-host-and-core)))
      ;; 0xE9 = 233 = é under Latin-1.
      (is (eql 233 result)))))

;;;; ----- enc-unsupported-target / enc-host-dependent (Phase 8) ------
;;;;
;;;; Two informational diagnostics fired from OPEN:
;;;;
;;;;   enc-unsupported-target: encoding is foreign to the host's
;;;;     expressive range (e.g. UTF-16 under --autocad).
;;;;   enc-host-dependent:     "ANSI" in a WRITE context — output is
;;;;     not portable across hosts.
;;;;
;;;; Both are informational; the runtime still attempts the open.

(test open-enc-unsupported-target-fires-for-utf-16-under-autocad
  (multiple-value-bind (result diagnostics)
      (%capture-enc-diagnostics
       (%open-fixture-form "\"w\" \"UTF-16-LE\"")
       :dialect :autocad-2026)
    (declare (ignore result))
    (is (search "[enc-unsupported-target]" diagnostics))))

(test open-enc-unsupported-target-silent-for-utf-8-under-autocad
  (multiple-value-bind (result diagnostics)
      (%capture-enc-diagnostics
       (%open-fixture-form "\"w\" \"utf8\"")
       :dialect :autocad-2026)
    (declare (ignore result))
    (is (not (search "[enc-unsupported-target]" diagnostics)))))

(test open-enc-unsupported-target-silent-under-clautolisp
  ;; clautolisp does the transcoding; no host-expressibility limit
  ;; applies in-process.
  (multiple-value-bind (result diagnostics)
      (%capture-enc-diagnostics
       (%open-fixture-form "\"w\" \"UTF-16-LE\"")
       :dialect :clautolisp)
    (declare (ignore result))
    (is (not (search "[enc-unsupported-target]" diagnostics)))))

(test open-enc-host-dependent-fires-for-ansi-write
  (multiple-value-bind (result diagnostics)
      (%capture-enc-diagnostics
       (%open-fixture-form "\"w\" \"ANSI\"")
       :dialect :autocad-2026)
    (declare (ignore result))
    (is (search "[enc-host-dependent]" diagnostics))))

(test open-enc-host-dependent-silent-on-ansi-read
  ;; Reading legacy ANSI files is the common case — no lint there.
  (multiple-value-bind (result diagnostics)
      (%capture-enc-diagnostics
       (%open-fixture-form "\"r\" \"ANSI\"")
       :dialect :autocad-2026)
    (declare (ignore result))
    (is (not (search "[enc-host-dependent]" diagnostics)))))

(test open-enc-host-dependent-fires-for-mbcs-write
  (multiple-value-bind (result diagnostics)
      (%capture-enc-diagnostics
       (%open-fixture-form "\"w\" \"MBCS\"")
       :dialect :autocad-2026)
    (declare (ignore result))
    (is (search "[enc-host-dependent]" diagnostics))))

(test open-enc-host-dependent-silent-for-cp-nnnn-write
  ;; Explicit CP-NNNN is reproducible — no host-dependent lint.
  (multiple-value-bind (result diagnostics)
      (%capture-enc-diagnostics
       (%open-fixture-form "\"w\" \"CP-1252\"")
       :dialect :autocad-2026)
    (declare (ignore result))
    (is (not (search "[enc-host-dependent]" diagnostics)))))
