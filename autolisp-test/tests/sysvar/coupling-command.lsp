;;;; tests/sysvar/coupling-command.lsp
;;;;
;;;; CMDECHO steers the (command ...) echo policy. The prompt echo it
;;;; controls is not observable through a value-returning conformance
;;;; assertion (it is captured in the builtins-core FiveAM test
;;;; COUPLING-CMDECHO-GATES-COMMAND-ECHO); here we assert the sysvar
;;;; round-trips and that (command ...) runs and returns nil under both
;;;; echo settings, i.e. CMDECHO=0 silences the echo without disabling
;;;; the command.

(deftest "sysvar-cmdecho-round-trips"
  '((operator . "CMDECHO") (area . "sysvar") (profile . strict))
  '(progn (setvar "CMDECHO" 0)
          (let ((result (getvar "CMDECHO")))
            (setvar "CMDECHO" 1)          ;; restore
            result))
  0)

(deftest "sysvar-command-runs-with-echo-off"
  '((operator . "CMDECHO") (area . "sysvar") (profile . strict))
  '(progn (setvar "CMDECHO" 0)
          (let ((result (command "_LINE")))
            (setvar "CMDECHO" 1)          ;; restore
            result))
  nil)

(deftest "sysvar-command-runs-with-echo-on"
  '((operator . "CMDECHO") (area . "sysvar") (profile . strict))
  '(progn (setvar "CMDECHO" 1)
          (command "_LINE"))
  nil)
