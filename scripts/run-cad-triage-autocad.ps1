# TEMPORARY triage (remove with the debug job): does autocad-no-rest-output-
# capture still reproduce at HEAD on real AutoCAD (accoreconsole, no &rest)? The
# probe prints ONLY via 1-arg (princ (strcat ...)); on the no-&rest path that
# output was lost (all sinks empty) while BricsCAD's &rest path is fine. Run a
# tiny 1-arg-princ probe via -l and -x and show whether the markers appear.
param([string]$Dwg = "c:/gitlab-runner/dwg/empty.dwg")
$ErrorActionPreference = "Continue"
$root = if ($env:CI_PROJECT_DIR) { $env:CI_PROJECT_DIR } else { (Get-Location).Path }
$out  = Join-Path $root "dist/cad-triage-autocad"
New-Item -ItemType Directory -Force -Path $out | Out-Null

# PowerShell needs a .exe to run the extension-less PE in a pipeline.
$alfe = Join-Path $root "autolisp-front-end/tools/alfe/bin/alfe-sbcl"
if (Test-Path "$alfe.exe") { $alfe = "$alfe.exe" }
elseif (Test-Path $alfe) { Copy-Item -Force $alfe "$alfe.exe"; $alfe = "$alfe.exe" }
else { Write-Error "alfe not built at $alfe"; exit 2 }
$env:ALFE_RUNTIME_LSP   = Join-Path $root "autolisp-front-end/source/runtime/autolisp-remote-io.lsp"
$env:ALFE_BOOTSTRAP_LSP = Join-Path $root "autolisp-front-end/source/runtime/autolisp-bootstrap.lsp"

# A probe that prints ONLY through 1-arg princ (the no-&rest-sensitive path).
$probe = Join-Path $out "no-rest-probe.lsp"
@'
(princ "TRIAGE-OUT-A")
(princ (strcat "TRIAGE-OUT-B" "-" "C"))
(princ (strcat "\nTRIAGE-DONE " (itoa (+ 40 2))))
'@ | Set-Content -Path $probe -Encoding ascii

Write-Host "==== TRIAGE autocad no-rest output (-l, 1-arg princ) ===="
& $alfe -norc --autocad --mode batch --dwg $Dwg --verbose --timeout 120 -l $probe 2>&1 | ForEach-Object { "$_" }
Write-Host "---- exit $LASTEXITCODE ----"

Write-Host "==== TRIAGE autocad no-rest output (-x, 1-arg princ) ===="
& $alfe -norc --autocad --mode batch --dwg $Dwg --verbose --timeout 120 -x '(progn (princ "TRIAGE-X-A")(princ "TRIAGE-X-B"))' 2>&1 | ForEach-Object { "$_" }
Write-Host "---- exit $LASTEXITCODE ----"
Write-Host "triage-autocad done"
exit 0
