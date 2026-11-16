;;;; probes/sources/probe-host-fns.lsp
;;;;
;;;; windows-runner-sunset-probe-campaign, batch B8 (AC-crit for the AutoCAD
;;;; halves). Host functions whose behaviour the spec harvested from the
;;;; documentation and never measured:
;;;;
;;;;   - SNVALID: which characters are rejected under EXTNAMES 0 and 1, and
;;;;     with the vertical-bar flag (EXTNAMES restored after);
;;;;   - CVUNIT: an offset conversion (degC -> degF), incompatible units (nil?),
;;;;     an unknown unit;
;;;;   - GETENV / SETENV: an undefined name vs one set to "", the case of the
;;;;     name; a probe-owned name (ClautolispProbeB8) is used;
;;;;   - GETCFG / SETCFG: an invalid section name, a value longer than 512
;;;;     characters (truncated?), under AppData/ClautolispProbeB8;
;;;;   - MENUCMD on an area the product may not support, MENUGROUP of an
;;;;     unknown group, TABLET with no digitiser (the ERRNO);
;;;;   - STARTAPP of a program that does not exist -- never a real one, so the
;;;;     probe launches nothing.
;;;;
;;;; Each case runs through CAD-PROBE--HF-RUN: ERRNO cleared, the case text
;;;; EVAL'd under VL-CATCH-ALL-APPLY, record (RESULT ERRNO-AFTER) -- RESULT is
;;;; (error MESSAGE) on an error.
;;;;
;;;; Portability (probes/README.org): each case is a STRING (eval (read ...))'d;
;;;; the case name is the exact expression. Parameter names are unique.

