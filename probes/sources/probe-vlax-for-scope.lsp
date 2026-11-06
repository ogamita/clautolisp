;;;; probes/sources/probe-vlax-for-scope.lsp
;;;;
;;;; Ground-truth for what VLAX-FOR does to its loop variable.
;;;;
;;;; THE QUESTION is FOREACH's (probe-foreach-scope.lsp), asked of the
;;;; other loop: does `(vlax-for x collection ...)' BIND x for the duration
;;;; of the loop -- whatever x held before comes back afterwards -- or does
;;;; it ASSIGN to an existing binding and leave the last member behind?
;;;;
;;;; clautolisp answers BIND, since 2.0.26, BY ANALOGY: AutoCAD answered
;;;; BIND for FOREACH (2.0.22), and VLAX-FOR had carried the same
;;;; assign-if-bound code until then. The specification does not say --
;;;; its VLAX-FOR entry has no `bind' and no `rebinding' in it -- so the
;;;; analogy is all there is (issues/open/vlax-for-binding-rule-unprobed).
;;;; These probes are the measurement.
;;;;
;;;; THE COLLECTION is the active document's Layers: every drawing has at
;;;; least layer "0", so the loop always runs. Each case returns
;;;;
;;;;     (<the loop variable afterwards> <iterations run>)
;;;;
;;;; so that BEFORE cannot be mistaken for "the loop never ran". A layer
;;;; left in the variable is shown by its name ("layer:0"), which is the
;;;; assignment answer. A host without an ActiveX object model records
;;;; `error' for each case -- that is an answer about the host, not about
;;;; the rule. (Headless clautolisp HAS one: its drawing model answers
;;;; with layer "0", so its baseline column reads (BEFORE 1), (BEFORE 1),
;;;; (OUTER 1), (nil 1) -- BIND, as 2.0.26 made it.)

(defun cad-probe--vlax-for (case expression thunk)
  (cad-probe-capture "vlax-for-scope" case thunk))

(defun cad-probe-vlax-for--layers ()
  (vl-load-com)
  (vla-get-layers (vla-get-activedocument (vlax-get-acad-object))))

(defun cad-probe-vlax-for--show (v)
  (if (= (type v) 'VLA-OBJECT)
    (strcat "layer:" (vla-get-name v))
    v))

(defun cad-probe-vlax-for--own-local ( / x n)
  ;; binding => (BEFORE n) ; assignment => ("layer:<last>" n)
  (setq x 'before n 0)
  (vlax-for x (cad-probe-vlax-for--layers) (setq n (1+ n)))
  (list (cad-probe-vlax-for--show x) n))

(defun cad-probe-vlax-for--callee ()
  (setq cad-probe-vlax-for-n 0)
  (vlax-for x (cad-probe-vlax-for--layers)
    (setq cad-probe-vlax-for-n (1+ cad-probe-vlax-for-n))))

(defun cad-probe-vlax-for--callers-local ( / x)
  ;; x is a /-local of the CALLER, reachable only by dynamic scope.
  ;; binding => (BEFORE n) ; assignment => ("layer:<last>" n)
  (setq x 'before)
  (cad-probe-vlax-for--callee)
  (list (cad-probe-vlax-for--show x) cad-probe-vlax-for-n))

(defun cad-probe-vlax-for--global ( / n)
  ;; The name is a GLOBAL. binding => (OUTER n) ; assignment => ("layer:.." n)
  (setq cad-probe-vlax-for-g 'outer n 0)
  (vlax-for cad-probe-vlax-for-g (cad-probe-vlax-for--layers) (setq n (1+ n)))
  (list (cad-probe-vlax-for--show cad-probe-vlax-for-g) n))

(defun cad-probe-vlax-for--unbound ( / n)
  ;; Bound NOWHERE before the loop. Both rules say it does not survive; a
  ;; layer left in it would mean VLAX-FOR leaks a global.
  (setq n 0)
  (vlax-for cad-probe-vlax-for-fresh (cad-probe-vlax-for--layers) (setq n (1+ n)))
  (list (cad-probe-vlax-for--show cad-probe-vlax-for-fresh) n))

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
