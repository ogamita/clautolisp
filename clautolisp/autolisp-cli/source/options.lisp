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
  ;; Dialect + host
  (dialect          :strict)          ; AC  :strict / :autocad-2026 / :bricscad-v26 / :clautolisp
  (host             :mock)            ; AC  :mock / :null (default :mock)
  ;; Encoding
  (load-encoding    nil)              ; AC  -e ENC (string)
  (io-encoding      nil)              ; AC  -E ENC (string)
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
  (dry-run-p        nil)              ; A
  (no-init-p        nil)              ; AC
  (no-color-p       nil)              ; AC
  (keep-workdir-p   nil)              ; A
  ;; Clautolisp-only
  (mock-input       nil)              ; C   --mock-input PATH (string)
  (gui              nil)              ; C   --gui CMD          (string)
  (trace-p          nil)              ; C   --trace
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
  (cond ((string-equal value "mock") :mock)
        ((string-equal value "null") :null)
        ((string-equal value "none") :null)
        (t (error 'cli-usage-error
                  :option option
                  :message
                  (format nil "Unknown --host ~S (expected mock/null)" value)))))

(defun parse-dialect (value option)
  "Validate a --dialect VALUE against the reader's dialect registry
(strict / autocad-2022 / autocad-2026 / autocad / bricscad-v25 /
bricscad-v26 / bricscad / clautolisp / lax; an unversioned vendor name
maps to the last known version) and return it as a keyword. The keyword
is resolved to a descriptor downstream by FIND-AUTOLISP-DIALECT, so
aliases stay aliases here."
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
