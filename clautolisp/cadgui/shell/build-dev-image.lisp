;;; build-dev-image.lisp -- build cadgui-dev.image: an ECL development image
;;; with clautolisp/cadgui and its whole dependency closure frozen in, starting
;;; on the ECL REPL (ecl skill EC10 / section 3.3). Run with build-dev-image.sh.
;;;
;;; Working session once built:
;;;   $ ./cadgui-dev.image
;;;   > (asdf:load-system "clautolisp/cadgui")   ; already frozen: a no-op
;;;   > (clautolisp.cadgui.tests:run-all-tests)  ; run the suite, no recompile
;;;   > (load "cadgui/source/protocol.lisp")     ; after an edit: instant (EC12)
(setf *debugger-hook*
      (lambda (c h) (declare (ignore h))
        (format *error-output* "~&build-dev-image: build failed: ~A~%" c)
        (finish-output *error-output*)
        (ext:quit 1)))
(ext:set-limit 'ext:binding-stack (* 1024 1024 64))
(ext:set-limit 'ext:frame-stack  (* 1024 1024))
(ext:set-limit 'ext:lisp-stack   (* 1024 1024 64))

(require :asdf)                          ; EC1: ASDF before Quicklisp
(let ((ql (merge-pathnames #p"quicklisp/setup.lisp" (user-homedir-pathname))))
  (when (probe-file ql) (load ql)))
(when (find-package :ql)
  (funcall (read-from-string "ql:quickload")
           (list "babel" "trivial-gray-streams" "cffi") :silent t))

(let ((root (uiop:ensure-directory-pathname
             (or (ext:getenv "CADGUI_CLAUTOLISP_DIR") "."))))
  (asdf:load-asd (merge-pathnames "clautolisp.asd" root))
  (asdf:load-asd (merge-pathnames "cadgui/shell/cadgui-dev.asd" root))
  ;; Load the dev system so Quicklisp downloads any missing dependency and the
  ;; closure is known, then compute the frozen closure (EC10: required-
  ;; components, NOT already-loaded-systems).
  (asdf:load-system "cadgui-dev" :verbose nil)
  (let ((frozen
          (remove "cadgui-dev"
                  (mapcar #'asdf:component-name
                          (asdf:required-components
                           "cadgui-dev"
                           :other-systems t
                           :component-type 'asdf:system
                           :keep-component 'asdf:system
                           :goal-operation 'asdf:load-op))
                  :test #'string=)))
    (format t "~&build-dev-image: freezing ~D systems~%" (length frozen))
    (asdf:make-build
     "cadgui-dev"
     :type :image                        ; image-op: ends on (si:top-level t)
     :move-here root
     ;; EC10: image-op ignores the defsystem :epilogue-code -- pass it here;
     ;; register the whole closure immutable so load-system never recompiles it.
     :epilogue-code `(dolist (system ',frozen)
                       (asdf:register-immutable-system system)))))
(format t "~&build-dev-image: wrote cadgui-dev.image~%")
(finish-output)
(ext:quit 0)
