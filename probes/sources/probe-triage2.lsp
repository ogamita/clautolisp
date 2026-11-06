;;;; probes/sources/probe-triage2.lsp
;;;;
;;;; Triage round 2026-10-04 (pjb: "Go ahead and do 1 to 6"):
;;;;   com-app  -- the COM application / document properties EPUREE calls
;;;;               (com-application-object-properties): Layouts + Item by
;;;;               name, Document.Active, Preferences.Files.SupportPath,
;;;;               Preferences.Profiles.ActiveProfile;
;;;;   regtype  -- what VL-REGISTRY-READ returns for a REG_DWORD, a
;;;;               REG_MULTI_SZ, a REG_EXPAND_SZ and a REG_BINARY (Windows
;;;;               only: standard values every Windows install has);
;;;;   version  -- the dialect-platform-version-axis remainder: LISPSYS and
;;;;               the Unicode behaviour of ASCII / CHR / STRLEN /
;;;;               VL-STRING->LIST (strings built with CHR, never source
;;;;               literals, whose decoding is the very question), OSNAP's
;;;;               "qui" mode, VL-CMDF's value, OPEN's encoding argument.
;;;; Every step runs under VL-CATCH-ALL-APPLY: an unsupported call records
;;;; an error and never stops the run. Values are VL-PRIN1-TO-STRING'd.

