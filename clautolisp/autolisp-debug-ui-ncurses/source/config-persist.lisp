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

(defparameter +cascade-config-keys+ '(:faces :bindings :layout :layouts)
  "The tui-core cascade keys a <name>.conf carries beside the scalar settings
(:layouts holds the named window layouts, on the \"layouts\" config).")

(defparameter +cascade-only-config-names+
  '("sedit" "navi" "stack" "inspect" "inspector" "repl" "layouts")
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

;;; --- named window layouts (windows-and-interactor-templates.issue Q5) ----
;;; A layout is the frame's split tree recorded as a readable role-tree
;;; (:horizontal RATIO A B | :vertical RATIO A B | ROLE-keyword). Named layouts
;;; live in the "layouts" config's :LAYOUTS alist (name -> spec) and persist with
;;; the rest of the cascade. Replay RE-TILES the existing panes; recreating NEW
;;; windows over saved targets ("2 sedit on different files") waits on the
;;; make-*-window window-creation.

(defparameter +layouts-config-name+ "layouts")

(defun layout->spec (node)
  "Serialise a frame layout NODE (a split list or a window) to a role-tree."
  (if (and (consp node) (member (first node) '(:horizontal :vertical)))
      (destructuring-bind (split ratio a b) node
        (list split ratio (layout->spec a) (layout->spec b)))
      (clautolisp.ui.tui:window-role node)))

(defun spec->layout (ui spec)
  "Rebuild a frame layout tree from SPEC (a role-tree), mapping each role back to
UI's existing window of that role."
  (if (and (consp spec) (member (first spec) '(:horizontal :vertical)))
      (destructuring-bind (split ratio a b) spec
        (list split ratio (spec->layout ui a) (spec->layout ui b)))
      (ui-window ui spec)))

(defun saved-layouts ()
  "The alist (NAME . SPEC) of named layouts."
  (clautolisp.ui.tui:config-value
   (clautolisp.ui.tui:ensure-config +layouts-config-name+) :layouts '()))

(defun save-layout (ui name)
  "Record UI's current frame layout under NAME into the \"layouts\" config
(persisted with the rest by M-x save-configuration; no file I/O here)."
  (let* ((spec (layout->spec (ui-layout ui)))
         (cfg (clautolisp.ui.tui:ensure-config +layouts-config-name+))
         (rest (remove name (clautolisp.ui.tui:config-value cfg :layouts '())
                       :key #'car :test #'string-equal)))
    (clautolisp.ui.tui:config-set-value cfg :layouts (acons name spec rest))
    name))

(defun load-layout (ui name)
  "Re-tile UI's frame to the saved layout NAME (using the existing panes).
Returns T when a layout of that name exists."
  (let ((spec (cdr (assoc name (saved-layouts) :test #'string-equal))))
    (when spec
      (setf (ui-layout ui) (spec->layout ui spec))
      t)))

;;; --- the M-x commands ---------------------------------------------------

(defun %read-name (ui arg prompt)
  (let ((name (if (and arg (plusp (length (string-trim " " arg))))
                  (string-trim " " arg)
                  (read-minibuffer ui prompt))))
    (and name (plusp (length (string-trim " " name))) (string-trim " " name))))

(defun save-layout-command (ui session hit arg)
  (declare (ignore session hit))
  (let ((name (%read-name ui arg "save layout: ")))
    (when name
      (save-layout ui name)
      (set-message ui "layout ~A saved" name)))
  nil)

(defun load-layout-command (ui session hit arg)
  (declare (ignore session hit))
  (let ((name (%read-name ui arg "load layout: ")))
    (when name
      (if (load-layout ui name)
          (set-message ui "layout ~A restored" name)
          (set-message ui "no layout named ~A" name))))
  nil)

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
                     (cons "load-configuration" #'load-configuration-command)
                     (cons "save-layout" #'save-layout-command)
                     (cons "load-layout" #'load-layout-command)))
  (setf *ncurses-commands*
        (cons entry (remove (car entry) *ncurses-commands*
                            :key #'car :test #'string-equal))))
