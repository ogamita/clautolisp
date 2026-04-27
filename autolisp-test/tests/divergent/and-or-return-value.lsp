;;;; tests/divergent/and-or-return-value.lsp -- AND / OR return convention
;;;;
;;;; This area is *not* divergent in current published vendor docs:
;;;; both AutoCAD and BricsCAD return T or nil only (never the first
;;;; truthy value), per the BricsCAD V26 / macOS Phase-5 probe and
;;;; per long-standing AutoCAD documentation. The strict tests in
;;;; tests/special-forms/and.lsp and or.lsp already pin that.
;;;;
;;;; The historical Common-Lisp-style behaviour (return last truthy
;;;; value) is recorded here as a deliberately failing test that some
;;;; non-conforming third-party implementations might still expose.
;;;; It is registered with profile AUTOCAD and BRICSCAD so that any
;;;; implementation reporting CL-style behaviour gets a clear DEVIATES
;;;; signal in the corresponding subset.

(deftest "autocad-and-returns-T-not-last-truthy"
  '((operator . "AND") (area . "special-forms") (profile . autocad)
    (authority . inferred))
  '(and 1 2 3) T)

(deftest "bricscad-and-returns-T-not-last-truthy"
  '((operator . "AND") (area . "special-forms") (profile . bricscad)
    (authority . tested-bricscad))
  '(and 1 2 3) T)

(deftest "autocad-or-returns-T-not-first-truthy"
  '((operator . "OR") (area . "special-forms") (profile . autocad)
    (authority . inferred))
  '(or 'first 'second) T)

(deftest "bricscad-or-returns-T-not-first-truthy"
  '((operator . "OR") (area . "special-forms") (profile . bricscad)
    (authority . tested-bricscad))
  '(or 'first 'second) T)
