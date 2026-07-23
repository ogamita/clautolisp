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

;;; --- platform backends (vl-registry.issue, re-opened) ---------------------
;;;
;;; Three targets, matching how the real products store vl-registry data:
;;;   windows: THE Windows registry, through reg.exe (present on every
;;;            Windows; the "win32" quicklisp library named in the issue is
;;;            not in the dist — only cl-win32-errors — so the stable
;;;            documented CLI is used; swap to FFI bindings when pjb points
;;;            at the exact system).
;;;   darwin:  the macOS defaults database (NSUserDefaults), through
;;;            /usr/bin/defaults, domain org.clautolisp.vl-registry, flat
;;;            keys "REGPATH|VALUENAME" (BricsCAD-style plist mapping).
;;;   unix:    the sexp store above ($XDG_CONFIG_HOME/clautolisp/registry.sexp).

(defun %run-lines (command)
  "Run COMMAND (a list); return (values output-lines exit-code)."
  (multiple-value-bind (out err code)
      (uiop:run-program command :output '(:string :stripped t)
                                :error-output nil :ignore-error-status t)
    (declare (ignore err))
    (values (if (and out (plusp (length out)))
                ;; strip the CR of CRLF line endings (reg.exe output on
                ;; Windows), else parsed values come back as "v1\r"
                (mapcar (lambda (line) (string-right-trim '(#\Return) line))
                        (uiop:split-string out :separator '(#\Newline)))
                '())
            code)))

#+(or win32 windows mswindows os-windows)
(progn
  (defun %reg-read (key value-name)
    (multiple-value-bind (lines code)
        (%run-lines (append (list "reg" "query" key)
                            (if value-name (list "/v" value-name) (list "/ve"))))
      (when (zerop code)
        (loop for line in lines
              for pos = (search "REG_SZ" line)
              when pos
                do (return (string-trim '(#\Space #\Tab)
                                        (subseq line (+ pos (length "REG_SZ")))))))))
  (defun %reg-write (key value-name value)
    (multiple-value-bind (lines code)
        (%run-lines (append (list "reg" "add" key)
                            (if value-name (list "/v" value-name) (list "/ve"))
                            (list "/t" "REG_SZ" "/d" value "/f")))
      (declare (ignore lines))
      (when (zerop code) value)))
  (defun %reg-delete (key value-name)
    (multiple-value-bind (lines code)
        (%run-lines (append (list "reg" "delete" key)
                            (when value-name (list "/v" value-name))
                            (list "/f")))
      (declare (ignore lines))
      (zerop code)))
  (defun %reg-descendents (key value-names-p)
    (multiple-value-bind (lines code) (%run-lines (list "reg" "query" key))
      (when (zerop code)
        (if value-names-p
            (loop for line in lines
                  for trimmed = (string-trim '(#\Space #\Tab) line)
                  for pos = (search "    REG_" line)
                  when (and pos (plusp (length trimmed))
                            (not (string-equal key trimmed)))
                    collect (string-trim '(#\Space #\Tab) (subseq line 0 pos))
                      into names
                  finally (return (sort (delete-duplicates names :test #'string-equal)
                                        #'string-lessp)))
            ;; reg query echoes EXPANDED key paths (HKEY_CURRENT_USER\…,
            ;; not HKCU\…) and, without /s, lists only immediate sub-keys:
            ;; collect the last path segment of each key line.
            (loop for line in lines
                  when (and (> (length line) 5)
                            (string-equal "HKEY_" line :end2 5)
                            (find #\\ line))
                    collect (subseq line (1+ (position #\\ line :from-end t)))
                      into subs
                  finally (return (sort (delete-duplicates subs :test #'string-equal)
                                        #'string-lessp))))))))

#+darwin
(progn
  (defparameter +defaults-domain+ "org.clautolisp.vl-registry")
  (defun %dflt-key (key value-name)
    (format nil "~A|~A" key (or value-name "")))
  (defun %dflt-read (key value-name)
    (multiple-value-bind (lines code)
        (%run-lines (list "defaults" "read" +defaults-domain+
                          (%dflt-key key value-name)))
      (when (zerop code) (format nil "~{~A~^~%~}" lines))))
  (defun %dflt-write (key value-name value)
    (multiple-value-bind (lines code)
        (%run-lines (list "defaults" "write" +defaults-domain+
                          (%dflt-key key value-name) "-string" value))
      (declare (ignore lines))
      (when (zerop code) value)))
  (defun %dflt-all-keys ()
    "Every stored flat key, parsed from the exported XML plist."
    (multiple-value-bind (lines code)
        (%run-lines (list "defaults" "export" +defaults-domain+ "-"))
      (when (zerop code)
        (loop for line in lines
              for start = (search "<key>" line)
              for end = (and start (search "</key>" line))
              when (and start end)
                collect (subseq line (+ start 5) end)))))
  (defun %dflt-delete (key value-name)
    (if value-name
        (multiple-value-bind (lines code)
            (%run-lines (list "defaults" "delete" +defaults-domain+
                              (%dflt-key key value-name)))
          (declare (ignore lines))
          (zerop code))
        (let ((prefix (concatenate 'string key "|")) (any nil))
          (dolist (k (%dflt-all-keys) any)
            (when (and (>= (length k) (length prefix))
                       (string-equal prefix k :end2 (length prefix)))
              (%run-lines (list "defaults" "delete" +defaults-domain+ k))
              (setf any t))))))
  (defun %dflt-descendents (key value-names-p)
    (let ((names '()))
      (dolist (k (%dflt-all-keys))
        (let ((bar (position #\| k :from-end t)))
          (when bar
            (let ((path (subseq k 0 bar)) (vname (subseq k (1+ bar))))
              (if value-names-p
                  (when (string-equal path key) (pushnew vname names :test #'string-equal))
                  (let ((prefix (concatenate 'string (string-right-trim "\\" key) "\\")))
                    (when (and (> (length path) (length prefix))
                               (string-equal prefix path :end2 (length prefix)))
                      (let ((rest (subseq path (length prefix))))
                        (pushnew (subseq rest 0 (position #\\ rest))
                                 names :test #'string-equal)))))))))
      (sort names #'string-lessp))))

(defmethod host-registry-read ((host mock-host) key value-name)
  #+(or win32 windows mswindows os-windows) (%reg-read key value-name)
  #-(or win32 windows mswindows os-windows)
  (progn
    #+darwin (%dflt-read key value-name)
    #-darwin
    (let ((values (gethash key (%registry))))
      (and values (gethash (%registry-value-name value-name) values)))))

(defmethod host-registry-write ((host mock-host) key value-name value)
  #+(or win32 windows mswindows os-windows) (%reg-write key value-name value)
  #-(or win32 windows mswindows os-windows)
  (progn
    #+darwin (%dflt-write key value-name value)
    #-darwin
    (let* ((registry (%registry))
           (values (or (gethash key registry)
                       (setf (gethash key registry)
                             (make-hash-table :test #'equalp)))))
      (setf (gethash (%registry-value-name value-name) values) value)
      (%registry-save)
      value)))

(defmethod host-registry-delete ((host mock-host) key value-name)
  #+(or win32 windows mswindows os-windows) (%reg-delete key value-name)
  #-(or win32 windows mswindows os-windows)
  (progn
    #+darwin (%dflt-delete key value-name)
    #-darwin
    (let* ((registry (%registry))
           (values (gethash key registry))
           (deleted
             (cond
               ((null values) nil)
               (value-name (remhash value-name values))
               (t (remhash key registry)))))
      (when deleted (%registry-save))
      deleted)))

(defmethod host-registry-descendents ((host mock-host) key value-names-p)
  #+(or win32 windows mswindows os-windows) (%reg-descendents key value-names-p)
  #-(or win32 windows mswindows os-windows)
  (progn
    #+darwin (%dflt-descendents key value-names-p)
    #-darwin
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
            (sort subkeys #'string-lessp))))))
