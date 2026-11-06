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
;;;;        documentation/autolisp-visual-lisp-specification-draft.org \
;;;;        [../clautolisp/cador/source/]   ; where cador's commands are read

(defpackage #:gen-command-entries (:use #:cl))
(in-package #:gen-command-entries)

;;; The CAD commands the cador host EXECUTES against the drawing model, and the
;;; ones it RECOGNISES as no-ops (consumed so a driven sequence keeps flowing,
;;; no drawing-model effect) -- READ from its sources, every DEFINE-CADOR-COMMAND
;;; form in ../clautolisp/cador/source/*.lisp: a handler whose name contains
;;; NOOP is a recognised no-op. (These were hand-kept lists, and fell behind:
;;; QSAVE, SHAPE, -VPORTS ... read "Not yet implemented".)

(defvar *cador-implemented* '())
(defvar *cador-recognised-noop* '())

(defun scan-cador-commands (source-dir)
  "Fill *CADOR-IMPLEMENTED* / *CADOR-RECOGNISED-NOOP* from the
DEFINE-CADOR-COMMAND forms of the .lisp files in SOURCE-DIR."
  (let ((*read-eval* nil)
        (*package* (or (find-package "GEN-COMMAND-SCAN")
                       (make-package "GEN-COMMAND-SCAN" :use '()))))
    (dolist (file (directory (merge-pathnames "*.lisp" source-dir)))
      (let ((text (with-open-file (in file :external-format :utf-8)
                    (let ((str (make-string (file-length in))))
                      (subseq str 0 (read-sequence str in))))))
        (loop for start = (search "(define-cador-command " text)
                then (search "(define-cador-command " text :start2 (1+ start))
              while start
              do (record-cador-command
                  (ignore-errors (read-from-string text t nil :start start)))))))
  (values (length *cador-implemented*) (length *cador-recognised-noop*)))

(defun record-cador-command (form)
  "Record the command names of one (DEFINE-CADOR-COMMAND NAMES 'HANDLER) form."
  (when (and (consp form) (= 3 (length form)))
    (let* ((names (second form))
           (handler (third form))
           (names (cond ((stringp names) (list names))
                        ((and (consp names) (eq (first names) 'quote)) (second names))))
           (noop (and (consp handler) (symbolp (second handler))
                      (search "NOOP" (symbol-name (second handler))))))
      (dolist (n names)
        (when (stringp n)
          (if noop
              (pushnew n *cador-recognised-noop* :test #'string=)
              (pushnew n *cador-implemented* :test #'string=)))))))

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

(defun availability-lines (pl)
  "The *** Availability list, in the Function Entry form the page builder
reads for the A / B coverage flags: one line per vendor -- with its version
range -- or 'not documented' where the vendor has no such command."
  (let ((avail (getf pl :availability))
        (acv (getf pl :autocad-versions))
        (bcv (getf pl :bricscad-versions)))
    (flet ((vendor (product versions)
             (if (or (null versions) (not (stringp versions)) (string-equal versions "all"))
                 (format nil "- ~A, all versions: documented." product)
                 (format nil "- ~A ~A: documented." product versions)))
           (absent (product) (format nil "- ~A: not documented." product)))
      (ecase avail
        (:both (list (vendor "AutoCAD" acv) (vendor "BricsCAD" bcv)))
        (:autocad-only (list (vendor "AutoCAD" acv) (absent "BricsCAD")))
        (:bricscad-only (list (absent "AutoCAD") (vendor "BricsCAD" bcv)))
        (:clautolisp (list (absent "AutoCAD") (absent "BricsCAD")))))))

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

(defun tier-line (pl)
  "The Phase 3 support tier (autolisp-spec-alref-commands.issue)."
  (ecase (getf pl :tier)
    (:core-now "Support tier: core-now -- in scope for implementation in the cador and cadtui hosts.")
    (:package-specific "Support tier: package-specific -- one vendor's surface; specified and classified, not scheduled for implementation.")
    (:deferred "Support tier: deferred -- in scope eventually, not scheduled now.")))

(defun clautolisp-line (name)
  (cond
    ((member name *cador-implemented* :test #'string=)
     "Implemented in the cador host (executed against the drawing model).")
    ((member name *cador-recognised-noop* :test #'string=)
     "Recognised by the cador host as a model-only no-op: its input is consumed so a driven command sequence keeps flowing, but it has no drawing-model effect (viewport/coordinate context or external process).")
    (t
     "Not yet implemented: (command ...) stops at it, with a \"; cador:\" notice on the console and no AutoLISP error; the call is recorded on the command log.")))

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
    (format out "*** Availability~%~{~A~%~}- clautolisp: ~A~%~%"
            (availability-lines pl) (clautolisp-line name))
    (format out "*** Compatibility~%~A~%~%" (compatibility-line pl))
    (format out "*** clautolisp~%~A~%~A~%~%" (clautolisp-line name) (tier-line pl))
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
  (destructuring-bind (inv-path org-path &optional
                       (cador-dir "../clautolisp/cador/source/"))
      (rest sb-ext:*posix-argv*)
    (multiple-value-bind (executed noops) (scan-cador-commands cador-dir)
      (format *error-output* "gen-command-entries: cador executes ~D commands, no-ops ~D~%"
              executed noops)
      (when (zerop executed)
        (error "No DEFINE-CADOR-COMMAND found under ~A" cador-dir)))
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
