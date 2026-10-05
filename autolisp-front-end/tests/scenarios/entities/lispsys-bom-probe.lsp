;;;; lispsys-bom-probe.lsp -- encoding-situations-cli-options experiment E1.
;;;;
;;;; How does AutoCAD's NATIVE (load) decode a source file: by its BOM, by
;;;; LISPSYS, or by the code page? scripts/run-lispsys-bom-probe.ps1 writes
;;;; three fixtures into $E1_DIR, each one line (setq *e1-value* "AéZ") with
;;;; the é encoded differently -- e1-cp1252.lsp (E9), e1-utf8.lsp (C3 A9),
;;;; e1-utf8bom.lsp (EF BB BF, then C3 A9) -- sets LISPSYS in every AutoCAD
;;;; profile, and starts AutoCAD once per level (LISPSYS is read at start).
;;;;
;;;; Prints one "ENC E1 ..." line per fixture: (STRLEN CODES) of the string
;;;; read, or LOAD-ERR and the message. A correct decode is 3 characters,
;;;; é = 233 in the middle; (4 (65 195 169 90)) is UTF-8 read as windows-1252.
;;;;
;;;; LOAD is reached through (read "load"): alfe rewrites a literal (load ...)
;;;; in the files it loads into its own deporting loader, which would decode
;;;; the fixture itself and measure alfe instead of AutoCAD.

(defun e1--line (text)
  (princ (strcat "\nENC E1 " text "\n")))

(defun e1-run ( / dir r)
  (setq dir (getenv "E1_DIR"))
  (e1--line (strcat "LISPSYS " (vl-prin1-to-string (getvar "LISPSYS"))
                    " ACADVER " (vl-prin1-to-string (getvar "ACADVER"))
                    " DIR " (vl-prin1-to-string dir)))
  (foreach e1--label '("cp1252" "utf8" "utf8bom")
    (setq *e1-value* nil)
    (setq r (vl-catch-all-apply (read "load")
                                (list (strcat dir "/e1-" e1--label ".lsp"))))
    (e1--line
     (strcat e1--label " "
             (cond ((vl-catch-all-error-p r)
                    (strcat "LOAD-ERR " (vl-catch-all-error-message r)))
                   ((= (type *e1-value*) 'STR)
                    (vl-prin1-to-string (list (strlen *e1-value*)
                                              (vl-string->list *e1-value*))))
                   (t (strcat "NO-VALUE " (vl-prin1-to-string *e1-value*)))))))
  (princ "\nENC-PROBE DONE\n")
  (princ))

(e1-run)
