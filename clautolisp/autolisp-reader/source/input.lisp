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
        (unwind-protect (decode-and-normalize-stream stream)
          (close stream)))
      (with-open-file (stream path
                              :direction :input)
        (decode-and-normalize-stream stream))))
