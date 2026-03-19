(in-package #:clautolisp.autolisp-runtime.internal)

(defparameter *autolisp-symbol-table* (make-hash-table :test #'equal))

(defstruct autolisp-symbol
  (name "" :type string)
  (original-name nil :type (or null string))
  (value nil)
  (value-bound-p nil :type boolean)
  (function nil)
  (function-bound-p nil :type boolean)
  (plist '() :type list))

(defstruct autolisp-string
  (value "" :type string))

(defstruct autolisp-file
  stream
  (path nil)
  (mode nil))

(defstruct autolisp-ename
  value)

(defstruct autolisp-pickset
  value)

(defstruct autolisp-subr
  (name "" :type string)
  function)

(defstruct autolisp-usubr
  (name "" :type string)
  (lambda-list '() :type list)
  (body '() :type list)
  environment)

(defstruct autolisp-variant
  value)

(defstruct autolisp-safearray
  value)

(defstruct autolisp-vla-object
  value)
