(:name "findtrustedfile-directory-prefix"
 :description "Return nil when FINDTRUSTEDFILE is given a filename with a directory prefix."
 :kind :builtin
 :classification :portable
 :tags (:builtin :paths :trusted :negative)
 :setup-files ((:type :directory :relative-path "trusted/")
               (:type :directory :relative-path "trusted/nested/")
               (:relative-path "trusted/nested/secure.txt" :input-text "secure"))
 :current-directory "cwd/"
 :trusted-paths ("trusted/")
 :builtin-name "FINDTRUSTEDFILE"
 :arguments ("nested/secure.txt")
 :expected-value (:nil))
