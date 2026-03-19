(in-package #:clautolisp.autolisp-builtins-core)

(defparameter *core-builtin-names*
  '("TYPE" "NULL" "NOT" "ATOM" "VL-SYMBOLP" "VL-SYMBOL-NAME" "VL-SYMBOL-VALUE"
    "+" "-" "*" "/"
    "BOUNDP" "CAR" "CDR" "CONS" "LIST" "APPEND" "ASSOC" "LENGTH" "NTH"
    "REVERSE" "LAST" "MEMBER" "SUBST" "LISTP" "VL-CONSP" "VL-LIST*"
    "NUMBERP" "=" "/=" "<" "<=" ">" ">=" "ABS" "FIX" "FLOAT" "ZEROP"
    "MINUSP"))

(defun builtin-boundp (object)
  (unless (typep object 'autolisp-symbol)
    (error "Expected an AutoLISP symbol, got ~S." object))
  (if (and (autolisp-symbol-value-bound-p object)
           (autolisp-symbol-value object))
      (intern-autolisp-symbol "T")
      nil))

(defun builtin-car (object)
  (cond
    ((null object) nil)
    ((consp object) (car object))
    (t
     (error "CAR expects a list, got ~S." object))))

(defun builtin-cdr (object)
  (cond
    ((null object) nil)
    ((consp object) (cdr object))
    (t
     (error "CDR expects a list or dotted pair, got ~S." object))))

(defun builtin-cons (first second)
  (cons first second))

(defun builtin-list (&rest objects)
  objects)

(defun proper-list-p (object)
  (loop
    while (consp object)
    do (setf object (cdr object))
    finally (return (null object))))

(defun require-proper-list (object operator-name)
  (unless (proper-list-p object)
    (error "~A expects a proper list, got ~S." operator-name object))
  object)

(defun autolisp-value= (left right)
  (cond
    ((and (null left) (null right))
     t)
    ((and (integerp left) (integerp right))
     (= left right))
    ((and (numberp left) (numberp right))
     (= left right))
    ((and (typep left 'autolisp-string)
          (typep right 'autolisp-string))
     (string= (autolisp-string-value left)
              (autolisp-string-value right)))
    ((and (typep left 'autolisp-symbol)
          (typep right 'autolisp-symbol))
     (string= (autolisp-symbol-name left)
              (autolisp-symbol-name right)))
    (t
     (eql left right))))

(defun builtin-append (&rest lists)
  (if (null lists)
      nil
      (progn
        (dolist (list (butlast lists))
          (require-proper-list list "APPEND"))
        (apply #'append lists))))

(defun builtin-assoc (key alist)
  (require-proper-list alist "ASSOC")
  (dolist (entry alist nil)
    (unless (consp entry)
      (error "ASSOC expects an alist, got entry ~S." entry))
    (when (autolisp-value= key (car entry))
      (return entry))))

(defun builtin-length (object)
  (require-proper-list object "LENGTH")
  (length object))

(defun builtin-nth (index object)
  (unless (typep index '(integer 0 2147483647))
    (error "NTH expects a non-negative AutoLISP integer index, got ~S." index))
  (require-proper-list object "NTH")
  (nth index object))

(defun builtin-reverse (object)
  (require-proper-list object "REVERSE")
  (reverse object))

(defun builtin-last (object)
  (require-proper-list object "LAST")
  (if (null object)
      nil
      (loop
        while (consp (cdr object))
        do (setf object (cdr object))
        finally (return (car object)))))

(defun builtin-member (item object)
  (require-proper-list object "MEMBER")
  (loop
    while (consp object)
    do (when (autolisp-value= item (car object))
         (return object))
       (setf object (cdr object))
    finally (return nil)))

(defun subst-tree (new old expr)
  (cond
    ((autolisp-value= expr old)
     new)
    ((consp expr)
     (cons (subst-tree new old (car expr))
           (subst-tree new old (cdr expr))))
    (t
     expr)))

(defun builtin-subst (new old expr)
  (subst-tree new old expr))

(defun builtin-vl-consp (object)
  (if (consp object)
      (intern-autolisp-symbol "T")
      nil))

(defun builtin-vl-list* (&rest arguments)
  (unless arguments
    (error "VL-LIST* expects at least one argument."))
  (if (null (rest arguments))
      (first arguments)
      (apply #'list* arguments)))

(defun builtin-numberp (object)
  (if (numberp object)
      (intern-autolisp-symbol "T")
      nil))

(defun arithmetic-result (value)
  (cond
    ((typep value '(signed-byte 32))
     value)
    ((integerp value)
     (error "Arithmetic result is outside the AutoLISP 32-bit integer range: ~S."
            value))
    ((rationalp value)
     (coerce value 'double-float))
    ((floatp value)
     (coerce value 'double-float))
    (t
     value)))

(defun builtin-+ (&rest arguments)
  (dolist (argument arguments)
    (require-number argument "+"))
  (arithmetic-result (apply #'+ arguments)))

(defun builtin-* (&rest arguments)
  (dolist (argument arguments)
    (require-number argument "*"))
  (arithmetic-result (apply #'* arguments)))

(defun builtin-- (first-number &rest more-numbers)
  (require-number first-number "-")
  (dolist (argument more-numbers)
    (require-number argument "-"))
  (arithmetic-result
   (if more-numbers
       (apply #'- first-number more-numbers)
       (- first-number))))

(defun builtin-/ (first-number &rest more-numbers)
  (require-number first-number "/")
  (dolist (argument more-numbers)
    (require-number argument "/"))
  (arithmetic-result
   (if more-numbers
       (apply #'/ first-number more-numbers)
       (/ 1 first-number))))

(defun comparison-value (object operator-name)
  (cond
    ((numberp object)
     object)
    ((typep object 'autolisp-string)
     (autolisp-string-value object))
    (t
     (error "~A expects numbers or strings, got ~S." operator-name object))))

(defun builtin-= (&rest arguments)
  (unless arguments
    (error "= expects at least one argument."))
  (let ((first-value (comparison-value (first arguments) "=")))
    (if (every (lambda (argument)
                 (equal first-value (comparison-value argument "=")))
               (rest arguments))
        (intern-autolisp-symbol "T")
        nil)))

(defun builtin-/= (&rest arguments)
  (unless arguments
    (error "/= expects at least one argument."))
  (let ((values (mapcar (lambda (argument)
                          (comparison-value argument "/="))
                        arguments)))
    (if (= (length values)
           (length (remove-duplicates values :test #'equal)))
        (intern-autolisp-symbol "T")
        nil)))

(defun require-number (object operator-name)
  (unless (numberp object)
    (error "~A expects a number, got ~S." operator-name object))
  object)

(defun numeric-order-p (arguments predicate operator-name)
  (dolist (argument arguments)
    (require-number argument operator-name))
  (if (or (null arguments)
          (null (rest arguments))
          (loop for (left right) on arguments
                while right
                always (funcall predicate left right)))
      (intern-autolisp-symbol "T")
      nil))

(defun builtin-< (&rest arguments)
  (numeric-order-p arguments #'< "<"))

(defun builtin-<= (&rest arguments)
  (numeric-order-p arguments #'<= "<="))

(defun builtin-> (&rest arguments)
  (numeric-order-p arguments #'> ">"))

(defun builtin->= (&rest arguments)
  (numeric-order-p arguments #'>= ">="))

(defun builtin-abs (object)
  (abs (require-number object "ABS")))

(defun builtin-fix (object)
  (let ((value (truncate (require-number object "FIX"))))
    (unless (typep value '(signed-byte 32))
      (error "FIX result is outside the AutoLISP 32-bit integer range: ~S." value))
    value))

(defun builtin-float (object)
  (coerce (require-number object "FLOAT") 'double-float))

(defun builtin-zerop (object)
  (if (zerop (require-number object "ZEROP"))
      (intern-autolisp-symbol "T")
      nil))

(defun builtin-minusp (object)
  (if (minusp (require-number object "MINUSP"))
      (intern-autolisp-symbol "T")
      nil))

(defun core-builtins ()
  (list
   (make-autolisp-subr "TYPE" #'autolisp-type)
   (make-autolisp-subr "NULL" #'autolisp-null)
   (make-autolisp-subr "NOT" #'autolisp-not)
   (make-autolisp-subr "ATOM" #'autolisp-atom)
   (make-autolisp-subr "VL-SYMBOLP" #'autolisp-vl-symbolp)
   (make-autolisp-subr "VL-SYMBOL-NAME" #'autolisp-vl-symbol-name)
   (make-autolisp-subr "VL-SYMBOL-VALUE" #'autolisp-vl-symbol-value)
   (make-autolisp-subr "+" #'builtin-+)
   (make-autolisp-subr "-" #'builtin--)
   (make-autolisp-subr "*" #'builtin-*)
   (make-autolisp-subr "/" #'builtin-/)
   (make-autolisp-subr "BOUNDP" #'builtin-boundp)
   (make-autolisp-subr "CAR" #'builtin-car)
   (make-autolisp-subr "CDR" #'builtin-cdr)
   (make-autolisp-subr "CONS" #'builtin-cons)
   (make-autolisp-subr "LIST" #'builtin-list)
   (make-autolisp-subr "APPEND" #'builtin-append)
   (make-autolisp-subr "ASSOC" #'builtin-assoc)
   (make-autolisp-subr "LENGTH" #'builtin-length)
   (make-autolisp-subr "NTH" #'builtin-nth)
   (make-autolisp-subr "REVERSE" #'builtin-reverse)
   (make-autolisp-subr "LAST" #'builtin-last)
   (make-autolisp-subr "MEMBER" #'builtin-member)
   (make-autolisp-subr "SUBST" #'builtin-subst)
   (make-autolisp-subr "LISTP" #'autolisp-listp)
   (make-autolisp-subr "VL-CONSP" #'builtin-vl-consp)
   (make-autolisp-subr "VL-LIST*" #'builtin-vl-list*)
   (make-autolisp-subr "NUMBERP" #'builtin-numberp)
   (make-autolisp-subr "=" #'builtin-=)
   (make-autolisp-subr "/=" #'builtin-/=)
   (make-autolisp-subr "<" #'builtin-<)
   (make-autolisp-subr "<=" #'builtin-<=)
   (make-autolisp-subr ">" #'builtin->)
   (make-autolisp-subr ">=" #'builtin->=)
   (make-autolisp-subr "ABS" #'builtin-abs)
   (make-autolisp-subr "FIX" #'builtin-fix)
   (make-autolisp-subr "FLOAT" #'builtin-float)
   (make-autolisp-subr "ZEROP" #'builtin-zerop)
   (make-autolisp-subr "MINUSP" #'builtin-minusp)))

(defun find-core-builtin (name)
  (find name (core-builtins)
        :key #'autolisp-subr-name
        :test #'string=))

(defun install-core-builtins ()
  (dolist (builtin (core-builtins))
    (let ((symbol (intern-autolisp-symbol (autolisp-subr-name builtin))))
      (set-autolisp-symbol-function symbol builtin)))
  t)
