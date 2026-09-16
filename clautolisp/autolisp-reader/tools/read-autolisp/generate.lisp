(in-package "COMMON-LISP-USER")

;;; THE CCL KERNEL EATS SOME OF THE PROGRAM'S ARGUMENTS
;;; (alfe-ccl-executable-drops-log-output.issue).
;;;
;;; Before any Lisp code runs, the CCL kernel (pmcl-kernel.c,
;;; process_options) scans the whole argv of EVERY executable, a
;;; save-application image with a prepended kernel included, and removes
;;; its own options:
;;;   -d --debug  -b --batch  --no-sigtrap  --avx  --no-avx
;;;   -I --image-name, -R --heap-reserve, -S --stack-size,
;;;   -Z --thread-stack-size  (each with a value; -I/-R/-S/-Z also match
;;;                            as prefixes: -Sfoo)
;;; It stops only at `--'. Every argument that starts with `-' is
;;; checked, including values given to our own options. So `alfe-ccl -d'
;;; and `clautolisp-ccl --debug' never saw their -d/--debug, which is a
;;; shared CLI option, and ran at the default verbosity.
;;;
;;; The kernel only rewrites its pointer array; the OS keeps the
;;; original command line:
;;;   - procfs: /proc/self/cmdline (Linux), /proc/curproc/cmdline
;;;     (FreeBSD, when procfs is mounted);
;;;   - macOS has no /proc: sysctl KERN_PROCARGS2 returns the same bytes
;;;     behind a header.
;;; Where neither is available (Windows), the kernel's list is used as
;;; before.

