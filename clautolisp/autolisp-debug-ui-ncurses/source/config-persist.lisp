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
;;; A layout is the frame's split tree recorded as a readable tree:
;;;   (:horizontal RATIO A B) | (:vertical RATIO A B)  -- a split;
;;;   ROLE                                             -- a debugger pane
;;;                                                       (:stack :source
;;;                                                       :interactor :repl);
;;;   (:window ROLE COMMAND ARG)                       -- a USER-MADE window:
;;;      the make-*-window COMMAND and the ARG text it was made with.
;;; pjb (Q5): "record their constructor parameters and replay them". Restoring
;;; a layout closes the current user-made windows, replays each (:window ...)
;;; leaf's command with its argument -- recreating the interactor (a sedit on
;;; the same form, a lisp REPL instance, an inspector on the value of the same
;;; expression...) -- and re-tiles the panes and the new windows by the tree.
;;; Named layouts live in the "layouts" config's :LAYOUTS alist (name -> spec)
;;; and persist with the rest of the cascade by the explicit M-x
;;; save-configuration (Q7). The layout named "debugger", when saved, is the
;;; one a new ncurses debugger opens with (at its first stop): the fixed four
;;; panes are only the default when no such layout exists.

(defparameter +layouts-config-name+ "layouts")

(defparameter +startup-layout-name+ "debugger"
  "The saved layout a new ncurses debugger UI applies at its first stop.")

(defun %pane-window-p (window)
  "True for the debugger's own panes (and the minibuffer), which a layout
re-tiles but never recreates or closes."
  (or (member (window-role window) +window-roles+)
      (eq (window-role window) :minibuffer)))

