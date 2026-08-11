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
