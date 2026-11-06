;;;; Fixture plug-in for tests/plugin-tests.lisp: registers under a name
;;;; other than the one of its file.
(defpackage #:alfe.plugin.wrongname (:use #:cl #:alfe.plugin))
(in-package #:alfe.plugin.wrongname)
(define-plugin "somethingelse" :version "0")
