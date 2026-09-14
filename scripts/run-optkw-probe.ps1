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

$bargs = @("--no-init")
switch ($Backend) {
  "bricscad"      { $bargs += @("--bricscad","--mode","batch","--timeout","240") }
  "autocad"       { $bargs += @("--autocad","--mode","automation","--timeout","300") }
  "accoreconsole" { $bargs += @("--autocad","--mode","batch","--timeout","300") }
  "clautolisp"    { $bargs += @("--clautolisp","--host","mock") }
}
$bargs += @("-l", $probe)

$outDir = Join-Path $root "dist/optkw"
New-Item -ItemType Directory -Force $outDir | Out-Null
$report = Join-Path $outDir "$Backend-Windows.txt"
Set-Content -Encoding utf8 $report "########## BACKEND: $Backend on Windows ##########"

& $alfe $bargs 2>&1 | ForEach-Object { $_ } | Tee-Object -FilePath $report -Append | Out-Null

if (-not (Select-String -Path $report -Pattern '^OPTKW-DONE' -Quiet)) {
  "OPTKW-INCOMPLETE  the probe did not reach its end" |
    Tee-Object -FilePath $report -Append | Out-Null
}

Write-Host "optkw probe ($Backend) -> $report"
