(:name "plugin-compile"
 :description "--compile-plugin FILE compiles a plug-in source for this alfe
version and Common Lisp implementation into NAME.VERSION-IMPL.plugin next to
it, prints the path and exits 0."
 :classification :portable
 :argv ("--compile-plugin" "hello.lisp")
 :setup-files
   (("hello.lisp" "(defpackage #:alfe.plugin.scenario-hello (:use #:cl #:alfe.plugin))
(in-package #:alfe.plugin.scenario-hello)
(define-plugin \"hello\" :version \"1\")
"))
 :expected-exit 0
 :expected-stdout-includes ("hello.0.0.0-" ".plugin")
 :covers-options ("--compile-plugin"))
