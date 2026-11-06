<#
  run-dxf-angles-probe.ps1 -- Windows twin of run-dxf-angles-probe.sh.
  MEASURES the unit of the angle groups of a DXF file the CAD writes, against
  entget of the same entities (issues/open/dxf-file-angle-units.issue,
  issues/open/dxf-angle-units-hatch-viewport-tables.issue).

    scripts/run-dxf-angles-probe.ps1 -Backend {clautolisp|bricscad|autocad|accoreconsole}

  `autocad' (GUI) and `accoreconsole' (headless) are separate backends on
  purpose: the same product two ways.

  Output: dist/dxf-angles/<backend>-Windows.txt -- the DXFANG lines -- and
  dist/dxf-angles/<backend>-Windows.dxf -- the DXF the CAD wrote. Copy both
  to clautolisp/drawing/tests/fixtures/vendor-dxf/ to make them a fixture of
  the drawing tests (see the README.org there).
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
# probes -- and the same trap: testing "$alfe.exe" when $alfe already ends in
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

$probe = Join-Path $root "autolisp-front-end/tests/scenarios/entities/dxf-angles-probe.lsp"
if (-not (Test-Path $probe)) { Write-Host "probe not found: $probe"; exit 2 }
if (-not $env:ALFE_RUNTIME_LSP)   { $env:ALFE_RUNTIME_LSP   = (Join-Path $root "autolisp-front-end/source/runtime/autolisp-remote-io.lsp") -replace '\\','/' }
if (-not $env:ALFE_BOOTSTRAP_LSP) { $env:ALFE_BOOTSTRAP_LSP = (Join-Path $root "autolisp-front-end/source/runtime/autolisp-bootstrap.lsp") -replace '\\','/' }

$bargs = @("--no-init")
switch ($Backend) {
  "bricscad"      { $bargs += @("--bricscad","--mode","batch","--timeout","300") }
  # --mode automation is the GUI engine (acad); --mode batch is AcCoreConsole.
  "autocad"       { $bargs += @("--autocad","--mode","automation","--timeout","300") }
  "accoreconsole" { $bargs += @("--autocad","--mode","batch","--timeout","300") }
  "clautolisp"    { $bargs += @("--clautolisp") }
}
$bargs += @("-l", $probe)

$outDir = Join-Path $root "dist/dxf-angles"
# The Windows runner reuses its build directory: start empty, or the
# artefact carries other backends' reports and DXFs (seen in job 17409369691).
if (Test-Path $outDir) { Remove-Item -Recurse -Force $outDir }
New-Item -ItemType Directory -Force $outDir | Out-Null
$report = Join-Path $outDir "$Backend-Windows.txt"
$dxfCopy = Join-Path $outDir "$Backend-Windows.dxf"
if (Test-Path $dxfCopy) { Remove-Item -Force $dxfCopy }

# Where the CAD should write its DXF -- a WORK file, never the artefact: the
# exported file BECOMES the CAD's document, which the probe saves again at
# the end (so no quit finds it modified) and the CAD may hold open. The probe
# reports a copy of the export as it was measured on its DXFANG EXPORT-PATH
# line, and that copy is what goes into the artefact. An AutoCAD started
# through COM may not inherit the environment; the probe then falls back on
# TEMPPREFIX. DXFANG_BACKEND tells the probe it runs in accoreconsole, which
# has no COM.
$env:DXFANG_DXF = (Join-Path $env:TEMP "dxfang-$Backend-export.dxf")
$env:DXFANG_BACKEND = $Backend

# Every write is Add-Content -Encoding utf8: Tee-Object -Append writes UTF-16
# under Windows PowerShell 5, which left the 2026-10-08 reports mixed
# (UTF-8 BOM + UTF-16LE body) and hid the DONE line from Select-String.
Set-Content -Encoding utf8 $report ""

function Write-Report([string]$line) {
  $line
  Add-Content -Encoding utf8 -Path $report -Value $line
}

Write-Report "########## BACKEND: $Backend on Windows ##########"
& $alfe $bargs 2>&1 |
  Select-String -Pattern '^DXFANG|BOOTSTRAP-FAILED|FAILED' |
  ForEach-Object { $_.Line } |
  ForEach-Object { $_; Add-Content -Encoding utf8 -Path $report -Value $_ }

# A report with no DONE line is a run that died mid-way; say so in the file, so
# a truncated run is never read as a complete one.
if (-not (Select-String -Path $report -Pattern '^DXFANG-DONE' -Quiet)) {
  Write-Report "DXFANG-INCOMPLETE  the probe did not reach its end"
}

# The DXF itself goes into the artefact, wherever the CAD wrote it.
$written = $null
$hit = Select-String -Path $report -Pattern '^DXFANG EXPORT-PATH ' | Select-Object -Last 1
if ($hit) { $written = $hit.Line.Substring("DXFANG EXPORT-PATH ".Length).Trim() }
if ($written -and (Test-Path -LiteralPath $written)) {
  $same = $false
  try {
    $same = ((Resolve-Path -LiteralPath $written).Path -eq (Resolve-Path -LiteralPath $dxfCopy -ErrorAction Stop).Path)
  } catch { $same = $false }
  if (-not $same) { Copy-Item -Force -LiteralPath $written -Destination $dxfCopy }
  Write-Report "DXFANG-COPIED $dxfCopy"
} else {
  Write-Report "DXFANG-NO-DXF  no file at '$written'"
}

Write-Host "dxf-angles probe ($Backend) -> $report"
