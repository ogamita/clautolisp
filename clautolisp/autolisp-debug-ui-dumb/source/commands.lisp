;;;; The built-in aldo vocabulary (command reference §0), registered as
;;;; commands of the ALDO dictionary (interactors step 2).
;;;;
;;;; Each built-in keeps its exact historical calling convention: the body
;;;; sees UI / SESSION / HIT (the dispatch dynamic vars) and ARG — the raw,
;;;; untokenized argument string (or NIL) — declared as the (&WHOLE ARG)
;;;; lambda-list, because most built-ins re-parse their argument themselves
;;;; (locations, Lisp forms, patterns). The `,word' spellings are legacy
;;;; aliases of the word forms.

(in-package #:clautolisp.ui.dumb)

;; Re-loading this file redefines the whole vocabulary: start from a fresh
;; dictionary so the registrations below never clash with their previous
;; incarnation.
(setf *aldo-commands* (clautolisp.interactor:make-command-dictionary "aldo"))

(defmacro define-aldo-command ((key &rest words) docstring &body body)
  "Register a built-in in *ALDO-COMMANDS*: KEY the short name, WORDS the
ordered words of its single long name — one phrase (§0: the key is their
initials); alternative spellings are aliases. BODY sees UI, SESSION, HIT and
ARG (raw argument string or NIL) and returns a resume directive, or NIL to
keep the command loop reading."
  `(bind-command *aldo-commands*
                 (list ',key ,@(mapcar (lambda (w) `',w) words))
                 '(&whole arg) ,docstring
                 (lambda (arg)
                   (declare (ignorable arg))
                   (let ((ui *debugger-ui*)
                         (session *debugger-session*)
                         (hit *debugger-hit*))
                     (declare (ignorable ui session hit))
                     ,@body))))

(defun %alias (token command-token)
  (bind-command-alias *aldo-commands* token command-token))

;;; --- execution control (§1) -------------------------------------------

(defun %refuse-at-error-stop (ui hit what)
  "At an error stop the erroring form never completes, so there is nothing to
step / advance / jump into: an unrecognised resume directive would silently
DECLINE the stop and let the error unwind out of the debugger
(error-while-debugging.issue). Print the §10.1 guidance instead and keep the
command loop reading. Returns T when refused."
  (when (and hit (eq (hit-when hit) :error))
    (out ui "DBG> can't ~A from an error stop — q abort, r FORM return a value, c continue/run *error*~%"
         what)
    t))

(define-aldo-command (c continue) "Resume execution."
  (cmd-continue session))

(define-aldo-command (i into) "Step to the next poll point, entering calls."
  (unless (%refuse-at-error-stop ui hit "step")
    (cmd-step session :into)))

(define-aldo-command (n next) "Step to the next poll point, over calls."
  (unless (%refuse-at-error-stop ui hit "step")
    (cmd-step session :over)))

(define-aldo-command (o out) "Step out of the current function."
  (unless (%refuse-at-error-stop ui hit "step")
    (cmd-step session :out)))

(define-aldo-command (a advance) "advance LINE: run to LINE, once."
  (unless (%refuse-at-error-stop ui hit "advance")
    (advance-cmd ui session arg)))

(define-aldo-command (j jump) "jump LINE|ppN: move the point of execution."
  (unless (%refuse-at-error-stop ui hit "jump")
    (jump-cmd ui session hit arg)))

(define-aldo-command (r return) "return [FORM]: return FORM's value from the current function."
  (return-value-cmd ui session hit arg))

(define-aldo-command (q quit) "Abort the debugged evaluation."
  (cmd-abort session))

;;; --- breakpoints (§2) ---------------------------------------------------

(define-aldo-command (b break)
    "break LINE|LINE.K|LINE:COL|ppN: set a breakpoint; `break once LOC' is volatile."
  ;; `break once LINE' (volatile) vs `break LINE'
  (if (and arg (let ((a (string-left-trim " " arg)))
                 (and (>= (length a) 5) (string-equal "once " (subseq a 0 5)))))
      (set-breakpoint-cmd ui session
                          (string-trim " " (subseq (string-left-trim " " arg) 4)) nil)
      (set-breakpoint-cmd ui session arg))
  nil)

(define-aldo-command (bo) "bo LOC: set a volatile (one-shot) breakpoint."
  (set-breakpoint-cmd ui session arg nil)
  nil)

(define-aldo-command (rbreak) "rbreak PATTERN: break on every function matching PATTERN."
  (rbreak-cmd ui session arg)
  nil)

