;;;; probes/sources/probe-rtos.lsp
;;;;
;;;; Ground-truth for real-to-string / angle-to-string formatting. The
;;;; clautolisp rtos/angtos work (1.2.13/1.2.14) reproduced AutoCAD
;;;; formatting from the documentation; these probes capture what the
;;;; live CADs actually emit so the spec and the implementation can be
;;;; verified against fact rather than prose.
;;;;
;;;; Each case forces an explicit mode + precision so the result does
;;;; not depend on the host's current LUNITS / LUPREC. A companion run
;;;; of probe-sysvars records those defaults separately.

(defun cad-probe--rtos (n mode prec)
  (cad-probe-capture "rtos"
    (strcat "(rtos " (vl-prin1-to-string n) " " (itoa mode) " " (itoa prec) ")")
    (function (lambda () (rtos n mode prec)))))

(defun cad-probe--angtos (a mode prec)
  (cad-probe-capture "angtos"
    (strcat "(angtos " (vl-prin1-to-string a) " " (itoa mode) " " (itoa prec) ")")
    (function (lambda () (angtos a mode prec)))))

(defun cad-probe-run-rtos-probes ( / nums modes precs)
  ;; Representative magnitudes: a clean fraction, a rounding case, a
  ;; large value (scientific threshold), a negative, a value that rounds
  ;; to a bare integer (precision-0 trailing-dot question), and zero.
  (setq nums  (list 3.14159 2.5 0.5 -0.5 100.0 123456.789 0.0 1.0))
  ;; Modes: 1 scientific, 2 decimal, 3 engineering, 4 architectural,
  ;; 5 fractional. clautolisp implements 1/2 today; 3-5 are probed to
  ;; capture the target output for the deferred work.
  (setq modes (list 1 2 3 4 5))
  (setq precs (list 0 2 4 6))
  (foreach m modes
    (foreach p precs
      (foreach n nums
        (cad-probe--rtos n m p))))
  ;; angtos: modes 0 degrees, 1 deg/min/sec, 2 grads, 3 radians,
  ;; 4 surveyor. Angles in radians.
  (foreach m (list 0 1 2 3 4)
    (foreach p precs
      (foreach a (list 0.0 0.7853981634 1.5707963268 3.1415926536)
        (cad-probe--angtos a m p))))
  (princ))
