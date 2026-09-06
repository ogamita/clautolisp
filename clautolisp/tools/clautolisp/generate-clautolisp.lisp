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

;;; Bake the no-grovel CFFI ncurses backend (clautolisp.ui.tui.curses) into the
;;; image so `--debugger-ui ncurses' works out of the box. Only the CL code is
;;; included; libncurses is still opened on demand at run time
;;; (ENSURE-CURSES-LOADED), so the BUILD needs no ncurses headers or library —
;;; just CFFI (pure Lisp). save-lisp-and-die dumps the current image, so
;;; pre-loading it here is enough. Wrapped so a host without CFFI still builds a
;;; working clautolisp (ncurses then falls back to the tui UI at run time).
(handler-case
    (progn
      (let ((setup (merge-pathnames #P"quicklisp/setup.lisp" (user-homedir-pathname))))
        (when (probe-file setup) (load setup)))
      (when (find-package '#:ql)
        (funcall (find-symbol (symbol-name '#:quickload) '#:ql) "cffi" :silent t))
      (asdf:load-asd *clautolisp-asd-file*)
      (asdf:load-asd (truename (merge-pathnames
                                #P"autolisp-debug-ui-tui-curses/clautolisp-tui-curses.asd"
                                *clautolisp-subproject-root*)))
      (asdf:load-system "clautolisp-tui-curses"))
  (serious-condition (e)
    (format *error-output*
            "~&NOTE: the ncurses backend was not baked into this image (~A); ~
`--debugger-ui ncurses' will fall back to the terminal (tui) UI.~%" e)))

(generate-program
 :program-name (format nil "clautolisp-~A" (implementation-tag))
 :main-function "clautolisp.tools.clautolisp:main"
 :system-name "clautolisp/clautolisp-tool"
 :asdf-directories *asdf-directories*
 :asd-file *clautolisp-asd-file*
 :release-directory *release-directory*)
