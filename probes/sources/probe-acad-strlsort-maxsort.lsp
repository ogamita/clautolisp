;;;; Observe ACAD_STRLSORT independently of the GUI MAXSORT limit.
(defun cad-probe-run-acad-strlsort-maxsort-probes (/ saved large n limit)
  (setq saved (getvar "MAXSORT"))
  (cad-probe-capture "acad-strlsort-maxsort" "initial-maxsort"
    (function (lambda () (getvar "MAXSORT"))))
  (setq large nil
        n     1001)
  (repeat 1001
    (setq large (cons (itoa n) large)
          n     (1- n)))
  (foreach limit '(0 1 2 200 1000)
    (cad-probe-capture "acad-strlsort-maxsort" (itoa limit)
      (function (lambda ()
        (setvar "MAXSORT" limit)
        (list (getvar "MAXSORT")
              (acad_strlsort '("c" "a" "b"))
              (length (acad_strlsort large)))))))
  (setvar "MAXSORT" saved)
  (princ))
