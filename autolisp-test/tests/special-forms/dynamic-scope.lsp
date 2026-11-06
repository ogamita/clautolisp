;;;; tests/special-forms/dynamic-scope.lsp -- AutoLISP dynamic scoping

;; AutoLISP variables are dynamically scoped: a name declared local in a
;; caller (after the `/` in its argument list) is visible to any function
;; called during that caller's dynamic extent, and the binding is unwound
;; when the caller returns. This differs from Common Lisp's lexical
;; scoping and is uniform across AutoCAD and BricsCAD.
;;
;; Regression anchor: issues/closed/autolisp-test-results-corrupted-to-t
;; wrongly blamed a "dynamic-binding bug" for a harness `or`-value mistake
;; (AutoLISP `or` returns T/nil, not the first truthy value -- see
;; tests/special-forms/or.lsp and tests/divergent/and-or-return-value.lsp).
;; These tests pin the (correct) dynamic scoping so that if it ever really
;; did regress, the corpus would catch it directly.

(deftest "dynamic-scope-callee-sees-caller-local"
  '((operator . "DEFUN") (area . "special-forms") (profile . strict))
  '(progn (setq dynscope-v 'global)
          (defun dynscope-callee ( / ) dynscope-v)
          (defun dynscope-caller ( / dynscope-v)
            (setq dynscope-v 'local)
            (dynscope-callee))
          (dynscope-caller))
  'local)

(deftest "dynamic-scope-binding-unwound-after-caller-returns"
  '((operator . "DEFUN") (area . "special-forms") (profile . strict))
  '(progn (setq dynscope-w 'global)
          (defun dynscope-shadow ( / dynscope-w)
            (setq dynscope-w 'local)
            dynscope-w)
          (dynscope-shadow)
          dynscope-w)
  'global)

(deftest "dynamic-scope-innermost-caller-binding-wins"
  '((operator . "DEFUN") (area . "special-forms") (profile . strict))
  '(progn (setq dynscope-x 'global)
          (defun dynscope-read ( / ) dynscope-x)
          (defun dynscope-inner ( / dynscope-x)
            (setq dynscope-x 'inner)
            (dynscope-read))
          (defun dynscope-outer ( / dynscope-x)
            (setq dynscope-x 'outer)
            (dynscope-inner))
          (dynscope-outer))
  'inner)
