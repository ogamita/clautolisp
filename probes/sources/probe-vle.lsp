;;;; probes/sources/probe-vle.lsp
;;;;
;;;; The VLE-* (BricsCAD "Visual Lisp Extensions") edge cases that
;;;; clautolisp implements on an UNVERIFIED reading of the Bricsys prose.
;;;; Each case here is a `;;; SPEC-UNCERTAIN:' marker in
;;;; clautolisp/autolisp-builtins-core/source/api.lisp whose answer only a
;;;; real engine settles; the questions are tracked in
;;;; issues/open/deferred-spec-research.issue.
;;;;
;;;; The VLE-* family is a BRICSCAD extension: on AutoCAD every case is
;;;; expected to record status "error" (no function definition), which is
;;;; itself the datapoint for each symbol's spec Availability line
;;;; (BricsCAD-only, confirmed on hardware). The BEHAVIOURAL answers come
;;;; from BricsCAD -- reachable on macOS (thalassa) as well as the Windows
;;;; runner, so this suite is not Windows-runner-critical; it is here
;;;; because it is the largest ready cluster of implementer-flagged
;;;; uncertainty and retires nine markers in one run.
;;;;
;;;; Portability (probes/README.org): every probed form is held as a STRING
;;;; and (eval (read ...))'d at run time, so a host that cannot parse or
;;;; does not define a form fails THAT ONE case (recorded "error"), never
;;;; the LOAD of the file or the whole run. The case name is the exact
;;;; expression, kept verbatim for re-evaluation.

(defun cad-probe--vle (case-text)
  (cad-probe-capture "vle" case-text
    (function (lambda () (vl-prin1-to-string (eval (read case-text)))))))

(defun cad-probe-run-vle-probes ()
  ;; VLE-SUBST-NTH (api.lisp): out-of-range IDX -- pad, leave unchanged,
  ;; or signal? clautolisp leaves the list unchanged.
  (cad-probe-note "vle" "vle-subst-nth"
    "out-of-range IDX: pad / unchanged / error? (clautolisp: unchanged)")
  (cad-probe--vle "(vle-subst-nth (list 'a 'b 'c) 1 'X)")   ; in range, baseline
  (cad-probe--vle "(vle-subst-nth (list 'a 'b 'c) 3 'X)")   ; idx == length
  (cad-probe--vle "(vle-subst-nth (list 'a 'b 'c) 5 'X)")   ; idx > length
  (cad-probe--vle "(vle-subst-nth (list 'a 'b 'c) -1 'X)")  ; negative

  ;; VLE-LIST-SPLIT (api.lisp): result shape (head tail) vs (head . tail);
  ;; where the splitter item lands; item not present.
  (cad-probe-note "vle" "vle-list-split"
    "result shape; splitter placement (head/tail/dropped); not-present")
  (cad-probe--vle "(vle-list-split (list 'a 'b 'c 'd) 'c)")
  (cad-probe--vle "(vle-list-split (list 'a 'b 'c) 'a)")    ; splitter first
  (cad-probe--vle "(vle-list-split (list 'a 'b 'c) 'z)")    ; not present

  ;; VLE-MEMBER (api.lisp): pure boolean (T/nil) vs tail-returning.
  (cad-probe-note "vle" "vle-member"
    "boolean (T/nil) vs tail-returning (b c)? (clautolisp: tail)")
  (cad-probe--vle "(vle-member 'b (list 'a 'b 'c))")
  (cad-probe--vle "(vle-member 'z (list 'a 'b 'c))")

  ;; VLE-VECTOR-NORMALISE (api.lisp): zero-length input -- nil, zero
  ;; vector, or signal? clautolisp returns nil.
  (cad-probe-note "vle" "vle-vector-normalise"
    "zero-length input: nil / zero-vector / error? (clautolisp: nil)")
  (cad-probe--vle "(vle-vector-normalise (list 3.0 0.0 0.0))")  ; baseline
  (cad-probe--vle "(vle-vector-normalise (list 0.0 0.0 0.0))")  ; degenerate

  ;; VLE-VECTOR-GETUCS (api.lisp): arbitrary-axis orientation at the
  ;; +-world-Z poles (the 1/64 threshold branch).
  (cad-probe-note "vle" "vle-vector-getucs"
    "basis orientation at normal == +/- world-Z (arbitrary-axis 1/64 rule)")
  (cad-probe--vle "(vle-vector-getucs (list 0.0 0.0 1.0))")
  (cad-probe--vle "(vle-vector-getucs (list 0.0 0.0 -1.0))")
  (cad-probe--vle "(vle-vector-getucs (list 0.01 0.0 1.0))")   ; just inside threshold

  ;; VLE-STRING-REPLACE (api.lisp): replace-first vs replace-all.
  ;; clautolisp replaces ALL.
  (cad-probe-note "vle" "vle-string-replace"
    "replace-first vs replace-all? arg order (new old in). (clautolisp: all)")
  (cad-probe--vle "(vle-string-replace \"X\" \"a\" \"banana\")")
  (cad-probe--vle "(vle-string-replace \"\" \"a\" \"banana\")")  ; empty needle

  ;; VLE-STRING-SPLIT (api.lisp): empty tokens between adjacent delimiters
  ;; -- kept or collapsed? Leading/trailing delimiter? clautolisp keeps.
  (cad-probe-note "vle" "vle-string-split"
    "empty tokens between adjacent delimiters: kept or collapsed? (clautolisp: kept)")
  (cad-probe--vle "(vle-string-split \",\" \"a,,b\")")    ; interior empty
  (cad-probe--vle "(vle-string-split \",\" \",a,\")")     ; leading + trailing
  (cad-probe--vle "(vle-string-split \",;\" \"a,b;c\")")  ; multi-key

  ;; VLE-ACI2RGB (api.lisp): the algorithmic 10-249 hue range, which
  ;; clautolisp leaves un-tabulated (returns nil). Capture the vendor RGB.
  (cad-probe-note "vle" "vle-aci2rgb"
    "RGB for the algorithmic 10-249 range (clautolisp: nil, un-tabulated)")
  (cad-probe--vle "(vle-aci2rgb 1)")     ; tabulated baseline (red)
  (cad-probe--vle "(vle-aci2rgb 10)")
  (cad-probe--vle "(vle-aci2rgb 150)")
  (cad-probe--vle "(vle-aci2rgb 249)")

  ;; VLE-RGB2ACI (api.lisp): argument shape -- a 3-element (R G B) list,
  ;; a single packed 24-bit integer, or three separate integers? Probe all
  ;; three; whichever does not error is the accepted form.
  (cad-probe-note "vle" "vle-rgb2aci"
    "arg shape: (R G B) list / packed int / three ints? (clautolisp: list)")
  (cad-probe--vle "(vle-rgb2aci (list 255 0 0))")  ; list form (clautolisp)
  (cad-probe--vle "(vle-rgb2aci 255)")             ; packed-integer form
  (cad-probe--vle "(vle-rgb2aci 255 0 0)")         ; three-argument form
  (princ))
