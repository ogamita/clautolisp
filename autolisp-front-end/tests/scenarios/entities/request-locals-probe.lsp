;;;; request-locals-probe.lsp -- MEASURE whether a user program's global
;;;; variables survive alfe's request machinery on a CAD
;;;; (issues/open/alfe-eval-request-locals-capture-user-setq.issue).
;;;;
;;;; AutoLISP binds a DEFUN's parameters and /-locals dynamically. Under alfe
;;;; every user form -- the -l file, each -x, --main, the REPL -- is evaluated
;;;; while alfe's own CAD-side functions are on the stack. Up to alfe 2.3.14
;;;; those functions bound common names (F, TEXT, R, PATH, FORM, ...), so a
;;;; user (setq f 1) assigned alfe's LOCAL F and the value was gone when the
;;;; request returned. Since 2.3.15 every such binding is named alfe--NAME.
;;;;
;;;; The run scripts (scripts/run-request-locals-probe.*) drive three steps,
;;;; each followed by a LATER request that reads the globals back:
;;;;   1  -l   this file sets them        then  -x (rlp-report 1)
;;;;   2  -x   a direct (setq ...)        then  -x (rlp-report 2)
;;;;   3  -x   (rlp-set-in-fn), a DEFUN   then  -x (rlp-report 3)
;;;;           without locals, as --main runs one
;;;; and end with -x (rlp-done).
;;;;
;;;; Output, one line per observation, space-separated:
;;;;   RLOCALS <step> <name> <kept|lost> <(vl-prin1-to-string value)>
;;;;   RLOCALS-SUMMARY <step> <kept|lost> <number of names lost>
;;;;   RLOCALS-INFO <name> <value>
;;;;   RLOCALS-DONE
;;;; "kept" means the global holds the value the step assigned. Keep this file
;;;; ASCII.

(setq *rlp-names*
  '(f text r path form source err normalized result keep req-id rc
    line obj msg args name value x s idx back on))

;; Step 1 values (as the ticket's repro: f 1 text "t" r 2 path "p" form 3).
(setq *rlp-expect-1*
  (list 1 "t" 2 "p" 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21))

;; Step 2 is the run scripts' -x text; it carries no double quote (Windows
;; PowerShell 5 does not pass one intact), so every value is a number.
(setq *rlp-expect-2*
  (list 111 112 113 114 115 116 117 118 119 120 121 122 123 124 125 126 127
        128 129 130 131 132 133))

(setq *rlp-expect-3*
  (list 211 212 213 214 215 216 217 218 219 220 221 222 223 224 225 226 227
        228 229 230 231 232 233))

(defun rlp-info (rlp--name rlp--value)
  (princ (strcat "RLOCALS-INFO " rlp--name " "
                 (vl-princ-to-string
                   (if (vl-catch-all-error-p rlp--value) "ERROR" rlp--value))
                 "\n")))

(defun rlp-report (rlp--step / rlp--expect rlp--names rlp--lost rlp--v)
  (setq rlp--expect (cond ((= rlp--step 1) *rlp-expect-1*)
                          ((= rlp--step 2) *rlp-expect-2*)
                          (T *rlp-expect-3*)))
  (setq rlp--names *rlp-names*)
  (setq rlp--lost 0)
  (while rlp--names
    (setq rlp--v (eval (car rlp--names)))
    (if (not (equal rlp--v (car rlp--expect)))
      (setq rlp--lost (1+ rlp--lost)))
    (princ (strcat "RLOCALS " (itoa rlp--step) " "
                   (vl-princ-to-string (car rlp--names)) " "
                   (if (equal rlp--v (car rlp--expect)) "kept" "lost") " "
                   (vl-prin1-to-string rlp--v) "\n"))
    (setq rlp--names (cdr rlp--names))
    (setq rlp--expect (cdr rlp--expect)))
  (princ (strcat "RLOCALS-SUMMARY " (itoa rlp--step) " "
                 (if (= rlp--lost 0) "kept" "lost") " "
                 (itoa rlp--lost) "\n"))
  rlp--lost)

;; Step 3: a function with no locals of its own sets the names, the way a
;; --main entry point (or any user function called from -x) does.
(defun rlp-set-in-fn ()
  (setq f 211 text 212 r 213 path 214 form 215 source 216 err 217
        normalized 218 result 219 keep 220 req-id 221 rc 222 line 223
        obj 224 msg 225 args 226 name 227 value 228 x 229 s 230 idx 231
        back 232 on 233)
  T)

(defun rlp-done ()
  (princ "RLOCALS-DONE\n")
  T)

(rlp-info "PRODUCT" (vl-catch-all-apply 'getvar (list "PRODUCT")))
(rlp-info "ACADVER" (vl-catch-all-apply 'getvar (list "ACADVER")))
(rlp-info "ALFE" (if (boundp '*AUTOLISP-VERSION*) *AUTOLISP-VERSION* "none"))

;; --- step 1: the -l file's own top-level setq ---------------------------
(setq f 1 text "t" r 2 path "p" form 3)
(setq source 4 err 5 normalized 6 result 7 keep 8 req-id 9 rc 10 line 11
      obj 12 msg 13 args 14 name 15 value 16 x 17 s 18 idx 19 back 20 on 21)
(princ)
