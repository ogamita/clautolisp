(in-package #:clautolisp.cador.tests)

;;;; The command-history log file (cador command-log.lisp): LOGFILEMODE /
;;;; LOGFILEPATH / LOGFILENAME, per dialect, as measured on AutoCAD 2022 and
;;;; BricsCAD V25 / V26 (probes/sources/probe-logfile.lsp, MR !428).

(in-suite cador-suite)

(defun %log-temp-directory ()
  (namestring (uiop:ensure-directory-pathname
               (merge-pathnames (format nil "cador-log-test-~36R/"
                                        (random (expt 36 8) (make-random-state t)))
                                (uiop:temporary-directory)))))

(defmacro %with-log-sandbox ((directory) &body body)
  "BODY with a private registry file and XDG_STATE_HOME, and DIRECTORY bound to
a fresh temporary directory, removed afterwards."
  (let ((saved-registry (gensym)) (saved-state (gensym)))
    `(let* ((,directory (%log-temp-directory))
            (,saved-registry (uiop:getenv "CLAUTOLISP_REGISTRY_FILE"))
            (,saved-state (uiop:getenv "XDG_STATE_HOME")))
       (unwind-protect
            (progn
              (setf (uiop:getenv "CLAUTOLISP_REGISTRY_FILE")
                    (concatenate 'string ,directory "registry.sexp"))
              (setf (uiop:getenv "XDG_STATE_HOME")
                    (concatenate 'string ,directory "state"))
              ,@body)
         (setf (uiop:getenv "CLAUTOLISP_REGISTRY_FILE") (or ,saved-registry ""))
         (setf (uiop:getenv "XDG_STATE_HOME") (or ,saved-state ""))
         (ignore-errors (uiop:delete-directory-tree (pathname ,directory)
                                                    :validate t))))))

(defun %log-setvar (host name value)
  (clautolisp.autolisp-host:host-setvar host name value))

(defun %log-getvar (host name)
  (let ((value (clautolisp.autolisp-host:host-getvar host name)))
    (if (typep value 'autolisp-string) (autolisp-string-value value) value)))

(defun %file-octets (path)
  (with-open-file (in path :element-type '(unsigned-byte 8))
    (let ((octets (make-array (file-length in) :element-type '(unsigned-byte 8))))
      (read-sequence octets in)
      octets)))

(defun %file-text (path)
  (map 'string #'code-char (%file-octets path)))

(defun %log-path-for-comparison (path)
  "Compare log paths independently of the native directory separator.
Keep the original path for opening the actual file."
  (substitute #\/ #\\ path))

(test command-log-autocad-name-header-content-and-encoding
  "AutoCAD: <path>/<drawing>_1<8 hex>.log, a header per opening, the whole
command line, windows-1252; a toggle keeps the file, a new path makes another."
  (%with-log-sandbox (dir)
    (%with-dialect (:autocad-2026)
      (let ((host (make-cador)))
        (clautolisp.cador:apply-command-log-preferences host)
        (%log-setvar host "LOGFILEPATH" (concatenate 'string dir "logs"))
        (is (equal (concatenate 'string dir "logs") (%log-getvar host "LOGFILEPATH"))
            "AutoCAD stores LOGFILEPATH as given")
        (%log-setvar host "LOGFILEMODE" 1)
        (let ((name (%log-getvar host "LOGFILENAME")))
          (is (eql 0 (search (concatenate 'string (%log-path-for-comparison dir)
                                         "logs/Drawing1_1")
                             (%log-path-for-comparison name))))
          (is (= (length (concatenate 'string dir "logs/Drawing1_1xxxxxxxx.log"))
                 (length name)))
          (is (probe-file name) "the log exists as soon as logging is on")
          (clautolisp.cador::cador-write-prompt
           host (format nil "Point ~C: " (code-char 233)))
          (%log-setvar host "LOGFILEMODE" 0)
          (%log-setvar host "LOGFILEMODE" 1)
          (is (equal name (%log-getvar host "LOGFILENAME")) "a toggle keeps the file")
          (%log-setvar host "LOGFILEMODE" 0)
          (let ((text (%file-text name)))
            (is (eql 0 (search "[ AutoCAD - " text)))
            (is (= 2 (count #\[ text)) "one header per opening: ~S" text)
            (is (search (format nil "Point ~C: " (code-char 233)) text)
                "the e-acute is one windows-1252 octet: ~S" text)
            ;; the reopened header starts a line of its own after the prompt
            (is (search (format nil ": ~%[ AutoCAD - ") text)))
          (%log-setvar host "LOGFILEPATH" (concatenate 'string dir "other"))
          (is (not (equal name (%log-getvar host "LOGFILENAME")))
              "a new LOGFILEPATH makes a new file"))))))

(test command-log-bricscad-name-header-and-command-channel-only
  "BricsCAD: a separator added to LOGFILEPATH, <drawing>_YYYY-MM-DD_HH-MM-SS.log,
its own header, and the command channel only (not the REPL's PRINC output)."
  (%with-log-sandbox (dir)
    (%with-dialect (:bricscad-v25)
      (let* ((host (make-cador))
             (session (evaluation-context-session (current-evaluation-context)))
             (saved-host (runtime-session-host session)))
        (unwind-protect
             (progn
               (set-runtime-session-host session host)
               (clautolisp.cador:apply-command-log-preferences host)
               (%log-setvar host "LOGFILEPATH" (concatenate 'string dir "logs"))
               (is (equal (concatenate 'string (%log-path-for-comparison dir) "logs/")
                          (%log-path-for-comparison (%log-getvar host "LOGFILEPATH"))))
               (%log-setvar host "LOGFILEMODE" 1)
               (let ((name (%log-getvar host "LOGFILENAME")))
                 (is (eql 0 (search (concatenate 'string (%log-path-for-comparison dir)
                                                "logs/Drawing1_")
                                    (%log-path-for-comparison name))))
                 (is (= (length (concatenate 'string dir "logs/Drawing1_2026-10-06_13-11-05.log"))
                        (length name)))
                 (clautolisp.cador::cador-write-prompt host "Start point: ")
                 (clautolisp.cador:command-log-output "PRINC-OUTPUT")
                 (%log-setvar host "LOGFILEMODE" 0)
                 (let ((text (%file-text name)))
                   (is (search "---------- [ BricsCAD - " text))
                   (is (search "Start point: " text))
                   (is (null (search "PRINC-OUTPUT" text))
                       "BricsCAD logs the command channel only"))))
          (set-runtime-session-host session saved-host))))))

(test command-log-bricscad-macos-bare-name
  "BricsCAD macOS: LOGFILENAME is the bare \"bricscad.log\" (measured, V26)."
  (%with-log-sandbox (dir)
    (%with-dialect (:bricscad-mac)
      (let ((host (make-cador)))
        (clautolisp.cador:apply-command-log-preferences host)
        (is (equal "bricscad.log" (%log-getvar host "LOGFILENAME")))))))

(test command-log-clautolisp-logs-repl-output-in-utf-8
  "clautolisp: the whole command line (the REPL's output too), in UTF-8, under
the XDG state directory by default."
  (%with-log-sandbox (dir)
    (%with-dialect (:clautolisp)
      (let* ((host (make-cador))
             (session (evaluation-context-session (current-evaluation-context)))
             (saved-host (runtime-session-host session)))
        (unwind-protect
             (progn
               (set-runtime-session-host session host)
               (clautolisp.cador:apply-command-log-preferences host)
               (is (equal (concatenate 'string dir "state/clautolisp/logs/")
                          (%log-getvar host "LOGFILEPATH"))
                   "the default LOGFILEPATH is $XDG_STATE_HOME/clautolisp/logs/")
               (%log-setvar host "LOGFILEMODE" 1)
               (let ((name (%log-getvar host "LOGFILENAME")))
                 (clautolisp.cador:command-log-output
                  (format nil "caf~C~%" (code-char 233)))
                 (clautolisp.cador:command-log-input-line "(+ 1 2)")
                 (%log-setvar host "LOGFILEMODE" 0)
                 (let ((text (%file-text name)))
                   (is (eql 0 (search "[ clautolisp - " text)))
                   (is (search (format nil "caf~C~C" (code-char #xC3) (code-char #xA9)) text)
                       "UTF-8: ~S" text)
                   (is (search "(+ 1 2)" text)))))
          (set-runtime-session-host session saved-host))))))

(test command-log-preferences-persist-per-product
  "LOGFILEMODE / LOGFILEPATH are registry preferences, per product: a new
session of the same product finds them, another product does not."
  (%with-log-sandbox (dir)
    (%with-dialect (:autocad-2026)
      (let ((host (make-cador)))
        (clautolisp.cador:apply-command-log-preferences host)
        (%log-setvar host "LOGFILEPATH" (concatenate 'string dir "kept"))
        (%log-setvar host "LOGFILEMODE" 1)
        (%log-setvar host "LOGFILEMODE" 1))
      (let ((host (make-cador)))
        (clautolisp.cador:apply-command-log-preferences host)
        (is (equal (concatenate 'string dir "kept") (%log-getvar host "LOGFILEPATH")))
        (is (eql 1 (%log-getvar host "LOGFILEMODE")))
        (%log-setvar host "LOGFILEMODE" 0)))
    (%with-dialect (:bricscad-v25)
      (let ((host (make-cador)))
        (clautolisp.cador:apply-command-log-preferences host)
        (is (eql 0 (%log-getvar host "LOGFILEMODE")))))))

(test command-log-closing-a-document-closes-its-log
  (%with-log-sandbox (dir)
    (%with-dialect (:clautolisp)
      (let ((host (make-cador)))
        (clautolisp.cador:apply-command-log-preferences host)
        (%log-setvar host "LOGFILEPATH" (concatenate 'string dir "logs"))
        (let ((second (clautolisp.autolisp-host:host-open-document host)))
          (clautolisp.autolisp-host:host-activate-document host second)
          (%log-setvar host "LOGFILEMODE" 1)
          (let ((stream (clautolisp.cador::doc-session-log-stream
                         (clautolisp.cador::cador-document-session host second))))
            (is (streamp stream))
            (clautolisp.autolisp-host:host-close-document host second)
            (is (not (open-stream-p stream)) "the closed document's log is closed")))
        (%log-setvar host "LOGFILEMODE" 0)))))

(test command-log-logfilename-is-read-only
  (%with-log-sandbox (dir)
    (let ((host (make-cador)))
      (is (eq :sysvar-read-only
              (handler-case (progn (%log-setvar host "LOGFILENAME" "x.log") nil)
                (autolisp-runtime-error (e) (autolisp-runtime-error-code e))))))))
