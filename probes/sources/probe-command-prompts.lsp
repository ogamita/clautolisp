;;;; probes/sources/probe-command-prompts.lsp
;;;;
;;;; Capture the verbatim command-line prompt / option-keyword strings each
;;;; drawing command issues (windows-runner-sunset-probe-campaign.issue B12).
;;;; clautolisp's (command ...) token feeds depend on these; the Options /
;;;; Argument-Sequence rows in the autolisp-spec command dictionary are
;;;; doc-harvested, never product-captured.
;;;;
;;;; WHY A probes/ SUITE (not an alfe scenario probe): the probe:suite:autocad
;;;; job runs this manifest DIRECTLY in accoreconsole (runner_template
;;;; "accoreconsole.exe /s run.scr"), with no alfe protocol layer. A first
;;;; attempt drove the command through alfe and LASTPROMPT came back as alfe's
;;;; own injected bootstrap line, not the command's prompt. Run direct in the
;;;; engine, LASTPROMPT reflects the real command. (The BricsCAD suite is still
;;;; alfe-driven -- detect-cad.sh -- so its prompt column may show the same
;;;; alfe artefact; AutoCAD, the perishable half, is the one that runs direct.)
;;;;
;;;; MECHANISM: a real CAD leaves a command ACTIVE between (command ...) calls
;;;; (CMDACTIVE != 0) and records the current prompt in LASTPROMPT. We feed one
;;;; token at a time and read LASTPROMPT between tokens; the recorded VALUE for
;;;; each step is (CMDACTIVE . LASTPROMPT).
;;;;
;;;; SAFETY: every (command)/(getvar) under vl-catch-all-apply; a cancel-reset
;;;; sends empty input while CMDACTIVE != 0 (capped) before and after each
;;;; command, so one wedged command cannot hang the run or poison the next.
;;;; A per-command token script may be EMPTY: "capture the initial prompt (the
;;;; option list) then cancel" -- the safe default for commands whose blind
;;;; completion is risky (OFFSET/FILLET/TRIM/EXTEND, the dash-LAYER menu).

(defun cad-probe--cp-active ( / v)
  (setq v (vl-catch-all-apply 'getvar '("CMDACTIVE")))
  (if (numberp v) v 0))

(defun cad-probe--cp-lastprompt ( / v)
  (setq v (vl-catch-all-apply 'getvar '("LASTPROMPT")))
  (if (vl-catch-all-error-p v) nil v))

(defun cad-probe--cp-cancel ( / n)
  (setq n 0)
  (while (and (< n 8) (> (cad-probe--cp-active) 0))
    (vl-catch-all-apply 'command '(""))
    (setq n (1+ n))))

(defun cad-probe--cp-step (name step)
  ;; Record (CMDACTIVE . LASTPROMPT) as this step's value.
  (cad-probe-capture "command-prompts" (strcat name "/" (itoa step))
    (function (lambda () (cons (cad-probe--cp-active) (cad-probe--cp-lastprompt))))))

(defun cad-probe--cp-one (name tokens / step)
  (cad-probe--cp-cancel)
  (vl-catch-all-apply 'command (list (strcat "_" name)))
  (cad-probe--cp-step name 0)                 ; initial prompt + option list
  (setq step 0)
  (foreach tok tokens
    (if (and (< step 8) (> (cad-probe--cp-active) 0))
        (progn
          (setq step (1+ step))
          (vl-catch-all-apply 'command (list tok))
          (cad-probe--cp-step name step))))
  (cad-probe--cp-cancel))

(defun cad-probe-run-command-prompts-probes ( / table)
  ;; Environment knobs that shape the prompts (TRIMEXTENDMODE drives the TRIM /
  ;; EXTEND option set; CMDECHO the echo).
  (cad-probe-capture "command-prompts" "ENV"
    (function (lambda ()
      (list (cons "CMDECHO"        (vl-catch-all-apply 'getvar '("CMDECHO")))
            (cons "TRIMEXTENDMODE" (vl-catch-all-apply 'getvar '("TRIMEXTENDMODE")))
            (cons "LASTPROMPT-readable" (if (cad-probe--cp-lastprompt) "Y" "N"))))))
  ;; SEED table; each entry (NAME TOKEN ...). Empty token list = capture the
  ;; initial option prompt then cancel. Grow toward the full cador-implemented
  ;; set as each safe token script is confirmed on a live engine.
  (setq table
    (list
      (list "LINE"   '(0.0 0.0) '(1.0 1.0) "")
      (list "CIRCLE" '(0.0 0.0) 1.0)
      (list "CIRCLE" "_3P")                    ; expose the 3P/2P/Ttr branch
      (list "ARC"    '(0.0 0.0))
      (list "PLINE"  '(0.0 0.0) '(1.0 0.0) "")
      (list "TEXT"   '(0.0 0.0) 1.0 0.0 "probe" "")
      (list "-LAYER")
      (list "-LINETYPE")
      (list "-INSERT")
      (list "RECTANG")
      (list "OFFSET")                          ; divergence: BricsCAD "Both sides"
      (list "FILLET")                          ; divergence: Expression/Chain/Loop
      (list "TRIM")                            ; divergence: Quick/Standard mode
      (list "EXTEND")))
  (foreach entry table
    (vl-catch-all-apply 'cad-probe--cp-one (list (car entry) (cdr entry))))
  (princ))
