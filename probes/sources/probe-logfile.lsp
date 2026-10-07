;;;; probes/sources/probe-logfile.lsp
;;;;
;;;; The command-history log file (LOGFILEMODE / LOGFILEPATH / LOGFILENAME),
;;;; measured before cador writes one per drawing (pjb 2026-10-06). One suite,
;;;; logfile:
;;;;   - the defaults: the three sysvars as found, and -- when the run is driven
;;;;     by alfe, which points LOGFILEPATH at its workdir -- the values alfe
;;;;     found and saved in *AUTOLISP_LOG_STATE* (mode path);
;;;;   - the name: DWGNAME / DWGPREFIX beside LOGFILENAME, before and after a
;;;;     LOGFILEMODE 0 -> 1 toggle (a new file per toggle?);
;;;;   - LOGFILEPATH moved to a fresh directory: LOGFILENAME follows? the file
;;;;     exists at once?
;;;;   - the content: after a PRINC marker (with an e-acute), a LINE command and
;;;;     a GETVAR at the prompt, LOGFILEMODE 0 closes the file; its lines are
;;;;     read back (first 60), with the char codes of the marker line;
;;;;   - LOGFILEMODE 1 again: same name or new, appended or rewritten;
;;;;   - (setvar "LOGFILENAME" ...) -- read-only, the message.
;;;;   - the log's encoding (BricsCAD's was not settled: windows-1252 or UTF-8
;;;;     with a BOM): its SIZE in bytes against what (open "r") reads back --
;;;;     characters, lines, characters above 127 -- so the runner can tell a
;;;;     single-octet file (size = chars + line ends) from a UTF-8 one (each
;;;;     accented character one byte more, plus 3 for a BOM).
;;;; Every step under VL-CATCH-ALL-APPLY; COMMAND only from a lambda.

