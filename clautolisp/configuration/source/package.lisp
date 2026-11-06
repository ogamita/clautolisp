(defpackage #:clautolisp.configuration
  (:use #:cl)
  (:documentation "Where clautolisp's configuration files live, and how to
find them. ONE implementation of that rule, in a layer every other module
can see.

It exists because there were two. aldo's configuration path was written
once in CLAUTOLISP.DEBUG.UI and once, independently, in
CLAUTOLISP.AUTOLISP-BUILTINS-CORE — not through carelessness but through
STACKING: builtins-core sits below the debug UI and cannot depend on it, so
the builtin that needed the path had no access to the implementation that
already existed and wrote another. They agreed line for line, which is
exactly what makes that kind of duplication dangerous: nothing is wrong
until one of them learns something the other does not, and then the path
the debugger SAVES to stops being the one the builtin READS
(aldo-config-path-implemented-twice.issue).

So this module sits at the bottom, depends on nothing but UIOP, and is the
only place that knows the answer.")
  (:export #:config-getenv
           #:xdg-config-home
           #:xdg-config-dirs
           #:config-relative-path
           #:config-save-path
           #:config-load-path
           #:*configuration-names*
           #:configuration-name-p))
