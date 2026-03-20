(:name "file-rename-current-directory-relative"
 :description "Rename a relative file resolved through the configured AutoLISP current directory."
 :kind :builtin
 :classification :portable
 :tags (:builtin :file :rename :current-directory)
 :setup-files ((:type :directory :relative-path "cwd/")
               (:relative-path "cwd/old.txt"
                :input-text "rename me"))
 :current-directory "cwd/"
 :builtin-name "VL-FILE-RENAME"
 :arguments ("old.txt" "new.txt")
 :expected-value (:symbol "T")
 :artifact-relative-path "cwd/new.txt"
 :expected-text "rename me")
