(defpackage #:clautolisp.autolisp-reader.tests
  (:use #:cl)
  (:import-from #:fiveam
                #:def-suite
                #:in-suite
                #:test
                #:is
                #:run
                #:explain!
                #:results-status)
  (:import-from #:clautolisp.autolisp-reader
                #:comment-object
                #:comment-object-kind
                #:comment-object-text
                #:concrete-list-object
                #:concrete-list-object-items
                #:cons-object
                #:cons-object-dotted-p
                #:cons-object-elements
                #:cons-object-tail
                #:diagnostic-code
                #:diagnostic-severity
                #:dot-object
                #:integer-object
                #:integer-object-value
                #:quote-object
                #:quote-object-object
                #:read-forms-from-file
                #:read-concrete-from-string
                #:read-forms-from-string
                #:read-result-diagnostics
                #:read-result-objects
                #:real-object
                #:real-object-overflowed-integer-p
                #:string-object
                #:string-object-value
                #:symbol-object
                #:symbol-object-canonical-name
                #:token
                #:token-kind
                #:token-lexeme
                #:tokenize-string)
  (:export #:run-all-tests
           #:autolisp-reader-suite))
