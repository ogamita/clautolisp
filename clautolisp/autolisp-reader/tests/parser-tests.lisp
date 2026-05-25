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

(test read-block-comments
  (let* ((result (read-forms-from-string "(a ;| block
comment |; b)"))
         (object (first (read-result-objects result))))
    (is (typep object 'cons-object))
    (is (= 2 (length (cons-object-elements object))))))

(test read-concrete-block-comments
  (let* ((result (read-concrete-from-string "(a ;| block
comment |; b)"))
         (object (first (read-result-objects result)))
         (items (concrete-list-object-items object)))
    (is (typep object 'concrete-list-object))
    (is (= 3 (length items)))
    (is (typep (second items) 'comment-object))
    (is (eq :block-comment (comment-object-kind (second items))))))

(test read-string-with-extended-escapes
  (let* ((result (read-forms-from-string
                  "\"Erreur d\\u+00E9tect\\u+00E9e \\#ok\\\".\""
                  :extended-string-escapes-p t))
         (object (first (read-result-objects result))))
    (is (typep object 'string-object))
    (is (string= "Erreur détectée #ok\"."
                 (string-object-value object)))))

(test read-string-with-default-quote-and-backslash-escapes
  (let* ((result (read-forms-from-string "\"a\\\\b\\\"c\""))
         (object (first (read-result-objects result))))
    (is (typep object 'string-object))
    (is (string= "a\\b\"c"
                 (string-object-value object)))))

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

;;; --- preceding-doc (source-aware-defun-documentation) -------------

(test preceding-doc-attaches-to-following-cons-form
  ;; A ;| block |; immediately before a (form) lands in the
  ;; cons-object's preceding-doc slot, delimiters stripped, internal
  ;; whitespace preserved verbatim.
  (let* ((result (read-forms-from-string ";| hello |;
(defun foo () 1)"))
         (object (first (read-result-objects result))))
    (is (typep object 'cons-object))
    (is (string= " hello " (cons-object-preceding-doc object)))))

(test preceding-doc-line-comments-between-block-and-form
  ;; Plain ; line comments between the block and the next form do
  ;; not clear the pending-doc — the block still attaches.
  (let* ((result (read-forms-from-string ";| doc |;
; line one
; line two
(defun foo () 1)"))
         (object (first (read-result-objects result))))
    (is (typep object 'cons-object))
    (is (string= " doc " (cons-object-preceding-doc object)))))

(test preceding-doc-second-block-clobbers-first
  ;; Two block comments before any form: the SECOND one wins
  ;; (matches Common Lisp / Emacs Lisp doc-string semantics).
  (let* ((result (read-forms-from-string ";| first |;
;| second |;
(defun foo () 1)"))
         (object (first (read-result-objects result))))
    (is (typep object 'cons-object))
    (is (string= " second " (cons-object-preceding-doc object)))))

(test preceding-doc-absent-when-no-block
  ;; A bare (defun ...) with no preceding block has nil for
  ;; preceding-doc — distinguishable from the empty string.
  (let* ((result (read-forms-from-string "(defun foo () 1)"))
         (object (first (read-result-objects result))))
    (is (typep object 'cons-object))
    (is (null (cons-object-preceding-doc object)))))

(test preceding-doc-nested-form
  ;; The pending-doc threading operates at any nesting depth, not
  ;; just top-level — an inner (defun ...) preceded by a block
  ;; comment inside an outer form gets its own preceding-doc.
  (let* ((result (read-forms-from-string
                  "(progn
                     ;| inner |;
                     (defun foo () 1))"))
         (outer (first (read-result-objects result)))
         (inner (second (cons-object-elements outer))))
    (is (typep outer 'cons-object))
    (is (null (cons-object-preceding-doc outer)))
    (is (typep inner 'cons-object))
    (is (string= " inner " (cons-object-preceding-doc inner)))))

(test preceding-doc-dropped-on-atom
  ;; An atom (symbol, string, number, quote) cannot carry doc —
  ;; the pending-doc is silently dropped so it does not bleed onto
  ;; a later form.
  (let* ((result (read-forms-from-string ";| dropped |;
foo
(defun bar () 1)"))
         (objects (read-result-objects result))
         (atom (first objects))
         (form (second objects)))
    (is (typep atom 'symbol-object))
    (is (typep form 'cons-object))
    (is (null (cons-object-preceding-doc form)))))

(test preceding-doc-preserves-internal-whitespace
  ;; Internal newlines and indentation between ;| and |; are kept
  ;; verbatim so multi-line doc blocks survive the round trip.
  (let* ((result (read-forms-from-string ";|
  line one
  line two
|;
(defun foo () 1)"))
         (object (first (read-result-objects result))))
    (is (typep object 'cons-object))
    (is (string= (format nil "~%  line one~%  line two~%")
                 (cons-object-preceding-doc object)))))

(test preceding-doc-at-file-start-attaches-to-first-form
  ;; A block comment at the very start of input (no prior whitespace)
  ;; attaches to the first form that follows.
  (let* ((result (read-forms-from-string ";|head|;(defun foo () 1)"))
         (object (first (read-result-objects result))))
    (is (typep object 'cons-object))
    (is (string= "head" (cons-object-preceding-doc object)))))

(test preceding-doc-trailing-block-is-dropped
  ;; A block comment at end-of-file with no following form is
  ;; silently discarded — there is no form to attach it to.
  (let* ((result (read-forms-from-string "(defun foo () 1)
;| trailing |;"))
         (objects (read-result-objects result))
         (object (first objects)))
    (is (= 1 (length objects)))
    (is (typep object 'cons-object))
    (is (null (cons-object-preceding-doc object)))))
