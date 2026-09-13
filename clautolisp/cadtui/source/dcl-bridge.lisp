(in-package #:clautolisp.cadtui)

;;;; DCL integration (Phase 3 slice 1): mirror the DCL runtime into ui-nodes.
;;;;
;;;; The autolisp-dcl runtime is a passive state machine that pushes to a
;;;; process-wide presentation backend, the *dcl-renderer* (a struct of function
;;;; slots; runtime.lisp). cadtui plugs in EXACTLY there: it installs its own
;;;; dcl-renderer whose open/set-tile/mode/close callbacks MIRROR the live
;;;; dcl-dialog / dcl-tile model into ui-dialog / ui-tile nodes under the active
;;;; drawing (spec tree /application/drawings[i]/dialogs[]/dialog:<id>/tile:<key>,
;;;; roadmap phase 3). cadtui never forks the runtime and never touches the
;;;; AutoLISP evaluator directly — callbacks are fired through the runtime's own
;;;; dcl-runtime-fire-action (wired in slice 2).
;;;;
;;;; This slice lands the renderer + the DCL->tree mirror only. Verb wiring
;;;; (input/click/close firing callbacks) is slice 2; the headless start_dialog
;;;; event-queue driver is slice 3.

(defvar *cadtui-dcl-root* nil
  "The cadtui root (a ui-application) whose active drawing receives mirrored DCL
dialogs. A host session binds/sets it; tests bind it around a dialog.")

;;; --- Locating placement + mirrored nodes --------------------------

(defun %dcl-placement-node (root)
  "Where a mirrored dialog attaches: the active drawing of ROOT, or ROOT itself
when there is no drawing (e.g. --host cador)."
  (or (and root (find :drawing (ui-children root) :key #'ui-role))
      root))

(defun %find-ui-dialog (dcl)
  "The ui-dialog mirroring the running DCL dialog DCL, or NIL — found by its
back-pointer in the dcl-source slot, anywhere under *cadtui-dcl-root*."
  (and *cadtui-dcl-root*
       (find-node *cadtui-dcl-root*
                  (lambda (n)
                    (and (eq :dialog (ui-role n))
                         (eq dcl (ui-dcl-source n)))))))

(defun %find-ui-tile (dcl key)
  "The ui-tile with KEY under the ui-dialog mirroring DCL, or NIL."
  (let ((uidlg (%find-ui-dialog dcl)))
    (and uidlg (ui-find-child uidlg (princ-to-string key)))))

;;; --- Mirroring the DCL model into ui-nodes -------------------------

(defun %collect-keyed-tiles (tile)
  "All tiles in TILE's subtree (TILE included) that carry a key, in preorder.
The dialog's addressable tiles are flattened directly under the ui-dialog
(spec tree: dialog:<id>/tile:<key>*), skipping unkeyed layout tiles."
  (let ((acc '()))
    (labels ((walk (tl)
               (when (dcl-tile-key tl) (push tl acc))
               (dolist (child (dcl-tile-children tl)) (walk child))))
      (dolist (child (dcl-tile-children tile)) (walk child)))
    (nreverse acc)))

(defun %mirror-tile (tile)
  "Build the ui-tile mirroring the parsed dcl-tile TILE."
  (make-instance 'ui-tile
                 :key (dcl-tile-key tile)
                 :tile-type (dcl-tile-type tile)
                 :label (tile-attribute tile "label")
                 :value (tile-attribute tile "value")))

(defun %mirror-dialog (dcl)
  "Build and attach the ui-dialog subtree mirroring the running DCL dialog DCL
under *cadtui-dcl-root*'s placement node. Returns the ui-dialog."
  (let* ((root-tile (dcl-dialog-tile dcl))
         (uidlg (make-instance 'ui-dialog
                               :key (princ-to-string (dcl-dialog-id dcl))
                               :label (tile-attribute root-tile "label")
                               :dcl-source dcl)))
    (dolist (tile (%collect-keyed-tiles root-tile))
      (add-child uidlg (%mirror-tile tile)))
    (let ((placement (%dcl-placement-node *cadtui-dcl-root*)))
      (when placement (add-child placement uidlg)))
    uidlg))

(defun %unmirror-dialog (dcl)
  "Detach the ui-dialog mirroring DCL and clear its back-pointer."
  (let ((uidlg (%find-ui-dialog dcl)))
    (when uidlg
      (let ((parent (ui-parent uidlg)))
        (when parent
          (setf (ui-children parent) (remove uidlg (ui-children parent)))))
      (setf (ui-parent uidlg) nil
            (ui-dcl-source uidlg) nil))
    uidlg))

(defun %mode->state (mode)
  "Map a DCL mode_tile MODE flag to a cadtui display state."
  (case mode
    (1 :grayed)            ; disabled
    (2 :focus)             ; set focus
    (t :normal)))          ; 0 enabled (and 3/4 focus-rect: treat as normal here)

;;; --- The cadtui DCL renderer --------------------------------------

(defun make-cadtui-dcl-renderer ()
  "A dcl-renderer whose callbacks mirror the DCL runtime into the cadtui tree.
run-fn is the no-op default in this slice (return the dialog status); the
headless event-queue driver is slice 3."
  (make-dcl-renderer
   :open-fn (lambda (dcl) (%mirror-dialog dcl) nil)
   :close-fn (lambda (dcl) (%unmirror-dialog dcl) nil)
   :set-tile-fn (lambda (dcl key value)
                  (let ((tile (%find-ui-tile dcl key)))
                    (when tile (setf (ui-tile-value tile) value)))
                  nil)
   :mode-fn (lambda (dcl key mode)
              (let ((tile (%find-ui-tile dcl key)))
                (when tile (setf (ui-state tile) (%mode->state mode))))
              nil)))

(defun install-cadtui-dcl-renderer (root)
  "Make ROOT the DCL placement root and install the cadtui DCL renderer as the
process-wide *dcl-renderer*. Returns the renderer."
  (setf *cadtui-dcl-root* root)
  (let ((renderer (make-cadtui-dcl-renderer)))
    (install-default-renderer renderer)
    renderer))
