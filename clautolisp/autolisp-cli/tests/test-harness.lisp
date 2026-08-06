(in-package #:clautolisp.autolisp-cli.tests)

(def-suite autolisp-cli-suite)
(in-suite autolisp-cli-suite)

(defun setup-mock-evaluation-context ()
  "Install a fresh evaluation context backed by a default MockHost and
return it. Mirrors the builtins-core fixture of the same name — the
launch-time transmit helpers (APPLY-CLAUTOLISP-HOST-IDENTITY,
APPLY-TEMPPREFIX-DEFAULT, …) need a runtime context whose host is a
mock so they have real sysvar cells to stamp."
  (clautolisp.autolisp-runtime:reset-default-evaluation-context)
  (let* ((session (clautolisp.autolisp-runtime:evaluation-context-session
                   (clautolisp.autolisp-runtime:current-evaluation-context)))
         (mock    (clautolisp.cador:make-cador)))
    (setf (clautolisp.autolisp-runtime.internal::runtime-session-host session)
          mock)
    (clautolisp.autolisp-runtime:current-evaluation-context)))

(defun mock-getvar (context name)
  "Read sysvar NAME back from CONTEXT's mock host, unwrapping the
autolisp-string wrapper the host puts on :string sysvars so callers get
a plain CL string to compare against."
  (let ((value (clautolisp.autolisp-host:host-getvar
                (clautolisp.autolisp-runtime:current-evaluation-host context)
                name)))
    (if (typep value 'clautolisp.autolisp-runtime:autolisp-string)
        (clautolisp.autolisp-runtime:autolisp-string-value value)
        value)))
