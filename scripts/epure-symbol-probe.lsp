;;;; Does the EPURE application define ANYTHING in the session alfe drives?
;;;;
;;;; alfe-plugin-epure-windows-validation. On 2026-09-27 three of four
;;;; invocations reached READY -- AutoCAD in 30.95 s, BricsCAD in 24.24 s --
;;;; and all three failed identically with "no function definition:
;;;; TOUTES_OPTIONS". That says the engines are fine and the API is not there.
;;;; It does NOT say which of two very different things happened:
;;;;
;;;;   a. EPURE never loaded at all, so nothing of its is defined;
;;;;   b. EPURE loaded into a context whose symbols this session cannot see,
;;;;      or under names other than the two we call.
;;;;
;;;; Those need different fixes, so the next run must tell them apart instead
;;;; of re-asking the same question.
;;;;
;;;; WHY ATOMS-FAMILY AND NOT A CALL. `vl-catch-all-apply' CANNOT trap an
;;;; unbound-symbol error -- that is recorded for the vendor probes and it is
;;;; why calling the function to test for it destroys the session's answer.
;;;; ATOMS-FAMILY asks whether the symbol EXISTS without evaluating it.
;;;;
;;;; Output is one OBSERVE-shaped line per fact, so a reader (and the job log)
;;;; can be grepped without parsing AutoLISP.

(defun alfe-epure-probe ( / all hits sample n)
  ;; Mode 1 returns NAMES (strings), which is what WCMATCH needs.
  (setq all (atoms-family 1))
  (setq hits '())
  (foreach name all
    ;; Exclude OUR OWN symbols. Measured, not foreseen: run under clautolisp
    ;; (which has no EPURE at all) the first version of this probe counted
    ;; ALFE-EPURE-PROBE itself -- "*EPURE*" matches it -- and therefore reported
    ;; `defined-under-other-names' when the truth was `nothing-defined'. A probe
    ;; that sees itself answers the wrong question, and on the runner that wrong
    ;; answer would have looked like a finding.
    (if (and (not (wcmatch name "ALFE-*"))
             (or (wcmatch name "*EPURE*")
                 (wcmatch name "F_*")
                 (wcmatch name "TOUTES_*")))
      (setq hits (cons name hits))))
  (princ (strcat "\nEPURE-PROBE total-symbols=" (itoa (length all))))
  (princ (strcat "\nEPURE-PROBE epure-like-symbols=" (itoa (length hits))))
  ;; The two names the API test actually calls, asked for by name: a list with
  ;; the name in it means defined, nil in its place means absent.
  (princ (strcat "\nEPURE-PROBE named="
                 (vl-princ-to-string
                  (atoms-family 1 (list "TOUTES_OPTIONS" "F_DATEHEURE_UTC")))))
  ;; A bounded sample, so a session with hundreds of EPURE symbols does not
  ;; bury the log while a session with three still shows them.
  (setq n 0 sample '())
  (foreach name hits
    (if (< n 12)
      (progn (setq sample (cons name sample))
             (setq n (1+ n)))))
  (princ (strcat "\nEPURE-PROBE sample=" (vl-princ-to-string sample)))
  ;; How to read it, stated here so the answer does not need this file open:
  ;;   epure-like-symbols=0            -> case (a), EPURE defined nothing
  ;;   epure-like-symbols>0, named=(nil nil) -> case (b), other names
  ;;   named has both, yet the call fails    -> neither; look at the call
  (princ (strcat "\nEPURE-PROBE verdict="
                 (cond ((= 0 (length hits)) "nothing-defined")
                       ((not (car (atoms-family 1 (list "TOUTES_OPTIONS"))))
                        "defined-under-other-names")
                       (t "names-present"))))
  (princ))

(alfe-epure-probe)