(define-aldo-command (lb) "List breakpoints."
  (list-breakpoints-cmd ui session)
  nil)

(define-aldo-command (delete) "delete [ppN]: delete breakpoints (all, or at ppN)."
  (delete-cmd ui session arg)
  nil)

(define-aldo-command (enable) "enable [ppN]: enable breakpoints."
  (enable-cmd ui session arg t)
  nil)

(define-aldo-command (disable) "disable [ppN]: disable breakpoints."
  (enable-cmd ui session arg nil)
  nil)

(define-aldo-command (condition) "condition ppN [FORM]: make ppN conditional on FORM."
  (condition-cmd ui session arg)
  nil)

(define-aldo-command (ignore) "ignore ppN COUNT: skip ppN's next COUNT hits."
  (ignore-cmd ui session arg)
  nil)

(define-aldo-command (bpcmd) "bpcmd ppN [FORM]: run FORM whenever ppN hits."
  (bpcmd-cmd ui session arg)
  nil)

(define-aldo-command (trace) "trace FN [FORM]: trace FN's calls (printing FORM)."
  (trace-cmd ui session arg)
  nil)

(define-aldo-command (untrace) "untrace [FN]: stop tracing FN (or everything)."
  (untrace-cmd ui session arg)
  nil)

(define-aldo-command (catch) "catch error|caught on|off: break on (caught) errors."
  (catch-cmd ui arg)
  nil)

(define-aldo-command (watch) "watch VAR [FORM]: break when VAR changes (and FORM holds)."
  (watch-cmd ui session arg)
  nil)

(define-aldo-command (unwatch) "unwatch [VAR]: remove a watch (or all)."
  (unwatch-cmd ui session arg)
  nil)

(define-aldo-command (lw) "List watches."
  (list-watches-cmd ui session)
  nil)

;;; --- stack and frames (§3) ---------------------------------------------

(define-aldo-command (lf) "List the call-stack frames."
  (print-stack ui session)
  nil)

(define-aldo-command (f frame) "frame N|inner|outer|top|bottom: select a frame."
  (frame-cmd ui session arg)
  nil)

(define-aldo-command (fi) "Select the inner frame."
  (frame-cmd ui session "inner")
  nil)

(define-aldo-command (fo) "Select the outer frame."
  (frame-cmd ui session "outer")
  nil)

(define-aldo-command (ft) "Select the top frame."
  (frame-cmd ui session "top")
  nil)

(define-aldo-command (fb) "Select the bottom frame."
  (frame-cmd ui session "bottom")
  nil)

(define-aldo-command (ll) "List the selected frame's locals."
  (list-vars-cmd ui session "locals")
  nil)

(define-aldo-command (lp) "List the selected frame's parameters."
  (list-vars-cmd ui session "parameters")
  nil)

(define-aldo-command (lv) "List the visible variables."
  (list-vars-cmd ui session "variables")
  nil)

;;; --- data (§4) ------------------------------------------------------------

(define-aldo-command (p print) "print EXPR: evaluate and print EXPR in the current frame."
  (print-variable-cmd ui session arg)
  nil)

(define-aldo-command (t type) "type EXPR: print EXPR's type."
  (type-cmd ui session arg)
  nil)

(define-aldo-command (v visit) "visit EXPR: inspect EXPR (the INSPECT interactor)."
  (inspector-loop ui session arg))

;;; --- source (§5) + structural navigation (§3) -------------------------

(define-aldo-command (ls) "List the current source."
  (relist-source ui session)
  nil)

(define-aldo-command (nav) "Enter the structural navigator (d u > < << >> ±N q)."
  (nav-loop ui session hit))

(define-aldo-command (g goto) "goto NAME: browse to NAME's definition."
  (goto-cmd ui session arg)
  nil)

(define-aldo-command (|.| definition) "definition NAME: show NAME's definition."
  (definition-cmd ui session arg)
  nil)

(define-aldo-command (back) "Back to the previous browse location."
  (back-cmd ui session)
  nil)

(define-aldo-command (history) "Show the browse history."
  (history-cmd ui session)
  nil)

(define-aldo-command (restore) "restore N: restore the Nth navigation state."
  (restore-cmd ui arg)
  nil)

(define-aldo-command (search) "search PATTERN: search the source."
  (search-cmd ui session arg)
  nil)

(define-aldo-command (list) "list source|breakpoints|watches|frames|locals|parameters|variables|polls."
  (list-sub-cmd ui session arg)
  nil)

;;; --- meta (§8) ------------------------------------------------------------

