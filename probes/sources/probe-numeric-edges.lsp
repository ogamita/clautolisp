;;;; probes/sources/probe-numeric-edges.lsp
;;;;
;;;; Numeric and lexical edges whose AutoCAD answer is lost when the
;;;; Windows runner goes away (the BricsCAD halves are already measured on
;;;; macOS -- see autolisp-spec Phase 5 / specification-resolution-plan.org).
;;;; These are the AUTOCAD-CRITICAL numeric gaps from the spec harvest:
;;;;
;;;;   - integer width / overflow (ch.8): does AutoCAD keep an integer, wrap
;;;;     to a negative, promote to a real, or signal, at/above 2^31?
;;;;   - negative integer division rounding (ch.8 `/'): -7/2 -> -3 (toward
;;;;     zero) or -4 (floor)? sign of REM?
;;;;   - atoi / atof lexical edges (ch.9): octal-on-leading-zero, 0x
;;;;     autodetect, C99 hex-float, sign, leading space, locale comma,
;;;;     trailing junk. BricsCAD V26/macOS is known (atoi strtol base-10;
;;;;     atof strtod incl. 0x1p4=>16.0, decimal-comma rejected); AutoCAD is
;;;;     the open half.
;;;;
;;;; NOT here, on purpose: real division by zero, (/ 1.0 0.0). The spec
;;;; harvest records that BricsCAD V26 *aborts the application* on it -- an
;;;; uncatchable abort that would take the whole run down, exactly the
;;;; hazard probe-load-refusal.lsp is quarantined for. It is scheduled as a
;;;; quarantined / AutoCAD-only probe in
;;;; windows-runner-sunset-probe-campaign.issue, not run inline here.
;;;;
;;;; Portability (probes/README.org): each form is held as a STRING and
;;;; (eval (read ...))'d, so a host that refuses to parse or evaluate one
;;;; form fails THAT case only. The case name is the exact expression.

(defun cad-probe--num (case-text)
  (cad-probe-capture "numeric-edges" case-text
    (function (lambda () (vl-prin1-to-string (eval (read case-text)))))))

(defun cad-probe-run-numeric-edges-probes ()
  ;; Integer width / overflow (ch.8). Each result's TYPE matters as much as
  ;; its value: capture (type V) alongside V so a silent promotion to real
  ;; or a wrap to a negative integer is visible.
  (cad-probe-note "numeric-edges" "integer-overflow"
    "at/above 2^31: integer kept / wrap-negative / promote-real / signal?")
  (cad-probe--num "(list (+ 2147483640 100) (type (+ 2147483640 100)))")
  (cad-probe--num "(list (* 2000000000 2) (type (* 2000000000 2)))")
  (cad-probe--num "(list (1+ 2147483647) (type (1+ 2147483647)))")
  (cad-probe--num "(list (* 46341 46341) (type (* 46341 46341)))")
  (cad-probe--num "(list (- -2147483648 1) (type (- -2147483648 1)))")
  (cad-probe--num "(list (* 100000 100000) (type (* 100000 100000)))")

  ;; Negative integer division rounding and remainder sign (ch.8 `/', REM).
  (cad-probe-note "numeric-edges" "neg-int-division"
    "(/ -7 2) -> -3 (toward zero) or -4 (floor)? sign of (rem -7 2)?")
  (cad-probe--num "(/ -7 2)")
  (cad-probe--num "(/ 7 -2)")
  (cad-probe--num "(/ -1 2)")
  (cad-probe--num "(rem -7 2)")
  (cad-probe--num "(rem 7 -2)")

  ;; ATOI lexical edges (ch.9). BricsCAD V26: strtol base-10 -- "017"->17
  ;; (no octal), "0xbabe"->0 (no hex autodetect), "+17"->17, "17x"->17,
  ;; leading space skipped, "3.9"->3. AutoCAD is the open half.
  (cad-probe-note "numeric-edges" "atoi"
    "octal-on-0 / 0x-autodetect / sign / leading-space / trailing-junk")
  (cad-probe--num "(atoi \"017\")")
  (cad-probe--num "(atoi \"0xbabe\")")
  (cad-probe--num "(atoi \"+17\")")
  (cad-probe--num "(atoi \"-17\")")
  (cad-probe--num "(atoi \"17x\")")
  (cad-probe--num "(atoi \" 17\")")
  (cad-probe--num "(atoi \"3.9\")")
  (cad-probe--num "(atoi \"\")")

  ;; ATOF lexical edges (ch.9). BricsCAD V26: strtod -- accepts C99 hex
  ;; float (0x1p4 -> 16.0), rejects decimal-comma (3,5 -> 3.0). AutoCAD is
  ;; the open half: does it accept hex-float / honour a locale comma?
  (cad-probe-note "numeric-edges" "atof"
    "hex-float 0x1p4 / .5 / 1. / exponent / locale-comma / leading-space")
  (cad-probe--num "(atof \"0x1p4\")")
  (cad-probe--num "(atof \".5\")")
  (cad-probe--num "(atof \"1.\")")
  (cad-probe--num "(atof \"1e3\")")
  (cad-probe--num "(atof \"1.5e-3\")")
  (cad-probe--num "(atof \"3,5\")")
  (cad-probe--num "(atof \" 3.5\")")
  (cad-probe--num "(atof \"017\")")
  (princ))
