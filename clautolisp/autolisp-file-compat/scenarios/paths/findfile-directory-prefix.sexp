(:name "findfile-directory-prefix"
 :description "Return nil when FINDFILE is given a filename with a directory prefix."
 :kind :builtin
 :classification :portable
 :tags (:builtin :paths :findfile :negative)
 :setup-files ((:type :directory :relative-path "support/")
               (:type :directory :relative-path "support/nested/")
               (:relative-path "support/nested/example.txt" :input-text "hello"))
 :current-directory "cwd/"
 :support-paths ("support/")
 :builtin-name "FINDFILE"
 :arguments ("nested/example.txt")
 :expected-value (:nil))
