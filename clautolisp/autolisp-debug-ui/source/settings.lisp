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
;;;; ASCII).

(in-package #:clautolisp.debug.ui)

;;; ---------------------------------------------------------------------------
;;; Defaults and the per-key specification (type, allowed values)

(defparameter *default-aldo-configuration*
  '((:navigator . :sexp)
    (:navigation-history-max . 1000)
    (:break-on-caught . nil)
    (:source-window-height . 24)
    (:value-line-width . 72)
    (:pager . :on)
    (:pager-height . 24)
    (:theme . :unicode)
    (:default-user-interface . :tui)
    (:default-aldb-listening-address . "127.0.0.1")
    (:default-aldb-listening-port . 4301)
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
    (:navigation-history-max  :integer)
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

(defvar *aldo-configuration* nil
  "The current aldo configuration (an alist like *DEFAULT-ALDO-CONFIGURATION*).
Initialised from the defaults; updated by `set' / CONFIG-SET; (re)loaded from
the XDG aldo.conf by LOAD-ALDO-CONFIGURATION; saved only on request.")

(defun reset-aldo-configuration ()
  "Reset *ALDO-CONFIGURATION* to a fresh copy of the built-in defaults."
  (setf *aldo-configuration* (copy-tree *default-aldo-configuration*)))

(reset-aldo-configuration)

;;; ---------------------------------------------------------------------------
;;; Key / value normalisation (case-insensitive)

(defun normalize-config-key (key)
  "Normalise KEY (a string, symbol or keyword) to an upper-cased keyword."
  (intern (string-upcase (string key)) :keyword))

(defun config-get (key &optional (config *aldo-configuration*))
  "The value of KEY in CONFIG (case-insensitive), or NIL if absent."
  (cdr (assoc (normalize-config-key key) config)))

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

(defun setting-spec (key)
  (assoc (normalize-config-key key) *setting-specs*))

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
  "The current value of setting NAME (case-insensitive)."
  (config-get name config))

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

(defun aldo-config-relative-path ()
  (make-pathname :directory '(:relative "clautolisp") :name "aldo" :type "conf"))

(defun aldo-config-save-path ()
  "Where SAVE writes: $XDG_CONFIG_HOME/clautolisp/aldo.conf."
  (merge-pathnames (aldo-config-relative-path)
                   (uiop:ensure-directory-pathname (xdg-config-home))))

(defun aldo-config-load-path ()
  "Where LOAD reads from: the save path if it exists, else the first
clautolisp/aldo.conf found along $XDG_CONFIG_DIRS; NIL if none."
  (let ((home (aldo-config-save-path)))
    (if (probe-file home)
        home
        (loop :for dir :in (xdg-config-dirs)
              :for path := (merge-pathnames (aldo-config-relative-path)
                                            (uiop:ensure-directory-pathname dir))
              :when (probe-file path) :return path))))

;;; ---------------------------------------------------------------------------
;;; Sexp I/O — aldo.conf is an AutoLISP-friendly sexp of bare lower-case symbols

(defun %externalize (form)
  "Convert the internal config FORM (keyword keys/enums) to its external,
AutoLISP-friendly shape: keywords become bare lower-case symbols (printed as
tokens), everything else is kept."
  (cond ((keywordp form) (make-symbol (string-downcase (symbol-name form))))
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

(defun write-aldo-configuration (stream &optional (config *aldo-configuration*))
  "Write CONFIG to STREAM as a readable sexp (bare lower-case symbols)."
  (let ((*print-case* :downcase)
        (*print-readably* nil)
        (*print-gensym* nil)            ; uninterned symbols print bare, no #:
        (*print-pretty* t))
    (prin1 (%externalize config) stream)
    (terpri stream)))

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
the path read, or NIL if none."
  (when (and path (probe-file path))
    (with-open-file (in path :direction :input :external-format :utf-8)
      (let ((config (read-aldo-configuration in)))
        (when (consp config)
          (setf *aldo-configuration* config))))
    path))
