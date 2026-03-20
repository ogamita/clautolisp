(:name "vl-prin1-to-string-basic"
 :description "Print a composite runtime value using AutoLISP-oriented escaping."
 :kind :builtin
 :classification :portable
 :tags (:builtin :printer :string)
 :builtin-name "VL-PRIN1-TO-STRING"
 :arguments ((:list 1 (:symbol "FOO") "bar"))
 :expected-value (:string "(1 FOO \"bar\")"))
