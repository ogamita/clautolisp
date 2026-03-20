(in-package #:clautolisp.autolisp-runtime)

(deftype autolisp-symbol ()
  'clautolisp.autolisp-runtime.internal::autolisp-symbol)

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
  (clrhash clautolisp.autolisp-runtime.internal::*autolisp-symbol-table*))

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

(defun set-autolisp-symbol-value (symbol value)
  (setf (clautolisp.autolisp-runtime.internal::autolisp-symbol-value symbol) value
        (clautolisp.autolisp-runtime.internal::autolisp-symbol-value-bound-p symbol) t)
  value)

(defun set-autolisp-symbol-function (symbol function)
  (setf (clautolisp.autolisp-runtime.internal::autolisp-symbol-function symbol) function
        (clautolisp.autolisp-runtime.internal::autolisp-symbol-function-bound-p symbol) t)
  function)

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
  (clautolisp.autolisp-runtime.internal::autolisp-symbol-value object))

(defun autolisp-symbol-value-bound-p (object)
  (clautolisp.autolisp-runtime.internal::autolisp-symbol-value-bound-p object))

(defun autolisp-symbol-function (object)
  (clautolisp.autolisp-runtime.internal::autolisp-symbol-function object))

(defun autolisp-symbol-function-bound-p (object)
  (clautolisp.autolisp-runtime.internal::autolisp-symbol-function-bound-p object))

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
