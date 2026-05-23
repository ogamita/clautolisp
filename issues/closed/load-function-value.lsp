
(defun good-name (object)
  (list 'good-name object))

(defun funny-fun (object good-name)
  (apply good-name (list object)))

(defun doit-in-object (/ object good-name)
  (setq object 33)
  (defun good-name (object)
    (list 'in-object object))
  (defun doit ()
    (list (funny-fun object (function good-name))
          (funny-fun object (function (lambda (object) (list 'expected object))))))
  (doit))

(defun test ()
  (list
   (list (funny-fun 42 (function good-name))
         (funny-fun 42 (function (lambda (object) (list 'expected object)))))
   (doit-in-object)))

'function-value
