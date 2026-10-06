(in-package #:clautolisp.cador)

;;;; The command-history log file, one per drawing: LOGFILEMODE / LOGFILEPATH /
;;;; LOGFILENAME (pjb 2026-10-06: "implement saving log files per drawing like
;;;; in BricsCAD / AutoCAD").
;;;;
;;;; MEASURED (probes/sources/probe-logfile.lsp, MR !428: AutoCAD 2022 job
;;;; 16965923806, BricsCAD V25 Windows 16965923810, BricsCAD V26 macOS
;;;; 16965923807):
;;;;
;;;;   AutoCAD 2022
;;;;     LOGFILENAME  <LOGFILEPATH>\<drawing>_1<8 hex>.log, e.g.
;;;;                  Dessin1_1696f0cec.log -- a NEW file whenever LOGFILEPATH
;;;;                  is set (the file exists at once, with logging on); a
;;;;                  LOGFILEMODE 0 -> 1 toggle keeps the same file.
;;;;     LOGFILEPATH  stored as given (no separator added).
;;;;     header       "[ AutoCAD - Tue Oct 06 13:07:22 2026  ]" + 40 dashes,
;;;;                  again on every reopening (appended).
;;;;     content      the whole command line: PRINC output, the command echo,
;;;;                  each prompt with the input typed after it.
;;;;     encoding     windows-1252 (an e-acute reads back as 233).
;;;;   BricsCAD V25, Windows
;;;;     LOGFILENAME  <LOGFILEPATH><drawing>_YYYY-MM-DD_HH-MM-SS.log -- a new
;;;;                  file when LOGFILEPATH is set; a toggle keeps it.
;;;;     LOGFILEPATH  a trailing separator is added.
;;;;     header       a blank line, then
;;;;                  "---------- [ BricsCAD - Tue Oct  6 13:11:05 2026] ----------"
;;;;     content      the command channel only (": _.LINE", "prompt : input");
;;;;                  PRINC output is NOT logged.
;;;;     encoding     not settled (accented prompts read back as one character
;;;;                  each: windows-1252 or UTF-8 with a BOM).
;;;;   BricsCAD V26, macOS
;;;;     LOGFILENAME  "bricscad.log" -- a bare name, the same for every drawing;
;;;;                  in batch mode no file is written at all.
;;;;   Both: LOGFILENAME is read-only; LOGFILEMODE / LOGFILEPATH are registry
;;;;   preferences. Neither product's FACTORY LOGFILEPATH could be measured (the
;;;;   runners' profiles hold alfe's and accoreconsole's own settings).
;;;;
;;;; clautolisp follows the active dialect's product for the name, the header,
;;;; what is logged and the encoding; under clautolisp / strict / lax it logs
;;;; the whole command line, names the file like BricsCAD (readable), writes an
;;;; AutoCAD-like header naming clautolisp, in UTF-8. -Elog overrides the
;;;; encoding. The default LOGFILEPATH is $XDG_STATE_HOME/clautolisp/logs/
;;;; (~/.local/state/clautolisp/logs/ when XDG_STATE_HOME is unset or empty).
;;;;
;;;; WHAT REACHES THE LOG. Two channels:
;;;;   - cador's own console channel -- prompts, the command echo, the
;;;;     "; cador:" notices, and the answer read after a prompt -- logged here,
;;;;     under every dialect (COMMAND-LOG-CHANNEL-TEXT);
;;;;   - the REPL's own output and input lines -- PRINC, the REPL prompt, what
;;;;     the user types -- which the clautolisp tool passes in through
;;;;     COMMAND-LOG-OUTPUT / COMMAND-LOG-INPUT-LINE from its stream tees, and
;;;;     which are logged except under a BricsCAD dialect (BricsCAD logs the
;;;;     command channel only).
;;;; In an interactive REPL cador's console IS the REPL's output stream, so
;;;; while cador writes on its channel *COMMAND-LOG-CHANNEL-ACTIVE* tells the
;;;; tool's tee to leave that text alone: each character is logged once.

(defvar *command-log-channel-active* nil
  "True while cador writes (or reads) on its console channel and has already
logged that text: the REPL stream tees then skip it.")

;;; --- the dialect's product --------------------------------------------------

(defun %command-log-product ()
  "The active dialect's product: :AUTOCAD, :BRICSCAD, or :CLAUTOLISP for every
other dialect (clautolisp, strict, lax)."
  (let* ((dialect (ignore-errors (clautolisp.autolisp-runtime:current-evaluation-dialect)))
         (product (and dialect (ignore-errors
                                (clautolisp.autolisp-reader:autolisp-dialect-product dialect)))))
    (case product
      (:autocad :autocad)
      (:bricscad :bricscad)
      (t :clautolisp))))

(defun %command-log-bricscad-macos-p ()
  (and (eq (%command-log-product) :bricscad)
       (eq (%current-dialect-platform) :macos)))

(defun %command-log-logs-repl-p ()
  "Whether the REPL's own output (PRINC ...) belongs in the log: AutoCAD logs
the whole command line, BricsCAD only its command channel."
  (not (eq (%command-log-product) :bricscad)))

;;; --- the sysvars ------------------------------------------------------------

(defun %command-log-sysvar (host name)
  (let ((cell (cador-sysvar host name)))
    (and cell (sysvar-cell-value cell))))

(defun %command-log-on-p (host)
  (eql 1 (%command-log-sysvar host "LOGFILEMODE")))

(defun command-log-state-directory ()
  "The default LOGFILEPATH: $XDG_STATE_HOME/clautolisp/logs/, or
~/.local/state/clautolisp/logs/ when XDG_STATE_HOME is unset or empty."
  (let ((state (%nonempty-getenv "XDG_STATE_HOME")))
    (namestring
     (merge-pathnames "clautolisp/logs/"
                      (if state
                          (uiop:ensure-directory-pathname state)
                          (merge-pathnames ".local/state/" (user-homedir-pathname)))))))

(defun %path-separator ()
  #+(or win32 windows mswindows os-windows) "\\"
  #-(or win32 windows mswindows os-windows) "/")

(defun %ends-with-separator-p (path)
  (and (plusp (length path))
       (member (char path (1- (length path))) '(#\/ #\\))))

(defun normalize-logfilepath (path)
  "LOGFILEPATH as the active product stores it: BricsCAD adds a trailing
separator (measured, both platforms); AutoCAD keeps what it was given. Under
clautolisp the separator is added too, so the value is a directory name."
  (if (or (not (stringp path)) (string= path "")
          (eq (%command-log-product) :autocad)
          (%ends-with-separator-p path))
      path
      (concatenate 'string path (%path-separator))))

;;; --- persistence: the registry, per product (like LISPSYS) -----------------

(defun command-log-registry-key ()
  "HKEY_CURRENT_USER\\Software\\clautolisp\\Variables\\<product>, where
LISPSYS is kept too: per product, so an AutoCAD dialect's preference does not
leak into a BricsCAD one."
  (concatenate 'string "HKEY_CURRENT_USER\\Software\\clautolisp\\Variables\\"
               (ecase (%command-log-product)
                 (:autocad "AutoCAD") (:bricscad "BricsCAD") (:clautolisp "clautolisp"))))

(defun %command-log-persist (host name value)
  (ignore-errors
   (host-registry-write host (command-log-registry-key) name
                        (if (stringp value) value (princ-to-string value)))))

(defun apply-command-log-preferences (host)
  "At launch (and after a dialect switch): lay the saved LOGFILEMODE and
LOGFILEPATH of the active product onto HOST, or the defaults -- 0 and the
state directory (COMMAND-LOG-STATE-DIRECTORY)."
  (let* ((key (command-log-registry-key))
         (mode (ignore-errors (host-registry-read host key "LOGFILEMODE")))
         (path (ignore-errors (host-registry-read host key "LOGFILEPATH")))
         (mode (or (and (stringp mode) (ignore-errors (parse-integer mode))) 0))
         (path (if (and (stringp path) (plusp (length path)))
                   path
                   (normalize-logfilepath (command-log-state-directory)))))
    (host-set-derived-sysvar host "LOGFILEPATH" path)
    (host-set-derived-sysvar host "LOGFILEMODE" (if (eql mode 1) 1 0))
    (values mode path)))

;;; --- the file name ----------------------------------------------------------

(defun %drawing-base-name (host key)
  (let* ((drawing (cdr (assoc key (cador-documents host) :test #'equal)))
         (name (if drawing (clautolisp.drawing:drawing-name drawing) "Drawing1.dwg")))
    (pathname-name (pathname name))))

(defun %timestamp-name-part (universal-time)
  (multiple-value-bind (second minute hour day month year)
      (decode-universal-time universal-time)
    (format nil "~4,'0D-~2,'0D-~2,'0D_~2,'0D-~2,'0D-~2,'0D"
            year month day hour minute second)))

(defun command-log-file-name (host key)
  "A new LOGFILENAME for document KEY under the active product's rule."
  (let ((path (or (%command-log-sysvar host "LOGFILEPATH") ""))
        (base (%drawing-base-name host key)))
    (flet ((in-directory (file)
             (if (or (string= path "") (%ends-with-separator-p path))
                 (concatenate 'string path file)
                 (concatenate 'string path (%path-separator) file))))
      (cond
        ((%command-log-bricscad-macos-p) "bricscad.log")
        ((eq (%command-log-product) :autocad)
         (in-directory (format nil "~A_1~(~8,'0X~).log" base (random #x100000000))))
        (t
         (in-directory (format nil "~A_~A.log" base
                               (%timestamp-name-part (get-universal-time)))))))))

(defun %command-log-file-pathname (host name)
  "Where the log named NAME lives: NAME itself, or -- for BricsCAD macOS's bare
\"bricscad.log\" -- that name in LOGFILEPATH."
  (if (string= name "bricscad.log")
      (let ((path (or (%command-log-sysvar host "LOGFILEPATH") "")))
        (merge-pathnames name (uiop:ensure-directory-pathname
                               (if (string= path "") (command-log-state-directory) path))))
      (pathname (substitute #\/ #\\ name))))

(defun command-log-name (host &optional (key (cador-active-document-key host)))
  "LOGFILENAME of document KEY: made on first use, kept until LOGFILEPATH
changes (measured: a toggle keeps the file, a new path makes a new one)."
  (let ((session (cador-document-session host key)))
    (or (doc-session-log-name session)
        (setf (doc-session-log-name session) (command-log-file-name host key)))))

;;; --- opening, writing, closing --------------------------------------------

(defun %command-log-encoding ()
  "-Elog when given, else the product's: windows-1252 for AutoCAD (measured),
UTF-8 otherwise."
  (or (clautolisp.autolisp-runtime:lookup-autolisp-encoding-variable
       "*AUTOLISP-LOG-ENCODING*")
      (if (eq (%command-log-product) :autocad) :cp1252 :utf-8)))

(defun %command-log-header (universal-time)
  (multiple-value-bind (second minute hour day month year day-of-week)
      (decode-universal-time universal-time)
    (let ((dow (nth day-of-week '("Mon" "Tue" "Wed" "Thu" "Fri" "Sat" "Sun")))
          (mon (nth (1- month) '("Jan" "Feb" "Mar" "Apr" "May" "Jun"
                                 "Jul" "Aug" "Sep" "Oct" "Nov" "Dec"))))
      (ecase (%command-log-product)
        (:bricscad
         (format nil "~%---------- [ BricsCAD - ~A ~A ~2D ~2,'0D:~2,'0D:~2,'0D ~D] ----------~%"
                 dow mon day hour minute second year))
        ((:autocad :clautolisp)
         (format nil "[ ~A - ~A ~A ~2,'0D ~2,'0D:~2,'0D:~2,'0D ~D  ]~40,,,'-A~%"
                 (if (eq (%command-log-product) :autocad) "AutoCAD" "clautolisp")
                 dow mon day hour minute second year ""))))))

(defun %file-ends-mid-line-p (file)
  "True when FILE exists and its last byte is not a line end."
  (ignore-errors
   (with-open-file (in file :element-type '(unsigned-byte 8) :if-does-not-exist nil)
     (when (and in (plusp (file-length in)))
       (file-position in (1- (file-length in)))
       (not (member (read-byte in) '(10 13)))))))

(defun cador-open-command-log (host &optional (key (cador-active-document-key host)))
  "Open document KEY's log for appending, writing the header. Returns the
stream, or NIL when it cannot be opened (logging never breaks the session)."
  (let ((session (cador-document-session host key)))
    (or (doc-session-log-stream session)
        (let ((file (%command-log-file-pathname host (command-log-name host key))))
          (handler-case
              (let ((open-line (%file-ends-mid-line-p file)))
                (ensure-directories-exist file)
                (let ((stream (clautolisp.autolisp-reader:open-with-external-format
                               file :direction :output :if-exists :append
                                    :if-does-not-exist :create
                                    :external-format (%command-log-encoding))))
                  ;; Reopened after an unterminated line (a prompt): the
                  ;; header starts on a line of its own, as AutoCAD's does
                  ;; after "Commande: ".
                  (when open-line
                    (terpri stream))
                  (write-string (%command-log-header (get-universal-time)) stream)
                  (finish-output stream)
                  (setf (doc-session-log-stream session) stream)))
            (error () nil))))))

(defun cador-close-command-log (host &optional (key (cador-active-document-key host)))
  "Close document KEY's log, if open."
  (let* ((table (cador-document-sessions host))
         (session (gethash (or key "") table))
         (stream (and session (doc-session-log-stream session))))
    (when stream
      (ignore-errors (close stream))
      (setf (doc-session-log-stream session) nil))))

(defun cador-close-all-command-logs (host &key forget-names)
  "Close every document's log; with FORGET-NAMES, also forget their
LOGFILENAMEs (a new LOGFILEPATH makes new files)."
  (maphash (lambda (key session)
             (declare (ignore key))
             (when (doc-session-log-stream session)
               (ignore-errors (close (doc-session-log-stream session)))
               (setf (doc-session-log-stream session) nil))
             (when forget-names
               (setf (doc-session-log-name session) nil)))
           (cador-document-sessions host)))

(defun cador-command-log-write (host string &key fresh-line)
  "Append STRING to the current document's log when logging is on -- on a
line of its own when FRESH-LINE. Flushed at each line end."
  (when (and host string (plusp (length string)) (%command-log-on-p host))
    (let ((stream (cador-open-command-log host)))
      (when stream
        (ignore-errors
         (when fresh-line (fresh-line stream))
         (write-string string stream)
         (when (find #\Newline string)
           (finish-output stream)))))))

(defun command-log-channel-text (host string &key fresh-line)
  "Log STRING written on cador's console channel (every dialect)."
  (cador-command-log-write host string :fresh-line fresh-line))

(defun %command-log-current-host ()
  (let ((host (ignore-errors (clautolisp.autolisp-runtime:current-evaluation-host))))
    (and (typep host 'cador) host)))

(defun command-log-output (string)
  "The REPL's own output STRING (from the tool's stdout tee): logged unless
cador's channel already logged it, or the dialect is BricsCAD's."
  (unless *command-log-channel-active*
    (let ((host (%command-log-current-host)))
      (when (and host (%command-log-logs-repl-p))
        (cador-command-log-write host string)))))

(defun command-log-input-line (line)
  "A line the user typed at the REPL (from the tool's input echo)."
  (unless *command-log-channel-active*
    (let ((host (%command-log-current-host)))
      (when (and host (%command-log-logs-repl-p))
        (cador-command-log-write host (format nil "~A~%" line))))))

(defun cador-console-write (host sink string &key fresh-line)
  "Write STRING to SINK -- cador's console channel -- and to the log, each on
a line of its own when FRESH-LINE (FORMAT's ~&)."
  (let ((*command-log-channel-active* t))
    (when sink
      (when fresh-line (fresh-line sink))
      (write-string string sink)
      (finish-output sink))
    (command-log-channel-text host string :fresh-line fresh-line)))

;;; --- the sysvars' side effects (host-setvar) --------------------------------

(defun command-log-before-setvar (host name value)
  "The value to store for NAME: LOGFILEPATH normalised as the product does."
  (declare (ignore host))
  (if (string-equal name "LOGFILEPATH")
      (normalize-logfilepath value)
      value))

(defun command-log-after-setvar (host name value)
  "LOGFILEMODE 1 opens the current document's log, 0 closes every log;
LOGFILEPATH starts new files (measured). Both are saved as preferences."
  (cond
    ((string-equal name "LOGFILEMODE")
     (%command-log-persist host "LOGFILEMODE" value)
     (if (eql value 1)
         (cador-open-command-log host)
         (cador-close-all-command-logs host)))
    ((string-equal name "LOGFILEPATH")
     (%command-log-persist host "LOGFILEPATH" value)
     (cador-close-all-command-logs host :forget-names t)
     (when (%command-log-on-p host)
       (cador-open-command-log host)))))
