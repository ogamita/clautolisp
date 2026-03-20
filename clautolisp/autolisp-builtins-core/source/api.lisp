(in-package #:clautolisp.autolisp-builtins-core)

(defparameter *core-builtin-names*
  '("TYPE" "NULL" "NOT" "ATOM" "VL-SYMBOLP" "VL-SYMBOL-NAME" "VL-SYMBOL-VALUE"
    "+" "-" "*" "/" "1+" "1-" "MAX" "MIN" "REM" "GCD" "LCM" "~" "LOGAND"
    "LOGIOR" "LSH" "STRCAT" "STRLEN" "SUBSTR" "ASCII" "CHR"
    "OPEN" "CLOSE" "READ-LINE" "READ-CHAR" "WRITE-LINE" "WRITE-CHAR"
    "FINDFILE" "FINDTRUSTEDFILE" "VL-DIRECTORY-FILES" "VL-FILE-DIRECTORY-P"
    "VL-FILENAME-BASE" "VL-FILENAME-DIRECTORY" "VL-FILENAME-EXTENSION"
    "VL-FILE-DELETE" "VL-FILE-RENAME" "VL-FILE-SIZE" "VL-MKDIR"
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

(defun require-string (object operator-name)
  (unless (typep object 'autolisp-string)
    (error "~A expects an AutoLISP string, got ~S." operator-name object))
  object)

(defun require-file (object operator-name)
  (unless (typep object 'autolisp-file)
    (error "~A expects an AutoLISP file descriptor, got ~S." operator-name object))
  object)

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
        (error "~A expects a valid directory pathname, got ~S."
               operator-name directory-string)))))

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
       (error "VL-DIRECTORY-FILES selector must be -1, 0, or 1, got ~S."
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
     (error "OPEN mode must be one of \"r\", \"w\", or \"a\", got ~S." mode))))

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
    (error "~A expects a 32-bit AutoLISP integer, got ~S." operator-name object))
  object)

(defun builtin-rem (first-number second-number)
  (arithmetic-result
   (rem (require-int32 first-number "REM")
        (require-int32 second-number "REM"))))

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
      (error "SUBSTR expects a positive 1-based start index, got ~S." start))
    (when (and length (<= (require-int32 length "SUBSTR") 0))
      (error "SUBSTR length must be positive, got ~S." length))
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
      (error "ASCII expects a non-empty string."))
    (char-code (char value 0))))

(defun builtin-chr (code)
  (let ((character (code-char (require-int32 code "CHR"))))
    (unless character
      (error "CHR code does not designate a valid character: ~S." code))
    (make-autolisp-string (string character))))

(defun builtin-open (filename mode &optional encoding)
  (declare (ignore encoding))
  (let* ((path-string (autolisp-string-value (require-string filename "OPEN")))
         (mode-string (autolisp-string-value (require-string mode "OPEN")))
         (path (resolve-open-pathname path-string)))
    (multiple-value-bind (direction if-exists if-does-not-exist)
        (open-direction-and-options mode-string)
      (handler-case
          (let ((stream (open path
                              :direction direction
                              :if-exists if-exists
                              :if-does-not-exist if-does-not-exist
                              :external-format :default)))
            (if stream
                (make-autolisp-file stream path-string mode-string)
                nil))
        (file-error ()
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

(defun builtin-read-line (file)
  (let ((stream (autolisp-file-stream (require-file file "READ-LINE"))))
    (unless stream
      (error "READ-LINE expects an open file descriptor."))
    (let ((line (read-line stream nil nil)))
      (if line
          (make-autolisp-string line)
          nil))))

(defun builtin-read-char (&optional file)
  (if file
      (let ((stream (autolisp-file-stream (require-file file "READ-CHAR"))))
        (unless stream
          (error "READ-CHAR expects an open file descriptor."))
        (let ((character (read-char stream nil nil)))
          (if character
              (char-code character)
              nil)))
      (error "READ-CHAR without a file descriptor is not implemented yet.")))

(defun builtin-write-line (string &optional file)
  (let ((value (autolisp-string-value (require-string string "WRITE-LINE"))))
    (if file
        (let ((stream (autolisp-file-stream (require-file file "WRITE-LINE"))))
          (unless stream
            (error "WRITE-LINE expects an open file descriptor."))
          (write-line value stream)
          string)
        (progn
          (write-line value *standard-output*)
          string))))

(defun builtin-write-char (char-code &optional file)
  (let ((character (code-char (require-int32 char-code "WRITE-CHAR"))))
    (unless character
      (error "WRITE-CHAR code does not designate a valid character: ~S." char-code))
    (if file
        (let ((stream (autolisp-file-stream (require-file file "WRITE-CHAR"))))
          (unless stream
            (error "WRITE-CHAR expects an open file descriptor."))
          (write-char character stream)
          char-code)
        (progn
          (write-char character *standard-output*)
          char-code))))

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
   (make-autolisp-subr "1+" #'builtin-1+)
   (make-autolisp-subr "1-" #'builtin-1-)
   (make-autolisp-subr "MAX" #'builtin-max)
   (make-autolisp-subr "MIN" #'builtin-min)
   (make-autolisp-subr "REM" #'builtin-rem)
   (make-autolisp-subr "GCD" #'builtin-gcd)
   (make-autolisp-subr "LCM" #'builtin-lcm)
   (make-autolisp-subr "~" #'builtin-~)
   (make-autolisp-subr "LOGAND" #'builtin-logand)
   (make-autolisp-subr "LOGIOR" #'builtin-logior)
   (make-autolisp-subr "LSH" #'builtin-lsh)
   (make-autolisp-subr "STRCAT" #'builtin-strcat)
   (make-autolisp-subr "STRLEN" #'builtin-strlen)
   (make-autolisp-subr "SUBSTR" #'builtin-substr)
   (make-autolisp-subr "ASCII" #'builtin-ascii)
   (make-autolisp-subr "CHR" #'builtin-chr)
   (make-autolisp-subr "OPEN" #'builtin-open)
   (make-autolisp-subr "CLOSE" #'builtin-close)
   (make-autolisp-subr "READ-LINE" #'builtin-read-line)
   (make-autolisp-subr "READ-CHAR" #'builtin-read-char)
   (make-autolisp-subr "WRITE-LINE" #'builtin-write-line)
   (make-autolisp-subr "WRITE-CHAR" #'builtin-write-char)
   (make-autolisp-subr "FINDFILE" #'builtin-findfile)
   (make-autolisp-subr "FINDTRUSTEDFILE" #'builtin-findtrustedfile)
   (make-autolisp-subr "VL-DIRECTORY-FILES" #'builtin-vl-directory-files)
   (make-autolisp-subr "VL-FILE-DIRECTORY-P" #'builtin-vl-file-directory-p)
   (make-autolisp-subr "VL-FILENAME-BASE" #'builtin-vl-filename-base)
   (make-autolisp-subr "VL-FILENAME-DIRECTORY" #'builtin-vl-filename-directory)
   (make-autolisp-subr "VL-FILENAME-EXTENSION" #'builtin-vl-filename-extension)
   (make-autolisp-subr "VL-FILE-DELETE" #'builtin-vl-file-delete)
   (make-autolisp-subr "VL-FILE-RENAME" #'builtin-vl-file-rename)
   (make-autolisp-subr "VL-FILE-SIZE" #'builtin-vl-file-size)
   (make-autolisp-subr "VL-MKDIR" #'builtin-vl-mkdir)
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
