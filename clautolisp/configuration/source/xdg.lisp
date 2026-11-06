(in-package #:clautolisp.configuration)

;;;; XDG configuration-file resolution.
;;;;
;;;; The implementation is the debug UI's, moved here unchanged — it was the
;;;; canonical one (name-parameterised, already serving two files), and the
;;;; copy in builtins-core was the aldo-only rewrite. Moving rather than
;;;; merging keeps the behaviour bit-for-bit what it was: this commit must
;;;; not change where anyone's configuration file is found.

(defun config-getenv (name)
  "The environment variable NAME, or NIL when unset OR EMPTY.

The empty case matters: an exported-but-empty XDG_CONFIG_HOME must fall
back to the default rather than resolve every configuration file against
the filesystem root."
  (let ((v (uiop:getenv name)))
    (if (and v (plusp (length v))) v nil)))

(defun xdg-config-home ()
  "$XDG_CONFIG_HOME, defaulting to ~/.config."
  (or (config-getenv "XDG_CONFIG_HOME")
      (namestring (merge-pathnames ".config/" (user-homedir-pathname)))))

(defun xdg-config-dirs ()
  "The list of $XDG_CONFIG_DIRS entries (defaulting to /etc/xdg)."
  (let ((v (or (config-getenv "XDG_CONFIG_DIRS") "/etc/xdg")))
    (loop :for part :in (uiop:split-string v :separator ":")
          :when (plusp (length part)) :collect part)))

;;;; --- the configuration files this project has -----------------------
;;;;
;;;; Named here rather than spelled at each use, so that "what configuration
;;;; does clautolisp have?" has an answer you can read, and so that adding
;;;; one is a change in this file rather than a string appearing somewhere
;;;; new. pjb, on the module this file opens: it should know the structure
;;;; of the interactors, and the Lisp-side configuration belongs here too.

(defparameter *configuration-names* '("aldo" "lisp")
  "The base names of clautolisp's configuration files, each resolving to
=clautolisp/NAME.conf= under the XDG directories:

  aldo  the aldo debugger interactor's settings (shared by the AutoLISP
        builtins CLAL-LOAD/SAVE-ALDO-CONFIGURATION and by the debug UI);
  lisp  the Common-Lisp-side settings the clautolisp tool reads.

A name not in this list is not rejected — CONFIG-SAVE-PATH takes any
string — but it is undeclared, and CONFIGURATION-NAME-P is how a caller
asks.")

(defun configuration-name-p (name)
  "True when NAME is one of the project's declared configuration files."
  (and (member name *configuration-names* :test #'string=) t))

(defun config-relative-path (&optional (name "aldo"))
  "The path of NAME's configuration file relative to a configuration
directory: =clautolisp/NAME.conf=."
  (make-pathname :directory '(:relative "clautolisp") :name name :type "conf"))

(defun config-save-path (&optional (name "aldo"))
  "Where SAVE writes: $XDG_CONFIG_HOME/clautolisp/NAME.conf."
  (merge-pathnames (config-relative-path name)
                   (uiop:ensure-directory-pathname (xdg-config-home))))

(defun config-load-path (&optional (name "aldo"))
  "Where LOAD reads from: the save path if it exists, else the first
clautolisp/NAME.conf found along $XDG_CONFIG_DIRS; NIL if none."
  (let ((home (config-save-path name)))
    (if (probe-file home)
        home
        (loop :for dir :in (xdg-config-dirs)
              :for path := (merge-pathnames (config-relative-path name)
                                            (uiop:ensure-directory-pathname dir))
              :when (probe-file path) :return path))))
