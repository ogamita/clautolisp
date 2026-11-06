(in-package #:clautolisp.debug.ui)

;;;; Per-module print IO-syntax (TUI module spec §13). The debugger modules
;;;; (stack browser, inspector, aldo, repl) each print AutoLISP objects with
;;;; their own printer settings — e.g. the stack browser prints arguments with a
;;;; short *print-length* / *print-level*, while the REPL prints results in
;;;; full. AutoLISP princ/prin1/print themselves have fixed syntax (per the
;;;; AutoLISP spec), so the modules use a parameterised CLAL-PRINC / CLAL-PRIN1 /
;;;; CLAL-PRINT that bind the CL printer variables from a set of *CLAL-PRINT-*
;;;; specials. Each module has its own *CLAL-<module>-PRINT-* set (with its own
;;;; defaults, user-customisable) and a WITH-<module>-PRINT-SYNTAX macro that
;;;; binds the base set from it.

;;; The base binding variables (bound by the WITH-…-PRINT-SYNTAX macros) and
;;; their default values (used when no module wraps the call).
(defparameter *clal-print-array*  t)
(defparameter *clal-print-case*   :upcase)
(defparameter *clal-print-circle* nil)
(defparameter *clal-print-length* nil)
(defparameter *clal-print-level*  nil)
(defparameter *clal-print-lines*  nil)

(defun call-with-clal-print-syntax (thunk)
  "Call THUNK with the CL printer variables bound from the *CLAL-PRINT-* set."
  (let ((*print-array*   *clal-print-array*)
        (*print-case*    *clal-print-case*)
        (*print-circle*  *clal-print-circle*)
        (*print-length*  *clal-print-length*)
        (*print-level*   *clal-print-level*)
        (*print-lines*   *clal-print-lines*)
        (*print-readably* nil))
    (funcall thunk)))

(defun clal-princ (object &optional (stream *standard-output*))
  "PRINC an AutoLISP OBJECT under the current *CLAL-PRINT-* syntax."
  (call-with-clal-print-syntax
   (lambda () (let ((*print-escape* nil)) (princ object stream))))
  object)

(defun clal-prin1 (object &optional (stream *standard-output*))
  "PRIN1 an AutoLISP OBJECT under the current *CLAL-PRINT-* syntax."
  (call-with-clal-print-syntax
   (lambda () (let ((*print-escape* t)) (prin1 object stream))))
  object)

(defun clal-print (object &optional (stream *standard-output*))
  "PRINT an AutoLISP OBJECT (fresh line + trailing space) under the current
*CLAL-PRINT-* syntax."
  (call-with-clal-print-syntax
   (lambda () (let ((*print-escape* t)) (print object stream))))
  object)

(defun clal-prin1-to-string (object)
  "OBJECT PRIN1'd to a string under the current *CLAL-PRINT-* syntax."
  (with-output-to-string (s) (clal-prin1 object s)))

(defun clal-princ-to-string (object)
  "OBJECT PRINC'd to a string under the current *CLAL-PRINT-* syntax."
  (with-output-to-string (s) (clal-princ object s)))

;;; --- per-module syntax sets -------------------------------------------

(defmacro define-clal-print-module (name &key array case circle length level lines)
  "Define the *CLAL-<NAME>-PRINT-* specials (with the given defaults) and a
WITH-<NAME>-PRINT-SYNTAX macro that binds the base *CLAL-PRINT-* set from them."
  (let* ((n   (string-upcase (string name)))
         (a   (intern (format nil "*CLAL-~A-PRINT-ARRAY*"  n)))
         (c   (intern (format nil "*CLAL-~A-PRINT-CASE*"   n)))
         (ci  (intern (format nil "*CLAL-~A-PRINT-CIRCLE*" n)))
         (l   (intern (format nil "*CLAL-~A-PRINT-LENGTH*" n)))
         (lv  (intern (format nil "*CLAL-~A-PRINT-LEVEL*"  n)))
         (li  (intern (format nil "*CLAL-~A-PRINT-LINES*"  n)))
         (with (intern (format nil "WITH-~A-PRINT-SYNTAX"  n))))
    `(progn
       (defparameter ,a  ,array)
       (defparameter ,c  ,case)
       (defparameter ,ci ,circle)
       (defparameter ,l  ,length)
       (defparameter ,lv ,level)
       (defparameter ,li ,lines)
       (defmacro ,with (&body body)
         `(let ((*clal-print-array*  ,',a)  (*clal-print-case*   ,',c)
                (*clal-print-circle* ,',ci) (*clal-print-length* ,',l)
                (*clal-print-level*  ,',lv) (*clal-print-lines*  ,',li))
            ,@body))
       ',name)))

;; The four module syntax sets and their defaults (spec §13 tables).
(define-clal-print-module stack   :array t :case :upcase :circle t :length 3   :level 2   :lines 1)
(define-clal-print-module inspect :array t :case :upcase :circle t :length 3   :level 2   :lines 1)
(define-clal-print-module aldo    :array t :case :upcase :circle t :length 3   :level 2   :lines 1)
(define-clal-print-module repl    :array t :case :upcase :circle t :length nil :level nil :lines nil)
