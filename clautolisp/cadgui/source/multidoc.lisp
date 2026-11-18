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
evaluates at a time; the rest hold parked evaluations.

AWAITING / QUEUED are the MULTIPLEXING driver's state (used by
CADGUI-WORKSPACE-DRIVE-STEP): AWAITING maps a scheduled-context to T while it is
parked for input; QUEUED maps it to a FIFO of input lines that arrived before it
parked. They let the driver resume WHICHEVER document just got input, even if
another parked first (out-of-order input), through one wait point."
  (session nil)
  (scheduler nil)
  (docs '())
  (awaiting (make-hash-table :test 'eq))
  (queued (make-hash-table :test 'eq)))

(defun cadgui-make-workspace ()
  "A fresh empty workspace with its own session + cooperative scheduler."
  (let ((session (clautolisp.autolisp-runtime:make-runtime-session))
        (sched (clautolisp.autolisp-runtime:make-document-scheduler)))
    (setf (clautolisp.autolisp-runtime:session-scheduler session) sched)
    (let ((ws (%make-cadgui-workspace :session session :scheduler sched)))
      ;; The documents share ONE session, so its HAL host is a single slot. Bind
      ;; it to the ACTIVE document's own host on every scheduler activation
      ;; (set-runtime-session-current-document fires this hook on every resume),
      ;; so typed (command)/entmake act on the right document -- otherwise an
      ;; interleaved sibling's host would be left bound and the models would bleed.
      (setf clautolisp.autolisp-runtime:*document-activation-hook*
            (lambda (s doc) (%cadgui-activate-document ws s doc)))
      ws)))

(defun %cadgui-activate-document (workspace session namespace)
  "Document-activation hook: bind SESSION's HAL host to the host of WORKSPACE's
document whose key NAMESPACE carries. A no-op for a namespace this workspace does
not own (so a stale global hook from another workspace never misbinds)."
  (let* ((key (clautolisp.autolisp-runtime:document-namespace-host-document-key namespace))
         (doc (and key (find key (cadgui-workspace-docs workspace)
                             :key #'cadgui-doc-key :test #'eql))))
    (when doc
      (clautolisp.autolisp-runtime:set-runtime-session-host
       session (cadgui-doc-host doc)))))

(defun cadgui-doc-supply (doc line)
  "Supply the next input LINE (a string, e.g. a point \"x,y\") to DOC's channel --
the GUI side of a click. Non-blocking. :EOF ends the document's input."
  (clautolisp.autolisp-runtime:park-mailbox-push (cadgui-doc-input doc) line)
  doc)

(defun cadgui-doc-supply-point (doc x y)
  "Supply a world point (X,Y) to DOC -- what a canvas click on DOC's view sends."
  (cadgui-doc-supply doc (cadgui-point-line x y)))

;;; --- the MULTIPLEXING driver (the live Qt driver thread runs this) --------
;;;
;;; Unlike the batch driver (CADGUI-WORKSPACE-RUN, which serves parks in order
;;; and blocks on a document's read), the multiplexing driver routes BOTH park
;;; notifications AND input arrivals through the scheduler's single driver wait
;;; point (SCHEDULER-NOTIFY-DRIVER), and resumes a parked document DIRECTLY with
;;; the supplied line (the line IS the read's response -- no blocking read on the
;;; driver). So it resumes WHICHEVER document just received input, even if
;;; another document parked first: the user can click in any window, in any
;;; order. A canvas click calls CADGUI-DOC-FEED; the Qt driver thread loops
;;; CADGUI-WORKSPACE-DRIVE-STEP.

(defun cadgui-doc-feed (workspace doc line)
  "Route an input LINE for DOC to the driver (the Qt main thread calls this on a
click). Delivered through the scheduler's single driver wait point, so the
driver resumes DOC even if another document parked earlier (out-of-order input).
Non-blocking."
  (clautolisp.autolisp-runtime:scheduler-notify-driver
   (cadgui-workspace-scheduler workspace)
   (list :input doc line))
  doc)

(defun cadgui-doc-feed-point (workspace doc x y)
  "Feed a world point (X,Y) for DOC through the multiplexing driver."
  (cadgui-doc-feed workspace doc (cadgui-point-line x y)))

(defun cadgui-workspace-launch (workspace doc)
  "Kick DOC's evaluation without waiting (the driver's DRIVE-STEP consumes the
resulting park). Start documents one at a time -- launch, then DRIVE-STEP its
park -- so the single-runner start is not raced."
  (clautolisp.autolisp-runtime:scheduler-start
   (cadgui-workspace-scheduler workspace) (cadgui-doc-context doc))
  doc)

(defun cadgui-workspace-drive-step (workspace &optional (timeout 5))
  "One step of the multiplexing driver loop. Wait for ONE event and act:
  - (:park sc ..)  -- a document parked for input. If it already has QUEUED
                      input, resume it at once with the next line; else mark it
                      AWAITING. Returns :PARK.
  - (:input doc L) -- input L arrived for DOC (CADGUI-DOC-FEED). If DOC is
                      AWAITING, resume it with L; else QUEUE L until it parks.
                      Returns :INPUT.
  - (:done sc ..)  -- a document finished. Returns :DONE.
  - none in TIMEOUT -- returns :TIMEOUT.
Resuming is DIRECT (SCHEDULER-RESUME-CONTEXT): the line is the parked read's
response, no blocking read on the driver thread."
  (let* ((sched (cadgui-workspace-scheduler workspace))
         (ev (clautolisp.autolisp-runtime:scheduler-await-park sched timeout)))
    (cond
      ((eq ev :timeout) :timeout)
      ((eq (first ev) :park)
       (let* ((sc (second ev))
              (q (gethash sc (cadgui-workspace-queued workspace))))
         (if q
             (progn
               (setf (gethash sc (cadgui-workspace-queued workspace)) (rest q))
               (clautolisp.autolisp-runtime:scheduler-resume-context sc (first q)))
             (setf (gethash sc (cadgui-workspace-awaiting workspace)) t))
         :park))
      ((eq (first ev) :input)
       (let* ((doc (second ev)) (line (third ev))
              (sc (cadgui-doc-context doc)))
         (if (gethash sc (cadgui-workspace-awaiting workspace))
             (progn
               (remhash sc (cadgui-workspace-awaiting workspace))
               (clautolisp.autolisp-runtime:scheduler-resume-context sc line))
             (setf (gethash sc (cadgui-workspace-queued workspace))
                   (append (gethash sc (cadgui-workspace-queued workspace)) (list line))))
         :input))
      ((eq (first ev) :done) :done)
      (t :unknown))))

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
    (let ((sched (cadgui-workspace-scheduler workspace)))
      (clautolisp.autolisp-runtime:scheduler-spawn-context
       sched sc
       (lambda ()
         ;; Run the document's evaluation, then notify the driver it finished
         ;; (so the multiplexing driver stops awaiting it). The notify runs
         ;; AFTER the thunk, so a (:done sc) event means the thunk's model
         ;; mutations are complete -- a safe point to read the document's model.
         (unwind-protect (funcall thunk host)
           (clautolisp.autolisp-runtime:scheduler-notify-driver sched (list :done sc))))))
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

(defun cadgui-workspace-run (workspace &optional (timeout 2))
  "Drive WORKSPACE to quiescence UNATTENDED, with input already available on the
documents' channels (pre-supplied, or supplied by another thread): start every
document and serve parks until no document parks any more. Returns the number of
parks served. This is the batch/scripted driver -- a script or an AI driving
several documents headless; the live Qt shell runs the equivalent serve loop on
its driver thread, with the input arriving from canvas clicks instead."
  (let ((sched (cadgui-workspace-scheduler workspace))
        (served 0)
        (pending '()))
    ;; Start each document (one at a time) to its first park; hold the notes.
    ;; (A document that finishes without parking yields :done, not a :park.)
    (flet ((parkp (ev) (and (consp ev) (eq (first ev) :park))))
      (dolist (doc (reverse (cadgui-workspace-docs workspace)))
        (let ((note (cadgui-workspace-start workspace doc timeout)))
          (when (parkp note) (push note pending))))
      ;; Serve held parks; each resume runs a document to its next park
      ;; (collected) or to completion (:done). Drains when no document parks.
      (loop while pending do
        (let ((note (pop pending)))
          (clautolisp.autolisp-runtime:scheduler-serve-park sched note)
          (incf served)
          (let ((next (clautolisp.autolisp-runtime:scheduler-await-park sched timeout)))
            (when (parkp next) (push next pending))))))
    served))

(defun cadgui-document-run-command (host string)
  "Evaluate STRING as AutoLISP IN THE CURRENT document context -- so any
getpoint/entsel/ssget it performs parks to the scheduler driver and resumes from
THIS document's input channel -- with HOST bound for the get-family and entmake.
Call it from a document's thunk, running on its own context thread: it is the
interactive per-document eval the live multi-window shell uses (a document's
command loop reads a typed command line and runs it through here). Returns the
value of the last form.

Unlike cadgui-eval-command (which spins a FRESH session with no scheduler, so
its getpoint would read synchronously), this reuses the CURRENT evaluation
context -- the one the scheduler installed -- so the whole get-family parks
cooperatively and the document interleaves with its siblings."
  (let* ((ctx (clautolisp.autolisp-runtime:current-evaluation-context))
         (dialect (clautolisp.autolisp-reader:autolisp-dialect-strict))
         (options (clautolisp.autolisp-runtime:derive-reader-options-for-dialect
                   dialect :source-name "<cadgui>"))
         (forms (clautolisp.autolisp-runtime:read-runtime-from-string string :options options)))
    (clautolisp.autolisp-builtins-core:install-core-builtins)
    (clautolisp.autolisp-runtime:set-runtime-session-host
     (clautolisp.autolisp-runtime:evaluation-context-session ctx) host)
    (clautolisp.autolisp-runtime:autolisp-eval-progn forms ctx)))

(defun cadgui-document-command-loop (host)
  "A document's interactive command loop (its thunk): read a command line from
the document's input (parks), run it as AutoLISP through
CADGUI-DOCUMENT-RUN-COMMAND, repeat until end of input. This is what each live
document window drives -- the user types a command, it runs, its getpoints read
the canvas. Blank lines are skipped; :EOF ends the loop."
  (loop
    (let ((line (clautolisp.cador:read-prompt-line host)))
      (when (eq line :eof) (return))
      (when (and (stringp line) (plusp (length (string-trim '(#\Space #\Tab) line))))
        (ignore-errors (cadgui-document-run-command host line))))))

(defun cadgui-doc-display-list (doc)
  "The display list of DOC's OWN model -- what DOC's window renders. Same
(:POLYLINE ...) format as cadgui-display-list, but for this document's host."
  (clautolisp.cador:cador-scene-display-list (cadgui-doc-host doc)))

(defun cadgui-doc-extents (doc)
  "(XMIN YMIN XMAX YMAX) of DOC's model, or NIL -- DOC's zoom-extents."
  (clautolisp.cador:cador-scene-extents (cadgui-doc-host doc)))

(defun cadgui-workspace-all-finished-p (workspace)
  "True when every document's evaluation thread has finished -- the shell polls
this to know when a batch of driven work is quiescent."
  (every (lambda (doc)
           (let ((th (clautolisp.autolisp-runtime:scheduled-context-thread
                      (cadgui-doc-context doc))))
             (or (null th) (not (bordeaux-threads:thread-alive-p th)))))
         (cadgui-workspace-docs workspace)))

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
