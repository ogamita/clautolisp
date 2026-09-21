;;;; autolisp-front-end/source/plugin.lisp
;;;;
;;;; alfe.plugin — the plug-in system. A plug-in is a Common Lisp file
;;;; that alfe loads at start-up and that (1) defines command-line options,
;;;; possibly with arguments, and (2) intervenes at any stage of the run
;;;; through named hooks. The first two plug-ins are EPURE and EPUREE
;;;; (plugins/epure/, plugins/epuree/).
;;;;
;;;; Specified by documentation/alfe--specifications.org, chapter
;;;; "Plug-ins", and by ../issues/open/alfe-plugin-model.issue (the epic)
;;;; and its sub-issues alfe-plugin-{loader,options,hooks}.
;;;;
;;;; The file has five parts:
;;;;
;;;;   1. the registry      PLUGIN / PLUGIN-OPTION structs, REGISTER-PLUGIN,
;;;;                        DEFINE-PLUGIN, DEFINE-PLUGIN-HOOK
;;;;   2. options           option-specs for the parser, resolution,
;;;;                        activation, the --help section
;;;;   3. the run context   *CONTEXT*, PLUGIN-OPTION, PLUGIN-STATE
;;;;   4. hooks             the catalogue and RUN-HOOK
;;;;   5. loading           search path, source/compiled forms, compiling
;;;;
;;;; alfe.cli depends on this package, never the other way round: the
;;;; things this file needs from the CLI (the names of the core options, to
;;;; refuse a collision) reach it through *CORE-OPTION-NAMES-FUNCTION*.

