;;;; autolisp-benchmark/benchmarks/lists.lsp
;;;;
;;;; Basic-language class: list construction and traversal. Exercises
;;;; cons / list / append, structural walks (reverse, nth, member),
;;;; association lookup, and mapping. One iteration builds and consumes
;;;; a small list.

(defun bench-lists (reps / i lst acc alist)
  (setq alist (list (cons 1 "one") (cons 2 "two") (cons 3 "three")
                    (cons 4 "four") (cons 5 "five")))
  (setq i 0)
  (while (< i reps)
    (setq lst (list 1 2 3 4 5 6 7 8))          ; allocation
    (setq lst (cons 0 lst))                     ; prepend
    (setq lst (append lst (list 9 10)))         ; concat
    (setq acc (reverse lst))                    ; traverse + rebuild
    (setq acc (mapcar '1+ acc))                 ; map
    (nth 6 acc)                                 ; index
    (member 5 acc)                              ; search
    (assoc 3 alist)                             ; keyed lookup
    (length acc)                                ; count
    (setq i (1+ i)))
  acc)

(defbench "lists" "lists" 'bench-lists)

(princ)
