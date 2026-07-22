;;;; clautolisp/autolisp-mock-host/source/registry-api.lisp
;;;;
;;;; VL-REGISTRY-* backing for the mock host (vl-registry.issue). On real
;;;; hosts these functions reach the Windows registry, or the macOS defaults
;;;; database (NSUserDefaults); the mock host emulates BOTH with one
;;;; per-user persistent store — a readable sexp file under the XDG config
;;;; directory — so vl-registry-write survives the process like it would on
;;;; a real platform. Keys are registry-style backslash-separated paths,
;;;; case-insensitive like the Windows registry; each key holds named
;;;; values (the default value is the name "").

(in-package #:clautolisp.autolisp-mock-host)

(defvar *mock-registry-path* nil
  "Override for the registry store file (tests point it at a temp file);
NIL means the XDG default $XDG_CONFIG_HOME/clautolisp/registry.sexp.")

(defvar *mock-registry* nil
  "The loaded registry: an EQUALP hash KEY-PATH -> (EQUALP hash
VALUE-NAME -> string); NIL until first use (loaded lazily from the store
file).")

(defvar *mock-registry-loaded-from* nil
  "The path *MOCK-REGISTRY* was loaded from — reloaded when the effective
path changes (tests rebinding *MOCK-REGISTRY-PATH*).")

(defun %registry-store-path ()
  (or *mock-registry-path*
      (merge-pathnames "clautolisp/registry.sexp"
                       (uiop:ensure-directory-pathname
                        (or (uiop:getenv "XDG_CONFIG_HOME")
                            (merge-pathnames ".config/" (user-homedir-pathname)))))))

(defun %registry ()
  "The registry hash, loading the store file on first use (or after the
effective path changed). The on-disk form is an alist
((KEY . ((VALUE-NAME . VALUE) ...)) ...) of strings, read with
*READ-EVAL* nil."
  (let ((path (%registry-store-path)))
    (unless (and *mock-registry* (equal path *mock-registry-loaded-from*))
      (setf *mock-registry* (make-hash-table :test #'equalp)
            *mock-registry-loaded-from* path)
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
                  (setf (gethash (car entry) *mock-registry*) values))))))))
    *mock-registry*))

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

(defmethod host-registry-read ((host mock-host) key value-name)
  (let ((values (gethash key (%registry))))
    (and values (gethash (%registry-value-name value-name) values))))

(defmethod host-registry-write ((host mock-host) key value-name value)
  (let* ((registry (%registry))
         (values (or (gethash key registry)
                     (setf (gethash key registry)
                           (make-hash-table :test #'equalp)))))
    (setf (gethash (%registry-value-name value-name) values) value)
    (%registry-save)
    value))

(defmethod host-registry-delete ((host mock-host) key value-name)
  (let* ((registry (%registry))
         (values (gethash key registry))
         (deleted
           (cond
             ((null values) nil)
             (value-name (remhash value-name values))
             (t (remhash key registry)))))
    (when deleted (%registry-save))
    deleted))

(defmethod host-registry-descendents ((host mock-host) key value-names-p)
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
          (sort subkeys #'string-lessp)))))
