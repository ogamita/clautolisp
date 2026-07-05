(in-package #:clautolisp.debug.ui)

;;;; The debugger.ui protocol (spec §17.1/§17.2). Notifications are
;;;; generic functions with NIL default methods, so a UI implements only
;;;; what it needs (spec §17.1). The one notification that must return a
;;;; value is UI-AWAIT-COMMAND: at a stopping point it drives the UI's
;;;; command loop and returns a resume directive interpreted by the engine
;;;; (:continue | (:step KIND) | (:advance FID FORM-ID [WHEN]) | :abort |
;;;; (:continue-with-return VALUE)). For in-image terminal UIs this runs
;;;; synchronously inside the application thread's *debug-hit-handler*.

;;; debugger → UI notifications
(defgeneric ui-attached (ui session)
  (:method (ui session) (declare (ignore ui session)) nil))
(defgeneric ui-detached (ui)
  (:method (ui) (declare (ignore ui)) nil))
(defgeneric ui-thread-hit (ui session hit)
  (:method (ui session hit) (declare (ignore ui session hit)) nil))
(defgeneric ui-thread-unhandled-error (ui session hit)
  (:method (ui session hit) (declare (ignore ui session hit)) nil))
(defgeneric ui-thread-caught-error (ui session hit)
  (:method (ui session hit) (declare (ignore ui session hit)) nil))
(defgeneric ui-thread-resumed (ui session)
  (:method (ui session) (declare (ignore ui session)) nil))
(defgeneric ui-thread-exited (ui session outcome)
  (:method (ui session outcome) (declare (ignore ui session outcome)) nil))
(defgeneric ui-breakpoint-added (ui breakpoint)
  (:method (ui breakpoint) (declare (ignore ui breakpoint)) nil))
(defgeneric ui-breakpoint-removed (ui breakpoint)
  (:method (ui breakpoint) (declare (ignore ui breakpoint)) nil))
(defgeneric ui-show-source (ui source-position)
  (:method (ui source-position) (declare (ignore ui source-position)) nil))
(defgeneric ui-show-message (ui level format-string &rest args)
  (:method (ui level format-string &rest args)
    (declare (ignore ui level format-string args)) nil))

;;; Pre-debug navigation entry (bug-aldo-nav-entry-and-breakpoint-flow): open the
;;; navigator for a queued CLAL-NAV-* request WITHOUT a stop, so
;;; (clal-nav-function 'NAME) at the REPL browses NAME and sets breakpoints
;;; without faking a break. The REPL calls this after a turn whose evaluation
;;; queued a request. Default: no-op (a UI with no interactive navigator).
(defgeneric ui-open-navigation-request (ui session request)
  (:documentation
   "Open the navigator for a queued CLAL-NAV-* REQUEST (see
clautolisp.debug:*pending-nav-request*) outside a stop. Returns NIL.")
  (:method (ui session request) (declare (ignore ui session request)) nil))

;;; Run one debugger command from outside the stop loop (spec §7): CLAL-SEDIT's
;;; `debug'/`aldo' prefix routes here through *debug-command-hook* so the editor
;;; can reach debugger commands (e.g. `aldo help'). Default: no-op.
(defgeneric ui-run-command (ui session command)
  (:documentation
   "Run the debugger COMMAND string in SESSION and return its resume directive
(or NIL). Used outside a stop, so there is no HIT.")
  (:method (ui session command) (declare (ignore ui session command)) nil))

;;; The command loop. UI returns a resume directive.
(defgeneric ui-await-command (ui session hit)
  (:documentation
   "Drive the UI's command loop at the stopping point described by HIT and
return a resume directive. Default: continue immediately.")
  (:method (ui session hit) (declare (ignore ui session hit)) :continue))

;;; --- the UI registry (spec §21 :ui keyword → constructor) ----------

(defparameter *ui-constructors* (make-hash-table :test 'eq)
  "Keyword (e.g. :terminal, :ncurses, :emacs) → a function of (&rest
initargs) returning a UI instance. Concrete UI systems register here.")

(defun register-ui (keyword constructor)
  (setf (gethash keyword *ui-constructors*) constructor))

(defun make-ui (designator &rest initargs)
  "Resolve a UI designator: a keyword looked up in *UI-CONSTRUCTORS*, or
an already-constructed UI object returned as-is."
  (cond
    ((keywordp designator)
     (let ((constructor (gethash designator *ui-constructors*)))
       (unless constructor
         (error "No registered debugger UI for ~S. Known: ~S"
                designator (loop for k being the hash-keys of *ui-constructors* collect k)))
       (apply constructor initargs)))
    (t designator)))
