;;;; probes/sources/probe-setvar-edges.lsp
;;;;
;;;; windows-runner-sunset-probe-campaign, batch B4 (AC-crit). The ch.16
;;;; SETVAR / GETVAR edges, whose AutoCAD answer is lost with the Windows
;;;; runner:
;;;;
;;;;   - the integer-range rule the spec contradicts itself on: does an
;;;;     out-of-range value CLAMP to [-32768, 32767] (or to the variable's own
;;;;     range), WRAP, or SIGNAL (with which ERRNO)?
;;;;   - type coercion: a real into an integer variable (CMDECHO 1.0), an
;;;;     integer into a real one, a string into an integer one, nil;
;;;;   - an unknown name, a read-only name: the error, the ERRNO;
;;;;   - the name's case: (setvar "osmode" ...);
;;;;   - ANGBASE / SNAPANG are radians whatever AUNITS says.
;;;;
;;;; Every case goes through CAD-PROBE--SV, which saves the variable, clears
;;;; ERRNO, tries the SETVAR under VL-CATCH-ALL-APPLY, reads it back, then
;;;; RESTORES the saved value -- a probe must leave the CAD as it found it.
;;;; Its record: (SETVAR-RESULT-or-(error MESSAGE) VALUE-AFTER ERRNO-AFTER).
;;;;
;;;; Portability (probes/README.org): each case is a STRING (eval (read ...))'d.
;;;; The case name is the exact expression.

(defun cad-probe--sve (case-text)
  (cad-probe-capture "setvar-edges" case-text
    (function (lambda () (vl-prin1-to-string (eval (read case-text)))))))

(defun cad-probe--sv (cad-probe--sv-name cad-probe--sv-value / old r after errno)
  (setq old (getvar cad-probe--sv-name))
  (vl-catch-all-apply 'setvar (list "ERRNO" 0))
  (setq r (vl-catch-all-apply 'setvar (list cad-probe--sv-name cad-probe--sv-value)))
  (setq after (getvar cad-probe--sv-name))
  (setq errno (getvar "ERRNO"))
  ;; restore what was there (a value that was nil -- an unknown name -- has
  ;; nothing to restore)
  (if old (vl-catch-all-apply 'setvar (list cad-probe--sv-name old)))
  (list (if (vl-catch-all-error-p r) (list 'error (vl-catch-all-error-message r)) r)
        after errno))

(defun cad-probe--sv-under (cad-probe--sv-units cad-probe--sv-name2 cad-probe--sv-value2
                            / saved r)
  ;; CAD-PROBE--SV with AUNITS set to UNITS meanwhile (restored after)
  (setq saved (getvar "AUNITS"))
  (vl-catch-all-apply 'setvar (list "AUNITS" cad-probe--sv-units))
  (setq r (cad-probe--sv cad-probe--sv-name2 cad-probe--sv-value2))
  (vl-catch-all-apply 'setvar (list "AUNITS" saved))
  r)

(defun cad-probe-run-setvar-edges-probes ()
  ;; --- integer range: clamp / wrap / signal? -------------------------------
  (cad-probe-note "setvar-edges" "integer-range"
    "(RESULT AFTER ERRNO) for out-of-range integers: clamp to the 16-bit range, wrap, or signal?")
  (cad-probe--sve "(cad-probe--sv \"OSMODE\" 70000)")
  (cad-probe--sve "(cad-probe--sv \"OSMODE\" 32767)")
  (cad-probe--sve "(cad-probe--sv \"OSMODE\" 32768)")
  (cad-probe--sve "(cad-probe--sv \"OSMODE\" 65535)")
  (cad-probe--sve "(cad-probe--sv \"OSMODE\" -1)")
  (cad-probe--sve "(cad-probe--sv \"OSMODE\" -40000)")
  (cad-probe--sve "(cad-probe--sv \"CMDECHO\" 2)")
  (cad-probe--sve "(cad-probe--sv \"LUNITS\" 7)")
  (cad-probe--sve "(cad-probe--sv \"LUPREC\" 9)")
  (cad-probe--sve "(cad-probe--sv \"USERI1\" 40000)")

  ;; --- type coercion ---------------------------------------------------------
  (cad-probe-note "setvar-edges" "type-coercion"
    "a real into an integer variable, an integer into a real one, a string / nil / a point where a number goes")
  (cad-probe--sve "(cad-probe--sv \"CMDECHO\" 1.0)")
  (cad-probe--sve "(cad-probe--sv \"CMDECHO\" 0.7)")
  (cad-probe--sve "(cad-probe--sv \"OSMODE\" 3.0)")
  (cad-probe--sve "(cad-probe--sv \"CMDECHO\" \"1\")")
  (cad-probe--sve "(cad-probe--sv \"CMDECHO\" nil)")
  (cad-probe--sve "(cad-probe--sv \"USERR1\" 2)")
  (cad-probe--sve "(cad-probe--sv \"USERR1\" \"2.5\")")
  (cad-probe--sve "(cad-probe--sv \"USERS1\" 5)")
  (cad-probe--sve "(cad-probe--sv \"CLAYER\" 0)")
  (cad-probe--sve "(cad-probe--sv \"VIEWCTR\" '(1.0 2.0))")
  (cad-probe--sve "(cad-probe--sv \"SNAPBASE\" '(1.0 2.0 3.0))")
  (cad-probe--sve "(cad-probe--sv \"SNAPBASE\" 5.0)")

  ;; --- unknown, read-only, case of the name -----------------------------------
  (cad-probe-note "setvar-edges" "names"
    "an unknown name, a read-only one, a lower-case name: the error and ERRNO")
  (cad-probe--sve "(cad-probe--sv \"NOSUCHVAR\" 1)")
  (cad-probe--sve "(list (getvar \"NOSUCHVAR\") (getvar \"ERRNO\"))")
  (cad-probe--sve "(cad-probe--sv \"DWGNAME\" \"x.dwg\")")
  (cad-probe--sve "(cad-probe--sv \"ACADVER\" \"1\")")
  (cad-probe--sve "(cad-probe--sv \"DATE\" 1.0)")
  (cad-probe--sve "(cad-probe--sv \"osmode\" 1)")
  (cad-probe--sve "(cad-probe--sv \"OsMode\" 2)")
  (cad-probe--sve "(vl-catch-all-error-message (vl-catch-all-apply 'setvar (list 'OSMODE 1)))")

  ;; --- angles are radians whatever AUNITS says --------------------------------
  (cad-probe-note "setvar-edges" "angle-units"
    "ANGBASE / SNAPANG set to 1.5708 under AUNITS 0 (degrees) and 3 (radians): read back in radians?")
  (cad-probe--sve "(cad-probe--sv-under 0 \"ANGBASE\" 1.5708)")
  (cad-probe--sve "(cad-probe--sv-under 3 \"ANGBASE\" 1.5708)")
  (cad-probe--sve "(cad-probe--sv-under 0 \"SNAPANG\" 1.5708)")
  (cad-probe--sve "(cad-probe--sv-under 0 \"ANGBASE\" 90)")
  (cad-probe--sve "(cad-probe--sv-under 0 \"ANGBASE\" 7.0)")
  (princ))
