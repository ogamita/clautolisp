(defpackage #:clautolisp.source
  (:use #:cl)
  (:documentation
   "Source-position map for the clautolisp debugger (clautolisp-debugger
spec §3). Carries (file line column) positions from the reader through
the reader→runtime lowering, so an executing AutoLISP form can be mapped
back to its source. The runtime records positions here when
*TRACK-SOURCE-POSITIONS* is set; the debugger reads them via POSITION-OF.")
  (:import-from #:clautolisp.autolisp-reader
                #:source-span
                #:source-span-source-name
                #:source-span-start-line
                #:source-span-start-column
                #:source-span-end-line
                #:source-span-end-column)
  (:export
   #:source-position
   #:make-source-position
   #:source-position-p
   #:source-position-file
   #:source-position-start-line
   #:source-position-start-column
   #:source-position-end-line
   #:source-position-end-column
   #:source-position-equal
   #:source-position-from-span
   #:*track-source-positions*
   #:*source-position-table*
   #:note-position
   #:position-of
   #:clear-source-positions
   #:call-with-source-tracking
   #:with-source-tracking
   #:lines-of))
