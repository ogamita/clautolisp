(in-package #:clautolisp.autolisp-builtins-core.tests)

(in-suite autolisp-builtins-core-suite)

;;;; Multi-document cador (cador-multidocument-host; pjb 2026-10-05: "do the
;;;; multidocument cador/cadtui"). Each open drawing has its own LISP
;;;; namespace, and a lifecycle command switches document at the next
;;;; top-level read, as AutoCAD does (deferred-document-lifecycle-command-
;;;; semantics, option A).

(defun %md-context ()
  "A fresh session on a cador host, linked as the CLI links it."
  (reset-autolisp-symbol-table)
  (clautolisp.autolisp-runtime:reset-default-evaluation-context)
  (install-core-builtins)
  (let* ((context (clautolisp.autolisp-runtime:default-evaluation-context))
         (session (clautolisp.autolisp-runtime:evaluation-context-session context))
         (host (clautolisp.cador:make-cador)))
    (clautolisp.autolisp-runtime:set-runtime-session-host session host)
    (clautolisp.autolisp-host:link-runtime-session-to-host session host)
    context))

(defun %md-turn (context text)
  "One top-level turn, as the REPL runs it: apply a pending document switch,
then evaluate TEXT. Returns the value."
  (clautolisp.autolisp-runtime:apply-pending-document-switch context)
  (clautolisp.autolisp-runtime:autolisp-eval-progn
   (clautolisp.autolisp-runtime:read-runtime-from-string text)
   context))

(defun %md-host (context)
  (clautolisp.autolisp-runtime:runtime-session-host
   (clautolisp.autolisp-runtime:evaluation-context-session context)))

(test new-switches-document-at-the-next-top-level-read
  (let* ((context (%md-context))
         (host (%md-host context))
         (start (clautolisp.autolisp-host:host-current-document host)))
    (%md-turn context "(setq md-marker \"first\")")
    ;; Inside ONE form: NEW, then the rest of the routine still runs in the
    ;; first drawing and sees its variables.
    (is (equal "first"
               (autolisp-string-value
                (%md-turn context "(progn (command \"_.NEW\" \"\") md-marker)"))))
    (is (equal start (clautolisp.autolisp-host:host-current-document host)))
    ;; The next top-level read is in the new drawing: a new namespace.
    (is (null (%md-turn context "md-marker")))
    (let ((now (clautolisp.autolisp-host:host-current-document host)))
      (is (not (equal start now)))
      (is (equal 2 (length (clautolisp.autolisp-host:host-document-list host)))))))

(test each-document-has-its-own-namespace-and-propagation-crosses
  (let* ((context (%md-context)))
    (%md-turn context "(setq md-own 1 md-shared 2)")
    (%md-turn context "(vl-propagate 'md-shared)")
    (%md-turn context "(command \"_.NEW\" \"\")")
    (is (null (%md-turn context "md-own")))
    (is (eql 2 (%md-turn context "md-shared")))
    ;; The blackboard is the application's, shared.
    (%md-turn context "(vl-bb-set 'md-bb 42)")
    (%md-turn context "(command \"_.NEW\" \"\")")
    (is (eql 42 (%md-turn context "(vl-bb-ref 'md-bb)")))))

(test entities-made-after-new-go-to-the-new-drawing
  (let* ((context (%md-context)))
    (%md-turn context "(entmake '((0 . \"LINE\") (10 0.0 0.0 0.0) (11 1.0 0.0 0.0)))")
    ;; Same form: still the first drawing.
    (is (eql 2 (%md-turn context
                         "(progn (command \"_.NEW\" \"\")
                                 (entmake '((0 . \"LINE\") (10 0.0 0.0 0.0) (11 2.0 0.0 0.0)))
                                 (sslength (ssget \"_X\")))")))
    ;; Next read: the new, empty drawing.
    (is (null (%md-turn context "(ssget \"_X\")")))))
