(defun expect (result expected)
  (if (not (equal result expected))
      (progn
        (princ "[FAIL] expected ")
        (princ result)
        (princ " to be ")
        (princ expected)
        (terpri))))

;|
   A nice and documented global foo function.
|;
(defun foo (/ foo)
    ;|
      A not less nice and still documented local foo function.
    |;
    (defun foo ()
      'inner)
  (list 'outer (foo) (clautolisp-documentation 'foo)))

(expect (list (foo)  (clautolisp-documentation 'foo))
        '(outer inner "
      A not less nice and still documented local foo function.
    "  "
   A nice and documented global foo function.
"))



;| global doc |;
(defun foo (/ foo)

  ;| recursive inner doc |; 
  (defun foo (x)
    (if (= 0 x)
       (setq foo 42)
       (foo (- x 1))))

  (foo 3))

;; (foo)
;; -> ([foo foo] 3)
;;   -> ([foo foo] 2)
;;     -> ([foo foo] 1)
;;       -> ([foo foo] 0)
;;         -> [foo foo] is set to 42, so it's not a documented function anymore
;;                      we must reset the "recursive inner doc" of [foo foo]
;; but the documentation of the global foo is still "global doc"  


;| global doc |;
(defun foo (/ foo)
  ;| recursive inner doc |; 
  (defun foo (x docs)
    (if (= 0 x)
       (progn (setq foo 42)
              (cons x (cons (clautolisp-documentation 'foo) docs)))
       (foo (- x 1)
            (cons x (cons (clautolisp-documentation 'foo) docs)))))
  (foo 3 nil))

(expect (cons (foo)  (clautolisp-documentation 'foo))
        '((0 nil
                 1 "recursive inner doc"
                 2 "recursive inner doc"
                 3 "recursive inner doc")
                "global doc"))
