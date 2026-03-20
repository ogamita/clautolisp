(:name "file-rename-current-directory-missing-source"
 :description "Return nil when renaming a missing source through the configured AutoLISP current directory."
 :kind :builtin
 :classification :portable
 :tags (:builtin :file :rename :current-directory :negative)
 :setup-files ((:type :directory :relative-path "cwd/"))
 :current-directory "cwd/"
 :builtin-name "VL-FILE-RENAME"
 :arguments ("missing.txt" "target.txt")
 :expected-value (:nil))
