<#
  run-pathname-probe.ps1 — Windows twin of run-pathname-probe.sh. Drives
  pathname-probe.lsp against a CAD backend to confirm how "." / ".." path
  segments resolve (cad-path-dotdot-resolution.issue).

    scripts/run-pathname-probe.ps1 -Backend {clautolisp|bricscad|autocad} [-Dwg FILE]

  Output: dist/pathname/<backend>-Windows.txt — the PATHPROBE lines.
#>
param(
  [ValidateSet("clautolisp","bricscad","autocad")]
  [string]$Backend = "clautolisp",
  [string]$Dwg = ""
)
$ErrorActionPreference = "Continue"

$root = if ($env:CI_PROJECT_DIR) { $env:CI_PROJECT_DIR } else { (Get-Location).Path }
$alfe = if ($env:ALFE_BIN) { $env:ALFE_BIN } else { Join-Path $root "autolisp-front-end/tools/alfe/bin/alfe-sbcl" }

# PowerShell's & only runs files whose extension is in $PATHEXT.
#
# Since 2026-08-16 the Windows build PRODUCES alfe-sbcl.exe (pjb: "on
# MS-Windows, we should generate all the executables with .exe extension"),
# so the first branch takes it and the Copy-Item below no longer fires. The
# copy is kept for a binary built before that change, or by a hand-run
# save-lisp-and-die; it duplicates a large image, so finding the .exe first
# is not merely tidier.
#
# The -like guard matters: ALFE_BIN may already name the .exe, and without
# it this would look for alfe-sbcl.exe.exe, miss, and copy the image onto
# that absurd name rather than just running it.
if ($alfe -like '*.exe') {
  if (-not (Test-Path $alfe)) {
    Write-Host "alfe binary not found at $alfe (build it: make -C autolisp-front-end build-alfe-sbcl)"
    exit 2
  }
} elseif (Test-Path "$alfe.exe") {
  $alfe = "$alfe.exe"
} elseif (Test-Path $alfe) {
  Copy-Item -Force $alfe "$alfe.exe"
  $alfe = "$alfe.exe"
} else {
  Write-Host "alfe binary not found at $alfe (build it: make -C autolisp-front-end build-alfe-sbcl)"
  exit 2
}

$probe = Join-Path $root "autolisp-front-end/tests/scenarios/entities/pathname-probe.lsp"
if (-not $env:ALFE_RUNTIME_LSP)   { $env:ALFE_RUNTIME_LSP   = (Join-Path $root "autolisp-front-end/source/runtime/autolisp-remote-io.lsp") -replace '\\','/' }
if (-not $env:ALFE_BOOTSTRAP_LSP) { $env:ALFE_BOOTSTRAP_LSP = (Join-Path $root "autolisp-front-end/source/runtime/autolisp-bootstrap.lsp") -replace '\\','/' }

$outDir = Join-Path $root "dist/pathname"
New-Item -ItemType Directory -Force $outDir | Out-Null
$report = Join-Path $outDir "$Backend-Windows.txt"
Set-Content -Encoding utf8 $report ""

$bargs = @("--no-init")
switch ($Backend) {
  "bricscad"   { $bargs += @("--bricscad","--mode","batch","--timeout","180") }
  "autocad"    { $bargs += @("--autocad","--mode","batch"); if ($Dwg) { $bargs += @("--dwg",$Dwg) } }
  "clautolisp" { $bargs += @("--clautolisp","--host","mock") }
}
$bargs += @("-l",$probe)

("########## BACKEND: {0} ##########" -f $Backend) | Tee-Object -FilePath $report -Append
(& $alfe @bargs 2>&1) |
  Where-Object { "$_" -match '^PATHPROBE |BOOTSTRAP-FAILED|FAILED' } |
  Tee-Object -FilePath $report -Append
"pathname probe ($Backend) -> $report"
