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
                             ;; default = the console read-eval loop (rules 2/3);
                             ;; a caller may supply its own thunk (tests do).
                             :thunk (or thunk (lambda () (%console-loop console))))))
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

;;; --- The park-aware blocked read (Phase 4 slice 2) ----------------
;;;
;;; Called ON the console's own scheduled-context thread. If a line is already
;;; queued (type-ahead) it is returned at once; otherwise the context yields the
;;; single-runner slot and PARKS until a line arrives — reusing the cador-2
;;; park-to-driver machinery (scheduler-park), so the blocking pop runs on the
;;; driver thread, never on the runner (D1 §13.1). Returns the line, or :exit
;;; when the context is torn down while parked.

(defun console-read-line (console)
  "Read the next pass-through line delivered to CONSOLE, blocking (via a park) if
the queue is empty. Must be called on CONSOLE's scheduled-context thread."
  (let* ((sc (ui-context console))
         (queue (console-queue console))
         (session (evaluation-context-session (scheduled-context-context sc)))
         (scheduler (session-scheduler session))
         ;; non-blocking poll: return a queued line at once (type-ahead).
         (immediate (park-mailbox-pop queue 0)))
    (if (not (eq immediate :timeout))
        immediate
        ;; empty: park until the driver delivers a line and serves the read.
        (scheduler-park scheduler sc (lambda () (park-mailbox-pop queue))))))

(defun start-console (console)
  "Spawn and start CONSOLE's scheduled-context thread (its read-eval loop). The
context must already carry a thunk (make-console-context). Returns the context."
  (let* ((sc (ui-context console))
         (session (evaluation-context-session (scheduled-context-context sc)))
         (scheduler (session-scheduler session)))
    (scheduler-spawn-context scheduler sc (scheduled-context-thunk sc))
    (scheduler-start scheduler sc)
    sc))

;;; --- REPL rules 2/3 + the read-eval loop (Phase 4 slice 3) --------
;;;
;;; Per popped pass-through line (spec §5.6): a line beginning with ( is a Lisp
;;; expression evaluated in THIS console's isolated namespace (rule 2 — the
;;; anti-BricsCAD isolation); anything else is a CAD command name (rule 3),
;;; for which Phase 4 records a stand-in — live command execution is Phase 5/6.
;;; Rule 1 (a blocked AutoLISP read taking priority) is console-read-line's park.

(defun %console-record (console text)
  "Append TEXT to CONSOLE's output buffer (a list of lines, in order)."
  (setf (ui-stream-buffer console)
        (append (ui-stream-buffer console) (list text)))
  text)

(defun %console-eval-lisp (console line)
  "Evaluate LINE (a Lisp expression) in CONSOLE's isolated evaluation-context."
  (let* ((sc (ui-context console))
         (evaluation-context (scheduled-context-context sc))
         (forms (read-runtime-from-string line :source-name "<cadtui-console>")))
    (autolisp-eval-toplevel-progn forms evaluation-context)))

(defun %console-repl-step (console line)
  "Apply REPL rules 2/3 to one pass-through LINE on CONSOLE."
  (let ((trimmed (string-left-trim '(#\Space #\Tab) line)))
    (cond
      ((zerop (length trimmed)) nil)
      ;; rule 2: a Lisp expression, evaluated in this console's namespace.
      ((char= (char trimmed 0) #\()
       (%console-eval-lisp console trimmed)
       (%console-record console (format nil "=> ~A" trimmed)))
      ;; rule 3: a CAD command name (live execution is Phase 5/6).
      (t (%console-record console (format nil "CAD command (not yet): ~A" trimmed))))))

(defun %console-loop (console)
  "The console's read-eval loop, run on its scheduled-context thread: read a
pass-through line (parking when none) and apply the REPL rules, until :exit.
An eval error is recorded and the loop survives (a REPL never dies on a slip)."
  (loop
    (let ((line (console-read-line console)))
      (when (eq line :exit) (return))
      (handler-case (%console-repl-step console line)
        (error (condition)
          (%console-record console (format nil "error: ~A" condition)))))))
