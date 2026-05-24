(in-package "COMMON-LISP-USER")

;;; Build script for the standalone `alfe` executable.
;;;
;;; Reuses the same generator as `clautolisp` and `read-autolisp`
;;; (clautolisp/autolisp-reader/tools/read-autolisp/generate.lisp) so
;;; all three tools share an identical SBCL/CCL save-image path.

(load (make-pathname
       :name "generate" :type "lisp" :version nil
       :defaults
       (merge-pathnames
        #P"../../../clautolisp/autolisp-reader/tools/read-autolisp/generate.lisp"
        (or *load-pathname* #P"./"))))

(defparameter *source-directory*
  (make-pathname :name nil :type nil :version nil
                 :defaults (or *load-pathname*
                               (truename (first (directory #P"./*.lisp"))))))

;;; The alfe subproject root is two levels up from this file
;;; (tools/alfe/ → tools/ → autolisp-front-end/).
(defparameter *alfe-subproject-root*
  (truename (merge-pathnames #P"../../" *source-directory* nil)))

(defparameter *alfe-asd-file*
  (truename (merge-pathnames #P"autolisp-front-end.asd"
                             *alfe-subproject-root* nil)))

(defparameter *clautolisp-subproject-root*
  (truename (merge-pathnames #P"../clautolisp/" *alfe-subproject-root* nil)))

(defparameter *clautolisp-asd-file*
  (truename (merge-pathnames #P"clautolisp.asd"
                             *clautolisp-subproject-root* nil)))

;;; The alfe-tool system depends on the autolisp-front-end aggregate,
;;; which depends on the clautolisp/* subsystems. ASDF needs to see
;;; both .asd files in the source registry to resolve all of them.
(defparameter *asdf-directories*
  (list *alfe-subproject-root* *clautolisp-subproject-root*))

(defparameter *release-directory*
  (merge-pathnames #P"bin/" *source-directory* nil))

(defun implementation-tag ()
  #+sbcl "sbcl"
  #+ccl "ccl"
  #-(or sbcl ccl)
  (string-downcase (lisp-implementation-type)))

(ensure-directories-exist *release-directory*)

(generate-program
 :program-name (format nil "alfe-~A" (implementation-tag))
 :main-function "alfe.tool:main"
 :system-name "autolisp-front-end/alfe-tool"
 :asdf-directories *asdf-directories*
 :asd-file *alfe-asd-file*
 :release-directory *release-directory*)
