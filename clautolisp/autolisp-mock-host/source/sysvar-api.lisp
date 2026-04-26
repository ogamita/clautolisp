(in-package #:clautolisp.autolisp-mock-host)

;;;; Sysvar HAL methods on MockHost (Phase 11).
;;;;
;;;; Implements: host-getvar, host-setvar.
;;;;
;;;; getvar returns the cell's current value, wrapping CL strings in
;;;; AutoLISP-strings. setvar coerces the supplied value against the
;;;; cell's :kind: integers / shorts truncate reals, reals coerce
;;;; from any number, strings come from AutoLISP-strings, points
;;;; come from coordinate lists.

(defun ensure-sysvar-name (name operator-name)
  (cond
    ((typep name 'clautolisp.autolisp-runtime:autolisp-string)
     (clautolisp.autolisp-runtime:autolisp-string-value name))
    ((stringp name) name)
    (t
     (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
      :invalid-sysvar-name
      "~A expects a sysvar name string, got ~S."
      operator-name name))))

(defun mock-string-of (value)
  (cond
    ((typep value 'clautolisp.autolisp-runtime:autolisp-string)
     (clautolisp.autolisp-runtime:autolisp-string-value value))
    ((stringp value) value)
    (t nil)))

(defun coerce-sysvar-value (kind value cell-name)
  "Coerce VALUE against the documented sysvar KIND. Signals
:invalid-sysvar-value on type mismatch."
  (case kind
    ((:integer)
     (cond
       ((typep value '(signed-byte 32)) value)
       ((integerp value) value)
       ((numberp value) (truncate value))
       (t
        (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
         :invalid-sysvar-value
         "Sysvar ~A expects an integer, got ~S."
         cell-name value))))
    ((:short)
     (cond
       ((numberp value) (max -32768 (min 32767 (truncate value))))
       (t
        (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
         :invalid-sysvar-value
         "Sysvar ~A expects a short integer, got ~S."
         cell-name value))))
    ((:real)
     (cond
       ((numberp value) (coerce value 'double-float))
       (t
        (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
         :invalid-sysvar-value
         "Sysvar ~A expects a real number, got ~S."
         cell-name value))))
    ((:string)
     (let ((string (mock-string-of value)))
       (or string
           (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
            :invalid-sysvar-value
            "Sysvar ~A expects a string, got ~S."
            cell-name value))))
    ((:point)
     (cond
       ((and (listp value) (every #'numberp value)
             (or (= (length value) 2) (= (length value) 3)))
        (mapcar (lambda (n) (coerce n 'double-float)) value))
       (t
        (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
         :invalid-sysvar-value
         "Sysvar ~A expects a 2-D or 3-D point list, got ~S."
         cell-name value))))
    (t value)))

(defun present-sysvar-value (kind raw)
  "Wrap RAW for AutoLISP consumption; strings get an
autolisp-string wrapper, others are returned as-is."
  (case kind
    ((:string)
     (clautolisp.autolisp-runtime:make-autolisp-string raw))
    (t raw)))

;;; --- Method definitions ------------------------------------------

(defmethod host-getvar ((host mock-host) name)
  (let* ((string (ensure-sysvar-name name 'getvar))
         (cell (mock-host-sysvar host string)))
    (and cell
         (present-sysvar-value (sysvar-cell-kind cell)
                               (sysvar-cell-value cell)))))

(defmethod host-setvar ((host mock-host) name value)
  (let* ((string (ensure-sysvar-name name 'setvar))
         (cell (mock-host-sysvar host string)))
    (cond
      ((null cell)
       (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
        :unknown-sysvar
        "MockHost has no system variable named ~A."
        string))
      ((sysvar-cell-read-only-p cell)
       (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
        :sysvar-read-only
        "Sysvar ~A is read-only."
        string))
      (t
       (let ((coerced (coerce-sysvar-value (sysvar-cell-kind cell) value string)))
         (setf (sysvar-cell-value cell) coerced)
         (present-sysvar-value (sysvar-cell-kind cell) coerced))))))
