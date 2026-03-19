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

(defun decode-and-normalize-file (path &key external-format)
  (if external-format
      (with-open-file (stream path
                              :direction :input
                              :external-format external-format)
        (decode-and-normalize-stream stream))
      (with-open-file (stream path
                              :direction :input)
        (decode-and-normalize-stream stream))))
