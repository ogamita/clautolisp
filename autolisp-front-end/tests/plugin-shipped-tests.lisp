(in-package #:autolisp-front-end.tests)

(in-suite autolisp-front-end-suite)

;;;; FiveAM tests for the two plug-ins alfe ships, plugins/epure/ and
;;;; plugins/epuree/, loaded from the source tree. The system they extend is
;;;; tested in plugin-tests.lisp (whose helpers are reused here).
;;;;
;;;; EPURE is Windows only and there is no Windows, no EPURE and no CAD in
;;;; these tests: what is asserted is what the plug-in DECIDES — the launch
;;;; command, the working directory, the lines it adds to run.scr and to the
;;;; VBScript bridges, its refusals — under *HOST-OS-OVERRIDE* :windows, with
;;;; a fake CAD executable and --print-command's launcher seam. Whether the
;;;; real CADs then do what those lines ask is the business of
;;;; issues/open/alfe-plugin-epure-windows-validation.issue.

;;; --- helpers -----------------------------------------------------------

(defun %shipped-plugins-directory ()
  (asdf:system-relative-pathname "autolisp-front-end" "plugins/"))

(defmacro with-shipped-plugins (&body body)
  "BODY with a clean registry into which epure and epuree, straight from the
source tree, are loaded."
  `(with-clean-plugins ()
     (alfe.plugin:load-plugins :directories (list (%shipped-plugins-directory))
                               :include-defaults nil :version "9.9.9")
     ,@body))

(defun %write-file (path text)
  (ensure-directories-exist path)
  (with-open-file (out path :direction :output :if-exists :supersede
                            :if-does-not-exist :create)
    (write-string text out))
  path)

(defun %lines (text)
  (uiop:split-string text :separator '(#\Newline)))

(defun %epure-options (&rest argv)
  "Parse ARGV (plus --no-init) with the shipped plug-ins registered."
  (parse-arguments (append '("--no-init") argv)))

(defmacro with-epure-context ((options-var argv &key (backend :bricscad)) &body body)
  "BODY with OPTIONS-VAR bound to the options of ARGV and a run context for
BACKEND, under a simulated Windows."
  `(let* ((,options-var (apply #'%epure-options ,argv))
          (alfe.backend.cad-common:*host-os-override* :windows)
          (alfe.plugin:*context*
            (alfe.plugin:make-context :options ,options-var :backend ,backend
                                      :version "9.9.9")))
     ,@body))

(defun %fake-cad (directory name)
  "A file standing in for a CAD executable, in DIRECTORY."
  (let ((path (merge-pathnames name directory)))
    (%write-file path "fake")
    (namestring path)))

;;; --- EPURE ----------------------------------------------------------------

(test epure-plugin-loads-and-defines-its-options
  (with-shipped-plugins
    (let ((plugin (alfe.plugin:find-plugin "epure")))
      (is (not (null plugin)))
      (is (eq :source (alfe.plugin:plugin-form plugin)))
      (is (equal '("--epure" "--epure-profile" "--epure-script")
                 (mapcar #'alfe.plugin:plugin-option-long
                         (alfe.plugin:plugin-options plugin)))))))

(test epure-options-parse-and-resolve
  (with-shipped-plugins
    (let ((options (%epure-options "--epure")))
      (is (equal '("epure") (cli-options-plugins-active options)))
      (let ((entry (cdr (assoc "epure" (cli-options-plugin-options options)
                               :test #'string=))))
        (is (string= "Epure" (getf entry :profile)))))
    (let* ((options (%epure-options "--epure" "--epure-profile" "Other"
                                    "--epure-script" "C:/x/y.scr"))
           (entry (cdr (assoc "epure" (cli-options-plugin-options options)
                              :test #'string=))))
      (is (string= "Other" (getf entry :profile)))
      (is (string= "C:/x/y.scr" (getf entry :script))))
    ;; The environment activates it, as $AUTOLISP_EPURE always did.
    (with-plugin-env (("AUTOLISP_EPURE" "1") ("AUTOLISP_EPURE_PROFILE" "FromEnv"))
      (let ((options (%epure-options)))
        (is (equal '("epure") (cli-options-plugins-active options)))
        (is (string= "FromEnv"
                     (getf (cdr (assoc "epure" (cli-options-plugin-options options)
                                       :test #'string=))
                           :profile)))))
    (signals cli-usage-error (%epure-options "--epure-profile" "Other"))))

(test epure-is-ignored-off-windows-and-under-other-backends
  "Off Windows, and under a backend that is not a CAD, --epure changes
nothing and leaves the active list, so that what is transmitted is true."
  (with-shipped-plugins
    (dolist (case '((:linux :bricscad) (:macos :autocad) (:windows :clautolisp)))
      (destructuring-bind (os backend-name) case
        (let* ((options (%epure-options "--epure"
                                        (format nil "--~(~A~)" backend-name)))
               (alfe.backend.cad-common:*host-os-override* os)
               (alfe.plugin:*context* (alfe.plugin:make-context :options options))
               (backend (ecase backend-name
                          (:bricscad (alfe.backend.bricscad:make-bricscad-backend
                                      :executable-path "/fake/bricscad"))
                          (:autocad (alfe.backend.autocad:make-autocad-backend))
                          (:clautolisp (alfe.backend:find-backend :clautolisp)))))
          (alfe.plugin:run-hook :backend-selected backend
                                :options options :dry-run-p nil)
          (is (null (cli-options-plugins-active options))
              "epure stays active for ~S on ~S" backend-name os)
          (is (eq :auto (alfe.cli::cli-options-mode options)) "mode untouched"))))))

(test epure-autocad-needs-the-gui
  "Under AutoCAD --epure defaults the mode to COM automation, keeps an
explicit automation, and refuses accoreconsole (batch)."
  (with-shipped-plugins
    (with-plugin-temp-directory (dir)
      (let ((script (namestring (%write-file (merge-pathnames "epure.scr" dir) "x")))
            (backend (alfe.backend.autocad:make-autocad-backend)))
        (flet ((select (&rest mode-args)
                 (with-epure-context (options (append (list "--autocad" "--epure"
                                                            "--epure-script" script)
                                                      mode-args)
                                      :backend :autocad)
                   (alfe.plugin:run-hook :backend-selected backend
                                         :options options :dry-run-p nil)
                   (alfe.cli::cli-options-mode options))))
          (is (eq :automation (select)))
          (is (eq :automation (select "--mode" "automation")))
          (handler-case (progn (select "--mode" "batch") (fail "no refusal"))
            (cli-usage-error (condition)
              (is (search "accoreconsole"
                          (alfe.error:cli-usage-error-message condition)))
              (is (= 2 (exit-code-for-condition condition))))))))))

(test epure-checks-its-control-script
  "The control script must exist — unless this is a dry run — and %APPDATA%
gives the default one."
  (with-shipped-plugins
    (let ((backend (alfe.backend.bricscad:make-bricscad-backend
                    :executable-path "/fake/bricscad.exe")))
      (flet ((select (args &key dry-run-p)
               (with-epure-context (options (append '("--bricscad" "--epure") args))
                 (alfe.plugin:run-hook :backend-selected backend
                                       :options options :dry-run-p dry-run-p)
                 t)))
        ;; Named, missing: refused with exit 4 (a dry run does not look).
        (handler-case (progn (select '("--epure-script" "/no/such/control.scr"))
                             (fail "no error"))
          (alfe.error:backend-bootstrap-error (condition)
            (is (eq :epure-script-missing (alfe.error:backend-error-code condition)))
            (is (search "/no/such/control.scr"
                        (alfe.error:backend-error-message condition)))
            ;; and it says what the absence MEANS: the path is fixed for
            ;; a given EPURE version, so a miss is "not installed" or
            ;; "the version moved" -- not a puzzle for the reader
            ;; (pjb, 2026-09-25).
            (let ((message (alfe.error:backend-error-message condition)))
              (is (search "not installed" message))
              (is (search "version changed" message))
              (is (search "--epure-script" message)))
            (is (= 4 (exit-code-for-condition condition)))))
        (is (select '("--epure-script" "/no/such/control.scr") :dry-run-p t))
        ;; No name and no %APPDATA%: cannot guess.
        (with-plugin-env (("APPDATA" ""))
          (handler-case (progn (select '()) (fail "no error"))
            (alfe.error:backend-bootstrap-error (condition)
              (is (eq :epure-script-unknown (alfe.error:backend-error-code condition))))))
        ;; No name, %APPDATA% with the EPURE install in it.
        (with-plugin-temp-directory (appdata)
          (%write-file (merge-pathnames
                        "sncf/epure/epure 2022_b/control_path_epure_2022.scr" appdata)
                       "x")
          (with-plugin-env (("APPDATA" (string-right-trim "/" (namestring appdata))))
            (is (select '()))))))))

(test epure-rewrites-the-bricscad-batch-command-line
  "/Automation goes (EPURE needs the frame window), any other profile pair
goes, and /p PROFILE stands right before the /b script pair."
  (with-shipped-plugins
    (with-epure-context (options '("--bricscad" "--epure"))
      (flet ((filter (argv &key (variant :batch))
               (alfe.plugin:run-hook :launch-argv argv :variant variant
                                                       :workdir #p"/w/")))
        (is (equal '("C:/b/bricscad.exe" "C:/t.dwt" "/p" "Epure" "/b" "C:/w/run.scr")
                   (filter '("C:/b/bricscad.exe" "/Automation" "C:/t.dwt"
                             "/p" "clean" "/b" "C:/w/run.scr"))))
        (is (equal '("bricscad.exe" "/p" "Epure" "/b" "run.scr")
                   (filter '("bricscad.exe" "-P" "x" "/b" "run.scr"))))
        (is (equal '("bricscad.exe" "/p" "Epure")
                   (filter '("bricscad.exe"))))
        ;; COM automation starts the CAD itself: nothing to rewrite.
        (is (equal '("cscript" "//nologo" "bridge.vbs")
                   (filter '("cscript" "//nologo" "bridge.vbs") :variant :automation))))
      (let ((alfe.plugin:*context* (alfe.plugin:make-context :options options
                                                             :backend :autocad)))
        (is (equal '("cscript" "//nologo" "bridge.vbs")
                   (alfe.plugin:run-hook :launch-argv '("cscript" "//nologo" "bridge.vbs")
                                         :variant :automation)))))
    (with-epure-context (options '("--bricscad" "--epure" "--epure-profile" "Site B"))
      (is (equal '("x.exe" "/p" "Site B" "/b" "s")
                 (alfe.plugin:run-hook :launch-argv '("x.exe" "/b" "s")
                                       :variant :batch))))))

(test epure-launches-from-the-cad-user-data-cache
  "Like the wrappers: cd to <CAD dir>/UserDataCache, or to the CAD's own
directory when there is none."
  (with-shipped-plugins
    (with-plugin-temp-directory (dir)
      (let ((exe (%fake-cad dir "bricscad.exe")))
        (with-epure-context (options '("--bricscad" "--epure"))
          (flet ((options-for (&optional (variant :batch))
                   (alfe.plugin:run-hook :launch-options
                                         (list :directory nil :environment '(("A" . "b")))
                                         :variant variant :argv (list exe "/b" "s"))))
            (is (equal (uiop:ensure-directory-pathname dir)
                       (getf (options-for) :directory)))
            (ensure-directories-exist (merge-pathnames "UserDataCache/" dir))
            (is (equal (merge-pathnames "UserDataCache/" (uiop:ensure-directory-pathname dir))
                       (getf (options-for) :directory)))
            ;; Other options survive; COM automation is left alone.
            (is (equal '(("A" . "b")) (getf (options-for) :environment)))
            (is (null (getf (options-for :automation) :directory)))))))))

(test epure-launcher-lines
  (with-shipped-plugins
    (let ((script "C:/Users/u/AppData/Roaming/sncf/epure/epure 2022_b/control_path_epure_2022.scr"))
      (with-epure-context (options (list "--bricscad" "--epure" "--epure-script" script
                                         "--epure-profile" "Ep\"ure"))
        (flet ((lines (slot kind)
                 (alfe.plugin:run-hook :launcher-lines slot :kind kind :variant :batch)))
          ;; run.scr LOADS the control script: it is AutoLISP source
          ;; despite the .scr name (it reads VENDORNAME and loads EPURE's
          ;; .des or .vlx), and LOAD returns, so the next line -- alfe's
          ;; own runtime -- runs. A nested ._SCRIPT does not return on
          ;; BricsCAD V25: run.scr began and stopped there, BOOTING until
          ;; the timeout, while the same script without EPURE completed
          ;; (verify:epure:windows, 2026-09-25).
          ;;
          ;; The path keeps a space (EPURE's own `epure 2022_b'), which
          ;; is what broke the earlier ._SCRIPT spelling: ~S writes it as
          ;; an AutoLISP string, where a space is just a character.
          (is (find #\Space script) "the path under test must contain a space")
          (is (equal (list (format nil "(load ~S)" script))
                     (lines :before-load :scr)))
          (is (null (lines :after-load :scr)))
          ;; VBScript: ASCII, quotes doubled.
          (let ((after-app (format nil "~{~A~%~}" (lines :after-app :vbs)))
                (before-load (format nil "~{~A~%~}" (lines :before-load :vbs))))
            (is (search "app.Preferences.Profiles.ActiveProfile = \"Ep\"\"ure\"" after-app))
            (is (search "On Error Resume Next" after-app))
            (is (search "._SCRIPT" before-load))
            (is (search script before-load))
            (is (search "doc.SendCommand(epureCmd)" before-load))
            (is (every (lambda (c) (< (char-code c) 128)) (concatenate 'string after-app before-load)))))))))

;;; --- EPURE through the backends (mock CAD, --print-command) ---------------

(defun %print-command (options backend)
  "PRINT-COMMAND-PLAN, keeping the workdir. (values printed-line workdir)."
  (let* ((wd-file (merge-pathnames (format nil "alfe-plugin-wd-~D.txt"
                                           (random 1000000 *plugin-test-random*))
                                   (uiop:temporary-directory)))
         (stdout (make-string-output-stream)))
    (setf (cli-options-write-workdir-path options) (namestring wd-file)
          (alfe.cli::cli-options-keep-workdir-p options) t)
    (let ((code (print-command-plan options backend :version-text "9.9.9"
                                                    :stream stdout)))
      (is (= 0 code)))
    (let ((workdir (uiop:ensure-directory-pathname
                    (with-open-file (in wd-file) (read-line in)))))
      (ignore-errors (delete-file wd-file))
      (values (string-trim '(#\Newline) (get-output-stream-string stdout)) workdir))))

(test epure-bricscad-batch-end-to-end
  "--bricscad --epure, staged for real: the printed command starts in
UserDataCache with /p Epure before /b and no /Automation, and run.scr runs
EPURE's control script before it loads alfe's run-common.lsp. Without
--epure the same run has /Automation, no /p and a plain run.scr."
  (with-shipped-plugins
    (with-plugin-temp-directory (dir)
      (let* ((exe (%fake-cad dir "bricscad.exe"))
             (script (namestring (%write-file (merge-pathnames "control.scr" dir) "x")))
             (backend (alfe.backend.bricscad:make-bricscad-backend
                       :executable-path exe :variant :batch)))
        (ensure-directories-exist (merge-pathnames "UserDataCache/" dir))
        ;; With EPURE.
        (with-epure-context (options (list "--bricscad" "--epure" "--epure-script" script
                                           "-x" "(princ 1)"))
          (alfe.plugin:run-hook :backend-selected backend :options options
                                                          :dry-run-p nil)
          (multiple-value-bind (command workdir) (%print-command options backend)
            (unwind-protect
                 (progn
                   (is (search "cd " command))
                   (is (search "UserDataCache" command))
                   (is (search "/p Epure /b" command))
                   (is (not (search "/Automation" command)))
                   (let* ((scr (uiop:read-file-string (merge-pathnames "run.scr" workdir)))
                          (lines (%lines scr))
                          (control-at (position (format nil "(load ~S)" script) lines
                                                :test #'string=))
                          (runtime-at (position-if
                                       (lambda (l) (and (search "(load " l)
                                                        (search "run-common" l)))
                                       lines)))
                     ;; EPURE's control script is LOADED, and alfe's
                     ;; runtime is loaded after it -- no nested ._SCRIPT,
                     ;; which BricsCAD does not return from.
                     (is (integerp control-at))
                     (is (integerp runtime-at))
                     (is (< control-at runtime-at))
                     (is (not (search "._SCRIPT" scr)))))
              (uiop:delete-directory-tree workdir :validate t :if-does-not-exist :ignore))))
        ;; Without it: the plug-in's registered, but the run is what it was.
        (let* ((alfe.backend.cad-common:*host-os-override* :windows)
               (options (%epure-options "--bricscad" "-x" "(princ 1)"))
               (alfe.plugin:*context* (alfe.plugin:make-context :options options)))
          (multiple-value-bind (command workdir) (%print-command options backend)
            (unwind-protect
                 (progn
                   (is (search "/Automation" command))
                   (is (not (search "/p Epure" command)))
                   (is (not (search "cd " command)))
                   (is (not (search "._SCRIPT"
                                    (uiop:read-file-string
                                     (merge-pathnames "run.scr" workdir))))))
              (uiop:delete-directory-tree workdir :validate t :if-does-not-exist :ignore))))))))

(test epure-autocad-automation-end-to-end
  "--autocad --epure: COM automation, the bridge activates the profile after
the application exists (before it waits for it) and sends the control script
after the document is active, before the (load …) of run-common.lsp."
  (with-shipped-plugins
    (with-plugin-temp-directory (dir)
      (let* ((script (namestring (%write-file (merge-pathnames "control.scr" dir) "x")))
             (backend (alfe.backend.autocad:make-autocad-backend
                       :executable-path "C:/fake/acad.exe")))
        (with-epure-context (options (list "--autocad" "--epure" "--epure-script" script
                                           "-x" "(princ 1)")
                             :backend :autocad)
          (alfe.plugin:run-hook :backend-selected backend :options options
                                                          :dry-run-p nil)
          (is (eq :automation (alfe.cli::cli-options-mode options)))
          (multiple-value-bind (command workdir) (%print-command options backend)
            (unwind-protect
                 (let* ((vbs (uiop:read-file-string
                              (merge-pathnames "bridge-autocad.vbs" workdir)))
                        (profile (search "ActiveProfile = \"Epure\"" vbs))
                        (quiescent (search "WaitQuiescent app, waitSecs" vbs))
                        (active (search "Set doc = app.ActiveDocument" vbs))
                        (sends (search "epureCmd = \"._SCRIPT \"" vbs))
                        (load (search "SendCommand (load" vbs)))
                   (is (search "cscript" command))
                   (is (not (search "${" vbs)) "no unfilled slot")
                   (is (every #'integerp (list profile quiescent active sends load)))
                   (is (< profile quiescent))
                   (is (< active sends load))
                   (is (search "control.scr" vbs)))
              (uiop:delete-directory-tree workdir :validate t :if-does-not-exist :ignore))))))))

(test cad-launcher-scripts-are-unchanged-without-plug-ins
  "With no plug-in active the VBScript bridges and run.scr are exactly the
templates: the slot lines are removed, nothing else changes."
  (with-clean-plugins ()
    (with-plugin-temp-directory (dir)
      (flet ((emitted (function)
               (let ((path (merge-pathnames "x.vbs" dir)))
                 (funcall function path)
                 (uiop:read-file-string path))))
        (dolist (case (list (list alfe.backend.autocad::*bridge-autocad-vbs-template*
                                  (lambda (path)
                                    (alfe.backend.autocad:emit-bridge-vbs
                                     path :runtime-load-path #p"/w/run-common.lsp"
                                          :status-path #p"/w/s" :error-path #p"/w/e")))
                            (list alfe.backend.bricscad::*bridge-bricscad-vbs-template*
                                  (lambda (path)
                                    (alfe.backend.bricscad::emit-bridge-vbs
                                     path :runtime-load-path #p"/w/run-common.lsp"
                                          :status-path #p"/w/s" :error-path #p"/w/e")))))
          (destructuring-bind (template function) case
            (let ((text (emitted function)))
              (is (search "${PLUGIN_AFTER_APP}" template))
              (is (search "${PLUGIN_BEFORE_LOAD}" template))
              (is (not (search "PLUGIN_" text)))
              ;; Same number of lines as the template less its two slot lines.
              (is (= (- (length (%lines template)) 2) (length (%lines text)))))))))))

(test epure-shows-in-dry-run-and-run-off-windows
  "The scenario every CI host can run: --epure with --bricscad, dry run."
  (with-shipped-plugins
    (multiple-value-bind (code out)
        (%run-alfe "--bricscad" "--epure" "--epure-profile" "P" "--epure-script" "/x.scr"
                   "--dry-run" "-x" "(+ 1 2)")
      (is (= 0 code))
      (is (search "backend:   BRICSCAD" out)))))

;;; --- EPUREE ----------------------------------------------------------------

(defparameter *fake-alpm*
  "(setq *alpm-calls* nil)
(defun alpm-register-directory (dir recursive)
  (setq *alpm-calls* (append *alpm-calls* (list (list 'register dir recursive))))
  dir)
(defun alpm-load-system (name force)
  (setq *alpm-calls* (append *alpm-calls* (list (list 'load name force))))
  (defun epuree-initialize ()
    (setq *alpm-calls* (append *alpm-calls* (list (list 'initialize))))
    \"\")
  name)
"
  "A stand-in for ALPM's alpm.lsp that records what it is asked to do; loading
the system defines epuree-initialize, as the real epuree.alpm does.")

(test epuree-plugin-loads-and-defines-its-options
  (with-shipped-plugins
    (let ((plugin (alfe.plugin:find-plugin "epuree")))
      (is (not (null plugin)))
      (is (equal '("--epuree" "--epuree-path" "--epuree-alpm")
                 (mapcar #'alfe.plugin:plugin-option-long
                         (alfe.plugin:plugin-options plugin)))))
    (let ((options (%epure-options "--epuree" "--epuree-path" "/a" "--epuree-path" "/b")))
      (is (equal '("/a" "/b")
                 (getf (cdr (assoc "epuree" (cli-options-plugin-options options)
                                   :test #'string=))
                       :paths))))
    (with-plugin-env (("EPUREE_PATH" (format nil "/p~A/q" (if (uiop:os-windows-p) #\; #\:)))
                      ("AUTOLISP_EPUREE" "1"))
      (is (equal '("/p" "/q")
                 (getf (cdr (assoc "epuree" (cli-options-plugin-options (%epure-options))
                                   :test #'string=))
                       :paths))))))

(test epuree-puts-its-actions-in-front-of-the-plan
  "ALPM is loaded, each --epuree-path is registered, the system is loaded and
initialized — before the init files and the user's actions, on every backend."
  (with-shipped-plugins
    (with-plugin-temp-directory (dir)
      (let* ((alpm (namestring (%write-file (merge-pathnames "alpm.lsp" dir) *fake-alpm*)))
             (options (%epure-options "--epuree" "--epuree-alpm" alpm
                                      "--epuree-path" "/a/one" "--epuree-path" "/b/two"
                                      "-x" "(+ 1 2)"))
             (alfe.plugin:*context* (alfe.plugin:make-context :options options))
             (plan (alfe.cli::effective-plan options))
             (texts (mapcar (lambda (action)
                              (let ((payload (alfe.backend:action-payload action)))
                                (if (stringp payload) payload (list payload))))
                            plan)))
        (is (= 7 (length plan)) "5 plug-in actions, the user's, the terminator")
        (is (eq :eval (alfe.backend:action-kind (first plan))))
        (is (search "(load \"" (first texts)))
        (is (search "alpm.lsp\")" (first texts)))
        (is (string= "(alpm-register-directory \"/a/one\" T)" (second texts)))
        (is (string= "(alpm-register-directory \"/b/two\" T)" (third texts)))
        (is (string= "(alpm-load-system \"epuree\" nil)" (fourth texts)))
        (is (string= "(epuree-initialize)" (fifth texts)))
        (is (string= "(+ 1 2)" (sixth texts)))))))

(test epuree-loads-the-system-through-alpm-on-the-clautolisp-backend
  "End to end against a real engine: the fake ALPM records the calls the
plug-in's actions made, in order — the initialization after the loading —
before the user's own action ran."
  (with-shipped-plugins
    (with-plugin-temp-directory (dir)
      (let ((alpm (namestring (%write-file (merge-pathnames "alpm.lsp" dir) *fake-alpm*))))
        (multiple-value-bind (code out err)
            (%run-alfe "--epuree" "--epuree-alpm" alpm "--epuree-path" "/lisp/tree"
                       "-x" "(princ (mapcar 'car *alpm-calls*))"
                       "-x" "(princ (cadr (car *alpm-calls*)))")
          (declare (ignore err))
          (is (= 0 code))
          (is (search "(REGISTER LOAD INITIALIZE)" out))
          (is (search "/lisp/tree" out)))))))

(test epuree-needs-an-alpm-lsp
  "A named alpm.lsp must exist; when none is named and none is in the usual
places the run is refused with the places tried."
  (with-shipped-plugins
    (multiple-value-bind (code out err)
        (%run-alfe "--epuree" "--epuree-alpm" "/nonexistent/alpm.lsp"
                   "--dry-run" "-x" "(+ 1 2)")
      (declare (ignore out))
      (is (= 2 code))
      (is (search "alpm.lsp not found: /nonexistent/alpm.lsp" err)))
    ;; The plug-in's package does not exist until it is loaded, so its
    ;; variable is found at run time.
    (progv (list (find-symbol "*ALPM-CANDIDATES-FUNCTION*" "ALFE.PLUGIN.EPUREE"))
        (list (lambda () '("/nowhere/a/alpm.lsp" "/nowhere/b/alpm.lsp")))
      (with-plugin-env (("ALPM_LSP" ""))
        (multiple-value-bind (code out err)
            (%run-alfe "--epuree" "--dry-run" "-x" "(+ 1 2)")
          (declare (ignore out))
          (is (= 2 code))
          (is (search "/nowhere/a/alpm.lsp, /nowhere/b/alpm.lsp" err))
          (is (search "--epuree-alpm" err)))))))

(test epuree-alpm-lsp-from-the-environment-and-dry-run
  (with-shipped-plugins
    (with-plugin-temp-directory (dir)
      (let ((alpm (namestring (%write-file (merge-pathnames "alpm.lsp" dir) *fake-alpm*))))
        (with-plugin-env (("ALPM_LSP" alpm))
          (multiple-value-bind (code out)
              (%run-alfe "--epuree" "--dry-run" "-x" "(+ 1 2)")
            (is (= 0 code))
            (is (search "alpm-load-system" out))
            (is (search "(epuree-initialize)" out))
            (is (< (search "alpm-load-system" out) (search "(epuree-initialize)" out)))
            (is (< (search "(epuree-initialize)" out) (search "(+ 1 2)" out)))))))))