(defun cad-probe--hf-run (cad-probe--hf-text / r errno)
  (vl-catch-all-apply 'setvar (list "ERRNO" 0))
  (setq r (vl-catch-all-apply (function (lambda () (eval (read cad-probe--hf-text)))) nil))
  (setq errno (getvar "ERRNO"))
  (list (if (vl-catch-all-error-p r) (list 'error (vl-catch-all-error-message r)) r)
        errno))

(defun cad-probe--hf (cad-probe--hf-case)
  (cad-probe-capture "host-fns" cad-probe--hf-case
    (function (lambda () (vl-prin1-to-string (cad-probe--hf-run cad-probe--hf-case))))))

(defun cad-probe--hf-snvalid-under (cad-probe--hf-ext cad-probe--hf-names / saved r)
  ;; (SNVALID name) for each of NAMES under EXTNAMES = EXT, restored after.
  (setq saved (getvar "EXTNAMES"))
  (vl-catch-all-apply 'setvar (list "EXTNAMES" cad-probe--hf-ext))
  (setq r (mapcar (function (lambda (n)
                              (list n (vl-catch-all-apply 'snvalid (list n)))))
                  cad-probe--hf-names))
  (vl-catch-all-apply 'setvar (list "EXTNAMES" saved))
  r)

(defun cad-probe--hf-cfg-long ( / long r)
  ;; SETCFG of a 600-character value, then GETCFG's length.
  (setq long "")
  (repeat 60 (setq long (strcat long "0123456789")))
  (setq r (vl-catch-all-apply 'setcfg (list "AppData/ClautolispProbeB8/Long" long)))
  (list (if (vl-catch-all-error-p r) 'error (if r (strlen r) r))
        (strlen (cond ((getcfg "AppData/ClautolispProbeB8/Long")) ("")))))

(defun cad-probe-run-host-fns-probes ()
  (cad-probe-note "host-fns" "snvalid"
    "((NAME SNVALID-RESULT) ...) under EXTNAMES 0 and 1")
  (cad-probe--hf "(cad-probe--hf-snvalid-under 0 '(\"ABC\" \"A B\" \"a-b\" \"a$b\" \"a_b\" \"a.b\" \"a|b\" \"a<b\" \"a*b\" \"a?b\" \"a,b\" \"a;b\" \"a'b\" \"\"))")
  (cad-probe--hf "(cad-probe--hf-snvalid-under 1 '(\"ABC\" \"A B\" \"a-b\" \"a$b\" \"a_b\" \"a.b\" \"a|b\" \"a<b\" \"a*b\" \"a?b\" \"a,b\" \"a;b\" \"a'b\" \"\"))")
  (cad-probe--hf "(snvalid (strcat (chr 201) \"T\" (chr 201)))")
  (cad-probe--hf "(snvalid \"a|b\" 0)")
  (cad-probe--hf "(snvalid \"a|b\" 1)")
  (cad-probe--hf "(snvalid (strcat \"A\" (chr 160) \"B\"))")

  (cad-probe-note "host-fns" "cvunit"
    "CVUNIT: an offset conversion, incompatible units, an unknown unit")
  (cad-probe--hf "(cvunit 100.0 \"celsius\" \"fahrenheit\")")
  (cad-probe--hf "(cvunit 0.0 \"celsius\" \"kelvin\")")
  (cad-probe--hf "(cvunit 1.0 \"inch\" \"mm\")")
  (cad-probe--hf "(cvunit 1.0 \"inch\" \"kilogram\")")
  (cad-probe--hf "(cvunit 1.0 \"clautolispnosuchunit\" \"mm\")")
  (cad-probe--hf "(cvunit '(1.0 2.0) \"inch\" \"mm\")")

  (cad-probe-note "host-fns" "env"
    "GETENV of an undefined name, SETENV to \"\" then GETENV, the name's case")
  (cad-probe--hf "(getenv \"ClautolispProbeB8Undefined\")")
  (cad-probe--hf "(setenv \"ClautolispProbeB8\" \"x\")")
  (cad-probe--hf "(getenv \"ClautolispProbeB8\")")
  (cad-probe--hf "(getenv \"CLAUTOLISPPROBEB8\")")
  (cad-probe--hf "(setenv \"ClautolispProbeB8\" \"\")")
  (cad-probe--hf "(getenv \"ClautolispProbeB8\")")
  (cad-probe--hf "(setenv \"ClautolispProbeB8\" nil)")

  (cad-probe-note "host-fns" "cfg"
    "GETCFG / SETCFG: an invalid section, a value of 600 characters")
  (cad-probe--hf "(getcfg \"NoSuchSection/ClautolispProbeB8\")")
  (cad-probe--hf "(setcfg \"NoSuchSection/ClautolispProbeB8\" \"x\")")
  (cad-probe--hf "(setcfg \"AppData/ClautolispProbeB8/Short\" \"v\")")
  (cad-probe--hf "(getcfg \"AppData/ClautolispProbeB8/Short\")")
  (cad-probe--hf "(getcfg \"appdata/ClautolispProbeB8/Short\")")
  (cad-probe--hf "(cad-probe--hf-cfg-long)")

  (cad-probe-note "host-fns" "menus-tablet"
    "MENUCMD on unusual areas, MENUGROUP of an unknown group, TABLET with no digitiser")
  (cad-probe--hf "(menucmd \"M=$(getvar,ACADVER)\")")
  (cad-probe--hf "(menucmd \"T1=*\")")
  (cad-probe--hf "(menucmd \"I=*\")")
  (cad-probe--hf "(menucmd \"Q=nosuch\")")
  (cad-probe--hf "(menugroup \"CLAUTOLISPNOSUCHGROUP\")")
  (cad-probe--hf "(menugroup \"ACAD\")")
  (cad-probe--hf "(tablet 0)")

  (cad-probe-note "host-fns" "startapp"
    "STARTAPP of a program that does not exist (nothing is launched)")
  (cad-probe--hf "(startapp \"clautolisp-no-such-program-b8.exe\")")
  (cad-probe--hf "(startapp \"clautolisp-no-such-program-b8.exe\" \"arg\")")
  (princ))
