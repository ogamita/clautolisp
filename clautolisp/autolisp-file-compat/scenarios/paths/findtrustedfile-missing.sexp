(:name "findtrustedfile-missing"
 :description "Return nil when a file is not found in the trusted path list."
 :kind :builtin
 :classification :portable
 :tags (:builtin :paths :trusted :negative)
 :setup-files ((:type :directory :relative-path "trusted/"))
 :current-directory "cwd/"
 :trusted-paths ("trusted/")
 :builtin-name "FINDTRUSTEDFILE"
 :arguments ("missing.txt")
 :expected-value (:nil))
