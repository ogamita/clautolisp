(in-package #:clautolisp.autolisp-runtime)

(deftype autolisp-symbol ()
  'clautolisp.autolisp-runtime.internal::autolisp-symbol)

(deftype binding-cell ()
  'clautolisp.autolisp-runtime.internal::binding-cell)

;; Backwards-compatible alias types — AutoLISP is Lisp-1 (chapter 7
;; of autolisp-spec), so a "value cell" and a "function cell" are the
;; same single per-symbol cell. Old call sites that still distinguish
;; the roles continue to compile.
(deftype value-cell () 'binding-cell)
(deftype function-cell () 'binding-cell)

(deftype document-namespace ()
  'clautolisp.autolisp-runtime.internal::document-namespace)

(deftype blackboard-namespace ()
  'clautolisp.autolisp-runtime.internal::blackboard-namespace)

(deftype separate-vlx-namespace ()
  'clautolisp.autolisp-runtime.internal::separate-vlx-namespace)

(deftype dynamic-frame ()
  'clautolisp.autolisp-runtime.internal::dynamic-frame)

(deftype evaluation-context ()
  'clautolisp.autolisp-runtime.internal::evaluation-context)

(deftype runtime-session ()
  'clautolisp.autolisp-runtime.internal::runtime-session)

(deftype autolisp-string ()
  'clautolisp.autolisp-runtime.internal::autolisp-string)

(deftype autolisp-file ()
  'clautolisp.autolisp-runtime.internal::autolisp-file)

(deftype autolisp-ename ()
  'clautolisp.autolisp-runtime.internal::autolisp-ename)

(deftype autolisp-pickset ()
  'clautolisp.autolisp-runtime.internal::autolisp-pickset)

(deftype autolisp-subr ()
  'clautolisp.autolisp-runtime.internal::autolisp-subr)

(deftype autolisp-usubr ()
  'clautolisp.autolisp-runtime.internal::autolisp-usubr)

(deftype autolisp-catch-all-error ()
  'clautolisp.autolisp-runtime.internal::autolisp-catch-all-error)

(deftype autolisp-variant ()
  'clautolisp.autolisp-runtime.internal::autolisp-variant)

(deftype autolisp-safearray ()
  'clautolisp.autolisp-runtime.internal::autolisp-safearray)

(deftype autolisp-vla-object ()
  'clautolisp.autolisp-runtime.internal::autolisp-vla-object)

(define-condition autolisp-runtime-error (error)
  ((code
    :initarg :code
    :reader autolisp-runtime-error-code)
   (message
    :initarg :message
    :reader autolisp-runtime-error-message)
   (details
    :initarg :details
    :initform nil
    :reader autolisp-runtime-error-details))
  (:report (lambda (condition stream)
             (format stream "~A" (autolisp-runtime-error-message condition)))))

(define-condition autolisp-termination (serious-condition)
  ((kind
    :initarg :kind
    :reader autolisp-termination-kind))
  (:report (lambda (condition stream)
             (format stream "AutoLISP termination requested: ~A"
                     (autolisp-termination-kind condition)))))

(define-condition autolisp-namespace-exit (serious-condition)
  ((kind
    :initarg :kind
    :reader autolisp-namespace-exit-kind)
   (value
    :initarg :value
    :reader autolisp-namespace-exit-value))
  (:report (lambda (condition stream)
             (format stream "AutoLISP namespace exit ~A: ~S"
                     (autolisp-namespace-exit-kind condition)
                     (autolisp-namespace-exit-value condition)))))

(defun signal-autolisp-runtime-error (code control-string &rest arguments)
  (error 'autolisp-runtime-error
         :code code
         :message (apply #'format nil control-string arguments)
         :details arguments))

(defun reset-autolisp-symbol-table ()
  (clrhash clautolisp.autolisp-runtime.internal::*autolisp-symbol-table*)
  (reset-default-evaluation-context))

(defun default-evaluation-context ()
  clautolisp.autolisp-runtime.internal::*default-evaluation-context*)

(defun current-evaluation-context ()
  (or clautolisp.autolisp-runtime.internal::*active-evaluation-context*
      (default-evaluation-context)))

(defun set-default-evaluation-context (context)
  (setf clautolisp.autolisp-runtime.internal::*default-evaluation-context* context))

(defun reset-default-evaluation-context ()
  (let* ((document (clautolisp.autolisp-runtime.internal::make-document-namespace
                    :name "DEFAULT"))
         (session (clautolisp.autolisp-runtime.internal::make-runtime-session
                   :current-document document))
         (context (clautolisp.autolisp-runtime.internal::make-evaluation-context
                   :session session
                   :current-document document
                   :current-namespace document
                   :dynamic-frame nil)))
    (setf clautolisp.autolisp-runtime.internal::*default-document-namespace* document
          clautolisp.autolisp-runtime.internal::*default-runtime-session* session
          clautolisp.autolisp-runtime.internal::*default-evaluation-context* context)
    context))

(defun normalize-directory-path (path)
  (namestring (uiop:ensure-directory-pathname (pathname path))))

(defun autolisp-current-directory ()
  clautolisp.autolisp-runtime.internal::*autolisp-current-directory*)

(defun set-autolisp-current-directory (path)
  (setf clautolisp.autolisp-runtime.internal::*autolisp-current-directory*
        (normalize-directory-path path)))

(defun autolisp-support-paths ()
  (copy-list clautolisp.autolisp-runtime.internal::*autolisp-support-paths*))

(defun set-autolisp-support-paths (paths)
  (setf clautolisp.autolisp-runtime.internal::*autolisp-support-paths*
        (mapcar #'normalize-directory-path paths)))

(defun autolisp-trusted-paths ()
  (copy-list clautolisp.autolisp-runtime.internal::*autolisp-trusted-paths*))

(defun set-autolisp-trusted-paths (paths)
  (setf clautolisp.autolisp-runtime.internal::*autolisp-trusted-paths*
        (mapcar #'normalize-directory-path paths)))

(defun find-autolisp-symbol (name)
  (gethash name clautolisp.autolisp-runtime.internal::*autolisp-symbol-table*))

(defun intern-autolisp-symbol (name &key original-name)
  (or (find-autolisp-symbol name)
      (setf (gethash name clautolisp.autolisp-runtime.internal::*autolisp-symbol-table*)
            (clautolisp.autolisp-runtime.internal::make-autolisp-symbol
             :name name
             :original-name original-name))))

(defun make-document-namespace (&key (name "DOCUMENT"))
  (clautolisp.autolisp-runtime.internal::make-document-namespace :name name))

(defun document-namespace-name (namespace)
  (clautolisp.autolisp-runtime.internal::document-namespace-name namespace))

(defun make-blackboard-namespace (&key (name "BLACKBOARD"))
  (clautolisp.autolisp-runtime.internal::make-blackboard-namespace :name name))

(defun blackboard-namespace-name (namespace)
  (clautolisp.autolisp-runtime.internal::blackboard-namespace-name namespace))

(defun make-separate-vlx-namespace (&key (name "VLX"))
  (clautolisp.autolisp-runtime.internal::make-separate-vlx-namespace :name name))

(defun separate-vlx-namespace-name (namespace)
  (clautolisp.autolisp-runtime.internal::separate-vlx-namespace-name namespace))

(defparameter *default-runtime-host* nil
  "Process-wide fallback host backend for fresh runtime sessions.
The autolisp-host module installs the NullHost singleton here when
loaded; downstream callers (the CLI, MockHost-aware tests, etc.)
may rebind it to switch the default backend. Sessions whose `:host`
keyword argument is not supplied inherit this value.")

(defun make-runtime-session (&key current-document dialect host)
  (let* ((document (or current-document
                       (make-document-namespace :name "DOCUMENT")))
         (chosen-dialect
          (or dialect
              (clautolisp.autolisp-reader:autolisp-dialect-strict)))
         (chosen-host (or host *default-runtime-host*)))
    (let ((session (clautolisp.autolisp-runtime.internal::make-runtime-session
                    :current-document document
                    :dialect chosen-dialect
                    :host chosen-host)))
      (setf (gethash (document-namespace-name document)
                     (clautolisp.autolisp-runtime.internal::runtime-session-document-namespaces
                      session))
            document)
      ;; Phase 14a back-pointer for event-channel resolution.
      (setf (clautolisp.autolisp-runtime.internal::document-namespace-session
             document)
            session)
      session)))

(defun runtime-session-host (session)
  "Return the HAL backend SESSION was instantiated with, or
*default-runtime-host* if the session's slot is nil."
  (or (clautolisp.autolisp-runtime.internal::runtime-session-host session)
      *default-runtime-host*))

(defun set-runtime-session-host (session host)
  "Replace SESSION's HAL backend. Used by tools that swap the
backend mid-session (e.g. switching from MockHost to LiveHost
within a single run)."
  (setf (clautolisp.autolisp-runtime.internal::runtime-session-host session)
        host))

(defun current-evaluation-host (&optional (context (current-evaluation-context)))
  "Return the active HAL backend for CONTEXT, falling back to
*default-runtime-host* when no session is in scope."
  (or (and context
           (clautolisp.autolisp-runtime.internal::evaluation-context-session context)
           (runtime-session-host
            (clautolisp.autolisp-runtime.internal::evaluation-context-session context)))
      *default-runtime-host*))

(defun runtime-session-dialect (session)
  "Return the dialect descriptor SESSION was instantiated with."
  (clautolisp.autolisp-runtime.internal::runtime-session-dialect session))

(defun set-runtime-session-dialect (session dialect)
  "Replace SESSION's dialect descriptor. Useful for tools that switch
profiles between subordinate evaluations within a single session."
  (setf (clautolisp.autolisp-runtime.internal::runtime-session-dialect session)
        dialect))

(defun current-evaluation-dialect (&optional (context (current-evaluation-context)))
  "Return the dialect of CONTEXT's session, or the strict default."
  (or (and context
           (clautolisp.autolisp-runtime.internal::evaluation-context-session context)
           (clautolisp.autolisp-runtime.internal::runtime-session-dialect
            (clautolisp.autolisp-runtime.internal::evaluation-context-session context)))
      (clautolisp.autolisp-reader:autolisp-dialect-strict)))

(defun runtime-session-current-document (session)
  (clautolisp.autolisp-runtime.internal::runtime-session-current-document session))

(defun runtime-session-blackboard-namespace (session)
  (clautolisp.autolisp-runtime.internal::runtime-session-blackboard-namespace session))

(defun runtime-session-errno (session)
  (clautolisp.autolisp-runtime.internal::runtime-session-errno session))

(defun find-runtime-session-document (session name)
  (gethash name
           (clautolisp.autolisp-runtime.internal::runtime-session-document-namespaces
            session)))

(defun find-runtime-session-vlx-namespace (session name)
  (gethash name
           (clautolisp.autolisp-runtime.internal::runtime-session-separate-vlx-namespaces
            session)))

(defun copy-value-cell-between-namespaces (source target symbol)
  (let ((source-cell (namespace-binding-cell source symbol :createp nil)))
    (when (and source-cell (binding-cell-bound-p source-cell))
      (let ((target-cell (namespace-binding-cell target symbol)))
        (setf (clautolisp.autolisp-runtime.internal::binding-cell-value target-cell)
              (binding-cell-value source-cell)
              (clautolisp.autolisp-runtime.internal::binding-cell-bound-p target-cell)
              t)))))

(defun register-runtime-session-document (session document &key (copy-propagated-p t))
  (unless (typep document 'document-namespace)
    (signal-autolisp-runtime-error
     :invalid-document
     "Expected a document namespace, got ~S."
     document))
  (setf (gethash (document-namespace-name document)
                 (clautolisp.autolisp-runtime.internal::runtime-session-document-namespaces
                  session))
        document)
  (when copy-propagated-p
    (maphash (lambda (symbol marker)
               (declare (ignore marker))
               (copy-value-cell-between-namespaces
                (runtime-session-current-document session)
                document
                symbol))
             (clautolisp.autolisp-runtime.internal::runtime-session-propagated-symbols
              session)))
  document)

(defun register-runtime-session-vlx-namespace (session namespace)
  (unless (typep namespace 'separate-vlx-namespace)
    (signal-autolisp-runtime-error
     :invalid-namespace
     "Expected a separate VLX namespace, got ~S."
     namespace))
  (setf (gethash (separate-vlx-namespace-name namespace)
                 (clautolisp.autolisp-runtime.internal::runtime-session-separate-vlx-namespaces
                  session))
        namespace)
  namespace)

(defun set-runtime-session-current-document (session document)
  (unless (typep document 'document-namespace)
    (signal-autolisp-runtime-error
     :invalid-document
     "Expected a document namespace, got ~S."
     document))
  (register-runtime-session-document session document :copy-propagated-p t)
  (setf (clautolisp.autolisp-runtime.internal::runtime-session-current-document session)
        document))

(defun autolisp-errno (&optional (context (current-evaluation-context)))
  (runtime-session-errno (evaluation-context-session context)))

(defun set-autolisp-errno (value &optional (context (current-evaluation-context)))
  (setf (clautolisp.autolisp-runtime.internal::runtime-session-errno
         (evaluation-context-session context))
        value))

(defun autolisp-runtime-error-errno (condition)
  (let ((code (autolisp-runtime-error-code condition)))
    (cond
      ((eq code :unbound-variable)
       2)
      ((eq code :undefined-function)
       3)
      ((or (eq code :builtin-file-error)
           (eq code :load-file-not-found)
           (eq code :unsupported-load-file-type)
           (eq code :autoload-definition-missing)
           (eq code :invalid-open-mode)
           (eq code :invalid-external-format)
           (eq code :invalid-file-argument)
           (eq code :invalid-directory-argument)
           (eq code :invalid-directory-selector)
           (eq code :closed-file-descriptor))
       5)
      ((or (eq code :host-error)
           (eq code :subr-call-host-error)
           (eq code :builtin-error))
       6)
      ((or (eq code :wrong-number-of-arguments)
           (eq code :unsupported-special-operator)
           (eq code :invalid-form)
           (eq code :invalid-call-operator)
           (eq code :invalid-function-designator)
           (eq code :invalid-function-object)
           (eq code :invalid-setq-arguments)
           (eq code :invalid-setq-place)
           (eq code :invalid-cond-clause)
           (eq code :invalid-repeat-count)
           (eq code :invalid-foreach-binding)
           (eq code :invalid-foreach-sequence)
           (eq code :invalid-lambda-list)
           (eq code :invalid-defun-name)
           (eq code :invalid-defun-q-definition)
           (eq code :invalid-document)
           (eq code :invalid-namespace)
           (eq code :type-error)
           (let ((name (string code)))
             (and (<= 8 (length name))
                  (string= "INVALID-" name :end2 8))))
       4)
      (t
       1))))

(defun make-evaluation-context (&key session current-document current-namespace dynamic-frame)
  (let* ((session (or session
                      (make-runtime-session :current-document current-document)))
         (current-document (or current-document
                               (runtime-session-current-document session)))
         (current-namespace (or current-namespace current-document))
         (dynamic-frame (or dynamic-frame nil)))
    (unless (typep current-document 'document-namespace)
      (signal-autolisp-runtime-error
       :invalid-document
       "Evaluation context current document must be a document namespace, got ~S."
       current-document))
    (unless (or (typep current-namespace 'document-namespace)
                (typep current-namespace 'separate-vlx-namespace))
      (signal-autolisp-runtime-error
       :invalid-namespace
       "Evaluation context current namespace must be a document or separate VLX namespace, got ~S."
       current-namespace))
    (clautolisp.autolisp-runtime.internal::make-evaluation-context
     :session session
     :current-document current-document
     :current-namespace current-namespace
     :dynamic-frame dynamic-frame)))

(defun evaluation-context-session (context)
  (clautolisp.autolisp-runtime.internal::evaluation-context-session context))

(defun evaluation-context-current-document (context)
  (clautolisp.autolisp-runtime.internal::evaluation-context-current-document context))

(defun evaluation-context-current-namespace (context)
  (clautolisp.autolisp-runtime.internal::evaluation-context-current-namespace context))

(defun evaluation-context-dynamic-frame (context)
  (clautolisp.autolisp-runtime.internal::evaluation-context-dynamic-frame context))

(defun enter-document-context (session document &key namespace)
  (set-runtime-session-current-document session document)
  (make-evaluation-context
   :session session
   :current-document document
   :current-namespace (or namespace document)
   :dynamic-frame nil))

(defun binding-cell-value (cell)
  (clautolisp.autolisp-runtime.internal::binding-cell-value cell))

(defun binding-cell-bound-p (cell)
  (clautolisp.autolisp-runtime.internal::binding-cell-bound-p cell))

(defun binding-cell-compatibility-definition (cell)
  (clautolisp.autolisp-runtime.internal::binding-cell-compatibility-definition cell))

;; Lisp-1 single-cell rule (autolisp-spec, chapter 7): the legacy
;; "value cell" and "function cell" accessors are facades over the
;; same per-symbol binding cell. Existing callers compile unchanged;
;; new code should prefer `binding-cell-*`.
(defun value-cell-value (cell) (binding-cell-value cell))
(defun value-cell-bound-p (cell) (binding-cell-bound-p cell))
(defun function-cell-function (cell) (binding-cell-value cell))
(defun function-cell-bound-p (cell) (binding-cell-bound-p cell))
(defun function-cell-compatibility-definition (cell)
  (binding-cell-compatibility-definition cell))

(defun namespace-bindings-table (namespace)
  (typecase namespace
    (document-namespace
     (clautolisp.autolisp-runtime.internal::document-namespace-bindings namespace))
    (blackboard-namespace
     (clautolisp.autolisp-runtime.internal::blackboard-namespace-bindings namespace))
    (separate-vlx-namespace
     (clautolisp.autolisp-runtime.internal::separate-vlx-namespace-bindings namespace))
    (t
     (signal-autolisp-runtime-error
      :invalid-namespace
      "Namespace ~S does not support symbol bindings."
      namespace))))

;; Backwards-compat aliases — both used to point at separate tables
;; under the Lisp-2 model; under the unified Lisp-1 model they all
;; route to the single binding table.
(defun namespace-value-table (namespace) (namespace-bindings-table namespace))
(defun namespace-function-table (namespace) (namespace-bindings-table namespace))

(defun namespace-binding-cell (namespace symbol &key (createp t))
  (or (gethash symbol (namespace-bindings-table namespace))
      (when createp
        (setf (gethash symbol (namespace-bindings-table namespace))
              (clautolisp.autolisp-runtime.internal::make-binding-cell)))))

(defun namespace-value-cell (namespace symbol &key (createp t))
  (namespace-binding-cell namespace symbol :createp createp))

(defun namespace-function-cell (namespace symbol &key (createp t))
  (namespace-binding-cell namespace symbol :createp createp))

(defun document-namespace-ref (namespace symbol)
  (unless (typep namespace 'document-namespace)
    (signal-autolisp-runtime-error
     :invalid-document
     "Expected a document namespace, got ~S."
     namespace))
  (let ((cell (namespace-binding-cell namespace symbol :createp nil)))
    (values (and cell (binding-cell-bound-p cell) (binding-cell-value cell))
            (and cell (binding-cell-bound-p cell)))))

(defun document-namespace-set (namespace symbol value)
  (unless (typep namespace 'document-namespace)
    (signal-autolisp-runtime-error
     :invalid-document
     "Expected a document namespace, got ~S."
     namespace))
  (let ((cell (namespace-binding-cell namespace symbol)))
    (setf (clautolisp.autolisp-runtime.internal::binding-cell-value cell) value
          (clautolisp.autolisp-runtime.internal::binding-cell-bound-p cell) t
          (clautolisp.autolisp-runtime.internal::binding-cell-compatibility-definition
           cell)
          nil)
    value))

(defun document-namespace-function-ref (namespace symbol)
  (unless (typep namespace 'document-namespace)
    (signal-autolisp-runtime-error
     :invalid-document
     "Expected a document namespace, got ~S."
     namespace))
  ;; Single-cell rule: same lookup as document-namespace-ref, but the
  ;; caller is asking specifically for a callable. We surface the
  ;; binding only when its value is a callable subr / usubr.
  (let* ((cell (namespace-binding-cell namespace symbol :createp nil))
         (boundp (and cell (binding-cell-bound-p cell)))
         (value (and boundp (binding-cell-value cell)))
         (callablep (and boundp (or (typep value 'autolisp-subr)
                                    (typep value 'autolisp-usubr)))))
    (values (and callablep value)
            callablep
            :document)))

(defun document-namespace-function-set (namespace symbol function)
  (unless (typep namespace 'document-namespace)
    (signal-autolisp-runtime-error
     :invalid-document
     "Expected a document namespace, got ~S."
     namespace))
  (let ((cell (namespace-binding-cell namespace symbol)))
    (setf (clautolisp.autolisp-runtime.internal::binding-cell-value cell) function
          (clautolisp.autolisp-runtime.internal::binding-cell-bound-p cell) t
          (clautolisp.autolisp-runtime.internal::binding-cell-compatibility-definition
           cell)
          nil)
    function))

(defun current-document-namespace-ref (symbol
                                       &optional (context (current-evaluation-context)))
  (document-namespace-ref (evaluation-context-current-document context) symbol))

(defun current-document-namespace-set (symbol value
                                       &optional (context (current-evaluation-context)))
  (document-namespace-set (evaluation-context-current-document context) symbol value))

(defun export-function-to-current-document (symbol
                                           &optional (context (current-evaluation-context)))
  (multiple-value-bind (function boundp)
      (lookup-function symbol context)
    (unless boundp
      (signal-autolisp-runtime-error
       :undefined-function
       "No function named ~A is defined in the current namespace."
       (autolisp-symbol-name symbol)))
    (let ((namespace (evaluation-context-current-namespace context))
          (session (evaluation-context-session context)))
      (when (typep namespace 'separate-vlx-namespace)
        (register-runtime-session-vlx-namespace session namespace)
        (let* ((application-name (separate-vlx-namespace-name namespace))
               (application-table
                 (or (gethash application-name
                              (clautolisp.autolisp-runtime.internal::runtime-session-exported-functions
                               session))
                     (setf (gethash application-name
                                    (clautolisp.autolisp-runtime.internal::runtime-session-exported-functions
                                     session))
                           (make-hash-table :test #'eq)))))
          (setf (gethash symbol application-table) function))))
    (document-namespace-function-set
     (evaluation-context-current-document context)
     symbol
     function)
    symbol))

(defun import-function-from-current-document (symbol
                                             &optional (context (current-evaluation-context)))
  (multiple-value-bind (function boundp)
      (document-namespace-function-ref (evaluation-context-current-document context)
                                       symbol)
    (unless boundp
      (signal-autolisp-runtime-error
       :undefined-function
       "No exported document function named ~A is available."
       (autolisp-symbol-name symbol)))
    (set-function symbol function context)
    symbol))

(defun import-functions-from-application (application
                                         &optional (context (current-evaluation-context)))
  (let* ((session (evaluation-context-session context))
         (application-name
           (etypecase application
             (string application)
             (autolisp-string (autolisp-string-value application))
             (autolisp-symbol (autolisp-symbol-name application))))
         (application-table
           (gethash application-name
                    (clautolisp.autolisp-runtime.internal::runtime-session-exported-functions
                     session))))
    (unless application-table
      (signal-autolisp-runtime-error
       :undefined-application
       "No exported VLX application named ~A is available in the current session."
       application-name))
    (let ((imported '()))
      (maphash (lambda (symbol function)
                 (set-function symbol function context)
                 (push symbol imported))
               application-table)
      (nreverse imported))))

(defun blackboard-ref (symbol &optional (context (current-evaluation-context)))
  (let* ((namespace (runtime-session-blackboard-namespace
                     (evaluation-context-session context)))
         (cell (namespace-binding-cell namespace symbol :createp nil)))
    (values (and cell (binding-cell-bound-p cell) (binding-cell-value cell))
            (and cell (binding-cell-bound-p cell)))))

(defun blackboard-set (symbol value &optional (context (current-evaluation-context)))
  (let* ((namespace (runtime-session-blackboard-namespace
                     (evaluation-context-session context)))
         (cell (namespace-binding-cell namespace symbol)))
    (setf (clautolisp.autolisp-runtime.internal::binding-cell-value cell) value
          (clautolisp.autolisp-runtime.internal::binding-cell-bound-p cell) t
          (clautolisp.autolisp-runtime.internal::binding-cell-compatibility-definition
           cell)
          nil)
    value))

(defun propagate-variable (symbol &optional (context (current-evaluation-context)))
  (multiple-value-bind (value boundp)
      (document-namespace-ref (evaluation-context-current-document context) symbol)
    (when boundp
      (let ((session (evaluation-context-session context))
            (source (evaluation-context-current-document context)))
        (setf (gethash symbol
                       (clautolisp.autolisp-runtime.internal::runtime-session-propagated-symbols
                        session))
              t)
        (maphash (lambda (name document)
                   (declare (ignore name))
                   (unless (eq document source)
                     (document-namespace-set document symbol value)))
                 (clautolisp.autolisp-runtime.internal::runtime-session-document-namespaces
                  session))))
    value))

(defun make-dynamic-frame (&key parent)
  (clautolisp.autolisp-runtime.internal::make-dynamic-frame :parent parent))

(defun push-dynamic-frame (&optional (context (current-evaluation-context)))
  (let ((frame (make-dynamic-frame :parent (evaluation-context-dynamic-frame context))))
    (setf (clautolisp.autolisp-runtime.internal::evaluation-context-dynamic-frame context)
          frame)
    frame))

(defun pop-dynamic-frame (&optional (context (current-evaluation-context)))
  (let ((frame (evaluation-context-dynamic-frame context)))
    (when frame
      (setf (clautolisp.autolisp-runtime.internal::evaluation-context-dynamic-frame context)
            (clautolisp.autolisp-runtime.internal::dynamic-frame-parent frame)))
    frame))

(defun bind-dynamic-variable (symbol value &optional (context (current-evaluation-context)))
  (let ((frame (or (evaluation-context-dynamic-frame context)
                   (push-dynamic-frame context))))
    (setf (gethash symbol (clautolisp.autolisp-runtime.internal::dynamic-frame-bindings frame))
          (clautolisp.autolisp-runtime.internal::make-dynamic-binding
           :symbol symbol
           :value value
           :bound-p t))
    value))

(defun find-dynamic-binding (symbol frame)
  (loop for current = frame then (clautolisp.autolisp-runtime.internal::dynamic-frame-parent current)
        while current
        for binding = (gethash symbol (clautolisp.autolisp-runtime.internal::dynamic-frame-bindings current))
        when binding
          do (return binding)))

;;; --- Lisp-1 binding lookup and update ------------------------------
;;
;; AutoLISP is Lisp-1 (autolisp-spec, chapter 7): the same per-symbol
;; binding cell is consulted in both value position and call position.
;; `lookup-variable` and `lookup-function` therefore walk the *same*
;; scope chain — first the dynamic-frame stack, then the current
;; namespace's bindings table. The function-position variant
;; additionally requires the value to be callable; an integer or
;; string in the binding produces an :undefined-function diagnostic
;; in the call dispatch path, matching BricsCAD's runtime.

(defun lookup-variable (symbol &optional (context (current-evaluation-context)))
  (let ((binding (find-dynamic-binding symbol (evaluation-context-dynamic-frame context))))
    (cond
      (binding
       (values (clautolisp.autolisp-runtime.internal::dynamic-binding-value binding) t :dynamic))
      (t
       (let* ((cell (namespace-binding-cell (evaluation-context-current-namespace context)
                                            symbol
                                            :createp nil))
              (boundp (and cell (binding-cell-bound-p cell))))
         (values (and boundp (binding-cell-value cell))
                 boundp
                 :namespace))))))

(defun set-variable (symbol value &optional (context (current-evaluation-context)))
  (let ((binding (find-dynamic-binding symbol (evaluation-context-dynamic-frame context))))
    (if binding
        (setf (clautolisp.autolisp-runtime.internal::dynamic-binding-value binding) value
              (clautolisp.autolisp-runtime.internal::dynamic-binding-bound-p binding) t)
        (let ((cell (namespace-binding-cell (evaluation-context-current-namespace context)
                                            symbol)))
          (setf (clautolisp.autolisp-runtime.internal::binding-cell-value cell) value
                (clautolisp.autolisp-runtime.internal::binding-cell-bound-p cell) t
                (clautolisp.autolisp-runtime.internal::binding-cell-compatibility-definition
                 cell)
                nil)))
    value))

(defun lookup-function (symbol &optional (context (current-evaluation-context)))
  ;; Same scope chain as lookup-variable; surface the binding only
  ;; when the bound value is a callable subr / usubr. A non-callable
  ;; value (e.g. an integer left over from a SETQ) means "no function
  ;; definition" in BricsCAD's dispatch — we model that by reporting
  ;; the binding as unbound from the call's point of view, so the
  ;; eval call-dispatch surfaces :undefined-function naturally.
  (multiple-value-bind (value boundp origin)
      (lookup-variable symbol context)
    (if (and boundp
             (or (typep value 'autolisp-subr)
                 (typep value 'autolisp-usubr)))
        (values value t origin)
        (values nil nil origin))))

(defun set-function (symbol function &optional (context (current-evaluation-context)))
  (let ((cell (namespace-binding-cell (evaluation-context-current-namespace context) symbol)))
    (setf (clautolisp.autolisp-runtime.internal::binding-cell-value cell) function
          (clautolisp.autolisp-runtime.internal::binding-cell-bound-p cell) t
          (clautolisp.autolisp-runtime.internal::binding-cell-compatibility-definition cell)
          nil)
    function))

(defun set-autolisp-symbol-value (symbol value)
  (set-variable symbol value))

(defun set-autolisp-symbol-function (symbol function)
  (set-function symbol function))

(defun runtime-value-p (object)
  (or (null object)
      (typep object '(signed-byte 32))
      (typep object 'double-float)
      (consp object)
      (typep object 'clautolisp.autolisp-runtime.internal::autolisp-symbol)
      (typep object 'clautolisp.autolisp-runtime.internal::autolisp-string)
      (typep object 'clautolisp.autolisp-runtime.internal::autolisp-file)
      (typep object 'clautolisp.autolisp-runtime.internal::autolisp-ename)
      (typep object 'clautolisp.autolisp-runtime.internal::autolisp-pickset)
      (typep object 'clautolisp.autolisp-runtime.internal::autolisp-subr)
      (typep object 'clautolisp.autolisp-runtime.internal::autolisp-usubr)
      (typep object 'clautolisp.autolisp-runtime.internal::autolisp-catch-all-error)
      (typep object 'clautolisp.autolisp-runtime.internal::autolisp-variant)
      (typep object 'clautolisp.autolisp-runtime.internal::autolisp-safearray)
      (typep object 'clautolisp.autolisp-runtime.internal::autolisp-vla-object)))

(defun autolisp-string-value (object)
  (clautolisp.autolisp-runtime.internal::autolisp-string-value object))

(defun make-autolisp-string (value)
  (clautolisp.autolisp-runtime.internal::make-autolisp-string
   :value value))

(defun autolisp-symbol-name (object)
  (clautolisp.autolisp-runtime.internal::autolisp-symbol-name object))

(defun autolisp-symbol-original-name (object)
  (clautolisp.autolisp-runtime.internal::autolisp-symbol-original-name object))

(defun autolisp-symbol-value (object)
  (nth-value 0 (lookup-variable object)))

(defun autolisp-symbol-value-bound-p (object)
  (nth-value 1 (lookup-variable object)))

(defun autolisp-symbol-function (object)
  (nth-value 0 (lookup-function object)))

(defun autolisp-symbol-function-bound-p (object)
  (nth-value 1 (lookup-function object)))

(defun autolisp-function-list-definition (object &optional (context (current-evaluation-context)))
  (let ((cell (namespace-binding-cell (evaluation-context-current-namespace context)
                                      object
                                      :createp nil)))
    (and cell
         (binding-cell-compatibility-definition cell))))

(defun set-autolisp-function-list-definition (symbol definition
                                              &optional (context (current-evaluation-context)))
  (let ((cell (namespace-binding-cell (evaluation-context-current-namespace context) symbol)))
    (setf (clautolisp.autolisp-runtime.internal::binding-cell-compatibility-definition cell)
          definition)
    definition))

(defun autolisp-file-stream (object)
  (clautolisp.autolisp-runtime.internal::autolisp-file-stream object))

(defun make-autolisp-file (stream path mode)
  (clautolisp.autolisp-runtime.internal::make-autolisp-file
   :stream stream
   :path path
   :mode mode))

(defun autolisp-file-path (object)
  (clautolisp.autolisp-runtime.internal::autolisp-file-path object))

(defun autolisp-file-mode (object)
  (clautolisp.autolisp-runtime.internal::autolisp-file-mode object))

(defun close-autolisp-file (object)
  (let ((stream (autolisp-file-stream object)))
    (when stream
      (close stream))
    (setf (clautolisp.autolisp-runtime.internal::autolisp-file-stream object) nil)
    nil))

(defun autolisp-ename-value (object)
  (clautolisp.autolisp-runtime.internal::autolisp-ename-value object))

(defun make-autolisp-ename (&key value)
  (clautolisp.autolisp-runtime.internal::make-autolisp-ename :value value))

(defun autolisp-pickset-value (object)
  (clautolisp.autolisp-runtime.internal::autolisp-pickset-value object))

(defun make-autolisp-pickset (&key value)
  (clautolisp.autolisp-runtime.internal::make-autolisp-pickset :value value))

(defun autolisp-subr-name (object)
  (clautolisp.autolisp-runtime.internal::autolisp-subr-name object))

(defun make-autolisp-subr (name function)
  (clautolisp.autolisp-runtime.internal::make-autolisp-subr
   :name name
   :function function))

(defun autolisp-subr-function (object)
  (clautolisp.autolisp-runtime.internal::autolisp-subr-function object))

(defun autolisp-usubr-name (object)
  (clautolisp.autolisp-runtime.internal::autolisp-usubr-name object))

(defun make-autolisp-usubr (name lambda-list body environment)
  (clautolisp.autolisp-runtime.internal::make-autolisp-usubr
   :name name
   :lambda-list lambda-list
   :body body
   :environment environment))

(defun autolisp-usubr-lambda-list (object)
  (clautolisp.autolisp-runtime.internal::autolisp-usubr-lambda-list object))

(defun autolisp-usubr-body (object)
  (clautolisp.autolisp-runtime.internal::autolisp-usubr-body object))

(defun autolisp-usubr-environment (object)
  (clautolisp.autolisp-runtime.internal::autolisp-usubr-environment object))

(defun make-autolisp-catch-all-error (message condition)
  (clautolisp.autolisp-runtime.internal::make-autolisp-catch-all-error
   :message message
   :condition condition))

(defun autolisp-catch-all-error-message (object)
  (clautolisp.autolisp-runtime.internal::autolisp-catch-all-error-message object))

(defun autolisp-catch-all-error-condition (object)
  (clautolisp.autolisp-runtime.internal::autolisp-catch-all-error-condition object))

(defun autolisp-variant-value (object)
  (clautolisp.autolisp-runtime.internal::autolisp-variant-value object))

(defun autolisp-safearray-value (object)
  (clautolisp.autolisp-runtime.internal::autolisp-safearray-value object))

(defun autolisp-vla-object-value (object)
  (clautolisp.autolisp-runtime.internal::autolisp-vla-object-value object))

(defun make-autolisp-vla-object (&key value)
  (clautolisp.autolisp-runtime.internal::make-autolisp-vla-object :value value))

(defun make-autolisp-safearray (&key value)
  (clautolisp.autolisp-runtime.internal::make-autolisp-safearray :value value))

(defun make-autolisp-variant (&key value)
  (clautolisp.autolisp-runtime.internal::make-autolisp-variant :value value))

(defun append-proper-and-tail (elements tail)
  (if (null elements)
      tail
      (cons (first elements)
            (append-proper-and-tail (rest elements) tail))))

(defun reader-object->runtime-value (object)
  (typecase object
    (symbol-object
     (intern-autolisp-symbol (symbol-object-canonical-name object)
                             :original-name (symbol-object-canonical-name object)))
    (string-object
     (clautolisp.autolisp-runtime.internal::make-autolisp-string
      :value (string-object-value object)))
    (integer-object
     (integer-object-value object))
    (real-object
     (real-object-value object))
    (cons-object
     (let ((elements (mapcar #'reader-object->runtime-value
                             (cons-object-elements object))))
       (if (cons-object-dotted-p object)
           (append-proper-and-tail
            elements
            (reader-object->runtime-value (cons-object-tail object)))
           elements)))
    (quote-object
     (list (intern-autolisp-symbol "QUOTE")
           (reader-object->runtime-value (quote-object-object object))))
    (t
     (signal-autolisp-runtime-error
      :reader-handoff-error
      "Cannot map reader object ~S to a runtime value."
      object))))

(defun reader-objects->runtime-values (objects)
  (mapcar #'reader-object->runtime-value objects))

(defun autolisp-false-p (object)
  (null object))

(defun autolisp-true-p (object)
  (not (autolisp-false-p object)))

(defun autolisp-boundp (object &optional (context (current-evaluation-context)))
  (unless (typep object 'autolisp-symbol)
    (signal-autolisp-runtime-error
     :type-error
     "Expected an AutoLISP symbol, got ~S."
     object))
  (multiple-value-bind (value boundp origin)
      (lookup-variable object context)
    (declare (ignore origin))
    (unless boundp
      ;; Autodesk documents that testing an undefined symbol with BOUNDP
      ;; creates the symbol and assigns it NIL, while still returning NIL.
      (set-variable object nil context)
      (setf value nil
            boundp t))
    (if value
        (intern-autolisp-symbol "T")
        nil)))

(defun autolisp-null (object)
  (if (null object)
      (intern-autolisp-symbol "T")
      nil))

(defun autolisp-not (object)
  (autolisp-null object))

(defun autolisp-listp (object)
  (if (listp object)
      (intern-autolisp-symbol "T")
      nil))

(defun autolisp-atom (object)
  (if (atom object)
      (intern-autolisp-symbol "T")
      nil))

(defun autolisp-vl-symbolp (object)
  (if (typep object 'autolisp-symbol)
      (intern-autolisp-symbol "T")
      nil))

(defun autolisp-vl-symbol-name (object)
  (unless (typep object 'autolisp-symbol)
    (signal-autolisp-runtime-error
     :type-error
     "Expected an AutoLISP symbol, got ~S."
     object))
  (clautolisp.autolisp-runtime.internal::make-autolisp-string
   :value (autolisp-symbol-name object)))

(defun autolisp-vl-symbol-value (object)
  (unless (typep object 'autolisp-symbol)
    (signal-autolisp-runtime-error
     :type-error
     "Expected an AutoLISP symbol, got ~S."
     object))
  (autolisp-symbol-value object))

(defun call-autolisp-function (function &rest arguments)
  (apply #'call-autolisp-function-in-context
         function
         (current-evaluation-context)
         arguments))

(defun resolve-autolisp-function-designator (designator
                                            &optional
                                              (context (current-evaluation-context)))
  (cond
    ((or (typep designator 'autolisp-subr)
         (typep designator 'autolisp-usubr))
     designator)
    ((typep designator 'autolisp-symbol)
     (multiple-value-bind (binding boundp origin)
         (lookup-function designator context)
       (declare (ignore origin))
       (unless boundp
         (signal-autolisp-runtime-error
          :undefined-function
          "Undefined AutoLISP function ~A."
          (autolisp-symbol-name designator)))
       binding))
    ((and (consp designator)
          (= (length designator) 2)
          (typep (first designator) 'autolisp-symbol)
          (string= "QUOTE" (autolisp-symbol-name (first designator)))
          (lambda-form-p (second designator)))
     (resolve-autolisp-function-designator (second designator) context))
    ((and (consp designator)
          (= (length designator) 2)
          (typep (first designator) 'autolisp-symbol)
          (string= "FUNCTION" (autolisp-symbol-name (first designator))))
     (resolve-autolisp-function-designator (second designator) context))
    ((lambda-form-p designator)
     (eval-lambda-form (rest designator) context))
    (t
     (signal-autolisp-runtime-error
      :invalid-function-designator
      "Expected an AutoLISP function designator, got ~S."
      designator))))

(defun resolve-autolisp-error-handler (context)
  (let ((symbol (intern-autolisp-symbol "*ERROR*")))
    (handler-case
        (resolve-autolisp-function-designator symbol context)
      (autolisp-runtime-error (condition)
        (if (eq :undefined-function (autolisp-runtime-error-code condition))
            nil
            (error condition))))))

(defun call-with-autolisp-error-handler (thunk &optional (context (current-evaluation-context)))
  (handler-case
      (let ((result (funcall thunk)))
        (set-autolisp-errno 0 context)
        result)
    (autolisp-runtime-error (condition)
      (set-autolisp-errno (autolisp-runtime-error-errno condition) context)
      (let ((handler (resolve-autolisp-error-handler context)))
        (if handler
            (call-autolisp-function-in-context
             handler
             context
             (make-autolisp-string (autolisp-runtime-error-message condition)))
            (error condition))))))

(defun autolisp-slash-symbol-p (symbol)
  (and (typep symbol 'autolisp-symbol)
       (string= "/" (autolisp-symbol-name symbol))))

(defun split-usubr-lambda-list (lambda-list)
  (unless (listp lambda-list)
    (signal-autolisp-runtime-error
     :invalid-lambda-list
     "AutoLISP function lambda list must be a proper list, got ~S."
     lambda-list))
  (let ((position (position-if #'autolisp-slash-symbol-p lambda-list)))
    (values (if position
                (subseq lambda-list 0 position)
                lambda-list)
            (if position
                (subseq lambda-list (1+ position))
                '()))))

(defun bind-usubr-frame (function arguments context)
  (multiple-value-bind (required locals)
      (split-usubr-lambda-list (autolisp-usubr-lambda-list function))
    (unless (= (length required) (length arguments))
      (signal-autolisp-runtime-error
       :wrong-number-of-arguments
       "AutoLISP function ~A expects ~D arguments, got ~D."
       (autolisp-usubr-name function)
       (length required)
       (length arguments)))
    (push-dynamic-frame context)
    (loop for symbol in required
          for value in arguments
          do (bind-dynamic-variable symbol value context))
    (dolist (symbol locals)
      (bind-dynamic-variable symbol nil context))))

(defun call-autolisp-function-in-context (function context &rest arguments)
  (let ((clautolisp.autolisp-runtime.internal::*active-evaluation-context* context))
    (cond
      ((typep function 'autolisp-subr)
       (handler-case
           (apply (autolisp-subr-function function) arguments)
         (autolisp-runtime-error (condition)
           (error condition))
         (error (condition)
           (error 'autolisp-runtime-error
                  :code :subr-call-host-error
                  :message (format nil
                                   "Common Lisp error while calling AutoLISP subr ~A: ~A"
                                   (autolisp-subr-name function)
                                   condition)
                  :details (list :subr (autolisp-subr-name function)
                                 :condition condition)))))
      ((typep function 'autolisp-usubr)
       (unwind-protect
            (progn
              (bind-usubr-frame function arguments context)
              (autolisp-eval-progn (autolisp-usubr-body function) context))
         (pop-dynamic-frame context)))
      (t
       (signal-autolisp-runtime-error
        :invalid-function-object
        "Expected an AutoLISP function object, got ~S."
        function)))))

(defun self-evaluating-runtime-value-p (object)
  (or (null object)
      (typep object '(signed-byte 32))
      (typep object 'double-float)
      (typep object 'autolisp-string)
      (typep object 'autolisp-file)
      (typep object 'autolisp-ename)
      (typep object 'autolisp-pickset)
      (typep object 'autolisp-subr)
      (typep object 'autolisp-usubr)
      (typep object 'autolisp-catch-all-error)
      (typep object 'autolisp-variant)
      (typep object 'autolisp-safearray)
      (typep object 'autolisp-vla-object)))

(defun special-operator-name (operator)
  (and (typep operator 'autolisp-symbol)
       (string-upcase (autolisp-symbol-name operator))))

(defun autolisp-eval-progn (forms &optional (context (current-evaluation-context)))
  (let ((result nil))
    (dolist (form forms result)
      (setf result (autolisp-eval form context)))))

(defun eval-quote-form (arguments context)
  (declare (ignore context))
  (unless (= (length arguments) 1)
    (signal-autolisp-runtime-error
     :wrong-number-of-arguments
     "QUOTE expects exactly one argument, got ~D."
     (length arguments)))
  (first arguments))

(defun eval-setq-form (arguments context)
  (unless (evenp (length arguments))
    (signal-autolisp-runtime-error
     :invalid-setq-arguments
     "SETQ expects an even number of arguments, got ~D."
     (length arguments)))
  (let ((result nil))
    (loop for (symbol-form value-form) on arguments by #'cddr
          do (unless (typep symbol-form 'autolisp-symbol)
               (signal-autolisp-runtime-error
                :invalid-setq-place
                "SETQ place must be an AutoLISP symbol, got ~S."
                symbol-form))
             (setf result (autolisp-eval value-form context))
             (set-variable symbol-form result context))
    result))

(defun eval-progn-form (arguments context)
  (autolisp-eval-progn arguments context))

(defun eval-if-form (arguments context)
  (unless (<= 2 (length arguments) 3)
    (signal-autolisp-runtime-error
     :wrong-number-of-arguments
     "IF expects two or three arguments, got ~D."
     (length arguments)))
  (if (autolisp-true-p (autolisp-eval (first arguments) context))
      (autolisp-eval (second arguments) context)
      (if (third arguments)
          (autolisp-eval (third arguments) context)
          nil)))

(defun eval-cond-form (arguments context)
  (dolist (clause arguments nil)
    (unless (consp clause)
      (signal-autolisp-runtime-error
       :invalid-cond-clause
       "COND clause must be a non-empty list, got ~S."
       clause))
    (let ((test-value (autolisp-eval (first clause) context)))
      (when (autolisp-true-p test-value)
        (return
          (if (rest clause)
              (autolisp-eval-progn (rest clause) context)
              test-value))))))

;; AutoLISP `and` / `or` are *boolean*: they return T / nil only,
;; not the first non-nil expression value (Common Lisp). This matches
;; Bricsys's per-symbol pages — confirmed for BricsCAD V26 against the
;; Phase-5 product test on 2026-04-26 (see autolisp-spec entry for
;; OR / AND, plus vendor-inventory-2026.org §10 item 11). Short-circuit
;; evaluation is preserved; only the return shape changes.
(defun eval-and-form (arguments context)
  (let ((t-symbol (intern-autolisp-symbol "T")))
    (dolist (argument arguments t-symbol)
      (when (autolisp-false-p (autolisp-eval argument context))
        (return nil)))))

(defun eval-or-form (arguments context)
  (let ((t-symbol (intern-autolisp-symbol "T")))
    (dolist (argument arguments nil)
      (when (autolisp-true-p (autolisp-eval argument context))
        (return t-symbol)))))

(defun eval-while-form (arguments context)
  (unless (>= (length arguments) 1)
    (signal-autolisp-runtime-error
     :wrong-number-of-arguments
     "WHILE expects at least one argument."))
  (loop while (autolisp-true-p (autolisp-eval (first arguments) context))
        do (autolisp-eval-progn (rest arguments) context))
  nil)

(defun eval-repeat-form (arguments context)
  (unless (>= (length arguments) 1)
    (signal-autolisp-runtime-error
     :wrong-number-of-arguments
     "REPEAT expects at least one argument."))
  (let ((count (autolisp-eval (first arguments) context)))
    (unless (typep count '(signed-byte 32))
      (signal-autolisp-runtime-error
       :invalid-repeat-count
       "REPEAT count must evaluate to an integer, got ~S."
       count))
    (loop repeat (max 0 count)
          do (autolisp-eval-progn (rest arguments) context))
    nil))

(defun eval-foreach-form (arguments context)
  (unless (>= (length arguments) 2)
    (signal-autolisp-runtime-error
     :wrong-number-of-arguments
     "FOREACH expects at least a binding name and a list argument, got ~D arguments."
     (length arguments)))
  (let ((name (first arguments))
        (body (cddr arguments))
        (result nil))
    (unless (typep name 'autolisp-symbol)
      (signal-autolisp-runtime-error
       :invalid-foreach-binding
       "FOREACH binding name must be an AutoLISP symbol, got ~S."
       name))
    (let ((sequence (autolisp-eval (second arguments) context)))
      (unless (listp sequence)
        (signal-autolisp-runtime-error
         :invalid-foreach-sequence
         "FOREACH list argument must evaluate to a proper list, got ~S."
         sequence))
      (unwind-protect
           (progn
             (push-dynamic-frame context)
             (dolist (element sequence result)
               (if (find-dynamic-binding name (evaluation-context-dynamic-frame context))
                   (set-variable name element context)
                   (bind-dynamic-variable name element context))
               (setf result (if body
                                (autolisp-eval-progn body context)
                                nil))))
        (pop-dynamic-frame context)))))

(defun eval-lambda-form (arguments context)
  (unless (>= (length arguments) 2)
    (signal-autolisp-runtime-error
     :wrong-number-of-arguments
     "LAMBDA expects a lambda list and at least one body form, got ~D arguments."
     (length arguments)))
  (make-autolisp-usubr "LAMBDA"
                       (first arguments)
                       (rest arguments)
                       context))

(defun compatibility-definition-from-parts (lambda-list body)
  (cons lambda-list body))

(defun compatibility-definition->parts (definition)
  (unless (and (consp definition)
               (listp definition))
    (signal-autolisp-runtime-error
     :invalid-defun-q-definition
     "DEFUN-Q compatibility definition must be a proper list, got ~S."
     definition))
  (values (first definition)
          (rest definition)))

(defun eval-function-form (arguments context)
  (unless (= (length arguments) 1)
    (signal-autolisp-runtime-error
     :wrong-number-of-arguments
     "FUNCTION expects exactly one argument, got ~D."
     (length arguments)))
  (let ((designator (first arguments)))
    (cond
      ((typep designator 'autolisp-symbol)
       (resolve-autolisp-function-designator designator context))
      ((lambda-form-p designator)
       (resolve-autolisp-function-designator designator context))
      (t
       (signal-autolisp-runtime-error
        :invalid-function-designator
        "FUNCTION expects a function name or lambda form, got ~S."
        designator)))))

(defun eval-defun-q-form (arguments context)
  (unless (>= (length arguments) 2)
    (signal-autolisp-runtime-error
     :wrong-number-of-arguments
     "DEFUN-Q expects at least a name and lambda list, got ~D arguments."
     (length arguments)))
  (let ((name (first arguments))
        (lambda-list (second arguments))
        (body (cddr arguments)))
    (unless (typep name 'autolisp-symbol)
      (signal-autolisp-runtime-error
       :invalid-defun-name
       "DEFUN-Q name must be an AutoLISP symbol, got ~S."
       name))
    (let ((function (make-autolisp-usubr (autolisp-symbol-name name)
                                         lambda-list
                                         body
                                         context))
          (definition (compatibility-definition-from-parts lambda-list body)))
      (set-function name function context)
      (set-autolisp-function-list-definition name definition context)
      name)))

(defun eval-defun-form (arguments context)
  (unless (>= (length arguments) 2)
    (signal-autolisp-runtime-error
     :wrong-number-of-arguments
     "DEFUN expects at least a name and lambda list, got ~D arguments."
     (length arguments)))
  (let ((name (first arguments))
        (lambda-list (second arguments))
        (body (cddr arguments)))
    (unless (typep name 'autolisp-symbol)
      (signal-autolisp-runtime-error
       :invalid-defun-name
       "DEFUN name must be an AutoLISP symbol, got ~S."
       name))
    (let ((function (make-autolisp-usubr (autolisp-symbol-name name)
                                         lambda-list
                                         body
                                         context)))
      (set-function name function context)
      name)))

(defparameter *special-operator-dispatch*
  (list (cons "QUOTE" #'eval-quote-form)
        (cons "SETQ" #'eval-setq-form)
        (cons "PROGN" #'eval-progn-form)
        (cons "IF" #'eval-if-form)
        (cons "COND" #'eval-cond-form)
        (cons "AND" #'eval-and-form)
        (cons "OR" #'eval-or-form)
        (cons "WHILE" #'eval-while-form)
        (cons "REPEAT" #'eval-repeat-form)
        (cons "FOREACH" #'eval-foreach-form)
        (cons "LAMBDA" #'eval-lambda-form)
        (cons "FUNCTION" #'eval-function-form)
        (cons "DEFUN-Q" #'eval-defun-q-form)
        (cons "DEFUN" #'eval-defun-form)))

(defun special-operator-function (operator)
  (cdr (assoc (special-operator-name operator)
              *special-operator-dispatch*
              :test #'string=)))

(defun eval-special-operator (operator arguments context)
  (let ((function (special-operator-function operator)))
    (unless function
      (signal-autolisp-runtime-error
       :unsupported-special-operator
       "Unsupported special operator ~A."
       (special-operator-name operator)))
    (funcall function arguments context)))

(defun lambda-form-p (form)
  (and (consp form)
       (typep (first form) 'autolisp-symbol)
       (string= "LAMBDA" (autolisp-symbol-name (first form)))))

(defun autolisp-eval (form &optional (context (current-evaluation-context)))
  (cond
    ((self-evaluating-runtime-value-p form)
     form)
    ((typep form 'autolisp-symbol)
     (multiple-value-bind (value boundp origin) (lookup-variable form context)
       (declare (ignore origin))
       (cond
         (boundp value)
         ;; Unbound-variable handling is dialect-controlled
         ;; (autolisp-spec ch. 3, "Unbound-Variable Reference"). The
         ;; strict dialect signals; AutoCAD / BricsCAD product
         ;; profiles silently return nil.
         ((eq :silent-nil
              (clautolisp.autolisp-reader:autolisp-dialect-unbound-variable-mode
               (current-evaluation-dialect context)))
          nil)
         (t
          (signal-autolisp-runtime-error
           :unbound-variable
           "Unbound AutoLISP variable ~A."
           (autolisp-symbol-name form))))))
    ((consp form)
     (let ((operator (first form))
           (arguments (rest form)))
       (cond
         ((special-operator-function operator)
          (eval-special-operator operator arguments context))
         (t
          (unless (or (lambda-form-p operator)
                      (typep operator 'autolisp-symbol))
            (signal-autolisp-runtime-error
             :invalid-call-operator
             "AutoLISP call operator must be a function name or lambda form, got ~S."
             operator))
          (let ((function
                  (if (lambda-form-p operator)
                      (autolisp-eval operator context)
                      (multiple-value-bind (binding boundp origin) (lookup-function operator context)
                        (declare (ignore origin))
                        (unless boundp
                          (signal-autolisp-runtime-error
                           :undefined-function
                           "Undefined AutoLISP function ~A."
                           (autolisp-symbol-name operator)))
                        binding))))
            (apply #'call-autolisp-function-in-context
                   function
                   context
                   (mapcar (lambda (argument)
                             (autolisp-eval argument context))
                           arguments)))))))
    (t
     (signal-autolisp-runtime-error
      :invalid-form
      "Cannot evaluate AutoLISP form ~S."
      form))))

(defun autolisp-type (object)
  (cond
    ((null object) nil)
    ((typep object '(signed-byte 32))
     (intern-autolisp-symbol "INT"))
    ((typep object 'double-float)
     (intern-autolisp-symbol "REAL"))
    ((typep object 'autolisp-string)
     (intern-autolisp-symbol "STR"))
    ((typep object 'autolisp-symbol)
     (intern-autolisp-symbol "SYM"))
    ((consp object)
     (intern-autolisp-symbol "LIST"))
    ((typep object 'autolisp-file)
     (intern-autolisp-symbol "FILE"))
    ((typep object 'autolisp-ename)
     (intern-autolisp-symbol "ENAME"))
    ((typep object 'autolisp-pickset)
     (intern-autolisp-symbol "PICKSET"))
    ((typep object 'autolisp-subr)
     (intern-autolisp-symbol "SUBR"))
    ((typep object 'autolisp-usubr)
     (intern-autolisp-symbol "USUBR"))
    ((typep object 'autolisp-safearray)
     (intern-autolisp-symbol "SAFEARRAY"))
    ((typep object 'autolisp-variant)
     (intern-autolisp-symbol "VARIANT"))
    ((typep object 'autolisp-vla-object)
     (intern-autolisp-symbol "VLA-OBJECT"))
    (t
     (signal-autolisp-runtime-error
      :unknown-runtime-type
      "No AutoLISP runtime type designator is defined for ~S."
      object))))

(defun read-runtime-from-string (text &rest options &key &allow-other-keys)
  (reader-objects->runtime-values
   (read-result-objects
    (apply #'read-forms-from-string text options))))

(defun read-runtime-from-stream (stream &rest options &key &allow-other-keys)
  (reader-objects->runtime-values
   (read-result-objects
    (apply #'read-forms-from-stream stream options))))

(defun read-runtime-from-file (path &rest options &key &allow-other-keys)
  (reader-objects->runtime-values
   (read-result-objects
    (apply #'read-forms-from-file path options))))

(defun autolisp-read-from-string (text &rest options &key &allow-other-keys)
  (first (apply #'read-runtime-from-string text options)))

(defun autolisp-read-from-stream (stream &rest options &key &allow-other-keys)
  (first (apply #'read-runtime-from-stream stream options)))

(defun autolisp-read-from-file (path &rest options &key &allow-other-keys)
  (first (apply #'read-runtime-from-file path options)))

(defun autolisp-load-file-in-context (path context &rest read-options)
  ;; Inject the dialect's default source encoding when the caller did
  ;; not pass an explicit :external-format. This makes
  ;;   * the strict dialect read files as ISO-8859-1 (a 1-1 byte
  ;;     coding, never fails on Latin-1 / Windows-1252 source);
  ;;   * the autocad-2026 / bricscad-v26 dialects read files as
  ;;     UTF-8, matching AutoCAD 2025+ and BricsCAD V26 defaults
  ;;     (autolisp-spec ch. 11, "Source-File and File-Stream
  ;;     Encoding").
  (let* ((options-have-external-format
          (loop for tail = read-options then (cddr tail)
                while tail
                thereis (eq (first tail) :external-format)))
         (dialect (current-evaluation-dialect context))
         (effective-options
          (if options-have-external-format
              read-options
              (append read-options
                      (list :external-format
                            (clautolisp.autolisp-reader:autolisp-dialect-default-source-encoding
                             dialect))))))
    (call-with-autolisp-error-handler
     (lambda ()
       (autolisp-eval-progn
        (apply #'read-runtime-from-file path effective-options)
        context))
     context)))

(defun autolisp-load-file (path &rest read-options)
  (apply #'autolisp-load-file-in-context
         path
         (default-evaluation-context)
         read-options))

;;; --- Standalone-evaluator entry points (Phase 6) -------------------
;;
;; Phase 6 adds a higher-level `run-autolisp-file` and
;; `run-autolisp-string` that wrap session creation, default-context
;; installation, and load+evaluate into a single call. The standalone
;; `clautolisp` executable consumes these entries.

(defun derive-reader-options-for-dialect (dialect &key source-name)
  "Build a reader-options struct from DIALECT, with SOURCE-NAME wired
through. Used by the standalone evaluator's load path."
  (clautolisp.autolisp-reader:reader-options-from-dialect
   dialect :source-name source-name))

(defun make-default-runtime-context (&key dialect)
  "Create a fresh runtime session under DIALECT, install it as the
default evaluation context, and return the context. Use this when a
caller (e.g. the standalone evaluator or the REPL) needs to set up
host-level state — such as installing builtin function bindings —
before evaluation begins."
  (let* ((selected-dialect
          (or dialect (clautolisp.autolisp-reader:autolisp-dialect-strict)))
         (session (make-runtime-session :dialect selected-dialect))
         (context (make-evaluation-context :session session)))
    (set-default-evaluation-context context)
    context))

(defun run-autolisp-file (path &key dialect source-name setup-fn)
  "Read PATH under DIALECT, evaluate its forms in a fresh session, and
return the value of the last form. DIALECT defaults to the strict
profile. SOURCE-NAME, if supplied, is used in diagnostic spans;
otherwise the file's namestring is used. SETUP-FN, if supplied, is
called once with the new context after the session is installed but
before any source forms are read — typically used to install builtin
function bindings into the new session's namespace."
  (let* ((selected-dialect
          (or dialect (clautolisp.autolisp-reader:autolisp-dialect-strict)))
         (context (make-default-runtime-context :dialect selected-dialect)))
    (when setup-fn
      (funcall setup-fn context))
    (let* ((effective-source-name (or source-name (namestring path)))
           (options (derive-reader-options-for-dialect
                     selected-dialect :source-name effective-source-name)))
      (autolisp-load-file-in-context path context :options options))))

(defun run-autolisp-string (text &key dialect source-name setup-fn)
  "Read TEXT under DIALECT and evaluate every form sequentially in a
fresh session. Useful for `-x EXPR`-style command-line invocations.
SETUP-FN behaves as for `run-autolisp-file`."
  (let* ((selected-dialect
          (or dialect (clautolisp.autolisp-reader:autolisp-dialect-strict)))
         (context (make-default-runtime-context :dialect selected-dialect)))
    (when setup-fn
      (funcall setup-fn context))
    (let* ((options (derive-reader-options-for-dialect
                     selected-dialect :source-name (or source-name "<string>")))
           (forms (apply #'read-runtime-from-string text :options options
                         (when source-name (list :source-name source-name)))))
      (call-with-autolisp-error-handler
       (lambda () (autolisp-eval-progn forms context))
       context))))
