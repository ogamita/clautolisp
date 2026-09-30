;;;; -*- mode:lisp; coding:utf-8 -*-
;;;;
;;;; DIESEL -- the string-expression language behind (menucmd "M=...").
;;;;
;;;; system-variables.issue: the DATE / CDATE / TDCREATE / TDUPDATE sysvars
;;;; were readable but nothing consumed them the way AutoCAD programs do,
;;;; through DIESEL's EDTIME: (menucmd "M=$(edtime,$(getvar,date),DD MON YYYY)").
;;;; MENUCMD was a stub returning "".
;;;;
;;;; The function set, the quoting rule and the error strings follow
;;;; Autodesk's DIESEL reference (the spec documents only the MENUCMD entry
;;;; point and its edtime example). What that reference leaves open -- how a
;;;; non-integral result is printed, most visibly -- is measured by
;;;; probes/sources/probe-diesel.lsp, and follows this file until the runners
;;;; say otherwise. BricsCAD does not document the M= form of MENUCMD at all
;;;; (spec, menucmd Availability); clautolisp evaluates it in every dialect.

(in-package #:clautolisp.autolisp-builtins-core)

(defparameter *diesel-functions* (make-hash-table :test 'equal)
  "DIESEL function name (lower case) -> function of the evaluated argument
strings, returning the result string.")

(define-condition %diesel-bad-arguments (error) ()
  (:documentation "Signalled inside a DIESEL function whose arguments do not
fit; the call then renders as $(NAME,??)."))

;;; --- scanning ---------------------------------------------------------------

(defun %diesel-split-arguments (text start)
  "Scan the argument list of a $( call in TEXT from START (just after the
function name's opening `$('), up to its matching `)'. Returns (values
RAW-SEGMENTS END), END being the index after the `)', or NIL when the call
is not closed. Commas split only at depth 0 and outside double quotes;
nested $( ... ) and quoted text are kept whole, raw."
  (let ((depth 0) (in-quote nil) (segments '()) (seg-start start))
    (loop for i from start below (length text)
          for c = (char text i)
          do (cond
               (in-quote
                (when (char= c #\") (setf in-quote nil)))
               ((char= c #\") (setf in-quote t))
               ((and (char= c #\$) (< (1+ i) (length text))
                     (char= (char text (1+ i)) #\())
                (incf depth))
               ((char= c #\))
                (if (zerop depth)
                    (return-from %diesel-split-arguments
                      (values (nreverse (cons (subseq text seg-start i) segments))
                              (1+ i)))
                    (decf depth)))
               ((and (char= c #\,) (zerop depth))
                (push (subseq text seg-start i) segments)
                (setf seg-start (1+ i)))))
    nil))

(defun %diesel-unquote (text)
  "Remove DIESEL's literal quotes: text between double quotes is passed as
is, and \"\" inside quotes is one double quote."
  (with-output-to-string (out)
    (let ((in-quote nil) (i 0) (n (length text)))
      (loop while (< i n)
            do (let ((c (char text i)))
                 (cond
                   ((and in-quote (char= c #\") (< (1+ i) n) (char= (char text (1+ i)) #\"))
                    (write-char #\" out) (incf i))
                   ((char= c #\") (setf in-quote (not in-quote)))
                   (t (write-char c out))))
               (incf i)))))

(defun diesel-evaluate (text)
  "Evaluate every $(FUNCTION,ARG,...) in the DIESEL string TEXT, innermost
first; the text around the calls is copied. An unclosed call yields `$?'."
  (with-output-to-string (out)
    (let ((i 0) (n (length text)))
      (loop while (< i n)
            do (let ((c (char text i)))
                 (cond
                   ((and (char= c #\$) (< (1+ i) n) (char= (char text (1+ i)) #\())
                    (multiple-value-bind (segments end) (%diesel-split-arguments text (+ i 2))
                      (cond
                        ((null segments)
                         (write-string "$?" out)
                         (setf i n))
                        (t
                         (write-string (%diesel-call segments) out)
                         (setf i end)))))
                   (t (write-char c out) (incf i))))))))

(defun %diesel-call (segments)
  (let* ((name (string-trim " " (diesel-evaluate (first segments))))
         (args (mapcar (lambda (raw) (%diesel-unquote (diesel-evaluate raw)))
                       (rest segments)))
         (fn (gethash (string-downcase name) *diesel-functions*)))
    (cond
      ((null fn) (format nil "$(~A)??" name))
      (t (handler-case (funcall fn args)
           (error () (format nil "$(~A,??)" name)))))))

;;; --- values -----------------------------------------------------------------

(defun %diesel-numeric-text-p (text)
  "True when TEXT is a whole number: [sign] digits [. digits] [e [sign] digits]
-- at least one digit before the exponent. PARSE-AUTOLISP-REAL alone is
ATOF-like and reads \"a\" as 0, which would turn $(+,a) into 0 instead of
the documented $(+,??)."
  (let ((i 0) (n (length text)) (digits 0))
    (flet ((peek () (and (< i n) (char text i))))
      (when (member (peek) '(#\+ #\-)) (incf i))
      (loop while (and (peek) (digit-char-p (peek))) do (incf i) (incf digits))
      (when (eql (peek) #\.)
        (incf i)
        (loop while (and (peek) (digit-char-p (peek))) do (incf i) (incf digits)))
      (when (and (plusp digits) (member (peek) '(#\e #\E)))
        (incf i)
        (when (member (peek) '(#\+ #\-)) (incf i))
        (let ((exp-digits 0))
          (loop while (and (peek) (digit-char-p (peek))) do (incf i) (incf exp-digits))
          (when (zerop exp-digits) (return-from %diesel-numeric-text-p nil))))
      (and (plusp digits) (= i n)))))

(defun %diesel-number (text)
  (let* ((trimmed (string-trim " " text))
         (value (and (%diesel-numeric-text-p trimmed)
                     (ignore-errors (parse-autolisp-real trimmed)))))
    (unless value (error '%diesel-bad-arguments))
    value))

(defun %diesel-integer (text)
  (truncate (%diesel-number text)))

(defun %diesel-format-number (x)
  "A DIESEL numeric result: an integral value without a decimal point, any
other with up to 8 decimals and no trailing zeros. (Pending
probe-diesel.lsp: Autodesk's reference does not state the precision.)"
  (let ((x (coerce x 'double-float)))
    (if (and (< (abs x) 1d15) (= x (ftruncate x)))
        (format nil "~D" (truncate x))
        (let ((s (string-right-trim "0" (format nil "~,8F" x))))
          (string-right-trim "." s)))))

(defun %diesel-bool (flag) (if flag "1" "0"))

(defun %diesel-sysvar-text (value)
  (typecase value
    (null "")
    (integer (format nil "~D" value))
    (real (%diesel-format-number value))
    (autolisp-string (autolisp-string-value value))
    (string value)
    (cons (format nil "~{~A~^,~}" (mapcar #'%diesel-sysvar-text value)))
    (t (princ-to-string value))))

;;; --- edtime -----------------------------------------------------------------

(defun %julian->calendar (jd)
  "The Julian date JD (a DATE sysvar value: Julian Day Number + the day
fraction since local midnight) as (values YEAR MONTH DAY HOUR MINUTE
SECOND MILLISECOND DAY-OF-WEEK), DAY-OF-WEEK 0 = Monday."
  (let* ((jdn (floor jd))
         (ms (%round-half-away (* (- jd jdn) 86400000)))
         (a (+ jdn 32044))
         (b (floor (+ (* 4 a) 3) 146097))
         (c (- a (floor (* 146097 b) 4)))
         (d (floor (+ (* 4 c) 3) 1461))
         (e (- c (floor (* 1461 d) 4)))
         (m (floor (+ (* 5 e) 2) 153))
         (day (+ e (- (floor (+ (* 153 m) 2) 5)) 1))
         (month (+ m 3 (* -12 (floor m 10))))
         (year (+ (* 100 b) d -4800 (floor m 10))))
    (when (>= ms 86400000) (setf ms 86399999))
    (multiple-value-bind (hour rest) (floor ms 3600000)
      (multiple-value-bind (minute rest) (floor rest 60000)
        (multiple-value-bind (second msec) (floor rest 1000)
          (values year month day hour minute second msec (mod jdn 7)))))))

(defparameter *edtime-codes*
  '("DDDD" "DDD" "DD" "D" "MONTH" "MON" "MO" "MSEC" "MM" "M" "YYYY" "YY"
    "HH" "H" "SS" "AM/PM" "am/pm" "A/P" "a/p")
  "EDTIME picture codes, longest first where one is a prefix of another.")

(defun %edtime (jd picture)
  (multiple-value-bind (year month day hour minute second msec dow) (%julian->calendar jd)
    (let* ((twelve (or (search "AM/PM" picture) (search "am/pm" picture)
                       (search "A/P" picture) (search "a/p" picture)))
           (h (if twelve (let ((h12 (mod hour 12))) (if (zerop h12) 12 h12)) hour))
           (pm (>= hour 12))
           (days #("Monday" "Tuesday" "Wednesday" "Thursday" "Friday" "Saturday" "Sunday"))
           (months #("January" "February" "March" "April" "May" "June" "July"
                     "August" "September" "October" "November" "December")))
      (with-output-to-string (out)
        (let ((i 0) (n (length picture)))
          (loop while (< i n)
                do (let ((code (find-if (lambda (k)
                                          (and (<= (+ i (length k)) n)
                                               (string= k picture :start2 i :end2 (+ i (length k)))))
                                        *edtime-codes*)))
                     (cond
                       ((null code) (write-char (char picture i) out) (incf i))
                       (t
                        (write-string
                         (cond
                           ((string= code "DDDD") (aref days dow))
                           ((string= code "DDD") (subseq (aref days dow) 0 3))
                           ((string= code "DD") (format nil "~2,'0D" day))
                           ((string= code "D") (format nil "~D" day))
                           ((string= code "MONTH") (aref months (1- month)))
                           ((string= code "MON") (subseq (aref months (1- month)) 0 3))
                           ((string= code "MO") (format nil "~2,'0D" month))
                           ((string= code "M") (format nil "~D" month))
                           ((string= code "YYYY") (format nil "~4,'0D" year))
                           ((string= code "YY") (format nil "~2,'0D" (mod year 100)))
                           ((string= code "HH") (format nil "~2,'0D" h))
                           ((string= code "H") (format nil "~D" h))
                           ((string= code "MM") (format nil "~2,'0D" minute))
                           ((string= code "SS") (format nil "~2,'0D" second))
                           ((string= code "MSEC") (format nil "~3,'0D" msec))
                           ((string= code "AM/PM") (if pm "PM" "AM"))
                           ((string= code "am/pm") (if pm "pm" "am"))
                           ((string= code "A/P") (if pm "P" "A"))
                           ((string= code "a/p") (if pm "p" "a")))
                         out)
                        (incf i (length code)))))))))))

;;; --- the function table -------------------------------------------------------

(defmacro define-diesel-function (name (args) &body body)
  `(setf (gethash ,name *diesel-functions*)
         (lambda (,args) (declare (ignorable ,args)) ,@body)))

(defun %diesel-arity (args min &optional (max min))
  (unless (<= min (length args) max) (error '%diesel-bad-arguments)))

(defun %diesel-fold (args fn)
  (%diesel-arity args 1 9)
  (%diesel-format-number (reduce fn (mapcar #'%diesel-number args))))

(define-diesel-function "+" (args) (%diesel-fold args #'+))
(define-diesel-function "-" (args) (%diesel-fold args #'-))
(define-diesel-function "*" (args) (%diesel-fold args #'*))
(define-diesel-function "/" (args)
  (%diesel-arity args 1 9)
  (let ((nums (mapcar #'%diesel-number args)))
    (when (some #'zerop (rest nums)) (error '%diesel-bad-arguments))
    (%diesel-format-number (reduce #'/ nums))))

(macrolet ((compare (name fn)
             `(define-diesel-function ,name (args)
                (%diesel-arity args 2)
                (%diesel-bool (,fn (%diesel-number (first args)) (%diesel-number (second args)))))))
  (compare "=" =) (compare "<" <) (compare ">" >) (compare "<=" <=) (compare ">=" >=)
  (compare "!=" /=))

(macrolet ((bitwise (name fn)
             `(define-diesel-function ,name (args)
                (%diesel-arity args 1 9)
                (format nil "~D" (reduce #',fn (mapcar #'%diesel-integer args))))))
  (bitwise "and" logand) (bitwise "or" logior) (bitwise "xor" logxor))

(define-diesel-function "eq" (args)
  (%diesel-arity args 2)
  (%diesel-bool (string= (first args) (second args))))

(define-diesel-function "if" (args)
  (%diesel-arity args 2 3)
  (if (/= 0 (%diesel-number (first args))) (second args) (or (third args) "")))

(define-diesel-function "eval" (args)
  (%diesel-arity args 1)
  (diesel-evaluate (first args)))

(define-diesel-function "fix" (args)
  (%diesel-arity args 1)
  (format nil "~D" (%diesel-integer (first args))))

(define-diesel-function "strlen" (args)
  (%diesel-arity args 1)
  (format nil "~D" (length (first args))))

(define-diesel-function "upper" (args)
  (%diesel-arity args 1)
  (string-upcase (first args)))

(define-diesel-function "substr" (args)
  ;; $(substr,STRING,START[,LENGTH]), START 1-based.
  (%diesel-arity args 2 3)
  (let* ((s (first args))
         (start (1- (%diesel-integer (second args))))
         (len (if (third args) (%diesel-integer (third args)) (length s))))
    (when (minusp start) (error '%diesel-bad-arguments))
    (if (>= start (length s))
        ""
        (subseq s start (min (length s) (+ start (max 0 len)))))))

(define-diesel-function "index" (args)
  ;; $(index,WHICH,STRING): the WHICH-th (0-based) comma-separated item.
  (%diesel-arity args 2)
  (let ((items (uiop:split-string (second args) :separator ","))
        (k (%diesel-integer (first args))))
    (if (< -1 k (length items)) (nth k items) "")))

(define-diesel-function "nth" (args)
  ;; $(nth,WHICH,ARG0,...,ARG7)
  (%diesel-arity args 2 9)
  (let ((k (%diesel-integer (first args))))
    (if (< -1 k (length (rest args))) (nth k (rest args)) "")))

(define-diesel-function "getvar" (args)
  (%diesel-arity args 1)
  (let ((value (ignore-errors
                (host-getvar (%sysvar-host (current-evaluation-host)) (first args)))))
    (%diesel-sysvar-text value)))

(define-diesel-function "getenv" (args)
  (%diesel-arity args 1)
  (or (uiop:getenv (first args)) ""))

(define-diesel-function "rtos" (args)
  (%diesel-arity args 1 3)
  (autolisp-string-value
   (builtin-rtos (%diesel-number (first args))
                 (and (second args) (%diesel-integer (second args)))
                 (and (third args) (%diesel-integer (third args))))))

(define-diesel-function "angtos" (args)
  (%diesel-arity args 1 3)
  (autolisp-string-value
   (builtin-angtos (%diesel-number (first args))
                   (and (second args) (%diesel-integer (second args)))
                   (and (third args) (%diesel-integer (third args))))))

(define-diesel-function "edtime" (args)
  ;; $(edtime,TIME,PICTURE): TIME a Julian date (the DATE sysvar); 0 = now.
  (%diesel-arity args 2)
  (let ((jd (%diesel-number (first args))))
    (when (zerop jd)
      (setf jd (let ((v (ignore-errors
                         (host-getvar (%sysvar-host (current-evaluation-host)) "DATE"))))
                 (if (realp v) v (error '%diesel-bad-arguments)))))
    (%edtime jd (second args))))