(defun cad-probe--t2-show (cad-probe--t2-thunk / r)
  (setq r (vl-catch-all-apply cad-probe--t2-thunk '()))
  (if (vl-catch-all-error-p r)
      (strcat "ERROR " (vl-catch-all-error-message r))
      (vl-prin1-to-string r)))

;; Distinct parameter names: AutoLISP binds dynamically, so a wrapper's free
;; THUNK resolved to CAD-PROBE--T2-SHOW's own THUNK -- the wrapper itself --
;; and recursed forever (caught on clautolisp, 2026-10-04).
(defun cad-probe--t2 (suite name cad-probe--t2-fn)
  (cad-probe-capture suite name
    (function (lambda () (cad-probe--t2-show cad-probe--t2-fn)))))

(defun cad-probe-run-triage2-probes ( / acad doc layouts names path f)
  (vl-catch-all-apply 'vl-load-com '())
  ;; --- com-app ---------------------------------------------------------
  (cad-probe--t2 "com-app" "type of (vlax-get-acad-object)"
    (function (lambda () (type (vlax-get-acad-object)))))
  (setq acad (vl-catch-all-apply 'vlax-get-acad-object '()))
  (setq doc (if (vl-catch-all-error-p acad) nil
                (vl-catch-all-apply 'vla-get-activedocument (list acad))))
  (if (vl-catch-all-error-p doc) (setq doc nil))
  (cad-probe--t2 "com-app" "Layouts count"
    (function (lambda () (vla-get-count (vla-get-layouts doc)))))
  (cad-probe--t2 "com-app" "Layouts names"
    (function (lambda ( / out)
                (vlax-for l (vla-get-layouts doc) (setq out (cons (vla-get-name l) out)))
                (reverse out))))
  (cad-probe--t2 "com-app" "Layouts Item \"Model\" name"
    (function (lambda () (vla-get-name (vla-item (vla-get-layouts doc) "Model")))))
  (cad-probe--t2 "com-app" "Layouts Item \"NoSuchLayout\""
    (function (lambda () (vla-item (vla-get-layouts doc) "NoSuchLayout"))))
  (cad-probe--t2 "com-app" "Document Active"
    (function (lambda () (vla-get-active doc))))
  (cad-probe--t2 "com-app" "Preferences Files SupportPath: type"
    (function (lambda () (type (vla-get-supportpath (vla-get-files (vla-get-preferences acad)))))))
  (cad-probe--t2 "com-app" "Preferences Files SupportPath: = (getenv \"ACAD\")"
    (function (lambda ()
                (= (vla-get-supportpath (vla-get-files (vla-get-preferences acad)))
                   (getenv "ACAD")))))
  (cad-probe--t2 "com-app" "Preferences Profiles ActiveProfile: type"
    (function (lambda () (type (vla-get-activeprofile (vla-get-profiles (vla-get-preferences acad)))))))
  ;; --- regtype (Windows only) --------------------------------------------
  (foreach spec '(("REG_DWORD" "HKEY_CURRENT_USER\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced" "HideFileExt")
                  ("REG_MULTI_SZ" "HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Control\\ServiceGroupOrder" "List")
                  ("REG_EXPAND_SZ" "HKEY_CURRENT_USER\\Environment" "TEMP")
                  ("REG_BINARY" "HKEY_CURRENT_USER\\Control Panel\\Desktop" "UserPreferencesMask")
                  ;; Raw value "%SystemRoot%\TEMP" on every Windows: expanded or not?
                  ("REG_EXPAND_SZ %SystemRoot%" "HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Environment" "TEMP")
                  ;; 8 bytes (a FILETIME): AutoCAD's UserPreferencesMask read back as (3) only.
                  ("REG_BINARY ShutdownTime" "HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Control\\Windows" "ShutdownTime")
                  ;; A nonzero REG_DWORD (1 on a default install).
                  ("REG_DWORD ProtectionMode" "HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Control\\Session Manager" "ProtectionMode"))
    (cad-probe--t2 "regtype" (strcat "vl-registry-read " (car spec))
      (function (lambda ( / v)
                  (if (getenv "WINDIR")
                      (progn
                        (setq v (vl-registry-read (cadr spec) (caddr spec)))
                        (list (type v) v))
                      "SKIPPED-OFF-WINDOWS")))))
  (cad-probe--t2 "regtype" "(getenv \"SystemRoot\")"
    (function (lambda () (getenv "SystemRoot"))))
  (cad-probe--t2 "regtype" "(getenv \"USERPROFILE\")"
    (function (lambda () (getenv "USERPROFILE"))))
  ;; --- version ----------------------------------------------------------
  (cad-probe--t2 "version" "getvar LISPSYS"
    (function (lambda () (getvar "LISPSYS"))))
  (cad-probe--t2 "version" "(ascii (chr 128))"
    (function (lambda () (ascii (chr 128)))))
  (cad-probe--t2 "version" "(ascii (chr 8364))"
    (function (lambda () (ascii (chr 8364)))))
  (cad-probe--t2 "version" "(strlen (chr 8364))"
    (function (lambda () (strlen (chr 8364)))))
  (cad-probe--t2 "version" "(vl-string->list (strcat \"1\" (chr 128)))"
    (function (lambda () (vl-string->list (strcat "1" (chr 128))))))
  (cad-probe--t2 "version" "(vl-string->list (chr 8364))"
    (function (lambda () (vl-string->list (chr 8364)))))
  ;; Never (vl-catch-all-apply 'command ...): AutoCAD 2022 refuses COMMAND
  ;; through APPLY ("fonction d'ordre incorrecte: COMMAND", uncaught) and the
  ;; whole run stopped there (job 16923765011). A lambda calling it is fine.
  (vl-catch-all-apply (function (lambda () (command "_.LINE" "0,0" "10,0" ""))) '())
  (cad-probe--t2 "version" "(osnap '(10 0 0) \"_end\")"
    (function (lambda () (osnap '(10.0 0.0 0.0) "_end"))))
  (cad-probe--t2 "version" "(osnap '(10 0 0) \"_qui,_end\")"
    (function (lambda () (osnap '(10.0 0.0 0.0) "_qui,_end"))))
  (cad-probe--t2 "version" "(vl-cmdf \"_.LINE\" \"0,0\" \"1,1\" \"\")"
    (function (lambda () (vl-cmdf "_.LINE" "0,0" "1,1" ""))))
  (setq path (strcat (getvar "TEMPPREFIX") "cad-probe-open-utf8.txt"))
  (cad-probe--t2 "version" "(open f \"w\" \"utf8\")"
    (function (lambda ( / h)
                (setq h (open path "w" "utf8"))
                (if h (progn (close h) "FILE") h))))
  (princ))
