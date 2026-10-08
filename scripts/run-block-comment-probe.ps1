<#
  run-block-comment-probe.ps1 -- Windows twin of run-block-comment-probe.sh.
  VERIFIES that alfe's CAD-side loader skips AutoLISP ;| ... |; block
  comments when it loads a file (-l)
  (issues/open/alfe-cad-source-loader-evaluates-block-comments.issue).

    scripts/run-block-comment-probe.ps1 -Backend {clautolisp|bricscad|autocad|accoreconsole}

  `autocad' (GUI) and `accoreconsole' (headless) are separate backends on
  purpose: the same product two ways.

  Output: dist/block-comment/<backend>-Windows.txt -- the BLKC lines.
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

$probe = Join-Path $root "autolisp-front-end/tests/scenarios/entities/block-comment-probe.lsp"
if (-not (Test-Path $probe)) { Write-Host "probe not found: $probe"; exit 2 }
if (-not $env:ALFE_RUNTIME_LSP)   { $env:ALFE_RUNTIME_LSP   = (Join-Path $root "autolisp-front-end/source/runtime/autolisp-remote-io.lsp") -replace '\\','/' }
if (-not $env:ALFE_BOOTSTRAP_LSP) { $env:ALFE_BOOTSTRAP_LSP = (Join-Path $root "autolisp-front-end/source/runtime/autolisp-bootstrap.lsp") -replace '\\','/' }

$bargs = @("--no-init")
switch ($Backend) {
  "bricscad"      { $bargs += @("--bricscad","--mode","batch","--timeout","180") }
  # --mode automation is the GUI engine (acad); --mode batch is AcCoreConsole.
  "autocad"       { $bargs += @("--autocad","--mode","automation","--timeout","300") }
  "accoreconsole" { $bargs += @("--autocad","--mode","batch","--timeout","300") }
  "clautolisp"    { $bargs += @("--clautolisp") }
}
# -l: the file goes through alfe's CAD-side loader, the code under test.
$bargs += @("-l", $probe)

$outDir = Join-Path $root "dist/block-comment"
New-Item -ItemType Directory -Force $outDir | Out-Null
$report = Join-Path $outDir "$Backend-Windows.txt"
# Every write is Add-Content -Encoding utf8: Tee-Object -Append writes UTF-16
# under Windows PowerShell 5, which left the 2026-10-08 reports mixed
# (UTF-8 BOM + UTF-16LE body) and hid the DONE line from Select-String.
Set-Content -Encoding utf8 $report ""

"########## BACKEND: $Backend on Windows ##########" | ForEach-Object { $_; Add-Content -Encoding utf8 -Path $report -Value $_ }
& $alfe $bargs 2>&1 |
  Select-String -Pattern '^BLKC|BOOTSTRAP-FAILED|FAILED|BOOM|ERROR' |
  ForEach-Object { $_.Line } |
  ForEach-Object { $_; Add-Content -Encoding utf8 -Path $report -Value $_ }

# A report with no DONE line is a run that died mid-way; say so in the file, so
# a truncated run is never read as a complete one.
if (-not (Select-String -Path $report -Pattern '^BLKC-DONE' -Quiet)) {
  "BLKC-INCOMPLETE  the probe did not reach its end" |
    ForEach-Object { $_; Add-Content -Encoding utf8 -Path $report -Value $_ }
}

Write-Host "block-comment probe ($Backend) -> $report"
