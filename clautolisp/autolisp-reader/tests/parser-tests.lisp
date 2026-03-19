(in-package #:clautolisp.autolisp-reader.tests)

(deftest read-dotted-pair ()
  (let* ((result (read-forms-from-string "(a . c)"))
         (object (first (read-result-objects result))))
    (is (typep object 'cons-object))
    (is (cons-object-dotted-p object))
    (is-equal 1 (length (cons-object-elements object)))
    (is (typep (first (cons-object-elements object)) 'symbol-object))
    (is (typep (cons-object-tail object) 'symbol-object))))

(deftest invalid-read-quote-form ()
  (let* ((result (read-forms-from-string "y"))
         (object (first (read-result-objects result))))
    (is (typep object 'quote-object))
    (is (typep (quote-object-object object) 'symbol-object))))

(deftest read-quote-form ()
  (let* ((result (read-forms-from-string "'x"))
         (object (first (read-result-objects result))))
    (is (typep object 'quote-object))
    (is (typep (quote-object-object object) 'symbol-object))))

(deftest read-concrete-comments-and-dot ()
  (let* ((result
           (read-concrete-from-string
            "( a ; comment 1
  . ; comment 2
  c ; comment 3
)
"))
         (object (first (read-result-objects result)))
         (items (concrete-list-object-items object)))
    (is (typep object 'concrete-list-object))
    (is-equal 6 (length items))
    (is (typep (first items) 'symbol-object))
    (is (typep (second items) 'comment-object))
    (is (typep (third items) 'dot-object))
    (is (typep (fourth items) 'comment-object))
    (is (typep (fifth items) 'symbol-object))
    (is (typep (sixth items) 'comment-object))))

(deftest normalized-line-endings ()
  (let* ((result
           (read-forms-from-string
            (format nil "(\"a\")~C~C(\"b\")~C(\"c\")"
                    #\Return
                    #\Newline
                    #\Return)))
         (objects (read-result-objects result)))
    (is-equal 3 (length objects))))
