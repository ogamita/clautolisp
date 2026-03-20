(:name "open-current-directory-subdir-backslash"
 :description "Resolve a backslash-delimited relative subpath against the configured AutoLISP current directory."
 :kind :builtin
 :classification :portable
 :tags (:builtin :stream :file-descriptor :current-directory :backslash)
 :setup-files ((:type :directory :relative-path "cwd/")
               (:type :directory :relative-path "cwd/nested/"))
 :current-directory "cwd/"
 :steps ((:builtin-name "OPEN"
          :arguments ("nested\\note.txt" "w")
          :bind "out")
         (:builtin-name "WRITE-LINE"
          :arguments ("alpha" (:ref "out")))
         (:builtin-name "CLOSE"
          :arguments ((:ref "out")))
         (:builtin-name "OPEN"
          :arguments ("nested\\note.txt" "r")
          :bind "in")
         (:builtin-name "READ-LINE"
          :arguments ((:ref "in"))
          :bind "line")
         (:builtin-name "CLOSE"
          :arguments ((:ref "in"))))
 :result-ref "line"
 :expected-value (:string "alpha")
 :artifact-relative-path "cwd/nested/note.txt"
 :expected-artifact-exists-p t
 :expected-text "alpha
")
