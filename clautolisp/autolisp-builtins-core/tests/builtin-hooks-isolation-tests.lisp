;;;; clautolisp/autolisp-builtins-core/tests/builtin-hooks-isolation-tests.lisp
;;;;
;;;; INSTALL-CORE-BUILTINS sets process-wide hooks in the runtime (COM points
;;;; and object arrays as VARIANT(SAFEARRAY), the vla-* facade, the VLAX-FOR
;;;; member list). The cador suite tests the host BELOW the builtins, where
;;;; points cross as plain lists; it used to get that state only because no
;;;; suite before it had installed the builtins, so a tool-suite test that did
;;;; made seven cador tests fail with "#<VARIANT ARRAY #<SAFEARRAY>> is not a
;;;; LIST" (install-core-builtins-leaks-com-hooks-across-suites.issue).
;;;;
;;;; These tests install the builtins -- exactly what a suite running before
;;;; cador does -- and then check what the cador suite's environment sees.

(in-package #:clautolisp.autolisp-builtins-core.tests)

(in-suite autolisp-builtins-core-suite)

(defmacro %preserving-builtin-hooks (&body body)
  "Run BODY and put the runtime hooks back as they were, so this file's own
INSTALL-CORE-BUILTINS leaves the process as it found it."
  `(let ((clautolisp.autolisp-runtime:*resolve-unbound-function-hook*
           clautolisp.autolisp-runtime:*resolve-unbound-function-hook*)
         (clautolisp.autolisp-runtime:*vlax-collection-items-hook*
           clautolisp.autolisp-runtime:*vlax-collection-items-hook*)
         (clautolisp.autolisp-runtime:*com-point-wrap-hook*
           clautolisp.autolisp-runtime:*com-point-wrap-hook*)
         (clautolisp.autolisp-runtime:*com-point-unwrap-hook*
           clautolisp.autolisp-runtime:*com-point-unwrap-hook*)
         (clautolisp.autolisp-runtime:*com-objects-wrap-hook*
           clautolisp.autolisp-runtime:*com-objects-wrap-hook*))
     ,@body))

(test installed-builtins-hooks-do-not-reach-the-cador-suite
  "After INSTALL-CORE-BUILTINS, the cador suite's environment still sees COM
points and object arrays as plain lists, as the bare host returns them."
  (%preserving-builtin-hooks
    (install-core-builtins)
    ;; The leak source is live: out here, a point is wrapped.
    (is (typep (clautolisp.cador::%wrap-com-point '(1.0d0 2.0d0 3.0d0))
               'clautolisp.autolisp-runtime:autolisp-variant))
    (multiple-value-bind (point objects point-in hooks)
        (clautolisp.cador.tests::call-with-cador-suite-environment
         (lambda ()
           (values (clautolisp.cador::%wrap-com-point '(1.0d0 2.0d0 3.0d0))
                   (clautolisp.cador::%wrap-com-objects '(:a :b))
                   (clautolisp.cador::%maybe-com-point '(4 5 6))
                   (list clautolisp.autolisp-runtime:*resolve-unbound-function-hook*
                         clautolisp.autolisp-runtime:*vlax-collection-items-hook*
                         clautolisp.autolisp-runtime:*com-point-wrap-hook*
                         clautolisp.autolisp-runtime:*com-point-unwrap-hook*
                         clautolisp.autolisp-runtime:*com-objects-wrap-hook*))))
      (is (equal '(1.0d0 2.0d0 3.0d0) point))
      (is (equal '(:a :b) objects))
      (is (equal '(4.0d0 5.0d0 6.0d0) point-in))
      (is (equal '(nil nil nil nil nil) hooks)))
    ;; ...and the installed builtins are untouched once it returns.
    (is (typep (clautolisp.cador::%wrap-com-point '(1.0d0 2.0d0 3.0d0))
               'clautolisp.autolisp-runtime:autolisp-variant))))

(test without-builtin-layer-hooks-restores-the-installed-hooks
  "WITHOUT-BUILTIN-LAYER-HOOKS unbinds, it does not uninstall: the hooks the
builtins set are back when its body exits, even by a non-local exit."
  (%preserving-builtin-hooks
    (install-core-builtins)
    (let ((wrap clautolisp.autolisp-runtime:*com-point-wrap-hook*)
          (resolve clautolisp.autolisp-runtime:*resolve-unbound-function-hook*))
      (catch 'out
        (clautolisp.autolisp-runtime:without-builtin-layer-hooks
          (throw 'out nil)))
      (is (eq wrap clautolisp.autolisp-runtime:*com-point-wrap-hook*))
      (is (eq resolve clautolisp.autolisp-runtime:*resolve-unbound-function-hook*)))))
