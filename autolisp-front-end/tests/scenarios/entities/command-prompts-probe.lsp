;;;; command-prompts-probe.lsp — capture the VERBATIM command-line prompt and
;;;; option-keyword strings each drawing command issues, on real AutoCAD and
;;;; BricsCAD, so clautolisp's (command ...) token feeds can be checked against
;;;; the engine that actually prompts.
;;;;
;;;; Why this probe exists (windows-runner-sunset-probe-campaign.issue, batch
;;;; B12): the Options / Argument-Sequence rows in the autolisp-spec command
;;;; dictionary are harvested from vendor docs, never captured from a running
;;;; product. The correctness-critical subset is the ~18 commands cador
;;;; actually drives (LINE, CIRCLE, ARC, PLINE, MTEXT, INSERT/-INSERT,
;;;; LAYER/-LAYER, LINETYPE/-LINETYPE, ...). AutoCAD's prompts are the
;;;; perishable half — reachable only through the Windows runner that is going
;;;; away; BricsCAD's stay capturable on macOS.
;;;;
;;;; MECHANISM. A real CAD leaves a command ACTIVE between (command ...) calls
;;;; and records the text of its current prompt in the LASTPROMPT sysvar, with
;;;; CMDACTIVE != 0 while a command is running. So we feed ONE token at a time
;;;; and read (getvar "LASTPROMPT") between tokens; the sequence of prompts IS
;;;; the option/keyword grammar. The headless cador model has NO interactive
;;;; prompt loop — it consumes a whole token list in one call and leaves
;;;; LASTPROMPT "" / CMDACTIVE 0 — so the clautolisp baseline column only
;;;; CONFIRMS RECOGNITION (the name resolves, no "unknown command"); the real
;;;; prompt strings come from the vendors. That asymmetry is the point.
;;;;
;;;; SAFETY. Driving a half-finished command in batch can hang the engine, so:
;;;;  - every (command ...) and (getvar ...) runs under vl-catch-all-apply;
;;;;  - before and after each command we CANCEL any still-active command by
;;;;    sending empty input while CMDACTIVE != 0, capped, so one wedged command
;;;;    cannot poison the next or hang the run;
;;;;  - the per-command token script is only driven while CMDACTIVE != 0 and
;;;;    under a hard step cap; a script may be EMPTY, meaning "capture the
;;;;    initial prompt (the option list — the money datum) then cancel".
;;;;
;;;; Each line is machine-readable:
;;;;   CMDPROBE <name>|<step>|active=<n>|cmdnames=<s>|prompt=<prin1 string>
;;;; ending with "CMDPROBE DONE".

(setq *cmdp-step-cap* 8)   ; max tokens driven into one command
(setq *cmdp-cancel-cap* 8) ; max empty-inputs sent to cancel a command

(defun cmdp-getvar (name / r)
  (setq r (vl-catch-all-apply 'getvar (list name)))
  (if (vl-catch-all-error-p r) nil r))

(defun cmdp-active ( / v)
  (setq v (cmdp-getvar "CMDACTIVE"))
  (if (numberp v) v 0))

(defun cmdp-emit (name step / lp cn)
  ;; Record the current prompt / active flag / active-command names.
  (setq lp (cmdp-getvar "LASTPROMPT")
        cn (cmdp-getvar "CMDNAMES"))
  (princ (strcat "CMDPROBE " name "|" (itoa step)
                 "|active=" (itoa (cmdp-active))
                 "|cmdnames=" (vl-princ-to-string cn)
                 "|prompt=" (vl-prin1-to-string lp) "\n"))
  (princ))

(defun cmdp-cancel ( / n)
  ;; Send empty input until no command is active (capped). Empty input
  ;; ends a point/keyword prompt and unwinds a wedged command.
  (setq n 0)
  (while (and (< n *cmdp-cancel-cap*) (> (cmdp-active) 0))
    (vl-catch-all-apply 'command '(""))
    (setq n (1+ n))))

(defun cmdp-feed (tok)
  ;; Feed one token (a string keyword/number, or a point list) to the
  ;; active command; never let it signal.
  (vl-catch-all-apply 'command (list tok)))

(defun cmdp-one (entry / name tokens step)
  ;; ENTRY is (NAME TOKEN ...). Start the command, capture its initial
  ;; prompt, then drive the scripted tokens while it stays active.
  (setq name   (car entry)
        tokens (cdr entry)
        step   0)
  (cmdp-cancel)                                 ; clean slate
  (vl-catch-all-apply 'command (list (strcat "_" name)))
  (cmdp-emit name 0)                            ; the initial prompt + option list
  (foreach tok tokens
    (if (and (< step *cmdp-step-cap*) (> (cmdp-active) 0))
        (progn
          (setq step (1+ step))
          (cmdp-feed tok)
          (cmdp-emit name step))))
  (cmdp-cancel)                                 ; leave nothing active
  (princ))

;; The SEED command table. Each entry is (NAME TOKEN ...): tokens drive the
;; command far enough to expose its prompts and the branches we care about.
;; An EMPTY token list means "capture the initial prompt only, then cancel" —
;; the safe default for commands whose completion is risky to script blind
;; (OFFSET/FILLET/TRIM/EXTEND option lists, the dash-LAYER keyword menu).
;; Extend this table toward the full cador-implemented set as each command's
;; safe token script is confirmed on a live engine (see the campaign issue).
(setq *cmdp-commands*
  (list
    ;; Geometry primitives with a safe, completing script.
    (list "LINE"   '(0.0 0.0) '(1.0 1.0) "")
    (list "CIRCLE" '(0.0 0.0) 1.0)
    (list "CIRCLE" "_3P")                       ; expose the 3P/2P/Ttr branch
    (list "ARC"    '(0.0 0.0))                  ; initial prompt, then cancel
    (list "PLINE"  '(0.0 0.0) '(1.0 0.0) "")
    (list "TEXT"   '(0.0 0.0) 1.0 0.0 "probe" "")
    ;; Option-list capture only (initial prompt is the keyword menu).
    (list "-LAYER")
    (list "-LINETYPE")
    (list "-INSERT")
    (list "RECTANG")
    (list "OFFSET")                             ; divergence: BricsCAD "Both sides"
    (list "FILLET")                             ; divergence: Expression/Chain/Loop
    (list "TRIM")                               ; divergence: Quick/Standard mode
    (list "EXTEND")))

(defun probe-command-prompts ( / )
  ;; Report the environment knobs that shape the prompts, then each command.
  (princ (strcat "CMDPROBE ENV|0|active=0|cmdnames=|prompt="
                 (vl-prin1-to-string
                   (list (cons "CMDECHO"        (cmdp-getvar "CMDECHO"))
                         (cons "TRIMEXTENDMODE" (cmdp-getvar "TRIMEXTENDMODE"))
                         (cons "LASTPROMPT-ok"  (if (cmdp-getvar "LASTPROMPT") "Y" "N"))))
                 "\n"))
  (foreach entry *cmdp-commands*
    (vl-catch-all-apply 'cmdp-one (list entry)))
  (princ "CMDPROBE DONE\n")
  (princ))

(vl-catch-all-apply 'probe-command-prompts nil)
(princ "CMDPROBE DONE\n")
(princ)
