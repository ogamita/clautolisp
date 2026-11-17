;;; run-cadgui-tests.lisp -- load clautolisp/cadgui/tests and run the cadgui
;;; fiveam suite. Exit 0 = pass, nonzero = fail. Run via run-cadgui-tests.sh.
(setf *debugger-hook*
      (lambda (c h) (declare (ignore h))
        (format *error-output* "~&run-cadgui-tests: ~A~%" c)
        (finish-output *error-output*)
        (ext:quit 1)))
(ext:set-limit 'ext:binding-stack (* 1024 1024 64))
(ext:set-limit 'ext:frame-stack  (* 1024 1024))
(ext:set-limit 'ext:lisp-stack   (* 1024 1024 64))
(require :asdf)
(let ((ql (merge-pathnames #p"quicklisp/setup.lisp" (user-homedir-pathname))))
  (when (probe-file ql) (load ql)))
(when (find-package :ql)
  (funcall (read-from-string "ql:quickload")
           (list "fiveam" "babel" "trivial-gray-streams" "cffi") :silent t))
(let ((dir (uiop:ensure-directory-pathname
            (or (ext:getenv "CADGUI_CLAUTOLISP_DIR") "."))))
  (asdf:load-asd (merge-pathnames "clautolisp.asd" dir)))
(asdf:load-system "clautolisp/cadgui/tests" :verbose nil)
(handler-case
    (progn
      (uiop:symbol-call :clautolisp.cadgui.tests :run-all-tests)
      (format t "~&CADGUI-TESTS: PASS~%")
      (finish-output)
      (ext:quit 0))
  (error (e)
    (format *error-output* "~&CADGUI-TESTS: FAIL -- ~A~%" e)
    (finish-output *error-output*)
    (ext:quit 2)))
