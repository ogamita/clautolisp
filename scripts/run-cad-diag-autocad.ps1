# TEMPORARY verification (remove with the debug job): confirm autocad-no-rest-
# output-capture is fixed — 1-arg princ output should now DRAIN as clean ASCII,
# not UTF-16 CJK mojibake (the protocol FILE drain now uses :AUTO, not the
# accoreconsole console's :utf-16le).
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

Write-Host "==== VERIFY -x: top-level 1-arg princ (expect clean VERIFY-A-B / VERIFY-C) ===="
& $alfe -norc --autocad --mode batch --dwg $Dwg --verbose --timeout 120 -x '(progn (princ "VERIFY-A")(princ "-B")(terpri)(princ "VERIFY-C"))' 2>&1 | ForEach-Object { "$_" }
Write-Host "---- exit $LASTEXITCODE ----"

# 1-arg princ INSIDE a loaded defun, then call it.
$probe = Join-Path $out "verify.lsp"
@'
(defun myprobe () (princ "PROBE-LINE-1")(terpri)(princ "PROBE-LINE-2")(terpri))
(myprobe)
(princ "PROBE-TOP")
'@ | Set-Content -Path $probe -Encoding ascii
Write-Host "==== VERIFY -l: 1-arg princ inside a defun (expect clean PROBE-LINE-1/2, PROBE-TOP) ===="
& $alfe -norc --autocad --mode batch --dwg $Dwg --verbose --timeout 120 -l $probe 2>&1 | ForEach-Object { "$_" }
Write-Host "---- exit $LASTEXITCODE ----"
Write-Host "verify done"
exit 0
