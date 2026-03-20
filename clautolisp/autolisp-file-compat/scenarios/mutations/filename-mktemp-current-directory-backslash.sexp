(:name "filename-mktemp-current-directory-backslash"
 :description "Create a temporary pathname under a backslash-delimited relative directory resolved through the configured AutoLISP current directory."
 :kind :builtin
 :classification :portable
 :tags (:builtin :file :mktemp :current-directory :backslash)
 :setup-files ((:type :directory :relative-path "cwd/")
               (:type :directory :relative-path "cwd/tmp/"))
 :current-directory "cwd/"
 :builtin-name "VL-FILENAME-MKTEMP"
 :arguments ("case-" "tmp\\" ".dat")
 :expected-value (:predicate :path-under-workspace "cwd/tmp/"
                             :suffix ".dat"
                             :exists-p nil))
