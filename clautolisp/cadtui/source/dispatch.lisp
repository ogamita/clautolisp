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
       (make-command-result :status :pass-through :verb nil
                            :text payload :data (implicit-input-target root)))
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
