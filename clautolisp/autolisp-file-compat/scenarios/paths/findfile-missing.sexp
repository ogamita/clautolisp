(:name "findfile-missing"
 :description "Return nil when a file is not found in the support path list."
 :kind :builtin
 :classification :portable
 :tags (:builtin :paths :findfile :negative)
 :setup-files ((:type :directory :relative-path "support/"))
 :current-directory "cwd/"
 :support-paths ("support/")
 :builtin-name "FINDFILE"
 :arguments ("missing.txt")
 :expected-value (:nil))
