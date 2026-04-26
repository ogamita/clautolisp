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

;;; AutoLISP is a Lisp-1 dialect: a symbol carries a single binding
;;; cell that is shared by variable and function uses. SETQ and DEFUN
;;; both write to that single cell; the most recent write wins.
;;;
;;; The runtime models that with a single `binding-cell` struct per
;;; symbol per namespace. The optional `compatibility-definition`
;;; slot is the side-channel DEFUN-Q stores a list-form copy of the
;;; function in (only DEFUN-Q populates it; ordinary SETQ and DEFUN
;;; clear it). See autolisp-spec, chapter 7, "Single-Cell Symbol
;;; Binding (Lisp-1)" for the normative rule and its vendor evidence.

(defstruct binding-cell
  (value nil)
  (bound-p nil :type boolean)
  (compatibility-definition nil :type list))

(defstruct document-namespace
  (name "DOCUMENT" :type string)
  (bindings (make-hash-table :test #'eq)))

(defstruct blackboard-namespace
  (name "BLACKBOARD" :type string)
  (bindings (make-hash-table :test #'eq)))

(defstruct separate-vlx-namespace
  (name "VLX" :type string)
  (bindings (make-hash-table :test #'eq)))

(defstruct dynamic-binding
  symbol
  (value nil)
  (bound-p nil :type boolean))

(defstruct dynamic-frame
  (bindings (make-hash-table :test #'eq))
  parent)

(defstruct runtime-session
  (document-namespaces (make-hash-table :test #'equal))
  (separate-vlx-namespaces (make-hash-table :test #'equal))
  (exported-functions (make-hash-table :test #'equal))
  (blackboard-namespace (make-blackboard-namespace))
  (propagated-symbols (make-hash-table :test #'eq))
  (errno 0 :type integer)
  current-document
  ;; Phase 6: every runtime session carries the dialect descriptor
  ;; that drove its instantiation. Builtins that have product-divergent
  ;; lex / mode behaviour (currently `atof` hex-float, `open` `ccs=`)
  ;; consult the active session's dialect.
  (dialect nil))

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
(defparameter *active-evaluation-context* nil)

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

(defstruct autolisp-catch-all-error
  (message "" :type string)
  condition)

(defstruct autolisp-variant
  value)

(defstruct autolisp-safearray
  value)

(defstruct autolisp-vla-object
  value)
