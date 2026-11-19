;;; run-cadgui-driveability.lisp -- load clautolisp/cadgui and run the
;;; driveability guard (cadgui-action-layer slice D). Exit 0 = no violations
;;; (green), nonzero = violations found. Run via run-cadgui-driveability.sh;
;;; wire into CI like scripts/ci-classify-changes.py.
(setf *debugger-hook*
      (lambda (c h) (declare (ignore h))
        (format *error-output* "~&run-cadgui-driveability: ~A~%" c)
        (finish-output *error-output*)
        (ext:quit 3)))
(ext:set-limit 'ext:binding-stack (* 1024 1024 64))
(ext:set-limit 'ext:frame-stack  (* 1024 1024))
(ext:set-limit 'ext:lisp-stack   (* 1024 1024 64))
(require :asdf)
(let ((ql (merge-pathnames #p"quicklisp/setup.lisp" (user-homedir-pathname))))
  (when (probe-file ql) (load ql)))
(when (find-package :ql)
  (funcall (read-from-string "ql:quickload")
           (list "babel" "trivial-gray-streams" "cffi") :silent t))
(let ((dir (uiop:ensure-directory-pathname
            (or (ext:getenv "CADGUI_CLAUTOLISP_DIR") "."))))
  (asdf:load-asd (merge-pathnames "clautolisp.asd" dir)))
(asdf:load-system "clautolisp/cadgui" :verbose nil)
(handler-case
    (let ((n (uiop:symbol-call :clautolisp.cadgui :cadgui-driveability-report)))
      (finish-output)
      (if (zerop n)
          (progn (format t "~&CADGUI DRIVEABILITY: GREEN~%") (finish-output) (ext:quit 0))
          (progn (format *error-output* "~&CADGUI DRIVEABILITY: ~D VIOLATION(S)~%" n)
                 (finish-output *error-output*) (ext:quit 1))))
  (error (e)
    (format *error-output* "~&CADGUI DRIVEABILITY: ERROR -- ~A~%" e)
    (finish-output *error-output*)
    (ext:quit 2)))
