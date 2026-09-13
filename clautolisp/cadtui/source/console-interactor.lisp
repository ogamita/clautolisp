(in-package #:clautolisp.cadtui)

;;;; The cadtui console interactor (Phase 4 slice 4b).
;;;;
;;;; Frozen decision (cadtui/CLAUDE.md): the cadtui console IS an interactor in
;;;; the existing framework (clautolisp.interactor), not an ad-hoc line reader.
;;;; Its READER is the classify-line line classifier over the escape held in the
;;;; activation state (TUI-COMMAND-ESCAPE, an interactor-stacked setting, not a
;;;; global), and it stacks/unstacks like the *autolisp* / aldo / sedit
;;;; interactors -- so from the console one can descend into aldo or sedit and
;;;; return, with no new mechanism. A line is never split into two streams: it is
;;;; wholly a meta-command (leading escape) or wholly a pass-through line.

(defstruct cadtui-console-state
  "Per-activation state of the cadtui console interactor: the UI-tree ROOT it
dispatches meta-commands and routes pass-through lines against, and the ESCAPE
character marking a meta-command line (per-activation, not a global)."
  root
  (escape #\=))

(defun tui-command-escape ()
  "The meta-command escape character of the current console activation."
  (cadtui-console-state-escape (activation-state *command-activation*)))

(defun (setf tui-command-escape) (new-escape)
  (setf (cadtui-console-state-escape (activation-state *command-activation*))
        new-escape))

(defun %cadtui-console-reader (input-context)
  "READER of the cadtui console: read one physical line and classify it with the
current activation's escape. Returns (KIND PAYLOAD); ends the interactor at EOF."
  (let ((line (read-line-from-input-context input-context)))
    (if (eq line :eof)
        (interactor-return :terminated)
        (multiple-value-bind (kind payload)
            (classify-line line :escape (tui-command-escape))
          (list kind payload)))))

(defun %cadtui-console-evaluate (input)
  "EVALUATOR of the cadtui console: run a meta-command immediately (an
unresolved target becomes an :error result), or deliver a pass-through line to
the implicit-input console's queue (spec §5.6)."
  (destructuring-bind (kind payload) input
    (let ((root (cadtui-console-state-root (activation-state *command-activation*))))
      (ecase kind
        (:meta-command
         (handler-case (dispatch-meta-command (parse-meta-command payload) root)
           (cadtui-error (condition)
             (make-command-result :status :error :verb nil
                                  :text (princ-to-string condition) :data condition))))
        (:pass-through
         (let ((console (implicit-input-target root)))
           (when console (deliver-line-to-console console payload))
           (make-command-result :status :pass-through :verb nil
                                :text payload :data console)))))))

(define-interactor *cadtui-console*
  :name "CADTUI-CONSOLE" :alias "CONSOLE"
  :prompt "cad> "
  :reader '%cadtui-console-reader
  :evaluator '%cadtui-console-evaluate
  :documentation "The cadtui console interactor: a line is a meta-command when
it begins with the escape (default =, an interactor-stacked setting), otherwise
a pass-through line delivered to the active console. Stacks/unstacks like the
aldo and sedit interactors.")

(defun push-console-interactor (root &key (escape #\=))
  "Push a cadtui console activation over ROOT onto the interactor stack."
  (push-interactor *cadtui-console*
                   (make-cadtui-console-state :root root :escape escape)))
