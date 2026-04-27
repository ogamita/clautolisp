;;;; autolisp-test/harness/test-loader.lsp
;;;;
;;;; Loads every test file under autolisp-test/tests/ in a documented
;;;; order. Pure AutoLISP. Loaded by run.lsp after the rest of the
;;;; harness.
;;;;
;;;; AutoLISP has no portable directory walker that works identically
;;;; on every host. Rather than relying on `vl-directory-files' (which
;;;; is widely available but not strictly required by the spec), the
;;;; harness uses an explicit manifest. Adding a new test file is a
;;;; two-step operation: drop the file under tests/, then add a line
;;;; to *autolisp-test-files*.

(setq *autolisp-test-files*
      '(
        ;; --- Phase C: profile STRICT, no extension required ---------
        ;; reader
        "tests/reader/integer-literal.lsp"
        "tests/reader/real-literal.lsp"
        "tests/reader/string-literal.lsp"
        "tests/reader/symbol.lsp"
        "tests/reader/list.lsp"
        "tests/reader/dotted-pair.lsp"
        "tests/reader/quote-syntax.lsp"
        ;; variables
        "tests/variables/nil.lsp"
        "tests/variables/t.lsp"
        "tests/variables/pi.lsp"
        "tests/variables/pause.lsp"
        "tests/variables/error-star.lsp"
        ;; types
        "tests/types/type-of.lsp"
        ;; special forms
        "tests/special-forms/quote.lsp"
        "tests/special-forms/setq.lsp"
        "tests/special-forms/progn.lsp"
        "tests/special-forms/if.lsp"
        "tests/special-forms/cond.lsp"
        "tests/special-forms/and.lsp"
        "tests/special-forms/or.lsp"
        "tests/special-forms/while.lsp"
        "tests/special-forms/repeat.lsp"
        "tests/special-forms/foreach.lsp"
        "tests/special-forms/lambda.lsp"
        "tests/special-forms/function.lsp"
        "tests/special-forms/defun.lsp"
        "tests/special-forms/defun-q.lsp"
        ;; equality and predicate
        "tests/equality/eq.lsp"
        "tests/equality/equal.lsp"
        "tests/equality/null.lsp"
        "tests/equality/atom.lsp"
        "tests/equality/listp.lsp"
        "tests/equality/numberp.lsp"
        "tests/equality/zerop.lsp"
        "tests/equality/minusp.lsp"
        ;; list
        "tests/list/cons.lsp"
        "tests/list/car.lsp"
        "tests/list/cdr.lsp"
        "tests/list/cxxr.lsp"
        "tests/list/list.lsp"
        "tests/list/append.lsp"
        "tests/list/assoc.lsp"
        "tests/list/length.lsp"
        "tests/list/nth.lsp"
        "tests/list/reverse.lsp"
        "tests/list/last.lsp"
        "tests/list/member.lsp"
        "tests/list/subst.lsp"
        "tests/list/vl-list-star.lsp"
        "tests/list/vl-consp.lsp"
        "tests/list/vl-list-length.lsp"
        "tests/list/vl-position.lsp"
        "tests/list/remove.lsp"
        "tests/list/vl-sort.lsp"
        "tests/list/mapcar.lsp"
        "tests/list/vl-every.lsp"
        "tests/list/vl-some.lsp"
        "tests/list/vl-member-if.lsp"
        "tests/list/vl-remove-if.lsp"
        ;; numeric
        "tests/numeric/arithmetic.lsp"
        "tests/numeric/comparison.lsp"
        "tests/numeric/bitwise.lsp"
        "tests/numeric/math.lsp"
        "tests/numeric/round-fix-float.lsp"
        ;; string
        "tests/string/strcat.lsp"
        "tests/string/strlen.lsp"
        "tests/string/substr.lsp"
        "tests/string/strcase.lsp"
        "tests/string/ascii-chr.lsp"
        "tests/string/atoi.lsp"
        "tests/string/atof.lsp"
        "tests/string/itoa.lsp"
        "tests/string/rtos.lsp"
        "tests/string/wcmatch.lsp"
        "tests/string/xstrcase.lsp"
        "tests/string/snvalid.lsp"
        "tests/string/vl-string.lsp"
        ;; geometry
        "tests/geometry/distance.lsp"
        "tests/geometry/angle.lsp"
        "tests/geometry/polar.lsp"
        "tests/geometry/inters.lsp"
        ;; symbol / namespace
        "tests/symbol/vl-symbol.lsp"
        "tests/symbol/boundp.lsp"
        "tests/symbol/atoms-family.lsp"
        "tests/namespace/vl-bb.lsp"
        "tests/namespace/vl-doc.lsp"
        "tests/namespace/defun-q-list.lsp"
        ;; control / error
        "tests/control/eval.lsp"
        "tests/control/apply.lsp"
        "tests/error/vl-catch-all.lsp"
        "tests/error/vl-exit.lsp"
        ;; printer (strict subset; vendor-specific framing in Phase D)
        "tests/printer/prin1.lsp"
        "tests/printer/princ.lsp"
        "tests/printer/print.lsp"
        "tests/printer/terpri.lsp"
        "tests/printer/vl-prin-string.lsp"
        ;; file I/O
        "tests/file/open-close.lsp"
        "tests/file/read-write.lsp"
        "tests/file/findfile.lsp"
        "tests/file/vl-file.lsp"
        "tests/file/vl-filename.lsp"
        "tests/file/vl-directory.lsp"
        ;; --- Phase D: vendor-divergent twin tests --------------------
        "tests/divergent/atof-hex-float.lsp"
        "tests/divergent/print-framing.lsp"
        "tests/divergent/and-or-return-value.lsp"
        ;; --- Phase E: deferred families (mock-host pending) ----------
        "tests/deferred/dcl.lsp"
        "tests/deferred/com-vlax.lsp"
        "tests/deferred/vlr.lsp"
        "tests/deferred/objectdbx.lsp"
        "tests/deferred/express-tools.lsp"
        "tests/deferred/doslib.lsp"
        "tests/deferred/arx.lsp"
        "tests/deferred/brx.lsp"))

(defun autolisp-test-load-all-tests ( / loaded-count missing-count path)
  (setq loaded-count 0)
  (setq missing-count 0)
  (foreach relative *autolisp-test-files*
    (setq path (strcat *autolisp-test-root* relative))
    (cond ((findfile path)
           (load path)
           (setq loaded-count (+ loaded-count 1)))
          (T
           (princ (strcat "[autolisp-test] missing test file: " path "\n"))
           (setq missing-count (+ missing-count 1)))))
  (princ
   (strcat "[autolisp-test] loaded "
           (itoa loaded-count) " test files; "
           (itoa missing-count) " missing.\n"))
  loaded-count)

(princ "[autolisp-test] test-loader.lsp loaded.\n")
(princ)
