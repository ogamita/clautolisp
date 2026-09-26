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
ancestor of <PREFIX>/share/common-lisp/source/clautolisp/.

This one needs the ASDF SOURCES to be installed. A release that ships
only the programs and the libraries has none, which is why it is no
longer the only installed candidate -- see
RUNNING-PROGRAM-PREFIX-CANDIDATES."
  (let* ((src (asdf:system-source-directory :clautolisp/drawing-dwg))
         (s   (and src (namestring src)))
         (marker "/share/common-lisp/source/")
         (pos (and s (search marker s))))
    (when pos
      (merge-pathnames
       (format nil "lib/clautolisp/~A/~A/" (%os) (%arch))
       (subseq s 0 (1+ pos))))))           ; PREFIX/ (keep trailing slash)

(defun running-program-pathname ()
  "Absolute pathname of the RUNNING program, or NIL when the
implementation does not say. The one implementation-specific spot here;
everything else works from its value.

clautolisp-distributed-native-libraries-not-loaded: a native library
shipped beside the program must be found from the PROGRAM, because a
release is staged, archived and unpacked under an arbitrary prefix, and
the prefix is only known at run time."
  (ignore-errors
   (let ((path #+sbcl sb-ext:*runtime-pathname*
               #+ccl  (and (find-symbol "KERNEL-PATH" "CCL")
                           (funcall (find-symbol "KERNEL-PATH" "CCL")))
               #-(or sbcl ccl) nil))
     (when (and path (probe-file path))
       (truename path)))))

(defun running-program-prefix-candidates (&optional (exe (running-program-pathname)))
  "The installation prefixes EXE can belong to, most specific first, as
directory pathnames. Two layouts ship today, the same two alfe's
INSTALLATION-PREFIXES knows:

  <PREFIX>/libexec/.../clautolisp-<lisp>[.exe]  (below libexec, per
      platform and processor, reached through the bin/ trampoline, which
      does not pass the prefix on)
  <PREFIX>/bin/clautolisp-<lisp>[.exe]          (the plain layout)

REUSE POINT: the next distributed native extension should call this
rather than grow its own copy; it is deliberately free of any DWG
knowledge. (It lives here because drawing-dwg is the first and only
caller; the natural home once there are two is clautolisp/configuration.)
Components compare case-insensitively, so LIBEXEC and libexec are the
same directory on MS-Windows."
  (when exe
    (let* ((dir (pathname-directory exe))
           (n (length dir))
           (prefixes '()))
      (flet ((prefix (drop)
               (when (and (> (- n drop) 0) (<= drop n))
                 (make-pathname :directory (subseq dir 0 (- n drop))
                                :name nil :type nil :version nil
                                :defaults exe))))
        (let ((pos (position-if (lambda (c)
                                  (and (stringp c) (string-equal c "libexec")))
                                dir :from-end t)))
          (when (and pos (> pos 0) (< pos n))
            (push (make-pathname :directory (subseq dir 0 pos)
                                 :name nil :type nil :version nil
                                 :defaults exe)
                  prefixes)))
        ;; <PREFIX>/bin/<exe>  ->  <PREFIX>/
        (let ((last (and (> n 0) (car (last dir)))))
          (when (and (stringp last) (string-equal last "bin"))
            (let ((p (prefix 1))) (when p (push p prefixes)))))
        (nreverse prefixes)))))

(defun native-library-directories ()
  "Every directory to look in for this platform's native libraries, most
specific first: the CLAUTOLISP_DWG_LIBDIR override, the development
tree, the prefixes of the RUNNING program, and the installed ASDF source
prefix. A complete installed release is found through the third of these
with no environment variable set and no ASDF sources present."
  (let ((dirs '()))
    (let ((env (uiop:getenv "CLAUTOLISP_DWG_LIBDIR")))
      (when (and env (plusp (length env)))
        (push (uiop:ensure-directory-pathname env) dirs)))
    (push (uiop:pathname-directory-pathname
           (asdf:system-relative-pathname
            :clautolisp/drawing-dwg "drawing-dwg/source/x"))
          dirs)
    (dolist (prefix (running-program-prefix-candidates))
      (push (merge-pathnames (format nil "lib/clautolisp/~A/~A/" (%os) (%arch))
                             prefix)
            dirs))
    (let ((libdir (%installed-libdir)))
      (when libdir (push libdir dirs)))
    (remove-duplicates (nreverse dirs) :test #'equal :from-end t)))

(defun %candidate-shim-pathnames ()
  (let ((name (%shim-file-name)))
    (mapcar (lambda (dir) (merge-pathnames name dir))
            (native-library-directories))))

(defvar *shim-loaded* nil)

(defun ensure-shim-loaded ()
  "Load the compiled libredwg shim if not yet loaded, searching the
candidate locations. Signals a clear error if it cannot be found (run
`make build-libredwg`, or set CLAUTOLISP_DWG_LIBDIR)."
  (unless *shim-loaded*
    (let* ((candidates (%candidate-shim-pathnames))
           (path (find-if #'probe-file candidates)))
      ;; The four cases the caller must be able to tell apart
      ;; (clautolisp-distributed-native-libraries-not-loaded): the Lisp
      ;; module not activated is now impossible -- it is baked into the
      ;; program -- and the other three each say so, with the pathnames.
      (unless path
        (error 'drawing-error
               :format-control "the DWG native library ~A was not found. ~
Looked in: ~{~A~^, ~}. A release must ship it under ~
lib/clautolisp/~A/~A/ beside the program; in a checkout build it with ~
`make build-libredwg'. CLAUTOLISP_DWG_LIBDIR overrides the search."
               :format-arguments (list (%shim-file-name) candidates
                                       (%os) (%arch))))
      ;; Windows DLLs carry no rpath/$ORIGIN, so the dynamic loader will
      ;; not find clal_dwg.dll's dependency libredwg.dll just because it
      ;; sits next to the shim. Pre-load it by absolute path first: once
      ;; libredwg.dll is in the process the shim's import resolves to it.
      ;; (On ELF/Mach-O the rpath handles this, so this is a no-op there.)
      (when (uiop:os-windows-p)
        (let ((dep (merge-pathnames "libredwg.dll"
                                    (uiop:pathname-directory-pathname path))))
          (unless (probe-file dep)
            (error 'drawing-error
                   :format-control "the DWG native library ~A is installed ~
but its dependency libredwg.dll is not beside it in ~A. The release's ~
libraries archive carries both; installing only one cannot work on ~
MS-Windows, where the shim's import is resolved by the loader."
                   :format-arguments
                   (list (namestring path)
                         (namestring (uiop:pathname-directory-pathname path)))))
          (handler-case (cffi:load-foreign-library dep)
            (error (condition)
              (error 'drawing-error
                     :format-control "the dynamic loader refused ~A: ~A"
                     :format-arguments (list (namestring dep) condition))))))
      (handler-case (cffi:load-foreign-library path)
        (error (condition)
          ;; Present but unloadable: the wrong architecture, a missing
          ;; transitive dependency, a hardened loader. Say which file and
          ;; give the loader's own words -- "no writer codec registered"
          ;; is what this used to look like from the outside.
          (error 'drawing-error
                 :format-control "the dynamic loader refused the DWG native ~
library ~A: ~A"
                 :format-arguments (list (namestring path) condition))))
      (setf *shim-loaded* t))))

;;; libredwg's error codes are a bit set (third-party/libredwg/include/dwg.h,
;;; enum Dwg_Error). Reporting the number alone -- "error code 2048" -- told a
;;; user nothing and cost a bisection to interpret; the names do the work
;;; (dwg-write-rejects-a-drawing-built-in-memory).
(defparameter *dwg-error-names*
  '((1 . "WRONGCRC") (2 . "NOTYETSUPPORTED") (4 . "UNHANDLEDCLASS")
    (8 . "INVALIDTYPE") (16 . "INVALIDHANDLE") (32 . "INVALIDEED")
    (64 . "VALUEOUTOFBOUNDS") (128 . "CLASSESNOTFOUND")
    (256 . "SECTIONNOTFOUND") (512 . "PAGENOTFOUND") (1024 . "INTERNALERROR")
    (2048 . "INVALIDDWG") (4096 . "IOERROR") (8192 . "OUTOFMEM"))
  "libredwg's Dwg_Error bits, by value.")

(defun dwg-error-text (rc)
  "RC as libredwg's own error names, e.g. 2048 -> \"DWG_ERR_INVALIDDWG\" and
2049 -> \"DWG_ERR_WRONGCRC|DWG_ERR_INVALIDDWG\". Falls back to the number
for a bit this libredwg does not name."
  (if (zerop rc)
      "DWG_NOERR"
      (let ((parts '()) (rest rc))
        (dolist (entry *dwg-error-names*)
          (when (logtest rc (car entry))
            (push (format nil "DWG_ERR_~A" (cdr entry)) parts)
            (setf rest (logandc2 rest (car entry)))))
        (when (plusp rest)
          (push (format nil "unnamed bits ~D" rest) parts))
        (format nil "~{~A~^|~}" (nreverse parts)))))

(cffi:defcfun ("clal_dwg_to_dxf" %dwg-to-dxf) :int
  (dwg-path :string) (dxf-path :string))

(cffi:defcfun ("clal_dxf_to_dwg" %dxf-to-dwg) :int
  (dxf-path :string) (dwg-path :string))

;; libredwg error codes >= DWG_ERR_CRITICAL (= DWG_ERR_CLASSESNOTFOUND,
;; 1<<7) mean the conversion failed; lower non-zero codes are warnings.
(defconstant +dwg-err-critical+ 128)
