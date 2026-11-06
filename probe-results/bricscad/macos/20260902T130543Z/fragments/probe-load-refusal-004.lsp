(defun cad-probe-run-load-refusal-probes ()
  ;; Reaching here at all is the headline result: it means every form
  ;; above LOADED. The per-form markers say which ones did when it is
  ;; not reached.
  (cad-probe-capture "load-refusal"
                     "the whole file loaded"
                     (function cad-probe-lr--no-body))
  (cad-probe-capture "load-refusal"
                     "(list (foreach e '(1 2 3) (* e 10)))"
                     (function cad-probe-lr--expression-position))
  (cad-probe-capture "load-refusal"
                     "(foreach e nil 99)"
                     (function cad-probe-lr--empty-list)))
