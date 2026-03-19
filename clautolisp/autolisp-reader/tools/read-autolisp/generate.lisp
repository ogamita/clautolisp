(in-package "COMMON-LISP-USER")

(defun argv ()
  #+ccl ccl:*command-line-argument-list*
  #+sbcl sb-ext:*posix-argv*
  #-(or ccl sbcl) (error "Unsupported Lisp implementation."))

(defun load-quicklisp ()
  (let ((setup (merge-pathnames #P"quicklisp/setup.lisp" (user-homedir-pathname))))
    (when (probe-file setup)
      (load setup))))

(defun configure-asdf-directories (directories)
  (if (member :asdf3 *features*)
      (asdf:initialize-source-registry
       `(:source-registry
         :ignore-inherited-configuration
         ,@(mapcar (lambda (dir) `(:directory ,dir)) directories)
         :default-registry))
      (setf asdf:*central-registry* directories)))

(defun make-toplevel-function (main-function-name)
  (let ((form `(lambda ()
                 (handler-case
                     (progn
                       (apply (read-from-string ,main-function-name)
                              (argv)))
                   (error (err)
                     (finish-output *standard-output*)
                     (finish-output *trace-output*)
                     (format *error-output* "~&~A~%" err)
                     (finish-output *error-output*)
                     #+ccl (ccl:quit 1)
                     #+sbcl (sb-ext:exit :code 1)))
                 #+ccl (ccl:quit 0)
                 #+sbcl (sb-ext:exit :code 0))))
    #-ecl (coerce form 'function)))

(defun generate-program (&key program-name main-function system-name source-directory
                           asdf-directories release-directory asd-file)
  (declare (ignore source-directory))
  (load-quicklisp)
  (require :asdf)
  (configure-asdf-directories asdf-directories)
  (when asd-file
    (asdf:load-asd asd-file))
  (asdf:load-system system-name)
  #+ccl
  (ccl:save-application
   (merge-pathnames program-name release-directory nil)
   :toplevel-function (make-toplevel-function main-function)
   :mode #o755
   :prepend-kernel t
   :error-handler t)
  #+sbcl
  (sb-ext:save-lisp-and-die
   (namestring (merge-pathnames program-name release-directory nil))
   :executable t
   :compression 9
   :toplevel (make-toplevel-function main-function)))
