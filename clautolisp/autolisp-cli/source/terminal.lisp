(in-package #:clautolisp.autolisp-cli)

;;;; terminal.lisp -- the `terminal` encoding situation applied to the running
;;;; tool's own standard streams (-Eterminal[-in|-out]). Moved here from alfe
;;;; (cli.lisp, G1) so the clautolisp tool honours -Eterminal as alfe does
;;;; (encoding-situations-cli-options, section 6).

;;; --- G1: apply the `terminal` situation encoding to the tool's OWN streams ---
;;;
;;; -Eterminal[-in|-out] declares the encoding of alfe's own REPL / batch I/O
;;; with the user. Until now the value was published to AutoLISP code as
;;; *AUTOLISP-TERMINAL-ENCODING* but never applied to this process's
;;; *standard-output* / *standard-input*, so the flag was inert (the streams
;;; kept SBCL's locale default). G1 makes it real: when — and ONLY when — a
;;; terminal encoding is explicitly requested, rebind alfe's standard streams
;;; to fresh fd-streams in that encoding. Unset ⇒ nothing changes (the
;;; behaviour-preserving default the phased plan requires).

(defun terminal-encoding-plan (options)
  "The stream reconfiguration the resolved `terminal` encoding implies for
alfe's OWN standard streams, as a list of (KEY FD DIRECTION EXTERNAL-FORMAT)
entries — KEY one of :OUTPUT / :ERROR / :INPUT, FD the OS descriptor,
EXTERNAL-FORMAT a CL keyword. NIL when -Eterminal was not given. The bare
-Eterminal sets both directions; -Eterminal-out drives stdout+stderr,
-Eterminal-in drives stdin. Pure — so tests assert what a CLI would
reconfigure without touching real process streams. The line-ending suffix is
accepted-and-ignored here (terminal I/O is line-buffered), matching the
--list-encodings note."
  (let ((out (cli-situation-encoding options "terminal" "out"))
        (in  (cli-situation-encoding options "terminal" "in")))
    (nconc
     (when out
       (let ((ext (encoding-keyword out)))
         (list (list :output 1 :output ext)
               (list :error  2 :output ext))))
     (when in
       (list (list :input 0 :input (encoding-keyword in)))))))

(defun %make-terminal-fd-stream (fd direction external-format)
  "A fresh stream over OS descriptor FD with EXTERNAL-FORMAT (DIRECTION is
:INPUT or :OUTPUT); :CONSOLE when FD is a Windows console whose code page
was set instead (the stream itself is kept); or NIL when the host CL cannot
reliably do either -- the caller then warns and keeps the host default.

POSIX SBCL reopens the descriptor. Windows SBCL goes through
%MAKE-WINDOWS-TERMINAL-STREAM (windows-terminal-encoding-fd-stream.issue)."
  (declare (ignorable fd direction external-format))
  #+(and sbcl (not win32))
  (sb-sys:make-fd-stream fd
                         :input  (eq direction :input)
                         :output (eq direction :output)
                         :external-format external-format
                         :buffering (if (eq direction :output) :line :full)
                         :name "terminal")
  #+(and sbcl win32)
  (%make-windows-terminal-stream fd direction external-format)
  #-sbcl
  nil)

;;; --- Windows: the std HANDLE, and the console code page ---------------------
;;;
;;; On Windows SBCL's fd-streams are over Win32 HANDLEs, not CRT descriptors:
;;; its own standard streams are made from GetStdHandle's values. Reopening
;;; "descriptor 1" therefore built a stream over HANDLE 1 -- no handle at all --
;;; whose first write failed with EBADF (`Descripteur non valide'), later, in
;;; user code. The stream is now made over the HANDLE SBCL's own standard
;;; stream holds. A console is different: SBCL talks UTF-16 to it
;;; (WriteConsoleW / ReadConsoleW: its stdstream external format is :UCS-2
;;; there), so alfe's own text already reaches it intact; what -Eterminal
;;; changes is the console's code page (SetConsoleOutputCP / SetConsoleCP),
;;; the encoding every program writing bytes to it -- a CAD child included --
;;; is read in.

(cffi:define-foreign-library kernel32
  (:windows "kernel32.dll"))

(defvar *kernel32-loaded-p* nil)

(defun %kernel32-entry (name)
  "The address of the kernel32 function NAME (the library loaded on first use)."
  (unless *kernel32-loaded-p*
    (cffi:load-foreign-library 'kernel32)
    (setf *kernel32-loaded-p* t))
  (or (cffi:foreign-symbol-pointer name :library 'kernel32)
      (error "kernel32: no entry point ~A" name)))

(defparameter *windows-console-code-pages*
  '(("UTF-8" . 65001) ("UTF8" . 65001)
    ("WINDOWS-1252" . 1252) ("CP1252" . 1252)
    ("ISO-8859-1" . 28591) ("LATIN-1" . 28591) ("LATIN1" . 28591)
    ("US-ASCII" . 20127) ("ASCII" . 20127)
    ("CP850" . 850) ("CP437" . 437))
  "(EXTERNAL-FORMAT-NAME . WINDOWS-CODE-PAGE) for -Eterminal on a console.")

(defun windows-console-code-page (external-format)
  "The Windows code page of EXTERNAL-FORMAT (a keyword, or a (KEYWORD
:NEWLINE ...) list), or NIL when it has none a console can be set to."
  (let ((base (if (consp external-format) (first external-format) external-format)))
    (cdr (assoc (string base) *windows-console-code-pages* :test #'string-equal))))

(defun %windows-console-handle-p (handle)
  "True when the Win32 HANDLE (an integer) is a console (GetConsoleMode succeeds)."
  (cffi:with-foreign-object (mode :uint32)
    (/= 0 (cffi:foreign-funcall-pointer (%kernel32-entry "GetConsoleMode")
                                        (:convention :stdcall)
                                        :pointer (cffi:make-pointer handle)
                                        :pointer mode
                                        :int))))

(defun %set-windows-console-code-page (direction code-page)
  "SetConsoleOutputCP (DIRECTION :OUTPUT) or SetConsoleCP (:INPUT); true on success."
  (/= 0 (cffi:foreign-funcall-pointer
         (%kernel32-entry (if (eq direction :output) "SetConsoleOutputCP" "SetConsoleCP"))
         (:convention :stdcall)
         :uint code-page
         :int)))

#+sbcl
(defun %make-windows-terminal-stream (fd direction external-format)
  "-Eterminal on Windows SBCL: :CONSOLE once the console's code page is set,
a fresh stream over the std HANDLE of SBCL's own standard stream for FD
otherwise, NIL when neither is possible."
  (let* ((standard (case fd
                     (0 sb-impl::*stdin*)
                     (1 sb-impl::*stdout*)
                     (2 sb-impl::*stderr*)))
         (handle (and (typep standard 'sb-sys:fd-stream)
                      (sb-sys:fd-stream-fd standard))))
    (cond
      ((null handle) nil)
      ((%windows-console-handle-p handle)
       (let ((code-page (windows-console-code-page external-format)))
         (and code-page
              (%set-windows-console-code-page direction code-page)
              :console)))
      (t
       (sb-sys:make-fd-stream handle
                              :input  (eq direction :input)
                              :output (eq direction :output)
                              :element-type :default
                              :external-format external-format
                              :buffering (if (eq direction :output) :line :full)
                              :auto-close nil
                              :name "terminal")))))

(defun apply-terminal-encoding (options &key (tool "clautolisp"))
  "G1 side effect: reconfigure alfe's own *standard-output* / *error-output*
/ *standard-input* per TERMINAL-ENCODING-PLAN. A no-op when -Eterminal was
not given. Any failure (unsupported host CL, a code page the console
refuses) degrades to a warning -- it must never abort the run, and the
un-reconfigured stream simply keeps the locale default."
  (dolist (entry (terminal-encoding-plan options))
    (destructuring-bind (key fd direction ext) entry
      (handler-case
          (let ((stream (%make-terminal-fd-stream fd direction ext)))
            (cond
              ((eq stream :console))    ; the console's code page was set
              (stream
               (ecase key
                 (:output (setf *standard-output* stream))
                 (:error  (setf *error-output* stream))
                 (:input  (setf *standard-input* stream))))
              (t
               (warn "~A: -Eterminal terminal-encoding reconfiguration ~
is unavailable on this host (non-SBCL, or a console without a code page for ~
~A); leaving ~(~A~) at the host default." tool ext key))))
        (error (e)
          (warn "~A: could not apply -Eterminal (~A) to ~(~A~): ~A"
                tool ext key e))))))

