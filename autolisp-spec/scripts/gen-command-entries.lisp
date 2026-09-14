;;;; gen-command-entries.lisp — regenerate the "** Command Entry: NAME"
;;;; subsections of the Commands chapter from commands-inventory.sexp.
;;;;
;;;; Reads the inventory plists, emits one org subsection per command using
;;;; the fixed Command Entry template, and splices them into the draft org
;;;; between the Commands chapter's Source Notes and the following chapter
;;;; heading. Idempotent: any existing "** Command Entry:" blocks in that
;;;; chapter are dropped first, so re-running replaces rather than appends.
;;;;
;;;; Usage (from autolisp-spec/):
;;;;   sbcl --script scripts/gen-command-entries.lisp \
;;;;        documentation/commands-inventory.sexp \
;;;;        documentation/autolisp-visual-lisp-specification-draft.org

(defpackage #:gen-command-entries (:use #:cl))
(in-package #:gen-command-entries)

;;; The CAD commands the cador MockHost actually EXECUTES against the drawing
;;; (clautolisp/cador/source/command-api.lisp %execute-command-tokens). Keep in
;;; sync with that dispatch; everything else is "not yet implemented".
(defparameter *cador-implemented*
  '("LINE" "CIRCLE" "TEXT" "DONUT" "SOLID" "ERASE" "MOVE" "COPY" "ROTATE" "BLOCK"))

(defun read-inventory (path)
  (with-open-file (in path :external-format :utf-8)
    (let ((*read-eval* nil))
      (read in))))

(defun join (strings sep)
  (with-output-to-string (s)
    (loop for (x . more) on strings
          do (write-string x s) (when more (write-string sep s)))))

(defun list-or-none (items sep)
  (if (and items (plusp (length items))) (join items sep) "None."))

(defun compatibility-line (pl)
  (let ((avail (getf pl :availability))
        (acv (getf pl :autocad-versions))
        (bcv (getf pl :bricscad-versions)))
    (flet ((v (x) (if (and x (stringp x)) x "all")))
      (ecase avail
        (:both (format nil "AutoCAD ~A; BricsCAD ~A." (v acv) (v bcv)))
        (:autocad-only (format nil "AutoCAD ~A only. BricsCAD: not present." (v acv)))
        (:bricscad-only (format nil "BricsCAD ~A only. AutoCAD: not present." (v bcv)))
        (:clautolisp "clautolisp-specific.")))))

(defun clautolisp-line (name)
  (if (member name *cador-implemented* :test #'string=)
      "Implemented in the cador host (executed against the drawing model)."
      "Not yet implemented; the command name is recorded on the command log without side effects."))

(defun category-name (kw)
  (string-downcase (symbol-name kw)))

(defun emit-entry (pl out)
  (let ((name (getf pl :name)))
    (format out "** Command Entry: ~A~%" name)
    (format out "*** Name~%~A~%~%" name)
    (format out "*** Aliases~%~A~%~%" (list-or-none (getf pl :aliases) ", "))
    (format out "*** Synopsis~%~A~%~%" (getf pl :synopsis))
    (format out "*** Options~%~A~%~%" (list-or-none (getf pl :options) " / "))
    (format out "*** Argument Sequence~%~A~%~%" (or (getf pl :arguments) "None."))
    (format out "*** Description~%~A~%~%" (getf pl :description))
    (format out "*** Category~%~A~%~%" (category-name (getf pl :category)))
    (format out "*** Compatibility~%~A~%~%" (compatibility-line pl))
    (format out "*** clautolisp~%~A~%~%" (clautolisp-line name))
    (format out "*** Source Notes~%")
    (let ((ac (getf pl :source-autocad)) (bc (getf pl :source-bricscad)))
      (when ac (format out "- AutoCAD: ~A~%" ac))
      (when bc (format out "- BricsCAD: ~A~%" bc)))
    (format out "~%#+LATEX: \\newpage~%~%")))

(defun read-lines (path)
  (with-open-file (in path :external-format :utf-8)
    (loop for line = (read-line in nil :eof)
          until (eq line :eof) collect line)))

(defun starts-with (line prefix)
  (and (>= (length line) (length prefix))
       (string= line prefix :end1 (length prefix))))

(defun strip-existing-entries (lines)
  "Drop any '** Command Entry: …' block (up to the next '** ' or '* ' heading)."
  (let ((out '()) (skip nil))
    (dolist (line lines (nreverse out))
      (cond
        ((starts-with line "** Command Entry:") (setf skip t))
        ((and skip (or (starts-with line "** ") (starts-with line "* ")))
         (setf skip nil) (push line out))
        (skip)                          ; drop
        (t (push line out))))))

(defun splice (lines entries-text)
  "Insert ENTRIES-TEXT immediately before the '* 29 Glossary' (any '* NN
Glossary') heading that follows '* 28 Commands'."
  (let ((commands-seen nil) (out '()) (done nil))
    (dolist (line lines)
      (when (and (not commands-seen) (search " Commands" line) (starts-with line "* "))
        (setf commands-seen t))
      (when (and commands-seen (not done) (starts-with line "* ") (search "Glossary" line))
        (dolist (el (with-input-from-string (s entries-text)
                      (loop for l = (read-line s nil :eof) until (eq l :eof) collect l)))
          (push el out))
        (setf done t))
      (push line out))
    (unless done (error "Could not find the Glossary heading after the Commands chapter."))
    (nreverse out)))

(defun main ()
  (destructuring-bind (inv-path org-path) (rest sb-ext:*posix-argv*)
    (let* ((inventory (read-inventory inv-path))
           (entries-text (with-output-to-string (s)
                           (dolist (pl inventory) (emit-entry pl s))))
           (lines (strip-existing-entries (read-lines org-path)))
           (spliced (splice lines entries-text)))
      (with-open-file (o org-path :direction :output :if-exists :supersede
                                  :external-format :utf-8)
        (dolist (l spliced) (write-line l o)))
      (format *error-output* "gen-command-entries: wrote ~D command entries into ~A~%"
              (length inventory) org-path))))

(handler-case (main)
  (error (e) (format *error-output* "ERROR: ~A~%" e) (sb-ext:exit :code 1)))