(define-aldo-command (set) "set NAME VALUE: change an aldo setting."
  (set-setting-cmd ui arg)
  nil)

(define-aldo-command (settings) "settings [NAME|save|reload]: show / manage the settings."
  (settings-cmd ui arg)
  nil)

(define-aldo-command (display) "display FORM: print FORM at every stop."
  (display-cmd ui arg)
  nil)

(define-aldo-command (undisplay) "undisplay [N]: remove display N (or all)."
  (undisplay-cmd ui arg)
  nil)

(define-aldo-command (h help) "Print the command summary."
  (print-help ui)
  nil)

(define-aldo-command (apropos) "apropos WORD: search the known functions."
  (apropos-cmd ui arg)
  nil)

;;; --- legacy `,word' aliases + mnemonic keys -----------------------------

(%alias "?" "help")
(%alias ",jump" "jump")
(%alias ",rbreak" "rbreak")
(%alias ",delete" "delete")
(%alias "clear" "delete")
(%alias ",clear" "delete")
(%alias ",enable" "enable")
(%alias ",disable" "disable")
(%alias ",condition" "condition")
(%alias ",ignore" "ignore")
(%alias ",bpcmd" "bpcmd")
(%alias ",trace" "trace")
(%alias ",untrace" "untrace")
(%alias ",catch" "catch")
(%alias ",watch" "watch")
(%alias ",unwatch" "unwatch")
(%alias ",type" "type")
(%alias ",nav" "nav")
(%alias ",goto" "goto")
(%alias ",definition" "definition")
(%alias ",back" "back")
(%alias ",history" "history")
(%alias ",restore" "restore")
(%alias ",search" "search")
(%alias ",settings" "settings")
(%alias ",display" "display")
(%alias ",undisplay" "undisplay")
(%alias ",apropos" "apropos")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; NAVI — the form navigator's vocabulary (sedit spec §5 motions).
;;;
;;; These stack over the debugger's dictionary while the navigator is
;;; entered: every non-navigator token falls through to the full debugger
;;; vocabulary (bug-aldo-nav-command-dictionary), and the motions are
;;; collision-free against it by design.

(setf *navi-commands* (clautolisp.interactor:make-command-dictionary "navi"))

(defmacro define-navi-command ((key &rest words) docstring &body body)
  "Register a navigator command in *NAVI-COMMANDS*. BODY sees STATE (the
NAVI-STATE), UI, SESSION, HIT, LOC and ARG (the raw argument string or NIL);
a body that changes the view sets (NAVI-STATE-REDRAW STATE)."
  `(bind-command *navi-commands*
                 (list ',key ,@(mapcar (lambda (w) `',w) words))
                 '(&whole arg) ,docstring
                 (lambda (arg)
                   (declare (ignorable arg))
                   (let* ((state (%navi-state))
                          (ui (navi-state-ui state))
                          (session (navi-state-session state))
                          (hit (navi-state-hit state))
                          (loc (navi-state-loc state)))
                     (declare (ignorable ui session hit loc))
                     ,@body))))

