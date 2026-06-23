;;;; tests/documentation/preceding-doc.lsp
;;;;
;;;; The clautolisp source-aware documentation extension: a ;| ... |;
;;;; block comment immediately preceding a (defun NAME ...) or
;;;; (setq NAME ...) attaches its text to the binding cell NAME
;;;; resolves to, queryable via CLAUTOLISP-DOCUMENTATION /
;;;; CLAUTOLISP-DOCUMENTATION-KIND. Exercises the Phase-2 update-rules
;;;; table and the dynamic-scope shadowing example from
;;;; issues/open/source-aware-defun-documentation.issue.
;;;;
;;;; clautolisp-only extension; these builtins are absent on AutoCAD /
;;;; BricsCAD. Each test uses fresh names so the shared image's other
;;;; bindings don't interfere.

(deftest "doc-defun-block-attaches-string"
  '((operator . "CLAUTOLISP-DOCUMENTATION") (area . "documentation") (profile . strict))
  '(progn ;|d1|;
          (defun doc-f1 () 1)
          (clautolisp-documentation 'doc-f1))
  "d1")

(deftest "doc-defun-block-kind-is-function"
  '((operator . "CLAUTOLISP-DOCUMENTATION-KIND") (area . "documentation") (profile . strict))
  '(progn ;|d2|;
          (defun doc-f2 () 1)
          (clautolisp-documentation-kind 'doc-f2))
  'function)

(deftest "doc-defun-without-block-overwrites-to-nil"
  '((operator . "CLAUTOLISP-DOCUMENTATION") (area . "documentation") (profile . strict))
  '(progn ;|d3|;
          (defun doc-f3 () 1)
          (defun doc-f3 () 2)
          (clautolisp-documentation 'doc-f3))
  nil)

(deftest "doc-setq-block-attaches-string"
  '((operator . "CLAUTOLISP-DOCUMENTATION") (area . "documentation") (profile . strict))
  '(progn ;|v4|;
          (setq doc-v4 42)
          (clautolisp-documentation 'doc-v4))
  "v4")

(deftest "doc-setq-block-kind-is-variable"
  '((operator . "CLAUTOLISP-DOCUMENTATION-KIND") (area . "documentation") (profile . strict))
  '(progn ;|v5|;
          (setq doc-v5 42)
          (clautolisp-documentation-kind 'doc-v5))
  'variable)

(deftest "doc-setq-without-block-preserves-variable-doc"
  '((operator . "CLAUTOLISP-DOCUMENTATION") (area . "documentation") (profile . strict))
  '(progn ;|v6|;
          (setq doc-v6 1)
          (setq doc-v6 2)
          (clautolisp-documentation 'doc-v6))
  "v6")

(deftest "doc-setq-after-documented-defun-clears"
  '((operator . "CLAUTOLISP-DOCUMENTATION") (area . "documentation") (profile . strict))
  '(progn ;|q7|;
          (defun doc-q7 () 1)
          (setq doc-q7 5)
          (clautolisp-documentation 'doc-q7))
  nil)

(deftest "doc-multipair-setq-attaches-to-first-name-only"
  '((operator . "CLAUTOLISP-DOCUMENTATION") (area . "documentation") (profile . strict))
  '(progn ;|m8|;
          (setq doc-a8 1 doc-b8 2)
          (list (clautolisp-documentation 'doc-a8)
                (clautolisp-documentation 'doc-b8)))
  '("m8" nil))

(deftest "doc-undocumented-binding-returns-nil"
  '((operator . "CLAUTOLISP-DOCUMENTATION") (area . "documentation") (profile . strict))
  '(progn (defun doc-u9 () 1)
          (clautolisp-documentation 'doc-u9))
  nil)

(deftest "doc-shadowing-inner-visible-then-outer-restored"
  '((operator . "CLAUTOLISP-DOCUMENTATION") (area . "documentation") (profile . strict))
  '(progn ;|g10|;
          (defun doc-s10 (/ doc-s10)
            ;|i10|;
            (defun doc-s10 (x) (clautolisp-documentation 'doc-s10))
            (doc-s10 0))
          (list (doc-s10) (clautolisp-documentation 'doc-s10)))
  '("i10" "g10"))
