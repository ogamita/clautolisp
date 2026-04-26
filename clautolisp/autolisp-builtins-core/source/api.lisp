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

(defun parse-open-external-format (string)
  (labels ((keywordize (name)
             (intern (string-upcase name) "KEYWORD")))
    (cond
      ((zerop (length string))
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
      (t
       (keywordize string)))))

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
  (require-number first-number "/")
  (dolist (argument more-numbers)
    (require-number argument "/"))
  (handler-case
      (arithmetic-result
       (if more-numbers
           (apply #'/ first-number more-numbers)
           (/ 1 first-number)))
    (division-by-zero ()
      (signal-builtin-host-error
       :division-by-zero
       "/"
       "Division by zero in /."))))

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

(defun builtin-open (filename mode &optional encoding)
  (let* ((path-string (autolisp-string-value (require-string filename "OPEN")))
         (mode-string (autolisp-string-value (require-string mode "OPEN")))
         (path (resolve-open-pathname path-string))
         (external-format (when encoding
                            (parse-open-external-format
                             (autolisp-string-value
                              (require-string encoding "OPEN"))))))
    (multiple-value-bind (direction if-exists if-does-not-exist)
        (open-direction-and-options mode-string)
      (handler-case
          (let ((stream (open path
                              :direction direction
                              :if-exists if-exists
                              :if-does-not-exist if-does-not-exist
                              :external-format (or external-format :default))))
            (if stream
                (make-autolisp-file stream path-string mode-string)
                nil))
        (error ()
          nil)))))

(defun builtin-findfile (filename)
  (let* ((value (autolisp-string-value (require-string filename "FINDFILE")))
         (located (search-path-list-for-file value (autolisp-support-paths))))
    (if located
        (make-autolisp-string located)
        nil)))

(defun builtin-findtrustedfile (filename)
  (let* ((value (autolisp-string-value (require-string filename "FINDTRUSTEDFILE")))
         (located (search-path-list-for-file value (autolisp-trusted-paths))))
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

(defun builtin-= (&rest arguments)
  (unless arguments
    (signal-builtin-argument-error
     :wrong-number-of-arguments
     "="
     "= expects at least one argument."))
  (let ((first-value (comparison-value (first arguments) "=")))
    (if (every (lambda (argument)
                 (equal first-value (comparison-value argument "=")))
               (rest arguments))
        (intern-autolisp-symbol "T")
        nil)))

(defun builtin-/= (&rest arguments)
  (unless arguments
    (signal-builtin-argument-error
     :wrong-number-of-arguments
     "/="
     "/= expects at least one argument."))
  (let ((values (mapcar (lambda (argument)
                          (comparison-value argument "/="))
                        arguments)))
    (if (= (length values)
           (length (remove-duplicates values :test #'equal)))
        (intern-autolisp-symbol "T")
        nil)))

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
