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
  "An open document in a CADGUI-WORKSPACE, on the workspace's SHARED cador host
(one host, N drawings -- the cador-correct multi-document model). KEY is the
caller's label; CADOR-KEY is the cador document key (a string) on the shared
host; DRAWING is this document's own drawing (so it can be rendered without
being current); STREAM is this document's cador input stream (its channel), made
current with the document; CONTEXT is its scheduled-context; INPUT its channel."
  (key nil)
  (cador-key nil)
  (host nil)                             ; the workspace's SHARED cador host
  (drawing nil)
  (stream nil)
  (context nil)                          ; a runtime scheduled-context
  (input nil))                           ; a park-mailbox of input LINES

(defstruct (cadgui-workspace (:constructor %make-cadgui-workspace))
  "A multi-document cadgui workspace: the SHARED cador HOST (one host carrying all
the open drawings), the runtime SESSION that carries the single-runner
cooperative SCHEDULER, and the open DOCS. At most one document evaluates at a
time; the rest hold parked evaluations.

AWAITING / QUEUED are the MULTIPLEXING driver's state (used by
CADGUI-WORKSPACE-DRIVE-STEP): AWAITING maps a scheduled-context to T while it is
parked for input; QUEUED maps it to a FIFO of input lines that arrived before it
parked. They let the driver resume WHICHEVER document just got input, even if
another parked first (out-of-order input), through one wait point.

