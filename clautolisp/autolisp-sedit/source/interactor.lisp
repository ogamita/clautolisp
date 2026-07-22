;;;; clautolisp/autolisp-sedit/source/interactor.lisp
;;;;
;;;; SEDIT as an interactor (interactor-design-revision.issue T2, Option A):
;;;; ONE SEDIT interactor — the motions and the editing keys in one
;;;; dictionary, prompt SEDIT> always. The spec §6.6 internal NAV/EDIT
;;;; two-mode machine dissolves into the interactor stack: sedit's keys
;;;; (i a r c x v z m s n …) shadow same-key debugger verbs while SEDIT is
;;;; stacked — `aldo CMD' reaches them explicitly — and every unshadowed
;;;; command falls through to the interactors below. SEDIT's motions
;;;; traverse ALL sub-sexps (unlike NAVI's, which skip to poll-points), so
;;;; they are sedit's own commands under the same keys (D5).
;;;;
;;;; The legacy standalone driver (SEDIT-RUN / SEDIT-COMMAND, modes.lisp)
;;;; remains as the library-level two-mode machine; the clautolisp tool and
;;;; the debugger drive sedit through SEDIT-ENTER below.

(in-package #:clautolisp.sedit)

(defvar *sedit-commands*
  (clautolisp.interactor:make-command-dictionary "sedit")
  "The SEDIT interactor's system dictionary: motions, editing commands,
eval/load/save, quit and help (sedit spec §5). Registered below.")

(defvar *sedit-user-commands*
  (clautolisp.interactor:make-command-dictionary "sedit-user")
  "User commands of the SEDIT interactor ((clal-define-command \"SEDIT\" …)),
shadowing *SEDIT-COMMANDS*.")

(defstruct sedit-interactor-state
  "The SEDIT activation's per-entry state: the editing SESSION plus the
runtime-coupling hooks (the same callbacks the legacy SEDIT-RUN takes)."
  session debug-hook eval-hook load-hook eval-print-hook)

(defun %sedit-istate ()
  (clautolisp.interactor:activation-state
   clautolisp.interactor:*command-activation*))

(defun %sedit-isession () (sedit-interactor-state-session (%sedit-istate)))

(defun %sedit-status (stream)
  "Render the marked selection before each prompt (spec §5.2)."
  (format stream "~&       ~A~%"
          (render-selection (sedit-state-loc (sedit-session-state (%sedit-isession))))))

(defun %sedit-signed-skip-p (input)
  "An INPUT-COMMAND whose whole line is ±N — the skip motion."
  (and (clautolisp.interactor:input-command-p input)
       (let ((tokens (clautolisp.interactor:input-command-tokens input)))
         (and (= 1 (length tokens))
              (eq (car (first tokens)) 'integer)
              (member (char (cdr (first tokens)) 0) '(#\+ #\-))))))

(defun %sedit-read (input-context)
  "The SEDIT reader: every line is a command; a `(' line is a form to
evaluate at the prompt (spec §6.6, like the REPL); a ±N line is the skip
motion."
  (let ((input (clautolisp.interactor:command-read
                input-context
                (lambda (ic)
                  (let ((line (clautolisp.interactor:read-line-from-input-context ic)))
                    (if (eq line :eof)
                        :eof
                        (list :eval (string-trim '(#\Space #\Tab) line))))))))
    (if (%sedit-signed-skip-p input)
        (let ((count (cdr (first (clautolisp.interactor:input-command-tokens input)))))
          (clautolisp.interactor:make-input-command
           :raw (concatenate 'string "skip " count)
           :tokens (list (cons 'clautolisp.interactor:ident "skip")
                         (cons 'integer count))))
        input)))

(defun %sedit-evaluate (input)
  "A form typed at SEDIT> evaluates through the eval-print hook and prints,
like the REPL (spec §6.6)."
  (let ((hook (sedit-interactor-state-eval-print-hook (%sedit-istate)))
        (text (second input)))
    (format t "~&~A~%"
            (or (and hook (funcall hook (parse-form text)))
                "(no evaluator here)"))))

(clautolisp.interactor:define-interactor *sedit*
  :name "SEDIT"
  :status '%sedit-status
  :prompt "SEDIT> "
  :reader '%sedit-read
  :evaluator '%sedit-evaluate
  :commands *sedit-commands*
  :user-commands *sedit-user-commands*
  :documentation "The sedit structural editor as an interactor (spec §5;
design-revision T2 Option A): one dictionary of motions + editing commands,
always the SEDIT> prompt. Its keys shadow same-key debugger verbs while
stacked (`aldo CMD' reaches them); unshadowed commands fall through.")

;;; --- the vocabulary (spec §5) over the modes.lisp machinery ---------------

(defmacro %define-sedit-command ((key &rest words) docstring &body body)
  "Register a SEDIT command whose BODY sees SESSION (the sedit session),
STATE (its editing state) and ARG (the raw argument string or NIL)."
  `(clautolisp.interactor:define-command (*sedit* ,key ,@words) (&whole arg)
       ,docstring
     (declare (ignorable arg))
     (let* ((session (%sedit-isession))
            (state (sedit-session-state session)))
       (declare (ignorable session state))
       ,@body)))

(defmacro %define-sedit-motion ((key &rest words) token docstring)
  `(%define-sedit-command (,key ,@words) ,docstring
     (%do-motion state ,token)
     nil))

(%define-sedit-motion (d down)      "d"  "Descend into the selection (all sub-sexps, not just code).")
(%define-sedit-motion (u up)        "u"  "Ascend to the containing form.")
(%define-sedit-motion (|>| forward) ">"  "Select the next sibling.")
(%define-sedit-motion (|<| backward) "<" "Select the previous sibling.")
(%define-sedit-motion (|<<| first)  "<<" "Select the first sibling.")
(%define-sedit-motion (|>>| last)   ">>" "Select the last sibling.")
(clautolisp.interactor:bind-command-alias *sedit-commands* "f" ">")
(clautolisp.interactor:bind-command-alias *sedit-commands* "b" "<")

(%define-sedit-command (skip) "skip ±N: move N siblings forward (+) or back (-)."
  (let ((count (and arg (ignore-errors (parse-integer arg)))))
    (if count
        (sedit-skip state count)
        (format t "~&SEDIT> skip needs a signed count (±N)~%")))
  nil)

(defmacro %define-sedit-editing ((key &rest words) token docstring)
  "An editing command: dispatch TOKEN through the §5 editing machinery."
  `(%define-sedit-command (,key ,@words) ,docstring
     (%do-editing session ,token arg
                  (sedit-interactor-state-eval-hook (%sedit-istate)))
     nil))

(%define-sedit-editing (i insert)  "i" "i FORM: insert FORM before the selection.")
(%define-sedit-editing (a add)     "a" "a FORM: add FORM after the selection.")
(%define-sedit-editing (r replace) "r" "r FORM: replace the selection (rename, on a directory entry).")
(%define-sedit-editing (ic)        "ic" "ic [TEXT]: insert a comment before the selection.")
(%define-sedit-editing (ac)        "ac" "ac [TEXT]: add a comment after the selection.")
(%define-sedit-editing (rc)        "rc" "rc [TEXT]: replace the selection by a comment.")
(%define-sedit-editing (z)         "z" "Undo the last edit.")
(clautolisp.interactor:bind-command-alias *sedit-commands* "undo" "z")
(%define-sedit-editing (c copy)    "c" "Copy the selection to the clipboard.")
(%define-sedit-editing (x)         "x" "Cut the selection (delete, on a directory entry).")
(clautolisp.interactor:bind-command-alias *sedit-commands* "cut" "x")
(%define-sedit-editing (v)         "v" "Paste the clipboard at the selection.")
(clautolisp.interactor:bind-command-alias *sedit-commands* "paste" "v")
(%define-sedit-editing (wrap)      "wrap"   "Wrap the selection in a new list.")
(%define-sedit-editing (slurp)     "slurp"  "Slurp the next sibling into the selection.")
(%define-sedit-editing (barf)      "barf"   "Barf the selection's last element out.")
(%define-sedit-editing (splice)    "splice" "Splice the selection into its parent.")
(%define-sedit-editing (split)     "split"  "Split the selection at the point.")
(%define-sedit-editing (join)      "join"   "Join the selection with the next sibling.")
(%define-sedit-editing (m macroexpand) "m" "Evaluate the selection and replace it by the result.")
(%define-sedit-editing (s save)    "s" "s [PATH]: write the edited file/form.")
(%define-sedit-editing (n new)     "n" "n NAME: new file (on a directory).")

(%define-sedit-command (rename) "rename NAME: rename the selected directory entry."
  (%do-rename session arg)
  nil)

(%define-sedit-command (delete) "Delete the selected directory entry."
  (%do-delete session)
  nil)

(%define-sedit-command (e eval) "Evaluate the selection and print the result."
  (let ((hook (sedit-interactor-state-eval-print-hook (%sedit-istate))))
    (format t "~&~A~%"
            (or (and hook (funcall hook (loc-focus (sedit-state-loc state))))
                "(no evaluator here)")))
  nil)

(%define-sedit-command (l load) "l [FILE]: load the current file (or FILE) into the running system."
  (%do-load session arg (sedit-interactor-state-load-hook (%sedit-istate)))
  nil)

(%define-sedit-command (aldo) "aldo CMD: run a debugger command (when no debugger interactor is stacked)."
  ;; When ALDO is ON the stack, `aldo CMD' never reaches this command — the
  ;; interactor-name routing wins. This is the fallback for a sedit entered
  ;; outside a stop (the plain REPL): the debug hook reaches the attached
  ;; session's UI, or explains that none is attached.
  (let ((hook (sedit-interactor-state-debug-hook (%sedit-istate))))
    (if (and hook arg)
        (funcall hook arg)
        (progn (format t "~&SEDIT> no debugger attached~%") nil))))
(clautolisp.interactor:bind-command-alias *sedit-commands* "debug" "aldo")

(defun sedit-interactor-help ()
  (format nil "SEDIT commands (§5): d u  > (f) < (b)  << >>  ±N move | ~
i a r insert/add/replace | ic ac rc comment | z undo | c copy x cut v paste | ~
wrap slurp barf splice split join | e eval  m macroexpand | l load  s save | ~
n new  rename  delete (directory) | (form) evaluate | q quit | h help~%~
unshadowed debugger commands fall through while the debugger is below; ~
aldo CMD forces the debugger's meaning of a shadowed key"))

(%define-sedit-command (h help) "Print the SEDIT command summary."
  (format t "~&~A~%" (sedit-interactor-help))
  nil)
(clautolisp.interactor:bind-command-alias *sedit-commands* "?" "h")

(%define-sedit-command (q quit)
    "Leave the editor; above a debugger stop, quitting aborts the debugged execution (asks first)."
  (if (clautolisp.interactor:find-activation "ALDO")
      ;; above the debugger (T4): leaving is resolving the stop — warn,
      ;; confirm, and delegate to the debugger's own quit (whose abort
      ;; directive cascades out of every nested loop); else do nothing.
      (progn
        (format t "~&SEDIT> q from the debugger aborts the execution and returns to the toplevel~%")
        (format t "SEDIT> (resume instead with: c continue, i into, n next, o out, a advance, r FORM return)~%")
        (format t "SEDIT> really abort? (y/n) ")
        (finish-output)
        (let ((answer (read-line *standard-input* nil :eof)))
          (when (and (stringp answer)
                     (member (string-trim " " answer) '("y" "yes")
                             :test #'string-equal))
            (clautolisp.interactor:run-command-line "aldo quit"))))
      ;; a (clal-sedit …) editor: quit pops SEDIT and the call returns
      ;; normally with the edited result (T4)
      (clautolisp.interactor:pop-interactor))
  nil)

;;; --- entering the editor ---------------------------------------------------

(defun sedit-enter (session &key debug-hook eval-hook load-hook eval-print-hook
                                 (input *standard-input*)
                                 (output *standard-output*)
                                 (error-output output))
  "Push the SEDIT interactor over the current stack — (SEDIT …) per
design-revision D9 — and drive it in a nested INTERACTOR-LOOP until its quit
pops it (or EOF). Returns (values RESULT DIRECTIVE): RESULT is the §2
session result when the editor was left normally; on a debugger resume
issued inside the editor (`aldo c', or the confirmed quit above a stop),
RESULT is NIL and DIRECTIVE the resume directive, which the caller must
propagate."
  (let* ((state (make-sedit-interactor-state
                 :session session
                 :debug-hook debug-hook :eval-hook eval-hook
                 :load-hook load-hook :eval-print-hook eval-print-hook))
         (clautolisp.interactor:*interactor-stack*
           (cons (clautolisp.interactor:make-activation *sedit* state)
                 clautolisp.interactor:*interactor-stack*)))
    (let ((directive (clautolisp.interactor:interactor-loop
                      :input input :output output :error-output error-output
                      :floor (length clautolisp.interactor:*interactor-stack*))))
      (if directive
          (values nil directive)
          (values (session-result session) nil)))))
