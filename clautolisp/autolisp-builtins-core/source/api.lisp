(in-package #:clautolisp.autolisp-builtins-core)

(defparameter *core-builtin-names*
  '("TYPE" "NULL" "NOT" "ATOM" "VL-SYMBOLP" "VL-SYMBOL-NAME" "VL-SYMBOL-VALUE"
    "VL-BB-REF" "VL-BB-SET" "VL-PROPAGATE" "VL-DOC-REF" "VL-DOC-SET"
    "VL-DOC-EXPORT" "VL-DOC-IMPORT"
    "MAPCAR" "VL-EVERY" "VL-MEMBER-IF" "VL-MEMBER-IF-NOT" "VL-REMOVE-IF"
    "VL-REMOVE-IF-NOT" "VL-SOME"
    "+" "-" "*" "/" "1+" "1-" "MAX" "MIN" "REM" "GCD" "LCM" "~" "LOGAND"
    "LOGIOR" "LSH" "STRCAT" "STRLEN" "SUBSTR" "ASCII" "CHR" "ATOI" "ATOF"
    "READ" "LOAD" "AUTOLOAD" "OPEN" "CLOSE" "READ-LINE" "READ-CHAR" "WRITE-LINE" "WRITE-CHAR"
    "FINDFILE" "FINDTRUSTEDFILE" "VL-DIRECTORY-FILES" "VL-FILE-DIRECTORY-P"
    "VL-FILENAME-BASE" "VL-FILENAME-DIRECTORY" "VL-FILENAME-EXTENSION"
    "VL-FILE-DELETE" "VL-FILE-RENAME" "VL-FILE-SIZE" "VL-FILE-SYSTIME"
    "VL-FILE-COPY" "VL-FILENAME-MKTEMP" "VL-MKDIR"
    "PRIN1" "PRINC" "PRINT" "TERPRI" "PROMPT" "EXIT" "QUIT"
    "VL-PRIN1-TO-STRING" "VL-PRINC-TO-STRING"
    "VL-CATCH-ALL-APPLY" "VL-CATCH-ALL-ERROR-P" "VL-CATCH-ALL-ERROR-MESSAGE"
    "VL-EXIT-WITH-ERROR" "VL-EXIT-WITH-VALUE"
    "DEFUN-Q-LIST-REF" "DEFUN-Q-LIST-SET"
    "BOUNDP" "CAR" "CDR" "CONS" "LIST" "APPEND" "ASSOC" "LENGTH" "NTH"
    "REVERSE" "LAST" "MEMBER" "SUBST" "LISTP" "VL-CONSP" "VL-LIST*"
    "NUMBERP" "=" "/=" "<" "<=" ">" ">=" "ABS" "FIX" "FLOAT" "ZEROP"
    "MINUSP"))

(defun make-builtin-runtime-error (code builtin-name condition)
  (error 'autolisp-runtime-error
         :code code
         :message (format nil
                          "AutoLISP builtin ~A signaled an error: ~A"
                          builtin-name
                          condition)
         :details (list :builtin builtin-name
                        :condition condition)))

