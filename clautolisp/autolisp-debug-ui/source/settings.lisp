;;;; aldo debugger settings / configuration core.
;;;;
;;;; Implements the configuration model of the command reference §8
;;;; "Configuration and persistence": the per-session settings, their
;;;; XDG-located persistence (aldo.conf), and the set / list machinery the
;;;; `set NAME VALUE` and `,settings` commands drive.  This is the headless,
;;;; UI-agnostic core; the AutoLISP-facing *clal-aldo-configuration* variable
;;;; and the clal-load/save-aldo-configuration builtins mirror this store (a
;;;; later wiring step).
;;;;
;;;; The store is an association list of (KEY . VALUE): keys and symbolic
;;;; (enumeration) values are normalised to keywords so lookup and the `set`
;;;; command are case-insensitive (command reference §8); sizes are integers,
;;;; flags are T / NIL, the listening address is a string, the port an integer
;;;; or a service-name string.  On disk aldo.conf is a plain sexp with bare,
;;;; lower-case symbols (AutoLISP-friendly, UTF-8); a glyph anywhere may be a
;;;; literal string or a list of integer code points (so the file can stay
;;;; ASCII).  The settings left at their default are written out too, but
;;;; commented, so the file documents what may be edited into it — see
;;;; WRITE-CONFIGURATION-FILE.

