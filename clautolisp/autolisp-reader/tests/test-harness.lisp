(in-package #:clautolisp.autolisp-reader.tests)

(defvar *tests* '())

(defmacro deftest (name () &body body)
  `(progn
     (defun ,name ()
       ,@body)
     (pushnew ',name *tests*)))

(defun fail-test (format-control &rest arguments)
  (error 'simple-error
         :format-control format-control
         :format-arguments arguments))

(defmacro is (condition &optional (message "Assertion failed: ~S"))
  `(unless ,condition
     (fail-test ,message ',condition)))

(defmacro is-equal (expected actual)
  `(let ((expected-value ,expected)
         (actual-value ,actual))
     (unless (equal expected-value actual-value)
       (fail-test "Expected ~S but got ~S." expected-value actual-value))))

(defun run-all-tests ()
  (let ((failures '()))
    (dolist (test (reverse *tests*))
      (handler-case
          (funcall test)
        (error (condition)
          (push (list test condition) failures))))
    (when failures
      (error "autolisp-reader tests failed:~%~:{  ~A: ~A~%~}"
             (mapcar (lambda (entry)
                       (list (first entry) (second entry)))
                     (nreverse failures))))
    t))
