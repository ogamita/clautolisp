(defun cad-probe-run-foreach-scope-probes ()
  (cad-probe--foreach
   "loop variable is a /-local of the same function"
   "(defun f ( / e) (setq e 'before) (foreach e '(1 2 3) nil) e)"
   (function cad-probe-foreach--own-local))
  (cad-probe--foreach
   "loop variable is a /-local of the CALLER"
   "caller binds e; callee runs (foreach e ...); caller reads e"
   (function cad-probe-foreach--callers-local))
  (cad-probe--foreach
   "loop variable is a global"
   "(setq g 'outer) then (foreach g '(1 2) nil) in a function; read g"
   (function cad-probe-foreach--global))
  (cad-probe--foreach
   "loop variable bound nowhere before the loop"
   "(foreach fresh '(1 2) nil) in a function; read fresh afterwards"
   (function cad-probe-foreach--unbound))
  (cad-probe--foreach
   "empty list -- no iteration runs"
   "(setq e 'before) (foreach e nil nil) e"
   (function cad-probe-foreach--empty-list))
  (cad-probe--foreach
   "return value: last body value (statement position, read at run time)"
   "(foreach e '(1 2 3) (* e 10))"
   (function cad-probe-foreach--return-statement))
  (cad-probe--foreach
   "return value: foreach in EXPRESSION position (read at run time)"
   "(list (foreach e '(1 2 3) (* e 10)))"
   (function cad-probe-foreach--return-expression))
  (cad-probe--foreach
   "return value: foreach over an EMPTY LIST (read at run time)"
   "(foreach e nil 99)"
   (function cad-probe-foreach--return-empty-list))
  (cad-probe--foreach
   "return value: a foreach with NO BODY (read at run time)"
   "(foreach e '(1 2 3))"
   (function cad-probe-foreach--empty-body)))
