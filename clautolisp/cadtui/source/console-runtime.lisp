(in-package #:clautolisp.cadtui)

;;;; Per-console runtime: namespace + scheduled-context + line queue (Phase 4).
;;;;
;;;; Each drawing's console runs its AutoLISP on the cador-2 cooperative
;;;; scheduler (autolisp-runtime/scheduler.lisp), never a second scheduler:
;;;;   ui-console  <->  a thread-backed scheduled-context on the session's
;;;;                    document-scheduler
;;;;   the console's evaluation-context carries the drawing's isolated
;;;;                    document-namespace (per-document isolation is already a
;;;;                    runtime guarantee — the anti-BricsCAD contract, spec
;;;;                    §"Communication inter-dessins")
;;;;   ui-console lignes-en-attente = a park-mailbox: the type-ahead line queue.
;;;;
;;;; Slice 1 lands the plumbing (namespace, context, queue) with NO live thread:
;;;; the context's thunk (the read-eval loop) and the blocking park-aware read
;;;; are slice 2; delivery and the REPL rules are slice 3. Single-document /
;;;; batch cador sessions never call this, so they stay scheduler-free and
;;;; thread-free (the no-regression guard).

(defun ensure-session-scheduler (session)
  "The session's document-scheduler, creating and installing one if absent.
A single-document/batch session that never opens a second console keeps
SESSION-SCHEDULER nil and stays thread-free."
  (or (session-scheduler session)
      (setf (session-scheduler session) (make-document-scheduler))))

(defun make-console-context (session console
                             &key (document-key (string (gensym "DOC")))
                                  (thunk nil))
  "Build the runtime backing for CONSOLE on SESSION: a fresh isolated
document-namespace keyed by DOCUMENT-KEY, an evaluation-context over it, and a
scheduled-context (THUNK is its read-eval loop, supplied in slice 2; NIL leaves
it a plain context that spawns no thread). Registers the namespace on the
session and the context on the session scheduler, gives CONSOLE its line queue,
and stores the context in CONSOLE. Returns the scheduled-context."
  (let* ((namespace (make-document-namespace :name document-key))
         (evaluation-context (make-evaluation-context
                              :session session
                              :current-document namespace
                              :current-namespace namespace))
         (scheduler (ensure-session-scheduler session))
         (scheduled-context (make-scheduled-context
                             :context evaluation-context
                             :document-key document-key
                             :thunk thunk)))
    (setf (document-namespace-host-document-key namespace) document-key)
    (register-runtime-session-document session namespace :copy-propagated-p nil)
    (scheduler-register-context scheduler scheduled-context)
    (setf (ui-context console) scheduled-context
          (ui-lignes-en-attente console) (make-park-mailbox))
    scheduled-context))

(defun console-namespace (console)
  "CONSOLE's isolated document-namespace, or NIL when it has no context."
  (let ((sc (ui-context console)))
    (and sc (evaluation-context-current-namespace (scheduled-context-context sc)))))

(defun console-queue (console)
  "CONSOLE's type-ahead line queue (a park-mailbox), or NIL."
  (ui-lignes-en-attente console))

(defun deliver-line-to-console (console line)
  "Push a pass-through LINE onto CONSOLE's type-ahead queue (non-blocking); the
console's AutoLISP thread consumes it at its next read, in arrival order. A
console with no queue silently drops the line (nothing is reading it)."
  (let ((queue (console-queue console)))
    (when queue (park-mailbox-push queue line)))
  line)
