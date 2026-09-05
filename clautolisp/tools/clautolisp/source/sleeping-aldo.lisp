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
;;;; session the tool creates for the lisp environment; the aldo companion
;;;; thread runs the full UI beside the REPL). Because the REPL thread and the
;;;; aldo companion are mutually exclusive (the blocking-queue rendezvous), the
;;;; REPL thread may read/modify the breakpoint table freely between stops.
;;;;
;;;; A breakpoint is designated by its poll-point number `ppN' (what `lb' shows
;;;; and the debugger UIs use). A NEW breakpoint is placed by a *position
;;;; designation* (aldo-command-from-repl.issue): so far by function —
;;;;   FUNC        the function's entry              (subform 0)
;;;;   FUNC.N      the Nth instrumenter poll-point of the function's source
;;;; N is the instrumenter-native form-id: entry is 0, then every COMPOUND
;;;; evaluable form pre-order, left-to-right (atoms/operators are not poll
;;;; points — see instrumenter-no-pollpoints-on-atoms.issue). The FILE:LINE /
;;;; bare-LINE forms and `condition' / `list source' are staged as follow-ups.

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

;;; --- breakpoint identification (ppN) and location display ----------------

(defun %sa-bp-pp (bp)
  "The poll-point number (ppN) of breakpoint BP — the id the UIs display and
these commands accept."
  (clautolisp.debug:poll-point-id (clautolisp.debug:breakpoint-fid bp)
                                  (clautolisp.debug:breakpoint-form-id bp)))

