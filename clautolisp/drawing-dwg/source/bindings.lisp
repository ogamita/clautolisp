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

(defun %native-library-directories (&key override program-dirs dev-dir
                                         installed-libdir)
  "The directories to search, IN ORDER, built from the pieces that name them:

  1. OVERRIDE          -- $CLAUTOLISP_DWG_LIBDIR, an explicit instruction;
  2. PROGRAM-DIRS      -- the RUNNING program's own lib/clautolisp/<os>/<arch>/;
  3. DEV-DIR           -- the development tree (this ASDF system's source/);
  4. INSTALLED-LIBDIR  -- the installed ASDF source prefix.

*The running program's own library comes before the development tree.* That is
the order fix (clautolisp-distributed-native-libraries-not-loaded): a library
shipped BESIDE THE PROGRAM belongs to that program, while a build tree merely
happens to exist on the same machine, and on the Windows runner (2026-09-26)
an installed release loaded the checkout's clal_dwg.dll -- which has no
libredwg.dll beside it -- and could not save a drawing.

A developer loses nothing by this. Running from a checkout, the program is the
host Lisp (or a dev image under tools/clautolisp/bin/), and neither carries a
lib/clautolisp/<os>/<arch>/ of its own, so PROGRAM-DIRS names nothing that
exists and the development tree is still what gets found. What the order
settles is the one case where BOTH exist -- an installed program on a machine
that also has a checkout -- and there the program's own library is the right
answer.

Pure, so the order can be tested without a filesystem or an environment."
  (let ((dirs '()))
    (when override (push override dirs))
    (dolist (dir program-dirs) (push dir dirs))
    (when dev-dir (push dev-dir dirs))
    (when installed-libdir (push installed-libdir dirs))
    (remove-duplicates (nreverse dirs) :test #'equal :from-end t)))

(defun native-library-directories ()
  "Every directory to look in for this platform's native libraries, in the
order %NATIVE-LIBRARY-DIRECTORIES documents: the CLAUTOLISP_DWG_LIBDIR
override, the RUNNING program's own lib/clautolisp/<os>/<arch>/, the
development tree, and the installed ASDF source prefix. A complete installed
release is found through the second of these with no environment variable set
and no ASDF sources present."
  (%native-library-directories
   :override (let ((env (uiop:getenv "CLAUTOLISP_DWG_LIBDIR")))
               (when (and env (plusp (length env)))
                 (uiop:ensure-directory-pathname env)))
   :program-dirs (mapcar (lambda (prefix)
                           (merge-pathnames
                            (format nil "lib/clautolisp/~A/~A/" (%os) (%arch))
                            prefix))
                         (running-program-prefix-candidates))
   :dev-dir (uiop:pathname-directory-pathname
             (asdf:system-relative-pathname
              :clautolisp/drawing-dwg "drawing-dwg/source/x"))
   :installed-libdir (%installed-libdir)))

(defun %candidate-shim-pathnames ()
  (let ((name (%shim-file-name)))
    (mapcar (lambda (dir) (merge-pathnames name dir))
            (native-library-directories))))

(defvar *shim-loaded* nil)

(defun %try-load-shim (path)
  "Try to load the shim at PATH, its MS-Windows dependency first. Returns T
when the library is loaded, else NIL and a one-line reason why this candidate
cannot be used. NEVER signals: the caller goes on to the next candidate.

Windows DLLs carry no rpath/$ORIGIN, so the loader will not find
clal_dwg.dll's import of libredwg.dll just because the two sit in one
directory. Pre-load it by absolute path: once libredwg.dll is in the process
the shim's import resolves to it. On ELF/Mach-O the rpath handles this, so
that part is a no-op there."
  (let ((dir (uiop:pathname-directory-pathname path)))
    (when (uiop:os-windows-p)
      (let ((dep (merge-pathnames "libredwg.dll" dir)))
        (unless (probe-file dep)
          (return-from %try-load-shim
            (values nil (format nil "its dependency libredwg.dll is not beside ~
it in ~A (the release's libraries archive carries both; installing only one ~
cannot work on MS-Windows, where the shim's import is resolved by the loader)"
                                (namestring dir)))))
        (handler-case (cffi:load-foreign-library dep)
          (error (condition)
            (return-from %try-load-shim
              (values nil (format nil "the dynamic loader refused its ~
dependency ~A: ~A" (namestring dep) condition)))))))
    (handler-case (progn (cffi:load-foreign-library path) t)
      (error (condition)
        ;; Present but unloadable: the wrong architecture, a missing
        ;; transitive dependency, a hardened loader.
        (values nil (format nil "the dynamic loader refused it: ~A" condition))))))

(defun %select-usable-shim (candidates &key (probe #'probe-file)
                                            (try #'%try-load-shim))
  "Walk CANDIDATES in order and load the FIRST USABLE one. Returns
(values PATH SKIPPED) where SKIPPED is a list of (PATH . REASON) for the
candidates that existed but could not be used, or (values NIL SKIPPED) when
none worked. PROBE and TRY are injectable so the choice can be tested without
a real library on disk.

*A candidate that EXISTS but cannot be LOADED must not end the search.* That
was the defect, measured on the Windows runner (2026-09-26,
clautolisp-distributed-native-libraries-not-loaded): a complete installed
release found the DEVELOPMENT tree's clal_dwg.dll first -- the ASDF path is
listed before the program's own prefix, which is right for a developer -- and
that copy has no libredwg.dll beside it, so the save failed although the
program's own lib/clautolisp/<os>/<arch>/ carried a complete pair. On ELF the
identical wrong pick is INVISIBLE, because the dev copy's rpath resolves its
dependency: the Linux check had been passing without ever loading the
installed library."
  (let ((skipped '()))
    (dolist (path candidates (values nil (nreverse skipped)))
      (when (funcall probe path)
        (multiple-value-bind (ok reason) (funcall try path)
          (if ok
              (return (values path (nreverse skipped)))
              (push (cons path reason) skipped)))))))

(defun ensure-shim-loaded ()
  "Load the compiled libredwg shim if not yet loaded, searching the
candidate locations. Signals a clear error if no candidate can be used (run
`make build-libredwg`, or set CLAUTOLISP_DWG_LIBDIR)."
  (unless *shim-loaded*
    (let ((candidates (%candidate-shim-pathnames)))
      (multiple-value-bind (path skipped) (%select-usable-shim candidates)
        (cond
          (path
           ;; Say what was passed over. A developer whose own build is
           ;; incomplete must not SILENTLY end up running an installed,
           ;; older library -- that would be a different bug wearing this
           ;; fix as a disguise.
           (dolist (entry skipped)
             (format *error-output*
                     "~&clautolisp: skipped the DWG native library ~A: ~A~%"
                     (namestring (car entry)) (cdr entry)))
           (setf *shim-loaded* t))
          (skipped
           ;; Present but none usable: name every one and the loader's own
           ;; words for it. "no writer codec registered" is what this used
           ;; to look like from the outside.
           (error 'drawing-error
                  :format-control "no usable DWG native library. Tried ~
~{~{~A (~A)~}~^; ~}."
                  :format-arguments
                  (list (mapcar (lambda (entry)
                                  (list (namestring (car entry)) (cdr entry)))
                                skipped))))
          (t
           ;; The four cases the caller must be able to tell apart
           ;; (clautolisp-distributed-native-libraries-not-loaded): the Lisp
           ;; module not activated is now impossible -- it is baked into the
           ;; program -- and the other three each say so, with the pathnames.
           (error 'drawing-error
                  :format-control "the DWG native library ~A was not found. ~
Looked in: ~{~A~^, ~}. A release must ship it under ~
lib/clautolisp/~A/~A/ beside the program; in a checkout build it with ~
`make build-libredwg'. CLAUTOLISP_DWG_LIBDIR overrides the search."
                  :format-arguments (list (%shim-file-name) candidates
                                          (%os) (%arch)))))))))

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
