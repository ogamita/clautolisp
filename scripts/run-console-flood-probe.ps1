<#
  run-console-flood-probe.ps1 -- does a long, chatty accoreconsole session
  complete? (issues/open/alfe-accoreconsole-console-pipe-not-drained)

    scripts/run-console-flood-probe.ps1 [-Backend {accoreconsole|bricscad}]

  Runs autolisp-front-end/tests/scenarios/entities/console-flood-probe.lsp in
  ONE CAD session: it PROMPTs 2, 4, 8, 16, 64 and 256 KB to the CAD's own
  command line (accoreconsole's console, UTF-16LE). Before alfe 2.3.11 nothing
  read that console until the engine exited, so the session hung at the block
  that filled the pipe, until --timeout. With the fix every block completes.

  Output: dist/console-flood/<backend>-Windows.txt -- the FLOOD lines, the
  elapsed time and alfe's exit code; dist/console-flood/workdir-<backend>/ --
  the kept workdir, whose engine-console-stdout.txt holds the console text.
  Exits 1 when the session did not reach FLOOD-DONE.
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

"########## BACKEND: $Backend on Windows ##########" | Tee-Object -FilePath $report -Append
$start = Get-Date
& $alfe $bargs 2>&1 |
  Select-String -Pattern '^FLOOD|BOOTSTRAP-FAILED|FAILED|TIMEOUT|did not reach' |
  ForEach-Object { $_.Line } |
  Tee-Object -FilePath $report -Append
$code = $LASTEXITCODE
$elapsed = [int]((Get-Date) - $start).TotalSeconds
"FLOOD-RUN     alfe exit $code after $elapsed s" | Tee-Object -FilePath $report -Append

$console = Join-Path $workdir "engine-console-stdout.txt"
if (Test-Path $console) {
  "FLOOD-CONSOLE engine-console-stdout.txt = $((Get-Item $console).Length) bytes" |
    Tee-Object -FilePath $report -Append
} else {
  "FLOOD-CONSOLE no engine-console-stdout.txt in the workdir (an alfe before 2.3.11?)" |
    Tee-Object -FilePath $report -Append
}

# No DONE line: the session did not complete -- say so in the file, so a
# truncated run is never read as a pass.
if (-not (Select-String -Path $report -Pattern '^FLOOD-DONE' -Quiet)) {
  "FLOOD-INCOMPLETE  the session did not reach its end" |
    Tee-Object -FilePath $report -Append
  Write-Host "console-flood probe ($Backend) -> $report : INCOMPLETE"
  exit 1
}
Write-Host "console-flood probe ($Backend) -> $report : complete"
