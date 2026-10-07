(in-package #:clautolisp.autolisp-reader.internal)

(defun normalize-line-endings (text)
  (with-output-to-string (out)
    (loop
      with length = (length text)
      for index from 0 below length
      for ch = (char text index)
      do (cond
           ((char= ch #\Return)
            (write-char #\Newline out)
            (when (and (< (1+ index) length)
                       (char= (char text (1+ index)) #\Newline))
              (incf index)))
           (t
            (write-char ch out))))))

(define-condition clautolisp.autolisp-reader:source-decoding-error (error)
  ((pathname :initarg :pathname
             :reader clautolisp.autolisp-reader:source-decoding-error-pathname))
  (:report (lambda (condition stream)
             (format stream "~A: bytes that are not valid in the source encoding"
                     (clautolisp.autolisp-reader:source-decoding-error-pathname condition))))
  (:documentation
   "A source file whose bytes are not valid in its encoding, detected after the
host decoded it leniently. CCL's file streams replace an invalid byte sequence
by U+FFFD instead of signalling, where SBCL's signal a STREAM-DECODING-ERROR;
this condition makes the two hosts agree (the class name ends in
DECODING-ERROR, so the engine maps it to EX_DATAERR like the host's own)."))

(defun %octets-contain-utf-8-replacement-p (octets)
  "True when OCTETS hold the UTF-8 encoding of U+FFFD (EF BF BD) literally."
  (loop for i from 0 below (- (length octets) 2)
        thereis (and (= (aref octets i) #xEF)
                     (= (aref octets (1+ i)) #xBF)
                     (= (aref octets (+ i 2)) #xBD))))

(defun %check-lenient-decoding (path text)
  "Signal SOURCE-DECODING-ERROR when the host decoded PATH into TEXT by
replacing invalid bytes with U+FFFD -- a U+FFFD the file does not literally
contain (CCL; see SOURCE-DECODING-ERROR). Returns TEXT."
  (when (and (find (code-char #xFFFD) text)
             (not (%octets-contain-utf-8-replacement-p (%read-file-octets path))))
    (error 'clautolisp.autolisp-reader:source-decoding-error :pathname path))
  text)

(defun decode-and-normalize-stream (stream)
  (normalize-line-endings
   (with-output-to-string (out)
     (loop for ch = (read-char stream nil nil)
           while ch
           do (write-char ch out)))))

(defun %read-file-octets (path)
  (with-open-file (in path :element-type '(unsigned-byte 8))
    (let ((octets (make-array (file-length in) :element-type '(unsigned-byte 8))))
      (subseq octets 0 (read-sequence octets in)))))

(defun %strip-utf-8-bom (octets)
  (if (and (>= (length octets) 3)
           (= (aref octets 0) #xEF) (= (aref octets 1) #xBB) (= (aref octets 2) #xBF))
      (subseq octets 3)
      octets))

(defun decode-autocad-source-octets (octets policy)
  "OCTETS of a source file decoded as AutoCAD 2022's native LOAD does
(encoding-situations-cli-options experiment E1, job 16931781178):
POLICY :ANSI (LISPSYS 0) -- windows-1252, a leading UTF-8 BOM SKIPPED and
otherwise ignored (the UTF-8 bytes after it still read as windows-1252);
POLICY :UNICODE (LISPSYS 1 / 2) -- UTF-8, BOM or not, and a file that is
not valid UTF-8 read as windows-1252 instead (a fallback, not an error)."
  (let ((body (%strip-utf-8-bom octets)))
    (ecase policy
      (:ansi (babel:octets-to-string body :encoding :cp1252 :errorp nil))
      (:unicode
       (handler-case (babel:octets-to-string body :encoding :utf-8 :errorp t)
         (babel-encodings:character-decoding-error ()
           (babel:octets-to-string body :encoding :cp1252 :errorp nil)))))))

;;; --- OPEN under the AutoCAD dialects (autocad-open-encoding-lispsys) ------
;;; Measured on AutoCAD 2022 (E1, job 16980926802): at LISPSYS 1 / 2 a
;;; default (open f "r") reads a windows-1252, a UTF-8 and a UTF-8+BOM file
;;; alike (the BOM is not returned); (open f "r" "utf8") returns the BOM as
;;; U+FEFF and stops -- end of data -- at the first byte that is not UTF-8.

(defun utf-8-valid-prefix-length (octets)
  "The length of the longest prefix of OCTETS that is well-formed UTF-8
(RFC 3629: no overlong forms, no surrogates, nothing above U+10FFFF). A
sequence cut short by the end of OCTETS is not part of the prefix."
  (let ((length (length octets))
        (i 0))
    (flet ((continuation-p (k &optional (low #x80) (high #xBF))
             (and (< k length) (<= low (aref octets k) high))))
      (loop
        (when (>= i length) (return i))
        (let ((b (aref octets i)))
          (cond
            ((< b #x80) (incf i))
            ((<= #xC2 b #xDF)
             (if (continuation-p (+ i 1)) (incf i 2) (return i)))
            ((<= #xE0 b #xEF)
             (if (and (continuation-p (+ i 1)
                                      (if (= b #xE0) #xA0 #x80)
                                      (if (= b #xED) #x9F #xBF))
                      (continuation-p (+ i 2)))
                 (incf i 3)
                 (return i)))
            ((<= #xF0 b #xF4)
             (if (and (continuation-p (+ i 1)
                                      (if (= b #xF0) #x90 #x80)
                                      (if (= b #xF4) #x8F #xBF))
                      (continuation-p (+ i 2))
                      (continuation-p (+ i 3)))
                 (incf i 4)
                 (return i)))
            (t (return i))))))))

(defun autocad-open-read-encoding (path)
  "How AutoCAD 2022 at LISPSYS 1 / 2 decodes PATH for a default (open f
\"r\"): (values EXTERNAL-FORMAT SKIP-BOM-P). A UTF-8 BOM -> :UTF-8, the BOM
skipped; well-formed UTF-8 -> :UTF-8; anything else -> :CP1252 (the same
rule as its LOAD, DECODE-AUTOCAD-SOURCE-OCTETS :UNICODE). An unreadable
PATH -> :UTF-8 (the open that follows reports the failure)."
  (let ((octets (ignore-errors (%read-file-octets path))))
    (cond
      ((null octets) (values :utf-8 nil))
      ((and (>= (length octets) 3)
            (= (aref octets 0) #xEF) (= (aref octets 1) #xBB) (= (aref octets 2) #xBF))
       (values :utf-8 t))
      ((= (utf-8-valid-prefix-length octets) (length octets))
       (values :utf-8 nil))
      (t (values :cp1252 nil)))))

(defun autocad-strict-utf-8-text (path)
  "For AutoCAD's (open f \"r\" \"utf8\"): NIL when PATH is well-formed
UTF-8 (or unreadable) -- a plain :UTF-8 stream then does what AutoCAD does,
U+FEFF included -- else the text of its well-formed prefix, where AutoCAD's
reading stops."
  (let ((octets (ignore-errors (%read-file-octets path))))
    (when octets
      (let ((end (utf-8-valid-prefix-length octets)))
        (when (< end (length octets))
          (babel:octets-to-string octets :end end :encoding :utf-8))))))

(defun decode-and-normalize-file (path &key external-format source-policy)
  (when source-policy
    (return-from decode-and-normalize-file
      (normalize-line-endings
       (decode-autocad-source-octets (%read-file-octets path) source-policy))))
  ;; Goes through OPEN-WITH-EXTERNAL-FORMAT rather than WITH-OPEN-FILE so
  ;; that (load "f" "cp1252") reads the same bytes on every host — the
  ;; same hole OPEN had, and it would have been odd to close one and not
  ;; the other. WITH-OPEN-FILE would do here too, but it expands into
  ;; CL:OPEN by definition, so the fallback has to be spliced in by hand.
  (if external-format
      (let ((stream (open-with-external-format path
                                               :direction :input
                                               :external-format external-format)))
        (%check-lenient-decoding
         path (unwind-protect (decode-and-normalize-stream stream)
                (close stream))))
      (%check-lenient-decoding
       path (with-open-file (stream path
                                    :direction :input)
              (decode-and-normalize-stream stream)))))
