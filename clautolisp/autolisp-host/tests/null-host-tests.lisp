(in-package #:clautolisp.autolisp-host.tests)

(in-suite autolisp-host-suite)

;;; Class hierarchy and singleton sanity ----------------------------

(test null-host-is-a-host
  (is (typep *null-host* 'host))
  (is (typep *null-host* 'null-host))
  (is (hostp *null-host*))
  (is (string= "null-host" (host-name *null-host*))))

(test make-null-host-builds-instances
  (let ((custom (make-null-host :name "scratch")))
    (is (typep custom 'null-host))
    (is (string= "scratch" (host-name custom)))
    (is (not (eq custom *null-host*)))))

;;; Default runtime backend installation -----------------------------

(test default-runtime-host-is-null-host
  ;; The autolisp-host module installs the NullHost singleton as the
  ;; runtime's process-wide default at load time.
  (is (eq *null-host* *default-runtime-host*)))

(test fresh-runtime-session-inherits-default-host
  (let ((session (make-runtime-session)))
    (is (eq *null-host* (runtime-session-host session)))))

(test runtime-session-host-keyword-overrides-default
  (let* ((custom (make-null-host :name "custom"))
         (session (make-runtime-session :host custom)))
    (is (eq custom (runtime-session-host session)))
    (is (string= "custom" (host-name (runtime-session-host session))))))

(test set-runtime-session-host-replaces-the-backend
  (let* ((session (make-runtime-session))
         (replacement (make-null-host :name "replacement")))
    (is (eq *null-host* (runtime-session-host session)))
    (set-runtime-session-host session replacement)
    (is (eq replacement (runtime-session-host session)))))

(test current-evaluation-host-resolves-via-context
  ;; The CLI / REPL path threads the host through the active
  ;; evaluation context.
  (reset-default-evaluation-context)
  (is (eq *null-host* (current-evaluation-host (default-evaluation-context)))))

;;; Every NullHost method signals :host-not-supported -----------------

(defun expect-not-supported (thunk)
  (handler-case
      (progn (funcall thunk) :no-error)
    (autolisp-runtime-error (condition)
      (autolisp-runtime-error-code condition))))

(test null-host-entget-signals-host-not-supported
  (is (eq :host-not-supported
          (expect-not-supported (lambda () (host-entget *null-host* :ename))))))

(test null-host-entlast-signals-host-not-supported
  (is (eq :host-not-supported
          (expect-not-supported (lambda () (host-entlast *null-host*))))))

(test null-host-getvar-signals-host-not-supported
  (is (eq :host-not-supported
          (expect-not-supported (lambda () (host-getvar *null-host* "CLAYER"))))))

(test null-host-setvar-signals-host-not-supported
  (is (eq :host-not-supported
          (expect-not-supported (lambda () (host-setvar *null-host* "CLAYER" "0"))))))

(test null-host-command-signals-host-not-supported
  (is (eq :host-not-supported
          (expect-not-supported (lambda () (host-command *null-host* '("LINE")))))))

(test null-host-prompt-signals-host-not-supported
  (is (eq :host-not-supported
          (expect-not-supported (lambda () (host-prompt *null-host* "go ahead"))))))

(test null-host-getstring-signals-host-not-supported
  (is (eq :host-not-supported
          (expect-not-supported (lambda () (host-getstring *null-host* "?"))))))

(test null-host-grdraw-signals-host-not-supported
  (is (eq :host-not-supported
          (expect-not-supported
           (lambda ()
             (host-grdraw *null-host* '(0 0) '(1 1) 7 nil))))))

(test null-host-ssget-signals-host-not-supported
  (is (eq :host-not-supported
          (expect-not-supported (lambda () (host-ssget *null-host* nil :mode "X"))))))

(test null-host-tblsearch-signals-host-not-supported
  (is (eq :host-not-supported
          (expect-not-supported (lambda () (host-tblsearch *null-host* :layer "0"))))))

(test null-host-tblnext-signals-host-not-supported
  (is (eq :host-not-supported
          (expect-not-supported
           (lambda () (host-tblnext *null-host* :layer :rewind t))))))

(test null-host-dictsearch-signals-host-not-supported
  (is (eq :host-not-supported
          (expect-not-supported
           (lambda ()
             (host-dictsearch *null-host* :root "ACAD_GROUP"))))))

(test null-host-dictadd-signals-host-not-supported
  (is (eq :host-not-supported
          (expect-not-supported
           (lambda () (host-dictadd *null-host* :root "FOO" :ent))))))

(test null-host-error-message-mentions-the-backend-name
  (handler-case
      (host-entget *null-host* :nope)
    (autolisp-runtime-error (condition)
      (let ((message (autolisp-runtime-error-message condition)))
        (is (search "null-host" message))
        (is (search "ENTGET" message))))))
