(:name "filename-mktemp-basic"
 :description "Generate a temporary pathname under a chosen workspace directory."
 :kind :builtin
 :classification :host-sensitive
 :tags (:builtin :file :mktemp)
 :setup-files ((:type :directory :relative-path "tmp/"))
 :builtin-name "VL-FILENAME-MKTEMP"
 :arguments ("case-" "tmp/" ".dat")
 :expected-value (:predicate :path-under-workspace "tmp/" :suffix ".dat" :exists-p nil))