(defun signal-builtin-argument-error (code builtin-name control-string &rest arguments)
  (error 'autolisp-runtime-error
         :code code
         :message (apply #'format nil control-string arguments)
         :details (list* :builtin builtin-name arguments)))

(defun signal-builtin-host-error (code builtin-name control-string &rest arguments)
  (error 'autolisp-runtime-error
         :code code
         :message (apply #'format nil control-string arguments)
         :details (list* :builtin builtin-name arguments)))

(defun wrap-builtin-function (builtin-name function)
  (lambda (&rest arguments)
    (handler-case
        (apply function arguments)
      (autolisp-runtime-error (condition)
        (error condition))
      (file-error (condition)
        (make-builtin-runtime-error :builtin-file-error builtin-name condition))
      (error (condition)
        (make-builtin-runtime-error :builtin-error builtin-name condition)))))

(defun make-core-builtin-subr (name function)
  (make-autolisp-subr name (wrap-builtin-function name function)))

(defun builtin-boundp (object)
  (unless (typep object 'autolisp-symbol)
    (signal-builtin-argument-error
     :invalid-symbol-argument
     "BOUNDP"
     "Expected an AutoLISP symbol, got ~S."
     object))
  (clautolisp.autolisp-runtime:autolisp-boundp object))

(defun builtin-vl-bb-ref (object)
  (unless (typep object 'autolisp-symbol)
    (signal-builtin-argument-error
     :invalid-symbol-argument
     "VL-BB-REF"
     "VL-BB-REF expects an AutoLISP symbol, got ~S."
     object))
  (nth-value 0 (blackboard-ref object)))

(defun builtin-vl-bb-set (symbol value)
  (unless (typep symbol 'autolisp-symbol)
    (signal-builtin-argument-error
     :invalid-symbol-argument
     "VL-BB-SET"
     "VL-BB-SET expects an AutoLISP symbol, got ~S."
     symbol))
  (blackboard-set symbol value))

(defun builtin-vl-propagate (symbol)
  (unless (typep symbol 'autolisp-symbol)
    (signal-builtin-argument-error
     :invalid-symbol-argument
     "VL-PROPAGATE"
     "VL-PROPAGATE expects an AutoLISP symbol, got ~S."
     symbol))
  (propagate-variable symbol))

(defun builtin-vl-doc-ref (object)
  (unless (typep object 'autolisp-symbol)
    (signal-builtin-argument-error
     :invalid-symbol-argument
     "VL-DOC-REF"
     "VL-DOC-REF expects an AutoLISP symbol, got ~S."
     object))
  (nth-value 0 (current-document-namespace-ref object)))

(defun builtin-vl-doc-set (symbol value)
  (unless (typep symbol 'autolisp-symbol)
    (signal-builtin-argument-error
     :invalid-symbol-argument
     "VL-DOC-SET"
     "VL-DOC-SET expects an AutoLISP symbol, got ~S."
     symbol))
  (current-document-namespace-set symbol value))

(defun builtin-vl-doc-export (object)
  (unless (typep object 'autolisp-symbol)
    (signal-builtin-argument-error
     :invalid-symbol-argument
     "VL-DOC-EXPORT"
     "VL-DOC-EXPORT currently expects an AutoLISP symbol, got ~S."
     object))
  (export-function-to-current-document object))

(defun builtin-vl-doc-import (object)
  (cond
    ((typep object 'autolisp-symbol)
     (import-function-from-current-document object))
    ((typep object 'autolisp-string)
     (import-functions-from-application object))
    (t
     (signal-builtin-argument-error
      :invalid-symbol-argument
      "VL-DOC-IMPORT"
      "VL-DOC-IMPORT currently expects an AutoLISP symbol or application string, got ~S."
      object))))

(defun require-function-definition-list (object operator-name)
  (unless (and (consp object) (listp object))
    (signal-builtin-argument-error
     :invalid-defun-q-definition
     operator-name
     "~A expects a proper list function definition, got ~S."
     operator-name
     object))
  object)

(defun builtin-defun-q-list-ref (object)
  (unless (typep object 'autolisp-symbol)
    (signal-builtin-argument-error
     :invalid-symbol-argument
     "DEFUN-Q-LIST-REF"
     "DEFUN-Q-LIST-REF expects an AutoLISP symbol, got ~S."
     object))
  (autolisp-function-list-definition object))

(defun builtin-defun-q-list-set (symbol definition)
  (unless (typep symbol 'autolisp-symbol)
    (signal-builtin-argument-error
     :invalid-symbol-argument
     "DEFUN-Q-LIST-SET"
     "DEFUN-Q-LIST-SET expects an AutoLISP symbol, got ~S."
     symbol))
  (let* ((list-definition (require-function-definition-list definition "DEFUN-Q-LIST-SET"))
         (lambda-list (first list-definition))
         (body (rest list-definition))
         (function (make-autolisp-usubr (autolisp-symbol-name symbol)
                                        lambda-list
                                        body
                                        (default-evaluation-context))))
    (set-autolisp-symbol-function symbol function)
    (set-autolisp-function-list-definition symbol list-definition)
    symbol))

(defun filename-extension-present-p (string)
  (let* ((normalized (normalize-path-string string))
         (separator (position #\/ normalized :from-end t))
         (leaf (if separator
                   (subseq normalized (1+ separator))
                   normalized)))
    (not (null (position #\. leaf :from-end t)))))

(defun load-candidate-paths (filename)
  (let ((normalized (normalize-path-string filename)))
    (if (filename-extension-present-p normalized)
        (list normalized)
        (mapcar (lambda (extension)
                  (concatenate 'string normalized extension))
                '(".vlx" ".fas" ".lsp")))))

(defun resolve-load-pathname (filename)
  (let ((normalized (normalize-path-string filename)))
    (cond
      ((directory-prefix-p normalized)
       (dolist (candidate (load-candidate-paths normalized) nil)
         (let ((resolved (resolve-open-pathname candidate)))
           (when (probe-file resolved)
             (return resolved)))))
      (t
       (dolist (candidate (load-candidate-paths normalized) nil)
         (let ((direct (probe-file (resolve-open-pathname candidate))))
           (when direct
             (return direct)))
         (let ((located (search-path-list-for-file candidate
                                                   (autolisp-support-paths))))
           (when located
             (return (pathname located)))))))))

(defun evaluate-load-onfailure (object)
  (cond
    ((null object) nil)
    ((or (typep object 'autolisp-subr)
         (typep object 'clautolisp.autolisp-runtime:autolisp-usubr))
     (call-autolisp-function object))
    ((typep object 'autolisp-symbol)
     (call-autolisp-function
      (resolve-autolisp-function-designator object)))
    (t
     object)))

(defun builtin-load (filename &optional (onfailure nil onfailure-supplied-p))
  (let* ((value (autolisp-string-value (require-string filename "LOAD")))
         (resolved (resolve-load-pathname value)))
    (cond
      ((null resolved)
       (if onfailure-supplied-p
           (evaluate-load-onfailure onfailure)
           (call-with-autolisp-error-handler
            (lambda ()
              (signal-builtin-host-error
               :load-file-not-found
               "LOAD"
               "LOAD could not locate ~A."
               value)))))
      ((member (string-downcase (or (pathname-type resolved) "")) '("vlx" "fas")
               :test #'string=)
       (if onfailure-supplied-p
           (evaluate-load-onfailure onfailure)
           (call-with-autolisp-error-handler
            (lambda ()
              (signal-builtin-host-error
               :unsupported-load-file-type
               "LOAD"
               "LOAD currently supports only source files, got ~A."
               (namestring resolved))))))
      (t
       (autolisp-load-file (namestring resolved))))))

(defun builtin-autoload (filename function-list)
  (let ((path (autolisp-string-value (require-string filename "AUTOLOAD"))))
    (require-proper-list function-list "AUTOLOAD")
    (dolist (name function-list nil)
      (let* ((command-name (autolisp-string-value (require-string name "AUTOLOAD")))
             (symbol (intern-autolisp-symbol command-name))
             (stub nil))
        (setf stub
              (make-autolisp-subr
               command-name
               (lambda (&rest arguments)
                 (builtin-load (make-autolisp-string path))
                 (let ((function (resolve-autolisp-function-designator symbol)))
                   (when (eq function stub)
                     (signal-builtin-host-error
                      :autoload-definition-missing
                      "AUTOLOAD"
                      "AUTOLOAD loaded ~A but did not define ~A."
                      path
                      command-name))
                   (apply #'call-autolisp-function function arguments)))))
        (set-autolisp-symbol-function symbol stub)))))

(defun builtin-vl-catch-all-apply (function-designator arg-list)
  (require-proper-list arg-list "VL-CATCH-ALL-APPLY")
  (handler-case
      (let ((result (apply #'call-autolisp-function
                           (resolve-autolisp-function-designator function-designator)
                           arg-list)))
        (set-autolisp-errno 0)
        result)
    (autolisp-termination (condition)
      (error condition))
    (autolisp-namespace-exit (condition)
      (error condition))
    (autolisp-runtime-error (condition)
      (set-autolisp-errno
       (autolisp-runtime-error-errno condition))
      (make-autolisp-catch-all-error
       (princ-to-string condition)
       condition))
    (error (condition)
      (set-autolisp-errno 1)
      (make-autolisp-catch-all-error
       (princ-to-string condition)
       condition))))

(defun builtin-vl-catch-all-error-p (object)
  (if (typep object 'autolisp-catch-all-error)
      (intern-autolisp-symbol "T")
      nil))

(defun builtin-vl-catch-all-error-message (object)
  (unless (typep object 'autolisp-catch-all-error)
    (signal-builtin-argument-error
     :invalid-catch-all-object
     "VL-CATCH-ALL-ERROR-MESSAGE"
     "VL-CATCH-ALL-ERROR-MESSAGE expects a catch-all error object, got ~S."
     object))
  (make-autolisp-string (autolisp-catch-all-error-message object)))

(defun builtin-exit ()
  (error 'autolisp-termination :kind :exit))

(defun builtin-quit ()
  (error 'autolisp-termination :kind :quit))

(defun builtin-vl-exit-with-error (message)
  (let ((text (autolisp-string-value (require-string message "VL-EXIT-WITH-ERROR"))))
    (error 'autolisp-namespace-exit :kind :error :value text)))

(defun builtin-vl-exit-with-value (value)
  (error 'autolisp-namespace-exit :kind :value :value value))

(defun builtin-mapcar (function-designator first-list &rest more-lists)
  (let* ((function (resolve-autolisp-function-designator function-designator))
         (lists (mapcar (lambda (object)
                          (require-proper-list object "MAPCAR"))
                        (cons first-list more-lists)))
         (results '()))
    (loop while (every #'consp lists)
          do (push (apply #'call-autolisp-function
                          function
                          (mapcar #'car lists))
                   results)
             (setf lists (mapcar #'cdr lists)))
    (nreverse results)))

(defun builtin-apply (function-designator argument-list)
  ;; (apply 'function list) — call function with the elements of list
  ;; spread as positional arguments. function-designator is whatever
  ;; resolve-autolisp-function-designator accepts: a subr/usubr, a
  ;; symbol naming a function, or a (lambda ...) / (quote (lambda ...))
  ;; / (function ...) form. nil is permitted in place of an empty
  ;; arg-list.
  (let ((function (resolve-autolisp-function-designator function-designator))
        (arguments (cond
                     ((null argument-list) '())
                     ((listp argument-list) argument-list)
                     (t
                      (signal-builtin-argument-error
                       :invalid-list-argument
                       "APPLY"
                       "APPLY expects a list of arguments, got ~S."
                       argument-list)))))
    (apply #'call-autolisp-function function arguments)))

(defun builtin-eval (form)
  ;; (eval expr) — evaluate the AutoLISP runtime form in the current
  ;; evaluation context. Lets programs evaluate values built at
  ;; runtime (e.g. constructed via list/cons).
  (autolisp-eval form))

(defun autolisp-equal-p (a b)
  ;; AutoLISP `equal` (autolisp-spec ch. 5, "Equality Predicates"):
  ;; structural over cons cells, content for strings, numeric across
  ;; int and real (so (equal 1 1.0) -> T), eq for everything else.
  (cond
    ((eql a b) t)
    ((and (numberp a) (numberp b)) (= a b))
    ((and (typep a 'autolisp-string) (typep b 'autolisp-string))
     (string= (autolisp-string-value a) (autolisp-string-value b)))
    ((and (consp a) (consp b))
     (and (autolisp-equal-p (car a) (car b))
          (autolisp-equal-p (cdr a) (cdr b))))
    (t nil)))

(defun builtin-eq (a b)
  ;; (eq a b) — pointer-level identity, with the standard exception
  ;; that two strings whose content is equal compare eq because the
  ;; host interns string literals (autolisp-spec ch. 5).
  (cond
    ((eql a b) (intern-autolisp-symbol "T"))
    ((and (typep a 'autolisp-string) (typep b 'autolisp-string)
          (string= (autolisp-string-value a) (autolisp-string-value b)))
     (intern-autolisp-symbol "T"))
    (t nil)))

(defun builtin-equal (a b &optional fuzz)
  ;; AutoLISP allows a third numeric `fuzz` argument that loosens
  ;; numeric comparisons by ±fuzz. When fuzz is nil or 0 the call
  ;; reduces to ordinary equal.
  (let ((tolerance (if (or (null fuzz) (and (numberp fuzz) (zerop fuzz)))
                       nil
                       fuzz)))
    (cond
      ((null tolerance)
       (if (autolisp-equal-p a b) (intern-autolisp-symbol "T") nil))
      ((not (numberp tolerance))
       (signal-builtin-argument-error
        :invalid-number-argument
        "EQUAL"
        "EQUAL fuzz must be a number, got ~S."
        fuzz))
      ((and (numberp a) (numberp b))
       (if (<= (abs (- a b)) tolerance)
           (intern-autolisp-symbol "T")
           nil))
      (t
       (if (autolisp-equal-p a b) (intern-autolisp-symbol "T") nil)))))

(defun builtin-vl-every (function-designator first-list &rest more-lists)
  (let* ((function (resolve-autolisp-function-designator function-designator))
         (lists (mapcar (lambda (object)
                          (require-proper-list object "VL-EVERY"))
                        (cons first-list more-lists))))
    (loop while (every #'consp lists)
          do (unless (autolisp-true-p
                      (apply #'call-autolisp-function
                             function
                             (mapcar #'car lists)))
               (return nil))
             (setf lists (mapcar #'cdr lists))
          finally (return (intern-autolisp-symbol "T")))))

(defun builtin-vl-some (function-designator first-list &rest more-lists)
  (let* ((function (resolve-autolisp-function-designator function-designator))
         (lists (mapcar (lambda (object)
                          (require-proper-list object "VL-SOME"))
                        (cons first-list more-lists))))
    (loop while (every #'consp lists)
          for result = (apply #'call-autolisp-function
                              function
                              (mapcar #'car lists))
          do (when (autolisp-true-p result)
               (return result))
             (setf lists (mapcar #'cdr lists))
          finally (return nil))))

(defun builtin-vl-member-if (function-designator object)
  (let ((function (resolve-autolisp-function-designator function-designator)))
    (require-proper-list object "VL-MEMBER-IF")
    (do ((tail object (cdr tail)))
        ((null tail) nil)
      (when (autolisp-true-p (call-autolisp-function function (car tail)))
        (return tail)))))

(defun builtin-vl-member-if-not (function-designator object)
  (let ((function (resolve-autolisp-function-designator function-designator)))
    (require-proper-list object "VL-MEMBER-IF-NOT")
    (do ((tail object (cdr tail)))
        ((null tail) nil)
      (when (autolisp-false-p (call-autolisp-function function (car tail)))
        (return tail)))))

(defun builtin-vl-remove-if (function-designator object)
  (let ((function (resolve-autolisp-function-designator function-designator)))
    (require-proper-list object "VL-REMOVE-IF")
    (loop for element in object
          unless (autolisp-true-p (call-autolisp-function function element))
            collect element)))

(defun builtin-vl-remove-if-not (function-designator object)
  (let ((function (resolve-autolisp-function-designator function-designator)))
    (require-proper-list object "VL-REMOVE-IF-NOT")
    (loop for element in object
          when (autolisp-true-p (call-autolisp-function function element))
            collect element)))

(defun builtin-car (object)
  (cond
    ((null object) nil)
    ((consp object) (car object))
    (t
     (signal-builtin-argument-error
      :invalid-list-argument
      "CAR"
      "CAR expects a list, got ~S."
      object))))

(defun builtin-cdr (object)
  (cond
    ((null object) nil)
    ((consp object) (cdr object))
    (t
     (signal-builtin-argument-error
      :invalid-list-argument
      "CDR"
      "CDR expects a list or dotted pair, got ~S."
      object))))

;; The CAxR / CDxR / CAxxR / CDxxR family. Each one is a composition
;; of CAR and CDR walked right-to-left over the letters between `c'
;; and the trailing `r'. Each step delegates to builtin-car /
;; builtin-cdr so a non-list argument anywhere along the chain
;; produces the standard "X expects a list" diagnostic with the
;; proper builtin name.

(defmacro define-cxxr (name letters)
  `(defun ,(intern (format nil "BUILTIN-~A" name)) (object)
     (let ((value object))
       ,@(loop for c across (reverse letters)
               collect (case c
                         (#\A `(setf value
                                     (cond
                                       ((null value) nil)
                                       ((consp value) (car value))
                                       (t (signal-builtin-argument-error
                                           :invalid-list-argument
                                           ,name
                                           ,(format nil "~A expects a list, got ~~S." name)
                                           value)))))
                         (#\D `(setf value
                                     (cond
                                       ((null value) nil)
                                       ((consp value) (cdr value))
                                       (t (signal-builtin-argument-error
                                           :invalid-list-argument
                                           ,name
                                           ,(format nil "~A expects a list, got ~~S." name)
                                           value)))))))
       value)))

(define-cxxr "CAAR"  "AA")
(define-cxxr "CADR"  "AD")
(define-cxxr "CDAR"  "DA")
(define-cxxr "CDDR"  "DD")
(define-cxxr "CAAAR" "AAA")
(define-cxxr "CAADR" "AAD")
(define-cxxr "CADAR" "ADA")
(define-cxxr "CADDR" "ADD")
(define-cxxr "CDAAR" "DAA")
(define-cxxr "CDADR" "DAD")
(define-cxxr "CDDAR" "DDA")
(define-cxxr "CDDDR" "DDD")
(define-cxxr "CAAAAR" "AAAA")
(define-cxxr "CAAADR" "AAAD")
(define-cxxr "CAADAR" "AADA")
(define-cxxr "CAADDR" "AADD")
(define-cxxr "CADAAR" "ADAA")
(define-cxxr "CADADR" "ADAD")
(define-cxxr "CADDAR" "ADDA")
(define-cxxr "CADDDR" "ADDD")
(define-cxxr "CDAAAR" "DAAA")
(define-cxxr "CDAADR" "DAAD")
(define-cxxr "CDADAR" "DADA")
(define-cxxr "CDADDR" "DADD")
(define-cxxr "CDDAAR" "DDAA")
(define-cxxr "CDDADR" "DDAD")
(define-cxxr "CDDDAR" "DDDA")
(define-cxxr "CDDDDR" "DDDD")

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
    (signal-builtin-argument-error
     :invalid-proper-list-argument
     operator-name
     "~A expects a proper list, got ~S."
     operator-name
     object))
  object)

(defun autolisp-value= (left right)
  (cond
    ((and (null left) (null right))
     t)
    ((and (consp left) (consp right))
     (and (autolisp-value= (car left) (car right))
          (autolisp-value= (cdr left) (cdr right))))
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
      (signal-builtin-argument-error
       :invalid-alist-argument
       "ASSOC"
       "ASSOC expects an alist, got entry ~S."
       entry))
    (when (autolisp-value= key (car entry))
      (return entry))))

(defun builtin-length (object)
  (require-proper-list object "LENGTH")
  (length object))

(defun builtin-nth (index object)
  (unless (typep index '(integer 0 2147483647))
    (signal-builtin-argument-error
     :invalid-index-argument
     "NTH"
     "NTH expects a non-negative AutoLISP integer index, got ~S."
     index))
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
    (signal-builtin-argument-error
     :wrong-number-of-arguments
     "VL-LIST*"
     "VL-LIST* expects at least one argument."))
  (if (null (rest arguments))
      (first arguments)
      (apply #'list* arguments)))

(defun require-string (object operator-name)
  (unless (typep object 'autolisp-string)
    (signal-builtin-argument-error
     :invalid-string-argument
     operator-name
     "~A expects an AutoLISP string, got ~S."
     operator-name
     object))
  object)

(defun require-file (object operator-name)
  (unless (typep object 'autolisp-file)
    (signal-builtin-argument-error
     :invalid-file-argument
     operator-name
     "~A expects an AutoLISP file descriptor, got ~S."
     operator-name
     object))
  object)

(defun require-open-file-stream (file operator-name)
  (let ((stream (autolisp-file-stream (require-file file operator-name))))
    (unless stream
      (signal-builtin-argument-error
       :closed-file-descriptor
       operator-name
       "~A expects an open file descriptor."
       operator-name))
    stream))

(defun absolute-path-string-p (string)
  (or (uiop:absolute-pathname-p (pathname string))
      (and (>= (length string) 2)
           (alpha-char-p (char string 0))
           (char= #\: (char string 1)))
      (and (>= (length string) 2)
           (char= #\\ (char string 0))
           (char= #\\ (char string 1)))))

(defun normalize-path-string (string)
  ;; AutoLISP accepts both slash and backslash delimiters in pathname-oriented APIs.
  (substitute #\/ #\\ string))

(defun directory-prefix-p (string)
  (let ((normalized (normalize-path-string string)))
    (or (absolute-path-string-p normalized)
        (position #\/ normalized))))

(defun resolve-open-pathname (string)
  (let ((normalized (normalize-path-string string)))
    (if (absolute-path-string-p normalized)
        (pathname normalized)
        (merge-pathnames normalized
                         (pathname (autolisp-current-directory))))))

(defun search-path-list-for-file (filename directories)
  (let ((normalized (normalize-path-string filename)))
    (unless (directory-prefix-p normalized)
      (dolist (directory directories nil)
        (let* ((base (pathname directory))
               (candidate (merge-pathnames normalized base))
               (located (probe-file candidate)))
          (when located
            (return (namestring located))))))))

(defun resolve-directory-pathname (directory-string operator-name)
  (let ((normalized (normalize-path-string directory-string)))
    (handler-case
        (uiop:ensure-directory-pathname
         (if (absolute-path-string-p normalized)
             (pathname normalized)
             (merge-pathnames normalized
                              (pathname (autolisp-current-directory)))))
      (error ()
        (signal-builtin-argument-error
         :invalid-directory-argument
         operator-name
         "~A expects a valid directory pathname, got ~S."
         operator-name
         directory-string)))))

(defun pathname-entry-name (pathname directoryp)
  (if directoryp
      (let* ((components (pathname-directory (uiop:ensure-directory-pathname pathname)))
             (last-component (car (last components))))
        (etypecase last-component
          (string last-component)
          (symbol (string last-component))))
      (file-namestring pathname)))

(defun wildcard-char= (pattern-char candidate-char)
  (char-equal pattern-char candidate-char))

(defun wildcard-match-p (pattern string)
  (labels ((match (pattern-index string-index)
             (cond
               ((= pattern-index (length pattern))
                (= string-index (length string)))
               ((char= #\* (char pattern pattern-index))
                (or (match (1+ pattern-index) string-index)
                    (and (< string-index (length string))
                         (match pattern-index (1+ string-index)))))
               ((char= #\? (char pattern pattern-index))
                (and (< string-index (length string))
                     (match (1+ pattern-index) (1+ string-index))))
               ((< string-index (length string))
                (and (wildcard-char= (char pattern pattern-index)
                                     (char string string-index))
                     (match (1+ pattern-index) (1+ string-index))))
               (t
                nil))))
    (match 0 0)))

(defun normalized-directory-pattern (pattern)
  (let ((value (normalize-path-string pattern)))
    (if (string= value "*.*")
        "*"
        value)))

(defun directory-selector-kind (directories)
  (let ((selector (if (null directories)
                      1
                      (require-int32 directories "VL-DIRECTORY-FILES"))))
    (cond
      ((= selector -1) :directories)
      ((= selector 0) :both)
      ((= selector 1) :files)
      (t
       (signal-builtin-argument-error
        :invalid-directory-selector
        "VL-DIRECTORY-FILES"
        "VL-DIRECTORY-FILES selector must be -1, 0, or 1, got ~S."
        directories)))))

(defun collect-directory-entries (directory selector pattern)
  (let ((results '()))
    (flet ((maybe-add (pathname directoryp)
             (let ((name (pathname-entry-name pathname directoryp)))
               (when (wildcard-match-p pattern name)
                 (push (make-autolisp-string name) results)))))
      (when (member selector '(:files :both))
        (dolist (pathname (uiop:directory-files directory))
          (maybe-add pathname nil)))
      (when (member selector '(:directories :both))
        (dolist (pathname (uiop:subdirectories directory))
          (maybe-add pathname t))))
    (nreverse results)))

(defun split-filename-components (filename)
  (let* ((normalized (normalize-path-string filename))
         (last-separator (position #\/ normalized :from-end t))
         (directory (if last-separator
                        (subseq normalized 0 last-separator)
                        ""))
         (leaf (if last-separator
                   (subseq normalized (1+ last-separator))
                   normalized))
         (dot-position (position #\. leaf :from-end t)))
    (values directory
            leaf
            (and dot-position (> dot-position 0) dot-position))))

(defun open-direction-and-options (mode)
  (cond
    ((string= mode "r")
     (values :input nil nil))
    ((string= mode "w")
     (values :output :supersede :create))
    ((string= mode "a")
     (values :output :append :create))
    (t
     (signal-builtin-argument-error
      :invalid-open-mode
      "OPEN"
      "OPEN mode must be one of \"r\", \"w\", or \"a\", got ~S."
      mode))))

(defun normalize-encoding-name (name)
  "Map an AutoLISP / Autodesk / BricsCAD encoding name (case-folded
ASCII, with optional dashes / underscores) to a SBCL- and CCL-
compatible :external-format keyword."
  (let ((canonical (with-output-to-string (out)
                     (loop for c across name
                           unless (or (char= c #\-) (char= c #\_) (char= c #\Space))
                             do (write-char (char-upcase c) out)))))
    (cond
      ;; Autodesk's documented short names.
      ((string= canonical "UTF8")     :utf-8)
      ((string= canonical "UTF8BOM")  :utf-8)
      ((string= canonical "UTF16")    :utf-16)
      ((string= canonical "UTF16LE")  :utf-16le)
      ((string= canonical "UTF16BE")  :utf-16be)
      ((string= canonical "UTF32")    :utf-32)
      ;; The "ANSI" short name historically meant the legacy host
      ;; code page. Map it to ISO-8859-1 — a strict 1-1 byte coding
      ;; that never fails on Western text. Hosts that need
      ;; Windows-1252 specifically can pass "cp1252" / "WINDOWS-1252"
      ;; explicitly.
      ((string= canonical "ANSI")     :iso-8859-1)
      ((string= canonical "ASCII")    :ascii)
      ((string= canonical "LATIN1")   :iso-8859-1)
      ((or (string= canonical "ISO88591")
           (string= canonical "8859.1"))
       :iso-8859-1)
      ((string= canonical "WINDOWS1252") :cp1252)
      ((string= canonical "CP1252")   :cp1252)
      ;; Anything else: keywordise. SBCL / CCL accept many aliases.
      (t (intern canonical "KEYWORD")))))

(defun parse-open-external-format (string)
  "Decode the third argument of (open path mode ENCODING). Accepted
forms (autolisp-spec ch. 16, \"OPEN External-Format Argument\"):

  - empty / nil      -> dialect default (resolved by the caller).
  - keyword literal  -> e.g. \":utf-8\" / \":iso-8859-1\".
  - sexp literal     -> a Common-Lisp external-format designator,
                         e.g. \"(:utf-8 :replacement #\\?)\".
  - Autodesk short   -> \"utf8\", \"utf8-bom\", \"ANSI\", \"ASCII\".
  - BricsCAD CCS form -> \"r,ccs=UTF-8\", \"w,ccs=ISO-8859-1\". The
                         leading mode-letter is stripped by the
                         caller; this parser only sees the trailing
                         encoding fragment, so a leading
                         \"ccs=NAME\" (with or without the comma)
                         is also accepted directly.
"
  (cond
    ((or (null string) (zerop (length string)))
     (signal-builtin-argument-error
      :invalid-external-format
      "OPEN"
      "Invalid empty external format."))
    ((or (char= (char string 0) #\:)
         (char= (char string 0) #\())
     (handler-case
         (let ((value (read-from-string string)))
           (unless (typep value '(or keyword cons))
             (signal-builtin-argument-error
              :invalid-external-format
              "OPEN"
              "Invalid external format ~S."
              string))
           value)
       (error ()
         (signal-builtin-argument-error
          :invalid-external-format
          "OPEN"
          "Invalid external format ~S."
          string))))
    ;; BricsCAD-style "MODE,ccs=NAME" or bare "ccs=NAME".
    ((let ((eq (position #\= string)))
       (and eq
            (let ((tag (subseq string 0 eq)))
              (or (string-equal tag "ccs")
                  (and (>= (length tag) 4)
                       (string-equal (subseq tag (- (length tag) 4)) ",ccs"))))))
     (let* ((eq (position #\= string))
            (name (subseq string (1+ eq))))
       (normalize-encoding-name name)))
    (t
     (normalize-encoding-name string))))

(defun builtin-numberp (object)
  (if (numberp object)
      (intern-autolisp-symbol "T")
      nil))

(defun arithmetic-result (value)
  (cond
    ((typep value '(signed-byte 32))
     value)
    ((integerp value)
     (signal-builtin-argument-error
      :integer-overflow
      "ARITHMETIC"
      "Arithmetic result is outside the AutoLISP 32-bit integer range: ~S."
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
  ;; AutoLISP `/` follows the per-spec rule (autolisp-spec, chapter 3,
  ;; "Number Tower and Division"): every-argument-integer divisions
  ;; truncate toward zero (BricsCAD V26 probe: (/ 7 2) = 3); any real
  ;; argument promotes the entire chain to real division.
  (require-number first-number "/")
  (dolist (argument more-numbers)
    (require-number argument "/"))
  (let ((all-integer (and (integerp first-number)
                          (every #'integerp more-numbers))))
    (handler-case
        (cond
          ((null more-numbers)
           ;; Unary `/` is rare in AutoLISP corpora; preserve the
           ;; legacy CL-style reciprocal but coerce through
           ;; arithmetic-result so a real input yields a real result.
           (arithmetic-result (/ 1 first-number)))
          (all-integer
           (arithmetic-result
            (reduce (lambda (a b) (truncate a b))
                    more-numbers :initial-value first-number)))
          (t
           (arithmetic-result (apply #'/ first-number more-numbers))))
      (division-by-zero ()
       (signal-builtin-host-error
        :division-by-zero
        "/"
        "Division by zero in /.")))))

(defun builtin-1+ (object)
  (arithmetic-result (1+ (require-number object "1+"))))

(defun builtin-1- (object)
  (arithmetic-result (1- (require-number object "1-"))))

(defun builtin-max (first-number &rest more-numbers)
  (require-number first-number "MAX")
  (dolist (argument more-numbers)
    (require-number argument "MAX"))
  (arithmetic-result (apply #'max first-number more-numbers)))

(defun builtin-min (first-number &rest more-numbers)
  (require-number first-number "MIN")
  (dolist (argument more-numbers)
    (require-number argument "MIN"))
  (arithmetic-result (apply #'min first-number more-numbers)))

(defun require-int32 (object operator-name)
  (unless (typep object '(signed-byte 32))
    (signal-builtin-argument-error
     :invalid-integer-argument
     operator-name
     "~A expects a 32-bit AutoLISP integer, got ~S."
     operator-name
     object))
  object)

(defun builtin-rem (first-number second-number)
  (handler-case
      (arithmetic-result
       (rem (require-int32 first-number "REM")
            (require-int32 second-number "REM")))
    (division-by-zero ()
      (signal-builtin-host-error
       :division-by-zero
       "REM"
       "Division by zero in REM."))))

(defun builtin-gcd (&rest arguments)
  (dolist (argument arguments)
    (require-int32 argument "GCD"))
  (arithmetic-result
   (if arguments
       (apply #'gcd arguments)
       0)))

(defun builtin-lcm (&rest arguments)
  (dolist (argument arguments)
    (require-int32 argument "LCM"))
  (arithmetic-result
   (if arguments
       (apply #'lcm arguments)
       1)))

(defun builtin-~ (object)
  (arithmetic-result (lognot (require-int32 object "~"))))

(defun builtin-logand (first-integer &rest more-integers)
  (require-int32 first-integer "LOGAND")
  (dolist (argument more-integers)
    (require-int32 argument "LOGAND"))
  (arithmetic-result (apply #'logand first-integer more-integers)))

(defun builtin-logior (first-integer &rest more-integers)
  (require-int32 first-integer "LOGIOR")
  (dolist (argument more-integers)
    (require-int32 argument "LOGIOR"))
  (arithmetic-result (apply #'logior first-integer more-integers)))

(defun builtin-lsh (integer count)
  (arithmetic-result
   (ash (require-int32 integer "LSH")
        (require-int32 count "LSH"))))

(defun builtin-strcat (&rest strings)
  (make-autolisp-string
   (apply #'concatenate 'string
          (mapcar (lambda (string)
                    (autolisp-string-value
                     (require-string string "STRCAT")))
                  strings))))

(defun builtin-strlen (&rest strings)
  (let ((total 0))
    (dolist (string strings total)
      (incf total
            (length (autolisp-string-value
                     (require-string string "STRLEN")))))))

(defun builtin-substr (string start &optional length)
  (let* ((value (autolisp-string-value (require-string string "SUBSTR")))
         (start-value (require-int32 start "SUBSTR")))
    (when (<= start-value 0)
      (signal-builtin-argument-error
       :invalid-substr-start
       "SUBSTR"
       "SUBSTR expects a positive 1-based start index, got ~S."
       start))
    (when (and length (<= (require-int32 length "SUBSTR") 0))
      (signal-builtin-argument-error
       :invalid-substr-length
       "SUBSTR"
       "SUBSTR length must be positive, got ~S."
       length))
    (let ((start-index (1- start-value)))
      (if (>= start-index (length value))
          (make-autolisp-string "")
          (let ((end-index (if length
                               (min (length value)
                                    (+ start-index length))
                               (length value))))
            (make-autolisp-string (subseq value start-index end-index)))))))

(defun builtin-strcase (string &optional lowercase-p)
  ;; (strcase STR [downcase-flag])
  ;; Default upcases; non-nil flag downcases.
  (let ((value (autolisp-string-value (require-string string "STRCASE"))))
    (make-autolisp-string
     (if lowercase-p
         (string-downcase value)
         (string-upcase value)))))

(defun string-trim-set (string-arg operator-name)
  ;; AutoLISP's vl-string-trim et al. take a string of characters,
  ;; each of which is trimmed. Coerce the AutoLISP string into a
  ;; CL list of host characters.
  (let ((value (autolisp-string-value (require-string string-arg operator-name))))
    (coerce value 'list)))

(defun builtin-vl-string-trim (chars-string source-string)
  (let ((chars (string-trim-set chars-string "VL-STRING-TRIM"))
        (value (autolisp-string-value
                (require-string source-string "VL-STRING-TRIM"))))
    (make-autolisp-string (string-trim chars value))))

(defun builtin-vl-string-left-trim (chars-string source-string)
  (let ((chars (string-trim-set chars-string "VL-STRING-LEFT-TRIM"))
        (value (autolisp-string-value
                (require-string source-string "VL-STRING-LEFT-TRIM"))))
    (make-autolisp-string (string-left-trim chars value))))

(defun builtin-vl-string-right-trim (chars-string source-string)
  (let ((chars (string-trim-set chars-string "VL-STRING-RIGHT-TRIM"))
        (value (autolisp-string-value
                (require-string source-string "VL-STRING-RIGHT-TRIM"))))
    (make-autolisp-string (string-right-trim chars value))))

(defun builtin-vl-string-search (pattern source &optional start)
  ;; (vl-string-search PATTERN STRING [START])
  ;; Returns the 0-based index of the first occurrence of PATTERN in
  ;; STRING at or after START (default 0), or nil if not found.
  (let ((p (autolisp-string-value (require-string pattern "VL-STRING-SEARCH")))
        (s (autolisp-string-value (require-string source "VL-STRING-SEARCH")))
        (s0 (if start (require-int32 start "VL-STRING-SEARCH") 0)))
    (when (minusp s0)
      (signal-builtin-argument-error
       :invalid-string-position
       "VL-STRING-SEARCH"
       "VL-STRING-SEARCH start must be non-negative, got ~S."
       start))
    (search p s :start2 (min s0 (length s)))))

(defun builtin-vl-string-position (char-code source &optional start from-right)
  ;; (vl-string-position CODE STRING [START [FROM-END]])
  ;; CODE is an integer character code; returns the 0-based position
  ;; of the first matching character, or nil.
  (let* ((code (require-int32 char-code "VL-STRING-POSITION"))
         (target (code-char code))
         (s (autolisp-string-value (require-string source "VL-STRING-POSITION"))))
    (unless target
      (signal-builtin-argument-error
       :invalid-character-code
       "VL-STRING-POSITION"
       "VL-STRING-POSITION code does not designate a character: ~S."
       char-code))
    (let ((s0 (if start (require-int32 start "VL-STRING-POSITION") 0)))
      (when (minusp s0)
        (signal-builtin-argument-error
         :invalid-string-position
         "VL-STRING-POSITION"
         "VL-STRING-POSITION start must be non-negative, got ~S."
         start))
      (if from-right
          (position target s :from-end t :start (min s0 (length s)))
          (position target s :start (min s0 (length s)))))))

(defun builtin-vl-string-translate (from-string to-string source)
  ;; (vl-string-translate FROM TO STRING)
  ;; Replace each character of STRING that occurs in FROM with the
  ;; character at the same position in TO. If TO is shorter than
  ;; FROM, the extra FROM characters are deleted.
  (let ((from (autolisp-string-value (require-string from-string "VL-STRING-TRANSLATE")))
        (to (autolisp-string-value (require-string to-string "VL-STRING-TRANSLATE")))
        (s (autolisp-string-value (require-string source "VL-STRING-TRANSLATE"))))
    (make-autolisp-string
     (with-output-to-string (out)
       (loop for c across s
             for at = (position c from)
             do (cond
                  ((null at) (write-char c out))
                  ((< at (length to)) (write-char (char to at) out))
                  ;; FROM character with no counterpart in TO is dropped.
                  (t nil)))))))

(defun builtin-vl-string-subst (new-string old-string source &optional start)
  ;; (vl-string-subst NEW OLD STRING [START])
  ;; Replace the FIRST occurrence of OLD with NEW. If OLD does not
  ;; occur, return STRING unchanged.
  (let ((new (autolisp-string-value (require-string new-string "VL-STRING-SUBST")))
        (old (autolisp-string-value (require-string old-string "VL-STRING-SUBST")))
        (s (autolisp-string-value (require-string source "VL-STRING-SUBST"))))
    (let* ((s0 (if start (require-int32 start "VL-STRING-SUBST") 0))
           (clamped-start (max 0 (min s0 (length s))))
           (hit (search old s :start2 clamped-start)))
      (if hit
          (make-autolisp-string
           (concatenate 'string
                        (subseq s 0 hit)
                        new
                        (subseq s (+ hit (length old)))))
          (make-autolisp-string s)))))

(defun builtin-vl-string-mismatch (a b)
  ;; (vl-string-mismatch S1 S2) -> integer count of leading matching characters.
  (let ((sa (autolisp-string-value (require-string a "VL-STRING-MISMATCH")))
        (sb (autolisp-string-value (require-string b "VL-STRING-MISMATCH"))))
    (loop for i below (min (length sa) (length sb))
          while (char= (char sa i) (char sb i))
          count 1)))

(defun builtin-vl-string-elt (string index)
  ;; (vl-string-elt STR I) -> character code at 0-based index.
  (let ((s (autolisp-string-value (require-string string "VL-STRING-ELT")))
        (i (require-int32 index "VL-STRING-ELT")))
    (when (or (minusp i) (>= i (length s)))
      (signal-builtin-argument-error
       :invalid-string-index
       "VL-STRING-ELT"
       "VL-STRING-ELT index ~S is out of range for a string of length ~A."
       index (length s)))
    (char-code (char s i))))

(defun builtin-vl-string->list (string)
  (let ((s (autolisp-string-value (require-string string "VL-STRING->LIST"))))
    (loop for c across s collect (char-code c))))

(defun builtin-vl-list->string (codes)
  ;; (vl-list->string LIST-OF-INTS) -> string built from those codes.
  (unless (listp codes)
    (signal-builtin-argument-error
     :invalid-list-argument
     "VL-LIST->STRING"
     "VL-LIST->STRING expects a list of integers, got ~S."
     codes))
  (make-autolisp-string
   (with-output-to-string (out)
     (dolist (code codes)
       (let ((int (require-int32 code "VL-LIST->STRING")))
         (unless (and (<= 0 int) (code-char int))
           (signal-builtin-argument-error
            :invalid-character-code
            "VL-LIST->STRING"
            "VL-LIST->STRING element ~S is not a valid character code."
            code))
         (write-char (code-char int) out))))))

(defun builtin-ascii (string)
  (let ((value (autolisp-string-value (require-string string "ASCII"))))
    (when (zerop (length value))
      (signal-builtin-argument-error
       :invalid-empty-string
       "ASCII"
       "ASCII expects a non-empty string."))
    (char-code (char value 0))))

(defun int32->character (code operator-name)
  (let ((int32 (require-int32 code operator-name)))
    (when (minusp int32)
      (signal-builtin-argument-error
       :invalid-character-code
       operator-name
       "~A code does not designate a valid character: ~S."
       operator-name
       code))
    (let ((character (code-char int32)))
      (unless character
        (signal-builtin-argument-error
         :invalid-character-code
         operator-name
         "~A code does not designate a valid character: ~S."
         operator-name
         code))
      character)))

(defun builtin-chr (code)
  (make-autolisp-string
   (string (int32->character code "CHR"))))

(defun open-default-external-format ()
  "Resolve the active dialect's default file encoding for `open`,
falling back to :iso-8859-1 (the historic ANSI/MBCS legacy default)
when no dialect is in scope."
  (let ((dialect (ignore-errors (current-evaluation-dialect))))
    (or (and dialect
             (clautolisp.autolisp-reader:autolisp-dialect-default-file-encoding
              dialect))
        :iso-8859-1)))

(defun builtin-open (filename mode &optional encoding)
  (let* ((path-string (autolisp-string-value (require-string filename "OPEN")))
         (mode-string (autolisp-string-value (require-string mode "OPEN")))
         (path (resolve-open-pathname path-string))
         (external-format (cond
                            ((null encoding) (open-default-external-format))
                            (t (parse-open-external-format
                                (autolisp-string-value
                                 (require-string encoding "OPEN")))))))
    (multiple-value-bind (direction if-exists if-does-not-exist)
        (open-direction-and-options mode-string)
      (handler-case
          (let ((stream (open path
                              :direction direction
                              :if-exists if-exists
                              :if-does-not-exist if-does-not-exist
                              :external-format external-format)))
            (if stream
                (make-autolisp-file stream path-string mode-string)
                nil))
        (error ()
          nil)))))

(defun resolve-existing-file (filename support-paths)
  ;; AutoLISP's `findfile` and `findtrustedfile` accept both absolute
  ;; and relative paths. Absolute paths are looked up directly via
  ;; probe-file; relative paths walk the configured support / trusted
  ;; path list.
  (let ((normalized (normalize-path-string filename)))
    (cond
      ((directory-prefix-p normalized)
       (let* ((path (if (absolute-path-string-p normalized)
                        (pathname normalized)
                        (merge-pathnames normalized
                                         (pathname (autolisp-current-directory)))))
              (located (probe-file path)))
         (and located (namestring located))))
      (t
       (search-path-list-for-file filename support-paths)))))

(defun builtin-findfile (filename)
  (let* ((value (autolisp-string-value (require-string filename "FINDFILE")))
         (located (resolve-existing-file value (autolisp-support-paths))))
    (if located
        (make-autolisp-string located)
        nil)))

(defun builtin-findtrustedfile (filename)
  (let* ((value (autolisp-string-value (require-string filename "FINDTRUSTEDFILE")))
         (located (resolve-existing-file value (autolisp-trusted-paths))))
    (if located
        (make-autolisp-string located)
        nil)))

(defun builtin-vl-directory-files (&optional directory pattern directories)
  (let* ((directory-value (if directory
                              (autolisp-string-value
                               (require-string directory "VL-DIRECTORY-FILES"))
                              (autolisp-current-directory)))
         (pattern-value (if pattern
                            (autolisp-string-value
                             (require-string pattern "VL-DIRECTORY-FILES"))
                            "*.*"))
         (resolved-directory (resolve-directory-pathname directory-value
                                                        "VL-DIRECTORY-FILES"))
         (selector (directory-selector-kind directories)))
    (handler-case
        (if (uiop:directory-exists-p resolved-directory)
            (let ((results (collect-directory-entries
                            resolved-directory
                            selector
                            (normalized-directory-pattern pattern-value))))
              (if results
                  results
                  nil))
            nil)
      (file-error ()
        nil))))

(defun builtin-vl-file-directory-p (filename)
  (let* ((value (autolisp-string-value
                 (require-string filename "VL-FILE-DIRECTORY-P")))
         (resolved (resolve-open-pathname value)))
    (if (uiop:directory-exists-p resolved)
        (intern-autolisp-symbol "T")
        nil)))

(defun builtin-vl-filename-base (filename)
  (multiple-value-bind (directory leaf dot-position)
      (split-filename-components
       (autolisp-string-value
        (require-string filename "VL-FILENAME-BASE")))
    (declare (ignore directory))
    (make-autolisp-string
     (if dot-position
         (subseq leaf 0 dot-position)
         leaf))))

(defun builtin-vl-filename-directory (filename)
  (multiple-value-bind (directory leaf dot-position)
      (split-filename-components
       (autolisp-string-value
        (require-string filename "VL-FILENAME-DIRECTORY")))
    (declare (ignore leaf dot-position))
    (make-autolisp-string directory)))

(defun builtin-vl-filename-extension (filename)
  (multiple-value-bind (directory leaf dot-position)
      (split-filename-components
       (autolisp-string-value
        (require-string filename "VL-FILENAME-EXTENSION")))
    (declare (ignore directory))
    (if dot-position
        (make-autolisp-string (subseq leaf dot-position))
        nil)))

(defun builtin-vl-file-delete (filename)
  (let* ((value (autolisp-string-value
                 (require-string filename "VL-FILE-DELETE")))
         (resolved (resolve-open-pathname value)))
    (handler-case
        (progn
          (delete-file resolved)
          (intern-autolisp-symbol "T"))
      (file-error ()
        nil))))

(defun builtin-vl-file-rename (old-filename new-filename)
  (let* ((old-value (autolisp-string-value
                     (require-string old-filename "VL-FILE-RENAME")))
         (new-value (autolisp-string-value
                     (require-string new-filename "VL-FILE-RENAME")))
         (old-path (resolve-open-pathname old-value))
         (new-path (resolve-open-pathname new-value)))
    (handler-case
        (if (probe-file new-path)
            nil
            (progn
              (rename-file old-path new-path)
              (intern-autolisp-symbol "T")))
      (file-error ()
        nil))))

(defun builtin-vl-file-size (filename)
  (let* ((value (autolisp-string-value
                 (require-string filename "VL-FILE-SIZE")))
         (resolved (resolve-open-pathname value)))
    (cond
      ((uiop:directory-exists-p resolved)
       0)
      ((not (probe-file resolved))
       nil)
      (t
       (handler-case
           (with-open-file (stream resolved
                                   :direction :input
                                   :element-type '(unsigned-byte 8))
             (file-length stream))
         (file-error ()
           nil))))))

(defun autolisp-day-of-week (common-lisp-day-of-week)
  ;; CL uses Monday=0..Sunday=6. AutoLISP compatibility is modeled here as
  ;; Sunday=0..Saturday=6, matching common host file-time conventions.
  (mod (1+ common-lisp-day-of-week) 7))

(defun builtin-vl-file-systime (filename)
  (let* ((value (autolisp-string-value
                 (require-string filename "VL-FILE-SYSTIME")))
         (resolved (resolve-open-pathname value))
         (write-date (ignore-errors (file-write-date resolved))))
    (if write-date
        (multiple-value-bind (second minute hour day month year day-of-week)
            (decode-universal-time write-date)
          (list year month (autolisp-day-of-week day-of-week) day hour minute second))
        nil)))

(defun copy-stream-contents (input output)
  (let ((buffer (make-array 4096 :element-type '(unsigned-byte 8)))
        (total 0))
    (loop
      for count = (read-sequence buffer input)
      until (zerop count)
      do (write-sequence buffer output :end count)
         (incf total count))
    total))

(defun builtin-vl-file-copy (source-filename destination-filename &optional append)
  (let* ((source-value (autolisp-string-value
                        (require-string source-filename "VL-FILE-COPY")))
         (destination-value (autolisp-string-value
                             (require-string destination-filename "VL-FILE-COPY")))
         (source-path (resolve-open-pathname source-value))
         (destination-path (resolve-open-pathname destination-value)))
    (cond
      ((or (uiop:directory-exists-p source-path)
           (not (probe-file source-path)))
       nil)
      ((uiop:directory-exists-p destination-path)
       nil)
      ((and (null append) (probe-file destination-path))
       nil)
      (t
       (handler-case
           (with-open-file (input source-path
                                  :direction :input
                                  :element-type '(unsigned-byte 8))
             (with-open-file (output destination-path
                                     :direction :output
                                     :element-type '(unsigned-byte 8)
                                     :if-exists (if append :append :error)
                                     :if-does-not-exist :create)
               (copy-stream-contents input output)))
         (file-error ()
           nil))))))

(defun normalize-mktemp-extension (extension)
  (cond
    ((null extension)
     "")
    ((zerop (length extension))
     "")
    ((char= #\. (char extension 0))
     extension)
    (t
     (concatenate 'string "." extension))))

(defun unique-temp-pathname (directory pattern extension)
  (loop
    for attempt from 0
    for suffix = (format nil "~36R-~36R" (get-universal-time) attempt)
    for leaf = (format nil "~A~A~A" pattern suffix extension)
    for candidate = (merge-pathnames leaf directory)
    unless (probe-file candidate)
      do (return candidate)))

(defun default-mktemp-directory ()
  (namestring (uiop:temporary-directory)))

(defun builtin-vl-filename-mktemp (&optional pattern directory extension)
  (let* ((pattern-value (if pattern
                            (autolisp-string-value
                             (require-string pattern "VL-FILENAME-MKTEMP"))
                            "tmp"))
         (directory-value (if directory
                              (autolisp-string-value
                               (require-string directory "VL-FILENAME-MKTEMP"))
                              (default-mktemp-directory)))
         (extension-value (if extension
                              (autolisp-string-value
                               (require-string extension "VL-FILENAME-MKTEMP"))
                              ""))
         (resolved-directory (resolve-directory-pathname directory-value
                                                        "VL-FILENAME-MKTEMP"))
         (candidate (unique-temp-pathname resolved-directory
                                          pattern-value
                                          (normalize-mktemp-extension
                                           extension-value))))
    (make-autolisp-string (namestring candidate))))

(defun builtin-vl-mkdir (directoryname)
  (let* ((value (autolisp-string-value
                 (require-string directoryname "VL-MKDIR")))
         (resolved (resolve-directory-pathname value "VL-MKDIR")))
    (if (uiop:directory-exists-p resolved)
        nil
        (handler-case
            (progn
              (ensure-directories-exist resolved)
              (if (uiop:directory-exists-p resolved)
                  (intern-autolisp-symbol "T")
                  nil))
          (file-error ()
            nil)))))

(defun builtin-close (file)
  (close-autolisp-file (require-file file "CLOSE")))

(defun builtin-read (string)
  (handler-case
      (autolisp-read-from-string
       (autolisp-string-value (require-string string "READ")))
    (autolisp-runtime-error (condition)
      (error 'autolisp-runtime-error
             :code :invalid-read-syntax
             :message (format nil "READ failed to parse input: ~A" condition)
             :details (list :builtin "READ"
                            :condition condition)))
    (error (condition)
      (error 'autolisp-runtime-error
             :code :invalid-read-syntax
             :message (format nil "READ failed to parse input: ~A" condition)
             :details (list :builtin "READ"
                            :condition condition)))))

(defun builtin-read-line (file)
  (let ((stream (require-open-file-stream file "READ-LINE")))
    (let ((line (read-line stream nil nil)))
      (if line
          (make-autolisp-string line)
          nil))))

(defun builtin-read-char (&optional file)
  (if file
      (let ((stream (require-open-file-stream file "READ-CHAR")))
        (let ((character (read-char stream nil nil)))
          (if character
              (char-code character)
              nil)))
      (let ((character (read-char *standard-input* nil nil)))
        (if character
            (char-code character)
            nil))))

(defun builtin-write-line (string &optional file)
  (let ((value (autolisp-string-value (require-string string "WRITE-LINE"))))
    (if file
        (let ((stream (require-open-file-stream file "WRITE-LINE")))
          (write-line value stream)
          string)
        (progn
          (write-line value *standard-output*)
          string))))

(defun builtin-write-char (char-code &optional file)
  (let ((character (int32->character char-code "WRITE-CHAR")))
    (if file
        (let ((stream (require-open-file-stream file "WRITE-CHAR")))
          (write-char character stream)
          char-code)
        (progn
          (write-char character *standard-output*)
          char-code))))

;; --- atoi / atof (Phase-5 product-tested model) ----------------------
;;
;; Lex model derived from the BricsCAD V26 product test on 2026-04-26
;; (results captured in autolisp-spec/results/bricscad/macos/
;; 20260426T122808Z/results.sexp):
;;
;; * skip leading whitespace
;; * accept optional `+` or `-`
;; * parse the longest run of decimal digits (atoi) or
;;   `digits ('.' digits?)? (('e'|'E') [+-]? digits)?` (atof)
;; * a trailing non-numeric tail terminates parsing; the value of the
;;   prefix (or 0 / 0.0 if no digits matched) is returned.
;;
;; For atof we deliberately *omit* the C99 hex-float syntax accepted
;; by BricsCAD V26 (e.g. `(atof "0x1p4") -> 16.0`). This is the
;; conservative `clautolisp` choice spelled out in the autolisp-spec
;; entry for ATOF: portable AutoLISP code should not rely on hex-float
;; input. Locale sensitivity is also intentionally absent: the decimal
;; separator is `.` only.

(defun atoi-skip-whitespace (string start)
  (loop while (and (< start (length string))
                   (member (char string start)
                           '(#\Space #\Tab #\Newline #\Return #\Page)
                           :test #'char=))
        do (incf start))
  start)

(defun atoi-scan-sign (string start)
  (cond
    ((>= start (length string)) (values 1 start))
    ((char= (char string start) #\+) (values 1 (1+ start)))
    ((char= (char string start) #\-) (values -1 (1+ start)))
    (t (values 1 start))))

(defun atoi-scan-digits (string start)
  "Returns (values numeric-value end-index) or (values nil start) on no digits."
  (let ((value 0)
        (i start))
    (loop while (and (< i (length string))
                     (digit-char-p (char string i)))
          do (setf value (+ (* value 10) (digit-char-p (char string i))))
             (incf i))
    (if (= i start) (values nil start) (values value i))))

(defun parse-autolisp-integer (string)
  "Parse STRING per the AutoLISP `atoi` lex model. Returns an int32."
  (let* ((start (atoi-skip-whitespace string 0)))
    (multiple-value-bind (sign signed-start) (atoi-scan-sign string start)
      (multiple-value-bind (value end) (atoi-scan-digits string signed-start)
        (declare (ignore end))
        (if (null value)
            0
            (* sign value))))))

(defun parse-autolisp-real (string)
  "Parse STRING per the AutoLISP `atof` lex model. Returns a double-float."
  (let* ((start (atoi-skip-whitespace string 0)))
    (multiple-value-bind (sign signed-start) (atoi-scan-sign string start)
      (multiple-value-bind (int-value int-end)
          (atoi-scan-digits string signed-start)
        ;; Optional fractional part: `.` followed by zero-or-more digits.
        (let* ((have-int int-value)
               (cursor (or int-end signed-start))
               (frac-numerator 0)
               (frac-denom 1)
               (have-frac nil))
          (when (and (< cursor (length string))
                     (char= (char string cursor) #\.))
            (incf cursor)
            (multiple-value-bind (fv fe) (atoi-scan-digits string cursor)
              (when fv
                (setf frac-numerator fv
                      frac-denom (expt 10 (- fe cursor))
                      have-frac t
                      cursor fe))))
          ;; Optional exponent: (e|E) optional sign, digits.
          (let ((exponent 0))
            (when (and (< cursor (length string))
                       (or (char= (char string cursor) #\e)
                           (char= (char string cursor) #\E)))
              (let ((ec (1+ cursor)))
                (multiple-value-bind (esign esigned-start)
                    (atoi-scan-sign string ec)
                  (multiple-value-bind (ev ee)
                      (atoi-scan-digits string esigned-start)
                    (when ev
                      (setf exponent (* esign ev)
                            cursor ee))))))
            (let* ((int-part (or have-int 0)))
              (cond
                ((and (null have-int) (null have-frac))
                 0.0d0)
                (t
                 (let* ((mantissa
                          (+ (coerce int-part 'double-float)
                             (/ (coerce frac-numerator 'double-float)
                                (coerce frac-denom 'double-float))))
                        (signed-mantissa (* sign mantissa))
                        (scaled (if (zerop exponent)
                                    signed-mantissa
                                    (* signed-mantissa
                                       (expt 10.0d0 exponent)))))
                   scaled))))))))))

(defun builtin-atoi (string)
  (parse-autolisp-integer (autolisp-string-value (require-string string "ATOI"))))

(defun builtin-atof (string)
  (parse-autolisp-real (autolisp-string-value (require-string string "ATOF"))))
;; --- end atoi / atof -------------------------------------------------

(defun escape-prin1-string (string)
  (with-output-to-string (out)
    (write-char #\" out)
    (loop for character across string
          do (case character
               (#\\
                (write-string "\\\\" out))
               (#\"
                (write-string "\\\"" out))
               (t
                (write-char character out))))
    (write-char #\" out)))

(defun autolisp-value->string (object princp)
  (cond
    ((null object)
     "nil")
    ((integerp object)
     (format nil "~D" object))
    ((floatp object)
     (princ-to-string object))
    ((typep object 'autolisp-string)
     (if princp
         (autolisp-string-value object)
         (escape-prin1-string (autolisp-string-value object))))
    ((typep object 'autolisp-symbol)
     (autolisp-symbol-name object))
    ((typep object 'autolisp-subr)
     (format nil "#<SUBR ~A>" (autolisp-subr-name object)))
    ((typep object 'autolisp-usubr)
     (format nil "#<USUBR ~A>" (autolisp-usubr-name object)))
    ((typep object 'autolisp-ename)
     (format nil "<Entity name: ~A>" (autolisp-ename-value object)))
    ((typep object 'autolisp-vla-object)
     (format nil "#<VLA-OBJECT ~A>" (autolisp-vla-object-value object)))
    ((typep object 'autolisp-safearray)
     (let ((data (autolisp-safearray-value object)))
       (if (typep data 'safearray-data)
           (format nil "#<SAFEARRAY ~S ~S>"
                   (safearray-data-type-tag data)
                   (safearray-data-bounds data))
           (format nil "#<SAFEARRAY>"))))
    ((typep object 'autolisp-variant)
     (let ((pair (autolisp-variant-value object)))
       (if (consp pair)
           (format nil "#<VARIANT ~S ~S>" (car pair) (cdr pair))
           (format nil "#<VARIANT>"))))
    ((consp object)
     (with-output-to-string (out)
       (labels ((emit-tail (tail)
                  (cond
                    ((null tail)
                     nil)
                    ((consp tail)
                     (write-char #\Space out)
                     (write-string (autolisp-value->string (car tail) princp) out)
                     (emit-tail (cdr tail)))
                    (t
                     (write-string " . " out)
                     (write-string (autolisp-value->string tail princp) out)))))
         (write-char #\( out)
         (write-string (autolisp-value->string (car object) princp) out)
         (emit-tail (cdr object))
         (write-char #\) out))))
    (t
     (with-output-to-string (out)
       (write object :stream out :escape (not princp))))))

(defun output-stream-for-file (file operator-name)
  (if file
      (require-open-file-stream file operator-name)
      *standard-output*))

(defun builtin-vl-prin1-to-string (object)
  (make-autolisp-string (autolisp-value->string object nil)))

(defun builtin-vl-princ-to-string (object)
  (make-autolisp-string (autolisp-value->string object t)))

(defun builtin-prin1 (object &optional file)
  (write-string (autolisp-value->string object nil)
                (output-stream-for-file file "PRIN1"))
  object)

(defun builtin-princ (&optional object file)
  (when object
    (write-string (autolisp-value->string object t)
                  (output-stream-for-file file "PRINC")))
  object)

(defun builtin-print (object &optional file)
  ;; AutoLISP `print` is `prin1` with a leading newline AND a trailing
  ;; SPACE (not a trailing newline) — confirmed by the Phase-5 BricsCAD
  ;; V26 product test on 2026-04-26 (autolisp-spec/results/bricscad/
  ;; macos/20260426T122808Z/print-string.txt contains the literal nine
  ;; characters `\n"hello" `). Bricsys's per-symbol page documents the
  ;; framing as "adds a newline \n before expression and adds an extra
  ;; space afterwards".
  (let ((stream (output-stream-for-file file "PRINT")))
    (terpri stream)
    (write-string (autolisp-value->string object nil) stream)
    (write-char #\Space stream))
  object)

(defun builtin-terpri ()
  ;; AutoLISP `terpri` is *zero-arity*: it does not accept a file
  ;; handle. The 2-argument form raises "too few / too many arguments
  ;; at [TERPRI]" in BricsCAD V26 — confirmed in the Phase-5 product
  ;; test on 2026-04-26. Portable file-handle newline output uses
  ;; `(princ "\n" stream)` instead. Bricsys recommends `(princ)` over
  ;; `(terpri)` to terminate a defun without a trailing blank line.
  (terpri *standard-output*)
  nil)

(defun builtin-prompt (string)
  (let ((value (autolisp-string-value (require-string string "PROMPT"))))
    (write-string value *standard-output*)
    nil))

(defun comparison-value (object operator-name)
  (cond
    ((numberp object)
     object)
    ((typep object 'autolisp-string)
     (autolisp-string-value object))
    (t
     (signal-builtin-argument-error
      :invalid-comparison-argument
      operator-name
      "~A expects numbers or strings, got ~S."
      operator-name
      object))))

(defun comparison-equal-p (a b)
  ;; AutoLISP `=` accepts arguments of any type, not just the
  ;; numeric/string pair documented in early references — production
  ;; code routinely uses it to compare symbols and lists. Numeric
  ;; pairs compare across int/real (autolisp-spec ch. 5, "Equality
  ;; Predicates"); strings compare by content; everything else falls
  ;; back to host-level identity (eql), which matches `eq` semantics
  ;; for symbols and other interned objects.
  (cond
    ((eql a b) t)
    ((and (numberp a) (numberp b)) (= a b))
    ((and (typep a 'autolisp-string) (typep b 'autolisp-string))
     (string= (autolisp-string-value a) (autolisp-string-value b)))
    (t nil)))

(defun builtin-= (&rest arguments)
  (unless arguments
    (signal-builtin-argument-error
     :wrong-number-of-arguments
     "="
     "= expects at least one argument."))
  (let ((first-arg (first arguments)))
    (if (every (lambda (argument)
                 (comparison-equal-p first-arg argument))
               (rest arguments))
        (intern-autolisp-symbol "T")
        nil)))

(defun builtin-/= (&rest arguments)
  (unless arguments
    (signal-builtin-argument-error
     :wrong-number-of-arguments
     "/="
     "/= expects at least one argument."))
  ;; `/=` is true when no two arguments compare equal — pairwise.
  (loop for tail on arguments
        do (loop for other in (rest tail)
                 when (comparison-equal-p (first tail) other)
                   do (return-from builtin-/= nil))
        finally (return (intern-autolisp-symbol "T"))))

(defun require-number (object operator-name)
  (unless (numberp object)
    (signal-builtin-argument-error
     :invalid-number-argument
     operator-name
     "~A expects a number, got ~S."
     operator-name
     object))
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
      (signal-builtin-argument-error
       :integer-overflow
       "FIX"
       "FIX result is outside the AutoLISP 32-bit integer range: ~S."
       value))
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

;;; --- Phase 7: function-coverage round-out ---------------------------
;;;
;;; Pure-language builtins that don't touch the host. Each entry
;;; references the autolisp-spec chapter that defines it.

;;; ERROR — signal a runtime error from user code.
(defun builtin-error (message-or-string &rest details)
  ;; (error MESSAGE)        — common signature, signals a runtime error.
  ;; (error CODE FORMAT...) — Visual LISP variant; we accept it but
  ;; coerce non-symbol first arg into the message.
  (let ((message
         (cond
           ((typep message-or-string 'autolisp-string)
            (autolisp-string-value message-or-string))
           ((stringp message-or-string)
            message-or-string)
           ((typep message-or-string 'autolisp-symbol)
            (autolisp-symbol-name message-or-string))
           (t
            (format nil "~A" message-or-string)))))
    (declare (ignore details))
    (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
     :user-error
     "~A"
     message)))

;;; --- Math (autolisp-spec ch.5) -------------------------------------

(defun builtin-sqrt (object)
  (let ((value (coerce (require-number object "SQRT") 'double-float)))
    (when (minusp value)
      (signal-builtin-argument-error
       :invalid-number-argument
       "SQRT"
       "SQRT expects a non-negative number, got ~S."
       object))
    (sqrt value)))

(defun builtin-exp (object)
  (exp (coerce (require-number object "EXP") 'double-float)))

(defun builtin-log (object)
  (let ((value (coerce (require-number object "LOG") 'double-float)))
    (when (not (plusp value))
      (signal-builtin-argument-error
       :invalid-number-argument
       "LOG"
       "LOG expects a positive number, got ~S."
       object))
    (log value)))

(defun builtin-log10 (object)
  (let ((value (coerce (require-number object "LOG10") 'double-float)))
    (when (not (plusp value))
      (signal-builtin-argument-error
       :invalid-number-argument
       "LOG10"
       "LOG10 expects a positive number, got ~S."
       object))
    (log value 10.0d0)))

(defun builtin-sin (object)
  (sin (coerce (require-number object "SIN") 'double-float)))

(defun builtin-cos (object)
  (cos (coerce (require-number object "COS") 'double-float)))

(defun builtin-tan (object)
  (tan (coerce (require-number object "TAN") 'double-float)))

(defun builtin-asin (object)
  (let ((value (coerce (require-number object "ASIN") 'double-float)))
    (when (or (< value -1.0d0) (> value 1.0d0))
      (signal-builtin-argument-error
       :invalid-number-argument
       "ASIN"
       "ASIN expects a value in [-1, 1], got ~S."
       object))
    (asin value)))

(defun builtin-acos (object)
  (let ((value (coerce (require-number object "ACOS") 'double-float)))
    (when (or (< value -1.0d0) (> value 1.0d0))
      (signal-builtin-argument-error
       :invalid-number-argument
       "ACOS"
       "ACOS expects a value in [-1, 1], got ~S."
       object))
    (acos value)))

(defun builtin-atan (y &optional x)
  ;; (atan y) -> arctangent in [-pi/2, pi/2].
  ;; (atan y x) -> arctangent of y/x using the signs of both
  ;; arguments to determine the quadrant. Real-valued double-float.
  (let ((y-value (coerce (require-number y "ATAN") 'double-float)))
    (if x
        (atan y-value (coerce (require-number x "ATAN") 'double-float))
        (atan y-value))))

(defun builtin-expt (base power)
  ;; (expt base power) — real if either arg is real OR the result
  ;; would not be a 32-bit integer. Mirrors AutoLISP's int-vs-real
  ;; promotion contract.
  (require-number base "EXPT")
  (require-number power "EXPT")
  (let ((result (handler-case (expt base power)
                  (arithmetic-error ()
                   (signal-builtin-argument-error
                    :invalid-number-argument
                    "EXPT"
                    "EXPT result is undefined for ~S^~S."
                    base power)))))
    (arithmetic-result
     (if (and (integerp base) (integerp power)
              (not (minusp power))
              (integerp result))
         result
         (coerce result 'double-float)))))

(defun builtin-mod (a b)
  ;; (mod a b) — modulo. Integers stay integer; mixed-type and real
  ;; promote to real. Division by zero -> error.
  (require-number a "MOD")
  (require-number b "MOD")
  (when (zerop b)
    (signal-builtin-argument-error
     :division-by-zero
     "MOD"
     "MOD divisor is zero."))
  (cond
    ((and (integerp a) (integerp b))
     (mod a b))
    (t
     (let ((af (coerce a 'double-float))
           (bf (coerce b 'double-float)))
       (- af (* bf (floor af bf)))))))

(defun builtin-floor (object &optional divisor)
  ;; (floor n) or (floor a b) -> integer floor toward -infinity.
  (require-number object "FLOOR")
  (when divisor (require-number divisor "FLOOR"))
  (let ((value (if divisor
                   (progn
                     (when (zerop divisor)
                       (signal-builtin-argument-error
                        :division-by-zero "FLOOR" "FLOOR divisor is zero."))
                     (/ object divisor))
                   object)))
    (arithmetic-result (floor value))))

(defun builtin-ceiling (object &optional divisor)
  (require-number object "CEILING")
  (when divisor (require-number divisor "CEILING"))
  (let ((value (if divisor
                   (progn
                     (when (zerop divisor)
                       (signal-builtin-argument-error
                        :division-by-zero "CEILING" "CEILING divisor is zero."))
                     (/ object divisor))
                   object)))
    (arithmetic-result (ceiling value))))

(defun builtin-round (object &optional divisor)
  ;; AutoLISP `round` rounds to nearest, half-away-from-zero on most
  ;; hosts. CL's `round` is half-to-even; we emulate the AutoLISP
  ;; convention to match deployed behaviour.
  (require-number object "ROUND")
  (when divisor (require-number divisor "ROUND"))
  (let* ((value (if divisor
                    (progn
                      (when (zerop divisor)
                        (signal-builtin-argument-error
                         :division-by-zero "ROUND" "ROUND divisor is zero."))
                      (/ object divisor))
                    object))
         (sign (if (minusp value) -1 1))
         (mag (abs value))
         (truncated (truncate (+ mag 0.5d0))))
    (arithmetic-result (* sign truncated))))

(defparameter *autolisp-random-state* (make-random-state t))

(defun builtin-random (n)
  ;; (random N) -> integer in [0, N) for positive integer N. Real
  ;; arguments are not common in AutoLISP corpora; we restrict to
  ;; integer for predictability.
  (let ((bound (require-int32 n "RANDOM")))
    (unless (plusp bound)
      (signal-builtin-argument-error
       :invalid-number-argument
       "RANDOM"
       "RANDOM expects a positive integer, got ~S."
       n))
    (random bound *autolisp-random-state*)))

;;; --- Bitwise ---------------------------------------------------------

(defun builtin-logxor (&rest arguments)
  (dolist (argument arguments)
    (require-int32 argument "LOGXOR"))
  (arithmetic-result (apply #'logxor 0 arguments)))

(defun builtin-boole (op &rest arguments)
  ;; (boole OP I1 I2 ...) — generic bitwise reducer; OP is an
  ;; integer 0..15 selecting one of the 16 binary boolean functions
  ;; per the documented truth-table layout (AND=1, IOR=7, XOR=6,
  ;; etc.). Most user code uses LOGAND / LOGIOR / LOGXOR directly;
  ;; we map the common selectors and signal :unsupported-boole-op
  ;; for the rest.
  (let ((selector (require-int32 op "BOOLE")))
    (dolist (argument arguments)
      (require-int32 argument "BOOLE"))
    (case selector
      (1 (arithmetic-result (apply #'logand -1 arguments)))      ; AND
      (6 (arithmetic-result (apply #'logxor 0 arguments)))       ; XOR
      (7 (arithmetic-result (apply #'logior 0 arguments)))       ; IOR
      (otherwise
       (signal-builtin-argument-error
        :unsupported-boole-op
        "BOOLE"
        "BOOLE selector ~S is not implemented; use LOGAND / LOGIOR / LOGXOR."
        op)))))

;;; --- List (autolisp-spec ch.5/13) -----------------------------------

(defun builtin-vl-list-length (list)
  ;; Return the proper-list length, or nil if list is dotted /
  ;; circular.
  (cond
    ((null list) 0)
    ((not (listp list)) nil)
    (t
     (let ((slow list) (fast list) (count 0))
       (loop
         (cond
           ((null fast) (return count))
           ((not (consp fast)) (return nil))
           (t (incf count) (setf fast (cdr fast))))
         (cond
           ((null fast) (return count))
           ((not (consp fast)) (return nil))
           (t (incf count) (setf fast (cdr fast))))
         (setf slow (cdr slow))
         (when (eq fast slow) (return nil)))))))

(defun builtin-vl-position (item list)
  ;; (vl-position ITEM LIST) -> 0-based index or nil.
  (require-proper-list list "VL-POSITION")
  (loop for cell on list
        for index from 0
        when (autolisp-equal-p item (car cell))
          return index
        finally (return nil)))

(defun builtin-remove (item list)
  ;; (remove ITEM LIST) -> new list with all elements equal to ITEM removed.
  (require-proper-list list "REMOVE")
  (loop for element in list
        unless (autolisp-equal-p item element)
          collect element))

(defun builtin-vl-sort (list comparator)
  ;; (vl-sort LIST PREDICATE) — sort LIST stably under PREDICATE
  ;; (a < b iff (PREDICATE a b)). Returns a fresh list.
  (require-proper-list list "VL-SORT")
  (let ((function (resolve-autolisp-function-designator comparator)))
    (sort (copy-list list)
          (lambda (a b)
            (autolisp-true-p (call-autolisp-function function a b))))))

(defun builtin-vl-sort-i (list comparator)
  ;; (vl-sort-i LIST PREDICATE) — return the list of original indices
  ;; sorted under PREDICATE.
  (require-proper-list list "VL-SORT-I")
  (let* ((function (resolve-autolisp-function-designator comparator))
         (indexed (loop for x in list for i from 0 collect (cons i x))))
    (mapcar #'car
            (sort indexed
                  (lambda (a b)
                    (autolisp-true-p
                     (call-autolisp-function function (cdr a) (cdr b))))))))

(defun builtin-distance (point-a point-b)
  ;; (distance P1 P2) -> 2D / 3D Euclidean distance between two
  ;; coordinate lists. Missing Z components default to 0.
  (require-proper-list point-a "DISTANCE")
  (require-proper-list point-b "DISTANCE")
  (let* ((coords-a (mapcar (lambda (n) (require-number n "DISTANCE")) point-a))
         (coords-b (mapcar (lambda (n) (require-number n "DISTANCE")) point-b))
         (xa (coerce (or (nth 0 coords-a) 0) 'double-float))
         (ya (coerce (or (nth 1 coords-a) 0) 'double-float))
         (za (coerce (or (nth 2 coords-a) 0) 'double-float))
         (xb (coerce (or (nth 0 coords-b) 0) 'double-float))
         (yb (coerce (or (nth 1 coords-b) 0) 'double-float))
         (zb (coerce (or (nth 2 coords-b) 0) 'double-float)))
    (sqrt (+ (expt (- xb xa) 2)
             (expt (- yb ya) 2)
             (expt (- zb za) 2)))))

(defun builtin-angle (point-a point-b)
  ;; (angle P1 P2) -> angle in radians from P1 to P2 in the XY plane.
  (require-proper-list point-a "ANGLE")
  (require-proper-list point-b "ANGLE")
  (let* ((xa (coerce (require-number (nth 0 point-a) "ANGLE") 'double-float))
         (ya (coerce (require-number (nth 1 point-a) "ANGLE") 'double-float))
         (xb (coerce (require-number (nth 0 point-b) "ANGLE") 'double-float))
         (yb (coerce (require-number (nth 1 point-b) "ANGLE") 'double-float))
         (theta (atan (- yb ya) (- xb xa))))
    (if (minusp theta) (+ theta (* 2 pi)) theta)))

(defun builtin-polar (origin angle distance)
  ;; (polar P A D) -> point at distance D from P at angle A.
  (require-proper-list origin "POLAR")
  (let* ((a (coerce (require-number angle "POLAR") 'double-float))
         (d (coerce (require-number distance "POLAR") 'double-float))
         (x (coerce (require-number (nth 0 origin) "POLAR") 'double-float))
         (y (coerce (require-number (nth 1 origin) "POLAR") 'double-float))
         (z (if (>= (length origin) 3)
                (coerce (require-number (nth 2 origin) "POLAR") 'double-float)
                0.0d0)))
    (list (+ x (* d (cos a)))
          (+ y (* d (sin a)))
          z)))

;;; --- String / conversion (autolisp-spec ch.7, 11) ------------------

(defun builtin-itoa (object)
  ;; (itoa INT) -> decimal string.
  (let ((value (require-int32 object "ITOA")))
    (make-autolisp-string (format nil "~D" value))))

(defun builtin-rtos (number &optional mode precision)
  ;; (rtos NUMBER [MODE [PRECISION]]) -> string. We honour MODE 1
  ;; (scientific) and 2 (decimal) and the PRECISION argument; modes
  ;; 3 (engineering), 4 (architectural), 5 (fractional) are not
  ;; useful headlessly and fall back to mode 2.
  (require-number number "RTOS")
  (when mode (require-int32 mode "RTOS"))
  (when precision (require-int32 precision "RTOS"))
  (let ((m (or mode 2))
        (p (or precision 4))
        (n (coerce number 'double-float)))
    (make-autolisp-string
     (case m
       (1 (format nil "~,vE" p n))
       (otherwise (format nil "~,vF" (max 0 p) n))))))

(defun builtin-angtos (angle &optional mode precision)
  ;; (angtos ANGLE [MODE [PRECISION]]) -> string in radians (MODE 0)
  ;; or degrees (MODE 1) by default. Modes 2-4 (grad / surveyor /
  ;; deg-min-sec) are not useful headlessly; we fall back to degrees.
  (require-number angle "ANGTOS")
  (when mode (require-int32 mode "ANGTOS"))
  (when precision (require-int32 precision "ANGTOS"))
  (let ((m (or mode 0))
        (p (or precision 4))
        (rad (coerce angle 'double-float)))
    (make-autolisp-string
     (case m
       (0 (format nil "~,vF" (max 0 p) rad))
       (otherwise (format nil "~,vF" (max 0 p) (* rad (/ 180.0d0 pi))))))))

(defun builtin-distof (string &optional mode)
  (declare (ignore mode))
  (let ((value (autolisp-string-value (require-string string "DISTOF"))))
    (parse-autolisp-real value)))

(defun builtin-angtof (string &optional mode)
  ;; (angtof STRING [MODE]) -> real angle. Mode 0 = radians, 1 = deg
  ;; (default decimal). Anything else falls back to a decimal parse.
  (let ((value (autolisp-string-value (require-string string "ANGTOF")))
        (m (if mode (require-int32 mode "ANGTOF") 0)))
    (let ((parsed (parse-autolisp-real value)))
      (case m
        (0 parsed)
        (1 (* parsed (/ pi 180.0d0)))
        (otherwise parsed)))))

(defun builtin-snvalid (string &optional flag)
  ;; (snvalid STRING [FLAG]) -> T if STRING is a valid AutoCAD
  ;; symbol-table name (alnum + a few specials, non-empty). FLAG
  ;; controls whether vertical bar is allowed; we accept conservative
  ;; identifier characters by default.
  (declare (ignore flag))
  (let ((value (autolisp-string-value (require-string string "SNVALID"))))
    (if (and (> (length value) 0)
             (every (lambda (c)
                      (or (alphanumericp c)
                          (find c "_-$#")))
                    value))
        (intern-autolisp-symbol "T")
        nil)))

(defun builtin-xstrcase (string &optional downcase-p)
  ;; vl-extension flavour of strcase that handles non-ASCII text
  ;; better. Headless: same effect as strcase.
  (builtin-strcase string downcase-p))

(defun wcmatch-pattern-p (text pattern)
  ;; Minimal AutoCAD WCMATCH grammar: `*` zero-or-more, `?` any
  ;; single, `#` digit, `@` letter, `.` any non-alnum, `~` (at start)
  ;; complements the match, `,` separates alternative patterns,
  ;; `[abc]` / `[~abc]` / `[a-z]` character classes, ``` `c ``` escapes.
  (let* ((alts (loop for s = 0 then (1+ pos)
                     for pos = (position #\, pattern :start s)
                     collect (subseq pattern s (or pos (length pattern)))
                     while pos))
         (matched
          (some (lambda (alt)
                  (let* ((negate (and (plusp (length alt)) (char= (char alt 0) #\~)))
                         (pat (if negate (subseq alt 1) alt))
                         (hit (wcmatch-single-p text pat)))
                    (if negate (not hit) hit)))
                alts)))
    matched))

(defun wcmatch-single-p (text pattern)
  ;; Recursive-descent matcher for one WCMATCH alternative.
  (let ((tlen (length text))
        (plen (length pattern)))
    (labels ((rec (ti pj)
               (cond
                 ((= pj plen) (= ti tlen))
                 ((char= (char pattern pj) #\*)
                  (or (rec ti (1+ pj))
                      (and (< ti tlen) (rec (1+ ti) pj))))
                 ((= ti tlen) nil)
                 ((char= (char pattern pj) #\?) (rec (1+ ti) (1+ pj)))
                 ((char= (char pattern pj) #\#)
                  (and (digit-char-p (char text ti)) (rec (1+ ti) (1+ pj))))
                 ((char= (char pattern pj) #\@)
                  (and (alpha-char-p (char text ti)) (rec (1+ ti) (1+ pj))))
                 ((char= (char pattern pj) #\.)
                  (and (not (alphanumericp (char text ti))) (rec (1+ ti) (1+ pj))))
                 ((char= (char pattern pj) #\`)
                  (and (< (1+ pj) plen)
                       (char= (char text ti) (char pattern (1+ pj)))
                       (rec (1+ ti) (+ 2 pj))))
                 ((char= (char pattern pj) #\[)
                  (let* ((end (position #\] pattern :start (1+ pj))))
                    (when end
                      (let* ((class (subseq pattern (1+ pj) end))
                             (negate (and (plusp (length class)) (char= (char class 0) #\~)))
                             (chars (if negate (subseq class 1) class))
                             (member-p (loop for k from 0 below (length chars)
                                             thereis
                                               (cond
                                                 ((and (< (+ k 2) (length chars))
                                                       (char= (char chars (1+ k)) #\-))
                                                  (char<= (char chars k)
                                                          (char text ti)
                                                          (char chars (+ k 2))))
                                                 (t (char= (char chars k)
                                                           (char text ti)))))))
                        (when (if negate (not member-p) member-p)
                          (rec (1+ ti) (1+ end)))))))
                 (t
                  (and (char= (char pattern pj) (char text ti))
                       (rec (1+ ti) (1+ pj)))))))
      (rec 0 0))))

(defun builtin-wcmatch (string pattern)
  (let ((s (autolisp-string-value (require-string string "WCMATCH")))
        (p (autolisp-string-value (require-string pattern "WCMATCH"))))
    (if (wcmatch-pattern-p s p) (intern-autolisp-symbol "T") nil)))

;;; --- Geometry ------------------------------------------------------

(defun builtin-inters (p1 p2 p3 p4 &optional within-segments-p)
  ;; (inters P1 P2 P3 P4 [FLAG]) -> point or nil. If FLAG is supplied
  ;; as nil, intersection may lie outside the segments. Default is to
  ;; require that the point lies on both segments.
  (require-proper-list p1 "INTERS")
  (require-proper-list p2 "INTERS")
  (require-proper-list p3 "INTERS")
  (require-proper-list p4 "INTERS")
  (let* ((require-within (if (boundp 'within-segments-p)
                             (autolisp-true-p within-segments-p)
                             t))
         (x1 (coerce (require-number (nth 0 p1) "INTERS") 'double-float))
         (y1 (coerce (require-number (nth 1 p1) "INTERS") 'double-float))
         (x2 (coerce (require-number (nth 0 p2) "INTERS") 'double-float))
         (y2 (coerce (require-number (nth 1 p2) "INTERS") 'double-float))
         (x3 (coerce (require-number (nth 0 p3) "INTERS") 'double-float))
         (y3 (coerce (require-number (nth 1 p3) "INTERS") 'double-float))
         (x4 (coerce (require-number (nth 0 p4) "INTERS") 'double-float))
         (y4 (coerce (require-number (nth 1 p4) "INTERS") 'double-float))
         (denom (- (* (- x1 x2) (- y3 y4))
                   (* (- y1 y2) (- x3 x4)))))
    (when (zerop denom) (return-from builtin-inters nil))
    (let* ((t-num (- (* (- x1 x3) (- y3 y4))
                     (* (- y1 y3) (- x3 x4))))
           (u-num (- (* (- x1 x3) (- y1 y2))
                     (* (- y1 y3) (- x1 x2))))
           (tt (/ t-num denom))
           (uu (/ u-num denom))
           (px (+ x1 (* tt (- x2 x1))))
           (py (+ y1 (* tt (- y2 y1)))))
      (cond
        ((not require-within) (list px py 0.0d0))
        ((and (<= 0.0d0 tt 1.0d0) (<= 0.0d0 uu 1.0d0)) (list px py 0.0d0))
        (t nil)))))

;;; --- Predicate helpers --------------------------------------------

(defun builtin-atoms-family (format-flag &optional symbol-list)
  ;; (atoms-family FORMAT [LIST]) -> list of names of currently-bound
  ;; symbols. FORMAT 0 = symbols, 1 = strings. With LIST, the return
  ;; is restricted to the supplied names; unbound names map to nil.
  (let ((format (require-int32 format-flag "ATOMS-FAMILY"))
        (filter symbol-list))
    (when filter (require-proper-list filter "ATOMS-FAMILY"))
    (labels ((render (name)
               (cond
                 ((zerop format) (intern-autolisp-symbol name))
                 ((= format 1) (make-autolisp-string name))
                 (t (signal-builtin-argument-error
                     :invalid-number-argument
                     "ATOMS-FAMILY"
                     "ATOMS-FAMILY format flag must be 0 or 1, got ~S."
                     format-flag)))))
      (cond
        (filter
         (mapcar (lambda (sym)
                   (let* ((name (cond
                                  ((typep sym 'autolisp-symbol)
                                   (autolisp-symbol-name sym))
                                  ((typep sym 'autolisp-string)
                                   (autolisp-string-value sym))
                                  (t (signal-builtin-argument-error
                                      :invalid-symbol-argument
                                      "ATOMS-FAMILY"
                                      "ATOMS-FAMILY list element must be a symbol or string, got ~S."
                                      sym))))
                          (resolved (clautolisp.autolisp-runtime:find-autolisp-symbol name)))
                     (if (and resolved
                              (clautolisp.autolisp-runtime:autolisp-symbol-value-bound-p resolved))
                         (render name)
                         nil)))
                 filter))
        (t
         (let ((result '()))
           (maphash (lambda (name sym)
                      (when (clautolisp.autolisp-runtime:autolisp-symbol-value-bound-p sym)
                        (push (render name) result)))
                    clautolisp.autolisp-runtime.internal::*autolisp-symbol-table*)
           (nreverse result)))))))

;;; --- Tracing / help (stubs that maintain identity) -----------------

(defun builtin-setfunhelp (function-name &rest topic)
  ;; (setfunhelp NAME [HELPTOPIC [COMMAND]]) — associates a help
  ;; topic with a function. Headless: accepted, recorded as a plist
  ;; entry on the function symbol but otherwise inert.
  (declare (ignore topic))
  (cond
    ((typep function-name 'autolisp-string)
     (intern-autolisp-symbol (autolisp-string-value function-name)))
    ((typep function-name 'autolisp-symbol)
     function-name)
    (t
     (signal-builtin-argument-error
      :invalid-symbol-argument
      "SETFUNHELP"
      "SETFUNHELP expects a function name (string or symbol), got ~S."
      function-name))))

(defparameter *autolisp-backtrace-enabled-p* nil)

(defun builtin-vl-bt ()
  ;; (vl-bt) — print a backtrace. Headless: no-op returning nil.
  nil)

(defun builtin-vl-bt-on ()
  (setf *autolisp-backtrace-enabled-p* t)
  (intern-autolisp-symbol "T"))

(defun builtin-vl-bt-off ()
  (setf *autolisp-backtrace-enabled-p* nil)
  nil)

;;; --- Phase 10: entity-level builtins -------------------------------
;;;
;;; Each builtin is a thin wrapper around the corresponding HAL
;;; generic function on the active session's host backend
;;; (autolisp-spec ch.16). The current-evaluation-host helper
;;; resolves the backend through the active context; under NullHost
;;; every call signals :host-not-supported, under MockHost it
;;; reaches the methods in autolisp-mock-host/source/entity-api.lisp.

(defun require-ename (object operator-name)
  (unless (typep object 'autolisp-ename)
    (signal-builtin-argument-error
     :invalid-ename
     operator-name
     "~A expects an ENAME, got ~S."
     operator-name object))
  object)

(defun builtin-entget (ename)
  (host-entget (current-evaluation-host) (require-ename ename "ENTGET")))

(defun builtin-entmod (data)
  (require-proper-list data "ENTMOD")
  (host-entmod (current-evaluation-host) data))

(defun builtin-entmake (data)
  (require-proper-list data "ENTMAKE")
  (host-entmake (current-evaluation-host) data))

(defun builtin-entmakex (data)
  (require-proper-list data "ENTMAKEX")
  (host-entmakex (current-evaluation-host) data))

(defun builtin-entdel (ename)
  (host-entdel (current-evaluation-host) (require-ename ename "ENTDEL")))

(defun builtin-entupd (ename)
  (host-entupd (current-evaluation-host) (require-ename ename "ENTUPD")))

(defun builtin-entlast ()
  (host-entlast (current-evaluation-host)))

(defun builtin-entnext (&optional ename)
  (host-entnext (current-evaluation-host)
                (and ename (require-ename ename "ENTNEXT"))))

(defun builtin-handent (handle-string)
  (host-handent (current-evaluation-host)
                (autolisp-string-value (require-string handle-string "HANDENT"))))

(defun require-pickset (object operator-name)
  (unless (typep object 'autolisp-pickset)
    (signal-builtin-argument-error
     :invalid-pickset
     operator-name
     "~A expects a PICKSET, got ~S."
     operator-name object))
  object)

;;; --- Phase 11: selection-set builtins -----------------------------

(defun builtin-ssget (&rest arguments)
  ;; (ssget)                   -> interactive (host-not-supported)
  ;; (ssget MODE)              -> mode without filter
  ;; (ssget MODE FILTER)       -> mode + filter
  ;; (ssget FILTER)            -> "X" + filter (rare; treated as
  ;;                              "X" / FILTER for convenience)
  ;; Modes are AutoLISP-strings; FILTER is a list of dotted pairs.
  (let* ((host (current-evaluation-host))
         mode filter)
    (cond
      ((null arguments) nil)
      ((null (rest arguments))
       (let ((only (first arguments)))
         (cond
           ((typep only 'autolisp-string) (setf mode only))
           ((listp only) (setf mode (make-autolisp-string "X")
                              filter only))
           (t (signal-builtin-argument-error
               :invalid-ssget-arguments
               "SSGET"
               "SSGET expects (MODE [FILTER]) or (MODE) or (FILTER), got ~S."
               only)))))
      (t
       (setf mode (first arguments)
             filter (second arguments))))
    (host-ssget host filter :mode mode)))

(defun builtin-ssadd (&rest arguments)
  ;; (ssadd)              -> empty pickset
  ;; (ssadd ENAME)        -> singleton pickset
  ;; (ssadd ENAME PICKSET) -> updated pickset
  (let ((host (current-evaluation-host)))
    (case (length arguments)
      (0 (host-ssadd host nil nil))
      (1 (host-ssadd host nil (require-ename (first arguments) "SSADD")))
      (2 (host-ssadd host
                     (require-pickset (second arguments) "SSADD")
                     (require-ename (first arguments) "SSADD")))
      (otherwise
       (signal-builtin-argument-error
        :wrong-number-of-arguments
        "SSADD"
        "SSADD expects 0, 1, or 2 arguments, got ~D."
        (length arguments))))))

(defun builtin-ssdel (ename pickset)
  (host-ssdel (current-evaluation-host)
              (require-pickset pickset "SSDEL")
              (require-ename ename "SSDEL")))

(defun builtin-ssname (pickset index)
  (host-ssname (current-evaluation-host)
               (require-pickset pickset "SSNAME")
               (require-int32 index "SSNAME")))

(defun builtin-sslength (pickset)
  (host-sslength (current-evaluation-host)
                 (require-pickset pickset "SSLENGTH")))

(defun builtin-ssmemb (ename pickset)
  (host-ssmemb (current-evaluation-host)
               (require-pickset pickset "SSMEMB")
               (require-ename ename "SSMEMB")))

(defun builtin-ssgetfirst ()
  (host-ssgetfirst (current-evaluation-host)))

(defun builtin-sssetfirst (grip-list &optional pickset)
  ;; AutoLISP signature: (sssetfirst GRIP-SET PICKSET). MockHost
  ;; ignores the grip set; we route the pickset to the host.
  (declare (ignore grip-list))
  (host-sssetfirst (current-evaluation-host)
                   (and pickset (require-pickset pickset "SSSETFIRST"))))

;;; --- Phase 11: table walkers --------------------------------------

(defun builtin-tblsearch (kind name &optional next-after)
  (declare (ignore next-after))
  (host-tblsearch (current-evaluation-host)
                  (autolisp-string-value (require-string kind "TBLSEARCH"))
                  (autolisp-string-value (require-string name "TBLSEARCH"))))

(defun builtin-tblnext (kind &optional rewind)
  (host-tblnext (current-evaluation-host)
                (autolisp-string-value (require-string kind "TBLNEXT"))
                :rewind (autolisp-true-p rewind)))

(defun builtin-tblobjname (kind name)
  (host-tblobjname (current-evaluation-host)
                   (autolisp-string-value (require-string kind "TBLOBJNAME"))
                   (autolisp-string-value (require-string name "TBLOBJNAME"))))

;;; --- Phase 11: sysvar access --------------------------------------

(defun builtin-getvar (name)
  (host-getvar (current-evaluation-host)
               (autolisp-string-value (require-string name "GETVAR"))))

(defun builtin-setvar (name value)
  (host-setvar (current-evaluation-host)
               (autolisp-string-value (require-string name "SETVAR"))
               value))

;;; --- Phase 12: headless interaction channel -----------------------

(defun optional-prompt-string (prompt operator-name)
  (cond
    ((null prompt) nil)
    (t (require-string prompt operator-name))))

(defun builtin-initget (&rest arguments)
  ;; (initget [BITS] [KWORD-STRING])
  ;; BITS is an integer; KWORD-STRING is a space-separated list.
  ;; Accepted argument shapes:
  ;;   (initget)
  ;;   (initget BITS)
  ;;   (initget KWORDS)
  ;;   (initget BITS KWORDS)
  (let ((bits 0)
        (keywords '()))
    (cond
      ((null arguments))
      ((null (rest arguments))
       (let ((only (first arguments)))
         (cond
           ((typep only 'autolisp-string)
            (setf keywords (split-keyword-string only)))
           ((integerp only) (setf bits only)))))
      (t
       (when (integerp (first arguments)) (setf bits (first arguments)))
       (let ((kw (or (second arguments)
                     (and (typep (first arguments) 'autolisp-string)
                          (first arguments)))))
         (when (typep kw 'autolisp-string)
           (setf keywords (split-keyword-string kw))))))
    (host-initget (current-evaluation-host) bits keywords)))

(defun split-keyword-string (autolisp-string-value)
  (let ((value (autolisp-string-value autolisp-string-value)))
    (let ((result '())
          (start 0))
      (loop for i from 0 below (length value)
            for c = (char value i)
            when (or (char= c #\Space) (char= c #\Tab))
              do (when (< start i)
                   (push (subseq value start i) result))
                 (setf start (1+ i)))
      (when (< start (length value))
        (push (subseq value start) result))
      (nreverse result))))

(defun builtin-getstring (&optional read-spaces-or-prompt prompt)
  ;; (getstring [PROMPT])              ; one-shot, no spaces
  ;; (getstring CRSPACES [PROMPT])     ; CRSPACES non-nil to allow spaces
  ;; The MockHost always reads a whole line, so the CRSPACES flag is
  ;; permissive for now.
  (let ((effective-prompt
         (cond
           ((null read-spaces-or-prompt) prompt)
           ((typep read-spaces-or-prompt 'autolisp-string) read-spaces-or-prompt)
           (t prompt))))
    (host-getstring (current-evaluation-host)
                    (and effective-prompt
                         (optional-prompt-string effective-prompt "GETSTRING")))))

(defun builtin-getint (&optional prompt)
  (host-getint (current-evaluation-host)
               (and prompt (optional-prompt-string prompt "GETINT"))))

(defun builtin-getreal (&optional prompt)
  (host-getreal (current-evaluation-host)
                (and prompt (optional-prompt-string prompt "GETREAL"))))

(defun builtin-getpoint (&rest arguments)
  ;; (getpoint [BASE] [PROMPT])
  (let (base prompt)
    (cond
      ((null arguments))
      ((null (rest arguments))
       (let ((only (first arguments)))
         (cond
           ((typep only 'autolisp-string) (setf prompt only))
           ((listp only) (setf base only)))))
      (t (setf base (first arguments) prompt (second arguments))))
    (host-getpoint (current-evaluation-host)
                   (and prompt (optional-prompt-string prompt "GETPOINT"))
                   :base base)))

(defun builtin-getcorner (base &optional prompt)
  (host-getcorner (current-evaluation-host)
                  (and prompt (optional-prompt-string prompt "GETCORNER"))
                  :base base))

(defun builtin-getdist (&rest arguments)
  ;; (getdist [BASE] [PROMPT])
  (let (base prompt)
    (cond
      ((null arguments))
      ((null (rest arguments))
       (let ((only (first arguments)))
         (cond
           ((typep only 'autolisp-string) (setf prompt only))
           ((listp only) (setf base only)))))
      (t (setf base (first arguments) prompt (second arguments))))
    (host-getdist (current-evaluation-host)
                  (and prompt (optional-prompt-string prompt "GETDIST"))
                  :base base)))

(defun builtin-getangle (&rest arguments)
  (let (base prompt)
    (cond
      ((null arguments))
      ((null (rest arguments))
       (let ((only (first arguments)))
         (cond
           ((typep only 'autolisp-string) (setf prompt only))
           ((listp only) (setf base only)))))
      (t (setf base (first arguments) prompt (second arguments))))
    (host-getangle (current-evaluation-host)
                   (and prompt (optional-prompt-string prompt "GETANGLE"))
                   :base base)))

(defun builtin-getorient (&rest arguments)
  (let (base prompt)
    (cond
      ((null arguments))
      ((null (rest arguments))
       (let ((only (first arguments)))
         (cond
           ((typep only 'autolisp-string) (setf prompt only))
           ((listp only) (setf base only)))))
      (t (setf base (first arguments) prompt (second arguments))))
    (host-getorient (current-evaluation-host)
                    (and prompt (optional-prompt-string prompt "GETORIENT"))
                    :base base)))

(defun builtin-getkword (&optional prompt)
  (host-getkword (current-evaluation-host)
                 (and prompt (optional-prompt-string prompt "GETKWORD"))))

;;; --- Phase 13: COM bridge (vlax-* + safearray + variant) ----------

(defun ensure-vlax-string (object operator-name)
  (etypecase object
    (autolisp-string (autolisp-string-value object))
    (string object)))

(defun builtin-vlax-create-object (progid)
  (host-vlax-create-object (current-evaluation-host)
                           (ensure-vlax-string
                            (require-string progid "VLAX-CREATE-OBJECT")
                            "VLAX-CREATE-OBJECT")))

(defun builtin-vlax-get-object (progid)
  (host-vlax-get-object (current-evaluation-host)
                        (ensure-vlax-string
                         (require-string progid "VLAX-GET-OBJECT")
                         "VLAX-GET-OBJECT")))

(defun builtin-vlax-get-or-create-object (progid)
  (or (builtin-vlax-get-object progid)
      (builtin-vlax-create-object progid)))

(defun builtin-vlax-release-object (vla)
  (host-vlax-release-object (current-evaluation-host) vla))

(defun builtin-vlax-object-released-p (vla)
  (cond
    ((typep vla 'autolisp-vla-object)
     (handler-case
         (progn (host-vlax-property-available-p (current-evaluation-host) vla "Name")
                nil)
       (autolisp-runtime-error (condition)
         (case (autolisp-runtime-error-code condition)
           ((:released-vla-object :unknown-vla-object)
            (intern-autolisp-symbol "T"))
           (t (error condition))))))
    (t nil)))

(defun builtin-vlax-get-property (vla name)
  (host-vlax-get-property (current-evaluation-host) vla
                          (cond
                            ((typep name 'autolisp-string) (autolisp-string-value name))
                            ((typep name 'autolisp-symbol) (autolisp-symbol-name name))
                            (t name))))

(defun builtin-vlax-put-property (vla name value)
  (host-vlax-put-property (current-evaluation-host) vla
                          (cond
                            ((typep name 'autolisp-string) (autolisp-string-value name))
                            ((typep name 'autolisp-symbol) (autolisp-symbol-name name))
                            (t name))
                          value))

(defun builtin-vlax-invoke-method (vla name &rest args)
  (host-vlax-invoke-method (current-evaluation-host) vla
                           (cond
                             ((typep name 'autolisp-string) (autolisp-string-value name))
                             ((typep name 'autolisp-symbol) (autolisp-symbol-name name))
                             (t name))
                           args))

(defun builtin-vlax-property-available-p (vla name)
  (if (host-vlax-property-available-p
       (current-evaluation-host) vla
       (cond
         ((typep name 'autolisp-string) (autolisp-string-value name))
         ((typep name 'autolisp-symbol) (autolisp-symbol-name name))
         (t name)))
      (intern-autolisp-symbol "T")
      nil))

(defun builtin-vlax-method-applicable-p (vla name)
  (if (host-vlax-method-applicable-p
       (current-evaluation-host) vla
       (cond
         ((typep name 'autolisp-string) (autolisp-string-value name))
         ((typep name 'autolisp-symbol) (autolisp-symbol-name name))
         (t name)))
      (intern-autolisp-symbol "T")
      nil))

;;; --- SAFEARRAY -----------------------------------------------------
;;
;; SAFEARRAY is a tagged multi-dimensional array with an element-
;; type marker and per-dimension lower/upper bounds. AutoLISP
;; programs use `vlax-make-safearray TYPE BOUNDS...` to allocate,
;; then `vlax-safearray-fill` / `vlax-safearray-put-element` to
;; populate. clautolisp keeps the storage as an internal struct
;; (`safearray-data`) inside the runtime's `autolisp-safearray`
;; wrapper's `value` slot.

(defstruct safearray-data
  (type-tag :variant :type keyword)
  (bounds   '() :type list)
  (storage  nil))

(defun safearray-of (object operator-name)
  (unless (typep object 'autolisp-safearray)
    (signal-builtin-argument-error
     :invalid-safearray
     operator-name
     "~A expects a SAFEARRAY, got ~S."
     operator-name object))
  (let ((data (autolisp-safearray-value object)))
    (unless (typep data 'safearray-data)
      (signal-builtin-argument-error
       :invalid-safearray
       operator-name
       "~A: SAFEARRAY storage is not a clautolisp safearray-data, got ~S."
       operator-name data))
    data))

(defun coerce-bounds-spec (raw operator-name)
  "Each dimension is given as (cons LOW HIGH); flatten into a list of
(LOW HIGH) pairs, validating integers and LOW <= HIGH."
  (unless (and raw (listp raw))
    (signal-builtin-argument-error
     :invalid-safearray-bounds
     operator-name
     "~A expects a list of (LOW . HIGH) bound pairs, got ~S."
     operator-name raw))
  (mapcar (lambda (pair)
            (unless (and (consp pair)
                         (integerp (car pair))
                         (integerp (cdr pair))
                         (<= (car pair) (cdr pair)))
              (signal-builtin-argument-error
               :invalid-safearray-bounds
               operator-name
               "~A: each bound must be (LOW . HIGH) integer pair with LOW <= HIGH, got ~S."
               operator-name pair))
            (list (car pair) (cdr pair)))
          raw))

(defun bounds-shape (bounds)
  (mapcar (lambda (pair) (1+ (- (second pair) (first pair)))) bounds))

(defun safearray-flat-index (bounds subscripts operator-name)
  (unless (= (length bounds) (length subscripts))
    (signal-builtin-argument-error
     :invalid-safearray-index
     operator-name
     "~A: ~D subscripts required, got ~D."
     operator-name (length bounds) (length subscripts)))
  (let ((flat 0)
        (stride 1))
    (loop for pair in (reverse bounds)
          for sub in (reverse subscripts)
          for low = (first pair)
          for high = (second pair)
          do (unless (and (integerp sub) (<= low sub high))
               (signal-builtin-argument-error
                :invalid-safearray-index
                operator-name
                "~A: subscript ~S out of bounds [~D..~D]."
                operator-name sub low high))
             (incf flat (* (- sub low) stride))
             (setf stride (* stride (1+ (- high low)))))
    flat))

(defun builtin-vlax-make-safearray (type &rest bounds)
  (let* ((tag (cond
                ((integerp type) type)
                ((typep type 'autolisp-symbol)
                 (intern (autolisp-symbol-name type) "KEYWORD"))
                (t :variant)))
         (parsed (coerce-bounds-spec bounds "VLAX-MAKE-SAFEARRAY"))
         (size (reduce #'* (bounds-shape parsed) :initial-value 1))
         (storage (make-array size :initial-element nil)))
    (make-autolisp-safearray
     :value (make-safearray-data :type-tag (if (keywordp tag) tag :variant)
                                  :bounds parsed
                                  :storage storage))))

(defun builtin-vlax-safearray-fill (safe values)
  (require-proper-list values "VLAX-SAFEARRAY-FILL")
  (let* ((data (safearray-of safe "VLAX-SAFEARRAY-FILL"))
         (storage (safearray-data-storage data)))
    (loop for value in values
          for i from 0
          while (< i (length storage))
          do (setf (aref storage i) value))
    safe))

(defun builtin-vlax-safearray-put-element (safe &rest indices-and-value)
  (when (< (length indices-and-value) 2)
    (signal-builtin-argument-error
     :wrong-number-of-arguments
     "VLAX-SAFEARRAY-PUT-ELEMENT"
     "VLAX-SAFEARRAY-PUT-ELEMENT expects subscripts followed by a value."))
  (let* ((data (safearray-of safe "VLAX-SAFEARRAY-PUT-ELEMENT"))
         (subscripts (butlast indices-and-value))
         (value (car (last indices-and-value)))
         (flat (safearray-flat-index (safearray-data-bounds data)
                                     subscripts
                                     "VLAX-SAFEARRAY-PUT-ELEMENT")))
    (setf (aref (safearray-data-storage data) flat) value)
    value))

(defun builtin-vlax-safearray-get-element (safe &rest indices)
  (let* ((data (safearray-of safe "VLAX-SAFEARRAY-GET-ELEMENT"))
         (flat (safearray-flat-index (safearray-data-bounds data)
                                     indices
                                     "VLAX-SAFEARRAY-GET-ELEMENT")))
    (aref (safearray-data-storage data) flat)))

(defun builtin-vlax-safearray->list (safe)
  (let* ((data (safearray-of safe "VLAX-SAFEARRAY->LIST"))
         (storage (safearray-data-storage data)))
    (coerce storage 'list)))

(defun builtin-vlax-safearray-type (safe)
  (let ((data (safearray-of safe "VLAX-SAFEARRAY-TYPE")))
    (intern-autolisp-symbol (symbol-name (safearray-data-type-tag data)))))

(defun builtin-vlax-safearray-get-l-bound (safe dim)
  (let* ((data (safearray-of safe "VLAX-SAFEARRAY-GET-L-BOUND"))
         (i (require-int32 dim "VLAX-SAFEARRAY-GET-L-BOUND"))
         (pair (nth (1- i) (safearray-data-bounds data))))
    (cond
      ((null pair)
       (signal-builtin-argument-error
        :invalid-safearray-dimension
        "VLAX-SAFEARRAY-GET-L-BOUND"
        "Dimension ~D is out of range." dim))
      (t (first pair)))))

(defun builtin-vlax-safearray-get-u-bound (safe dim)
  (let* ((data (safearray-of safe "VLAX-SAFEARRAY-GET-U-BOUND"))
         (i (require-int32 dim "VLAX-SAFEARRAY-GET-U-BOUND"))
         (pair (nth (1- i) (safearray-data-bounds data))))
    (cond
      ((null pair)
       (signal-builtin-argument-error
        :invalid-safearray-dimension
        "VLAX-SAFEARRAY-GET-U-BOUND"
        "Dimension ~D is out of range." dim))
      (t (second pair)))))

;;; --- VARIANT -------------------------------------------------------
;;
;; Internal storage: a (cons type-keyword inner-value) pair.
;; Inner-value is whatever the AutoLISP code supplied; type-keyword
;; is one of :integer / :real / :string / :array / :variant /
;; :short / :boolean — descriptive only, not type-checked beyond
;; the identity round-trip.

(defun variant-pair (object operator-name)
  (unless (typep object 'autolisp-variant)
    (signal-builtin-argument-error
     :invalid-variant
     operator-name
     "~A expects a VARIANT, got ~S."
     operator-name object))
  (let ((pair (autolisp-variant-value object)))
    (unless (consp pair)
      (signal-builtin-argument-error
       :invalid-variant
       operator-name
       "~A: VARIANT storage is not a (TYPE . VALUE) pair, got ~S."
       operator-name pair))
    pair))

(defun builtin-vlax-make-variant (&optional value type)
  (let* ((tag (cond
                ((null type)
                 (cond
                   ((integerp value) :integer)
                   ((numberp value) :real)
                   ((typep value 'autolisp-string) :string)
                   ((typep value 'autolisp-safearray) :array)
                   ((null value) :empty)
                   (t :variant)))
                ((typep type 'autolisp-symbol)
                 (intern (autolisp-symbol-name type) "KEYWORD"))
                ((keywordp type) type)
                ((integerp type) type)
                (t :variant))))
    (make-autolisp-variant :value (cons (if (keywordp tag) tag :variant) value))))

(defun builtin-vlax-variant-type (variant)
  (let ((tag (car (variant-pair variant "VLAX-VARIANT-TYPE"))))
    (intern-autolisp-symbol (symbol-name tag))))

(defun builtin-vlax-variant-value (variant)
  (cdr (variant-pair variant "VLAX-VARIANT-VALUE")))

(defun builtin-vlax-variant-change-type (variant new-type)
  (let* ((pair (variant-pair variant "VLAX-VARIANT-CHANGE-TYPE"))
         (target (cond
                   ((typep new-type 'autolisp-symbol)
                    (intern (autolisp-symbol-name new-type) "KEYWORD"))
                   ((keywordp new-type) new-type)
                   (t :variant))))
    (make-autolisp-variant :value (cons target (cdr pair)))))

(defun core-builtins ()
  (list
   (make-core-builtin-subr "TYPE" #'autolisp-type)
   (make-core-builtin-subr "NULL" #'autolisp-null)
   (make-core-builtin-subr "NOT" #'autolisp-not)
   (make-core-builtin-subr "ATOM" #'autolisp-atom)
   (make-core-builtin-subr "VL-SYMBOLP" #'autolisp-vl-symbolp)
   (make-core-builtin-subr "VL-SYMBOL-NAME" #'autolisp-vl-symbol-name)
   (make-core-builtin-subr "VL-SYMBOL-VALUE" #'autolisp-vl-symbol-value)
   (make-core-builtin-subr "VL-BB-REF" #'builtin-vl-bb-ref)
   (make-core-builtin-subr "VL-BB-SET" #'builtin-vl-bb-set)
   (make-core-builtin-subr "VL-PROPAGATE" #'builtin-vl-propagate)
   (make-core-builtin-subr "VL-DOC-REF" #'builtin-vl-doc-ref)
   (make-core-builtin-subr "VL-DOC-SET" #'builtin-vl-doc-set)
   (make-core-builtin-subr "VL-DOC-EXPORT" #'builtin-vl-doc-export)
   (make-core-builtin-subr "VL-DOC-IMPORT" #'builtin-vl-doc-import)
   (make-core-builtin-subr "MAPCAR" #'builtin-mapcar)
   (make-core-builtin-subr "APPLY" #'builtin-apply)
   (make-core-builtin-subr "EVAL" #'builtin-eval)
   (make-core-builtin-subr "EQ" #'builtin-eq)
   (make-core-builtin-subr "EQUAL" #'builtin-equal)
   (make-core-builtin-subr "ERROR" #'builtin-error)
   ;; Phase 7 — math
   (make-core-builtin-subr "SQRT" #'builtin-sqrt)
   (make-core-builtin-subr "EXP" #'builtin-exp)
   (make-core-builtin-subr "LOG" #'builtin-log)
   (make-core-builtin-subr "LOG10" #'builtin-log10)
   (make-core-builtin-subr "SIN" #'builtin-sin)
   (make-core-builtin-subr "COS" #'builtin-cos)
   (make-core-builtin-subr "TAN" #'builtin-tan)
   (make-core-builtin-subr "ASIN" #'builtin-asin)
   (make-core-builtin-subr "ACOS" #'builtin-acos)
   (make-core-builtin-subr "ATAN" #'builtin-atan)
   (make-core-builtin-subr "EXPT" #'builtin-expt)
   (make-core-builtin-subr "MOD" #'builtin-mod)
   (make-core-builtin-subr "FLOOR" #'builtin-floor)
   (make-core-builtin-subr "CEILING" #'builtin-ceiling)
   (make-core-builtin-subr "ROUND" #'builtin-round)
   (make-core-builtin-subr "RANDOM" #'builtin-random)
   ;; Phase 7 — bitwise
   (make-core-builtin-subr "LOGXOR" #'builtin-logxor)
   (make-core-builtin-subr "BOOLE" #'builtin-boole)
   ;; Phase 7 — list
   (make-core-builtin-subr "VL-LIST-LENGTH" #'builtin-vl-list-length)
   (make-core-builtin-subr "VL-POSITION" #'builtin-vl-position)
   (make-core-builtin-subr "REMOVE" #'builtin-remove)
   (make-core-builtin-subr "VL-SORT" #'builtin-vl-sort)
   (make-core-builtin-subr "VL-SORT-I" #'builtin-vl-sort-i)
   ;; Phase 7 — geometry
   (make-core-builtin-subr "DISTANCE" #'builtin-distance)
   (make-core-builtin-subr "ANGLE" #'builtin-angle)
   (make-core-builtin-subr "POLAR" #'builtin-polar)
   (make-core-builtin-subr "INTERS" #'builtin-inters)
   ;; Phase 7 — string / conversion
   (make-core-builtin-subr "ITOA" #'builtin-itoa)
   (make-core-builtin-subr "RTOS" #'builtin-rtos)
   (make-core-builtin-subr "ANGTOS" #'builtin-angtos)
   (make-core-builtin-subr "DISTOF" #'builtin-distof)
   (make-core-builtin-subr "ANGTOF" #'builtin-angtof)
   (make-core-builtin-subr "SNVALID" #'builtin-snvalid)
   (make-core-builtin-subr "WCMATCH" #'builtin-wcmatch)
   (make-core-builtin-subr "XSTRCASE" #'builtin-xstrcase)
   ;; Phase 7 — predicate / introspection
   (make-core-builtin-subr "ATOMS-FAMILY" #'builtin-atoms-family)
   ;; Phase 7 — help / tracing (headless stubs)
   (make-core-builtin-subr "SETFUNHELP" #'builtin-setfunhelp)
   (make-core-builtin-subr "VL-BT" #'builtin-vl-bt)
   (make-core-builtin-subr "VL-BT-ON" #'builtin-vl-bt-on)
   (make-core-builtin-subr "VL-BT-OFF" #'builtin-vl-bt-off)
   ;; Phase 10 — entity API (thin wrappers over the HAL)
   (make-core-builtin-subr "ENTGET"   #'builtin-entget)
   (make-core-builtin-subr "ENTMOD"   #'builtin-entmod)
   (make-core-builtin-subr "ENTMAKE"  #'builtin-entmake)
   (make-core-builtin-subr "ENTMAKEX" #'builtin-entmakex)
   (make-core-builtin-subr "ENTDEL"   #'builtin-entdel)
   (make-core-builtin-subr "ENTUPD"   #'builtin-entupd)
   (make-core-builtin-subr "ENTLAST"  #'builtin-entlast)
   (make-core-builtin-subr "ENTNEXT"  #'builtin-entnext)
   (make-core-builtin-subr "HANDENT"  #'builtin-handent)
   ;; Phase 11 — selection sets, table walkers, sysvars
   (make-core-builtin-subr "SSGET"      #'builtin-ssget)
   (make-core-builtin-subr "SSADD"      #'builtin-ssadd)
   (make-core-builtin-subr "SSDEL"      #'builtin-ssdel)
   (make-core-builtin-subr "SSNAME"     #'builtin-ssname)
   (make-core-builtin-subr "SSLENGTH"   #'builtin-sslength)
   (make-core-builtin-subr "SSMEMB"     #'builtin-ssmemb)
   (make-core-builtin-subr "SSGETFIRST" #'builtin-ssgetfirst)
   (make-core-builtin-subr "SSSETFIRST" #'builtin-sssetfirst)
   (make-core-builtin-subr "TBLSEARCH"  #'builtin-tblsearch)
   (make-core-builtin-subr "TBLNEXT"    #'builtin-tblnext)
   (make-core-builtin-subr "TBLOBJNAME" #'builtin-tblobjname)
   (make-core-builtin-subr "GETVAR"     #'builtin-getvar)
   (make-core-builtin-subr "SETVAR"     #'builtin-setvar)
   ;; Phase 12 — headless interaction channel (PROMPT is registered
   ;; once already as a *standard-output* writer; we keep that)
   (make-core-builtin-subr "INITGET"    #'builtin-initget)
   (make-core-builtin-subr "GETSTRING"  #'builtin-getstring)
   (make-core-builtin-subr "GETINT"     #'builtin-getint)
   (make-core-builtin-subr "GETREAL"    #'builtin-getreal)
   (make-core-builtin-subr "GETPOINT"   #'builtin-getpoint)
   (make-core-builtin-subr "GETCORNER"  #'builtin-getcorner)
   (make-core-builtin-subr "GETDIST"    #'builtin-getdist)
   (make-core-builtin-subr "GETANGLE"   #'builtin-getangle)
   (make-core-builtin-subr "GETORIENT"  #'builtin-getorient)
   (make-core-builtin-subr "GETKWORD"   #'builtin-getkword)
   ;; Phase 13 — COM bridge (vlax-* + safearray + variant)
   (make-core-builtin-subr "VLAX-CREATE-OBJECT"           #'builtin-vlax-create-object)
   (make-core-builtin-subr "VLAX-GET-OBJECT"              #'builtin-vlax-get-object)
   (make-core-builtin-subr "VLAX-GET-OR-CREATE-OBJECT"    #'builtin-vlax-get-or-create-object)
   (make-core-builtin-subr "VLAX-RELEASE-OBJECT"          #'builtin-vlax-release-object)
   (make-core-builtin-subr "VLAX-OBJECT-RELEASED-P"       #'builtin-vlax-object-released-p)
   (make-core-builtin-subr "VLAX-GET-PROPERTY"            #'builtin-vlax-get-property)
   (make-core-builtin-subr "VLAX-PUT-PROPERTY"            #'builtin-vlax-put-property)
   (make-core-builtin-subr "VLAX-INVOKE-METHOD"           #'builtin-vlax-invoke-method)
   (make-core-builtin-subr "VLAX-PROPERTY-AVAILABLE-P"    #'builtin-vlax-property-available-p)
   (make-core-builtin-subr "VLAX-METHOD-APPLICABLE-P"     #'builtin-vlax-method-applicable-p)
   (make-core-builtin-subr "VLAX-MAKE-SAFEARRAY"          #'builtin-vlax-make-safearray)
   (make-core-builtin-subr "VLAX-SAFEARRAY-FILL"          #'builtin-vlax-safearray-fill)
   (make-core-builtin-subr "VLAX-SAFEARRAY-PUT-ELEMENT"   #'builtin-vlax-safearray-put-element)
   (make-core-builtin-subr "VLAX-SAFEARRAY-GET-ELEMENT"   #'builtin-vlax-safearray-get-element)
   (make-core-builtin-subr "VLAX-SAFEARRAY->LIST"         #'builtin-vlax-safearray->list)
   (make-core-builtin-subr "VLAX-SAFEARRAY-TYPE"          #'builtin-vlax-safearray-type)
   (make-core-builtin-subr "VLAX-SAFEARRAY-GET-L-BOUND"   #'builtin-vlax-safearray-get-l-bound)
   (make-core-builtin-subr "VLAX-SAFEARRAY-GET-U-BOUND"   #'builtin-vlax-safearray-get-u-bound)
   (make-core-builtin-subr "VLAX-MAKE-VARIANT"            #'builtin-vlax-make-variant)
   (make-core-builtin-subr "VLAX-VARIANT-TYPE"            #'builtin-vlax-variant-type)
   (make-core-builtin-subr "VLAX-VARIANT-VALUE"           #'builtin-vlax-variant-value)
   (make-core-builtin-subr "VLAX-VARIANT-CHANGE-TYPE"     #'builtin-vlax-variant-change-type)
   (make-core-builtin-subr "VL-EVERY" #'builtin-vl-every)
   (make-core-builtin-subr "VL-MEMBER-IF" #'builtin-vl-member-if)
   (make-core-builtin-subr "VL-MEMBER-IF-NOT" #'builtin-vl-member-if-not)
   (make-core-builtin-subr "VL-REMOVE-IF" #'builtin-vl-remove-if)
   (make-core-builtin-subr "VL-REMOVE-IF-NOT" #'builtin-vl-remove-if-not)
   (make-core-builtin-subr "VL-SOME" #'builtin-vl-some)
   (make-core-builtin-subr "+" #'builtin-+)
   (make-core-builtin-subr "-" #'builtin--)
   (make-core-builtin-subr "*" #'builtin-*)
   (make-core-builtin-subr "/" #'builtin-/)
   (make-core-builtin-subr "1+" #'builtin-1+)
   (make-core-builtin-subr "1-" #'builtin-1-)
   (make-core-builtin-subr "MAX" #'builtin-max)
   (make-core-builtin-subr "MIN" #'builtin-min)
   (make-core-builtin-subr "REM" #'builtin-rem)
   (make-core-builtin-subr "GCD" #'builtin-gcd)
   (make-core-builtin-subr "LCM" #'builtin-lcm)
   (make-core-builtin-subr "~" #'builtin-~)
   (make-core-builtin-subr "LOGAND" #'builtin-logand)
   (make-core-builtin-subr "LOGIOR" #'builtin-logior)
   (make-core-builtin-subr "LSH" #'builtin-lsh)
   (make-core-builtin-subr "STRCAT" #'builtin-strcat)
   (make-core-builtin-subr "STRLEN" #'builtin-strlen)
   (make-core-builtin-subr "SUBSTR" #'builtin-substr)
   (make-core-builtin-subr "STRCASE" #'builtin-strcase)
   (make-core-builtin-subr "VL-STRING-TRIM" #'builtin-vl-string-trim)
   (make-core-builtin-subr "VL-STRING-LEFT-TRIM" #'builtin-vl-string-left-trim)
   (make-core-builtin-subr "VL-STRING-RIGHT-TRIM" #'builtin-vl-string-right-trim)
   (make-core-builtin-subr "VL-STRING-SEARCH" #'builtin-vl-string-search)
   (make-core-builtin-subr "VL-STRING-POSITION" #'builtin-vl-string-position)
   (make-core-builtin-subr "VL-STRING-TRANSLATE" #'builtin-vl-string-translate)
   (make-core-builtin-subr "VL-STRING-SUBST" #'builtin-vl-string-subst)
   (make-core-builtin-subr "VL-STRING-MISMATCH" #'builtin-vl-string-mismatch)
   (make-core-builtin-subr "VL-STRING-ELT" #'builtin-vl-string-elt)
   (make-core-builtin-subr "VL-STRING->LIST" #'builtin-vl-string->list)
   (make-core-builtin-subr "VL-LIST->STRING" #'builtin-vl-list->string)
   (make-core-builtin-subr "ASCII" #'builtin-ascii)
   (make-core-builtin-subr "CHR" #'builtin-chr)
   (make-core-builtin-subr "ATOI" #'builtin-atoi)
   (make-core-builtin-subr "ATOF" #'builtin-atof)
   (make-core-builtin-subr "READ" #'builtin-read)
   (make-core-builtin-subr "LOAD" #'builtin-load)
   (make-core-builtin-subr "AUTOLOAD" #'builtin-autoload)
   (make-core-builtin-subr "OPEN" #'builtin-open)
   (make-core-builtin-subr "CLOSE" #'builtin-close)
   (make-core-builtin-subr "READ-LINE" #'builtin-read-line)
   (make-core-builtin-subr "READ-CHAR" #'builtin-read-char)
   (make-core-builtin-subr "WRITE-LINE" #'builtin-write-line)
   (make-core-builtin-subr "WRITE-CHAR" #'builtin-write-char)
   (make-core-builtin-subr "FINDFILE" #'builtin-findfile)
   (make-core-builtin-subr "FINDTRUSTEDFILE" #'builtin-findtrustedfile)
   (make-core-builtin-subr "VL-DIRECTORY-FILES" #'builtin-vl-directory-files)
   (make-core-builtin-subr "VL-FILE-DIRECTORY-P" #'builtin-vl-file-directory-p)
   (make-core-builtin-subr "VL-FILENAME-BASE" #'builtin-vl-filename-base)
   (make-core-builtin-subr "VL-FILENAME-DIRECTORY" #'builtin-vl-filename-directory)
   (make-core-builtin-subr "VL-FILENAME-EXTENSION" #'builtin-vl-filename-extension)
   (make-core-builtin-subr "VL-FILE-DELETE" #'builtin-vl-file-delete)
   (make-core-builtin-subr "VL-FILE-RENAME" #'builtin-vl-file-rename)
   (make-core-builtin-subr "VL-FILE-SIZE" #'builtin-vl-file-size)
   (make-core-builtin-subr "VL-FILE-SYSTIME" #'builtin-vl-file-systime)
   (make-core-builtin-subr "VL-FILE-COPY" #'builtin-vl-file-copy)
   (make-core-builtin-subr "VL-FILENAME-MKTEMP" #'builtin-vl-filename-mktemp)
   (make-core-builtin-subr "VL-MKDIR" #'builtin-vl-mkdir)
   (make-core-builtin-subr "PRIN1" #'builtin-prin1)
   (make-core-builtin-subr "PRINC" #'builtin-princ)
   (make-core-builtin-subr "PRINT" #'builtin-print)
   (make-core-builtin-subr "TERPRI" #'builtin-terpri)
   (make-core-builtin-subr "PROMPT" #'builtin-prompt)
   (make-core-builtin-subr "EXIT" #'builtin-exit)
   (make-core-builtin-subr "QUIT" #'builtin-quit)
   (make-core-builtin-subr "VL-PRIN1-TO-STRING" #'builtin-vl-prin1-to-string)
   (make-core-builtin-subr "VL-PRINC-TO-STRING" #'builtin-vl-princ-to-string)
   (make-core-builtin-subr "VL-CATCH-ALL-APPLY" #'builtin-vl-catch-all-apply)
   (make-core-builtin-subr "VL-CATCH-ALL-ERROR-P" #'builtin-vl-catch-all-error-p)
   (make-core-builtin-subr "VL-CATCH-ALL-ERROR-MESSAGE"
                           #'builtin-vl-catch-all-error-message)
   (make-core-builtin-subr "VL-EXIT-WITH-ERROR" #'builtin-vl-exit-with-error)
   (make-core-builtin-subr "VL-EXIT-WITH-VALUE" #'builtin-vl-exit-with-value)
   (make-core-builtin-subr "DEFUN-Q-LIST-REF" #'builtin-defun-q-list-ref)
   (make-core-builtin-subr "DEFUN-Q-LIST-SET" #'builtin-defun-q-list-set)
   (make-core-builtin-subr "BOUNDP" #'builtin-boundp)
   (make-core-builtin-subr "CAR" #'builtin-car)
   (make-core-builtin-subr "CDR" #'builtin-cdr)
   (make-core-builtin-subr "CAAR"  #'builtin-caar)
   (make-core-builtin-subr "CADR"  #'builtin-cadr)
   (make-core-builtin-subr "CDAR"  #'builtin-cdar)
   (make-core-builtin-subr "CDDR"  #'builtin-cddr)
   (make-core-builtin-subr "CAAAR" #'builtin-caaar)
   (make-core-builtin-subr "CAADR" #'builtin-caadr)
   (make-core-builtin-subr "CADAR" #'builtin-cadar)
   (make-core-builtin-subr "CADDR" #'builtin-caddr)
   (make-core-builtin-subr "CDAAR" #'builtin-cdaar)
   (make-core-builtin-subr "CDADR" #'builtin-cdadr)
   (make-core-builtin-subr "CDDAR" #'builtin-cddar)
   (make-core-builtin-subr "CDDDR" #'builtin-cdddr)
   (make-core-builtin-subr "CAAAAR" #'builtin-caaaar)
   (make-core-builtin-subr "CAAADR" #'builtin-caaadr)
   (make-core-builtin-subr "CAADAR" #'builtin-caadar)
   (make-core-builtin-subr "CAADDR" #'builtin-caaddr)
   (make-core-builtin-subr "CADAAR" #'builtin-cadaar)
   (make-core-builtin-subr "CADADR" #'builtin-cadadr)
   (make-core-builtin-subr "CADDAR" #'builtin-caddar)
   (make-core-builtin-subr "CADDDR" #'builtin-cadddr)
   (make-core-builtin-subr "CDAAAR" #'builtin-cdaaar)
   (make-core-builtin-subr "CDAADR" #'builtin-cdaadr)
   (make-core-builtin-subr "CDADAR" #'builtin-cdadar)
   (make-core-builtin-subr "CDADDR" #'builtin-cdaddr)
   (make-core-builtin-subr "CDDAAR" #'builtin-cddaar)
   (make-core-builtin-subr "CDDADR" #'builtin-cddadr)
   (make-core-builtin-subr "CDDDAR" #'builtin-cdddar)
   (make-core-builtin-subr "CDDDDR" #'builtin-cddddr)
   (make-core-builtin-subr "CONS" #'builtin-cons)
   (make-core-builtin-subr "LIST" #'builtin-list)
   (make-core-builtin-subr "APPEND" #'builtin-append)
   (make-core-builtin-subr "ASSOC" #'builtin-assoc)
   (make-core-builtin-subr "LENGTH" #'builtin-length)
   (make-core-builtin-subr "NTH" #'builtin-nth)
   (make-core-builtin-subr "REVERSE" #'builtin-reverse)
   (make-core-builtin-subr "LAST" #'builtin-last)
   (make-core-builtin-subr "MEMBER" #'builtin-member)
   (make-core-builtin-subr "SUBST" #'builtin-subst)
   (make-core-builtin-subr "LISTP" #'autolisp-listp)
   (make-core-builtin-subr "VL-CONSP" #'builtin-vl-consp)
   (make-core-builtin-subr "VL-LIST*" #'builtin-vl-list*)
   (make-core-builtin-subr "NUMBERP" #'builtin-numberp)
   (make-core-builtin-subr "=" #'builtin-=)
   (make-core-builtin-subr "/=" #'builtin-/=)
   (make-core-builtin-subr "<" #'builtin-<)
   (make-core-builtin-subr "<=" #'builtin-<=)
   (make-core-builtin-subr ">" #'builtin->)
   (make-core-builtin-subr ">=" #'builtin->=)
   (make-core-builtin-subr "ABS" #'builtin-abs)
   (make-core-builtin-subr "FIX" #'builtin-fix)
   (make-core-builtin-subr "FLOAT" #'builtin-float)
   (make-core-builtin-subr "ZEROP" #'builtin-zerop)
   (make-core-builtin-subr "MINUSP" #'builtin-minusp)))

(defun find-core-builtin (name)
  (find name (core-builtins)
        :key #'autolisp-subr-name
        :test #'string=))

(defun install-core-builtins ()
  (dolist (builtin (core-builtins))
    (let ((symbol (intern-autolisp-symbol (autolisp-subr-name builtin))))
      (set-autolisp-symbol-function symbol builtin)))
  t)
