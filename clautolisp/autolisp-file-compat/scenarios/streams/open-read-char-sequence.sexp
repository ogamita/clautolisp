(:name "open-read-char-sequence"
 :description "Open a file and read successive character codes until EOF."
 :kind :builtin
 :classification :portable
 :tags (:builtin :stream :file-descriptor)
 :setup-files ((:relative-path "chars.txt" :input-text "AZ"))
 :steps ((:builtin-name "OPEN"
          :arguments ("chars.txt" "r")
          :bind "in")
         (:builtin-name "READ-CHAR"
          :arguments ((:ref "in"))
          :bind "first"
          :expected-value 65)
         (:builtin-name "READ-CHAR"
          :arguments ((:ref "in"))
          :bind "second"
          :expected-value 90)
         (:builtin-name "READ-CHAR"
          :arguments ((:ref "in"))
          :bind "eof"
          :expected-value (:nil))
         (:builtin-name "CLOSE"
          :arguments ((:ref "in"))))
 :result-ref "second"
 :expected-value 90)