(defun layout->spec (node &optional ui)
  "Serialise a frame layout NODE (a split list or a window) to a layout spec.
With UI, a user-made window that has a recipe is recorded as
(:window ROLE COMMAND ARG) so it can be recreated; otherwise a leaf is its role."
  (if (and (consp node) (member (first node) '(:horizontal :vertical)))
      (destructuring-bind (split ratio a b) node
        (list split ratio (layout->spec a ui) (layout->spec b ui)))
      (let ((recipe (and ui (not (%pane-window-p node)) (window-recipe ui node))))
        (if recipe
            (list :window (clautolisp.ui.tui:window-role node) (car recipe) (cdr recipe))
            (clautolisp.ui.tui:window-role node)))))

(defun %recipe-leaf-p (spec)
  (and (consp spec) (eq (first spec) :window)))

(defun replay-window-recipe (ui command arg &key session hit)
  "Recreate a user-made window by running its make-*-window COMMAND with ARG, as
the user did. Returns the new window, or NIL when the command made none (e.g. a
stack browser outside a stop) or is unknown."
  (let ((entry (assoc command *ncurses-commands* :test #'string-equal))
        (before (copy-list (ui-windows ui))))
    (when entry
      (let ((*replaying-layout* t))
        (handler-case (funcall (cdr entry) ui session hit arg)
          (error (e) (set-message ui "layout: ~A: ~A" command e))))
      (find-if (lambda (w) (not (member w before))) (ui-windows ui)))))

(defun spec->layout (ui spec &key session hit)
  "Rebuild a frame layout tree from SPEC: a role leaf maps to UI's existing
window of that role, a (:window ROLE COMMAND ARG) leaf is recreated by replaying
its command. A leaf that yields no window collapses out of its split. Returns
the tree, or NIL when nothing could be placed."
  (cond
    ((and (consp spec) (member (first spec) '(:horizontal :vertical)))
     (destructuring-bind (split ratio a b) spec
       (let ((la (spec->layout ui a :session session :hit hit))
             (lb (spec->layout ui b :session session :hit hit)))
         (cond ((and la lb) (list split ratio la lb))
               (t (or la lb))))))
    ((%recipe-leaf-p spec)
     (destructuring-bind (role command &optional (arg "")) (rest spec)
       (declare (ignore role))
       (replay-window-recipe ui command arg :session session :hit hit)))
    (t (ui-window ui spec))))

(defun saved-layouts ()
  "The alist (NAME . SPEC) of named layouts."
  (clautolisp.ui.tui:config-value
   (clautolisp.ui.tui:ensure-config +layouts-config-name+) :layouts '()))

(defun save-layout (ui name)
  "Record UI's current frame layout -- with the recipes of its user-made
windows -- under NAME into the \"layouts\" config (persisted with the rest by
M-x save-configuration; no file I/O here)."
  (let* ((spec (layout->spec (ui-layout ui) ui))
         (cfg (clautolisp.ui.tui:ensure-config +layouts-config-name+))
         (rest (remove name (clautolisp.ui.tui:config-value cfg :layouts '())
                       :key #'car :test #'string-equal)))
    (clautolisp.ui.tui:config-set-value cfg :layouts (acons name spec rest))
    name))

(defun close-user-windows (ui)
  "Close every user-made window of UI (keeping the debugger panes)."
  (dolist (w (copy-list (ui-windows ui)))
    (unless (%pane-window-p w)
      (remhash w (ncurses-ui-window-recipes ui))
      (clautolisp.ui.tui:remove-window-from-frame (ncurses-ui-frame ui) w))))

(defun %reseat-window-manager (ui)
  "Make the active window a tiled one, and the only one carrying :WINDOW-MANAGER."
  (let ((leaves (clautolisp.ui.tui:layout-leaves (ui-layout ui))))
    (unless (member (active-window ui) leaves)
      (setf (frame-selected-window (ncurses-ui-frame ui)) (first leaves)))
    (dolist (w (ui-windows ui))
      (setf (window-stack w) (remove :window-manager (window-stack w))))
    (let ((active (active-window ui)))
      (when active (push :window-manager (window-stack active))))))

(defun load-layout (ui name &key session hit)
  "Restore the saved layout NAME in UI: close the current user-made windows,
recreate the layout's own (replaying their make-*-window commands, over the stop
SESSION/HIT when given) and re-tile. Returns T when a layout of that name
exists."
  (let ((spec (cdr (assoc name (saved-layouts) :test #'string-equal))))
    (when spec
      (close-user-windows ui)
      ;; replay from the debugger's interactor pane, so a recreated window
      ;; shares its (aldo lisp) stack bottom, as one made from there would
      (let ((pane (ui-window ui :interactor)))
        (when pane (activate-window ui pane)))
      (let ((tree (spec->layout ui spec :session session :hit hit)))
        (when tree
          (setf (ui-layout ui) tree))
        (%reseat-window-manager ui))
      t)))

(defun apply-startup-layout (ui session hit)
  "At UI's first stop, restore the saved layout named \"debugger\" when there
is one (the debugger's default layout, pjb Q5). Only once per UI; a failure
leaves the default four panes. Returns T when a layout was applied."
  (unless (ncurses-ui-startup-layout-done ui)
    (setf (ncurses-ui-startup-layout-done ui) t)
    (and (layout-exists-p +startup-layout-name+)
         (ignore-errors
          (load-layout ui +startup-layout-name+ :session session :hit hit)))))

(defun layout-exists-p (name)
  "True when a named layout NAME is saved."
  (and (assoc name (saved-layouts) :test #'string-equal) t))

(defun delete-layout (name)
  "Remove the named layout NAME from the \"layouts\" config. Returns T when a
layout of that name existed (windows-and-interactor-templates / ncurses-windows
`window-layout-delete')."
  (let* ((cfg (clautolisp.ui.tui:ensure-config +layouts-config-name+))
         (all (clautolisp.ui.tui:config-value cfg :layouts '()))
         (rest (remove name all :key #'car :test #'string-equal)))
    (clautolisp.ui.tui:config-set-value cfg :layouts rest)
    (< (length rest) (length all))))

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
  (let ((name (%read-name ui arg "load layout: ")))
    (when name
      (if (load-layout ui name :session session :hit hit)
          (set-message ui "layout ~A restored" name)
          (set-message ui "no layout named ~A" name))))
  nil)

(defun %confirm (ui prompt)
  "Ask PROMPT in the minibuffer; true only on a leading y/Y."
  (let ((answer (read-minibuffer ui prompt)))
    (and answer (plusp (length answer)) (char-equal #\y (char answer 0)))))

(defun save-as-layout-command (ui session hit arg)
  "Prompt for a NAME and save the current layout under it; if a layout of that
name already exists, ask to override first (ncurses-windows `C-w w')."
  (declare (ignore session hit))
  (let ((name (%read-name ui arg "save layout as: ")))
    (when name
      (if (and (layout-exists-p name)
               (not (%confirm ui (format nil "layout ~A exists; override? (y/n) " name))))
          (set-message ui "layout ~A kept" name)
          (progn (save-layout ui name)
                 (set-message ui "layout ~A saved" name)))))
  nil)

(defun delete-layout-command (ui session hit arg)
  "Prompt for a saved layout NAME and, after confirmation, delete it
(ncurses-windows `window-layout-delete')."
  (declare (ignore session hit))
  (let ((name (%read-name ui arg "delete layout: ")))
    (when name
      (cond
        ((not (layout-exists-p name)) (set-message ui "no layout named ~A" name))
        ((%confirm ui (format nil "delete layout ~A? (y/n) " name))
         (delete-layout name)
         (set-message ui "layout ~A deleted" name))
        (t (set-message ui "layout ~A kept" name)))))
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

(defun messages-command (ui session hit arg)
  "M-x messages: list the interactor-line message history (newest first) into the
repl pane, so a message a command scrolled past can still be read."
  (declare (ignore session hit arg))
  (let ((history (ncurses-ui-message-history ui)))
    (if history
        (progn
          (push-repl ui "--- messages (newest first) ---")
          (dolist (m history) (push-repl ui "  ~A" m)))
        (push-repl ui "no messages yet")))
  nil)

(defun why-command (ui session hit arg)
  "M-x why (also the `w' key): redisplay why we entered the debugger — the error
or clal-break message — which a later command may have replaced on the line."
  (declare (ignore session hit arg))
  (set-message ui "~A" (or (ncurses-ui-why-message ui)
                           "why: not stopped on an error or break"))
  nil)

;; Register (or replace, on reload) the M-x / , commands.
(dolist (entry (list (cons "save-configuration" #'save-configuration-command)
                     (cons "load-configuration" #'load-configuration-command)
                     (cons "save-layout" #'save-layout-command)
                     (cons "save-layout-as" #'save-as-layout-command)
                     (cons "load-layout" #'load-layout-command)
                     (cons "delete-layout" #'delete-layout-command)
                     (cons "messages" #'messages-command)
                     (cons "why" #'why-command)))
  (setf *ncurses-commands*
        (cons entry (remove (car entry) *ncurses-commands*
                            :key #'car :test #'string-equal))))
