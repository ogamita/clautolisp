(in-package #:clautolisp.autolisp-builtins-core.tests)

(in-suite autolisp-builtins-core-suite)

;;;; The sysvar table follows the dialect
;;;; (sysvar-table-ignores-runtime-dialect-change.issue).
;;;;
;;;; Everything else dialect-dependent already followed
;;;; `(setq *AUTOLISP-DIALECT* …)' at once, because
;;;; CURRENT-EVALUATION-DIALECT consults the variable on every call. The
;;;; sysvar table did not: it belongs to the HOST and was populated once,
;;;; at launch, from the LAUNCH dialect. So which clautolisp sysvars
;;;; exist, which AutoCAD ones BricsCAD hides, and the seeding from the
;;;; environment were all frozen to however the process started.
;;;;
;;;; These tests drive the dialect the way a user does — by assigning the
;;;; runtime variable — and then ask GETVAR, which is the whole point:
;;;; nothing "notices" the assignment, the table is rebuilt lazily at the
;;;; next sysvar access.

(defun %sdt-context ()
  "A fresh session on a clautolisp-dialect MockHost, with the dialect
controller installed exactly as the CLI installs it at launch: the base
snapshot FIRST, then the overlays for the launch dialect.

The environment is faked rather than read, so the test asserts the
seeding rule and not the machine it runs on."
  ;; Order matters: the context reset clears the symbol table, so the
  ;; builtins go in AFTER it or GETVAR / SETVAR are undefined.
  (clautolisp.autolisp-runtime:reset-default-evaluation-context)
  (install-core-builtins)
  (let* ((context (clautolisp.autolisp-runtime:default-evaluation-context))
         (session (clautolisp.autolisp-runtime:evaluation-context-session context))
         (mock (clautolisp.cador:make-cador))
         (getenv (lambda (name)
                   (when (string= name "CLAUTOLISPCASEINSENSITIVEPATHS") "1"))))
    (setf (clautolisp.autolisp-runtime.internal::runtime-session-host session) mock)
    (flet ((overlays (host dialect-keyword)
             (clautolisp.autolisp-builtins-core:apply-dialect-trust-sysvar-defaults
              host dialect-keyword :getenv getenv)
             (when (eq dialect-keyword :bricscad-v26)
               (clautolisp.cador:apply-bricscad-dialect-sysvars host))))
      ;; The snapshot must precede the overlays: it is the
      ;; dialect-INDEPENDENT base they are applied on top of, and the one
      ;; a later switch rebuilds from.
      (clautolisp.autolisp-builtins-core:install-sysvar-dialect-controller
       mock :strict #'overlays)
      (overlays mock :strict))
    context))

(defun %sdt-eval (context text)
  (clautolisp.autolisp-runtime:autolisp-eval-progn
   (clautolisp.autolisp-runtime:read-runtime-from-string text)
   context))

(defun %sdt-getvar (context name)
  "GETVAR NAME through the ordinary builtin path, unwrapped to a plain
CL value (nil / integer / string)."
  (let ((raw (%sdt-eval context (format nil "(getvar ~S)" name))))
    (cond ((null raw) nil)
          ((typep raw 'clautolisp.autolisp-runtime:autolisp-string)
           (clautolisp.autolisp-runtime:autolisp-string-value raw))
          (t raw))))

(test sysvar-table-follows-a-runtime-dialect-change
  "pjb's report, 1.8.59: CLAUTOLISPCASEINSENSITIVEPATHS=1 in the
environment, launched STRICT. Under strict the sysvar does not exist, so
GETVAR answers nil — correct. Switching the dialect at runtime must
REVEAL it, and the first reveal applies the full precedence
(setvar > env > default), so the environment's 1 is what shows: a reveal
that ignored the environment would leave the reported trace wrong."
  (let ((context (%sdt-context)))
    (is (null (%sdt-getvar context "CLAUTOLISPCASEINSENSITIVEPATHS")))
    (%sdt-eval context "(setq *AUTOLISP-DIALECT* 'bricscad-v26)")
    (is (eql 1 (%sdt-getvar context "CLAUTOLISPCASEINSENSITIVEPATHS")))))

(test sysvar-masking-keeps-the-value-set-under-another-dialect
  "pjb's ruling — masking WITH MEMORY. Passing through a dialect that
hides a sysvar must not DESTROY the setting, only make it invisible
while we are there. So a value set under bricscad survives a trip
through strict, and coming back gives back THAT value (0), not the
environment's (1): the precedence is setvar > env > default, and a
remembered setvar is still a setvar."
  (let ((context (%sdt-context)))
    (%sdt-eval context "(setq *AUTOLISP-DIALECT* 'bricscad-v26)")
    (%sdt-eval context "(setvar \"CLAUTOLISPCASEINSENSITIVEPATHS\" 0)")
    (is (eql 0 (%sdt-getvar context "CLAUTOLISPCASEINSENSITIVEPATHS")))
    (%sdt-eval context "(setq *AUTOLISP-DIALECT* 'strict)")
    (is (null (%sdt-getvar context "CLAUTOLISPCASEINSENSITIVEPATHS")))
    (%sdt-eval context "(setq *AUTOLISP-DIALECT* 'bricscad-v26)")
    (is (eql 0 (%sdt-getvar context "CLAUTOLISPCASEINSENSITIVEPATHS")))))

(test sysvar-masking-is-symmetric-for-bricscad-absent-sysvars
  "The defect was symmetric and the fix is too: switching TO bricscad
must also HIDE the sysvars BricsCAD does not define, and switching away
must bring them back. One mechanism, not a special case for one sysvar —
the table is rebuilt from the dialect-independent base every time, so
both directions fall out of the same replay."
  (let* ((context (%sdt-context))
         (name (first clautolisp.cador::*bricscad-absent-sysvars*)))
    (is (not (null name)))
    (let ((under-strict (%sdt-getvar context name)))
      (is (not (null under-strict)))
      (%sdt-eval context "(setq *AUTOLISP-DIALECT* 'bricscad-v26)")
      (is (null (%sdt-getvar context name)))
      (%sdt-eval context "(setq *AUTOLISP-DIALECT* 'autocad-2026)")
      (is (equal under-strict (%sdt-getvar context name))))))

(test sysvar-dialect-rebuild-does-not-disturb-an-unrelated-sysvar
  "The rebuild restores a whole table, so it has to be checked that it
does not lose ordinary user state along the way: a value set on a sysvar
that EVERY dialect defines must survive any number of switches. Without
the user-value memory this is exactly what a rebuild would throw away."
  (let ((context (%sdt-context)))
    (%sdt-eval context "(setvar \"USERI1\" 42)")
    (%sdt-eval context "(setq *AUTOLISP-DIALECT* 'bricscad-v26)")
    (is (eql 42 (%sdt-getvar context "USERI1")))
    (%sdt-eval context "(setq *AUTOLISP-DIALECT* 'strict)")
    (is (eql 42 (%sdt-getvar context "USERI1")))))
