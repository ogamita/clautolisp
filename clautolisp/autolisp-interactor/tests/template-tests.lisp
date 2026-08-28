;;;; clautolisp/autolisp-interactor/tests/template-tests.lisp
;;;;
;;;; The interactor-template registry (windows-and-interactor-templates.issue).

(in-package #:clautolisp.interactor.tests)

(in-suite interactor-suite)

;;; A throwaway interactor + template built on a fresh registry, so the tests
;;; do not depend on (or pollute) the real templates.

(defmacro with-fresh-template-registry (&body body)
  `(let ((clautolisp.interactor:*interactor-templates* '()))
     ,@body))

(defun %make-test-interactor (name)
  (clautolisp.interactor:make-interactor :name name))

(test template-make-defaults
  "MAKE-INTERACTOR-TEMPLATE downcases the name, defaults the display name to
the name, the description to \"\", and the config-name to the name when an
interactor is given."
  (let* ((it (%make-test-interactor "sedit"))
         (tpl (clautolisp.interactor:make-interactor-template
               :name "SEdit" :interactor it)))
    (is (string= "sedit" (clautolisp.interactor:interactor-template-name tpl)))
    (is (string= "sedit" (clautolisp.interactor:interactor-template-display-name tpl)))
    (is (string= "" (clautolisp.interactor:interactor-template-description tpl)))
    (is (string= "sedit" (clautolisp.interactor:interactor-template-config-name tpl)))
    (is (eq it (clautolisp.interactor:interactor-template-interactor tpl)))))

(test template-make-explicit-fields
  "Explicit display-name / description / config-name are kept verbatim."
  (let ((tpl (clautolisp.interactor:make-interactor-template
              :name "inspector" :display-name "Object inspector"
              :description "Inspect a Lisp object" :config-name "inspector")))
    (is (string= "Object inspector"
                 (clautolisp.interactor:interactor-template-display-name tpl)))
    (is (string= "Inspect a Lisp object"
                 (clautolisp.interactor:interactor-template-description tpl)))
    (is (string= "inspector"
                 (clautolisp.interactor:interactor-template-config-name tpl)))))

(test template-config-name-nil-without-interactor
  "With no interactor and no explicit config-name, config-name stays NIL
(inherit the enclosing stack's config)."
  (let ((tpl (clautolisp.interactor:make-interactor-template :name "picker")))
    (is (null (clautolisp.interactor:interactor-template-config-name tpl)))))

(test template-register-find-list
  "Registering makes a template findable (case-insensitively, by name or
object) and listed; re-registering the same name replaces, not duplicates
(moving it to the end — registration order, newest last — like the interactor
registry)."
  (with-fresh-template-registry
    (let ((a (clautolisp.interactor:make-interactor-template :name "navi"))
          (b (clautolisp.interactor:make-interactor-template :name "sedit")))
      (clautolisp.interactor:register-interactor-template a)
      (clautolisp.interactor:register-interactor-template b)
      (is (equal '("navi" "sedit")
                 (clautolisp.interactor:interactor-template-names)))
      (is (eq a (clautolisp.interactor:find-interactor-template "NAVI")))
      (is (eq b (clautolisp.interactor:find-interactor-template "sedit")))
      (is (eq a (clautolisp.interactor:find-interactor-template a)))
      (is (null (clautolisp.interactor:find-interactor-template "nope")))
      ;; reload: same name replaces (no dup), the fresh entry moving to the end
      (let ((a2 (clautolisp.interactor:make-interactor-template :name "navi")))
        (clautolisp.interactor:register-interactor-template a2)
        (is (equal '("sedit" "navi")
                   (clautolisp.interactor:interactor-template-names)))
        (is (eq a2 (clautolisp.interactor:find-interactor-template "navi")))))))

(test template-instantiate-calls-constructor
  "INSTANTIATE-INTERACTOR-TEMPLATE calls the constructor with the context and
returns the activation it makes; the constructor sees the context's target."
  (with-fresh-template-registry
    (let* ((it (%make-test-interactor "sedit"))
           (seen nil)
           (tpl (clautolisp.interactor:make-interactor-template
                 :name "sedit" :interactor it
                 :constructor (lambda (ctx)
                                (setf seen (clautolisp.interactor:template-context-target ctx))
                                (clautolisp.interactor:make-activation it (list :edited seen))))))
      (clautolisp.interactor:register-interactor-template tpl)
      (let* ((ctx (clautolisp.interactor:make-template-context :target '(a b c)))
             (act (clautolisp.interactor:instantiate-interactor-template "sedit" ctx)))
        (is (equal '(a b c) seen))
        (is (clautolisp.interactor:activation-p act))
        (is (eq it (clautolisp.interactor:activation-interactor act)))
        (is (equal '(:edited (a b c)) (clautolisp.interactor:activation-state act)))))))

(test template-instantiate-unknown-signals
  "Instantiating an unknown template, or one without a constructor, signals."
  (with-fresh-template-registry
    (signals error
      (clautolisp.interactor:instantiate-interactor-template
       "ghost" (clautolisp.interactor:make-template-context)))
    (clautolisp.interactor:register-interactor-template
     (clautolisp.interactor:make-interactor-template :name "noctor"))
    (signals error
      (clautolisp.interactor:instantiate-interactor-template
       "noctor" (clautolisp.interactor:make-template-context)))))

(test template-context-carries-continuations
  "The template-context carries the shared stack tail and the save/quit
continuations the constructor wires into the activation."
  (let* ((tail (list (clautolisp.interactor:make-activation (%make-test-interactor "lisp"))))
         (saved nil) (quit nil)
         (ctx (clautolisp.interactor:make-template-context
               :stack tail :target 42
               :save-continuation (lambda (r) (setf saved r))
               :quit-continuation (lambda (r) (setf quit r)))))
    (is (eq tail (clautolisp.interactor:template-context-stack ctx)))
    (is (eql 42 (clautolisp.interactor:template-context-target ctx)))
    (funcall (clautolisp.interactor:template-context-save-continuation ctx) :s)
    (funcall (clautolisp.interactor:template-context-quit-continuation ctx) :q)
    (is (eq :s saved))
    (is (eq :q quit))))

(test define-interactor-template-registers
  "DEFINE-INTERACTOR-TEMPLATE registers into the live registry and returns the
template."
  (with-fresh-template-registry
    (let ((tpl (clautolisp.interactor:define-interactor-template "stack-browser"
                 :display-name "Stack browser"
                 :description "Browse the backtrace")))
      (is (clautolisp.interactor:interactor-template-p tpl))
      (is (eq tpl (clautolisp.interactor:find-interactor-template "stack-browser")))
      (is (string= "Browse the backtrace"
                   (clautolisp.interactor:interactor-template-description tpl))))))
