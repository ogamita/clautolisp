;;;; autolisp-front-end/source/workdir.lisp
;;;;
;;;; Per-run WORKDIR helpers. The spec section "Variables
;;;; d'environnement" describes the workdir contract:
;;;;
;;;;   $AUTOLISP_WORKDIR or --workdir DIR overrides the auto-generated
;;;;   location; otherwise alfe builds a unique directory under
;;;;   $TMPDIR (or /tmp on POSIX, %TEMP% on Windows) named
;;;;   `alfe-<backend>-<pid>-<random>`. CAD backends additionally
;;;;   create a `protocol/` subdir for the file-IPC slots; the
;;;;   clautolisp backend only uses the directory for logs and
;;;;   --dry-run symmetry.
;;;;
;;;; Cleanup is driven by alfe.backend:cleanup-workdir, which respects
;;;; the $AUTOLISP_KEEP_WORKDIR escape hatch.

(defpackage #:alfe.workdir
  (:use #:cl)
  (:export #:default-workdir-root
           #:make-fresh-workdir
           #:ensure-subdir
           #:remove-workdir
           #:keep-workdir-env-set-p))

(in-package #:alfe.workdir)

(defun default-workdir-root ()
  "Return the directory under which fresh per-run workdirs are
created. Honors $TMPDIR / %TEMP% if set; otherwise falls back to
/tmp. The result always ends in a directory separator."
  (let ((env (or (uiop:getenv "TMPDIR")
                 (uiop:getenv "TEMP")
                 (uiop:getenv "TMP"))))
    (uiop:ensure-directory-pathname
     (or env "/tmp"))))

(defun random-tag (&optional (length 6))
  "Six lowercase alphanumerics — enough to make collisions in a
single second statistically improbable for interactive use, short
enough to keep workdir names readable in logs."
  (let ((alphabet "abcdefghijklmnopqrstuvwxyz0123456789"))
    (with-output-to-string (out)
      (dotimes (_ length)
        (write-char (char alphabet (random (length alphabet))) out)))))

(defun current-pid ()
  "Return the host process PID via the platform-specific helper.
UIOP does not expose a portable GETPID — every supported Lisp does,
but the symbol lives in an implementation package."
  #+sbcl (sb-posix:getpid)
  #+ccl  (ccl::getpid)
  #-(or sbcl ccl) 0)

(defun make-fresh-workdir (backend-name &key root)
  "Create a unique workdir for BACKEND-NAME (a keyword like
:clautolisp or :bricscad) under ROOT (defaults to DEFAULT-WORKDIR-ROOT).
The directory name is `alfe-<backend>-<pid>-<random>/`. Returns the
absolute pathname."
  (let* ((root-path (uiop:ensure-directory-pathname
                     (or root (default-workdir-root))))
         (pid (current-pid))
         (basename (format nil "alfe-~(~A~)-~D-~A"
                           backend-name pid (random-tag)))
         (path (uiop:ensure-directory-pathname
                (merge-pathnames basename root-path))))
    (ensure-directories-exist path)
    path))

(defun ensure-subdir (workdir name)
  "Ensure WORKDIR/NAME/ exists; return its pathname. NAME may contain
slashes (e.g. \"protocol/incoming\") to nest more than one level."
  (let ((subdir (uiop:ensure-directory-pathname
                 (merge-pathnames name workdir))))
    (ensure-directories-exist subdir)
    subdir))

(defun keep-workdir-env-set-p ()
  "True iff $AUTOLISP_KEEP_WORKDIR is set to a non-empty value.
Used by cleanup-workdir to skip the removal step when the user has
opted to inspect a run's artefacts after the fact."
  (let ((value (uiop:getenv "AUTOLISP_KEEP_WORKDIR")))
    (and value (plusp (length value)))))

(defun remove-workdir (workdir &key keep-p)
  "Recursively remove WORKDIR unless KEEP-P or
$AUTOLISP_KEEP_WORKDIR forbids it. No-op if WORKDIR does not exist."
  (when (or keep-p (keep-workdir-env-set-p))
    (return-from remove-workdir workdir))
  (when (uiop:directory-exists-p workdir)
    (uiop:delete-directory-tree
     workdir :validate t :if-does-not-exist :ignore))
  workdir)
