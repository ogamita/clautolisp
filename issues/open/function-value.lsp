(defun good-name (object)
  (list 'good-name object))

(defun funny-fun (object good-name)
  (good-name object))

(defun doit-in-object (/ object good-name)
  (setq object 33)
  (defun good-name (object)
    (list 'in-object object))
  (defun doit ()
    (list (funny-fun object good-name)
          (funny-fun object (function good-name))
          (funny-fun object (function (lambda (object) (list 'expected object))))))
  (doit))

(defun test ()
  (list
   (list (funny-fun 42 good-name)
         (funny-fun 42 (function good-name))
         (funny-fun 42 (function (lambda (object) (list 'expected object)))))
   (doit-in-object)))


;; autolisp> (test)
;; (((GOOD-NAME 42) (GOOD-NAME 42) (GOOD-NAME 42))
;;  ((IN-OBJECT 33) (IN-OBJECT 33) (IN-OBJECT 33)))
;; ;;                                  ^ definitely not good.
;; ;;          they should be (EXPECTED 42) and (EXPECTED 33)

(princ "Call (test)") (terpri)
'function-value
