;;;; probes/sources/probe-versions.lsp
;;;;
;;;; Version-dependent facts (dialect-platform-version-axis): whether the
;;;; operators the vendor documentation says a release added or removed are
;;;; defined on this engine, and the sysvars whose form changed by release.
;;;; Run on the versions the CI has (AutoCAD 2022, BricsCAD V26); users of
;;;; other versions can contribute their results (pjb 2026-10-03). Nothing
;;;; is called -- only TYPE of the symbol's value is read.

(defun cad-probe-run-version-probes ()
  (foreach name '("FINDTRUSTEDFILE" "VLAX-MACHINE-PRODUCT-KEY"
                  "SHOWHTMLMODALWINDOW" "ACET-LOAD-EXPRESSTOOLS"
                  "DOS_COMMAND" "VLE-ENABLESERVERBUSY" "DUMPALLPROPERTIES"
                  "GETPROPERTYVALUE" "ISPROPERTYVALID" "VL-INFP" "VL-NANP"
                  "VLA-POSTCOMMAND" "VLE-FILE-ENCODING" "VL-SUBENT-ATPOINT"
                  "VLE-SUNID" "VL-LOCAL-UNDO-PUSH" "VLE-VECTOR-TO2D" "MOD" "ROUND")
    (cad-probe-capture "versions" (strcat "type of " name)
      (function (lambda () (vl-princ-to-string (type (eval (read name))))))))
  (foreach var '("LISPSYS" "LOCALE")
    (cad-probe-capture "versions" (strcat "getvar " var)
      (function (lambda () (vl-prin1-to-string (getvar var))))))
  (cad-probe-capture "versions" "(ver)"
    (function (lambda () (vl-prin1-to-string (ver)))))
  ;; BricsCAD V18.1's release notes: "tiny doubles print 0.0". How do both
  ;; print them today (prin1 / princ / rtos)? The values are built by
  ;; arithmetic, not read from source text.
  (foreach v (list (/ 1.0 1.0e6) (/ 1.0 1.0e10) (/ 1.0 1.0e15) (/ 1.0 1.0e20)
                   (/ 1.0 1.0e100) (/ 1.0 (* 1.0e150 1.0e150)) (- (/ 1.0 1.0e20))
                   (* 123.0 (/ 1.0 1.0e20)))
    (cad-probe-capture "versions" (strcat "tiny double " (rtos v 1 3))
      (function (lambda ()
        (strcat (vl-prin1-to-string v) " | " (vl-princ-to-string v)
                " | " (rtos v))))))
  (princ))
