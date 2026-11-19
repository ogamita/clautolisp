;;;; -*- mode:lisp; coding:utf-8 -*-
;;;;
;;;; installed-libraries-test.lisp -- regression test for
;;;; issues/closed/install-libraries-omits-runtime-data-files.issue.
;;;;
;;;; Run by `make -C clautolisp test-installed-libraries', which first runs
;;;; `make install-lisp-systems' into a scratch DESTDIR (the same file list
;;;; `make install-libraries' and the release-libraries artefact use) and
;;;; names the installed share/common-lisp/source/clautolisp/ in
;;;; CLAUTOLISP_INSTALLED_SOURCE. This file then loads clautolisp FROM THAT
;;;; TREE ALONE -- the registry is limited to it, so the checkout cannot
;;;; stand in for a missing file -- and checks what used to come out quietly
;;;; wrong from an install:
;;;;
;;;;   - GETCNAME: its tables are read at COMPILE time from
;;;;     cador/data/getcname/*.sexp; without them "_LINE" gave NIL;
;;;;   - cadtui's locale dictionaries, read at compile time from
;;;;     cadtui/data/locale/<locale>/*.sexp; without them fr_FR was unknown;
;;;;   - the NEW-drawing template drawing/template/empty-drawing.dxf.
;;;;
;;;; Quicklisp, when present, still supplies the third-party dependencies:
;;;; its search function is not part of the source-registry.

(in-package "COMMON-LISP-USER")

(defparameter *ilt-source*
  (or (uiop:getenv-absolute-directory "CLAUTOLISP_INSTALLED_SOURCE")
      (progn
        (format *error-output* "~&installed-libraries: run me with `make -C clautolisp test-installed-libraries'~%")
        (uiop:quit 2)))
  "The installed <PREFIX>/share/common-lisp/source/clautolisp/.")

(asdf:clear-source-registry)
(asdf:initialize-source-registry
 `(:source-registry (:tree ,*ilt-source*) :ignore-inherited-configuration))

(defvar *ilt-failures* 0)

(defun ilt-check (ok format-control &rest arguments)
  (format t "~&installed-libraries: ~:[FAIL~;ok  ~] ~?~%" ok format-control arguments)
  (unless ok (incf *ilt-failures*)))

(defun ilt-under-install-p (pathname)
  (let ((file (and pathname (probe-file pathname))))
    (and file (uiop:subpathp file (truename *ilt-source*)) t)))

(dolist (system '("clautolisp/drawing" "clautolisp/cador" "clautolisp/cadtui"))
  (handler-case (asdf:load-system system)
    (error (e)
      (format t "~&installed-libraries: FAIL loading ~A from the install: ~A~%" system e)
      (uiop:quit 1))))

(ilt-check (ilt-under-install-p (asdf:system-source-file "clautolisp/cador"))
           "clautolisp/cador comes from the install: ~A"
           (asdf:system-source-file "clautolisp/cador"))

(let ((getcname (find-symbol "CADOR-GETCNAME" "CLAUTOLISP.CADOR"))
      (stretch  (coerce '(#\LATIN_CAPITAL_LETTER_E_WITH_ACUTE #\T #\I #\R #\E #\R) 'string)))
  (ilt-check (equal "LINE" (funcall getcname "_LINE" :autocad nil))
             "getcname \"_LINE\" (no locale) => ~S"
             (funcall getcname "_LINE" :autocad nil))
  (ilt-check (equal stretch (funcall getcname "_STRETCH" :bricscad "fr_FR" 26))
             "getcname \"_STRETCH\" BricsCAD V26 fr_FR => ~S"
             (funcall getcname "_STRETCH" :bricscad "fr_FR" 26)))

(ilt-check (funcall (find-symbol "%LOCALE-KNOWN-P" "CLAUTOLISP.CADTUI") "fr_FR")
           "cadtui knows the fr_FR locale")

(let ((template (funcall (find-symbol "DRAWING-TEMPLATE-PATH" "CLAUTOLISP.DRAWING"))))
  (ilt-check (ilt-under-install-p template)
             "the NEW-drawing template is installed: ~A" template))

(if (zerop *ilt-failures*)
    (format t "~&installed-libraries: PASS -- the installed systems carry their data~%")
    (format t "~&installed-libraries: ~D check(s) failed~%" *ilt-failures*))
(uiop:quit (if (zerop *ilt-failures*) 0 1))

;;;; THE END ;;;;
