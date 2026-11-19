;;;; -*- mode:lisp; coding:utf-8 -*-
;;;;
;;;; checkout-source-registry-test.lisp -- regression test for
;;;; issues/closed/make-test-loads-installed-clautolisp.issue.
;;;;
;;;; Run by `make -C clautolisp test-checkout-registry' (part of `make
;;;; test'). It plants a DECOY install in a scratch directory under
;;;; $XDG_CACHE_HOME -- a share/common-lisp/systems/ holding a clautolisp.asd,
;;;; tui-core.asd, clautolisp-tui-curses.asd and autolisp-front-end.asd of its
;;;; own -- which the Makefile makes the INHERITED configuration see through
;;;; CL_SOURCE_REGISTRY. That is how an install under /opt/local reaches ASDF
;;;; on poseidon (XDG_DATA_DIRS=/opt/local/share); CL_SOURCE_REGISTRY is used
;;;; here because it outranks the user's own configuration files (a
;;;; ~/.config/common-lisp/source-registry.conf that ignores the inherited
;;;; configuration hides XDG_DATA_DIRS, which is why thalassa never failed).
;;;; Then:
;;;;
;;;;   1. with the inherited configuration alone, the registry must find the
;;;;      decoy -- otherwise the test would prove nothing;
;;;;   2. after tools/checkout-source-registry.lisp and the LOAD-ASD every
;;;;      test lane does, FIND-SYSTEM must answer the checkout for each of
;;;;      our systems -- the primary, a secondary one, a test system, the
;;;;      separate .asd files -- never the decoy.
;;;;
;;;; Before the fix, step 2 answered the decoy for every one of them.

(in-package "COMMON-LISP-USER")

(defparameter *crt-subproject*
  (uiop:pathname-parent-directory-pathname
   (uiop:pathname-directory-pathname *load-truename*))
  "The clautolisp subproject directory of this checkout.")

(defparameter *crt-decoy-share*
  (or (uiop:getenv-absolute-directory "CLAUTOLISP_CHECKOUT_REGISTRY_DECOY")
      (progn
        (format *error-output* "~&checkout-registry: run me with `make -C clautolisp test-checkout-registry'~%~
                                ~:*  (CLAUTOLISP_CHECKOUT_REGISTRY_DECOY and CL_SOURCE_REGISTRY unset)~%")
        (uiop:quit 2)))
  "The scratch directory standing for an installed <PREFIX>/share. The
Makefile also points CL_SOURCE_REGISTRY at its common-lisp/systems/.")

(defparameter *crt-decoy-systems*
  '(("clautolisp"
     "(asdf:defsystem \"clautolisp\" :version \"0.0.0\")"
     "(asdf:defsystem \"clautolisp/cador\")"
     "(asdf:defsystem \"clautolisp/cador/tests\")")
    ("tui-core"              "(asdf:defsystem \"tui-core\")")
    ("clautolisp-tui-curses" "(asdf:defsystem \"clautolisp-tui-curses\")")
    ("autolisp-front-end"    "(asdf:defsystem \"autolisp-front-end\")"))
  "(ASD-NAME FORM...) of each decoy .asd file.")

(defun crt-plant-decoy ()
  (let ((systems (merge-pathnames #P"common-lisp/systems/" *crt-decoy-share*)))
    (uiop:delete-directory-tree *crt-decoy-share* :validate t :if-does-not-exist :ignore)
    (ensure-directories-exist systems)
    (dolist (entry *crt-decoy-systems*)
      (with-open-file (out (make-pathname :name (first entry) :type "asd" :defaults systems)
                           :direction :output :if-exists :supersede)
        (format out ";;;; decoy: an installed copy that must NOT win~%~{~A~%~}" (rest entry))))))

(defun crt-under-p (pathname directory)
  "True when PATHNAME names an existing file under DIRECTORY."
  (let ((file (and pathname (probe-file pathname)))
        (directory (probe-file directory)))
    (and file directory (uiop:subpathp file directory) t)))

(defun crt-under-decoy-p (pathname)
  (crt-under-p pathname *crt-decoy-share*))

(defun crt-under-checkout-p (pathname)
  (crt-under-p pathname *crt-subproject*))

(crt-plant-decoy)

;;; 1. The decoy must be visible through the inherited configuration.
(asdf:clear-source-registry)
(asdf:initialize-source-registry)
(let ((found (asdf/source-registry:sysdef-source-registry-search "clautolisp")))
  (unless (crt-under-decoy-p found)
    (format t "~&checkout-registry: BROKEN TEST the inherited registry does not see the decoy (it finds ~S)~%"
            found)
    (uiop:quit 2))
  (format t "~&checkout-registry: inherited registry finds the decoy ~A~%"
          (uiop:native-namestring found)))

;;; 2. What every test lane does, then: our systems come from the checkout.
(load (merge-pathnames #P"tools/checkout-source-registry.lisp" *crt-subproject*))
(asdf:load-asd (merge-pathnames #P"clautolisp.asd" *crt-subproject*))

(let ((failures 0)
      (repository (uiop:pathname-parent-directory-pathname *crt-subproject*)))
  (dolist (name '("clautolisp" "clautolisp/cador" "clautolisp/cador/tests"
                  "clautolisp/drawing" "tui-core" "clautolisp-tui-curses"
                  "autolisp-front-end"))
    (let* ((system (asdf:find-system name nil))
           (file   (and system (asdf:system-source-file system)))
           (ok     (and (not (crt-under-decoy-p file))
                        (crt-under-p file repository))))
      (format t "~&checkout-registry: ~:[FAIL~;ok  ~] ~A -> ~A~%"
              ok name (and file (uiop:native-namestring file)))
      (unless ok (incf failures))))
  (unless (crt-under-checkout-p (ignore-errors
                                (asdf:system-relative-pathname
                                 "clautolisp/drawing" "drawing/template/empty-drawing.dxf")))
    (format t "~&checkout-registry: FAIL the drawing template does not resolve into the checkout~%")
    (incf failures))
  (uiop:delete-directory-tree *crt-decoy-share* :validate t :if-does-not-exist :ignore)
  (if (zerop failures)
      (format t "~&checkout-registry: PASS -- every system resolves to this checkout~%")
      (format t "~&checkout-registry: ~D system(s) resolved OUTSIDE this checkout~%" failures))
  (uiop:quit (if (zerop failures) 0 1)))

;;;; THE END ;;;;
