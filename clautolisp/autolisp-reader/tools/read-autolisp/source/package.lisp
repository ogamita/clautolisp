(defpackage #:clautolisp.autolisp-reader.tools.read-autolisp
  (:use #:cl)
  (:import-from #:uiop
                #:command-line-arguments
                #:quit)
  (:import-from #:clautolisp.autolisp-reader
                #:cons-object
                #:cons-object-dotted-p
                #:cons-object-elements
                #:cons-object-tail
                #:diagnostic
                #:diagnostic-code
                #:diagnostic-message
                #:diagnostic-severity
                #:diagnostic-span
                #:integer-object
                #:integer-object-value
                #:make-reader-options
                #:quote-object
                #:quote-object-object
                #:read-forms-from-file
                #:read-result-diagnostics
                #:read-result-objects
                #:real-object
                #:real-object-value
                #:reader-options
                #:source-span
                #:source-span-end-column
                #:source-span-end-line
                #:source-span-source-name
                #:source-span-start-column
                #:source-span-start-line
                #:string-object
                #:string-object-value
                #:symbol-object
                #:symbol-object-canonical-name)
  (:export #:main))