(defun cad-probe--log-show (cad-probe--log-thunk / r)
  (setq r (vl-catch-all-apply cad-probe--log-thunk '()))
  (if (vl-catch-all-error-p r)
      (strcat "ERROR " (vl-catch-all-error-message r))
      (vl-prin1-to-string r)))

(defun cad-probe--log (name cad-probe--log-fn)
  (cad-probe-capture "logfile" name
    (function (lambda () (cad-probe--log-show cad-probe--log-fn)))))

(defun cad-probe--log-state ()
  (list (getvar "LOGFILEMODE") (getvar "LOGFILEPATH") (getvar "LOGFILENAME")))

(defun cad-probe--log-lines (path limit / f line acc n)
  ;; The first LIMIT lines of PATH and the total line count, or :NO-FILE.
  (if (and path (/= path "") (findfile path))
    (progn
      (setq f (open path "r") n 0)
      (while (setq line (read-line f))
        (setq n (1+ n))
        (if (<= n limit) (setq acc (cons line acc))))
      (close f)
      (list n (reverse acc)))
    :NO-FILE))

(defun cad-probe--log-marker-codes (path / f line found)
  ;; The char codes of the first line holding PRB-LOG-MARKER.
  (if (and path (/= path "") (findfile path))
    (progn
      (setq f (open path "r"))
      (while (and (not found) (setq line (read-line f)))
        (if (vl-string-search "PRB-LOG-MARKER" line)
          (setq found (vl-string->list line))))
      (close f)
      found)
    :NO-FILE))

(defun cad-probe--log-measure (path / f line chars lines nhigh first c)
  ;; (SIZE CHARS LINES HIGH-CHARS FIRST-HIGH-CODES): the file's byte size and,
  ;; read back with (open "r"), its character count (line ends excluded), its
  ;; line count, how many characters are above 127, and the first ten such
  ;; codes. Or :NO-FILE.
  (if (and path (/= path "") (findfile path))
    (progn
      (setq f (open path "r") chars 0 lines 0 nhigh 0 first '())
      (while (setq line (read-line f))
        (setq lines (1+ lines) chars (+ chars (strlen line)))
        (foreach c (vl-string->list line)
          (if (> c 127)
            (progn
              (setq nhigh (1+ nhigh))
              (if (< (length first) 10) (setq first (cons c first)))))))
      (close f)
      (list (vl-file-size path) chars lines nhigh (reverse first)))
    :NO-FILE))

(defun cad-probe-run-logfile-probes ( / cad-probe--log-dir cad-probe--log-name
                                        cad-probe--log-old)
  (setq cad-probe--log-old (list (getvar "LOGFILEMODE") (getvar "LOGFILEPATH")))
  ;; --- defaults -------------------------------------------------------------
  (cad-probe--log "as found: (LOGFILEMODE LOGFILEPATH LOGFILENAME)"
    (function cad-probe--log-state))
  (cad-probe--log "alfe's saved (LOGFILEMODE LOGFILEPATH), or nil"
    (function (lambda ()
                (if (boundp '*AUTOLISP_LOG_STATE*) (eval '*AUTOLISP_LOG_STATE*) :NOT-ALFE))))
  (cad-probe--log "(DWGNAME DWGPREFIX TEMPPREFIX)"
    (function (lambda () (list (getvar "DWGNAME") (getvar "DWGPREFIX") (getvar "TEMPPREFIX")))))
  (cad-probe--log "LOGFILENAME file exists? (vl-file-size)"
    (function (lambda () (vl-file-size (getvar "LOGFILENAME")))))
  ;; --- the name across a toggle --------------------------------------------
  (cad-probe--log "LOGFILEMODE 0: state"
    (function (lambda () (setvar "LOGFILEMODE" 0) (cad-probe--log-state))))
  (cad-probe--log "LOGFILEMODE 1: state"
    (function (lambda () (setvar "LOGFILEMODE" 1) (cad-probe--log-state))))
  ;; --- a fresh directory ----------------------------------------------------
  (setq cad-probe--log-dir (strcat (getvar "TEMPPREFIX") "prblogdir"))
  (cad-probe--log "vl-mkdir TEMPPREFIX/prblogdir"
    (function (lambda () (vl-mkdir cad-probe--log-dir))))
  (cad-probe--log "setvar LOGFILEPATH dir (no trailing separator): state"
    (function (lambda () (setvar "LOGFILEPATH" cad-probe--log-dir) (cad-probe--log-state))))
  (cad-probe--log "files in the new dir right after"
    (function (lambda () (vl-directory-files cad-probe--log-dir nil 1))))
  ;; --- the content ----------------------------------------------------------
  (cad-probe--log "princ marker, LINE, getvar"
    (function (lambda ()
                (princ (strcat "\nPRB-LOG-MARKER caf" (chr 233) " (e-acute)\n"))
                (command "_.LINE" "0,0" "1,1" "")
                (getvar "CLAYER"))))
  (setq cad-probe--log-name (getvar "LOGFILENAME"))
  (cad-probe--log "LOGFILEMODE 0 (closes): state"
    (function (lambda () (setvar "LOGFILEMODE" 0) (cad-probe--log-state))))
  (cad-probe--log "files in the new dir after closing"
    (function (lambda () (vl-directory-files cad-probe--log-dir nil 1))))
  (cad-probe--log "the log: (line-count first-60-lines)"
    (function (lambda () (cad-probe--log-lines cad-probe--log-name 60))))
  (cad-probe--log "the marker line's char codes"
    (function (lambda () (cad-probe--log-marker-codes cad-probe--log-name))))
  (cad-probe--log "the log's (size chars lines high-chars first-high-codes)"
    (function (lambda () (cad-probe--log-measure cad-probe--log-name))))
  ;; --- reopened -------------------------------------------------------------
  (cad-probe--log "LOGFILEMODE 1 again: state"
    (function (lambda () (setvar "LOGFILEMODE" 1) (cad-probe--log-state))))
  (cad-probe--log "princ second marker"
    (function (lambda () (princ "\nPRB-LOG-SECOND\n") T)))
  (cad-probe--log "LOGFILEMODE 0: the log now (line-count first-60-lines)"
    (function (lambda ()
                (setvar "LOGFILEMODE" 0)
                (cad-probe--log-lines (getvar "LOGFILENAME") 60))))
  (cad-probe--log "files in the new dir at the end"
    (function (lambda () (vl-directory-files cad-probe--log-dir nil 1))))
  ;; --- the empty name (clautolisp's (findfile "") gave the current directory)
  (cad-probe--log "(findfile \"\")"
    (function (lambda () (findfile ""))))
  (cad-probe--log "(vl-file-size \"\")"
    (function (lambda () (vl-file-size ""))))
  ;; --- read-only ------------------------------------------------------------
  (cad-probe--log "(setvar \"LOGFILENAME\" \"x.log\")"
    (function (lambda () (setvar "LOGFILENAME" "x.log"))))
  ;; leave logging as found: alfe drains the CAD's output through this log.
  (cad-probe--log "restored as found: state"
    (function (lambda ()
                (setvar "LOGFILEPATH" (cadr cad-probe--log-old))
                (setvar "LOGFILEMODE" (car cad-probe--log-old))
                (cad-probe--log-state)))))
