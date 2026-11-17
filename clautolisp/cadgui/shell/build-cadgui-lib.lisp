;;; build-cadgui-lib.lisp -- compile clautolisp/cadgui and its whole dependency
;;; closure into ONE monolithic static library (clautolisp-cadgui.a) that the
;;; C++ cadgui shell links in, so the shell initializes the engine from C
;;; (ecl_init_module) instead of asdf:load-system at runtime. No ASDF planner
;;; at runtime => no warm-cache PLAN::STAMP overflow, and no ~96 s recompile.
;;;
;;; Unlike image-op/program-op (which link libcmp.a -- absent from this Debian
;;; ECL), a monolithic static library is just `ar` over the compiled objects,
;;; so it builds here. The shell links libecl.so dynamically (ecl-config).
;;;
;;; Build COLD (build-cadgui-lib.sh clears the cache first) so make-build's own
;;; ASDF planning does not hit the warm-cache overflow.
(setf *debugger-hook*
      (lambda (c h) (declare (ignore h))
        (format *error-output* "~&build-cadgui-lib: build failed: ~A~%" c)
        (finish-output *error-output*)
        (ext:quit 1)))
(ext:set-limit 'ext:binding-stack (* 1024 1024 64))
(ext:set-limit 'ext:frame-stack  (* 1024 1024))
(ext:set-limit 'ext:lisp-stack   (* 1024 1024 64))

(require :asdf)                          ; cold build: the ASDF upgrade is harmless
(let ((ql (merge-pathnames #p"quicklisp/setup.lisp" (user-homedir-pathname))))
  (when (probe-file ql) (load ql)))
(when (find-package :ql)
  (funcall (read-from-string "ql:quickload")
           (list "babel" "trivial-gray-streams" "cffi") :silent t))

(let* ((root (uiop:ensure-directory-pathname
              (or (ext:getenv "CADGUI_CLAUTOLISP_DIR") ".")))
       (out  (merge-pathnames "cadgui/shell/" root)))
  (asdf:load-asd (merge-pathnames "clautolisp.asd" root))
  (format t "~&build-cadgui-lib: building the monolithic static library ...~%")
  ;; NB: ECL's monolithic bundle assigns a RANDOMISED init symbol
  ;; (init_lib__<tag>); :init-name is not honoured here. build-cadgui-lib.sh
  ;; extracts the real symbol from the archive with nm afterwards.
  (let ((lib (asdf:make-build "clautolisp/cadgui"
                              :type :static-library
                              :monolithic t
                              :move-here out)))
    (format t "~&build-cadgui-lib: wrote ~A~%" lib)))
(finish-output)
(ext:quit 0)
