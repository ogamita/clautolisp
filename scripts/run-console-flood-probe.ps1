<#
  run-console-flood-probe.ps1 -- does a long, chatty accoreconsole session
  complete? (issues/open/alfe-accoreconsole-console-pipe-not-drained)

    scripts/run-console-flood-probe.ps1 [-Backend {accoreconsole|bricscad}]

  Runs autolisp-front-end/tests/scenarios/entities/console-flood-probe.lsp in
  ONE CAD session: it drives about 1 MB into accoreconsole's own console
  (UTF-16LE) -- PROMPT, native PRINC, echoed SETVAR and REGEN commands --
  measuring engine-console-stdout.txt after every chunk (FLOOD-STEP lines).
  Before alfe 2.3.11 nothing read that console until the engine exited, so the
  session hung once the pipe was full, until --timeout.

  Output: dist/console-flood/<backend>-Windows.txt -- the FLOOD lines, the
  elapsed time and alfe's exit code; dist/console-flood/workdir-<backend>/ --
  the kept workdir, whose engine-console-stdout.txt holds the console text.
  Exits 1 when the session did not reach FLOOD-DONE (FLOOD-INCOMPLETE), or when
  the console received under 256 KB (FLOOD-WEAK: the run proves nothing).
#>
param(
  [ValidateSet("accoreconsole","bricscad")]
  [string]$Backend = "accoreconsole"
)
$ErrorActionPreference = "Continue"

$root = if ($env:CI_PROJECT_DIR) { $env:CI_PROJECT_DIR } else { (Get-Location).Path }
$alfe = if ($env:ALFE_BIN) { $env:ALFE_BIN } else { Join-Path $root "autolisp-front-end/tools/alfe/bin/alfe-sbcl" }

# PowerShell's & only runs files whose extension is in $PATHEXT (same dance as
# run-path-sysvars-probe.ps1).
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

$probe = Join-Path $root "autolisp-front-end/tests/scenarios/entities/console-flood-probe.lsp"
if (-not (Test-Path $probe)) { Write-Host "probe not found: $probe"; exit 2 }
if (-not $env:ALFE_RUNTIME_LSP)   { $env:ALFE_RUNTIME_LSP   = (Join-Path $root "autolisp-front-end/source/runtime/autolisp-remote-io.lsp") -replace '\\','/' }
if (-not $env:ALFE_BOOTSTRAP_LSP) { $env:ALFE_BOOTSTRAP_LSP = (Join-Path $root "autolisp-front-end/source/runtime/autolisp-bootstrap.lsp") -replace '\\','/' }

$outDir = Join-Path $root "dist/console-flood"
New-Item -ItemType Directory -Force $outDir | Out-Null
$report = Join-Path $outDir "$Backend-Windows.txt"
Set-Content -Encoding utf8 $report ""
$workdir = Join-Path $outDir "workdir-$Backend"
if (Test-Path $workdir) { Remove-Item -Recurse -Force $workdir }

# The drawing is alfe's (a fresh one in the workdir): see
# run-path-sysvars-probe.ps1 for why AUTOLISP_DWG is not set here.
$bargs = @("--no-init", "--keep-workdir", "--workdir", ($workdir -replace '\\','/'))
switch ($Backend) {
  "accoreconsole" { $bargs += @("--autocad","--mode","batch","--timeout","300") }
  "bricscad"      { $bargs += @("--bricscad","--mode","batch","--timeout","300") }
}
$bargs += @("-l", $probe)

# Every report line goes through Add-Content -Encoding utf8: Tee-Object writes
# UTF-16LE on Windows PowerShell 5, and mixed with the UTF-8 header it made the
# file unreadable to Select-String, which then missed FLOOD-DONE in a run that
# had printed it (job 17028620750). The verdict below is computed from the
# CAPTURED lines, never by re-reading the file.
function Report([string]$line) {
  Write-Host $line
  Add-Content -Encoding utf8 -Path $report -Value $line
}

Report "########## BACKEND: $Backend on Windows ##########"
$start = Get-Date
$lines = @(& $alfe $bargs 2>&1 |
  ForEach-Object { "$_" } |
  Where-Object { $_ -match '^FLOOD|BOOTSTRAP-FAILED|FAILED|TIMEOUT|did not reach' })
$code = $LASTEXITCODE
$elapsed = [int]((Get-Date) - $start).TotalSeconds
foreach ($l in $lines) { Report $l }
Report "FLOOD-RUN     alfe exit $code after $elapsed s"

$console = Join-Path $workdir "engine-console-stdout.txt"
$bytes = 0
if (Test-Path $console) {
  $bytes = (Get-Item $console).Length
  Report "FLOOD-CONSOLE engine-console-stdout.txt = $bytes bytes"
} else {
  Report "FLOOD-CONSOLE no engine-console-stdout.txt in the workdir (an alfe before 2.3.11?)"
}

# No DONE line: the session did not complete. A run that completed but whose
# console never received far more than a pipe buffer proves nothing about the
# deadlock: say so and fail, rather than read it as a pass.
$done = @($lines | Where-Object { $_ -match '^FLOOD-DONE' })
if ($done.Count -eq 0) {
  Report "FLOOD-INCOMPLETE  the session did not reach its end"
  exit 1
}
$minimum = 256 * 1024
if ($bytes -lt $minimum) {
  Report "FLOOD-WEAK    the console received $bytes bytes, under $minimum -- the run proves nothing about a full pipe"
  exit 1
}
Report "FLOOD-VERDICT complete, $bytes console bytes in one session"
