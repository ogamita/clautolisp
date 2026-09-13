<#
  run-getcname-probe.ps1 — Windows twin of run-getcname-probe.sh. Harvests
  localised CAD command names via getcname for cadtui's locale dictionaries
  (cadtui-locale-probe-getcname.issue).

    scripts/run-getcname-probe.ps1 -Backend {clautolisp|bricscad|autocad|accoreconsole}

  `autocad' (GUI) and `accoreconsole' (headless) are separate backends on
  purpose: the same product two ways, and whether they translate identically is
  itself an answer. getcname is a nil stub in clautolisp, so --clautolisp only
  validates the probe shape.

  Output: dist/getcname/<backend>-Windows.txt — the GETCNAME lines.
#>
param(
  [ValidateSet("clautolisp","bricscad","autocad","accoreconsole")]
  [string]$Backend = "clautolisp"
)
$ErrorActionPreference = "Continue"

$root = if ($env:CI_PROJECT_DIR) { $env:CI_PROJECT_DIR } else { (Get-Location).Path }
$alfe = if ($env:ALFE_BIN) { $env:ALFE_BIN } else { Join-Path $root "autolisp-front-end/tools/alfe/bin/alfe-sbcl" }

# PowerShell's & only runs files whose extension is in $PATHEXT, so the image
# is copied to .exe when not already named that (same dance as the sibling
# probes — and the same trap: testing "$alfe.exe" when $alfe already ends in
# .exe would look for alfe-sbcl.exe.exe).
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

$probe = Join-Path $root "autolisp-front-end/tests/scenarios/entities/getcname-probe.lsp"
if (-not (Test-Path $probe)) { Write-Host "probe not found: $probe"; exit 2 }
if (-not $env:ALFE_RUNTIME_LSP)   { $env:ALFE_RUNTIME_LSP   = (Join-Path $root "autolisp-front-end/source/runtime/autolisp-remote-io.lsp") -replace '\\','/' }
if (-not $env:ALFE_BOOTSTRAP_LSP) { $env:ALFE_BOOTSTRAP_LSP = (Join-Path $root "autolisp-front-end/source/runtime/autolisp-bootstrap.lsp") -replace '\\','/' }

$bargs = @("--no-init")
switch ($Backend) {
  "bricscad"      { $bargs += @("--bricscad","--mode","batch","--timeout","180") }
  # --mode automation is the GUI engine (acad); --mode batch is AcCoreConsole.
  "autocad"       { $bargs += @("--autocad","--mode","automation","--timeout","300") }
  "accoreconsole" { $bargs += @("--autocad","--mode","batch","--timeout","300") }
  "clautolisp"    { $bargs += @("--clautolisp","--host","mock") }
}
$bargs += @("-l", $probe)

$outDir = Join-Path $root "dist/getcname"
New-Item -ItemType Directory -Force $outDir | Out-Null
$report = Join-Path $outDir "$Backend-Windows.txt"
Set-Content -Encoding utf8 $report ""

"########## BACKEND: $Backend on Windows ##########" | Tee-Object -FilePath $report -Append
& $alfe $bargs 2>&1 |
  Select-String -Pattern '^GETCNAME|BOOTSTRAP-FAILED|FAILED' |
  ForEach-Object { $_.Line } |
  Tee-Object -FilePath $report -Append

# A report with no DONE line is a run that died mid-way; say so in the file, so
# a truncated harvest is never read as an engine that translates nothing.
if (-not (Select-String -Path $report -Pattern '^GETCNAME-DONE' -Quiet)) {
  "GETCNAME-INCOMPLETE  the probe did not reach its end" |
    Tee-Object -FilePath $report -Append
}

Write-Host "getcname probe ($Backend) -> $report"
