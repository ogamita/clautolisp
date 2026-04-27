;;;; tests/divergent/atof-hex-float.lsp -- vendor divergence on (atof "0x1p4")
;;;;
;;;; BricsCAD V26 / macOS Phase-5 probe (autolisp-spec/results/bricscad/macos/
;;;; 20260426T122808Z/results.sexp) recorded:
;;;;   (atof "0x1p4") -> 16.0
;;;; clautolisp deliberately omits C99 hex-float syntax under its conservative
;;;; choice (see clautolisp/PLAN.md, autolisp-spec source notes).
;;;;
;;;; AutoCAD probe data is not yet available; the AutoCAD twin is INFERRED
;;;; from "atof rejects hex-float syntax" being the strict-spec position.

;; --- BricsCAD twin (TESTED-BRICSCAD) -------------------------------
(deftest "bricscad-atof-accepts-c99-hex-float"
  '((operator . "ATOF") (area . "string") (profile . bricscad)
    (authority . tested-bricscad))
  '(atof "0x1p4")
  16.0)

;; --- AutoCAD twin (INFERRED) ---------------------------------------
(deftest "autocad-atof-rejects-c99-hex-float"
  '((operator . "ATOF") (area . "string") (profile . autocad)
    (authority . inferred))
  '(atof "0x1p4")
  0.0)
