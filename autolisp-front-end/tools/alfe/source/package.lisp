;;;; autolisp-front-end/tools/alfe/source/package.lisp
;;;;
;;;; Package for the standalone `alfe` executable. The package is
;;;; deliberately thin: it imports ALFE.CLI:RUN, exposes MAIN as the
;;;; image entry-point, and re-exports *VERSION* so generate-alfe.lisp
;;;; can stamp it onto the binary banner.

(defpackage #:alfe.tool
  (:use #:cl)
  (:import-from #:uiop
                #:command-line-arguments
                #:quit)
  (:import-from #:alfe.cli
                #:run
                #:print-usage
                #:print-version)
  (:export #:main
           #:*version*))
