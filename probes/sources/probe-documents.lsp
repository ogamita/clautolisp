;;;; probes/sources/probe-documents.lsp
;;;;
;;;; Multi-document semantics (cador-multidocument-host, pjb 2026-10-05: "do
;;;; the multidocument cador/cadtui"; deferred-document-lifecycle-command-
;;;; semantics.issue asks A -- the switch deferred until the routine unwinds --
;;;; or B -- inline). LAST in the manifest: a NEW may end the run.
;;;;   docs-sysvars -- DWGNAME, DWGTITLED, DBMOD, SDI, and DBMOD after an edit;
;;;;   docs-com     -- Documents.Count / ActiveDocument / Add / the new
;;;;                   document's Active and Name / Close (BricsCAD; AutoCAD's
;;;;                   console has no COM);
;;;;   docs-new     -- inside ONE routine: (command "_.NEW" ""), then what the
;;;;                   routine sees -- does it continue, in which drawing
;;;;                   (DWGNAME), with which variables (a marker set before).
;;;; Every step under VL-CATCH-ALL-APPLY; COMMAND only from a lambda.

(defun cad-probe--doc-show (cad-probe--doc-thunk / r)
  (setq r (vl-catch-all-apply cad-probe--doc-thunk '()))
  (if (vl-catch-all-error-p r)
      (strcat "ERROR " (vl-catch-all-error-message r))
      (vl-prin1-to-string r)))

(defun cad-probe--doc (suite name cad-probe--doc-fn)
  (cad-probe-capture suite name
    (function (lambda () (cad-probe--doc-show cad-probe--doc-fn)))))

(defun cad-probe--doc-name (cad-probe--doc-d)
  (if cad-probe--doc-d (vla-get-name cad-probe--doc-d) "NO-DOC"))

(defun cad-probe-run-document-probes ( / acad docs newdoc)
  (vl-catch-all-apply 'vl-load-com '())
  ;; --- docs-sysvars ---------------------------------------------------------
  (foreach cad-probe--doc-var '("DWGNAME" "DWGTITLED" "DBMOD" "SDI" "DWGPREFIX")
    (cad-probe--doc "docs-sysvars" (strcat "(getvar \"" cad-probe--doc-var "\")")
      (function (lambda () (getvar cad-probe--doc-var)))))
  (cad-probe--doc "docs-sysvars" "DBMOD after drawing a LINE"
    (function (lambda ()
                (command "_.LINE" "0,0" "3,4" "")
                (getvar "DBMOD"))))
  ;; --- docs-com --------------------------------------------------------------
  (setq acad (vl-catch-all-apply 'vlax-get-acad-object '()))
  (if (vl-catch-all-error-p acad) (setq acad nil))
  (setq docs (if acad (vl-catch-all-apply 'vla-get-documents (list acad))))
  (if (vl-catch-all-error-p docs) (setq docs nil))
  (cad-probe--doc "docs-com" "Documents.Count before"
    (function (lambda () (vla-get-count docs))))
  (cad-probe--doc "docs-com" "ActiveDocument.Name before"
    (function (lambda () (cad-probe--doc-name (vla-get-activedocument acad)))))
  (setq newdoc (if docs (vl-catch-all-apply 'vla-add (list docs))))
  (if (vl-catch-all-error-p newdoc)
      (progn
        (cad-probe--doc "docs-com" "Documents.Add" (function (lambda () newdoc)))
        (setq newdoc nil)))
  (cad-probe--doc "docs-com" "after Add: new document Name / Active"
    (function (lambda () (list (vla-get-name newdoc) (vla-get-active newdoc)))))
  (cad-probe--doc "docs-com" "after Add: Count / ActiveDocument.Name"
    (function (lambda () (list (vla-get-count docs)
                               (cad-probe--doc-name (vla-get-activedocument acad))))))
  (cad-probe--doc "docs-com" "after Add: (getvar \"DWGNAME\") in the running routine"
    (function (lambda () (getvar "DWGNAME"))))
  (cad-probe--doc "docs-com" "new document's ModelSpace.Count (separate database?)"
    (function (lambda () (vla-get-count (vla-get-modelspace newdoc)))))
  (cad-probe--doc "docs-com" "Close the new document, then Count"
    (function (lambda ()
                (vla-close newdoc :vlax-false)
                (vla-get-count docs))))
  ;; --- docs-new (last: it may end the run) -----------------------------------
  (setq cad-probe--doc-marker "set-before-NEW")
  (cad-probe--doc "docs-new" "(command \"_.NEW\" \"\") then, in the same routine: DWGNAME / marker / CMDACTIVE"
    (function (lambda ( / before)
                (setq before (getvar "DWGNAME"))
                (command "_.NEW" "")
                (list before (getvar "DWGNAME") cad-probe--doc-marker (getvar "CMDACTIVE")
                      (if acad (cad-probe--doc-name (vla-get-activedocument acad)) "NO-COM")))))
  (cad-probe--doc "docs-new" "after the NEW step: still running, DWGNAME"
    (function (lambda () (list "RUNNING" (getvar "DWGNAME")))))
  (princ))
