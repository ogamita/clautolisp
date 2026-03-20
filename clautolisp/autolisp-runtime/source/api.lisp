(in-package #:clautolisp.autolisp-runtime)

(deftype autolisp-symbol ()
  'clautolisp.autolisp-runtime.internal::autolisp-symbol)

(deftype value-cell ()
  'clautolisp.autolisp-runtime.internal::value-cell)

(deftype function-cell ()
  'clautolisp.autolisp-runtime.internal::function-cell)

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

(deftype autolisp-variant ()
  'clautolisp.autolisp-runtime.internal::autolisp-variant)

(deftype autolisp-safearray ()
  'clautolisp.autolisp-runtime.internal::autolisp-safearray)

(deftype autolisp-vla-object ()
  'clautolisp.autolisp-runtime.internal::autolisp-vla-object)

(defun reset-autolisp-symbol-table ()
  (clrhash clautolisp.autolisp-runtime.internal::*autolisp-symbol-table*)
  (reset-default-evaluation-context))

(defun default-evaluation-context ()
  clautolisp.autolisp-runtime.internal::*default-evaluation-context*)

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

(defun make-runtime-session (&key current-document)
  (clautolisp.autolisp-runtime.internal::make-runtime-session
   :current-document current-document))

(defun runtime-session-current-document (session)
  (clautolisp.autolisp-runtime.internal::runtime-session-current-document session))

(defun make-evaluation-context (&key session current-document current-namespace dynamic-frame)
  (clautolisp.autolisp-runtime.internal::make-evaluation-context
   :session session
   :current-document current-document
   :current-namespace current-namespace
   :dynamic-frame dynamic-frame))

(defun evaluation-context-session (context)
  (clautolisp.autolisp-runtime.internal::evaluation-context-session context))

(defun evaluation-context-current-document (context)
  (clautolisp.autolisp-runtime.internal::evaluation-context-current-document context))

(defun evaluation-context-current-namespace (context)
  (clautolisp.autolisp-runtime.internal::evaluation-context-current-namespace context))

(defun evaluation-context-dynamic-frame (context)
  (clautolisp.autolisp-runtime.internal::evaluation-context-dynamic-frame context))

(defun value-cell-value (cell)
  (clautolisp.autolisp-runtime.internal::value-cell-value cell))

(defun value-cell-bound-p (cell)
  (clautolisp.autolisp-runtime.internal::value-cell-bound-p cell))

(defun function-cell-function (cell)
  (clautolisp.autolisp-runtime.internal::function-cell-function cell))

(defun function-cell-bound-p (cell)
  (clautolisp.autolisp-runtime.internal::function-cell-bound-p cell))

(defun namespace-value-table (namespace)
  (typecase namespace
    (document-namespace
     (clautolisp.autolisp-runtime.internal::document-namespace-value-cells namespace))
    (blackboard-namespace
     (clautolisp.autolisp-runtime.internal::blackboard-namespace-value-cells namespace))
    (separate-vlx-namespace
     (clautolisp.autolisp-runtime.internal::separate-vlx-namespace-value-cells namespace))
    (t
     (error "Namespace ~S does not support value cells." namespace))))

(defun namespace-function-table (namespace)
  (typecase namespace
    (document-namespace
     (clautolisp.autolisp-runtime.internal::document-namespace-function-cells namespace))
    (separate-vlx-namespace
     (clautolisp.autolisp-runtime.internal::separate-vlx-namespace-function-cells namespace))
    (t
     (error "Namespace ~S does not support function cells." namespace))))

(defun namespace-value-cell (namespace symbol &key (createp t))
  (or (gethash symbol (namespace-value-table namespace))
      (when createp
        (setf (gethash symbol (namespace-value-table namespace))
              (clautolisp.autolisp-runtime.internal::make-value-cell)))))

(defun namespace-function-cell (namespace symbol &key (createp t))
  (or (gethash symbol (namespace-function-table namespace))
      (when createp
        (setf (gethash symbol (namespace-function-table namespace))
              (clautolisp.autolisp-runtime.internal::make-function-cell)))))

(defun make-dynamic-frame (&key parent)
  (clautolisp.autolisp-runtime.internal::make-dynamic-frame :parent parent))

(defun push-dynamic-frame (&optional (context (default-evaluation-context)))
  (let ((frame (make-dynamic-frame :parent (evaluation-context-dynamic-frame context))))
    (setf (clautolisp.autolisp-runtime.internal::evaluation-context-dynamic-frame context)
          frame)
    frame))

(defun pop-dynamic-frame (&optional (context (default-evaluation-context)))
  (let ((frame (evaluation-context-dynamic-frame context)))
    (when frame
      (setf (clautolisp.autolisp-runtime.internal::evaluation-context-dynamic-frame context)
            (clautolisp.autolisp-runtime.internal::dynamic-frame-parent frame)))
    frame))

(defun bind-dynamic-variable (symbol value &optional (context (default-evaluation-context)))
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

(defun lookup-variable (symbol &optional (context (default-evaluation-context)))
  (let ((binding (find-dynamic-binding symbol (evaluation-context-dynamic-frame context))))
    (cond
      (binding
       (values (clautolisp.autolisp-runtime.internal::dynamic-binding-value binding) t :dynamic))
      (t
       (let* ((cell (namespace-value-cell (evaluation-context-current-namespace context)
                                          symbol
                                          :createp nil))
              (boundp (and cell (value-cell-bound-p cell))))
         (values (and boundp (value-cell-value cell))
                 boundp
                 :namespace))))))

(defun set-variable (symbol value &optional (context (default-evaluation-context)))
  (let ((binding (find-dynamic-binding symbol (evaluation-context-dynamic-frame context))))
    (if binding
        (setf (clautolisp.autolisp-runtime.internal::dynamic-binding-value binding) value
              (clautolisp.autolisp-runtime.internal::dynamic-binding-bound-p binding) t)
        (let ((cell (namespace-value-cell (evaluation-context-current-namespace context) symbol)))
          (setf (clautolisp.autolisp-runtime.internal::value-cell-value cell) value
                (clautolisp.autolisp-runtime.internal::value-cell-bound-p cell) t)))
    value))

(defun lookup-function (symbol &optional (context (default-evaluation-context)))
  (let* ((cell (namespace-function-cell (evaluation-context-current-namespace context)
                                        symbol
                                        :createp nil))
         (boundp (and cell (function-cell-bound-p cell))))
    (values (and boundp (function-cell-function cell))
            boundp
            :namespace)))

(defun set-function (symbol function &optional (context (default-evaluation-context)))
  (let ((cell (namespace-function-cell (evaluation-context-current-namespace context) symbol)))
    (setf (clautolisp.autolisp-runtime.internal::function-cell-function cell) function
          (clautolisp.autolisp-runtime.internal::function-cell-bound-p cell) t)
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

(defun autolisp-pickset-value (object)
  (clautolisp.autolisp-runtime.internal::autolisp-pickset-value object))

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

(defun autolisp-variant-value (object)
  (clautolisp.autolisp-runtime.internal::autolisp-variant-value object))

(defun autolisp-safearray-value (object)
  (clautolisp.autolisp-runtime.internal::autolisp-safearray-value object))

(defun autolisp-vla-object-value (object)
  (clautolisp.autolisp-runtime.internal::autolisp-vla-object-value object))

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
     (error "Cannot map reader object ~S to a runtime value." object))))

(defun reader-objects->runtime-values (objects)
  (mapcar #'reader-object->runtime-value objects))

(defun autolisp-false-p (object)
  (null object))

(defun autolisp-true-p (object)
  (not (autolisp-false-p object)))

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
    (error "Expected an AutoLISP symbol, got ~S." object))
  (clautolisp.autolisp-runtime.internal::make-autolisp-string
   :value (autolisp-symbol-name object)))

(defun autolisp-vl-symbol-value (object)
  (unless (typep object 'autolisp-symbol)
    (error "Expected an AutoLISP symbol, got ~S." object))
  (autolisp-symbol-value object))

(defun call-autolisp-function (function &rest arguments)
  (cond
    ((typep function 'autolisp-subr)
     (apply (autolisp-subr-function function) arguments))
    ((typep function 'autolisp-usubr)
     (error "User-defined AutoLISP functions are not callable yet: ~S." function))
    (t
     (error "Expected an AutoLISP function object, got ~S." function))))

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
     (error "No AutoLISP runtime type designator is defined for ~S." object))))

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
