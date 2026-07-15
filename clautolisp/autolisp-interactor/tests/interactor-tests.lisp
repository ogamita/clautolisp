;;;; Interactors: the readers, invocation resolution on the stack, argument
;;;; marshaling, and the INTERACTOR-LOOP itself.

(in-package #:clautolisp.interactor.tests)

(in-suite interactor-suite)

;;; --- readers ---------------------------------------------------------------

(defun read-all (reader script)
  "Apply READER to SCRIPT's lines until :EOF; return the list of inputs."
  (with-input-from-string (stream script)
    (let ((*package* (find-package '#:clautolisp.interactor.tests))
          (context (make-input-context :stream stream)))
      (loop :for input := (funcall reader context)
            :until (eq input :eof)
            :collect input))))

(test command-read-takes-lines-as-commands-except-forms
  (destructuring-bind (cmd motion form blank)
      (read-all #'command-read (format nil "break 42~%>>~%(print x)~%~%"))
    (is (input-command-p cmd))
    (is (equal "break 42" (input-command-raw cmd)))
    (is (equal '(("break") ((integer . "42")))
               (list (input-command-invocation cmd)
                     (input-command-arguments cmd))))
    (is (input-command-p motion))
    (is (equal '(">>") (input-command-invocation motion)))
    (is (equal '(print x) form))                ; a `(' line reads as a sexp
    (is (eq :blank blank))))

(test comma-command-read-takes-sexps-except-comma-lines
  (destructuring-bind (sexp cmd)
      (read-all #'comma-command-read (format nil "(setq x 1)~%,date~%"))
    (is (equal '(setq x 1) sexp))
    (is (input-command-p cmd))
    (is (equal '("date") (input-command-invocation cmd)))))

(test multi-line-forms-read-across-lines
  ;; the sexp reader consumes the unread line plus the following ones
  (destructuring-bind (form) (read-all #'command-read (format nil "(+ 1~%   2)~%"))
    (is (equal '(+ 1 2) form))))

(test invocation-of-a-multi-ident-line-is-its-leading-idents
  (destructuring-bind (cmd) (read-all #'command-read (format nil "list breakpoints 3~%"))
    (is (equal '("list" "breakpoints") (input-command-invocation cmd)))
    (is (equal '((integer . "3")) (input-command-arguments cmd)))))

(test raw-arguments-preserve-the-argument-text
  (destructuring-bind (cmd) (read-all #'command-read
                                      (format nil "condition 3 (equal s \"a  b\")~%"))
    (is (equal "3 (equal s \"a  b\")" (input-command-raw-arguments cmd 1)))
    (is (equal "\"a  b\")" (input-command-raw-arguments cmd 4)))
    (is (null (input-command-raw-arguments cmd 6)))))

;;; --- resolution on the interactor stack -------------------------------------

(defun test-stack ()
  "Two stacked interactors: NAVI over ALDO, with a user command shadowing an
ALDO system command."
  (let ((aldo (make-interactor :name "ALDO" :alias "debug"))
        (navi (make-interactor :name "NAVI")))
    (bind-command (interactor-commands aldo) '(b break) '(&whole arg) "Break." (constantly :aldo-break))
    (bind-command (interactor-commands aldo) '(c continue) '() "Continue." (constantly :aldo-continue))
    (bind-command (interactor-commands aldo) '(lb list breakpoints) '() "List." (constantly :aldo-lb))
    (bind-command (interactor-user-commands aldo) '(c cont-mine) '() "User c." (constantly :user-continue))
    (bind-command (interactor-commands navi) '(b breakpoint) '() "NAV break." (constantly :navi-break))
    (list navi aldo)))

(defun resolve (line stack)
  (find-interactor-command
   (make-input-command :raw line :tokens (parse-command line))
   stack))

(test inner-interactors-and-user-dictionaries-shadow
  (let ((stack (test-stack)))
    ;; NAVI's b shadows ALDO's
    (is (eq :navi-break (funcall (command-function (resolve "b" stack)))))
    ;; ALDO's user c shadows its system c
    (is (eq :user-continue (funcall (command-function (resolve "c" stack)))))))

(test explicit-interactor-routing-reaches-a-shadowed-command
  (let ((stack (test-stack)))
    (multiple-value-bind (cmd args skip interactor) (resolve "aldo b 42" stack)
      (is (eq :aldo-break (funcall (command-function cmd))))
      (is (equal '((integer . "42")) args))
      (is (= 2 skip))
      (is (equal "ALDO" (interactor-name interactor))))))

(test longest-phrase-wins-and-the-rest-are-arguments
  (let ((stack (test-stack)))
    (multiple-value-bind (cmd args) (resolve "list breakpoints" stack)
      (is (eq :aldo-lb (funcall (command-function cmd))))
      (is (null args)))
    ;; trailing idents that don't extend a phrase are arguments
    (multiple-value-bind (cmd args skip) (resolve "b foo" stack)
      (is (eq :navi-break (funcall (command-function cmd))))
      (is (equal '((ident . "foo")) args))
      (is (= 1 skip)))))

(test the-alias-routes-like-the-name
  ;; `aldo' and `debug' are name and alias of the one debugger interactor
  (let ((stack (test-stack)))
    (multiple-value-bind (cmd args skip interactor) (resolve "debug b 42" stack)
      (is (eq :aldo-break (funcall (command-function cmd))))
      (is (equal '((integer . "42")) args))
      (is (= 2 skip))
      (is (equal "ALDO" (interactor-name interactor))))))

(test the-command-word-skips-the-user-dictionaries
  ;; like bash's `command foo': reach a system command a user command shadows
  (let ((stack (test-stack)))
    ;; normally the user c shadows the system c …
    (is (eq :user-continue (funcall (command-function (resolve "c" stack)))))
    (is (eq :user-continue (funcall (command-function (resolve "aldo c" stack)))))
    ;; … `command c' / `NAME command c' reach the system one
    (is (eq :aldo-continue (funcall (command-function (resolve "command c" stack)))))
    (is (eq :aldo-continue (funcall (command-function (resolve "aldo command c" stack)))))
    (is (eq :aldo-continue (funcall (command-function (resolve "debug command c" stack)))))
    ;; the consumed-words count keeps raw arguments aligned
    (multiple-value-bind (cmd args skip) (resolve "aldo command b 42" stack)
      (is (eq :aldo-break (funcall (command-function cmd))))
      (is (equal '((integer . "42")) args))
      (is (= 3 skip)))
    ;; the word alone resolves nothing (it is reserved)
    (is (null (resolve "command" stack)))))

(test unresolved-commands-return-nil
  (is (null (resolve "nosuch" (test-stack)))))

;;; --- calling commands --------------------------------------------------------

(test call-command-marshals-token-texts
  (let ((d (make-command-dictionary "test")))
    (let ((cmd (bind-command d '(z zar) '(count name) "Zar." #'list)))
      (is (equal '("3" "foo")
                 (call-command cmd '((integer . "3") (ident . "foo"))))))))

(test call-command-passes-the-raw-string-to-whole-commands
  (let ((d (make-command-dictionary "test")))
    (let ((cmd (bind-command d '(e echo) '(&whole arg) "Echo." #'identity)))
      (is (equal "3 (> x 2)" (call-command cmd '() :raw "3 (> x 2)")))
      (is (null (call-command cmd '() :raw nil))))))

(test call-command-prompts-for-missing-required-arguments
  (let ((d (make-command-dictionary "test"))
        (output (make-string-output-stream)))
    (let ((cmd (bind-command d '(z zar) '(count name) "Zar." #'list)))
      (with-input-from-string (input (format nil "foo~%"))
        (let ((context (make-input-context :stream input)))
          (is (equal '("3" "foo")
                     (call-command cmd '((integer . "3"))
                                   :output output :input-context context)))))
      (is (search "name? " (get-output-stream-string output))))))

(test call-command-drops-extra-arguments-unless-rest
  (let ((d (make-command-dictionary "test")))
    (let ((one  (bind-command d '(o one) '(x) "One." #'list))
          (many (bind-command d '(m many) '(x &rest xs) "Many."
                              (lambda (x &rest xs) (cons x xs)))))
      (is (equal '("a")
                 (handler-bind ((warning #'muffle-warning))
                   (call-command one '((ident . "a") (ident . "b"))))))
      (is (equal '("a" "b" "c")
                 (call-command many '((ident . "a") (ident . "b") (ident . "c"))))))))

(test call-command-reports-execution-errors
  (let ((d (make-command-dictionary "test"))
        (errors (make-string-output-stream)))
    (let ((cmd (bind-command d '(f fail) '() "Fail."
                             (lambda () (error "boom")))))
      (call-command cmd '() :error-output errors)
      (is (search "boom" (get-output-stream-string errors))))))

;;; --- the loop -----------------------------------------------------------------

(defun make-echo-interactor (&key (name "ECHO") prompt)
  "An interactor whose evaluator prints = SEXP and with a few commands."
  (let ((interactor (make-interactor
                     :name name
                     :prompt prompt
                     :reader #'command-read
                     :evaluator (lambda (sexp)
                                  (format t "= ~S~%" sexp)))))
    (bind-command (interactor-commands interactor) '(p ping) '() "Ping."
                  (lambda () (format t "pong~%")))
    (bind-command (interactor-commands interactor) '(q quit) '() "Quit."
                  (lambda () (pop-interactor)))
    (bind-command (interactor-commands interactor) '(r result) '(value) "Return."
                  (lambda (value) (interactor-return value)))
    interactor))

(test loop-prompts-runs-commands-and-evaluates-forms
  (multiple-value-bind (output value)
      (run-loop-on-script (format nil "ping~%(+ 1 2)~%")
                          :interactors (list (make-echo-interactor)))
    (is (null value))                            ; EOF
    (is (search (format nil "ECHO> pong~%") output))
    (is (search "= (+ 1 2)" output))))

(test loop-returns-when-the-entry-interactor-pops
  (multiple-value-bind (output value)
      (run-loop-on-script (format nil "q~%ping~%")
                          :interactors (list (make-echo-interactor)))
    (is (null value))
    ;; nothing ran after q popped the last interactor
    (is (not (search "pong" output)))))

(test loop-returns-interactor-return-values
  (multiple-value-bind (output value)
      (run-loop-on-script (format nil "r 42~%ping~%")
                          :interactors (list (make-echo-interactor)))
    (is (equal "42" value))
    (is (not (search "pong" output)))))

(test pushed-interactors-take-over-and-shadow
  ;; entering a mode: a command pushes an inner interactor; its q returns to
  ;; the outer one; `outer ping' routes to the outer from inside.
  (let* ((outer (make-echo-interactor :name "OUTER"))
         (inner (make-echo-interactor :name "INNER")))
    (bind-command (interactor-commands outer) '(m mode) '() "Enter INNER."
                  (lambda () (push-interactor inner)))
    (multiple-value-bind (output)
        (run-loop-on-script
         (format nil "m~%outer ping~%q~%ping~%")
         :interactors (list outer))
      ;; prompts: OUTER (m), INNER (outer ping), INNER (q), OUTER (ping), OUTER (EOF)
      (is (search "INNER> " output))
      (is (= 3 (count-substring "OUTER> " output)))
      (is (= 2 (count-substring "pong" output))))))

(defun count-substring (needle haystack)
  (loop :with start := 0
        :for hit := (search needle haystack :start2 start)
        :while hit
        :count 1
        :do (setf start (1+ hit))))

(test unknown-commands-and-reader-errors-keep-the-loop-alive
  (multiple-value-bind (output value errors)
      (run-loop-on-script (format nil "nosuch~%\"a string\" cannot start a command~%ping~%")
                          :interactors (list (make-echo-interactor)))
    (declare (ignore value))
    (is (search "? unknown command \"nosuch\"" output))
    (is (search "Cannot read a sexp or command" errors))
    (is (search "pong" output))))

(test on-result-carries-directives-out-of-the-loop
  ;; an ALDO-style interactor: a command's non-nil value is a resume
  ;; directive; ON-RESULT carries it out of the loop with INTERACTOR-RETURN
  (let ((aldo (make-echo-interactor :name "ALDO")))
    (setf (interactor-on-result aldo)
          (lambda (result) (when result (interactor-return result))))
    (bind-command (interactor-commands aldo) '(c continue) '() "Continue."
                  (constantly :continue))
    (multiple-value-bind (output value)
        (run-loop-on-script (format nil "ping~%c~%ping~%")
                            :interactors (list aldo))
      (is (eq :continue value))
      (is (= 1 (count-substring "pong" output))))))   ; nothing ran after c

(test on-result-belongs-to-the-owning-interactor
  ;; a debugger command typed at an inner mode (routed or fallen through)
  ;; still carries its directive out: the OWNER's on-result applies
  (let ((aldo (make-echo-interactor :name "ALDO"))
        (navi (make-echo-interactor :name "NAVI")))
    (setf (interactor-on-result aldo)
          (lambda (result) (when result (interactor-return result))))
    (bind-command (interactor-commands aldo) '(c continue) '() "Continue."
                  (constantly :continue))
    (multiple-value-bind (output value)
        (run-loop-on-script (format nil "aldo c~%") :interactors (list aldo navi))
      (declare (ignore output))
      (is (eq :continue value)))))

(test command-bodies-reach-their-mode-state
  ;; *COMMAND-INTERACTOR* is the command's owner: its body reads the mode's
  ;; mutable state from the interactor instance
  (let ((navi (make-interactor :name "NAVI" :state (list 0))))
    (bind-command (interactor-commands navi) '(m more) '() "Count."
                  (lambda ()
                    (incf (first (interactor-state *command-interactor*)))
                    (format t "count=~D~%" (first (interactor-state *command-interactor*)))))
    (multiple-value-bind (output)
        (run-loop-on-script (format nil "m~%m~%") :interactors (list navi))
      (is (search "count=1" output))
      (is (search "count=2" output)))))

(test the-floor-lets-inner-interactors-pop-within-the-loop
  ;; stack (INNER over OUTER) with floor 1: q pops INNER and the SAME loop
  ;; continues at OUTER (the auto-opened navigator dropping to the debugger)
  (let ((outer (make-echo-interactor :name "OUTER"))
        (inner (make-echo-interactor :name "INNER")))
    (multiple-value-bind (output)
        (run-loop-on-script (format nil "q~%ping~%")
                            :interactors (list outer inner) :floor 1)
      (is (search "INNER> " output))
      (is (search (format nil "OUTER> pong") output)))))

(test comma-commands-at-a-repl-interactor
  (let ((repl (make-interactor
               :name "LISP"
               :prompt "_$ "
               :reader #'comma-command-read
               :evaluator (lambda (sexp) (format t "= ~S~%" sexp)))))
    (bind-command (interactor-commands repl) '(h help) '() "Help."
                  (lambda () (format t "Help~%")))
    (multiple-value-bind (output)
        (run-loop-on-script (format nil "(setq x 1)~%,help~%help~%")
                            :interactors (list repl))
      (is (search "= (SETQ X 1)" output))
      (is (search (format nil "Help~%") output))
      ;; without the comma, `help' is a sexp (a variable), not a command
      (is (search "= HELP" output)))))

(test the-status-renders-before-each-prompt
  (let ((interactor (make-echo-interactor :name "NAVI")))
    (setf (interactor-status interactor)
          (lambda (stream) (format stream "~&[view]~%")))
    (multiple-value-bind (output)
        (run-loop-on-script (format nil "ping~%") :interactors (list interactor))
      (is (= 2 (count-substring "[view]" output))))))    ; before each of 2 prompts

(test make-prompt-function-shows-the-stack-depth
  (let ((*interactor-stack* (list (make-interactor :name "A"))))
    (let ((prompt (with-output-to-string (s)
                    (funcall (make-prompt-function "LISP") s))))
      (is (search "[1]LISP> " prompt)))))
