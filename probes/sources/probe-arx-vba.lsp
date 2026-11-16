;;;; probes/sources/probe-arx-vba.lsp
;;;;
;;;; windows-runner-sunset-probe-campaign, batch B7 (AC-crit). ARX and VBA:
;;;; there is no BricsCAD analogue to fall back on, so AutoCAD-on-Windows is the
;;;; only witness, and it goes with the runner:
;;;;
;;;;   - (arx): the fresh session's module list;
;;;;   - ARXLOAD of a missing file, with and without ONFAILURE (a symbol, a
;;;;     string): error, return value, ERRNO;
;;;;   - ARXLOAD of a module already loaded (the double-load case);
;;;;   - ARXUNLOAD of a module that is not loaded, with and without ONFAILURE;
;;;;     ARXUNLOAD of a loaded module -- ONLY with ONFAILURE, and reloaded at
;;;;     once if it did unload, so the rest of the run keeps its environment;
;;;;   - VL-VBALOAD of a missing project, VL-VBARUN of a missing macro;
;;;;   - which of these functions exist at all (BricsCAD records its answer).
;;;;
;;;; Each case runs through CAD-PROBE--AV-RUN: ERRNO cleared, the case text
;;;; EVAL'd under VL-CATCH-ALL-APPLY, record (RESULT ERRNO-AFTER) -- RESULT is
;;;; (error MESSAGE) on an error.
;;;;
;;;; Portability (probes/README.org): each case is a STRING (eval (read ...))'d;
;;;; the case name is the exact expression. Parameter names are unique.

(defun cad-probe--av-run (cad-probe--av-text / r errno)
  (vl-catch-all-apply 'setvar (list "ERRNO" 0))
  (setq r (vl-catch-all-apply (function (lambda () (eval (read cad-probe--av-text)))) nil))
  (setq errno (getvar "ERRNO"))
  (list (if (vl-catch-all-error-p r) (list 'error (vl-catch-all-error-message r)) r)
        errno))

(defun cad-probe--av (cad-probe--av-case)
  (cad-probe-capture "arx-vba" cad-probe--av-case
    (function (lambda () (vl-prin1-to-string (cad-probe--av-run cad-probe--av-case))))))

(defun cad-probe--av-first-module ( / l)
  ;; The first module (arx) lists, or nil.
  (setq l (vl-catch-all-apply 'arx nil))
  (if (and (listp l) l) (car l)))

(defun cad-probe--av-unload-reload (cad-probe--av-module / r back)
  ;; ARXUNLOAD MODULE with ONFAILURE; reload it at once if it did unload.
  (if (null cad-probe--av-module)
      'no-module
      (progn
        (setq r (vl-catch-all-apply 'arxunload (list cad-probe--av-module 'cad-probe-av-refused)))
        (if (and (not (vl-catch-all-error-p r)) (/= r 'cad-probe-av-refused))
            (setq back (vl-catch-all-apply 'arxload (list cad-probe--av-module))))
        (list (if (vl-catch-all-error-p r) (list 'error (vl-catch-all-error-message r)) r)
              (if back (if (vl-catch-all-error-p back) 'reload-failed 'reloaded) 'not-unloaded)))))

(defun cad-probe-run-arx-vba-probes ()
  (cad-probe-note "arx-vba" "functions"
    "TYPE of the ARX / VBA functions: which exist on this product")
  (cad-probe--av "(list (type arx) (type arxload) (type arxunload) (type autoarxload))")
  (cad-probe--av "(list (type vl-vbaload) (type vl-vbarun) (type vla-get-vbe))")

  (cad-probe-note "arx-vba" "module-list"
    "(arx) in a fresh batch session, and how many")
  (cad-probe--av "(arx)")
  (cad-probe--av "(length (arx))")

  (cad-probe-note "arx-vba" "arxload"
    "ARXLOAD of a missing file, with ONFAILURE as a symbol and as a string; of a module already loaded")
  (cad-probe--av "(arxload \"clautolisp-no-such-module.arx\")")
  (cad-probe--av "(arxload \"clautolisp-no-such-module.arx\" 'cad-probe-av-failed)")
  (cad-probe--av "(arxload \"clautolisp-no-such-module.arx\" \"failed\")")
  (cad-probe--av "(arxload \"\")")
  (cad-probe--av "(if (cad-probe--av-first-module) (arxload (cad-probe--av-first-module)) 'no-module)")
  (cad-probe--av "(if (cad-probe--av-first-module) (arxload (cad-probe--av-first-module) 'cad-probe-av-failed) 'no-module)")

  (cad-probe-note "arx-vba" "arxunload"
    "ARXUNLOAD of a module not loaded (with / without ONFAILURE); of a loaded one (ONFAILURE only, reloaded at once)")
  (cad-probe--av "(arxunload \"clautolisp-no-such-module.arx\")")
  (cad-probe--av "(arxunload \"clautolisp-no-such-module.arx\" 'cad-probe-av-failed)")
  (cad-probe--av "(cad-probe--av-unload-reload (cad-probe--av-first-module))")

  (cad-probe-note "arx-vba" "vba"
    "VL-VBALOAD of a missing project; VL-VBARUN of a missing macro and of an empty name")
  (cad-probe--av "(vl-vbaload \"clautolisp-no-such-project.dvb\")")
  (cad-probe--av "(vl-vbarun \"ClautolispNoSuchMacro\")")
  (cad-probe--av "(vl-vbarun \"\")")
  (princ))
