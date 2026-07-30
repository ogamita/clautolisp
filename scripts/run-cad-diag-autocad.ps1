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
(defun fsize (p / f n) (setq n -1) (setq f (open p "r")) (if f (progn (setq n 0) (while (read-line f) (setq n (1+ n))) (close f))) n)
;; On AutoCAD 2022 a defun'd function reports (type)=SUBR (not USUBR) -- calibrate:
(defun __tf (a) a)
(dl (strcat "USER-DEFUN-TYPE=" (vl-princ-to-string (type __tf))))
(dl (strcat "PRINC-TYPE=" (vl-princ-to-string (type princ))))
(dl (strcat "NORMALIZE-TYPE=" (vl-princ-to-string (type autolisp-normalize-princ-call))))
(dl (strcat "CAPTURE=" (cond ((not (boundp (quote *AUTOLISP_CAPTURE_STDOUT*))) "UNBOUND") (*AUTOLISP_CAPTURE_STDOUT* "T") (T "NIL"))))
(setq sf (if (boundp (quote *AUTOLISP_PROTOCOL_STDOUTFILE*)) *AUTOLISP_PROTOCOL_STDOUTFILE* "?"))
(dl (strcat "STDOUTFILE=" sf))
(dl (strcat "STDOUT-LINES-BEFORE=" (itoa (fsize sf))))
;; Does an explicit 2-arg (princ x nil) write to the protocol stdout?
(setq r1 (vl-catch-all-apply (quote princ) (list "MARK-2ARG-NILFD" nil)))
(dl (strcat "PRINC-2ARG=" (if (vl-catch-all-error-p r1) (strcat "ERR:" (vl-catch-all-error-message r1)) "OK")))
;; Does emit-user-line write to the protocol stdout?
(setq r2 (vl-catch-all-apply (quote autolisp-emit-user-line) (list "MARK-EMIT")))
(dl (strcat "EMIT-CALL=" (if (vl-catch-all-error-p r2) (strcat "ERR:" (vl-catch-all-error-message r2)) "OK")))
(dl (strcat "STDOUT-LINES-AFTER=" (itoa (fsize sf))))
;; Does the walk-rewriter pad a 1-arg (princ x) when a form is normalized+eval'd?
(setq r3 (vl-catch-all-apply (quote eval) (list (list (quote autolisp-normalize-princ-call) (list (quote quote) (list (quote princ) "MARK-NORMALIZED"))))))
(dl (strcat "NORMALIZE-1ARG=" (if (vl-catch-all-error-p r3) (strcat "ERR:" (vl-catch-all-error-message r3)) (vl-princ-to-string r3))))
;; Dump stdout content so we SEE what landed:
(if (and (/= sf "?") (findfile sf))
  (progn (setq f (open sf "r")) (setq c "") (while (setq l (read-line f)) (setq c (strcat c l "|"))) (close f)
         (dl (strcat "STDOUT-CONTENT=[" c "]")))
  (dl "STDOUT-ABSENT"))
;; debug.log (need --debug for it to be written):
(setq __ld (cond ((boundp (quote *AUTOLISP-LOGDIR*)) *AUTOLISP-LOGDIR*) ((boundp (quote *AUTOLISP_LOGDIR*)) *AUTOLISP_LOGDIR*) (T nil)))
(if __ld (progn (setq __lp (strcat __ld "/debug.log"))
  (if (findfile __lp) (progn (setq __lf (open __lp "r")) (while (setq __l (read-line __lf)) (dl (strcat "  DBG| " __l))) (close __lf)) (dl "  DEBUGLOG-ABSENT"))))
(close __d)
(princ "DIAG3-DONE")
"@ | Set-Content -Path $probe -Encoding ascii

Write-Host "==== run diagnostic probe on AutoCAD ===="
& $alfe -norc --autocad --mode batch --dwg $Dwg --debug --verbose --timeout 120 -l $probe 2>&1 | ForEach-Object { "$_" }
Write-Host "---- exit $LASTEXITCODE ----"
Write-Host "==== DIAG FILE CONTENT ===="
if (Test-Path $diag) { Get-Content $diag } else { Write-Host "(diag file not written: $diag)" }
Copy-Item -Force $diag (Join-Path $out "diag-out.txt") -ErrorAction SilentlyContinue
exit 0
