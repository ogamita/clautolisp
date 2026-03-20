(:name "open-write-char-read-char"
 :description "Write character codes through a file descriptor, then read them back."
 :kind :builtin
 :classification :portable
 :tags (:builtin :stream :file-descriptor :character)
 :steps ((:builtin-name "OPEN"
          :arguments ("chars.txt" "w")
          :bind "out")
         (:builtin-name "WRITE-CHAR"
          :arguments (65 (:ref "out")))
         (:builtin-name "WRITE-CHAR"
          :arguments (90 (:ref "out")))
         (:builtin-name "CLOSE"
          :arguments ((:ref "out")))
         (:builtin-name "OPEN"
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
 :expected-value 90
 :artifact-relative-path "chars.txt"
 :expected-artifact-exists-p t
 :expected-text "AZ")
