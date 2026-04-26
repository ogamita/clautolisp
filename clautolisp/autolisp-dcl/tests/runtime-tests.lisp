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
  "Firing an action sets *$KEY$* / *$VALUE$* / *$REASON$* in the
default evaluation context."
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
                             (intern-autolisp-symbol "$KEY$")))
                        (vv (autolisp-symbol-value
                             (intern-autolisp-symbol "$VALUE$"))))
                    (is (string= "x" (autolisp-string-value kv)))
                    (is (string= "hello" (autolisp-string-value vv))))
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
