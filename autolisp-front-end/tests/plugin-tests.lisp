(in-package #:autolisp-front-end.tests)

(in-suite autolisp-front-end-suite)

;;;; FiveAM tests for alfe.plugin, the plug-in system: registration and its
;;;; rules, options and activation, hooks, discovery and loading (source and
;;;; compiled), and the whole thing driven through ALFE.CLI:RUN. The plug-ins
;;;; shipped with alfe are tested in plugin-epure-tests.lisp and
;;;; plugin-epuree-tests.lisp.
;;;;
;;;; Every test runs against a fresh registry and a fresh loaded-file cache,
;;;; and (through %RUN-ALFE) with the plug-in search path emptied of whatever
;;;; the developer installed: what is under test is never a plug-in that
;;;; happens to be on this machine.

;;; --- helpers -----------------------------------------------------------

(defvar *plugin-test-random* (make-random-state t)
  "Seeded once per process; CCL starts every process with the same
*RANDOM-STATE*, which made temporary directory names collide across runs.")

(defun %plugin-fixtures ()
  "The directory holding the fixture plug-ins (a plug-in root)."
  (asdf:system-relative-pathname "autolisp-front-end/tests"
                                 "tests/fixtures/plugins/"))

(defun %plugin-temp-directory ()
  (loop
    (let ((dir (uiop:ensure-directory-pathname
                (uiop:subpathname
                 (uiop:temporary-directory)
                 (format nil "alfe-plugin-test-~36R"
                         (random (expt 36 12) *plugin-test-random*))))))
      (unless (uiop:directory-exists-p dir)
        (ensure-directories-exist dir)
        (return dir)))))

(defun call-with-plugin-temp-directory (function)
  (let ((dir (%plugin-temp-directory)))
    (unwind-protect (funcall function dir)
      (ignore-errors
       (uiop:delete-directory-tree dir :validate t :if-does-not-exist :ignore)))))

(defmacro with-plugin-temp-directory ((var) &body body)
  `(call-with-plugin-temp-directory (lambda (,var) ,@body)))

(defun call-with-plugin-env (bindings function)
  (let ((saved (mapcar (lambda (b) (cons (car b) (uiop:getenv (car b)))) bindings)))
    (unwind-protect
         (progn (dolist (b bindings)
                  (setf (uiop:getenv (car b)) (or (cdr b) "")))
                (funcall function))
      (dolist (s saved)
        (setf (uiop:getenv (car s)) (or (cdr s) ""))))))

(defmacro with-plugin-env (bindings &body body)
  "Run BODY with the environment variables in BINDINGS, ((NAME VALUE) …),
set (an empty value means unset), and restore them afterwards."
  `(call-with-plugin-env (list ,@(mapcar (lambda (b) `(cons ,(first b) ,(second b)))
                                         bindings))
                         (lambda () ,@body)))

(defmacro with-clean-plugins ((&key (vendored nil)) &body body)
  "BODY with an empty plug-in registry and loaded-file cache, and (unless
VENDORED) without the source tree's plugins/ among the roots."
  `(let ((alfe.plugin::*plugins* nil)
         (alfe.plugin::*registration-counter* 0)
         (alfe.plugin::*load-reports* nil)
         (alfe.plugin::*search-path* nil)
         (alfe.plugin::*loaded-files* (make-hash-table :test #'equal))
         (alfe.plugin:*core-option-names-function*
           alfe.plugin:*core-option-names-function*)
         (alfe.plugin:*vendored-plugin-system*
           ,(if vendored
                'alfe.plugin:*vendored-plugin-system*
                "no-such-asdf-system-for-the-plugin-tests"))
         (alfe.plugin:*context* nil))
     (with-plugin-env (("XDG_DATA_HOME" "/nonexistent/alfe-plugin-test")
                       ("XDG_DATA_DIRS" "/nonexistent/alfe-plugin-test-dirs")
                       ("ALFE_PLUGIN_PATH" "")
                       ("ALFE_PLUGINS" "")
                       ("ALFE_NO_PLUGINS" ""))
       ,@body)))

(defun %run-alfe (&rest argv)
  "ALFE.CLI:RUN in-process, with --no-init. (values exit-code stdout stderr)."
  (let* ((out (make-string-output-stream))
         (err (make-string-output-stream))
         (code (let ((*standard-output* out) (*error-output* err))
                 (run (append '("--no-init") argv) :version "9.9.9"))))
    (values code (get-output-stream-string out) (get-output-stream-string err))))

(defun %fixture-path (&rest argv)
  "ARGV led by --plugin-path to the fixture plug-ins."
  (list* "--plugin-path" (namestring (%plugin-fixtures)) argv))

(defun %copy-plugin (name root &key (replace nil))
  "Copy the fixture plug-in NAME into ROOT (a plug-in root); REPLACE is a
list of (FROM TO) substitutions applied to its source."
  (let* ((source (merge-pathnames (format nil "~A/~A.lisp" name name)
                                  (%plugin-fixtures)))
         (target (merge-pathnames (format nil "~A/~A.lisp" name name) root))
         (text (uiop:read-file-string source)))
    (ensure-directories-exist target)
    (loop for (from to) in replace
          do (setf text (uiop:frob-substrings text (list from) to)))
    (with-open-file (out target :direction :output :if-exists :supersede)
      (write-string text out))
    target))

(defun %register-demo (&rest keys)
  (apply #'alfe.plugin:register-plugin "demo"
         :options '((:flag "--demo" :activates t :env "DEMO_ON")
                    (:value "--demo-level" :key :level :env "DEMO_LEVEL"
                     :default "1")
                    (:repeat "--demo-tag" :key :tags))
         keys))

;;; --- registration -------------------------------------------------------

(test plugin-register-and-find
  "REGISTER-PLUGIN returns the plug-in; FIND-PLUGIN accepts a string, a
symbol or a keyword; registering again replaces."
  (with-clean-plugins ()
    (let ((plugin (%register-demo :version "1.0" :description "d")))
      (is (string= "demo" (alfe.plugin:plugin-name plugin)))
      (is (eq plugin (alfe.plugin:find-plugin "demo")))
      (is (eq plugin (alfe.plugin:find-plugin :demo)))
      (is (eq plugin (alfe.plugin:find-plugin 'demo)))
      (%register-demo :version "2.0")
      (is (= 1 (length (alfe.plugin:list-plugins))))
      (is (string= "2.0" (alfe.plugin:plugin-version
                          (alfe.plugin:find-plugin "demo")))))))

(test plugin-name-is-validated
  (with-clean-plugins ()
    (dolist (bad '("" "1demo" "de mo" "de_mo" "-demo"))
      (signals error (alfe.plugin:register-plugin bad))
      (is (null (alfe.plugin:list-plugins))))
    (is (alfe.plugin:register-plugin "de-mo1"))))

(test plugin-options-stay-in-their-namespace
  "A plug-in NAME defines --NAME and --NAME-… only, long options only, of a
known kind."
  (with-clean-plugins ()
    (flet ((refused (&rest options)
             (handler-case (progn (alfe.plugin:register-plugin "demo" :options options)
                                  nil)
               (error () t))))
      (is (refused '(:flag "--other")))
      (is (refused '(:flag "--demonstration")))
      (is (refused '(:flag "-d")))
      (is (refused '(:flag "demo")))
      (is (refused '(:switch "--demo")))
      (is (refused '(:flag "--demo-a") '(:flag "--demo-a")))
      (is (refused '(:flag "--demo-a" :parser #'identity)))
      (is (not (refused '(:flag "--demo") '(:value "--demo-a") '(:repeat "--demo-b")))))))

(test plugin-option-collisions-are-refused
  "An option alfe or another plug-in already owns is a registration error."
  (with-clean-plugins ()
    (let ((alfe.plugin:*core-option-names-function*
            (lambda () '("--demo-core"))))
      (signals error (alfe.plugin:register-plugin
                      "demo" :options '((:flag "--demo-core"))))
      (%register-demo)
      ;; Another plug-in cannot take --demo-level (its own namespace rule
      ;; would already refuse: a plug-in named `demo' owns --demo-…).
      (signals error (alfe.plugin:register-plugin
                      "demo-level" :options '((:flag "--demo-level")))))
    ;; The same plug-in re-registering keeps its own options.
    (is (alfe.plugin:register-plugin "demo" :options '((:flag "--demo"))))))

(test plugin-applies-to-is-validated
  (with-clean-plugins ()
    (signals error (alfe.plugin:register-plugin "demo" :applies-to '(:nowhere)))
    (is (alfe.plugin:register-plugin "demo" :applies-to '(:bricscad :autocad)))
    (is (alfe.plugin:register-plugin "demo" :applies-to :all))))

(test plugin-define-plugin-evaluates-option-values
  "In DEFINE-PLUGIN the plist values of an option spec are evaluated (a
function, a quoted list), the spec itself is literal."
  (with-clean-plugins ()
    (alfe.plugin:define-plugin "demo"
      :version "3"
      :options ((:value "--demo-n" :parser #'parse-integer :choices '("1" "2"))
                (:flag "--demo" :activates t)))
    (let ((plugin (alfe.plugin:find-plugin "demo")))
      (is (string= "3" (alfe.plugin:plugin-version plugin)))
      (is (= 2 (length (alfe.plugin:plugin-options plugin))))
      (is (eq :n (alfe.plugin:plugin-option-key
                  (first (alfe.plugin:plugin-options plugin)))))
      (is (eq :enabled (alfe.plugin:plugin-option-key
                        (second (alfe.plugin:plugin-options plugin))))))))

(test plugin-unknown-hook-is-refused-at-registration
  (with-clean-plugins ()
    (%register-demo)
    (signals error (alfe.plugin:register-hook "demo" :no-such-hook #'identity))
    (signals error (alfe.plugin:register-hook "absent" :plan #'identity))
    (is (alfe.plugin:register-hook "demo" :plan #'identity))))

(test plugin-hook-lambda-lists-accept-other-keys
  "DEFINE-PLUGIN-HOOK adds &ALLOW-OTHER-KEYS: a handler names only the
details it uses, and one with no &KEY at all still takes them."
  (with-clean-plugins ()
    (%register-demo)
    (alfe.plugin:define-plugin-hook "demo" :plan (ctx plan) (cons :a plan))
    (alfe.plugin:define-plugin-hook "demo" :exit-code (ctx code &key result)
      (+ code 1))
    (let* ((options (make-cli-options :plugins-active '("demo")))
           (alfe.plugin:*context* (alfe.plugin:make-context :options options)))
      (is (equal '(:a 1) (alfe.plugin:run-hook :plan '(1) :extra 42)))
      (is (= 1 (alfe.plugin:run-hook :exit-code 0 :result :x :surplus t))))))

;;; --- options, resolution, activation --------------------------------------

(test plugin-options-parse-and-activate
  "Flag, value and repeat options land in CLI-OPTIONS-PLUGIN-OPTIONS, and the
activation flag adds the plug-in to CLI-OPTIONS-PLUGINS-ACTIVE."
  (with-clean-plugins ()
    (%register-demo)
    (let ((options (parse-arguments '("--demo" "--demo-level" "7"
                                      "--demo-tag=a" "--demo-tag" "b"))))
      (is (equal '("demo") (cli-options-plugins-active options)))
      (let ((entry (cdr (assoc "demo" (cli-options-plugin-options options)
                               :test #'string=))))
        (is (eq t (getf entry :enabled)))
        (is (string= "7" (getf entry :level)))
        (is (equal '("a" "b") (getf entry :tags)))))))

(test plugin-option-of-an-inactive-plugin-is-a-usage-error
  "--demo-level without --demo: refused, and the message names the flag to
add."
  (with-clean-plugins ()
    (%register-demo)
    (handler-case (progn (parse-arguments '("--demo-level" "7")) (fail "no error"))
      (cli-usage-error (condition)
        (is (search "--demo-level" (alfe.error:cli-usage-error-message condition)))
        (is (search "add --demo" (alfe.error:cli-usage-error-message condition)))))))

(test plugin-value-parser-and-choices
  "A :parser converts and reports through CLI-USAGE-ERROR; :choices are
checked first."
  (with-clean-plugins ()
    (alfe.plugin:register-plugin
     "demo"
     :options (list '(:flag "--demo" :activates t)
                    (list :value "--demo-n" :key :n :parser #'parse-integer)
                    (list :value "--demo-c" :key :c :choices '("a" "b"))))
    (is (= 12 (getf (cdr (assoc "demo" (cli-options-plugin-options
                                        (parse-arguments '("--demo" "--demo-n" "12")))
                                :test #'string=))
                    :n)))
    (signals error (parse-arguments '("--demo" "--demo-n" "twelve")))
    (signals cli-usage-error (parse-arguments '("--demo" "--demo-c" "z")))
    (is (string= "a" (getf (cdr (assoc "demo" (cli-options-plugin-options
                                               (parse-arguments '("--demo" "--demo-c" "a")))
                                       :test #'string=))
                           :c)))))

(test plugin-resolution-command-line-then-environment-then-default
  (with-clean-plugins ()
    (%register-demo)
    (flet ((level (&rest argv)
             (getf (cdr (assoc "demo" (cli-options-plugin-options
                                       (parse-arguments (cons "--demo" argv)))
                               :test #'string=))
                   :level)))
      (with-plugin-env (("DEMO_LEVEL" ""))
        (is (string= "1" (level))))
      (with-plugin-env (("DEMO_LEVEL" "5"))
        (is (string= "5" (level)))
        (is (string= "9" (level "--demo-level" "9")))))))

(test plugin-environment-activates-and-fills-repeat-options
  "A true value in the activating option's environment variable activates
the plug-in; a :repeat option's variable is a PATH-style list."
  (with-clean-plugins ()
    (alfe.plugin:register-plugin
     "demo" :options '((:flag "--demo" :activates t :env "DEMO_ON")
                       (:repeat "--demo-tag" :key :tags :env "DEMO_TAGS")))
    (with-plugin-env (("DEMO_ON" "yes")
                      ("DEMO_TAGS" (format nil "x~Ay" (if (uiop:os-windows-p) #\; #\:))))
      (let ((options (parse-arguments '())))
        (is (equal '("demo") (cli-options-plugins-active options)))
        (is (equal '("x" "y")
                   (getf (cdr (assoc "demo" (cli-options-plugin-options options)
                                     :test #'string=))
                         :tags)))))
    (with-plugin-env (("DEMO_ON" "0") ("DEMO_TAGS" ""))
      (is (null (cli-options-plugins-active (parse-arguments '())))))))

(test plugin-activation-by-name
  "--plugin NAME and $ALFE_PLUGINS activate a plug-in; an unknown one is a
usage error naming the installed ones."
  (with-clean-plugins ()
    (%register-demo)
    (is (equal '("demo") (cli-options-plugins-active
                          (parse-arguments '("--plugin" "demo")))))
    (with-plugin-env (("ALFE_PLUGINS" "demo"))
      (is (equal '("demo") (cli-options-plugins-active (parse-arguments '())))))
    (handler-case (progn (parse-arguments '("--plugin" "nothere")) (fail "no error"))
      (cli-usage-error (condition)
        (is (search "nothere" (alfe.error:cli-usage-error-message condition)))
        (is (search "demo" (alfe.error:cli-usage-error-message condition)))))
    (with-plugin-env (("ALFE_PLUGINS" "nothere"))
      (signals cli-usage-error (parse-arguments '())))))

(test plugin-usage-text-lists-installed-options
  (with-clean-plugins ()
    (is (null (alfe.plugin:plugin-usage-text)))
    (alfe.plugin:register-plugin
     "demo" :version "1.0" :description "A demo."
     :options '((:flag "--demo" :activates t :doc "Turn it on." :env "DEMO_ON")
                (:value "--demo-level" :arg "N" :default "3" :doc "How much.")))
    (let ((text (alfe.plugin:plugin-usage-text)))
      (is (search "demo 1.0" text))
      (is (search "A demo." text))
      (is (search "--demo-level N" text))
      (is (search "How much." text))
      (is (search "(default: 3)" text))
      (is (search "[$DEMO_ON]" text)))
    (let ((usage (alfe.cli:usage-string)))
      (is (search "Plug-in options" usage))
      (is (search "--demo-level N" usage)))))

(test plugin-options-are-transmitted-as-active-plugin-names
  "*AUTOLISP-PLUGIN-OPTIONS* holds one symbol per active plug-in."
  (with-clean-plugins ()
    (%register-demo)
    (flet ((binding (options)
             (second (assoc "*AUTOLISP-PLUGIN-OPTIONS*"
                            (alfe.cli:cli-options-transmit-bindings-for-alfe
                             options :backend "CLAUTOLISP" :version-text "1.0")
                            :test #'string=))))
      (is (null (binding (parse-arguments '()))))
      (let ((value (binding (parse-arguments '("--demo")))))
        (is (= 1 (length value)))
        ;; AutoLISP symbols are runtime objects, interned by name.
        (is (eq (clautolisp.autolisp-runtime:intern-autolisp-symbol "DEMO")
                (first value)))))))

;;; --- hooks --------------------------------------------------------------

(defun %activate-context (&rest plugin-names)
  (alfe.plugin:make-context
   :options (make-cli-options :plugins-active plugin-names)
   :backend :clautolisp))

(test plugin-hooks-without-a-context-are-no-ops
  (with-clean-plugins ()
    (is (equal '(1 2) (alfe.plugin:run-hook :plan '(1 2))))
    (is (= 7 (alfe.plugin:run-hook :exit-code 7)))
    (is (null (alfe.plugin:run-hook :pre-shutdown :session)))
    (is (null (alfe.plugin:run-hook :dry-run-report nil)))
    (is (not (alfe.plugin:hook-active-p :plan)))
    (signals error (alfe.plugin:run-hook :no-such-hook nil))))

(test plugin-hook-kinds-and-order
  "Event results are ignored, a filter threads its value, a collect
concatenates; handlers run in :PRIORITY order, ties in registration order."
  (with-clean-plugins ()
    (let ((calls '()))
      (alfe.plugin:register-plugin "late"  :priority 5)
      (alfe.plugin:register-plugin "first" :priority -1)
      (alfe.plugin:register-plugin "mid-a")
      (alfe.plugin:register-plugin "mid-b")
      (dolist (name '("late" "first" "mid-a" "mid-b"))
        (let ((name name))
          (alfe.plugin:register-hook
           name :plan (lambda (ctx value &key backend)
                        (declare (ignore ctx))
                        (push (list name backend) calls)
                        (append value (list name))))
          (alfe.plugin:register-hook
           name :dry-run-report (lambda (ctx value &key backend)
                                  (declare (ignore ctx value backend))
                                  (list (format nil "line from ~A" name))))
          (alfe.plugin:register-hook
           name :pre-shutdown (lambda (ctx value &key backend)
                                (declare (ignore ctx value backend))
                                :ignored))))
      (let ((alfe.plugin:*context*
              (%activate-context "late" "mid-b" "first" "mid-a")))
        (is (equal '("x" "first" "mid-a" "mid-b" "late")
                   (alfe.plugin:run-hook :plan '("x"))))
        (is (equal '("line from first" "line from mid-a" "line from mid-b"
                     "line from late")
                   (alfe.plugin:run-hook :dry-run-report nil)))
        (is (null (alfe.plugin:run-hook :pre-shutdown :session)))
        ;; The running backend is added to the details.
        (is (every (lambda (call) (eq :clautolisp (second call))) calls))))))

(test plugin-only-active-plugins-that-apply-are-called
  (with-clean-plugins ()
    (let ((called '()))
      (dolist (spec '(("cad-only" (:bricscad :autocad)) ("any" :all) ("idle" :all)))
        (destructuring-bind (name applies) spec
          (alfe.plugin:register-plugin name :applies-to applies)
          (alfe.plugin:register-hook
           name :plan (lambda (ctx value &key &allow-other-keys)
                        (declare (ignore ctx))
                        (push name called)
                        value))))
      (let ((alfe.plugin:*context* (%activate-context "cad-only" "any")))
        (alfe.plugin:run-hook :plan nil)
        ;; "idle" is not active; "cad-only" does not apply to clautolisp.
        (is (equal '("any") called))
        (setf (alfe.plugin:context-backend alfe.plugin:*context*) :bricscad)
        (setf called '())
        (alfe.plugin:run-hook :plan nil)
        (is (equal '("any" "cad-only") called))
        (is (alfe.plugin:hook-active-p :plan))
        (is (not (alfe.plugin:hook-active-p :pre-action)))))))

(test plugin-handler-errors-are-wrapped-or-passed-through
  "A plain Lisp error becomes PLUGIN-ERROR (naming plug-in and hook, exit
code 4); a usage error or a backend error keeps its own class and exit code."
  (with-clean-plugins ()
    (alfe.plugin:register-plugin "bad")
    (let ((alfe.plugin:*context* (%activate-context "bad")))
      (alfe.plugin:register-hook "bad" :plan (lambda (ctx value &key &allow-other-keys)
                                               (declare (ignore ctx value))
                                               (error "boom")))
      (handler-case (progn (alfe.plugin:run-hook :plan nil) (fail "no error"))
        (alfe.error:plugin-error (condition)
          (is (string= "bad" (alfe.error:plugin-error-plugin condition)))
          (is (eq :plan (alfe.error:plugin-error-hook condition)))
          (is (search "boom" (format nil "~A" condition)))
          (is (search "plug-in bad" (format nil "~A" condition)))
          (is (= 4 (exit-code-for-condition condition)))))
      (alfe.plugin:register-hook "bad" :plan (lambda (ctx value &key &allow-other-keys)
                                               (declare (ignore ctx value))
                                               (error 'cli-usage-error
                                                      :option "--x" :message "no")))
      (signals cli-usage-error (alfe.plugin:run-hook :plan nil))
      (alfe.plugin:register-hook "bad" :plan (lambda (ctx value &key &allow-other-keys)
                                               (declare (ignore ctx value))
                                               (error 'backend-not-available
                                                      :message "gone")))
      (signals backend-not-available (alfe.plugin:run-hook :plan nil)))))

(test plugin-deactivate-removes-it-for-the-rest-of-the-run
  (with-clean-plugins ()
    (let ((calls 0))
      (alfe.plugin:register-plugin "quitter")
      (alfe.plugin:register-hook "quitter" :cli-parsed
                                 (lambda (ctx value &key &allow-other-keys)
                                   (declare (ignore value))
                                   (incf calls)
                                   (alfe.plugin:deactivate-plugin ctx)))
      (alfe.plugin:register-hook "quitter" :plan
                                 (lambda (ctx value &key &allow-other-keys)
                                   (declare (ignore ctx))
                                   (incf calls 100)
                                   value))
      (let* ((options (make-cli-options :plugins-active '("quitter")))
             (alfe.plugin:*context* (alfe.plugin:make-context :options options)))
        (alfe.plugin:run-hook :cli-parsed options)
        (alfe.plugin:run-hook :plan nil)
        (is (= 1 calls))
        ;; What alfe transmits says what actually ran.
        (is (null (cli-options-plugins-active options)))))))

(test plugin-option-and-state-accessors
  (with-clean-plugins ()
    (%register-demo)
    (let* ((options (parse-arguments '("--demo" "--demo-level" "4")))
           (alfe.plugin:*context* (alfe.plugin:make-context :options options)))
      (alfe.plugin:register-hook
       "demo" :cli-parsed
       (lambda (ctx value &key &allow-other-keys)
         (declare (ignore value))
         (setf (alfe.plugin:plugin-state ctx :seen) (alfe.plugin:plugin-option :level))))
      (alfe.plugin:register-hook
       "demo" :plan
       (lambda (ctx value &key &allow-other-keys)
         (append value (list (alfe.plugin:plugin-state ctx :seen)))))
      (alfe.plugin:run-hook :cli-parsed options)
      (is (equal '("4") (alfe.plugin:run-hook :plan nil)))
      (signals error (alfe.plugin:plugin-option :level)))))

;;; --- discovery and loading -----------------------------------------------

(test plugin-loads-a-source-plugin-from-a-root
  (with-clean-plugins ()
    (let ((reports (let ((*error-output* (make-broadcast-stream))) ; broken/wrongname warn
                     (alfe.plugin:load-plugins :directories (list (%plugin-fixtures))
                                               :include-defaults nil :version "9.9.9"))))
      (let ((hello (find "hello" reports :key #'alfe.plugin::load-report-name
                                         :test #'string=)))
        (is (not (null hello)))
        (is (eq :loaded (alfe.plugin::load-report-status hello)))
        (is (eq :source (alfe.plugin::load-report-form hello))))
      (let ((plugin (alfe.plugin:find-plugin "hello")))
        (is (string= "1.2.3" (alfe.plugin:plugin-version plugin)))
        (is (eq :source (alfe.plugin:plugin-form plugin)))
        (is (search "hello.lisp" (namestring (alfe.plugin:plugin-source plugin))))))))

(test plugin-failing-plugins-are-reported-and-skipped
  "A file that does not read, or registers under another name, is reported
and skipped; the good plug-ins in the same root still load."
  (with-clean-plugins ()
    (let* ((stderr (make-string-output-stream))
           (reports (let ((*error-output* stderr))
                      (alfe.plugin:load-plugins
                       :directories (list (%plugin-fixtures))
                       :include-defaults nil :version "9.9.9")))
           (text (get-output-stream-string stderr)))
      (flet ((status (name)
               (alfe.plugin::load-report-status
                (find name reports :key #'alfe.plugin::load-report-name
                                   :test #'string=))))
        (is (eq :failed (status "broken")))
        (is (eq :failed (status "wrongname")))
        (is (eq :loaded (status "hello")))
        (is (eq :loaded (status "recorder"))))
      (is (search "warning: plug-in broken" text))
      (is (search "warning: plug-in wrongname" text))
      (is (null (alfe.plugin:find-plugin "broken")))
      (is (null (alfe.plugin:find-plugin "somethingelse")))
      (is (not (null (alfe.plugin:find-plugin "hello")))))))

(test plugin-first-root-wins
  "The same plug-in in two roots: the earlier root's is the one loaded."
  (with-clean-plugins ()
    (with-plugin-temp-directory (first)
      (with-plugin-temp-directory (second)
        (%copy-plugin "hello" first :replace '(("1.2.3" "1.0.0")))
        (%copy-plugin "hello" second :replace '(("1.2.3" "2.0.0")))
        (alfe.plugin:load-plugins :directories (list first second)
                                  :include-defaults nil)
        (is (string= "1.0.0" (alfe.plugin:plugin-version
                              (alfe.plugin:find-plugin "hello"))))
        (alfe.plugin:reset-plugins)
        (alfe.plugin:load-plugins :directories (list second first)
                                  :include-defaults nil)
        (is (string= "2.0.0" (alfe.plugin:plugin-version
                              (alfe.plugin:find-plugin "hello"))))))))

(test plugin-search-path-order
  "--plugin-path roots, then $ALFE_PLUGIN_PATH, then the XDG data home, then
the XDG data dirs. (POSIX spellings: the path lists are `:'-separated.)"
  (unless (uiop:os-windows-p)
   (with-clean-plugins ()
    (with-plugin-env (("ALFE_PLUGIN_PATH" "/e/one:/e/two")
                      ("XDG_DATA_HOME" "/x/home")
                      ("XDG_DATA_DIRS" "/x/d1:/x/d2"))
      (let ((path (mapcar #'uiop:native-namestring
                          (alfe.plugin:plugin-search-path
                           :directories '("/cli/a" "/cli/b")))))
        (is (equal '("/cli/a/" "/cli/b/" "/e/one/" "/e/two/"
                     "/x/home/clautolisp/plug-in/"
                     "/x/d1/clautolisp/plug-in/" "/x/d2/clautolisp/plug-in/")
                   path))))
    (is (equal '("/only/")
               (mapcar #'uiop:native-namestring
                       (alfe.plugin:plugin-search-path
                        :directories '("/only") :include-defaults nil)))))))

(test plugin-compile-and-load-the-compiled-form
  "COMPILE-PLUGIN writes NAME.VERSION-IMPL.plugin; when it is at least as new
as the source it is what gets loaded; a newer source wins; a compiled file
for another version is ignored; a compiled file that will not load falls
back to the source."
  (with-clean-plugins ()
    (with-plugin-temp-directory (root)
      (let* ((source (%copy-plugin "hello" root))
             (compiled (alfe.plugin:compile-plugin source :version "9.9.9"))
             (expected (alfe.plugin:compiled-plugin-file-name "hello" "9.9.9")))
        (is (string= expected (file-namestring compiled)))
        (is (search (alfe.plugin:implementation-tag) expected))
        (flet ((load-form (&optional (version "9.9.9"))
                 (alfe.plugin:reset-plugins)
                 (clrhash alfe.plugin::*loaded-files*)
                 (let ((report (first (alfe.plugin:load-plugins
                                       :directories (list root)
                                       :include-defaults nil :version version))))
                   (values (alfe.plugin::load-report-form report)
                           (alfe.plugin::load-report-status report)))))
          ;; Compiled, for this version.
          (is (eq :compiled (load-form)))
          (is (eq :compiled (alfe.plugin:plugin-form (alfe.plugin:find-plugin "hello"))))
          ;; Another alfe version: the compiled file does not apply.
          (is (eq :source (load-form "1.0.0")))
          ;; A source newer than the compiled file.
          (sleep 1.1)
          (with-open-file (out source :direction :output :if-exists :append)
            (terpri out))
          (is (eq :source (load-form)))
          ;; A compiled file that is newest but garbage: fall back, warn.
          (sleep 1.1)
          (with-open-file (out compiled :direction :output :if-exists :supersede)
            (write-string "not a fasl" out))
          (let ((stderr (make-string-output-stream)))
            (multiple-value-bind (form status)
                (let ((*error-output* stderr)) (load-form))
              (is (eq :source form))
              (is (eq :loaded status)))
            (is (search "loading the source" (get-output-stream-string stderr)))))))))

(test plugin-compiled-only-and-foreign-implementations
  "A plug-in delivered compiled only loads; compiled files for another
implementation are ignored."
  (with-clean-plugins ()
    (with-plugin-temp-directory (root)
      (let* ((source (%copy-plugin "hello" root))
             (compiled (alfe.plugin:compile-plugin source :version "9.9.9")))
        (delete-file source)
        ;; A file another implementation would have written: garbage here.
        (with-open-file (out (merge-pathnames "hello.9.9.9-otherlisp.plugin"
                                              (uiop:pathname-directory-pathname compiled))
                             :direction :output :if-exists :supersede)
          (write-string "garbage" out))
        (let ((report (first (alfe.plugin:load-plugins
                              :directories (list root) :include-defaults nil
                              :version "9.9.9"))))
          (is (eq :loaded (alfe.plugin::load-report-status report)))
          (is (eq :compiled (alfe.plugin::load-report-form report))))))))

(test plugin-compile-plugin-refuses-bad-sources
  (with-clean-plugins ()
    (with-plugin-temp-directory (root)
      (let ((source (%copy-plugin "broken" (uiop:ensure-directory-pathname root))))
        (signals error (alfe.plugin:compile-plugin source))
        (signals error (alfe.plugin:compile-plugin
                        (merge-pathnames "absent.lisp" root)))))))

(test plugin-prescan-finds-what-decides-loading
  (multiple-value-bind (directories none)
      (alfe.plugin:prescan-plugin-arguments
       '("-x" "1" "--plugin-path" "/a" "--plugin-path=/b" "--no-plugins" "--plugin-path"))
    (is (equal '("/a" "/b") directories))
    (is (eq t none)))
  (multiple-value-bind (directories none)
      (alfe.plugin:prescan-plugin-arguments '("-x" "1"))
    (is (null directories))
    (is (null none)))
  (is (alfe.plugin:plugins-disabled-p t))
  (with-plugin-env (("ALFE_NO_PLUGINS" "1"))
    (is (alfe.plugin:plugins-disabled-p nil)))
  (with-plugin-env (("ALFE_NO_PLUGINS" ""))
    (is (not (alfe.plugin:plugins-disabled-p nil)))))

(test plugin-autolisp-string-literal
  (is (string= "\"abc\"" (alfe.plugin:autolisp-string-literal "abc")))
  (is (string= "\"a\\\\b\\\"c\\n\"" (alfe.plugin:autolisp-string-literal
                                       (format nil "a\\b\"c~%")))))

;;; --- through ALFE.CLI:RUN -------------------------------------------------

(test plugin-run-hello-end-to-end
  "A plug-in found with --plugin-path, activated by its flag, given an
argument, whose :plan hook puts an action in front of the user's: the
greeting comes out before the user's own output."
  (with-clean-plugins ()
    (multiple-value-bind (code out err)
        (apply #'%run-alfe (%fixture-path "--hello" "--hello-name" "Ada"
                                          "-x" "(princ \"|done\")"))
      (declare (ignore err))
      (is (= 0 code))
      (is (search "Hello, Ada!|done" out)))
    (multiple-value-bind (code out)
        (apply #'%run-alfe (%fixture-path "--hello" "-x" "(princ \"|done\")"))
      (is (= 0 code))
      (is (search "Hello, world!|done" out)))
    ;; Not activated: no greeting.
    (multiple-value-bind (code out)
        (apply #'%run-alfe (%fixture-path "-x" "(princ \"|done\")"))
      (is (= 0 code))
      (is (not (search "Hello" out))))))

(test plugin-run-inactive-plugin-option-exits-2
  (with-clean-plugins ()
    (multiple-value-bind (code out err)
        (apply #'%run-alfe (%fixture-path "--hello-name" "Ada" "-x" "(+ 1 2)"))
      (declare (ignore out))
      (is (= 2 code))
      (is (search "--hello-name" err))
      (is (search "--hello" err)))))

(test plugin-run-list-plugins
  (with-clean-plugins ()
    (multiple-value-bind (code out err)
        (apply #'%run-alfe (%fixture-path "--list-plugins"))
      (is (= 0 code))
      (is (search "hello 1.2.3" out))
      (is (search "Greet before the plan runs." out))
      (is (search "recorder 0.1.0" out))
      (is (search "broken  FAILED" out))
      (is (search "Search path:" out))
      (is (search (uiop:native-namestring (%plugin-fixtures)) out))
      ;; The failures were also reported as they happened.
      (is (search "warning: plug-in broken" err)))))

(test plugin-run-help-lists-plugin-options
  (with-clean-plugins ()
    (multiple-value-bind (code out)
        (apply #'%run-alfe (%fixture-path "--help"))
      (is (= 0 code))
      (is (search "--plugin NAME" out))
      (is (search "--list-plugins" out))
      (is (search "--compile-plugin FILE" out))
      (is (search "Plug-in options" out))
      (is (search "--hello-name NAME" out)))))

(test plugin-run-no-plugins
  "--no-plugins and $ALFE_NO_PLUGINS load nothing: the plug-in's options are
then unknown."
  (with-clean-plugins ()
    (multiple-value-bind (code out err)
        (apply #'%run-alfe (%fixture-path "--no-plugins" "--hello" "-x" "(+ 1 2)"))
      (declare (ignore out))
      (is (= 2 code))
      (is (search "Unknown option --hello" err)))
    (with-plugin-env (("ALFE_NO_PLUGINS" "1"))
      (multiple-value-bind (code out err)
          (apply #'%run-alfe (%fixture-path "--hello" "-x" "(+ 1 2)"))
        (declare (ignore out))
        (is (= 2 code))
        (is (search "Unknown option --hello" err))))))

(test plugin-run-a-broken-plugin-does-not-stop-alfe
  (with-clean-plugins ()
    (with-plugin-temp-directory (root)
      (%copy-plugin "broken" root)
      (multiple-value-bind (code out err)
          (%run-alfe "--plugin-path" (namestring root) "-x" "(princ 42)")
        (is (= 0 code))
        (is (search "42" out))
        (is (search "warning: plug-in broken" err))))))

(test plugin-run-environment-plugin-path-and-activation
  (with-clean-plugins ()
    (with-plugin-env (("ALFE_PLUGIN_PATH" (uiop:native-namestring (%plugin-fixtures)))
                      ("ALFE_PLUGINS" "hello"))
      (multiple-value-bind (code out)
          (%run-alfe "-x" "(princ \"|x\")")
        (is (= 0 code))
        (is (search "Hello, world!|x" out))))))

(test plugin-run-compile-plugin-command
  (with-clean-plugins ()
    (with-plugin-temp-directory (root)
      (let ((source (%copy-plugin "hello" root)))
        (multiple-value-bind (code out)
            (%run-alfe "--compile-plugin" (namestring source))
          (is (= 0 code))
          (is (search (alfe.plugin:compiled-plugin-file-name "hello" "9.9.9") out))
          (is (probe-file (merge-pathnames
                           (alfe.plugin:compiled-plugin-file-name "hello" "9.9.9")
                           (uiop:pathname-directory-pathname source)))))
        (multiple-value-bind (code out err)
            (%run-alfe "--compile-plugin" (namestring (merge-pathnames "nothere.lisp" root)))
          (declare (ignore out))
          (is (= 1 code))
          (is (search "--compile-plugin" err)))))))

(defun %recorded-hooks ()
  (mapcar #'first (reverse (symbol-value (find-symbol "*EVENTS*" "ALFE.PLUGIN.RECORDER")))))

(defun %recorded (hook)
  (remove hook (reverse (symbol-value (find-symbol "*EVENTS*" "ALFE.PLUGIN.RECORDER")))
          :key #'first :test-not #'eq))

(test plugin-run-lifecycle-order-on-the-clautolisp-backend
  "Every stage of a run calls its hook, in the order the spec lists them; the
launch-related hooks, which only the CAD backends have, are not called."
  (with-clean-plugins ()
    (multiple-value-bind (code out)
        (apply #'%run-alfe (%fixture-path "--recorder" "-x" "(princ 1)" "-x" "(princ 2)"))
      (is (= 0 code))
      (is (search "12" out)))
    (is (equal '(:cli-parsed :backend-selected :plan :workdir-prepared
                 :engine-started
                 :pre-action :post-action :pre-action :post-action
                 :pre-action :post-action
                 :exit-code :pre-shutdown :post-shutdown)
               (%recorded-hooks)))
    ;; Two -x plus the quit terminator: three actions, indexes 1..3.
    (is (equal '(1 2 3) (mapcar (lambda (event) (getf (cdr event) :index))
                                (%recorded :pre-action))))
    (is (every (lambda (event) (= 3 (getf (cdr event) :count)))
               (%recorded :post-action)))
    (is (eq :clautolisp (getf (cdr (first (%recorded :plan))) :backend)))
    (is (eql 0 (getf (cdr (first (%recorded :exit-code))) :value)))
    (is (eq :success (alfe.backend:eval-result-status
                      (getf (cdr (first (%recorded :post-action))) :result))))))

(test plugin-run-reports-errors-to-the-error-hook
  "An error escaping the run is offered to :error, at the point of the
error, before it is turned into an exit code; the exit code is unchanged."
  (with-clean-plugins ()
    ;; Load the recorder, then add a plug-in that fails right after parsing.
    (let ((*error-output* (make-broadcast-stream))) ; broken/wrongname warn
      (alfe.plugin:load-plugins :directories (list (%plugin-fixtures))
                                :include-defaults nil :version "9.9.9"))
    (alfe.plugin:register-plugin "raiser" :options '((:flag "--raiser" :activates t)))
    (alfe.plugin:register-hook "raiser" :cli-parsed
                               (lambda (ctx value &key &allow-other-keys)
                                 (declare (ignore ctx value))
                                 (error 'cli-usage-error :option "--raiser"
                                                         :message "raised on purpose")))
    (multiple-value-bind (code out err)
        (apply #'%run-alfe (%fixture-path "--recorder" "--raiser" "-x" "(+ 1 2)"))
      (declare (ignore out))
      (is (= 2 code))
      (is (search "raised on purpose" err)))
    (let ((errors (%recorded :error)))
      (is (= 1 (length errors)))
      (is (eq :usage (getf (cdr (first errors)) :phase)))
      ;; The recorder stores the TYPE of a value it has no size for.
      (is (eq 'cli-usage-error (getf (cdr (first errors)) :value))))))

(test plugin-run-hook-error-exits-4-and-names-the-plugin
  (with-clean-plugins ()
    (alfe.plugin:register-plugin "kaput" :options '((:flag "--kaput" :activates t)))
    (alfe.plugin:register-hook "kaput" :plan (lambda (ctx value &key &allow-other-keys)
                                               (declare (ignore ctx value))
                                               (error "kaput inside")))
    (multiple-value-bind (code out err) (%run-alfe "--kaput" "-x" "(+ 1 2)")
      (declare (ignore out))
      (is (= 4 code))
      (is (search "plug-in kaput" err))
      (is (search "kaput inside" err)))))

(test plugin-run-exit-code-filter
  (with-clean-plugins ()
    (alfe.plugin:register-plugin "codes" :options '((:flag "--codes" :activates t)))
    (alfe.plugin:register-hook "codes" :exit-code (lambda (ctx value &key &allow-other-keys)
                                                    (declare (ignore ctx))
                                                    (+ value 7)))
    (is (= 7 (%run-alfe "--codes" "-x" "(+ 1 2)")))))

(test plugin-run-dry-run-shows-plan-and-report
  "--dry-run runs :plan (so the plug-in's actions are shown) and
:dry-run-report, and starts no engine."
  (with-clean-plugins ()
    (alfe.plugin:register-plugin "shown" :options '((:flag "--shown" :activates t)))
    (alfe.plugin:register-hook "shown" :plan (lambda (ctx plan &key &allow-other-keys)
                                               (declare (ignore ctx))
                                               (cons (alfe.backend:action-eval "(princ 'from-plugin)")
                                                     plan)))
    (alfe.plugin:register-hook "shown" :dry-run-report
                               (lambda (ctx value &key &allow-other-keys)
                                 (declare (ignore ctx value))
                                 (list "shown: a plug-in note")))
    (multiple-value-bind (code out) (%run-alfe "--shown" "--dry-run" "-x" "(+ 1 2)")
      (is (= 0 code))
      (is (search "from-plugin" out))
      (is (< (search "from-plugin" out) (search "(+ 1 2)" out)))
      (is (search "shown: a plug-in note" out)))))

;;; --- per-action evaluation is only for plug-ins that ask ------------------

(defclass counting-backend (alfe.backend:backend)
  ((calls :initform '() :accessor counting-backend-calls)
   (fail-on :initarg :fail-on :initform nil :accessor counting-backend-fail-on)))

(defstruct (counting-session (:include alfe.backend:session)
                             (:constructor make-counting-session)
                             (:copier nil))
  (backend-object nil))

(defmethod alfe.backend:detect ((backend counting-backend) &key) backend)

(defmethod alfe.backend:prepare-workdir ((backend counting-backend) workdir-root &key)
  (or workdir-root
      (uiop:ensure-directory-pathname
       (merge-pathnames (format nil "alfe-test-counting-~D/"
                                (random 999999 *plugin-test-random*))
                        (uiop:temporary-directory)))))

(defmethod alfe.backend:start-engine ((backend counting-backend) workdir
                                      &key &allow-other-keys)
  (make-counting-session :backend :counting :workdir workdir :state :ready
                         :backend-object backend))

(defmethod alfe.backend:eval-plan ((session counting-session) plan)
  (let ((backend (counting-session-backend-object session)))
    (push (length plan) (counting-backend-calls backend))
    (let ((failed (some (lambda (action)
                          (and (counting-backend-fail-on backend)
                               (eq (alfe.backend:action-kind action)
                                   (counting-backend-fail-on backend))))
                        plan)))
      (alfe.backend:make-eval-result :status (if failed :failed :success)
                                     :output "" :error-output ""))))

(defmethod alfe.backend:shutdown ((session counting-session) &key reason)
  (declare (ignore reason))
  (alfe.backend:session-state-set session :stopped)
  session)

(defmethod alfe.backend:cleanup-workdir ((backend counting-backend) workdir &key keep-p)
  (declare (ignore keep-p))
  (ignore-errors (uiop:delete-directory-tree workdir :validate t
                                                     :if-does-not-exist :ignore))
  nil)

(defun %plan-of (&rest actions) actions)

(test plugin-plan-goes-to-the-backend-in-one-call-unless-a-plugin-asks
  "With no :pre-action / :post-action handler the whole plan is ONE EVAL-PLAN
call, as always; with one, the actions are evaluated one at a time, and the
run stops at the first that does not succeed."
  (with-clean-plugins ()
    (let ((options (make-cli-options
                    :no-init-p t
                    :actions (list (alfe.backend:action-eval "(a)")
                                   (alfe.backend:action-eval "(b)")
                                   (alfe.backend:action-load "/x.lsp")))))
      ;; No plug-in: one call, the whole plan (three actions and the quit).
      (let ((backend (make-instance 'counting-backend :name :counting))
            (alfe.plugin:*context* (alfe.plugin:make-context :options options)))
        (is (= 0 (alfe.cli::run-plan options backend)))
        (is (equal '(4) (counting-backend-calls backend))))
      ;; A plug-in with :post-action: one call per action.
      (alfe.plugin:register-plugin "watch")
      (let ((seen '()))
        (alfe.plugin:register-hook "watch" :post-action
                                   (lambda (ctx action &key index &allow-other-keys)
                                     (declare (ignore ctx))
                                     (push (list index (alfe.backend:action-kind action)) seen)))
        (setf (cli-options-plugins-active options) '("watch"))
        (let ((backend (make-instance 'counting-backend :name :counting))
              (alfe.plugin:*context* (alfe.plugin:make-context :options options)))
          (is (= 0 (alfe.cli::run-plan options backend)))
          (is (equal '(1 1 1 1) (counting-backend-calls backend)))
          (is (equal '((1 :eval) (2 :eval) (3 :load) (4 :quit)) (reverse seen))))
        ;; A failing action stops the plan and fails the run.
        (let ((backend (make-instance 'counting-backend :name :counting
                                                        :fail-on :eval))
              (alfe.plugin:*context* (alfe.plugin:make-context :options options)))
          (is (= 1 (alfe.cli::run-plan options backend)))
          (is (equal '(1) (counting-backend-calls backend))))))))
