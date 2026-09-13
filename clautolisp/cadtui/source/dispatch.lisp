(in-package #:clautolisp.cadtui)

;;;; Verb dispatch + the non-modal line entry (Phase 2 slice 4).
;;;;
;;;; INTERPRET-LINE is the pure seam the Phase-4 console interactor's READER
;;;; will call: it classifies a line, and either routes a pass-through line to
;;;; the implicit-input target console (rule 0, spec §5.6) or parses and
;;;; dispatches a meta-command. It performs NO real I/O beyond building result
;;;; strings and touches no threads — executing a pass-through line (the
;;;; REPL/CAD rules 1-3) and the live console/thread wiring are Phase 4.
;;;;
;;;; This slice lands the FULL, tree-only verbs: dump (all options; window: is a
;;;; parsed-and-accepted stand-in until Phase 5's spatial cull), page/next/
;;;; previous over the last dump, and help. The state-changing verbs
;;;; (activate/select/close/zoom/... and the click/key family) are slice 5.

(defstruct command-result
  "The immediate result of a line (spec §5.3: each meta-command returns an ack /
new state / a dump straight away). STATUS is :ok | :not-yet | :pass-through |
:error; VERB the dispatched verb (or nil); TEXT the human-readable rendering;
DATA a structured payload (a dump-descriptor, a resolved node, the routed
console, ...)."
  status verb text data)

(defvar *verb-table* (make-hash-table :test 'eq)
  "Maps a verb keyword to a handler (meta-command root) -> command-result.")

(defmacro define-verb (name (mc root) &body body)
  "Register a verb handler under keyword NAME."
  `(setf (gethash ,name *verb-table*)
         (lambda (,mc ,root)
           (declare (ignorable ,mc ,root))
           ,@body)))

;;; --- Argument helpers ---------------------------------------------

(defun %first-target (mc)
  "The raw target string of MC's first positional, or NIL when it is not a
target."
  (let ((p (first (meta-command-positionals mc))))
    (and (consp p) (eq (car p) :target) (cdr p))))

(defun %option (mc key)
  "MC's option value for KEY, or NIL."
  (cdr (assoc key (meta-command-options mc))))

;;; --- The implicit-input target (spec §5.6 rule 0) -----------------

(defun implicit-input-target (root)
  "The console a pass-through line is delivered to: the active drawing's console
if there is an active drawing, else the application console — never both."
  (let ((active (find :drawing (ui-children root) :key #'ui-role)))
    (or (and active (find :console (ui-children active) :key #'ui-role))
        (find :console (ui-children root) :key #'ui-role))))

;;; --- Dispatch + the line entry ------------------------------------

(defun dispatch-meta-command (mc root)
  "Dispatch a parsed META-COMMAND MC against ROOT via *verb-table*. May signal
a cadtui-error (an unresolved target); INTERPRET-LINE catches those."
  (let ((handler (gethash (meta-command-verb mc) *verb-table*)))
    (if handler
        (funcall handler mc root)
        (make-command-result :status :error :verb (meta-command-verb mc)
                             :text (format nil "Unknown meta-command verb ~S."
                                           (meta-command-verb mc))))))

(defun interpret-line (line root &key (escape *command-escape*))
  "Interpret one physical LINE against the tree at ROOT and return a
COMMAND-RESULT. A pass-through line is routed (not executed) to the
implicit-input console; a meta-command is parsed and dispatched. Pure: no I/O,
no threads. Parse/address errors become an :error result."
  (multiple-value-bind (kind payload) (classify-line line :escape escape)
    (ecase kind
      (:pass-through
       ;; Deliver the line to the implicit-input console's type-ahead queue
       ;; (Phase 4). A console with no live context/queue (a Phase 1-3 tree)
       ;; drops it harmlessly, so the result is unchanged for those callers.
       (let ((console (implicit-input-target root)))
         (when console (deliver-line-to-console console payload))
         (make-command-result :status :pass-through :verb nil
                              :text payload :data console)))
      (:meta-command
       (handler-case
           (dispatch-meta-command (parse-meta-command payload) root)
         (cadtui-error (condition)
           (make-command-result :status :error :verb nil
                                :text (princ-to-string condition)
                                :data condition)))))))

;;; --- FULL verbs: dump, pagination, help ---------------------------

(define-verb :dump (mc root)
  (let* ((target (%first-target mc))
         (node (if target (resolve-target root target) root))
         (depth (%option mc :depth))
         (page (%option mc :page))
         (size (%option mc :size))
         (path (or target "/application")))
    ;; NB: window: is parsed and accepted here but the 2D spatial cull it selects
    ;; needs entity bounding boxes = Phase 5; a batch/tree dump ignores it.
    (if (or page size)
        ;; a paginated list dump of NODE's children.
        (let ((text (with-output-to-string (s)
                      (dump-list node :page (or page 1) :page-size (or size 50)
                                 :path path :stream s))))
          (make-command-result :status :ok :verb :dump :text text :data *last-dump*))
        ;; a structural tree dump; still gets a D<n> for later addressing.
        (let* ((descriptor (register-dump node :path path :depth depth))
               (text (with-output-to-string (s)
                       (format s "D~D ~A~%" (dump-descriptor-number descriptor) path)
                       (dump-node node :depth depth :stream s))))
          (make-command-result :status :ok :verb :dump :text text
                               :data descriptor)))))

(defun %page-command (verb which)
  "Re-page the last dump: WHICH is :next, :previous, or a 1-based page integer."
  (let ((descriptor *last-dump*))
    (if (null descriptor)
        (make-command-result :status :error :verb verb :text "No dump to page.")
        (let* ((current (or (dump-descriptor-page descriptor) 1))
               (target (cond ((eq which :next) (1+ current))
                             ((eq which :previous) (1- current))
                             ((integerp which) which)
                             (t current)))
               (out (make-string-output-stream))
               (result (dump-page descriptor target :stream out)))
          (if result
              (make-command-result :status :ok :verb verb
                                   :text (get-output-stream-string out)
                                   :data descriptor)
              (make-command-result :status :error :verb verb
                                   :text (format nil "No page ~A." target)))))))

(define-verb :page (mc root)
  (%page-command :page (or (first (meta-command-positionals mc)) 1)))

(define-verb :next (mc root)
  (%page-command :next :next))

(define-verb :previous (mc root)
  (%page-command :previous :previous))

(defparameter *help-text*
  "cadtui meta-commands (prefix each with the escape, default '='):
  dump(target [, depth: n] [, page: n] [, size: n] [, window: (x1 y1 x2 y2)])
  page(n) / next / previous     -- page the last dump
  activate(target)              -- give focus to a window/drawing/dialog
  key(name)                     -- simulate a special/function key
  click / dclick / right-click(target)
  drag(target, dx, dy) | drag(target1, target2)
  select / add-selection / remove-selection(target...)
  input(target, \"text\")         -- type into an edit_box tile
  close(target) | zoom(target, ...) | pan(target, dx, dy)
  cancel-command() | help()
Targets: absolute /application/... paths, role:key, role[i], active-drawing,
a D<n>.key reference, or a bare key from the last dump."
  "The meta-command repertoire returned by help() (spec §5.3).")

(define-verb :help (mc root)
  (make-command-result :status :ok :verb :help :text *help-text*))

;;; --- PARTIAL (tree-only) and STAND-IN verbs (Phase 2 slice 5) ------
;;;
;;; These change the tree state that is meaningful headlessly (the active
;;; drawing order, a view's selection, a tile's value, a viewport request, node
;;; detachment) and stand in for the effects that need threads / live CAD /
;;; edit-mode geometry (Phase 4/5). Every handler still RESOLVES its target now,
;;; so an unresolvable target errors in Phase 2; only the effect is deferred.

(defun %positional-targets (mc root)
  "Resolve each :target positional of MC to a node."
  (loop for p in (meta-command-positionals mc)
        when (and (consp p) (eq (car p) :target))
          collect (resolve-target root (cdr p))))

(defun %cad-view-of (node)
  "The ui-cad-view at or above NODE, or NIL."
  (loop for n = node then (ui-parent n)
        while n
        when (eq :cad-view (ui-role n)) return n))

(defun %activate-drawing (drawing)
  "Move DRAWING to the front of its parent's :drawing children, so
active-drawing (= drawings[1]) becomes DRAWING."
  (let ((parent (ui-parent drawing)))
    (when parent
      (setf (ui-children parent) (remove drawing (ui-children parent)))
      (let ((pos (position :drawing (ui-children parent) :key #'ui-role)))
        (setf (ui-children parent)
              (if pos
                  (append (subseq (ui-children parent) 0 pos)
                          (list drawing)
                          (subseq (ui-children parent) pos))
                  (append (ui-children parent) (list drawing))))))
    drawing))

(define-verb :activate (mc root)
  (let* ((target (%first-target mc))
         (node (and target (resolve-target root target))))
    (cond
      ((null node)
       (make-command-result :status :error :verb :activate
                            :text "activate needs a target"))
      (t
       (when (eq :drawing (ui-role node))
         (%activate-drawing node)                ; reorder: active-drawing = node
         (activate-drawing-document node))       ; Phase 4: current document follows
       (make-command-result :status :ok :verb :activate
                            :text (format nil "activated ~A:~A"
                                          (%role-name node) (ui-key node))
                            :data node)))))

(defun %selection-command (verb mc root combine)
  (let* ((nodes (%positional-targets mc root))
         (view (and nodes (%cad-view-of (first nodes)))))
    (if view
        (progn
          (setf (ui-selection view) (funcall combine (ui-selection view) nodes))
          (make-command-result :status :ok :verb verb :data view
                               :text (format nil "selection: ~D" (length (ui-selection view)))))
        (make-command-result :status :error :verb verb
                             :text "no cad-view for the selection"))))

(define-verb :select (mc root)
  (%selection-command :select mc root (lambda (old new) (declare (ignore old)) new)))

(define-verb :add-selection (mc root)
  (%selection-command :add-selection mc root
                      (lambda (old new) (union old new))))

(define-verb :remove-selection (mc root)
  (%selection-command :remove-selection mc root
                      (lambda (old new) (set-difference old new))))

(define-verb :input (mc root)
  (let* ((target (%first-target mc))
         (node (and target (resolve-target root target)))
         (text (second (meta-command-positionals mc))))
    (cond
      ((null node) (make-command-result :status :error :verb :input
                                        :text "input needs a target"))
      ((eq :tile (ui-role node))
       (setf (ui-tile-value node) text)
       ;; Phase 3: also record into the DCL runtime and fire the tile's
       ;; action_tile callback (spec §5.3 requires both), when this tile mirrors
       ;; a live DCL dialog. No-op for a non-DCL tile.
       (let ((dcl (%live-dcl-dialog node)))
         (when dcl
           (dcl-runtime-fire-action dcl (ui-key node) text +dcl-reason-changed+)))
       (make-command-result :status :ok :verb :input :data node
                            :text (format nil "input ~S into ~A" text (ui-key node))))
      (t (make-command-result :status :error :verb :input
                              :text "input target is not a tile")))))

(define-verb :close (mc root)
  (let* ((target (%first-target mc))
         (node (and target (resolve-target root target))))
    (cond
      ((null node) (make-command-result :status :error :verb :close
                                        :text "close needs a target"))
      ((null (ui-parent node)) (make-command-result :status :error :verb :close
                                                    :text "cannot close the root"))
      (t
       ;; Phase 3: closing a mirrored dialog ends it in the DCL runtime first
       ;; (done_dialog), so a blocked start_dialog would return; then detach.
       (let ((dcl (and (eq :dialog (ui-role node)) (ui-dcl-source node))))
         (when dcl (dcl-runtime-done-dialog (dcl-dialog-id dcl) 1)))
       (let ((parent (ui-parent node)))
         (setf (ui-children parent) (remove node (ui-children parent))
               (ui-parent node) nil)
         (make-command-result :status :ok :verb :close :data parent
                              :text (format nil "closed ~A:~A"
                                            (%role-name node) (ui-key node))))))))

(defun %ensure-viewport (view)
  "VIEW's viewport struct, creating (and installing) a fresh one if unset."
  (or (ui-viewport view)
      (setf (ui-viewport view) (make-viewport))))

(defun %tuple-numbers (value)
  "The numbers of a parsed tuple VALUE (:tuple n ...), or NIL for anything else."
  (when (and (consp value) (eq (car value) :tuple))
    (cdr value)))

(define-verb :zoom (mc root)
  (let* ((target (%first-target mc))
         (node (and target (resolve-target root target)))
         (view (and node (%cad-view-of node)))
         (window (%tuple-numbers (%option mc :window)))
         (factor (%option mc :factor)))
    (cond
      ((null view)
       (make-command-result :status :error :verb :zoom :text "no cad-view to zoom"))
      ;; zoom(window:) sets the visible world rectangle (the display changes).
      ((%option mc :window)
       (if (and window (= 4 (length window)) (every #'realp window))
           (destructuring-bind (x1 y1 x2 y2) window
             (let ((vp (%ensure-viewport view)))
               (setf (viewport-x1 vp) x1 (viewport-y1 vp) y1
                     (viewport-x2 vp) x2 (viewport-y2 vp) y2))
             (make-command-result :status :ok :verb :zoom :data view :text "zoomed"))
           (make-command-result :status :error :verb :zoom
                                :text "zoom window: expects a (x1 y1 x2 y2) tuple")))
      ;; zoom(factor:) scales in place, about the window centre.
      (factor
       (if (and (realp factor) (plusp factor))
           (let* ((vp (%ensure-viewport view))
                  (cx (/ (+ (viewport-x1 vp) (viewport-x2 vp)) 2))
                  (cy (/ (+ (viewport-y1 vp) (viewport-y2 vp)) 2))
                  (hw (/ (- (viewport-x2 vp) (viewport-x1 vp)) 2 factor))
                  (hh (/ (- (viewport-y2 vp) (viewport-y1 vp)) 2 factor)))
             (setf (viewport-x1 vp) (- cx hw) (viewport-x2 vp) (+ cx hw)
                   (viewport-y1 vp) (- cy hh) (viewport-y2 vp) (+ cy hh)
                   (viewport-scale vp) (* (viewport-scale vp) factor))
             (make-command-result :status :ok :verb :zoom :data view :text "zoomed"))
           (make-command-result :status :error :verb :zoom
                                :text "zoom factor: expects a positive number")))
      ;; bare zoom() — a no-op focus request (zoom extents lands with slice 3).
      (t
       (%ensure-viewport view)
       (make-command-result :status :ok :verb :zoom :data view :text "zoomed")))))

(define-verb :pan (mc root)
  (let* ((target (%first-target mc))
         (node (and target (resolve-target root target)))
         (view (and node (%cad-view-of node)))
         (dx (second (meta-command-positionals mc)))
         (dy (third (meta-command-positionals mc))))
    (cond
      ((null view)
       (make-command-result :status :error :verb :pan :text "no cad-view to pan"))
      ((not (and (realp dx) (realp dy)))
       (make-command-result :status :error :verb :pan
                            :text "pan expects dx and dy numbers"))
      (t
       (let ((vp (%ensure-viewport view)))
         (incf (viewport-x1 vp) dx) (incf (viewport-x2 vp) dx)
         (incf (viewport-y1 vp) dy) (incf (viewport-y2 vp) dy))
       (make-command-result :status :ok :verb :pan :data view :text "panned")))))

(defparameter *key-bindings*
  '(("f2"     . :toggle-text-window)
    ("escape" . "cancel-command()")
    ("delete" . :delete-selection)
    ("tab"    . :cycle-grips))
  "Maps a key name to a prebuilt meta-command (a string, re-dispatched) or a
native-action keyword (spec §Touches). Like AutoCAD's AcceleratorCollection, a
key is a shortcut to an action already expressible another way.")

(define-verb :key (mc root)
  (let* ((p (first (meta-command-positionals mc)))
         (name (cond ((and (consp p) (eq (car p) :target)) (cdr p))
                     ((keywordp p) (string-downcase (symbol-name p)))
                     ((null p) "")
                     (t (princ-to-string p))))
         (binding (cdr (assoc name *key-bindings* :test #'string-equal))))
    (cond
      ((null binding)
       (make-command-result :status :error :verb :key
                            :text (format nil "unbound key ~S" name)))
      ;; f2 toggles the text window == activate the implicit-input console.
      ((eq binding :toggle-text-window)
       (let ((console (implicit-input-target root)))
         (make-command-result :status :ok :verb :key :data console
                              :text (format nil "activated ~A"
                                            (and console (ui-key console))))))
      ((stringp binding)
       (dispatch-meta-command (parse-meta-command binding) root))
      (t
       (make-command-result :status :not-yet :verb :key
                            :text (format nil "key ~A (~A) not yet wired" name binding))))))

(define-verb :click (mc root)
  (let* ((target (%first-target mc))
         (node (and target (resolve-target root target))))
    (cond
      ((null node) (make-command-result :status :error :verb :click
                                        :text "click needs a target"))
      ;; clicking a menu unrolls it: print its contents (spec §5.3).
      ((eq :menu (ui-role node))
       (let ((descriptor (register-dump node :path (or target ""))))
         (make-command-result :status :ok :verb :click :data descriptor
                              :text (with-output-to-string (s)
                                      (format s "D~D ~A~%"
                                              (dump-descriptor-number descriptor)
                                              (or target ""))
                                      (dump-node node :stream s)))))
      ;; Phase 3: clicking a DCL tile fires its action_tile callback (e.g. an
      ;; "accept" button whose callback runs (done_dialog 1)).
      ((and (eq :tile (ui-role node)) (%live-dcl-dialog node))
       (dcl-runtime-fire-action (%live-dcl-dialog node) (ui-key node)
                                (ui-tile-value node) +dcl-reason-selected+)
       (make-command-result :status :ok :verb :click :data node
                            :text (format nil "clicked tile ~A" (ui-key node))))
      ;; clicking an executable node would run its action (needs the CAD runtime).
      ((ui-action node)
       (make-command-result :status :not-yet :verb :click :data node
                            :text (format nil "would run action ~A" (ui-action node))))
      (t (make-command-result :status :ok :verb :click :data node
                              :text (format nil "clicked ~A:~A"
                                            (%role-name node) (ui-key node)))))))

(defun %stand-in (verb mc root)
  "A verb whose real effect needs Phase 4/5 (edit-mode / active-command /
geometry): resolve its first target now (so a bad target still errors), then
return a :not-yet ack recording the intent."
  (let ((target (%first-target mc)))
    (when target (resolve-target root target))
    (make-command-result :status :not-yet :verb verb
                         :text (format nil "~(~A~) is not yet wired (Phase 4/5)" verb))))

(define-verb :dclick (mc root) (%stand-in :dclick mc root))
(define-verb :right-click (mc root) (%stand-in :right-click mc root))
(define-verb :drag (mc root) (%stand-in :drag mc root))
(define-verb :cancel-command (mc root) (%stand-in :cancel-command mc root))

;;; --- Headless modal-dialog driver (Phase 3 slice 3) ---------------
;;;
;;; The event-queue drainer start_dialog's run-fn calls (installed into the
;;; dcl-bridge hook here, where interpret-line is defined). It applies each
;;; queued cadtui meta-command line against the DCL placement root until the
;;; dialog finishes or the queue empties, then returns the dialog's status. This
;;; is the direct analog of the terminal renderer's pre-fed stdin -- fully
;;; deterministic, single-threaded. Phase 4 replaces the pre-filled queue with a
;;; live console interactor pushing events; the run-fn/queue seam is unchanged.

(defun %drain-cadtui-dcl-events (dcl)
  "Drain *cadtui-dcl-events*, interpreting each line against *cadtui-dcl-root*,
until DCL is finished or the queue empties. Returns DCL's exit status."
  (loop while (and *cadtui-dcl-events* (not (dcl-dialog-finished-p dcl)))
        do (interpret-line (pop *cadtui-dcl-events*) *cadtui-dcl-root*))
  (dcl-dialog-status dcl))

(setf *cadtui-dcl-run-hook* #'%drain-cadtui-dcl-events)
