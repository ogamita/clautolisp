;;;; probes/sources/probe-lispsys.lsp
;;;;
;;;; Read, and optionally set, the CAD's LISPSYS (dialect-platform-version-axis:
;;;; AutoCAD at LISPSYS 1 had never been measured -- the CI machine is at 0).
;;;; LISPSYS is persisted and takes effect at the NEXT launch, so a run that
;;;; sets it measures nothing: scripts/run-lispsys1-probe.sh sets it in one
;;;; session, measures in fresh ones, and sets it back.
;;;;
;;;; PROBE_LISPSYS (environment): "0", "1" or "2" -> setvar it; anything else
;;;; (e.g. "read") -> only record the value this session started with.
;;;;
;;;; QUARANTINED in manifest.txt: a default probe run must never change the
;;;; machine's LISPSYS. It runs only when PROBE_SUITES names it.

(defun cad-probe-run-lispsys-probes ( / want)
  (setq want (getenv "PROBE_LISPSYS"))
  (cad-probe-capture "lispsys" "value at start"
    (function (lambda () (vl-prin1-to-string (getvar "LISPSYS")))))
  (if (member want '("0" "1" "2"))
    (cad-probe-capture "lispsys" "setvar"
      (function (lambda ()
        (vl-prin1-to-string (setvar "LISPSYS" (atoi want)))))))
  (princ))
