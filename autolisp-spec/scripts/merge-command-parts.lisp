;;;; merge-command-parts.lisp — validate and merge the Wave-2 partial harvest
;;;; files (documentation/.harvest/part-*.sexp) with the pilot inventory into
;;;; documentation/commands-inventory.sexp.
;;;;
;;;; Each part file is one list of command plists. The pilot's 25 entries in
;;;; commands-inventory.sexp are kept; on a name collision the pilot entry wins
;;;; (it was authored/verified first). Output is sorted by :name, deduplicated.
;;;;
;;;; Usage (from autolisp-spec/):
;;;;   sbcl --script scripts/merge-command-parts.lisp

(defpackage #:merge-command-parts (:use #:cl))
(in-package #:merge-command-parts)

(defparameter *keys*
  '(:name :category :aliases :intl-name :synopsis :options :arguments
    :description :availability :autocad-versions :bricscad-versions
    :source-autocad :source-bricscad))

(defun read-list (path)
  (with-open-file (in path :external-format :utf-8)
    (let ((*read-eval* nil)) (read in))))

(defun part-paths ()
  (sort (directory "documentation/.harvest/part-*.sexp") #'string<
        :key #'namestring))

(defun main ()
  (let ((table (make-hash-table :test 'equal))  ; name -> plist
        (order '())
        (part-count 0) (part-total 0))
    ;; Parts first (lower precedence), then pilot overrides.
    (dolist (path (part-paths))
      (let ((entries (read-list path)))
        (incf part-count)
        (incf part-total (length entries))
        (format *error-output* "  ~A: ~D~%" (file-namestring path) (length entries))
        (dolist (pl entries)
          (let ((name (getf pl :name)))
            (unless (gethash name table) (push name order))
            (setf (gethash name table) pl)))))
    ;; Pilot inventory wins on collisions.
    (let ((pilot (read-list "documentation/commands-inventory.sexp")))
      (format *error-output* "  pilot commands-inventory.sexp: ~D~%" (length pilot))
      (dolist (pl pilot)
        (let ((name (getf pl :name)))
          (unless (gethash name table) (push name order))
          (setf (gethash name table) pl))))
    (let* ((names (sort (remove-duplicates order :test #'equal) #'string<))
           (merged (mapcar (lambda (n) (gethash n table)) names)))
      ;; sanity: every plist has exactly the 13 keys
      (dolist (pl merged)
        (loop for k in *keys*
              unless (member k pl)
                do (error "entry ~A missing key ~A" (getf pl :name) k)))
      (with-open-file (o "documentation/commands-inventory.sexp"
                         :direction :output :if-exists :supersede
                         :external-format :utf-8)
        (format o ";;;; -*- Mode: Lisp; coding: utf-8 -*-~%")
        (format o ";;;; Commands inventory feeding the autolisp-spec Commands chapter.~%")
        (format o ";;;; Harvested from help.autodesk.com (2026 ENU) + help.bricsys.com (V25).~%")
        (format o ";;;; One plist per command, sorted by :NAME. Facts come only from the~%")
        (format o ";;;; cited vendor pages; an absent fact is NIL. Generated/merged by~%")
        (format o ";;;; scripts/merge-command-parts.lisp — do not hand-edit.~%")
        (format o ";;;; Keys, in order: ~{~A~^ ~}~%~%" *keys*)
        (format o "(~%")
        (dolist (pl merged)
          (format o "(:name ~S~% :category ~S~% :aliases ~S~% :intl-name ~S~%"
                  (getf pl :name) (getf pl :category) (getf pl :aliases) (getf pl :intl-name))
          (format o " :synopsis ~S~% :options ~S~% :arguments ~S~%"
                  (getf pl :synopsis) (getf pl :options) (getf pl :arguments))
          (format o " :description ~S~% :availability ~S~%"
                  (getf pl :description) (getf pl :availability))
          (format o " :autocad-versions ~S~% :bricscad-versions ~S~%"
                  (getf pl :autocad-versions) (getf pl :bricscad-versions))
          (format o " :source-autocad ~S~% :source-bricscad ~S)~%~%"
                  (getf pl :source-autocad) (getf pl :source-bricscad)))
        (format o ")~%"))
      (format *error-output* "MERGED ~D parts (~D entries) -> ~D distinct commands~%"
              part-count part-total (length merged)))))

(handler-case (main)
  (error (e) (format *error-output* "ERROR: ~A~%" e) (sb-ext:exit :code 1)))
