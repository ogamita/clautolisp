;;;; clautolisp/autolisp-inspect/tests/package.lisp

(defpackage #:clautolisp.inspect.tests
  (:use #:cl)
  (:import-from #:fiveam
                #:def-suite #:in-suite #:test #:is #:signals #:run #:explain! #:results-status)
  (:export #:run-all-tests))

(in-package #:clautolisp.inspect.tests)

(def-suite inspect-suite
  :description "clautolisp.inspect: pages, accessors, navigation, path expressions, workspace.")

(defun run-all-tests ()
  (let ((results (run 'inspect-suite)))
    (explain! results)
    (unless (results-status results)
      (error "clautolisp.inspect tests failed."))))

;;; --- fixtures ------------------------------------------------------

(defun rt-sym (name) (clautolisp.autolisp-runtime:intern-autolisp-symbol name))
(defun rt-str (s) (clautolisp.autolisp-runtime:make-autolisp-string s))

(defun fresh-context ()
  (clautolisp.autolisp-runtime:make-default-runtime-context))

(defun load-source (context source)
  (dolist (form (clautolisp.autolisp-runtime:read-runtime-from-string source))
    (clautolisp.autolisp-runtime:autolisp-eval form context)))

(defun path-string (session)
  (princ-to-string (clautolisp.inspect:session-path-expression session)))

(defun component-index (session label)
  (position label (clautolisp.inspect:inspect-page-components
                   (clautolisp.inspect:session-page session))
            :key #'clautolisp.inspect:inspect-component-label :test #'string=))
