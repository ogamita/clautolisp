<#
  run-request-locals-probe.ps1 -- Windows twin of run-request-locals-probe.sh.
  MEASURES whether a user program's globals survive alfe's request machinery
  on the CAD: a (setq f 1 text "t" ...) made by the -l file, by an -x request
  and by a function, read back by a LATER request
  (issues/open/alfe-eval-request-locals-capture-user-setq.issue).

    scripts/run-request-locals-probe.ps1 -Backend {clautolisp|bricscad|autocad|accoreconsole}

  `autocad' (GUI) and `accoreconsole' (headless) are separate backends on
  purpose: the same product two ways.

  Output: dist/request-locals/<backend>-Windows.txt -- the RLOCALS lines.
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

$probe = Join-Path $root "autolisp-front-end/tests/scenarios/entities/request-locals-probe.lsp"
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
# Step 1: the -l file sets the names; step 2: an -x setq; step 3: a function
# setting them, as --main runs one. Each is read back by a LATER request. No
# double quote inside the -x text: Windows PowerShell 5 does not pass
# embedded quotes intact.
$bargs += @("-l", $probe, "-x", "(rlp-report 1)",
            "-x", "(setq f 111 text 112 r 113 path 114 form 115 source 116 err 117 normalized 118 result 119 keep 120 req-id 121 rc 122 line 123 obj 124 msg 125 args 126 name 127 value 128 x 129 s 130 idx 131 back 132 on 133)", "-x", "(rlp-report 2)",
            "-x", "(rlp-set-in-fn)", "-x", "(rlp-report 3)", "-x", "(rlp-done)")

$outDir = Join-Path $root "dist/request-locals"
New-Item -ItemType Directory -Force $outDir | Out-Null
$report = Join-Path $outDir "$Backend-Windows.txt"
# Every write is Add-Content -Encoding utf8: Tee-Object -Append writes UTF-16
# under Windows PowerShell 5, which left the 2026-10-08 reports mixed
# (UTF-8 BOM + UTF-16LE body) and hid the DONE line from Select-String.
Set-Content -Encoding utf8 $report ""

"########## BACKEND: $Backend on Windows ##########" | ForEach-Object { $_; Add-Content -Encoding utf8 -Path $report -Value $_ }
& $alfe $bargs 2>&1 |
  Select-String -Pattern '^RLOCALS|BOOTSTRAP-FAILED|FAILED' |
  ForEach-Object { $_.Line } |
  ForEach-Object { $_; Add-Content -Encoding utf8 -Path $report -Value $_ }

# A report with no DONE line is a run that died mid-way; say so in the file, so
# a truncated run is never read as a complete one.
if (-not (Select-String -Path $report -Pattern '^RLOCALS-DONE' -Quiet)) {
  "RLOCALS-INCOMPLETE  the probe did not reach its end" |
    ForEach-Object { $_; Add-Content -Encoding utf8 -Path $report -Value $_ }
}

Write-Host "request-locals probe ($Backend) -> $report"
