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

(define-aldo-command (v visit) "visit EXPR: inspect EXPR (the inspector sub-REPL)."
  (inspector-loop ui session arg)
  nil)

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
