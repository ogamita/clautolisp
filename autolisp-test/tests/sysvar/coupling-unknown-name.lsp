;;;; tests/sysvar/coupling-unknown-name.lsp
;;;;
;;;; §16 normative rule: (getvar NAME) returns nil when NAME is not
;;;; a defined sysvar; (setvar NAME ...) signals.

(deftest "sysvar-getvar-on-unknown-name-is-nil"
  '((operator . "GETVAR") (area . "sysvar") (profile . strict))
  '(getvar "DEFINITELY-NOT-A-SYSVAR-NAME-123XYZ")
  nil)

(deftest-error "sysvar-setvar-on-unknown-name-signals"
  '((operator . "SETVAR") (area . "sysvar") (profile . strict))
  '(setvar "DEFINITELY-NOT-A-SYSVAR-NAME-123XYZ" 0)
  'unknown-sysvar)

(deftest "sysvar-name-case-insensitive-getvar"
  '((operator . "GETVAR") (area . "sysvar") (profile . strict))
  '(progn (setvar "CMDECHO" 1)
          (equal (getvar "cmdecho") (getvar "CMDECHO")))
  T)

(deftest "sysvar-name-case-insensitive-mixed-case"
  '((operator . "GETVAR") (area . "sysvar") (profile . strict))
  '(progn (setvar "CMDECHO" 0)
          (equal (getvar "CmdEcho") (getvar "CMDECHO")))
  T)
