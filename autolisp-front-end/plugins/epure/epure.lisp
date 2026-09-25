;;;; plugins/epure/epure.lisp — the EPURE plug-in for alfe.
;;;;
;;;; EPURE is the SNCF Réseau vertical application (menus, profile, SCHMS+)
;;;; that the site's CAD sessions run under. This plug-in launches BricsCAD
;;;; or AutoCAD the way scripts/bricscad-epure and scripts/autocad-epure do
;;;; (and the legacy `autolisp --epure' did): with the `Epure' user profile,
;;;; from the CAD's UserDataCache directory, running EPURE's control script —
;;;; and arranges for that script to run before alfe's own runtime is
;;;; loaded.
;;;;
;;;; Specified by documentation/alfe--specifications.org, chapter "EPURE",
;;;; and issues/closed/alfe-plugin-epure.issue. Windows only; silently
;;;; ignored elsewhere and under --clautolisp. NOT validated on real CADs:
;;;; see issues/open/alfe-plugin-epure-windows-validation.issue.

(defpackage #:alfe.plugin.epure
  (:use #:cl #:alfe.plugin)
  (:import-from #:alfe.error
                #:cli-usage-error
                #:backend-bootstrap-error)
  (:import-from #:alfe.logging
                #:log-verbose)
  (:import-from #:alfe.backend.cad-common
                #:windows-p
                #:vbs-escape)
  (:import-from #:clautolisp.autolisp-cli
                #:cli-options-mode))

(in-package #:alfe.plugin.epure)

(define-plugin "epure"
  :version "1.0.0"
  :description "Run BricsCAD or AutoCAD under the EPURE profile and control script (Windows only)."
  :options ((:flag  "--epure" :activates t :env "AUTOLISP_EPURE"
                    :doc "Run the CAD under EPURE (Windows only; ignored elsewhere).")
            (:value "--epure-profile" :key :profile :arg "NAME"
                    :env "AUTOLISP_EPURE_PROFILE" :default "Epure"
                    :doc "CAD user profile EPURE runs under.")
            (:value "--epure-script" :key :script :arg "FILE"
                    :env "AUTOLISP_EPURE_SCRIPT"
                    :doc "EPURE control script (default: the one under %APPDATA%/sncf/epure).")))

;;; --- the control script ---------------------------------------------

(defun forward-slashes (string)
  (substitute #\/ #\\ string))

(defun default-control-script (backend)
  "%APPDATA%/sncf/epure/epure 2022[_b]/control_path_epure_2022.scr, the file
EPURE's own installer puts in the user's roaming profile; NIL when %APPDATA%
is not set."
  (let ((appdata (uiop:getenv "APPDATA")))
    (when (and appdata (plusp (length appdata)))
      (format nil "~A/sncf/epure/~A/control_path_epure_2022.scr"
              (string-right-trim "/" (forward-slashes appdata))
              (ecase backend
                (:bricscad "epure 2022_b")
                (:autocad  "epure 2022"))))))

(defun control-script (backend)
  "The control script the plug-in was asked for, or the default one, with
forward slashes."
  (let ((script (or (plugin-option :script) (default-control-script backend))))
    (and script (forward-slashes script))))

;;; --- backend selection: the checks and the mode ---------------------

(define-plugin-hook "epure" :backend-selected (ctx backend &key options dry-run-p)
  (let ((name (alfe.backend:backend-name backend)))
    (cond
      ((not (member name '(:bricscad :autocad)))
       (log-verbose "epure: no effect under the ~(~A~) backend; ignored" name)
       (deactivate-plugin ctx))
      ((not (windows-p))
       (log-verbose "epure: Windows only; ignored")
       (deactivate-plugin ctx))
      (t
       ;; AutoCAD: EPURE needs the full GUI, so COM automation is the
       ;; default; accoreconsole (batch) has no GUI and no profiles.
       (when (eq name :autocad)
         (case (cli-options-mode options)
           (:auto (setf (cli-options-mode options) :automation))
           (:batch (error 'cli-usage-error
                          :option "--epure"
                          :message "EPURE requires the full AutoCAD GUI; accoreconsole (--mode batch) has no profile support. Use --mode automation."))))
       (unless dry-run-p
         (let ((script (control-script name)))
           (cond
             ((null script)
              (error 'backend-bootstrap-error
                     :backend name :code :epure-script-unknown
                     :message "cannot locate the EPURE control script: %APPDATA% is not set; pass --epure-script FILE or set $AUTOLISP_EPURE_SCRIPT."))
             ;; The path is fixed for a given EPURE version, so its
             ;; absence says something definite: EPURE is not installed
             ;; here, or its version moved and this directory is no
             ;; longer the one (pjb, 2026-09-25). Either way, stop now --
             ;; not at a READY timeout with a CAD already on screen.
             ((not (probe-file script))
              (error 'backend-bootstrap-error
                     :backend name :code :epure-script-missing
                     :message (format nil "EPURE control script not found: ~A~
~%  EPURE is not installed for this user, or its version changed and that~
~%  directory is no longer the right one. Name the script with~
~%  --epure-script FILE or $AUTOLISP_EPURE_SCRIPT."
                                      script))))))))))

;;; --- the launch: argv and working directory (BricsCAD batch) --------

(defun switch-p (argument &rest names)
  (and (stringp argument) (member argument names :test #'string-equal)))

(define-plugin-hook "epure" :launch-argv (ctx argv &key backend variant)
  ;; Only BricsCAD batch is a direct launch of the CAD executable; the COM
  ;; bridges start the CAD themselves.
  (if (and (eq backend :bricscad) (eq variant :batch))
      (let ((kept '()))
        ;; No /Automation: EPURE loads a CUIX and menus, it needs the frame
        ;; window. No other /p or -P: the profile is EPURE's.
        (loop while argv
              do (let ((argument (pop argv)))
                   (cond ((switch-p argument "/Automation") nil)
                         ((switch-p argument "/p" "-P") (pop argv))
                         (t (push argument kept)))))
        (setf kept (nreverse kept))
        (let ((position (position-if (lambda (a) (switch-p a "/b" "-B")) kept)))
          (append (subseq kept 0 position)
                  (list "/p" (plugin-option :profile))
                  (and position (subseq kept position)))))
      argv))

(define-plugin-hook "epure" :launch-options (ctx options &key backend variant argv)
  (when (and (eq backend :bricscad) (eq variant :batch) argv)
    ;; Like the wrappers: cd to <CAD dir>/UserDataCache, or to the CAD's
    ;; own directory when that does not exist.
    (let* ((executable (pathname (first argv)))
           (directory (make-pathname :name nil :type nil :version nil
                                     :defaults executable))
           (cache (merge-pathnames "UserDataCache/" directory)))
      (setf options (list* :directory
                           (if (uiop:directory-exists-p cache) cache directory)
                           (loop for (key value) on options by #'cddr
                                 unless (eq key :directory)
                                   append (list key value))))))
  options)

;;; --- the launcher script ---------------------------------------------

(defun profile-activation-lines (profile)
  "VBScript: try to make PROFILE the active profile. A failure is written
to the errors file and the run goes on with the current profile."
  (list "On Error Resume Next"
        (format nil "app.Preferences.Profiles.ActiveProfile = \"~A\"" (vbs-escape profile))
        "If Err.Number <> 0 Then"
        (format nil "  AppendLine errFile, \"WARN COM bridge: cannot activate the CAD profile '~A' (\" & Err.Description & \"); using the current profile.\""
                (vbs-escape profile))
        "  Err.Clear"
        "End If"
        "On Error GoTo 0"))

(defun send-script-lines (script)
  "VBScript: ask the running CAD to run SCRIPT, as the legacy bridge did."
  (list "Dim epureCmd"
        (format nil "epureCmd = \"._SCRIPT \" & Chr(34) & \"~A\" & Chr(34) & vbCr"
                (vbs-escape script))
        "On Error Resume Next"
        "Call doc.SendCommand(epureCmd)"
        "If Err.Number <> 0 Then"
        "  AppendLine errFile, \"WARN COM bridge: EPURE _SCRIPT send failed: \" & Err.Description"
        "  Err.Clear"
        "End If"
        "On Error GoTo 0"))

(define-plugin-hook "epure" :launcher-lines (ctx slot &key kind backend)
  (let ((script (control-script backend)))
    (ecase kind
      ;; run.scr: LOAD EPURE's control script, then (next line of the
      ;; script) alfe's own runtime.
      ;;
      ;; NOT a nested ._SCRIPT. That was inherited from the legacy
      ;; wrapper, on the assumption that control returns to the outer
      ;; script afterwards, and on the Windows runner it does not: run.scr
      ;; BEGAN and then stopped there, BricsCAD sitting at BOOTING until
      ;; the timeout, while the same run.scr without EPURE completed
      ;; (verify:epure:windows, 2026-09-25, BricsCAD V25).
      ;;
      ;; The file is AutoLISP SOURCE despite its .scr name -- it reads
      ;; VENDORNAME and loads EPURE's .des (BricsCAD) or .vlx (AutoCAD)
      ;; accordingly -- so LOAD is what it wants, and (load ...) simply
      ;; returns, leaving the next line to run. pjb, 2026-09-25.
      (:scr (when (and (eq slot :before-load) script)
              (list (format nil "(load ~S)" script))))
      (:vbs (case slot
              (:after-app (profile-activation-lines (plugin-option :profile)))
              (:before-load (when script (send-script-lines script))))))))