(defmacro define-navi-motion ((key &rest words) motion docstring)
  "A motion command: apply MOTION (a NAVI-MOVE key) and redisplay."
  `(define-navi-command (,key ,@words) ,docstring
     (navi-move state ,motion)
     (setf (navi-state-redraw state) t)
     nil))

(define-navi-motion (d down)      :down  "Descend into the selected node.")
(define-navi-motion (u up)        :up    "Ascend — sub-form -> form -> file -> directory.")
(define-navi-motion (|>| next)    :next  "Select the next sibling (code positions only).")
(define-navi-motion (|<| previous) :prev "Select the previous sibling.")
(define-navi-motion (|<<| first)  :first "Select the first sibling.")
(define-navi-motion (|>>| last)   :last  "Select the last sibling.")
(bind-command-alias *navi-commands* "enter" "d")

(define-navi-command (skip) "skip ±N: move N siblings forward (+) or back (-)."
  (let ((count (and arg (ignore-errors (parse-integer arg)))))
    (if count
        (progn (navi-move state :skip count)
               (setf (navi-state-redraw state) t))
        (out ui "NAV> skip needs a signed count (±N)~%")))
  nil)

(define-navi-command (b) "Set a breakpoint on the selected form; `b LOC' is the debugger's break."
  ;; bare `b' breakpoints the selection; with an argument it is the
  ;; debugger's break (as when it falls through the stacked dictionaries)
  (if arg
      (funcall (command-function (find-command *aldo-commands* "b")) arg)
      (progn (nav-set-breakpoint ui session loc)
             (setf (navi-state-redraw state) t)
             nil)))

(define-navi-command (q quit) "Leave the navigator."
  (pop-interactor)
  nil)

(define-navi-command (h help) "The motions plus the stacked debugger dictionary."
  (nav-help ui)                                 ; output only: no re-render
  nil)
(bind-command-alias *navi-commands* "?" "h")

;; The editing words (§1.3): each opens the sedit structural editor on the
;; selected form, performing itself as the first editing command (spec §7).
(dolist (word +nav-editing-words+)
  (bind-command *navi-commands* (list word) '(&whole arg)
                (format nil "~A: open the sedit structural editor on the form." word)
                (let ((word word))
                  (lambda (arg)
                    (let* ((state (%navi-state))
                           (ui (navi-state-ui state)))
                      (nav-edit-session ui (navi-state-session state)
                                        (navi-state-hit state)
                                        (navi-state-loc state) word arg)
                      (setf (navi-state-redraw state) t)
                      nil)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; LAVI — the flat line navigator's vocabulary (`set navigator line').

(setf *lavi-commands* (clautolisp.interactor:make-command-dictionary "lavi"))

(defmacro define-lavi-command ((key &rest words) docstring &body body)
  "Register a line-navigator command in *LAVI-COMMANDS*. BODY sees STATE (the
LAVI-STATE) and ARG."
  `(bind-command *lavi-commands*
                 (list ',key ,@(mapcar (lambda (w) `',w) words))
                 '(&whole arg) ,docstring
                 (lambda (arg)
                   (declare (ignorable arg))
                   (let ((state (%lavi-state)))
                     (declare (ignorable state))
                     ,@body))))

(define-lavi-command (d down) "Next poll-point line."
  (lavi-skip state 1) nil)
(define-lavi-command (u up) "Previous poll-point line."
  (lavi-skip state -1) nil)
(define-lavi-command (|<<| first) "First poll-point line."
  (lavi-skip state most-negative-fixnum) nil)
(define-lavi-command (|>>| last) "Last poll-point line."
  (lavi-skip state most-positive-fixnum) nil)
(define-lavi-command (skip) "skip ±N: move N lines forward (+) or back (-)."
  (let ((count (and arg (ignore-errors (parse-integer arg)))))
    (if count
        (lavi-skip state count)
        (out (lavi-state-ui state) "NAV> skip needs a signed count (±N)~%")))
  nil)
(define-lavi-command (q quit) "Leave the line navigator."
  (pop-interactor) nil)
(bind-command-alias *lavi-commands* ">" "d")
(bind-command-alias *lavi-commands* "<" "u")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; INSPECT — the inspector's vocabulary (spec §18.2).
;;;
;;; The §8 stacked-dispatch example: the inspector's =b= is its own =bind=,
;;; shadowing the global =break=; every unshadowed debugger verb remains
;;; directly reachable while inspecting.

(setf *inspi-commands* (clautolisp.interactor:make-command-dictionary "inspect"))

(defmacro define-inspi-command ((key &rest words) docstring &body body)
  "Register an inspector command in *INSPI-COMMANDS*. BODY sees STATE (the
INSPI-STATE), UI, SESSION and ARG."
  `(bind-command *inspi-commands*
                 (list ',key ,@(mapcar (lambda (w) `',w) words))
                 '(&whole arg) ,docstring
                 (lambda (arg)
                   (declare (ignorable arg))
                   (let* ((state (%inspi-state))
                          (ui (inspi-state-ui state))
                          (session (inspi-state-session state)))
                     (declare (ignorable ui session))
                     ,@body))))

(define-inspi-command (q quit) "Leave the inspector (a blank line too)."
  (pop-interactor)
  nil)

(define-inspi-command (u up) "Ascend to the containing value."
  (cmd-inspector-up session)
  nil)

(define-inspi-command (p path) "Copy the path expression to the selection."
  (print-path ui session)
  nil)

(define-inspi-command (d descend) "d N: descend into component N."
  (if arg
      (descend ui session arg)
      (out ui "INSPECT> d needs a component number~%"))
  nil)

(define-inspi-command (e eval) "e FORM: evaluate FORM ($ is the selection); a bare (FORM) evaluates too."
  (if arg
      (inspector-eval ui session arg)
      (out ui "INSPECT> e needs a form~%"))
  nil)

(define-inspi-command (b bind) "b $|NAME: bind the selection in the workspace."
  (if arg
      (inspector-bind ui session arg)
      (out ui "INSPECT> b needs $ or a name~%"))
  nil)
