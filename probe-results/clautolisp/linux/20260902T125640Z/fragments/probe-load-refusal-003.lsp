(defun cad-probe-lr--empty-list ()
  ;; FOREACH over a literal NIL. THE KNOWN CULPRIT, so it goes LAST:
  ;; anything after it in this file will not be reached.
  (foreach e nil 99))

