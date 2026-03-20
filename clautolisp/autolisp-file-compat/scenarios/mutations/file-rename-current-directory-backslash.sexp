(:name "file-rename-current-directory-backslash"
 :description "Rename a backslash-delimited relative subpath resolved through the configured AutoLISP current directory."
 :kind :builtin
 :classification :portable
 :tags (:builtin :file :rename :current-directory :backslash)
 :setup-files ((:type :directory :relative-path "cwd/")
               (:type :directory :relative-path "cwd/nested/")
               (:relative-path "cwd/nested/old.txt"
                :input-text "rename me"))
 :current-directory "cwd/"
 :builtin-name "VL-FILE-RENAME"
 :arguments ("nested\\old.txt" "nested\\new.txt")
 :expected-value (:symbol "T")
 :artifact-relative-path "cwd/nested/new.txt"
 :expected-text "rename me")
