# Run the alfe entity / drawing-data / selection conformance probes against a
# real CAD backend (bricscad | autocad) and turn each probe's verdict line into
# a job pass/fail, saving every probe's full output as an artifact.
#
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts/run-vendor-probes.ps1 -Backend bricscad
#
# This is the automated form of the entity-mutation / drawing-data-structures /
# selection-and-snapshot "vendor verification" tail: the probes are byte-
# identical to the ones clautolisp passes headlessly, so a FAIL here names a
# real clautolisp-vs-vendor divergence. Exits non-zero if any probe fails or
# produces no verdict (backend unreachable).
param(
  [Parameter(Mandatory=$true)]
  [ValidateSet("bricscad","autocad")]
  [string]$Backend,
  # Drawing to open for the probes. AutoCAD batch (accoreconsole) needs one
  # or it stops with NO-DWG; empty.dwg is the clean canvas the create/delete
  # probes want. Overridden by the PROBE_DWG CI variable. A content drawing
  # (e.g. 2018.dwg) can be passed for read-oriented probes later.
  [string]$Dwg = "c:/gitlab-runner/dwg/empty.dwg"
)

$ErrorActionPreference = "Continue"
$root = if ($env:CI_PROJECT_DIR) { $env:CI_PROJECT_DIR } else { (Get-Location).Path }
$alfe = Join-Path $root "autolisp-front-end/tools/alfe/bin/alfe-sbcl"
$probeDir = Join-Path $root "autolisp-front-end/tests/scenarios/entities"
$outDir = Join-Path $root "dist/vendor-probes/$Backend"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

# AUTOLISP_DWG is consulted by both backends' batch paths; --dwg (below) is
# the explicit AutoCAD form and wins where supported.
if ($Dwg) { $env:AUTOLISP_DWG = $Dwg }

# The Makefile saves the SBCL image as `alfe-sbcl` with no extension. On
# Windows it is a native PE, but PowerShell's call operator (&) only runs
# files whose extension is in $PATHEXT, so it must be a `.exe`. Prefer an
# existing .exe, else copy the extension-less PE to one. (make-driven targets
# run the bare name fine because they go through sh/cmd, not PowerShell.)
if (Test-Path "$alfe.exe") {
  $alfe = "$alfe.exe"
} elseif (Test-Path $alfe) {
  Copy-Item -Force $alfe "$alfe.exe"
  $alfe = "$alfe.exe"
} else {
  Write-Host "alfe binary not found at $alfe (build it: make -C autolisp-front-end build-alfe-sbcl)"
  exit 2
}

$probes = @(
  @{ Name = "entity-lifecycle"; File = "entity-lifecycle-probe.lsp"; Pass = "ALL ENTITY PROBES PASSED" },
  @{ Name = "drawing-data";     File = "drawing-data-probe.lsp";     Pass = "ALL DRAWING-DATA PROBES PASSED" },
  @{ Name = "selection";        File = "selection-probe.lsp";        Pass = "ALL SELECTION PROBES PASSED" }
)

$failed = 0
$summary = @("vendor probes: $Backend", "alfe: $alfe", "dwg: $Dwg", "")
$tmpBase = if ($env:TEMP) { $env:TEMP } else { $outDir }
foreach ($p in $probes) {
  $probePath = Join-Path $probeDir $p.File
  $log = Join-Path $outDir ("{0}.log" -f $p.Name)
  Write-Host "=== $Backend : $($p.Name) ==="
  # Copy the drawing to a unique temp name per probe so concurrent /
  # back-to-back runs never share and lock the same file (or its
  # .dwl/.bak siblings). Removed after the probe.
  $probeDwg = $null
  if ($Dwg -and (Test-Path $Dwg)) {
    $probeDwg = Join-Path $tmpBase ("vp-{0}-{1}-{2}.dwg" -f $Backend, $p.Name, [guid]::NewGuid().ToString("N"))
    Copy-Item -Force $Dwg $probeDwg
  }
  try {
    if ($Backend -eq "autocad" -and $probeDwg) {
      # explicit batch + drawing selection for accoreconsole
      & $alfe "--autocad" "--mode" "batch" "--dwg" $probeDwg -l $probePath 2>&1 | Tee-Object -FilePath $log
    } else {
      & $alfe "--$Backend" -l $probePath 2>&1 | Tee-Object -FilePath $log
    }
  } finally {
    if ($probeDwg -and (Test-Path $probeDwg)) {
      Remove-Item -Force $probeDwg -ErrorAction SilentlyContinue
    }
  }
  $content = ""
  if (Test-Path $log) { $content = Get-Content -Raw $log }
  if ($content -match [regex]::Escape($p.Pass)) {
    $summary += "PASS  $($p.Name)"
    Write-Host "PASS  $($p.Name)"
  } else {
    $failed++
    $verdict = "no verdict (backend unreachable or crashed)"
    if ($content -match "PROBES FAILED: (\d+)") { $verdict = "$($matches[1]) assertion(s) failed" }
    $summary += "FAIL  $($p.Name) -- $verdict"
    Write-Host "FAIL  $($p.Name) -- $verdict"
  }
}
$summary | Set-Content -Encoding utf8 (Join-Path $outDir "SUMMARY.txt")
Write-Host "--- $Backend vendor-probe summary ---"
$summary | ForEach-Object { Write-Host $_ }
if ($failed -gt 0) { Write-Host "$failed probe(s) failed on $Backend"; exit 1 }
Write-Host "all vendor probes passed on $Backend"
exit 0
