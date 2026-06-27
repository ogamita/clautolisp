Assume we have the following form:

((lambda (par)

   ((lambda ( x / a )
      ↓(setq a 1)
      (print (+ x a)))
    par)

   ((lambda ( z / b )
      (setq b z)
      (setq par ↑(* b b)))
    par)

   par))

with ↑ denoting the poll-point where we jump from,
and ↓ the poll-point where we jump to.

If we explicit the poll-points:

((lambda (par)
   (pp 0
       (progn
         (pp 1
             ((lambda ( x / a ) 
                (pp 2
                    ↓(setq a (pp 3
                                 1)))
                (pp 4
                    (print (pp 5
                               (+ (pp 6 x)
                                  (pp 7 a))))))
              (pp 8 par)))

         (pp 9
             ((lambda ( z / b )
                (pp 10
                    (setq b (pp 11 z)))
                (pp 12
                    (setq par (pp 13
                                  ↑(* (pp 14 b)
                                      (pp 15 b))))))
              (pp 16
                  par)))))) 
 (pp 17
     par))

;; pp 13 says: let's jump to pp 2
;; pp 13 notice that pp 2 is not inside its form (only pp 14 and pp 15)
;; so it skips evaluation and returns to pp 12.
;; 
;; pp 12 sees: let's jump to pp 2
;; pp 12 notice that pp 2 is not inside its form (only pp 13, pp 14 and pp 15)
;; so it skips evaluation (nothing more to do, but if ever), and returns to pp 9
;; 
;; pp 9 same, returns to pp 0
;; 
;; pp 0 sees: let's jump to pp2,
;; pp 0 notice that pp2 is inside its form,
;; so it enters the progn.
;; 
;; pp 1 sees: let's jump to pp2, 
;; pp1 notice that pp2 is inside its form,
;; so it enters the function call.
;; 
;; Since function calls establish binding, we'd need to reestablish them.
;; If don't want to re-évaluate the arguments (but we can consider that
;; this is implied by the jump back), we could save the arguments of the
;; previous call, and re-use the values to bind the parameters. This doesn't seem more justified than recomputing them. It could be a user option.
;; 
;; We enter the function, the bindings are established, and the local variables created.
;; Then pp 2 executes.
;; pp 2 sees: let's jump to pp2,
;; houra!
;; remove this instruction and continue executing normally (or step-by-step, etc).
