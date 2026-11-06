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

(defun cad-probe--rtos-dimzin (d n mode prec)
  ;; The same rtos call under an explicit DIMZIN; the case label carries it.
  (cad-probe-capture "rtos-dimzin"
    (strcat "DIMZIN=" (itoa d) " (rtos " (vl-prin1-to-string n) " "
            (itoa mode) " " (itoa prec) ")")
    (function (lambda () (setvar "DIMZIN" d) (rtos n mode prec)))))

(defun cad-probe-run-rtos-dimzin-probes ( / old)
  ;; system-variables.issue: the first run of this suite had DIMZIN 8 on both
  ;; vendors, i.e. only feet/inch code 0 plus trailing-zero suppression. This
  ;; measures the rest before clautolisp relies on Autodesk's prose for it:
  ;;   - codes 0-3 (DIMZIN 0 1 2 3): zero feet / precisely zero inches;
  ;;   - the decimal bits 4 (leading zero) and 8 (trailing zeros), and 12;
  ;;   - exact feet (12, 24), the engineering carry (11.999 at 2 places),
  ;;     a negative that rounds to zero (-0.1 at 0 places), and 0.
  (setq old (getvar "DIMZIN"))
  (foreach d (list 0 1 2 3 4 8 12)
    (foreach m (list 3 4)
      (foreach p (list 0 2)
        (foreach n (list 0.0 0.5 6.0 12.0 24.0 17.5 11.999 -0.1)
          (cad-probe--rtos-dimzin d n m p)))))
  (setvar "DIMZIN" old)
  (princ))

(defun cad-probe--distof (text mode)
  (cad-probe-capture "distof"
    (strcat "(distof " (vl-prin1-to-string text) " " (itoa mode) ")")
    (function (lambda () (distof text mode)))))

(defun cad-probe-run-distof-probes ()
  ;; system-variables.issue: clautolisp's distof reads RTOS's own output back
  ;; (modes 3/4 alike, 5 fractional). These ask the vendors which INPUT forms
  ;; they accept -- including under mode 2, where clautolisp stays decimal.
  (foreach m (list 2 3 4 5)
    (foreach s (list "1'-6\"" "1'6\"" "1'-5 1/2\"" "1'-5-1/2\"" "1'-5.50\""
                     "1'" "1/2\"" "-1/2\"" "17.5" "1.5'" "17 1/2" "17-1/2"
                     "1/2" "1'-x\"" "")
      (cad-probe--distof s m)))
  (princ))

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
  (cad-probe-run-rtos-dimzin-probes)
  (cad-probe-run-distof-probes)
  (princ))
