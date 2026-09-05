;;;; clautolisp/tools/clautolisp/source/sleeping-aldo.lisp
;;;;
;;;; The "sleeping-aldo" interactor (aldo-command-from-repl.issue): a thin
;;;; ALDO / DEBUG interactor pushed BELOW the *AUTOLISP* interactor in the Lisp
;;;; REPL, giving a subset of aldo's debugging commands when the full aldo
;;;; debugger is not on the stack — chiefly managing breakpoints between runs.
;;;;
;;;; It is a DISTINCT interactor from the real *ALDO* (autolisp-debug-ui-dumb):
;;;; it shares only the name "ALDO" and alias "DEBUG" so `,aldo …' / `,debug …'
;;;; routing reaches it on the REPL stack (FIND-ACTIVATION matches the
;;;; interactor's name/alias on the stack). Because a lisp-interactor command of
;;;; the same name shadows it, the ALDO/DEBUG prefix reaches these when needed.
;;;;
;;;; It is deliberately NOT registered in the interactor registry (no
;;;; DEFINE-INTERACTOR): REGISTER-INTERACTOR replaces any same-name entry, which
;;;; would evict the real *ALDO* — and the registry is for listing / named
;;;; user-command binding, which should keep pointing at the full debugger.
;;;;
;;;; The breakpoints live on the persistent debugger session's thread-info (the
;;;; session START-DEBUG-SESSION created and REPL-LOOP was handed under
;;;; --debugger-ui / --on-error debug); with no session, debugging is off and
;;;; the commands say so. Only the subset that needs no live stop is here so
;;;; far — break (on a function's entry) and list breakpoints; the rest of the
;;;; issue's table (enable/disable/delete/condition/ignore, file:line & line
;;;; forms, list-source) is staged as follow-up.

(in-package #:clautolisp.tools.clautolisp)

(defstruct sleeping-aldo-state
  "A sleeping-aldo activation's state: the debugger SESSION whose thread-info
holds the breakpoints, or NIL when no debugger is attached to the REPL."
  session)

(defparameter *sleeping-aldo*
  (make-interactor
   :name "ALDO" :alias "DEBUG"
   :documentation
   "A subset of the aldo debugger's commands, usable from the Lisp REPL while
the full aldo debugger is not active — mainly to manage breakpoints between
runs (aldo-command-from-repl.issue).")
  "The sleeping-aldo interactor (see this file's header): NOT registered, so it
does not evict the real *ALDO* from the interactor registry.")

(defun make-sleeping-aldo-activation (session)
  "A sleeping-aldo activation over SESSION (the REPL's debugger session, or NIL),
to push below the *AUTOLISP* interactor in the REPL stack."
  (make-activation *sleeping-aldo* (make-sleeping-aldo-state :session session)))

(defun %sleeping-aldo-session ()
  "The SESSION of the running sleeping-aldo command, or NIL."
  (sleeping-aldo-state-session (activation-state *command-activation*)))

(defun %sleeping-aldo-require-session ()
  "The session, or NIL after reporting that debugging is not active."
  (or (%sleeping-aldo-session)
      (progn
        (format t "~&aldo: debugging is not active — start with --debug, ~
--on-error debug, or a --debugger-ui to manage breakpoints.~%")
        nil)))

(define-command (*sleeping-aldo* b break) (&whole argument)
    "Set a breakpoint on a function's entry: ,break FUNC-NAME."
  (let ((session (%sleeping-aldo-require-session))
        (name (string-trim " " (or argument ""))))
    (when session
      (cond
        ((zerop (length name))
         (format t "~&usage: ,break FUNC-NAME   (breakpoint on the function's entry)~%"))
        ;; the file:line and bare-line forms are staged for a follow-up
        ((or (find #\: name) (every #'digit-char-p name))
         (format t "~&aldo: only ,break FUNC-NAME is available from the REPL so ~
far (file:line / line forms are coming).~%"))
        (t
         (let ((metadata (clautolisp.debug:ensure-metadata-for-name name)))
           (if (null metadata)
               (format t "~&aldo: no user-defined function named ~A~%"
                       (string-upcase name))
               (let ((bp (clautolisp.debug.ui:cmd-set-breakpoint
                          session
                          (clautolisp.debug:function-debug-metadata-function-id metadata)
                          0)))
                 (format t "~&breakpoint #~A on ~A (entry)~%"
                         (clautolisp.debug:breakpoint-id bp)
                         (string-upcase name))))))))))

(define-command (*sleeping-aldo* lb list breakpoints) ()
    "List the breakpoints."
  (let ((session (%sleeping-aldo-require-session)))
    (when session
      (let ((breakpoints (clautolisp.debug.ui:cmd-list-breakpoints session)))
        (if (null breakpoints)
            (format t "~&no breakpoints.~%")
            (dolist (bp breakpoints)
              (format t "~&#~A  fid ~A  form ~A  ~A~%"
                      (clautolisp.debug:breakpoint-id bp)
                      (clautolisp.debug:breakpoint-fid bp)
                      (clautolisp.debug:breakpoint-form-id bp)
                      (if (clautolisp.debug:breakpoint-enabled-p bp)
                          "enabled" "disabled"))))))))
