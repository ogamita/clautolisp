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

(defun terminal-tile-key (tile)
  (or (dcl-tile-key tile) (tile-attribute tile "key")))

(defun terminal-list-items (dialog key)
  "The items populated into a list_box / popup_list KEY via
start_list/add_list/end_list, or NIL."
  (let ((items (and key (gethash (concatenate 'string key ":items")
                                 (dcl-dialog-state dialog) nil))))
    (if (listp items) items '())))

(defun terminal-render-tile-tree (tile dialog indent)
  (let ((indentation (make-string (* 2 indent) :initial-element #\Space)))
    (case (dcl-tile-type tile)
      ((:dialog :row :column :boxed-row :boxed-column
        :radio-column :radio-row :concatenation)
       (let ((label (tile-attribute tile "label")))
         (when label
           (format *standard-output* "~A~A~%" indentation label)))
       (dolist (child (dcl-tile-children tile))
         (terminal-render-tile-tree child dialog (1+ indent))))
      (:text
       (format *standard-output* "~A~A~%" indentation
               (or (tile-attribute tile "label")
                   ;; An errtile (or any keyed text) shows its live value.
                   (let ((key (terminal-tile-key tile)))
                     (and key (gethash key (dcl-dialog-state dialog) "")))
                   "")))
      (:spacer
       (format *standard-output* "~%"))
      ((:button :image-button)
       (format *standard-output* "~A[ ~A ]"
               indentation
               (or (tile-attribute tile "label")
                   (or (dcl-tile-key tile) (tile-attribute tile "_name_") "button")))
       (let ((key (terminal-tile-key tile)))
         (when key (format *standard-output* "  (key: ~A)" key)))
       (terpri *standard-output*))
      (:edit-box
       (let* ((key (terminal-tile-key tile))
              (label (or (tile-attribute tile "label") key "edit"))
              (value (and key (gethash key (dcl-dialog-state dialog) ""))))
         (format *standard-output* "~A~A: ~A~@[  (key: ~A)~]~%"
                 indentation label value key)))
      (:toggle
       (let* ((key (terminal-tile-key tile))
              (label (or (tile-attribute tile "label") key "toggle"))
              (value (and key (gethash key (dcl-dialog-state dialog) "0"))))
         (format *standard-output* "~A[~A] ~A~@[  (key: ~A)~]~%"
                 indentation (if (equal value "1") "x" " ") label key)))
      (:list-box
       (let* ((key (terminal-tile-key tile))
              (label (or (tile-attribute tile "label") key "list"))
              (selected (and key (gethash key (dcl-dialog-state dialog) ""))))
         (format *standard-output* "~A~A:~@[  (key: ~A)~]~%" indentation label key)
         (loop for item in (terminal-list-items dialog key)
               for i from 0
               do (format *standard-output* "~A  ~A ~D: ~A~%"
                          indentation
                          (if (equal selected (princ-to-string i)) ">" " ")
                          i item))))
      (:popup-list
       (let* ((key (terminal-tile-key tile))
              (label (or (tile-attribute tile "label") key "popup"))
              (selected (and key (gethash key (dcl-dialog-state dialog) "")))
              (items (terminal-list-items dialog key)))
         (format *standard-output* "~A~A: [~A]~@[  (key: ~A)~]~%"
                 indentation label
                 (let ((idx (ignore-errors (parse-integer selected))))
                   (if (and idx (< -1 idx (length items)))
                       (nth idx items) selected))
                 key)
         (loop for item in items for i from 0
               do (format *standard-output* "~A    ~D: ~A~%" indentation i item))))
      (:radio-button
       (let* ((key (terminal-tile-key tile))
              (label (or (tile-attribute tile "label") key "option"))
              (value (and key (gethash key (dcl-dialog-state dialog) "0"))))
         (format *standard-output* "~A( ~A ) ~A~@[  (key: ~A)~]~%"
                 indentation
                 (if (equal value "1") "*" " ")
                 label key)))
      (:slider
       (let* ((key (terminal-tile-key tile))
              (label (or (tile-attribute tile "label") key "slider"))
              (value (and key (gethash key (dcl-dialog-state dialog) "0")))
              (mn (or (tile-attribute tile "min_value") 0))
              (mx (or (tile-attribute tile "max_value") 100)))
         (format *standard-output* "~A~A: ~A  (~A..~A)~@[  (key: ~A)~]~%"
                 indentation label value mn mx key)))
      (:image
       (let ((key (terminal-tile-key tile)))
         (format *standard-output* "~A[image~@[ ~A~]]~%" indentation key)))
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

(defun terminal-modifier-reason (modifier default)
  "Map an input-line MODIFIER to the AutoLISP $reason keyword for an
editable tile (edit_box / slider), where `key=value' is an in-progress
value change (reason 2). DEFAULT covers a bare activation."
  (case modifier
    (:change :reason-changed)         ; key=value  — value changed
    (:commit :reason-lost-focus)      ; key! / key=value! — tile lost focus
    (:double :reason-double-click)    ; key==value — double-click / accept
    (t default)))                     ; :activate

(defun terminal-select-reason (modifier)
  "Map an input-line MODIFIER to the AutoLISP $reason keyword for a
selection tile (toggle / radio_button / list_box / popup_list), where
choosing a value IS the selection (reason 1), a double-click is reason 4,
and losing focus is reason 3."
  (case modifier
    (:double :reason-double-click)    ; key==value — double-click / accept
    (:commit :reason-lost-focus)      ; key! — lost focus
    (t :reason-selected)))            ; :activate and :change are selections

(defun terminal-truthy-p (value)
  "Interpret a toggle input string as on/off."
  (member value '("1" "t" "on" "yes" "true") :test #'string-equal))

(defun terminal-cluster-radio-keys (cluster)
  "The keys of every radio_button descendant of CLUSTER, in source order."
  (let ((acc '()))
    (labels ((walk (node)
               (when (eq (dcl-tile-type node) :radio-button)
                 (let ((k (terminal-tile-key node)))
                   (when k (push k acc))))
               (dolist (c (dcl-tile-children node)) (walk c))))
      (walk cluster))
    (nreverse acc)))

(defun terminal-find-radio-cluster (root key)
  "The radio_column / radio_row tile that contains the radio_button KEY,
or NIL when KEY is a stand-alone radio_button."
  (labels ((find-cluster (tile)
             (cond
               ((and (member (dcl-tile-type tile) '(:radio-column :radio-row))
                     (member key (terminal-cluster-radio-keys tile)
                             :test #'string=))
                tile)
               (t (some #'find-cluster (dcl-tile-children tile))))))
    (find-cluster root)))

(defun terminal-select-radio (dialog key)
  "Set KEY's radio_button to \"1\" and every sibling in its cluster to
\"0\" (mutual exclusion). Also set the enclosing radio cluster's own key,
when it has one, to KEY — so (get_tile CLUSTER-KEY) returns the selected
button's key, matching AutoCAD/BricsCAD radio-group semantics."
  (let* ((root (dcl-dialog-tile dialog))
         (cluster (terminal-find-radio-cluster root key))
         (siblings (and cluster (terminal-cluster-radio-keys cluster))))
    (dolist (k (or siblings (list key)))
      (setf (gethash k (dcl-dialog-state dialog))
            (if (string= k key) "1" "0")))
    (let ((cluster-key (and cluster (terminal-tile-key cluster))))
      (when cluster-key
        (setf (gethash cluster-key (dcl-dialog-state dialog)) key)))))

(defun terminal-set-and-fire (dialog key value reason)
  "Store VALUE under KEY and fire KEY's action with REASON."
  (setf (gethash key (dcl-dialog-state dialog)) value)
  (dcl-runtime-fire-action dialog key value reason))

(defun terminal-handle-value-tile (dialog tile key value modifier)
  "Update the dialog state for an interactive non-button tile and fire its
action with the $reason implied by MODIFIER (see terminal-modifier-reason).
Prompts for a value when the user supplied none on an editable tile."
  (case (dcl-tile-type tile)
    (:toggle
     ;; key=1/0 sets; a bare `key' (or key!) flips the current state.
     (let* ((current (gethash key (dcl-dialog-state dialog) "0"))
            (new (cond (value (if (terminal-truthy-p value) "1" "0"))
                       (t (if (equal current "1") "0" "1")))))
       (terminal-set-and-fire dialog key new
                              (terminal-select-reason modifier))))
    (:radio-button
     (terminal-select-radio dialog key)
     (dcl-runtime-fire-action dialog key "1"
                              (terminal-select-reason modifier)))
    ((:list-box :popup-list)
     ;; The stored value is the selected item's INDEX (as a string), which
     ;; is what get_tile returns for a list in AutoLISP. Accept a numeric
     ;; index or match an item by name.
     (let* ((items (terminal-list-items dialog key))
            (index (cond
                     ((null value) (gethash key (dcl-dialog-state dialog) ""))
                     ((every #'digit-char-p value) value)
                     (t (let ((pos (position value items :test #'string-equal)))
                          (if pos (princ-to-string pos) value))))))
       (terminal-set-and-fire dialog key index
                              (terminal-select-reason modifier))))
    (:slider
     (let* ((mn (or (tile-attribute tile "min_value") 0))
            (mx (or (tile-attribute tile "max_value") 100))
            ;; A commit (lost focus) with no value keeps the current value;
            ;; otherwise a bare `key' prompts for one.
            (raw (cond (value value)
                       ((eq modifier :commit) nil)
                       (t (terminal-prompt-line (format nil "~A=" key)))))
            (n (and raw (ignore-errors (parse-integer raw :junk-allowed t))))
            (clamped (cond ((null n) (gethash key (dcl-dialog-state dialog) "0"))
                           ((< n mn) (princ-to-string mn))
                           ((> n mx) (princ-to-string mx))
                           (t (princ-to-string n)))))
       (terminal-set-and-fire dialog key clamped
                              (terminal-modifier-reason modifier :reason-changed))))
    (otherwise
     ;; edit_box and any other value-bearing tile.
     (let ((new-value
             (cond (value value)
                   ;; `key!' (lost focus) fires with the current value —
                   ;; no re-prompt.
                   ((eq modifier :commit) (gethash key (dcl-dialog-state dialog) ""))
                   (t (terminal-prompt-line (format nil "~A=" key))))))
       (when new-value
         (terminal-set-and-fire dialog key new-value
                                (terminal-modifier-reason modifier :reason-changed)))))))

(defun terminal-handle-line (dialog interactive line)
  "Interpret one input line. Returns :continue to keep prompting, or an
integer status when the line caused done_dialog to fire (a button's action,
or the accept/cancel convention).

The line grammar is:
  KEY            activate the tile — press a button, flip a toggle, select a
                 radio_button / list item ($reason 1 = selected)
  KEY=VALUE      change the tile's value ($reason 2 = changed for edit_box /
                 slider; a select for list/popup/toggle)
  KEY==VALUE     double-click select ($reason 4)
  KEY! / KEY=V!  the tile loses focus after the edit ($reason 3)

A named tile fires its registered action — including the `accept' / `cancel'
predefined buttons (now real tiles after cluster expansion). Only when the
word names no tile do we fall back to the bare accept->1 / cancel->0
convention (terminal-fire-registered), kept as a harmless stopgap for a
dialog that ships no explicit accept/cancel tile."
  (multiple-value-bind (key value modifier) (terminal-parse-command line)
    (let ((entry (assoc key interactive :test #'string=)))
      (cond
        (entry
         (let ((tile (cdr entry)))
           (case (dcl-tile-type tile)
             ((:button :image-button)
              (or (terminal-handle-button dialog tile key) :continue))
             (otherwise
              (terminal-handle-value-tile dialog tile key value modifier)
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
  "Parse one TUI command into (values KEY VALUE MODIFIER). Grammar:
`key' (:activate), `key=value' (:change), `key==value' (:double, a
double-click), and a trailing `!' (:commit, focus lost) on either form."
  (let* ((trimmed (string-trim '(#\Space #\Tab #\Return) line))
         (commit (and (plusp (length trimmed))
                      (char= (char trimmed (1- (length trimmed))) #\!)))
         (trimmed (if commit
                      (string-right-trim '(#\! #\Space) trimmed)
                      trimmed))
         (eq-pos (position #\= trimmed)))
    (cond
      ((null eq-pos)
       (values trimmed nil (if commit :commit :activate)))
      (t
       (let* ((key (string-trim '(#\Space) (subseq trimmed 0 eq-pos)))
              (rest (subseq trimmed (1+ eq-pos)))
              (double (and (plusp (length rest)) (char= (char rest 0) #\=)))
              (value (string-trim '(#\Space)
                                  (if double (subseq rest 1) rest))))
         (values key value
                 (cond (double :double)
                       (commit :commit)
                       (t :change))))))))

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
