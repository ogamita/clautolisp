(:name "file-copy-current-directory-backslash"
 :description "Copy a backslash-delimited relative subpath through the configured AutoLISP current directory."
 :kind :builtin
 :classification :portable
 :tags (:builtin :file :copy :current-directory :backslash)
 :setup-files ((:type :directory :relative-path "cwd/")
               (:type :directory :relative-path "cwd/nested/")
               (:relative-path "cwd/nested/source.txt"
                :input-text "copy me"))
 :current-directory "cwd/"
 :builtin-name "VL-FILE-COPY"
 :arguments ("nested\\source.txt" "nested\\target.txt")
 :expected-value 7
 :artifact-relative-path "cwd/nested/target.txt"
 :expected-artifact-exists-p t
 :expected-text "copy me")
