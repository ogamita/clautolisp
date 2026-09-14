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
character marking a meta-command line (per-activation, not a global).

PASS-READER and PASS-EVALUATOR are the optional hosting seam (spec §5.6 rule
0): when the console is the TOP interactor of a live REPL rather than a stacked
console over a threaded console runtime, the host supplies these so that a
non-meta line is read and evaluated by the REPL machinery below (,-commands,
!shell, balanced multi-line AutoLISP) instead of being queued for a console
thread. Both NIL (the default) keeps the pure Phase-4 behaviour: a physical
line is classified and a pass-through line is delivered to the implicit-input
console's type-ahead queue.

  PASS-READER    (function (input-context) -> reader-result), consulted for a
                 non-meta line: the classified payload is unread and this reader
                 takes over (it may itself return an INPUT-COMMAND for a
                 ,-command, or (:SOURCE TEXT) for AutoLISP source).
  PASS-EVALUATOR (function (source) -> result), consulted for a (:SOURCE TEXT)
                 the classified/PASS-READER path yields: evaluate + print it as
                 an AutoLISP REPL turn."
  root
  (escape #\=)
  (pass-reader nil)
  (pass-evaluator nil))

(defun tui-command-escape ()
  "The meta-command escape character of the current console activation."
  (cadtui-console-state-escape (activation-state *command-activation*)))

(defun (setf tui-command-escape) (new-escape)
  (setf (cadtui-console-state-escape (activation-state *command-activation*))
        new-escape))

(defun %cadtui-console-reader (input-context)
  "READER of the cadtui console: read one physical line and classify it with the
current activation's escape. A meta-command line (leading escape) always returns
(:META-COMMAND PAYLOAD). For a non-meta line: with no PASS-READER (the stacked
console) return (:PASS-THROUGH PAYLOAD); with a PASS-READER (hosting a live
REPL) unread the classified payload and hand it to that reader, so ,-commands,
!shell and balanced multi-line AutoLISP behave exactly as at the bare REPL.
Ends the interactor at EOF (returns :EOF when hosting a REPL, so the loop leaves
cleanly)."
  (let* ((state (activation-state *command-activation*))
         (pass-reader (cadtui-console-state-pass-reader state))
         (line (read-line-from-input-context input-context)))
    (if (eq line :eof)
        (if pass-reader :eof (interactor-return :terminated))
        (multiple-value-bind (kind payload)
            (classify-line line :escape (cadtui-console-state-escape state))
          (if (and pass-reader (eq kind :pass-through))
              (progn (unread-line-from-input-context payload input-context)
                     (funcall pass-reader input-context))
              (list kind payload))))))

(defun %cadtui-console-evaluate (input)
  "EVALUATOR of the cadtui console: run a meta-command immediately (an
unresolved target becomes an :error result); evaluate a (:SOURCE TEXT) turn via
the activation's PASS-EVALUATOR when hosting a live REPL; otherwise deliver a
pass-through line to the implicit-input console's queue (spec §5.6)."
  (destructuring-bind (kind payload) input
    (let* ((state (activation-state *command-activation*))
           (root (cadtui-console-state-root state)))
      (ecase kind
        (:meta-command
         ;; Dispatch the meta-command (localise-meta-line canonicalises localised
         ;; tokens first, as INTERPRET-LINE does) and print its rendering, so a
         ;; =dump/=help/… shows its result at the REPL. The interactor loop does
         ;; not print an evaluator's return value, hence the explicit output.
         (let ((result (handler-case
                           (dispatch-meta-command
                            (parse-meta-command (localise-meta-line payload)) root)
                         (cadtui-error (condition)
                           (make-command-result :status :error :verb nil
                                                :text (princ-to-string condition)
                                                :data condition)))))
           (let ((text (command-result-text result)))
             (when (and text (plusp (length text)))
               (format *standard-output* "~&~A~%" text)))
           result))
        (:source
         ;; A PASS-READER classified this as AutoLISP source (REPL hosting):
         ;; evaluate + print it through the host's REPL turn.
         (funcall (cadtui-console-state-pass-evaluator state) payload))
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

(defun make-console-activation (root &key (escape #\=) pass-reader pass-evaluator)
  "Build a cadtui console ACTIVATION over ROOT (an interactor stack entry, for a
host that assembles the stack itself, e.g. the REPL as TOP interactor). ESCAPE
is the meta-command escape; PASS-READER / PASS-EVALUATOR are the REPL-hosting
seam (see CADTUI-CONSOLE-STATE)."
  (make-activation *cadtui-console*
                   (make-cadtui-console-state :root root :escape escape
                                              :pass-reader pass-reader
                                              :pass-evaluator pass-evaluator)))
