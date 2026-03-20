(defpackage #:clautolisp.autolisp-file-compat.tools.run-file-compat
  (:use #:cl)
  (:import-from #:uiop
                #:command-line-arguments
                #:quit)
  (:import-from #:clautolisp.autolisp-file-compat
                #:collect-scenario-file-paths
                #:emit-report
                #:emit-json-value
                #:load-scenario-file
                #:report->plist
                #:run-scenario
                #:scenario-matches-tags-p
                #:summarize-reports
                #:summary->plist)
  (:export #:main))
