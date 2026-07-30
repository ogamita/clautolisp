# TEMPORARY diagnostic (remove with the debug job): understand WHY 1-arg princ
# output vanishes on AutoCAD (no-&rest). Report findings through a USER FILE via
# 2-arg (princ x fd) — fixed arity, which works on AutoCAD 2022 — so we get data
# even though the normal output channel is broken.
param([string]$Dwg = "c:/gitlab-runner/dwg/empty.dwg")
$ErrorActionPreference = "Continue"
$root = if ($env:CI_PROJECT_DIR) { $env:CI_PROJECT_DIR } else { (Get-Location).Path }
$out  = Join-Path $root "dist/cad-diag-autocad"
New-Item -ItemType Directory -Force -Path $out | Out-Null
$alfe = Join-Path $root "autolisp-front-end/tools/alfe/bin/alfe-sbcl"
if (Test-Path "$alfe.exe") { $alfe = "$alfe.exe" }
elseif (Test-Path $alfe) { Copy-Item -Force $alfe "$alfe.exe"; $alfe = "$alfe.exe" }
else { Write-Error "alfe not built"; exit 2 }
$env:ALFE_RUNTIME_LSP   = Join-Path $root "autolisp-front-end/source/runtime/autolisp-remote-io.lsp"
$env:ALFE_BOOTSTRAP_LSP = Join-Path $root "autolisp-front-end/source/runtime/autolisp-bootstrap.lsp"

# Diagnostic writes here (a path the shell also knows). Forward slashes for AutoLISP.
$diag = "C:/msys64/tmp/alfe-ac-diag.txt"
$diagLisp = $diag
Remove-Item -Force $diag -ErrorAction SilentlyContinue

$probe = Join-Path $out "diag.lsp"
@"
(setq __d (open "$diagLisp" "w"))
(defun dl (s) (princ s __d) (princ "\n" __d))
(dl (strcat "RUNTIME-EMIT-DEF=" (if (member (quote autolisp-emit-user-line) (atoms-family 1)) "yes" "no")))
(dl (strcat "NORMALIZE-DEF=" (if (member (quote autolisp-normalize-princ-call) (atoms-family 1)) "yes" "no")))
(dl (strcat "PRINC-IS-SUBR=" (if (= (type princ) (quote SUBR)) "native-subr" "shadowed-usubr")))
(dl (strcat "CAPTURE=" (cond ((not (boundp (quote *AUTOLISP_CAPTURE_STDOUT*))) "UNBOUND") (*AUTOLISP_CAPTURE_STDOUT* "T") (T "NIL"))))
(dl (strcat "STDOUTFILE=" (if (boundp (quote *AUTOLISP_PROTOCOL_STDOUTFILE*)) *AUTOLISP_PROTOCOL_STDOUTFILE* "UNBOUND")))
(setq __r (vl-catch-all-apply (quote autolisp-emit-user-line) (list "DIAG-EMIT-MARKER")))
(dl (strcat "EMIT-CALL=" (if (vl-catch-all-error-p __r) (strcat "ERR:" (vl-catch-all-error-message __r)) "OK")))
(setq __p2 (vl-catch-all-apply (quote princ) (list "DIAG-P2-MARKER" nil)))
(dl (strcat "PRINC-2ARG-NILFD=" (if (vl-catch-all-error-p __p2) (strcat "ERR:" (vl-catch-all-error-message __p2)) "OK")))
(dl (strcat "SOURCE-LOAD-TYPE=" (vl-princ-to-string (type autolisp-source-load))))
(dl (strcat "PROTOCOL-WRITE-TYPE=" (vl-princ-to-string (type autolisp-protocol-write-line))))
(dl (strcat "DEBUG-LOG-TYPE=" (vl-princ-to-string (type alfe-debug-log))))
(dl (strcat "EMIT-LINE-TYPE=" (vl-princ-to-string (type autolisp-emit-user-line))))
(dl (strcat "NORMALIZE-TYPE=" (vl-princ-to-string (type autolisp-normalize-princ-call))))
(dl (strcat "BOOTSTRAP-LSP-VAR=" (if (boundp (quote *AUTOLISP_BOOTSTRAP_LSP*)) *AUTOLISP_BOOTSTRAP_LSP* "UNBOUND")))
;; Dump the CAD-side debug.log — it records the startup load sequence + errors.
(setq __ld (cond ((boundp (quote *AUTOLISP-LOGDIR*)) *AUTOLISP-LOGDIR*)
                 ((boundp (quote *AUTOLISP_LOGDIR*)) *AUTOLISP_LOGDIR*) (T nil)))
(dl (strcat "LOGDIR=" (if __ld __ld "UNBOUND")))
(if __ld
  (progn
    (setq __lp (strcat __ld "/debug.log"))
    (if (findfile __lp)
      (progn (setq __lf (open __lp "r"))
             (while (setq __l (read-line __lf)) (dl (strcat "  DBG| " __l))) (close __lf))
      (dl "  DEBUGLOG-ABSENT"))))
(close __d)
(princ "DIAG-DONE-VIA-1ARG")
"@ | Set-Content -Path $probe -Encoding ascii

Write-Host "==== run diagnostic probe on AutoCAD ===="
& $alfe -norc --autocad --mode batch --dwg $Dwg --verbose --timeout 120 -l $probe 2>&1 | ForEach-Object { "$_" }
Write-Host "---- exit $LASTEXITCODE ----"
Write-Host "==== DIAG FILE CONTENT ===="
if (Test-Path $diag) { Get-Content $diag } else { Write-Host "(diag file not written: $diag)" }
Copy-Item -Force $diag (Join-Path $out "diag-out.txt") -ErrorAction SilentlyContinue
exit 0
