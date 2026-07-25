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
  [string]$Backend
)

$ErrorActionPreference = "Continue"
$root = if ($env:CI_PROJECT_DIR) { $env:CI_PROJECT_DIR } else { (Get-Location).Path }
$alfe = Join-Path $root "autolisp-front-end/tools/alfe/bin/alfe-sbcl"
$probeDir = Join-Path $root "autolisp-front-end/tests/scenarios/entities"
$outDir = Join-Path $root "dist/vendor-probes/$Backend"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

if (-not (Test-Path $alfe)) {
  Write-Host "alfe binary not found at $alfe (build it: make -C autolisp-front-end build-alfe-sbcl)"
  exit 2
}

$probes = @(
  @{ Name = "entity-lifecycle"; File = "entity-lifecycle-probe.lsp"; Pass = "ALL ENTITY PROBES PASSED" },
  @{ Name = "drawing-data";     File = "drawing-data-probe.lsp";     Pass = "ALL DRAWING-DATA PROBES PASSED" },
  @{ Name = "selection";        File = "selection-probe.lsp";        Pass = "ALL SELECTION PROBES PASSED" }
)

$failed = 0
$summary = @("vendor probes: $Backend", "alfe: $alfe", "")
foreach ($p in $probes) {
  $probePath = Join-Path $probeDir $p.File
  $log = Join-Path $outDir ("{0}.log" -f $p.Name)
  Write-Host "=== $Backend : $($p.Name) ==="
  & $alfe "--$Backend" -l $probePath 2>&1 | Tee-Object -FilePath $log
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
