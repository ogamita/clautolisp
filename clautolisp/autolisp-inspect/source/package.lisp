(defpackage #:clautolisp.inspect
  (:use #:cl)
  ;; We define our own INSPECT (the session entry, spec §14); shadow CL's.
  (:shadow #:inspect)
  (:documentation
   "AutoLISP value inspector (clautolisp-debugger spec Part IV). A generic
value browser: given a value it produces a page of labelled, descendable
components, tracks the navigation path from an origin, and can reconstruct
the accessor S-expression that names the currently-displayed value. A
separate library from the debugger (the debugger uses it; it also works
from any REPL), so it depends only on the runtime.")
  ;; Struct TYPE names come from the .internal package: those symbols name
  ;; the structure-classes (the public package re-exports them only as
  ;; DEFTYPE aliases, which work for TYPEP but not as DEFMETHOD
  ;; specializers). Accessors/constructors/functions come from the public
  ;; package (forwarders).
  (:import-from #:clautolisp.autolisp-runtime.internal
                #:autolisp-symbol
                #:autolisp-string
                #:autolisp-ename
                #:autolisp-pickset
                #:autolisp-vla-object
                #:autolisp-file
                ;; the real keyword constructor (the public symbol is a
                ;; deftype-only export with no constructor function)
                #:make-autolisp-string)
  (:import-from #:clautolisp.autolisp-runtime
                #:autolisp-symbol-name
                #:intern-autolisp-symbol
                #:autolisp-string-value
                #:autolisp-file-path
                #:autolisp-file-mode
                #:autolisp-eval
                #:lookup-variable
                #:lookup-function
                #:set-variable
                #:push-dynamic-frame
                #:pop-dynamic-frame
                #:bind-dynamic-variable
                #:current-evaluation-context
                #:current-document-namespace-set
                #:runtime-value-p
                #:*debugging*)
  (:export
   ;; pages
   #:inspect-page
   #:inspect-page-p
   #:inspect-page-value
   #:inspect-page-type-name
   #:inspect-page-header
   #:inspect-page-components
   #:inspect-component
   #:inspect-component-label
   #:inspect-component-preview
   #:inspect-component-accessor
   #:inspect-component-value
   #:inspect-component-descendable-p
   #:inspect-page-for
   #:preview-of
   ;; sessions + navigation
   #:inspect
   #:inspector-session
   #:inspector-session-p
   #:inspector-session-current
   #:inspector-session-page
   #:inspector-session-origin
   #:inspector-session-context
   #:inspector-session-workspace
   #:inspector-session-bind-frame-fn
   #:session-current
   #:session-page
   #:session-origin
   #:session-history
   #:session-down
   #:session-up
   #:session-eval
   #:session-path-expression
   #:session-bind
   #:descent-step
   #:descent-step-value
   #:descent-step-page
   #:descent-step-accessor
   ;; workspace ($N)
   #:workspace
   #:make-workspace
   #:workspace-p
   #:workspace-bind
   #:workspace-ref
   #:workspace-list
   #:workspace-clear
   #:next-slot-name))
