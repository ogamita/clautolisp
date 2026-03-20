(:name "open-append-read-lines"
 :description "Append a line to an existing file, then read successive lines back."
 :kind :builtin
 :classification :portable
 :tags (:builtin :stream :file-descriptor :append)
 :setup-files ((:relative-path "sample.txt" :input-text "alpha
"))
 :steps ((:builtin-name "OPEN"
          :arguments ("sample.txt" "a")
          :bind "out")
         (:builtin-name "WRITE-LINE"
          :arguments ("beta" (:ref "out")))
         (:builtin-name "CLOSE"
          :arguments ((:ref "out")))
         (:builtin-name "OPEN"
          :arguments ("sample.txt" "r")
          :bind "in")
         (:builtin-name "READ-LINE"
          :arguments ((:ref "in"))
          :bind "first"
          :expected-value (:string "alpha"))
         (:builtin-name "READ-LINE"
          :arguments ((:ref "in"))
          :bind "second"
          :expected-value (:string "beta"))
         (:builtin-name "READ-LINE"
          :arguments ((:ref "in"))
          :bind "eof"
          :expected-value (:nil))
         (:builtin-name "CLOSE"
          :arguments ((:ref "in"))))
 :result-ref "second"
 :expected-value (:string "beta")
 :artifact-relative-path "sample.txt"
 :expected-artifact-exists-p t
 :expected-text "alpha
beta
")
