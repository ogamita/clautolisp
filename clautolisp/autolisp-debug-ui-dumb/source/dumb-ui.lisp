(in-package #:clautolisp.ui.dumb)

;;;; The dumb-terminal UI (spec §18). No layout: every notification is one
;;;; or more tagged lines on the output stream; at a stopping point a
;;;; sub-REPL reads single-letter commands (and bare forms) from the input
;;;; stream and returns a resume directive. Both streams are injectable so
;;;; the UI is fully testable over string streams.

(defclass dumb-ui ()
  ((input  :initarg :input  :initform *standard-input*  :accessor dumb-ui-input)
   (output :initarg :output :initform *standard-output* :accessor dumb-ui-output)
   (prompt :initarg :prompt :initform "DBG> " :accessor dumb-ui-prompt)
   (source-window :initarg :source-window :initform 2 :accessor dumb-ui-source-window)
   ;; `display' forms (strings), auto-printed after every stop (cmd-ref §4)
   (displays :initarg :displays :initform '() :accessor dumb-ui-displays)
   ;; source-browse stack (cmd-ref §3): a list of (NAME . source-position),
   ;; top = current browse position; pushed by goto/definition, popped by back.
   (browse-stack :initarg :browse-stack :initform '() :accessor dumb-ui-browse-stack)
   ;; cross-stop navigation history (cmd-ref §3): a list of saved browse-stack
   ;; snapshots, newest first, pushed on each debugger re-entry; `restore N'
   ;; returns to one. Bounded by the navigation-history-max setting.
   (navigation-history :initarg :navigation-history :initform '()
                       :accessor dumb-ui-navigation-history)))

(defun make-dumb-ui (&rest initargs)
  (apply #'make-instance 'dumb-ui initargs))

(register-ui :terminal (lambda (&rest initargs) (apply #'make-dumb-ui initargs)))
(register-ui :dumb     (lambda (&rest initargs) (apply #'make-dumb-ui initargs)))

(defun out (ui control &rest args)
  (apply #'format (dumb-ui-output ui) control args)
  (force-output (dumb-ui-output ui)))

(defun string-lines (text)
  "TEXT split into a list of lines (a single trailing newline is dropped)."
  (let ((lines (uiop:split-string text :separator '(#\Newline))))
    (if (and (cdr lines) (string= "" (car (last lines))))
        (butlast lines)
        lines)))

(defun paged-out (ui text)
  "Emit TEXT to the UI, a page at a time when the pager is on and TEXT is taller
than a page (command reference §8 *Paging long output*). The page prompt reads
one line of input (the modal pager sub-mode): SPACE / f / =>= / RET next page,
b / =<= back, d / u half-page down / up, j / k one line down / up, g / =<<=
first, G / =>>= last, =/pat= / =?pat= search forward / backward, n / N repeat
search, q quit. With the pager off, or on a non-interactive stream (EOF), TEXT
is written straight through (never blocks)."
  (let* ((pager-on (eq (get-aldo-setting :pager) :on))
         (page (max 1 (1- (or (get-aldo-setting :pager-height) 24))))
         (half (max 1 (floor page 2)))
         (lines (coerce (string-lines text) 'vector))
         (n (length lines))
         (top (max 0 (- n page))))                 ; furthest start keeping a full page
    (flet ((seek (pat start dir)
             "First line index from START stepping DIR (±1) whose text contains
PAT (case-insensitive), or NIL."
             (when (and pat (plusp (length pat)))
               (loop for k = start then (+ k dir)
                     while (and (<= 0 k) (< k n))
                     when (search pat (svref lines k) :test #'char-equal)
                       do (return k)))))
      (if (or (not pager-on) (<= n page))
          (write-string text (dumb-ui-output ui))
          (loop with s = 0 with last-pat = nil
                do (loop for k from s below (min n (+ s page))
                         do (out ui "~A~%" (svref lines k)))
                   (let ((end (min n (+ s page))))
                     (when (>= end n) (return))
                     (out ui "--More--(~D/~D) [SPACE/f/> b/< d/u j/k g G /pat ?pat n N q] " end n)
                     (let ((line (read-line (dumb-ui-input ui) nil :eof)))
                       (if (eq line :eof)
                           (progn (loop for k from end below n
                                        do (out ui "~A~%" (svref lines k)))
                                  (return))
                           (let* ((cmd (string-trim " " line))
                                  (c0 (and (plusp (length cmd)) (char cmd 0))))
                             (cond
                               ((string-equal cmd "q") (return))
                               ((member cmd '("b" "<") :test #'string-equal) (setf s (max 0 (- s page))))
                               ((member cmd '("g" "<<") :test #'string-equal) (setf s 0))
                               ((member cmd '("G" ">>") :test #'string-equal) (setf s top))
                               ((string-equal cmd "d") (setf s (min top (+ s half))))   ; half page down
                               ((string-equal cmd "u") (setf s (max 0 (- s half))))     ; half page up
                               ((string-equal cmd "j") (setf s (min top (1+ s))))       ; one line down
                               ((string-equal cmd "k") (setf s (max 0 (1- s))))         ; one line up
                               ((eql c0 #\/)                                            ; search forward
                                (let* ((p (subseq cmd 1)) (hit (seek p (1+ s) 1)))
                                  (setf last-pat p) (when hit (setf s hit))))
                               ((eql c0 #\?)                                            ; search backward
                                (let* ((p (subseq cmd 1)) (hit (seek p (1- s) -1)))
                                  (setf last-pat p) (when hit (setf s hit))))
                               ((string-equal cmd "n")                                  ; repeat forward
                                (let ((hit (seek last-pat (1+ s) 1))) (when hit (setf s hit))))
                               ((string-equal cmd "N")                                  ; repeat backward
                                (let ((hit (seek last-pat (1- s) -1))) (when hit (setf s hit))))
                               (t (setf s end))))))))))))   ; SPACE/f/>/RET/… → next

;;; --- notifications -------------------------------------------------

(defmethod ui-attached ((ui dumb-ui) session)
  (declare (ignore session))
  (out ui "~&DBG> clautolisp debugger attached (h for help)~%"))

(defmethod ui-detached ((ui dumb-ui))
  (out ui "~&DBG> detached~%"))

(defmethod ui-show-message ((ui dumb-ui) level control &rest args)
  (out ui "~&DBG> [~A] ~A~%" level (apply #'format nil control args)))

(defun describe-stop (ui session kind hit)
  (let ((snapshot (session-snapshot session)))
    (out ui "~&DBG> ~A at ~A~@[ — ~A~]~%"
         kind
         (location-string (hit-source-position hit)
                          (and snapshot (snapshot-function-name snapshot)))
         (and (eq kind "Error") (hit-error-message hit)))
    (when snapshot (print-bindings ui snapshot) (print-stack-line ui snapshot))
    (print-displays ui session)))

(defun print-displays (ui session)
  "Auto-print every `display' form in the current frame (command reference §4)."
  (loop for form in (dumb-ui-displays ui)
        for i from 1
        do (handler-case
               (out ui "DBG> display ~D: ~A = ~A~%" i form (preview (cmd-eval session form)))
             (error (e) (out ui "DBG> display ~D: ~A = <error: ~A>~%" i form e)))))

(defmethod ui-thread-hit ((ui dumb-ui) session hit)
  (let ((reason (hit-stop-reason hit)))
    (describe-stop ui session
                   (case reason (:step "Step") (:watch "Watchpoint")
                                (:break "Break") (t "Hit breakpoint"))
                   hit)
    (when (and (eq reason :break) (hit-error-message hit))
      (out ui "DBG>   ~A~%" (preview (hit-error-message hit))))
    (when (and (eq reason :watch) (hit-watch hit))
      (let ((w (hit-watch hit)))
        (out ui "DBG>   ~A changed: ~A → ~A~%"
             (watch-name w) (preview (watch-prev-value w)) (preview (watch-last-value w)))))))

(defmethod ui-thread-unhandled-error ((ui dumb-ui) session hit)
  (describe-stop ui session "Error" hit)
  (out ui "DBG>   (q abort, r <form> return a value, c continue/run *error*)~%"))

(defmethod ui-thread-caught-error ((ui dumb-ui) session hit)
  (describe-stop ui session "Caught error" hit))

(defun location-string (position function-name)
  (cond
    ((source-position-p position)
     (format nil "~@[~A ~]line ~D col ~D"
             function-name
             (source-position-start-line position)
             (source-position-start-column position)))
    (function-name (format nil "~A" function-name))
    (t "<unknown>")))

(defun print-bindings (ui snapshot)
  (loop for (symbol . value) in (snapshot-visible-names snapshot)
        do (out ui "DBG>   ~A = ~A~%"
                (autolisp-symbol-name symbol) (preview value))))

(defun print-stack-line (ui snapshot)
  (let ((names (mapcar #'stack-frame-function-name (snapshot-call-stack snapshot))))
    (when names
      (out ui "DBG>   <stack: ~{~A~^ ← ~} ← top>~%" names))))

(defun effective-value-line-width ()
  "The configured single-line value width (the `value-line-width' setting,
command reference §8), or 72 if unset/unavailable."
  (or (ignore-errors (get-aldo-setting :value-line-width)) 72))

(defun preview (value &optional limit)
  "A one-line printed preview of VALUE, truncated with an ellipsis at LIMIT
characters. LIMIT defaults to the `value-line-width' setting so the user can
configure how wide single-line value displays are (command reference §8)."
  (let ((limit (or limit (effective-value-line-width)))
        (string (handler-case (prin1-to-string value) (error () "#<?>"))))
    (if (> (length string) limit)
        (concatenate 'string (subseq string 0 limit) "…")
        string)))

;;; --- source listing (spec §18.1) -----------------------------------

(defmethod ui-show-stop-source-p ((ui dumb-ui))
  "With `set navigator sexp' (the default) each stop opens the sexp form
navigator, which renders the source itself with the selection marked — the flat
line window must not also print (it is the *line* navigator's presentation;
sedit-spec §7). With `set navigator line' the window is the stop display."
  (not (eq (ignore-errors (get-aldo-setting :navigator)) :sexp)))

(defmethod ui-show-source ((ui dumb-ui) position)
  (when (source-position-p position)
    (let* ((file (source-position-file position))
           (lines (and file (ignore-errors (lines-of file))))
           (target (source-position-start-line position))
           (window (dumb-ui-source-window ui)))
      (when (and lines (plusp (length lines)))
        (loop for n from (max 1 (- target window)) to (min (length lines) (+ target window))
              for text = (aref lines (1- n))
              do (out ui "~A~3D:   ~A~%" (if (= n target) ">> " "   ") n text))))))

;;; --- the command loop (spec §18.1) ---------------------------------

(defun record-navigation-state (ui)
  "On debugger re-entry, save the current browse stack to the navigation history
(newest first), de-duplicating the immediate previous and capping at the
navigation-history-max setting (command reference §3)."
  (let ((stack (dumb-ui-browse-stack ui)))
    (when (and stack
               (not (equal stack (first (dumb-ui-navigation-history ui)))))
      (let ((max (or (ignore-errors (get-aldo-setting :navigation-history-max)) 1000)))
        (setf (dumb-ui-navigation-history ui)
              (subseq (cons (copy-list stack) (dumb-ui-navigation-history ui))
                      0 (min (1+ (length (dumb-ui-navigation-history ui))) (max 1 max))))))))

(defmethod ui-run-command ((ui dumb-ui) session command)
  "Run one debugger command string outside a stop (spec §7): split it into
verb + argument and dispatch it. HIT is NIL (there is no current stop), so
meta commands like `help' / `settings' work; frame-relative commands degrade
gracefully. Returns the resume directive, or NIL."
  (let* ((line (string-trim " 	" (or command "")))
         (sp (position #\Space line))
         (cmd (if sp (subseq line 0 sp) line))
         (arg (and sp (string-trim " " (subseq line sp)))))
    (unless (zerop (length cmd))
      (run-command ui session nil cmd arg))))

(defmethod ui-open-navigation-request ((ui dumb-ui) session request)
  "Open the navigator on a queued CLAL-NAV-* REQUEST outside a stop — the
(clal-nav-function 'NAME) pre-debug entry (bug-aldo-nav-entry-and-breakpoint-
flow). There is no stop, so HIT is NIL and any resume directive is ignored."
  (let ((loc (nav-loc-for-request ui session request)))
    (when loc (navi-enter ui session nil loc)))
  nil)

(defun %directive-on-result (result)
  "The debugger interactor's ON-RESULT: a command's non-nil value is a resume
directive — carry it out of the running INTERACTOR-LOOP."
  (when result (interactor-return result)))

(defun %line-command-read (input-context)
  "The debugger/navigator reader: every line is a command, except a `(' line —
one Lisp form to evaluate in the current frame, returned as (:EVAL LINE)."
  (command-read input-context
                (lambda (ic)
                  (let ((line (read-line-from-input-context ic)))
                    (if (eq line :eof)
                        :eof
                        (list :eval (string-trim " 	" line)))))))


(defvar *aldo-commands*
  (clautolisp.interactor:make-command-dictionary "aldo")
  "The built-in command-reference §0 vocabulary, as a command dictionary
(interactors step 2): the system dictionary of the ALDO interactor. User /
mode dictionaries (the active stack, with ALDO's own user dictionary) layer
over it, so a user command may shadow a built-in — `command TOKEN' (or the
historical `debugger TOKEN') reaches the built-in meaning regardless. The
commands are registered in commands.lisp.")

(defvar *navi-commands* (clautolisp.interactor:make-command-dictionary "navi")
  "The form navigator's system dictionary: the motions (d u > < << >> skip),
bare `b', the editing words, help and quit — stacked over the debugger's
vocabulary while NAVI is entered. Registered in commands.lisp.")

(defvar *navi-user-commands* (clautolisp.interactor:make-command-dictionary "navi-user")
  "User commands of the form navigator, shadowing *NAVI-COMMANDS*.")

(defvar *lavi-commands* (clautolisp.interactor:make-command-dictionary "lavi")
  "The flat line navigator's system dictionary. Registered in commands.lisp.")

(defvar *lavi-user-commands* (clautolisp.interactor:make-command-dictionary "lavi-user")
  "User commands of the line navigator, shadowing *LAVI-COMMANDS*.")

(defvar *inspi-commands* (clautolisp.interactor:make-command-dictionary "inspect")
  "The inspector's system dictionary (spec §18.2): u/up, d/descend, e/eval,
b/bind (shadowing the global break — the command-reference §8 example),
p/path, q/quit. Registered in commands.lisp.")

(defvar *inspi-user-commands* (clautolisp.interactor:make-command-dictionary "inspect-user")
  "User commands of the inspector, shadowing *INSPI-COMMANDS*.")

;;; The interactors (interactor-design-revision.issue D1): SINGLETONS — pure
;;; program, never copied — declaring each mode's identity: name, alias,
;;; dictionaries, prompt/status/reader/evaluator functions, conventions.
;;; Entering a mode pushes an ACTIVATION pairing the interactor with this
;;; entry's state (the navigator's location, the stop's UI/session/hit), so
;;; recursive entries stack cleanly; the interactor functions reach that
;;; state as (ACTIVATION-STATE *COMMAND-ACTIVATION*). The vocabularies are
;;; registered on these interactors with DEFINE-*-COMMAND (commands.lisp),
;;; sugar over the framework's DEFINE-COMMAND.

(define-interactor *aldo*
  :name "ALDO" :alias "debug"
  :prompt '%aldo-prompt
  :reader '%line-command-read
  :evaluator '%aldo-evaluate
  :commands *aldo-commands*
  :on-result '%directive-on-result
  :documentation "The ALDO debugger (command reference §0/§8): every line is a
command — `(FORM)' evaluates in the current frame — and a command's non-nil
value is a resume directive, carried out of the loop.")

(define-interactor *navi*
  :name "NAVI"
  :status '%navi-status
  :prompt '%navi-prompt
  :reader '%navi-reader
  :evaluator '%navi-evaluate
  :commands *navi-commands*
  :user-commands *navi-user-commands*
  ;; a NAVI command's non-nil value is a resume directive too: the editing
  ;; words return the directive that unwound a stacked SEDIT (`aldo c'
  ;; issued inside the editor), which must cascade out of the stop's loop.
  :on-result '%directive-on-result
  :documentation "The structural form navigator (sedit spec §5): motions over
a :SEXP / :FILE / :DIR location, stacked over the debugger's vocabulary.")

(define-interactor *lavi*
  :name "LAVI"
  :status '%lavi-status
  :prompt "NAV> "
  :reader '%lavi-reader
  :evaluator '%lavi-evaluate
  :commands *lavi-commands*
  :user-commands *lavi-user-commands*
  :documentation "The flat line navigator (`set navigator line'): a cursor
over the current function's poll-point lines, stacked over the debugger.")

(define-interactor *inspi*
  :name "INSPECT"
  :status '%inspi-status
  :prompt "INSPECT> "
  :reader '%inspi-read
  :evaluator '%inspi-evaluate
  :commands *inspi-commands*
  :user-commands *inspi-user-commands*
  :documentation "The value inspector (spec §18.2): the §8 stacked-dispatch
example — its `b' is `bind', shadowing the global `break'; unshadowed
debugger verbs fall through.")

(defstruct aldo-state
  "The ALDO activation's per-stop state: the UI at the stop, the session, and
the HIT (NIL outside a stop)."
  ui session hit)

(defun %aldo-state () (activation-state *command-activation*))

(defun %aldo-prompt (stream)
  "The *ALDO* template's prompt: the stop UI's configured prompt string."
  (format stream "~&~A" (dumb-ui-prompt (aldo-state-ui (%aldo-state)))))

(defun %aldo-evaluate (input)
  "The *ALDO* template's evaluator: a `(FORM)' line evaluates in the current
frame and echoes with the DBG> prefix."
  (let ((state (%aldo-state)))
    (eval-and-print (aldo-state-ui state) (aldo-state-session state)
                    (second input))))

(defmethod ui-await-command ((ui dumb-ui) session hit)
  (record-navigation-state ui)
  ;; The stop's ALDO activation stacks OVER whatever was active — the REPL's
  ;; AUTOLISP bottom interactor, a suspended navigator of an outer stop — so
  ;; the whole stack stays reachable (stacked dispatch, and D6: a user
  ;; command on AUTOLISP is reachable everywhere). FLOOR is the depth WITH
  ;; this ALDO: an inner navigator can pop back to DBG> within the same
  ;; loop, but leaving ALDO itself is a resume directive, never a pop (T4).
  (let* ((*interactor-stack*
           (cons (make-activation *aldo* (make-aldo-state :ui ui :session session
                                                          :hit hit))
                 *interactor-stack*))
         (floor (length *interactor-stack*))
         (*debugger-ui* ui) (*debugger-session* session) (*debugger-hit* hit))
    ;; CLAL-NAV-* requested a stop to open a navigator (a function's source, a
    ;; file's forms, or a directory): open it on top of the stop's stack
    ;; (aldo-pre-debug.issue). A debugger command issued from NAV (e.g.
    ;; `continue') resumes: its directive cascades out through ON-RESULT
    ;; (bug-aldo-nav-command-dictionary).
    (when *pending-nav-request*
      (let ((request *pending-nav-request*))
        (setf *pending-nav-request* nil)
        (let ((loc (nav-loc-for-request ui session request)))
          (when loc
            (push-interactor *navi* (make-navi-state :ui ui :session session
                                                     :hit hit :loc loc))))))
    ;; `set navigator sexp' (the default): every stop enters the sexp form
    ;; navigator directly, anchored on the current poll-point (sedit-spec §7).
    ;; `q' pops the navigator and drops to the flat DBG> prompt — the FLOOR
    ;; (the stop's ALDO depth) keeps the same loop running on the debugger.
    (when (and hit
               (= (length *interactor-stack*) floor) ; no navigator opened above
               (eq (ignore-errors (get-aldo-setting :navigator)) :sexp))
      (let ((loc (nav-function-loc session hit)))
        (when loc
          (push-interactor *navi* (make-navi-state :ui ui :session session
                                                   :hit hit :loc loc)))))
    (or (interactor-loop :input (dumb-ui-input ui) :output (dumb-ui-output ui)
                         :error-output (dumb-ui-output ui) :floor floor)
        :continue)))                                 ; EOF ⇒ continue (CI/pipe)

(defun %command-tokens (arg)
  "ARG split into whitespace-separated tokens (empties dropped)."
  (and arg (remove "" (uiop:split-string (string-trim " " arg) :separator '(#\Space #\Tab))
                   :test #'string=)))

(defun %marshal-command-args (lambda-list tokens)
  "Map TOKENS (strings) onto LAMBDA-LIST for APPLY: each required / &optional
parameter takes the next token (or NIL when exhausted); &rest collects the
remainder as a list. So a command body receives its parsed positional args."
  (let ((args '()) (toks tokens) (rest-p nil))
    (dolist (item lambda-list)
      (cond
        ((eq item '&optional))
        ((eq item '&rest) (setf rest-p t) (return))
        (t (push (pop toks) args))))
    (nreverse-then-append (nreverse args) (when rest-p (list toks)))))

(defun nreverse-then-append (front rest)
  (if rest (append front rest) front))

(defun dispatch-in-dictionaries (ui session hit dictionaries cmd arg)
  "Look CMD up in DICTIONARIES (innermost-first) and dispatch it — binding the
debugger dynamic vars so the body can reach the session. A raw (&WHOLE)
command receives ARG untokenized; the others their parsed positional args
(command reference §8). Returns the resume directive, or NIL; unknown
commands report and keep the loop reading."
  (let ((command (and (plusp (length cmd)) (lookup-command cmd dictionaries))))
    (if command
        (let ((*debugger-ui* ui) (*debugger-session* session) (*debugger-hit* hit)
              (*command-line* (format nil "~A~@[ ~A~]" cmd arg))
              (*command-arguments-text* arg))
          ;; An error escaping a command body must not unwind the stop — a
          ;; debugging state may represent a lot of processing and is only
          ;; dropped on an explicit q/abort (error-while-debugging.issue).
          ;; An AutoLISP error signaled while the command evaluates user code
          ;; still re-enters the debugger first (the session's handler-bind
          ;; runs before this unwinds); whatever propagates lands here.
          (handler-case
              (if (command-raw-argument-p command)
                  (funcall (command-function command) arg)
                  (apply (command-function command)
                         (%marshal-command-args (command-lambda-list command)
                                                (%command-tokens arg))))
            (error (e)
              (out ui "DBG> error while executing ~A: ~A~%" cmd e)
              nil)))
        (progn (out ui "DBG> ? unknown command ~S (h for help)~%" cmd) nil))))

(defun run-command (ui session hit cmd arg)
  "Dispatch one command. The `command' system word (interactors design; like
bash's `command') forces the BUILT-IN meaning of the following token —
reaching a built-in that a user / mode command shadows; `debugger' is its
historical equivalent. Otherwise a command in the active dictionary stack
(§8 stacked dispatch — user-defined commands, mode dictionaries) is tried
first, then the built-in command-reference §0 vocabulary (*ALDO-COMMANDS*).
Returns a resume directive, or NIL."
  (if (or (string-equal cmd +system-command-word+)
          (string-equal cmd +debugger-escape-word+))
      (let* ((a (or arg "")) (sp (position #\Space a)))
        (dispatch-in-dictionaries ui session hit (list *aldo-commands*)
                                  (subseq a 0 (or sp (length a)))
                                  (and sp (string-trim " " (subseq a sp)))))
      (dispatch-in-dictionaries ui session hit
                                (list (interactor-user-commands *aldo*)
                                      *aldo-commands*)
                                cmd arg)))

;;; poll-point-number (PP) designation (command reference §2 / DN-11) ---------

(defun breakpoint-pp (bp)
  "The poll-point number a breakpoint sits on (its designator)."
  (poll-point-id (breakpoint-fid bp) (breakpoint-form-id bp)))

(defun find-bp-by-pp (session pp)
  "The breakpoint whose poll-point number is PP, or NIL."
  (and pp (find pp (cmd-list-breakpoints session) :key #'breakpoint-pp)))

(defun parse-pp-token (tok)
  "Parse a poll-point designator token — \"ppN\" or \"N\" — to the integer N,
or NIL."
  (when (and tok (plusp (length tok)))
    (let ((s (if (and (>= (length tok) 2) (string-equal "pp" (subseq tok 0 2)))
                 (subseq tok 2) tok)))
      (ignore-errors (parse-integer s :junk-allowed t)))))

(defun split-pp-and-rest (arg)
  "Split ARG into (values PP REST): the first token as a poll-point number, the
remaining text."
  (if (null arg)
      (values nil nil)
      (let* ((sp (position #\Space arg))
             (tok (subseq arg 0 (or sp (length arg))))
             (rest (and sp (string-trim " " (subseq arg sp)))))
        (values (parse-pp-token tok) (and rest (plusp (length rest)) rest)))))

(defun make-condition-predicate (rform)
  "A breakpoint condition: evaluate RFORM at the poll point with debugging off
and stop iff it is non-nil; an error in the form also stops (so a broken
condition is not silently lost)."
  (lambda (hit)
    (declare (ignore hit))
    (handler-case
        (let ((*debugging* nil))
          (not (null (autolisp-eval rform (current-evaluation-context)))))
      (error () t))))

(defun condition-cmd (ui session arg)
  "`condition ppN [FORM]' — fire breakpoint ppN only when FORM is non-nil; with
no FORM, clear the condition (command reference §2)."
  (multiple-value-bind (pp form) (split-pp-and-rest arg)
    (let ((bp (find-bp-by-pp session pp)))
      (cond
        ((null bp) (out ui "DBG> condition: no breakpoint pp~A~%" (or pp arg)))
        ((null form) (setf (breakpoint-condition bp) nil)
                     (out ui "DBG> breakpoint pp~D condition cleared~%" pp))
        (t (let ((rform (ignore-errors (first (read-current-source form :source-name "<debugger>"
                                                                  :context (session-context session))))))
             (if (null rform)
                 (out ui "DBG> condition: cannot read form ~S~%" form)
                 (progn (setf (breakpoint-condition bp) (make-condition-predicate rform))
                        (out ui "DBG> breakpoint pp~D condition set~%" pp)))))))))

(defun ignore-cmd (ui session arg)
  "`ignore ppN COUNT' — skip the next COUNT hits of breakpoint ppN (a counting
condition, command reference §2)."
  (multiple-value-bind (pp rest) (split-pp-and-rest arg)
    (let ((count (and rest (ignore-errors (parse-integer rest :junk-allowed t))))
          (bp (find-bp-by-pp session pp)))
      (cond
        ((null bp) (out ui "DBG> ignore: no breakpoint pp~A~%" (or pp arg)))
        ((null count) (out ui "DBG> ignore: usage: ignore ppN COUNT~%"))
        (t (setf (breakpoint-condition bp)
                 (let ((remaining count))
                   (lambda (hit) (declare (ignore hit))
                     (if (plusp remaining) (progn (decf remaining) nil) t))))
           (out ui "DBG> breakpoint pp~D will ignore the next ~D hit~:P~%" pp count))))))

(defun make-bp-action (ui rform label)
  "A breakpoint action (function of HIT): with RFORM, evaluate it at the poll
point (debugging off) and print LABEL plus the value; without RFORM just print
LABEL. Used by `bpcmd' (then stops) and `trace' (then continues)."
  (lambda (hit)
    (declare (ignore hit))
    (if rform
        (handler-case
            (let ((*debugging* nil))
              (out ui "~A ~A~%" label
                   (preview (autolisp-eval rform (current-evaluation-context)) 200)))
          (error (e) (out ui "~A <error: ~A>~%" label e)))
        (out ui "~A~%" label))))

(defun bpcmd-cmd (ui session arg)
  "`bpcmd ppN [FORM]' — attach FORM to breakpoint ppN: when the breakpoint hits,
FORM is evaluated and shown, then the debugger stops as usual (command reference
§2). With no FORM, clear the attached command."
  (multiple-value-bind (pp form) (split-pp-and-rest arg)
    (let ((bp (find-bp-by-pp session pp)))
      (cond
        ((null bp) (out ui "DBG> bpcmd: no breakpoint pp~A~%" (or pp arg)))
        ((null form) (set-breakpoint-action bp nil)
                     (out ui "DBG> breakpoint pp~D command cleared~%" pp))
        (t (let ((rform (ignore-errors (first (read-current-source form :source-name "<debugger>"
                                                                  :context (session-context session))))))
             (if (null rform)
                 (out ui "DBG> bpcmd: cannot read form ~S~%" form)
                 (progn
                   ;; TRACE NIL ⇒ run the action, then stop (bpcmd, not a tracepoint).
                   (set-breakpoint-action
                    bp (make-bp-action ui rform (format nil "DBG> pp~D:" pp)) :trace nil)
                   (out ui "DBG> breakpoint pp~D command set~%" pp)))))))))

(defun find-trace-breakpoint (session fid)
  "The entry tracepoint (form-id 0, with an action, trace-p) on function FID, or
NIL."
  (find-if (lambda (b)
             (and (= (breakpoint-fid b) fid) (= (breakpoint-form-id b) 0)
                  (breakpoint-action b) (breakpoint-trace-p b)))
           (cmd-list-breakpoints session)))

(defun trace-cmd (ui session arg)
  "`trace FN [FORM]' — trace function FN: each time it is entered, print a trace
line (and FORM's value, if given), then continue transparently (command
reference §6.4). Implemented as an auto-continuing breakpoint (a tracepoint) on
FN's entry poll point."
  (multiple-value-bind (sp) (and arg (position #\Space arg))
    (let* ((name (and arg (string-trim " " (subseq arg 0 (or sp (length arg))))))
           (rest (and sp (string-trim " " (subseq arg sp))))
           (form (and rest (plusp (length rest)) rest)))
      (cond
        ((or (null name) (zerop (length name))) (out ui "DBG> trace: usage: trace FN [FORM]~%"))
        (t (let ((metadata (metadata-for-name name)))
             (cond
               ((null metadata)
                (out ui "DBG> trace: ~A is not instrumented~%" name))
               (t (let* ((fid (function-debug-metadata-function-id metadata))
                         (rform (and form (ignore-errors (first (read-current-source form :source-name "<debugger>"
                                                                  :context (session-context session)))))))
                    (when (and form (null rform))
                      (out ui "DBG> trace: cannot read form ~S (tracing entry only)~%" form))
                    (when (find-trace-breakpoint session fid)
                      (out ui "DBG> trace: ~A already traced (replacing)~%" name)
                      (cmd-remove-breakpoint session (find-trace-breakpoint session fid)))
                    (cmd-set-breakpoint
                     session fid 0 :when :before :steady t :trace t
                     :action (make-bp-action ui rform (format nil "TRACE> ~A" name)))
                    (out ui "DBG> tracing ~A~%" name))))))))))

(defun untrace-cmd (ui session arg)
  "`untrace [FN]' — stop tracing FN (or every traced function when no name is
given); removes the entry tracepoint(s) (command reference §6.4)."
  (let ((name (and arg (plusp (length (string-trim " " arg))) (string-trim " " arg))))
    (cond
      ((null name)
       (let ((traced (remove-if-not (lambda (b)
                                      (and (= (breakpoint-form-id b) 0)
                                           (breakpoint-action b) (breakpoint-trace-p b)))
                                    (cmd-list-breakpoints session))))
         (if (null traced)
             (out ui "DBG>   nothing traced~%")
             (progn (dolist (b traced) (cmd-remove-breakpoint session b))
                    (out ui "DBG> untraced ~D function~:P~%" (length traced))))))
      (t (let ((metadata (metadata-for-name name)))
           (if (null metadata)
               (out ui "DBG> untrace: ~A is not instrumented~%" name)
               (let ((bp (find-trace-breakpoint
                          session (function-debug-metadata-function-id metadata))))
                 (if bp
                     (progn (cmd-remove-breakpoint session bp)
                            (out ui "DBG> untraced ~A~%" name))
                     (out ui "DBG> ~A is not traced~%" name)))))))))

(defun rbreak-cmd (ui session arg)
  "`rbreak PATTERN' — set an entry breakpoint on every instrumented function
whose name matches the wcmatch wildcard PATTERN (=*= any run, =?= one char),
skipping functions that already carry an entry breakpoint (command reference
§2)."
  (let ((pattern (and arg (string-trim " " arg))))
    (cond
      ((or (null pattern) (zerop (length pattern)))
       (out ui "DBG> rbreak: usage: rbreak PATTERN~%"))
      (t (let ((matches (functions-matching pattern))
               (set '()))
           (cond
             ((null matches)
              (out ui "DBG> rbreak: no instrumented function matches ~A~%" pattern))
             (t (dolist (md matches)
                  (let ((fid (function-debug-metadata-function-id md)))
                    (unless (find-if (lambda (b)
                                       (and (= (breakpoint-fid b) fid)
                                            (= (breakpoint-form-id b) 0)
                                            (not (breakpoint-action b))))
                                     (cmd-list-breakpoints session))
                      (cmd-set-breakpoint session fid 0 :when :before)
                      (push (function-debug-metadata-name md) set))))
                (if set
                    (out ui "DBG> rbreak: ~D breakpoint~:P set: ~{~A~^ ~}~%"
                         (length set) (nreverse set))
                    (out ui "DBG> rbreak: all ~D match~:P already have entry breakpoints~%"
                         (length matches))))))))))

(defun catch-cmd (ui arg)
  "`catch error on|off' / `catch caught on|off' — choose what stops execution:
breaking on an unhandled AutoLISP error (`error', default on) and/or on one
caught by vl-catch-all (`caught', default off) (command reference §2). With no
argument, report the current policy."
  (let* ((toks (and arg (remove "" (uiop:split-string (string-trim " " arg) :separator '(#\Space))
                                :test #'string=)))
         (which (and toks (string-downcase (first toks))))
         (state (and (cdr toks) (string-downcase (second toks)))))
    (flet ((report ()
             (out ui "DBG> catch: error ~:[off~;on~]   caught ~:[off~;on~]~%"
                  *break-on-error* *break-on-caught-error*)))
      (cond
        ((null which) (report))
        ((not (member which '("error" "caught") :test #'string=))
         (out ui "DBG> catch: usage: catch error|caught on|off~%"))
        ((not (member state '("on" "off") :test #'string=))
         (out ui "DBG> catch: usage: catch ~A on|off~%" which))
        (t (let ((on (string= state "on")))
             (if (string= which "error")
                 (setf *break-on-error* on)
                 (setf *break-on-caught-error* on))
             (report)))))))

(defun watch-cmd (ui session arg)
  "`watch VAR [FORM]' — set a software watchpoint: stop when VAR's value changes,
or — with FORM — when FORM first becomes true (an edge), e.g.
`watch n (= n 17)' (command reference §2). FORM is evaluated at each poll point
with debugging off."
  (multiple-value-bind (sp) (and arg (position #\Space arg))
    (let* ((name (and arg (string-trim " " (subseq arg 0 (or sp (length arg))))))
           (rest (and sp (string-trim " " (subseq arg sp))))
           (form (and rest (plusp (length rest)) rest)))
      (cond
        ((or (null name) (zerop (length name)))
         (out ui "DBG> watch: usage: watch VAR [FORM]~%"))
        (t (let* ((symbol (intern-autolisp-symbol (string-upcase name)))
                  (rform (and form (ignore-errors (first (read-current-source form :source-name "<debugger>"
                                                                  :context (session-context session))))))
                  (predicate (and rform
                                  (lambda ()
                                    (let ((*debugging* nil))
                                      (autolisp-eval rform (current-evaluation-context)))))))
             (when (and form (null rform))
               (out ui "DBG> watch: cannot read form ~S (watching value change instead)~%" form))
             (cmd-watch session symbol name :predicate predicate)
             (if predicate
                 (out ui "DBG> watching ~A when ~A~%" name form)
                 (out ui "DBG> watching ~A~%" name))))))))

(defun unwatch-cmd (ui session arg)
  "`unwatch [VAR]' — remove the watch on VAR, or every watch when no name is
given (command reference §2)."
  (let ((name (and arg (plusp (length (string-trim " " arg))) (string-trim " " arg))))
    (cond
      ((null name)
       (let ((n (length (cmd-list-watches session))))
         (cmd-clear-watches session)
         (out ui "DBG> cleared ~D watch~:P~%" n)))
      (t (if (cmd-unwatch session name)
             (out ui "DBG> unwatched ~A~%" name)
             (out ui "DBG> no watch on ~A~%" name))))))

(defun list-watches-cmd (ui session)
  "`lw' / `list watches' — the active software watchpoints (command reference §2)."
  (let ((ws (cmd-list-watches session)))
    (if (null ws)
        (out ui "DBG>   no watches~%")
        (dolist (w ws)
          (out ui "DBG>   ~A~:[~; (predicated)~] = ~A~%"
               (watch-name w) (watch-predicate w) (preview (watch-last-value w)))))))

(defun enable-cmd (ui session arg enabled)
  "`enable [N]' / `disable [N]' — (de)activate breakpoint N (the number shown by
`lb'), or all when no number is given (command reference §2). A disabled
breakpoint stays in the list but does not fire."
  (let ((bps (cmd-list-breakpoints session))
        (verb (if enabled "enabled" "disabled")))
    (cond
      ((null bps) (out ui "DBG>   no breakpoints~%"))
      ((null arg)
       (dolist (bp bps) (set-breakpoint-enabled bp enabled))
       (out ui "DBG> ~A all breakpoints~%" verb))
      (t (let* ((pp (parse-pp-token arg))
                (bp (find-bp-by-pp session pp)))
           (if bp
               (progn (set-breakpoint-enabled bp enabled)
                      (out ui "DBG> ~A breakpoint pp~D~%" verb pp))
               (out ui "DBG> no breakpoint pp~A~%" arg)))))))

(defun delete-cmd (ui session arg)
  "`delete [N]' / `clear' — remove breakpoint N (the number shown by `lb'), or
all breakpoints when no number is given (command reference §2). (The designator
is the breakpoint id `lb' displays; it aligns to the poll-point number once
that numbering is settled — design-notes register.)"
  (let ((bps (cmd-list-breakpoints session)))
    (cond
      ((null bps) (out ui "DBG>   no breakpoints~%"))
      ((null arg)
       (dolist (bp bps) (cmd-remove-breakpoint session bp))
       (out ui "DBG> deleted all breakpoints~%"))
      (t (let* ((pp (parse-pp-token arg))
                (bp (find-bp-by-pp session pp)))
           (if bp
               (progn (cmd-remove-breakpoint session bp)
                      (out ui "DBG> deleted breakpoint pp~D~%" pp))
               (out ui "DBG> no breakpoint pp~A~%" arg)))))))

(defun source-form-of-metadata (metadata)
  "Reconstruct =(defun NAME LAMBDA-LIST BODY…)= from METADATA's usubr, or NIL."
  (when metadata
    (let ((usubr (function-debug-metadata-usubr metadata)))
      (when usubr
        (list* (intern-autolisp-symbol "DEFUN")
               (intern-autolisp-symbol (autolisp-usubr-name usubr))
               (autolisp-usubr-lambda-list usubr)
               (autolisp-usubr-body usubr))))))

(defun current-source-form (session)
  "The source form =(defun NAME LAMBDA-LIST BODY…)= the navigator should show:
the function `g NAME' / CLAL-NAV-FUNCTION retargeted to (SESSION-NAV-TARGET) if
any, else the stopped frame's function (aldo-pre-debug.issue). NIL if neither."
  (source-form-of-metadata (or (session-nav-target session)
                               (current-metadata session))))

(defun nav-loop (ui session hit)
  "`nav' — enter the navigation interactor over the current function (command
reference §3). The `navigator' setting (§8) chooses the granularity: =sexp=
(default) opens the source/structure browser (NAVI) — from which =u= ascends
to the file's directory (aldo-pre-debug.issue) — while =line= walks the
function's poll-point lines flatly (LAVI). Returns a resume directive when a
debugger command issued from the navigator resumes execution, else NIL."
  (if (eq (ignore-errors (get-aldo-setting :navigator)) :line)
      (lavi-enter ui session hit)
      (let ((loc (nav-function-loc session hit)))
        (if loc
            (navi-enter ui session hit loc)
            (progn (out ui "DBG> nav: no current function~%") nil)))))

;;; --- LAVI: the flat line navigator as an interactor ------------------------

(defstruct lavi-state ui session pps lines (index 0))

(defun %lavi-state () (activation-state *command-activation*))

(defun lavi-skip (state n)
  (setf (lavi-state-index state)
        (max 0 (min (1- (length (lavi-state-lines state)))
                    (+ (lavi-state-index state) n)))))

(defun lavi-show (state)
  "The LAVI status line: the selected poll-point line, flagged when any of its
poll points carries a breakpoint."
  (let* ((i (lavi-state-index state))
         (lines (lavi-state-lines state))
         (line (nth i lines))
         (bp (some (lambda (pp) (and (= (second pp) line) (third pp)))
                   (lavi-state-pps state))))
    (out (lavi-state-ui state) "~&NAV(line ~D/~D)> line ~D~:[~; *breakpoint~]~%"
         (1+ i) (length lines) line bp)))

(defun %lavi-status (stream)
  "The *LAVI* singleton's status: the selected poll-point line."
  (declare (ignore stream))
  (lavi-show (%lavi-state)))

(defun %lavi-reader (input-context)
  "The *LAVI* singleton's reader: like NAVI's, but the status always reprints
so a blank line needs no redraw state."
  (%navi-read nil input-context))

(defun %lavi-evaluate (input)
  "The *LAVI* singleton's evaluator: a `(FORM)' line evaluates in the current
frame, echoed with the NAV> prefix."
  (let ((state (%lavi-state)))
    (eval-and-print (lavi-state-ui state) (lavi-state-session state)
                    (second input) "NAV> ")))

(defun lavi-enter (ui session hit)
  "`nav' in LINE mode (the `navigator line' setting): a flat cursor over the
current function's distinct source lines (those carrying a poll point). Keys:
=d=/=>= next, =u=/=<= prev, =<<= first, =>>= last, =±N= skip, =q= leave; every
debugger command is also reachable directly (stacked dictionaries)."
  (let* ((pps (current-poll-points session))
         ;; one entry per distinct source line (a line may hold several poll
         ;; points); flag the line if any of its poll points is breakpointed.
         (lines (sort (remove-duplicates (mapcar #'second pps)) #'<)))
    (if (null lines)
        (progn (out ui "DBG> nav: no poll points in the current function~%") nil)
        (%interactor-mode-loop ui session hit *lavi*
                               (make-lavi-state :ui ui :session session
                                                :pps pps :lines lines)))))

;;; ===== unified navigation: function/file source + directory browsing =====
;;;
;;; (aldo-pre-debug.issue) One modal loop over a "location" that is either a
;;; :SEXP navigator (a function's form, or a file's top-level forms) or a :DIR
;;; directory listing. `u' ascends the hierarchy — sub-form -> form -> file ->
;;; directory -> parent directory; `d' descends (into a sub-form, a subdirectory,
;;; or a file's forms); `>'/`<'/`<<'/`>>'/±N move among siblings; `q' leaves.

(defstruct nav-loc
  kind                    ; :sexp | :file | :dir
  ;; :sexp — a navigator over ONE form (a function, or one of a file's top forms)
  navigator
  file                    ; source file namestring the form belongs to, or NIL
  metadata                ; function-debug-metadata when navigating a function (for `b')
  parent-loc              ; :file loc to return to on `u' at the root; NIL -> directory
  ;; :file — a file's top-level forms, one shown at a time
  file-forms              ; simple-vector of top-level forms (may be empty)
  (file-index 0)
  ;; :dir — a directory listing
  dir
  entries                 ; simple-vector of entry plists (:name :path :dir-p :lsp-p)
  (index 0))

;;; Modal motion keys (sedit spec §5): d u > < << >> ±N. These are collision-free
;;; against the global debugger dictionary, so in NAV every non-motion token
;;; falls through to the debugger command dispatch (bug-aldo-nav-command-
;;; dictionary). The earlier i/k/jj/j/l/ll letter aliases are retired: they
;;; shadowed debugger verbs (i into, j jump, ll list-locals), which the stacked
;;; dictionary must reach directly.

(defstruct navi-state
  "The form navigator's per-entry state: the current location (mutated /
replaced by the motions) and the redraw policy — the view re-renders only
when it changed; a bare RET forces a redisplay (sedit-spec; the duplicate
display fix)."
  ui session hit loc (redraw t))

(defun %navi-state () (activation-state *command-activation*))

(defun %navi-set-file-index (state j)
  (let* ((loc (navi-state-loc state))
         (n (length (nav-loc-file-forms loc))))
    (setf (nav-loc-file-index loc) (max 0 (min (max 0 (1- n)) j)))))

(defun %navi-set-dir-index (state j)
  (let* ((loc (navi-state-loc state))
         (n (length (nav-loc-entries loc))))
    (setf (nav-loc-index loc) (max 0 (min (max 0 (1- n)) j)))))

(defun navi-move (state key &optional (count 1))
  "Apply motion KEY (:down :up :next :prev :first :last :skip) to STATE's
location — the :SEXP navigator, a :FILE's top-level forms, or a :DIR listing.
Code motions skip non-poll-point positions; a motion crossing a level
(sub-form -> form -> file -> directory, or descending) REPLACES the location
(aldo-pre-debug.issue)."
  (let* ((loc (navi-state-loc state))
         (ui (navi-state-ui state)))
    (ecase (nav-loc-kind loc)
      (:sexp
       (let ((nav (nav-loc-navigator loc)))
         (ecase key
           (:down  (nav-code-down nav))
           (:up    (if (navigator-path nav)
                       (nav-up nav)
                       ;; at the root: back to the file (if descended from
                       ;; one), else the file's directory
                       (let ((next (or (nav-loc-parent-loc loc)
                                       (nav-ascend-to-dir ui loc))))
                         (when next (setf (navi-state-loc state) next)))))
           (:next  (nav-code-forward nav))
           (:prev  (nav-code-backward nav))
           (:first (nav-code-first nav))
           (:last  (nav-code-last nav))
           (:skip  (nav-code-skip nav count)))))
      (:file
       (if (eq key :up)
           (setf (navi-state-loc state) (nav-file-ascend loc))
           (let* ((forms (nav-loc-file-forms loc))
                  (n (length forms))
                  (i (nav-loc-file-index loc)))
             (if (zerop n)
                 (out ui "NAV[file]> (no top-level forms) — u up, q leave~%")
                 (ecase key
                   (:down  (setf (navi-state-loc state)
                                 (make-nav-loc :kind :sexp
                                               :navigator (make-navigator (aref forms i))
                                               :file (nav-loc-file loc)
                                               :parent-loc loc)))
                   (:next  (%navi-set-file-index state (1+ i)))
                   (:prev  (%navi-set-file-index state (1- i)))
                   (:first (%navi-set-file-index state 0))
                   (:last  (%navi-set-file-index state (1- n)))
                   (:skip  (%navi-set-file-index state (+ i count))))))))
      (:dir
       (let* ((entries (nav-loc-entries loc))
              (n (length entries))
              (i (nav-loc-index loc)))
         (ecase key
           (:up    (setf (navi-state-loc state)
                         (nav-make-dir-loc
                          (namestring (uiop:pathname-parent-directory-pathname
                                       (uiop:ensure-directory-pathname (nav-loc-dir loc)))))))
           (:down  (when (plusp n)
                     (let ((next (nav-enter-dir-entry ui (aref entries i))))
                       (when next (setf (navi-state-loc state) next)))))
           (:next  (%navi-set-dir-index state (1+ i)))
           (:prev  (%navi-set-dir-index state (1- i)))
           (:first (%navi-set-dir-index state 0))
           (:last  (%navi-set-dir-index state (1- n)))
           (:skip  (%navi-set-dir-index state (+ i count)))))))))

(defun nav-function-loc (session &optional hit)
  "A :SEXP location over the current function — the `g'/nav target or the stopped
frame — or NIL when there is none. `u' at its root ascends to the file's directory.

The initial selection re-anchors to the *current* poll-point when HIT stopped
inside this function — the form the debugger stopped on (sedit spec §7 re-entry).
Failing that (no HIT, or its position is not found — e.g. `g NAME' with no
break), it is the function's *first poll-point* (nav-down of the whole form,
skipping the non-evaluable `defun' head), not the whole toplevel form, per sedit
spec §4 (bug-aldo-nav-entry-and-breakpoint-flow)."
  (let* ((metadata (or (session-nav-target session) (current-metadata session)))
         (form (and metadata (source-form-of-metadata metadata)))
         (file (and metadata
                    (let ((p (function-debug-metadata-source-position metadata)))
                      (and p (source-position-file p)))))
         (stop (and hit (hit-source-position hit))))
    (when form
      (let ((nav (make-navigator form)))
        (unless (and stop
                     (nav-select-source-position
                      nav (source-position-start-line stop)
                      (source-position-start-column stop)))
          (nav-code-down nav))          ; first poll-point when the stop form isn't located
        (make-nav-loc :kind :sexp :navigator nav
                      :file file :metadata metadata)))))

;;; --- reading a file's top-level forms (with source positions) -------------

(defun nav-read-file-forms (file)
  "Read FILE's top-level forms with source positions recorded (so the navigator
can show verbatim source). Returns the (possibly empty) list of forms, or :ERROR
on a read/IO/parse failure — distinct from an empty file, which yields NIL."
  (handler-case
      (with-source-tracking ()
        (read-runtime-from-string (uiop:read-file-string file) :source-name file))
    (error () :error)))

(defun nav-form-index-for-line (forms line)
  "Index of the top-level form on or containing LINE (or the first at/after it,
else the last), or 0 when LINE is NIL (aldo-pre-debug.issue)."
  (if (null line)
      0
      (let ((after nil))
        (loop for f in forms for i from 0
              for p = (position-of f)
              when p do
                (when (<= (source-position-start-line p) line (source-position-end-line p))
                  (return-from nav-form-index-for-line i))
                (when (and (null after) (>= (source-position-start-line p) line))
                  (setf after i)))
        (or after (max 0 (1- (length forms)))))))

(defun nav-make-file-loc (path &optional line)
  "A :FILE location over PATH's top-level forms — shown one at a time — selecting
the form on/containing LINE (the first when LINE is NIL; a file with no forms
selects NIL). NIL only when PATH cannot be read (aldo-pre-debug.issue)."
  (let* ((file (ignore-errors (namestring (truename path))))
         (forms (and file (nav-read-file-forms file))))
    (cond
      ((null file) nil)
      ((eq forms :error) nil)
      (t (let ((vec (coerce forms 'simple-vector)))
           (make-nav-loc :kind :file :file file :file-forms vec
                         :file-index (if (plusp (length vec))
                                         (nav-form-index-for-line forms line)
                                         0)))))))

;;; --- directory listing ----------------------------------------------------

(defun nav-dir-name (subdir)
  "The last directory component of the directory pathname SUBDIR."
  (car (last (pathname-directory subdir))))

(defun nav-lsp-file-p (pathname)
  (let ((type (pathname-type pathname)))
    (and (stringp type) (string-equal type "lsp"))))

(defun nav-read-dir-entries (dir)
  "A simple-vector of DIR's entries as plists (:name :path :dir-p :lsp-p): `..'
first, then subdirectories (sorted), then files (sorted)."
  (let* ((dirpath (uiop:ensure-directory-pathname dir))
         (parent (uiop:pathname-parent-directory-pathname dirpath))
         (subdirs (ignore-errors (uiop:subdirectories dirpath)))
         (files (ignore-errors (uiop:directory-files dirpath)))
         (entries '()))
    (dolist (f (sort (copy-list files) #'string< :key #'file-namestring))
      (push (list :name (file-namestring f) :path (namestring f)
                  :dir-p nil :lsp-p (nav-lsp-file-p f))
            entries))
    (dolist (d (sort (copy-list subdirs) #'string< :key #'nav-dir-name))
      (push (list :name (concatenate 'string (nav-dir-name d) "/")
                  :path (namestring d) :dir-p t :lsp-p nil)
            entries))
    (setf entries (nreverse entries))
    (push (list :name "../" :path (namestring parent) :dir-p t :lsp-p nil) entries)
    (coerce entries 'simple-vector)))

(defun nav-initial-dir-index (entries select-name)
  "The initial selection: the SELECT-NAME entry if present, else the first .lsp
file, else the first subdirectory, else `..' (index 0)."
  (or (and select-name
           (position select-name entries
                     :key (lambda (e) (getf e :name)) :test #'string-equal))
      (position-if (lambda (e) (getf e :lsp-p)) entries)
      (position-if (lambda (e) (and (getf e :dir-p)
                                    (not (string= (getf e :name) "../"))))
                   entries)
      0))

(defun nav-make-dir-loc (dir &optional select-name)
  (let* ((canon (namestring (uiop:ensure-directory-pathname dir)))
         (entries (nav-read-dir-entries canon)))
    (make-nav-loc :kind :dir :dir canon :entries entries
                  :index (nav-initial-dir-index entries select-name))))

(defun nav-format-date (universal)
  (if universal
      (multiple-value-bind (s mi h d mo y) (decode-universal-time universal)
        (declare (ignore s))
        (format nil "~4,'0D-~2,'0D-~2,'0D ~2,'0D:~2,'0D" y mo d h mi))
      (make-string 16 :initial-element #\Space)))

(defun nav-entry-label (entry mode)
  "The display text for a directory ENTRY under the DIRECTORY-LISTING MODE
(:long adds size + mtime; :short / :column show the name only)."
  (let ((name (getf entry :name)))
    (if (eq mode :long)
        (let* ((path (getf entry :path))
               (size (and (not (getf entry :dir-p))
                          (ignore-errors
                           (with-open-file (s path :element-type '(unsigned-byte 8))
                             (file-length s)))))
               (date (ignore-errors (file-write-date path))))
          (format nil "~10@A  ~A  ~A" (or size "") (nav-format-date date) name))
        name)))

(defun nav-window-bounds (index n window)
  "Half-open [lo, hi) of entries to show: the whole range when WINDOW <= 0, else
WINDOW context entries on each side of INDEX (aldo-pre-debug.issue note 2)."
  (if (and (integerp window) (plusp window))
      (values (max 0 (- index window)) (min n (+ index window 1)))
      (values 0 n)))

(defun nav-render-dir (ui loc)
  (let* ((entries (nav-loc-entries loc))
         (n (length entries))
         (index (nav-loc-index loc))
         (mode (or (ignore-errors (get-aldo-setting :directory-listing)) :short))
         (window (or (ignore-errors (get-aldo-setting :directory-window)) 0)))
    (out ui "~&NAV: directory ~A~%" (nav-loc-dir loc))
    (multiple-value-bind (lo hi) (nav-window-bounds index n window)
      (when (> lo 0) (out ui "   ...~%"))
      (loop for i from lo below hi
            for e = (aref entries i)
            do (out ui "~A~A~%" (if (= i index) " > " "   ") (nav-entry-label e mode)))
      (when (< hi n) (out ui "   ...~%")))))

;;; --- the modal loop -------------------------------------------------------

(defun nav-render-file (ui loc)
  "Show the file one top-level form at a time: only the selected form is
pretty-printed (verbatim source), with `...' above/below when other forms are
omitted — never above the first form or below the last. An empty file shows NIL
(aldo-pre-debug.issue)."
  (let* ((forms (nav-loc-file-forms loc))
         (n (length forms))
         (i (nav-loc-file-index loc)))
    (out ui "~&NAV: file ~A~%" (nav-loc-file loc))
    (if (zerop n)
        (out ui "   NIL   (no top-level forms)~%")
        (progn
          (when (> i 0) (out ui "   ...~%"))
          (let* ((nav (make-navigator (aref forms i)))
                 (listing (nav-source-listing nav)))
            (if listing (out ui "~A" listing) (out ui "   ~A~%" (nav-render nav))))
          (when (< i (1- n)) (out ui "   ...~%"))))))

;;; --- decorations woven into the verbatim source (TUI spec) ----------------
;;;
;;; The debugger navigator prints the function's source ONCE — the file's own
;;; lines — and weaves the decoration glyphs INTO those lines: the selected
;;; sub-form in the selection brackets 【…】, each poll point carrying its status
;;; (⏸ enabled / ⏯ disabled breakpoint, ⏵ current poll point) as a prefix on its
;;; opening paren. The glyphs come from the aldo :decorations config
;;; (theme-aware; set / ,settings can change them). They are placed by consuming
;;; the leading indentation so the code stays aligned (aldo-pre-debug.issue; TUI
;;; spec §Debugger Specific Decorations).

(defun nav-defun-name (form)
  "The function name string of a (DEFUN NAME …) / (DEFUN-Q NAME …) FORM, or NIL."
  (when (and (consp form) (consp (cdr form))
             (typep (first form) 'clautolisp.autolisp-runtime:autolisp-symbol)
             (member (string-upcase (autolisp-symbol-name (first form)))
                     '("DEFUN" "DEFUN-Q") :test #'string=)
             (typep (second form) 'clautolisp.autolisp-runtime:autolisp-symbol))
    (autolisp-symbol-name (second form))))

(defun nav-ensure-loc-metadata (loc)
  "The function-debug-metadata for a :SEXP LOC: the one it carries (function
nav), or — for a browsed file's (defun NAME …) form — the loaded function's
metadata (resolved / instrumented on demand, cached on the loc), or NIL when no
such function is loaded (aldo-pre-debug.issue)."
  (or (nav-loc-metadata loc)
      (let ((name (nav-defun-name (navigator-root (nav-loc-navigator loc)))))
        (when name
          (setf (nav-loc-metadata loc) (ensure-metadata-for-name name))))))

(defun nav-decoration-points (session md file)
  "A list of (LINE COL . GLYPH) poll-point decorations for MD's function that lie
in FILE: enabled / disabled breakpoints and the current poll point (TUI spec
decoration table)."
  (when (and session md)
    (let ((fid (function-debug-metadata-function-id md))
          (points '()))
      (flet ((add (pos glyph)
               (when (and (source-position-p pos) glyph (plusp (length glyph))
                          (equal (source-position-file pos) file))
                 (push (list* (source-position-start-line pos)
                              (source-position-start-column pos) glyph)
                       points))))
        (dolist (bp (list-breakpoints (session-thread-info session)))
          (when (eql (breakpoint-fid bp) fid)
            (add (form-id-position md (breakpoint-form-id bp))
                 (aldo-decoration-glyph (if (breakpoint-enabled-p bp)
                                            :enabled-bp :disabled-bp)))))
        (let* ((snap (session-snapshot session))
               (pos (and snap (snapshot-source-position snap))))
          (add pos (aldo-decoration-glyph :current-pp))))
      points)))

(defun %nav-first-nonspace-col (text)
  (1+ (or (position #\Space text :test-not #'char=) 0)))

(defun %nav-last-nonspace-col (text)
  (let ((p (position #\Space text :test-not #'char= :from-end t)))
    (if p (1+ p) (max 1 (length text)))))

(defun %nav-weave-line (text sep before after)
  "Weave decorations into one source line: TEXT prefixed by a SEP-space
separator. BEFORE is an alist (COL . STRING) inserted immediately before source
COL, consuming up to (length STRING) leading spaces so the code stays put; AFTER
is an alist (COL . STRING) inserted just BEFORE source COL (COL = one past the
form's last character, so the string lands right after it)."
  (let ((s (concatenate 'string (make-string sep :initial-element #\Space) text)))
    (dolist (a (sort (copy-list after) #'> :key #'car))
      (let ((p (min (length s) (+ sep (1- (car a))))))
        (setf s (concatenate 'string (subseq s 0 p) (cdr a) (subseq s p)))))
    (dolist (b (sort (copy-list before) #'> :key #'car))
      (let* ((p (min (length s) (+ sep (1- (car b)))))
             (left (subseq s 0 p)) (right (subseq s p))
             (avail (- (length left) (length (string-right-trim " " left))))
             (k (min (length (cdr b)) avail)))
        (setf s (concatenate 'string (subseq left 0 (- (length left) k)) (cdr b) right))))
    s))

(defun %nav-form-end (lines start-line start-col)
  "Scan LINES (a vector of strings) from the sexp beginning at (START-LINE,
START-COL) to its end, returning (values END-LINE END-COL) — END-COL the 1-based
column of the form's last character. Balances ( ), skips \"strings\" (with
backslash escapes) and ; comments. Used to place the selection's closing bracket
independently of the reader's end-column convention (aldo-pre-debug.issue)."
  (let ((line start-line) (col start-col) (depth 0) (seen-open nil) (in-string nil))
    (loop
      (when (> line (length lines)) (return (values start-line start-col)))
      (let* ((text (aref lines (1- line))) (len (length text)))
        (loop while (<= col len) do
          (let ((ch (char text (1- col))))
            (cond
              (in-string (cond ((char= ch #\\) (incf col))
                               ((char= ch #\") (setf in-string nil))))
              ((char= ch #\") (setf in-string t seen-open t))
              ((char= ch #\;) (return))                          ; comment: skip rest of line
              ((char= ch #\() (incf depth) (setf seen-open t))
              ((char= ch #\))
               (decf depth)
               (when (<= depth 0) (return-from %nav-form-end (values line col))))
              ((and (not seen-open) (not (member ch '(#\Space #\Tab))))
               (let ((e col))                                    ; a bare atom: its token
                 (loop while (and (<= e len)
                                  (not (find (char text (1- e)) " 	()\";")))
                       do (incf e))
                 (return-from %nav-form-end (values line (1- e)))))))
          (incf col))
        (incf line) (setf col 1)))))

(defun nav-render-sexp-source (ui session loc)
  "Print LOC's function source ONCE with the decorations woven in — selection
brackets 【…】 and poll-point status glyphs. Returns T, or NIL when no source
text is available (so the caller can fall back)."
  (let ((nav (nav-loc-navigator loc)))
    (multiple-value-bind (file f-start f-end) (nav-form-span nav)
      (let ((lines (and file (ignore-errors (lines-of file)))))
        (when (and file lines (plusp (length lines)))
          (let ((decos (nav-decoration-points session (nav-ensure-loc-metadata loc) file))
                (open  (or (aldo-decoration-glyph :selection :open) "【"))
                (close (or (aldo-decoration-glyph :selection :close) "】"))
                (so-line nil) (so-col nil) (sc-line nil) (sc-col nil))
            ;; selection bounds: start from the reader position, end by scanning
            (multiple-value-bind (sf s-line s-col) (nav-selected-bounds nav)
              (declare (ignore sf))
              (when (and s-line (<= 1 s-line (length lines)))
                (let ((scol (or s-col (%nav-first-nonspace-col (aref lines (1- s-line))))))
                  (multiple-value-bind (e-line e-col) (%nav-form-end lines s-line scol)
                    (setf so-line s-line so-col scol
                          sc-line e-line sc-col (1+ e-col))))))  ; close after the last char
            (loop for n from (max 1 f-start) to (min (length lines) f-end)
                  for text = (aref lines (1- n))
                  for before = '() for after = '()
                  do
                     (dolist (d decos)
                       (when (eql (first d) n)
                         (push (cons (second d) (cddr d)) before)))
                     (when (eql n so-line)
                       (let ((cell (assoc so-col before)))
                         (if cell
                             (setf (cdr cell) (concatenate 'string open (cdr cell)))
                             (push (cons so-col open) before))))
                     (when (eql n sc-line)
                       (push (cons sc-col close) after))
                     (out ui "~A~3D:~A~%"
                          (if (eql n so-line) " >>" "   ")
                          n (%nav-weave-line text 3 before after)))
            t))))))

(defun nav-render-pretty (ui nav)
  "Render a navigated form that has *no* source text (e.g. a clal-compile'd
function) laid out from the AutoLISP indentation rules — sedit spec §5.2, the
same layout sedit gives it — with the selection marked, instead of one flat
line. Falls back to the flat render when the printed form cannot be re-parsed."
  (let* ((text (let ((*print-pretty* nil))
                 (prin1-to-string (navigator-root nav))))
         (node (ignore-errors (clautolisp.sedit:parse-form text)))
         (open  (or (aldo-decoration-glyph :selection :open) "【"))
         (close (or (aldo-decoration-glyph :selection :close) "】")))
    (if node
        (out ui "~&~A~%" (clautolisp.sedit:format-marked
                          (clautolisp.sedit:reflow node)
                          (navigator-path nav) :open open :close close))
        (out ui "~&NAV> ~A~%" (nav-render nav)))))

(defun nav-render-display (ui session loc)
  "The navigator's view of LOC — the marked source (or the reflowed form when it
has none), the selected top-level form of a file, or the directory listing."
  (ecase (nav-loc-kind loc)
    (:sexp
     (let ((nav (nav-loc-navigator loc)))
       (unless (nav-render-sexp-source ui session loc)
         (nav-render-pretty ui nav))))
    (:file (nav-render-file ui loc))
    (:dir  (nav-render-dir ui loc))))

(defun nav-prompt (ui loc)
  "The navigator prompt. One prompt per mode (sedit-spec §6): the sexp form
navigator is NAV>, never NAV[code]>/NAV[non-code]> — whether the selection is
evaluable code is shown by the poll-point decoration, not the prompt."
  (out ui "~&~A" (ecase (nav-loc-kind loc)
                   (:sexp "NAV> ")
                   (:file "NAV[file]> ")
                   (:dir  "NAV[dir]> ")))
  (finish-output (dumb-ui-output ui)))

(defun nav-ascend-to-dir (ui loc)
  "Ascend from a :SEXP location to its file's directory, the file selected; or a
message and NIL when there is no source file."
  (let ((file (nav-loc-file loc)))
    (if file
        (nav-make-dir-loc (namestring (uiop:pathname-directory-pathname file))
                          (file-namestring file))
        (progn (out ui "NAV> (no source file to ascend to)~%") nil))))

(defun nav-file-ascend (loc)
  "Ascend from a :FILE location to its directory, the file selected."
  (nav-make-dir-loc (namestring (uiop:pathname-directory-pathname (nav-loc-file loc)))
                    (file-namestring (nav-loc-file loc))))

(defun nav-set-breakpoint (ui session loc)
  "`b' in nav — set a breakpoint on the selected form. Needs a loaded/
instrumented function (a function navigation); breakpoints on a merely-browsed
file need the function loaded (aldo-pre-debug.issue)."
  (let ((md (nav-ensure-loc-metadata loc))
        (nav (nav-loc-navigator loc)))
    (cond
      ((not (and session md))
       (out ui "NAV> breakpoints need a loaded function — nav one with `g NAME' or (clal-nav-function …)~%"))
      (t (let* ((pos (position-of (nav-selected nav)))
                (form-id (and (source-position-p pos)
                              (form-id-at-line-col
                               md (source-position-start-line pos)
                               (source-position-start-column pos)))))
           (if form-id
               (multiple-value-bind (bp new-p)
                   (cmd-set-breakpoint
                    session (function-debug-metadata-function-id md) form-id)
                 (out ui "NAV> breakpoint pp~D ~:[already set~;set~] on the selected form~%"
                      (breakpoint-pp bp) new-p))
               (out ui "NAV> the selected form has no poll point (pick an evaluated sub-form)~%")))))))

;;; --- NAV -> EDIT: bridge into the sedit structural editor (spec §7) --------

(defparameter +nav-editing-words+
  '("edit" "insert" "add" "replace" "wrap" "slurp" "barf" "splice" "split" "join"
    "cut" "copy" "paste" "undo")
  "Editing commands recognised in NAV by their WORD (§1.3): typing one enters the
sedit structural editor. Single-letter editing keys would collide with debugger
keys, so only the words switch modes. Registered in *NAVI-COMMANDS*
(commands.lisp).")

(defun nav-form-source-text (nav)
  "The verbatim source text of the whole navigated form, or NIL when its source
file / line span is unavailable (a reconstructed form with no file). The
span's END-LINE is computed from POSITIONED sub-nodes, which misses a
bare-atom tail (interned symbols carry no per-occurrence position): a
function ending in a bare `z' spanned short and `edit' fed sedit an
unterminated list (nav-edit-span-atom-tail.issue). Re-derive the real end
by balancing parens from the form's start with %NAV-FORM-END."
  (multiple-value-bind (file start end) (nav-form-span nav)
    (when (and file start end)
      (let ((lines (ignore-errors (lines-of file))))
        (when (and lines (<= 1 start) (<= start (length lines)))
          (let ((balanced-end
                  (nth-value 0 (%nav-form-end
                                lines start
                                (%nav-first-nonspace-col (aref lines (1- start)))))))
            (setf end (min (length lines) (max end balanced-end))))
          (with-output-to-string (s)
            (loop for n from (max 1 start) to (min (length lines) end)
                  for first = t then nil
                  do (unless first (terpri s))
                     (write-string (aref lines (1- n)) s))))))))

(defun nav-edit-session (ui session hit loc cmd arg)
  "NAV -> SEDIT (spec §7): open the current form's source in the SEDIT
interactor, stacked over the navigator and the debugger (design-revision T2
Option A — one SEDIT> prompt, no internal NAV/EDIT modes), and install the
edited definition (evaluate it in the running system) when it quits,
dropping the cached metadata so the navigator re-instruments. SEDIT's keys
shadow the debugger's; `aldo CMD' reaches them; a resume directive issued
inside (`aldo c', the confirmed quit) is returned to be propagated."
  (let* ((nav (nav-loc-navigator loc))
         (text (nav-form-source-text nav)))
    (if (not text)
        (progn (out ui "NAV> can't edit here: no source text for this form~%") nil)
        (let ((sedit (clautolisp.sedit:sedit-open (clautolisp.sedit:parse-form text))))
          ;; perform the triggering editing command (unless it was bare `edit')
          (unless (string= cmd "edit")
            (clautolisp.sedit:sedit-command
             sedit (if arg (format nil "~A ~A" cmd arg) cmd)))
          (multiple-value-bind (result directive)
              (clautolisp.sedit:sedit-enter
               sedit :input (dumb-ui-input ui) :output (dumb-ui-output ui)
                     :debug-hook (lambda (line) (nav-run-debug-line ui session hit line))
                     :eval-print-hook (lambda (node) (nav-eval-node-string session node))
                     ;; the sedit-on-quit guard (design-revision point-6
                     ;; answer): saving here means installing the edited
                     ;; definition in the running system; the policy comes
                     ;; from the aldo configuration (a lisp-interactor
                     ;; configuration stacks under it —
                     ;; issues/open/lisp-configuration.issue).
                     :save-hook (lambda (sedit-session)
                                  (nav-install-edited-form
                                   ui session
                                   (clautolisp.sedit:session-result sedit-session)
                                   loc))
                     :on-quit (lambda ()
                                (or (ignore-errors (get-aldo-setting :sedit-on-quit))
                                    :ask)))
            (cond
              (directive directive)
              (t (nav-install-edited-form ui session result loc) nil)))))))

(defun nav-eval-node-string (session node)
  "Evaluate a sedit NODE's form in the stopped context and return a printable
result string (spec §7: a Lisp form at the editor prompt evaluates like the REPL)."
  (handler-case
      (format nil "= ~A" (preview (cmd-eval session (clautolisp.sedit:unparse node))))
    (error (e) (format nil "eval error: ~A" e))))

(defun nav-run-debug-line (ui session hit line)
  "Run a debugger command LINE reached from EDIT via the `debug'/`aldo' prefix."
  (let ((sp (position #\Space line)))
    (run-command ui session hit
                 (if sp (subseq line 0 sp) line)
                 (and sp (string-trim " " (subseq line sp))))))

(defun nav-install-edited-form (ui session result loc)
  "Install the edited form RESULT by evaluating it in the stopped context (spec
§7), then drop the cached metadata so `b' / the display re-instrument."
  (if (and result session)
      (handler-case
          (progn (cmd-eval session (clautolisp.sedit:unparse result))
                 (setf (nav-loc-metadata loc) nil)
                 (out ui "NAV> installed the edited definition~%"))
        (error (e) (out ui "NAV> could not install the edit: ~A~%" e)))
      (out ui "NAV> left the editor (nothing installed)~%")))

(defun nav-help (ui)
  "`?'/`h' in NAV: the navigator motion keys plus the stacked debugger dictionary
(bug-aldo-nav-command-dictionary — help is the union of the active dictionaries)."
  (out ui "NAV> motion: d down  u up  > < siblings  << >> ends  ±N skip  b break (selection)  q leave~%")
  (out ui "NAV> edit (or insert/add/replace/wrap/…): open the sedit structural editor~%")
  (out ui "NAV> all debugger commands are also available directly (aldo/debug CMD forces the debugger's):~%")
  (print-help ui))

(defun nav-enter-dir-entry (ui entry)
  "Descend into a directory ENTRY: a subdirectory/`..' -> its listing, a .lsp file
-> its top-level forms, otherwise a message. Returns the new location or NIL."
  (cond
    ((getf entry :dir-p) (nav-make-dir-loc (getf entry :path)))
    ((getf entry :lsp-p)
     (or (nav-make-file-loc (getf entry :path))
         (progn (out ui "NAV[dir]> cannot read ~A~%" (getf entry :name)) nil)))
    (t (out ui "NAV[dir]> ~A is not a .lsp file~%" (getf entry :name)) nil)))

;;; --- NAVI: the form navigator as an interactor -----------------------------
;;;
;;; The modal navigation loop is the single INTERACTOR-LOOP driving a NAVI
;;; instance stacked over the debugger interactor (interactor-unification):
;;; the motions live in *NAVI-COMMANDS* (commands.lisp), everything else falls
;;; through to the debugger vocabulary (bug-aldo-nav-command-dictionary),
;;; `aldo CMD' / `command CMD' route explicitly, and a resume directive
;;; cascades out through the debugger's ON-RESULT. The view re-renders only
;;; when it changed; a bare RET redisplays (the duplicate-display fix).

(defun %signed-skip-p (input)
  "An INPUT-COMMAND whose whole line is ±N — the navigators' skip motion."
  (and (input-command-p input)
       (let ((tokens (input-command-tokens input)))
         (and (= 1 (length tokens))
              (eq (car (first tokens)) 'integer)
              (member (char (cdr (first tokens)) 0) '(#\+ #\-))))))

(defun %navi-read (state input-context)
  "The navigator reader: a blank line redisplays (bare RET — STATE may be NIL
for LAVI, whose status always reprints); a ±N line reads as the skip motion;
otherwise a command, or a `(' form to evaluate in the current frame."
  (let ((input (%line-command-read input-context)))
    (cond
      ((eq input :blank)
       (when state (setf (navi-state-redraw state) t))
       :blank)
      ((%signed-skip-p input)
       (let ((count (cdr (first (input-command-tokens input)))))
         (make-input-command
          :raw (concatenate 'string "skip " count)
          :tokens (list (cons 'ident "skip") (cons 'integer count)))))
      (t input))))

(defun %navi-prompt (stream)
  "The *NAVI* singleton's prompt: the kind-specific NAV> prompt over this
activation's location (sedit-spec §6)."
  (declare (ignore stream))
  (let ((state (%navi-state)))
    (nav-prompt (navi-state-ui state) (navi-state-loc state))))

(defun %navi-status (stream)
  "The *NAVI* singleton's status: re-render the view when it changed — a bare
RET forces a redisplay (the duplicate-display fix)."
  (declare (ignore stream))
  (let ((state (%navi-state)))
    (when (navi-state-redraw state)
      (setf (navi-state-redraw state) nil)
      (nav-render-display (navi-state-ui state) (navi-state-session state)
                          (navi-state-loc state)))))

(defun %navi-reader (input-context)
  "The *NAVI* singleton's reader over this activation's state."
  (%navi-read (%navi-state) input-context))

(defun %navi-evaluate (input)
  "The *NAVI* singleton's evaluator: a `(FORM)' line evaluates in the current
frame, echoed with the NAV> prefix (sedit-spec §6)."
  (let ((state (%navi-state)))
    (eval-and-print (navi-state-ui state) (navi-state-session state)
                    (second input) "NAV> ")))

(defun %interactor-mode-loop (ui session hit interactor state)
  "Drive INTERACTOR — activated with this entry's STATE — pushed over the
current stack in a nested INTERACTOR-LOOP, adding a base debugger activation
when no ALDO is active (ui-run-command, the sedit debug hook, a mode entered
straight from the REPL), so the debugger vocabulary and `aldo …' routing
reach down. Returns when the mode pops (q) or at EOF (NIL), or with a
resume directive a debugger command issued inside carried out."
  (let ((*interactor-stack*
          (cons (make-activation interactor state)
                (if (find-activation "ALDO")
                    *interactor-stack*
                    (cons (make-activation
                           *aldo*
                           (make-aldo-state :ui ui :session session :hit hit))
                          *interactor-stack*)))))
    (interactor-loop :input (dumb-ui-input ui) :output (dumb-ui-output ui)
                     :error-output (dumb-ui-output ui)
                     :floor (length *interactor-stack*))))

(defun navi-enter (ui session hit loc)
  "Enter the form navigator over LOC; see %INTERACTOR-MODE-LOOP."
  (%interactor-mode-loop ui session hit *navi*
                         (make-navi-state :ui ui :session session
                                          :hit hit :loc loc)))

(defun nav-loc-for-request (ui session request)
  "Build the initial navigation location for a CLAL-NAV-* REQUEST — (:function
NAME) / (:file PATH LINE) / (:directory PATH) — or NIL (aldo-pre-debug.issue)."
  (ecase (first request)
    (:function
     (and (browse-to-name ui session (second request))
          (nav-function-loc session)))
    (:file
     (destructuring-bind (path &optional line) (rest request)
       (or (nav-make-file-loc path line)
           (progn (out ui "DBG> nav: cannot read file ~A~%" path) nil))))
    (:directory
     (nav-make-dir-loc (or (second request) (namestring (uiop:getcwd)))))))

;;; --- source-browse stack (command reference §3 Navigation) ----------------

(defun browse-push-and-show (ui name position)
  "Push (NAME . POSITION) on the browse stack and display the source there. The
browse stack changes only what is displayed — never execution or bindings."
  (push (cons name position) (dumb-ui-browse-stack ui))
  (out ui "DBG> ~A:~%" name)
  (if (source-position-p position)
      (ui-show-source ui position)
      (out ui "DBG>   (no source position recorded)~%")))

(defun browse-to-name (ui session name)
  "Resolve NAME to a function and browse to it, retargeting the navigator to it
(SESSION-NAV-TARGET) so a following `nav' walks NAME's source. The function is
instrumented ON DEMAND when it was defined/loaded but never called
(aldo-pre-debug.issue). T on success. Frame and bindings are untouched."
  (let ((md (ensure-metadata-for-name name)))
    (cond
      ((null md) (out ui "DBG> no function named ~A (define or load it first)~%" name) nil)
      (t (when session (setf (session-nav-target session) md))
         (browse-push-and-show ui (function-debug-metadata-name md)
                               (function-debug-metadata-source-position md))
         t))))

(defun goto-cmd (ui session arg)
  "`goto NAME' (=g=) — browse to the definition of the global function NAME and
retarget the navigator to it, so `g NAME' then `nav' walks NAME's source
(command reference §3; aldo-pre-debug.issue). NAME need not have been called —
it is instrumented on demand. v1: a global function name; qualified local paths,
FILE:LINE, and the object idiom (DN-12) are not yet implemented."
  (let ((name (and arg (string-trim " " arg))))
    (cond
      ((or (null name) (zerop (length name)))
       (out ui "DBG> goto: usage: goto NAME~%"))
      ((find #\: name)
       (out ui "DBG> goto: FILE:LINE not yet supported (v1: goto NAME)~%"))
      ((find #\Space name)
       (out ui "DBG> goto: qualified local paths not yet supported (v1: goto NAME)~%"))
      (t (browse-to-name ui session name)))))

(defun definition-cmd (ui session arg)
  "`definition NAME' (=.=) — follow the call graph by name to NAME's definition
and browse it, crossing files if need be (command reference §3). The cursor form
(=.= on the selected call) belongs to the keystroke UIs; the dumb terminal takes
the name explicitly. Does not move the current frame."
  (let ((name (and arg (string-trim " " arg))))
    (if (or (null name) (zerop (length name)))
        (out ui "DBG> definition: usage: definition NAME~%")
        (browse-to-name ui session name))))

(defun back-cmd (ui session)
  "`back' — pop the source-browse stack to the previous position and redisplay
it (command reference §3)."
  (declare (ignore session))
  (let ((stack (dumb-ui-browse-stack ui)))
    (cond
      ((null stack) (out ui "DBG>   browse stack empty~%"))
      ((null (rest stack))
       (setf (dumb-ui-browse-stack ui) '())
       (out ui "DBG>   browse stack empty (back to the current poll point)~%"))
      (t (pop (dumb-ui-browse-stack ui))
         (destructuring-bind (name . position) (first (dumb-ui-browse-stack ui))
           (out ui "DBG> back to ~A:~%" name)
           (when (source-position-p position) (ui-show-source ui position)))))))

(defun history-cmd (ui session)
  "`history' — list the source-browse stack (innermost/current first) and the
saved cross-stop navigation states; `restore N' returns to state N (command
reference §3)."
  (declare (ignore session))
  (let ((stack (dumb-ui-browse-stack ui))
        (saved (dumb-ui-navigation-history ui)))
    (if (null stack)
        (out ui "DBG>   browse stack empty~%")
        (loop for (name . position) in stack
              for i from 0
              do (out ui "DBG>   ~D: ~A  ~A~%" i name
                      (location-string position name))))
    (when saved
      (out ui "DBG>   --- saved navigation states (restore N) ---~%")
      (loop for state in saved
            for n from 0
            do (out ui "DBG>   [~D] ~{~A~^ < ~}~%" n (mapcar #'car state))))))

(defun restore-cmd (ui arg)
  "`restore N' — make saved navigation state N (as listed by `history') the
current source-browse stack and redisplay its top (command reference §3)."
  (let* ((n (and arg (ignore-errors (parse-integer (string-trim " " arg) :junk-allowed t))))
         (saved (dumb-ui-navigation-history ui)))
    (cond
      ((null n) (out ui "DBG> restore: usage: restore N~%"))
      ((not (< -1 n (length saved))) (out ui "DBG> restore: no navigation state ~A~%" n))
      (t (setf (dumb-ui-browse-stack ui) (copy-list (nth n saved)))
         (destructuring-bind (name . position) (first (dumb-ui-browse-stack ui))
           (out ui "DBG> restored to ~A:~%" name)
           (when (source-position-p position) (ui-show-source ui position)))))))

(defun search-cmd (ui session arg)
  "`search PATTERN' — list instrumented functions whose name matches the wcmatch
wildcard PATTERN, with their locations; `goto NAME' jumps to one (command
reference §3). v1: a name search over the source map (full-text search deferred)."
  (declare (ignore session))
  (let ((pattern (and arg (string-trim " " arg))))
    (cond
      ((or (null pattern) (zerop (length pattern)))
       (out ui "DBG> search: usage: search PATTERN~%"))
      (t (let ((matches (sort (functions-matching pattern) #'string-lessp
                              :key #'function-debug-metadata-name)))
           (if (null matches)
               (out ui "DBG>   no function name matches ~A~%" pattern)
               (dolist (md matches)
                 (out ui "DBG>   ~A  ~A~%"
                      (function-debug-metadata-name md)
                      (location-string (function-debug-metadata-source-position md)
                                       (function-debug-metadata-name md))))))))))

(defun advance-cmd (ui session arg)
  "`advance LINE' (=a=) — run to the poll point on LINE (§1). Returns the resume
directive, or NIL (with a message) when LINE has none."
  (let ((line (and arg (ignore-errors (parse-integer arg :junk-allowed t)))))
    (cond
      ((null line) (out ui "DBG> advance needs a line number~%") nil)
      (t (or (cmd-advance-at-line session line)
             (progn (out ui "DBG> no poll point at line ~D~%" line) nil))))))

(defun jump-target-location (metadata arg)
  "Resolve a jump destination ARG to (values FID FORM-ID): =ppN= names a poll
point by number; otherwise a within-function location =LINE= / =LINE.K= /
=LINE:COL= (command reference §2). Returns (values NIL NIL) if unresolved."
  (let ((tok (and arg (string-trim " " arg))))
    (cond
      ((or (null tok) (zerop (length tok))) (values nil nil))
      ;; ppN — a poll-point number (explicit `pp' prefix)
      ((and (>= (length tok) 2) (string-equal "pp" (subseq tok 0 2)))
       (let ((pp (ignore-errors (parse-integer (subseq tok 2) :junk-allowed t))))
         (if pp (poll-point-location pp) (values nil nil))))
      ;; otherwise a LINE / LINE.K / LINE:COL location in the current function
      (t (let ((form-id (resolve-line-spec metadata tok)))
           (if form-id
               (values (function-debug-metadata-function-id metadata) form-id)
               (values nil nil)))))))

(defun jump-cmd (ui session hit arg)
  "`jump LINE' / `jump ppN' (=j=) — resume execution at the target poll point,
skipping the forms in between WITHOUT evaluating them (command reference §1).
v1: forward jumps within the current function; backward and cross-function
jumps (the jump-back.lsp re-drive) are not yet supported. Returns the resume
directive, or NIL (with a message) when the target is rejected."
  (let ((metadata (current-metadata session))
        (cur-fid (and hit (hit-fid hit)))
        (cur-form (and hit (hit-form-id hit))))
    (cond
      ((null metadata) (out ui "DBG> jump: no current function~%") nil)
      ((or (null arg) (zerop (length (string-trim " " arg))))
       (out ui "DBG> jump: usage: jump LINE | jump ppN~%") nil)
      (t (multiple-value-bind (fid form-id) (jump-target-location metadata arg)
           (cond
             ((null fid) (out ui "DBG> jump: no poll point for ~A~%" arg) nil)
             ((not (eql fid cur-fid))
              (out ui "DBG> jump: cross-function jump not supported (v1: within the current function)~%")
              nil)
             ((and cur-form (<= form-id cur-form))
              (out ui "DBG> jump: backward jump not supported (v1: forward only)~%")
              nil)
             (t (out ui "DBG> jumping to pp~D~%" (poll-point-id fid form-id))
                (cmd-jump session fid form-id))))))))

(defun frame-cmd (ui session arg)
  "`frame N' / `frame inner|outer|top|bottom' — select a call frame (§3).
top = innermost = frame 0; inner heads toward top, outer toward the toplevel."
  (let* ((snapshot (session-snapshot session))
         (frames (and snapshot (snapshot-call-stack snapshot)))
         (n (length frames))
         (cur (or (session-selected-frame session) 0)))
    (if (zerop n)
        (out ui "DBG> no frames~%")
        (let ((target (cond
                        ((null arg) cur)
                        ((string-equal arg "inner") (1- cur))
                        ((string-equal arg "outer") (1+ cur))
                        ((string-equal arg "top") 0)
                        ((string-equal arg "bottom") (1- n))
                        (t (or (ignore-errors (parse-integer arg :junk-allowed t)) cur)))))
          (setf target (max 0 (min (1- n) target)))
          (cmd-select-frame session target)
          (out ui "DBG> frame ~D: ~A~%" target
               (stack-frame-function-name (nth target frames)))))))

(defun list-vars-cmd (ui session what)
  "`list locals|parameters|variables' (=ll=/=lp=/=lv=) — show the visible
bindings at the stop (§3). The locals/parameters/variables distinction is a
refinement; all three currently show the visible bindings."
  (let ((snapshot (session-snapshot session)))
    (out ui "DBG> ~A:~%" what)
    (if snapshot (print-bindings ui snapshot) (out ui "DBG>   (no snapshot)~%"))))

(defun list-sub-cmd (ui session arg)
  "Dispatch the spelled `list X' form to the matching =l*= command."
  (cond
    ((null arg) (out ui "DBG> list what? (breakpoints|watches|frames|source|locals|parameters|variables|polls)~%"))
    ((string-equal arg "breakpoints") (list-breakpoints-cmd ui session))
    ((string-equal arg "watches") (list-watches-cmd ui session))
    ((string-equal arg "frames") (print-stack ui session))
    ((string-equal arg "source") (relist-source ui session))
    ((string-equal arg "locals") (list-vars-cmd ui session "locals"))
    ((string-equal arg "parameters") (list-vars-cmd ui session "parameters"))
    ((string-equal arg "variables") (list-vars-cmd ui session "variables"))
    ((member arg '("polls" "poll-points") :test #'string-equal) (list-poll-points-cmd ui session))
    (t (out ui "DBG> list ~A? (breakpoints|watches|frames|source|locals|parameters|variables|polls)~%" arg))))

(defun type-cmd (ui session arg)
  "`type EXPR' — show the AutoLISP type of EXPR's value (command reference §4)."
  (if (null arg)
      (out ui "DBG> type: usage: type EXPR~%")
      (handler-case
          (let* ((value (cmd-eval session arg))
                 (ty (clautolisp.autolisp-runtime:autolisp-type value)))
            (out ui "DBG> ~A : ~A~%" (preview value 60) (preview ty 40)))
        (error (e) (out ui "DBG> type error: ~A~%" e)))))

(defun display-cmd (ui arg)
  "`display FORM' — auto-print FORM after every stop (command reference §4)."
  (if (null arg)
      (out ui "DBG> display: usage: display FORM~%")
      (progn
        (setf (dumb-ui-displays ui) (append (dumb-ui-displays ui) (list arg)))
        (out ui "DBG> display ~D: ~A~%" (length (dumb-ui-displays ui)) arg))))

(defun undisplay-cmd (ui arg)
  "`undisplay [N]' — remove auto-display N, or all of them (command reference §4)."
  (let ((n (and arg (ignore-errors (parse-integer arg :junk-allowed t)))))
    (cond
      ((and n (<= 1 n (length (dumb-ui-displays ui))))
       (setf (dumb-ui-displays ui)
             (append (subseq (dumb-ui-displays ui) 0 (1- n))
                     (subseq (dumb-ui-displays ui) n)))
       (out ui "DBG> undisplay ~D~%" n))
      ((null arg)
       (setf (dumb-ui-displays ui) '())
       (out ui "DBG> undisplay (all)~%"))
      (t (out ui "DBG> undisplay: no display ~A~%" arg)))))

(defun set-setting-cmd (ui arg)
  "`set NAME VALUE' — update one aldo setting (command reference §8)."
  (if (null arg)
      (out ui "DBG> set: usage: set NAME VALUE~%")
      (let* ((sp (position #\Space arg))
             (name (subseq arg 0 (or sp (length arg))))
             (value (and sp (string-trim " " (subseq arg sp)))))
        (handler-case
            (let ((v (set-aldo-setting name (or value ""))))
              ;; write through to the canonical *CLAL-ALDO-CONFIGURATION*
              (ignore-errors (sync-config-to-variable))
              (out ui "DBG> ~(~A~) = ~A~%" name (format-setting-value v)))
          (error (e) (out ui "DBG> set error: ~A~%" e))))))

(defun call-canonical-config (name)
  "Invoke the canonical config builtin NAME (CLAL-SAVE/LOAD-ALDO-CONFIGURATION)
in the current evaluation context — the single on-disk format and store
(command reference §8). Returns (values RESULT t) when the builtin exists, or
(values NIL NIL) so the caller falls back to the UI's own file I/O (e.g. a
minimal context with no core builtins)."
  (let* ((ctx (ignore-errors (current-evaluation-context)))
         (fn (and ctx (ignore-errors (lookup-function (intern-autolisp-symbol name) ctx)))))
    (if fn (values (call-autolisp-function fn) t) (values nil nil))))

(defun config-path-string (value)
  "A printable path string from a CLAL-SAVE result (an AutoLISP string), or its
princ form."
  (handler-case (autolisp-string-value value) (error () (princ-to-string value))))

(defun settings-cmd (ui arg)
  "`,settings' — list all options; `,settings NAME' print one; `,settings save'
/ `,settings reload' persist (command reference §8)."
  (cond
    ((null arg)
     ;; reflect any AutoLISP-side change to the canonical variable first
     (ignore-errors (sync-config-from-variable))
     (paged-out ui (format nil "~{  ~A~%~}" (aldo-settings-lines))))
    ((string-equal arg "save")
     (handler-case
         (progn
           (ignore-errors (sync-config-to-variable))   ; UI copy → canonical variable
           (multiple-value-bind (res ok)
               (call-canonical-config "CLAL-SAVE-ALDO-CONFIGURATION")
             (out ui "DBG> saved ~A~%"
                  (if ok (config-path-string res) (save-aldo-configuration)))))
       (error (e) (out ui "DBG> save error: ~A~%" e))))
    ((string-equal arg "reload")
     (handler-case
         (multiple-value-bind (res ok)
             (call-canonical-config "CLAL-LOAD-ALDO-CONFIGURATION")
           (cond
             (ok                                       ; canonical reload → sync into UI
              (ignore-errors (sync-config-from-variable))
              (if res (out ui "DBG> reloaded~%")
                  (out ui "DBG> no configuration file found~%")))
             (t                                        ; fallback: the UI's own loader
              (let ((p (load-aldo-configuration)))
                (ignore-errors (sync-config-to-variable))
                (if p (out ui "DBG> reloaded ~A~%" p)
                    (out ui "DBG> no configuration file found~%"))))))
       (error (e) (out ui "DBG> reload error: ~A~%" e))))
    (t (ignore-errors (sync-config-from-variable))
       (if (setting-spec arg)
           (out ui "  ~(~A~) = ~A~%" arg (format-setting-value (get-aldo-setting arg)))
           (out ui "DBG> unknown setting ~S (,settings lists them all)~%"
                (string-downcase (string arg)))))))

(defun eval-and-print (ui session form-string &optional (prompt "DBG> "))
  "Evaluate FORM-STRING in the stopped frame and echo the value, prefixed by the
current mode's PROMPT (sedit-spec §6: DBG> at the debugger, NAV> in the form
navigator, so the echo matches where the form was typed)."
  (handler-case
      (out ui "~A~A~%" prompt (preview (cmd-eval session form-string)))
    (error (e) (out ui "~Aeval error: ~A~%" prompt e))))

(defun print-variable-cmd (ui session arg)
  (if (and arg (plusp (length arg)))
      (eval-and-print ui session arg)
      (let ((snapshot (session-snapshot session)))
        (when snapshot (print-bindings ui snapshot)))))

(defun current-poll-points (session)
  "A list of (PP LINE BREAKPOINTED-P) for the current function's poll points
that have a known source line (TUI Numbered Poll-Points)."
  (let ((metadata (current-metadata session))
        (result '()))
    (when metadata
      (let ((fid (function-debug-metadata-function-id metadata))
            (bps (cmd-list-breakpoints session)))
        (dotimes (form-id (function-debug-metadata-poll-point-count metadata))
          (let ((pos (form-id-position metadata form-id)))
            (when (and (source-position-p pos) (source-position-start-line pos))
              (push (list (poll-point-id fid form-id)
                          (source-position-start-line pos)
                          (and (find-if (lambda (b)
                                          (and (= (breakpoint-fid b) fid)
                                               (= (breakpoint-form-id b) form-id)))
                                        bps)
                               t))
                    result))))))
    (sort result #'< :key #'first)))

(defun list-poll-points-cmd (ui session)
  "`list polls' — the current function's poll points with their numbers, source
lines, and breakpoint status (the dumb-terminal way to discover the ppN a user
types into break/condition/…; TUI Numbered Poll-Points)."
  (let ((pps (current-poll-points session)))
    (if (null pps)
        (out ui "DBG>   no poll points~%")
        (dolist (pp pps)
          (destructuring-bind (n line bp) pp
            (out ui "DBG>   pp~D  line ~D~:[~; *breakpoint~]~%" n line bp))))))

(defun relist-source (ui session)
  "`ls' — list source around the current stop, or around the file:line selected
by CLAL-SELECT-FILE when one is set (aldo-pre-debug.issue)."
  (let ((selected *selected-source*))
    (if selected
        (ui-show-source ui (clautolisp.source:make-source-position
                            :file (car selected)
                            :start-line (cdr selected) :end-line (cdr selected)))
        (let ((snapshot (session-snapshot session)))
          (when snapshot (ui-show-source ui (snapshot-source-position snapshot)))))))

(defun print-stack (ui session)
  (let ((snapshot (session-snapshot session)))
    (when snapshot
      (loop for frame in (snapshot-call-stack snapshot)
            for i from 0
            do (out ui "DBG>   ~D: ~A  ~A~%" i
                    (stack-frame-function-name frame)
                    (location-string (stack-frame-source-position frame)
                                     (stack-frame-function-name frame)))))))

(defun breakpoint-annotations (bp)
  "A trailing annotation string for a breakpoint listing — flags disabled,
conditional, once, traced, bpcmd state (command reference §2)."
  (with-output-to-string (s)
    (unless (breakpoint-enabled-p bp) (write-string " (disabled)" s))
    (when (breakpoint-condition bp) (write-string " (conditional)" s))
    (unless (breakpoint-steady-p bp) (write-string " (once)" s))
    (when (breakpoint-action bp)
      (write-string (if (breakpoint-trace-p bp) " (traced)" " (bpcmd)") s))))

(defun list-breakpoints-cmd (ui session)
  (let ((bps (cmd-list-breakpoints session)))
    (if bps
        (dolist (bp bps)
          (out ui "DBG>   pp~D fid ~D form ~D ~A~A~%"
               (breakpoint-pp bp) (breakpoint-fid bp)
               (breakpoint-form-id bp) (breakpoint-when bp)
               (breakpoint-annotations bp)))
        (out ui "DBG>   no breakpoints~%"))))

(defun location-label (token)
  "A readable label for a location TOKEN in messages: a bare integer reads as
\"line N\"; the finer LINE.K / LINE:COL forms are shown verbatim."
  (if (and (plusp (length token)) (every #'digit-char-p token))
      (format nil "line ~A" token)
      token))

(defun resolve-line-spec (metadata token)
  "Resolve a within-function location TOKEN to a form-id (command reference §2
*Specifying a location*): =LINE= (the innermost poll point on the line),
=LINE.K= (the K-th poll point on LINE, left-to-right, 1-based), or =LINE:COL=
(the poll point starting at that column). Returns the form-id or NIL."
  (let ((dot (position #\. token))
        (colon (position #\: token)))
    (cond
      (colon
       (let ((line (ignore-errors (parse-integer token :end colon)))
             (col (ignore-errors (parse-integer token :start (1+ colon)))))
         (and line col (form-id-at-line-col metadata line col))))
      (dot
       (let ((line (ignore-errors (parse-integer token :end dot)))
             (k (ignore-errors (parse-integer token :start (1+ dot)))))
         (and line k (let ((ids (form-ids-at-line metadata line)))
                       (and (<= 1 k (length ids)) (nth (1- k) ids))))))
      (t (let ((line (ignore-errors (parse-integer token :junk-allowed t))))
           (and line (find-form-id-at-line metadata line)))))))

(defun set-breakpoint-cmd (ui session arg &optional (steady t))
  "`b LINE' / `b LINE.K' / `b LINE:COL' / `b ppN' — set a breakpoint at a poll
point of the current function by source line (innermost on the line, the K-th on
the line, or the one at LINE:COL) or by its poll-point number. With STEADY NIL
the breakpoint is volatile — removed on first hit (`break once' / `bo', §2)."
  (let* ((tok (and arg (string-trim " " arg)))
         (kind (if steady "" " (once)"))
         (pp (and tok (>= (length tok) 3) (string-equal "pp" (subseq tok 0 2))
                  (ignore-errors (parse-integer (subseq tok 2) :junk-allowed t)))))
    (cond
      ((or (null tok) (zerop (length tok))) (out ui "DBG> break needs a location (LINE, LINE.K, LINE:COL, or ppN)~%"))
      (pp (multiple-value-bind (fid form-id) (poll-point-location pp)
            (if fid
                (multiple-value-bind (bp new-p)
                    (cmd-set-breakpoint session fid form-id :steady steady)
                  (out ui "DBG> breakpoint pp~D ~:[already set~;set~]~A~%"
                       (breakpoint-pp bp) new-p kind))
                (out ui "DBG> no poll point pp~D~%" pp))))
      (t (let* ((metadata (or (session-nav-target session) (current-metadata session)))
                (form-id (and metadata (resolve-line-spec metadata tok))))
           (if form-id
               (multiple-value-bind (bp new-p)
                   (cmd-set-breakpoint
                    session (function-debug-metadata-function-id metadata)
                    form-id :steady steady)
                 (out ui "DBG> breakpoint pp~D ~:[already set at~;set at~] ~A~A~%"
                      (breakpoint-pp bp) new-p (location-label tok) kind))
               (out ui "DBG> no poll point at ~A~%" tok)))))))

(defun prompt-for-command-argument (ui prompt)
  "Prompt for a missing mandatory command argument and read one line from the
UI's input. Returns the trimmed answer, or NIL on EOF / a blank answer — the
command is cancelled (error-while-debugging.issue)."
  (out ui "~A" prompt)
  (finish-output (dumb-ui-output ui))
  (let ((line (read-line (dumb-ui-input ui) nil :eof)))
    (unless (eq line :eof)
      (let ((trimmed (string-trim " 	" line)))
        (when (plusp (length trimmed)) trimmed)))))

(defun return-value-cmd (ui session hit arg)
  "r FORM — continue-with-return (command reference §1 / spec §10.1): make the
innermost instrumented form return FORM's value. Works at any stop that an
instrumented form encloses — a breakpoint/step stop as well as an error stop.
The expression is MANDATORY — AutoLISP has no multiple-values / no-value, so
every function returns something (error-while-debugging.issue): a bare =r=
prompts for the value; a blank answer cancels."
  (declare (ignore hit))
  (let ((arg (or arg (prompt-for-command-argument ui "DBG> return value? "))))
    (if (null arg)
        (progn (out ui "DBG> r needs a return-value expression — cancelled~%") nil)
        (handler-case
            (let ((value (cmd-eval session arg)))
              (cmd-return session value))
          (error (e) (out ui "DBG> return error: ~A~%" e) nil)))))

(defun help-text ()
  "The one-screen command summary (command reference §0 vocabulary)."
  (format nil "DBG> commands: (command reference §0 vocabulary)~%~
            DBG>   c continue   i into   n next   o out   a LINE advance   j LINE|ppN jump   r FORM return   q quit~%~
            DBG>   b LINE|LINE.K|LINE:COL|ppN break   bo break once   rbreak PATTERN   lb list breakpoints   delete [ppN] / clear~%~
            DBG>   enable [ppN]   disable [ppN]   condition ppN [FORM]   ignore ppN COUNT~%~
            DBG>   bpcmd ppN [FORM]   trace FN [FORM]   untrace [FN]   catch error|caught on|off~%~
            DBG>   watch VAR [FORM]   unwatch [VAR]   lw list watches~%~
            DBG>   lf list frames   f N frame   fi/fo inner/outer   ft/fb top/bottom~%~
            DBG>   ll/lp/lv list locals/parameters/variables   list polls~%~
            DBG>   p EXPR print   t EXPR type   v EXPR visit   ls list source~%~
            DBG>   nav (structural navigation: d u > < << >> ±N q)~%~
            DBG>   g/goto NAME   . /definition NAME   back   history   restore N   search PATTERN~%~
            DBG>   set NAME VALUE   ,settings [NAME|save|reload]~%~
            DBG>   display FORM   undisplay [N]~%~
            DBG>   (form...) evaluate in the current frame   h/? help   apropos WORD~%"))

(defun print-help (ui)
  (paged-out ui (help-text)))

(defun apropos-cmd (ui arg)
  "`apropos WORD' — show the command-summary lines mentioning WORD (command
reference §8). Searches the same text `help' shows, so user-visible commands
document themselves uniformly."
  (if (null arg)
      (out ui "DBG> apropos: usage: apropos WORD~%")
      (let ((hits (remove-if-not (lambda (line) (search arg line :test #'char-equal))
                                 (string-lines (help-text)))))
        (if hits
            (dolist (line hits) (out ui "  ~A~%" (string-left-trim "DBG> " line)))
            (out ui "DBG>   no command matching ~A~%" arg)))))

;;; --- inspector sub-REPL (spec §18.2) -------------------------------

(defstruct inspi-state ui session)

(defun %inspi-state () (activation-state *command-activation*))

(defun %inspi-read (input-context)
  "The inspector reader: a blank line leaves the inspector (§18.2)."
  (let ((input (%line-command-read input-context)))
    (if (eq input :blank)
        (make-input-command :raw "q" :tokens (list (cons 'ident "q")))
        input)))

(defun %inspi-status (stream)
  "The *INSPI* singleton's status: render the inspector page (spec §18.2)."
  (declare (ignore stream))
  (let ((state (%inspi-state)))
    (render-inspector-page (inspi-state-ui state) (inspi-state-session state))))

(defun %inspi-evaluate (input)
  "The *INSPI* singleton's evaluator: a bare `(FORM)' evaluates with $ bound
to the selection (spec §18.2)."
  (let ((state (%inspi-state)))
    (inspector-eval (inspi-state-ui state) (inspi-state-session state)
                    (second input))))

(defun inspector-loop (ui session arg)
  "Open the inspector on ARG (a form evaluated in-frame) or the first visible
binding, then enter the INSPECT interactor (spec §18.2). Returns NIL when the
inspector pops (q / blank / EOF), or a resume directive when an unshadowed
debugger command issued inside resumes execution (§8 stacked dispatch)."
  (let ((value (handler-case (cmd-eval session (or arg "nil"))
                 (error (e) (out ui "INSPECT> eval error: ~A~%" e) (return-from inspector-loop)))))
    (cmd-inspect session value :origin (and arg (first (read-current-source arg :source-name "<debugger>"
                                                             :context (session-context session)))))
    (%interactor-mode-loop ui session nil *inspi*
                           (make-inspi-state :ui ui :session session))))

(defun render-inspector-page (ui session)
  (let ((page (session-page (session-inspector session))))
    (out ui "~&INSPECT> origin: ~A  path: ~A~%"
         (preview (clautolisp.inspect:session-origin (session-inspector session)))
         (preview (session-path-expression-safe session)))
    (out ui "INSPECT> #<~A> ~A~%" (inspect-page-type-name page) (inspect-page-header page))
    (loop for component in (inspect-page-components page)
          for i from 0
          do (out ui "INSPECT>   ~D. ~A~14T~A~50T[~A]~%"
                  i (inspect-component-label component)
                  (inspect-component-preview component)
                  (preview (inspect-component-accessor component) 40)))))

(defun session-path-expression-safe (session)
  (multiple-value-bind (expr kind) (cmd-inspector-path-expression session)
    (if (eq kind :partial) (format nil "~A …(opaque)" (preview expr)) expr)))

(defun descend (ui session arg)
  (let ((index (ignore-errors (parse-integer arg :junk-allowed t))))
    (if index
        (handler-case (cmd-inspector-descend session index)
          (error (e) (out ui "INSPECT> ~A~%" e)))
        (out ui "INSPECT> d needs a component number~%"))))

(defun inspector-eval (ui session form-string)
  (handler-case
      (out ui "INSPECT> ~A~%"
           (preview (session-eval (session-inspector session)
                                  (first (read-current-source form-string :source-name "<debugger>"
                                          :context (session-context session))))
                    200))
    (error (e) (out ui "INSPECT> eval error: ~A~%" e))))

(defun inspector-bind (ui session arg)
  "b $        bind to next workspace slot
   b ! NAME  setq NAME (frame-aware, §16.1)
   b $NAME   bind to a named workspace slot"
  (cond
    ((or (null arg) (string= arg "") (string= arg "$"))
     (out ui "INSPECT> bound to ~A~%" (cmd-inspector-bind session :workspace)))
    ((and (> (length arg) 1) (char= (char arg 0) #\!))
     (let ((name (intern-rt (string-trim " " (subseq arg 1)))))
       (cmd-inspector-bind session (list :setq name))
       (out ui "INSPECT> setq ~A~%" (autolisp-symbol-name name))))
    ((char= (char arg 0) #\$)
     (out ui "INSPECT> bound to ~A~%" (cmd-inspector-bind session (list :workspace arg))))
    (t (out ui "INSPECT> use: b $ | b $NAME | b ! NAME~%"))))

(defun intern-rt (name)
  (clautolisp.autolisp-runtime:intern-autolisp-symbol (string-upcase name)))

(defun print-path (ui session)
  (out ui "INSPECT> path: ~A~%" (session-path-expression-safe session)))
