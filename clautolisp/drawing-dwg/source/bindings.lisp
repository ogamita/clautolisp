(in-package #:clautolisp.drawing.dwg)

;;;; CFFI bindings to the libredwg shim (Phase 17e).
;;;;
;;;; The shim (source/clal_dwg.c) is compiled by the build into
;;;; source/clal_dwg.<dylib|so>, linked against the vendored libredwg
;;;; (which it finds at runtime via an embedded rpath). We bind only
;;;; its two trivial (int, path, path) entry points; no libredwg struct
;;;; layout crosses into Lisp.

(defun %shim-library-pathname ()
  (asdf:system-relative-pathname
   :clautolisp/drawing-dwg
   (format nil "drawing-dwg/source/clal_dwg.~A"
           #+darwin "dylib" #-darwin "so")))

(defvar *shim-loaded* nil)

(defun ensure-shim-loaded ()
  "Load the compiled libredwg shim if it has not been loaded yet.
Signals a clear error if it has not been built (run `make
build-libredwg` in the clautolisp subproject first)."
  (unless *shim-loaded*
    (let ((path (%shim-library-pathname)))
      (unless (probe-file path)
        (error 'drawing-error
               :format-control "the libredwg shim is not built: ~A is missing. ~
Build it with `make build-libredwg` in the clautolisp subproject."
               :format-arguments (list path)))
      (cffi:load-foreign-library path)
      (setf *shim-loaded* t))))

(cffi:defcfun ("clal_dwg_to_dxf" %dwg-to-dxf) :int
  (dwg-path :string) (dxf-path :string))

(cffi:defcfun ("clal_dxf_to_dwg" %dxf-to-dwg) :int
  (dxf-path :string) (dwg-path :string))

;; libredwg error codes >= DWG_ERR_CRITICAL (= DWG_ERR_CLASSESNOTFOUND,
;; 1<<7) mean the conversion failed; lower non-zero codes are warnings.
(defconstant +dwg-err-critical+ 128)