(defpackage #:alfe.plugin
  (:use #:cl)
  (:import-from #:alfe.error
                #:cli-usage-error
                #:backend-error
                #:plugin-error)
  (:import-from #:alfe.logging
                #:log-debug
                #:log-verbose)
  (:import-from #:clautolisp.autolisp-cli
                #:make-option-spec
                #:cli-options-backend
                #:cli-options-plugin-options
                #:cli-options-plugins-active)
  (:export ;; registry
           #:plugin
           #:plugin-name
           #:plugin-version
           #:plugin-description
           #:plugin-applies-to
           #:plugin-priority
           #:plugin-options
           #:plugin-source
           #:plugin-form
           #:plugin-option-long
           #:plugin-option-kind
           #:plugin-option-key
           #:plugin-option-activates
           #:register-plugin
           #:register-hook
           #:define-plugin
           #:define-plugin-hook
           #:find-plugin
           #:list-plugins
           #:reset-plugins
           #:*core-option-names-function*
           ;; hooks
           #:+hook-points+
           #:hook-kind
           #:run-hook
           #:hook-active-p
           ;; the run context
           #:context
           #:make-context
           #:*context*
           #:with-run-context
           #:context-options
           #:context-backend
           #:context-version
           #:plugin-option
           #:plugin-state
           #:deactivate-plugin
           ;; options and activation (used by alfe.cli)
           #:plugin-option-specs
           #:resolve-plugin-options
           #:activate-plugin-by-name
           #:plugin-usage-text
           ;; loading
           #:plugin-search-path
           #:prescan-plugin-arguments
           #:load-plugins
           #:plugins-disabled-p
           #:compile-plugin
           #:implementation-tag
           #:compiled-plugin-file-name
           #:print-plugins
           #:*vendored-plugin-system*
           ;; utilities for plug-in authors
           #:autolisp-string-literal))

(in-package #:alfe.plugin)

;;; ====================================================================
;;; 1. The registry
;;; ====================================================================

(defstruct (plugin-option (:constructor %make-plugin-option))
  "One option a plug-in defines. KIND is :FLAG / :VALUE / :REPEAT; LONG the
long option string; KEY the keyword its value is stored under."
  (kind      :flag :type (member :flag :value :repeat))
  (long      ""    :type string)
  (key       nil   :type symbol)
  (activates nil)
  (arg       nil)
  (doc       nil)
  (env       nil)
  (default   nil)
  (parser    nil)
  (choices   nil))

(defstruct (plugin (:constructor %make-plugin))
  "A registered plug-in. SOURCE is the file it was loaded from (NIL when it
was registered from code, as the tests do) and FORM is :SOURCE or :COMPILED."
  (name        "" :type string)
  (version     "0")
  (description "")
  (applies-to  :all)
  (priority    0 :type integer)
  (options     nil :type list)
  (hooks       nil :type list)                ; alist (HOOK . FUNCTION)
  (source      nil)
  (form        nil)
  (order       0 :type integer))

(defvar *plugins* nil
  "The registered plug-ins, in registration order.")

(defvar *registration-counter* 0)

(defvar *loading* nil
  "While a plug-in file is being loaded, the plug-in NAME it was found
under; REGISTER-PLUGIN insists on registering under exactly that name.")

(defvar *loading-source* nil
  "While a plug-in file is being loaded, (PATH FORM) — recorded into the
plug-in REGISTER-PLUGIN builds.")

(defvar *core-option-names-function* nil
  "Function of no argument returning every long option string alfe defines
itself. Set by alfe.cli so that a plug-in option colliding with a core one
is refused at registration. NIL means: check nothing.")

(defun find-plugin (name)
  "The registered plug-in named NAME (a string, symbol or keyword), or NIL."
  (find (%normalise-name name) *plugins* :key #'plugin-name :test #'string=))

(defun list-plugins ()
  "The registered plug-ins, in registration order."
  (copy-list *plugins*))

(defun reset-plugins ()
  "Forget every registered plug-in. For tests."
  (setf *plugins* nil
        *registration-counter* 0))

(defun %normalise-name (name)
  (string-downcase (etypecase name
                     (string name)
                     (symbol (symbol-name name)))))

(defun %valid-name-p (name)
  (and (plusp (length name))
       (lower-case-p (char name 0))
       (every (lambda (c)
                (or (lower-case-p c) (digit-char-p c) (char= c #\-)))
              name)))

(defun %registration-error (name control &rest arguments)
  (error "plug-in ~A: ~?" name control arguments))

(defun %default-key (plugin-name long)
  "The key an option is stored under when :KEY is not given: LONG minus its
--NAME- prefix, or :ENABLED for --NAME itself."
  (let ((bare (concatenate 'string "--" plugin-name)))
    (cond ((string= long bare) :enabled)
          (t (intern (string-upcase (subseq long (1+ (length bare))))
                     :keyword)))))

(defun %make-option (plugin-name spec)
  "Validate one OPTION-SPEC, (KIND LONG . PLIST), and build the struct."
  (destructuring-bind (kind long &rest plist) spec
    (unless (member kind '(:flag :value :repeat))
      (%registration-error plugin-name "option ~S: unknown kind ~S" long kind))
    (unless (and (stringp long) (> (length long) 2)
                 (string= "--" long :end2 2))
      (%registration-error plugin-name
                           "option ~S must be a long option (--NAME…); ~
plug-ins define no short options" long))
    (let ((bare (concatenate 'string "--" plugin-name)))
      (unless (or (string= long bare)
                  (and (> (length long) (1+ (length bare)))
                       (string= (concatenate 'string bare "-") long
                                :end2 (1+ (length bare)))))
        (%registration-error plugin-name
                             "option ~A is outside the plug-in's namespace: ~
only ~A and ~A-… are allowed" long bare bare)))
    (when (and (eq kind :flag) (or (getf plist :parser) (getf plist :choices)))
      (%registration-error plugin-name
                           "flag ~A cannot have :parser or :choices" long))
    (%make-plugin-option
     :kind kind :long long
     :key (or (getf plist :key) (%default-key plugin-name long))
     :activates (getf plist :activates)
     :arg (getf plist :arg)
     :doc (getf plist :doc)
     :env (getf plist :env)
     :default (getf plist :default)
     :parser (getf plist :parser)
     :choices (getf plist :choices))))

(defun %check-collisions (plugin)
  "Refuse an option that another plug-in or alfe itself already owns."
  (let ((core (when *core-option-names-function*
                (funcall *core-option-names-function*))))
    (dolist (option (plugin-options plugin))
      (let ((long (plugin-option-long option)))
        (when (member long core :test #'string=)
          (%registration-error (plugin-name plugin)
                               "option ~A is a core alfe option" long))
        (dolist (other *plugins*)
          (unless (string= (plugin-name other) (plugin-name plugin))
            (when (find long (plugin-options other)
                        :key #'plugin-option-long :test #'string=)
              (%registration-error (plugin-name plugin)
                                   "option ~A is already defined by plug-in ~A"
                                   long (plugin-name other)))))))))

(defun register-plugin (name &key (version "0") (description "")
                               (applies-to :all) (priority 0) options)
  "Register a plug-in and return it. OPTIONS is a list of (KIND LONG . PLIST)
option specs (see the spec chapter). Registering a NAME already registered
replaces the earlier registration; a plug-in being loaded from a file must
register under the name of the directory it was found in."
  (let ((name (%normalise-name name)))
    (unless (%valid-name-p name)
      (error "plug-in name ~S must match [a-z][a-z0-9-]*" name))
    (when (and *loading* (string/= *loading* name))
      (%registration-error name "registered from the file of plug-in ~A" *loading*))
    (unless (or (eq applies-to :all)
                (and (listp applies-to)
                     (every (lambda (b) (member b '(:clautolisp :bricscad :autocad)))
                            applies-to)))
      (%registration-error name ":applies-to must be :all or a list of ~
:clautolisp / :bricscad / :autocad, not ~S" applies-to))
    (let ((plugin (%make-plugin
                   :name name :version version :description description
                   :applies-to applies-to :priority priority
                   :options (mapcar (lambda (spec) (%make-option name spec))
                                    options)
                   :source (first *loading-source*)
                   :form (second *loading-source*)
                   :order (incf *registration-counter*))))
      (let ((longs (mapcar #'plugin-option-long (plugin-options plugin))))
        (unless (= (length longs) (length (remove-duplicates longs :test #'string=)))
          (%registration-error name "an option is defined twice")))
      (setf *plugins* (remove name *plugins* :key #'plugin-name :test #'string=))
      (%check-collisions plugin)
      (setf *plugins* (append *plugins* (list plugin)))
      plugin)))

(defmacro define-plugin (name &rest keys &key options &allow-other-keys)
  "Register the plug-in NAME. KEYS: :VERSION :DESCRIPTION :APPLIES-TO
:PRIORITY (evaluated) and :OPTIONS, a literal list of option specs
(KIND \"--long\" . PLIST) whose plist values ARE evaluated — quote list
literals, as in :CHOICES '(\"a\" \"b\")."
  (let ((others (loop for (key value) on keys by #'cddr
                      unless (eq key :options)
                        append (list key value))))
    `(register-plugin ,name ,@others
                      :options (list ,@(mapcar (lambda (spec)
                                                 `(list ,(first spec) ,(second spec)
                                                        ,@(cddr spec)))
                                               options)))))

;;; --- hook registration ----------------------------------------------

(defparameter +hook-points+
  '((:cli-parsed          :event   "after parsing and --cad selection, before the backend is resolved")
    (:backend-selected    :event   "after the backend is resolved")
    (:plan                :filter  "the effective action plan")
    (:dry-run-report      :collect "lines printed after the plan by --dry-run")
    (:workdir-prepared    :event   "after the workdir exists")
    (:run-common-prelude  :collect "AutoLISP source before the bootstrap load in run-common.lsp")
    (:run-common-epilogue :collect "AutoLISP source before the server loop in run-common.lsp")
    (:launcher-lines      :collect "lines for one slot of the launcher script")
    (:launcher-script     :filter  "the whole launcher script text")
    (:launch-argv         :filter  "the CAD command line")
    (:launch-options      :filter  "working directory and environment of the spawn")
    (:engine-started      :event   "the engine reached READY")
    (:pre-action          :event   "before each action")
    (:post-action         :event   "after each action")
    (:pre-shutdown        :event   "before the engine is shut down")
    (:post-shutdown       :event   "after the shutdown, before the workdir is removed")
    (:exit-code           :filter  "the exit code of a run that reached the end of its plan")
    (:error               :event   "an error is about to be reported"))
  "The hook catalogue: (NAME KIND DOCUMENTATION). Kinds: :EVENT results are
ignored; :FILTER threads a value; :COLLECT concatenates lists.")

(defun hook-kind (name)
  "The kind of hook NAME, or NIL when NAME is not in the catalogue."
  (second (assoc name +hook-points+)))

(defun register-hook (plugin-name hook function)
  "Add FUNCTION as PLUGIN-NAME's handler for HOOK, replacing an earlier one."
  (let ((plugin (or (find-plugin plugin-name)
                    (error "register-hook: no plug-in ~A is registered"
                           plugin-name))))
    (unless (hook-kind hook)
      (%registration-error (plugin-name plugin)
                           "unknown hook ~S (known: ~{~S~^ ~})"
                           hook (mapcar #'first +hook-points+)))
    (setf (plugin-hooks plugin)
          (acons hook function (remove hook (plugin-hooks plugin) :key #'car)))
    function))

(defun %lambda-list-variables (lambda-list)
  (loop for item in lambda-list
        unless (member item lambda-list-keywords)
          collect (if (consp item)
                      (if (consp (first item)) (second (first item)) (first item))
                      item)))

(defun %with-allow-other-keys (lambda-list)
  "Make a handler lambda list accept the details keys it does not name."
  (cond ((member '&allow-other-keys lambda-list) lambda-list)
        ((member '&key lambda-list) (append lambda-list '(&allow-other-keys)))
        (t (append lambda-list '(&key &allow-other-keys)))))

(defmacro define-plugin-hook (plugin-name hook lambda-list &body body)
  "Define PLUGIN-NAME's handler for HOOK: (LAMBDA (CTX VALUE &KEY …) …).
&ALLOW-OTHER-KEYS is added for you, so name only the details you use."
  `(register-hook ,plugin-name ,hook
                  (lambda ,(%with-allow-other-keys lambda-list)
                    (declare (ignorable ,@(%lambda-list-variables lambda-list)))
                    ,@body)))

;;; ====================================================================
;;; 2. Options
;;; ====================================================================

(defun %env-true-p (value)
  (and (stringp value)
       (member value '("1" "y" "yes" "true" "on") :test #'string-equal)))

(defun %path-list (string)
  (remove "" (uiop:split-string string
                                :separator (list (if (uiop:os-windows-p) #\; #\:)))
          :test #'string=))

(defun %plist-value (options name key)
  (getf (cdr (assoc name (cli-options-plugin-options options) :test #'string=)) key))

(defun %set-plist-value (options name key value)
  (let ((entry (assoc name (cli-options-plugin-options options) :test #'string=)))
    (if entry
        (setf (cdr entry) (list* key value (%remove-key (cdr entry) key)))
        (setf (cli-options-plugin-options options)
              (append (cli-options-plugin-options options)
                      (list (list name key value)))))
    value))

(defun %remove-key (plist key)
  (loop for (k v) on plist by #'cddr unless (eq k key) append (list k v)))

(defun %activate (options name)
  (unless (member name (cli-options-plugins-active options) :test #'string=)
    (setf (cli-options-plugins-active options)
          (append (cli-options-plugins-active options) (list name)))))

(defun %convert-value (option string spelled)
  "STRING, checked against OPTION's :CHOICES then converted by its :PARSER."
  (when (and (plugin-option-choices option)
             (not (member string (plugin-option-choices option) :test #'string=)))
    (error 'cli-usage-error
           :option spelled
           :message (format nil "Invalid value ~S for ~A (expected one of ~{~A~^, ~})"
                            string spelled (plugin-option-choices option))))
  (if (plugin-option-parser option)
      (funcall (plugin-option-parser option) string)
      string))

(defun %option-handler (plugin option)
  (let ((name (plugin-name plugin))
        (key (plugin-option-key option)))
    (lambda (options value spelled)
      (ecase (plugin-option-kind option)
        (:flag   (%set-plist-value options name key t))
        (:value  (%set-plist-value options name key
                                   (%convert-value option value spelled)))
        (:repeat (%set-plist-value options name key
                                   (append (%plist-value options name key)
                                           (list (%convert-value option value
                                                                 spelled))))))
      (when (plugin-option-activates option)
        (%activate options name)))))

(defun plugin-option-specs ()
  "The parser option-specs of every registered plug-in's options."
  (loop for plugin in *plugins*
        append (loop for option in (plugin-options plugin)
                     collect (make-option-spec
                              :longs (list (plugin-option-long option))
                              :takes-arg-p (not (eq (plugin-option-kind option) :flag))
                              :handler (%option-handler plugin option)))))

(defun activate-plugin-by-name (options name)
  "Activate the plug-in NAME (--plugin NAME); a usage error when it is not
installed."
  (let ((plugin (find-plugin name)))
    (unless plugin
      (error 'cli-usage-error
             :option "--plugin"
             :message (format nil "Unknown plug-in ~A (installed: ~:[none~;~:*~{~A~^, ~}~])"
                              name (mapcar #'plugin-name *plugins*))))
    (%activate options (plugin-name plugin))))

(defun %activating-option (plugin)
  (find-if #'plugin-option-activates (plugin-options plugin)))

(defun resolve-plugin-options (options)
  "Once the command line is parsed: activate the plug-ins the environment
asks for, refuse the options of plug-ins that are not active, then resolve
every active plug-in's options — command line, then environment, then
default. Returns OPTIONS."
  ;; 1. Activation by environment.
  (dolist (plugin *plugins*)
    (let ((flag (%activating-option plugin)))
      (when (and flag (plugin-option-env flag)
                 (%env-true-p (uiop:getenv (plugin-option-env flag))))
        (%activate options (plugin-name plugin))
        (unless (%plist-value options (plugin-name plugin) (plugin-option-key flag))
          (%set-plist-value options (plugin-name plugin) (plugin-option-key flag) t)))))
  (let ((names (uiop:getenv "ALFE_PLUGINS")))
    (when (and names (plusp (length names)))
      (dolist (name (uiop:split-string names :separator ","))
        (let ((name (string-trim " " name)))
          (when (plusp (length name))
            (activate-plugin-by-name options name))))))
  ;; 2. An option of a plug-in that is not active.
  (dolist (entry (cli-options-plugin-options options))
    (unless (member (car entry) (cli-options-plugins-active options)
                    :test #'string=)
      (let* ((plugin (find-plugin (car entry)))
             (flag (and plugin (%activating-option plugin)))
             (given (loop for (key nil) on (cdr entry) by #'cddr
                          for option = (and plugin
                                            (find key (plugin-options plugin)
                                                  :key #'plugin-option-key))
                          when option return option)))
        (error 'cli-usage-error
               :option (if given (plugin-option-long given) (car entry))
               :message (format nil "~A needs plug-in ~A to be active~@[: add ~A~]"
                                (if given (plugin-option-long given) (car entry))
                                (car entry)
                                (and flag (plugin-option-long flag)))))))
  ;; 3. Environment and defaults, for the active plug-ins.
  (dolist (name (cli-options-plugins-active options))
    (let ((plugin (find-plugin name)))
      (when plugin
        (dolist (option (plugin-options plugin))
          (let ((key (plugin-option-key option))
                (sentinel '#:absent))
            (when (eq sentinel (getf (cdr (assoc name (cli-options-plugin-options options)
                                                 :test #'string=))
                                     key sentinel))
              (let ((env (and (plugin-option-env option)
                              (uiop:getenv (plugin-option-env option)))))
                (cond
                  ((and env (plusp (length env)) (eq (plugin-option-kind option) :flag))
                   (when (%env-true-p env)
                     (%set-plist-value options name key t)))
                  ((and env (plusp (length env)) (eq (plugin-option-kind option) :repeat))
                   (%set-plist-value options name key
                                     (mapcar (lambda (item)
                                               (%convert-value option item
                                                               (plugin-option-env option)))
                                             (%path-list env))))
                  ((and env (plusp (length env)))
                   (%set-plist-value options name key
                                     (%convert-value option env
                                                     (plugin-option-env option))))
                  ((plugin-option-default option)
                   (%set-plist-value options name key
                                     (plugin-option-default option))))))))))
    options))

(defun plugin-usage-text ()
  "The 'Plug-in options' section of --help: every option of every installed
plug-in, active or not. NIL when no plug-in is installed."
  (when *plugins*
    (with-output-to-string (out)
      (format out "~%Plug-in options (installed plug-ins; a plug-in is active with its own flag,~%~
--plugin NAME or $ALFE_PLUGINS):~%")
      (dolist (plugin *plugins*)
        (format out "  ~A ~A~@[ — ~A~]~%" (plugin-name plugin) (plugin-version plugin)
                (and (plusp (length (plugin-description plugin)))
                     (plugin-description plugin)))
        (dolist (option (plugin-options plugin))
          (let ((left (format nil "    ~A~@[ ~A~]" (plugin-option-long option)
                              (and (not (eq (plugin-option-kind option) :flag))
                                   (or (plugin-option-arg option) "ARG")))))
            (format out "~A~vT~@[~A~]~@[ (default: ~A)~]~@[ [$~A]~]~%"
                    left 28 (plugin-option-doc option)
                    (plugin-option-default option) (plugin-option-env option))))))))

;;; ====================================================================
;;; 3. The run context
;;; ====================================================================

(defstruct (context (:constructor %make-context))
  "The state of one alfe run, as hooks see it."
  (options nil)
  (backend :clautolisp)
  (version "0.0.0")
  (active  nil)          ; active PLUGIN structs, in call order
  (plugin  nil)          ; the plug-in whose handler is running
  (state   nil))         ; alist (PLUGIN-NAME . plist)

(defvar *context* nil
  "The context of the current run; NIL outside one, which makes every hook
call site a no-op.")

(defun make-context (&key options backend version)
  "A context for OPTIONS. The active plug-ins are those OPTIONS names, in
:PRIORITY order (ties: registration order)."
  (%make-context
   :options options
   :backend (or backend (and options (cli-options-backend options)) :clautolisp)
   :version (or version "0.0.0")
   :active (stable-sort
            (loop for name in (and options (cli-options-plugins-active options))
                  for plugin = (find-plugin name)
                  when plugin collect plugin)
            #'< :key (lambda (p) (+ (* 1000000 (plugin-priority p)) (plugin-order p))))))

(defmacro with-run-context ((options &key backend version) &body body)
  "Run BODY with *CONTEXT* bound to a fresh context for OPTIONS."
  `(let ((*context* (make-context :options ,options :backend ,backend
                                  :version ,version)))
     ,@body))

(defun plugin-option (key &optional (context *context*))
  "The calling plug-in's resolved value for its option stored under KEY."
  (let ((plugin (and context (context-plugin context))))
    (unless plugin
      (error "PLUGIN-OPTION ~S called outside a plug-in hook" key))
    (%plist-value (context-options context) (plugin-name plugin) key)))

(defun plugin-state (context key)
  "The calling plug-in's per-run scratch value under KEY (SETF-able)."
  (getf (cdr (assoc (plugin-name (context-plugin context)) (context-state context)
                    :test #'string=))
        key))

(defun (setf plugin-state) (value context key)
  (let* ((name (plugin-name (context-plugin context)))
         (entry (assoc name (context-state context) :test #'string=)))
    (if entry
        (setf (cdr entry) (list* key value (%remove-key (cdr entry) key)))
        (push (list name key value) (context-state context)))
    value))

(defun deactivate-plugin (context)
  "The calling plug-in takes no further part in this run. It also leaves
the options' list of active plug-ins, so what alfe transmits to the engine
(*AUTOLISP-PLUGIN-OPTIONS*) says what actually ran."
  (let ((plugin (context-plugin context)))
    (when plugin
      (log-verbose "plug-in ~A: deactivated for this run" (plugin-name plugin))
      (setf (context-active context) (remove plugin (context-active context)))
      (when (context-options context)
        (setf (cli-options-plugins-active (context-options context))
              (remove (plugin-name plugin)
                      (cli-options-plugins-active (context-options context))
                      :test #'string=))))))

;;; ====================================================================
;;; 4. Hooks
;;; ====================================================================

(defun %applies-p (plugin backend)
  (let ((applies (plugin-applies-to plugin)))
    (or (eq applies :all) (member backend applies))))

(defun %handlers (context name)
  (loop for plugin in (context-active context)
        for function = (cdr (assoc name (plugin-hooks plugin)))
        when (and function (%applies-p plugin (context-backend context)))
          collect (cons plugin function)))

(defun hook-active-p (name)
  "True when an active plug-in that applies to the running backend has a
handler for the hook NAME."
  (and *context* (%handlers *context* name) t))

(defun %call-handler (context plugin function name value details)
  (let ((previous (context-plugin context)))
    (setf (context-plugin context) plugin)
    (unwind-protect
         (handler-bind
             ((error (lambda (condition)
                       (unless (typep condition '(or cli-usage-error backend-error))
                         (error 'plugin-error
                                :plugin (plugin-name plugin)
                                :hook name
                                :message (format nil "~A" condition))))))
           (apply function context value details))
      (setf (context-plugin context) previous))))

(defun run-hook (name value &rest details)
  "Call the handlers of the hook NAME. VALUE is the hook's primary value and
DETAILS its keyword details (the running backend is added as :BACKEND). By
kind: :EVENT returns NIL; :FILTER threads VALUE through the handlers and
returns the last result; :COLLECT returns the concatenation of the handlers'
lists. With no context or no handler it returns VALUE (filter) or NIL."
  (let ((kind (or (hook-kind name)
                  (error "unknown hook ~S" name)))
        (context *context*))
    (if (null context)
        (if (eq kind :filter) value nil)
        (let ((details (list* :backend (context-backend context) details))
              (result (if (eq kind :filter) value nil)))
          (dolist (entry (%handlers context name))
            (destructuring-bind (plugin . function) entry
              (when (member plugin (context-active context))
                (let ((answer (%call-handler context plugin function name
                                             (if (eq kind :filter) result value)
                                             details)))
                  (ecase kind
                    (:event nil)
                    (:filter (setf result answer))
                    (:collect (setf result (append result answer))))))))
          result))))

;;; ====================================================================
;;; 5. Loading
;;; ====================================================================

(defvar *vendored-plugin-system* "autolisp-front-end"
  "The ASDF system whose source tree holds plugins/, the last plug-in root
searched: it is what makes the shipped plug-ins work from a checkout, before
any install. A variable so tests can make it unavailable.")

(defstruct (load-report (:constructor make-load-report))
  "What loading one plug-in file did. STATUS: :LOADED / :FAILED / :SKIPPED."
  name path form status message)

(defvar *load-reports* nil
  "The LOAD-REPORTs of the last LOAD-PLUGINS, in search order.")

(defvar *search-path* nil
  "The directories the last LOAD-PLUGINS searched.")

(defun implementation-tag ()
  "The Common Lisp implementation as it appears in a compiled plug-in's file
name: sbcl, ccl, or the downcased implementation type."
  #+sbcl "sbcl"
  #+ccl "ccl"
  #-(or sbcl ccl) (string-downcase
                   (remove-if-not #'alphanumericp (lisp-implementation-type))))

(defun compiled-plugin-file-name (name version)
  "NAME.VERSION-IMPL.plugin"
  (format nil "~A.~A-~A.plugin" name version (implementation-tag)))

(defun %directory-of (path)
  (uiop:ensure-directory-pathname path))

(defun plugin-search-path (&key directories (include-defaults t))
  "The plug-in roots, in the order the spec gives: DIRECTORIES (the
--plugin-path options), $ALFE_PLUGIN_PATH, the XDG data home, the XDG data
dirs, PREFIX/share/clautolisp/plug-in for the running executable, and the
source tree's plugins/. With INCLUDE-DEFAULTS NIL only DIRECTORIES."
  ;; ROOTS is built by PUSH and reversed at the end, so it starts reversed.
  (let ((roots (reverse (mapcar #'%directory-of directories))))
    (when include-defaults
      (let ((env (uiop:getenv "ALFE_PLUGIN_PATH")))
        (when env
          (dolist (dir (%path-list env))
            (push (%directory-of dir) roots))))
      (let* ((home (let ((xdg (uiop:getenv "XDG_DATA_HOME")))
                     (cond ((and xdg (plusp (length xdg))) xdg)
                           ((uiop:os-windows-p) (uiop:getenv "APPDATA"))
                           (t (namestring
                               (merge-pathnames ".local/share/"
                                                (user-homedir-pathname)))))))
             (dirs (let ((xdg (uiop:getenv "XDG_DATA_DIRS")))
                     (if (and xdg (plusp (length xdg)))
                         (%path-list xdg)
                         (unless (uiop:os-windows-p)
                           (list "/usr/local/share" "/usr/share"))))))
        (dolist (share (append (and home (list home)) dirs))
          (push (merge-pathnames "clautolisp/plug-in/" (%directory-of share))
                roots)))
      (dolist (prefix (ignore-errors
                       (uiop:symbol-call :alfe.backend.cad-common
                                         :installation-prefixes)))
        (push (merge-pathnames "share/clautolisp/plug-in/" prefix) roots))
      (let ((vendored (ignore-errors
                       (asdf:system-relative-pathname *vendored-plugin-system*
                                                      "plugins/"))))
        (when vendored (push vendored roots))))
    (remove-duplicates (nreverse roots) :test #'equal :from-end t)))

(defun plugins-disabled-p (no-plugins-flag)
  "True when NO-PLUGINS-FLAG (--no-plugins) or $ALFE_NO_PLUGINS says to load
no plug-in."
  (or no-plugins-flag (%env-true-p (uiop:getenv "ALFE_NO_PLUGINS"))))

(defun prescan-plugin-arguments (argv)
  "The two things ARGV says that decide what is loaded, found before the
parser knows the plug-in options: (VALUES DIRECTORIES NO-PLUGINS-P)."
  (let ((directories '()) (none nil))
    (loop while argv
          do (let ((arg (pop argv)))
               (cond ((string= arg "--no-plugins") (setf none t))
                     ((string= arg "--plugin-path")
                      (when argv (push (pop argv) directories)))
                     ((and (> (length arg) 14)
                           (string= "--plugin-path=" arg :end2 14))
                      (push (subseq arg 14) directories)))))
    (values (nreverse directories) none)))

(defun %candidates (root version)
  "The plug-ins found under ROOT: a list of (NAME SOURCE COMPILED IGNORED),
SOURCE and COMPILED being pathnames or NIL, IGNORED the compiled files there
for another version or implementation."
  (let ((found '()))
    (dolist (dir (ignore-errors (uiop:subdirectories root)))
      (let* ((name (car (last (pathname-directory dir))))
             (source (probe-file (merge-pathnames (format nil "~A.lisp" name) dir)))
             (compiled (probe-file (merge-pathnames
                                    (compiled-plugin-file-name name version) dir)))
             (prefix (format nil "~A." name))
             (ignored (remove-if-not
                       (lambda (file)
                         (let ((base (pathname-name file)))
                           (and (> (length base) (length prefix))
                                (string= prefix base :end2 (length prefix))
                                (not (and compiled
                                          (equal base (pathname-name compiled)))))))
                       (directory (merge-pathnames
                                   (make-pathname :name :wild :type "plugin")
                                   dir)))))
        (when (and (stringp name) (%valid-name-p name)
                   (or source compiled))
          (push (list name source compiled ignored) found))))
    (sort found #'string< :key #'first)))

(defvar *loaded-files* (make-hash-table :test #'equal)
  "Namestring -> write date of every plug-in file loaded in this process. A
process that runs alfe once never reads it; the test suite, which calls RUN
hundreds of times, does not pay to compile the same plug-in each time.")

(defun %already-loaded-p (name path)
  (let ((plugin (find-plugin name)))
    (and plugin
         (equal (plugin-source plugin) path)
         (eql (gethash (namestring path) *loaded-files*)
              (file-write-date path)))))

(defun %load-file (name path form)
  "Load PATH, registering under NAME. Returns NIL, or the message of the
failure. Loader and compiler output is captured, shown at :debug."
  (when (%already-loaded-p name path)
    (return-from %load-file nil))
  (let ((chatter (make-string-output-stream)))
    (unwind-protect
         (handler-case
             (let ((*loading* name)
                   (*loading-source* (list path form))
                   (*package* (find-package :cl-user))
                   (*compile-verbose* nil) (*compile-print* nil)
                   (*load-verbose* nil) (*load-print* nil)
                   (*error-output* chatter)
                   (*standard-output* chatter))
               (handler-bind ((style-warning #'muffle-warning))
                 (load path))
               (unless (find-plugin name)
                 (error "the file did not register plug-in ~A" name))
               (setf (gethash (namestring path) *loaded-files*)
                     (file-write-date path))
               nil)
           (error (condition) (format nil "~A" condition)))
      (let ((text (get-output-stream-string chatter)))
        (when (plusp (length text))
          (log-debug "plug-in ~A: loader output:~%~A" name text))))))

(defun %newer-or-equal-p (a b)
  (or (null b) (>= (file-write-date a) (file-write-date b))))

(defun load-plugins (&key directories (include-defaults t) (version "0.0.0"))
  "Find and load every plug-in under the search path, first of a given name
wins. A plug-in that fails to load is reported on standard error and
skipped. Returns the list of LOAD-REPORTs (also kept for --list-plugins)."
  (let ((roots (plugin-search-path :directories directories
                                   :include-defaults include-defaults))
        (seen '())
        (reports '()))
    (setf *search-path* roots)
    (dolist (root roots)
      (dolist (candidate (%candidates root version))
        (destructuring-bind (name source compiled ignored) candidate
          (dolist (file ignored)
            (log-verbose "plug-in ~A: ignoring ~A (not for alfe ~A on ~A)"
                         name (file-namestring file) version (implementation-tag)))
          (cond
            ((member name seen :test #'string=)
             (log-verbose "plug-in ~A: ~A shadowed by an earlier root" name root))
            (t
             (push name seen)
             (let* ((use-compiled (and compiled (%newer-or-equal-p compiled source)))
                    (path (if use-compiled compiled source))
                    (form (if use-compiled :compiled :source))
                    (failure (%load-file name path form)))
               (when (and failure use-compiled source)
                 (format *error-output*
                         "~&alfe: warning: plug-in ~A: compiled form ~A failed (~A); ~
loading the source~%" name (file-namestring compiled) failure)
                 (setf form :source path source
                       failure (%load-file name source :source)))
               (cond
                 (failure
                  (format *error-output* "~&alfe: warning: plug-in ~A (~A): ~A~%"
                          name path failure)
                  (push (make-load-report :name name :path path :form form
                                          :status :failed :message failure)
                        reports))
                 (t
                  (log-verbose "plug-in ~A: loaded ~A (~(~A~))" name path form)
                  (push (make-load-report :name name :path path :form form
                                          :status :loaded)
                        reports)))))))))
    (setf *load-reports* (nreverse reports))))

(defun print-plugins (&optional (stream *standard-output*))
  "--list-plugins: the plug-ins found, those that failed, the search path."
  (format stream "~&Installed plug-ins:~%")
  (if (null *load-reports*)
      (format stream "  (none)~%")
      (dolist (report *load-reports*)
        (let ((plugin (find-plugin (load-report-name report))))
          (if (eq (load-report-status report) :loaded)
              (format stream "  ~A ~A  ~(~A~)  ~A~%    ~A~%"
                      (load-report-name report)
                      (if plugin (plugin-version plugin) "?")
                      (load-report-form report)
                      (load-report-path report)
                      (if plugin (plugin-description plugin) ""))
              (format stream "  ~A  FAILED  ~A~%    ~A~%"
                      (load-report-name report) (load-report-path report)
                      (load-report-message report))))))
  (format stream "Search path:~%")
  (dolist (root *search-path*)
    (format stream "  ~A~:[  (missing)~;~]~%" (uiop:native-namestring root)
            (uiop:directory-exists-p root)))
  (finish-output stream))

(defun compile-plugin (file &key (version "0.0.0") output-directory)
  "Compile the plug-in source FILE (NAME.lisp) for VERSION and this
implementation into NAME.VERSION-IMPL.plugin next to it (or in
OUTPUT-DIRECTORY). Returns the pathname written; signals an error when the
compilation fails."
  (let* ((file (truename file))
         (name (pathname-name file))
         (output (merge-pathnames (compiled-plugin-file-name name version)
                                  (or output-directory file))))
    (unless (%valid-name-p name)
      (error "~A: a plug-in source is named NAME.lisp with NAME matching ~
[a-z][a-z0-9-]*" (file-namestring file)))
    (multiple-value-bind (fasl warnings-p failure-p)
        (let ((*compile-verbose* nil) (*compile-print* nil))
          (handler-bind ((style-warning #'muffle-warning))
            (compile-file file :output-file output)))
      (declare (ignore warnings-p))
      (when (or failure-p (null fasl))
        (error "compiling ~A failed" file))
      fasl)))

;;; ====================================================================
;;; Utilities for plug-in authors
;;; ====================================================================

(defun autolisp-string-literal (string)
  "STRING as an AutoLISP string literal (quotes included), escaping the
backslash, the double quote and the control characters AutoLISP names."
  (with-output-to-string (out)
    (write-char #\" out)
    (loop for c across string
          do (case c
               (#\\ (write-string "\\\\" out))
               (#\" (write-string "\\\"" out))
               (#\Newline (write-string "\\n" out))
               (#\Tab (write-string "\\t" out))
               (#\Return (write-string "\\r" out))
               (t (write-char c out))))
    (write-char #\" out)))
