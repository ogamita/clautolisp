;;;; autolisp-front-end/source/template.lisp
;;;;
;;;; --template NAME|PATH: one of the CAD's own templates as the session's
;;;; drawing, instead of the embedded empty.dwg (empty-drawing.lisp).

(defpackage #:alfe.template
  (:use #:cl)
  (:export #:find-template
           #:list-templates
           #:copy-template))

(in-package #:alfe.template)

;;; alfe-template-option (pjb 2026-10-24). empty.dwg is a French AutoCAD
;;; 2005 drawing: a session on it starts on THAT database, not on a new
;;; drawing of the CAD. --template NAME|PATH copies one of the CAD's own
;;; templates into the run's workdir instead, as template.dwg (a .dwt and a
;;; .dwg share the format; as a .dwg the CAD opens it with no units dialog),
;;; a fresh copy per run as for empty.dwg (a shared file gets locked: modal
;;; "in use" dialogs, empty-drawing.lisp). A NAME is looked up where the
;;; products keep their templates, in the product's own folders only (the
;;; rule of probes/scripts/run-probes.sh: walking a whole %LOCALAPPDATA% took
;;; 12 minutes on the Windows runner); the user's folders come first.

(defun %template-roots ()
  "The folders the products keep their templates under, the user's first."
  (remove-duplicates
   (remove nil
           (append
            (mapcar (lambda (variable)
                      (let ((value (uiop:getenv variable)))
                        (and value (plusp (length value))
                             (uiop:ensure-directory-pathname value))))
                    '("LOCALAPPDATA" "APPDATA" "PROGRAMFILES" "ProgramW6432" "PROGRAMDATA"))
            (list (uiop:ensure-directory-pathname
                   (merge-pathnames "Library/Application Support/"
                                    (user-homedir-pathname)))
                  #p"/Applications/")))
   :test #'equal))

(defun %template-product-patterns (product)
  (case product
    (:autocad '("autodesk"))
    (:bricscad '("brics"))
    (t '("autodesk" "brics"))))

(defun %directory-leaf (directory)
  (let ((parts (pathname-directory directory)))
    (if (consp parts) (string (car (last parts))) "")))

(defun %template-product-directories (product)
  "The PRODUCT's own folders under the template roots: each root's
top-level folders whose name holds the product's pattern."
  (let ((patterns (%template-product-patterns product)))
    (loop for root in (%template-roots)
          when (uiop:directory-exists-p root)
            append (remove-if-not
                    (lambda (directory)
                      (let ((leaf (%directory-leaf directory)))
                        (some (lambda (p) (search p leaf :test #'char-equal)) patterns)))
                    (ignore-errors (uiop:subdirectories root))))))

(defun %walk-files (directory depth function)
  "Call FUNCTION on every file under DIRECTORY, DEPTH levels deep at most."
  (dolist (file (ignore-errors (uiop:directory-files directory)))
    (funcall function file))
  (when (plusp depth)
    (dolist (sub (ignore-errors (uiop:subdirectories directory)))
      (%walk-files sub (1- depth) function))))

(defun list-templates (product)
  "Every .dwt in PRODUCT's folders (:AUTOCAD, :BRICSCAD, or NIL for both)."
  (let ((found '()))
    (dolist (directory (%template-product-directories product))
      (%walk-files directory 8
                   (lambda (file)
                     (when (string-equal "dwt" (or (pathname-type file) ""))
                       (push file found)))))
    (nreverse found)))

(defun find-template (name product)
  "The template NAME|PATH names for PRODUCT: a PATH (it has a directory
separator) when that file exists, else the first file named NAME (case
ignored) in PRODUCT's folders, or NIL."
  (if (or (find #\/ name) (find #\\ name))
      (let ((path (probe-file name)))
        (and path (not (uiop:directory-pathname-p path)) path))
      (dolist (directory (%template-product-directories product) nil)
        (%walk-files directory 8
                     (lambda (file)
                       (when (string-equal name (file-namestring file))
                         (return-from find-template file)))))))

(defun copy-template (source directory &key (name "template.dwg"))
  "Copy the template SOURCE into DIRECTORY as NAME and return the copy."
  (let ((path (merge-pathnames name (uiop:ensure-directory-pathname directory))))
    (ensure-directories-exist path)
    (uiop:copy-file source path)
    (truename path)))
