(:name "open-write-read-line-basic"
 :description "Open a file, write a line, reopen it, and read the line back."
 :kind :builtin
 :classification :portable
 :tags (:builtin :stream :file-descriptor)
 :steps ((:builtin-name "OPEN"
          :arguments ("sample.txt" "w")
          :bind "out")
         (:builtin-name "WRITE-LINE"
          :arguments ("alpha" (:ref "out")))
         (:builtin-name "CLOSE"
          :arguments ((:ref "out")))
         (:builtin-name "OPEN"
          :arguments ("sample.txt" "r")
          :bind "in")
         (:builtin-name "READ-LINE"
          :arguments ((:ref "in"))
          :bind "line")
         (:builtin-name "CLOSE"
          :arguments ((:ref "in"))))
 :result-ref "line"
 :expected-value (:string "alpha")
 :artifact-relative-path "sample.txt"
 :expected-artifact-exists-p t
 :expected-text "alpha
")
