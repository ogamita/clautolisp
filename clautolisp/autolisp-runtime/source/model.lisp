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
  (bindings (make-hash-table :test #'eq))
  ;; Phase 14a: lifecycle state per the host-object ontology.
  ;; (:loading -> :loaded <-> :active <-> :inactive -> :closing -> :closed,
  ;;  with a transient :saving substate during write).
  (state :loaded :type keyword)
  ;; Per-document reactor registry. Hash-table from reactor-id to
  ;; reactor struct. Phase 14b populates entries via the vlr-* family;
  ;; Phase 14a leaves the table empty but reachable.
  (reactors (make-hash-table :test #'eq))
  ;; Per-document persistent-reactor symbol-name index. Maps a
  ;; reactor-id to a property list (:type :callbacks :data :owners)
  ;; suitable for serialisation / round-trip via
  ;; mock-host-snapshot. Maintained by vlr-pers / vlr-pers-release.
  (persistent-reactor-index (make-hash-table :test #'eq))
  ;; Phase 14a back-pointer: the runtime-session that owns this
  ;; document. Set by make-runtime-session and preserved across
  ;; register-runtime-session-document. Lets signal-document-event
  ;; locate the session reliably without scanning the active
  ;; evaluation context.
  (session nil))

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
  (dialect nil)
  ;; Phase 8: every runtime session also carries a HAL backend
  ;; (`host`) that decides where CAD-host effects land. Defaults to
  ;; nil when the session is created from the runtime alone; the
  ;; autolisp-host module installs a NullHost singleton via the
  ;; *default-runtime-host* parameter once its package is loaded.
  ;; Higher-level callers (the CLI, the file-compat harness, etc.)
  ;; can pass any object satisfying the HAL contract.
  (host nil)
  ;; Phase 14a: host-object ontology. The runtime models the
  ;; application as a single-state-machine value and the
  ;; document-manager implicitly via the document-namespaces table.
  ;; Lifecycle: :running -> :quitting -> :quit. Application-scoped
  ;; reactors live here (vlr-docmanager / vlr-editor / vlr-linker /
  ;; vlr-lisp / vlr-miscellaneous).
  (application-state :running :type keyword)
  (application-reactors (make-hash-table :test #'eq))
  ;; Optional per-session debug listener for tests. When non-nil,
  ;; signal-document-event / signal-application-event push their
  ;; argument tuples onto this list (newest first). Tests inspect
  ;; the list, then clear it. Production callers leave it nil.
  (event-trace nil))

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
