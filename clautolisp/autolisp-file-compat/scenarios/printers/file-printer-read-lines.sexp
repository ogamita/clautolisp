(:name "file-printer-read-lines"
 :description "Write multiple printer forms to a file and read them back line by line."
 :kind :builtin
 :classification :portable
 :tags (:builtin :printer :stream :file-descriptor)
 :steps ((:builtin-name "OPEN"
          :arguments ("lines.txt" "w")
          :bind "out")
         (:builtin-name "PRINC"
          :arguments ("alpha" (:ref "out")))
         (:builtin-name "TERPRI"
          :arguments ((:ref "out")))
         (:builtin-name "PRIN1"
          :arguments ("beta" (:ref "out")))
         (:builtin-name "TERPRI"
          :arguments ((:ref "out")))
         (:builtin-name "CLOSE"
          :arguments ((:ref "out")))
         (:builtin-name "OPEN"
          :arguments ("lines.txt" "r")
          :bind "in")
         (:builtin-name "READ-LINE"
          :arguments ((:ref "in"))
          :bind "first"
          :expected-value (:string "alpha"))
         (:builtin-name "READ-LINE"
          :arguments ((:ref "in"))
          :bind "second"
          :expected-value (:string "\"beta\""))
         (:builtin-name "READ-LINE"
          :arguments ((:ref "in"))
          :bind "eof"
          :expected-value (:nil))
         (:builtin-name "CLOSE"
          :arguments ((:ref "in"))))
 :result-ref "second"
 :expected-value (:string "\"beta\"")
 :artifact-relative-path "lines.txt"
 :expected-artifact-exists-p t
 :expected-text "alpha
\"beta\"
")
