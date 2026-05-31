(in-package #:clautolisp.inspect)

;;;; Page generation (spec §15). INSPECT-PAGE-FOR returns an INSPECT-PAGE:
;;;; a header plus a list of INSPECT-COMPONENTs. Each component carries an
;;;; ACCESSOR — an S-expression template with the free placeholder symbol
;;;; `_` that, with `_` replaced by the parent's path expression, yields a
;;;; form evaluating to the component's value (§15.2). For the types that
;;;; allow it the component VALUE is computed directly in CL (a runtime
;;;; cons is a CL cons), so the core inspector needs no builtins/host; the
;;;; host-dependent types (ename/pickset) render by evaluating their
;;;; accessor and degrade gracefully when no host is present.

(defparameter +preview-limit+ 60)

(defstruct inspect-component
  (label "" :type string)
  (preview "" :type string)
  accessor                                  ; S-expr template with `_`, or :opaque
  value                                     ; component value, or :unrealized
  (descendable-p nil))

(defstruct inspect-page
  value
  (type-name "" :type string)
  (header "" :type string)
  (components '() :type list))

;;; --- helpers -------------------------------------------------------

(defun %sym (name) (intern-autolisp-symbol name))
(defun %ph () (intern-autolisp-symbol "_"))

(defun preview-of (value &optional (limit +preview-limit+))
  "One-line printed representation of VALUE (AutoLISP surface syntax via
the runtime's print-object methods), truncated to LIMIT."
  (let ((string (handler-case (prin1-to-string value)
                  (error () "#<unprintable>"))))
    (if (> (length string) limit)
        (concatenate 'string (subseq string 0 limit) "…")
        string)))

(defun %component (label value accessor &key (descendable t))
  (make-inspect-component :label label
                          :preview (preview-of value)
                          :accessor accessor
                          :value value
                          :descendable-p descendable))

(defun %eval-accessor (template value context)
  "Evaluate TEMPLATE with `_` replaced by VALUE embedded literally;
returns (values result ok-p), ok-p NIL when the evaluation errors (e.g.
no host for ENTGET)."
  (handler-case
      (values (autolisp-eval (subst value (%ph) template :test #'eq) context) t)
    (error () (values nil nil))))

(defun runtime-list-elements (value &optional (limit 256))
  "Elements of a proper-list prefix of VALUE, up to LIMIT, and whether it
was a proper list within the limit."
  (let ((elements '()) (count 0))
    (loop for cell = value then (cdr cell)
          while (consp cell)
          do (push (car cell) elements) (incf count)
          until (>= count limit))
    (values (nreverse elements)
            (and (null (nthcdr count value)) (<= count limit)))))

;;; --- the generic + per-type methods (spec §15.1) -------------------

(defgeneric inspect-page-for (value &optional context)
  (:documentation "Return an INSPECT-PAGE describing VALUE."))

(defmethod inspect-page-for ((value integer) &optional context)
  (declare (ignore context))
  (make-inspect-page :value value :type-name "INT" :header (preview-of value)))

(defmethod inspect-page-for ((value double-float) &optional context)
  (declare (ignore context))
  (make-inspect-page :value value :type-name "REAL" :header (preview-of value)))

(defmethod inspect-page-for ((value null) &optional context)
  (declare (ignore context))
  (make-inspect-page :value value :type-name "LIST" :header "nil"))

(defmethod inspect-page-for ((value autolisp-string) &optional context)
  (declare (ignore context))
  (let* ((string (autolisp-string-value value))
         (length (length string))
         (components
           (loop for index from 0 below (min length 64)
                 collect (%component
                          (format nil "[~D]" index)
                          (make-autolisp-string :value (string (char string index)))
                          ;; AutoLISP SUBSTR is 1-based
                          (list (%sym "SUBSTR") (%ph) (1+ index) 1)
                          :descendable nil))))
    (make-inspect-page :value value :type-name "STR"
                       :header (format nil "~S  (strlen ~D)" string length)
                       :components components)))

(defmethod inspect-page-for ((value autolisp-symbol) &optional (context (current-evaluation-context)))
  (let* ((var (multiple-value-bind (v bound) (lookup-variable value context)
                (if bound v :unbound)))
         (fn (multiple-value-bind (f bound) (lookup-function value context)
               (if bound f :unbound)))
         (plist (ignore-errors
                  (clautolisp.autolisp-runtime.internal::autolisp-symbol-plist value))))
    (make-inspect-page
     :value value :type-name "SYM"
     :header (autolisp-symbol-name value)
     :components
     (list (%component "value" (if (eq var :unbound) nil var)
                       (list (%sym "EVAL") (%ph))
                       :descendable (not (eq var :unbound)))
           (%component "function" (if (eq fn :unbound) nil fn)
                       (list (%sym "FUNCTION") (%ph))
                       :descendable (not (eq fn :unbound)))
           (%component "plist" plist
                       (list (%sym "VLAX-LDATA-LIST") (%ph))
                       :descendable (and plist t))))))

(defmethod inspect-page-for ((value cons) &optional context)
  (declare (ignore context))
  (multiple-value-bind (elements properp) (runtime-list-elements value)
    (let ((components
            (list* (%component "car" (car value) (list (%sym "CAR") (%ph)))
                   (%component "cdr" (cdr value) (list (%sym "CDR") (%ph)))
                   ;; extended indexed view for a proper list (§15.1)
                   (when properp
                     (loop for element in elements
                           for index from 0
                           collect (%component
                                    (format nil "nth ~D" index)
                                    element
                                    (list (%sym "NTH") index (%ph))))))))
      (make-inspect-page :value value :type-name "LIST"
                         :header (format nil "~A  (~D element~:P)"
                                         (preview-of value)
                                         (if properp (length elements) -1))
                         :components components))))

(defmethod inspect-page-for ((value autolisp-ename) &optional (context (current-evaluation-context)))
  ;; DXF group codes via (entget _); degrade if no host is available.
  (multiple-value-bind (dxf ok) (%eval-accessor (list (%sym "ENTGET") (%ph)) value context)
    (if (and ok (consp dxf))
        (make-inspect-page
         :value value :type-name "ENAME"
         :header (format nil "~A  (entget: ~D group~:P)" (preview-of value) (length dxf))
         :components
         (cons (%component "entget" dxf (list (%sym "ENTGET") (%ph)))
               (loop for pair in dxf
                     when (consp pair)
                       collect (%component
                                (format nil "group ~A" (car pair))
                                (cdr pair)
                                (list (%sym "CDR")
                                      (list (%sym "ASSOC") (car pair)
                                            (list (%sym "ENTGET") (%ph))))
                                :descendable (consp (cdr pair))))))
        (make-inspect-page
         :value value :type-name "ENAME"
         :header (format nil "~A  (entget unavailable)" (preview-of value))
         :components (list (%component "entget" :unrealized
                                       (list (%sym "ENTGET") (%ph))
                                       :descendable nil))))))

(defmethod inspect-page-for ((value autolisp-pickset) &optional (context (current-evaluation-context)))
  (multiple-value-bind (length ok) (%eval-accessor (list (%sym "SSLENGTH") (%ph)) value context)
    (let ((n (and ok (integerp length) length)))
      (make-inspect-page
       :value value :type-name "PICKSET"
       :header (format nil "~A  (sslength ~A)" (preview-of value) (or n "?"))
       :components
       (when n
         (loop for index from 0 below (min n 256)
               for (item item-ok)
                 = (multiple-value-list
                    (%eval-accessor (list (%sym "SSNAME") (%ph) index) value context))
               collect (%component (format nil "ssname ~D" index)
                                   (if item-ok item :unrealized)
                                   (list (%sym "SSNAME") (%ph) index)
                                   :descendable item-ok)))))))

(defmethod inspect-page-for ((value autolisp-file) &optional context)
  (declare (ignore context))
  ;; Read-only derived properties; no AutoLISP accessor reconstructs a file
  ;; descriptor (spec §15.1).
  (make-inspect-page
   :value value :type-name "FILE"
   :header (format nil "#<file ~A  mode ~A>"
                   (or (autolisp-file-path value) "?")
                   (or (autolisp-file-mode value) "?"))))

(defmethod inspect-page-for ((value autolisp-vla-object) &optional context)
  (declare (ignore context))
  ;; Properties need ActiveX; not enumerable here. Descend via the REPL
  ;; with (vla-get-PROP _) when ActiveX is loaded.
  (make-inspect-page :value value :type-name "VLA-OBJECT"
                     :header (preview-of value)))

(defmethod inspect-page-for ((value t) &optional context)
  (declare (ignore context))
  ;; A value with no AutoLISP-expressible accessor: descending is still
  ;; allowed, but the accessor is :opaque, so session-path-expression
  ;; reports the path as :partial (spec §15.1/§15.2).
  (make-inspect-page :value value
                     :type-name "?"
                     :header (preview-of value)
                     :components
                     (list (%component "value" value :opaque :descendable t))))
