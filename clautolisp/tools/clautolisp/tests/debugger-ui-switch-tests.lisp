;;;; clautolisp/tools/clautolisp/tests/debugger-ui-switch-tests.lisp
;;;;
;;;; The LIVE debugger-UI switch (debugger-ui-live-switch): setting the AutoLISP
;;;; variable *CLAL-DEBUGGER-UI* selects the UI used at the NEXT debugger entry,
;;;; so e.g. (foreach *clal-debugger-ui* '(tui ncurses aldb) (clal-break))
;;;; enters the debugger successively on the dumb terminal, ncurses, and aldb.
;;;; Covered here: the live read of the mirror, the per-stop selector's rebuild
;;;; on change, and the session's re-resolution/swap of the active UI.

(in-package #:clautolisp.tools.clautolisp.tests)

(in-suite clautolisp-tool-suite)

(defmacro with-active-context ((var) &body body)
  "Run BODY with VAR (a fresh runtime context) as the CURRENT evaluation context,
so LIVE-DEBUGGER-UI-KEYWORD reads the AutoLISP *CLAL-DEBUGGER-UI* from it."
  `(let* ((,var (clautolisp.autolisp-runtime:make-default-runtime-context))
          (clautolisp.autolisp-runtime.internal::*active-evaluation-context* ,var))
     ,@body))

(defun %set-debugger-ui-mirror (name context)
  "Set the AutoLISP *CLAL-DEBUGGER-UI* mirror to the symbol NAME (a string), as
(setq *clal-debugger-ui* 'name) would from AutoLISP."
  (clautolisp.autolisp-runtime:set-variable
   (clautolisp.autolisp-runtime:intern-autolisp-symbol "*CLAL-DEBUGGER-UI*")
   (clautolisp.autolisp-runtime:intern-autolisp-symbol name)
   context))

(test live-debugger-ui-keyword-falls-back-to-the-cli-default
  ;; No AutoLISP mirror set ⇒ the CLI-set runtime default (--debugger-ui) wins.
  (with-active-context (ctx)
    (declare (ignore ctx))
    (let ((clautolisp.autolisp-runtime:*clal-debugger-ui* :ncurses))
      (is (eq :ncurses (clautolisp.tools.clautolisp::live-debugger-ui-keyword))))))

(test live-debugger-ui-keyword-honours-the-autolisp-mirror
  ;; (setq *clal-debugger-ui* 'tui) overrides the CLI default, read live.
  (with-active-context (ctx)
    (let ((clautolisp.autolisp-runtime:*clal-debugger-ui* :ncurses))
      (%set-debugger-ui-mirror "TUI" ctx)
      (is (eq :tui (clautolisp.tools.clautolisp::live-debugger-ui-keyword)))
      ;; and a later change is seen (it is re-read each call, not cached)
      (%set-debugger-ui-mirror "ALDB" ctx)
      (is (eq :aldb (clautolisp.tools.clautolisp::live-debugger-ui-keyword))))))

(test debug-ui-selector-rebuilds-only-when-the-live-selection-changes
  ;; The per-stop selector returns the SAME UI while the selection is unchanged,
  ;; and a freshly built UI when *CLAL-DEBUGGER-UI* changes.
  (with-active-context (ctx)
    (let ((clautolisp.autolisp-runtime:*clal-debugger-ui* :tui))
      (let* ((initial (clautolisp.tools.clautolisp::build-debug-ui :tui ctx))
             (selector (clautolisp.tools.clautolisp::make-debug-ui-selector
                        :tui initial ctx)))
        ;; unchanged ⇒ the seeded launch UI, same object (no rebuild)
        (is (eq initial (funcall selector)))
        (is (eq initial (funcall selector)))
        ;; switch selection ⇒ a different, freshly built UI object
        (%set-debugger-ui-mirror "NCURSES" ctx)
        (let ((switched (funcall selector)))
          (is (not (eq initial switched)))
          ;; stable at the new selection ⇒ same object again
          (is (eq switched (funcall selector)))
          ;; switch back ⇒ rebuilt once more (a new object)
          (%set-debugger-ui-mirror "TUI" ctx)
          (is (not (eq switched (funcall selector)))))))))

;;; --- the session's per-stop re-resolution / swap -------------------

(defclass recording-ui ()
  ((attached :initform nil :accessor recording-ui-attached-p)
   (detached :initform nil :accessor recording-ui-detached-p))
  (:documentation "A minimal UI that records whether it was attached/detached,
to observe RESOLVE-SESSION-UI swapping the active UI."))

(defmethod clautolisp.debug.ui:ui-attached ((ui recording-ui) session)
  (declare (ignore session))
  (setf (recording-ui-attached-p ui) t))

(defmethod clautolisp.debug.ui:ui-detached ((ui recording-ui))
  (setf (recording-ui-detached-p ui) t))

(test resolve-session-ui-swaps-the-active-ui-on-a-changed-selection
  (let* ((a (make-instance 'recording-ui))
         (b (make-instance 'recording-ui))
         (wanted a)
         (session (clautolisp.debug.ui::make-debugger-session
                   :ui a :ui-selector (lambda () wanted))))
    ;; selector wants the current UI ⇒ no swap, no detach
    (is (eq a (clautolisp.debug.ui::resolve-session-ui session)))
    (is (not (recording-ui-detached-p a)))
    ;; selector now wants B ⇒ detach A, attach B, session slot becomes B
    (setf wanted b)
    (is (eq b (clautolisp.debug.ui::resolve-session-ui session)))
    (is (recording-ui-detached-p a))
    (is (recording-ui-attached-p b))
    (is (eq b (clautolisp.debug.ui::debugger-session-ui session)))
    ;; stable at B ⇒ no further churn
    (is (eq b (clautolisp.debug.ui::resolve-session-ui session)))))

(test resolve-session-ui-without-a-selector-keeps-the-fixed-ui
  ;; Library callers (no selector) always use the session's fixed UI.
  (let* ((a (make-instance 'recording-ui))
         (session (clautolisp.debug.ui::make-debugger-session :ui a)))
    (is (eq a (clautolisp.debug.ui::resolve-session-ui session)))
    (is (not (recording-ui-detached-p a)))))
