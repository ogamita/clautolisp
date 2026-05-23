;;;; tests/special-forms/function.lsp -- FUNCTION special form

(deftest "function-named-symbol-resolves-to-function"
  '((operator . "FUNCTION") (area . "special-forms") (profile . strict))
  '(progn (defun fn-target (x) (+ x 1))
          (apply (function fn-target) '(10)))
  11)

(deftest "function-of-builtin"
  '((operator . "FUNCTION") (area . "special-forms") (profile . strict))
  '(apply (function +) '(1 2 3))
  6)

(deftest "function-of-lambda"
  '((operator . "FUNCTION") (area . "special-forms") (profile . strict))
  '(apply (function (lambda (x) (* x 10))) '(7))
  70)

(deftest "function-mapcar-with-builtin"
  '((operator . "FUNCTION") (area . "special-forms") (profile . strict))
  '(mapcar (function 1+) '(1 2 3))
  '(2 3 4))

;;;; Portable higher-order-function idiom (TN003): `function` is
;;;; identical to `quote` except for a Visual-LISP compiler hint, so
;;;; passing `(function foo)` through a parameter and applying it via
;;;; APPLY must resolve `foo` at call time against the dynamic-scope
;;;; chain — *not* at the point the FUNCTION form was reached. That
;;;; late resolution is what makes higher-order code portable between
;;;; AutoCAD and BricsCAD.

(deftest "function-symbol-resolves-through-parameter-shadow"
  '((operator . "FUNCTION") (area . "special-forms") (profile . strict))
  ;; A parameter named `helper` shadows the global by lisp-1 rules. The
  ;; symbol value is not callable, so APPLY must walk past the shadow
  ;; and resolve `helper` against the surrounding namespace.
  '(progn (defun helper (x) (list 'global x))
          (defun hof (helper x) (apply helper (list x)))
          (hof (function helper) 42))
  '(global 42))

(deftest "function-of-lambda-via-parameter"
  '((operator . "FUNCTION") (area . "special-forms") (profile . strict))
  '(progn (defun hof (fn x) (apply fn (list x)))
          (hof (function (lambda (n) (* n n))) 9))
  81)

(deftest "function-late-resolution-picks-up-shadowed-defun"
  '((operator . "FUNCTION") (area . "special-forms") (profile . strict))
  ;; Inner `defun` inside the `/`-locals of `outer` rebinds the local
  ;; shadow (mirroring SETQ in a lisp-1). A nested function called
  ;; from `outer` MUST see that local redefinition when applying
  ;; `(function helper)`, even though TEST at top-level still sees the
  ;; original global. Validates set-function honouring dynamic shadows
  ;; and lookup-function walking past non-callable bindings.
  '(progn (defun helper (x) (list 'global x))
          (defun hof (helper x) (apply helper (list x)))
          (defun outer (/ helper)
            (defun helper (x) (list 'local x))
            (defun inner () (hof (function helper) 99))
            (inner))
          (list (hof (function helper) 1) (outer)))
  '((global 1) (local 99)))

(deftest "function-after-outer-returns-restores-global"
  '((operator . "FUNCTION") (area . "special-forms") (profile . strict))
  ;; The local `defun helper` inside `outer`'s `/`-locals must NOT
  ;; corrupt the global definition. Once `outer` returns and its
  ;; dynamic frame pops, calling `helper` directly resolves to the
  ;; original global.
  '(progn (defun helper (x) (list 'global x))
          (defun outer (/ helper)
            (defun helper (x) (list 'local x))
            (helper 1))
          (outer)
          (helper 2))
  '(global 2))
