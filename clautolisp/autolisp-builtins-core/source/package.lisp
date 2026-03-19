(defpackage #:clautolisp.autolisp-builtins-core
  (:use #:cl)
  (:import-from #:clautolisp.autolisp-runtime
                #:autolisp-string
                #:autolisp-string-value
                #:autolisp-symbol
                #:autolisp-symbol-name
                #:autolisp-symbol-value
                #:autolisp-symbol-value-bound-p
                #:autolisp-atom
                #:autolisp-listp
                #:autolisp-not
                #:autolisp-null
                #:autolisp-subr
                #:autolisp-subr-name
                #:autolisp-type
                #:autolisp-vl-symbol-name
                #:autolisp-vl-symbolp
                #:autolisp-vl-symbol-value
                #:intern-autolisp-symbol
                #:make-autolisp-subr
                #:set-autolisp-symbol-function)
  (:export
   #:*core-builtin-names*
   #:core-builtins
   #:find-core-builtin
   #:install-core-builtins))
