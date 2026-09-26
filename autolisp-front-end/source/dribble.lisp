;;;; alfe's dribble: record a CAD session's interactions into a log file.
;;;;
;;;; alfe-dribble.issue / dribble.issue. The clautolisp half shipped first and
;;;; is the reference for the FORMAT:
;;;;
;;;;   ;; H: <program> <version> …        header, written when recording starts
;;;;   input line                         raw, unprefixed
;;;;   ;; O: standard output line
;;;;   ;; E: error output line
;;;;   ;; C: condition / error message line
;;;;
;;;; WHICH BACKENDS THIS SERVES (pjb, 2026-08-11: "dribble sur alfe signifie que
;;;; la fonction travaille avec bricscad et autocad. alfe --clautolisp surement
;;;; l'implemente deja dans clautolisp"):
;;;;
;;;;   --clautolisp : NOT recorded here. The flags are forwarded to the spawned
;;;;                  engine, which records its own REPL -- a better transcript
;;;;                  than alfe could reconstruct, and recording both would
;;;;                  produce two files for one session
;;;;                  (%DRIBBLE-CLI-FLAGS, backend-clautolisp.lisp).
;;;;   bricscad /   : recorded HERE, because those engines have no dribble of
;;;;   autocad       their own. alfe writes what it sees of the conversation:
;;;;                  the form it sends, and the output it drains.
;;;;
;;;; WHAT DIFFERS FROM THE REPL CASE, deliberately. clautolisp tees three Gray
;;;; streams CHARACTER BY CHARACTER and has to discriminate prompts (a prompt is
;;;; omitted from the format, and is indistinguishable after the fact from a
;;;; line of output that simply lacked a newline). alfe has neither: it drains
;;;; COMPLETE chunks from the protocol's stdout.txt / stderr.txt, and a CAD
;;;; engine driven through files writes no prompts at alfe. So there is no
;;;; prompt discrimination here, and a partial line is always genuine output --
;;;; kept, never dropped. The interleaving rule IS mirrored: when the other tag
;;;; must write while a line is still open, the open line is terminated first,
;;;; so a line never carries two tags' text.
;;;;
;;;; INTERACTOR FILTERING. --dribble-interactors selects which interactors are
;;;; recorded, and a CAD session driven through the file protocol has none: the
;;;; interactor stack belongs to clautolisp's own REPL. So the option is
;;;; forwarded to the clautolisp backend (where it means something) and IGNORED
;;;; for the CAD backends, which record the whole session. That is the reading
;;;; alfe-dribble.issue recommends, and it is stated in the manual rather than
;;;; left for a user to discover.

(defpackage #:alfe.dribble
  (:use #:cl)
  (:export #:*dribble-stream*
           #:*dribble-path*
           #:dribble-active-p
           #:default-dribble-path
           #:start-dribble
           #:stop-dribble
           #:record-input
           #:record-output
           #:record-error-output
           #:record-condition))

(in-package #:alfe.dribble)

(defvar *dribble-stream* nil
  "The open dribble file stream, or NIL when alfe is not recording.")

(defvar *dribble-path* nil
  "The absolute namestring of the active dribble file, or NIL.")

(defvar *open-tag* nil
  "The tag (\"O\" / \"E\") owning an unterminated line, or NIL.")

(defvar *open-text* ""
  "The partial text of the unterminated line owned by *OPEN-TAG*.")

(defun dribble-active-p ()
  "True when alfe is recording."
  (and *dribble-stream* t))

;;; --- where it goes ---------------------------------------------------

(defun %state-home ()
  "$XDG_STATE_HOME, or ~/.local/state as the specification's default."
  (let ((env (uiop:getenv "XDG_STATE_HOME")))
    (if (and env (plusp (length env)))
        (uiop:ensure-directory-pathname env)
        (merge-pathnames ".local/state/" (user-homedir-pathname)))))

(defun %timestamp ()
  "YYYYMMDDTHHMMSS in local time -- the spelling dribble.issue asks for."
  (multiple-value-bind (second minute hour day month year)
      (decode-universal-time (get-universal-time))
    (format nil "~4,'0D~2,'0D~2,'0DT~2,'0D~2,'0D~2,'0D"
            year month day hour minute second)))

(defun default-dribble-path (backend)
  "The default file for BACKEND (a keyword such as :BRICSCAD):
$XDG_STATE_HOME/alfe/dribbles/<backend>/<timestamp>.log.

The per-backend subdirectory is alfe's own (clautolisp has no counterpart): one
machine drives several engines, and a directory listing that mixes an AutoCAD
session with a BricsCAD one hides the very difference a dribble is kept for."
  (merge-pathnames
   (format nil "alfe/dribbles/~(~A~)/~A.log"
           (or backend :unknown) (%timestamp))
   (%state-home)))

;;; --- writing ---------------------------------------------------------

(defun %write-line-raw (text)
  (write-string text *dribble-stream*)
  (write-char #\Newline *dribble-stream*)
  (force-output *dribble-stream*))

(defun %write-tagged-line (tag text)
  (%write-line-raw (format nil ";; ~A: ~A" tag text)))

(defun %terminate-open-line ()
  "Emit the open line, if any, as a complete tagged line. A partial line is
genuine output here -- alfe sees no prompts -- so it is kept, never dropped."
  (when *open-tag*
    (%write-tagged-line *open-tag* *open-text*)
    (setf *open-tag* nil
          *open-text* "")))

(defun %record-chunk (tag text)
  "Record TEXT under TAG, splitting it into lines. A chunk that does not end in
a newline leaves its last line OPEN, to be completed by the next chunk of the
same tag -- or terminated by anything else that must write (the interleaving
rule)."
  (when (and (dribble-active-p) text (plusp (length text)))
    (unless (equal tag *open-tag*)
      (%terminate-open-line))
    (let ((start 0)
          (length (length text)))
      (loop
        (let ((newline (position #\Newline text :start start)))
          (cond
            (newline
             (let ((line (concatenate 'string
                                      (if (equal tag *open-tag*) *open-text* "")
                                      (subseq text start newline))))
               (setf *open-tag* nil *open-text* "")
               (%write-tagged-line tag line))
             (setf start (1+ newline))
             (when (>= start length) (return)))
            (t
             ;; A trailing partial line: hold it open under this tag.
             (when (< start length)
               (setf *open-text* (concatenate 'string
                                              (if (equal tag *open-tag*)
                                                  *open-text* "")
                                              (subseq text start))
                     *open-tag* tag))
             (return))))))))

(defun record-output (text)
  "Record TEXT as standard output (`;; O: ')."
  (%record-chunk "O" text))

(defun record-error-output (text)
  "Record TEXT as error output (`;; E: ')."
  (%record-chunk "E" text))

(defun record-condition (text)
  "Record TEXT as a condition report (`;; C: '), one line per line of TEXT.
A condition interrupts whatever line is open, so that line is terminated
first."
  (when (and (dribble-active-p) text)
    (%terminate-open-line)
    (with-input-from-string (in text)
      (loop for line = (read-line in nil nil)
            while line do (%write-tagged-line "C" line)))))

(defun record-input (text)
  "Record TEXT as INPUT: raw, unprefixed, one line per line. This is the form
alfe sends to the engine -- the nearest thing a file-protocol session has to
what a user typed."
  (when (and (dribble-active-p) text)
    (%terminate-open-line)
    (with-input-from-string (in text)
      (loop for line = (read-line in nil nil)
            while line do (%write-line-raw line)))))

;;; --- start / stop ----------------------------------------------------

(defun start-dribble (&key file backend alfe-version cad-version)
  "Start recording into FILE (a namestring / pathname) or, when FILE is NIL or
T, into DEFAULT-DRIBBLE-PATH for BACKEND. An existing file is APPENDED to, so a
day's sessions accumulate rather than overwrite. Returns the path.

The header carries TWO versions, unlike clautolisp's one:

  ;; H: alfe <alfe-version> <backend> <cad-version>

CAD-VERSION is what alfe KNOWS WHEN RECORDING STARTS -- the release it selected
or detected -- and =unknown= when it knows nothing yet. It is deliberately NOT
delayed until the engine answers: a CAD start takes tens of seconds and can
fail, and a transcript whose first line appeared only after a successful start
would be missing exactly the sessions worth reading."
  (let* ((path (if (and file (not (eq file t)))
                   (pathname file)
                   (default-dribble-path backend)))
         (directory (uiop:pathname-directory-pathname path)))
    (ensure-directories-exist directory)
    (setf *dribble-stream* (open path :direction :output
                                      :if-exists :append
                                      :if-does-not-exist :create
                                      :external-format :utf-8)
          *dribble-path* (namestring path)
          *open-tag* nil
          *open-text* "")
    (%write-line-raw (format nil ";; H: alfe ~A ~(~A~) ~A"
                             (or alfe-version "unknown")
                             (or backend :unknown)
                             (or cad-version "unknown")))
    *dribble-path*))

(defun stop-dribble ()
  "Stop recording, flushing an open line (genuine output: alfe has no prompts to
discard). Returns the path that was being written, or NIL."
  (let ((path *dribble-path*))
    (when *dribble-stream*
      (%terminate-open-line)
      (ignore-errors (finish-output *dribble-stream*))
      (ignore-errors (close *dribble-stream*)))
    (setf *dribble-stream* nil
          *dribble-path* nil
          *open-tag* nil
          *open-text* "")
    path))
