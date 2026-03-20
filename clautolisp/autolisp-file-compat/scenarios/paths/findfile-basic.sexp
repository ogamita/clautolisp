(:name "findfile-basic"
 :description "Locate a file through the configured support path list."
 :kind :builtin
 :classification :portable
 :tags (:builtin :paths :findfile)
 :setup-files ((:type :directory :relative-path "support/")
               (:relative-path "support/example.txt" :input-text "hello"))
 :current-directory "cwd/"
 :support-paths ("support/")
 :builtin-name "FINDFILE"
 :arguments ("example.txt")
 :expected-value (:workspace-relative "support/example.txt"))
