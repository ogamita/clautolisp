<#
  run-command-prompts-probe.ps1 — Windows twin of run-command-prompts-probe.sh.
  Drives command-prompts-probe.lsp against a CAD backend to capture each drawing
  command's verbatim LASTPROMPT / option-keyword strings
  (windows-runner-sunset-probe-campaign.issue, batch B12).

    scripts/run-command-prompts-probe.ps1 -Backend {clautolisp|bricscad|autocad} [-Dwg FILE]

  Output: dist/command-prompts/<backend>-Windows.txt — the CMDPROBE lines.
#>
param(
  [ValidateSet("clautolisp","bricscad","autocad")]
  [string]$Backend = "clautolisp",
  [string]$Dwg = ""
)
$ErrorActionPreference = "Continue"

$root = if ($env:CI_PROJECT_DIR) { $env:CI_PROJECT_DIR } else { (Get-Location).Path }
$alfe = if ($env:ALFE_BIN) { $env:ALFE_BIN } else { Join-Path $root "autolisp-front-end/tools/alfe/bin/alfe-sbcl" }

# PowerShell's & only runs files whose extension is in $PATHEXT; the Windows
# build produces alfe-sbcl.exe. The -like guard avoids alfe-sbcl.exe.exe when
# ALFE_BIN already names the .exe. (Same logic as run-pathname-probe.ps1.)
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

$probe = Join-Path $root "autolisp-front-end/tests/scenarios/entities/command-prompts-probe.lsp"
if (-not $env:ALFE_RUNTIME_LSP)   { $env:ALFE_RUNTIME_LSP   = (Join-Path $root "autolisp-front-end/source/runtime/autolisp-remote-io.lsp") -replace '\\','/' }
if (-not $env:ALFE_BOOTSTRAP_LSP) { $env:ALFE_BOOTSTRAP_LSP = (Join-Path $root "autolisp-front-end/source/runtime/autolisp-bootstrap.lsp") -replace '\\','/' }

$outDir = Join-Path $root "dist/command-prompts"
New-Item -ItemType Directory -Force $outDir | Out-Null
$report = Join-Path $outDir "$Backend-Windows.txt"
# Add-Content -Encoding utf8, never Tee-Object -Append: Windows PowerShell 5
# writes UTF-16 there, which hid DONE lines from Select-String
# (probe-ps1-done-check-misreads-utf16-report).
Set-Content -Encoding utf8 $report ""

$bargs = @("--no-init")
switch ($Backend) {
  "bricscad"   { $bargs += @("--bricscad","--mode","batch","--timeout","180") }
  "autocad"    { $bargs += @("--autocad","--mode","batch"); if ($Dwg) { $bargs += @("--dwg",$Dwg) } }
  "clautolisp" { $bargs += @("--clautolisp","--host","cador") }
}
$bargs += @("-l",$probe)

("########## BACKEND: {0} ##########" -f $Backend) | ForEach-Object { $_; Add-Content -Encoding utf8 -Path $report -Value "$_" }
(& $alfe @bargs 2>&1) |
  Where-Object { "$_" -match '^CMDPROBE |BOOTSTRAP-FAILED|FAILED' } |
  ForEach-Object { $_; Add-Content -Encoding utf8 -Path $report -Value "$_" }
"command-prompts probe ($Backend) -> $report"
