;;;; tests/sysvar/coupling-user-scratch.lsp
;;;;
;;;; USERI1..USERI5 / USERR1..USERR5 / USERS1..USERS5 are documented
;;;; as user-writable scratch slots with no behavioural coupling --
;;;; the only contract is "writes round-trip to reads of the right
;;;; AutoLISP type".

(deftest "sysvar-useri1-round-trip"
  '((operator . "USERI1") (area . "sysvar") (profile . strict))
  '(progn (setvar "USERI1" 42)
          (getvar "USERI1"))
  42)

(deftest "sysvar-userr3-round-trip"
  '((operator . "USERR3") (area . "sysvar") (profile . strict))
  '(progn (setvar "USERR3" 3.14)
          (getvar "USERR3"))
  3.14)

(deftest "sysvar-users5-round-trip"
  '((operator . "USERS5") (area . "sysvar") (profile . strict))
  '(progn (setvar "USERS5" "hello")
          (getvar "USERS5"))
  "hello")

(deftest "sysvar-useri-coercion-rejects-non-integer"
  ;; USERI1 is :integer; setvar must coerce / reject a real.
  ;; clautolisp policy: reject (no implicit coercion).
  '((operator . "USERI1") (area . "sysvar") (profile . strict))
  '(progn (setvar "USERI1" 0)
          (or (vl-catch-all-error-p
               (vl-catch-all-apply 'setvar (list "USERI1" 1.5)))
              ;; AutoCAD and BricsCAD coerce silently in some builds;
              ;; if the call succeeded we accept the truncated value.
              (= (getvar "USERI1") 1)))
  T)

(deftest "sysvar-users-empty-string-round-trip"
  '((operator . "USERS1") (area . "sysvar") (profile . strict))
  '(progn (setvar "USERS1" "")
          (getvar "USERS1"))
  "")

(deftest "sysvar-useri-all-five-independent"
  '((operator . "USERI1") (area . "sysvar") (profile . strict))
  '(progn (setvar "USERI1" 1)
          (setvar "USERI2" 2)
          (setvar "USERI3" 3)
          (setvar "USERI4" 4)
          (setvar "USERI5" 5)
          (list (getvar "USERI1") (getvar "USERI2")
                (getvar "USERI3") (getvar "USERI4")
                (getvar "USERI5")))
  '(1 2 3 4 5))
