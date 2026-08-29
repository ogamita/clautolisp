;;;; clautolisp/autolisp-debug-ui-ncurses/source/config-persist.lisp
;;;;
;;;; Unified configuration persistence (windows-and-interactor-templates.issue,
;;;; pjb: "the cascade configs integrate with the existing config files").
;;;;
;;;; The debug-ui settings (aldo.conf / lisp.conf) and the tui-core cascade
;;;; faces / bindings / layout share ONE self-documenting <name>.conf per config,
;;;; in the settings writer's format. This file is the only place that sees both
;;;; systems: it installs the settings save/load HOOKS so the aldo and lisp files
;;;; also carry their cascade keys, and it saves / loads the remaining cascade
;;;; configs (sedit, navi, stack, inspect, inspector, repl) to their own files
;;;; in the same format. Saving is EXPLICIT (pjb, Q7): M-x save-configuration.

(in-package #:clautolisp.ui.ncurses)

(defparameter +cascade-config-keys+ '(:faces :bindings :layout)
  "The tui-core cascade keys a <name>.conf carries beside the scalar settings.")

(defparameter +cascade-only-config-names+
  '("sedit" "navi" "stack" "inspect" "inspector" "repl")
  "Cascade configs with no scalar settings: persisted to their own <name>.conf
in the shared format. (aldo and lisp ride inside the settings files via the
hooks below.)")

(defun %cascade-p (cell) (member (car cell) +cascade-config-keys+))

(defun %cascade-entries (name)
  "The tui-core config NAME's own cascade entries (:faces/:bindings/:layout),
or NIL — the *CONFIG-EXTRA-ENTRIES-HOOK* payload written into <name>.conf."
  (let ((cfg (clautolisp.ui.tui:find-config name)))
    (and cfg (remove-if-not #'%cascade-p
                            (clautolisp.ui.tui:config-settings-alist cfg)))))

(defun %consume-cascade-entries (name alist)
  "Distribute ALIST's cascade keys into the tui-core config NAME; return ALIST
minus those keys (the scalar remainder the settings store keeps). The
*CONFIG-CONSUME-EXTRAS-HOOK*."
  (let ((cfg (clautolisp.ui.tui:ensure-config name)))
    (dolist (cell alist)
      (when (%cascade-p cell)
        (clautolisp.ui.tui:config-set-value cfg (car cell) (cdr cell)))))
  (remove-if #'%cascade-p alist))

(defun install-config-cascade-bridge ()
  "Wire the settings save/load to also carry the tui-core cascade
faces/bindings/layout in the same aldo.conf / lisp.conf files."
  (setf clautolisp.debug.ui:*config-extra-entries-hook*  #'%cascade-entries
        clautolisp.debug.ui:*config-consume-extras-hook* #'%consume-cascade-entries))

(install-config-cascade-bridge)

;;; --- the cascade-only files (same self-documenting format) --------------

(defun save-cascade-config-file (name)
  "Write the tui-core config NAME's cascade entries to <name>.conf (the shared
settings format). Does nothing when the config has no cascade settings."
  (let ((entries (%cascade-entries name)))
    (when entries
      (let ((path (clautolisp.debug.ui:config-save-path name)))
        (ensure-directories-exist path)
        (with-open-file (out path :direction :output :if-exists :supersede
                                  :if-does-not-exist :create
                                  :external-format :utf-8)
          (clautolisp.debug.ui:write-configuration-file
           out entries '() '()
           :name (format nil "~A.conf" name)
           :what (format nil "the ~A interactor cascade" name)
           :save-command "M-x save-configuration"))
        path))))

(defun load-cascade-config-file (name)
  "Read <name>.conf and distribute its cascade keys into the tui-core config."
  (let ((path (clautolisp.debug.ui:config-load-path name)))
    (when (and path (probe-file path))
      (with-open-file (in path :external-format :utf-8)
        (let ((alist (clautolisp.debug.ui:read-aldo-configuration in)))
          (when (consp alist) (%consume-cascade-entries name alist))))
      path)))

(defun save-all-configurations ()
  "Persist every cascade config (pjb Q7, explicit): aldo and lisp through the
settings files — which now carry their faces/bindings via the hooks — and the
rest to their own <name>.conf. Returns T."
  (clautolisp.debug.ui:save-aldo-configuration)
  (clautolisp.debug.ui:save-lisp-configuration)
  (dolist (name +cascade-only-config-names+) (save-cascade-config-file name))
  t)

(defun load-cascade-only-configurations ()
  "Load the cascade-only <name>.conf files (sedit/navi/…). aldo.conf and
lisp.conf are loaded by the settings loaders, which already absorb their
cascade via the consume hook — so tool start-up calls this AFTER those two,
without loading them twice. Returns T."
  (dolist (name +cascade-only-config-names+) (load-cascade-config-file name))
  t)

(defun load-all-configurations ()
  "Load every cascade config from its <name>.conf (aldo/lisp via the settings
loaders + the consume hook; the rest directly). Returns T."
  (clautolisp.debug.ui:load-aldo-configuration)
  (clautolisp.debug.ui:load-lisp-configuration)
  (load-cascade-only-configurations)
  t)

;;; --- the M-x commands ---------------------------------------------------

(defun save-configuration-command (ui session hit arg)
  (declare (ignore session hit arg))
  (save-all-configurations)
  (set-message ui "configuration saved")
  nil)

(defun load-configuration-command (ui session hit arg)
  (declare (ignore session hit arg))
  (load-all-configurations)
  (set-message ui "configuration loaded")
  nil)

;; Register (or replace, on reload) the M-x / , commands.
(dolist (entry (list (cons "save-configuration" #'save-configuration-command)
                     (cons "load-configuration" #'load-configuration-command)))
  (setf *ncurses-commands*
        (cons entry (remove (car entry) *ncurses-commands*
                            :key #'car :test #'string-equal))))
