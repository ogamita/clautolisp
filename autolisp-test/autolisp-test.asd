;;;; autolisp-test/autolisp-test.asd
;;;;
;;;; ASDF wrapper that lets clautolisp drive the AutoLISP-only
;;;; conformance harness from a Common Lisp environment (SBCL or CCL).
;;;;
;;;; The harness itself remains pure AutoLISP; the system only loads
;;;; a thin driver that installs the runtime, exposes an implementation
;;;; marker, and invokes (autolisp-test-run-all) inside the session.

(asdf:defsystem "autolisp-test"
  :description "Aggregate ASDF system for the autolisp-test conformance suite."
  :author "Codex"
  :license "AGPL-3.0"
  :depends-on ("autolisp-test/clautolisp-driver"))

(asdf:defsystem "autolisp-test/clautolisp-driver"
  :description "clautolisp-side driver for the autolisp-test conformance suite."
  :author "Codex"
  :license "AGPL-3.0"
  :depends-on ("clautolisp/autolisp-reader"
               "clautolisp/autolisp-runtime"
               "clautolisp/autolisp-builtins-core")
  :pathname "clautolisp-driver/source/"
  :serial t
  :components
  ((:file "package")
   (:file "driver")))
