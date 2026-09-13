(in-package #:clautolisp.cadtui.tests)

(in-suite cadtui-suite)

;;;; Phase 3 slice 1: mirror the DCL runtime into ui-nodes.

(defun %write-temp-dcl (name body)
  "Write a DCL dialog NAME with BODY tiles to a temp file; return its namestring."
  (let ((path (uiop:with-temporary-file (:pathname p :keep t :type "dcl") p)))
    (with-open-file (s path :direction :output :if-exists :supersede
                            :if-does-not-exist :create
                            :external-format :iso-8859-1)
      (format s "~A : dialog { label = \"~A\"; ~A }~%" name name body))
    (namestring path)))

(defmacro %with-cadtui-dcl ((root-var) &body body)
  "Build a tree with one drawing, install the cadtui DCL renderer over it, run
BODY, and restore the previously-installed renderer (so the DCL suite is not
disturbed)."
  (let ((saved (gensym "SAVED")) (dwg (gensym "DWG")))
    `(let* ((,root-var (make-application-tree))
            (,dwg (make-instance 'ui-drawing :key "plan.dwg"))
            (,saved (current-dcl-renderer)))
       (add-child ,root-var ,dwg)
       (install-cadtui-dcl-renderer ,root-var)
       (unwind-protect (progn ,@body)
         (install-default-renderer ,saved)))))

(test dcl-new-dialog-mirrors-into-tree
  (%with-cadtui-dcl (root)
    (let ((path (%write-temp-dcl
                 "g"
                 "colour : edit_box { key = \"colour\"; label = \"Colour\"; } accept : button { key = \"accept\"; label = \"OK\"; }")))
      (unwind-protect
           (let* ((src (dcl-runtime-load-dialog path))
                  (id (dcl-runtime-new-dialog src "g"))
                  (uidlg (resolve-target
                          root (format nil "/application/active-drawing/dialog:~D" id))))
             (is (eq :dialog (ui-role uidlg)))
             ;; keyed tiles are flattened directly under the dialog, in order.
             (is (equal '("colour" "accept") (mapcar #'ui-key (ui-children uidlg))))
             (let ((accept (ui-find-child uidlg "accept"))
                   (colour (ui-find-child uidlg "colour")))
               (is (eq :button (clautolisp.cadtui::ui-tile-type accept)))
               (is (string= "Colour" (ui-label colour))))
             (dcl-runtime-done-dialog id 1))
        (ignore-errors (delete-file path))))))

(test dcl-set-tile-updates-ui-tile-value
  (%with-cadtui-dcl (root)
    (let ((path (%write-temp-dcl "g" "colour : edit_box { key = \"colour\"; }")))
      (unwind-protect
           (let* ((src (dcl-runtime-load-dialog path))
                  (id (dcl-runtime-new-dialog src "g"))
                  (tile (resolve-target
                         root (format nil "/application/active-drawing/dialog:~D/tile:colour" id))))
             (dcl-runtime-set-tile id "colour" "CYAN")
             (is (string= "CYAN" (clautolisp.cadtui::ui-tile-value tile)))
             (dcl-runtime-done-dialog id 1))
        (ignore-errors (delete-file path))))))

(test dcl-mode-tile-updates-ui-state
  (%with-cadtui-dcl (root)
    (let ((path (%write-temp-dcl "g" "b : button { key = \"b\"; }")))
      (unwind-protect
           (let* ((src (dcl-runtime-load-dialog path))
                  (id (dcl-runtime-new-dialog src "g"))
                  (tile (resolve-target
                         root (format nil "/application/active-drawing/dialog:~D/tile:b" id))))
             (is (eq :normal (ui-state tile)))
             (dcl-runtime-mode-tile id "b" 1)          ; disable
             (is (eq :grayed (ui-state tile)))
             (dcl-runtime-mode-tile id "b" 0)          ; enable
             (is (eq :normal (ui-state tile)))
             (dcl-runtime-done-dialog id 1))
        (ignore-errors (delete-file path))))))

;;;; Phase 3 slice 2: input/click/close fire DCL callbacks + teardown.

(test dcl-input-fires-action-and-records-value
  (reset-default-evaluation-context)
  (%with-cadtui-dcl (root)
    (let ((path (%write-temp-dcl "g" "colour : edit_box { key = \"colour\"; }")))
      (unwind-protect
           (let* ((src (dcl-runtime-load-dialog path))
                  (id (dcl-runtime-new-dialog src "g")))
             (dcl-runtime-action-tile id "colour"
                                      (make-autolisp-string "(setq pick $value)"))
             (interpret-line
              (format nil "=input(/application/active-drawing/dialog:~D/tile:colour, \"CYAN\")" id)
              root)
             ;; the action_tile callback ran ($value bound, pick set) ...
             (is (string= "CYAN"
                          (autolisp-string-value
                           (autolisp-symbol-value (intern-autolisp-symbol "PICK")))))
             ;; ... and get_tile reflects the entered value.
             (is (string= "CYAN" (dcl-runtime-get-tile id "colour")))
             (dcl-runtime-done-dialog id 1))
        (ignore-errors (delete-file path))))))

(test dcl-click-button-fires-callback
  ;; The button's action_tile callback runs on click. Uses setq (a runtime
  ;; special form) so the test does not depend on builtins-core being loaded.
  (reset-default-evaluation-context)
  (%with-cadtui-dcl (root)
    (let ((path (%write-temp-dcl "g" "accept : button { key = \"accept\"; }")))
      (unwind-protect
           (let* ((src (dcl-runtime-load-dialog path))
                  (id (dcl-runtime-new-dialog src "g")))
             (dcl-runtime-action-tile id "accept" (make-autolisp-string "(setq clicked 1)"))
             (interpret-line
              (format nil "=click(/application/active-drawing/dialog:~D/tile:accept)" id)
              root)
             (is (eql 1 (autolisp-symbol-value (intern-autolisp-symbol "CLICKED"))))
             (dcl-runtime-done-dialog id 1))
        (ignore-errors (delete-file path))))))

(test dcl-close-dialog-ends-and-detaches
  (%with-cadtui-dcl (root)
    (let ((path (%write-temp-dcl "g" "x : edit_box { key = \"x\"; }")))
      (unwind-protect
           (let* ((src (dcl-runtime-load-dialog path))
                  (id (dcl-runtime-new-dialog src "g"))
                  (uidlg (resolve-target
                          root (format nil "/application/active-drawing/dialog:~D" id)))
                  (dcl (clautolisp.cadtui::ui-dcl-source uidlg))
                  (drawing (ui-parent uidlg)))
             (interpret-line
              (format nil "=close(/application/active-drawing/dialog:~D)" id) root)
             ;; done_dialog fired (finished) and the ui-dialog is detached.
             (is (eq t (dcl-dialog-finished-p dcl)))
             (is (null (ui-find-child drawing (princ-to-string id)))))
        (ignore-errors (delete-file path))))))
