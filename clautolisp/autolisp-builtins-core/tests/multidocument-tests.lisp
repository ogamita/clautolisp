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

