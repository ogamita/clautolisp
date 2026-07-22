;;;; autolisp-benchmark/harness/timer.lsp
;;;;
;;;; Portable millisecond clock for the benchmark harness.
;;;;
;;;; The harness must measure wall-clock elapsed time identically on
;;;; AutoCAD, BricsCAD, and clautolisp so that results collected on the
;;;; same hardware are directly comparable. Two portable AutoLISP time
;;;; sources exist across all three targets:
;;;;
;;;;   MILLISECS - integer milliseconds since the process/host started.
;;;;               Native on AutoCAD and BricsCAD; live on clautolisp
;;;;               (the 1.3.x line).
;;;;   DATE      - real Julian date; the fractional part is the fraction
;;;;               of the day, so multiplying by 86_400_000 yields
;;;;               milliseconds. Live on every target.
;;;;
;;;; bench-timer-init probes MILLISECS once (read, spin, read again). If
;;;; it advances we use it; otherwise we fall back to DATE. Either way
;;;; bench-clock-ms returns a real number of milliseconds and only
;;;; *differences* are ever used, so the absolute epoch is irrelevant.
;;;;
;;;; Pure AutoLISP: no Common Lisp, no host integration, no Express
;;;; Tools.

(if (not (boundp '*bench-timer-mode*))
    (setq *bench-timer-mode* nil))

(defun bench--getvar-num (name / v)
  "Return (getvar NAME) when it is a number, else nil."
  (setq v (getvar name))
  (if (numberp v) v nil))

(defun bench-timer-init ( / m1 m2 spin d)
  "Decide the clock source once and record it in *bench-timer-mode*
(one of the symbols MILLISECS or DATE). Returns the chosen mode."
  (setq *bench-timer-mode* nil)
  ;; Probe MILLISECS: read, burn a little time, read again. If the
  ;; counter moved it is a live millisecond clock and we prefer it.
  (setq m1 (bench--getvar-num "MILLISECS"))
  (if m1
      (progn
        (setq spin 0)
        (while (< spin 200000) (setq spin (1+ spin)))
        (setq m2 (bench--getvar-num "MILLISECS"))
        (if (and m2 (> m2 m1))
            (setq *bench-timer-mode* 'millisecs))))
  ;; Fall back to DATE (fraction of a day -> milliseconds).
  (if (null *bench-timer-mode*)
      (progn
        (setq d (bench--getvar-num "DATE"))
        (if d (setq *bench-timer-mode* 'date))))
  *bench-timer-mode*)

(defun bench-clock-ms ( / )
  "Current clock reading in milliseconds, as a real. Only differences
between two readings are meaningful."
  (cond
    ((eq *bench-timer-mode* 'millisecs)
     (float (getvar "MILLISECS")))
    ((eq *bench-timer-mode* 'date)
     (* (getvar "DATE") 86400000.0))
    ;; Uninitialised: default to DATE, which is live on every target.
    (t (* (getvar "DATE") 86400000.0))))

(defun bench-timer-description ( / )
  "Human-readable name of the active clock source."
  (cond ((eq *bench-timer-mode* 'millisecs) "MILLISECS (integer ms)")
        ((eq *bench-timer-mode* 'date) "DATE (Julian * 86400000)")
        (t "DATE (uninitialised default)")))

(princ)
