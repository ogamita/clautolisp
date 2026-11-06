(in-package #:clautolisp.autolisp-host.tests)

(in-suite autolisp-host-suite)

;;; Class hierarchy and singleton sanity ----------------------------

(test nihil-is-a-host
  (is (typep *nihil* 'host))
  (is (typep *nihil* 'nihil))
  (is (hostp *nihil*))
  (is (string= "nihil" (host-name *nihil*))))

(test make-nihil-builds-instances
  (let ((custom (make-nihil :name "scratch")))
    (is (typep custom 'nihil))
    (is (string= "scratch" (host-name custom)))
    (is (not (eq custom *nihil*)))))

;;; Default runtime backend installation -----------------------------

(test default-runtime-host-is-nihil
  ;; The autolisp-host module installs the NullHost singleton as the
  ;; runtime's process-wide default at load time.
  (is (eq *nihil* *default-runtime-host*)))

(test fresh-runtime-session-inherits-default-host
  (let ((session (make-runtime-session)))
    (is (eq *nihil* (runtime-session-host session)))))

(test runtime-session-host-keyword-overrides-default
  (let* ((custom (make-nihil :name "custom"))
         (session (make-runtime-session :host custom)))
    (is (eq custom (runtime-session-host session)))
    (is (string= "custom" (host-name (runtime-session-host session))))))

(test set-runtime-session-host-replaces-the-backend
  (let* ((session (make-runtime-session))
         (replacement (make-nihil :name "replacement")))
    (is (eq *nihil* (runtime-session-host session)))
    (set-runtime-session-host session replacement)
    (is (eq replacement (runtime-session-host session)))))

(test current-evaluation-host-resolves-via-context
  ;; The CLI / REPL path threads the host through the active
  ;; evaluation context.
  (reset-default-evaluation-context)
  (is (eq *nihil* (current-evaluation-host (default-evaluation-context)))))

;;; Every NullHost method signals :host-not-supported -----------------

(defun expect-not-supported (thunk)
  (handler-case
      (progn (funcall thunk) :no-error)
    (autolisp-runtime-error (condition)
      (autolisp-runtime-error-code condition))))

(test nihil-entget-signals-host-not-supported
  (is (eq :host-not-supported
          (expect-not-supported (lambda () (host-entget *nihil* :ename))))))

(test nihil-entlast-signals-host-not-supported
  (is (eq :host-not-supported
          (expect-not-supported (lambda () (host-entlast *nihil*))))))

(test nihil-getvar-signals-host-not-supported
  (is (eq :host-not-supported
          (expect-not-supported (lambda () (host-getvar *nihil* "CLAYER"))))))

(test nihil-setvar-signals-host-not-supported
  (is (eq :host-not-supported
          (expect-not-supported (lambda () (host-setvar *nihil* "CLAYER" "0"))))))

(test nihil-command-signals-host-not-supported
  (is (eq :host-not-supported
          (expect-not-supported (lambda () (host-command *nihil* '("LINE")))))))

(test nihil-command-log-signals-host-not-supported
  (is (eq :host-not-supported
          (expect-not-supported (lambda () (host-command-log *nihil*))))))

(test nihil-prompt-signals-host-not-supported
  (is (eq :host-not-supported
          (expect-not-supported (lambda () (host-prompt *nihil* "go ahead"))))))

(test nihil-getstring-signals-host-not-supported
  (is (eq :host-not-supported
          (expect-not-supported (lambda () (host-getstring *nihil* "?"))))))

(test nihil-grdraw-signals-host-not-supported
  (is (eq :host-not-supported
          (expect-not-supported
           (lambda ()
             (host-grdraw *nihil* '(0 0) '(1 1) 7 nil))))))

(test nihil-ssget-signals-host-not-supported
  (is (eq :host-not-supported
          (expect-not-supported (lambda () (host-ssget *nihil* nil :mode "X"))))))

(test nihil-tblsearch-signals-host-not-supported
  (is (eq :host-not-supported
          (expect-not-supported (lambda () (host-tblsearch *nihil* :layer "0"))))))

(test nihil-tblnext-signals-host-not-supported
  (is (eq :host-not-supported
          (expect-not-supported
           (lambda () (host-tblnext *nihil* :layer :rewind t))))))

(test nihil-dictsearch-signals-host-not-supported
  (is (eq :host-not-supported
          (expect-not-supported
           (lambda ()
             (host-dictsearch *nihil* :root "ACAD_GROUP"))))))

(test nihil-dictadd-signals-host-not-supported
  (is (eq :host-not-supported
          (expect-not-supported
           (lambda () (host-dictadd *nihil* :root "FOO" :ent))))))

(test nihil-error-message-mentions-the-backend-name
  (handler-case
      (host-entget *nihil* :nope)
    (autolisp-runtime-error (condition)
      (let ((message (autolisp-runtime-error-message condition)))
        (is (search "nihil" message))
        (is (search "ENTGET" message))))))
