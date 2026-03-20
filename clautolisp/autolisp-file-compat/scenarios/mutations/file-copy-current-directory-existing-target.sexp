(:name "file-copy-current-directory-existing-target"
 :description "Return nil when copying onto an existing target through the configured AutoLISP current directory."
 :kind :builtin
 :classification :portable
 :tags (:builtin :file :copy :current-directory :negative)
 :setup-files ((:type :directory :relative-path "cwd/")
               (:relative-path "cwd/source.txt"
                :input-text "source")
               (:relative-path "cwd/target.txt"
                :input-text "target"))
 :current-directory "cwd/"
 :builtin-name "VL-FILE-COPY"
 :arguments ("source.txt" "target.txt")
 :expected-value (:nil))
