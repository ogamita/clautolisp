;;;; optkw-probe.lsp -- harvest the localised OPTION KEYWORDS of CAD commands
;;;; (the second, and hardest, CAD locale dictionary) for cadtui
;;;; (issues/open/cadtui-locale-option-keywords).
;;;;
;;;; There is no getcname-equivalent for option keywords: the only way to read a
;;;; command's offered options is to ENTER the command and let it print its
;;;; prompt, which on a localised install lists the localised keywords in
;;;; brackets, e.g. OFFSET -> "... ou [Par/Effacer/Calque] <...>:".
;;;;
;;;; WHERE THE PROMPT IS READ (2026-10-06): from the CAD's own command-history
;;;; LOG, not from stdout. The first version bracketed stdout and got EMPTY
;;;; blocks on BricsCAD V25 Windows and V26 macOS (jobs 16979749963 /
;;;; 16979749962): a prompt never reaches the output alfe collects. The log
;;;; does carry it (probe-logfile, MR !428: AutoCAD logs the whole command line,
;;;; BricsCAD the command channel, e.g. "Depart de la ligne ou [Reprendre]").
;;;; So, per command: point LOGFILEPATH at a fresh directory (a new log file
;;;; there, measured), LOGFILEMODE 1, enter the command, cancel it, LOGFILEMODE
;;;; 0, read that log; then RESTORE the original LOGFILEPATH / LOGFILEMODE
;;;; BEFORE printing anything (alfe drains AutoCAD's output through that log).
;;;; BricsCAD on macOS writes no log in batch mode (measured): empty there.
;;;;
;;;; PROMPTOPTIONTRANSLATEKEYWORDS is set only when the variable exists: on
;;;; AutoCAD 2022's console a setvar of it aborts the whole run, even under
;;;; VL-CATCH-ALL-APPLY (job 16979749961, "parametre ... rejete").
;;;;
;;;; SCOPE: a NARROW set of common commands whose options appear at the first
;;;; prompt (the issue: scope narrowly, expand later).
;;;;
;;;; Output (stdout; the payload is the log lines between the markers):
;;;;   OPTKW-ENGINE  <PROGRAM>  <ACADVER>  <PLATFORM>  <LOCALE>
;;;;   OPTKW-BEGIN   _<COMMAND>
;;;;   OPTKW-LOG     <a line of the command's log>
;;;;   OPTKW-END     _<COMMAND>
;;;;   OPTKW-DONE

;; A narrow set of command-line commands whose options show at the first prompt.
;; Dialog-prone commands (HATCH, ARRAY) are deliberately excluded: they can open
;; a modal dialog that a plain cancel will not clear, wedging the CAD runner.
;; ZOOM LAST: entering it ended the whole accoreconsole run (job 16981155886,
;; OPTKW-INCOMPLETE right after SCALE), so it can cost nothing but itself.
(setq *optkw-cmds*
  (list "OFFSET" "TRIM" "EXTEND" "FILLET" "CHAMFER" "MIRROR"
        "ROTATE" "SCALE" "RECTANG" "PLINE"
        "BREAK" "LENGTHEN" "ZOOM"))

(defun optkw--getvar (name / v)
  (setq v (vl-catch-all-apply 'getvar (list name)))
  (if (vl-catch-all-error-p v) nil v))

(vl-catch-all-apply 'setvar (list "CMDECHO" 1))
(if (optkw--getvar "PROMPTOPTIONTRANSLATEKEYWORDS")
  (vl-catch-all-apply 'setvar (list "PROMPTOPTIONTRANSLATEKEYWORDS" 1)))

(defun optkw--cancel ( / n)
  ;; Cancel until no command is active, bounded so a stuck prompt cannot hang.
  (setq n 0)
  (while (and (< n 6) (< 0 (cond ((numberp (optkw--getvar "CMDACTIVE"))
                                  (optkw--getvar "CMDACTIVE"))
                                 (t 0))))
    (vl-catch-all-apply (function (lambda () (command))))
    (setq n (1+ n))))

(defun optkw--read-lines (path / f line acc)
  (if (and path (/= path "") (findfile path))
    (progn
      (setq f (open path "r"))
      (while (setq line (read-line f)) (setq acc (cons line acc)))
      (close f)
      (reverse acc))))

(defun optkw--log-file (name / file)
  ;; LOGFILENAME is a full path on AutoCAD and BricsCAD Windows, a bare name
  ;; on BricsCAD macOS (in LOGFILEPATH).
  (setq file (optkw--getvar "LOGFILENAME"))
  (cond ((null file) nil)
        ((findfile file) file)
        (t (strcat (optkw--getvar "LOGFILEPATH") file))))

(defun probe-cmd (name / old-path old-mode dir lines)
  (setq old-path (optkw--getvar "LOGFILEPATH")
        old-mode (optkw--getvar "LOGFILEMODE")
        dir (strcat (optkw--getvar "TEMPPREFIX") "optkw-" name))
  (vl-catch-all-apply 'vl-mkdir (list dir))
  (vl-catch-all-apply 'setvar (list "LOGFILEMODE" 0))
  (vl-catch-all-apply 'setvar (list "LOGFILEPATH" dir))
  (vl-catch-all-apply 'setvar (list "LOGFILEMODE" 1))
  (vl-catch-all-apply (function (lambda () (command (strcat "_" name)))))
  (optkw--cancel)
  (vl-catch-all-apply 'setvar (list "LOGFILEMODE" 0))
  (setq lines (optkw--read-lines (optkw--log-file name)))
  ;; restore BEFORE printing: alfe drains AutoCAD's output through the log
  (if old-path (vl-catch-all-apply 'setvar (list "LOGFILEPATH" old-path)))
  (if old-mode (vl-catch-all-apply 'setvar (list "LOGFILEMODE" old-mode)))
  (princ (strcat "\nOPTKW-BEGIN\t_" name "\n"))
  (foreach l lines (princ (strcat "OPTKW-LOG\t" l "\n")))
  (princ (strcat "OPTKW-END\t_" name "\n"))
  nil)

(princ (strcat "OPTKW-ENGINE\t"
               (vl-princ-to-string (optkw--getvar "PROGRAM"))
               "\t"
               (vl-princ-to-string (optkw--getvar "ACADVER"))
               "\t"
               (vl-princ-to-string (optkw--getvar "PLATFORM"))
               "\t"
               (vl-princ-to-string (optkw--getvar "LOCALE"))
               "\n"))
(foreach c *optkw-cmds* (probe-cmd c))
(princ "\nOPTKW-DONE\n")
(princ)
