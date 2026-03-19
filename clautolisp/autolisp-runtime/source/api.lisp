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

(defun find-autolisp-symbol (name)
  (gethash name clautolisp.autolisp-runtime.internal::*autolisp-symbol-table*))

(defun intern-autolisp-symbol (name &key original-name)
  (or (find-autolisp-symbol name)
      (setf (gethash name clautolisp.autolisp-runtime.internal::*autolisp-symbol-table*)
            (clautolisp.autolisp-runtime.internal::make-autolisp-symbol
             :name name
             :original-name original-name))))

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

(defun autolisp-symbol-name (object)
  (clautolisp.autolisp-runtime.internal::autolisp-symbol-name object))

(defun autolisp-symbol-original-name (object)
  (clautolisp.autolisp-runtime.internal::autolisp-symbol-original-name object))

(defun autolisp-symbol-value-bound-p (object)
  (clautolisp.autolisp-runtime.internal::autolisp-symbol-value-bound-p object))

(defun autolisp-symbol-function-bound-p (object)
  (clautolisp.autolisp-runtime.internal::autolisp-symbol-function-bound-p object))

(defun autolisp-file-stream (object)
  (clautolisp.autolisp-runtime.internal::autolisp-file-stream object))

(defun autolisp-file-path (object)
  (clautolisp.autolisp-runtime.internal::autolisp-file-path object))

(defun autolisp-file-mode (object)
  (clautolisp.autolisp-runtime.internal::autolisp-file-mode object))

(defun autolisp-ename-value (object)
  (clautolisp.autolisp-runtime.internal::autolisp-ename-value object))

(defun autolisp-pickset-value (object)
  (clautolisp.autolisp-runtime.internal::autolisp-pickset-value object))

(defun autolisp-subr-name (object)
  (clautolisp.autolisp-runtime.internal::autolisp-subr-name object))

(defun autolisp-subr-function (object)
  (clautolisp.autolisp-runtime.internal::autolisp-subr-function object))

(defun autolisp-usubr-name (object)
  (clautolisp.autolisp-runtime.internal::autolisp-usubr-name object))

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
