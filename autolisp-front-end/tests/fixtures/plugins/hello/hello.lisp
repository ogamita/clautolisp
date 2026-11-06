;;;; Fixture plug-in for tests/plugin-tests.lisp: the `hello' example of the
;;;; spec chapter "Plug-ins" — an option with an argument, a default, and a
;;;; :plan hook that puts an action in front of the plan.

(defpackage #:alfe.plugin.hello (:use #:cl #:alfe.plugin))
(in-package #:alfe.plugin.hello)

(define-plugin "hello"
  :version "1.2.3"
  :description "Greet before the plan runs."
  :options ((:flag  "--hello" :activates t :doc "Enable the greeting.")
            (:value "--hello-name" :key :name :arg "NAME" :default "world"
                                   :doc "Whom to greet.")
            (:value "--hello-level" :key :level :arg "N"
                                    :parser #'parse-integer
                                    :doc "A number.")
            (:value "--hello-style" :key :style :arg "STYLE"
                                    :choices '("plain" "loud")
                                    :doc "A choice.")
            (:repeat "--hello-tag" :key :tags :arg "TAG" :env "HELLO_TAGS"
                                   :doc "Repeatable.")))

(define-plugin-hook "hello" :plan (ctx plan)
  (cons (alfe.backend:action-eval
         (format nil "(princ ~A)"
                 (autolisp-string-literal
                  (format nil "Hello, ~A!" (plugin-option :name)))))
        plan))
