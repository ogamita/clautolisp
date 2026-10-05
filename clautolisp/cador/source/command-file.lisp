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
  "Register DRAWING as document KEY and make it current -- at the next
top-level read when a LISP session drives HOST (the running routine finishes
in its own drawing, as in AutoCAD: deferred-document-lifecycle-command-
semantics, option A), at once otherwise."
  (cador-prepare-document-drawing host drawing)
  (setf (cador-documents host)
        (append (cador-documents host) (list (cons key drawing))))
  (clautolisp.autolisp-host:request-host-document-activation host key)
  (%notify-ui host :document-opened key)
  key)

;;; NEW: an optional template answer (a path, "." for none, RETURN for the
;;; default); opens a new drawing and makes it current, as the vendors do.
(defun %cmd-new (host tokens)
  (let ((template (first tokens)))
    (when (and (stringp template) (not (%command-name-p template)))
      (pop tokens))
    (let* ((name (%cador-next-drawing-name host))
           (key (%cador-fresh-document-key host name))
           (drawing
             (if (and (stringp template) (plusp (length template))
                      (not (string= template ".")) (probe-file template))
                 (clautolisp.drawing:make-drawing-from-template :name name :template template)
                 (cador-make-new-drawing host :name name))))
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

;;; --- Saving and closing (multi-document slice 4) -----------------------
;;;
;;; With FILEDIA 0 the vendors prompt on the command line, and a driven
;;; command answers the prompts in order:
;;;   QSAVE     -- a titled drawing is written to its file; an untitled one
;;;                takes a file name;
;;;   SAVE      -- "Save drawing as": a file name, RETURN for the current one;
;;;   SAVEAS    -- an optional file format (DXF, or a release: 2018, 2013,
;;;                2010, 2007, 2004, 2000), then the file name (RETURN: the
;;;                current one);
;;;   CLOSE     -- a modified drawing asks "Save changes?": Y (then a file name
;;;                if untitled) or N; the next open drawing becomes current;
;;;   CLOSEALL  -- the same question for each modified drawing.
;;; A clautolisp session always has a drawing: closing the last one opens a
;;; fresh untitled drawing first (AutoCAD is left with none).

(defparameter *saveas-format-answers*
  '(("DXF" :dxf-ascii nil) ("2018" nil :ac1032) ("2013" nil :ac1027) ("2010" nil :ac1024)
    ("2007" nil :ac1021) ("2004" nil :ac1018) ("2000" nil :ac1015))
  "SAVEAS file-format answers -> (FORMAT VERSION).")

(defun %drawing-current-path (drawing)
  (let ((path (clautolisp.drawing:drawing-path drawing)))
    (if path
        (namestring path)
        (namestring (merge-pathnames (clautolisp.drawing:drawing-name drawing)
                                     (uiop:getcwd))))))

(defun %file-answer-p (token)
  (and (stringp token) (plusp (length token)) (not (%command-name-p token))))

(defun %cmd-qsave (host tokens)
  (let ((drawing (cador-active-drawing host)))
    (cond
      ((clautolisp.drawing:drawing-path drawing)
       (cador-save-drawing host drawing (namestring (clautolisp.drawing:drawing-path drawing))))
      ((%file-answer-p (first tokens))
       (cador-save-drawing host drawing (pop tokens)))))
  tokens)

(defun %cmd-save (host tokens)
  (let* ((drawing (cador-active-drawing host))
         (answer (and (stringp (first tokens)) (not (%command-name-p (first tokens)))
                      (pop tokens)))
         (path (if (and answer (plusp (length answer))) answer (%drawing-current-path drawing))))
    (cador-save-drawing host drawing path))
  tokens)

(defun %cmd-saveas (host tokens)
  (let* ((drawing (cador-active-drawing host))
         (format-row (and (stringp (first tokens))
                          (assoc (string-left-trim "_" (first tokens)) *saveas-format-answers*
                                 :test #'string-equal))))
    (when format-row (pop tokens))
    (let* ((answer (and (stringp (first tokens)) (not (%command-name-p (first tokens)))
                        (pop tokens)))
           (path (if (and answer (plusp (length answer))) answer (%drawing-current-path drawing))))
      (cador-save-drawing host drawing path
                          :format (second format-row) :version (third format-row))))
  tokens)

(defun %yes-answer-p (token)
  (and (stringp token)
       (member (string-left-trim "_" token) '("Y" "YES" "O" "OUI") :test #'string-equal)))

(defun %close-document (host key tokens)
  "Close document KEY, answering \"Save changes?\" from TOKENS when it is
modified. Returns the remaining TOKENS."
  (let ((drawing (cdr (assoc key (cador-documents host) :test #'string=))))
    (when (and drawing (plusp (clautolisp.drawing:drawing-dbmod drawing))
               (stringp (first tokens)) (not (%command-name-p (first tokens))))
      (let ((answer (pop tokens)))
        (when (%yes-answer-p answer)
          (cond
            ((clautolisp.drawing:drawing-path drawing)
             (cador-save-drawing host drawing (namestring (clautolisp.drawing:drawing-path drawing))))
            ((%file-answer-p (first tokens))
             (cador-save-drawing host drawing (pop tokens)))))))
    (cador-close-document host key)
    tokens))

(defun %cmd-close (host tokens)
  (%close-document host (cador-active-document-key host) tokens))

(defun %cmd-closeall (host tokens)
  (dolist (key (mapcar #'car (cador-documents host)) tokens)
    (setf tokens (%close-document host key tokens))))

(define-cador-command "QSAVE" '%cmd-qsave)
(define-cador-command "SAVE" '%cmd-save)
(define-cador-command "SAVEAS" '%cmd-saveas)
(define-cador-command "CLOSE" '%cmd-close)
(define-cador-command "CLOSEALL" '%cmd-closeall)
(define-cador-command "NEW" '%cmd-new)
(define-cador-command "OPEN" '%cmd-open)
(define-cador-command '("MENULOAD" "CUILOAD") '%cmd-menuload)
