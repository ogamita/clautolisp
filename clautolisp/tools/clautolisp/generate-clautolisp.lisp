(in-package "COMMON-LISP-USER")

;;; Build script for the standalone `clautolisp` evaluator.
;;;
;;; Reuses the same generator as `read-autolisp` to keep both tools'
;;; build paths consistent across SBCL and CCL.

(load (make-pathname :name "generate" :type "lisp" :version nil
                     :defaults
                     (merge-pathnames
                      #P"../../autolisp-reader/tools/read-autolisp/generate.lisp"
                      (or *load-pathname* #P"./"))))

(defparameter *source-directory*
  (make-pathname :name nil :type nil :version nil
                 :defaults (or *load-pathname*
                               (truename (first (directory #P"./*.lisp"))))))

(defparameter *clautolisp-subproject-root*
  (truename (merge-pathnames #P"../../" *source-directory* nil)))

(defparameter *clautolisp-asd-file*
  (truename (merge-pathnames #P"clautolisp.asd" *clautolisp-subproject-root* nil)))

(defparameter *asdf-directories*
  (list *clautolisp-subproject-root*))

(defparameter *release-directory*
  (merge-pathnames #P"bin/" *source-directory* nil))

(defun implementation-tag ()
  #+sbcl "sbcl"
  #+ccl "ccl"
  #-(or sbcl ccl)
  (string-downcase (lisp-implementation-type)))

(generate-program
 :program-name (format nil "clautolisp-~A" (implementation-tag))
 :main-function "clautolisp.tools.clautolisp:main"
 :system-name "clautolisp/clautolisp-tool"
 :asdf-directories *asdf-directories*
 :asd-file *clautolisp-asd-file*
 :release-directory *release-directory*)
