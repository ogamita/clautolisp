;;;; probes/sources/probe-sysvars.lsp
;;;;
;;;; Capture the host's default value (and read-only-ness) for the
;;;; system variables clautolisp couples behaviour to. Run on a freshly
;;;; launched CAD with a new drawing so the values are the dialect /
;;;; product defaults, not values a session has mutated.
;;;;
;;;; Drives the system-variables work (issues/open/system-variables.issue)
;;;; and the SECURELOAD trust model
;;;; (documentation/clautolisp-secureload-trust-model-spec.org).

(defun cad-probe-run-sysvar-probes ( / names)
  (setq names
    (list
      ;; --- trust model ---
      "SECURELOAD" "TRUSTEDPATHS"
      ;; --- linear units / rtos coupling ---
      "LUNITS" "LUPREC" "DIMZIN" "UNITMODE" "MEASUREMENT"
      ;; --- angular units / angtos coupling ---
      "AUNITS" "AUPREC" "ANGBASE" "ANGDIR"
      ;; --- echo / command context ---
      "CMDECHO" "MAXSORT"
      ;; --- identity / paths (cross-check mock-host getvar) ---
      "PROGRAM" "PRODUCT" "ACADVER" "PLATFORM" "LOCALE"
      "DWGNAME" "DWGPREFIX"))
  (foreach n names
    (cad-probe-sysvar "sysvar" n))
  (princ))
