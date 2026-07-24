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

;;; --- AutoLISP call-stack tracking ---------------------------------
;;;
;;; *autolisp-call-stack* records the chain of forms currently being
;;; evaluated. Each frame is a cons (KIND . FORM) where KIND is
;;;   :eval        - autolisp-eval is evaluating a form
;;;   :special-op  - eval-special-operator is dispatching a special form
;;;   :subr        - call-autolisp-function-in-context is calling a SUBR
;;;   :usubr       - call-autolisp-function-in-context is calling a USUBR
;;; The most recent frame is at the head of the list. Captured by
;;; signal-autolisp-runtime-error and exposed to AutoLISP code through
;;; vl-bt and through the catch-all error object.

(defparameter *autolisp-call-stack* nil
  "Current AutoLISP evaluator call stack. Each frame is a cons
(KIND . FORM). The list is built and torn down by the evaluator
through unwind-protect, so it is safe to consult during error
handling.")

(defun current-autolisp-call-stack ()
  "Return a copy of the current evaluator stack so consumers can
keep a snapshot beyond the dynamic extent of the active frame."
  (copy-list *autolisp-call-stack*))

;;; --- source-aware-defun-documentation: read-time → eval-time bridge

(defparameter *preceding-docs* (make-hash-table :test 'eq)
  "Side-table populated by REGISTER-PRECEDING-DOC during the
reader→runtime conversion: maps the freshly-allocated CL cons
representing a parsed cons-object to the text of the ;|…|; block
comment that preceded it in the source. Looked up by
EVAL-DEFUN-FORM / EVAL-SETQ-FORM via *current-form*. EQ-keyed
because we want pointer-identity on the cons; the table grows
once per file load and is not pruned (entries become unreachable
when the form cons is GCed; SBCL/CCL handle that for us via the
weak-reference semantics of an EQ hash with no other references).")

(defparameter *current-form* nil
  "Bound by AUTOLISP-EVAL's cons-dispatch to the form being
dispatched, so EVAL-DEFUN-FORM and EVAL-SETQ-FORM can recover
the parse-tree's preceding-doc via (gethash *current-form*
*preceding-docs*). nil during evaluation of self-evaluating
values, symbol lookups, and programmatically-constructed forms
that were never registered.")

(defun register-preceding-doc (cl-cons doc-text)
  "Record DOC-TEXT (a string) as the preceding-doc of CL-CONS.
Called from REGISTER-PRECEDING-DOC during the reader→runtime
conversion when a cons-object carried a non-nil preceding-doc."
  (when (and (consp cl-cons) doc-text)
    (setf (gethash cl-cons *preceding-docs*) doc-text)))

(defun current-form-preceding-doc ()
  "Return the doc string registered for the form currently being
dispatched by AUTOLISP-EVAL, or nil. Called by EVAL-DEFUN-FORM
and EVAL-SETQ-FORM (and only by them) at the moment they update
the binding-cell doc slot."
  (and *current-form* (gethash *current-form* *preceding-docs*)))

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
    :reader autolisp-runtime-error-details)
   (call-stack
    :initarg :call-stack
    :initform nil
    :reader autolisp-runtime-error-call-stack))
  (:report (lambda (condition stream)
             (format stream "~A" (autolisp-runtime-error-message condition)))))

(define-condition autolisp-termination (serious-condition)
  ((kind
    :initarg :kind
    :reader autolisp-termination-kind)
   ;; The process exit status carried by (quit [status]) / (exit
   ;; [status]). Defaults to 0 so the historical 0-arg (quit)/(exit)
   ;; keep exiting with success; a script sets it explicitly, or lets
   ;; it fall through to the session's stored autolisp-status.
   (status
    :initarg :status
    :initform 0
    :reader autolisp-termination-status))
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
         :details arguments
         :call-stack (current-autolisp-call-stack)))

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

(defun autolisp-trusted-init-files ()
  "The list of absolute init-file namestrings trusted by exact path
(see *AUTOLISP-TRUSTED-INIT-FILES*)."
  (copy-list clautolisp.autolisp-runtime.internal::*autolisp-trusted-init-files*))

(defun set-autolisp-trusted-init-files (paths)
  "Register PATHS (pathnames or namestrings) as the trusted init files.
Stored as namestrings; nil / blank entries are dropped. Called by the
launch wiring after resolving the user init files (empty under
--no-init)."
  (setf clautolisp.autolisp-runtime.internal::*autolisp-trusted-init-files*
        (loop for p in paths
              for s = (and p (namestring p))
              when (and s (plusp (length s))) collect s)))

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

