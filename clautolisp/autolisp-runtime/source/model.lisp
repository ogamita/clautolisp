(in-package #:clautolisp.autolisp-runtime.internal)

(defparameter *autolisp-symbol-table* (make-hash-table :test #'equal))
(defparameter *autolisp-current-directory*
  (namestring (uiop:ensure-directory-pathname (truename "."))))
(defparameter *autolisp-support-paths* (list *autolisp-current-directory*))
(defparameter *autolisp-trusted-paths* '())

(defstruct autolisp-symbol
  (name "" :type string)
  (original-name nil :type (or null string))
  (plist '() :type list))

(defstruct value-cell
  (value nil)
  (bound-p nil :type boolean))

(defstruct function-cell
  (function nil)
  (bound-p nil :type boolean)
  (compatibility-definition nil :type list))

(defstruct document-namespace
  (name "DOCUMENT" :type string)
  (value-cells (make-hash-table :test #'eq))
  (function-cells (make-hash-table :test #'eq)))

(defstruct blackboard-namespace
  (name "BLACKBOARD" :type string)
  (value-cells (make-hash-table :test #'eq)))

(defstruct separate-vlx-namespace
  (name "VLX" :type string)
  (value-cells (make-hash-table :test #'eq))
  (function-cells (make-hash-table :test #'eq)))

(defstruct dynamic-binding
  symbol
  (value nil)
  (bound-p nil :type boolean))

(defstruct dynamic-frame
  (bindings (make-hash-table :test #'eq))
  parent)

(defstruct runtime-session
  (document-namespaces (make-hash-table :test #'equal))
  (blackboard-namespace (make-blackboard-namespace))
  (propagated-symbols (make-hash-table :test #'eq))
  current-document)

(defstruct evaluation-context
  session
  current-document
  current-namespace
  dynamic-frame)

(defparameter *default-document-namespace*
  (make-document-namespace :name "DEFAULT"))
(defparameter *default-runtime-session*
  (make-runtime-session :current-document *default-document-namespace*))
(defparameter *default-evaluation-context*
  (make-evaluation-context
   :session *default-runtime-session*
   :current-document *default-document-namespace*
   :current-namespace *default-document-namespace*
   :dynamic-frame nil))

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
