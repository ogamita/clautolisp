(defun cad-probe-foreach--empty-list ( / e)
  ;; An empty list runs no iteration. Under binding semantics e is still
  ;; BEFORE; under assignment it is also BEFORE, so this case separates
  ;; "assigns per iteration" from "assigns once up front".
  (setq e 'before)
  (foreach e nil nil)
  e)

