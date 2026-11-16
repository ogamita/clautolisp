(in-package #:clautolisp.cador.tests)

(in-suite cador-suite)

;;; SETVAR validation as AutoCAD and BricsCAD measure it
;;; (setvar-validation-as-measured; sunset campaign B4 probe-setvar-edges.lsp
;;; and B5 probe-sysvar-flags.lsp). Each case states the measured
;;; (RESULT STORED ERRNO) of the product.

(defun %sv (mock name value)
  "(RESULT STORED ERRNO) of (setvar NAME VALUE) on MOCK -- RESULT :ERROR for a
refusal, ERRNO the one the error leaves (0 when it succeeds) -- the stored
value read back."
  (let* ((al-name (clautolisp.autolisp-runtime:make-autolisp-string name))
         (result (handler-case (host-setvar mock al-name value)
                   (clautolisp.autolisp-runtime:autolisp-runtime-error (c)
                     (list :error (clautolisp.autolisp-runtime:autolisp-runtime-error-errno c))))))
    (if (and (consp result) (eq (first result) :error))
        (list :error (host-getvar mock al-name) (second result))
        (list result (host-getvar mock al-name) 0))))

(defun %sv-plain (mock name value)
  "%SV with a string STORED shown as a CL string."
  (destructuring-bind (result stored errno) (%sv mock name value)
    (list result
          (if (typep stored 'clautolisp.autolisp-runtime:autolisp-string)
              (clautolisp.autolisp-runtime:autolisp-string-value stored)
              stored)
          errno)))

(test setvar-refuses-out-of-range-with-the-products-errno
  (let ((mock (make-cador)))
    (%with-dialect (:autocad-2022)
      (is (equal '(:error 1 22) (%sv mock "CMDECHO" 2)))
      (is (equal '(:error 2 22) (%sv mock "LUNITS" 7)))
      (is (eql 22 (third (%sv mock "OSMODE" -1))))
      (is (eql 22 (third (%sv mock "OSMODE" 70000))))
      (is (eql 22 (third (%sv mock "USERI1" 40000)))))
    (%with-dialect (:bricscad-v26)
      (is (equal '(:error 1 0) (%sv mock "CMDECHO" 2)))
      (is (equal '(:error 2 0) (%sv mock "LUNITS" 7)))
      (is (eql 0 (third (%sv mock "OSMODE" -1))))
      ;; BricsCAD wraps to 16 bits first, then the range applies
      (is (equal '(70000 4464 0) (%sv mock "OSMODE" 70000)))
      (is (equal '(-40000 25536 0) (%sv mock "OSMODE" -40000)))
      (is (equal '(40000 -25536 0) (%sv mock "USERI1" 40000))))))

(test setvar-returns-the-value-given
  (let ((mock (make-cador)))
    (dolist (dialect '(:autocad-2022 :bricscad-v26))
      (%with-dialect (dialect)
        (is (equal '(1.0d0 1 0) (%sv mock "CMDECHO" 1.0d0)))
        (is (equal '(2 2.0d0 0) (%sv mock "USERR1" 2)))
        (is (equal '(3.0d0 3 0) (%sv mock "OSMODE" 3.0d0)))))))

(test setvar-type-errors-leave-the-products-errno
  (let ((mock (make-cador)))
    (%with-dialect (:autocad-2022)
      ;; a fraction into an integer: refused, 87
      (is (equal '(:error 1 87) (%sv mock "CMDECHO" 0.7d0)))
      (is (eql 87 (third (%sv mock "CMDECHO" (clautolisp.autolisp-runtime:make-autolisp-string "1")))))
      (is (eql 87 (third (%sv mock "CMDECHO" nil))))
      ;; a number into a string variable: refused, 0
      (is (eql 0 (third (%sv mock "USERS1" 5))))
      ;; a 3D point into the 2D SNAPBASE: refused, 0
      (is (eq :error (first (%sv mock "SNAPBASE" '(1.0d0 2.0d0 3.0d0))))))
    (%with-dialect (:bricscad-v26)
      ;; a fraction is truncated
      (is (equal '(0.7d0 0 0) (%sv mock "CMDECHO" 0.7d0)))
      (is (eql 0 (third (%sv mock "CMDECHO" nil))))
      ;; the 2D part of a 3D point is kept
      (destructuring-bind (result stored errno) (%sv mock "SNAPBASE" '(1.0d0 2.0d0 3.0d0))
        (is (equal '(1.0d0 2.0d0 3.0d0) result))
        (is (equal '(1.0d0 2.0d0) stored))
        (is (eql 0 errno))))))

(test setvar-read-only-and-unknown-names
  (let ((mock (make-cador)))
    (dolist (dialect '(:autocad-2022 :bricscad-v26))
      (%with-dialect (dialect)
        (is (eql 20 (third (%sv mock "DWGNAME" (clautolisp.autolisp-runtime:make-autolisp-string "x.dwg")))))
        (is (eql 0 (third (%sv mock "NOSUCHVAR" 1))))))))

(test setvar-accepts-a-symbol-name
  (let ((mock (make-cador)))
    (host-setvar mock (clautolisp.autolisp-runtime:intern-autolisp-symbol "OSMODE") 1)
    (is (eql 1 (host-getvar mock (clautolisp.autolisp-runtime:make-autolisp-string "OSMODE"))))))

(test setvar-measured-range-widening
  "B5 measured DIMALTZ accepting 13 on AutoCAD, above its documented 0-12."
  (let ((mock (make-cador)))
    (%with-dialect (:autocad-2022)
      (is (equal '(13 13 0) (%sv mock "DIMALTZ" 13)))
      (is (eql 22 (third (%sv mock "DIMALTZ" -1)))))))
