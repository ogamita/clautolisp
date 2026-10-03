(in-package #:clautolisp.cador)

;;;; File and customisation commands (alref Phase 4 S3): NEW, OPEN,
;;;; MENULOAD, CUILOAD.
;;;;
;;;; cador owns the documents; a UI layered over it (cadtui) is told what
;;;; happened through *CADOR-COMMAND-UI-HOOK*, so the headless core never
;;;; depends on a UI. With FILEDIA 0 -- the only mode a driven command
;;;; has -- the vendors prompt on the command line: NEW for a template
;;;; ("." for none, RETURN for the default), OPEN for a drawing name,
;;;; MENULOAD / CUILOAD for a customisation file.

(defvar *cador-command-ui-hook* nil
  "NIL, or a function (HOST EVENT &rest ARGS) a UI installs to mirror the
file commands: EVENT :DOCUMENT-OPENED (KEY), :MENU-LOADED (FORMS PATH).")

(defun %notify-ui (host event &rest args)
  (when *cador-command-ui-hook*
    (apply *cador-command-ui-hook* host event args)))

(defun %open-and-activate (host key drawing)
  (setf (cador-documents host)
        (append (cador-documents host) (list (cons key drawing))))
  (host-activate-document host key)
  (%notify-ui host :document-opened key)
  key)

;;; NEW: an optional template answer (a path, "." for none, RETURN for the
;;; default); opens a new drawing and makes it current, as the vendors do.
(defun %cmd-new (host tokens)
  (let ((template (first tokens)))
    (when (and (stringp template) (not (%command-name-p template)))
      (pop tokens))
    (let* ((key (%cador-fresh-document-key host "Drawing.dwg"))
           (drawing
             (if (and (stringp template) (plusp (length template))
                      (not (string= template ".")) (probe-file template))
                 (clautolisp.drawing:make-drawing-from-template :name key :template template)
                 (cador-make-new-drawing host :name key))))
      (%open-and-activate host key drawing))
    tokens))

;;; OPEN: a drawing file name; read (DXF or DWG, sniffed) and made current.
;;; An unreadable file opens nothing.
(defun %cmd-open (host tokens)
  (let ((path (first tokens)))
    (when (and (stringp path) (plusp (length path)))
      (pop tokens)
      (let ((drawing (ignore-errors (clautolisp.drawing:read-drawing path))))
        (when drawing
          (%open-and-activate host
                              (%cador-fresh-document-key host (file-namestring path))
                              drawing))))
    tokens))

;;; MENULOAD / CUILOAD: a customisation file. cadtui's format is the spec's
;;; "simplified CUIX/MNU" (Roadmap 6): the data description its menu bar
;;; and bands are built from -- (:menu-bar ...) and (:band ...) forms, read
;;; as data (*READ-EVAL* off). Real .cuix / .mnu files are not parsed.
(defun read-customisation-file (path)
  "The (:menu-bar ...) / (:band ...) forms in PATH, or NIL if unreadable."
  (ignore-errors
   (with-open-file (in path :external-format :utf-8)
     (let ((*read-eval* nil)
           (*package* (find-package "KEYWORD")))
       (loop for form = (read in nil in)
             until (eq form in)
             when (and (consp form) (member (first form) '(:menu-bar :band)))
               collect form)))))

(defun %cmd-menuload (host tokens)
  (let ((path (first tokens)))
    (when (and (stringp path) (plusp (length path)))
      (pop tokens)
      (let ((forms (read-customisation-file path)))
        (when forms (%notify-ui host :menu-loaded forms path))))
    tokens))

(defun %command-name-p (token)
  "Whether TOKEN names a command the engine knows (so it is not an answer)."
  (let ((name (%command-name token)))
    (and name (gethash name *cador-commands*) t)))

(define-cador-command "NEW" '%cmd-new)
(define-cador-command "OPEN" '%cmd-open)
(define-cador-command '("MENULOAD" "CUILOAD") '%cmd-menuload)
