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

# Give BricsCAD BOTH a drawing and a profile.
#
# pjb, 2026-08-14: "sans dessins et sans profile, bricscad met des dialogues
# pour demander a l'utilisateur quoi utiliser." Those dialogs are fatal in a
# CI job — nobody can answer them — and under /Automation the main frame is
# hidden, so the prompt is not even visible. The run simply sits at BOOTING.
#
# That is exactly what happened here: READY-TIMEOUT after 180 s, "last
# status: BOOTING; launcher still running", while in the SAME pipeline the
# vendor probes reached READY on BricsCAD in 9.4 s. The two command lines:
#
#   probes (works):  bricscad.exe /Automation empty.dwg /p <profile> /b run.scr
#   this   (hangs):  bricscad.exe /Automation /b run.scr
#
# Every other Windows driver in scripts/ passes both; this one passed
# neither.
#
# Two things this means, both worth stating because both were got wrong
# before the argv was read:
#
#   - The timeout was NOT evidence against /Automation. The run never got
#     far enough to say anything about the switch, which is the only thing
#     this check exists to test.
#   - It was not the profile "auto-loading EPURE" either. That was a guess
#     of mine; the launched argv carries no /p at all, and per pjb EPURE is
#     loaded by explicit options, not by the default profile. The profile is
#     needed here to stop a PROMPT, not to unload an application.
# Only when someone NAMED a drawing. Defaulting to the shared
# c:/gitlab-runner/dwg/empty.dwg is what left a stale .dwl lock in front of
# the next job as a modal dialog; alfe writes a fresh drawing into its own
# workdir when nothing is named (empty-ressource.issue).
if ((-not $env:AUTOLISP_DWG) -and $env:PROBE_DWG) {
  $env:AUTOLISP_DWG = $env:PROBE_DWG
}
if (-not $env:AUTOLISP_BRICSCAD_PROFILE) {
  $env:AUTOLISP_BRICSCAD_PROFILE =
    if ($env:BRICSCAD_PROFILE_CLEAN) { $env:BRICSCAD_PROFILE_CLEAN } else { "<<Profil sans nom>>" }
}
Write-Host "AUTOLISP_DWG = $env:AUTOLISP_DWG"
Write-Host "AUTOLISP_BRICSCAD_PROFILE = $env:AUTOLISP_BRICSCAD_PROFILE"

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
