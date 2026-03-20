(:name "file-delete-current-directory-relative"
 :description "Delete a relative file resolved through the configured AutoLISP current directory."
 :kind :builtin
 :classification :portable
 :tags (:builtin :file :delete :current-directory)
 :setup-files ((:type :directory :relative-path "cwd/")
               (:relative-path "cwd/obsolete.txt"
                :input-text "remove me"))
 :current-directory "cwd/"
 :builtin-name "VL-FILE-DELETE"
 :arguments ("obsolete.txt")
 :expected-value (:symbol "T")
 :artifact-relative-path "cwd/obsolete.txt")
