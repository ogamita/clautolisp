(in-package #:clautolisp.autolisp-dcl.tests)

(in-suite autolisp-dcl-suite)

(defun write-temp-dcl (name body)
  "Write BODY to a temp .dcl file and return its absolute pathname."
  (let ((path (uiop:with-temporary-file
                  (:pathname p :keep t :type "dcl")
                p)))
    (with-open-file (s path :direction :output
                            :if-exists :supersede
                            :if-does-not-exist :create
                            :external-format :iso-8859-1)
      (format s "~A : dialog { label = \"~A\"; ~A }~%" name name body))
    (namestring path)))

(test runtime-load-and-unload-dialog
  "A loaded source returns an integer handle; unloading removes
it; loading a non-existent file returns nil."
  (let ((path (write-temp-dcl "g" "")))
    (unwind-protect
         (let ((id (dcl-runtime-load-dialog path)))
           (is (integerp id))
           (dcl-runtime-unload-dialog id))
      (ignore-errors (delete-file path))))
  (is (null (dcl-runtime-load-dialog "/no/such/file.dcl"))))

(test runtime-new-dialog-creates-instance
  "new_dialog returns an integer dialog handle whose tile tree
mirrors the loaded source."
  (let ((path (write-temp-dcl "g" "ok : button { label = \"OK\"; }")))
    (unwind-protect
         (let* ((source-id (dcl-runtime-load-dialog path))
                (saved-renderer (current-dcl-renderer)))
           (install-default-renderer (make-noop-renderer))
           (unwind-protect
                (let* ((dialog-id (dcl-runtime-new-dialog source-id "g")))
                  (is (integerp dialog-id))
                  (let* ((tile (dcl-runtime-find-tile
                                (gethash dialog-id
                                         (symbol-value
                                          (find-symbol "*ACTIVE-DIALOGS*"
                                                       :clautolisp.autolisp-dcl)))
                                "ok")))
                    (is (eq :button (dcl-tile-type tile))))
                  (dcl-runtime-done-dialog dialog-id 1))
             (install-default-renderer saved-renderer))
           (dcl-runtime-unload-dialog source-id))
      (ignore-errors (delete-file path)))))

(test runtime-action-callback-binding-symbols
  "Firing an action binds the AutoLISP DCL reserved variables $key /
$value / $reason (NO trailing $ — the reader upcases the source $value to
the symbol $VALUE) in the default evaluation context. $reason is the integer
reason code (1 = selected)."
  (reset-default-evaluation-context)
  (let ((path (write-temp-dcl "g" "x : edit_box { key = \"x\"; }")))
    (unwind-protect
         (let* ((source-id (dcl-runtime-load-dialog path))
                (saved-renderer (current-dcl-renderer)))
           (install-default-renderer (make-noop-renderer))
           (unwind-protect
                (let* ((dialog-id (dcl-runtime-new-dialog source-id "g"))
                       (dialog (gethash dialog-id
                                        (symbol-value
                                         (find-symbol "*ACTIVE-DIALOGS*"
                                                      :clautolisp.autolisp-dcl)))))
                  ;; An empty action body — the test only verifies
                  ;; that *$KEY$* / *$VALUE$* are bound when fire-action
                  ;; runs. PRINC etc. are builtins-core, not loaded here.
                  (dcl-runtime-action-tile dialog-id "x"
                                            (make-autolisp-string ""))
                  (dcl-runtime-fire-action dialog "x" "hello" :reason-selected)
                  (let ((kv (autolisp-symbol-value
                             (intern-autolisp-symbol "$KEY")))
                        (vv (autolisp-symbol-value
                             (intern-autolisp-symbol "$VALUE")))
                        (rv (autolisp-symbol-value
                             (intern-autolisp-symbol "$REASON"))))
                    (is (string= "x" (autolisp-string-value kv)))
                    (is (string= "hello" (autolisp-string-value vv)))
                    (is (eql 1 rv)))
                  (dcl-runtime-done-dialog dialog-id 1))
             (install-default-renderer saved-renderer))
           (dcl-runtime-unload-dialog source-id))
      (ignore-errors (delete-file path)))))

(test runtime-set-and-get-tile-roundtrip
  "set_tile / get_tile move values through the dialog state map."
  (let ((path (write-temp-dcl "g" "x : edit_box { key = \"x\"; }")))
    (unwind-protect
         (let* ((source-id (dcl-runtime-load-dialog path))
                (saved-renderer (current-dcl-renderer)))
           (install-default-renderer (make-noop-renderer))
           (unwind-protect
                (let ((dialog-id (dcl-runtime-new-dialog source-id "g")))
                  (dcl-runtime-set-tile dialog-id "x" "value-1")
                  (is (string= "value-1"
                               (dcl-runtime-get-tile dialog-id "x")))
                  (dcl-runtime-mode-tile dialog-id "x" 1)
                  (dcl-runtime-done-dialog dialog-id 0))
             (install-default-renderer saved-renderer))
           (dcl-runtime-unload-dialog source-id))
      (ignore-errors (delete-file path)))))

(test runtime-default-renderer-is-terminal
  "The package auto-installs the terminal renderer when loaded."
  (is (not (null (current-dcl-renderer)))))

(test runtime-list-batch-flushes-via-populate-list-fn
  "start_list / add_list* / end_list collects items and delivers
them in source order to the renderer's populate-list-fn."
  (let ((path (write-temp-dcl "g" "lst : list_box { key = \"items\"; }")))
    (unwind-protect
         (let* ((source-id (clautolisp.autolisp-dcl:dcl-runtime-load-dialog
                            path))
                (saved (current-dcl-renderer))
                (captured (list nil nil nil nil nil)))
           (install-default-renderer
            (clautolisp.autolisp-dcl::make-dcl-renderer
             :populate-list-fn
             (lambda (dialog key op idx items)
               (declare (ignore dialog))
               (setf (first captured) key)
               (setf (second captured) op)
               (setf (third captured) idx)
               (setf (fourth captured) items)
               (setf (fifth captured) t))))
           (unwind-protect
                (let ((dialog-id (clautolisp.autolisp-dcl:dcl-runtime-new-dialog
                                  source-id "g")))
                  (declare (ignore dialog-id))
                  (clautolisp.autolisp-dcl:dcl-runtime-start-list "items")
                  (clautolisp.autolisp-dcl:dcl-runtime-add-list "alpha")
                  (clautolisp.autolisp-dcl:dcl-runtime-add-list "beta")
                  (clautolisp.autolisp-dcl:dcl-runtime-add-list "gamma")
                  (clautolisp.autolisp-dcl:dcl-runtime-end-list)
                  (is (eq t (fifth captured)))
                  (is (equal "items" (first captured)))
                  (is (eql 3 (second captured)))
                  (is (eql 0 (third captured)))
                  (is (equal '("alpha" "beta" "gamma") (fourth captured))))
             (install-default-renderer saved))
           (clautolisp.autolisp-dcl:dcl-runtime-unload-dialog source-id))
      (ignore-errors (delete-file path)))))

;;;; ---------------------------------------------------------------------
;;;; Terminal (TUI) renderer — interactive tile types + cluster expansion
;;;; + $reason breadth (dcl-tui-completion items 1, 2, 4).
;;;;
;;;; These drive the terminal renderer's input-line handler directly
;;;; (terminal-handle-line), with values round-tripping through
;;;; dcl-runtime-get-tile — the pure-renderer counterpart to the
;;;; builtins-core stdin-driven integration test.

(defun %tui-active-dialog (id)
  (gethash id (symbol-value (find-symbol "*ACTIVE-DIALOGS*"
                                         :clautolisp.autolisp-dcl))))

(defmacro with-tui-dialog ((id-var dialog-var body-dcl) &body body)
  "Load a one-dialog source whose body is BODY-DCL, instantiate it under
the noop renderer, and bind ID-VAR / DIALOG-VAR. Cleans up afterwards."
  (let ((path (gensym "PATH")) (source (gensym "SRC")) (saved (gensym "SAVED")))
    `(let ((,path (write-temp-dcl "d" ,body-dcl)))
       (unwind-protect
            (let* ((,source (dcl-runtime-load-dialog ,path))
                   (,saved (current-dcl-renderer)))
              (install-default-renderer (make-noop-renderer))
              (unwind-protect
                   (let* ((,id-var (dcl-runtime-new-dialog ,source "d"))
                          (,dialog-var (%tui-active-dialog ,id-var)))
                     (declare (ignorable ,id-var ,dialog-var))
                     ,@body
                     (dcl-runtime-done-dialog ,id-var 0))
                (install-default-renderer ,saved))
              (dcl-runtime-unload-dialog ,source))
         (ignore-errors (delete-file ,path))))))

(defun %tui-feed (dialog line)
  "Feed one input LINE to DIALOG's terminal handler, discarding the
handler's echo. Returns the handler result."
  (let ((interactive (clautolisp.autolisp-dcl::terminal-collect-interactive-keys
                      (dcl-dialog-tile dialog)))
        (*standard-output* (make-string-output-stream)))
    (clautolisp.autolisp-dcl::terminal-handle-line dialog interactive line)))

(test tui-cluster-expands-into-real-buttons
  "A predefined cluster (ok_cancel) expands at load into real accept /
cancel :button tiles that the renderer walks — no <ok-cancel> placeholder
survives (dcl-tui-completion item 1)."
  (with-tui-dialog (id dialog ": ok_cancel;")
    (let ((accept (dcl-runtime-find-tile dialog "accept"))
          (cancel (dcl-runtime-find-tile dialog "cancel")))
      (is (and accept (eq :button (dcl-tile-type accept))))
      (is (and cancel (eq :button (dcl-tile-type cancel))))
      ;; No tile of the unexpanded cluster keyword remains anywhere.
      (labels ((has-cluster (tile)
                 (or (member (dcl-tile-type tile)
                             '(:ok-cancel :ok-only :ok-cancel-help
                               :ok-cancel-help-errtile))
                     (some #'has-cluster (dcl-tile-children tile)))))
        (is (not (has-cluster (dcl-dialog-tile dialog))))))))

(test tui-toggle-roundtrips
  "toggle: key=1 stores \"1\"; a bare key flips the state
(dcl-tui-completion item 2 — the greet `shout' toggle)."
  (with-tui-dialog (id dialog ": toggle { key = \"shout\"; label = \"Shout?\"; }")
    (%tui-feed dialog "shout=1")
    (is (string= "1" (dcl-runtime-get-tile id "shout")))
    (%tui-feed dialog "shout")
    (is (string= "0" (dcl-runtime-get-tile id "shout")))
    (%tui-feed dialog "shout")
    (is (string= "1" (dcl-runtime-get-tile id "shout")))))

(test tui-radio-column-is-mutually-exclusive
  "Selecting one radio_button in a radio_column sets it to \"1\" and clears
its siblings to \"0\" (dcl-tui-completion item 2)."
  (with-tui-dialog (id dialog
                    ": radio_column { key = \"grp\";
                        : radio_button { key = \"r1\"; label = \"One\"; }
                        : radio_button { key = \"r2\"; label = \"Two\"; }
                        : radio_button { key = \"r3\"; label = \"Three\"; } }")
    (%tui-feed dialog "r2")
    (is (string= "1" (dcl-runtime-get-tile id "r2")))
    (is (string= "0" (dcl-runtime-get-tile id "r1")))
    (is (string= "0" (dcl-runtime-get-tile id "r3")))
    ;; get_tile on the cluster key returns the selected button's key
    ;; (AutoCAD/BricsCAD radio-group semantics).
    (is (string= "r2" (dcl-runtime-get-tile id "grp")))
    (%tui-feed dialog "r1")
    (is (string= "1" (dcl-runtime-get-tile id "r1")))
    (is (string= "0" (dcl-runtime-get-tile id "r2")))
    (is (string= "r1" (dcl-runtime-get-tile id "grp")))))

(test tui-list-and-popup-select-by-index-and-name
  "list_box / popup_list store the selected item's index string; a numeric
index is taken verbatim, a name is resolved to its index
(dcl-tui-completion item 2)."
  (with-tui-dialog (id dialog
                    ": list_box { key = \"lst\"; }
                     : popup_list { key = \"pop\"; }")
    (dcl-runtime-start-list "lst")
    (dcl-runtime-add-list "Red") (dcl-runtime-add-list "Green")
    (dcl-runtime-add-list "Blue")
    (dcl-runtime-end-list)
    (dcl-runtime-start-list "pop")
    (dcl-runtime-add-list "Alpha") (dcl-runtime-add-list "Beta")
    (dcl-runtime-end-list)
    (%tui-feed dialog "lst=2")
    (is (string= "2" (dcl-runtime-get-tile id "lst")))
    (%tui-feed dialog "lst=Green")
    (is (string= "1" (dcl-runtime-get-tile id "lst")))
    (%tui-feed dialog "pop=Beta")
    (is (string= "1" (dcl-runtime-get-tile id "pop")))))

(test tui-slider-clamps-to-range
  "slider clamps the entered value to [min_value, max_value]
(dcl-tui-completion item 2)."
  (with-tui-dialog (id dialog
                    ": slider { key = \"s\"; min_value = 0; max_value = 10; }")
    (%tui-feed dialog "s=5")
    (is (string= "5" (dcl-runtime-get-tile id "s")))
    (%tui-feed dialog "s=99")
    (is (string= "10" (dcl-runtime-get-tile id "s")))
    (%tui-feed dialog "s=-3")
    (is (string= "0" (dcl-runtime-get-tile id "s")))))

(test tui-image-button-is-activatable
  "image_button is collected as an interactive tile and activating it via
the terminal handler runs the button path without error
(dcl-tui-completion item 2)."
  (with-tui-dialog (id dialog ": image_button { key = \"pick\"; }")
    (let ((interactive (clautolisp.autolisp-dcl::terminal-collect-interactive-keys
                        (dcl-dialog-tile dialog))))
      (is (assoc "pick" interactive :test #'string=)))
    ;; No registered action: the button path fires a nil callback (a no-op)
    ;; and returns :continue rather than an exit status.
    (is (eq :continue (%tui-feed dialog "pick")))))

(test tui-reason-codes-cover-the-four-cases
  "The terminal renderer emits the four $reason codes per input-line
modifier: key=value changed (2), key! lost-focus (3), key==value
double-click (4), bare key selected (1) — dcl-tui-completion item 4."
  (reset-default-evaluation-context)
  (with-tui-dialog (id dialog
                    ": edit_box { key = \"e\"; }
                     : list_box { key = \"lst\"; }
                     : toggle { key = \"t\"; }")
    (dcl-runtime-start-list "lst")
    (dcl-runtime-add-list "a") (dcl-runtime-add-list "b")
    (dcl-runtime-end-list)
    ;; Register empty string actions so fire-action binds the $ variables.
    (dcl-runtime-action-tile id "e" (make-autolisp-string ""))
    (dcl-runtime-action-tile id "lst" (make-autolisp-string ""))
    (dcl-runtime-action-tile id "t" (make-autolisp-string ""))
    (flet ((reason ()
             (autolisp-symbol-value (intern-autolisp-symbol "$REASON"))))
      (%tui-feed dialog "e=hi")     (is (eql 2 (reason)))  ; changed
      (%tui-feed dialog "e!")       (is (eql 3 (reason)))  ; lost focus
      (%tui-feed dialog "lst==1")   (is (eql 4 (reason)))  ; double-click
      (%tui-feed dialog "t")        (is (eql 1 (reason)))))) ; selected

(test runtime-image-batch-flushes-via-image-paint-fn
  "start_image, vector_image, fill_image, slide_image, end_image
deliver primitives to the renderer's image-paint-fn in source
order."
  (let ((path (write-temp-dcl "g" "img : image { key = \"icon\"; }")))
    (unwind-protect
         (let* ((source-id (clautolisp.autolisp-dcl:dcl-runtime-load-dialog
                            path))
                (saved (current-dcl-renderer))
                (got nil))
           (install-default-renderer
            (clautolisp.autolisp-dcl::make-dcl-renderer
             :image-paint-fn
             (lambda (dialog key prims)
               (declare (ignore dialog key))
               (setf got prims))))
           (unwind-protect
                (progn
                  (clautolisp.autolisp-dcl:dcl-runtime-new-dialog
                   source-id "g")
                  (clautolisp.autolisp-dcl:dcl-runtime-start-image "icon")
                  (clautolisp.autolisp-dcl:dcl-runtime-image-fill 0 0 10 10 1)
                  (clautolisp.autolisp-dcl:dcl-runtime-image-vector 0 0 10 10 7)
                  (clautolisp.autolisp-dcl:dcl-runtime-end-image)
                  (is (= 2 (length got)))
                  (is (eq :fill (first (first got))))
                  (is (eq :vector (first (second got)))))
             (install-default-renderer saved))
           (clautolisp.autolisp-dcl:dcl-runtime-unload-dialog source-id))
      (ignore-errors (delete-file path)))))
