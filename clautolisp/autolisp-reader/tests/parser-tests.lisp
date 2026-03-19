(in-package #:clautolisp.autolisp-reader.tests)

(in-suite autolisp-reader-suite)

(test read-dotted-pair
  (let* ((result (read-forms-from-string "(a . c)"))
         (object (first (read-result-objects result))))
    (is (typep object 'cons-object))
    (is (cons-object-dotted-p object))
    (is (= 1 (length (cons-object-elements object))))
    (is (typep (first (cons-object-elements object)) 'symbol-object))
    (is (typep (cons-object-tail object) 'symbol-object))))

(test read-symbol-form
  (let* ((result (read-forms-from-string "y"))
         (object (first (read-result-objects result))))
    (is (typep object 'symbol-object))))

(test read-quote-form
  (let* ((result (read-forms-from-string "'x"))
         (object (first (read-result-objects result))))
    (is (typep object 'quote-object))
    (is (typep (quote-object-object object) 'symbol-object))))

(test read-concrete-comments-and-dot
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
    (is (= 6 (length items)))
    (is (typep (first items) 'symbol-object))
    (is (typep (second items) 'comment-object))
    (is (typep (third items) 'dot-object))
    (is (typep (fourth items) 'comment-object))
    (is (typep (fifth items) 'symbol-object))
    (is (typep (sixth items) 'comment-object))))

(test normalized-line-endings
  (let* ((result
           (read-forms-from-string
            (format nil "(\"a\")~C~C(\"b\")~C(\"c\")"
                    #\Return
                    #\Newline
                    #\Return)))
         (objects (read-result-objects result)))
    (is (= 3 (length objects)))))

(test read-forms-from-file-with-default-external-format
  (let* ((path (merge-pathnames
                #P"autolisp-reader-default-external-format.lsp"
                (uiop:temporary-directory))))
    (unwind-protect
         (progn
           (with-open-file (stream path
                                   :direction :output
                                   :if-exists :supersede
                                   :if-does-not-exist :create)
             (write-string "(abc 42)" stream))
           (let* ((result (read-forms-from-file path))
                  (objects (read-result-objects result)))
             (is (= 1 (length objects)))
             (is (typep (first objects) 'cons-object))))
      (when (probe-file path)
        (delete-file path)))))
