(:name "open-append-read-lines-utf8"
 :description "Append UTF-8 text with an explicit encoding and read the lines back."
 :kind :builtin
 :classification :portable
 :tags (:builtin :stream :file-descriptor :append :encoding :utf8)
 :setup-files ((:relative-path "utf8.txt"
                :external-format :utf-8
                :input-text "déjà
"))
 :steps ((:builtin-name "OPEN"
          :arguments ("utf8.txt" "a" "utf-8")
          :bind "out")
         (:builtin-name "WRITE-LINE"
          :arguments ("vu" (:ref "out")))
         (:builtin-name "CLOSE"
          :arguments ((:ref "out")))
         (:builtin-name "OPEN"
          :arguments ("utf8.txt" "r" "utf-8")
          :bind "in")
         (:builtin-name "READ-LINE"
          :arguments ((:ref "in"))
          :bind "first"
          :expected-value (:string "déjà"))
         (:builtin-name "READ-LINE"
          :arguments ((:ref "in"))
          :bind "second"
          :expected-value (:string "vu"))
         (:builtin-name "READ-LINE"
          :arguments ((:ref "in"))
          :bind "eof"
          :expected-value (:nil))
         (:builtin-name "CLOSE"
          :arguments ((:ref "in"))))
 :result-ref "second"
 :expected-value (:string "vu")
 :artifact-relative-path "utf8.txt"
 :expected-artifact-exists-p t
 :expected-text "déjà
vu
")
