<#
  verify-bricscad-hidden-ui.ps1 — Windows integration check for
  alfe-bricscad-batch-hidden-ui. Drives a minimal `alfe --bricscad
  --mode batch` invocation through the real BricsCAD and asserts the
  full protocol cycle completes: BricsCAD is launched with /Automation
  (main frame hidden), reaches READY, executes the request, reports
  DONE, and exits cleanly.

  A successful run proves BricsCAD V25 ACCEPTS the /Automation switch in
  the direct /b batch command (an unaccepted switch aborts the launch).
  The UI being hidden is not something a headless check can assert
  directly; this proves the argv is accepted and the batch cycle still
  works. Interactive/RDP/session-0 behaviour (issue tests 2-4) stays a
  manual experiment.

  Exit 0 on success; non-zero (and a diagnostic) on any failure.
#>
$ErrorActionPreference = "Continue"

$root = if ($env:CI_PROJECT_DIR) { $env:CI_PROJECT_DIR } else { (Get-Location).Path }
$alfe = if ($env:ALFE_BIN) { $env:ALFE_BIN } else { Join-Path $root "autolisp-front-end/tools/alfe/bin/alfe-sbcl" }

# PowerShell's & only runs files whose extension is in $PATHEXT; the image
# is saved extension-less, so ensure a .exe copy exists (mirrors the other
# .ps1 drivers).
if (Test-Path "$alfe.exe") {
  $alfe = "$alfe.exe"
} elseif (Test-Path $alfe) {
  Copy-Item -Force $alfe "$alfe.exe"
  $alfe = "$alfe.exe"
} else {
  Write-Host "alfe binary not found at $alfe (build it: make -C autolisp-front-end build-alfe-sbcl)"
  exit 2
}

# CAD-side runtime for a built-not-installed alfe (see alfe-cad-console-encoding).
if (-not $env:ALFE_RUNTIME_LSP)   { $env:ALFE_RUNTIME_LSP   = (Join-Path $root "autolisp-front-end/source/runtime/autolisp-remote-io.lsp") -replace '\\','/' }
if (-not $env:ALFE_BOOTSTRAP_LSP) { $env:ALFE_BOOTSTRAP_LSP = (Join-Path $root "autolisp-front-end/source/runtime/autolisp-bootstrap.lsp") -replace '\\','/' }

$marker = "HIDDEN-UI-PROBE-OK-$PID"

# Pass the expression in a FILE (-l), never as -x "(princ \"...\")".
# PowerShell's native-argument parser strips the inner double quotes when
# calling a native executable, so `-x (princ "M")' reaches alfe as
# `(princ M)' -- BricsCAD then princ's an unbound symbol and echoes "nil".
# That is exactly how the first run of this script reported FAIL while the
# whole /Automation cycle had in fact succeeded (exit 0, "nil" echoed).
# The other .ps1 probe drivers in scripts/ all use -l for this reason.
$probe = Join-Path ([System.IO.Path]::GetTempPath()) "alfe-hidden-ui-probe-$PID.lsp"
Set-Content -Encoding ascii -Path $probe -Value "(princ `"$marker`")"
Write-Host "== probe file $probe =="
Get-Content $probe | ForEach-Object { Write-Host "   $_" }

# Record the exact command line alfe will launch (alfe 1.7.10+). Purely
# informational: it shows the /Automation switch really is in the argv.
Write-Host "== command line alfe would launch =="
& $alfe "--no-init" "--bricscad" "--mode" "batch" "--print-command" "-l" $probe 2>&1 |
  ForEach-Object { Write-Host $_ }

Write-Host "== running: alfe --bricscad --mode batch -l $probe =="
$out = & $alfe "--no-init" "--bricscad" "--mode" "batch" "--timeout" "180" "-l" $probe 2>&1
$code = $LASTEXITCODE
$out | ForEach-Object { Write-Host $_ }

Remove-Item -Force $probe -ErrorAction SilentlyContinue

$joined = ($out | Out-String)
if ($code -eq 0 -and $joined.Contains($marker)) {
  Write-Host "== PASS: batch cycle completed with /Automation; marker echoed, exit 0 =="
  exit 0
} else {
  Write-Host "== FAIL: exit=$code marker-present=$($joined.Contains($marker)) =="
  exit 1
}
