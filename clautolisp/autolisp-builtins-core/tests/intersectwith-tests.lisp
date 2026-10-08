(in-package #:clautolisp.autolisp-builtins-core.tests)

(in-suite autolisp-builtins-core-suite)

;;;; IntersectWith end to end on the cador host (cador-intersectwith-missing):
;;;; the downstream SCHMS report was "VLA-Object AutoCAD.Entity has no method
;;;; named INTERSECTWITH". Both call forms, the VARIANT / SAFEARRAY shape, the
;;;; EMPTY result. The geometry itself is covered by cador's intersect-tests.

(defparameter *iw-setup*
  "(vl-load-com)
   (setq iw-a (vlax-ename->vla-object
               (entmakex '((0 . \"LINE\") (10 0.0 0.0 0.0) (11 10.0 10.0 0.0)))))
   (setq iw-b (vlax-ename->vla-object
               (entmakex '((0 . \"LINE\") (10 0.0 10.0 0.0) (11 10.0 0.0 0.0)))))
   (setq iw-c (vlax-ename->vla-object
               (entmakex '((0 . \"CIRCLE\") (10 0.0 0.0 0.0) (40 . 5.0)))))
   (setq iw-in (vlax-ename->vla-object
                (entmakex '((0 . \"LINE\") (10 -1.0 0.0 0.0) (11 1.0 0.0 0.0)))))
   (setq iw-far (vlax-ename->vla-object
                 (entmakex '((0 . \"LINE\") (10 20.0 0.0 0.0) (11 30.0 1.0 0.0)))))
   ")

(defun %iw-run (source)
  (%vla (concatenate 'string *iw-setup* source)))

(defun %iw-near (expected actual)
  (and (listp actual)
       (= (length expected) (length actual))
       (every (lambda (e a) (and (realp a) (< (abs (- e a)) 1d-9))) expected actual)))

(test intersectwith-extend-constants-are-bound
  (is (equal '(0 1 2 3)
             (%iw-run "(list acExtendNone acExtendThisEntity acExtendOtherEntity acExtendBoth)"))))

(test vla-intersectwith-returns-a-variant-of-a-double-safearray
  (let ((result (%iw-run "(setq iw-v (vla-intersectwith iw-a iw-b acExtendNone))
                          (list (type iw-v)
                                (type (vlax-variant-value iw-v))
                                (vlax-safearray-get-l-bound (vlax-variant-value iw-v) 1)
                                (vlax-safearray-get-u-bound (vlax-variant-value iw-v) 1)
                                (vlax-safearray->list (vlax-variant-value iw-v))
                                (vlax-variant-type iw-v))")))
    (is (equal "VARIANT" (autolisp-symbol-name (first result))))
    (is (equal "SAFEARRAY" (autolisp-symbol-name (second result))))
    ;; 8192 + vlax-vbDouble, measured on AutoCAD and BricsCAD
    (is (eql 8197 (sixth result)))
    (is (eql 0 (third result)))
    (is (eql 2 (fourth result)))
    (is (%iw-near '(5d0 5d0 0d0) (fifth result)))))

(test vla-intersectwith-two-points-flattened-in-the-measured-order
  ;; line x circle: the point farther from the line's start first
  (is (%iw-near '(5d0 0d0 0d0 -5d0 0d0 0d0)
                (%iw-run "(vlax-safearray->list
                           (vlax-variant-value (vla-intersectwith iw-in iw-c acExtendThisEntity)))"))))

(defun %iw-empty-shape (dialect-form)
  (%iw-run (concatenate 'string dialect-form
                        "(setq iw-v (vla-intersectwith iw-a iw-far acExtendNone))
                         (list (type iw-v)
                               (vlax-safearray-get-l-bound (vlax-variant-value iw-v) 1)
                               (vlax-safearray-get-u-bound (vlax-variant-value iw-v) 1)
                               (vlax-variant-type iw-v)
                               (vl-catch-all-error-message
                                (vl-catch-all-apply 'vlax-safearray->list
                                                    (list (vlax-variant-value iw-v)))))")))

(test vla-intersectwith-empty-result-is-an-empty-array-not-nil
  ;; Measured 2026-10-08 (AutoCAD 2022, BricsCAD V25 / V26): bounds 0 .. -1,
  ;; and vlax-safearray->list of it is an ERROR on both.
  (let ((result (%iw-empty-shape "(setq *AUTOLISP-DIALECT* 'autocad)")))
    (is (equal "VARIANT" (autolisp-symbol-name (first result))))
    (is (eql 0 (second result)))
    (is (eql -1 (third result)))
    ;; AutoCAD: an empty array of doubles
    (is (eql 8197 (fourth result)))
    (is (search "Invalid index" (autolisp-string-value (fifth result)))))
  (let ((result (%iw-empty-shape "(setq *AUTOLISP-DIALECT* 'bricscad)")))
    (is (eql -1 (third result)))
    ;; BricsCAD: an empty array of VARIANTs
    (is (eql 8204 (fourth result)))
    (is (search "expected SAFEARRAY" (autolisp-string-value (fifth result))))))

(test intersectwith-order-follows-the-dialect-product
  ;; circle x circle with acExtendOtherEntity: AutoCAD answers as the
  ;; argument's IntersectWith, BricsCAD does not (probe, 2026-10-08).
  (flet ((%in-dialect (dialect)
           (%iw-run (format nil "(setq *AUTOLISP-DIALECT* '~A)
                                 (setq iw-r6 (vlax-ename->vla-object
                                   (entmakex '((0 . \"CIRCLE\") (10 6.0 0.0 0.0) (40 . 5.0)))))
                                 (vlax-invoke iw-c 'IntersectWith iw-r6 acExtendOtherEntity)"
                            dialect))))
    (is (%iw-near '(3d0 -4d0 0d0 3d0 4d0 0d0) (%in-dialect "autocad")))
    (is (%iw-near '(3d0 4d0 0d0 3d0 -4d0 0d0) (%in-dialect "bricscad")))
    (is (%iw-near '(3d0 -4d0 0d0 3d0 4d0 0d0) (%in-dialect "strict")))))

(test vlax-invoke-intersectwith-returns-a-plain-list-or-nil
  (is (%iw-near '(5d0 5d0 0d0) (%iw-run "(vlax-invoke iw-a 'IntersectWith iw-b acExtendNone)")))
  (is (%iw-near '(5d0 0d0 0d0 -5d0 0d0 0d0)
                (%iw-run "(vlax-invoke iw-in 'IntersectWith iw-c acExtendBoth)")))
  (is (null (%iw-run "(vlax-invoke iw-in 'IntersectWith iw-c acExtendNone)")))
  (is (null (%iw-run "(vlax-invoke iw-a 'IntersectWith iw-far 0)")))
  ;; extended, the far line and the diagonal meet at (-2.2222..., -2.2222...)
  (is (%iw-near (list (/ -20d0 9) (/ -20d0 9) 0d0)
                (%iw-run "(vlax-invoke iw-a 'IntersectWith iw-far acExtendBoth)"))))

(test vlax-invoke-method-intersectwith-and-applicability
  (is (%iw-near '(5d0 5d0 0d0)
                (%iw-run "(vlax-safearray->list
                           (vlax-variant-value
                            (vlax-invoke-method iw-a \"IntersectWith\" iw-b 0)))")))
  (is (%iw-run "(vlax-method-applicable-p iw-a 'IntersectWith)")))

(test intersectwith-unsupported-geometry-is-a-catchable-error
  (let ((message (%iw-run "(setq iw-p (vlax-ename->vla-object
                                        (entmakex '((0 . \"POINT\") (10 0.0 0.0 0.0)))))
                           (vl-catch-all-error-message
                            (vl-catch-all-apply 'vlax-invoke (list iw-a 'IntersectWith iw-p 0)))")))
    (is (search "IntersectWith" (autolisp-string-value message)))
    (is (search "AcDbPoint" (autolisp-string-value message)))))

(test vlax-variant-type-returns-the-vb-type-code
  ;; spec: "Integer type code" (vlax-variant-type-returns-a-symbol); it
  ;; used to return the symbols ARRAY / INTEGER / REAL. Literal codes: the
  ;; vlax-vb* constants are not bound yet (vlax-vb-constants-unbound).
  (is (equal '(8197 3 5 8 2 5 8197)
             (%vla "(vl-load-com)
                    (list (vlax-variant-type (vlax-3d-point 1 2 3))
                          (vlax-variant-type (vlax-make-variant 42))
                          (vlax-variant-type (vlax-make-variant 1.5))
                          (vlax-variant-type (vlax-make-variant \"s\"))
                          (vlax-variant-type (vlax-make-variant 42 2))
                          (vlax-safearray-type (vlax-make-safearray 5 '(0 . 1)))
                          (vlax-variant-type
                           (vlax-make-variant (vlax-make-safearray 5 '(0 . 1)))))"))))
