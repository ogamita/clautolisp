(:name "read-basic"
 :description "Read back a printed AutoLISP form from a string."
 :kind :builtin
 :classification :portable
 :tags (:builtin :printer :read)
 :builtin-name "READ"
 :arguments ("(1 FOO \"bar\")")
 :expected-value (:list 1 (:symbol "FOO") "bar"))
