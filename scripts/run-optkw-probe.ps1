<#
  run-optkw-probe.ps1 — Windows twin of run-optkw-probe.sh. Harvests localised
  command OPTION KEYWORDS by driving each command and capturing its prompt
  (cadtui-locale-option-keywords.issue).

    scripts/run-optkw-probe.ps1 -Backend {clautolisp|bricscad|autocad|accoreconsole}

  Captures the FULL stdout: the keywords live in the [option/list] of the prompt
  BETWEEN the OPTKW-BEGIN/OPTKW-END markers. Prefer a batch backend
  (accoreconsole) so prompts are echoed to stdout.

  Output: dist/optkw/<backend>-Windows.txt — the full transcript.
#>
param(
  [ValidateSet("clautolisp","bricscad","autocad","accoreconsole")]
  [string]$Backend = "clautolisp"
)
$ErrorActionPreference = "Continue"

$root = if ($env:CI_PROJECT_DIR) { $env:CI_PROJECT_DIR } else { (Get-Location).Path }
$alfe = if ($env:ALFE_BIN) { $env:ALFE_BIN } else { Join-Path $root "autolisp-front-end/tools/alfe/bin/alfe-sbcl" }

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

$probe = Join-Path $root "autolisp-front-end/tests/scenarios/entities/optkw-probe.lsp"
if (-not (Test-Path $probe)) { Write-Host "probe not found: $probe"; exit 2 }
if (-not $env:ALFE_RUNTIME_LSP)   { $env:ALFE_RUNTIME_LSP   = (Join-Path $root "autolisp-front-end/source/runtime/autolisp-remote-io.lsp") -replace '\\','/' }
if (-not $env:ALFE_BOOTSTRAP_LSP) { $env:ALFE_BOOTSTRAP_LSP = (Join-Path $root "autolisp-front-end/source/runtime/autolisp-bootstrap.lsp") -replace '\\','/' }

# accoreconsole: ONE SESSION PER COMMAND. Its run hung part-way three times
# (jobs 16981155886, 16998925798, 17026576122), after a different command
# each time; the leading hypothesis is that alfe does not read accoreconsole's
# console pipe while the engine runs, so a long run blocks once that pipe is
# full (issues/open/alfe-accoreconsole-console-pipe-not-drained.issue). One
# command per session keeps each run's console output small, and a hang then
# costs one command, not the rest. The probe reads its command list from
# OPTKW_COMMANDS (comma-separated) when it is set.
$perCommand = @("PLINE","BREAK","LENGTHEN","OFFSET","TRIM","EXTEND","FILLET",
                "CHAMFER","MIRROR","ROTATE","SCALE","RECTANG","ZOOM")
$timeout = if ($Backend -eq "accoreconsole") { "120" } else { "300" }

$bargs = @("--no-init")
switch ($Backend) {
  "bricscad"      { $bargs += @("--bricscad","--mode","batch","--timeout","240") }
  "autocad"       { $bargs += @("--autocad","--mode","automation","--timeout","300") }
  "accoreconsole" { $bargs += @("--autocad","--mode","batch","--timeout",$timeout) }
  "clautolisp"    { $bargs += @("--clautolisp","--host","mock") }
}
$bargs += @("-l", $probe)

$outDir = Join-Path $root "dist/optkw"
New-Item -ItemType Directory -Force $outDir | Out-Null
$report = Join-Path $outDir "$Backend-Windows.txt"
Set-Content -Encoding utf8 $report "########## BACKEND: $Backend on Windows ##########"

# Run alfe once (with OPTKW_COMMANDS = $commands, or the probe's whole list),
# append its output to the report, and record OPTKW-INCOMPLETE when it did not
# reach OPTKW-DONE. Checked on the CAPTURED LINES: a Select-String over the
# report (UTF-8 banner + UTF-16LE body) missed a present OPTKW-DONE and flagged
# a complete BricsCAD run incomplete (job 17026576124).
function Invoke-OptkwRun([string]$commands, [string]$what) {
  $env:OPTKW_COMMANDS = $commands
  $lines = @(& $alfe $bargs 2>&1 | ForEach-Object { "$_" })
  $lines | Tee-Object -FilePath $report -Append | Out-Null
  if (-not ($lines | Where-Object { $_ -match '^OPTKW-DONE' })) {
    "OPTKW-INCOMPLETE  $what did not reach its end" |
      Tee-Object -FilePath $report -Append | Out-Null
  }
  Remove-Item Env:OPTKW_COMMANDS -ErrorAction SilentlyContinue
}

if ($Backend -eq "accoreconsole") {
  foreach ($c in $perCommand) { Invoke-OptkwRun $c "the session for $c" }
} else {
  Invoke-OptkwRun "" "the probe"
}

Write-Host "optkw probe ($Backend) -> $report"
