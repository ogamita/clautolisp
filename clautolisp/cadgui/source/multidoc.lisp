;;;; cadgui multi-document workspace -- SLICE 1 of the cooperative-scheduler
;;;; integration (cadgui-2 "Threading architecture" / the scheduler remainder).
;;;;
;;;; The runtime already has a single-runner cooperative scheduler
;;;; (autolisp-runtime/source/scheduler.lisp) and cador already parks interactive
;;;; reads through it (prompt-api.lisp %cador-maybe-park-read): when a document's
;;;; evaluation runs on its own context thread and reaches a getpoint/entsel/ssget
;;;; with no input ready, it yields to the DRIVER, which performs the blocking
;;;; read on its own thread and resumes the context. At most one document context
;;;; evaluates at a time (the single-runner invariant); the others hold suspended
;;;; (parked) evaluations.
;;;;
;;;; This module is the cadgui side of that: a WORKSPACE of open documents, each
;;;; with its own cador host and a PER-DOCUMENT INPUT CHANNEL. The GUI (the Qt
;;;; main thread, later) fills a document's channel when the user clicks on its
;;;; canvas; the scheduler driver drains it to answer that document's parked read.
;;;; So two documents' getpoint-driven commands INTERLEAVE correctly, each
;;;; reading only its own input, with no cross-document bleed.
;;;;
;;;; Slice 1 is the CL foundation + headless driver, tested deterministically
;;;; (points supplied by the test instead of by canvas clicks). OUT of slice 1:
;;;; the Qt multi-window shell (a driver thread + per-document canvas, the active
;;;; document routing clicks to its channel), one shared cador host with N
;;;; drawings (slice 1 gives each document its own host), and document
;;;; switching/close UI.

(in-package #:clautolisp.cadgui)

(defstruct (cadgui-doc (:constructor %make-cadgui-doc))
  "An open document in a CADGUI-WORKSPACE: its cador HOST, its scheduled CONTEXT
in the cooperative scheduler, and its per-document INPUT channel (a blocking
mailbox the GUI fills and the scheduler driver drains)."
  (key nil)
  (host nil)
  (context nil)                          ; a runtime scheduled-context
  (input nil))                           ; a park-mailbox of input LINES

(defstruct (cadgui-workspace (:constructor %make-cadgui-workspace))
  "A multi-document cadgui workspace: the runtime SESSION that carries the
single-runner cooperative SCHEDULER, and the open DOCS. At most one document
evaluates at a time; the rest hold parked evaluations."
  (session nil)
  (scheduler nil)
  (docs '()))

(defun cadgui-make-workspace ()
  "A fresh empty workspace with its own session + cooperative scheduler."
  (let ((session (clautolisp.autolisp-runtime:make-runtime-session))
        (sched (clautolisp.autolisp-runtime:make-document-scheduler)))
    (setf (clautolisp.autolisp-runtime:session-scheduler session) sched)
    (%make-cadgui-workspace :session session :scheduler sched)))

(defun cadgui-doc-supply (doc line)
  "Supply the next input LINE (a string, e.g. a point \"x,y\") to DOC's channel --
the GUI side of a click. Non-blocking. :EOF ends the document's input."
  (clautolisp.autolisp-runtime:park-mailbox-push (cadgui-doc-input doc) line)
  doc)

(defun cadgui-doc-supply-point (doc x y)
  "Supply a world point (X,Y) to DOC -- what a canvas click on DOC's view sends."
  (cadgui-doc-supply doc (cadgui-point-line x y)))

(defun cadgui-open-document (workspace key thunk)
  "Open document KEY in WORKSPACE and return its CADGUI-DOC. Creates a fresh cador
host whose prompt-stream reads from this document's own input channel, a
scheduler context, and spawns THUNK -- a function of the host -- as the
document's evaluation (born parked; CADGUI-WORKSPACE-START kicks it). Inside
THUNK, getpoint/entsel/ssget park and are served from THIS document's channel."
  (let* ((input (clautolisp.autolisp-runtime:make-park-mailbox))
         (host  (clautolisp.cador:make-cador))
         (ns    (clautolisp.autolisp-runtime:make-document-namespace
                 :name (string key)))
         (ctx   (clautolisp.autolisp-runtime:make-evaluation-context
                 :session (cadgui-workspace-session workspace)
                 :current-document ns
                 :current-namespace ns))
         (sc    (clautolisp.autolisp-runtime:make-scheduled-context
                 :context ctx :document-key key))
         (doc   (%make-cadgui-doc :key key :host host :context sc :input input)))
    ;; This document's cador reads block on ITS channel (not the global hook).
    (setf (clautolisp.cador:cador-prompt-stream host)
          (make-instance 'cadgui-input-stream
                         :fill-fn (lambda ()
                                    (let ((line (clautolisp.autolisp-runtime:park-mailbox-pop input)))
                                      (if (eq line :eof) nil line)))))
    (setf (clautolisp.autolisp-runtime:document-namespace-host-document-key ns) key)
    (clautolisp.autolisp-runtime:scheduler-register-context
     (cadgui-workspace-scheduler workspace) sc)
    (clautolisp.autolisp-runtime:scheduler-spawn-context
     (cadgui-workspace-scheduler workspace) sc
     (lambda () (funcall thunk host)))
    (push doc (cadgui-workspace-docs workspace))
    doc))

(defun cadgui-workspace-start (workspace doc &optional (timeout 5))
  "Kick DOC's evaluation and block until it parks on its first input request;
return the park notification (serve it later with CADGUI-WORKSPACE-SERVE), or
:TIMEOUT if it finished / never parked. Documents are started ONE AT A TIME --
each runs to its first park before the next starts -- so the single-runner
invariant is never racing a half-started context."
  (clautolisp.autolisp-runtime:scheduler-start
   (cadgui-workspace-scheduler workspace) (cadgui-doc-context doc))
  (clautolisp.autolisp-runtime:scheduler-await-park
   (cadgui-workspace-scheduler workspace) timeout))

(defun cadgui-workspace-serve (workspace note &optional (timeout 5))
  "Serve a held park NOTE: run the parked document's blocked read on the driver
thread -- it reads that document's input channel, so SUPPLY the input first --
and resume it. The document then runs to its NEXT park; this returns that park
notification, or :TIMEOUT when the document finished. This is the step the Qt
driver thread will run in a loop."
  (clautolisp.autolisp-runtime:scheduler-serve-park
   (cadgui-workspace-scheduler workspace) note)
  (clautolisp.autolisp-runtime:scheduler-await-park
   (cadgui-workspace-scheduler workspace) timeout))

(defun cadgui-workspace-shutdown (workspace)
  "Stop every document thread: end its input, unpark it with :EXIT, and join.
Safe to call on a partially-run workspace."
  (dolist (doc (cadgui-workspace-docs workspace))
    (let* ((sc (cadgui-doc-context doc))
           (th (clautolisp.autolisp-runtime:scheduled-context-thread sc)))
      (ignore-errors (clautolisp.autolisp-runtime:park-mailbox-push
                      (cadgui-doc-input doc) :eof))
      (ignore-errors (clautolisp.autolisp-runtime:park-mailbox-push
                      (clautolisp.autolisp-runtime:scheduled-context-mailbox sc) :exit))
      (when (and th (bordeaux-threads:thread-alive-p th))
        (ignore-errors (bordeaux-threads:join-thread th)))))
  workspace)
