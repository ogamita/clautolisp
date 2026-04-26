(:name "file-printer-sequence"
 :description "Write a mixed printer sequence to a file descriptor and compare the final text. AutoLISP `terpri` is zero-arity (BricsCAD V26 Phase-5 product test, 2026-04-26 -- see autolisp-spec/results/bricscad/macos/20260426T122808Z/), so file-handle newlines are emitted via `(princ \"\\n\" stream)`. AutoLISP `print` writes leading-newline + prin1 + trailing-space, not trailing-newline."
 :kind :builtin
 :classification :portable
 :tags (:builtin :printer :file-descriptor)
 :steps ((:builtin-name "OPEN"
          :arguments ("print.txt" "w")
          :bind "out")
         (:builtin-name "PRINC"
          :arguments ("alpha" (:ref "out")))
         (:builtin-name "PRINC"
          :arguments ("
" (:ref "out")))
         (:builtin-name "PRIN1"
          :arguments ("beta" (:ref "out")))
         (:builtin-name "PRINC"
          :arguments ("
" (:ref "out")))
         (:builtin-name "PRINT"
          :arguments ((:list 1 (:symbol "FOO")) (:ref "out")))
         (:builtin-name "CLOSE"
          :arguments ((:ref "out"))))
 :artifact-relative-path "print.txt"
 :expected-artifact-exists-p t
 :expected-text "alpha
\"beta\"

(1 FOO) ")
