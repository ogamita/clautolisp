;;;; clautolisp/autolisp-sedit/source/modes.lisp
;;;;
;;;; The two modes and their transition machine (sedit spec §1, §5, §6.6): the
;;;; revised command set, the NAV<->EDIT machine, a marked-selection renderer,
;;;; and an interactive driver. A command interpreter dispatches one line per the
;;;; §6.6 rules; the runtime couplings — running a debugger command, evaluating,
;;;; loading — are callbacks (DEBUG-HOOK / EVAL-HOOK / LOAD-HOOK), so this stays a
;;;; dependency-free library. The aldo bridge and the AutoLISP clal-sedit builtin
;;;; wire these hooks in the debugger UI / runtime.

(in-package #:clautolisp.sedit)

;;; --- the command vocabulary (§5) ------------------------------------------

(defparameter +motion-tokens+
  '("d" "down" "u" "up"
    ">" "f" "forward" "<" "b" "backward"
    "<<" "first" ">>" "last")
  "The both-mode motion keys/words (§5): d u > < << >>; =f= / =b= alias =>= / =<=
(forward / backward); ±N is handled separately.")

(defparameter +editing-tokens+
  '("i" "insert" "a" "add" "r" "replace" "ic" "ac" "rc" "z" "undo"
    "c" "copy" "x" "cut" "v" "paste"
    "wrap" "slurp" "barf" "splice" "split" "join"
    "m" "macroexpand" "s" "save" "n" "new" "rename" "delete")
  "The EDIT-mode commands (§5): issuing one in NAV switches to EDIT (§6.6).")