(defun %sa-parse-pp (token)
  "Parse a breakpoint selector TOKEN — \"ppN\" or \"N\" — to the integer N, or
NIL when it is not a poll-point number."
  (let* ((s (string-trim " " token))
         (digits (if (and (>= (length s) 2) (string-equal (subseq s 0 2) "pp"))
                     (subseq s 2)
                     s)))
    (and (plusp (length digits))
         (every #'digit-char-p digits)
         (values (parse-integer digits)))))

(defun %sa-bp-where (bp)
  "A human location for BP: the function name plus `(entry)' for the entry
poll-point or `.N' for subform N."
  (let* ((fid (clautolisp.debug:breakpoint-fid bp))
         (form-id (clautolisp.debug:breakpoint-form-id bp))
         (metadata (clautolisp.debug:metadata-for-function-id fid))
         (name (if metadata
                   (string-upcase (clautolisp.debug:function-debug-metadata-name metadata))
                   (format nil "fid ~A" fid))))
    (if (zerop form-id)
        (format nil "~A (entry)" name)
        (format nil "~A.~A" name form-id))))

(defun %sa-bp-line (bp)
  "The source line of BP's poll-point, or NIL when unknown."
  (ignore-errors
   (let* ((fid (clautolisp.debug:breakpoint-fid bp))
          (metadata (clautolisp.debug:metadata-for-function-id fid))
          (position (and metadata
                         (clautolisp.debug:form-id-position
                          metadata (clautolisp.debug:breakpoint-form-id bp)))))
     (when (clautolisp.source:source-position-p position)
       (clautolisp.source:source-position-start-line position)))))

(defun %sa-select-breakpoints (session token)
  "Resolve a selector TOKEN to a list of breakpoints on SESSION: empty or
\"ALL\" ⇒ every breakpoint; \"ppN\"/\"N\" ⇒ the one with that poll-point.
Returns :NONE when a ppN selector matches nothing."
  (let ((all (clautolisp.debug.ui:cmd-list-breakpoints session))
        (s (string-trim " " token)))
    (cond
      ((or (zerop (length s)) (string-equal s "ALL")) all)
      (t (let ((pp (%sa-parse-pp s)))
           (if (null pp)
               :none
               (let ((bp (find pp all :key #'%sa-bp-pp)))
                 (if bp (list bp) :none))))))))

;;; --- commands ------------------------------------------------------------

(defun %sa-parse-func-dot (name)
  "Split a break target NAME into (values FUNCTION-NAME SUBFORM-INDEX): a
trailing `.N' (all digits) is the subform index, else the whole NAME is the
function and the index is 0 (its entry)."
  (let ((dot (position #\. name :from-end t)))
    (if (and dot (< (1+ dot) (length name))
             (every #'digit-char-p (subseq name (1+ dot))))
        (values (subseq name 0 dot) (parse-integer name :start (1+ dot)))
        (values name 0))))

(defun %sa-break-function (session name index)
  "Set a breakpoint on function NAME's poll-point INDEX (0 = entry),
instrumenting it on demand. Reports the resulting ppN."
  (let ((metadata (clautolisp.debug:ensure-metadata-for-name name)))
    (if (null metadata)
        (format t "~&aldo: no user-defined function named ~A~%" (string-upcase name))
        (let ((count (length (clautolisp.debug:function-debug-metadata-form-id->position
                              metadata))))
          (if (>= index count)
              (format t "~&aldo: ~A has no subform ~A (poll-points 0..~A)~%"
                      (string-upcase name) index (1- count))
              (let ((bp (clautolisp.debug.ui:cmd-set-breakpoint
                         session
                         (clautolisp.debug:function-debug-metadata-function-id metadata)
                         index)))
                (format t "~&breakpoint pp~A on ~A~%" (%sa-bp-pp bp) (%sa-bp-where bp))))))))

(define-command (*sleeping-aldo* b break) (&whole argument)
    "Set a breakpoint: ,break FUNC (entry) or ,break FUNC.N (subform N)."
  (let ((session (%sleeping-aldo-require-session))
        (name (string-trim " " (or argument ""))))
    (when session
      (cond
        ((zerop (length name))
         (format t "~&usage: ,break FUNC          breakpoint on the function's entry~%~
                      ~&       ,break FUNC.N        breakpoint on subform N (0 = entry)~%"))
        ;; the file:line and bare-line forms are staged for a follow-up
        ((find #\: name)
         (format t "~&aldo: ,break FILE:LINE is coming in a follow-up; ~
use ,break FUNC or ,break FUNC.N for now.~%"))
        ((every #'digit-char-p name)
         (format t "~&aldo: ,break LINE is coming in a follow-up; ~
use ,break FUNC or ,break FUNC.N for now.~%"))
        (t
         (multiple-value-bind (fname index) (%sa-parse-func-dot name)
           (%sa-break-function session fname index)))))))

(define-command (*sleeping-aldo* lb list breakpoints) ()
    "List the breakpoints (by poll-point number ppN)."
  (let ((session (%sleeping-aldo-require-session)))
    (when session
      (let ((breakpoints (clautolisp.debug.ui:cmd-list-breakpoints session)))
        (if (null breakpoints)
            (format t "~&no breakpoints.~%")
            (dolist (bp (sort (copy-list breakpoints) #'< :key #'%sa-bp-pp))
              (format t "~&pp~A  ~A~@[  line ~A~]  ~A~:[~;  [cond]~]~%"
                      (%sa-bp-pp bp)
                      (%sa-bp-where bp)
                      (%sa-bp-line bp)
                      (if (clautolisp.debug:breakpoint-enabled-p bp) "enabled" "disabled")
                      (clautolisp.debug:breakpoint-condition bp))))))))

(defun %sa-set-enabled (token enabled)
  "Enable/disable the breakpoints selected by TOKEN (ppN or ALL)."
  (let ((session (%sleeping-aldo-require-session)))
    (when session
      (let ((bps (%sa-select-breakpoints session token)))
        (if (eq bps :none)
            (format t "~&aldo: no breakpoint ~A~%" (string-trim " " token))
            (progn
              (dolist (bp bps) (clautolisp.debug:set-breakpoint-enabled bp enabled))
              (format t "~&~A ~A breakpoint~:P~%"
                      (if enabled "enabled" "disabled") (length bps))))))))

(define-command (*sleeping-aldo* eb enable breakpoint) (&whole argument)
    "Enable a breakpoint: ,eb ppN | ,eb ALL."
  (%sa-set-enabled (or argument "") t))

(define-command (*sleeping-aldo* db disable breakpoint) (&whole argument)
    "Disable a breakpoint: ,db ppN | ,db ALL."
  (%sa-set-enabled (or argument "") nil))

(define-command (*sleeping-aldo* rb remove breakpoint) (&whole argument)
    "Remove a breakpoint: ,rb ppN | ,rb ALL."
  (let ((session (%sleeping-aldo-require-session)))
    (when session
      (let ((bps (%sa-select-breakpoints session (or argument ""))))
        (if (eq bps :none)
            (format t "~&aldo: no breakpoint ~A~%" (string-trim " " (or argument "")))
            (progn
              (dolist (bp bps) (clautolisp.debug.ui:cmd-remove-breakpoint session bp))
              (format t "~&removed ~A breakpoint~:P~%" (length bps))))))))

(define-command (*sleeping-aldo* cb condition breakpoint) (&whole argument)
    "Set or clear a breakpoint condition: ,cb ppN FORM  (,cb ppN alone clears)."
  (let ((session (%sleeping-aldo-require-session))
        (arg (string-trim " " (or argument ""))))
    (when session
      (let* ((space (position #\Space arg))
             (pp-token (if space (subseq arg 0 space) arg))
             (form-text (and space (string-trim " " (subseq arg (1+ space)))))
             (bps (%sa-select-breakpoints session pp-token)))
        (cond
          ((or (eq bps :none) (/= 1 (length bps)))
           (format t "~&aldo: ,cb needs one breakpoint (ppN)~%"))
          ((or (null form-text) (zerop (length form-text)))
           (setf (clautolisp.debug:breakpoint-condition (first bps)) nil)
           (format t "~&pp~A condition cleared~%" (%sa-bp-pp (first bps))))
          (t
           ;; Read the AutoLISP FORM in the session's context/dialect, then wrap
           ;; it with the debugger's own condition semantics (evaluate with
           ;; debugging off; stop iff non-nil; an error in the form also stops).
           (let ((rform (ignore-errors
                         (first (read-current-source
                                 form-text :source-name "<aldo>"
                                 :context (clautolisp.debug.ui:session-context session))))))
             (if (null rform)
                 (format t "~&aldo: cannot read condition form ~S~%" form-text)
                 (progn
                   (setf (clautolisp.debug:breakpoint-condition (first bps))
                         (clautolisp.ui.dumb:make-condition-predicate rform))
                   (format t "~&pp~A condition set~%" (%sa-bp-pp (first bps))))))))))))

(define-command (*sleeping-aldo* ib ignore breakpoint) (&whole argument)
    "Ignore the next COUNT hits of a breakpoint: ,ib ppN COUNT."
  (let ((session (%sleeping-aldo-require-session))
        (arg (string-trim " " (or argument ""))))
    (when session
      (let* ((space (position #\Space arg))
             (pp-token (if space (subseq arg 0 space) arg))
             (count-token (and space (string-trim " " (subseq arg (1+ space)))))
             (count (and count-token (plusp (length count-token))
                         (every #'digit-char-p count-token)
                         (parse-integer count-token))))
        (cond
          ((null count)
           (format t "~&usage: ,ib ppN COUNT   (ignore the next COUNT hits)~%"))
          (t
           (let ((bps (%sa-select-breakpoints session pp-token)))
             (if (or (eq bps :none) (/= 1 (length bps)))
                 (format t "~&aldo: ,ib needs one breakpoint (ppN), not ~A~%" pp-token)
                 (let ((bp (first bps)))
                   ;; ignore-count is not an engine field: a counting condition
                   ;; that suppresses the stop for the first COUNT hits (the same
                   ;; idiom the dumb UI uses).
                   (setf (clautolisp.debug:breakpoint-condition bp)
                         (let ((remaining count))
                           (lambda (hit)
                             (declare (ignore hit))
                             (if (plusp remaining) (progn (decf remaining) nil) t))))
                   (format t "~&pp~A will ignore its next ~A hit~:P~%"
                           (%sa-bp-pp bp) count))))))))))
