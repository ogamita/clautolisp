(in-package #:clautolisp.autolisp-mock-host)

;;;; Headless interaction-channel HAL methods on MockHost (Phase 12).
;;;;
;;;; Implements host-prompt, host-initget, host-getstring,
;;;; host-getint, host-getreal, host-getpoint, host-getcorner,
;;;; host-getdist, host-getangle, host-getorient, host-getkword.
;;;;
;;;; Input model
;;;;   The host's PROMPT-STREAM slot is a CL input stream supplied by
;;;;   the test harness or the CLI's --mock-input flag. Each get*
;;;;   call reads one logical line and parses it according to the
;;;;   target type. EOF returns nil (matching AutoLISP's cancellation
;;;;   convention).
;;;;
;;;; Output model
;;;;   The PROMPT and PROMPT-prefixing of get* writes to PROMPT-OUTPUT.
;;;;   Tests inspect that stream's contents.
;;;;
;;;; initget state
;;;;   AutoLISP's initget controls the *next* get* call only; it is
;;;;   reset after consumption. We model that with two slots stored
;;;;   on the host: pending-initget-bits and pending-initget-keywords.

;;; --- Helpers ----------------------------------------------------

(defclass initget-state ()
  ((bits     :initarg :bits     :initform 0   :accessor initget-bits)
   (keywords :initarg :keywords :initform '() :accessor initget-keywords))
  (:documentation "Captured INITGET arguments awaiting consumption
by the next get* call."))

(defun mock-host-take-initget (host)
  "Pop the pending initget state off HOST, returning its bits and
keyword list. Subsequent calls return defaults until another
initget is issued."
  (let ((state (mock-host-pending-initget host)))
    (setf (mock-host-pending-initget host) nil)
    (values (if state (initget-bits state) 0)
            (if state (initget-keywords state) '()))))

(defun mock-host-write-prompt (host string)
  (let ((sink (mock-host-prompt-output host)))
    (when (and string sink)
      (write-string string sink)
      ;; When the sink is a live terminal (interactive REPL) the prompt
      ;; must reach the screen before the following blocking read; on a
      ;; string-output-stream (the deterministic test path) this is a
      ;; harmless no-op.
      (finish-output sink))))

(defun read-prompt-line (host)
  "Read one line from HOST's prompt-stream, returning the line as a
CL string or :eof on end of stream / when no input was configured."
  (let ((stream (mock-host-prompt-stream host)))
    (cond
      ((null stream) :eof)
      (t (let ((line (read-line stream nil :eof)))
           line)))))

(defun parse-real (text)
  (let ((trimmed (string-trim '(#\Space #\Tab #\Return) text)))
    (handler-case
        (let ((value (with-input-from-string (s trimmed)
                       (read s nil nil))))
          (and (numberp value) (coerce value 'double-float)))
      (error () nil))))

(defun parse-integer-token (text)
  (let ((trimmed (string-trim '(#\Space #\Tab #\Return) text)))
    (handler-case (parse-integer trimmed) (error () nil))))

(defun %angle-number-char-p (c)
  "True for the characters that make up a numeric magnitude in an
angle expression: digits, a decimal point, and a rational slash. The
CL reader turns \"4/3\" straight into the ratio 4/3, so we let those
tokens flow through unchanged."
  (or (digit-char-p c) (char= c #\.) (char= c #\/)))

(defun parse-angle (text)
  "Parse an angle from TEXT and return its value in RADIANS as a
double-float, or NIL when TEXT is not a recognizable angle.

Accepted forms (case-insensitive, whitespace-flexible):
  - a bare number            -> taken as radians (\"0.5\", back-compat)
  - radians  rd|rad|radian(s) -> \"2.34 rd\", \"pi rd\", \"2pi rd\",
                                 \"4/3 pi rd\", \"-3/2 pi rd\"
  - degrees  deg|degree(s)    -> \"45 deg\", \"45.3321 degree\"
  - D-M-S    ' = minutes, \" = seconds, summed with the degrees:
                                 \"43 deg 23' 15\\\"\" (markers in any order)

A magnitude may be an integer, decimal, or rational (a/b), optionally
followed by PI (\"pi\", \"2pi\", \"4/3 pi\") which multiplies it by pi and
makes the term a radian term. Degree, minute and second terms are
summed as degrees; radian and pi terms are summed as radians; the two
running totals are combined at the end."
  (let ((s (string-downcase
            (string-trim '(#\Space #\Tab #\Return #\Newline) text))))
    (when (plusp (length s))
      (let ((i 0) (n (length s))
            (components '()) (pending nil) (bad nil))
        (loop while (and (< i n) (not bad)) do
          (let ((c (char s i)))
            (cond
              ((member c '(#\Space #\Tab)) (incf i))
              ;; numeric magnitude, with an optional leading sign
              ((or (%angle-number-char-p c)
                   (and (member c '(#\+ #\-))
                        (< (1+ i) n)
                        (%angle-number-char-p (char s (1+ i)))))
               (let ((start i))
                 (when (member c '(#\+ #\-)) (incf i))
                 (loop while (and (< i n) (%angle-number-char-p (char s i)))
                       do (incf i))
                 (let ((value (ignore-errors
                               ;; read decimals as double-float so
                               ;; "45.3321" keeps full precision.
                               (let ((*read-default-float-format* 'double-float))
                                 (read-from-string (subseq s start i) nil nil)))))
                   (if (realp value) (setf pending value) (setf bad t)))))
              ;; minute / second markers
              ((char= c #\') (push (cons (or pending 1) :min) components)
                             (setf pending nil) (incf i))
              ((char= c #\") (push (cons (or pending 1) :sec) components)
                             (setf pending nil) (incf i))
              ;; alphabetic unit word
              ((alpha-char-p c)
               (let ((start i))
                 (loop while (and (< i n) (alpha-char-p (char s i))) do (incf i))
                 (let ((word (subseq s start i)))
                   (cond
                     ((member word '("deg" "degree" "degrees" "d") :test #'string=)
                      (push (cons (or pending 1) :deg) components) (setf pending nil))
                     ((member word '("rad" "radian" "radians" "rd" "r") :test #'string=)
                      ;; A magnitude before rd/rad IS the radian value; a
                      ;; bare rd/rad after a pi term just confirms the unit.
                      (when pending
                        (push (cons pending :rad) components) (setf pending nil)))
                     ((string= word "pi")
                      (push (cons (or pending 1) :pi) components) (setf pending nil))
                     (t (setf bad t))))))
              (t (setf bad t)))))
        (cond
          (bad nil)
          ;; a lone number with no unit: radians, preserving the old
          ;; MockHost contract.
          ((and (null components) pending) (coerce pending 'double-float))
          ((null components) nil)
          ;; a number left dangling with no unit alongside united terms
          ;; is ambiguous -> reject rather than guess.
          (pending nil)
          (t (let ((total-deg 0) (total-rad 0))
               (dolist (comp components)
                 (destructuring-bind (mag . unit) comp
                   (ecase unit
                     (:deg (incf total-deg mag))
                     (:min (incf total-deg (/ mag 60)))
                     (:sec (incf total-deg (/ mag 3600)))
                     (:rad (incf total-rad mag))
                     (:pi  (incf total-rad (* mag pi))))))
               (coerce (+ total-rad (* total-deg (/ pi 180))) 'double-float))))))))

(defun parse-coordinate-list (text)
  "Parse a whitespace-separated list of numbers from TEXT. Returns
nil if fewer than 2 valid numbers are present or any token is
non-numeric."
  (let ((coords '())
        (failed nil))
    (with-input-from-string (s (string-trim '(#\Space #\Tab #\Return) text))
      (loop for token = (read s nil nil)
            while token
            do (cond
                 ((numberp token)
                  (push (coerce token 'double-float) coords))
                 (t (setf failed t) (loop-finish)))))
    (let ((result (nreverse coords)))
      (cond
        (failed nil)
        ((< (length result) 2) nil)
        ((= (length result) 2) (append result (list 0.0d0)))
        ((= (length result) 3) result)
        (t (subseq result 0 3))))))

;;; --- Method definitions -----------------------------------------

(defmethod host-prompt ((host mock-host) string)
  (let ((text (etypecase string
                (clautolisp.autolisp-runtime:autolisp-string
                 (clautolisp.autolisp-runtime:autolisp-string-value string))
                (string string))))
    (mock-host-write-prompt host text)
    nil))

(defmethod host-initget ((host mock-host) bits keywords)
  (setf (mock-host-pending-initget host)
        (make-instance 'initget-state
                       :bits (or bits 0)
                       :keywords (or keywords '())))
  nil)

(defmethod host-getstring ((host mock-host) prompt &key controls)
  (declare (ignore controls))
  (multiple-value-bind (bits kwords) (mock-host-take-initget host)
    (declare (ignore bits kwords))
    (when prompt (host-prompt host prompt))
    (let ((line (read-prompt-line host)))
      (cond
        ((eq line :eof) nil)
        (t (clautolisp.autolisp-runtime:make-autolisp-string line))))))

(defmethod host-getint ((host mock-host) prompt &key controls)
  (declare (ignore controls))
  (multiple-value-bind (bits kwords) (mock-host-take-initget host)
    (declare (ignore bits kwords))
    (when prompt (host-prompt host prompt))
    (let ((line (read-prompt-line host)))
      (cond
        ((eq line :eof) nil)
        (t (parse-integer-token line))))))

(defmethod host-getreal ((host mock-host) prompt &key controls)
  (declare (ignore controls))
  (multiple-value-bind (bits kwords) (mock-host-take-initget host)
    (declare (ignore bits kwords))
    (when prompt (host-prompt host prompt))
    (let ((line (read-prompt-line host)))
      (cond
        ((eq line :eof) nil)
        (t (parse-real line))))))

(defmethod host-getpoint ((host mock-host) prompt &key base controls)
  (declare (ignore base controls))
  (multiple-value-bind (bits kwords) (mock-host-take-initget host)
    (declare (ignore bits kwords))
    (when prompt (host-prompt host prompt))
    (let ((line (read-prompt-line host)))
      (cond
        ((eq line :eof) nil)
        (t (parse-coordinate-list line))))))

(defmethod host-getcorner ((host mock-host) prompt &key base controls)
  (declare (ignore base))
  (host-getpoint host prompt :controls controls))

(defmethod host-getdist ((host mock-host) prompt &key base controls)
  (declare (ignore base controls))
  (multiple-value-bind (bits kwords) (mock-host-take-initget host)
    (declare (ignore bits kwords))
    (when prompt (host-prompt host prompt))
    (let ((line (read-prompt-line host)))
      (cond
        ((eq line :eof) nil)
        (t (parse-real line))))))

(defmethod host-getangle ((host mock-host) prompt &key base controls)
  ;; Parse the entered angle and return it in RADIANS. A bare number is
  ;; radians (MockHost's dialect-neutral default); an explicit unit
  ;; (deg / rd) or a D-M-S expression is honored -- see PARSE-ANGLE.
  (declare (ignore base controls))
  (multiple-value-bind (bits kwords) (mock-host-take-initget host)
    (declare (ignore bits kwords))
    (when prompt (host-prompt host prompt))
    (let ((line (read-prompt-line host)))
      (cond
        ((eq line :eof) nil)
        (t (parse-angle line))))))

(defmethod host-getorient ((host mock-host) prompt &key base controls)
  (host-getangle host prompt :base base :controls controls))

(defmethod host-getkword ((host mock-host) prompt &key controls)
  (declare (ignore controls))
  (multiple-value-bind (bits kwords) (mock-host-take-initget host)
    (declare (ignore bits))
    (when prompt (host-prompt host prompt))
    (let ((line (read-prompt-line host)))
      (cond
        ((eq line :eof) nil)
        (t
         (let ((trimmed (string-trim '(#\Space #\Tab #\Return) line)))
           (cond
             ((null kwords)
              (clautolisp.autolisp-runtime:make-autolisp-string trimmed))
             (t
              (loop for keyword in kwords
                    when (string-equal keyword trimmed)
                      return (clautolisp.autolisp-runtime:make-autolisp-string keyword)
                    finally (return nil))))))))))
