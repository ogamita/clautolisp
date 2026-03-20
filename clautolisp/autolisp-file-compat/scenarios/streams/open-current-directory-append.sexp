(:name "open-current-directory-append"
 :description "Append to a relative file through the configured AutoLISP current directory and read the lines back."
 :kind :builtin
 :classification :portable
 :tags (:builtin :stream :file-descriptor :current-directory :append)
 :setup-files ((:type :directory :relative-path "cwd/")
               (:relative-path "cwd/log.txt"
                :input-text "alpha
"))
 :current-directory "cwd/"
 :steps ((:builtin-name "OPEN"
          :arguments ("log.txt" "a")
          :bind "out")
         (:builtin-name "WRITE-LINE"
          :arguments ("beta" (:ref "out")))
         (:builtin-name "CLOSE"
          :arguments ((:ref "out")))
         (:builtin-name "OPEN"
          :arguments ("log.txt" "r")
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
 :artifact-relative-path "cwd/log.txt"
 :expected-artifact-exists-p t
 :expected-text "alpha
beta
")
