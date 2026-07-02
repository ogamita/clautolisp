;;;; autolisp-benchmark/benchmarks/serialization.lsp
;;;;
;;;; I/O class: in-memory serialisation and deserialisation of Lisp
;;;; objects to and from strings. (vl-prin1-to-string OBJ) renders a
;;;; nested structure to its printed representation; (read STR) parses
;;;; the first object back out. One iteration round-trips a small mixed
;;;; structure (dotted pairs, nested lists, reals, strings, symbols).

(defun bench-serialization (reps / i obj str back)
  (setq i 0)
  (while (< i reps)
    (setq obj (list 'entity
                    (cons 0 "LINE")
                    (cons 8 "Layer0")
                    (cons 10 (list (float i) (* 2.0 (float i)) 0.0))
                    (cons 11 (list (float (+ i 1)) 0.0 0.0))
                    (list 1 2 3 (/ 1.0 (float (+ i 1))))
                    "a text value"))
    (setq str (vl-prin1-to-string obj))         ; serialise
    (setq back (read str))                      ; deserialise
    (setq i (1+ i)))
  back)

(defbench "serialize" "serialization" 'bench-serialization)

(princ)
