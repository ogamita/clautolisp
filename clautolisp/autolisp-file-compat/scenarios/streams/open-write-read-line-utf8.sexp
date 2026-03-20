(:name "open-write-read-line-utf8"
 :description "Write and read UTF-8 text through OPEN's explicit encoding argument."
 :kind :builtin
 :classification :portable
 :tags (:builtin :stream :file-descriptor :encoding :utf8)
 :steps ((:builtin-name "OPEN"
          :arguments ("utf8.txt" "w" "utf-8")
          :bind "out")
         (:builtin-name "WRITE-LINE"
          :arguments ("déjà vu" (:ref "out")))
         (:builtin-name "CLOSE"
          :arguments ((:ref "out")))
         (:builtin-name "OPEN"
          :arguments ("utf8.txt" "r" "utf-8")
          :bind "in")
         (:builtin-name "READ-LINE"
          :arguments ((:ref "in"))
          :bind "line")
         (:builtin-name "CLOSE"
          :arguments ((:ref "in"))))
 :result-ref "line"
 :expected-value (:string "déjà vu")
 :artifact-relative-path "utf8.txt"
 :expected-artifact-exists-p t
 :expected-text "déjà vu
")
