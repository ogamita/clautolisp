(:name "open-current-directory-relative"
 :description "Resolve relative OPEN paths against the configured AutoLISP current directory."
 :kind :builtin
 :classification :portable
 :tags (:builtin :stream :file-descriptor :current-directory)
 :current-directory "cwd/"
 :steps ((:builtin-name "OPEN"
          :arguments ("relative.txt" "w")
          :bind "out")
         (:builtin-name "WRITE-LINE"
          :arguments ("alpha" (:ref "out")))
         (:builtin-name "CLOSE"
          :arguments ((:ref "out")))
         (:builtin-name "OPEN"
          :arguments ("relative.txt" "r")
          :bind "in")
         (:builtin-name "READ-LINE"
          :arguments ((:ref "in"))
          :bind "line")
         (:builtin-name "CLOSE"
          :arguments ((:ref "in"))))
 :result-ref "line"
 :expected-value (:string "alpha")
 :artifact-relative-path "cwd/relative.txt"
 :expected-artifact-exists-p t
 :expected-text "alpha
")
