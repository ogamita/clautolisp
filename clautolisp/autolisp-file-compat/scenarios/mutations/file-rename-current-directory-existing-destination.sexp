(:name "file-rename-current-directory-existing-destination"
 :description "Return nil when renaming onto an existing destination through the configured AutoLISP current directory."
 :kind :builtin
 :classification :portable
 :tags (:builtin :file :rename :current-directory :negative)
 :setup-files ((:type :directory :relative-path "cwd/")
               (:relative-path "cwd/source.txt"
                :input-text "source")
               (:relative-path "cwd/target.txt"
                :input-text "target"))
 :current-directory "cwd/"
 :builtin-name "VL-FILE-RENAME"
 :arguments ("source.txt" "target.txt")
 :expected-value (:nil))