(defun runtime-session-default-source-encoding (session)
  "Return SESSION's user-configured source-file encoding override
(a keyword such as :UTF-8 / :ISO-8859-1 / :WINDOWS-1252), or NIL
when no override was set. Honoured by AUTOLISP-LOAD-FILE-IN-CONTEXT
for loads without an explicit :external-format. Set by the CLI's
`-e ENC' flag."
  (clautolisp.autolisp-runtime.internal::runtime-session-default-source-encoding
   session))

(defun set-runtime-session-default-source-encoding (session encoding)
  "Install ENCODING (a keyword or NIL) as SESSION's source-file
encoding override. See RUNTIME-SESSION-DEFAULT-SOURCE-ENCODING for
how it's consumed."
  (setf (clautolisp.autolisp-runtime.internal::runtime-session-default-source-encoding
         session)
        encoding))

(defun set-default-source-encoding (context encoding)
  "Convenience setter for callers holding an EVALUATION-CONTEXT
(the shape the runtime exposes outside its session struct). Installs
ENCODING on the context's underlying session."
  (let ((session (clautolisp.autolisp-runtime.internal::evaluation-context-session
                  context)))
    (when session
      (set-runtime-session-default-source-encoding session encoding))))

;;; --- POSIX locale probe --------------------------------------------
;;;
;;; The CLI's `-e ENC' is one way to set the session's source-file
;;; encoding override. The other — implicit and very common — is the
;;; POSIX locale: a host with LC_CTYPE=en_US.UTF-8 (or LC_ALL, or
;;; LANG) is telling every program "treat byte streams as UTF-8 by
;;; default." We honour the same convention so the user doesn't have
;;; to spell `-e utf-8' explicitly on a UTF-8 host.
;;;
;;; Precedence (POSIX, see also issues/open/lc-environment.txt):
;;;   LC_ALL  →  LC_CTYPE  →  LANG  →  C
;;;
;;; The OTHER LC_* categories (LC_COLLATE, LC_TIME, LC_NUMERIC, …)
;;; are intentionally NOT consulted for source-file encoding: they
;;; govern strings comparison, dates, decimal separators, etc., not
;;; byte-stream interpretation. Using them for file encoding would be
;;; misuse of the standard. If the runtime ever localises error
;;; messages or honours decimal separators via locale, *those*
;;; features will consult their own LC_MESSAGES / LC_NUMERIC.

(defun parse-locale-encoding-string (s)
  "Map an encoding suffix (\"UTF-8\", \"utf8\", \"ISO-8859-1\",
\"latin1\", \"cp1252\", …) to a Lisp external-format keyword, or
return NIL when nothing recognisable comes through. Used by
LOCALE-DEFAULT-SOURCE-ENCODING."
  (cond
    ((null s) nil)
    ((zerop (length s)) nil)
    ((or (string-equal s "utf-8") (string-equal s "utf8"))      :utf-8)
    ((or (string-equal s "iso-8859-1") (string-equal s "iso88591")
         (string-equal s "latin-1")    (string-equal s "latin1"))
                                                                :iso-8859-1)
    ((or (string-equal s "windows-1252") (string-equal s "cp1252"))
                                                                :windows-1252)
    ((or (string-equal s "ascii") (string-equal s "us-ascii"))  :ascii)
    (t
     ;; Unknown encodings pass through as upper-cased keywords —
     ;; the underlying Lisp's OPEN will surface a clear error if
     ;; it can't honour them.
     (intern (string-upcase s) :keyword))))

(defun parse-posix-locale (value)
  "Extract the encoding suffix of a POSIX locale string such as
\"en_US.UTF-8\", \"fr_FR.ISO-8859-1@euro\", or just \"C\".
Returns the parsed external-format keyword (via
PARSE-LOCALE-ENCODING-STRING) or NIL when no encoding portion is
present. Strips a trailing `@modifier' segment."
  (when (and value (plusp (length value)))
    (let ((dot (position #\. value)))
      (when dot
        (let* ((tail (subseq value (1+ dot)))
               (at   (position #\@ tail))
               (raw  (if at (subseq tail 0 at) tail)))
          (parse-locale-encoding-string raw))))))

(defun locale-default-source-encoding ()
  "Resolve the host's default source-file encoding from the POSIX
locale environment.

Probes (encoding.issue order — LANG before LC_CTYPE):
  1. LC_ALL    — global override.
  2. LANG      — user-visible language + encoding selector.
  3. LC_CTYPE  — character classification category, last-resort
                 because users rarely set it explicitly while LANG
                 is the conventional knob shells expose.

The user-facing order intentionally deviates from POSIX's
LC_ALL > LC_CTYPE > LANG. Most distributions set LANG and leave
LC_CTYPE unset, so probing LANG first gives the user-observable
encoding the higher priority.

Returns a keyword (e.g. :UTF-8) or NIL when nothing is set or
the resolved locale carries no encoding suffix (the `C' / `POSIX'
case)."
  (or (parse-posix-locale (uiop:getenv "LC_ALL"))
      (parse-posix-locale (uiop:getenv "LANG"))
      (parse-posix-locale (uiop:getenv "LC_CTYPE"))))

(defun runtime-session-dialect (session)
  "Return the dialect descriptor SESSION was instantiated with."
  (clautolisp.autolisp-runtime.internal::runtime-session-dialect session))

(defun set-runtime-session-dialect (session dialect)
  "Replace SESSION's dialect descriptor. Useful for tools that switch
profiles between subordinate evaluations within a single session."
  (setf (clautolisp.autolisp-runtime.internal::runtime-session-dialect session)
        dialect))

(defun %autolisp-dialect-from-variable (context)
  "If the AutoLISP variable *AUTOLISP-DIALECT* is bound in CONTEXT to a
symbol (or string) naming a known dialect, return that dialect
descriptor; otherwise NIL. This lets `(setq *AUTOLISP-DIALECT* 'lax)`
change the active dialect dynamically at runtime
(alfe-clautolisp-dialect.issue point 5). Heavily guarded: any failure
(symbol table not ready, odd value, unknown name) yields NIL so the
caller falls back to the session dialect."
  (ignore-errors
   (let ((sym (find-autolisp-symbol "*AUTOLISP-DIALECT*")))
     (when sym
       (multiple-value-bind (value boundp) (lookup-variable sym context)
         (when (and boundp value)
           (let ((name (typecase value
                         (string value)
                         (t (ignore-errors (autolisp-symbol-name value))))))
             (when (and name (or (stringp name) (symbolp name)))
               (clautolisp.autolisp-reader:find-autolisp-dialect name)))))))))

(defun current-evaluation-dialect (&optional (context (current-evaluation-context)))
  "Return the active dialect. Precedence: the runtime *AUTOLISP-DIALECT*
variable (when it names a known dialect) over CONTEXT's session
dialect over the strict default. The variable override makes
`(setq *AUTOLISP-DIALECT* 'lax)` take effect immediately for every
subsequent dialect-sensitive operation."
  (or (and context (%autolisp-dialect-from-variable context))
      (and context
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

(defun runtime-session-exit-status (session)
  (clautolisp.autolisp-runtime.internal::runtime-session-exit-status session))

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

(defun autolisp-exit-status (&optional (context (current-evaluation-context)))
  "Read the pending clautolisp exit status (the value last stored by
(autolisp-set-status …); 0 when never set)."
  (runtime-session-exit-status (evaluation-context-session context)))

(defun set-autolisp-exit-status (value &optional (context (current-evaluation-context)))
  "Store VALUE (an integer) as the pending clautolisp exit status on
CONTEXT's session. Returns VALUE."
  (setf (clautolisp.autolisp-runtime.internal::runtime-session-exit-status
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
           (eq code :load-untrusted-file)
           (eq code :open-untrusted-file)
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

(defun binding-cell-doc (cell)
  (clautolisp.autolisp-runtime.internal::binding-cell-doc cell))

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

;;; --- Dynamic-frame introspection for the debugger (spec §9) --------
;;
;; The debugger walks the dynamic-frame chain to build the binding stack
;; (§9.4) and reads/writes individual frames' bindings — including a
;; currently-shadowed one — without going through ordinary lookup. These
;; thin accessors expose just what it needs, keeping it off the runtime's
;; internal package.

(defun dynamic-frame-parent (frame)
  "The frame FRAME shadows, or NIL."
  (clautolisp.autolisp-runtime.internal::dynamic-frame-parent frame))

(defun dynamic-frame-symbols (frame)
  "List of AutoLISP symbols bound *directly* in FRAME (not its parents),
i.e. the shadowings this frame introduced."
  (loop for symbol being the hash-keys
          of (clautolisp.autolisp-runtime.internal::dynamic-frame-bindings frame)
        collect symbol))

(defun dynamic-frame-binding-value (frame symbol)
  "Read SYMBOL's binding in FRAME only. Returns (values value bound-p);
bound-p is NIL when FRAME has no binding for SYMBOL."
  (let ((binding (gethash symbol
                          (clautolisp.autolisp-runtime.internal::dynamic-frame-bindings frame))))
    (if binding
        (values (clautolisp.autolisp-runtime.internal::dynamic-binding-value binding)
                (clautolisp.autolisp-runtime.internal::dynamic-binding-bound-p binding))
        (values nil nil))))

(defun set-dynamic-frame-binding-value (frame symbol value)
  "Write SYMBOL's binding in FRAME only (the debugger's shadowed-binding
write, §9.4). Signals if FRAME has no binding for SYMBOL — the debugger
must not create a new frame-local binding mid-execution (§16.1)."
  (let ((binding (gethash symbol
                          (clautolisp.autolisp-runtime.internal::dynamic-frame-bindings frame))))
    (unless binding
      (signal-autolisp-runtime-error
       :no-such-frame-binding
       "Frame has no binding for ~A to write." symbol))
    (setf (clautolisp.autolisp-runtime.internal::dynamic-binding-value binding) value
          (clautolisp.autolisp-runtime.internal::dynamic-binding-bound-p binding) t)
    value))

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

(defun lookup-documentation (symbol &optional (context (current-evaluation-context)))
  "Walk the dynamic frame chain like LOOKUP-VARIABLE; return the
`doc' slot of the innermost binding for SYMBOL. Returns nil for
an unbound symbol or for a binding with no recorded doc.

The returned value is a tagged list:
  nil                — no documentation.
  (function \"STR\")   — last installed by DEFUN with a preceding ;|…|;.
  (variable \"STR\")   — last installed by SETQ with a preceding ;|…|;.

The bare doc-string is extracted by CLAUTOLISP-DOCUMENTATION via
cadr; the head symbol is read by CLAUTOLISP-DOCUMENTATION-KIND
via car. See source-aware-defun-documentation.issue for the
update-rule table."
  (let ((binding (find-dynamic-binding symbol (evaluation-context-dynamic-frame context))))
    (cond
      (binding
       (clautolisp.autolisp-runtime.internal::dynamic-binding-doc binding))
      (t
       (let ((cell (namespace-binding-cell (evaluation-context-current-namespace context)
                                           symbol
                                           :createp nil)))
         (and cell (binding-cell-doc cell)))))))

(defun set-binding-doc (symbol new-doc &optional (context (current-evaluation-context)))
  "Install NEW-DOC (nil or a (function|variable \"STR\") tag) on
the doc slot of the innermost binding cell for SYMBOL. The
binding is expected to exist — callers are SET-VARIABLE /
SET-FUNCTION wrappers, which have just created or updated it.
Silently no-ops when no cell exists (defensive; should not
happen in the documented call sites)."
  (let ((binding (find-dynamic-binding symbol (evaluation-context-dynamic-frame context))))
    (cond
      (binding
       (setf (clautolisp.autolisp-runtime.internal::dynamic-binding-doc binding) new-doc))
      (t
       (let ((cell (namespace-binding-cell (evaluation-context-current-namespace context)
                                           symbol
                                           :createp nil)))
         (when cell
           (setf (clautolisp.autolisp-runtime.internal::binding-cell-doc cell) new-doc))))))
  new-doc)

(defun callable-value-p (value)
  "True iff VALUE is something AutoLISP can call in operator
position: a built-in SUBR, a user-defined USUBR, or a literal
LAMBDA-form list (e.g. `(LAMBDA (X) (PRINC X))`) passed through
a parameter via `(function (lambda …))'. Function-call dispatch
unwraps the lambda-form lazily into a USUBR via EVAL-LAMBDA-FORM
when it actually invokes the binding."
  (or (typep value 'autolisp-subr)
      (typep value 'autolisp-usubr)
      (lambda-form-p value)))

(defun lookup-function (symbol &optional (context (current-evaluation-context)))
  ;; Walk the dynamic-frame chain looking for a *callable* binding,
  ;; falling back to the namespace cell. Non-callable shadows are
  ;; transparent in function position: in a lisp-1 with `/`-locals,
  ;; entering `(defun foo (/ helper) ...)` shadows HELPER to nil — yet
  ;; a later `(setq helper (function bar))` followed by
  ;; `(apply helper (list 1))` MUST be able to look past the nil
  ;; shadow that the parameter list installed and resolve HELPER to
  ;; the function it now holds. Equally, when a function value is
  ;; passed through a parameter — the portable HOF idiom documented in
  ;; autolisp-spec ch.3 (FUNCTION / APPLY) — the parameter binds the
  ;; *symbol*, which is itself not callable; APPLY must then resolve
  ;; the symbol against the surrounding scope, not stop at the
  ;; parameter shadow. This rule yields the same result as BricsCAD's
  ;; documented behaviour for symbol-via-parameter resolution.
  ;;
  ;; Lambda-form bindings — values shaped (LAMBDA ARGS BODY...) —
  ;; are also accepted as callables here. `(function (lambda …))'
  ;; returns the unevaluated list per the spec (FUNCTION ≡ QUOTE),
  ;; so a parameter receiving such a value carries a *list*, not a
  ;; pre-cooked USUBR. Issue function-value.issue demonstrates the
  ;; failure mode when this path is omitted: the parameter shadow
  ;; is invisible in operator position and the call falls through
  ;; to a same-named global. The actual lambda-form -> usubr
  ;; coercion happens lazily in CALL-AUTOLISP-FUNCTION-IN-CONTEXT
  ;; so the dynamic context at the call site is the one EVAL-LAMBDA-
  ;; FORM captures (matching the late-resolution rule above).
  (loop for frame = (evaluation-context-dynamic-frame context)
                then (clautolisp.autolisp-runtime.internal::dynamic-frame-parent frame)
        while frame
        for binding = (gethash symbol
                               (clautolisp.autolisp-runtime.internal::dynamic-frame-bindings
                                frame))
        when (and binding
                  (clautolisp.autolisp-runtime.internal::dynamic-binding-bound-p binding)
                  (callable-value-p
                   (clautolisp.autolisp-runtime.internal::dynamic-binding-value binding)))
          do (return-from lookup-function
               (values (clautolisp.autolisp-runtime.internal::dynamic-binding-value binding)
                       t
                       :dynamic)))
  (let* ((cell (namespace-binding-cell (evaluation-context-current-namespace context)
                                       symbol
                                       :createp nil))
         (boundp (and cell (binding-cell-bound-p cell)))
         (value  (and boundp (binding-cell-value cell))))
    (if (and boundp (callable-value-p value))
        (values value t :namespace)
        (values nil nil :namespace))))

(defun set-function (symbol function &optional (context (current-evaluation-context)))
  ;; Mirror SET-VARIABLE: if a dynamic shadow for SYMBOL already
  ;; exists (typically installed by a `/`-locals declaration), update
  ;; the shadow; otherwise write through to the namespace cell. This
  ;; keeps `defun` aligned with `setq` in a lisp-1: an inner
  ;; `(defun helper ...)` inside `(defun outer (/ helper) ...)` should
  ;; rebind the local, not stomp the surrounding/global definition.
  (let ((binding (find-dynamic-binding
                  symbol
                  (evaluation-context-dynamic-frame context))))
    (if binding
        (setf (clautolisp.autolisp-runtime.internal::dynamic-binding-value binding) function
              (clautolisp.autolisp-runtime.internal::dynamic-binding-bound-p binding) t)
        (let ((cell (namespace-binding-cell
                     (evaluation-context-current-namespace context) symbol)))
          (setf (clautolisp.autolisp-runtime.internal::binding-cell-value cell) function
                (clautolisp.autolisp-runtime.internal::binding-cell-bound-p cell) t
                (clautolisp.autolisp-runtime.internal::binding-cell-compatibility-definition cell)
                nil))))
  function)

(defun set-autolisp-symbol-value (symbol value)
  (set-variable symbol value))

(defun set-autolisp-symbol-function (symbol function)
  (set-function symbol function))

(defun autolisp-makunbound (symbol &optional (context (current-evaluation-context)))
  "Clear SYMBOL's binding in the current namespace (Lisp-1: the single
value/function cell), returning SYMBOL. Dynamic-frame shadows are left
untouched — this is a top-level operation, the inverse of
SET-AUTOLISP-SYMBOL-FUNCTION / -VALUE for a symbol that had no prior
binding. A no-op when SYMBOL has no namespace cell yet."
  (let ((cell (namespace-binding-cell
               (evaluation-context-current-namespace context) symbol :createp nil)))
    (when cell
      (setf (clautolisp.autolisp-runtime.internal::binding-cell-value cell) nil
            (clautolisp.autolisp-runtime.internal::binding-cell-bound-p cell) nil
            (clautolisp.autolisp-runtime.internal::binding-cell-compatibility-definition
             cell) nil)))
  symbol)

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

(defun autolisp-usubr-instrumented-body (object)
  (clautolisp.autolisp-runtime.internal::autolisp-usubr-instrumented-body object))

(defun (setf autolisp-usubr-instrumented-body) (value object)
  (setf (clautolisp.autolisp-runtime.internal::autolisp-usubr-instrumented-body object)
        value))

(defun autolisp-usubr-debug-metadata (object)
  (clautolisp.autolisp-runtime.internal::autolisp-usubr-debug-metadata object))

(defun (setf autolisp-usubr-debug-metadata) (value object)
  (setf (clautolisp.autolisp-runtime.internal::autolisp-usubr-debug-metadata object)
        value))

(defun make-autolisp-catch-all-error (message condition)
  (clautolisp.autolisp-runtime.internal::make-autolisp-catch-all-error
   :message message
   :condition condition))

(defun autolisp-catch-all-error-message (object)
  (clautolisp.autolisp-runtime.internal::autolisp-catch-all-error-message object))

(defun autolisp-catch-all-error-condition (object)
  (clautolisp.autolisp-runtime.internal::autolisp-catch-all-error-condition object))

(defun autolisp-catch-all-error-call-stack (object)
  "Return the AutoLISP call-stack snapshot captured at the time the
underlying autolisp-runtime-error was raised, or NIL if the catch-all
error wraps a non-autolisp-runtime condition."
  (let ((condition (autolisp-catch-all-error-condition object)))
    (if (typep condition 'autolisp-runtime-error)
        (autolisp-runtime-error-call-stack condition)
        nil)))

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

(defparameter *clal-on-error* :quit
  "The error policy when an uncaught AutoLISP error escapes to the top level
(debugger command reference §10): one of :QUIT (report and exit non-zero — the
default and the historical clautolisp behavior), :DEBUG (break into the aldo
debugger), or :IGNORE (let the AutoLISP *error* / default handler run, no
debugger). Set by the clautolisp CLI's --on-error option; user code and init
files may rebind it (e.g. (let ((*clal-on-error* :debug)) …)) to shadow it
around a suspect region.")

(defparameter *clal-on-interrupt* :debug
  "The interrupt policy when the process receives SIGINT (Control-C)
(debugger-public-interface-and-on-error.issue Part B): one of :DEBUG (break
into the aldo debugger at the interrupt point — the default), :IGNORE (the
interrupt is ignored and execution resumes), or :QUIT (the process quits,
exit status 130). Set by the clautolisp CLI's --on-interrupt option; the
AutoLISP variable *CLAL-ON-INTERRUPT* mirrors it and is consulted LIVE at
each interrupt, so user code may change the policy at runtime.")

(defparameter *clal-on-quit* :quit
  "The QUIT-event policy when (quit) / (exit) is called
(debugger-public-interface-and-on-error.issue Part B): :QUIT (the process
quits — the default) or :DEBUG (the aldo debugger is entered from QUIT
before the stack unwinds; continuing resumes the quit, aborting cancels
it). The QUIT event cannot be ignored. Set by the clautolisp CLI's
--on-quit option; the AutoLISP variable *CLAL-ON-QUIT* mirrors it and is
consulted LIVE at each (quit) / (exit) call.")

(defparameter *clal-debugger-ui* :tui
  "The debugger user-interface selection (debugger command reference §10):
:TUI (the line/terminal UI), :NCURSES, or :ALDB (the Emacs front-end). Set
by the clautolisp CLI's --debugger-ui option, defaulting to the persisted
default-user-interface aldo setting. Mirrored to the AutoLISP variable
*CLAL-DEBUGGER-UI*.")

(defparameter *clal-aldb-listen* nil
  "The aldb (Emacs UI) transport requested on the CLI
(debugger-public-interface-and-on-error.issue Part C/D): an \"ADDRESS:PORT\"
string (--aldb-listen), :STDIO (--aldb-stdio), or NIL — no explicit request;
the default-aldb-listening-address / -port aldo settings apply. Mirrored to
the AutoLISP variable *CLAL-ALDB-LISTEN*.")

(defparameter *debugging* nil
  "Non-nil iff a debug session is active on the executing thread. It is
set once by the debugger's session entry and is NOT rebound per call.
While it is set, a USUBR call runs the function's INSTRUMENTED-BODY (the
woven %CLAL-POLL form tree) if the function HAS one, otherwise its plain
BODY (clautolisp-debugger plan §3a, revised by design note DN-2). Body
choice is therefore per function, not propagated along the call path: an
instrumented function is debugged wherever it is called from — including
through an uninstrumented library function, a higher-order function, or a
builtin — while an uninstrumented function always runs plain. NIL by
default: with no session active every call runs the plain body at full
speed.")

;;; --- vl-catch-all-apply integration for the debugger (spec §10.2) ---
;;
;; A frame describing an active vl-catch-all-apply, recorded on
;; *autolisp-catch-stack* while the applied function runs so the debugger
;; snapshot can show the catch context (§9.2 catch-stack). The
;; vl-catch-all-apply builtin maintains the stack; the debugger reads it.

(defstruct catch-frame
  function
  (arguments '() :type list))

(defparameter *autolisp-catch-stack* '()
  "Active vl-catch-all-apply frames on the current thread, innermost
first (spec §10.2). Bound/pushed by the vl-catch-all-apply builtin; read
by the debugger's snapshot. NIL when no catch is active.")

(defparameter *autolisp-caught-error-hook* nil
  "When non-nil, a function the vl-catch-all-apply builtin calls with the
caught autolisp-runtime-error BEFORE returning the AutoLISP error object
(spec §10.2 'break on caught error'). The debugger installs this only when
break-on-caught is enabled; NIL by default (off).")

(defparameter *debug-define-command-hook* nil
  "When non-nil, a function (NAMES FUNCTION DOC) the CLAL-DEFINE-DEBUGGER-COMMAND
builtin calls to register an AutoLISP-defined debugger command (command
reference §8). NAMES is a CL list (KEY WORD…) of strings, FUNCTION the AutoLISP
command body, DOC a string or NIL. The aldo debugger UI installs it; NIL (a
no-op) when the debug-ui layer is absent. CLAL-DEFINE-DEBUGGER-COMMAND is the
deprecated equivalent of (CLAL-DEFINE-COMMAND \"ALDO\" …), which goes through
*DEFINE-INTERACTOR-COMMAND-HOOK*.")

(defparameter *define-interactor-command-hook* nil
  "When non-nil, a function (INTERACTOR-NAME NAMES FUNCTION DOC) the
CLAL-DEFINE-COMMAND builtin calls to register an AutoLISP-defined user
command of the NAMED interactor (interactor-design-revision.issue D7).
INTERACTOR-NAME and the NAMES list (KEY WORD…) are CL strings, FUNCTION the
AutoLISP command body, DOC a string or NIL. The debugger UI installs it; NIL
(a no-op) when that layer is absent.")

(defparameter *list-interactor-names-hook* nil
  "When non-nil, a thunk returning the CL list of registered interactor name
strings, for the CLAL-LIST-INTERACTOR-NAMES builtin. The debugger UI
installs it; NIL (an empty list) when that layer is absent.")

(defparameter *debug-break-hook* nil
  "When non-nil, a function of one optional MESSAGE argument that the
CLAL-BREAK / CLAL-INVOKE-DEBUGGER builtins call to drop into the aldo debugger
at the current poll point — the programmatic debugger entry (debugger command
reference §1). The aldo debugger installs it when its system is loaded; it is a
no-op (returns without stopping) unless a debug session is active on the
thread. NIL when the debug system is absent, making CLAL-BREAK a no-op.")

(defparameter *debug-nav-hook* nil
  "When non-nil, a function (REQUEST) the CLAL-NAV-FUNCTION / CLAL-NAV-FILE /
CLAL-NAV-DIRECTORY builtins call to enter the aldo debugger in a navigation mode
(pre-debug navigation, aldo-pre-debug.issue). REQUEST is a CL list: (:function
NAME) navigates a function's source; (:file PATH LINE) a file's top-level forms
(LINE may be NIL); (:directory PATH) a directory listing (PATH may be NIL for the
current directory). The aldo debugger UI installs it; NIL (a no-op) when the
debug-ui layer is absent or no debug session is active.")

(defparameter *debug-select-file-hook* nil
  "When non-nil, a function (FILE LINE) the CLAL-SELECT-FILE builtin calls to make
the debugger's `ls' list-source command show FILE at LINE (aldo-pre-debug.issue).
The aldo debugger installs it; NIL (a no-op) when the debug system is absent.")

(defparameter *debug-command-hook* nil
  "When non-nil, a function (COMMAND-STRING) that runs one aldo debugger command
in the active debug session and returns its resume directive (or NIL). CLAL-SEDIT
calls it for the editor's `debug'/`aldo' prefix, so debugger commands (e.g.
`aldo help') work from within sedit. The tool installs it, bound to the running
session's UI, while a debug session is attached; NIL (a no-op) otherwise.")

(defparameter *dribble-hook* nil
  "When non-nil, a function (PATH INTERACTORS) the CLAL-DRIBBLE builtin calls
to toggle/redirect the REPL dribble (dribble.issue). PATH is a CL string or
NIL (NIL toggles: start on the default path when off, stop when on);
INTERACTORS is :ALL, a CL list of interactor name strings, or NIL (NIL means
consult the AutoLISP variable *CLAL-DRIBBLE-INTERACTORS* — the hook
implementation reads it from the current evaluation context). Returns the
absolute namestring of the dribble file it opened, or NIL when it stopped
dribbling. The clautolisp tool installs it; NIL (a no-op) when no
dribble-capable front-end is attached.")

(defparameter *instrument-usubr-hook* nil
  "When non-nil, a function (USUBR) that weaves USUBR's instrumented fork and
debug-metadata in place (clautolisp.debug:instrument-usubr). The aldo debugger
installs it when its system loads; NIL when the debug system is absent. Lets the
runtime instrument functions for stepping/breakpoints — lazily, on a function's
first call under a debug session — without the runtime depending on the debugger
layer (the same dependency-inversion as *debug-break-hook*).")

(defparameter *debug-instrumentation-enabled* t
  "Whether the runtime weaves instrumented forks while debugging. Reflects the
CLAL-OPTIMIZATION DEBUG level (CLAL-OPTIMIZE sets it: T when DEBUG>0, NIL under
SPACE / DEBUG 0). When NIL, debugged code runs its plain body — no poll points,
no stepping — trading debuggability for speed/size (the fork matrix's DEBUG-0
rows). T by default, so a debug session instruments what it runs.")

(defun maybe-instrument-usubr (function)
  "Lazily weave FUNCTION's instrumented fork on its first call under a debug
session, when instrumentation is enabled and the debugger layer is loaded.
Returns the instrumented body (now non-nil), or NIL if instrumentation is
disabled / the debugger is absent, so the caller falls back to the plain body."
  (when (and *debug-instrumentation-enabled* *instrument-usubr-hook*)
    (ignore-errors (funcall *instrument-usubr-hook* function))
    (autolisp-usubr-instrumented-body function)))

(defun append-proper-and-tail (elements tail)
  (if (null elements)
      tail
      (cons (first elements)
            (append-proper-and-tail (rest elements) tail))))

(defun reader-object->runtime-value (object)
  ;; CAUTION (DEBUGGER): every branch below intentionally drops the
  ;; reader-object's source span. The runtime-value type is positional-
  ;; info-free: strings carry only their value, integers/reals only
  ;; their value, symbol-objects only their canonical name, cons-
  ;; objects only their element/tail structure, and quote-objects only
  ;; the quoted form.
  ;;
  ;; The debugger work (clautolisp-debugger) took exactly the side-table
  ;; route this caution predicted: source positions are NOT threaded
  ;; into the runtime values here. Instead, when
  ;; clautolisp.source:*track-source-positions* is set (a debug load),
  ;; the COMPOUND-form branches below record each freshly-consed runtime
  ;; cons against the reader span it came from, in the EQ-keyed parallel
  ;; side-table clautolisp.source:*source-position-table* (see the
  ;; CONS-OBJECT and QUOTE-OBJECT branches). clautolisp.source:position-of
  ;; then maps an executing compound form back to (file line column).
  ;; Atoms stay bare (a fixnum / interned symbol cannot be EQ-keyed
  ;; uniquely), so the debugger resolves an atom's position through its
  ;; enclosing form's per-function form-id table, not through this
  ;; function. The NORMALISATION below is the right place; the SPAN
  ;; capture is a side effect layered on top, never a different lowering.
  ;;
  ;; The NIL normalisation in the SYMBOL-OBJECT branch is consistent
  ;; with that side-table direction: CL nil is a singleton with no
  ;; meaningful source position (it appears from a hundred call sites
  ;; — literal `nil`, literal `()`, function returns, default arg
  ;; values, …), so it is never span-keyed; only compound conses are.
  (typecase object
    (symbol-object
     ;; AutoLISP defines nil as the symbol named NIL — by definition
     ;; (a b c . nil) is identical to (a b c). Normalising the
     ;; reader-time symbol NIL to CL nil here means downstream
     ;; proper-list predicates, REVERSE / LENGTH / MAPCAR / etc.
     ;; see the canonical empty-list terminator instead of an
     ;; autolisp-symbol struct that happens to print as "nil".
     ;;
     ;; T is intentionally NOT normalised the same way: (a b c . T)
     ;; is a legitimate improper list (T is just a symbol, not a
     ;; list terminator), so collapsing source-level 'T to CL t
     ;; would change observable list shape, not just print form.
     (let ((name (symbol-object-canonical-name object)))
       (cond
         ((string-equal name "NIL")
          nil)
         (t
          (intern-autolisp-symbol name :original-name name)))))
    (string-object
     (clautolisp.autolisp-runtime.internal::make-autolisp-string
      :value (string-object-value object)))
    (integer-object
     (integer-object-value object))
    (real-object
     (real-object-value object))
    (cons-object
     (let* ((elements (mapcar #'reader-object->runtime-value
                              (cons-object-elements object)))
            (result (if (cons-object-dotted-p object)
                        (append-proper-and-tail
                         elements
                         (reader-object->runtime-value (cons-object-tail object)))
                        elements))
            (doc (cons-object-preceding-doc object)))
       (when (and clautolisp.source:*track-source-positions* (consp result))
         (clautolisp.source:note-position result (cons-object-span object)))
       ;; Source-aware-defun-documentation: if the parsed cons-object
       ;; carried a ;|…|; block-comment doc, register that text against
       ;; the fresh CL cons we are returning. eval-defun-form /
       ;; eval-setq-form consult *preceding-docs* via *current-form*.
       (when (and doc (consp result))
         (register-preceding-doc result doc))
       result))
    (quote-object
     (let ((result (list (intern-autolisp-symbol "QUOTE")
                         (reader-object->runtime-value (quote-object-object object)))))
       (when clautolisp.source:*track-source-positions*
         (clautolisp.source:note-position result (quote-object-span object)))
       result))
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

(defun autolisp-ampersand-symbol-p (symbol)
  "T iff SYMBOL is the AutoLISP rest-parameter separator — either
the bare `&' (clautolisp's original spelling proposed in
`issues/open/variadic-functions.issue') or `&REST' (BricsCAD V26's
spelling, confirmed by Bricsys support and observed in the user's
own `(defun foo (&rest args) …)' transcripts). Match is
case-insensitive on the symbol name only; we do NOT implement a
full Common Lisp lambda-list parser — `&body', `&optional', `&key'
remain unsupported."
  (and (typep symbol 'autolisp-symbol)
       (let ((name (string-upcase (autolisp-symbol-name symbol))))
         (or (string= "&" name)
             (string= "&REST" name)))))

(defun autolisp-ampersand-spelling (symbol)
  "Return :ampersand if SYMBOL is `&', :and-rest if it is `&REST'
(any case). Returns NIL when SYMBOL is not a recognised
rest-separator. Used by the dialect-warning path to format the
exact spelling the user wrote."
  (when (typep symbol 'autolisp-symbol)
    (let ((name (string-upcase (autolisp-symbol-name symbol))))
      (cond
        ((string= "&" name)     :ampersand)
        ((string= "&REST" name) :and-rest)
        (t nil)))))

(defun %portability-warning-occurrence-seen-p (occurrence)
  "T iff this OCCURRENCE (a source object identity — the lambda-list
cons of the offending defun/lambda) has already produced a dialect
portability warning in the current run. Records it as seen when it
had not been. Keyed by EQ object identity in the active session's
`portability-warnings-seen' table, so the dedup is once-per-source-
occurrence and resets with a fresh session. When OCCURRENCE is NIL
or no session is reachable, dedup is skipped (always emit)."
  (let* ((context (ignore-errors (current-evaluation-context)))
         (session (and context
                       (clautolisp.autolisp-runtime.internal::evaluation-context-session
                        context)))
         (table   (and session
                       (clautolisp.autolisp-runtime.internal::runtime-session-portability-warnings-seen
                        session))))
    (cond
      ((or (null occurrence) (null table)) nil)
      ((gethash occurrence table) t)
      (t (setf (gethash occurrence table) t) nil))))

(defun emit-lambda-list-extension-warning (spelling who &optional occurrence)
  "When a defun/lambda lambda-list uses a rest-parameter separator,
emit a `[lambda-list-extension]' dialect portability warning
(autolisp-spec ch.25) unless the current dialect explicitly accepts
that spelling.

Per `issues/open/bricscad-undocumented-clisms.issue' and the user's
2026-06-07 ruling:

  - :clautolisp dialect — silent for both `&' and `&REST' (both
    are blessed by the spec extension).
  - :bricscad-v26 dialect — silent for `&REST' (BricsCAD's native
    undocumented form), warns for `&' (clautolisp's spelling that
    BricsCAD does NOT accept).
  - :lax dialect — silent for everything. `--lax' is the catch-all
    `accept every vendor's extensions without complaining' mode;
    extending that contract to lambda-list extensions matches the
    same dialect's behavior on encoding diagnostics
    (see `%enc-dialect-is-lax-p').
  - :strict, :autocad-2026 — warn for both spellings (they are
    non-portable across vendors).

Once-per-occurrence (autolisp-spec ch.25): a warning fires at most
once per run for each distinct source OCCURRENCE (the lambda-list
cons identity). Re-evaluating the SAME defun/lambda — e.g. inside a
loop — is silent after the first hit; a DIFFERENT defun warns on its
own first evaluation. A never-reached (guarded) occurrence never
warns because this function only runs when evaluation reaches it.

Escalation knob (autolisp-spec ch.25): when the active dialect's
`portability-warning-mode' is `:error' (default `:warn'), a
non-silent occurrence signals an AutoLISP runtime error instead of
printing — the opt-in `warning->error' knob mirroring
`:unbound-variable-mode :strict-error'. It is non-conforming (it
changes whether the program runs) and is never a dialect default.

The advisory warning is informational only — the function is defined
as usual and runs normally. WHO is a short string identifying the
caller (e.g. \"DEFUN\" or \"LAMBDA\") for the diagnostic prefix.
Warnings go to *ERROR-OUTPUT*, which a normal `clautolisp' / `alfe'
run surfaces (stderr is not swallowed by the quiet/verbosity knobs)."
  (let* ((dialect (ignore-errors (current-evaluation-dialect)))
         (name (and dialect
                    (clautolisp.autolisp-reader:autolisp-dialect-name dialect)))
         (mode (or (and dialect
                        (ignore-errors
                         (clautolisp.autolisp-reader:autolisp-dialect-portability-warning-mode
                          dialect)))
                   :warn))
         (silent-p
           (case name
             ((:clautolisp :lax) t)
             ((:bricscad-v26) (eq spelling :and-rest))
             (t nil)))
         (token (case spelling
                  (:ampersand "&")
                  (:and-rest  "&REST")
                  (t "<rest-separator>"))))
    (unless silent-p
      (when (eq mode :error)
        ;; Escalation: turn the advisory into a hard error. This runs
        ;; before dedup — the first reached occurrence aborts the run.
        (signal-autolisp-runtime-error
         :non-portable-construct
         "~A: `~A' is a clautolisp variadic-function extension, not portable to dialect ~(~A~); --portability-warning-mode error escalates it to an error."
         who token (or name "default")))
      (unless (%portability-warning-occurrence-seen-p occurrence)
        (format *error-output*
                "~&[lambda-list-extension] ~A: `~A' is a clautolisp ~
variadic-function extension; --dialect ~(~A~) flags it as ~
non-portable. Use --dialect clautolisp to silence, or rewrite ~
without a rest parameter.~%"
                who token (or name "default"))))))

(defun split-usubr-lambda-list (lambda-list)
  "Walk LAMBDA-LIST and split it into the three positional groups
clautolisp's `defun' / `lambda' recognises:

  required* [`&' rest-param] [`/' locals*]

Return three values: REQUIRED (list of symbols), REST-PARAM (the
single symbol after `&', or NIL when no `&' is present), LOCALS
(list of symbols after `/').

Errors signalled:
  :invalid-lambda-list  — LAMBDA-LIST is not a proper list.
  :invalid-rest-parameter — `&' is present but the following slot
    is missing, is not a single symbol, or there is more than one
    symbol between `&' and `/'.

The `/'-locals slot stays exactly as before for back-compat with
every existing AutoLISP defun."
  (unless (listp lambda-list)
    (signal-autolisp-runtime-error
     :invalid-lambda-list
     "AutoLISP function lambda list must be a proper list, got ~S."
     lambda-list))
  (let* ((amp-pos   (position-if #'autolisp-ampersand-symbol-p lambda-list))
         (slash-pos (position-if #'autolisp-slash-symbol-p lambda-list)))
    (when (and amp-pos slash-pos (>= amp-pos slash-pos))
      ;; `&' appearing AFTER `/' is meaningless: it would name a
      ;; local. Refuse it explicitly so users hit a clean error
      ;; rather than a silent mis-bind.
      (signal-autolisp-runtime-error
       :invalid-rest-parameter
       "AutoLISP lambda list: `&' must precede `/', got ~S."
       lambda-list))
    (let* ((required (subseq lambda-list 0 (or amp-pos slash-pos
                                               (length lambda-list))))
           (rest-end (or slash-pos (length lambda-list)))
           (rest-slice (when amp-pos
                         (subseq lambda-list (1+ amp-pos) rest-end)))
           (locals (if slash-pos
                       (subseq lambda-list (1+ slash-pos))
                       '())))
      (when amp-pos
        (unless (= 1 (length rest-slice))
          (signal-autolisp-runtime-error
           :invalid-rest-parameter
           "AutoLISP lambda list: `&' must be followed by exactly one symbol, got ~S."
           rest-slice))
        (unless (typep (first rest-slice) 'autolisp-symbol)
          (signal-autolisp-runtime-error
           :invalid-rest-parameter
           "AutoLISP lambda list: rest-parameter after `&' must be a symbol, got ~S."
           (first rest-slice))))
      (values required
              (when amp-pos (first rest-slice))
              locals))))

(defun bind-usubr-frame (function arguments context)
  (multiple-value-bind (required rest-param locals)
      (split-usubr-lambda-list (autolisp-usubr-lambda-list function))
    (let ((req-count (length required))
          (arg-count (length arguments)))
      (cond
        (rest-param
         ;; Variadic: at least REQ-COUNT arguments are needed, no
         ;; upper bound. Excess arguments gather into REST-PARAM as
         ;; a proper list (NIL when there are exactly REQ-COUNT
         ;; arguments, matching `(princ)' / `(princ x)' / `(princ x
         ;; fh)' behavior the extension was designed to emulate).
         (when (< arg-count req-count)
           (signal-autolisp-runtime-error
            :wrong-number-of-arguments
            "AutoLISP function ~A expects at least ~D arguments, got ~D."
            (autolisp-usubr-name function)
            req-count
            arg-count)))
        (t
         (unless (= req-count arg-count)
           (signal-autolisp-runtime-error
            :wrong-number-of-arguments
            "AutoLISP function ~A expects ~D arguments, got ~D."
            (autolisp-usubr-name function)
            req-count
            arg-count)))))
    (push-dynamic-frame context)
    (loop for symbol in required
          for value in arguments
          do (bind-dynamic-variable symbol value context))
    (when rest-param
      (bind-dynamic-variable rest-param
                             (subseq arguments (length required))
                             context))
    (dolist (symbol locals)
      (bind-dynamic-variable symbol nil context))))

(defparameter *autolisp-trace-p* nil
  "When non-nil, every call into call-autolisp-function-in-context
emits an indented trace line on entry and exit. Toggle via the
clautolisp CLI's --trace flag, or set directly from user code.
For per-symbol filtering instead of session-wide instrumentation
see `*autolisp-traced-symbols*' and the TRACE / UNTRACE special
operators.")

(defparameter *autolisp-trace-depth* 0
  "Indentation level for the trace printer. Incremented on entry,
decremented on exit; visible as leading spaces in trace output.")

(defparameter *autolisp-trace-stream* nil
  "Stream the tracer writes to. nil means *trace-output*.")

(defparameter *autolisp-traced-symbols* (make-hash-table :test 'equal)
  "Upcased AutoLISP function-name strings whose invocations are
traced even when *autolisp-trace-p* is nil. Populated by the
TRACE special operator and emptied by UNTRACE called with no
arguments. Anonymous functions (lambdas without DEFUN) can't be
selected this way — they fall back to the session-wide
*autolisp-trace-p* flag.")

(defun autolisp-trace-stream ()
  (or *autolisp-trace-stream* *trace-output*))

(defun autolisp-function-name-for-trace (function)
  (cond
    ((typep function 'autolisp-subr)  (autolisp-subr-name function))
    ((typep function 'autolisp-usubr) (or (autolisp-usubr-name function) "<lambda>"))
    (t (format nil "~S" function))))

(defun autolisp-function-trace-p (function)
  "T iff FUNCTION's invocation should be traced — either the
session-wide *autolisp-trace-p* flag is on, or the function has
a name that's been registered via the TRACE special operator.
Anonymous lambdas (no name) fall through to the session-wide
flag only."
  (or *autolisp-trace-p*
      (let ((name (cond ((typep function 'autolisp-subr)
                         (autolisp-subr-name function))
                        ((typep function 'autolisp-usubr)
                         (autolisp-usubr-name function)))))
        (and name (gethash name *autolisp-traced-symbols*)))))

(defun autolisp-format-trace-value (value)
  ;; Compact one-line printer for trace-value display. Strings keep
  ;; their quotes; other values get princ'd via existing helpers
  ;; where available, falling back to ~S so even unfamiliar carriers
  ;; render readably.
  (cond
    ((null value) "nil")
    ((eq value t) "T")
    ((typep value 'autolisp-string)
     (format nil "~S" (autolisp-string-value value)))
    ((typep value 'autolisp-symbol)
     (autolisp-symbol-name value))
    ((numberp value) (format nil "~A" value))
    ((consp value)
     (let ((items (loop for cell on value
                        collect (autolisp-format-trace-value (car cell))
                        until (atom (cdr cell)))))
       (format nil "(~{~A~^ ~})" items)))
    (t (format nil "~S" value))))

(defun autolisp-trace-prefix ()
  (make-string (* 2 *autolisp-trace-depth*) :initial-element #\Space))

(defun autolisp-trace-enter (function arguments)
  (let ((stream (autolisp-trace-stream)))
    (format stream "~&~A-> (~A~{ ~A~})~%"
            (autolisp-trace-prefix)
            (autolisp-function-name-for-trace function)
            (mapcar #'autolisp-format-trace-value arguments))
    (force-output stream)))

(defun autolisp-trace-exit (function result)
  (let ((stream (autolisp-trace-stream)))
    (format stream "~&~A<- ~A => ~A~%"
            (autolisp-trace-prefix)
            (autolisp-function-name-for-trace function)
            (autolisp-format-trace-value result))
    (force-output stream)))

(defun call-autolisp-function-in-context (function context &rest arguments)
  ;; Lambda-form coercion: when FUNCTION is a literal
  ;; (LAMBDA ARGS BODY...) list — typically the value of a
  ;; parameter that received `(function (lambda …))' — wrap it
  ;; into a USUBR right here, so the dynamic context at the call
  ;; site (and not the original FUNCTION form's site) is what
  ;; gets captured. This makes the lisp-1 parameter-shadowing
  ;; path (issue function-value.issue) work without changing the
  ;; surface semantics of FUNCTION ≡ QUOTE.
  (when (lambda-form-p function)
    (setf function (eval-lambda-form (rest function) context)))
  (let ((clautolisp.autolisp-runtime.internal::*active-evaluation-context* context)
        ;; Capture the trace decision ONCE on entry. Per-symbol
        ;; trace state can change mid-call (e.g. the traced
        ;; function itself runs UNTRACE on its own name) but the
        ;; enter/exit lines must agree on whether this call is
        ;; instrumented or the depth counter will skew.
        (trace-this-call (autolisp-function-trace-p function)))
    (when trace-this-call
      (autolisp-trace-enter function arguments)
      (incf *autolisp-trace-depth*))
    (let ((result
            (cond
              ((typep function 'autolisp-subr)
               (let ((*autolisp-call-stack*
                      (cons (cons :subr
                                  (cons (autolisp-subr-name function) arguments))
                            *autolisp-call-stack*)))
                 (handler-case
                     (apply (autolisp-subr-function function) arguments)
                   (autolisp-runtime-error (condition)
                     (when trace-this-call
                       (decf *autolisp-trace-depth*)
                       (autolisp-trace-exit function (format nil "<error: ~A>" condition)))
                     (error condition))
                   (error (condition)
                     (when trace-this-call
                       (decf *autolisp-trace-depth*)
                       (autolisp-trace-exit function (format nil "<host-error: ~A>" condition)))
                     (error 'autolisp-runtime-error
                            :code :subr-call-host-error
                            :message (format nil
                                             "Common Lisp error while calling AutoLISP subr ~A: ~A"
                                             (autolisp-subr-name function)
                                             condition)
                            :details (list :subr (autolisp-subr-name function)
                                           :condition condition)
                            :call-stack (current-autolisp-call-stack))))))
              ((typep function 'autolisp-usubr)
               ;; Two-bodies dispatch (clautolisp-debugger plan §3a,
               ;; revised by design note DN-2): while a debug session is
               ;; active on this thread (*DEBUGGING*), a function that HAS
               ;; an instrumented body runs it; otherwise it runs its
               ;; plain body. Selection is PER FUNCTION, not propagated
               ;; along the call path: *DEBUGGING* is NOT rebound here, so
               ;; an instrumented function is debugged wherever it is
               ;; called from — including through an uninstrumented
               ;; library function, a higher-order function, or a builtin
               ;; — and an uninstrumented function always runs plain. With
               ;; no session active *DEBUGGING* is NIL and this reduces to
               ;; the original plain-body path at no cost.
               (let ((selected-body
                       (if *debugging*
                           (or (autolisp-usubr-instrumented-body function)
                               ;; Lazily weave the instrumented fork on this
                               ;; function's first call under a debug session
                               ;; (compiled-eval model): stepping/breakpoints
                               ;; then ride on it, and code defined before the
                               ;; session becomes debuggable without a separate
                               ;; instrument-on-defun pass. No cost when not
                               ;; debugging (*DEBUGGING* NIL short-circuits).
                               (maybe-instrument-usubr function)
                               (autolisp-usubr-body function))
                           (autolisp-usubr-body function))))
                 (let ((*autolisp-call-stack*
                        (cons (cons :usubr
                                    (cons (or (autolisp-usubr-name function) "<lambda>")
                                          arguments))
                              *autolisp-call-stack*)))
                   ;; BIND-USUBR-FRAME signals its wrong-number-of-arguments
                   ;; error BEFORE pushing the frame, so it must stay OUTSIDE
                   ;; the unwind-protect: with it inside, an unwind from that
                   ;; error popped a frame that was never pushed — the
                   ;; CALLER's — silently dropping the caller's bindings, so
                   ;; after a *caught* arity error (vl-catch-all-apply, or a
                   ;; debugger resume) the caller's variables resolved to
                   ;; stale outer values (the infinite fact recursion,
                   ;; error-while-debugging follow-up). Once it returns, the
                   ;; frame provably exists and the pop pairs with it.
                   (bind-usubr-frame function arguments context)
                   (unwind-protect
                        (autolisp-eval-progn selected-body context)
                     (pop-dynamic-frame context)))))
              (t
               (signal-autolisp-runtime-error
                :invalid-function-object
                "Expected an AutoLISP function object, got ~S."
                function)))))
      (when trace-this-call
        (decf *autolisp-trace-depth*)
        (autolisp-trace-exit function result))
      result)))

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

(defun autolisp-compiled-eval (form &optional (context (current-evaluation-context)))
  "Evaluate a TOP-LEVEL FORM through the compiled-eval model
(debugger-public-interface issue): (eval expr) == (funcall (clal-compile nil
`(lambda () ,expr))). Under an active debug session with instrumentation enabled,
FORM is wrapped in a nullary usubr which the apply boundary instruments, so the
poll points inside FORM fire — a top-level (/ 0) or (setq x (buggy)) stops at a
real frame and can be stepped. With no session (all normal runs and tests) this
is plain AUTOLISP-EVAL at full speed — the wrap is never built."
  (if (and *debugging* *debug-instrumentation-enabled*)
      (let ((usubr (make-autolisp-usubr "<toplevel>" '() (list form) context)))
        (call-autolisp-function-in-context usubr context))
      (autolisp-eval form context)))

(defun autolisp-eval-toplevel-progn (forms &optional (context (current-evaluation-context)))
  "Evaluate FORMS as a sequence of TOP-LEVEL forms through AUTOLISP-COMPILED-EVAL
(so LOAD and the REPL get instrumentable top-level forms under a debug session),
returning the last form's value. Outside a session this is AUTOLISP-EVAL-PROGN."
  (let ((result nil))
    (dolist (form forms result)
      (setf result (autolisp-compiled-eval form context)))))

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
  (let ((result nil)
        ;; Source-aware-defun-documentation: the parser's preceding-doc
        ;; (if any) belongs to the *first* name in a multi-pair setq.
        ;; The remaining pairs apply the no-block rule independently.
        (preceding-text (current-form-preceding-doc))
        (first-pair-p t))
    (loop for (symbol-form value-form) on arguments by #'cddr
          do (unless (typep symbol-form 'autolisp-symbol)
               (signal-autolisp-runtime-error
                :invalid-setq-place
                "SETQ place must be an AutoLISP symbol, got ~S."
                symbol-form))
             (setf result (autolisp-eval value-form context))
             (set-variable symbol-form result context)
             ;; Apply the setq update rule from
             ;; source-aware-defun-documentation:
             ;;   preceding ;|…|; → install (:variable "TEXT")
             ;;   no preceding block, current doc is (:function _)
             ;;                    → clear (function-doc no longer applies)
             ;;   no preceding block, current doc is nil
             ;;                    → leave nil
             ;;   no preceding block, current doc is (:variable _)
             ;;                    → leave it (plain mutation does not
             ;;                      erase a documented variable)
             ;; Only the FIRST pair sees the parse-tree's preceding-doc;
             ;; subsequent pairs in a multi-pair setq behave as if no
             ;; block preceded them.
             (let ((block-text (and first-pair-p preceding-text)))
               (cond
                 (block-text
                  (set-binding-doc symbol-form
                                   (list :variable block-text)
                                   context))
                 (t
                  (let ((current (lookup-documentation symbol-form context)))
                    (when (and (consp current) (eq (car current) :function))
                      (set-binding-doc symbol-form nil context))))))
             (setf first-pair-p nil))
    result))

(defun eval-set-form (arguments context)
  ;; (set 'foo VALUE)  — like SETQ but the place form is evaluated.
  ;; AutoLISP's SET takes exactly two arguments (one symbol-producing
  ;; form + one value form); the pair-iteration shape of SETQ is
  ;; not a feature of SET in any documented dialect.
  (unless (= 2 (length arguments))
    (signal-autolisp-runtime-error
     :wrong-number-of-arguments
     "SET expects two arguments, got ~D."
     (length arguments)))
  (let* ((place-result (autolisp-eval (first arguments) context))
         (value-result (autolisp-eval (second arguments) context)))
    (unless (typep place-result 'autolisp-symbol)
      (signal-autolisp-runtime-error
       :invalid-set-place
       "SET place must evaluate to an AutoLISP symbol, got ~S."
       place-result))
    (set-variable place-result value-result context)
    value-result))

(defun eval-trace-form (arguments context)
  ;; (trace foo bar)  — symbol-name arguments are taken bare (not
  ;; evaluated), upcased, and added to *autolisp-traced-symbols*.
  ;; Returns the last symbol traced (the SETQ "current value"
  ;; idiom). Autodesk's reference page documents single-symbol
  ;; calls; clautolisp accepts a variadic form for ergonomic
  ;; (trace a b c) at the REPL.
  (declare (ignore context))
  (let ((last-symbol nil))
    (dolist (arg arguments)
      (unless (typep arg 'autolisp-symbol)
        (signal-autolisp-runtime-error
         :invalid-trace-argument
         "TRACE argument must be a bare symbol, got ~S." arg))
      (setf (gethash (autolisp-symbol-name arg) *autolisp-traced-symbols*) t)
      (setf last-symbol arg))
    last-symbol))

(defun eval-untrace-form (arguments context)
  ;; (untrace foo bar)  — remove each named symbol from the trace
  ;; set. (untrace) with no arguments clears the whole set — a
  ;; common extension over Autodesk's single-symbol form, useful
  ;; at the REPL to wipe out a noisy trace session.
  (declare (ignore context))
  (cond
    ((null arguments)
     (clrhash *autolisp-traced-symbols*)
     nil)
    (t
     (let ((last-symbol nil))
       (dolist (arg arguments)
         (unless (typep arg 'autolisp-symbol)
           (signal-autolisp-runtime-error
            :invalid-untrace-argument
            "UNTRACE argument must be a bare symbol, got ~S." arg))
         (remhash (autolisp-symbol-name arg) *autolisp-traced-symbols*)
         (setf last-symbol arg))
       last-symbol))))

;;; --- COMMAND / COMMAND-S (deferred-command-special-form issue) ------
;;;
;;; Autodesk classifies COMMAND as a special form (autolisp-spec ch.3,
;;; "Special Form Entry: COMMAND"): it is the canonical channel from
;;; AutoLISP into the host CAD's command engine. clautolisp evaluates
;;; every argument, normalizes each value to a command-line *token
;;; string* per the spec's input rules, and routes the whole token
;;; sequence through the active HAL backend's HOST-COMMAND method.
;;;
;;; Token normalization ("as a user types it at the CAD prompt"):
;;;   string   -> itself, verbatim. "" is the RETURN token and the
;;;               one-backslash string "\\" is the PAUSE token — both
;;;               pass through unchanged; the backend interprets them.
;;;   integer  -> its decimal spelling ("42").
;;;   real     -> its AutoLISP princ spelling ("3.14", no CL marker).
;;;   point    -> a proper list of 2 or 3 numbers, formatted as the
;;;               comma-separated coordinates a user would type
;;;               ("1.0,2.0" / "1.0,2.0,3.0").
;;;   ename    -> the entity handle text (entity-selection input).
;;;   others   -> :invalid-command-argument (nil included: vendor
;;;               AutoLISP rejects nil command input too).
;;;
;;; The runtime cannot name the HOST-COMMAND generic directly — the
;;; autolisp-host system depends on autolisp-runtime, not the other
;;; way around — so routing goes through *HOST-COMMAND-FUNCTION*, a
;;; funcallable of (host token-list) the autolisp-host module installs
;;; at load time (same pattern as *default-runtime-host*).

(defparameter *host-command-function* nil
  "Funcallable of (HOST TOKEN-LIST) that delivers a normalized
COMMAND token sequence to the HAL backend HOST. The autolisp-host
module installs #'HOST-COMMAND here when loaded; tests may rebind
it to capture routed tokens without a host system.")

(defun format-command-number (value)
  "Format the number VALUE as a CAD command-line token: integers in
decimal, reals in their AutoLISP princ spelling (no CL float marker)."
  (if (integerp value)
      (format nil "~D" value)
      (let ((*read-default-float-format* 'double-float))
        (princ-to-string (coerce value 'double-float)))))

(defun command-point-p (value)
  "True iff VALUE is an AutoLISP point usable as command input: a
proper list of 2 or 3 CL reals (the runtime representation of
AutoLISP 2D/3D points)."
  (and (consp value)
       (let ((length (list-length value)))     ; nil on dotted/circular
         (and length (<= 2 length 3)))
       (every (lambda (element)
                (or (typep element '(signed-byte 32))
                    (typep element 'double-float)))
              value)))

(defun command-token-from-value (value)
  "Normalize the evaluated COMMAND argument VALUE to its command-line
token string. Signals :invalid-command-argument for values that have
no command-input reading (nil, symbols, nested lists, functions, …)."
  (cond
    ((typep value 'autolisp-string)
     (autolisp-string-value value))
    ((or (typep value '(signed-byte 32))
         (typep value 'double-float))
     (format-command-number value))
    ((command-point-p value)
     (format nil "~{~A~^,~}" (mapcar #'format-command-number value)))
    ((typep value 'autolisp-ename)
     (format nil "~A" (autolisp-ename-value value)))
    (t
     (signal-autolisp-runtime-error
      :invalid-command-argument
      "COMMAND argument must be a string, number, point list, or entity name, got ~S."
      value))))

(defun dispatch-autolisp-command (values &optional (context (current-evaluation-context)))
  "Normalize the evaluated argument VALUES to command tokens and route
them through the active host's command channel in a single call.
Returns the host's result. Signals :host-not-supported when no HAL
backend (or no host module) is attached. Shared by the COMMAND /
COMMAND-S special forms and the VL-CMDF builtin."
  (let ((tokens (mapcar #'command-token-from-value values))
        (host   (current-evaluation-host context))
        (router *host-command-function*))
    (unless (and host router)
      (signal-autolisp-runtime-error
       :host-not-supported
       "No host backend is attached; COMMAND requires a CAD host."))
    (funcall router host tokens)))

(defun eval-command-form (arguments context)
  ;; (command "._LINE" pt1 pt2 "") — evaluate every argument, then
  ;; send the normalized token sequence to the host command engine.
  ;; Returns nil (the documented COMMAND return-value rule).
  ;; (command) with no arguments sends the empty sequence — the
  ;; vendor-documented "cancel the current command" call.
  (dispatch-autolisp-command
   (mapcar (lambda (argument) (autolisp-eval argument context)) arguments)
   context)
  nil)

(defun eval-command-s-form (arguments context)
  ;; (command-s ...) — the synchronous variant. In the in-process
  ;; clautolisp engine every HOST-COMMAND call already completes
  ;; before returning, so COMMAND-S shares COMMAND's routing
  ;; unchanged; it exists so vendor code calling it runs. Returns
  ;; nil on success per Autodesk's page; failures surface as
  ;; runtime errors (the *error* channel).
  (eval-command-form arguments context))

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

(defun maybe-warn-about-rest-separator (lambda-list who)
  "Walk LAMBDA-LIST, find the rest-separator if any, and emit a
dialect-aware warning via `emit-lambda-list-extension-warning'.
A no-op when LAMBDA-LIST has no separator or is malformed (the
malformed cases surface at call-time via `bind-usubr-frame')."
  (when (listp lambda-list)
    (dolist (element lambda-list)
      (let ((spelling (autolisp-ampersand-spelling element)))
        (when spelling
          (emit-lambda-list-extension-warning spelling who lambda-list)
          (return))))))

(defun eval-lambda-form (arguments context)
  (unless (>= (length arguments) 2)
    (signal-autolisp-runtime-error
     :wrong-number-of-arguments
     "LAMBDA expects a lambda list and at least one body form, got ~D arguments."
     (length arguments)))
  (maybe-warn-about-rest-separator (first arguments) "LAMBDA")
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
  ;; Autodesk specifies that `function` is identical to `quote` except
  ;; for a compiler hint to Visual LISP (cf. autolisp-spec ch.3,
  ;; "Special Form Entry: FUNCTION"). Returning the unevaluated
  ;; argument preserves *late* resolution: a symbol arg is resolved
  ;; against the dynamic-scope chain at the point APPLY runs (or
  ;; lookup-function fires), not at the point the FUNCTION form
  ;; itself was reached. That late resolution is what lets the
  ;; portable HOF idiom — `(apply (function fn) (list arg))` — work
  ;; when `fn` is a name defined further down the dynamic stack (e.g.
  ;; via an inner `defun` inside the calling scope's `/`-locals).
  (declare (ignore context))
  (unless (= (length arguments) 1)
    (signal-autolisp-runtime-error
     :wrong-number-of-arguments
     "FUNCTION expects exactly one argument, got ~D."
     (length arguments)))
  (let ((designator (first arguments)))
    (cond
      ((typep designator 'autolisp-symbol) designator)
      ((lambda-form-p designator) designator)
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
    (maybe-warn-about-rest-separator lambda-list "DEFUN-Q")
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
    (maybe-warn-about-rest-separator lambda-list "DEFUN")
    (let ((function (make-autolisp-usubr (autolisp-symbol-name name)
                                         lambda-list
                                         body
                                         context)))
      (set-function name function context)
      ;; Source-aware-defun-documentation: DEFUN always rewrites the
      ;; binding cell's doc slot. With a preceding ;|…|; block the
      ;; new doc is (:function "TEXT"); without one it is nil. Every
      ;; defun is an authoritative redeclaration — the absence of a
      ;; doc means "the author has not documented this revision."
      ;; The keyword head is internal; the CLAUTOLISP-DOCUMENTATION
      ;; / -KIND builtins translate to AutoLISP-visible values.
      (set-binding-doc name
                       (let ((text (current-form-preceding-doc)))
                         (and text (list :function text)))
                       context)
      name)))

(defparameter *special-operator-dispatch*
  (list (cons "QUOTE" #'eval-quote-form)
        (cons "SETQ" #'eval-setq-form)
        (cons "SET" #'eval-set-form)
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
        (cons "DEFUN" #'eval-defun-form)
        (cons "TRACE" #'eval-trace-form)
        (cons "UNTRACE" #'eval-untrace-form)
        (cons "COMMAND" #'eval-command-form)
        (cons "COMMAND-S" #'eval-command-s-form)))

(defun special-operator-function (operator)
  (cdr (assoc (special-operator-name operator)
              *special-operator-dispatch*
              :test #'string=)))

(defun register-special-operator (name function)
  "Install FUNCTION as the handler for the special operator named NAME
(an upper-case string). The handler receives the operator's unevaluated
ARGUMENTS and the evaluation CONTEXT, exactly like the built-in
eval-*-form handlers. Used by the debugger to register its private
%CLAL-POLL poll-point operator without the runtime depending on the
debug system. Re-registering a name replaces the previous handler."
  (let ((entry (assoc name *special-operator-dispatch* :test #'string=)))
    (if entry
        (setf (cdr entry) function)
        (push (cons name function) *special-operator-dispatch*)))
  name)

(defun unregister-special-operator (name)
  "Remove a special operator previously installed by
register-special-operator. Returns T if an entry was removed."
  (let ((present (assoc name *special-operator-dispatch* :test #'string=)))
    (setf *special-operator-dispatch*
          (remove name *special-operator-dispatch*
                  :key #'car :test #'string=))
    (and present t)))

(defun known-special-operator-p (name)
  "True iff NAME (an upper-case string) names a special operator in the
dispatch table. The debugger's instrumenter uses this to decide which
forms have unevaluated operands it must not instrument (spec §5.3)."
  (and (assoc name *special-operator-dispatch* :test #'string=) t))

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
  ;; Push a backtrace frame for every form being evaluated. Using
  ;; let-binding around the body via a fresh dynamic binding ensures
  ;; the frame is automatically popped on normal return AND on
  ;; non-local exit (autolisp-runtime-error, autolisp-termination,
  ;; autolisp-namespace-exit) without an explicit unwind-protect.
  (let ((*autolisp-call-stack* (cons (cons :eval form) *autolisp-call-stack*)))
    (cond
      ((self-evaluating-runtime-value-p form)
       form)
      ((and (typep form 'autolisp-symbol)
            (string= "T" (autolisp-symbol-name form)))
       ;; T is the canonical truth constant in AutoLISP and must be
       ;; self-evaluating regardless of dialect or any (setq T ...)
       ;; the user might attempt. Without this, (cond (... ) (T ...))
       ;; would fall through silently in dialects whose unbound-
       ;; variable mode is :silent-nil.
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
             (arguments (rest form))
             ;; Source-aware-defun-documentation: expose the
             ;; current form to eval-defun-form / eval-setq-form
             ;; so they can pull the parser's preceding-doc out
             ;; of *preceding-docs* and tag the binding cell.
             ;; Other special operators / function calls ignore
             ;; this binding.
             (*current-form* form))
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
        form)))))

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

(defun lookup-autolisp-file-encoding (&optional (context (current-evaluation-context)))
  "Resolve the AutoLISP-level *AUTOLISP-FILE-ENCODING* global to a
CL external-format keyword, or NIL when the global isn't bound
to a usable string. Lets a user's `(setq *autolisp-file-encoding*
\"ISO-8859-1\")' at the REPL actually take effect on the next
LOAD — without it the CL session slot (set at startup by the
CLI's -e flag) silently wins.

Used by both the input path (LOAD / read / read-line) and the
output path (OPEN for write/append, see OPEN-DEFAULT-EXTERNAL-FORMAT)
so a value written and read back under the same encoding round-trips."
  (handler-case
      (multiple-value-bind (value boundp)
          (lookup-variable (intern-autolisp-symbol "*AUTOLISP-FILE-ENCODING*")
                           context)
        (cond
          ((not boundp) nil)
          ((typep value 'autolisp-string)
           (parse-locale-encoding-string (autolisp-string-value value)))
          (t nil)))
    (error () nil)))

(defun autolisp-load-file-in-context (path context &rest read-options)
  ;; Source-file encoding precedence, when the caller did NOT pass
  ;; an explicit :external-format:
  ;;   1. AutoLISP-level *AUTOLISP-FILE-ENCODING* global. Lets the
  ;;      user override mid-session: (setq *autolisp-file-encoding*
  ;;      \"ISO-8859-1\") and the next LOAD picks the new encoding.
  ;;   2. CL-level session override (set by the CLI's `-e ENC' flag
  ;;      at startup; carried in the session's
  ;;      default-source-encoding slot).
  ;;   3. Dialect default — strict reads ISO-8859-1 (a 1-1 byte
  ;;      coding that never errors on Latin-1 / Windows-1252
  ;;      source); autocad-2026 / bricscad-v26 / clautolisp read
  ;;      UTF-8 (matches AutoCAD 2025+ / BricsCAD V26 defaults;
  ;;      autolisp-spec ch. 11, "Source-File and File-Stream
  ;;      Encoding").
  (let* ((options-have-external-format
          (loop for tail = read-options then (cddr tail)
                while tail
                thereis (eq (first tail) :external-format)))
         (global-encoding (unless options-have-external-format
                            (lookup-autolisp-file-encoding context)))
         (session (and context
                       (clautolisp.autolisp-runtime.internal::evaluation-context-session
                        context)))
         (session-encoding (and session
                                (runtime-session-default-source-encoding
                                 session)))
         (dialect (current-evaluation-dialect context))
         (effective-encoding
          (cond
            (options-have-external-format nil) ; caller supplied one
            (global-encoding global-encoding)
            (session-encoding session-encoding)
            (t (clautolisp.autolisp-reader:autolisp-dialect-default-source-encoding
                dialect))))
         (effective-options
          (if effective-encoding
              (append read-options
                      (list :external-format effective-encoding))
              read-options)))
    (call-with-autolisp-error-handler
     (lambda ()
       ;; Top-level forms go through the compiled-eval model so a file
       ;; loaded under a debug session is instrumentable (LOAD → EVAL →
       ;; clal-compile). Outside a session this is a plain eval-progn.
       (autolisp-eval-toplevel-progn
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

(defun read-current-source (text &key source-name
                                      (context (current-evaluation-context)))
  "THE reader entry for interactively typed AutoLISP source
(interactor-design-revision.issue D2): read TEXT under the dialect in force
NOW — CURRENT-EVALUATION-DIALECT, so a mid-session
=(setq *AUTOLISP-DIALECT* 'lax)= takes effect immediately — and return the
list of runtime forms. Every interactor's sexp path reads through here: the
REPL turn, a `(FORM)' at DBG> / NAV>, the inspector's =e=, sedit's =e=. The
dialect is NOT interactor state; it influences only this read."
  (read-runtime-from-string
   text
   :options (derive-reader-options-for-dialect
             (current-evaluation-dialect context)
             :source-name (or source-name "<interactive>"))))

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

;;; --- Encoding-dispatch diagnostics (Phase 4 of encoding-dispatch.issue) -

(defparameter *enc-diagnostic-stream* nil
  "Stream that encoding-dispatch diagnostics are written to.
NIL means SIGNAL-ENCODING-DIAGNOSTIC falls back to *error-output*
at call time. Tests rebind this to a string stream to assert on
diagnostic output without printing to the real stderr.")

(defparameter *enc-diagnostic-suppress-p* nil
  "When true, SIGNAL-ENCODING-DIAGNOSTIC is a no-op. Used by tests
that exercise the runtime path but don't want the diagnostic to
print, and by the per-file pragma mechanism documented in
encoding-dispatch.issue.")

(defparameter *enc-diagnostic-suppress-codes* '()
  "Per-code suppression set. SIGNAL-ENCODING-DIAGNOSTIC skips
emission when its CODE argument is a member. Updated by the
CLAL-SUPPRESS-ENC-DIAGNOSTIC / CLAL-ENABLE-ENC-DIAGNOSTIC builtins
(encoding-dispatch.issue Phase 10 'per-file pragma' surface) and
by tests that need to silence a specific code while keeping the
rest of the stream observable.")

(defparameter *enc-diagnostic-codes*
  '(:enc-foreign-dialect       ; spelling belongs to a non-selected dialect
    :enc-extension-used        ; --strict only: any encoding extension used
    :enc-unsupported-target    ; selected encoding cannot be expressed on host
    :enc-invalid-value         ; bad encoding name string
    :enc-lispsys-out-of-range  ; (setvar "LISPSYS" n) with n not in {0,1,2}
    :enc-codepage-mismatch     ; DWGCODEPAGE differs from SYSCODEPAGE
    :enc-unknown-codepage      ; SYSCODEPAGE string clautolisp cannot map
    :enc-host-dependent)       ; info-level: "ANSI" used in a write context
  "Closed set of diagnostic codes SIGNAL-ENCODING-DIAGNOSTIC accepts.
See issues/closed/encoding-dispatch.issue under 'Diagnostics' for the
authoritative descriptions.")

(defun %enc-dialect-is-lax-p ()
  "True when the current evaluation context's dialect is :lax.
Consulted by SIGNAL-ENCODING-DIAGNOSTIC to silence every encoding
diagnostic uniformly under --lax (encoding-dispatch.issue 'Dialect
matrix / --lax')."
  (let ((dialect (ignore-errors (current-evaluation-dialect))))
    (and dialect
         (eq :lax
             (clautolisp.autolisp-reader:autolisp-dialect-name dialect)))))

(defun signal-encoding-diagnostic (code format-control &rest format-args)
  "Emit an encoding-dispatch diagnostic with CODE (a keyword from
*ENC-DIAGNOSTIC-CODES*). Writes \"[enc-CODE] message\\n\" to
*ENC-DIAGNOSTIC-STREAM* (default *error-output*).

Three suppression gates, evaluated in order:

  1. *ENC-DIAGNOSTIC-SUPPRESS-P* — global silencer (tests, pragma
     'suppress all').
  2. CODE in *ENC-DIAGNOSTIC-SUPPRESS-CODES* — per-code pragma.
  3. The active dialect is :lax — the spec's catch-all 'accept
     everything quietly' mode.

The diagnostic is NEVER a runtime error — execution continues. The
caller has already decided that the form is honoured (so user code
stays runnable across dialects) and only the diagnosis is being
surfaced. Phase-4 surface; a structured diagnostic registry can
replace the textual stream in a later phase without changing the
call-site signature."
  (unless (member code *enc-diagnostic-codes*)
    (error "Unknown encoding-diagnostic code ~S; expected one of ~S."
           code *enc-diagnostic-codes*))
  (unless (or *enc-diagnostic-suppress-p*
              (member code *enc-diagnostic-suppress-codes*)
              (%enc-dialect-is-lax-p))
    (let ((stream (or *enc-diagnostic-stream* *error-output*))
          (code-name (string-downcase (symbol-name code))))
      (fresh-line stream)
      (format stream "[~A] " code-name)
      (apply #'format stream format-control format-args)
      (terpri stream)
      (force-output stream))))

;;; --- SECURELOAD trust diagnostics ----------------------------------
;;;
;;; Parallel to the encoding diagnostics above: the warn-and-proceed
;;; path of the SECURELOAD trust model (value 1) emits a diagnostic and
;;; continues. Same suppression model so tests / harnesses can silence
;;; it; :lax also silences (no gating under --lax).

(defparameter *secureload-diagnostic-stream* nil
  "Stream SECURELOAD trust diagnostics are written to. NIL falls back
to *error-output* at call time.")

(defparameter *secureload-diagnostic-suppress-p* nil
  "When true, SIGNAL-SECURELOAD-DIAGNOSTIC is a no-op. Bound by tests
and by harnesses that load their own trusted corpus.")

(defparameter *secureload-diagnostic-codes*
  '(:sec-untrusted-load     ; LOAD of a gated file from an untrusted location
    :sec-untrusted-open)    ; OPEN of a gated-extension file, untrusted location
  "Closed set of diagnostic codes SIGNAL-SECURELOAD-DIAGNOSTIC accepts.")

(defun signal-secureload-diagnostic (code format-control &rest format-args)
  "Emit a SECURELOAD trust diagnostic with CODE (a keyword from
*SECURELOAD-DIAGNOSTIC-CODES*) as \"[CODE] message\" to
*SECURELOAD-DIAGNOSTIC-STREAM* (default *error-output*). Suppressed by
*SECURELOAD-DIAGNOSTIC-SUPPRESS-P* or under the :lax dialect. Never a
runtime error — this is the warn-and-proceed path; the caller has
already decided to honour the load."
  (unless (member code *secureload-diagnostic-codes*)
    (error "Unknown secureload-diagnostic code ~S; expected one of ~S."
           code *secureload-diagnostic-codes*))
  (unless (or *secureload-diagnostic-suppress-p*
              (%enc-dialect-is-lax-p))
    (let ((stream (or *secureload-diagnostic-stream* *error-output*))
          (code-name (string-downcase (symbol-name code))))
      (fresh-line stream)
      (format stream "[~A] " code-name)
      (apply #'format stream format-control format-args)
      (terpri stream)
      (force-output stream))))

(defun call-with-suppressed-encoding-diagnostics (thunk)
  "Run THUNK with encoding-dispatch diagnostics suppressed.
Convenience for tests that exercise an encoding-dispatch code path
without printing to *error-output*."
  (let ((*enc-diagnostic-suppress-p* t))
    (funcall thunk)))
