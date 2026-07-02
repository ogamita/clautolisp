;;;; autolisp-benchmark/benchmarks/strings.lsp
;;;;
;;;; Basic-language class: string manipulation. Exercises concatenation,
;;;; length / substring, case folding, number<->string conversion, and
;;;; wildcard matching. One iteration builds and picks apart a string.

(defun bench-strings (reps / i s)
  (setq i 0)
  (while (< i reps)
    (setq s (strcat "item-" (itoa i) "-" (rtos (float i) 2 3)))
    (strlen s)                                  ; length
    (substr s 2 4)                              ; slice
    (strcase s)                                 ; upcase
    (strcase s t)                               ; downcase
    (atoi (itoa i))                             ; string -> int
    (atof (rtos (float i) 2 2))                 ; string -> real
    (wcmatch s "item*")                         ; wildcard match
    (vl-string-search "-" s)                    ; substring search
    (setq i (1+ i)))
  s)

(defbench "strings" "strings" 'bench-strings)

(princ)
