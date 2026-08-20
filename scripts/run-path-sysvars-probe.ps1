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

# A PRIVATE DRAWING PER JOB, and this is not tidiness.
#
# Every Windows CAD probe here opens the same fixed file,
# c:/gitlab-runner/dwg/empty.dwg. A BricsCAD that was killed -- by a job
# timeout, by a cancelled pipeline -- leaves its .dwl/.dwl2 lock beside that
# file, and the NEXT job to open it gets a modal dialog: "already in use,
# open read-only?" (pjb, observed 2026-08-20). Under /Automation the dialog
# is invisible, nobody clicks it, and the job holds the concurrency-1 CAD
# runner until its timeout -- which is how a stale lock from one dead job
# costs every later job half an hour each
# (cad-runner-wedged-by-modal-dialog.issue).
#
# Copying to a per-job name removes the collision at the root: a file named
# after $CI_JOB_ID has no lock beside it, because nothing has ever opened it.
# The stale lock next to the shared original stops mattering to this job.
$src = if ($env:PROBE_DWG) { $env:PROBE_DWG } else { "c:/gitlab-runner/dwg/empty.dwg" }
if (Test-Path $src) {
  $jobId = if ($env:CI_JOB_ID) { $env:CI_JOB_ID } else { [guid]::NewGuid().ToString("N") }
  # NOT under $outDir: that directory is the job's artifact path, and a
  # drawing copied there would be uploaded with every run for nothing.
  $workDir = Join-Path $root "dist/probe-dwg"
  New-Item -ItemType Directory -Force $workDir | Out-Null
  $mine = Join-Path $workDir ("probe-$jobId.dwg")
  Copy-Item -Force $src $mine
  # Belt and braces: a lock could exist if the name were ever reused.
  foreach ($ext in @(".dwl", ".dwl2")) {
    $lock = [System.IO.Path]::ChangeExtension($mine, $ext)
    if (Test-Path $lock) { Remove-Item -Force $lock }
  }
  $env:AUTOLISP_DWG = ($mine -replace '\\','/')
  Write-Host "probe drawing (private copy): $env:AUTOLISP_DWG"
} else {
  Write-Host "no probe drawing at $src -- letting alfe choose its own"
}

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
