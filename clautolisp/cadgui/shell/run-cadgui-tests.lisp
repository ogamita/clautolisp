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
;; Which suite to run -- defaults to cadgui; override with SUITE_SYSTEM /
;; SUITE_PACKAGE (e.g. clautolisp/cador/tests + clautolisp.cador.tests).
(let ((system  (or (ext:getenv "SUITE_SYSTEM")  "clautolisp/cadgui/tests"))
      (package (or (ext:getenv "SUITE_PACKAGE") "clautolisp.cadgui.tests")))
  (asdf:load-system system :verbose nil)
  (handler-case
      (progn
        (uiop:symbol-call (string-upcase package) :run-all-tests)
        (format t "~&SUITE ~A: PASS~%" system)
        (finish-output)
        (ext:quit 0))
    (error (e)
      (format *error-output* "~&SUITE ~A: FAIL -- ~A~%" system e)
      (finish-output *error-output*)
      (ext:quit 2))))
