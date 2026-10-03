(in-package #:clautolisp.cadtui.tests)

(in-suite cadtui-suite)

;;;; Phase 6: menu bar and bands built from a data description.

(defparameter *menu-bar-desc*
  '(:menu-bar
    (:menu "Draw"
     (:item "Line" :action "LINE")
     (:item "Circle" :action "CIRCLE")
     (:separator)
     (:menu "Arc"
      (:item "3-Point" :action "ARC")))
    (:menu "Edit"
     (:item "Undo" :action "U" :state :grayed))))

(test build-menu-bar-nests-menus-items-and-separators
  (let ((bar (build-menu-bar *menu-bar-desc*)))
    (is (eq :menu-bar (ui-role bar)))
    (is (equal '("Draw" "Edit") (mapcar #'ui-key (ui-children bar))))
    (let ((draw (ui-find-child bar "Draw")))
      (is (eq :menu (ui-role draw)))
      ;; item, item, separator, submenu — in order.
      (is (equal '(:item :item :separator :menu)
                 (mapcar #'ui-role (ui-children draw))))
      (is (equal '("Line" "Circle" "separator-3" "Arc")
                 (mapcar #'ui-key (ui-children draw))))
      (let ((line (ui-find-child draw "Line")))
        (is (string= "LINE" (ui-action line)))
        (is (string= "Line" (ui-label line))))
      ;; the submenu carries its own item.
      (let ((arc (ui-find-child draw "Arc")))
        (is (eq :menu (ui-role arc)))
        (is (equal '("3-Point") (mapcar #'ui-key (ui-children arc))))))
    (let ((undo (ui-find-child (ui-find-child bar "Edit") "Undo")))
      (is (eq :grayed (ui-state undo))))))

(test build-toolbar-band-of-flat-buttons
  (let ((band (build-band '(:band "Modify" :style :toolbar
                            (:button "Move" :action "MOVE")
                            (:button "Copy" :action "COPY")))))
    (is (eq :band (ui-role band)))
    (is (eq :toolbar (ui-band-style band)))
    (is (equal '(:button :button) (mapcar #'ui-role (ui-children band))))
    (is (equal '("Move" "Copy") (mapcar #'ui-key (ui-children band))))
    (is (string= "MOVE" (ui-action (ui-find-child band "Move"))))))

(test build-ribbon-band-nests-tabs-panels-buttons
  (let ((band (build-band '(:band "Ribbon" :style :ribbon
                            (:tab "Home"
                             (:panel "Draw"
                              (:button "Line" :action "LINE"))
                             (:panel "Modify"
                              (:button "Move" :action "MOVE")))))))
    (is (eq :ribbon (ui-band-style band)))
    (let ((home (ui-find-child band "Home")))
      (is (eq :ribbon-tab (ui-role home)))
      (is (equal '("Draw" "Modify") (mapcar #'ui-key (ui-children home))))
      (let ((draw (ui-find-child home "Draw")))
        (is (eq :ribbon-panel (ui-role draw)))
        (is (eq :button (ui-role (first (ui-children draw)))))
        (is (string= "LINE" (ui-action (ui-find-child draw "Line"))))))))

(test build-band-defaults-to-toolbar-style
  (let ((band (build-band '(:band "Bare" (:button "X" :action "X")))))
    (is (eq :toolbar (ui-band-style band)))
    (is (equal '("X") (mapcar #'ui-key (ui-children band))))))

(test malformed-descriptions-signal-ui-description-error
  (is (eq :err (handler-case (build-menu-bar '(:not-a-menu-bar))
                 (ui-description-error () :err))))
  (is (eq :err (handler-case (build-band '(:band "S" :style :bogus))
                 (ui-description-error () :err))))
  (is (eq :err (handler-case (build-menu-bar '(:menu-bar (:menu 42)))
                 (ui-description-error () :err)))))

(test install-menu-bar-replaces-and-keeps-it-first
  (let ((app (make-application-tree)))          ; already has an empty menu-bar + console
    (let ((bar (install-menu-bar app *menu-bar-desc*)))
      (is (eq bar (ui-find-child app "menu-bar")))
      ;; menu-bar is the first child (spec tree order).
      (is (eq bar (first (ui-children app))))
      (is (equal '("Draw" "Edit") (mapcar #'ui-key (ui-children bar))))
      ;; only one menu-bar remains.
      (is (= 1 (count :menu-bar (ui-children app) :key #'ui-role))))))

(test add-band-appends-to-a-drawing
  (let* ((app (make-application-tree))
         (dwg (make-instance 'ui-drawing :key "plan.dwg")))
    (add-child app dwg)
    (let ((band (add-band dwg '(:band "Modify" (:button "Move" :action "MOVE")))))
      (is (eq band (ui-find-child dwg "Modify")))
      (is (eq :band (ui-role band))))))

(test click-runs-a-lisp-closure-action
  (let* ((ran nil)
         (app (make-application-tree)))
    (install-menu-bar
     app `(:menu-bar (:menu "Tools"
                      (:item "Ping" :action ,(lambda () (setf ran :pong))))))
    (let ((r (interpret-line
              "=click(/application/menu-bar/menu:Tools/item:Ping)" app)))
      (is (eq :ok (command-result-status r)))
      (is (eq :pong ran))
      (is (eq :pong (command-result-data r))))))

;;; --- alref Phase 4 S3: file-command events and console rule 3 ---------

(test file-command-events-build-drawings-menus-and-bands
  (let ((root (make-application-tree)))
    ;; NEW / OPEN: a ui-drawing with its console, made active.
    (let ((d (apply-file-command-event root :document-opened "Drawing.dwg<2>")))
      (is (eq :drawing (ui-role d)))
      (is (string= "Drawing.dwg<2>" (ui-key d)))
      (is (eq d (find :drawing (ui-children root) :key #'ui-role)))
      (is (ui-find-child d "console")))
    ;; MENULOAD: the menu bar replaced, the band added to the active drawing.
    (apply-file-command-event
     root :menu-loaded
     '((:menu-bar (:menu "Draw" (:item "Line" :action "LINE")))
       (:band "Tools" (:button "Circle" :action "CIRCLE")))
     "x.mnu")
    (is (ui-find-child (ui-find-child root "menu-bar") "Draw"))
    (is (ui-find-child (find :drawing (ui-children root) :key #'ui-role) "Tools"))))

(test console-rule-3-classifies-and-builds-a-command-line
  ;; Spec 5.6: "(" is Lisp, "," and "!" are the REPL's; anything else is a
  ;; CAD command line, its words the inputs (SPACE is ENTER), a final RETURN.
  (is (cad-command-line-p "LINE 0,0 4,0"))
  (is (cad-command-line-p "  _.circle 1,1 2"))
  (is (not (cad-command-line-p "(setq a 1)")))
  (is (not (cad-command-line-p ",quit")))
  (is (not (cad-command-line-p "!ls")))
  (is (not (cad-command-line-p "   ")))
  (is (string= "CIRCLE" (cad-command-line-name "  _.circle 1,1 2")))
  (is (string= "(progn (command \"LINE\" \"0,0\" \"4,0\" \"\") (princ))"
               (cad-command-line-source "LINE  0,0 4,0 "))))
