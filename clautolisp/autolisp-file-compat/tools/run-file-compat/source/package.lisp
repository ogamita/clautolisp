(defpackage #:clautolisp.autolisp-file-compat.tools.run-file-compat
  (:use #:cl)
  (:import-from #:uiop
                #:command-line-arguments
                #:quit)
  (:import-from #:clautolisp.autolisp-file-compat
                #:emit-report
                #:load-scenario-file
                #:run-scenario)
  (:export #:main))
