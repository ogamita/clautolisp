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

(test autolisp-read-from-string-returns-first-form
  (reset-autolisp-symbol-table)
  (let ((value (autolisp-read-from-string "(a) (b)")))
    (is (consp value))
    (is (string= "A"
                 (autolisp-symbol-name (first value))))))
