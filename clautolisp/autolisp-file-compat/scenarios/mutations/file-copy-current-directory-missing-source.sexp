(:name "file-copy-current-directory-missing-source"
 :description "Return nil when copying a missing source through the configured AutoLISP current directory."
 :kind :builtin
 :classification :portable
 :tags (:builtin :file :copy :current-directory :negative)
 :setup-files ((:type :directory :relative-path "cwd/"))
 :current-directory "cwd/"
 :builtin-name "VL-FILE-COPY"
 :arguments ("missing.txt" "target.txt")
 :expected-value (:nil))
