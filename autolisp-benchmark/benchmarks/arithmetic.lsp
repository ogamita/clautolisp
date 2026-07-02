;;;; autolisp-benchmark/benchmarks/arithmetic.lsp
;;;;
;;;; Basic-language class: numeric evaluation. Exercises integer and
;;;; floating-point arithmetic, the transcendental library, and the
;;;; comparison / increment primitives in a tight loop. One iteration
;;;; performs a fixed bundle of arithmetic operations.

(defun bench-arithmetic (reps / i x y)
  (setq i 0)
  (setq x 1.0)
  (while (< i reps)
    (setq y (+ (float i) 1.0))
    (setq x (+ 1.0
               (* 3.0 (- 7 2))                ; integer arithmetic
               (/ y 2.0)                      ; float division
               (sqrt y)                       ; roots
               (expt 1.0001 3)                ; power
               (rem (+ i 7) 5)                ; integer remainder
               (* (sin y) (cos y))            ; transcendental
               (abs (- 0.5 x))                ; magnitude
               (min x (max y 2.0))))          ; comparisons
    (setq i (1+ i)))
  x)

(defbench "arithmetic" "arithmetic" 'bench-arithmetic)

(princ)
