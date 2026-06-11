(in-package "COMMON-LISP-USER")

(defun argv ()
  #+ccl ccl:*command-line-argument-list*
  #+sbcl sb-ext:*posix-argv*
  #-(or ccl sbcl) (error "Unsupported Lisp implementation."))

(defun load-quicklisp ()
  (let ((setup (merge-pathnames #P"quicklisp/setup.lisp" (user-homedir-pathname))))
    (when (probe-file setup)
      (load setup))))

(defun configure-asdf-directories (directories)
  (if (member :asdf3 *features*)
      (asdf:initialize-source-registry
       `(:source-registry
         :ignore-inherited-configuration
         ,@(mapcar (lambda (dir) `(:directory ,dir)) directories)
         :default-registry))
      (setf asdf:*central-registry* directories)))

(defun make-toplevel-function (main-function-name)
  (let ((form `(lambda ()
                 (handler-case
                     (progn
                       (apply (read-from-string ,main-function-name)
                              (argv)))
                   (error (err)
                     (finish-output *standard-output*)
                     (finish-output *trace-output*)
                     (format *error-output* "~&~A~%" err)
                     (finish-output *error-output*)
                     #+ccl (ccl:quit 1)
                     #+sbcl (sb-ext:exit :code 1)))
                 #+ccl (ccl:quit 0)
                 #+sbcl (sb-ext:exit :code 0))))
    #-ecl (coerce form 'function)))

(defvar *warning-tally* nil
  "List of (CLASS . MESSAGE) cells accumulated by the build-time
warning handler. Reset and inspected by LOAD-SYSTEM-WITH-WARNING-REPORT
around each load. Lets us print a cross-implementation summary at the
end of the build, so a developer can spot conditions one CL reports
that the others don't (the whole reason we build under multiple
implementations).")

(defun build-strict-p ()
  "True iff the build should fail when compilation reports any
WARNING (or worse — but ERROR halts the build naturally either way).
STYLE-WARNING is reported but never fatal; it's frequently triggered
by transitive deps and rarely actionable inside the build script."
  (let ((env (uiop:getenv "CLAUTOLISP_STRICT_BUILD")))
    (and env (not (zerop (length env))))))

(defun record-warning (condition)
  (push (cons (type-of condition)
              (princ-to-string condition))
        *warning-tally*))

(defun report-warning-tally (system-name)
  (when *warning-tally*
    (let* ((rows (reverse *warning-tally*))
           (warnings       (count-if (lambda (row)
                                       (subtypep (car row) 'warning))
                                     rows))
           (style-warnings (count-if (lambda (row)
                                       (subtypep (car row) 'style-warning))
                                     rows))
           (hard-warnings  (- warnings style-warnings)))
      (format *error-output*
              "~&;;; ~A build: ~D warning~:P (~D STYLE-WARNING, ~D WARNING).~%~
                 ;;; Implementation: ~A ~A~%"
              system-name (length rows) style-warnings hard-warnings
              (lisp-implementation-type) (lisp-implementation-version))
      (when (and (build-strict-p) (plusp hard-warnings))
        (format *error-output*
                "~&;;; CLAUTOLISP_STRICT_BUILD=1 set and ~D non-style WARNING~:P seen — aborting build.~%"
                hard-warnings)
        (finish-output *error-output*)
        #+sbcl (sb-ext:exit :code 2)
        #+ccl  (ccl:quit 2)))))

(defun load-system-with-quicklisp-fetch (system-name)
  "Load SYSTEM-NAME, asking Quicklisp to fetch transitive deps
that aren't already on disk. Falls back to plain ASDF:LOAD-SYSTEM
when Quicklisp isn't loaded (a host that pre-installs every dep
via OS packages, say).

Wraps the load in a handler-bind that records every WARNING and
STYLE-WARNING the compiler signals — see *WARNING-TALLY* /
REPORT-WARNING-TALLY for the cross-impl rationale. Conditions are
recorded then passed through (no MUFFLE-WARNING) so the normal
build log still shows them. CLAUTOLISP_STRICT_BUILD=1 in the env
turns the post-load tally into a hard failure when any non-style
WARNING was signalled."
  (let ((*warning-tally* nil)
        (ql-package (find-package :ql)))
    (unwind-protect
         (handler-bind
             ((warning #'record-warning))
           (if ql-package
               (funcall (intern (symbol-name '#:quickload) ql-package)
                        system-name)
               (asdf:load-system system-name)))
      (report-warning-tally system-name))))

(defun generate-program (&key program-name main-function system-name source-directory
                           asdf-directories release-directory asd-file)
  (declare (ignore source-directory))
  (load-quicklisp)
  (require :asdf)
  (configure-asdf-directories asdf-directories)
  (when asd-file
    (asdf:load-asd asd-file))
  (load-system-with-quicklisp-fetch system-name)
  ;; Make sure the bin/ directory exists before SAVE-LISP-AND-DIE /
  ;; SAVE-APPLICATION tries to write into it. Locally the directory
  ;; usually pre-exists from a prior build; in CI on a fresh clone
  ;; it doesn't (git doesn't track empty directories), and the save
  ;; would otherwise error with "no such file or directory" /
  ;; SB-IMPL::SAVE-ERROR.
  (ensure-directories-exist release-directory)
  #+ccl
  (ccl:save-application
   (merge-pathnames program-name release-directory nil)
   :toplevel-function (make-toplevel-function main-function)
   :mode #o755
   :prepend-kernel t
   :error-handler t)
  #+sbcl
  ;; :COMPRESSION is only accepted when the running SBCL was built with
  ;; core compression support (feature :SB-CORE-COMPRESSION, which in
  ;; turn requires libzstd at build time). On platforms where zstd is
  ;; unavailable SBCL ships without that feature and passing :COMPRESSION
  ;; signals an error, so we gate the keyword on the feature and fall
  ;; back to an uncompressed (larger) executable image.
  (apply #'sb-ext:save-lisp-and-die
         (namestring (merge-pathnames program-name release-directory nil))
         :executable t
         :save-runtime-options t
         :toplevel (make-toplevel-function main-function)
         #+sb-core-compression (list :compression 9)
         #-sb-core-compression '()))
