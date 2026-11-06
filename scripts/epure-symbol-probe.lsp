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

;;; A SAMPLE OF EPURE'S REAL PUBLIC API, evenly spaced through the 422-name
;;; catalogue that generates its own unit tests
;;; (~/src/pjb/epuree/tests/unit/public-api-catalog.lsp, itself generated from
;;; spec/api/public-api.yaml). pjb, 2026-09-27: "toutes_options is EPURE; you may
;;; have a look at EPURE API looking into epuree".
;;;
;;; WHY A SAMPLE AND NOT TWO NAMES. The first run of this probe asked only for the
;;; two functions the API test calls, found neither, and concluded "defined under
;;; other names" -- true but useless. Meanwhile it HAD found
;;; SNCF:EPURE:REG:ENV:SET, which is itself in that catalogue. So part of the
;;; public API is loaded and part is not, and the useful question is WHICH: a
;;; census over a spread of modules says whether one module is missing or the
;;; whole function library is, and those are different faults.
;;;
;;; Names are asked for verbatim; ATOMS-FAMILY is case-insensitive in the hosts
;;; we drive, and the catalogue's own spelling is kept so a reader can grep it
;;; there.
;;; SETQ, not DEFVAR: DEFVAR is Common Lisp and AutoLISP has no such function --
;;; the first version of this file died with "Undefined AutoLISP function DEFVAR"
;;; when run under clautolisp, which is exactly what the local negative control
;;; is for. A CAD would have failed the same way, one queued job later.
(setq *alfe-epure-api-sample*
  (list "toutes_options"        ; the one the API test calls (module COM)
        "f_DateHeure_UTC"       ; the other one
        "dateheureutc"
        "epuree-directory"
        "epure-version"
        "epure-directory"
        "com_startup"
        "com_version"
        "com_savecont"
        "com_way"
        "SNCF:Epure:Reg:Env:Set"  ; FOUND in the session on both engines
        "interr"
        "affiche_message"
        "identite"
        "fld"
        "rempl"
        "getbloc"
        "dos_chdir"
        "pose"
        "f_nom_date"
        "com_tl_continu"
        "schme_sauvegrd"
        "Annuaire"
        "ConvertAuto"))

(defun alfe-epure-api-census ( / present absent)
  (setq present '() absent '())
  (foreach name *alfe-epure-api-sample*
    (if (car (atoms-family 1 (list name)))
      (setq present (cons name present))
      (setq absent (cons name absent))))
  (princ (strcat "\nEPURE-PROBE api-sample=" (itoa (length *alfe-epure-api-sample*))
                 " present=" (itoa (length present))
                 " absent=" (itoa (length absent))))
  (princ (strcat "\nEPURE-PROBE api-present=" (vl-princ-to-string (reverse present))))
  (princ (strcat "\nEPURE-PROBE api-absent=" (vl-princ-to-string (reverse absent))))
  ;; present=0 means the function library never loaded at all; a mixture means
  ;; SOME modules loaded and names the ones that did not, which is the fault to
  ;; chase. all present would mean the API test's two names are simply wrong.
  (princ (strcat "\nEPURE-PROBE api-verdict="
                 (cond ((= 0 (length present)) "library-absent")
                       ((= 0 (length absent))  "library-complete")
                       (t "library-partial"))))
  (princ))

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
    ;; "*ALFE*", not "ALFE-*", and the difference cost a second wrong verdict.
    ;; The prefix form caught ALFE-EPURE-PROBE but not *ALFE-EPURE-API-SAMPLE*,
    ;; whose name begins with a star -- so the probe counted its own variable and
    ;; reported `defined-under-other-names' on a session with no EPURE at all.
    ;; Twice now, by two different name shapes: match OUR MARKER ANYWHERE.
    (if (and (not (wcmatch name "*ALFE*"))
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
(alfe-epure-api-census)