(in-package #:clautolisp.debug.ui)

;;; ---------------------------------------------------------------------------
;;; Defaults and the per-key specification (type, allowed values)

(defparameter *default-aldo-configuration*
  '((:navigator . :sexp)
    (:directory-listing . :short)
    (:directory-window . 0)
    (:navigation-history-max . 1000)
    (:sedit-on-quit . :ask)
    (:break-on-caught . nil)
    (:source-window-height . 24)
    (:value-line-width . 72)
    (:pager . :on)
    (:pager-height . 24)
    (:theme . :unicode)
    (:default-user-interface . :tui)
    (:default-aldb-listening-address . "127.0.0.1")
    ;; 0 = an OS-chosen FREE port (aldb-stdio-is-a-poor-default): a random free
    ;; port never clashes with another session, and the actual port is printed in
    ;; the connect prompt. Pin a fixed port here if you prefer a stable one.
    (:default-aldb-listening-port . 0)
    (:decorations
     (:current-pp  :unicode (9205))   ; PREFIX  ⏵ U+23F5 as a code-point list
     (:current-pp  :ascii   ">")
     (:enabled-bp  :unicode (9208))   ; ⏸ U+23F8
     (:enabled-bp  :ascii   "^")
     (:disabled-bp :unicode (9199))   ; ⏯ U+23EF
     (:disabled-bp :ascii   "_")
     (:selection   :unicode (12304) (12305)) ; OPEN 【 / CLOSE 】
     (:selection   :ascii   "[" "]")))
  "The built-in default aldo configuration (command reference §8). An
association list of (KEY . VALUE); see *SETTING-SPECS* for the scalar settings'
types and the :DECORATIONS sub-list for the theme glyphs.")

(defparameter *setting-specs*
  '((:navigator               :enum (:sexp :line))
    (:directory-listing       :enum (:long :column :short))
    (:directory-window        :integer)
    (:navigation-history-max  :integer)
    (:sedit-on-quit           :enum (:auto-save :do-not-save :ask))
    (:break-on-caught         :boolean)
    (:source-window-height    :integer)
    (:value-line-width        :integer)
    (:pager                   :enum (:on :off))
    (:pager-height            :integer)
    (:theme                   :enum (:unicode :ascii :white-on-black
                                     :black-on-white :green-on-black :attributes))
    (:default-user-interface  :enum (:tui :ncurses :aldb))
    (:default-aldb-listening-address :string)
    (:default-aldb-listening-port    :port))
  "For each scalar setting: (KEY TYPE [ALLOWED]). TYPE drives `set' value
parsing and validation. :DECORATIONS is structural (edited as data, not via
`set'), so it is not listed here.")

;;; --------------------------------------------------------------------------
;;; The LISP (REPL) interactor's own settings — lisp-configuration.issue
;;;
;;; pjb's point-6 answer in interactor-design-revision.issue: the REPL
;;; interactor needs its own persistent configuration, and configurations
;;; STACK the way interactors do — at the REPL only lisp.conf is active; in
;;; the debugger both are, aldo OVER lisp, so a setting absent from aldo.conf
;;; but present in lisp.conf is taken from lisp.conf.

(defparameter *default-lisp-configuration*
  '((:sedit-on-quit . :ask)
    (:shell-escape-character . #\!))
  "Built-in defaults for the LISP (REPL) interactor. Its first setting is
:SEDIT-ON-QUIT — the same key aldo carries, governing (clal-sedit …)
invocations made from the REPL while aldo's governs debugger-side ones.

:SHELL-ESCAPE-CHARACTER is the bang.issue escape: a line starting with it
goes to $SHELL. It belongs to the LISP interactor (pjb, 2026-08-15), and
the other interactors inherit it through the ordinary stacking rule — a
key absent from aldo.conf is taken from lisp.conf.")

(defparameter *lisp-setting-specs*
  '((:sedit-on-quit :enum (:auto-save :do-not-save :ask))
    (:shell-escape-character :character))
  "(KEY TYPE [ALLOWED]) for the LISP interactor's settings; same shape as
*SETTING-SPECS*.")

;;; --------------------------------------------------------------------------
;;; Layers
;;;
;;; Each configuration variable holds ONLY the settings explicitly set — by
;;; `set', or by loading a conf file. The built-in defaults are a third,
;;; bottom layer consulted at lookup time.
;;;
;;; This is option (b) of lisp-configuration.issue, and it is what makes the
;;; stacking work at all: the aldo-over-lisp fall-through needs "present in
;;; aldo.conf" to be distinguishable from "aldo's built-in default". While the
;;; store was SEEDED from the defaults (as it was before), every common key
;;; always looked present on the aldo layer and the lisp layer could never be
;;; reached from DBG>. Tracking explicitly-set keys in a set alongside the
;;; alist — option (a) — would work too, but it keeps two structures in step
;;; where one suffices.
;;;
;;; One visible consequence, and the reason this is worth stating: SAVE now
;;; writes only what was explicitly set, so aldo.conf becomes a diff against
;;; the defaults rather than a full dump. Reading an old full-dump conf still
;;; works — every key in it simply counts as explicit.

(defvar *aldo-configuration* nil
  "The EXPLICIT aldo settings (an alist of (KEY . VALUE)) — NOT seeded from
the defaults; see the Layers commentary above. Updated by `set' / CONFIG-SET;
(re)loaded from the XDG aldo.conf by LOAD-ALDO-CONFIGURATION; saved only on
request. Read it through CONFIG-GET / DEBUGGER-SETTING, which resolve the
defaults, rather than by ASSOC.")

(defvar *lisp-configuration* nil
  "The EXPLICIT LISP (REPL) interactor settings; the counterpart of
*ALDO-CONFIGURATION* for lisp.conf.")

(defun reset-aldo-configuration ()
  "Drop every explicitly-set aldo setting, leaving the built-in defaults in
effect."
  (setf *aldo-configuration* nil))

(defun reset-lisp-configuration ()
  "Drop every explicitly-set LISP-interactor setting."
  (setf *lisp-configuration* nil))

(reset-aldo-configuration)
(reset-lisp-configuration)

;;; ---------------------------------------------------------------------------
;;; Key / value normalisation (case-insensitive)

(defun normalize-config-key (key)
  "Normalise KEY (a string, symbol or keyword) to an upper-cased keyword."
  (intern (string-upcase (string key)) :keyword))

(defun config-explicit (key &optional (config *aldo-configuration*))
  "(values VALUE PRESENTP) for KEY in CONFIG's EXPLICIT layer only — no
default resolution. The predicate the stacking is built on."
  (let ((cell (assoc (normalize-config-key key) config)))
    (if cell (values (cdr cell) t) (values nil nil))))

(defun config-get (key &optional (config *aldo-configuration*)
                            (defaults *default-aldo-configuration*))
  "The value of KEY (case-insensitive): CONFIG's explicit setting if it has
one, else the built-in DEFAULTS, else NIL.

Every reader should come through here rather than ASSOC the alist directly —
since the store holds only explicit settings, a direct ASSOC now misses every
value the user has not overridden."
  (multiple-value-bind (value presentp) (config-explicit key config)
    (if presentp
        value
        (cdr (assoc (normalize-config-key key) defaults)))))

(defun %default-setting (key)
  "KEY's built-in default: aldo's table, else the LISP interactor's."
  (let ((k (normalize-config-key key)))
    (let ((cell (or (assoc k *default-aldo-configuration*)
                    (assoc k *default-lisp-configuration*))))
      (and cell (cdr cell)))))

(defun lisp-setting (key)
  "Resolve KEY for the LISP (REPL) interactor: at the REPL only lisp.conf is
active, so it is the explicit lisp setting, else the built-in default."
  (multiple-value-bind (value presentp) (config-explicit key *lisp-configuration*)
    (if presentp value (%default-setting key))))

(defun debugger-setting (key)
  "Resolve KEY inside the debugger: the ALDO layer over the LISP layer over
the built-in defaults (lisp-configuration.issue). A key the user set in
aldo.conf wins; a key they set only in lisp.conf is taken from there;
otherwise the built-in default applies.

The middle clause is the whole reason the layers hold only explicit settings:
were the aldo layer still seeded from the defaults, it could never be
reached."
  (multiple-value-bind (value presentp) (config-explicit key *aldo-configuration*)
    (if presentp
        value
        (multiple-value-bind (value presentp)
            (config-explicit key *lisp-configuration*)
          (if presentp value (%default-setting key))))))

(defun config-set (key value &optional (config *aldo-configuration*))
  "Set KEY to VALUE in CONFIG (default *ALDO-CONFIGURATION*), creating the pair
if needed. Returns the (possibly new) config; updates *ALDO-CONFIGURATION* in
place when CONFIG is it."
  (let* ((k (normalize-config-key key))
         (cell (assoc k config)))
    (cond (cell (setf (cdr cell) value) config)
          (t (let ((new (cons (cons k value) config)))
               (when (eq config *aldo-configuration*)
                 (setf *aldo-configuration* new))
               new)))))

(defun config-keys (&optional (config *aldo-configuration*))
  "The keys present in CONFIG, in order."
  (mapcar #'car config))

;;; ---------------------------------------------------------------------------
;;; The `set NAME VALUE' setter: parse + validate a textual value

(defun setting-spec (key &optional (specs *setting-specs*))
  (assoc (normalize-config-key key) specs))

(defun parse-setting-value (type raw &optional allowed)
  "Parse the textual RAW value for a setting of TYPE (with ALLOWED for :ENUM).
Signals a SIMPLE-ERROR on a bad value."
  (let ((raw (string-trim " " (string raw))))
    (ecase type
      (:enum
       (let ((kw (intern (string-upcase raw) :keyword)))
         (unless (member kw allowed)
           (error "value ~S is not one of ~{~(~A~)~^ | ~}" raw allowed))
         kw))
      (:integer
       (multiple-value-bind (n end) (parse-integer raw :junk-allowed t)
         (unless (and n (= end (length raw)))
           (error "value ~S is not an integer" raw))
         n))
      (:boolean
       (cond ((member raw '("on" "true" "t" "yes" "1") :test #'string-equal) t)
             ((member raw '("off" "false" "nil" "no" "0") :test #'string-equal) nil)
             (t (error "value ~S is not a boolean (on/off)" raw))))
      (:string raw)
      (:character
       ;; "ascii character or unicode code point" (pjb). Both spellings are
       ;; accepted, exactly as the :DECORATIONS glyphs accept either a
       ;; literal string or a list of code points — one convention in this
       ;; file, not two. A bare digit run is a code point, so a decimal
       ;; digit cannot be chosen as the escape by typing it; give its code
       ;; point instead, which is unambiguous.
       (let ((text (string-trim "\"" raw)))
         (cond
           ((and (plusp (length text))
                 (every #'digit-char-p text))
            (let ((code (parse-integer text)))
              (unless (and (<= 0 code) (< code char-code-limit))
                (error "code point ~D is out of range" code))
              (code-char code)))
           ((= 1 (length text)) (char text 0))
           (t (error "value ~S is not a single character or a code point" raw)))))
      (:port
       (multiple-value-bind (n end) (parse-integer raw :junk-allowed t)
         (if (and n (= end (length raw))) n raw))))))

(defun set-aldo-setting (name value-string &optional (config *aldo-configuration*))
  "Implement `set NAME VALUE': normalise NAME, validate/parse VALUE-STRING for
its setting type, and store it. Returns the stored value. Signals on an unknown
setting or an invalid value."
  (let ((spec (setting-spec name)))
    (unless spec
      (error "unknown setting ~S" (string-downcase (string name))))
    (destructuring-bind (key type &optional allowed) spec
      (let ((value (parse-setting-value type value-string allowed)))
        (config-set key value config)
        value))))

(defun get-aldo-setting (name &optional (config *aldo-configuration*))
  "The current value of setting NAME (case-insensitive) on the aldo layer,
with the built-in default resolved. NOTE: this is the single-layer read. Code
running inside the debugger should prefer DEBUGGER-SETTING, which also
consults the LISP layer as lisp-configuration.issue specifies."
  (config-get name config))

(defun set-lisp-setting (name value-string &optional (config *lisp-configuration*))
  "`,set NAME VALUE' at the REPL: the LISP-interactor counterpart of
SET-ALDO-SETTING. Writes go to the ACTIVE interactor's own configuration
(lisp-configuration.issue), so this always writes the LISP layer, never
aldo's — even for a key both define."
  (let ((spec (setting-spec name *lisp-setting-specs*)))
    (unless spec
      (error "unknown setting ~S" (string-downcase (string name))))
    (destructuring-bind (key type &optional allowed) spec
      (let ((value (parse-setting-value type value-string allowed)))
        (if (eq config *lisp-configuration*)
            (let ((cell (assoc (normalize-config-key key) *lisp-configuration*)))
              (if cell
                  (setf (cdr cell) value)
                  (push (cons (normalize-config-key key) value)
                        *lisp-configuration*)))
            (config-set key value config))
        value))))

(defun get-lisp-setting (name)
  "The current value of LISP-interactor setting NAME, defaults resolved."
  (lisp-setting name))

(defun setting-character (value)
  "VALUE as a CHARACTER, or NIL.

Accepts every spelling the setting's type admits, because the conf file
is hand-editable and all three are reasonable things to have typed:
a character (what `set' stores), a one-character string (=\"@\"=, the
spelling the annex shows), or an integer code point (=64=, the way to
name a character that is awkward to type). A value that is none of those
yields NIL rather than an error — a malformed escape character disables
the escape, it does not break the REPL."
  (typecase value
    (character value)
    (string (when (= 1 (length value)) (char value 0)))
    (integer (when (and (<= 0 value) (< value char-code-limit))
               (code-char value)))
    (t nil)))

(defun shell-escape-character-setting ()
  "The LISP interactor's shell-escape character (bang.issue), or NIL.

Read through LISP-SETTING, so `,set shell-escape-character …' takes
effect at once and the built-in default applies when nothing was set."
  (setting-character (lisp-setting :shell-escape-character)))

(defun %decoration-glyph->string (spec)
  "Turn a decoration glyph SPEC — a literal string or a list of Unicode code
points — into a string."
  (cond ((stringp spec) spec)
        ((and (consp spec) (every #'integerp spec)) (map 'string #'code-char spec))
        (t "")))

(defun aldo-decoration-glyph (name &optional (part :open) (config *aldo-configuration*))
  "The glyph string for decoration NAME (:current-pp / :enabled-bp /
:disabled-bp / :selection) under the current :theme — the :ascii variant for the
ascii theme, the :unicode variant otherwise (command reference §8 / TUI spec
decoration table). PART is :open (the glyph, or the opening 【 for :selection) or
:close (the closing 】 for :selection). NIL when the decoration is not configured."
  (let* ((theme (or (config-get :theme config) :unicode))
         (variant (if (eq theme :ascii) :ascii :unicode))
         (entry (find-if (lambda (e) (and (eq (first e) name) (eq (second e) variant)))
                         ;; CONFIG-GET, not ASSOC: the store holds only
                         ;; explicitly-set keys now, so a direct ASSOC would
                         ;; find no decorations at all until the user had
                         ;; overridden one — every glyph would come out blank.
                         (config-get :decorations config)))
         (spec (if (eq part :close) (fourth entry) (third entry))))
    (and spec (%decoration-glyph->string spec))))

(defun format-setting-value (value)
  "Render a setting VALUE for the `,settings' listing."
  (cond ((eq value t) "on")
        ((null value) "off")
        ((keywordp value) (string-downcase (symbol-name value)))
        (t (princ-to-string value))))

(defun aldo-settings-lines (&optional (config *aldo-configuration*))
  "A list of \"name = value\" strings for the scalar settings, for `,settings'."
  (loop :for (key) :in *setting-specs*
        :collect (format nil "~(~A~) = ~A"
                         key (format-setting-value (config-get key config)))))

(defun lisp-settings-lines ()
  "A list of \"name = value [(default)]\" strings for the LISP interactor's
settings, for the REPL's `,settings'. Marks which values are the user's and
which are still the built-in default — the distinction the layered store now
makes, and the one that tells you whether a setting will be shadowed inside
the debugger."
  (loop :for (key) :in *lisp-setting-specs*
        :collect (multiple-value-bind (value presentp)
                     (config-explicit key *lisp-configuration*)
                   (format nil "~(~A~) = ~A~:[ (default)~;~]"
                           key
                           (format-setting-value (if presentp value
                                                     (%default-setting key)))
                           presentp))))

;;; ---------------------------------------------------------------------------
;;; XDG path resolution (command reference §8 — Loading)

(defun %getenv (name)
  (let ((v (uiop:getenv name)))
    (if (and v (plusp (length v))) v nil)))

(defun xdg-config-home ()
  "$XDG_CONFIG_HOME, defaulting to ~/.config."
  (or (%getenv "XDG_CONFIG_HOME")
      (namestring (merge-pathnames ".config/" (user-homedir-pathname)))))

(defun xdg-config-dirs ()
  "The list of $XDG_CONFIG_DIRS entries (defaulting to /etc/xdg)."
  (let ((v (or (%getenv "XDG_CONFIG_DIRS") "/etc/xdg")))
    (loop :for part :in (uiop:split-string v :separator ":")
          :when (plusp (length part)) :collect part)))

(defun config-relative-path (&optional (name "aldo"))
  (make-pathname :directory '(:relative "clautolisp") :name name :type "conf"))

(defun config-save-path (&optional (name "aldo"))
  "Where SAVE writes: $XDG_CONFIG_HOME/clautolisp/NAME.conf."
  (merge-pathnames (config-relative-path name)
                   (uiop:ensure-directory-pathname (xdg-config-home))))

(defun config-load-path (&optional (name "aldo"))
  "Where LOAD reads from: the save path if it exists, else the first
clautolisp/NAME.conf found along $XDG_CONFIG_DIRS; NIL if none."
  (let ((home (config-save-path name)))
    (if (probe-file home)
        home
        (loop :for dir :in (xdg-config-dirs)
              :for path := (merge-pathnames (config-relative-path name)
                                            (uiop:ensure-directory-pathname dir))
              :when (probe-file path) :return path))))

(defun aldo-config-relative-path () (config-relative-path "aldo"))
(defun aldo-config-save-path () (config-save-path "aldo"))
(defun aldo-config-load-path () (config-load-path "aldo"))

(defun lisp-config-save-path () (config-save-path "lisp"))
(defun lisp-config-load-path () (config-load-path "lisp"))

;;; ---------------------------------------------------------------------------
;;; Sexp I/O — aldo.conf is an AutoLISP-friendly sexp of bare lower-case symbols

(defun %externalize (form)
  "Convert the internal config FORM (keyword keys/enums) to its external,
AutoLISP-friendly shape: keywords become bare lower-case symbols (printed as
tokens), everything else is kept.

The uninterned symbol keeps the keyword's UPPER-CASE name and is rendered
lower-case by *PRINT-CASE* at print time, rather than being built lower-case:
a symbol actually named \"navigator\" does not read back as itself under the
standard readtable, so PRIN1 has to write it |navigator|. That was invisible
while the file was only ever machine-written and machine-read — it stops being
invisible now that the file documents itself for hand editing."
  (cond ((keywordp form) (make-symbol (string-upcase (symbol-name form))))
        ((consp form) (cons (%externalize (car form)) (%externalize (cdr form))))
        (t form)))

(defun %internalize (form)
  "Inverse of %EXTERNALIZE: any symbol read from the file becomes a keyword (so
the store is case-insensitive), EXCEPT the booleans named T / NIL which map to
CL T / NIL — note the config is read in a package with no inherited symbols, so
\"t\" and \"nil\" are *not* CL:T / CL:NIL and must be matched by name; numbers,
strings and conses are preserved structurally."
  (cond ((null form) nil)
        ((eq form t) t)
        ((symbolp form)
         (let ((name (string-upcase (symbol-name form))))
           (cond ((string= name "NIL") nil)
                 ((string= name "T") t)
                 (t (intern name :keyword)))))
        ((consp form) (cons (%internalize (car form)) (%internalize (cdr form))))
        (t form)))

(defun %config-entry-string (entry)
  "ENTRY (a (KEY . VALUE) cell) printed in the file's external syntax.

A NIL value is written as an explicit `. nil' rather than left to print as the
end of the list — (break-on-caught) is correct but reads, to someone editing
the file, like a setting with its value missing."
  (let ((entry (if (null (cdr entry))
                   (cons (%externalize (car entry)) (make-symbol "NIL"))
                   entry))
        (*print-case* :downcase)
        (*print-readably* nil)
        (*print-gensym* nil)            ; uninterned symbols print bare, no #:
        (*print-pretty* t)
        (*print-right-margin* 72))
    (prin1-to-string (%externalize entry))))

(defun %prefix-lines (text prefix &optional (continuation prefix))
  "TEXT with PREFIX prepended to its first line and CONTINUATION to the rest —
so a pretty-printed multi-line entry can be commented out or indented as a
whole."
  (let ((lines (uiop:split-string text :separator (string #\Newline))))
    (format nil "~{~A~^~%~}"
            (loop :for line :in lines
                  :for first := t :then nil
                  :collect (concatenate 'string (if first prefix continuation) line)))))

(defun %setting-value-syntax (key specs)
  "A one-line description of the values setting KEY accepts, annotating the
commented-out defaults in a saved conf file. NIL for a key with no scalar spec
\(:DECORATIONS, which is edited as data).

Note this describes the FILE syntax, not `set''s: a boolean is written t / nil
here, because the file reader maps only those two symbols to booleans — an
\"off\" in the file would read back as the (true) symbol :OFF."
  (let ((spec (assoc (normalize-config-key key) specs)))
    (when spec
      (destructuring-bind (name type &optional allowed) spec
        (declare (ignore name))
        (ecase type
          (:enum      (format nil "~{~(~A~)~^ | ~}" allowed))
          (:integer   "an integer")
          (:boolean   "t | nil")
          (:string    "a string")
          (:character "one character, as \"x\" or a Unicode code point")
          (:port      "a port number, or a service name in a string"))))))

(defun write-configuration-file (stream config defaults specs
                                 &key (name "aldo.conf") (what "the aldo debugger")
                                      (save-command ",settings save"))
  "Write CONFIG to STREAM as the self-documenting sexp a conf file is.

The settings the user explicitly set are written as live data; every OTHER
known setting is then written commented out, at its built-in default value and
annotated with the values it accepts. That is what makes the file editable by
hand without the manual open beside it: it lists what exists, what it is
currently worth, and what may be put there (pjb's request).

Only the live entries are data — `;' comments are skipped by the reader, so
the file still reads back as exactly one form, and reads back as the same
configuration it was saved from. LOAD therefore does not turn the documented
defaults into explicit settings, which is what keeps the file a diff against
the defaults and keeps the aldo-over-lisp stacking working."
  ;; Everything written here stays ASCII: the settings themselves are kept
  ;; ASCII-representable on purpose (a glyph may be a list of code points
  ;; rather than a literal character), so the prose must not be what forces
  ;; the file to need a UTF-8 reader.
  (format stream ";;;; clautolisp ~A - the configuration of ~A.~%" name what)
  (format stream ";;;;~%")
  (format stream ";;;; One list of (name . value) settings, read at start-up.~%")
  (format stream ";;;; Only the settings you changed are stored.  The lines commented~%")
  (format stream ";;;; out below are at their built-in default: they are listed so you~%")
  (format stream ";;;; can see what exists -- uncomment one and edit its value to~%")
  (format stream ";;;; override it.  The accepted values follow each line.~%")
  (format stream ";;;;~%")
  (format stream ";;;; Saving (~A) rewrites this file; comments you~%" save-command)
  (format stream ";;;; add by hand are not kept.~%")
  (write-line "(" stream)
  (dolist (cell config)
    (write-line (%prefix-lines (%config-entry-string cell) " " "  ") stream))
  (let ((documented (remove-if (lambda (cell)
                                 (nth-value 1 (config-explicit (car cell) config)))
                               defaults)))
    (when documented
      (when config (terpri stream))
      (write-line " ;; Defaults -- uncomment a line to set it." stream)
      (dolist (cell documented)
        (let ((syntax (%setting-value-syntax (car cell) specs)))
          (if syntax
              (format stream " ;;~A~36T; ~A~%"
                      (%config-entry-string cell) syntax)
              ;; No scalar spec: a structural setting, printed over as many
              ;; lines as it takes, every one of them commented out.
              (write-line (%prefix-lines (%config-entry-string cell) " ;;" " ;;  ")
                          stream))))))
  (write-line ")" stream))

;;; --- cascade bridge hooks (windows-and-interactor-templates.issue) ------
;;; A layer that also owns the tui-core cascade configs (faces / bindings /
;;; layout) installs these so the cascade SHARES the existing <name>.conf files
;;; rather than a parallel set. Unset (the default), the files are written and
;;; read exactly as before — this system does not depend on tui-core.

(defvar *config-extra-entries-hook* nil
  "(function (config-name)) -> an alist of extra (KEY . VALUE) entries to WRITE
into <config-name>.conf beside the scalar settings — the tui-core cascade's
:faces / :bindings / :layout. NIL writes only the scalar settings.")

(defvar *config-consume-extras-hook* nil
  "Inverse of *CONFIG-EXTRA-ENTRIES-HOOK*: (function (config-name loaded-alist))
-> the SCALAR-ONLY alist to store, having distributed the cascade keys into the
tui-core config. NIL returns LOADED-ALIST unchanged.")

(defun %config-with-extras (name config)
  "CONFIG plus the cascade's extra entries for NAME (via the hook); CONFIG
unchanged when no hook is installed."
  (append config (and *config-extra-entries-hook*
                      (funcall *config-extra-entries-hook* name))))

(defun %config-consume-extras (name alist)
  "Hand ALIST to the consume hook (which absorbs the cascade keys and returns
the scalar-only remainder); ALIST unchanged when no hook is installed."
  (if *config-consume-extras-hook*
      (funcall *config-consume-extras-hook* name alist)
      alist))

(defun write-aldo-configuration (stream &optional (config *aldo-configuration*))
  "Write CONFIG to STREAM as aldo.conf (see WRITE-CONFIGURATION-FILE); includes
the cascade's aldo faces/bindings when the bridge hook is installed."
  (write-configuration-file stream (%config-with-extras "aldo" config)
                            *default-aldo-configuration* *setting-specs*
                            :name "aldo.conf" :what "the aldo debugger"
                            :save-command ",settings save"))

(defun write-lisp-configuration (stream &optional (config *lisp-configuration*))
  "Write CONFIG to STREAM as lisp.conf. Not WRITE-ALDO-CONFIGURATION with
another argument: the documented defaults and the accepted values must come
from the LISP interactor's own tables, or lisp.conf would advertise aldo's
settings as if they were its own."
  (write-configuration-file stream (%config-with-extras "lisp" config)
                            *default-lisp-configuration* *lisp-setting-specs*
                            :name "lisp.conf"
                            :what "the LISP (REPL) interactor"
                            :save-command ",write-settings"))

(defparameter +config-read-package-name+ "CLAUTOLISP.DEBUG.UI.CONFIO"
  "A throw-away package the config reader interns file symbols into, so reading
aldo.conf never pollutes a real package.")

(defun read-aldo-configuration (stream)
  "Read one config sexp from STREAM and internalise it. Reads with *READ-EVAL*
NIL in a throw-away package."
  (let ((pkg (or (find-package +config-read-package-name+)
                 (make-package +config-read-package-name+ :use nil))))
    (let ((*read-eval* nil)
          (*package* pkg))
      (%internalize (read stream nil nil)))))

(defun save-aldo-configuration (&optional (path (aldo-config-save-path)))
  "Write *ALDO-CONFIGURATION* to PATH (default the XDG save path) as UTF-8.
Creates the containing directory. Returns the path written."
  (ensure-directories-exist path)
  (with-open-file (out path :direction :output :if-exists :supersede
                            :if-does-not-exist :create
                            :external-format :utf-8)
    (write-aldo-configuration out))
  path)

(defun load-aldo-configuration (&optional (path (aldo-config-load-path)))
  "Read the configuration from PATH (default: the first available XDG aldo.conf)
into *ALDO-CONFIGURATION*. With no file, leaves the defaults in place. Returns
the path read, or NIL if none.

Every key the file carries counts as explicitly set, so an aldo.conf written
by an older clautolisp — a full dump of every setting — keeps behaving exactly
as it did, shadowing the LISP layer for all of them."
  (when (and path (probe-file path))
    (with-open-file (in path :direction :input :external-format :utf-8)
      (let ((config (read-aldo-configuration in)))
        (when (consp config)
          (setf *aldo-configuration* (%config-consume-extras "aldo" config)))))
    path))

(defun save-lisp-configuration (&optional (path (lisp-config-save-path)))
  "Write *LISP-CONFIGURATION* to PATH (default $XDG_CONFIG_HOME/clautolisp/
lisp.conf) as UTF-8. Returns the path written."
  (ensure-directories-exist path)
  (with-open-file (out path :direction :output :if-exists :supersede
                            :if-does-not-exist :create
                            :external-format :utf-8)
    (write-lisp-configuration out *lisp-configuration*))
  path)

(defun load-lisp-configuration (&optional (path (lisp-config-load-path)))
  "Read lisp.conf from PATH into *LISP-CONFIGURATION*. With no file, leaves
the defaults in place. Returns the path read, or NIL if none."
  (when (and path (probe-file path))
    (with-open-file (in path :direction :input :external-format :utf-8)
      (let ((config (read-aldo-configuration in)))
        (when (consp config)
          (setf *lisp-configuration* (%config-consume-extras "lisp" config)))))
    path))
