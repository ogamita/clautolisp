;;;; optkw-probe.lsp -- harvest the localised OPTION KEYWORDS of CAD commands
;;;; (the second, and hardest, CAD locale dictionary) for cadtui
;;;; (issues/open/cadtui-locale-option-keywords).
;;;;
;;;; There is no getcname-equivalent for option keywords: the only way to read a
;;;; command's offered options is to ENTER the command and let it print its
;;;; prompt, which on a localised install lists the localised keywords in
;;;; brackets, e.g. OFFSET -> "... ou [Par/Effacer/Calque] <...>:". We invoke
;;;; each command with PROMPTOPTIONTRANSLATEKEYWORDS on and CMDECHO on so the
;;;; prompt reaches stdout, bracket the output with markers, then CANCEL the
;;;; command hard (a bounded ESC loop guards against a wedged prompt holding the
;;;; single CAD runner). The converter parses the "[...]" keyword lists between
;;;; the markers.
;;;;
;;;; SCOPE: a NARROW set of common commands whose options appear at the first
;;;; prompt (the issue: scope narrowly, expand later). On the clautolisp dry-run
;;;; the commands are stand-ins, so the blocks are empty but well-formed.
;;;;
;;;; Output (stdout is captured verbatim; the payload is the prompt text between
;;;; the markers):
;;;;   OPTKW-ENGINE  <PROGRAM>  <ACADVER>  <PLATFORM>  <LOCALE>
;;;;   OPTKW-BEGIN   _<COMMAND>
;;;;   ... the command's prompt, incl. its [option/list] ...
;;;;   OPTKW-END     _<COMMAND>
;;;;   OPTKW-DONE

;; A narrow set of command-line commands whose options show at the first prompt.
;; Dialog-prone commands (HATCH, ARRAY) are deliberately excluded: they can open
;; a modal dialog that a plain cancel will not clear, wedging the CAD runner.
(setq *optkw-cmds*
  (list "OFFSET" "TRIM" "EXTEND" "FILLET" "CHAMFER" "MIRROR"
        "ROTATE" "SCALE" "ZOOM" "RECTANG" "PLINE"
        "BREAK" "LENGTHEN"))

(vl-catch-all-apply 'setvar (list "CMDECHO" 1))
(vl-catch-all-apply 'setvar (list "PROMPTOPTIONTRANSLATEKEYWORDS" 1))

(defun cancel-active ( / n)
  ;; Cancel until no command is active, bounded so a stuck prompt cannot hang.
  (setq n 0)
  (while (and (< n 6)
              (< 0 (cond ((vl-catch-all-error-p
                            (setq v (vl-catch-all-apply 'getvar (list "CMDACTIVE"))))
                          0)
                         ((numberp v) v)
                         (t 0))))
    (vl-catch-all-apply 'command '())
    (setq n (1+ n))))

(defun probe-cmd (name)
  (princ (strcat "\nOPTKW-BEGIN\t_" name "\n"))
  (vl-catch-all-apply
    (function (lambda () (command (strcat "_" name)))))
  (cancel-active)
  (princ (strcat "\nOPTKW-END\t_" name "\n"))
  nil)

(princ (strcat "OPTKW-ENGINE\t"
               (vl-princ-to-string (vl-catch-all-apply 'getvar (list "PROGRAM")))
               "\t"
               (vl-princ-to-string (vl-catch-all-apply 'getvar (list "ACADVER")))
               "\t"
               (vl-princ-to-string (vl-catch-all-apply 'getvar (list "PLATFORM")))
               "\t"
               (vl-princ-to-string (vl-catch-all-apply 'getvar (list "LOCALE")))
               "\n"))
(foreach c *optkw-cmds* (probe-cmd c))
(princ "\nOPTKW-DONE\n")
(princ)
