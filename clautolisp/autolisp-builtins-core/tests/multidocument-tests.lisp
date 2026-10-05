(in-package #:clautolisp.autolisp-builtins-core.tests)

(in-suite autolisp-builtins-core-suite)

;;;; Multi-document cador (cador-multidocument-host; pjb 2026-10-05: "do the
;;;; multidocument cador/cadtui"). Each open drawing has its own LISP
;;;; namespace, and a lifecycle command switches document at the next
;;;; top-level read, as AutoCAD does (deferred-document-lifecycle-command-
;;;; semantics, option A).

(defun %md-context ()
  "A fresh session on a cador host, linked as the CLI links it."
  (reset-autolisp-symbol-table)
  (clautolisp.autolisp-runtime:reset-default-evaluation-context)
  (install-core-builtins)
  (let* ((context (clautolisp.autolisp-runtime:default-evaluation-context))
         (session (clautolisp.autolisp-runtime:evaluation-context-session context))
         (host (clautolisp.cador:make-cador)))
    (clautolisp.autolisp-runtime:set-runtime-session-host session host)
    (clautolisp.autolisp-host:link-runtime-session-to-host session host)
    context))

(defun %md-turn (context text)
  "One top-level turn, as the REPL runs it: apply a pending document switch,
then evaluate TEXT. Returns the value."
  (clautolisp.autolisp-runtime:apply-pending-document-switch context)
  (clautolisp.autolisp-runtime:autolisp-eval-progn
   (clautolisp.autolisp-runtime:read-runtime-from-string text)
   context))

(defun %md-host (context)
  (clautolisp.autolisp-runtime:runtime-session-host
   (clautolisp.autolisp-runtime:evaluation-context-session context)))

(test new-switches-document-at-the-next-top-level-read
  (let* ((context (%md-context))
         (host (%md-host context))
         (start (clautolisp.autolisp-host:host-current-document host)))
    (%md-turn context "(setq md-marker \"first\")")
    ;; Inside ONE form: NEW, then the rest of the routine still runs in the
    ;; first drawing and sees its variables.
    (is (equal "first"
               (autolisp-string-value
                (%md-turn context "(progn (command \"_.NEW\" \"\") md-marker)"))))
    (is (equal start (clautolisp.autolisp-host:host-current-document host)))
    ;; The next top-level read is in the new drawing: a new namespace.
    (is (null (%md-turn context "md-marker")))
    (let ((now (clautolisp.autolisp-host:host-current-document host)))
      (is (not (equal start now)))
      (is (equal 2 (length (clautolisp.autolisp-host:host-document-list host)))))))

(test each-document-has-its-own-namespace-and-propagation-crosses
  (let* ((context (%md-context)))
    (%md-turn context "(setq md-own 1 md-shared 2)")
    (%md-turn context "(vl-propagate 'md-shared)")
    (%md-turn context "(command \"_.NEW\" \"\")")
    (is (null (%md-turn context "md-own")))
    (is (eql 2 (%md-turn context "md-shared")))
    ;; The blackboard is the application's, shared.
    (%md-turn context "(vl-bb-set 'md-bb 42)")
    (%md-turn context "(command \"_.NEW\" \"\")")
    (is (eql 42 (%md-turn context "(vl-bb-ref 'md-bb)")))))

(test entities-made-after-new-go-to-the-new-drawing
  (let* ((context (%md-context)))
    (%md-turn context "(entmake '((0 . \"LINE\") (10 0.0 0.0 0.0) (11 1.0 0.0 0.0)))")
    ;; Same form: still the first drawing.
    (is (eql 2 (%md-turn context
                         "(progn (command \"_.NEW\" \"\")
                                 (entmake '((0 . \"LINE\") (10 0.0 0.0 0.0) (11 2.0 0.0 0.0)))
                                 (sslength (ssget \"_X\")))")))
    ;; Next read: the new, empty drawing.
    (is (null (%md-turn context "(ssget \"_X\")")))))

;;; --- slice 2: per-document session state; document-tagged enames (C5) ----

(defun %md-switch-to (context key)
  "Make host document KEY current at the next turn (as COM / cadtui will)."
  (clautolisp.autolisp-host:request-host-document-activation (%md-host context) key))

(defun %md-errors-p (context text)
  (handler-case (progn (%md-turn context text) nil)
    (clautolisp.autolisp-runtime:autolisp-runtime-error (e)
      (clautolisp.autolisp-runtime:autolisp-runtime-error-code e))))

(test an-ename-from-another-drawing-signals
  (let* ((context (%md-context))
         (host (%md-host context))
         (first (clautolisp.autolisp-host:host-current-document host)))
    (%md-turn context "(entmake '((0 . \"LINE\") (10 0.0 0.0 0.0) (11 1.0 0.0 0.0)))")
    (%md-turn context "(vl-bb-set 'md-e (entlast))")
    (%md-turn context "(command \"_.NEW\" \"\")")
    (%md-turn context "(setq e (vl-bb-ref 'md-e))")
    (is (eq :cross-document-dereference (%md-errors-p context "(entget e)")))
    (is (eq :cross-document-dereference
            (%md-errors-p context "(entmod (list (cons -1 e) '(8 . \"0\")))")))
    ;; Back in its drawing, the same ename works.
    (%md-switch-to context first)
    (is (%md-turn context "(entget (vl-bb-ref (quote md-e)))"))))

(test selection-sets-pickfirst-and-ldata-are-per-document
  (let* ((context (%md-context))
         (host (%md-host context))
         (first (clautolisp.autolisp-host:host-current-document host)))
    (%md-turn context "(entmake '((0 . \"LINE\") (10 0.0 0.0 0.0) (11 1.0 0.0 0.0)))")
    (%md-turn context "(sssetfirst nil (ssget \"_X\"))")
    (%md-turn context "(vl-load-com)")
    (%md-turn context "(vlax-ldata-put \"MD\" \"k\" 1)")
    (%md-turn context "(command \"_.NEW\" \"\")")
    (is (null (cadr (%md-turn context "(ssgetfirst)"))))
    (is (null (%md-turn context "(vlax-ldata-get \"MD\" \"k\")")))
    (%md-switch-to context first)
    (is (eql 1 (%md-turn context "(sslength (cadr (ssgetfirst)))")))
    (is (eql 1 (%md-turn context "(vlax-ldata-get \"MD\" \"k\")")))))

;;; --- slice 3: DWGNAME / DWGTITLED / DBMOD follow each document ------------

(test dwgname-dwgtitled-dbmod-follow-the-current-drawing
  (let* ((context (%md-context))
         (file (namestring (merge-pathnames (format nil "md-~D.dxf" (random 1000000))
                                            (uiop:temporary-directory)))))
    (unwind-protect
         (progn
           (is (equal "Drawing1.dwg" (autolisp-string-value (%md-turn context "(getvar \"DWGNAME\")"))))
           (is (eql 0 (%md-turn context "(getvar \"DWGTITLED\")")))
           (is (eql 0 (%md-turn context "(getvar \"DBMOD\")")))
           (%md-turn context "(entmake '((0 . \"LINE\") (10 0.0 0.0 0.0) (11 1.0 0.0 0.0)))")
           (is (eql 1 (%md-turn context "(getvar \"DBMOD\")")))
           ;; Saving titles the drawing and clears DBMOD.
           (%md-turn context (format nil "(progn (vl-load-com)
                                            (vla-saveas (vla-get-activedocument (vlax-get-acad-object)) ~S))"
                                     file))
           (is (eql 1 (%md-turn context "(getvar \"DWGTITLED\")")))
           (is (eql 0 (%md-turn context "(getvar \"DBMOD\")")))
           ;; A NEW drawing is the next untitled one, unmodified.
           (%md-turn context "(command \"_.NEW\" \"\")")
           (is (equal "Drawing2.dwg" (autolisp-string-value (%md-turn context "(getvar \"DWGNAME\")"))))
           (is (eql 0 (%md-turn context "(getvar \"DWGTITLED\")")))
           (is (eql 0 (%md-turn context "(getvar \"DBMOD\")"))))
      (ignore-errors (delete-file file)))))

(test bricscad-switches-the-drawing-at-once-the-namespace-at-the-next-read
  "probe-documents: BricsCAD V26 (job 16932759882) -- after (command \"_.NEW\"
\"\") the same routine's DWGNAME is the new drawing's, its variables still its
own; AutoCAD (job 16932759881) stays in the old drawing until the routine ends."
  (let ((context (%md-context)))
    (%md-turn context "(setq *AUTOLISP-DIALECT* 'bricscad-v26)")
    (%md-turn context "(setq md-marker \"first\")")
    (is (equal "(\"Drawing2.dwg\" \"first\")"
               (autolisp-string-value
                (%md-turn context "(progn (command \"_.NEW\" \"\")
                                          (vl-prin1-to-string (list (getvar \"DWGNAME\") md-marker)))"))))
    (is (null (%md-turn context "md-marker"))))
  (let ((context (%md-context)))
    (%md-turn context "(setq *AUTOLISP-DIALECT* 'autocad-2022)")
    (is (equal "Drawing1.dwg"
               (autolisp-string-value
                (%md-turn context "(progn (command \"_.NEW\" \"\") (getvar \"DWGNAME\"))"))))
    (is (equal "Drawing2.dwg" (autolisp-string-value (%md-turn context "(getvar \"DWGNAME\")"))))))

;;; --- slice 4: QSAVE / SAVE / SAVEAS / CLOSE / CLOSEALL --------------------

(defun %md-temp (name)
  (namestring (merge-pathnames (format nil "md-~D-~A" (random 1000000) name)
                               (uiop:temporary-directory))))

(test qsave-saveas-name-the-drawing-after-its-file
  (let* ((context (%md-context))
         (a (%md-temp "a.dxf"))
         (b (%md-temp "b.dxf")))
    (unwind-protect
         (progn
           (%md-turn context "(entmake '((0 . \"LINE\") (10 0.0 0.0 0.0) (11 1.0 0.0 0.0)))")
           ;; Untitled: QSAVE takes a file name.
           (%md-turn context (format nil "(command \"_.QSAVE\" ~S)" a))
           (is (probe-file a))
           (is (equal (file-namestring a)
                      (autolisp-string-value (%md-turn context "(getvar \"DWGNAME\")"))))
           (is (eql 1 (%md-turn context "(getvar \"DWGTITLED\")")))
           (is (eql 0 (%md-turn context "(getvar \"DBMOD\")")))
           ;; SAVEAS with a format answer, then the new file.
           (%md-turn context (format nil "(command \"_.SAVEAS\" \"DXF\" ~S)" b))
           (is (probe-file b))
           (is (equal (file-namestring b)
                      (autolisp-string-value (%md-turn context "(getvar \"DWGNAME\")")))))
      (ignore-errors (delete-file a))
      (ignore-errors (delete-file b)))))

(test close-moves-to-the-next-drawing-and-forgets-its-namespace
  (let* ((context (%md-context))
         (host (%md-host context)))
    (%md-turn context "(setq md-first 1)")
    (%md-turn context "(command \"_.NEW\" \"\")")
    (%md-turn context "(setq md-second 2)")
    (%md-turn context "(entmake '((0 . \"LINE\") (10 0.0 0.0 0.0) (11 1.0 0.0 0.0)))")
    ;; Modified: CLOSE asks "Save changes?" -- N.
    (%md-turn context "(command \"_.CLOSE\" \"_N\")")
    (is (eql 1 (length (clautolisp.autolisp-host:host-document-list host))))
    (is (eql 1 (%md-turn context "md-first")))
    (is (null (%md-turn context "md-second")))
    (is (equal "Drawing1.dwg" (autolisp-string-value (%md-turn context "(getvar \"DWGNAME\")"))))))

(test closeall-leaves-one-fresh-drawing
  (let* ((context (%md-context))
         (host (%md-host context)))
    (%md-turn context "(command \"_.NEW\" \"\")")
    (%md-turn context "(command \"_.NEW\" \"\")")
    (%md-turn context "(setq md-x 1)")
    (%md-turn context "(command \"_.CLOSEALL\")")
    (is (eql 1 (length (clautolisp.autolisp-host:host-document-list host))))
    (is (null (%md-turn context "md-x")))
    (is (null (%md-turn context "(ssget \"_X\")")))))

;;; --- slice 5: COM documents (BricsCAD V26, probe-documents job 16932759882) --

(test com-documents-add-is-a-separate-inactive-drawing
  (let ((context (%md-context)))
    (%md-turn context "(vl-load-com)")
    (%md-turn context "(setq app (vlax-get-acad-object) docs (vla-get-documents app))")
    (%md-turn context "(entmake '((0 . \"LINE\") (10 0.0 0.0 0.0) (11 1.0 0.0 0.0)))")
    (%md-turn context "(setq nd (vla-add docs))")
    (is (equal "(\"Drawing2.dwg\" :VLAX-FALSE 2 \"Drawing1.dwg\" \"Drawing1.dwg\" 0 1)"
               (autolisp-string-value
                (%md-turn context
                          "(vl-prin1-to-string
                             (list (vla-get-name nd) (vla-get-active nd) (vla-get-count docs)
                                   (vla-get-name (vla-get-activedocument app)) (getvar \"DWGNAME\")
                                   (vla-get-count (vla-get-modelspace nd))
                                   (vla-get-count (vla-get-modelspace (vla-get-activedocument app)))))"))))
    ;; vlax-for walks the open documents.
    (is (equal "(\"Drawing1.dwg\" \"Drawing2.dwg\")"
               (autolisp-string-value
                (%md-turn context "(progn (setq n '())
                                          (vlax-for d docs (setq n (cons (vla-get-name d) n)))
                                          (vl-prin1-to-string (reverse n)))"))))
    ;; An entity added through the new document's ModelSpace goes there.
    (%md-turn context "(vla-addline (vla-get-modelspace nd) (vlax-3d-point 0 0 0) (vlax-3d-point 5 5 0))")
    (is (eql 1 (%md-turn context "(vla-get-count (vla-get-modelspace nd))")))
    (is (eql 1 (%md-turn context "(sslength (ssget \"_X\"))")))
    ;; Close: one document again.
    (%md-turn context "(vla-close nd :vlax-false)")
    (is (eql 1 (%md-turn context "(vla-get-count docs)")))))

(test com-activate-and-open-switch-at-the-next-read
  (let* ((context (%md-context))
         (file (namestring (merge-pathnames (format nil "md-open-~D.dxf" (random 1000000))
                                            (uiop:temporary-directory)))))
    (unwind-protect
         (progn
           (%md-turn context "(vl-load-com)")
           (%md-turn context "(setq app (vlax-get-acad-object) docs (vla-get-documents app))")
           (%md-turn context "(setq nd (vla-add docs))")
           ;; SaveAs on the inactive document writes ITS drawing.
           (%md-turn context "(vla-addline (vla-get-modelspace nd) (vlax-3d-point 0 0 0) (vlax-3d-point 5 5 0))")
           (%md-turn context (format nil "(vla-saveas nd ~S)" file))
           (is (probe-file file))
           (%md-turn context "(vla-activate nd)")
           (is (equal (file-namestring file)
                      (autolisp-string-value (%md-turn context "(getvar \"DWGNAME\")"))))
           (is (eql 1 (%md-turn context "(sslength (ssget \"_X\"))")))
           ;; Now in the other document's namespace: its own variables.
           (is (null (%md-turn context "nd")))
           ;; Documents.Open: the file opens as another document, made current.
           (%md-turn context (format nil "(progn (vl-load-com)
                                          (setq docs (vla-get-documents (vlax-get-acad-object))
                                                od (vla-open docs ~S)))" file))
           ;; The next read is in the opened document (AutoCAD: Open activates).
           (is (eql 3 (%md-turn context "(vla-get-count (vla-get-documents (vlax-get-acad-object)))")))
           (is (equal (file-namestring file)
                      (autolisp-string-value (%md-turn context "(getvar \"DWGNAME\")"))))
           (is (eql 1 (%md-turn context "(sslength (ssget \"_X\"))"))))
      (ignore-errors (delete-file file)))))

;;; --- slice 6: the startup chain per document; vl-load-all ------------------

(defun %md-write (path text)
  (with-open-file (out path :direction :output :if-exists :supersede)
    (write-string text out))
  path)

(test acaddoc-and-on-doc-load-run-for-every-drawing
  (let* ((dir (uiop:ensure-directory-pathname
               (merge-pathnames (format nil "md-chain-~D/" (random 1000000))
                                (uiop:temporary-directory))))
         (saved (clautolisp.autolisp-runtime:autolisp-support-paths)))
    (ensure-directories-exist dir)
    (unwind-protect
         (let ((context (%md-context)))
           (%md-write (merge-pathnames "acad.lsp" dir) "(setq md-session-once 1)")
           (%md-write (merge-pathnames "acaddoc.lsp" dir)
                      "(setq md-per-doc (getvar \"DWGNAME\")) (defun s::startup () (setq md-started t))")
           (clautolisp.autolisp-runtime:set-autolisp-support-paths (list (namestring dir)))
           (%md-turn context "(setq *AUTOLISP-DIALECT* 'autocad-2022)")
           (clautolisp.autolisp-builtins-core:run-session-startup-chain context)
           (is (eql 1 (%md-turn context "md-session-once")))
           (is (equal "Drawing1.dwg" (autolisp-string-value (%md-turn context "md-per-doc"))))
           (is (%md-turn context "md-started"))
           ;; A later drawing runs acaddoc.lsp (and S::STARTUP), not acad.lsp.
           (%md-turn context "(command \"_.NEW\" \"\")")
           (is (null (%md-turn context "md-session-once")))
           (is (equal "Drawing2.dwg" (autolisp-string-value (%md-turn context "md-per-doc"))))
           (is (%md-turn context "md-started")))
      (clautolisp.autolisp-runtime:set-autolisp-support-paths saved)
      (uiop:delete-directory-tree dir :validate t))))

(test vl-load-all-loads-into-every-drawing-now-and-later
  (let* ((file (namestring (merge-pathnames (format nil "md-all-~D.lsp" (random 1000000))
                                            (uiop:temporary-directory))))
         (context (%md-context))
         (host (%md-host context))
         (first (clautolisp.autolisp-host:host-current-document host)))
    (unwind-protect
         (progn
           (%md-write file "(defun md-everywhere () \"here\")")
           (%md-turn context "(command \"_.NEW\" \"\")")
           (%md-turn context (format nil "(vl-load-all ~S)" file))
           (is (equal "here" (autolisp-string-value (%md-turn context "(md-everywhere)"))))
           ;; The other open drawing has it ...
           (%md-switch-to context first)
           (is (equal "here" (autolisp-string-value (%md-turn context "(md-everywhere)"))))
           ;; ... and so does one opened later.
           (%md-turn context "(command \"_.NEW\" \"\")")
           (is (equal "here" (autolisp-string-value (%md-turn context "(md-everywhere)")))))
      (ignore-errors (delete-file file)))))

;;; --- slice 7: cadtui mirrors and drives the host documents ------------------

(test cadtui-tree-follows-and-drives-the-host-documents
  (let* ((root (clautolisp.cadtui:make-application-tree))
         (clautolisp.cador:*cador-command-ui-hook*
           (lambda (host event &rest args)
             (declare (ignore host))
             (apply #'clautolisp.cadtui:apply-file-command-event root event args)))
         (context (%md-context))
         (host (%md-host context))
         (clautolisp.cadtui:*cadtui-activate-document-function*
           (lambda (key) (clautolisp.autolisp-host:request-host-document-activation host key)))
         (clautolisp.cadtui:*cadtui-close-document-function*
           (lambda (key) (clautolisp.cador:cador-close-document host key))))
    (flet ((active-key ()
             (clautolisp.cadtui:ui-key
              (clautolisp.cadtui:resolve-target root "/application/active-drawing")))
           (drawing-keys ()
             (loop for node in (clautolisp.cadtui:ui-children root)
                   when (eq :drawing (clautolisp.cadtui:ui-role node))
                     collect (clautolisp.cadtui:ui-key node))))
      ;; The startup drawing, as the CLI seeds it.
      (clautolisp.cadtui:ensure-drawing-node root "Drawing1.dwg")
      (clautolisp.cadtui:apply-file-command-event root :document-activated "Drawing1.dwg")
      ;; NEW: a node at once, current at the next read.
      (%md-turn context "(command \"_.NEW\" \"\")")
      (is (= 2 (length (drawing-keys))))
      (%md-turn context "nil")
      (is (equal "Drawing2.dwg" (active-key)))
      ;; =activate on the first drawing's node: the host switches back.
      (clautolisp.cadtui:interpret-line "=activate(drawings[2])" root)
      (%md-turn context "nil")
      (is (equal "Drawing1.dwg" (autolisp-string-value (%md-turn context "(getvar \"DWGNAME\")"))))
      (is (equal "Drawing1.dwg" (active-key)))
      ;; =close on the other drawing's node closes the host document.
      (clautolisp.cadtui:interpret-line "=close(drawings[2])" root)
      (is (equal '("Drawing1.dwg") (clautolisp.autolisp-host:host-document-list host)))
      (is (equal '("Drawing1.dwg") (drawing-keys))))))


;;; --- the drawing argument (--dwg): the session's first drawing --------------

(test startup-drawing-replaces-the-untitled-drawing
  (let* ((path (namestring (merge-pathnames (format nil "md-start-~D.dxf" (random 1000000))
                                            (uiop:temporary-directory))))
         (maker (clautolisp.cador:make-cador)))
    (unwind-protect
         (progn
           (clautolisp.drawing:write-drawing (clautolisp.cador:cador-active-drawing maker) path)
           (reset-autolisp-symbol-table)
           (clautolisp.autolisp-runtime:reset-default-evaluation-context)
           (install-core-builtins)
           (let* ((context (clautolisp.autolisp-runtime:default-evaluation-context))
                  (session (clautolisp.autolisp-runtime:evaluation-context-session context))
                  (host (clautolisp.cador:make-cador))
                  (key (clautolisp.autolisp-host:host-open-startup-drawing host path)))
             (clautolisp.autolisp-runtime:set-runtime-session-host session host)
             (clautolisp.autolisp-host:link-runtime-session-to-host session host)
             (is (equal (file-namestring path) key))
             ;; The only open drawing, and the current one.
             (is (equal (list key) (clautolisp.autolisp-host:host-document-list host)))
             (is (equal key (autolisp-string-value (%md-turn context "(getvar \"DWGNAME\")"))))
             (is (eql 1 (%md-turn context "(getvar \"DWGTITLED\")")))
             (is (eql 0 (%md-turn context "(getvar \"DBMOD\")")))
             ;; A NEW from there is a second drawing, with its own namespace.
             (%md-turn context "(setq md-in-start 1)")
             (%md-turn context "(command \"_.NEW\" \"\")")
             (is (= 2 (length (clautolisp.autolisp-host:host-document-list host))))
             (is (null (%md-turn context "md-in-start")))))
      (ignore-errors (delete-file path)))))

(test startup-drawing-that-cannot-be-read-signals
  (is (eq t (handler-case
                (progn (clautolisp.autolisp-host:host-open-startup-drawing
                        (clautolisp.cador:make-cador) "/nonexistent/md-none.dxf")
                       nil)
              (error () t)))))

;;; --- viewports: -VPORTS, VPORTS, CVPORT, SETVIEW (probe-viewports) -----------

(defun %vp-run (dialect &rest forms)
  "The value of the last of FORMS in a fresh cador session under DIALECT."
  (let ((context (%md-context)))
    (%md-turn context (format nil "(setq *AUTOLISP-DIALECT* '~A)" dialect))
    (let (value)
      (dolist (form forms value)
        (setq value (%md-turn context form))))))

(test vports-split-and-single-follow-each-product
  ;; AutoCAD 2022: the current viewport keeps the RIGHT half; SIngle keeps 3.
  (is (equal '(2 ((2 (0.5d0 0d0) (1d0 1d0)) (3 (0d0 0d0) (0.5d0 1d0))))
             (%vp-run "autocad-2022" "(command \"_.-VPORTS\" \"2\" \"_V\")"
                      "(list (getvar \"CVPORT\") (vports))")))
  (is (equal '(3 ((3 (0d0 0d0) (1d0 1d0))))
             (%vp-run "autocad-2022" "(command \"_.-VPORTS\" \"2\" \"_V\")"
                      "(command \"_.-VPORTS\" \"_SI\")"
                      "(list (getvar \"CVPORT\") (vports))")))
  ;; BricsCAD: the LEFT half; SIngle keeps the current one, 2.
  (is (equal '(2 ((2 (0d0 0d0) (0.5d0 1d0)) (3 (0.5d0 0d0) (1d0 1d0))))
             (%vp-run "bricscad-v25" "(command \"_.-VPORTS\" \"2\" \"_V\")"
                      "(list (getvar \"CVPORT\") (vports))")))
  (is (equal '(2 ((2 (0d0 0d0) (1d0 1d0))))
             (%vp-run "bricscad-v25" "(command \"_.-VPORTS\" \"2\" \"_V\")"
                      "(command \"_.-VPORTS\" \"_SI\")"
                      "(list (getvar \"CVPORT\") (vports))"))))

(test vports-in-paper-space-and-setview-nil
  (is (equal '(1 ((1 (0d0 0d0) (15.8893d0 9d0)) (2 (25.7d0 19.5d0) (231.3d0 175.5d0))))
             (%vp-run "autocad-2022" "(setvar \"TILEMODE\" 0)"
                      "(list (getvar \"CVPORT\") (vports))")))
  (is (equal '(1 ((1 (-28.613d0 -13.59d0) (285.613d0 208.59d0)) (2 (25.7d0 19.5d0) (231.3d0 175.5d0))))
             (%vp-run "bricscad-v25" "(setvar \"TILEMODE\" 0)"
                      "(list (getvar \"CVPORT\") (vports))")))
  ;; (setview nil): nil under BricsCAD, a bad-argument error under AutoCAD.
  (is (null (%vp-run "bricscad-v25" "(setview nil)")))
  (is (eq t (handler-case (progn (%vp-run "autocad-2022" "(setview nil)") nil)
              (error () t)))))

;;; --- cador-4 slice 1: the HAL document API (D1 §3) and the scope tier (C4) -----

(test host-open-document-from-file-registers-without-switching
  (let* ((path (namestring (merge-pathnames (format nil "md-hal-~D.dxf" (random 1000000))
                                            (uiop:temporary-directory))))
         (context (%md-context))
         (host (%md-host context))
         (first-key (clautolisp.autolisp-host:host-current-document host)))
    (unwind-protect
         (progn
           (%md-turn context "(command \"_.LINE\" \"0,0\" \"1,1\" \"\")")
           (%md-turn context (format nil "(command \"_.SAVEAS\" \"DXF\" ~S)" path))
           (let ((key (clautolisp.autolisp-host:host-open-document-from-file
                       host path :read-only t)))
             (is (stringp key))
             (is (member key (clautolisp.autolisp-host:host-document-list host) :test #'equal))
             ;; Not made current.
             (is (equal first-key (clautolisp.autolisp-host:host-current-document host)))
             (is (clautolisp.cador::doc-session-read-only
                  (clautolisp.cador::cador-document-session host key)))))
      (ignore-errors (delete-file path)))
    ;; An unreadable file is a backend error.
    (is (eq t (handler-case
                  (progn (clautolisp.autolisp-host:host-open-document-from-file
                          host "/nonexistent/md-none.dxf")
                         nil)
                (error () t))))))

(test host-close-document-with-save-writes-the-file
  (let* ((path (namestring (merge-pathnames (format nil "md-close-~D.dxf" (random 1000000))
                                            (uiop:temporary-directory))))
         (context (%md-context))
         (host (%md-host context)))
    (unwind-protect
         (let ((key (clautolisp.autolisp-host:host-open-document host)))
           (clautolisp.autolisp-host:host-close-document host key :save t :file path)
           (is (probe-file path))
           (is (not (member key (clautolisp.autolisp-host:host-document-list host)
                            :test #'equal))))
      (ignore-errors (delete-file path)))))

(test host-document-of-names-the-owning-document
  (let* ((context (%md-context))
         (host (%md-host context))
         (first-key (clautolisp.autolisp-host:host-current-document host)))
    (%md-turn context "(command \"_.LINE\" \"0,0\" \"1,1\" \"\")")
    (let ((ename (%md-turn context "(entlast)")))
      (is (equal first-key (clautolisp.autolisp-host:host-document-of host ename)))
      ;; Still the first document's after a switch.
      (%md-turn context "(command \"_.NEW\" \"\")")
      (%md-turn context "nil")
      (is (equal first-key (clautolisp.autolisp-host:host-document-of host ename)))
      (is (null (clautolisp.autolisp-host:host-document-of host 42))))))

(test host-sysvar-scope-gives-the-tier
  (let ((host (%md-host (%md-context))))
    (is (eq :drawing (clautolisp.autolisp-host:host-sysvar-scope host "LTSCALE")))
    (is (eq :registry (clautolisp.autolisp-host:host-sysvar-scope host "OSMODE")))
    (is (eq :not-saved (clautolisp.autolisp-host:host-sysvar-scope host "CMDACTIVE")))
    (is (eq :drawing (clautolisp.drawing:sysvar-cell-scope
                      (clautolisp.cador:cador-sysvar host "LTSCALE"))))))
