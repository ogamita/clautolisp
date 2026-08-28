;;;; clautolisp/autolisp-sedit/tests/template-tests.lisp
;;;;
;;;; SEDIT as a window interactor template (windows-and-interactor-templates.issue).

(in-package #:clautolisp.sedit.tests)

(in-suite sedit-suite)

(test sedit-template-is-registered
  "The sedit interactor template is registered with its metadata and the
*SEDIT* singleton as its interactor."
  (let ((tpl (clautolisp.interactor:find-interactor-template "sedit")))
    (is (not (null tpl)))
    (is (string= "sedit" (clautolisp.interactor:interactor-template-name tpl)))
    (is (string= "sedit" (clautolisp.interactor:interactor-template-config-name tpl)))
    (is (eq clautolisp.sedit:*sedit*
            (clautolisp.interactor:interactor-template-interactor tpl)))))

(test make-sedit-activation-wraps-the-session
  "MAKE-SEDIT-ACTIVATION returns a *SEDIT* activation whose state carries the
given session (no loop run)."
  (let* ((session (sedit-open (parse-form "(a b c)")))
         (act (make-sedit-activation session)))
    (is (clautolisp.interactor:activation-p act))
    (is (eq clautolisp.sedit:*sedit* (clautolisp.interactor:activation-interactor act)))
    (let ((state (clautolisp.interactor:activation-state act)))
      (is (sedit-interactor-state-p state))
      (is (eq session (sedit-interactor-state-session state))))))

(test sedit-template-instantiates-over-a-session-target
  "INSTANTIATE-INTERACTOR-TEMPLATE \"sedit\" with a session TARGET uses that
session directly."
  (let* ((session (sedit-open (parse-form "(defun foo () 1)")))
         (ctx (clautolisp.interactor:make-template-context :target session))
         (act (clautolisp.interactor:instantiate-interactor-template "sedit" ctx)))
    (is (eq clautolisp.sedit:*sedit* (clautolisp.interactor:activation-interactor act)))
    (is (eq session (sedit-interactor-state-session
                     (clautolisp.interactor:activation-state act))))))

(test sedit-template-opens-a-node-target
  "A non-session TARGET is opened with SEDIT-OPEN: a node target yields a
session whose §2 result is that node's form."
  (let* ((node (parse-form "(+ 1 2)"))
         (ctx (clautolisp.interactor:make-template-context :target node))
         (act (clautolisp.interactor:instantiate-interactor-template "sedit" ctx))
         (session (sedit-interactor-state-session
                   (clautolisp.interactor:activation-state act))))
    (is (sedit-session-p session))
    (is (equal '(:+ 1 2) (tree->sexp (session-result session))))))
