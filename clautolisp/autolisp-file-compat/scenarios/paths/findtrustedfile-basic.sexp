(:name "findtrustedfile-basic"
 :description "Locate a file through the configured trusted path list."
 :kind :builtin
 :classification :portable
 :tags (:builtin :paths :trusted)
 :setup-files ((:type :directory :relative-path "trusted/")
               (:relative-path "trusted/secure.txt" :input-text "secure"))
 :current-directory "cwd/"
 :trusted-paths ("trusted/")
 :builtin-name "FINDTRUSTEDFILE"
 :arguments ("secure.txt")
 :expected-value (:workspace-relative "trusted/secure.txt"))
