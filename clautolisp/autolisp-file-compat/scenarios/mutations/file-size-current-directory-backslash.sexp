(:name "file-size-current-directory-backslash"
 :description "Report file size for a backslash-delimited relative subpath resolved through the configured AutoLISP current directory."
 :kind :builtin
 :classification :portable
 :tags (:builtin :file :size :current-directory :backslash)
 :setup-files ((:type :directory :relative-path "cwd/")
               (:type :directory :relative-path "cwd/nested/")
               (:relative-path "cwd/nested/example.txt"
                :input-text "alpha"))
 :current-directory "cwd/"
 :builtin-name "VL-FILE-SIZE"
 :arguments ("nested\\example.txt")
 :expected-value 5)
