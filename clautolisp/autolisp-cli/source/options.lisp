(in-package #:clautolisp.autolisp-cli)

;;;; Union cli-options struct shared by clautolisp and alfe.
;;;;
;;;; Both tools instantiate the same struct; each consults only the
;;;; slots that match the options it accepts. Slots tagged below
;;;; with `A` are alfe-only (clautolisp ignores them), `C` are
;;;; clautolisp-only (alfe ignores them), `AC` are common. The
;;;; parser's option-spec list decides which options are actually
;;;; recognised on a given tool's CLI — slots stay at their default
;;;; when the tool doesn't expose the matching option.

(defstruct cli-options
  ;; Action queue + positional args
  (actions          nil :type list)   ; AC  ((:file . PATH)/(:expression . TEXT)/(:main . FN)/(:interactive . T)/(:quit . T))
  (positional       nil :type list)   ; AC  positional FILE args, in source order
  ;; Backend + mode (alfe)
  (backend          nil)              ; A   :clautolisp / :bricscad / :autocad
  (mode             :auto)            ; A   :auto / :automation / :batch
  (backend-variant  nil)              ; A   :attach / :launch / :direct / :subprocess
  (cad              nil)              ; A   --cad DENOTATION (alfe backend selection)
  ;; Dialect + host
  (dialect          :strict)          ; AC  :strict / :autocad-2026 / :bricscad-v26 / :clautolisp
  (host             :mock)            ; AC  :mock / :null (default :mock)
  ;; Encoding
  (load-encoding    nil)              ; AC  = the `source' situation (-Esource); mirrored for downstream
  (io-encoding      nil)              ; AC  = the `terminal' situation (-Eterminal); mirrored for downstream
  (situation-encodings nil)           ; AC  alist (KEY . canonical-enc): KEY = "all" | "<situation>" | "<situation>/<dir>"
                                      ;     built by the -E<situation>[-<dir>] / --<situation>-encoding family
  ;; Drawing + plugin
  (dwg              nil)              ; A
  (epure-p          nil)              ; A
  ;; Bootstrap
  (bootstrap-phase  :full)            ; A   :marker / :core / :log / :full
  ;; REPL + lifecycle
  (interactive-p    nil)              ; AC
  (quit-p           nil)              ; A
  (main             nil)              ; A   symbol name (string)
  ;; Misc
  (workdir          nil)              ; A
  (timeout          nil)              ; A   positive integer
  (verbosity        :info)            ; AC  :debug / :verbose / :info / :warn
  (help-p           nil)              ; AC
  (version-p        nil)              ; AC
  (list-encodings-p nil)              ; AC  --list-encodings
  (list-dialects-p  nil)              ; AC  --list-dialects
  (list-situations-p nil)             ; AC  --list-situations
  (list-cad-programs-p nil)           ; AC  --list-cad-programs (alfe)
  (dry-run-p        nil)              ; A
  (print-command-p  nil)              ; A   --print-command: stage the workdir as
                                      ;     usual, print the CAD command line that
                                      ;     WOULD be launched, then exit without
                                      ;     launching. Unlike --dry-run (which
                                      ;     resolves nothing and touches no disk),
                                      ;     this needs a real backend and a real
                                      ;     workdir, so the printed argv is the
                                      ;     exact one alfe would spawn.
  (no-init-p        nil)              ; AC
  (no-color-p       nil)              ; AC
  (keep-workdir-p   nil)              ; A
  (write-workdir-path nil)            ; A   --write-workdir-path FILE: after the
                                      ;     workdir is prepared, write its
                                      ;     absolute path to FILE (for CI to
                                      ;     locate a --keep-workdir workdir).
  ;; Clautolisp-only
  (mock-input       nil)              ; C   --mock-input PATH (string)
  (gui              nil)              ; C   --gui CMD          (string)
  (dcl              :auto)            ; C   --dcl tui|gui|auto — DCL renderer selection
  (trace-p          nil)              ; C   --trace
  ;; --optimize / -O: the accumulated ((QUALITY . LEVEL) …) pairs, in the
  ;; order written. NIL = the option was never given, which is NOT the same
  ;; as "all qualities at 0": an absent option must leave every level alone.
  (optimization     nil)              ; C   --optimize / -O QUALITY=N,…
  ;; Dribble (dribble.issue; clautolisp today, alfe planned)
  (dribble          nil)              ; C   --dribble / --dribble=FILE → t / FILE (string)
  (dribble-interactors nil)           ; C   --dribble-interactors=IS → :all / list of name strings
  ;; Debugger (clautolisp-only): event policies + UI selection (debugger §10,
  ;; debugger-public-interface-and-on-error.issue Parts B-D)
  (on-error         nil)              ; C   --on-error quit|debug|ignore     → :quit/:debug/:ignore
  (on-interrupt     nil)              ; C   --on-interrupt debug|ignore|quit → :debug/:ignore/:quit
  (on-quit          nil)              ; C   --on-quit debug|quit             → :debug/:quit
  (user-interface   nil)              ; C   --debugger-ui tui|ncurses|aldb   → :tui/:ncurses/:aldb
  (aldb-address     nil)              ; C   --aldb-listen [HOST:]PORT — the HOST part (string)
  (aldb-port        nil)              ; C   --aldb-listen [HOST:]PORT — the PORT part (integer or service-name string)
  (aldb-stdio-p     nil))             ; C   --aldb-stdio → t

;;; --- value parsers ----------------------------------------------------
;;;
;;; Each parser converts an option-value string to a tool-neutral
;;; keyword. The tool's downstream code resolves the keyword to its
;;; runtime type (e.g. clautolisp turns :strict into an
;;; autolisp-dialect descriptor; alfe stores the keyword as-is).

(defun parse-mode (value option)
  (cond ((string-equal value "auto")       :auto)
        ((string-equal value "automation") :automation)
        ((string-equal value "batch")      :batch)
        (t (error 'cli-usage-error
                  :option option
                  :message
                  (format nil "Unknown mode ~S (expected auto/automation/batch)" value)))))

(defun parse-backend-symbol (value option)
  (cond ((string-equal value "clautolisp") :clautolisp)
        ((string-equal value "bricscad")   :bricscad)
        ((string-equal value "autocad")    :autocad)
        ((string-equal value "echo")       :echo) ; tests only
        (t (error 'cli-usage-error
                  :option option
                  :message (format nil "Unknown backend ~S" value)))))

(defun parse-backend-variant (value option)
  (cond ((string-equal value "attach")     :attach)
        ((string-equal value "launch")     :launch)
        ((or (string-equal value "direct")
             (string-equal value "in-process"))  :direct)
        ((string-equal value "subprocess") :subprocess)
        (t (error 'cli-usage-error
                  :option option
                  :message
                  (format nil "Unknown --backend variant ~S (expected attach/launch/direct/subprocess)"
                          value)))))

(defun parse-host (value option)
  ;; cador = the headless CAD core (was named "mock"); null = the trivial
  ;; backend. "mock" is kept as a deprecated alias of cador.
  (cond ((string-equal value "cador") :cador)
        ((string-equal value "mock") :cador)
        ((string-equal value "nihil") :nihil)
        ((string-equal value "null") :null)
        ((string-equal value "none") :null)
        (t (error 'cli-usage-error
                  :option option
                  :message
                  (format nil "Unknown --host ~S (expected cador/nihil; mock=alias of cador, null/none=aliases of nihil)" value)))))

(defun parse-dialect (value option)
  "Validate a --dialect VALUE against the reader's dialect registry and
return it as a keyword. Accepted: the enumerated names (strict /
autocad-2022 / autocad-2026 / autocad / autocad-mac / bricscad-v25 /
bricscad-v26 / bricscad / bricscad-mac / bricscad-linux / clautolisp /
lax) AND derived platform+version spellings — a product optionally
suffixed with a platform (`-mac' / `-linux', windows being the default)
and/or a version (autocad-2027, autocad-mac-2027, bricscad-mac-v26).
An unversioned vendor name maps to the last known version; an
unqualified platform means windows. The keyword is resolved to a
descriptor downstream by FIND-AUTOLISP-DIALECT, so aliases stay aliases
here (dialect-platform-version-axis.issue)."
  (if (clautolisp.autolisp-reader:find-autolisp-dialect value)
      (intern (string-upcase value) :keyword)
      (error 'cli-usage-error
             :option option
             :message (format nil "Unknown dialect ~S (see --list-dialects)"
                              value))))

(defun print-dialects (&optional (stream *standard-output*))
  "Print every dialect name accepted by --dialect, one per line, in
canonical order (strict first, lax last; an unversioned vendor name
maps to the last known version). Drives the --list-dialects action and
is shell-loop friendly: `for d in $(clautolisp --list-dialects); do …`."
  (dolist (name (clautolisp.autolisp-reader:autolisp-dialect-names))
    (write-line name stream)))

(defun parse-bootstrap-phase (value option)
  (cond ((string-equal value "marker") :marker)
        ((string-equal value "core")   :core)
        ((string-equal value "log")    :log)
        ((string-equal value "full")   :full)
        (t (error 'cli-usage-error
                  :option option
                  :message (format nil "Unknown bootstrap phase ~S" value)))))

(defun parse-timeout (value option)
  (let ((parsed (parse-integer value :junk-allowed t)))
    (unless (and parsed (plusp parsed))
      (error 'cli-usage-error
             :option option
             :message
             (format nil "Timeout must be a positive integer (got ~S)" value)))
    parsed))

;;; --- debugger option parsers (debugger §10, ---------------------------
;;; debugger-public-interface-and-on-error.issue Parts B-D)

(defun %parse-event-policy (value option allowed)
  "Shared body of the --on-<event> POLICY parsers: VALUE names one of the
ALLOWED policy keywords (case-insensitive); anything else is a
cli-usage-error naming OPTION."
  (or (find value allowed :test #'string-equal :key #'symbol-name)
      (error 'cli-usage-error
             :option option
             :message
             (format nil "Unknown ~A policy ~S (expected ~{~(~A~)~^/~})"
                     option value allowed))))

(defun parse-on-error (value option)
  "The --on-error policy: quit (abort the program), debug (break into the
debugger), or ignore (let the user *error* / default handler run)."
  (%parse-event-policy value option '(:quit :debug :ignore)))

(defun parse-on-interrupt (value option)
  "The --on-interrupt policy: debug (break into the debugger at the interrupt
point), ignore (the interrupt is ignored), or quit (the process quits)."
  (%parse-event-policy value option '(:debug :ignore :quit)))

(defun parse-on-quit (value option)
  "The --on-quit policy: quit (the process quits — the default) or debug (the
debugger is entered from QUIT before unwinding). The QUIT event cannot be
ignored (debugger-public-interface-and-on-error.issue Part B)."
  (%parse-event-policy value option '(:quit :debug)))

(defun parse-aldb-listen (value option)
  "Parse the --aldb-listen [HOST:]PORT value into (values HOST PORT): a bare
PORT leaves HOST nil (the 127.0.0.1 default applies downstream); HOST:PORT
splits at the LAST colon so a bracketed IPv6 literal ([::1]:4301) works —
the brackets are stripped. PORT is validated: a decimal integer must be in
0..65535 (0 = pick a free port); anything else non-empty is kept as a
service-name string."
  (let* ((value (string value))
         (colon (position #\: value :from-end t))
         (host (and colon (string-trim "[]" (subseq value 0 colon))))
         (port-string (if colon (subseq value (1+ colon)) value)))
    (when (and colon (zerop (length host)))
      (error 'cli-usage-error
             :option option
             :message (format nil "~A got an empty HOST in ~S (expected [HOST:]PORT)"
                              option value)))
    (when (zerop (length port-string))
      (error 'cli-usage-error
             :option option
             :message (format nil "~A got an empty PORT in ~S (expected [HOST:]PORT)"
                              option value)))
    (multiple-value-bind (n end) (parse-integer port-string :junk-allowed t)
      (let ((port (if (and n (= end (length port-string)))
                      (if (<= 0 n 65535)
                          n
                          (error 'cli-usage-error
                                 :option option
                                 :message
                                 (format nil "~A port ~D is out of range 0..65535"
                                         option n)))
                      port-string)))    ; a service name
        (values host port)))))

(defun parse-dribble-interactors (value option)
  "The --dribble-interactors=IS value (dribble.issue): `t' (any case) means
every interactor (:ALL); otherwise IS is a comma-separated list of interactor
names/aliases, yielding the list of name strings."
  (cond ((or (null value) (zerop (length value)))
         (error 'cli-usage-error
                :option option
                :message
                (format nil "~A needs a value: t, or a comma-separated list of interactor names" option)))
        ((string-equal value "t") :all)
        (t (let ((names '()) (start 0))
             (loop
               (let ((comma (position #\, value :start start)))
                 (let ((name (string-trim " " (subseq value start comma))))
                   (when (plusp (length name))
                     (push name names)))
                 (unless comma (return))
                 (setf start (1+ comma))))
             (unless names
               (error 'cli-usage-error
                      :option option
                      :message
                      (format nil "~A got no interactor names in ~S" option value)))
             (nreverse names)))))

(defun parse-dcl-mode (value option)
  "The --dcl DCL-renderer selection: tui (force the terminal / command-line
form — the clautolisp spelling of AutoCAD's `-command' convention), gui (the
subprocess GUI renderer), or auto (GUI when a driver is configured and stdout
is a TTY, otherwise the TUI — so every headless / piped run gets the TUI).
`terminal' / `text' are accepted spellings of tui."
  (cond ((or (string-equal value "tui")
             (string-equal value "terminal")
             (string-equal value "text")) :tui)
        ((string-equal value "gui")  :gui)
        ((string-equal value "auto") :auto)
        (t (error 'cli-usage-error
                  :option option
                  :message
                  (format nil "Unknown --dcl mode ~S (expected tui/gui/auto)" value)))))

(defun parse-user-interface (value option)
  "The --debugger-ui selection: tui (the line/terminal UI; `terminal' and
`dumb' are accepted spellings), ncurses, or aldb (the Emacs front-end;
`emacs' is an accepted spelling)."
  (cond ((string-equal value "tui")     :tui)
        ((or (string-equal value "terminal") (string-equal value "dumb")) :tui)
        ((string-equal value "ncurses") :ncurses)
        ((or (string-equal value "aldb") (string-equal value "emacs")) :aldb)
        (t (error 'cli-usage-error
                  :option option
                  :message
                  (format nil "Unknown ~A value ~S (expected tui/ncurses/aldb)"
                          option value)))))

;;; --- --optimize / -O --------------------------------------------------
;;;
;;; The CLI spelling of AutoLISP's (CLAL-OPTIMIZE '((SPEED 3) …)).
;;;
;;; The option exists because the AutoLISP surface cannot reach the moment
;;; that matters most. In Common Lisp a DECLAIM in a file changes the
;;; qualities for the rest of that file, because DECLAIM is a macro with a
;;; compilation-time side effect. AutoLISP has neither macros nor a
;;; distinction between compilation-time, load-time and run-time effects, so
;;; a (CLAL-OPTIMIZE …) at the top of a .lsp takes effect only once that call
;;; is EVALuated -- by which time the file it was meant to govern has already
;;; been read and its DEFUNs already built. Nothing inside the language can
;;; set the qualities BEFORE the first file is loaded; the command line can.
;;;
;;; The grammar mirrors CLAL-OPTIMIZE's rather than inventing a second
;;; vocabulary for the same thing:
;;;
;;;   QUALITY=N   set QUALITY (debug/space/speed) to level N (0..3)
;;;   QUALITY     the quality at level 3   (= CLAL-OPTIMIZE's bare symbol)
;;;   N           shorthand for speed=N    (`-O2' reads as it does everywhere)
;;;
;;; Several specifiers may be comma-separated, and the option may be repeated;
;;; both accumulate left to right, and a quality never mentioned keeps the
;;; level it had. So `-O speed=3 -O debug=0' and `-O speed=3,debug=0' are the
;;; same request, and neither says anything about SPACE.
;;;
;;; The result is the pairs, not the effect: this package must not know what a
;;; level MEANS (that algebra lives in one place, APPLY-CLAL-OPTIMIZATION in
;;; the builtins), and alfe links against this parser without linking against
;;; the AutoLISP runtime at all.

(defparameter *optimization-qualities* '(("debug" . :debug)
                                         ("space" . :space)
                                         ("speed" . :speed))
  "The quality names accepted by --optimize, mapped to their keywords. The
same three CLAL-OPTIMIZE accepts, deliberately: one vocabulary, two spellings.")

(defun %parse-optimization-level (text option specifier)
  "Parse TEXT as an optimization level 0..3, or signal a CLI-USAGE-ERROR
naming OPTION and the offending SPECIFIER."
  (multiple-value-bind (n end) (parse-integer text :junk-allowed t)
    (unless (and n (= end (length text)) (<= 0 n 3))
      (error 'cli-usage-error
             :option option
             :message (format nil "~A got a bad level in ~S (expected an integer 0..3)"
                              option specifier)))
    n))

(defun %parse-optimization-specifier (specifier option)
  "Parse one --optimize specifier into (QUALITY . LEVEL)."
  (let* ((equals (position #\= specifier))
         (name   (string-trim " " (if equals (subseq specifier 0 equals) specifier)))
         (level  (and equals (string-trim " " (subseq specifier (1+ equals))))))
    (cond
      ;; QUALITY=N
      (equals
       (let ((quality (cdr (assoc name *optimization-qualities* :test #'string-equal))))
         (unless quality
           (error 'cli-usage-error
                  :option option
                  :message (format nil "Unknown optimization quality ~S in ~S (expected debug, space or speed)"
                                   name specifier)))
         (cons quality (%parse-optimization-level level option specifier))))
      ;; QUALITY -- level 3, as a bare symbol means in CLAL-OPTIMIZE.
      ((assoc name *optimization-qualities* :test #'string-equal)
       (cons (cdr (assoc name *optimization-qualities* :test #'string-equal)) 3))
      ;; N -- speed=N.
      ((and (plusp (length name)) (every #'digit-char-p name))
       (cons :speed (%parse-optimization-level name option specifier)))
      (t
       (error 'cli-usage-error
              :option option
              :message (format nil "Unknown --optimize specifier ~S (expected QUALITY, QUALITY=N or N)"
                               specifier))))))

(defun parse-optimize (value option)
  "The --optimize / -O value: a comma-separated list of specifiers, yielding
a list of (QUALITY . LEVEL) pairs in the order written."
  (when (or (null value) (zerop (length (string-trim " " value))))
    (error 'cli-usage-error
           :option option
           :message (format nil "~A needs a value: QUALITY, QUALITY=N or N (0..3)" option)))
  (let ((pairs '()) (start 0))
    (loop
      (let* ((comma (position #\, value :start start))
             (specifier (string-trim " " (subseq value start comma))))
        (when (plusp (length specifier))
          (push (%parse-optimization-specifier specifier option) pairs))
        (unless comma (return))
        (setf start (1+ comma))))
    (unless pairs
      (error 'cli-usage-error
             :option option
             :message (format nil "~A got no specifiers in ~S" option value)))
    (nreverse pairs)))
