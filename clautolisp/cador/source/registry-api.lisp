;;;; clautolisp/cador/source/registry-api.lisp
;;;;
;;;; VL-REGISTRY-* backing for the cador host (vl-registry.issue). Each
;;;; platform's REAL persistent store, through its binary API by CFFI
;;;; (registry-native.lisp): the Windows registry (advapi32), the macOS
;;;; defaults database (CoreFoundation CFPreferences, domain
;;;; org.clautolisp.vl-registry), and elsewhere a readable sexp file under
;;;; the XDG configuration directory. Keys are registry-style
;;;; backslash-separated paths, case-insensitive like the Windows registry;
;;;; each key holds named values (the default value is the name "").
;;;;
;;;; CLAUTOLISP_REGISTRY_FILE, when set, forces the sexp store at that path
;;;; on every platform -- the test suites set it, so a test never writes a
;;;; developer's or a runner's real registry (lispsys persistence, 2026-10-04).

(in-package #:clautolisp.cador)

(defvar *cador-registry-path* nil
  "Override for the registry store file (tests point it at a temp file);
NIL means the XDG default $XDG_CONFIG_HOME/clautolisp/registry.sexp.")

(defvar *cador-registry* nil
  "The loaded registry: an EQUALP hash KEY-PATH -> (EQUALP hash
VALUE-NAME -> string); NIL until first use (loaded lazily from the store
file).")

(defvar *cador-registry-loaded-from* nil
  "The path *CADOR-REGISTRY* was loaded from — reloaded when the effective
path changes (tests rebinding *CADOR-REGISTRY-PATH*).")

(defun %nonempty-getenv (name)
  "The environment variable NAME, or NIL when unset OR EMPTY (an exported
but empty XDG_CONFIG_HOME must fall back to the default)."
  (let ((value (uiop:getenv name)))
    (and value (plusp (length value)) value)))

(defun %registry-file-override ()
  "CLAUTOLISP_REGISTRY_FILE: the sexp store every platform uses instead of
its real one (the test suites' sandbox), or NIL."
  (%nonempty-getenv "CLAUTOLISP_REGISTRY_FILE"))

(defun %registry-store-path ()
  (or *cador-registry-path*
      (let ((override (%registry-file-override)))
        (and override (pathname override)))
      (merge-pathnames "clautolisp/registry.sexp"
                       (uiop:ensure-directory-pathname
                        (or (%nonempty-getenv "XDG_CONFIG_HOME")
                            (merge-pathnames ".config/" (user-homedir-pathname)))))))

(defun %registry ()
  "The registry hash, loading the store file on first use (or after the
effective path changed). The on-disk form is an alist
((KEY . ((VALUE-NAME . VALUE) ...)) ...) of strings, read with
*READ-EVAL* nil."
  (let ((path (%registry-store-path)))
    (unless (and *cador-registry* (equal path *cador-registry-loaded-from*))
      (setf *cador-registry* (make-hash-table :test #'equalp)
            *cador-registry-loaded-from* path)
      (when (probe-file path)
        (with-open-file (in path :direction :input :external-format :utf-8)
          (let* ((*read-eval* nil)
                 (data (ignore-errors (read in nil nil))))
            (dolist (entry data)
              (when (and (consp entry) (stringp (car entry)))
                (let ((values (make-hash-table :test #'equalp)))
                  (dolist (pair (cdr entry))
                    (when (and (consp pair) (stringp (car pair)))
                      (setf (gethash (car pair) values) (cdr pair))))
                  (setf (gethash (car entry) *cador-registry*) values))))))))
    *cador-registry*))

(defun %registry-save ()
  "Write the registry back to the store file, PRIN1 (readable strings —
the aldo.conf princ-serialisation lesson), sorted for stable diffs."
  (let ((path (%registry-store-path))
        (entries '()))
    (maphash (lambda (key values)
               (let ((pairs '()))
                 (maphash (lambda (name value) (push (cons name value) pairs))
                          values)
                 (push (cons key (sort pairs #'string-lessp :key #'car))
                       entries)))
             (%registry))
    (ensure-directories-exist path)
    (with-open-file (out path :direction :output :if-exists :supersede
                              :if-does-not-exist :create :external-format :utf-8)
      (with-standard-io-syntax
        (let ((*print-readably* nil) (*print-pretty* t))
          (prin1 (sort entries #'string-lessp :key #'car) out)))
      (terpri out))
    path))

(defun %registry-value-name (value-name)
  "NIL names the key's default value, stored under the name \"\"."
  (or value-name ""))

;;; --- platform backends (vl-registry.issue, re-opened) ---------------------
;;;
;;; Three targets, matching how the real products store vl-registry data:
;;;   windows: THE Windows registry, through advapi32 (registry-native.lisp;
;;;            reg.exe until 2026-10-04).
;;;   darwin:  the macOS defaults database, through CoreFoundation
;;;            CFPreferences (registry-native.lisp; /usr/bin/defaults until
;;;            2026-10-04), domain org.clautolisp.vl-registry, flat keys
;;;            "REGPATH|VALUENAME" (BricsCAD-style plist mapping).
;;;   unix:    the sexp store above ($XDG_CONFIG_HOME/clautolisp/registry.sexp).

(defvar *vl-registry-backend*
  #+(or win32 windows mswindows os-windows) :windows
  #+(and darwin (not (or win32 windows mswindows os-windows))) :darwin
  #-(or win32 windows mswindows os-windows darwin) :unix
  "Which vl-registry store cador talks to: :WINDOWS (the real
registry via advapi32), :DARWIN (the defaults database via CFPreferences), :UNIX (the
persistent sexp file). Defaults to the platform; RUNTIME-dispatched so
the unit tests can bind :UNIX and exercise the sexp store on any
platform (the platform verify jobs cover the other two).")

(defun %effective-registry-backend ()
  "*VL-REGISTRY-BACKEND*, or :UNIX when CLAUTOLISP_REGISTRY_FILE sandboxes
the store."
  (if (%registry-file-override) :unix *vl-registry-backend*))

(defmethod host-registry-read ((host cador) key value-name)
  (ecase (%effective-registry-backend)
    (:windows (%reg-read key value-name))
    (:darwin (%dflt-read key value-name))
    (:unix
     (let ((values (gethash key (%registry))))
       (and values (gethash (%registry-value-name value-name) values))))))

(defmethod host-registry-write ((host cador) key value-name value)
  (ecase (%effective-registry-backend)
    (:windows (%reg-write key value-name value))
    (:darwin (%dflt-write key value-name value))
    (:unix
     (let* ((registry (%registry))
           (values (or (gethash key registry)
                       (setf (gethash key registry)
                             (make-hash-table :test #'equalp)))))
       (setf (gethash (%registry-value-name value-name) values) value)
       (%registry-save)
       value))))

(defmethod host-registry-delete ((host cador) key value-name)
  (ecase (%effective-registry-backend)
    (:windows (%reg-delete key value-name))
    (:darwin (%dflt-delete key value-name))
    (:unix
     (let* ((registry (%registry))
           (values (gethash key registry))
           (deleted
             (cond
               ((null values) nil)
               (value-name (remhash value-name values))
               (t (remhash key registry)))))
       (when deleted (%registry-save))
       deleted))))

(defmethod host-registry-descendents ((host cador) key value-names-p)
  (ecase (%effective-registry-backend)
    (:windows (%reg-descendents key value-names-p))
    (:darwin (%dflt-descendents key value-names-p))
    (:unix
     (let ((registry (%registry)))
      (if value-names-p
          (let ((values (gethash key registry)) (names '()))
            (when values
              (maphash (lambda (name value) (declare (ignore value))
                         (push name names))
                       values))
            (sort names #'string-lessp))
          ;; immediate sub-keys: the segment after KEY\ up to the next \
          (let ((prefix (concatenate 'string (string-right-trim "\\" key) "\\"))
                (subkeys '()))
            (maphash
             (lambda (path values)
               (declare (ignore values))
               (when (and (> (length path) (length prefix))
                          (string-equal prefix path :end2 (length prefix)))
                 (let* ((rest (subseq path (length prefix)))
                        (segment (subseq rest 0 (position #\\ rest))))
                   (pushnew segment subkeys :test #'string-equal))))
             registry)
            (sort subkeys #'string-lessp)))))))
