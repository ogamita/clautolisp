(in-package #:clautolisp.drawing.dwg)

;;;; CFFI bindings to the libredwg shim (Phase 17e).
;;;;
;;;; The shim (source/clal_dwg.c) is compiled by the build into
;;;; clal_dwg.<dylib|so|dll>, linked against the vendored libredwg. The
;;;; shim carries two rpaths (its own dev build dir, and @loader_path /
;;;; $ORIGIN), so it finds libredwg both in the dev tree and when
;;;; installed adjacent to it. We bind only its two trivial
;;;; (int, path, path) entry points; no libredwg struct layout crosses
;;;; into Lisp.
;;;;
;;;; The shim is located by searching, in order:
;;;;   1. $CLAUTOLISP_DWG_LIBDIR                (explicit override)
;;;;   2. the dev tree: <system>/drawing-dwg/source/
;;;;   3. the installed layout: <PREFIX>/lib/clautolisp/<os>/<arch>/,
;;;;      with PREFIX derived from this system's installed source dir
;;;;      (<PREFIX>/share/common-lisp/source/clautolisp/).

(defun %shim-file-name ()
  (format nil "clal_dwg.~A"
          (cond ((uiop:os-windows-p) "dll")
                ((uiop:os-macosx-p)  "dylib")
                (t                   "so"))))

(defun %os () (cond ((uiop:os-macosx-p) "darwin")
                    ((uiop:os-windows-p) "windows")
                    (t "linux")))

(defun %arch ()
  "Canonical arch tag x86-64 / arm64, matching the Makefile REL_ARCH and
dispatch.sh layout. (machine-type) varies by implementation: SBCL gives
\"X86-64\"/\"ARM64\"; others may give \"x86_64\"/\"aarch64\"/\"amd64\"."
  (let ((m (string-downcase (machine-type))))
    (cond ((member m '("x86-64" "x86_64" "amd64" "x8664") :test #'string=) "x86-64")
          ((member m '("arm64" "aarch64") :test #'string=) "arm64")
          (t m))))

(defun %installed-libdir ()
  "The lib/clautolisp/<os>/<arch>/ directory under the PREFIX this
system was installed into, or NIL in a dev checkout. PREFIX is the
ancestor of <PREFIX>/share/common-lisp/source/clautolisp/."
  (let* ((src (asdf:system-source-directory :clautolisp/drawing-dwg))
         (s   (and src (namestring src)))
         (marker "/share/common-lisp/source/")
         (pos (and s (search marker s))))
    (when pos
      (merge-pathnames
       (format nil "lib/clautolisp/~A/~A/" (%os) (%arch))
       (subseq s 0 (1+ pos))))))           ; PREFIX/ (keep trailing slash)

(defun %candidate-shim-pathnames ()
  (let ((name (%shim-file-name)) (cands '()))
    (let ((env (uiop:getenv "CLAUTOLISP_DWG_LIBDIR")))
      (when env (push (merge-pathnames name (uiop:ensure-directory-pathname env)) cands)))
    (push (asdf:system-relative-pathname
           :clautolisp/drawing-dwg (format nil "drawing-dwg/source/~A" name))
          cands)
    (let ((libdir (%installed-libdir)))
      (when libdir (push (merge-pathnames name libdir) cands)))
    (nreverse cands)))

(defvar *shim-loaded* nil)

(defun ensure-shim-loaded ()
  "Load the compiled libredwg shim if not yet loaded, searching the
candidate locations. Signals a clear error if it cannot be found (run
`make build-libredwg`, or set CLAUTOLISP_DWG_LIBDIR)."
  (unless *shim-loaded*
    (let* ((candidates (%candidate-shim-pathnames))
           (path (find-if #'probe-file candidates)))
      (unless path
        (error 'drawing-error
               :format-control "the libredwg shim was not found in any of: ~{~A~^, ~}. ~
Build it with `make build-libredwg`, or set CLAUTOLISP_DWG_LIBDIR."
               :format-arguments (list candidates)))
      ;; Windows DLLs carry no rpath/$ORIGIN, so the dynamic loader will
      ;; not find clal_dwg.dll's dependency libredwg.dll just because it
      ;; sits next to the shim. Pre-load it by absolute path first: once
      ;; libredwg.dll is in the process the shim's import resolves to it.
      ;; (On ELF/Mach-O the rpath handles this, so this is a no-op there.)
      (when (uiop:os-windows-p)
        (let ((dep (merge-pathnames "libredwg.dll"
                                    (uiop:pathname-directory-pathname path))))
          (when (probe-file dep)
            (cffi:load-foreign-library dep))))
      (cffi:load-foreign-library path)
      (setf *shim-loaded* t))))

(cffi:defcfun ("clal_dwg_to_dxf" %dwg-to-dxf) :int
  (dwg-path :string) (dxf-path :string))

(cffi:defcfun ("clal_dxf_to_dwg" %dxf-to-dwg) :int
  (dxf-path :string) (dwg-path :string))

;; libredwg error codes >= DWG_ERR_CRITICAL (= DWG_ERR_CLASSESNOTFOUND,
;; 1<<7) mean the conversion failed; lower non-zero codes are warnings.
(defconstant +dwg-err-critical+ 128)
