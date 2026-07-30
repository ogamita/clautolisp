# TEMPORARY CAD smoke / diagnostic harness (Windows twin of run-cad-smoke.sh) —
# cad-runtime bug-cluster debugging. Runs a handful of alfe evaluations against
# a selected CAD backend on a real Windows runner and prints labelled results:
#   * confirm a backend/mode LAUNCHES (esp. the new --cad acad --mode batch,
#     real AutoCAD GUI batch vs only accoreconsole), and
#   * see real-CAD behaviour of the cluster bugs (princ/prin1 newlines,
#     (load VAR) evaluation, large single-form load).
# Remove this and the debug:cad:* jobs once the CAD-runtime cluster work lands.
#
# Usage: run-cad-smoke.ps1 -Cad DENOT [-Mode batch|auto|automation] [-Dwg FILE]
param(
  [Parameter(Mandatory=$true)][string]$Cad,
  [string]$Mode = "batch",
  [string]$Dwg = ""
)
$ErrorActionPreference = "Continue"

$root = if ($env:CI_PROJECT_DIR) { $env:CI_PROJECT_DIR } else { (Get-Location).Path }
$alfe = Join-Path $root "autolisp-front-end/tools/alfe/bin/alfe-sbcl.exe"
if (-not (Test-Path $alfe)) {
  # Some runners build without the .exe suffix on the wrapper; fall back.
  $alt = Join-Path $root "autolisp-front-end/tools/alfe/bin/alfe-sbcl"
  if (Test-Path $alt) { $alfe = $alt }
}
$outDir = Join-Path $root ("dist/cad-debug/{0}-Windows" -f $Cad)
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

if (-not (Test-Path $alfe)) {
  Write-Error "alfe binary not found at $alfe (build: make -C autolisp-front-end build-alfe-sbcl)"
  exit 2
}

$rtLsp = Join-Path $root "autolisp-front-end/source/runtime/autolisp-remote-io.lsp"
$bsLsp = Join-Path $root "autolisp-front-end/source/runtime/autolisp-bootstrap.lsp"
if (Test-Path $rtLsp) { $env:ALFE_RUNTIME_LSP  = $rtLsp } else { Write-Host "WARN: no runtime lsp at $rtLsp" }
if (Test-Path $bsLsp) { $env:ALFE_BOOTSTRAP_LSP = $bsLsp } else { Write-Host "WARN: no bootstrap lsp at $bsLsp" }

$dwgArgs = @()
if ($Dwg -ne "") { $dwgArgs = @("--dwg", $Dwg) }

Write-Host "############################################################"
Write-Host "# CAD smoke: --cad $Cad --mode $Mode  (host Windows)"
Write-Host "# alfe: $alfe"
Write-Host "# dwg:  $(if ($Dwg) { $Dwg } else { '<none>' })"
Write-Host "############################################################"

# 0) Discovery — what CAD installs does alfe see on this runner? (no launch)
Write-Host "==== SMOKE discover (--list-cad-programs) ===="
& $alfe --list-cad-programs 2>&1 | Tee-Object -FilePath (Join-Path $outDir "00-discover.log")
Write-Host ""

function Smoke {
  param([string]$Label, [string[]]$AlfeArgs)
  Write-Host "==== SMOKE $Label  (--cad $Cad --mode $Mode) ===="
  $args = @("-norc","--cad",$Cad,"--mode",$Mode) + $dwgArgs + @("--verbose","--timeout","120") + $AlfeArgs
  & $alfe @args 2>&1 | Tee-Object -FilePath (Join-Path $outDir "$Label.log")
  Write-Host "---- $Label exit: $LASTEXITCODE ----"
  Write-Host ""
}

# 1) Launch + evaluate at all?
Smoke -Label "launch" -AlfeArgs @("-x",'(princ "SMOKE-LAUNCH-OK")')

# 2) princ/prin1 trailing-newline bug — correct output is "1 ABC" on one line.
Smoke -Label "princ-prin1" -AlfeArgs @("-x",'(progn (prin1 1) (princ " ") (prin1 (quote abc)) (terpri) (princ "END"))')

# 3) (load VAR) argument-evaluation bug.
$loadme = Join-Path $outDir "loadme.lsp"
Set-Content -Path $loadme -Value '(princ "LOADED-FROM-FILE-OK")' -Encoding ascii
$loadmeLisp = $loadme -replace '\\','/'
Smoke -Label "load-form" -AlfeArgs @("-x","(progn (setq p `"$loadmeLisp`") (load p) (princ `" AFTER-LOAD`"))")

Write-Host "############################################################"
Write-Host "# CAD smoke done: --cad $Cad --mode $Mode ; logs under $outDir"
Write-Host "############################################################"
# Diagnostic harness: always succeed so an offline/misbehaving CAD never reddens
# the (allow_failure) debug pipeline.
exit 0
