(:name "file-copy-current-directory-relative"
 :description "Copy a relative file through the configured AutoLISP current directory."
 :kind :builtin
 :classification :portable
 :tags (:builtin :file :copy :current-directory)
 :setup-files ((:type :directory :relative-path "cwd/")
               (:relative-path "cwd/source.txt"
                :input-text "copy me"))
 :current-directory "cwd/"
 :builtin-name "VL-FILE-COPY"
 :arguments ("source.txt" "target.txt")
 :expected-value 7
 :artifact-relative-path "cwd/target.txt"
 :expected-artifact-exists-p t
 :expected-text "copy me")
