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

(defun e1-run ( / dir r e1--path)
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
  ;; OPEN's third (encoding) argument at this LISPSYS level (open-third-
  ;; argument-dialect-divergence: at LISPSYS 0 AutoCAD 2022 rejects it; at
  ;; 1 / 2 it is documented, "utf8" / "utf8-bom", never measured). Writes
  ;; "A" e-acute "B" and reports the file size (3 cp1252, 4 UTF-8, 7 UTF-8 +
  ;; BOM) and what (open f "r") and (open f "r" "utf8") read back.
  (foreach e1--case '(("default" "w") ("utf8" "w" "utf8") ("utf8bom" "w" "utf8-bom"))
    (setq e1--path (strcat dir "/e1-open-" (car e1--case) ".txt"))
    (setq r (vl-catch-all-apply
             '(lambda ( / f)
                (setq f (apply 'open (cons e1--path (cdr e1--case))))
                (write-char 65 f) (write-char 233 f) (write-char 66 f)
                (close f)
                (vl-file-size e1--path))
             '()))
    (e1--line (strcat "open-w-" (car e1--case) " "
                      (if (vl-catch-all-error-p r)
                        (strcat "ERR " (vl-catch-all-error-message r))
                        (strcat "SIZE " (vl-prin1-to-string r)))))
    (foreach e1--read '(("r") ("r" "utf8"))
      (setq r (vl-catch-all-apply
               '(lambda ( / f c acc)
                  (setq f (apply 'open (cons e1--path e1--read)))
                  (while (setq c (read-char f)) (setq acc (cons c acc)))
                  (close f)
                  (reverse acc))
               '()))
      (e1--line (strcat "open-w-" (car e1--case) " read-" (apply 'strcat e1--read) " "
                        (if (vl-catch-all-error-p r)
                          (strcat "ERR " (vl-catch-all-error-message r))
                          (vl-prin1-to-string r))))))
  ;; APPEND with the third argument: write "A" e-acute "B" with
  ;; (open f "w" ENC), append one e-acute with (open f "a" ENC), report both
  ;; sizes -- "utf8": 4 then 6; "utf8-bom": 7 then 9 (no second BOM) or 12.
  ;; Measured 2026-10-08 (AutoCAD 2022, job 16998925786): LISPSYS 1 / 2 give
  ;; (4 6) and (7 9) -- no second BOM -- and LISPSYS 0 "too many arguments";
  ;; so alfe forwards -Efile-write UTF-8 to an "a" as well.
  (foreach e1--enc '("utf8" "utf8-bom")
    (setq e1--path (strcat dir "/e1-append-" e1--enc ".txt"))
    (setq r (vl-catch-all-apply
             '(lambda ( / f s1)
                (setq f (open e1--path "w" e1--enc))
                (write-char 65 f) (write-char 233 f) (write-char 66 f)
                (close f)
                (setq s1 (vl-file-size e1--path))
                (setq f (open e1--path "a" e1--enc))
                (write-char 233 f)
                (close f)
                (list s1 (vl-file-size e1--path)))
             '()))
    (e1--line (strcat "open-a-" e1--enc " "
                      (if (vl-catch-all-error-p r)
                        (strcat "ERR " (vl-catch-all-error-message r))
                        (strcat "SIZES " (vl-prin1-to-string r))))))
  (princ "\nENC-PROBE DONE\n")
  (princ))

(e1-run)
