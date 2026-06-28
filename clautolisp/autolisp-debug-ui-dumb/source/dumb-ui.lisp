(in-package #:clautolisp.ui.dumb)

;;;; The dumb-terminal UI (spec §18). No layout: every notification is one
;;;; or more tagged lines on the output stream; at a stopping point a
;;;; sub-REPL reads single-letter commands (and bare forms) from the input
;;;; stream and returns a resume directive. Both streams are injectable so
;;;; the UI is fully testable over string streams.

(defclass dumb-ui ()
  ((input  :initarg :input  :initform *standard-input*  :accessor dumb-ui-input)
   (output :initarg :output :initform *standard-output* :accessor dumb-ui-output)
   (prompt :initarg :prompt :initform "DBG> " :accessor dumb-ui-prompt)
   (source-window :initarg :source-window :initform 2 :accessor dumb-ui-source-window)
   ;; `display' forms (strings), auto-printed after every stop (cmd-ref §4)
   (displays :initarg :displays :initform '() :accessor dumb-ui-displays)))

(defun make-dumb-ui (&rest initargs)
  (apply #'make-instance 'dumb-ui initargs))

(register-ui :terminal (lambda (&rest initargs) (apply #'make-dumb-ui initargs)))
(register-ui :dumb     (lambda (&rest initargs) (apply #'make-dumb-ui initargs)))

(defun out (ui control &rest args)
  (apply #'format (dumb-ui-output ui) control args)
  (force-output (dumb-ui-output ui)))

(defun string-lines (text)
  "TEXT split into a list of lines (a single trailing newline is dropped)."
  (let ((lines (uiop:split-string text :separator '(#\Newline))))
    (if (and (cdr lines) (string= "" (car (last lines))))
        (butlast lines)
        lines)))

(defun paged-out (ui text)
  "Emit TEXT to the UI, a page at a time when the pager is on and TEXT is taller
than a page (command reference §8 *Paging long output*). The page prompt reads
one line of input (the modal pager sub-mode): SPACE / f / =>= / RET next page,
b / =<= back, g / =<<= first, G / =>>= last, q quit. With the pager off, or on a
non-interactive stream (EOF), TEXT is written straight through (never blocks)."
  (let* ((pager-on (eq (get-aldo-setting :pager) :on))
         (page (max 1 (1- (or (get-aldo-setting :pager-height) 24))))
         (lines (coerce (string-lines text) 'vector))
         (n (length lines)))
    (if (or (not pager-on) (<= n page))
        (write-string text (dumb-ui-output ui))
        (loop with s = 0
              do (loop for k from s below (min n (+ s page))
                       do (out ui "~A~%" (svref lines k)))
                 (let ((end (min n (+ s page))))
                   (when (>= end n) (return))
                   (out ui "--More--(~D/~D) [SPACE/f/> b/< g G q] " end n)
                   (let ((line (read-line (dumb-ui-input ui) nil :eof)))
                     (if (eq line :eof)
                         (progn (loop for k from end below n
                                      do (out ui "~A~%" (svref lines k)))
                                (return))
                         (let ((cmd (string-trim " " line)))
                           (cond
                             ((string-equal cmd "q") (return))
                             ((member cmd '("b" "<") :test #'string-equal)
                              (setf s (max 0 (- s page))))
                             ((member cmd '("g" "<<") :test #'string-equal) (setf s 0))
                             ((member cmd '("G" ">>") :test #'string-equal)
                              (setf s (max 0 (- n page))))
                             (t (setf s end)))))))))))   ; SPACE/f/>/RET/… → next

;;; --- notifications -------------------------------------------------

(defmethod ui-attached ((ui dumb-ui) session)
  (declare (ignore session))
  (out ui "~&DBG> clautolisp debugger attached (h for help)~%"))

(defmethod ui-detached ((ui dumb-ui))
  (out ui "~&DBG> detached~%"))

(defmethod ui-show-message ((ui dumb-ui) level control &rest args)
  (out ui "~&DBG> [~A] ~A~%" level (apply #'format nil control args)))

(defun describe-stop (ui session kind hit)
  (let ((snapshot (session-snapshot session)))
    (out ui "~&DBG> ~A at ~A~@[ — ~A~]~%"
         kind
         (location-string (hit-source-position hit)
                          (and snapshot (snapshot-function-name snapshot)))
         (and (eq kind "Error") (hit-error-message hit)))
    (when snapshot (print-bindings ui snapshot) (print-stack-line ui snapshot))
    (print-displays ui session)))

(defun print-displays (ui session)
  "Auto-print every `display' form in the current frame (command reference §4)."
  (loop for form in (dumb-ui-displays ui)
        for i from 1
        do (handler-case
               (out ui "DBG> display ~D: ~A = ~A~%" i form (preview (cmd-eval session form) 80))
             (error (e) (out ui "DBG> display ~D: ~A = <error: ~A>~%" i form e)))))

(defmethod ui-thread-hit ((ui dumb-ui) session hit)
  (describe-stop ui session
                 (if (eq (hit-stop-reason hit) :step) "Step" "Hit breakpoint") hit))

(defmethod ui-thread-unhandled-error ((ui dumb-ui) session hit)
  (describe-stop ui session "Error" hit)
  (out ui "DBG>   (a abort, r <form> return a value, c run *error*)~%"))

(defmethod ui-thread-caught-error ((ui dumb-ui) session hit)
  (describe-stop ui session "Caught error" hit))

(defun location-string (position function-name)
  (cond
    ((source-position-p position)
     (format nil "~@[~A ~]line ~D col ~D"
             function-name
             (source-position-start-line position)
             (source-position-start-column position)))
    (function-name (format nil "~A" function-name))
    (t "<unknown>")))

(defun print-bindings (ui snapshot)
  (loop for (symbol . value) in (snapshot-visible-names snapshot)
        do (out ui "DBG>   ~A = ~A~%"
                (autolisp-symbol-name symbol) (preview value))))

(defun print-stack-line (ui snapshot)
  (let ((names (mapcar #'stack-frame-function-name (snapshot-call-stack snapshot))))
    (when names
      (out ui "DBG>   <stack: ~{~A~^ ← ~} ← top>~%" names))))

(defun preview (value &optional (limit 60))
  (let ((string (handler-case (prin1-to-string value) (error () "#<?>"))))
    (if (> (length string) limit)
        (concatenate 'string (subseq string 0 limit) "…")
        string)))

;;; --- source listing (spec §18.1) -----------------------------------

(defmethod ui-show-source ((ui dumb-ui) position)
  (when (source-position-p position)
    (let* ((file (source-position-file position))
           (lines (and file (ignore-errors (lines-of file))))
           (target (source-position-start-line position))
           (window (dumb-ui-source-window ui)))
      (when (and lines (plusp (length lines)))
        (loop for n from (max 1 (- target window)) to (min (length lines) (+ target window))
              for text = (aref lines (1- n))
              do (out ui "~A~3D:   ~A~%" (if (= n target) ">> " "   ") n text))))))

;;; --- the command loop (spec §18.1) ---------------------------------

(defmethod ui-await-command ((ui dumb-ui) session hit)
  (loop
    (out ui "~&~A" (dumb-ui-prompt ui))
    (let ((line (read-line (dumb-ui-input ui) nil :eof)))
      (when (eq line :eof) (return :continue))     ; EOF ⇒ continue (CI/pipe)
      (let ((directive (dispatch-command ui session hit (string-trim " 	" line))))
        (when directive (return directive))))))     ; non-nil ⇒ resume

(defun dispatch-command (ui session hit line)
  "Interpret one command LINE; return a resume directive or NIL to keep
reading. A line that looks like (form) is eval-in-frame."
  (cond
    ((string= line "") nil)
    ((and (plusp (length line)) (char= (char line 0) #\())
     (eval-and-print ui session line) nil)
    (t
     (let* ((space (position #\Space line))
            (cmd (subseq line 0 (or space (length line))))
            (arg (and space (string-trim " " (subseq line space)))))
       (run-command ui session hit cmd arg)))))

(defun run-command (ui session hit cmd arg)
  "Dispatch one command, using the command reference §0 vocabulary (single keys
+ word forms). Returns a resume directive, or NIL to keep reading."
  (let ((c (string-downcase cmd)))
    (cond
      ;; execution control (§1)
      ((member c '("c" "continue") :test #'string=) (cmd-continue session))
      ((member c '("i" "into") :test #'string=) (cmd-step session :into))
      ((member c '("n" "next") :test #'string=) (cmd-step session :over))
      ((member c '("o" "out") :test #'string=) (cmd-step session :out))
      ((member c '("r" "return") :test #'string=) (return-value-cmd ui session hit arg))
      ((member c '("q" "quit") :test #'string=) (cmd-abort session))
      ;; breakpoints (§2)
      ((member c '("b" "break") :test #'string=) (set-breakpoint-cmd ui session arg) nil)
      ((string= c "lb") (list-breakpoints-cmd ui session) nil)
      ;; stack and frames (§3)
      ((string= c "lf") (print-stack ui session) nil)
      ((member c '("f" "frame") :test #'string=) (frame-cmd ui session arg) nil)
      ((string= c "fi") (frame-cmd ui session "inner") nil)
      ((string= c "fo") (frame-cmd ui session "outer") nil)
      ((string= c "ft") (frame-cmd ui session "top") nil)
      ((string= c "fb") (frame-cmd ui session "bottom") nil)
      ((string= c "ll") (list-vars-cmd ui session "locals") nil)
      ((string= c "lp") (list-vars-cmd ui session "parameters") nil)
      ((string= c "lv") (list-vars-cmd ui session "variables") nil)
      ;; data (§4)
      ((member c '("p" "print") :test #'string=) (print-variable-cmd ui session arg) nil)
      ((member c '("t" "type" ",type") :test #'string=) (type-cmd ui session arg) nil)
      ((member c '("v" "visit") :test #'string=) (inspector-loop ui session arg) nil)
      ;; source (§5)
      ((string= c "ls") (relist-source ui session) nil)
      ;; spelled two-word "list X"
      ((string= c "list") (list-sub-cmd ui session arg) nil)
      ;; meta (§8)
      ((string= c "set") (set-setting-cmd ui arg) nil)
      ((member c '(",settings" "settings") :test #'string=) (settings-cmd ui arg) nil)
      ((member c '(",display" "display") :test #'string=) (display-cmd ui arg) nil)
      ((member c '(",undisplay" "undisplay") :test #'string=) (undisplay-cmd ui arg) nil)
      ((member c '("h" "?" "help") :test #'string=) (print-help ui) nil)
      (t (out ui "DBG> ? unknown command ~S (h for help)~%" cmd) nil))))

(defun frame-cmd (ui session arg)
  "`frame N' / `frame inner|outer|top|bottom' — select a call frame (§3).
top = innermost = frame 0; inner heads toward top, outer toward the toplevel."
  (let* ((snapshot (session-snapshot session))
         (frames (and snapshot (snapshot-call-stack snapshot)))
         (n (length frames))
         (cur (or (session-selected-frame session) 0)))
    (if (zerop n)
        (out ui "DBG> no frames~%")
        (let ((target (cond
                        ((null arg) cur)
                        ((string-equal arg "inner") (1- cur))
                        ((string-equal arg "outer") (1+ cur))
                        ((string-equal arg "top") 0)
                        ((string-equal arg "bottom") (1- n))
                        (t (or (ignore-errors (parse-integer arg :junk-allowed t)) cur)))))
          (setf target (max 0 (min (1- n) target)))
          (cmd-select-frame session target)
          (out ui "DBG> frame ~D: ~A~%" target
               (stack-frame-function-name (nth target frames)))))))

(defun list-vars-cmd (ui session what)
  "`list locals|parameters|variables' (=ll=/=lp=/=lv=) — show the visible
bindings at the stop (§3). The locals/parameters/variables distinction is a
refinement; all three currently show the visible bindings."
  (let ((snapshot (session-snapshot session)))
    (out ui "DBG> ~A:~%" what)
    (if snapshot (print-bindings ui snapshot) (out ui "DBG>   (no snapshot)~%"))))

(defun list-sub-cmd (ui session arg)
  "Dispatch the spelled `list X' form to the matching =l*= command."
  (cond
    ((null arg) (out ui "DBG> list what? (breakpoints|frames|source|locals|parameters|variables)~%"))
    ((string-equal arg "breakpoints") (list-breakpoints-cmd ui session))
    ((string-equal arg "frames") (print-stack ui session))
    ((string-equal arg "source") (relist-source ui session))
    ((string-equal arg "locals") (list-vars-cmd ui session "locals"))
    ((string-equal arg "parameters") (list-vars-cmd ui session "parameters"))
    ((string-equal arg "variables") (list-vars-cmd ui session "variables"))
    (t (out ui "DBG> list ~A? (breakpoints|frames|source|locals|parameters|variables)~%" arg))))

(defun type-cmd (ui session arg)
  "`type EXPR' — show the AutoLISP type of EXPR's value (command reference §4)."
  (if (null arg)
      (out ui "DBG> type: usage: type EXPR~%")
      (handler-case
          (let* ((value (cmd-eval session arg))
                 (ty (clautolisp.autolisp-runtime:autolisp-type value)))
            (out ui "DBG> ~A : ~A~%" (preview value 60) (preview ty 40)))
        (error (e) (out ui "DBG> type error: ~A~%" e)))))

(defun display-cmd (ui arg)
  "`display FORM' — auto-print FORM after every stop (command reference §4)."
  (if (null arg)
      (out ui "DBG> display: usage: display FORM~%")
      (progn
        (setf (dumb-ui-displays ui) (append (dumb-ui-displays ui) (list arg)))
        (out ui "DBG> display ~D: ~A~%" (length (dumb-ui-displays ui)) arg))))

(defun undisplay-cmd (ui arg)
  "`undisplay [N]' — remove auto-display N, or all of them (command reference §4)."
  (let ((n (and arg (ignore-errors (parse-integer arg :junk-allowed t)))))
    (cond
      ((and n (<= 1 n (length (dumb-ui-displays ui))))
       (setf (dumb-ui-displays ui)
             (append (subseq (dumb-ui-displays ui) 0 (1- n))
                     (subseq (dumb-ui-displays ui) n)))
       (out ui "DBG> undisplay ~D~%" n))
      ((null arg)
       (setf (dumb-ui-displays ui) '())
       (out ui "DBG> undisplay (all)~%"))
      (t (out ui "DBG> undisplay: no display ~A~%" arg)))))

(defun set-setting-cmd (ui arg)
  "`set NAME VALUE' — update one aldo setting (command reference §8)."
  (if (null arg)
      (out ui "DBG> set: usage: set NAME VALUE~%")
      (let* ((sp (position #\Space arg))
             (name (subseq arg 0 (or sp (length arg))))
             (value (and sp (string-trim " " (subseq arg sp)))))
        (handler-case
            (let ((v (set-aldo-setting name (or value ""))))
              ;; write through to the canonical *CLAL-ALDO-CONFIGURATION*
              (ignore-errors (sync-config-to-variable))
              (out ui "DBG> ~(~A~) = ~A~%" name (format-setting-value v)))
          (error (e) (out ui "DBG> set error: ~A~%" e))))))

(defun settings-cmd (ui arg)
  "`,settings' — list all options; `,settings NAME' print one; `,settings save'
/ `,settings reload' persist (command reference §8)."
  (cond
    ((null arg)
     ;; reflect any AutoLISP-side change to the canonical variable first
     (ignore-errors (sync-config-from-variable))
     (paged-out ui (format nil "~{  ~A~%~}" (aldo-settings-lines))))
    ((string-equal arg "save")
     (handler-case
         (progn (ignore-errors (sync-config-to-variable))
                (out ui "DBG> saved ~A~%" (save-aldo-configuration)))
       (error (e) (out ui "DBG> save error: ~A~%" e))))
    ((string-equal arg "reload")
     (handler-case
         (let ((p (load-aldo-configuration)))
           (ignore-errors (sync-config-to-variable))
           (if p (out ui "DBG> reloaded ~A~%" p)
               (out ui "DBG> no configuration file found~%")))
       (error (e) (out ui "DBG> reload error: ~A~%" e))))
    (t (ignore-errors (sync-config-from-variable))
       (out ui "  ~(~A~) = ~A~%" arg (format-setting-value (get-aldo-setting arg))))))

(defun eval-and-print (ui session form-string)
  (handler-case
      (out ui "DBG> ~A~%" (preview (cmd-eval session form-string) 200))
    (error (e) (out ui "DBG> eval error: ~A~%" e))))

(defun print-variable-cmd (ui session arg)
  (if (and arg (plusp (length arg)))
      (eval-and-print ui session arg)
      (let ((snapshot (session-snapshot session)))
        (when snapshot (print-bindings ui snapshot)))))

(defun relist-source (ui session)
  (let ((snapshot (session-snapshot session)))
    (when snapshot (ui-show-source ui (snapshot-source-position snapshot)))))

(defun print-stack (ui session)
  (let ((snapshot (session-snapshot session)))
    (when snapshot
      (loop for frame in (snapshot-call-stack snapshot)
            for i from 0
            do (out ui "DBG>   ~D: ~A  ~A~%" i
                    (stack-frame-function-name frame)
                    (location-string (stack-frame-source-position frame)
                                     (stack-frame-function-name frame)))))))

(defun list-breakpoints-cmd (ui session)
  (let ((bps (cmd-list-breakpoints session)))
    (if bps
        (dolist (bp bps)
          (out ui "DBG>   #~D fid ~D form ~D ~A~%"
               (breakpoint-id bp) (breakpoint-fid bp)
               (breakpoint-form-id bp) (breakpoint-when bp)))
        (out ui "DBG>   no breakpoints~%"))))

(defun set-breakpoint-cmd (ui session arg)
  "B <line> — set a breakpoint at a line of the current function (§17.3)."
  (let ((line (and arg (ignore-errors (parse-integer arg :junk-allowed t)))))
    (cond
      ((null line) (out ui "DBG> B needs a line number~%"))
      (t (let ((bp (cmd-set-breakpoint-at-line session line)))
           (if bp
               (out ui "DBG> breakpoint #~D set at line ~D~%" (breakpoint-id bp) line)
               (out ui "DBG> no poll point at line ~D~%" line)))))))

(defun return-value-cmd (ui session hit arg)
  "r <form> — continue-with-return (spec §10.1), only at an error stop."
  (declare (ignore hit))
  (handler-case
      (let ((value (cmd-eval session (or arg "nil"))))
        (cmd-return session value))
    (error (e) (out ui "DBG> return error: ~A~%" e) nil)))

(defun print-help (ui)
  (paged-out ui
   (format nil "DBG> commands: (command reference §0 vocabulary)~%~
            DBG>   c continue   i into   n next   o out   r [FORM] return   q quit~%~
            DBG>   b LINE break   lb list breakpoints~%~
            DBG>   lf list frames   f N frame   fi/fo inner/outer   ft/fb top/bottom~%~
            DBG>   ll/lp/lv list locals/parameters/variables~%~
            DBG>   p EXPR print   t EXPR type   v EXPR visit   ls list source~%~
            DBG>   set NAME VALUE   ,settings [NAME|save|reload]~%~
            DBG>   display FORM   undisplay [N]~%~
            DBG>   (form...) evaluate in the current frame   h/? help~%")))

;;; --- inspector sub-REPL (spec §18.2) -------------------------------

(defun inspector-loop (ui session arg)
  "Open the inspector on ARG (a form evaluated in-frame) or the first
visible binding, then run a small navigation REPL (spec §18.2)."
  (let ((value (handler-case (cmd-eval session (or arg "nil"))
                 (error (e) (out ui "INSPECT> eval error: ~A~%" e) (return-from inspector-loop)))))
    (cmd-inspect session value :origin (and arg (first (read-runtime-from-string arg))))
    (loop
      (render-inspector-page ui session)
      (out ui "~&INSPECT> ")
      (let ((line (read-line (dumb-ui-input ui) nil :eof)))
        (when (eq line :eof) (return))
        (let ((line (string-trim " 	" line)))
          (cond
            ((or (string= line "q") (string= line "")) (return))
            ((string= line "u") (cmd-inspector-up session))
            ((string= line "p") (print-path ui session))
            ((and (> (length line) 1) (char= (char line 0) #\d))
             (descend ui session (string-trim " " (subseq line 1))))
            ((and (> (length line) 1) (char= (char line 0) #\e))
             (inspector-eval ui session (string-trim " " (subseq line 1))))
            ((and (> (length line) 1) (char= (char line 0) #\b))
             (inspector-bind ui session (string-trim " " (subseq line 1))))
            (t (out ui "INSPECT> [d N] descend [u] up [e form] eval [p] copy path [b $|NAME] bind [q] quit~%"))))))))

(defun render-inspector-page (ui session)
  (let ((page (session-page (session-inspector session))))
    (out ui "~&INSPECT> origin: ~A  path: ~A~%"
         (preview (clautolisp.inspect:session-origin (session-inspector session)))
         (preview (session-path-expression-safe session)))
    (out ui "INSPECT> #<~A> ~A~%" (inspect-page-type-name page) (inspect-page-header page))
    (loop for component in (inspect-page-components page)
          for i from 0
          do (out ui "INSPECT>   ~D. ~A~14T~A~50T[~A]~%"
                  i (inspect-component-label component)
                  (inspect-component-preview component)
                  (preview (inspect-component-accessor component) 40)))))

(defun session-path-expression-safe (session)
  (multiple-value-bind (expr kind) (cmd-inspector-path-expression session)
    (if (eq kind :partial) (format nil "~A …(opaque)" (preview expr)) expr)))

(defun descend (ui session arg)
  (let ((index (ignore-errors (parse-integer arg :junk-allowed t))))
    (if index
        (handler-case (cmd-inspector-descend session index)
          (error (e) (out ui "INSPECT> ~A~%" e)))
        (out ui "INSPECT> d needs a component number~%"))))

(defun inspector-eval (ui session form-string)
  (handler-case
      (out ui "INSPECT> ~A~%"
           (preview (session-eval (session-inspector session)
                                  (first (read-runtime-from-string form-string)))
                    200))
    (error (e) (out ui "INSPECT> eval error: ~A~%" e))))

(defun inspector-bind (ui session arg)
  "b $        bind to next workspace slot
   b ! NAME  setq NAME (frame-aware, §16.1)
   b $NAME   bind to a named workspace slot"
  (cond
    ((or (null arg) (string= arg "") (string= arg "$"))
     (out ui "INSPECT> bound to ~A~%" (cmd-inspector-bind session :workspace)))
    ((and (> (length arg) 1) (char= (char arg 0) #\!))
     (let ((name (intern-rt (string-trim " " (subseq arg 1)))))
       (cmd-inspector-bind session (list :setq name))
       (out ui "INSPECT> setq ~A~%" (autolisp-symbol-name name))))
    ((char= (char arg 0) #\$)
     (out ui "INSPECT> bound to ~A~%" (cmd-inspector-bind session (list :workspace arg))))
    (t (out ui "INSPECT> use: b $ | b $NAME | b ! NAME~%"))))

(defun intern-rt (name)
  (clautolisp.autolisp-runtime:intern-autolisp-symbol (string-upcase name)))

(defun print-path (ui session)
  (out ui "INSPECT> path: ~A~%" (session-path-expression-safe session)))
