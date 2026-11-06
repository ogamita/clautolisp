# Characterise what alfe can drive in the CURRENT Windows session state.
#
# The question (pjb, 2026-09-28): with the runner account logged in but the
# GUI session suspended -- back to the login window / "change user" -- which
# of {clautolisp, bricscad, autocad} x {--mode batch, --mode automation,
# --epure} still run? The hypothesis, from benchmark:autocad:windows dying
# after 2 of 7 benchmarks while benchmark:bricscad:windows ran all 7 on the
# same runner: COM automation (--mode automation, and --epure which drives
# COM on AutoCAD) needs a live interactive desktop and fails when the session
# is disconnected/locked, while headless batch (accoreconsole for AutoCAD)
# survives. See autocad-com-fails-in-disconnected-windows-session.issue.
#
# A PROBE, not a gate: it runs the whole matrix, records each cell's outcome
# and prints a table, and ALWAYS exits 0. Reading the table against the
# session state banner (printed first) is the deliverable; nothing here is an
# assertion that fails the job.

$ErrorActionPreference = 'Continue'

# 1. Session state first, so the matrix below is read in its light.
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'windows-session-state.ps1')

$alfe = Join-Path $PSScriptRoot '..\autolisp-front-end\tools\alfe\bin\alfe-sbcl.exe'
if (-not (Test-Path $alfe)) { Write-Host "alfe-sbcl.exe not built at $alfe"; exit 0 }

# Per-engine timeout (seconds). A disconnected COM run must not sit forever;
# alfe's own --timeout is what bounds a hang, so keep these modest.
$tAutocad   = if ($env:PROBE_AUTOCAD_TIMEOUT)   { $env:PROBE_AUTOCAD_TIMEOUT }   else { '180' }
$tBricscad  = if ($env:PROBE_BRICSCAD_TIMEOUT)  { $env:PROBE_BRICSCAD_TIMEOUT }  else { '300' }
$tClautolisp= if ($env:PROBE_CLAUTOLISP_TIMEOUT){ $env:PROBE_CLAUTOLISP_TIMEOUT }else { '120' }

$marker = 'PROBE.SESSION.MARKER.OK'
$probe  = Join-Path ([System.IO.Path]::GetTempPath()) 'alfe-session-probe.lsp'
"(progn (princ `"$marker`") (princ))" | Set-Content -Path $probe -Encoding ASCII

# The matrix. clautolisp is the base: in-process, no external process, so it
# is the control that must pass in EVERY session state -- if it does not, the
# problem is not the desktop. Which engines to try: PROBE_CADS overrides.
$engines = if ($env:PROBE_CADS) { $env:PROBE_CADS -split '[,\s]+' } else { @('clautolisp', 'bricscad', 'autocad') }
$options = @(
    [pscustomobject]@{ Key = 'batch';      Args = @('--mode', 'batch') }
    [pscustomobject]@{ Key = 'automation'; Args = @('--mode', 'automation') }
    [pscustomobject]@{ Key = 'epure';      Args = @('--epure') }
)

$rows = @()
foreach ($engine in $engines) {
    $t = switch ($engine) {
        'autocad'    { $tAutocad }
        'bricscad'   { $tBricscad }
        default      { $tClautolisp }
    }
    foreach ($opt in $options) {
        $label = "--$engine $($opt.Args -join ' ')"
        Write-Host ""
        Write-Host "================ alfe $label   (timeout ${t}s)"
        $started = Get-Date
        $argv = @('--no-init', '--debug', "--$engine") + $opt.Args + `
                @('--timeout', $t, '--keep-workdir', '-l', $probe)
        $out = & $alfe @argv 2>&1 | Out-String
        $status = $LASTEXITCODE
        $elapsed = [int]((Get-Date) - $started).TotalSeconds
        Write-Host $out
        Write-Host "--- alfe exit $status after ${elapsed}s"

        $sawMarker = [bool]($out -match [regex]::Escape($marker))
        # alfe's own "READY after N s" -- not the bare word, which its timeout
        # messages also carry ("waiting for READY", "[READY-TIMEOUT]"): job
        # 16990501680 labelled four never-READY timeouts REACHED-READY-THEN-FAILED.
        $sawReady  = [bool]($out -match 'READY after ')
        $verdict   = if ($status -eq 0 -and $sawMarker) { 'OK' }
                     elseif ($sawReady)                 { 'REACHED-READY-THEN-FAILED' }
                     else                               { 'FAIL' }
        $rows += [pscustomobject]@{
            Engine = $engine; Option = $opt.Key; Exit = $status
            Marker = $sawMarker; Ready = $sawReady; Seconds = $elapsed; Verdict = $verdict
        }
    }
}

Write-Host ""
Write-Host "==================== session-state CAD matrix ===================="
Write-Host ("{0,-11} {1,-11} {2,5} {3,7} {4,6} {5,4} {6}" -f `
            'engine','option','exit','marker','ready','sec','verdict')
foreach ($r in $rows) {
    Write-Host ("{0,-11} {1,-11} {2,5} {3,7} {4,6} {5,4} {6}" -f `
                $r.Engine, $r.Option, $r.Exit,
                $(if ($r.Marker){'yes'}else{'no'}),
                $(if ($r.Ready){'yes'}else{'no'}),
                $r.Seconds, $r.Verdict)
}
Write-Host "=================================================================="
Write-Host "(read this against the SESSION-STATE line printed at the top)"
exit 0