(defun %motion-token-p (token) (member token +motion-tokens+ :test #'string=))
(defun %editing-token-p (token) (member token +editing-tokens+ :test #'string=))

(defun %split-command (line)
  "LINE split into its first token and the trimmed remainder (or NIL / NIL)."
  (let* ((s (string-trim '(#\Space #\Tab) line))
         (sp (position #\Space s)))
    (if (zerop (length s))
        (values nil nil)
        (values (subseq s 0 (or sp (length s)))
                (and sp (string-trim '(#\Space #\Tab) (subseq s sp)))))))

(defun %signed-integer (token)
  "The integer of a signed skip token (\"+3\", \"-2\"), or NIL."
  (and (>= (length token) 2) (member (char token 0) '(#\+ #\-) :test #'char=)
       (ignore-errors (parse-integer token))))

(defun %arg-node (arg)
  "The new form an editing command inserts: ARG parsed, or a stand-alone nil."
  (if (and arg (plusp (length arg))) (parse-form arg) (make-atom-node nil)))

(defun %arg-comment (arg)
  "The comment object an ic/ac/rc command inserts (default an empty ;- comment)."
  (make-comment-node (if (and arg (plusp (length arg))) arg "; ")))

;;; --- selection in a directory? (r/x/n object-exclusivity, §5) -------------

(defun %dir-selection-p (state)
  "True when the selection is a directory entry (a file or sub-directory node) —
so r means rename, x delete, and n new (spec §5, object-exclusive)."
  (let ((focus (loc-focus (sedit-state-loc state))))
    (or (dir-node-p focus) (file-node-p focus))))

;;; --- motions --------------------------------------------------------------

(defun %do-motion (state token)
  (cond
    ((member token '("d" "down") :test #'string=) (sedit-down state))
    ((member token '("u" "up") :test #'string=) (sedit-up state))
    ((member token '(">" "f" "forward") :test #'string=) (sedit-right state))
    ((member token '("<" "b" "backward") :test #'string=) (sedit-left state))
    ((member token '("<<" "first") :test #'string=) (sedit-first state))
    ((member token '(">>" "last") :test #'string=) (sedit-last state))))

;;; --- editing (§5 / §6.3) --------------------------------------------------

(defun %do-editing (session token arg eval-hook)
  "Perform an EDIT-mode command on SESSION (already switched to :edit)."
  (let ((state (sedit-session-state session)))
    (cond
      ((member token '("i" "insert") :test #'string=) (sedit-insert state (%arg-node arg)))
      ((member token '("a" "add") :test #'string=) (sedit-add state (%arg-node arg)))
      ((member token '("ic") :test #'string=) (sedit-insert state (%arg-comment arg)))
      ((member token '("ac") :test #'string=) (sedit-add state (%arg-comment arg)))
      ((member token '("rc") :test #'string=) (sedit-replace state (%arg-comment arg)))
      ((member token '("z" "undo") :test #'string=) (sedit-undo state))
      ((member token '("c" "copy") :test #'string=) (sedit-copy state))
      ((member token '("v" "paste") :test #'string=) (sedit-paste state))
      ((string= token "wrap") (sedit-wrap state))
      ((string= token "slurp") (sedit-slurp state))
      ((string= token "barf") (sedit-barf state))
      ((string= token "splice") (sedit-splice state))
      ((string= token "split") (sedit-split state))
      ((string= token "join") (sedit-join state))
      ((member token '("m" "macroexpand") :test #'string=) (%do-macroexpand state eval-hook))
      ((member token '("s" "save") :test #'string=) (%do-save session arg))
      ;; r/x/n are object-exclusive: rename/delete/new on a directory entry,
      ;; else replace/cut (§5)
      ((member token '("r" "replace") :test #'string=)
       (if (%dir-selection-p state) (%do-rename session arg) (sedit-replace state (%arg-node arg))))
      ((member token '("x" "cut") :test #'string=)
       (if (%dir-selection-p state) (%do-delete session) (sedit-cut state)))
      ((member token '("n" "new") :test #'string=) (%do-new session arg)))))

(defun %do-macroexpand (state eval-hook)
  "Evaluate the selection and replace it by the result (spec §5.6). Needs
EVAL-HOOK (node -> result-node); a no-op with a message otherwise."
  (when eval-hook
    (let ((result (funcall eval-hook (loc-focus (sedit-state-loc state)))))
      (when result (sedit-replace state result)))))

(defun %do-eval (state eval-hook)
  "Evaluate the selection (spec §5.6). Non-mutating; returns the result via
EVAL-HOOK, or NIL."
  (and eval-hook (funcall eval-hook (loc-focus (sedit-state-loc state)))))

;;; --- file: load / save (§5.7–§5.8) ----------------------------------------

(defun %do-load (session arg load-hook)
  "load [FILE] (§5.7): load the current file or FILE into the running system via
LOAD-HOOK. Not an editing command — the mode is unchanged (§6.6)."
  (let ((path (or arg (%session-file session))))
    (when (and load-hook path) (funcall load-hook path))))

(defun %do-save (session arg)
  "save [PATH] (§5.8): write the edited file/form to PATH, or the session's file."
  (let ((path (or arg (%session-file session))))
    (when path
      (sedit-save (sedit-result-node (sedit-state-loc (sedit-session-state session))) path))))

(defun %session-file (session)
  "The file path backing SESSION, or NIL (a stand-alone / directory session)."
  (let ((origin (sedit-session-origin session)))
    (and (consp origin) (eq (first origin) :file) (second origin))))

;;; --- directory ops (§5.9): act on disk, then re-read the listing ----------

(defun %session-dir (session)
  (let ((origin (sedit-session-origin session)))
    (and (consp origin) (eq (first origin) :dir) (second origin))))

(defun %reread-directory (session)
  "Rebuild the session's dir-node from disk, selecting its first entry."
  (let ((dir (%session-dir session)))
    (when dir
      (setf (sedit-state-loc (sedit-session-state session)) (%first-child-loc (read-directory dir))))))

(defun %do-new (session arg)
  (let ((dir (%session-dir session)))
    (when (and dir arg) (sedit-fs-new-file dir arg) (%reread-directory session))))

(defun %do-rename (session arg)
  (let ((dir (%session-dir session))
        (focus (loc-focus (sedit-state-loc (sedit-session-state session)))))
    (when (and dir arg (or (file-node-p focus) (dir-node-p focus)))
      (let ((name (if (file-node-p focus) (file-node-name focus) (dir-node-name focus))))
        (sedit-fs-rename (merge-pathnames name (uiop:ensure-directory-pathname dir)) arg)
        (%reread-directory session)))))

(defun %do-delete (session)
  (let ((dir (%session-dir session))
        (focus (loc-focus (sedit-state-loc (sedit-session-state session)))))
    (when (and dir (or (file-node-p focus) (dir-node-p focus)))
      (let ((name (if (file-node-p focus) (file-node-name focus) (dir-node-name focus))))
        (sedit-fs-delete (merge-pathnames name (uiop:ensure-directory-pathname dir)))
        (%reread-directory session)))))

;;; --- the transition machine (§6.6) ----------------------------------------

(defun sedit-command (session line &key debug-hook eval-hook load-hook)
  "Dispatch one command LINE against SESSION per the two-mode machine (§6.6).
Returns (values SESSION ACTION): ACTION is NIL (keep editing), :QUIT, :HELP,
:UNKNOWN, or a debugger resume directive from DEBUG-HOOK. Editing commands switch
NAV->EDIT and run; `edit'/`nav' switch modes; `debug'/`aldo' CMD run a debugger
command and return to NAV; a bare debugger command runs directly in NAV (the
navigator dictionary is stacked over the debugger's); motions, eval and load keep
the mode."
  (let ((state (sedit-session-state session)))
    (multiple-value-bind (token arg) (%split-command line)
      (cond
        ((null token) (values session nil))
        ((member token '("q" "quit") :test #'string=) (values session :quit))
        ((member token '("h" "?" "help") :test #'string=) (values session :help))
        ((member token '("l" "load") :test #'string=)
         (%do-load session arg load-hook) (values session nil))
        ((%motion-token-p token) (%do-motion state token) (values session nil))
        ((%signed-integer token) (sedit-skip state (%signed-integer token)) (values session nil))
        ((member token '("e" "eval") :test #'string=)
         (%do-eval state eval-hook) (values session nil))
        ((string= token "edit") (setf (sedit-state-mode state) :edit) (values session nil))
        ((string= token "nav") (setf (sedit-state-mode state) :nav) (values session nil))
        ((member token '("debug" "aldo") :test #'string=)
         (let ((directive (and debug-hook arg (funcall debug-hook arg))))
           (setf (sedit-state-mode state) :nav)
           (values session directive)))
        ((%editing-token-p token)
         (setf (sedit-state-mode state) :edit)         ; NAV->EDIT, or stay EDIT
         (%do-editing session token arg eval-hook)
         (values session nil))
        ((eq (sedit-state-mode state) :nav)
         ;; a bare debugger command in NAV — the stacked debugger dictionary
         (values session (and debug-hook (funcall debug-hook line))))
        (t (values session :unknown))))))       ; EDIT: debugger needs the prefix

;;; --- rendering the selection ----------------------------------------------

(defun render-selection (loc &key (open "[") (close "]"))
  "The top-level form the selection at LOC is in, with the selected node wrapped
in OPEN…CLOSE (spec §2/§5.2 examples, e.g. (list [nil])). Rendered structurally
along the path to the focus so the markers can be placed; verbatim elsewhere."
  (let* ((top (loc-focus (%top-level-loc loc)))
         (rel (nthcdr (length (loc-path (%top-level-loc loc))) (loc-path loc))))
    (%emit-marked top rel 0 open close)))

(defun %top-level-loc (loc)
  "Ascend out of nested lists to the top-level form's location."
  (let ((l loc))
    (loop for ctx = (loc-ctx l)
          while (and ctx (list-node-p (ctx-parent ctx)))
          do (setf l (loc-up l)))
    l))

(defun %emit-marked (node path col open close)
  (cond
    ((null path) (concatenate 'string open (%emit node col) close))
    ((list-node-p node)
     (let* ((children (list-node-children node)) (idx (first path)))
       (format nil "(~{~A~^ ~})"
               (loop for c in children for i from 0
                     collect (if (= i idx)
                                 (%emit-marked c (rest path) (1+ col) open close)
                                 (%emit c (1+ col)))))))
    (t (%emit node col))))

(defun sedit-mode-prompt (session)
  "The mode prompt for SESSION: SEDIT> in EDIT, NAV> in NAV."
  (if (eq (sedit-state-mode (sedit-session-state session)) :edit) "SEDIT" "NAV"))

;;; --- the interactive driver -----------------------------------------------

(defun sedit-help-text ()
  (format nil "commands (§5): d u  > (f) < (b)  << >>  ±N move | i a r insert/add/replace | ~
               ic ac rc comment | z undo | c x v copy/cut/paste | ~
               wrap slurp barf splice split join | e eval m macroexpand | ~
               l load s save | edit nav | debug/aldo CMD | q quit | h help"))

(defun sedit-run (session &key (input *standard-input*) (output *standard-output*)
                               debug-hook eval-hook load-hook)
  "Run the interactive editor loop on SESSION until `quit' / EOF, then return the
§2 result (session-result). Each turn renders the marked selection and the mode
prompt, reads a command line, and dispatches it (§6.6)."
  (loop
    (format output "~&       ~A~%~A> "
            (render-selection (sedit-state-loc (sedit-session-state session)))
            (sedit-mode-prompt session))
    ;; Flush the (newline-less) prompt to the terminal BEFORE reading, so it is
    ;; shown ahead of the echoed input rather than after it (a general rule:
    ;; finish-output the output stream before reading its paired input stream).
    (finish-output output)
    (let ((line (read-line input nil :eof)))
      (when (eq line :eof) (return))
      (multiple-value-bind (_ action)
          (sedit-command session line :debug-hook debug-hook :eval-hook eval-hook
                                      :load-hook load-hook)
        (declare (ignore _))
        (case action
          (:quit (return))
          (:help (format output "~A~%" (sedit-help-text)))
          (:unknown (format output "? unknown command (h for help)~%"))))))
  (session-result session))
