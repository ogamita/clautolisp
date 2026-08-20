<#
  run-path-sysvars-probe.ps1 — Windows twin of run-path-sysvars-probe.sh.
  Reads every path-carrying system variable off a CAD engine
  (bricscad-sysvars-on-macos.issue).

    scripts/run-path-sysvars-probe.ps1 -Backend {clautolisp|bricscad|autocad|accoreconsole}

  `autocad' and `accoreconsole' are separate backends on purpose: the same
  product launched two ways (GUI vs headless), and whether they populate the
  same variables is one of the questions being asked.

  Output: dist/path-sysvars/<backend>-Windows.txt — the PATHSYSVAR lines.
#>
param(
  [ValidateSet("clautolisp","bricscad","autocad","accoreconsole")]
  [string]$Backend = "clautolisp"
)
$ErrorActionPreference = "Continue"

$root = if ($env:CI_PROJECT_DIR) { $env:CI_PROJECT_DIR } else { (Get-Location).Path }
$alfe = if ($env:ALFE_BIN) { $env:ALFE_BIN } else { Join-Path $root "autolisp-front-end/tools/alfe/bin/alfe-sbcl" }

# PowerShell's & only runs files whose extension is in $PATHEXT, so the image
# is copied to .exe when it is not already named that (same dance as
# run-pathname-probe.ps1 -- and the same trap: testing for "$alfe.exe" when
# $alfe already ends in .exe would look for alfe-sbcl.exe.exe).
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

$probe = Join-Path $root "autolisp-front-end/tests/scenarios/entities/path-sysvars-probe.lsp"
if (-not (Test-Path $probe)) { Write-Host "probe not found: $probe"; exit 2 }
if (-not $env:ALFE_RUNTIME_LSP)   { $env:ALFE_RUNTIME_LSP   = (Join-Path $root "autolisp-front-end/source/runtime/autolisp-remote-io.lsp") -replace '\\','/' }
if (-not $env:ALFE_BOOTSTRAP_LSP) { $env:ALFE_BOOTSTRAP_LSP = (Join-Path $root "autolisp-front-end/source/runtime/autolisp-bootstrap.lsp") -replace '\\','/' }

$outDir = Join-Path $root "dist/path-sysvars"
New-Item -ItemType Directory -Force $outDir | Out-Null
$report = Join-Path $outDir "$Backend-Windows.txt"
Set-Content -Encoding utf8 $report ""

$bargs = @("--no-init")
switch ($Backend) {
  "bricscad"      { $bargs += @("--bricscad","--mode","batch","--timeout","180") }
  # --mode automation is the GUI engine (acad); --mode batch is AcCoreConsole.
  "autocad"       { $bargs += @("--autocad","--mode","automation","--timeout","300") }
  "accoreconsole" { $bargs += @("--autocad","--mode","batch","--timeout","300") }
  "clautolisp"    { $bargs += @("--clautolisp","--host","mock") }
}
$bargs += @("-l", $probe)

"########## BACKEND: $Backend on Windows ##########" | Tee-Object -FilePath $report -Append
& $alfe $bargs 2>&1 |
  Select-String -Pattern '^PATHSYSVAR|BOOTSTRAP-FAILED|FAILED' |
  ForEach-Object { $_.Line } |
  Tee-Object -FilePath $report -Append

# A report with no DONE line is a run that died mid-way; say so in the file,
# so a truncated probe is never read as an engine that defines nothing.
if (-not (Select-String -Path $report -Pattern '^PATHSYSVAR-DONE' -Quiet)) {
  "PATHSYSVAR-INCOMPLETE  the probe did not reach its end" |
    Tee-Object -FilePath $report -Append
}

Write-Host "path-sysvars probe ($Backend) -> $report"
