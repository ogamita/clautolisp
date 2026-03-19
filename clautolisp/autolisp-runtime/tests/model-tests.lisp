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