(defun %split-nul-strings (octets decode &key (start 0) (end (length octets))
                                              count)
  "The NUL-terminated strings in OCTETS from START to END, decoded with
DECODE (octets start end -> string). A final string without a NUL counts
too. Stops after COUNT strings when COUNT is given."
  (let ((strings '())
        (from start))
    (loop for i from start below end
          while (or (null count) (< (length strings) count))
          when (zerop (aref octets i))
            do (push (funcall decode octets from i) strings)
               (setf from (1+ i)))
    (when (and (< from end)
               (or (null count) (< (length strings) count)))
      (push (funcall decode octets from end) strings))
    (nreverse strings)))

(defun %parse-procargs2 (octets decode)
  "The argv in a macOS KERN_PROCARGS2 block:
  argc (a native-endian 32-bit int), the executable path and its NUL,
  NUL padding, then argc NUL-terminated strings (the environment after).
Returns NIL when the block does not have that shape."
  (when (>= (length octets) 4)
    (let* ((argc #+(or little-endian-target little-endian)
                 (logior (aref octets 0) (ash (aref octets 1) 8)
                         (ash (aref octets 2) 16) (ash (aref octets 3) 24))
                 #-(or little-endian-target little-endian)
                 (logior (aref octets 3) (ash (aref octets 2) 8)
                         (ash (aref octets 1) 16) (ash (aref octets 0) 24)))
           (path-end (position 0 octets :start 4))
           (args-start (and path-end
                            (position-if #'plusp octets :start path-end))))
      (when (and args-start (< 0 argc 100000))
        (let ((args (%split-nul-strings octets decode
                                        :start args-start :count argc)))
          (when (= (length args) argc)
            args))))))

#+ccl
(defun %utf-8-decoder (octets start end)
  (ccl:decode-string-from-octets octets :start start :end end
                                        :external-format :utf-8))

#+ccl
(defun %read-file-octets (path)
  (with-open-file (in path :element-type '(unsigned-byte 8))
    ;; procfs files report length 0: read to EOF.
    (let ((buffer (make-array 256 :element-type '(unsigned-byte 8)
                                  :adjustable t :fill-pointer 0)))
      (loop for byte = (read-byte in nil)
            while byte
            do (vector-push-extend byte buffer))
      (coerce buffer '(simple-array (unsigned-byte 8) (*))))))

#+(and ccl darwin)
(defun %darwin-procargs2 ()
  "The raw KERN_PROCARGS2 block of this process, or NIL."
  (let ((ctl-kern 1)
        (kern-procargs2 49))
    (ccl:%stack-block ((mib 12) (size 8))
      (setf (ccl:%get-signed-long mib 0) ctl-kern
            (ccl:%get-signed-long mib 4) kern-procargs2
            (ccl:%get-signed-long mib 8) (ccl::getpid))
      (setf (ccl:%get-unsigned-long size 0) 0
            (ccl:%get-unsigned-long size 4) 0)
      ;; First call: the size of the block.
      (when (zerop (ccl:external-call "sysctl"
                                      :address mib :unsigned-fullword 3
                                      :address (ccl:%null-ptr) :address size
                                      :address (ccl:%null-ptr)
                                      :unsigned-doubleword 0
                                      :signed-fullword))
        (let ((n (ccl:%get-unsigned-long size 0)))
          ;; kern.argmax is about 1 MB: heap, not stack.
          (when (< 0 n (* 16 1024 1024))
            (let ((buffer (ccl::malloc n)))
              (unless (ccl:%null-ptr-p buffer)
                (unwind-protect
                     (when (zerop (ccl:external-call "sysctl"
                                                     :address mib
                                                     :unsigned-fullword 3
                                                     :address buffer
                                                     :address size
                                                     :address (ccl:%null-ptr)
                                                     :unsigned-doubleword 0
                                                     :signed-fullword))
                       (let* ((got (min n (ccl:%get-unsigned-long size 0)))
                              (octets (make-array got
                                                  :element-type '(unsigned-byte 8))))
                         (dotimes (i got octets)
                           (setf (aref octets i)
                                 (ccl:%get-unsigned-byte buffer i)))))
                  (ccl:free buffer))))))))))

#+ccl
(defun %ccl-os-argv ()
  "The command line as the OS received it, as a list of strings, or NIL
when it cannot be read."
  (or (loop for path in '("/proc/self/cmdline" "/proc/curproc/cmdline")
            for args = (ignore-errors
                        (%split-nul-strings (%read-file-octets path)
                                            #'%utf-8-decoder))
            when args return args)
      #+darwin
      (ignore-errors
       (let ((block (%darwin-procargs2)))
         (and block (%parse-procargs2 block #'%utf-8-decoder))))))

(defun %subsequence-p (short long)
  "True when SHORT is LONG with some elements removed, order kept."
  (loop for item in short
        for tail = (member item long :test #'string=)
          then (member item (rest tail) :test #'string=)
        always tail))

(defun argv ()
  #+ccl
  (let ((kernel-argv ccl:*command-line-argument-list*)
        (os-argv (%ccl-os-argv)))
    ;; Only when the OS list is recognisably the same command line, with
    ;; the kernel's removals the only difference. Otherwise (unreadable,
    ;; undecodable, or anything unexpected) keep the kernel's list.
    (if (and os-argv
             (string= (first os-argv) (first kernel-argv))
             (%subsequence-p kernel-argv os-argv))
        os-argv
        kernel-argv))
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

(defun executable-program-name (program-name)
  "Return PROGRAM-NAME with a platform-appropriate executable suffix.

On Windows, SAVE-LISP-AND-DIE :EXECUTABLE T does NOT reliably append
.exe itself -- confirmed on the GitLab Windows runner, 2026-08-20:
build-alfe-sbcl wrote a plain, extension-less `alfe-sbcl' image (56 MB,
so the build itself was fine) despite :EXECUTABLE T, which then made
every downstream reference to `alfe-sbcl.exe' (the CI --version probe,
and presumably any user expecting a double-clickable / PATH-resolved
binary) fail with a plain \"file not found\", not a build error. Do not
trust the implementation to add the suffix; ask for it explicitly."
  (if (and (uiop:os-windows-p)
           (not (string-equal ".exe" program-name
                               :start2 (max 0 (- (length program-name) 4)))))
      (concatenate 'string program-name ".exe")
      program-name))

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
  (let ((program-name (executable-program-name program-name)))
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
           #-sb-core-compression '())))
