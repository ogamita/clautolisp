(in-package #:clautolisp.autolisp-host.tests)

(in-suite autolisp-host-suite)

;;; The host condition taxonomy (D1 §15; pjb, 2026-09-28): one superclass,
;;; HOST-ERROR, four subclasses, each keeping its CODE so that handlers
;;; testing (autolisp-runtime-error-code c) keep working.

(defun %signalled-by (thunk)
  "The condition THUNK signals, or NIL when it returns normally."
  (handler-case (progn (funcall thunk) nil)
    (error (condition) condition)))

(test host-error-is-an-autolisp-runtime-error
  (is (subtypep 'clautolisp.autolisp-runtime:host-error 'autolisp-runtime-error))
  (dolist (class '(clautolisp.autolisp-runtime:operation-not-supported-by-this-host
                   clautolisp.autolisp-runtime:unavailable-in-headless-context
                   clautolisp.autolisp-runtime:operation-not-yet-implemented
                   clautolisp.autolisp-runtime:backend-error))
    (is (subtypep class 'clautolisp.autolisp-runtime:host-error) "~S" class)))

(test each-raiser-signals-its-class-with-its-code
  (loop for (thunk class code)
          in (list (list (lambda () (clautolisp.autolisp-host:signal-host-not-supported *nihil* 'entget))
                         'clautolisp.autolisp-runtime:operation-not-supported-by-this-host
                         :host-not-supported)
                   (list (lambda () (clautolisp.autolisp-host:signal-unavailable-in-headless *nihil* 'grread))
                         'clautolisp.autolisp-runtime:unavailable-in-headless-context
                         :host-unavailable-headless)
                   (list (lambda () (clautolisp.autolisp-host:signal-not-yet-implemented *nihil* 'ssget-window))
                         'clautolisp.autolisp-runtime:operation-not-yet-implemented
                         :host-not-yet-implemented)
                   (list (lambda () (clautolisp.autolisp-host:signal-backend-error *nihil* 'dwgin "bad header"))
                         'clautolisp.autolisp-runtime:backend-error
                         :host-backend-error))
        do (let ((condition (%signalled-by thunk)))
             (is (typep condition class) "~S" class)
             (is (typep condition 'clautolisp.autolisp-runtime:host-error))
             (is (eq code (autolisp-runtime-error-code condition)))
             (is (search "nihil" (autolisp-runtime-error-message condition))))))

(test the-code-alone-chooses-the-class
  ;; Every existing raiser that passes a host code by hand -- over a hundred of
  ;; them -- gets the class without being touched.
  (let ((condition (%signalled-by
                    (lambda ()
                      (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
                       :host-not-supported "by hand")))))
    (is (typep condition 'clautolisp.autolisp-runtime:operation-not-supported-by-this-host)))
  (let ((condition (%signalled-by
                    (lambda ()
                      (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
                       :sysvar-read-only "not a host boundary")))))
    (is (typep condition 'autolisp-runtime-error))
    (is (not (typep condition 'clautolisp.autolisp-runtime:host-error)))))

(test nihil-refusals-are-operation-not-supported
  (let ((condition (%signalled-by (lambda () (host-entget *nihil* :ename)))))
    (is (typep condition 'clautolisp.autolisp-runtime:operation-not-supported-by-this-host))
    (is (eq :host-not-supported (autolisp-runtime-error-code condition)))))

(test a-handler-on-host-error-catches-every-subclass
  (dolist (thunk (list (lambda () (clautolisp.autolisp-host:signal-host-not-supported *nihil* 'a))
                       (lambda () (clautolisp.autolisp-host:signal-unavailable-in-headless *nihil* 'b))
                       (lambda () (clautolisp.autolisp-host:signal-not-yet-implemented *nihil* 'c))
                       (lambda () (clautolisp.autolisp-host:signal-backend-error *nihil* 'd "e"))))
    (is (eq :caught
            (handler-case (funcall thunk)
              (clautolisp.autolisp-runtime:host-error () :caught))))))

;;; --- C6: the core never reaches into a host ----------------------------------
;;; (cador-4 slice 3, D2 section II.15.) The reader, runtime, host interface and
;;; builtins name no host package: everything CAD goes through the host
;;; generics. Prose may mention cador; a package-qualified reference may not.

(test c6-core-sources-name-no-host-package
  (let ((offenders '()))
    (dolist (dir '("autolisp-reader/source/" "autolisp-runtime/source/"
                   "autolisp-host/source/" "autolisp-builtins-core/source/"))
      (dolist (file (directory (merge-pathnames
                                "*.lisp" (asdf:system-relative-pathname "clautolisp" dir))))
        (with-open-file (in file :external-format :utf-8)
          (loop for line = (read-line in nil)
                for n from 1
                while line
                when (let ((lower (string-downcase line)))
                       (some (lambda (pkg) (search pkg lower))
                             '("clautolisp.cador:" "clautolisp.drawing:" "clautolisp.cadtui:")))
                  do (push (format nil "~A:~D" (file-namestring file) n) offenders)))))
    (is (null offenders) "core sources reference a host package: ~{~A~^, ~}" offenders)))
