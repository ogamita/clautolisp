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
    (when (and string sink) (write-string string sink))))

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
  ;; Headless: same as getreal, but the result is taken as radians.
  ;; Real AutoCAD interprets numeric input under the active angle
  ;; mode (UNITS); MockHost is dialect-neutral and returns radians.
  (declare (ignore base controls))
  (multiple-value-bind (bits kwords) (mock-host-take-initget host)
    (declare (ignore bits kwords))
    (when prompt (host-prompt host prompt))
    (let ((line (read-prompt-line host)))
      (cond
        ((eq line :eof) nil)
        (t (parse-real line))))))

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
