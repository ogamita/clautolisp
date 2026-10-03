(defun cad-probe-run-vlax-for-scope-probes ()
  (cad-probe--vlax-for
   "loop variable is a /-local of the same function"
   "(defun f ( / x) (setq x 'before) (vlax-for x layers ...) x)"
   (function cad-probe-vlax-for--own-local))
  (cad-probe--vlax-for
   "loop variable is a /-local of the CALLER"
   "caller binds x; callee runs (vlax-for x layers ...); caller reads x"
   (function cad-probe-vlax-for--callers-local))
  (cad-probe--vlax-for
   "loop variable is a global"
   "(setq g 'outer) then (vlax-for g layers ...); read g"
   (function cad-probe-vlax-for--global))
  (cad-probe--vlax-for
   "loop variable bound nowhere before the loop"
   "(vlax-for fresh layers ...); read fresh afterwards"
   (function cad-probe-vlax-for--unbound)))
