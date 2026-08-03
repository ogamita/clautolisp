(in-package #:clautolisp.autolisp-dcl)

;;;; Terminal-UI renderer for DCL dialogs.
;;;;
;;;; This is a minimal pure-CL TUI: no ncurses, no cffi, just ANSI
;;;; escape sequences for cursor positioning and screen clearing.
;;;; The renderer paints a labelled tree of tiles, prompts the user
;;;; for each interactive tile in tab order, and fires the
;;;; registered action callback when the value changes. Buttons are
;;;; rendered as `[label]`; the user activates one by typing its
;;;; key (or pressing the highlighted mnemonic). When a button's
;;;; action calls done_dialog the run loop exits with that status.
;;;;
;;;; This is the *fallback* renderer when no GUI backend is wired.
;;;; On a non-TTY stdout (CI / piped stdin) it degrades to a
;;;; line-oriented prompt-and-collect mode.

(defun terminal-render-dialog (dialog)
  (let ((root (dcl-dialog-tile dialog)))
    (format *standard-output* "~&~%[ ~A ]~%"
            (or (tile-attribute root "label") "(dialog)"))
    (terminal-render-tile-tree root dialog 0)
    (force-output *standard-output*)))

(defun terminal-render-tile-tree (tile dialog indent)
  (let ((indentation (make-string (* 2 indent) :initial-element #\Space)))
    (case (dcl-tile-type tile)
      ((:dialog :row :column :boxed-row :boxed-column)
       (let ((label (tile-attribute tile "label")))
         (when label
           (format *standard-output* "~A~A~%" indentation label)))
       (dolist (child (dcl-tile-children tile))
         (terminal-render-tile-tree child dialog (1+ indent))))
      (:text
       (format *standard-output* "~A~A~%" indentation
               (or (tile-attribute tile "label") "")))
      (:spacer
       (format *standard-output* "~%"))
      (:button
       (format *standard-output* "~A[ ~A ]"
               indentation
               (or (tile-attribute tile "label")
                   (or (dcl-tile-key tile) (tile-attribute tile "_name_") "button")))
       (let ((key (or (dcl-tile-key tile) (tile-attribute tile "key"))))
         (when key (format *standard-output* "  (key: ~A)" key)))
       (terpri *standard-output*))
      (:edit-box
       (let* ((key (or (dcl-tile-key tile) (tile-attribute tile "key")))
              (label (or (tile-attribute tile "label") key "edit"))
              (value (and key (gethash key (dcl-dialog-state dialog) ""))))
         (format *standard-output* "~A~A: ~A~%" indentation label value)))
      (:list-box
       (let* ((key (or (dcl-tile-key tile) (tile-attribute tile "key")))
              (label (or (tile-attribute tile "label") key "list")))
         (format *standard-output* "~A~A:~%" indentation label)
         (let ((items (and key
                           (gethash (concatenate 'string key ":items")
                                    (dcl-dialog-state dialog) nil))))
           (dolist (item (if (listp items) items '()))
             (format *standard-output* "~A  - ~A~%" indentation item)))))
      (:popup-list
       (let* ((key (or (dcl-tile-key tile) (tile-attribute tile "key")))
              (label (or (tile-attribute tile "label") key "popup")))
         (format *standard-output* "~A~A: ~A~%" indentation label
                 (and key (gethash key (dcl-dialog-state dialog) "")))))
      (:radio-button
       (let* ((key (or (dcl-tile-key tile) (tile-attribute tile "key")))
              (label (or (tile-attribute tile "label") key "option"))
              (value (and key (gethash key (dcl-dialog-state dialog) "0"))))
         (format *standard-output* "~A( ~A ) ~A~%"
                 indentation
                 (if (equal value "1") "*" " ")
                 label)))
      (:image
       (format *standard-output* "~A[image]~%" indentation))
      (otherwise
       (let ((label (tile-attribute tile "label")))
         (format *standard-output* "~A<~A>~A~%"
                 indentation
                 (string-downcase (string (dcl-tile-type tile)))
                 (if label (format nil " ~A" label) "")))
       (dolist (child (dcl-tile-children tile))
         (terminal-render-tile-tree child dialog (1+ indent)))))))

(defun terminal-collect-interactive-keys (tile)
  "Return a list of (KEY . TILE) pairs for the dialog's
interactive tiles, in source order."
  (let ((acc '()))
    (labels ((walk (tile)
               (let ((key (or (dcl-tile-key tile)
                              (tile-attribute tile "key"))))
                 (when (and key
                            (member (dcl-tile-type tile)
                                    '(:button :edit-box :list-box
                                      :popup-list :radio-button
                                      :slider :toggle :image-button)))
                   (push (cons key tile) acc)))
               (dolist (child (dcl-tile-children tile)) (walk child))))
      (walk tile))
    (nreverse acc)))

(defun terminal-prompt-line (prompt)
  (format *standard-output* "~&~A " prompt)
  (force-output *standard-output*)
  (let ((line (read-line *standard-input* nil :eof)))
    (if (eq line :eof) nil line)))

(defun terminal-handle-button (dialog tile key)
  "Fire the button's action; if it's the default or cancel
button, return its conventional status (1 or 0). Returns nil if
no auto-exit is warranted."
  (dcl-runtime-fire-action dialog key
                            (gethash key (dcl-dialog-state dialog) "")
                            :reason-selected)
  (cond
    ((dcl-dialog-finished-p dialog) nil)
    ((tile-attribute tile "is_cancel") 0)
    ((tile-attribute tile "is_default") 1)
    (t nil)))

(defun terminal-handle-value-tile (dialog tile key value)
  "Update the dialog state for a non-button tile from a parsed
command, prompting for the value when the user did not supply
one."
  (declare (ignore tile))
  (let ((new-value (or value
                       (terminal-prompt-line (format nil "~A=" key)))))
    (when new-value
      (setf (gethash key (dcl-dialog-state dialog)) new-value)
      (dcl-runtime-fire-action dialog key new-value :reason-selected))))

(defun terminal-handle-line (dialog interactive line)
  "Interpret one input line. Returns :continue to keep prompting, or an
integer status when the line caused done_dialog to fire (a button's action,
or the accept/cancel convention).

A named tile is handled by FIRING its registered action — including the
`accept' / `cancel' predefined buttons, whose action typically reads the
tiles (get_tile) and calls done_dialog. Only when the word names no tile do
we fall back to the bare accept->1 / cancel->0 convention (for dialogs that
ship no explicit accept/cancel tile). Previously accept/ok/cancel/quit
short-circuited to a status BEFORE the tile lookup, so an accept button's
action never fired and any value it copied into a variable via get_tile was
lost (the greet example returned nil and crashed)."
  (multiple-value-bind (key value) (terminal-parse-command line)
    (let ((entry (assoc key interactive :test #'string=)))
      (cond
        (entry
         (let ((tile (cdr entry)))
           (case (dcl-tile-type tile)
             (:button
              (or (terminal-handle-button dialog tile key) :continue))
             (otherwise
              (terminal-handle-value-tile dialog tile key value)
              :continue))))
        ((or (string= key "accept") (string= key "ok"))
         (terminal-fire-registered dialog "accept")
         (if (dcl-dialog-finished-p dialog) (dcl-dialog-status dialog) 1))
        ((or (string= key "quit") (string= key "cancel"))
         (terminal-fire-registered dialog "cancel")
         (if (dcl-dialog-finished-p dialog) (dcl-dialog-status dialog) 0))
        (t
         (format *standard-output* "~&Unknown key ~A.~%" key)
         :continue)))))

(defun terminal-fire-registered (dialog key)
  "Fire the action registered under KEY, if any. Used when a conventional
word (`accept' / `cancel') names an action whose button is not an explicit
tile in the tree — notably the `ok_cancel' predefined cluster, which is not
expanded into separate accept/cancel button tiles, so action_tile \"accept\"
would otherwise be unreachable from the TUI."
  (when (gethash key (dcl-dialog-actions dialog))
    (dcl-runtime-fire-action dialog key
                             (gethash key (dcl-dialog-state dialog) "")
                             :reason-selected)))

(defun terminal-run-dialog (dialog)
  "Drive DIALOG until done_dialog or EOF. Returns the dialog's
terminal status. Default-binds OK to status=1 and Cancel to
status=0 even when no explicit action was attached, matching
AutoCAD's documented predefined-button behaviour."
  (terminal-render-dialog dialog)
  (let ((interactive (terminal-collect-interactive-keys
                      (dcl-dialog-tile dialog))))
    (loop
      (when (dcl-dialog-finished-p dialog)
        (return (dcl-dialog-status dialog)))
      (let ((line (terminal-prompt-line "_dcl$ ")))
        (cond
          ((null line) (return 0))
          ((zerop (length line)) nil)
          (t
           (let ((result (terminal-handle-line dialog interactive line)))
             (when (integerp result)
               (return result)))))))))

(defun terminal-parse-command (line)
  "Parse a single TUI command of the form `key` or `key=value`."
  (let* ((trimmed (string-trim '(#\Space #\Tab #\Return) line))
         (eq-pos (position #\= trimmed)))
    (cond
      ((null eq-pos) (values trimmed nil))
      (t (values (string-trim '(#\Space) (subseq trimmed 0 eq-pos))
                 (string-trim '(#\Space) (subseq trimmed (1+ eq-pos))))))))

(defun make-terminal-renderer ()
  (make-dcl-renderer
   :open-fn (lambda (dialog) (declare (ignore dialog)) nil)
   :close-fn (lambda (dialog)
               (declare (ignore dialog))
               (format *standard-output* "~&[dialog closed]~%")
               (force-output *standard-output*))
   :set-tile-fn (lambda (dialog key value)
                  (declare (ignore dialog))
                  (format *standard-output* "~&[set ~A = ~A]~%" key value))
   :focus-fn (lambda (dialog key)
               (declare (ignore dialog))
               (format *standard-output* "~&[focus ~A]~%" key))
   :mode-fn (lambda (dialog key mode)
              (declare (ignore dialog))
              (format *standard-output* "~&[mode ~A = ~A]~%" key mode))
   :populate-list-fn
   (lambda (dialog key operation index items)
     (declare (ignore dialog operation index))
     (format *standard-output* "~&[~A:items]~%" key)
     (dolist (item items)
       (format *standard-output* "  ~A~%" item)))
   :image-paint-fn
   (lambda (dialog key primitives)
     (declare (ignore dialog))
     (format *standard-output* "~&[image ~A: ~D primitive~:P]~%"
             key (length primitives))
     (dolist (p primitives)
       (format *standard-output* "  ~A~%" p)))
   :run-fn  #'terminal-run-dialog))

(eval-when (:load-toplevel :execute)
  (install-default-renderer (make-terminal-renderer)))