EVENTS / ENTITY-COUNTS are the STRUCTURED-INTERACTION protocol's state
(cadgui-action-layer slice C): as the driver processes each step it records a
structured event -- (:request ..), (:answer ..), (:entity-created ..), (:done ..)
-- onto EVENTS (newest first; CADGUI-WORKSPACE-EVENTS returns them in order), the
event stream an AI / test driver reads to follow what each command did without
screen-scraping. ENTITY-COUNTS maps a scheduled-context to the drawable-entity
count last observed for its document, so the driver can emit an :entity-created
event by diffing at a safe point (just after a park/done, when no context runs)."
  (host nil)
  (session nil)
  (scheduler nil)
  (docs '())
  (awaiting (make-hash-table :test 'eq))
  (queued (make-hash-table :test 'eq))
  (event-log '())
  (entity-counts (make-hash-table :test 'eq)))

(defun cadgui-make-workspace ()
  "A fresh empty workspace: ONE shared cador host, a session carrying the
cooperative scheduler, and the activation hook that switches the host's current
document in lock-step with the scheduler."
  (let ((session (clautolisp.autolisp-runtime:make-runtime-session))
        (sched (clautolisp.autolisp-runtime:make-document-scheduler))
        (host (clautolisp.cador:make-cador)))
    (setf (clautolisp.autolisp-runtime:session-scheduler session) sched)
    (clautolisp.autolisp-runtime:set-runtime-session-host session host)   ; the one HAL host
    (let ((ws (%make-cadgui-workspace :host host :session session :scheduler sched)))
      ;; Documents share ONE cador host with N drawings. On every scheduler
      ;; activation (set-runtime-session-current-document fires this hook), make
      ;; that document's drawing current AND point the host's prompt-stream at
      ;; that document's input channel -- so typed (command)/entmake and
      ;; getpoint/entsel act on the right document despite the shared host.
      (setf clautolisp.autolisp-runtime:*document-activation-hook*
            (lambda (s doc) (%cadgui-activate-document ws s doc)))
      ws)))

(defun %cadgui-activate-document (workspace session namespace)
  "Document-activation hook: on the workspace's shared host, make current the
cador document NAMESPACE names, and point the host's prompt-stream at that
document's input channel. A no-op for a namespace this workspace does not own (so
a stale global hook from another workspace never misactivates)."
  (declare (ignore session))
  (let* ((cador-key (clautolisp.autolisp-runtime:document-namespace-host-document-key namespace))
         (doc (and cador-key (find cador-key (cadgui-workspace-docs workspace)
                                   :key #'cadgui-doc-cador-key :test #'equal))))
    (when doc
      (let ((host (cadgui-workspace-host workspace)))
        (clautolisp.autolisp-host:host-activate-document host (cadgui-doc-cador-key doc))
        (setf (clautolisp.cador:cador-prompt-stream host) (cadgui-doc-stream doc))))))

(defun cadgui-doc-supply (doc line)
  "Supply the next input LINE (a string, e.g. a point \"x,y\") to DOC's channel --
the GUI side of a click. Non-blocking. :EOF ends the document's input."
  (clautolisp.autolisp-runtime:park-mailbox-push (cadgui-doc-input doc) line)
  doc)

(defun cadgui-doc-supply-point (doc x y)
  "Supply a world point (X,Y) to DOC -- what a canvas click on DOC's view sends."
  (cadgui-doc-supply doc (cadgui-point-line x y)))

;;; --- structured interaction: the event stream (slice C) -------------------
;;;
;;; The multiplexing driver is the one place that sees every park, every input
;;; arrival and every completion, so it is where the structured-interaction
;;; protocol lives. Each step records a machine-readable event onto the
;;; workspace -- a REQUEST when a document parks awaiting input, an ANSWER when
;;; input is delivered to it, an ENTITY-CREATED when a command grew a document's
;;; model, and DONE when a document finishes. An AI / test driver reads the
;;; stream (CADGUI-WORKSPACE-EVENTS) to follow a command to completion instead of
;;; screen-scraping, and reads the open REQUESTS (CADGUI-WORKSPACE-PENDING-REQUESTS)
;;; to know which document needs input next.

(defun %cadgui-doc-by-context (workspace sc)
  "The cadgui-doc whose scheduled-context is SC, or NIL."
  (find sc (cadgui-workspace-docs workspace) :key #'cadgui-doc-context :test #'eq))

(defun %cadgui-record-event (workspace event)
  "Push EVENT (a plist-tailed list, e.g. (:done :document :a)) onto WORKSPACE's
event stream. Newest first; CADGUI-WORKSPACE-EVENTS reverses to chronological."
  (push event (cadgui-workspace-event-log workspace))
  event)

(defun %cadgui-doc-entity-count (doc)
  "DOC's drawable-entity count -- the length of its own display list."
  (length (cadgui-doc-display-list doc)))

(defun %cadgui-note-entity-changes (workspace)
  "At a SAFE point (just after SCHEDULER-AWAIT-PARK returns, when the single
runner has yielded so NO context is running), diff each document's current
entity count against the last count recorded for it; for each document whose
model grew, record an (:entity-created :document KEY :count NEW :added DELTA)
event and update the recorded count. This turns a command's model mutation into
a structured event the driver can read without reaching into cador."
  (dolist (doc (cadgui-workspace-docs workspace))
    (let* ((sc  (cadgui-doc-context doc))
           (now (%cadgui-doc-entity-count doc))
           (was (gethash sc (cadgui-workspace-entity-counts workspace) 0)))
      (when (> now was)
        (%cadgui-record-event workspace
                              (list :entity-created :document (cadgui-doc-key doc)
                                    :count now :added (- now was))))
      (setf (gethash sc (cadgui-workspace-entity-counts workspace)) now))))

(defun cadgui-workspace-events (workspace)
  "WORKSPACE's structured event stream in chronological order -- the record of
what each document requested, was answered, drew, and finished, as plain data
for an AI / test driver (cadgui-action-layer slice C)."
  (reverse (cadgui-workspace-event-log workspace)))

(defun %cadgui-answer-event (workspace sc line)
  "The (:answer :document KEY :value LINE) event for delivering LINE to SC."
  (let ((doc (%cadgui-doc-by-context workspace sc)))
    (list :answer :document (and doc (cadgui-doc-key doc)) :value line)))

(defun cadgui-workspace-pending-requests (workspace)
  "The OPEN input requests: for each document currently parked awaiting input, a
(:document KEY :type :input) plist. What an AI / test driver reads to know which
document to answer next. TYPE is :input generically -- the cadgui canvas renders
it as a point pick when the shell is in pick mode; a per-get-family typed request
(point vs string vs keyword) is the follow-up over cador's prompt-api seam."
  (let ((out '()))
    (maphash (lambda (sc awaiting)
               (when awaiting
                 (let ((doc (%cadgui-doc-by-context workspace sc)))
                   (when doc
                     (push (list :document (cadgui-doc-key doc) :type :input) out)))))
             (cadgui-workspace-awaiting workspace))
    (nreverse out)))

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
    (when (eq ev :timeout) (return-from cadgui-workspace-drive-step :timeout))
    ;; Safe point: the runner has yielded, so NO context is running -- diff each
    ;; document's model and record any :entity-created events the LAST resume
    ;; produced, before this step resumes another context.
    (%cadgui-note-entity-changes workspace)
    (cond
      ((eq (first ev) :park)
       (let* ((sc (second ev))
              (q (gethash sc (cadgui-workspace-queued workspace))))
         (if q
             ;; input arrived before this park -- deliver it now (an ANSWER)
             (let ((line (first q)))
               (setf (gethash sc (cadgui-workspace-queued workspace)) (rest q))
               (%cadgui-record-event workspace (%cadgui-answer-event workspace sc line))
               (clautolisp.autolisp-runtime:scheduler-resume-context sc line))
             ;; no input yet -- the document is now awaiting (a REQUEST)
             (progn
               (setf (gethash sc (cadgui-workspace-awaiting workspace)) t)
               (let ((doc (%cadgui-doc-by-context workspace sc)))
                 (when doc
                   (%cadgui-record-event
                    workspace (list :request :document (cadgui-doc-key doc) :type :input))))))
         :park))
      ((eq (first ev) :input)
       (let* ((doc (second ev)) (line (third ev))
              (sc (cadgui-doc-context doc)))
         (if (gethash sc (cadgui-workspace-awaiting workspace))
             (progn
               (remhash sc (cadgui-workspace-awaiting workspace))
               (%cadgui-record-event workspace (%cadgui-answer-event workspace sc line))
               (clautolisp.autolisp-runtime:scheduler-resume-context sc line))
             (setf (gethash sc (cadgui-workspace-queued workspace))
                   (append (gethash sc (cadgui-workspace-queued workspace)) (list line))))
         :input))
      ((eq (first ev) :done)
       (let ((doc (%cadgui-doc-by-context workspace (second ev))))
         (when doc
           (%cadgui-record-event workspace (list :done :document (cadgui-doc-key doc)))))
       :done)
      (t :unknown))))

(defun cadgui-open-document (workspace key thunk)
  "Open document KEY on WORKSPACE's shared cador host -- a NEW drawing on the one
host -- and return its CADGUI-DOC. Creates this document's own input channel +
cador input stream, a scheduler context, and spawns THUNK (a function of the
host) as its evaluation (born parked; CADGUI-WORKSPACE-START kicks it). Inside
THUNK, getpoint/entsel/ssget park and are served from THIS document's channel,
and (command)/entmake act on THIS document's drawing (the activation hook makes
it current)."
  (let* ((host      (cadgui-workspace-host workspace))
         (cador-key (clautolisp.autolisp-host:host-open-document host (string key)))
         (drawing   (cdr (assoc cador-key (clautolisp.cador:cador-documents host) :test #'equal)))
         (input     (clautolisp.autolisp-runtime:make-park-mailbox))
         (stream    (make-instance 'cadgui-input-stream
                                   :fill-fn (lambda ()
                                              (let ((line (clautolisp.autolisp-runtime:park-mailbox-pop input)))
                                                (if (eq line :eof) nil line)))))
         (ns        (clautolisp.autolisp-runtime:make-document-namespace
                     :name (string key)))
         (ctx       (clautolisp.autolisp-runtime:make-evaluation-context
                     :session (cadgui-workspace-session workspace)
                     :current-document ns
                     :current-namespace ns))
         (sc        (clautolisp.autolisp-runtime:make-scheduled-context
                     :context ctx :document-key cador-key))
         (doc       (%make-cadgui-doc :key key :cador-key cador-key :host host
                                      :drawing drawing :stream stream :context sc :input input)))
    ;; The activation hook keys on the namespace's cador document key.
    (setf (clautolisp.autolisp-runtime:document-namespace-host-document-key ns) cador-key)
    (clautolisp.autolisp-runtime:scheduler-register-context
     (cadgui-workspace-scheduler workspace) sc)
    ;; Seed the entity-change baseline (slice C) so a document opened with
    ;; pre-existing geometry does not report its whole model as newly created.
    (setf (gethash sc (cadgui-workspace-entity-counts workspace))
          (%cadgui-doc-entity-count doc))
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

(defun cadgui-document-command-loop (host &optional after-command)
  "A document's interactive command loop (its thunk): read a command line from
the document's input (parks), run it as AutoLISP through
CADGUI-DOCUMENT-RUN-COMMAND, repeat until end of input. This is what each live
document window drives -- the user types a command, it runs, its getpoints read
the canvas. Blank lines are skipped. ANY non-string read ends the loop -- :EOF
(end of input) and :EXIT (the document is being closed, CADGUI-CLOSE-DOCUMENT
resumes the parked thread with :exit so it can unwind).

AFTER-COMMAND, when supplied, is a function of no arguments called ON THE
DOCUMENT'S THREAD after each command runs -- the live shell sets it to publish
this document's display-list snapshot and request its window's repaint (done on
the owning thread, so the paint is race-free)."
  (loop
    (let ((line (clautolisp.cador:read-prompt-line host)))
      (unless (stringp line) (return))          ; :EOF / :EXIT / anything non-string
      (when (plusp (length (string-trim '(#\Space #\Tab) line)))
        (ignore-errors (cadgui-document-run-command host line))
        (when after-command (ignore-errors (funcall after-command)))))))

(defun cadgui-doc-display-list (doc)
  "The display list of DOC's OWN drawing -- what DOC's window renders. Renders
DOC's specific drawing on the shared host, so it is correct even when a DIFFERENT
document is current. Same (:POLYLINE ...) format as cadgui-display-list."
  (clautolisp.cador:cador-scene-display-list (cadgui-doc-host doc) (cadgui-doc-drawing doc)))

(defun cadgui-doc-extents (doc)
  "(XMIN YMIN XMAX YMAX) of DOC's own drawing, or NIL -- DOC's zoom-extents."
  (clautolisp.cador:cador-scene-extents (cadgui-doc-host doc) (cadgui-doc-drawing doc)))

(defun cadgui-workspace-all-finished-p (workspace)
  "True when every document's evaluation thread has finished -- the shell polls
this to know when a batch of driven work is quiescent."
  (every (lambda (doc)
           (let ((th (clautolisp.autolisp-runtime:scheduled-context-thread
                      (cadgui-doc-context doc))))
             (or (null th) (not (bordeaux-threads:thread-alive-p th)))))
         (cadgui-workspace-docs workspace)))

(defun %cadgui-end-document-thread (doc)
  "End DOC's evaluation thread: close its input and resume it with :EXIT so its
command loop unwinds, then join. Shared by close and shutdown."
  (let* ((sc (cadgui-doc-context doc))
         (th (clautolisp.autolisp-runtime:scheduled-context-thread sc)))
    (ignore-errors (clautolisp.autolisp-runtime:park-mailbox-push
                    (cadgui-doc-input doc) :eof))
    (ignore-errors (clautolisp.autolisp-runtime:park-mailbox-push
                    (clautolisp.autolisp-runtime:scheduled-context-mailbox sc) :exit))
    (when (and th (bordeaux-threads:thread-alive-p th))
      (ignore-errors (bordeaux-threads:join-thread th))))
  doc)

(defun cadgui-close-document (workspace doc &key save file)
  "Close DOC: end its evaluation thread, close its cador document (SAVE writes it,
to FILE or its own path), and drop it from WORKSPACE. Returns T, or NIL when the
cador document could not be closed (cador keeps at least one open). The dead
scheduler context is left registered -- harmless, it never runs again."
  (%cadgui-end-document-thread doc)
  (if (clautolisp.autolisp-host:host-close-document
       (cadgui-workspace-host workspace) (cadgui-doc-cador-key doc) :save save :file file)
      (progn
        (setf (cadgui-workspace-docs workspace)
              (remove doc (cadgui-workspace-docs workspace)))
        t)
      nil))

(defun cadgui-workspace-document-keys (workspace)
  "The caller keys of WORKSPACE's open documents, in the order they were opened."
  (mapcar #'cadgui-doc-key (reverse (cadgui-workspace-docs workspace))))

(defun cadgui-workspace-active-document (workspace)
  "The cadgui-doc whose cador document is currently active on the shared host, or
NIL -- which window the GUI should show as focused."
  (let ((key (clautolisp.cador:cador-active-document-key (cadgui-workspace-host workspace))))
    (and key (find key (cadgui-workspace-docs workspace)
                   :key #'cadgui-doc-cador-key :test #'equal))))

(defun cadgui-document-state (doc &optional workspace)
  "A structured snapshot of DOC: its key, its drawable entity count, and whether
its evaluation thread is still alive. Plain data (a plist) for an AI / test
driver (action-layer get-state). With WORKSPACE, also reports :AWAITING -- whether
DOC is currently parked awaiting input (an open request the driver must answer)."
  (append
   (list :key (cadgui-doc-key doc)
         :entities (length (cadgui-doc-display-list doc))
         :alive (let ((th (clautolisp.autolisp-runtime:scheduled-context-thread
                           (cadgui-doc-context doc))))
                  (and th (bordeaux-threads:thread-alive-p th) t)))
   (when workspace
     (list :awaiting
           (and (gethash (cadgui-doc-context doc)
                         (cadgui-workspace-awaiting workspace))
                t)))))

(defun cadgui-workspace-state (workspace)
  "A structured snapshot of WORKSPACE for an AI / test driver -- the action
layer's GET-STATE (cadgui-action-layer slice B): the ACTIVE document key, each
open document's state (CADGUI-DOCUMENT-STATE), and the registered ACTION ids.
I.e. what is open, which is current, what each holds, and what can be invoked --
as plain data, no screen-scraping.

Includes the structured-interaction surface (slice C): :REQUESTS, the open input
requests (which documents are parked awaiting input), and :EVENTS, the structured
event stream (requests, answers, entity-creations, completions) in chronological
order."
  (list :active (let ((d (cadgui-workspace-active-document workspace)))
                  (and d (cadgui-doc-key d)))
        :documents (mapcar (lambda (doc) (cadgui-document-state doc workspace))
                           (reverse (cadgui-workspace-docs workspace)))
        :actions (cadgui-list-actions)
        :requests (cadgui-workspace-pending-requests workspace)
        :events (cadgui-workspace-events workspace)))

(defun cadgui-workspace-shutdown (workspace)
  "Stop every document thread (end input, resume with :EXIT, join). Safe to call
on a partially-run workspace."
  (dolist (doc (cadgui-workspace-docs workspace))
    (%cadgui-end-document-thread doc))
  workspace)
